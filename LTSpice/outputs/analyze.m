clear; close all; clc;
unwrap=0;
s=read_touchstone("input_reflection.txt");
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
saveas(gca, '/home/msboss/Documents/diplomova_prace/LTSpice/outputs/input_reflection.eps','epsc');
%saveas(gca, '/home/msboss/Documents/ant/s11.png','png');
%plotyy(s11.freq,s11.mag,s11.freq,s11.ph,@plot);

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

