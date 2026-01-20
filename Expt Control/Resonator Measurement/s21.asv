clear all;

vna = visadev("TCPIP0::169.254.54.30::inst0::INSTR");
vna.Timeout = 300;

writeline(vna, "*IDN?");
idn = readline(vna);
fprintf("Connected to: %s\n", idn);

fstart    = 4.015149e9;
fstop     = 4.015302e9;
numpoints = 501;
ifbw      = 10;
pow       = 10;

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
freq = str2double(split(readline(vna), ','));

writeline(vna, "FORM:DATA ASCII");
writeline(vna, "CALC1:PAR:SEL 'Trc1'");
writeline(vna, "CALC1:DATA? SDATA");

raw = str2double(split(readline(vna), ','));
S21 = raw(1:2:end) + 1j*raw(2:2:end);

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

clear vna
