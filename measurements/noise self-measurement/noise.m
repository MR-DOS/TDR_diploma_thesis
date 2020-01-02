close all; clear all;
open_avg(1)=load('open_avg1.dat','decoded_data');
open_avg(2)=load('open_avg2.dat','decoded_data');
open_avg(3)=load('open_avg4.dat','decoded_data');
open_avg(4)=load('open_avg8.dat','decoded_data');
open_avg(5)=load('open_avg16.dat','decoded_data');
open_avg(6)=load('open_avg32.dat','decoded_data');
open_avg(7)=load('open_avg64.dat','decoded_data');

load_avg(1)=load('load_avg1.dat','decoded_data');
load_avg(2)=load('load_avg2.dat','decoded_data');
load_avg(3)=load('load_avg4.dat','decoded_data');
load_avg(4)=load('load_avg8.dat','decoded_data');
load_avg(5)=load('load_avg16.dat','decoded_data');
load_avg(6)=load('load_avg32.dat','decoded_data');
load_avg(7)=load('load_avg64.dat','decoded_data');

time=1E12*(46*128/(24*25000000))*(1/(1+24*50000/24))*(0:4095);

open_avg_bkp=open_avg;

for i=1:7
  open_avg(i).decoded_data=open_avg(i).decoded_data-load_avg(7).decoded_data;
endfor
  
figure(1);
plot(time,open_avg(1).decoded_data-0.25*1);
hold on;
plot(time(1+128*1:end),open_avg(2).decoded_data(1:end-128*1)-0.25*2);
plot(time(1+128*2:end),open_avg(3).decoded_data(1:end-128*2)-0.25*3);
plot(time(1+128*3:end),open_avg(4).decoded_data(1:end-128*3)-0.25*4);
plot(time(1+128*4:end),open_avg(5).decoded_data(1:end-128*4)-0.25*5);
plot(time(1+128*5:end),open_avg(6).decoded_data(1:end-128*5)-0.25*6);
plot(time(1+128*6:end),open_avg(7).decoded_data(1:end-128*6)-0.25*7);

xlim([time(1) time(end)]);
xticks([]);
yticks([]);
legend({"1x prumerovano","2x prumerovano","4x prumerovano","8x prumerovano","16x prumerovano","32x prumerovano","64x prumerovano"},"location","southeast");

saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/noise_cal_comparison.eps','epsc');

figure();
plot(time,open_avg_bkp(1).decoded_data-0.25*1);
hold on;
plot(time(1+128*1:end),open_avg_bkp(2).decoded_data(1:end-128*1)-0.25*2);
plot(time(1+128*2:end),open_avg_bkp(3).decoded_data(1:end-128*2)-0.25*3);
plot(time(1+128*3:end),open_avg_bkp(4).decoded_data(1:end-128*3)-0.25*4);
plot(time(1+128*4:end),open_avg_bkp(5).decoded_data(1:end-128*4)-0.25*5);
plot(time(1+128*5:end),open_avg_bkp(6).decoded_data(1:end-128*5)-0.25*6);
plot(time(1+128*6:end),open_avg_bkp(7).decoded_data(1:end-128*6)-0.25*7);

xlim([time(1) time(end)]);
xticks([]);
yticks([]);
ylim([-1.75 1.25]);
legend({"1x prumerovano","2x prumerovano","4x prumerovano","8x prumerovano","16x prumerovano","32x prumerovano","64x prumerovano"},"location","southeast");

saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/noise_raw_comparison.eps','epsc');

open_spectrum=[fft(open_avg(1).decoded_data);fft(open_avg(2).decoded_data);fft(open_avg(3).decoded_data);fft(open_avg(4).decoded_data);fft(open_avg(5).decoded_data);fft(open_avg(6).decoded_data);fft(open_avg(7).decoded_data)];
open_spectrum=20*log(abs(open_spectrum/4096));
open_spectrum=open_spectrum(:,1:2049);

Fs=1/((time(2)-time(1))*1E-12);
f=Fs*(0:2048)/4096/1E9;

figure();
plot(f, open_spectrum(1,:));
xlim([f(1) f(end)]);
hold on;
grid off;
grid minor on;
xlabel("Frekvence (GHz)");
ylabel("Amplituda (a.u.)");
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/noise_cal_avg1.eps','epsc');

while(0)
    figure();
    plot(f, open_spectrum(2,:));
    xlim([f(1) f(end)]);
    hold on;
    grid off;
    grid minor on;
    xlabel("Frekvence (GHz)");
    ylabel("Amplituda (a.u.)");

    figure();
    plot(f, open_spectrum(3,:));
    xlim([f(1) f(end)]);
    hold on;
    grid off;
    grid minor on;
    xlabel("Frekvence (GHz)");
    ylabel("Amplituda (a.u.)");

    figure();
    plot(f, open_spectrum(4,:));
    xlim([f(1) f(end)]);
    hold on;
    grid off;
    grid minor on;
    xlabel("Frekvence (GHz)");
    ylabel("Amplituda (a.u.)");

    figure();
    plot(f, open_spectrum(5,:));
    xlim([f(1) f(end)]);
    hold on;
    grid off;
    grid minor on;
    xlabel("Frekvence (GHz)");
    ylabel("Amplituda (a.u.)");

    figure();
    plot(f, open_spectrum(6,:));
    xlim([f(1) f(end)]);
    hold on;
    grid off;
    grid minor on;
    xlabel("Frekvence (GHz)");
    ylabel("Amplituda (a.u.)");
endwhile;

figure();
plot(f, open_spectrum(7,:));
xlim([f(1) f(end)]);
hold on;
grid off;
grid minor on;
xlabel("Frekvence (GHz)");
ylabel("Amplituda (a.u.)");
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/noise_cal_avg64.eps','epsc');

open_raw_spectrum=[fft(open_avg_bkp(1).decoded_data);fft(open_avg_bkp(7).decoded_data)];
open_raw_spectrum=20*log(abs(open_raw_spectrum/4096));
open_raw_spectrum=open_raw_spectrum(:,1:2049);

figure();
plot(f, open_raw_spectrum(1,:));
xlim([f(1) f(end)]);
hold on;
grid off;
grid minor on;
xlabel("Frekvence (GHz)");
ylabel("Amplituda (a.u.)");
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/noise_raw_avg1.eps','epsc');

figure();
plot(f, open_raw_spectrum(2,:));
xlim([f(1) f(end)]);
hold on;
grid off;
grid minor on;
xlabel("Frekvence (GHz)");
ylabel("Amplituda (a.u.)");
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/noise_raw_avg64.eps','epsc');
