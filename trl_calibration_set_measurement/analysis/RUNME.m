clear
close all
clc

%% constants
% length of lines
L1 = 8e-3;
L2 = 50e-3;
L3 = 69.8e-3;
% model of reflects
shortModel = -1;
openModel = 1;

phaseConst0 = 22449.5;
f0 = 10e9;

% folderName = '191206 - Mereni_SMA';
folderName = '191206 - Mereni_Southwest';

%% load S parameters
[freq, SThru] = SXPParse(fullfile(folderName, 'thru.s2p'));
[~, SShort] = SXPParse(fullfile(folderName, 'short.s2p'));
[~, SLine1] = SXPParse(fullfile(folderName, 'line_8mm.s2p'));
[~, SLine2] = SXPParse(fullfile(folderName, 'line_50mm.s2p'));
[~, SLine3] = SXPParse(fullfile(folderName, 'line_70mm.s2p'));
[~, SMatch] = SXPParse(fullfile(folderName, 'match.s2p'));
[~, SOpen] = SXPParse(fullfile(folderName, 'open.s2p'));

freq = freq.';

%% calibration
[SaCal1, SbCal1, propConst1] = TRL_SPar(SThru, ...
   SLine1, SShort, L1, 0, shortModel);

[SaCal2, SbCal2, propConst2] = TRL_SPar(SThru, ...
   SLine2, SShort, L2, 0, shortModel);

[SaCal3, SbCal3, propConst3] = TRL_SPar(SThru, ...
   SLine3, SShort, L3, 0, shortModel);
% multile TRL (utilize combination L1-L2, L1-L3, L2-L3)
[SaCal12, SbCal12, propConst12] = TRL_SPar(SLine1, ...
   SLine2, SShort, L2, L1, shortModel);

[SaCal13, SbCal13, propConst13] = TRL_SPar(SLine1, ...
   SLine3, SShort, L3, L1, shortModel);

[SaCal23, SbCal23, propConst23] = TRL_SPar(SLine2, ...
   SLine3, SShort, L3, L2, shortModel);

allPropConst = [propConst1, propConst2, propConst3, propConst12, propConst13, propConst23];
allSa = cat(4, SaCal1, SaCal2, SaCal3, SaCal12, SaCal13, SaCal23);
allSb = cat(4, SbCal1, SbCal2, SbCal3, SbCal12, SbCal13, SbCal23);
%% weighted mean of error boxes

% compute Effective Phase Delay
EPD = EPDofLines([L1, L2, L3, L2-L1, L3-L1, L3-L2], freq, phaseConst0, f0);

% compute weighted error boxes
Sa = computeWeightedMean(allSa, EPD);
Sb = computeWeightedMean(allSb, EPD);

%% weighted mean of propagation constant
propConst = sum(allPropConst.*EPD, 2)./sum(EPD, 2);

%% calibrate measured S-parameters of 69.8mm Line

SLine3Cal = calibrate2PortSParDUT(Sa, Sb, SLine3);

%% export S-parameters of 69.8mm Line
% skip first point because of faulty data
% set zero reflections and unitary transmission (to not extract substrate losses)
SLine3Export = SLine3Cal(:, :, 2:end);
SLine3Export(1, 1, :) = 0;
SLine3Export(2, 2, :) = 0;
SLine3Export(2, 1, :) = exp(1j*angle(SLine3Export(2, 1, :)));
SLine3Export(1, 2, :) = SLine3Export(2, 1, :);

% SXPWrite(freq(2:end), SLine3Export, 'Line3.s2p');

%% TRM calibration
[SaTRM, SbTRM, propConstTRM] = TRL_SPar(SThru, ...
   SMatch, SShort, L1, 0, shortModel);

SLine3CalTRM = calibrate2PortSParDUT(SaTRM, SbTRM, SLine3);

%% UOSM calibration
P1Meas = struct('open', squeeze(SOpen(1, 1, :)), ...
   'short', squeeze(SShort(1, 1, :)), ...
   'match', squeeze(SMatch(1, 1, :)));
P2Meas = struct('open', squeeze(SOpen(2, 2, :)), ...
   'short', squeeze(SShort(2, 2, :)), ...
   'match', squeeze(SMatch(2, 2, :)));
P1Model = struct('open', ones(size(freq)), ...
   'short', -ones(size(freq)));
P2Model = P1Model;
thruS21Model = ones(size(freq));

[SaUOSM, SbUOSM] = UOSM(P1Meas, P2Meas, SThru, P1Model, P2Model, thruS21Model);

SLine3CalUOSM = calibrate2PortSParDUT(SaUOSM, SbUOSM, SLine3);
%% figures
figure
showXPortParameters(repmat({freq}, 1, 4), {SThru, SLine1, SLine2, SLine3}, ...
   'ShowLegend', false, 'LineStyle', repmat({'-'}, 1, 4), ...
   'Title', 'Thru and Lines (meas.)')

figure
showXPortParameters({freq, freq}, {SShort, SOpen}, ...
   'Title', 'Short and Open (meas.)', ...
   'LegendText', {'Short', 'Open'})

figure
showXPortParameters({freq}, {SMatch}, 'Title', 'Match (meas.)')

figure
showXPortParameters(repmat({freq}, 1, 7), ...
   {SaCal1, SaCal2, SaCal3, SaCal12, SaCal13, SaCal23, Sa}, ...
   'Title', 'Error boxes A from all Lines', ...
   'LegendText', {'8mm', '50mm', '70mm', '1-2', '1-3', '2-3', 'mean'}, ...
   'LineStyle', {'--', '--', '--', '--', '--', '--', '-'}, ...
   'LineWidth', [1 1 1 1 1 1 2])

figure
showXPortParameters(repmat({freq}, 1, 7), ...
   {SbCal1, SbCal2, SbCal3, SbCal12, SbCal13, SbCal23, Sb}, ...
   'Title', 'Error boxes B from all Lines', ...
   'LegendText', {'8mm', '50mm', '70mm', '1-2', '1-3', '2-3', 'mean'}, ...
   'LineStyle', {'--', '--', '--', '--', '--', '--', '-'}, ...
   'LineWidth', [1 1 1 1 1 1 2])

plotEPD(freq, EPD, 20)

figure
yyaxis left
plot(freq/1e9, real(allPropConst), 'Marker', 'none')
hold on
plot(freq/1e9, real(propConst), '-', 'LineWidth', 2, 'Marker', 'none')
xlabel('freq (GHz)')
ylabel('\alpha (Attenuation constant, -)')
yyaxis right
plot(freq/1e9, imag(allPropConst), 'Marker', 'none')
hold on
plot(freq/1e9, imag(propConst), '-', 'LineWidth', 2, 'Marker', 'none')
ylabel('\beta (Phase constant, rad/m)')
legend('8mm', '50mm', '70mm', '1-2', '1-3', '2-3', 'mean', 'Location', 'west')
title('Propagation constant')
grid on

figure
showXPortParameters({freq, freq}, {Sa, Sb}, 'Title', 'Mean error boxes A, B')

figure
showXPortParameters({freq, freq, freq}, {Sa, SaTRM, SaUOSM}, ...
   'Title', 'Error box A from TRL, TRM and UOSM', ...
   'LegendText', {'TRL', 'TRM', 'UOSM'}, ...
   'LineStyle', {'-', '-', '-'})

figure
showXPortParameters({freq, freq, freq}, {Sb, SbTRM, SbUOSM}, ...
   'Title', 'Error box B from TRL, TRM and UOSM', ...
   'LegendText', {'TRL', 'TRM', 'UOSM'}, ...
   'LineStyle', {'-', '-', '-'})

figure
showXPortParameters({freq, freq, freq}, {SLine3CalTRM, SLine3Cal, SLine3CalUOSM}, ...
   'Title', 'Calibrated Line 69.8mm with TRL, TRM and UOSM', ...
   'LegendText', {'TRL', 'TRM', 'UOSM'}, ...
   'LineStyle', {'-', '-', '-'})