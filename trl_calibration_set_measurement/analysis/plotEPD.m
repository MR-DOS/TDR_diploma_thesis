function plotEPD(freq, EPD, tol)
% plotEPD plots Effective Phase Delayof tansmission lines.
%
%  INPUTS:
%   freq: frequency points, double [nFreq x 1]
%   EPD: Effective Phase Delay, double [nFreq x nLines]
%   tol: minimal value of EPD considered as useful, double [1 x 1], deg
%
% © 2019, Viktor Adler, CTU in Prague, adlervik@fel.cvut.cz

%%
nLines = size(EPD, 2);
isInTolerance = EPD >= tol;
% number of lines which are in tolerance
% values in inToleranceNum are number of line where it lies in tolerance and NaN
% otherwise
inToleranceNum = isInTolerance.*(1:nLines);
inToleranceNum(inToleranceNum == 0) = NaN;
% value of phase difference
% set NaN where it is outside the tolerance interval
inToleranceEPD = EPD;
inToleranceEPD(~isInTolerance) = NaN;

figure
subplot(3, 1, 1)
plot(freq/1e9, inToleranceEPD, 'LineWidth', 2)
grid on
title('Usable phase delay')
xlabel('f (GHz)')
ylabel('Phase Delay (deg)')

subplot(3, 1, 2)
plot(freq/1e9, inToleranceNum, 'LineWidth', 2)
grid on
ylim([1 nLines])
title(sprintf('Lie in interval <%d, %d> deg.', tol, 180-tol))
xlabel('f (GHz)')
ylabel('line n. (-)')

subplot(3, 1, 3)
plot(freq/1e9, EPD, 'LineWidth', 1, 'LineStyle', '--')
grid on
hold on
plot(freq/1e9, max(EPD, [], 2), 'k', 'LineWidth', 2)
title('Effective phase delay')
xlabel('f (GHz)')
ylabel('EPD (deg.)')

end