close all; clear all; clf;

time=0:10:10000;
incident_time=1000;
discontinuity_time=6000;
no_reflection=(erf(0.005*(time-incident_time))-1)/2;
open_reflection=no_reflection.+(erf(0.005*(time-discontinuity_time))+1)/2;
short_reflection=no_reflection.-(erf(0.005*(time-discontinuity_time))+1)/2;

larger_impedance_reflection=no_reflection.+(erf(0.005*(time-discontinuity_time))+1)/4;
lower_impedance_reflection=no_reflection.-(erf(0.005*(time-discontinuity_time))+1)/4;
plot(time,open_reflection,"linewidth",2);
hold on;
ylim([-1.2 1.2]);
yticks([-1:0.2:1]);
plot(time,larger_impedance_reflection,"linewidth",2);
plot(time,no_reflection,"linewidth",2);
plot(time,lower_impedance_reflection,"linewidth",2);
plot(time,short_reflection,"linewidth",2);
grid off;
grid minor on;
l=xlabel("Cas (ps)");
ylabel("Merene napeti (a.u.)");
l=legend({'Z_L=\infty','Z_L>50\Omega','Z_L=Z_0','Z_L<50\Omega','Z_L=0'},"location","northwest");
set(l, 'interpreter', 'Tex');
saveas(gca, '/home/msboss/Documents/diplomova_prace/LaTeX/images/onereflectionsample.eps','epsc');