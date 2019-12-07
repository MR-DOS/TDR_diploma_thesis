# Time domain reflectometer
----
## Description
Simple and cheap TDR based on experience from TDR\_avalanche and TDR\_splitter. Primary intention of this device is to give people the possibility to measure defects on cables / PCBs for less than about $100.
It is also my diploma thesis. All software (GUI in Octave), firmware (which runs in the processor in the reflectometer) and hardware (the PCB) was written/drawn by me. All parts are open source and you can use the in any way which is conformant with GNU GPL 3.0. The only parts not made by me are the SPD and CMSIS drivers which are included because the firmware might not work with different versions (note: I patched a bug in the SPD in ADC section where changing ADC sources was programmed plainly wrong). 

----
## Overview
This device uses a PLL, fast CML buffer and diode sampling bridge. The principle is simple: one oscillator is fed into the CML buffer and then the resulting rectangular waveform with sharp edges (measured around 75-85 ps) is fed into the cable. Both the input pulse and the reflections are sampled by the diode sampling bridge which is driven by another oscillator. The oscillators have a fixed frequency ratio, which allows equivalent-time sampling. The use of equivalent time sampling reduces cost of the device, because the slowed-down waveform can be sampled by a normal ADC, thus there is no need for a oscilloscope grade fast ADC, fast (and expensive) circuitry like FPGAs.
The generated pulse should have maximum jitter of about 23 ps peak-to-peak and 4 ps RMS (measured). The TDR is able to sample with timestep of 20 ps.
In contrary with the TDR\_avalanche, this device uses only deterministic parts. The avalanche pulser had quite a lot of jitter and was difficult to tune to behave properly, I decided to use these instead.

----
## How it works
### Pulse generator
This TDR uses Si5351-A-B with 8 outputs as a triple oscillator with balanced outputs. One of the oscillators drives a CML buffer (SY54020), which creates a rectangular pulse with sharp edges. The pulses are fed into the network which connect the pulse generator, cable and sampler.

### Connecting network
The network mentioned earlier serves as a matching network to reduce impedance mismatch at the measuring connector.

### Sampler
The sampler is a simple dual diode bridge sampler which is fed by the other two oscillators. These two oscillators are synchronous with constant offset to allow double sampling and have a slightly different frequency than the oscillator in the generator. With this setup, the output of the sampler is a slowed-down version of the input waveform, which is then sampled by the microcontroller.

### ADC
The sampled waveform is digitized by the ADC of the microcontroller.

----
## References
[1-GHz Sampling Oscilloscope Front End Is Easily Modified](http://www.redrok.com/sampscope.htm)

----
## Sidenotes
