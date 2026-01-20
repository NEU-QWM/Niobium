clear all; clc;

addpath('C:\Niobium\Analysis\Common');

vna = visadev("TCPIP0::169.254.54.30::inst0::INSTR");
vna.Timeout = 300;

writeline(vna, "*IDN?");
idn = readline(vna);
fprintf("Connected to: %s\n", idn);

f0_guess = 4.015225e9;
expected_Q = 1e5;
span = f0_guess / expected_Q * 5;  % sweep 5× linewidth
fstart = f0_guess - span/2;
fstop  = f0_guess + span/2;
numpoints = 501;
ifbw = 10;
pow = 10;
%test comment
% Configure VNA
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

% Read frequency points
writeline(vna, "CALC1:DATA:STIM?");
freq = str2double(split(readline(vna), ','))';
freq = freq(:)';  % ensure row vector

% Read S21 data
writeline(vna, "FORM:DATA ASCII");
writeline(vna, "CALC1:PAR:SEL 'Trc1'");
writeline(vna, "CALC1:DATA? SDATA");
raw = str2double(split(readline(vna), ','))';
S21 = raw(1:2:end) + 1j*raw(2:2:end);
S21 = S21(:)';  % ensure row vector

% Plot raw S21
figure('Name','Raw S21');
subplot(2,1,1)
plot(freq/1e9, 20*log10(abs(S21)),'LineWidth',1.5)
xlabel('Frequency (GHz)'); ylabel('|S21| [dB]');
grid on
subplot(2,1,2)
plot(freq/1e9, unwrap(angle(S21))*180/pi,'LineWidth',1.5)
xlabel('Frequency (GHz)'); ylabel('Phase [deg]');
grid on

% Save raw data
dateStr = datestr(now,'yyyymmdd');
filename = sprintf("RES1_S21_%s.mat", dateStr);
save(filename, "freq", "S21");

% --- Apply your separate calibration function ---
S21 = apply_calibration(freq, S21, 1, struct());
S21_dB = 20*log10(abs(S21));

% Fit resonance (gets Qi, Qc, f0, phi)
[fit_params, ~] = fit_resonance_circle(freq, S21, 'show_plot', 1);

% % --- Apply your separate calibration function ---
% S21_calibrated = apply_calibration(freq, S21, 1, struct());
% S21_cal_dB = 20*log10(abs(S21_calibrated));

% Plot calibrated S21
figure('Name','Calibrated S21 (0 dB baseline)');
plot(freq/1e9, S21_dB,'LineWidth',1.5);
xlabel('Frequency (GHz)');
ylabel('|S21| [dB]');
grid on;
title('Calibrated S21 (0 dB baseline)');

% Plot resonator circle
figure('Name','S21 Circle');
plot(real(S21), imag(S21), '.', 'MarkerSize', 15);
xlabel('Re(S21)'); ylabel('Im(S21)'); axis equal; grid on;
title('Calibrated Resonator Circle');

% Calculate loaded Q
Ql = 1 / (1/fit_params.Qi + 1/fit_params.Qc);

fprintf("\n===== Resonator Fit Results =====\n");
fprintf("f0  = %.6f GHz\n", fit_params.f0/1e9);
fprintf("Qi  = %.2e\n", fit_params.Qi);
fprintf("Qc  = %.2e\n", fit_params.Qc);
fprintf("Ql  = %.2e\n", Ql);
fprintf("phi = %.3f rad\n", fit_params.phi);

clear vna
