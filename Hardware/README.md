# TDR_5351_core
----
## Description
Simple and cheap TDR based on experience from TDR\_avalanche and TDR\_splitter. Primary intention of this device is to give people the possibility to measure defects on cables / PCBs for less than about $100. UNDER CONSTRUCTION UNTIL STATED OTHERWISE.

----
## Overview
This device uses a PLL, fast CML buffer and diode sampling bridge. The principle is simple: one oscillator is fed into the CML buffer and then the resulting rectangular waveform with sharp edges (currently less than 200 ps) is fed into the cable. Both the input pulse and the reflections are sampled by the diode sampling bridge which is driven by another oscillator. The oscillators have a fixed frequency ratio, which allows equivalent-time sampling. The use of equivalent time sampling reduces cost of the device, because the slowed-down waveform can be sampled by a normal ADC, thus there is no need for a oscilloscope grade fast ADC, fast (and expensive) circuitry like FPGAs.
The generated pulse should have maximum jitter of about 80 ps peak-to-peak. The jitter of the sampler is not known as of now. Without the use of any averaging or statistical analysis, this could allow to sample points separated by no more than 100 ps (about 1-1.5 cm in a typical cable) and even less if averaging is used.

In contrary with the TDR\_avalanche, this device uses only deterministic parts. The avalanche pulser had quite a lot of jitter and was difficult to tune to behave properly. Since there are now quite cheap buffers with low rise/fall times (less than 200 ps, but there are even faster, though more expensive), Idecided to use these instead.

----
## How it works
### Pulse generator
This TDR uses Si5351-A-B with 8 outputs as a triple oscillator with balanced outputs. One of the oscillators drives a CML buffer (SY54020), which creates a rectangular pulse with sharp edges. The pulses are fed into the network which connect the pulse generator, cable and sampler.

### Connecting network
The network mentioned earlier serves as a matching network to reduce impedance mismatch at the measuring connector.

### Sampler
The sampler is a simple dual diode bridge sampler which is fed by the other two oscillators. These two oscillators are synchronous with constant offset to allow double sampling and have a slightly different frequency than the oscillator in the generator. With this setup, the output of the sampler is a slowed-down version of the input waveform, which is then sampled by the microcontroller.

### ADC
The sampled waveform is digitized by the ADC of the microcontroller. Because the ADC has only 12 bits, there is also a logarithmic detector with 90 dB dynamic range, effectively increasing the resolution to ~15 bits. This resolution can not be achieved with realtime sampling without spending a fortune on the ADC itself. There is an additional DAC for calibrating offset before measurement.

### First level of postprocessing
The first level of postprocessing is differentiation and normalization. After these operations, the user gets the response of the DUT to the input impulse. However, since the input pulse does not have infinitesimally short risetime, it may need additional postprocessing to get transmission / reflection graph.

### Second level of postprocessing
This second level consists of Wiener deconvolution - we have a measured input pulse and a "wish" - we want to get a nice clean step rising edge. Using these two vectors, a reverse filter can be computed using Wiener deconvolution. This step could help to get data which could be processed by the third level of postprocessing.

### Third level of postprocessing
This level analyses the data from the second level to get transmission and reflection coefficients for each measured point. The measured data has to be processed point-by-point. At each point, the reflected energy is used to compute the coefficients and the remaining energy after it has passed through this point. Then, a 1D simulation is run to get a vector of the reflected pulses. 
This resulting vector is then subtracted from the measured vector of data to get rid of multiple reflections. There is still one unsolved problem: defects with antisymmetrical reflection coefficient. This happens when two cables of different impedance are connected together. A localised defect (such as additional resistor in the path) has symmetrical reflection coefficient. Second problem is figuring out what is a multiple reflection and what is a periodic structure (this question may even have NO answer). After processing all of the points, the T/R vectors should be computed (note that there are two vectors for each parameter due to the antisymmetric behavior).
Next step is to turn the T/R vectors into a vector of characteristic impedance.

----
## Images
Description:
![Description](/relative/link.jpg)
Description2:
![Description2](https://some.page/some/image.jpg)

----
## References
[1-GHz Sampling Oscilloscope Front End Is Easily Modified](http://www.redrok.com/sampscope.htm)

----
## Sidenotes