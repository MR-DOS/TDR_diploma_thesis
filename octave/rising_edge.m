clc;clf;close all;

while(0)
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
endwhile

fid=fopen("/home/msboss/Documents/SW4STM32/load_fall.dat");
val=4096-fread(fid,4096,"uint16")';
time=(1:4096)*20;
figure();
%plot(time,val,"linewidth", 2);
%hold on;

fid=fopen("/home/msboss/Documents/SW4STM32/open_fall.dat");
val=4096-fread(fid,4096,"uint16")'-90;
plot(time,val,"linewidth", 2);
hold on;

ylim([2100 3300]);

grid off;
grid minor on;
xlim([1 time(end)]);
xlabel("Cas (ps)");
ylabel("Zmerena data (-)");

base_value=mean(val(700:1100));
top_value=mean(val(1400:2100));

value_20_percent=base_value+(top_value-base_value)/5;
value_80_percent=base_value+4*(top_value-base_value)/5;

position_20_percent=min(find((val.*[zeros(1,600) ones(1,4096-600)])>=value_20_percent));
position_80_percent=max(find(val<=value_80_percent));
value_20_percent=val(position_20_percent);
value_80_percent=val(position_80_percent);

plot(time, value_20_percent.*ones(1,4096),"color",[0.5 0 0],"linewidth",1);
plot(time, value_80_percent.*ones(1,4096),"color",[0 0.5 0],"linewidth",1);

xlim([time(position_20_percent)-(time(position_80_percent)-time(position_20_percent))*3  time(position_80_percent)+(time(position_80_percent)-time(position_20_percent))*8])

plot(time(position_20_percent)*ones(1,4096), 1:4096,"color",[0.5 0 0],"linewidth",1);
plot(time(position_80_percent)*ones(1,4096), 1:4096,"color",[0 0.5 0],"linewidth",1);

risetime=time(position_80_percent)-time(position_20_percent);

saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/rising_edge_DUT_open.eps','epsc');

figure();
diffavg=8;
[ax,h1,h2]=plotyy(time, val, time,[zeros(1,diffavg) val(1+diffavg:end)-val(1:end-diffavg)]);
set(h1,"linewidth",2);
set(h2,"linewidth",2);
%xlim([2800 12000]);
%ylim([1000 2500]);
xlim(ax(1),[2800 10000]);
xlim(ax(2),[2800 10000]);
ylim(ax(1),[0 2500]);
ylim(ax(2),[-200 1050]);
xlabel("Cas (ps)");
ylabel(ax(1),"Zmerena data (-)");
ylabel(ax(2),"Prumerovana diference (-)");
grid off;
grid minor on;
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/rising_edge_port_load.eps','epsc');