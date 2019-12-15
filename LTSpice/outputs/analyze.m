clear; close all; clc;
unwrap=0;
s=read_touchstone("input_reflection.txt");
s.freq=s.freq;
%graphics_toolkit qt;

if (unwrap==1)
  for j=2:length(s.s11.ph)
    if ((s.s11.ph(j)-s.s11.ph(j-1))>300)
      s.s11.ph(j:length(s.s11.ph))=s.s11.ph(j:length(s.s11.ph))-360; 
    endif
    
    if ((s.s11.ph(j)-s.s11.ph(j-1))<-300)
      s.s11.ph(j:length(s.s11.ph))=s.s11.ph(j:length(s.s11.ph))+360;   
    endif  
  endfor
endif

figure(1);
[ax,h1,h2]=plotyy(s.freq, s.s11.mag, s.freq, s.s11.ph, @semilogx, @semilogx);
xlim([s.freq(1) s.freq(end)]);
grid off;
grid minor on;
hold on;
hold off;
xlabel("Frekvence (Hz)");
set(h1,"linewidth",2);
set(h2,"linewidth",2);
ylabel(ax(1),"|S11| (dB)");
ylabel(ax(2),"arg(S11) (deg)");
ylim(ax(2), [-180 180]);
yticks(ax(2), -180:30:180);
saveas(gca, '/home/msboss/Documents/diplomova_prace/LTSpice/outputs/input_reflection.eps','epsc');
%saveas(gca, '/home/msboss/Documents/ant/s11.png','png');
%plotyy(s11.freq,s11.mag,s11.freq,s11.ph,@plot);

%------------------------------------------------------------------------------%

s=read_touchstone("input_impedance.txt");
s.freq=s.freq;

if (unwrap==1)
  for j=2:length(s.s11.ph)
    if ((s.s11.ph(j)-s.s11.ph(j-1))>300)
      s.s11.ph(j:length(s.s11.ph))=s.s11.ph(j:length(s.s11.ph))-360; 
    endif
    
    if ((s.s11.ph(j)-s.s11.ph(j-1))<-300)
      s.s11.ph(j:length(s.s11.ph))=s.s11.ph(j:length(s.s11.ph))+360;   
    endif  
  endfor
endif

figure(2);
[ax,h1,h2]=plotyy(s.freq, 10.^(s.s11.mag/20), s.freq, s.s11.ph, @semilogx, @semilogx);
xlim([s.freq(1) s.freq(end)]);
grid off;
grid minor on;
hold on;
hold off;
xlabel("Frekvence (Hz)");
set(h1,"linewidth",2);
set(h2,"linewidth",2);
ylim(ax(1), [48 52]);
ylim(ax(2), [-3 3]);
ylabel(ax(1),"|Z| (Ohm)");
ylabel(ax(2),"arg(Z) (deg)");
saveas(gca, '/home/msboss/Documents/diplomova_prace/LTSpice/outputs/input_impedance.eps','epsc');
%saveas(gca, '/home/msboss/Documents/ant/s11.png','png');
%plotyy(s11.freq,s11.mag,s11.freq,s11.ph,@plot);

%------------------------------------------------------------------------------%

s=read_touchstone("transfer_characteristic.txt");

figure(3);
p=polyfit(s.voltage2,s.voltage1,2);
poly_data=s.voltage1-s.voltage2.*p(2)-p(3);
ax=plot(s.voltage2,-1e6*(poly_data-max(poly_data)));
xlim([-0.05 0.05]);
ylim([0 0.3]);

grid off;
grid minor on;
xlabel("Vstupni napeti (V)");
set(ax,"linewidth",2);
ylabel("Chyba vystupniho napeti (uV)");
saveas(gca, '/home/msboss/Documents/diplomova_prace/LTSpice/outputs/transfer_characteristic.eps','epsc');
%saveas(gca, '/home/msboss/Documents/ant/s11.png','png');
%plotyy(s11.freq,s11.mag,s11.freq,s11.ph,@plot);

%------------------------------------------------------------------------------%

s=read_touchstone("frequency_transfer_function_BF.txt");

figure(4);
[ax,h1,h2]=plotyy(s.freq, s.s11.mag, s.freq, s.s11.ph, @semilogx, @semilogx);
xlim([s.freq(1) s.freq(end)]);
grid off;
grid minor on;
hold on;
hold off;
xlabel("Frekvence (Hz)");
set(h1,"linewidth",2);
set(h2,"linewidth",2);
%ylim(ax(1), [48 52]);
ylim(ax(2), [-90 90]);
yticks(ax(2), -90:10:90);
ylabel(ax(1),"Prenos (dB)");
ylabel(ax(2),"Faze prenosu (deg)");
saveas(gca, '/home/msboss/Documents/diplomova_prace/LTSpice/outputs/frequency_transfer_function_BF.eps','epsc');
%saveas(gca, '/home/msboss/Documents/ant/s11.png','png');
%plotyy(s11.freq,s11.mag,s11.freq,s11.ph,@plot);

%------------------------------------------------------------------------------%

s=read_touchstone("frequency_transfer_function_all.txt");

unwrap=1;
if (unwrap==1)
  for j=2:length(s.s11.ph)
    if ((s.s11.ph(j)-s.s11.ph(j-1))>300)
      s.s11.ph(j:length(s.s11.ph))=s.s11.ph(j:length(s.s11.ph))-360; 
    endif
    
    if ((s.s11.ph(j)-s.s11.ph(j-1))<-300)
      s.s11.ph(j:length(s.s11.ph))=s.s11.ph(j:length(s.s11.ph))+360;   
    endif  
  endfor
endif

figure(5);
[ax,h1,h2]=plotyy(s.freq, s.s11.mag, s.freq, s.s11.ph, @semilogx, @semilogx);
xlim([s.freq(1) s.freq(end)]);
grid off;
grid minor on;
hold on;
hold off;
xlabel("Frekvence (Hz)");
set(h1,"linewidth",2);
set(h2,"linewidth",2);
%ylim(ax(1), [48 52]);
%ylim(ax(2), [-180 180]);
%yticks(ax(2), -180:20:180);
ylabel(ax(1),"Prenos (dB)");
ylabel(ax(2),"Faze prenosu (deg)");
saveas(gca, '/home/msboss/Documents/diplomova_prace/LTSpice/outputs/frequency_transfer_function_all.eps','epsc');
%saveas(gca, '/home/msboss/Documents/ant/s11.png','png');
%plotyy(s11.freq,s11.mag,s11.freq,s11.ph,@plot);

%------------------------------------------------------------------------------%

s=read_touchstone("denoiser_positive.txt");
figure(6);
h1=semilogx(s.freq, s.s11.mag);
hold on;
set(h1,"linewidth",2);
s=read_touchstone("denoiser_negative.txt");
h2=semilogx(s.freq, s.s11.mag);
hold off;
xlim([s.freq(1) s.freq(end)]);
grid off;
grid minor on;
hold on;
hold off;
xlabel("Frekvence (Hz)");

set(h2,"linewidth",2);
%ylim(ax(1), [48 52]);
%ylim(ax(2), [-180 180]);
%yticks(ax(2), -180:20:180);
ylabel("Prenos (dB)");
saveas(gca, '/home/msboss/Documents/diplomova_prace/LTSpice/outputs/denoiser_transfer_function.eps','epsc');
%saveas(gca, '/home/msboss/Documents/ant/s11.png','png');
%plotyy(s11.freq,s11.mag,s11.freq,s11.ph,@plot);