function sqr = cSqrt(A)
%% cSqrt computes square root of complex number A.
% It preserve phase in interval (-180, 180] deg. Normal sqrt cut angle to
% interval (-pi/2, pi/2]. Be sure that the input signals with fast phase change have
% enough samples to correctly predict the unwraped phase.
% NOTE: this implementation pressumes that the phase of A starts from zero.
%
%  INPUTS
%   A: vector/matrix/multidim. array of complex numbers,
%      complex double [n1 x n2 x ... x nm]
%
%  OUTPUTS
%   sqr: square root of complex number with phase in [-180, 180] deg range,
%        double [n1 x n2 ... x nm]
%
% © 2019, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

sqr = sqrt(abs(A)).*exp(1j*unwrap(angle(A))./2);

end