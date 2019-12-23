clear; close all; clc;
unwrap=0;
s11=read_touchstone("high.s1p");
s11.freq=s11.freq/1e9;

figure(1);
plot(s11.freq, 20*log(s11.mag),"linewidth",2);
xlim([0 s11.freq(end)]);
ylim([-60 0]);
xticks(0:5:18);
grid off;
grid minor on;
hold on;
plot(s11.freq, -10.*ones(1,length(s11.freq)),"linewidth",2);
xlabel("Frekvence (GHz)");
ylabel("Koeficient odrazu |S11| (dB)");

s11=read_touchstone("low.s1p");
s11.freq=s11.freq/1e9;
plot(s11.freq, 20*log(s11.mag),"linewidth",2);

saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/measurements/vna_high_low.eps','epsc');

figure(2);
s11=read_touchstone("low.s1p");
s11.freq=s11.freq/1e9;
plot(s11.freq, 20*log(s11.mag),"linewidth",2);
xlim([0 s11.freq(end)]);
ylim([-60 0]);
xticks(0:5:18);
grid off;
grid minor on;
hold on;

s11=read_touchstone("blank.s1p");
s11.freq=s11.freq/1e9;
plot(s11.freq, 20*log(s11.mag),"linewidth",2);

xlabel("Frekvence (GHz)");
ylabel("Koeficient odrazu |S11| (dB)");

saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/measurements/vna_low_blank.eps','epsc');
