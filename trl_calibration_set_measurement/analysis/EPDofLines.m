function EPD = EPDofLines(lineLengths, freq, phaseConst0, f0)
%% EPDofLines computes effective phase delay of line(s).
%
%  INPUTS:
%   lineLengths: row vector with lengths of lines, double [1 x nLines]
%   freq: column vector with frequency points, double [nFreq x 1]
%   phaseConst0: phase constant of lines (all lines has the same), double
%                [1 x 1], in deg/m
%   f0: frequency where the phaseConst0 holds, double [1 x 1]
%
%  OUTPUTS:
%   EPD - effective phase delay of lines, double [nFreq x nLines]
%
% © 2019, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

%%
phaseConst = phaseConst0/f0*freq;
% compute electrical length of all lines at all frequencies
% assumptions of nondispersive lines
electricalLengths = phaseConst.*lineLengths;
% set to range <-180, 180>deg
electricalLengths = angle(exp(1j*electricalLengths/180*pi))/pi*180;
% compute EPD
EPD = abs(electricalLengths);
EPD(EPD > 90) = -EPD(EPD > 90) + 180;
end