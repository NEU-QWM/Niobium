% connect to Rohde & Schwarz ZNB3020
% 169.254.54.30
ZNB3020 = visadev("TCPIP0::169.254.54.30::inst0::INSTR");

writeline(ZNB3020, "*IDN?");
idn = readline(ZNB3020);
fprintf("%s\n", idn)

% close connection
delete(ZNB3020);
clear("ZNB3020");