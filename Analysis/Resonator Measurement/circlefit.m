clear all;

addpath("C:\Niobium\Analysis\Common");

dataFile = 'RES1_S21_20260116.mat';  % Change to your actual filename
load(dataFile, 'freq', 'S21');

[fit_params, ~] = fit_resonance_circle(freq, S21, 'show_plot', 1);

Ql = 1 / (1/fit_params.Qi + 1/fit_params.Qc);

fprintf("\n===== Resonator Fit Results =====\n");
fprintf("Resonant frequency f0  = %.6f GHz\n", fit_params.f0/1e9);
fprintf("Internal Q (Qi)        = %.2e\n", fit_params.Qi);
fprintf("Coupling Q (Qc)        = %.2e\n", fit_params.Qc);
fprintf("Loaded Q (Ql)          = %.2e\n", Ql);
fprintf("Impedance mismatch phi = %.3f rad\n", fit_params.phi);
