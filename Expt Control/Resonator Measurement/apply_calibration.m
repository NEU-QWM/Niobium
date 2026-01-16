function scaled_data = apply_calibration(f, data, show_plot, figHandles)
    %%% Apply the calibration to resonator data to move it to canonical position
    [tau, alpha, a] = calibrate_resonance(f, data);
    
    % Apply cable delay
    data_delayed = data .* exp(-1i*2*pi*f*tau);
    
    % Apply rotation
    rot = [cos(-alpha) -sin(-alpha); sin(-alpha) cos(-alpha)];
    scaled_data = zeros(size(data));
    for j = 1:length(data)
        v = rot * [real(data_delayed(j)); imag(data_delayed(j))];
        scaled_data(j) = (v(1) + 1i*v(2)) / a;
    end
    
    % Optional plot
    if show_plot
        figure('Name','Calibrated S21 (Canonical)');
        plot(real(scaled_data), imag(scaled_data), '.', 'MarkerSize', 15);
        axis equal; grid on;
        xlabel('Re(S21)'); ylabel('Im(S21)');
        title('Calibrated Resonator Circle');
    end
end

function [tau, alpha, a] = calibrate_resonance(f, data)
    % Fit to cable delay
    tau = fit_delay(f, data);
    Sp = data .* exp(-1i*2*pi*f*tau);
    
    % Fit circle
    [R, xc, yc] = fit_circle(real(Sp), imag(Sp));
    Strans = (real(Sp)-xc) + 1i*(imag(Sp)-yc);
    
    % Phase reference
    [~, ~, theta0, ~] = fit_phase(f, Strans);
    
    % Compute amplitude scaling and rotation
    P = xc + R*cos(theta0+pi) + 1i*(yc + R*sin(theta0+pi));
    a = abs(P);
    alpha = angle(P);
end

%%%%% Functions for fitting frequency-dependent phase delay
function sse = delay_model(tau, f, data)
    %Model constant cable phase delay of resonator
    data = data.*exp(-2*pi*1i*f*tau);
    [R, xc, yc] = fit_circle(real(data), imag(data));
    X = real(data); Y = imag(data);
    sse = sum(R.^2 - (X-xc).^2 - (Y-yc).^2);
end

function tau = fit_delay(f, data)   
    %Phase delay adds a linear offset phase, so estimate first using
    %first and last 10 data points of data.
    phi = unwrap(angle(data));
    phi = [phi(1:10), phi(end-9:end)]';
    linfit = [ones(length(phi), 1) [f(1:10) f(end-9:end)]']\phi;
    model = @(t)delay_model(t, f, data);
    tau = fminsearch(model, linfit(2)/2/pi);
end

%%%%% Functions for frequency-phase fit of circle

function sse = phase_model(params, f, data, slope)
    %check direction of data
    theta0 = params(1);
    Q = params(2);
    f0 = params(3);
    fitfunc = theta0 + 2*slope*atan(2*Q*(1 - f/f0));
    sse = sum((fitfunc - unwrap(angle(data))).^2);
end

function [f0, Q, theta, fit] = fit_phase(f, data)
    phi = unwrap(angle(data));
    [~,idx] = min(abs(phi-mean(phi)));
      
    % % if mean(phi(1:10)) > mean(phi(end-9:end))
    % %     j = find(phi-phi(idx) < pi/2, 1, 'first');
    % %     k = find(phi-phi(idx) < -pi/2, 1, 'first');
    % %     slope = 1;
    % % else
    % %     j = find(phi-phi(idx) > pi/2, 1, 'first');
    % %     k = find(phi-phi(idx) > -pi/2, 1, 'first');
    % %     slope = -1;
    % % end
    
    if mean(phi(1:10)) > mean(phi(end-9:end))
        j = find(phi-phi(idx) < pi/2, 1, 'first');
        k = find(phi-phi(idx) < -pi/2, 1, 'first');
        slope = 1;
    else
        j = find(phi-phi(idx) > pi/2, 1, 'first');
        k = find(phi-phi(idx) > -pi/2, 1, 'first');
        slope = -1;
    end
    
    if isempty(j)
        j = min(idx+1,length(f));
    end
    if isempty(k)
        k = max(idx-1,1);
    end

    Qg = f(idx)/abs(f(j)-f(k));
    model = @(p) phase_model(p, f, data, slope);
    % pmin = fminsearch(model, [phi(idx), Qg, f(idx)]);
    options = optimset('MaxFunEvals', 1e6, 'MaxIter', 1e6);
    pmin = fminsearch(model, [phi(idx), Qg, f(idx)], options);
    fit = pmin(1) + 2*slope*atan(2*pmin(2)*(1 - f/pmin(3)));
    f0 = pmin(3); 
    Q = pmin(2);
    theta = pmin(1);
end
    
function [R, xc, yc] = fit_circle(x,y)
    %Fit the points x,y to a circle using algebra! See [2]    
    assert(length(x) == length(y), 'X and Y coordinates of circle must have same number of points.');
    n = length(x);
    z = x.^2 + y.^2;
    Mxx = sum(x.^2); Mx = sum(x);
    Myy = sum(y.^2); My = sum(y);
    Mzz = sum(z.^2); Mz = sum(z);
    Mxy = sum(x.*y);
    Mxz = sum(x.*z);
    Myz = sum(y.*z);
    M = [[Mzz Mxz Myz Mz]; [Mxz Mxx Mxy Mx]; [Myz Mxy Myy My]; [Mz Mx My n]];
    B = [[0 0 0 -2]; [0 1 0 0]; [0 0 1 0]; [-2 0 0 0]];
    %just solve the generalized eigenvalue problem -- reasonable for
    %the size of data we care about
    [V,D] = eig(M, B);
    D(D<eps) = NaN;
    [~,idx] = min(diag(D));
    ev = V(:,idx);
    xc = -ev(2)/2/ev(1);
    yc = -ev(3)/2/ev(1);
    R = sqrt(ev(2)^2 + ev(3)^2 - 4*ev(1)*ev(4))/2/abs(ev(1));
end