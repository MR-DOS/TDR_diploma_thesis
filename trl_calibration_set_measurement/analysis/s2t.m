function [T, isValid] = s2t(S)
%% s2t converts scattering parameters to transfer scattering parameters.
% Works for two ports only.
%
%  INPUTS
%   S: scattering parameters, complex duble [2 x 2 x N x ...]
%
%  OUTPUTS
%   T: scattering transfer parameters, complex duble [2 x 2 x N x ...]
%   isValid: state variable indicating presence of zero S21 transmission,
%            logical [1 x 1]
%
% © 2019, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

%% Validation
isValid = ~any(S(2, 1, :) == 0);

%% Allocation
T = zeros(size(S), 'like', S);

%% Conversion
T(1, 1, :) = S(1, 2,:) - S(1, 1, :).*S(2, 2, :)./S(2, 1, :);
T(1, 2, :) = S(1, 1, :)./S(2, 1, :);
T(2, 1, :) = -S(2, 2, :)./S(2, 1, :);
T(2, 2, :) = 1./S(2, 1, :);

end