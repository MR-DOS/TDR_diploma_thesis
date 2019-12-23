function [S, isValid] = t2s(T)
%% t2s converts transfer scattering parameters to scattering parameters.
% Works for two ports only.
%
%  INPUTS
%   T: scattering transfer parameters, complex duble [2 x 2 x N x ...]
%
%  OUTPUTS
%   S: scattering parameters, complex duble [2 x 2 x N x ...]
%   isValid: state variable indicating presence of zero S21 transmission,
%            logical [1 x 1]
%
% © 2019, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

%% Validation
isValid = ~any(T(2, 2, :) == 0);

%% Allocation
S = zeros(size(T), 'like', T);

%% Conversion
S(1, 1, :) = T(1, 2, :)./T(2, 2, :);
S(1, 2, :) = T(1, 1, :) - T(1, 2, :).*T(2, 1, :) ./T(2, 2, :);
S(2, 1, :) = 1./T(2, 2, :);
S(2, 2, :) = -T(2, 1, :) ./T(2, 2, :);
end