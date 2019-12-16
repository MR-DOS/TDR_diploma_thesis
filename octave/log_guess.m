clc;clf;close all;

fid=fopen("/home/msboss/Documents/SW4STM32/log.dat");
val=fread(fid,4096,"uint16")';

a=210;
b=2086;
c=860;
%logtable=round(a*log2(abs((1:4096)-b))+c);
logtable=val;

%divtable=(logtable(round(b+1.07.^(51:82)))-logtable(round(b+1.07.^(50:81)))+logtable(round(b-1.07.^(51:82)))-logtable(round(b-1.07.^(50:81))))/2;
%stem(divtable./log2(1.07));
%mean(divtable./log2(1.07))
%hold on;

b2=find(logtable==min(logtable))
tabstart=500;
tabend=735;
exponent=1.01;
tab1=round(exponent.^(tabstart:tabend));
tab2=round(exponent.^(tabstart+1:tabend+1));
divtable=(logtable(b2+tab2)-logtable(b2+tab1)+logtable(b2-tab2)-logtable(b2-tab1))/2;
%stem(divtable./log2(1.07));
a2=mean(divtable./log2(exponent))
hold on;
h=plot(logtable);
xlim([1 4096]);
grid off;
grid minor on;
set(h,"linewidth",2);
xlabel('Kodove slovo (-)');
ylabel('Zmerene napeti (-)');
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/log_function_graph_whole.eps','epsc');
xlim([1877-200 1877+200]);
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/log_function_graph_zoomed.eps','epsc');


offset=1000;
logtable2=a2*log2(abs((1:4096)-b2));
c2=mean([logtable(1:b2-offset) logtable(b2+offset:4096)]-[logtable2(1:b2-offset) logtable2(b2+offset:4096)]);
logtable2=logtable2+c2;
%plot(logtable2);
logtable3=logtable2-logtable;
figure(2);
plot(logtable3);