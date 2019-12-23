function SCasc = cascadeSPar(Sa, Sb)
%% cascadeSPar compute S-parameters of two cascaded S-parameter boxes.
% It is useful for computing cascade of circuits with zero transmission, which
% cant be expresses using T-parameters.
% Implemented according to J. Stenarson and K. Yhland, "A Reformulation and 
% Stability Study of TRL and LRM Using $S$ -Parameters," in IEEE Transactions on
% Microwave Theory and Techniques, vol. 57, no. 11, pp. 2800-2807, Nov. 2009.
%
%  INPUTS
%   Sa, Sb: S-parameters of individual circuits, double [2 x 2 x nFreq]
%
%  OUTPUTS
%   SCasc: S-parameters of cascade of two circuits, double [2 x 2 x nFreq]
%
% © 2019, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

nFreq = size(Sa, 3);
SCasc = zeros(size(Sa), 'like', Sa);

for iFreq = 1:nFreq
   detSa = det(Sa(:, :, iFreq));
   detSb = det(Sb(:, :, iFreq));
   SCasc(:, :, iFreq) = ...
      [Sa(1, 1, iFreq) - Sb(1, 1, iFreq)*detSa Sa(1, 2, iFreq)*Sb(1, 2, iFreq);
      Sa(2, 1, iFreq)*Sb(2, 1, iFreq) Sb(2, 2, iFreq) - Sa(2, 2, iFreq)*detSb]...
      /(1 - Sa(2, 2, iFreq)*Sb(1, 1, iFreq)); % Eq. (71)
end
end