function SInv = invSPar(S)
%% invSPar computes inverse S-matrix of circuit.
% It can be used for deembeding of a circuit from cascade of circuits.
%
%  INPUTS
%   S: S-parameters of circuit, double [2 x 2 x nFreq]
%
%  OUTPUTS
%   SInv: S-parameters of inverted circuit, double [2 x 2 x nFreq]
%
% � 2019, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

nFreq = size(S, 3);
SInv = zeros(size(S), typeinfo(S));

for iFreq = 1:nFreq
   SInv(:, :, iFreq) = [S(1, 1, iFreq) -S(2, 1, iFreq);
      -S(1, 2, iFreq) S(2, 2, iFreq)]/det(S(:, :, iFreq)); % Eq. (72)
end

end