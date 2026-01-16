clear all;

vna = visadev("TCPIP0::169.254.54.30::inst0::INSTR");

writeline(vna, "*IDN?");
idn = readline(vna);
fprintf("%s\n", idn)


