clear; clc;

addpath('C:\Niobium\Expt Control\Common');

%% ---------------- User parameters ----------------
resource = "TCPIP0::169.254.54.30::inst0::INSTR";

f0_guess   = 4.019661e9;
expected_Q = 1e4;
span       = f0_guess / expected_Q * 5;
fstart = f0_guess - span/2;
fstop  = f0_guess + span/2;
numpoints = 501;
ifbw      = 10;     
power     = 10;

%% ---------------- Connect to VNA ----------------
vna = deviceDrivers.ZNB3020(resource);
vna.preset();

vna.configureS21Sweep(fstart, fstop, numpoints, ifbw, power);
[freq, S21] = vna.measureS21();

%% ---------------- Plot raw S21 ----------------
figure('Name','Raw S21');

subplot(2,1,1)
plot(freq/1e9, 20*log10(abs(S21)), 'LineWidth', 1.5)
xlabel('Frequency (GHz)');
ylabel('|S21| [dB]');
grid on

subplot(2,1,2)
plot(freq/1e9, unwrap(angle(S21))*180/pi, 'LineWidth', 1.5)
xlabel('Frequency (GHz)');
ylabel('Phase [deg]');
grid on

dateStr = datestr(now,'yyyymmdd');
filename = sprintf("RES1_S21_%s.mat", dateStr);
save(filename, "freq", "S21");

S21 = apply_calibration(freq, S21, 1, struct());
S21_dB = 20*log10(abs(S21));

[fit_params, ~] = fit_resonance_circle(freq, S21, 'show_plot', 1);

figure('Name','Calibrated S21 (0 dB baseline)');
plot(freq/1e9, S21_dB, 'LineWidth', 1.5);
xlabel('Frequency (GHz)');
ylabel('|S21| [dB]');
grid on
title('Calibrated S21 (0 dB baseline)');

figure('Name','S21 Circle');
plot(real(S21), imag(S21), '.', 'MarkerSize', 15);
xlabel('Re(S21)');
ylabel('Im(S21)');
axis equal
grid on
title('Calibrated Resonator Circle');

Ql = 1 / (1/fit_params.Qi + 1/fit_params.Qc);

fprintf("\n===== Resonator Fit Results =====\n");
fprintf("f0  = %.6f GHz\n", fit_params.f0/1e9);
fprintf("Qi  = %.2e\n", fit_params.Qi);
fprintf("Qc  = %.2e\n", fit_params.Qc);
fprintf("Ql  = %.2e\n", Ql);
fprintf("phi = %.3f rad\n", fit_params.phi);

clear vna
