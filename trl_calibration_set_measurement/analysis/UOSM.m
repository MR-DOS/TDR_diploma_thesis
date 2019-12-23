function [Ea, Eb] = UOSM(P1Meas, P2Meas, thruMeas, P1Model, P2Model, thruS21)
%% UOSM compute error model of 2-port VNA.
% Error boxes A and B are computed from OSM method. Additional transmission
% normalization of error box B is made in accordance to Thru measurement. It is
% assumed that port n. 1 of box A is connected to VNA, port n. 2 is connected to
% DTU Port n. 1 of box B is connected to DUT, port n. 2 is connected to VNA.
% NOTE:
% It is considered that match is ideal 0 reflection standard.
% This use only 7-term error model. We use just S21 of Thru stadard to compute
% error model. We assume to be Thru ideally matched.
% TODO: incorporate RRR calibration with known all three 1-port standards.
%
%  INPUTS
%   P1Meas: struct with fields:
%         .open: measurement of Open standard on port 1, double [nFreq x 1]
%         .short: measurement of Short standard on port 1, double [nFreq x 1]
%         .match: measurement of Match standard on port 1, double [nFreq x 1]
%   P2Meas: struct with fields:
%         .open: measurement of Open standard on port 2, double [nFreq x 1]
%         .short: measurement of Short standard on port 2, double [nFreq x 1]
%         .match: measurement of Match standard on port 2, double [nFreq x 1]
%   thruMeas: measurement of Thru standard, double [2 x 2 x nFreq]
%   P1Model: struct with fields:
%          .open: model of Open standard on port 1, double [nFreq x 1]
%          .short: model of Short standard on port 1, double [nFreq x 1]
%   P2Model: struct with fields:
%          .open: model of Open standard on port 2, double [nFreq x 1]
%          .short: model of Short standard on port 2, double [nFreq x 1]
%   thruS21: estimation of Thru standard transmission, double [nFreq x 1]
%
% implemented according to: Ferrero, A., Pisani, U.: Two-Port Network Analyzer
%                           Calibration Using an Unknown "Thru".
%
% © 2017, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

openP1Meas = P1Meas.open;
shortP1Meas = P1Meas.short;
matchP1Meas = P1Meas.match;

openP2Meas = P2Meas.open;
shortP2Meas = P2Meas.short;
matchP2Meas = P2Meas.match;

openP1Model = P1Model.open;
shortP1Model = P1Model.short;

openP2Model = P2Model.open;
shortP2Model = P2Model.short;

Ea = OSM(openP1Meas, shortP1Meas, matchP1Meas, openP1Model, shortP1Model);
Eb = OSM(openP2Meas, shortP2Meas, matchP2Meas, openP2Model, shortP2Model);
% switch port 1 and 2 of Eb error box
% port 1 of B is on DUT, port 2 on VNA
Eb11 = Eb(1, 1, :);
Eb21 = Eb(2, 1, :);
Eb(1, 1, :) = Eb(2, 2, :);
Eb(2, 2, :) = Eb11;
Eb(2, 1, :) = Eb(1, 2, :);
Eb(1, 2, :) = Eb21;

Ta = s2t(Ea);
Tb = s2t(Eb);

calibratedThruT = zeros(size(Ea));

nFreq = size(Ea, 3);

for iFreq = 1:nFreq
   calibratedThruT(:, :, iFreq) = Ta(:, :, iFreq)\s2t(thruMeas(:, :, iFreq))/Tb(:, :, iFreq);
end

alpha = reshape(thruS21, 1, 1, nFreq)./calibratedThruT(1, 1, :);
% alpha = conj(reshape(thruS21, 1, 1, nFreq))./calibratedThruT(2, 2, :);

% thruTransmisson = exp(-2*pi*1j*delay*freq);
% alpha = conj(reshape(thruTransmisson, 1, 1, nFreq))./calibratedThruT(2, 2, :);

Eb = t2s(Tb./repmat(alpha, 2, 2, 1));

end