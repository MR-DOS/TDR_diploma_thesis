clc;clf;close all;clear;
n=128;

figure(1);
data=round(sqrt(1024)*randn(4096,n)+2048);
%data=sqrt(10)*randn(4096,n)+2048;
variance(1)=std(data(:,1))^2;

for(i=2:n)
  data(:,i)=floor(( data(:,i) + (i-1)*data(:,i-1) ) / i);
  %data(:,i)=( data(:,i) + (i-1)*data(:,i-1) ) / i;
  variance(i)=std(data(:,i))^2;
endfor

plot(variance,"linewidth",2);
xlim([1 n]);
grid off;
grid minor on;
xlabel('Pocet provedenych prumeru (-)');
ylabel('Rozptyl (-)');
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/averaging_integer_variance.eps','epsc');

figure(2);
plot((1:n).*variance,"linewidth",2);
hold on;
der_variance=variance(2:n)-variance(1:n-1);
plot(der_variance,"linewidth",2);
xlabel('Pocet provedenych prumeru (-)');
xlim([1 n]);
grid off;
grid minor on;
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/averaging_integer_difference_error.eps','epsc');

%-----------------------%

figure(3);
data=sqrt(1024)*randn(4096,n)+2048;
%data=sqrt(10)*randn(4096,n)+2048;
variance(1)=std(data(:,1))^2;

for(i=2:n)
  data(:,i)=( data(:,i) + (i-1)*data(:,i-1) ) / i;
  %data(:,i)=( data(:,i) + (i-1)*data(:,i-1) ) / i;
  variance(i)=std(data(:,i))^2;
endfor

plot(variance,"linewidth",2);
xlim([1 n]);
grid off;
grid minor on;
xlabel('Pocet provedenych prumeru (-)');
ylabel('Rozptyl (-)');
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/averaging_float_variance.eps','epsc');

figure(4);
plot((1:n).*variance,"linewidth",2);
hold on;
der_variance=variance(2:n)-variance(1:n-1);
plot(der_variance,"linewidth",2);
xlim([1 n]);
grid off;
grid minor on;
xlabel('Pocet provedenych prumeru (-)');
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/averaging_float_difference_error.eps','epsc');
