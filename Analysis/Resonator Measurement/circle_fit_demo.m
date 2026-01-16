clear all
close all
clc

fitFuncFolder = 'C:\Niobium\Analysis\Common';
addpath(fitFuncFolder)

dummyFreq = 1;     % numeric dummy, just to satisfy parser
dummyData = 1;     % numeric dummy, just to satisfy parser

[fit_params, fit_errors] = fit_resonance_circle(dummyFreq, dummyData, 'demo', 1);

fprintf('\n===== Demo Resonator Fit Results =====\n');
fprintf('Resonant frequency f0 : %.6f GHz\n', fit_params.f0);
fprintf('Internal Q factor Qi : %.2e\n', fit_params.Qi);
fprintf('Coupling Q factor Qc : %.2e\n', fit_params.Qc);
fprintf('Impedance mismatch phi: %.3f rad\n', fit_params.phi);
