function SMean = computeWeightedMean(S, weights)
%% computeWeightedMean compute weighted mean of complex S-parameters.
%
%  INPUTS
%   S: N-port S-parameters, double [N x N x nFreq x nMeas]
%   weights: weigts for mean. One mean per one frequency point and measurement, 
%            double [nFreq x nMeas]
%
%  OUTPUTS
%   SMean: weighted mean of S-parameters acros measurements, double [2 x 2 x nFreq]
%
%  NOTE
%   When all weights for some frequency are all zero, output is NaN.
%
% © 2017, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

repWeights = zeros([1, 1, size(weights)]);
repWeights(1, 1, :, :) = weights;

SMean = sum(S.*repWeights, 4)./sum(repWeights, 4);

end