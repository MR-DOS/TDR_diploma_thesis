function [SaCal, SbCal, propConst] = TRL_SPar(SThruM, ...
   SLineM, SReflM, LLine, LThru, reflect)
%% TRL_SPar computes error boxes from measurement of TRL standards.
% It is also usable for LRL calibration when the Thru has non-zero length.
% This function implements computation of two two port error boxes of seven-term
% error model of a VNA. Port n. 1 of error box A is connected to port 1 of VNA,
% port n. 2 to port n. 1 of DUT. Port n. 1 of error box B is connected to port 2
% of DUT and port 2 of B is connected to port 2 of VNA.
% It is also possible to proceed TRM calibration when the SLineM input is
% replaced by Match measurement. Impedance of Match standard defines reference
% impedance. In TRM case the LLine has to be non zero and Thru has to have
% zero length. Propagation constant is not (properly) computed during calibration.
% Implemented according to J. Stenarson and K. Yhland, "A Reformulation and 
% Stability Study of TRL and LRM Using S -Parameters," in IEEE Transactions on
% Microwave Theory and Techniques, vol. 57, no. 11, pp. 2800-2807, Nov. 2009.
%
%  INPUTS
%   SThruM: measured THRU standard, double [2 x 2 x nFreq]
%   SLineM: measured LINE standard, or Match standard for TRM calibration, 
%           double [2 x 2 x nFreq]
%   SReflM: measured reflect standards, double [2 x 2 x nFreq]
%   LLine: physical length of LINE standard in m, in double [1 x 1]
%   LThru: physical length of THRU standard in m, double [1 x 1]
%   reflect: approximate reflection of reflect standard in reference plane.
%            -1 for short, +1 for open, double [1 x 1]
%            OR S-parameters of known reflects standard, double [nFreq x 1]
%
%  OUTPUTS
%   SaCal: S-parameters of Error box A, double [2 x 2 x nFreq]
%   SbCal: S-parameters of Error box B. Port 1 is on the left (reflect standard
%       connection), port 2 connected to VNA. Double [2 x 2 x nFreq]
%   propConst: propagation constant of LINE standard in form alpha + j*beta,
%              alpha-Attenuation const., beta-Phase const., double [nFreq x 1]
%
% © 2019, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

nFreq = size(SThruM, 3);

Sa = cascadeSPar(SLineM, invSPar(SThruM));
Sb = cascadeSPar(invSPar(SThruM), SLineM);

expMinus2gammaL = zeros(nFreq, 1, 'like', Sa);
detSt = zeros(nFreq, 1, 'like', Sa);
for iFreq = 1:nFreq
   detSa = det(Sa(:, :, iFreq));
   detSt(iFreq) = det(SThruM(:, :, iFreq));
   sqr = sqrt((1 - detSa)^2 - 4*Sa(1, 2, iFreq)*Sa(2, 1, iFreq));
   expMinus2gammaL(iFreq) = (1 - detSa - sqr)/(1 - detSa + sqr); % Eq. (14)
end

dL = LLine - LThru;

alphaProp = -log(abs(expMinus2gammaL))/(2*dL);
betaProp = -(unwrap(angle(expMinus2gammaL)))/(2*dL);

propConst = alphaProp + 1j*betaProp;

expMinusGammaL = exp(-propConst*dL);
% in case of LRL calibration the model of reflect standard has to be deembeded
% to the center of the Thru standard to properly choose root later
% S matrix of line with -LThru/2 length
shiftedReflect = exp(-propConst.*-LThru).*reflect;

E00 = squeeze(Sa(1, 1, :))./(1 - squeeze(Sa(1, 2, :)).*expMinusGammaL); % Eq. (22)
E33 = squeeze(Sb(2, 2, :))./(1 - squeeze(Sb(2, 1, :)).*expMinusGammaL); % Eq. (23)

deltaA = squeeze(Sa(2, 2, :))./(1 - squeeze(Sa(2, 1, :)).*expMinusGammaL); % Eq. (32)
deltaB = squeeze(Sb(1, 1, :))./(1 - squeeze(Sb(1, 2, :)).*expMinusGammaL); % Eq. (33)

GammaA = squeeze(SReflM(1, 1, :));
GammaB = squeeze(SReflM(2, 2, :));

numerator = (E00 - GammaA).*(E33 - GammaB);
denominator = (1 - deltaA.*GammaA).*(1 - deltaB.*GammaB);

GammaRefl1Ver1 = cSqrt((1 - deltaA.*squeeze(SThruM(1, 1, :))).*numerator./...
   (((E00.*squeeze(SThruM(2, 2, :))) - detSt).*denominator)); % Eq. (38)
GammaRefl1Both = GammaRefl1Ver1.*[1, -1];
[~, I1] = min(sum(abs(GammaRefl1Both - shiftedReflect)));
GammaRefl1 = GammaRefl1Both(:, I1);

GammaRefl2Ver1 = cSqrt((1 - deltaB.*squeeze(SThruM(2, 2, :))).*numerator./...
   (((E33.*squeeze(SThruM(1, 1, :))) - detSt).*denominator));  % Eq. (39)
GammaRefl2Both = GammaRefl2Ver1.*[1, -1];
[~, I2] = min(sum(abs(GammaRefl2Both - shiftedReflect)));
GammaRefl2 = GammaRefl2Both(:, I2);

% NOTE: in ideal case the GammaRefl1 and GammaRefl2 should be the same and its
% difference can be used to predict the quality of calibration.
GammaRefl = mean([GammaRefl1, GammaRefl2], 2);

detEa = (E00 - GammaA)./(GammaRefl.*(1 - GammaA.*deltaA));
detEb = (E33 - GammaB)./(GammaRefl.*(1 - GammaB.*deltaB));

E11 = deltaA.*detEa;
E22 = deltaB.*detEb;
E01E10 = E00.*E11 - detEa;
E23E32 = E22.*E33 - detEb;

E01 = cSqrt(E01E10);
E10 = E01;

E23 = (E00.*E33 - detEa.*detEb)./(detSt./squeeze(SThruM(2, 1, :)))./E01;
E32 = E23E32./E23;

SaCal = zeros(size(SThruM), 'like', SThruM);
SaCal(1, 1, :) = E00;
SaCal(2, 2, :) = E11;
SaCal(2, 1, :) = E10;
SaCal(1, 2, :) = E01;

SbCal = zeros(size(SThruM), 'like', SThruM);
SbCal(1, 1, :) = E22;
SbCal(2, 2, :) = E33;
SbCal(2, 1, :) = E32;
SbCal(1, 2, :) = E23;

% LRL case when the Thru has non-zero length
% deembeding of the line with the length LThru/2
if LThru ~= 0
   SLine = zeros(size(SThruM), 'like', SThruM);
   SLine(1, 1, :) = 0;
   SLine(2, 2, :) = 0;
   halfThruTransmission = exp(-propConst*LThru/2);
   SLine(2, 1, :) = halfThruTransmission;
   SLine(1, 2, :) = halfThruTransmission;
   
   SLineInv = invSPar(SLine);
   SaCal = cascadeSPar(SaCal, SLineInv);
   SbCal = cascadeSPar(SLineInv, SbCal);
end

end