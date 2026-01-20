clear all;

fitFuncFolder = 'C:\Niobium\Analysis\Common';
addpath(fitFuncFolder);

vna = visadev("TCPIP0::169.254.54.30::inst0::INSTR");
vna.Timeout = 300;

writeline(vna, "*IDN?");
idn = readline(vna);
fprintf("Connected to: %s\n", idn);

f0_guess = 10.078e9;
expected_Q = 1e3;
span = f0_guess / expected_Q * 5;  % sweep 5× linewidth
fstart = f0_guess - span/2;
fstop  = f0_guess + span/2;
numpoints = 501;
ifbw = 10;
pow = 10;

writeline(vna, "*RST");
writeline(vna, "SYST:PRES");
writeline(vna, "*CLS");

writeline(vna, "DISP:WIND1:STAT ON");
writeline(vna, "DISP:WIND1:TRAC1:DEL:ALL");

writeline(vna, "CALC1:PAR:DEF 'Trc1','S21'");
writeline(vna, "DISP:WIND1:TRAC1:FEED 'Trc1'");
writeline(vna, "CALC1:PAR:SEL 'Trc1'");

writeline(vna, sprintf("SENS1:FREQ:STAR %e", fstart));
writeline(vna, sprintf("SENS1:FREQ:STOP %e", fstop));
writeline(vna, sprintf("SENS1:SWE:POIN %d", numpoints));
writeline(vna, sprintf("SENS1:BWID %e", ifbw));
writeline(vna, sprintf("SOUR1:POW %f", pow));

writeline(vna, "INIT1:CONT OFF");
writeline(vna, "INIT1:IMM");
writeline(vna, "*OPC?");
readline(vna);

writeline(vna, "CALC1:DATA:STIM?");
freq = str2double(split(readline(vna), ','))';
writeline(vna, "FORM:DATA ASCII");
writeline(vna, "CALC1:PAR:SEL 'Trc1'");
writeline(vna, "CALC1:DATA? SDATA");
raw = str2double(split(readline(vna), ','))';
S21 = raw(1:2:end) + 1j*raw(2:2:end);

freq = freq(:)';    % force row vector
S21 = S21(:)';      % force row vector

S21_mag_dB = 20*log10(abs(S21));
S21_phase  = unwrap(angle(S21))*180/pi;

figure;
subplot(2,1,1)
plot(freq/1e9, S21_mag_dB, 'LineWidth', 1.5)
xlabel("Frequency (GHz)")
ylabel("S21 (dB)")
grid on

subplot(2,1,2)
plot(freq/1e9, S21_phase, 'LineWidth', 1.5)
xlabel("Frequency (GHz)")
ylabel("Phase (deg)")
grid on

dateStr = datestr(now,'yyyymmdd');
filename = sprintf("RES1_S21_%s.mat", dateStr);
save(filename, "freq", "S21");

opts = optimset('MaxFunEvals',5000);  % increase maximum function evaluations
[fit_params, ~] = fit_resonance_circle(freq, S21, 'show_plot', 1);

Ql = 1 / (1/fit_params.Qi + 1/fit_params.Qc);

fprintf("\n===== Resonator Fit Results =====\n");
fprintf("f0  = %.6f GHz\n", fit_params.f0/1e9);
fprintf("Qi  = %.2e\n", fit_params.Qi);
fprintf("Qc  = %.2e\n", fit_params.Qc);
fprintf("Ql  = %.2e\n", Ql);
fprintf("phi = %.3f rad\n", fit_params.phi);

%% Plot Lorentzian using calibrated circle
f0 = fit_params.f0;
Qi = fit_params.Qi;
Qc = fit_params.Qc;
phi = fit_params.phi;

Ql = 1 / (1/Qi + 1/Qc);
tau = 0; alpha = 0; A = 1; % approximate calibration for plotting
S21_corr = S21 .* exp(-1i*2*pi*freq*tau); % simple correction

S_fit = A ./ sqrt(1 + 4*Ql^2*((freq - f0)/f0).^2);

figure;
plot(freq/1e9, 20*log10(abs(S21_corr)), '.', 'MarkerSize', 12);
hold on;
plot(freq/1e9, 20*log10(S_fit), '-', 'LineWidth', 2);
xlabel('Frequency (GHz)');
ylabel('|S_{21}| [dB]');
grid on;
legend('Calibrated Data','Lorentzian Fit');

clear vna
