function S_DUT = calibrate2PortSParDUT(Sa, Sb, S_DUT_m)
%% calibrate2PortSParDUT use error boxes Sa and Sb to compute DUT S-parameters.
% The 8(7)-term error model is used. It can apply N error boxes to one DUT.
% Port n. 1 of error box A is connected to port 1 of VNA, port n. 2 to port n. 1
% of DUT. Port n. 1 of error box B is connected to port 2 of DUT and port 2 of B
% is connected to port 2 of VNA. It is necessary the DUT to have non-zero 
% transmission S21.
%
%  INPUTS
%   Sa, Sb: S-parameters of error boxes, double [2 x 2 x nFreq x N]
%   S_DUT_m: measured S-parameters (Sa - DUT - Sb),
%            double [2 x 2 x nFreq]
%
%  OUTPUTS
%   S_DUT: S-parameters of calibrated 2-port DUT, double [2 x 2 x nFreq x N]
%
% © 2019, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

%% Calibrating DUT
boxSize = size(Sa);
nElements = numel(Sa);

% replicate measured S parameters of DUT for simpler indexing
T_DUT_m = s2t(repmat(S_DUT_m, 1, 1, nElements/prod(boxSize(1:3))));
Ta = s2t(reshape(Sa, 2, 2, []));
Tb = s2t(reshape(Sb, 2, 2, []));
T_DUT = zeros(size(Ta), 'like', S_DUT_m);

for iSlice = 1:nElements/4
   T_DUT(:, :, iSlice) = Ta(:, :, iSlice)\T_DUT_m(:, :, iSlice)/Tb(:, :, iSlice);
end

S_DUT = t2s(reshape(T_DUT, boxSize));

end