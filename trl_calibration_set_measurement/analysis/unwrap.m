function unwrappedPhase = unwrap(inPhase)
%% unwrap input phase if there are steps larger than pi.
% The unwrapping will be performed along the first nonsingleton dimension. The
% singleton dimensions are removed. Steps larger than pi are removed by adding
% of multiplies of +-2pi.
%
%  INPUTS
%   inPhase: input phase in radians, double [n1 x n2 x ... x nm]
%
%  OUTPUTS
%   unwrappedPhase: unwrapepd phase, double [n1 x n2 x ... x nm]
%
% © 2019, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

%% Squeeze the input phase multidim. array
inPhase = squeeze(inPhase);

%% Size of input array
inSize = size(inPhase);
nElements = prod(inSize);

%% Reshape input multidim. array
inPhase = reshape(inPhase, inSize(1), []);

%% Unwrapping
diffPhase = [zeros(1, nElements/inSize(1)); diff(inPhase)];
logIndStep = abs(diffPhase) > pi;
stepSign = zeros(size(inPhase));
stepSign(logIndStep) = sign(diffPhase(logIndStep));
phaseCorrection = cumsum(-2*pi*stepSign);

unwrappedPhase = reshape(inPhase + phaseCorrection, inSize);
end