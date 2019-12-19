close all;
%pkg load fuzzy-logic-toolkit;
%pkg load communications;
pkg load signal;
l=1; dl=2.5e-4;
time=-l:dl:l;
corrtime=-2*l:dl:2*l;

function ret=gaussmf(x, options)
sig=options(1);
c=options(2);
ret = exp((-(x - c).^2)./(2 * sig.^2));
endfunction

%scalepaper=0.3;
%papersize=[21*scalepaper 21*scalepaper];
%paperposition=[0 0 papersize];
%axesposition=[0.1, 0.1, 0.9, 0.9];
%fontsize=22;

unitstep=time>0;
h=figure(1);
%set (h,'papertype', '<custom>');
%set (h,'paperunits','centimeters');
%set (h,'papersize',papersize);
%set (h,'paperposition',paperposition);
%set (h,'defaultaxesposition', axesposition);
%set (h,'defaultaxesfontsize', fontsize);
plot(time,unitstep,"linewidth",2);
ylim([-0.2 1.2]);
xlabel("x [-]");
ylabel("H(x)");
grid off;
grid minor on;
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/unitstep.eps','epsc');
pause(1);

h=figure(2);
%set (h,'defaultaxesfontsize', fontsize);
dirac=(time==0)/dl;
h=plot(time,dirac,'linewidth', 2);
line_color=get(h,"color");
llength=0.05;
line([-llength 0], [1.2-llength 1.2], 'linewidth', 2, "color", line_color);
line([llength 0], [1.2-llength 1.2], 'linewidth', 2, "color", line_color);
ylim([-0.2 1.2]);
xlabel("x [-]");
ylabel("d(x)");
grid off;
grid minor on;
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/dirac.eps','epsc');

h=figure(3);
%set (h,'defaultaxesfontsize', fontsize);
err=erf(10*time)/2+1/2;
h=plot(10*time,err, 'linewidth', 2);
ylim([-0.2 1.2]);
xlabel("x [-]");
ylabel("erf(x)");
grid off;
grid minor on;
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/erf.eps','epsc');

h=figure(4);
%set (h,'defaultaxesfontsize', fontsize);
gauss=gaussmf(time, [0.05 0]);
%plot(log(abs(fft(hamming(length(gauss))'.*(gauss-mean(gauss))))));
plot(time,gauss, 'linewidth', 2);
ylim([-0.2 1.2]);
xlabel("x [-]");
ylabel("g(x)");
grid off;
grid minor on;
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/gauss.eps','epsc');

h=figure(5);
%set (h,'defaultaxesfontsize', fontsize);
sincx=sinc(20*time);
plot(20*time,sincx, 'linewidth', 2);
ylim([-0.3 1.1]);
xlabel("x [-]");
ylabel("sinc(x)");
grid off;
grid minor on;
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/sinc.eps','epsc');

sincxcorr=xcorr(sincx,sincx);
h=figure(6);
%set (h,'defaultaxesfontsize', fontsize);
plot(corrtime,sincxcorr, 'linewidth', 2);
xlim([-1 1]);
xlabel("x [-]");
ylabel("");
grid off;
grid minor on;
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/sinccorr.eps','epsc');

h=figure(7);
%set (h,'defaultaxesfontsize', fontsize);
noise=randn(length(time),1);
plot(time,noise, 'linewidth', 2);
xlabel("x [-]");
ylabel("rand(x)");
grid off;
grid minor on;
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/whitenoise.eps','epsc');

noisecorr=xcorr(noise,noise);
h=figure(8);
%set (h,'defaultaxesfontsize', fontsize);
plot(corrtime,noisecorr, 'linewidth', 2);
xlim([-1 1]);
xlabel("t (-)");
ylabel("R(rand(x))");
grid off;
grid minor on;
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/whitenoisecorr.eps','epsc');

h=figure(9);
%set (h,'defaultaxesfontsize', fontsize);
erfspeed=20;
separation=(erf(erfspeed*(time-0)) + 0.2*erf(erfspeed*(time-0.5)));% + 0.05*erf(erfspeed*(time-0.6)) - 0.1*erf(erfspeed*(time-0.7)) + 0.1*erf(erfspeed*(time-0.8)) +1.45)/2;
plot(time,separation, 'linewidth', 2);
xlabel("t (ns)");
ylabel("f(t)");
grid off;
grid minor on;
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/separableunitstep.eps','epsc');

%ylim([-0.2 2.2]);

close all;