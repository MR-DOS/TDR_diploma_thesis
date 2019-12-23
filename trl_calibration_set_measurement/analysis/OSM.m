function E = OSM(openMeas, shortMeas, matchMeas, openModel, shortModel)
%% OSM computes error box of 1-port vector measuremet.
% Error box E is two-port circuit, where on the port n. 1 is connected VNA, on
% the port n. 2 DUT is connected.
% NOTE: Match is concerned as ideal 0 reflection!
%
%  INPUTS
%   openMeas: measured S-parameters of Open standard, double [nFreq x 1]
%   shortMeas: measured S-parameters of Short standard, double [nFreq x 1]
%   matchMeas: measured S-parameters of Match standard, double [nFreq x 1]
%   openModel: S-parameters of Open standard in reference plane,
%              double [nFreq x 1], or double [1 x 1]
%   shortModel: S-parameters of Short standard in reference plane,
%              double [nFreq x 1], or double [1 x 1]
%
%  OUTPUTS
%   E: S-parameters of error two-port circuit, S12==S21, double [2 x 2 x nFreq]
%
% implemented according to: Hiebel, M.: Fundamentals of Vector Network Analysis
%
% © 2017, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

nFreq = size(openMeas, 1);
E = zeros(2, 2, nFreq);

E(1, 1, :) = matchMeas;
E(2, 2, :) = (shortModel.*(openMeas - matchMeas) - openModel.*(shortMeas - matchMeas))./...
   (openModel.*shortModel.*(openMeas - shortMeas));

% reciprocal
E(2, 1, :) = cSqrt((openModel - shortModel).*(openMeas - matchMeas).*(shortMeas - matchMeas)./...
   (openModel.*shortModel.*(openMeas - shortMeas)));
E(1, 2, :) = E(2, 1, :);

% no reciprocal
% E(2, 1, :) = ((openModel - shortModel).*(openMeas - matchMeas).*(shortMeas - matchMeas))./...
%    (openModel.*shortModel.*(openMeas - shortMeas));
% E(1, 2, :) = 1;

end