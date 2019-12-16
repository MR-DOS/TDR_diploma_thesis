clc;clf;close all;

fid=fopen("/home/msboss/Documents/SW4STM32/rising.dat");
val=fread(fid,4096,"uint16")';
val=val-mean(val(2048-256+2:2048-256+2+200));
maxval=mean(val(2500:4096));
val=val/maxval;
figure();
plot(val(2048-256+2:4096),"linewidth", 3);
grid on;
grid minor on;
hold on;

%fid=fopen("/home/msboss/Documents/SW4STM32/short_avg16.dat");
fid=fopen("/home/msboss/Documents/SW4STM32/short_avg48.dat");
val=fread(fid,4096,"uint16")';
val=val-mean(val(1:200));
val=val/maxval;
plot(val,"linewidth", 3);

%fid=fopen("/home/msboss/Documents/SW4STM32/open_avg32.dat");
fid=fopen("/home/msboss/Documents/SW4STM32/load_avg32.dat");
val=fread(fid,4096,"uint16")';
val=val-mean(val(1:128));
val=val/maxval;
plot([ones(1,11)*val(1) val],"linewidth", 3);

%fid=fopen("/home/msboss/Documents/SW4STM32/nothing_avg32.dat");
%val=fread(fid,4096,"uint16")';
%plot([0 0 0 val]);

fid=fopen("/home/msboss/Documents/SW4STM32/RG223_SUHNER_50cm_THRU_SHORT.dat");
RG223_THRU_SHORT=fread(fid,4096,"uint16")';

fid=fopen("/home/msboss/Documents/SW4STM32/RG223_SUHNER_50cm_THRU_LOAD.dat");
RG223_THRU_LOAD=fread(fid,4096,"uint16")';

fid=fopen("/home/msboss/Documents/SW4STM32/RG223_SUHNER_50cm_avg32.dat");
RG223_OPEN=fread(fid,4096,"uint16")';

fid=fopen("/home/msboss/Documents/SW4STM32/load_avg32.dat");
LOAD=fread(fid,4096,"uint16")';

LOAD=LOAD-mean(LOAD(1:128));
maxLOAD=mean(LOAD(1024:4096));
LOAD=LOAD/maxLOAD;

RG223_OPEN=RG223_OPEN-mean(RG223_OPEN(1:128));
RG223_OPEN=RG223_OPEN/maxLOAD;

RG223_THRU_LOAD=RG223_THRU_LOAD-mean(RG223_THRU_LOAD(1:128));
RG223_THRU_LOAD=RG223_THRU_LOAD/maxLOAD;

RG223_THRU_SHORT=RG223_THRU_SHORT-mean(RG223_THRU_SHORT(1:128));
RG223_THRU_SHORT=RG223_THRU_SHORT/maxLOAD;

h=figure();

plot(RG223_OPEN,"linewidth", 3);
grid on;
grid minor on;
hold on;
plot([ones(1,15).*LOAD(1) LOAD],"linewidth", 3);
plot(RG223_THRU_LOAD(3:4096),"linewidth", 3);
plot([ones(1,10).*RG223_THRU_LOAD(1) RG223_THRU_SHORT],"linewidth", 3);

fid=fopen("/home/msboss/Documents/SW4STM32/smallcap.dat");
smallcap=fread(fid,4096,"uint16")'(11:4096);
smallcap=smallcap-mean(smallcap(1:128));
smallcap=smallcap/maxLOAD;
figure(1);
plot([ones(1,34).*smallcap(1) smallcap], "linewidth", 3);

fid=fopen("/home/msboss/Documents/SW4STM32/open_avg21.dat");
val=fread(fid,4096,"uint16")';
val=val-mean(val(1:200));
maxval=mean(val(2500:4096));
val=val/maxval;
figure();
plot(val);

fid=fopen("/home/msboss/Documents/SW4STM32/open_long_cable_avg13.dat");
val=fread(fid,4096,"uint16")'(11:4096);
open_cal=val(2940-1023:2940);
open_reflection=val(2900:2900+1023);
val=val-mean(val(1:128));
val=val/maxLOAD;
error();
close all;
plot([ones(1,34).*val(1) val], "linewidth", 3);
hold on;

fid=fopen("/home/msboss/Documents/SW4STM32/short_long_cable_avg13.dat");
val=fread(fid,4096,"uint16")'(11:4096);
val=val-mean(val(1:128));
val=val/maxLOAD;
plot([ones(1,34).*val(1) val], "linewidth", 3);

fid=fopen("/home/msboss/Documents/SW4STM32/load_long_cable_avg13.dat");
val=fread(fid,4096,"uint16")'(11:4096);
val=val-mean(val(1:128));
val=val/maxLOAD;
plot([ones(1,34).*val(1) val], "linewidth", 3);


open_cal_fft=fft(open_cal);
open_cal_ref=[ones(1,43).*open_cal(1) ones(1,1024-43).*open_cal(end)];
open_cal_ref_fft=fft(open_cal_ref);
open_cal_filter=open_cal_ref_fft./open_cal_fft;
open_cal_deembedded=abs(ifft(open_cal_fft.*open_cal_filter));
open_reflection_deembedded=abs(ifft(fft(open_reflection).*open_cal_filter));
figure();
plot(open_reflection);
hold on;
plot(open_reflection_deembedded);

fid=fopen("/home/msboss/Documents/SW4STM32/temp.dat");
val=fread(fid,4096,"uint16")'(11:4096);
%val=val-mean(val(1:128));
%val=val/maxLOAD;
figure();
close all;
%plot(val, "linewidth", 2, "linestyle",'-','+', "markersize", 8);
plot(val, "linewidth", 3);
%plot(val(1+16:end)-val(1:end-16));
xlim([1 4096]);

fid=fopen("/home/msboss/Documents/SW4STM32/meas_open.dat");
val=fread(fid,4096,"uint16")';
measured_data=val;
%val=val-mean(val(1:128));
%val=val/maxLOAD;
figure();
close all;
%plot(val, "linewidth", 2, "linestyle",'-','+', "markersize", 8);
plot(val, "linewidth", 3);
%plot(val(1+16:end)-val(1:end-16));
xlim([1 4096]);
hold on;
fid=fopen("/home/msboss/Documents/SW4STM32/cal_open.dat");
val=fread(fid,1024,"uint16")';
open=val;
plot(val, "linewidth", 3);
fid=fopen("/home/msboss/Documents/SW4STM32/cal_short.dat");
val=fread(fid,1024,"uint16")';
load=val;
plot(val, "linewidth", 3);
fid=fopen("/home/msboss/Documents/SW4STM32/cal_load.dat");
val=fread(fid,1024,"uint16")';
short=val;
plot(val, "linewidth", 3);

figure();
open_fft=fft(open);
load_fft=fft(load);
short_fft=fft(short);
plot(log10(abs(open_fft)));
xlim([1 1024]);
hold on;
plot(log10(abs(short_fft)));
plot(log10(abs(load_fft)));

figure();
Ed=load_fft;
Es=-(short_fft.+open_fft.-2.*load_fft)./(short_fft.-open_fft);
plot(log10(abs(short_fft)));
plot(log10(abs(Es)));
Er=2.*((open_fft.-load_fft).*short_fft.-load_fft.*open_fft.+load_fft.*load_fft)./(short_fft.-open_fft);
hold on;
plot(log10(abs(Er)));
plot(log10(abs(Ed)));
measured_data_fft=fft(measured_data(1:1024));
%measured_data_fft=fft((measured_data(1:1024)+[ones(1,300).*measured_data(1) measured_data(1:1024-300)])./2);
%measured_data_fft=short_fft;
normalized_data_fft=(measured_data_fft-Ed)./(Es.*(measured_data_fft-Ed)+Er);
figure();
plot(log10(abs(measured_data_fft)));
hold on;
plot(log10(abs(normalized_data_fft)));
figure();
normalized_data=ifft(normalized_data_fft);
plot(real(normalized_data));

fid=fopen("/home/msboss/Documents/SW4STM32/load_fall.dat");
val=fread(fid,4096,"uint16")';
figure();
plot(val,"linewidth", 3);
hold on;

fid=fopen("/home/msboss/Documents/SW4STM32/open_fall.dat");
val=fread(fid,4096,"uint16")';
plot(val,"linewidth", 3);
