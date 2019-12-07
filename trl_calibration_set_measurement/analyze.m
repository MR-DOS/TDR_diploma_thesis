clear; %close all; clc;
unwrap=0;
s=read_touchstone("diplomka_trl_china/line69.s2p");
s2=read_touchstone("diplomka_trl_southwest/short.s2p");
s.freq=s.freq/1e9;
c0=299792458;

if (unwrap==1)
  for j=2:length(s11.ph)
    if ((s11.ph(j)-s11.ph(j-1))>300)
      s11.ph(j:length(s11.ph))=s11.ph(j:length(s11.ph))-360; 
    endif
    
    if ((s11.ph(j)-s11.ph(j-1))<-300)
      s11.ph(j:length(s11.ph))=s11.ph(j:length(s11.ph))+360;   
    endif  
  endfor
endif

figure(1);
plot(s.freq, 20*log10(s.s11.mag));
xlim([s.freq(1) s.freq(end)]);
grid on;
grid minor on;
hold on;
plot(s.freq,-15*ones(1,length(s.freq)),"color","k","linewidth",1);
hold off;
xlabel("Frekvence [GHz]");
ylabel("S11 [dB]");
%saveas(gca, '/home/msboss/Documents/ant/s11.png','png');
%plotyy(s11.freq,s11.mag,s11.freq,s11.ph,@plot);

figure(2);
s_diff=[0;diff(20*log10(s.s11.mag))];
plot(s.freq, s_diff);
xlim([s.freq(1) s.freq(end)]);
new_diff=ones(1,numel(s_diff));
new_diff(find(s_diff>0, numel(s_diff)))=0;
freq_res=0;
for i=2:numel(new_diff)
  if new_diff(i)!=new_diff(i-1) 
    freq_res=[freq_res s.freq(i)];    
  endif;
endfor

figure(3);
freq_res_diff=diff(freq_res);
freq_res_div=freq_res_diff./max(freq_res_diff);
plot(freq_res(2:end), freq_res_div,"marker","+","linestyle","none");
xlim([freq_res(1) freq_res(end)]);
hold on;
%plot(0:0.1:s.freq(end),polyval(polyfit(freq_res(2:end), freq_res_div(1:end), 16),0:0.1:s.freq(end)));
plot(0:0.1:s.freq(end),polyval(polyfit(freq_res(2:1:end)(5:end), freq_res_div(1:1:end)(5:end), 4),0:0.1:s.freq(end)));