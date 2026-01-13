% connect to Rohde & Schwarz ZNB3020
% 169.254.54.30

function [spec] = GetVNASpec()
    % connect to Rohde & Schwarz ZNB3020
    % 169.254.54.30
    vna = visadev("TCPIP0::169.254.54.30::inst0::INSTR");

    writeline(vna, "*IDN?");
    idn = readline(vna);
    fprintf("%s\n", idn)

    % close connection
    delete(vna);
    clear("vna");
end
