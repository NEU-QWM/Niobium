classdef ZNB3020 < handle
    % Copyright 2026 Northeastern University
    %
    % Licensed under the Apache License, Version 2.0 (the "License");
    % you may not use this file except in compliance with the License.
    % You may obtain a copy of the License at
    %
    %     http://www.apache.org/licenses/LICENSE-2.0
    %
    % Unless required by applicable law or agreed to in writing, software
    % distributed under the License is distributed on an "AS IS" BASIS,
    % WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    % See the License for the specific language governing permissions and
    % limitations under the License.
    %
    % Author: Gun Suer (suer.g@northeastern.edu)
    % Affiliation: Northeastern University, Quantum Wave-Matter Group
    %
    % Description:
    %   Instrument driver for the Rohde & Schwarz ZNB3020 Vector Network Analyzer.


    properties
        visaObj
        timeout = 3000;   % ms
    end

    methods
        %% Constructor
        function obj = ZNB3020(resourceString)
            obj.visaObj = visadev(resourceString);
            obj.visaObj.Timeout = obj.timeout;

            obj.write("*IDN?");
            idn = obj.read();
            fprintf("Connected to: %s\n", idn);
        end

        %% Low-level VISA helpers
        function write(obj, cmd)
            writeline(obj.visaObj, cmd);
        end

        function out = read(obj)
            out = readline(obj.visaObj);
        end

        %% Preset / reset
        function preset(obj)
            obj.write("*RST");
            obj.write("SYST:PRES");
            obj.write("*CLS");
        end

        %% Configure an S21 sweep
        function configureS21Sweep(obj, fstart, fstop, numpoints, ifbw, power)
            % Display & trace
            obj.write("DISP:WIND1:STAT ON");
            obj.write("DISP:WIND1:TRAC1:DEL:ALL");
            obj.write("CALC1:PAR:DEF 'Trc1','S21'");
            obj.write("DISP:WIND1:TRAC1:FEED 'Trc1'");
            obj.write("CALC1:PAR:SEL 'Trc1'");

            % Sweep settings
            obj.write(sprintf("SENS1:FREQ:STAR %e", fstart));
            obj.write(sprintf("SENS1:FREQ:STOP %e", fstop));
            obj.write(sprintf("SENS1:SWE:POIN %d", numpoints));
            obj.write(sprintf("SENS1:BWID %e", ifbw));
            obj.write(sprintf("SOUR1:POW %f", power));

            % Single sweep mode
            obj.write("INIT1:CONT OFF");
        end

        %% Trigger sweep and wait
        function trigger(obj)
            obj.write("INIT1:IMM");
            obj.write("*OPC?");
            obj.read();
        end

        %% Read frequency axis
        function freq = readFrequency(obj)
            obj.write("CALC1:DATA:STIM?");
            freq = str2double(split(obj.read(), ','))';
            freq = freq(:)';  % row vector
        end

        %% Read complex S21
        function S21 = readS21(obj)
            obj.write("FORM:DATA ASCII");
            obj.write("CALC1:PAR:SEL 'Trc1'");
            obj.write("CALC1:DATA? SDATA");

            raw = str2double(split(obj.read(), ','))';
            S21 = raw(1:2:end) + 1j*raw(2:2:end);
            S21 = S21(:)';  % row vector
        end

        %% High-level measurement
        function [freq, S21] = measureS21(obj)
            obj.trigger();
            freq = obj.readFrequency();
            S21  = obj.readS21();
        end

        %% Destructor
        function delete(obj)
            try
                clear obj.visaObj
            catch
            end
        end
    end
end
