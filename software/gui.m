pkg load instrument-control;
close all;
clear all;
graphics_toolkit qt;
warning('off', 'Octave:possible-matlab-short-circuit-operator');
#warning('off', 'Octave:missing-glyph');

global calibration_data;
calibration_data.open=[];
calibration_data.short=[];
calibration_data.load=[];
calibration_data.noise=[];
calibration_data.noise_avg=0;
calibration_data.load_avg=0;

global decoded_data=[];
global noise=[];

%------------------------------------------------------------------------------- 

function calibration_io(calling_object,event_data,h)
  global calibration_data;
  
  if (gcbo()==h.calibration_store) 
    save calibration.cal calibration_data;
  endif;
  if (gcbo()==h.calibration_restore)
    load calibration.cal;
    update_graph_data([],[],h);
  endif;
endfunction

function update_graph_data(calling_object,event_data,h)
  global decoded_data;
  global calibration_data;
  global noise;
  
  if (get(h.calibration_use,"value")==0)
    
    if(length(calibration_data.load)==4096) 
      waveform=decoded_data-calibration_data.load;
    else
      waveform=decoded_data;
    endif;
    
    if (get(h.calibration_denoise,"value")==1)
      waveform_spectrum=fft([0 diff(waveform)]);
      noise=sqrt(calibration_data.noise_avg./(1+round(63*get(h.device_average_slider, "value")))).*(calibration_data.noise-calibration_data.load)./(sqrt(1+(calibration_data.noise_avg/calibration_data.load_avg)^2));
      noise=[0 diff(noise)];
      noise_spectrum=fft(noise);
      sigma=6;
      noise_floor_shift=1; %makes the noise estimation N times larger to suppress more noise
      gaussian=(1/(sigma*sqrt(2*pi())))*exp(-0.5*(((1:4096)-2048)/sigma).^2);
      gaussian_spectrum=fft(gaussian);
      noise_filter=1./(1+(noise_floor_shift*((abs(noise_spectrum)+abs(flip(noise_spectrum)))/2)./((abs(gaussian_spectrum)+abs(flip(gaussian_spectrum)))/2)).^2);
      S11A=waveform_spectrum.*noise_filter;
      calibrated_data=real(ifft(S11A));
      for i=2:length(calibrated_data)
        calibrated_data(i)=calibrated_data(i)+calibrated_data(i-1);
      endfor  
      set(h.plot,"YData",calibrated_data);
    else
      set(h.plot,"YData",waveform);
    endif;
    
    
  else
    S11L=fft([0 diff(calibration_data.load)]);
    S11O=fft([0 diff(calibration_data.open)]);
    S11S=fft([0 diff(calibration_data.short)]);
    S11M=fft([0 diff(decoded_data)]);
    
    Ed=S11L;
    Er=2.*( ( (S11O-S11L).*(S11S - S11L) ) ./ (S11S-S11O) );
    Es=-( (S11S+S11O-2.*S11L) ./ (S11S-S11O) );
    
    S11A= (S11M-Ed) ./ ( Es.*(S11M-Ed)+Er );
    
    if (get(h.calibration_denoise,"value")==1)
      noise=sqrt(calibration_data.noise_avg./(1+round(63*get(h.device_average_slider, "value")))).*(calibration_data.noise-calibration_data.load)./(sqrt(1+(calibration_data.noise_avg/calibration_data.load_avg)^2));
      noise=[0 diff(noise)];
      noise_spectrum=fft(noise);
      sigma=6;
      noise_floor_shift=1; %makes the noise estimation N times larger to suppress more noise
      gaussian=(1/(sigma*sqrt(2*pi())))*exp(-0.5*(((1:4096)-2048)/sigma).^2);
      gaussian_spectrum=fft(gaussian);
      noise_filter=1./(1+(noise_floor_shift*((abs(noise_spectrum)+abs(flip(noise_spectrum)))/2)./((abs(gaussian_spectrum)+abs(flip(gaussian_spectrum)))/2)).^2);
      S11A=S11A.*noise_filter;
    endif;
    
    calibrated_data=real(ifft(S11A));
    for i=2:length(calibrated_data)
      calibrated_data(i)=calibrated_data(i)+calibrated_data(i-1);
    endfor  
    
    set(h.plot,"YData",calibrated_data);
  endif;
  
  xlim(h.graph_axes,[get(h.plot,"XData")(1) get(h.plot,"XData")(end)]);
  ylim(h.graph_axes, [-1.2 1.2]);
  drawnow;
endfunction

function ret=GetChildCoord(parent_coord, child_coord)
    ret=[parent_coord(1)+parent_coord(3)*(child_coord(1)-child_coord(3)/2) parent_coord(2)-parent_coord(4)*(child_coord(2)-child_coord(4)/2) parent_coord(3)*child_coord(3) parent_coord(4)*child_coord(4)];
endfunction

function ret=GetCornerCoord(middle_coord)
    ret=[middle_coord(1)-middle_coord(3)/2 middle_coord(2)-middle_coord(4)/2 middle_coord(3) middle_coord(4)];
endfunction

function send_continue(calling_object,event_data,ser_port)
    srl_write(ser_port,"CONTINUE!\n\n");
endfunction 

function send_start(calling_object,event_data,ser_port,h)
    avg=num2str(round(63*get(h.device_average_slider,"value"))+1,"%d");
    if (length(avg)==1) avg=cstrcat("0",avg); endif;
    srl_write(ser_port,cstrcat("AVG! ",avg,"\r\n"));
    srl_write(ser_port,"CONTINUE!\n\n");
endfunction 

function update_average(calling_object,event_data,h)
    set(h.device_slider_text, "string", strcat("Averages: ",sprintf("%d",round(63*get(h.device_average_slider, "value")+1))));
endfunction     

function calibration_action(calling_object,event_data,h)
    global calibration_data;
    global decoded_data;
    if (length(decoded_data)==4096)
      
      if (gcbo()==h.calibration_open) 
        if(length(calibration_data.open)==4096)
          calibration_data.open=[];
          set(h.calibration_use,"value",0);
        else
          calibration_data.open=decoded_data;
        endif;
      endif;

      if (gcbo()==h.calibration_short) 
        if(length(calibration_data.short)==4096)
          calibration_data.short=[];
          set(h.calibration_use,"value",0);
        else
          calibration_data.short=decoded_data;
        endif;
      endif;
      
      if (gcbo()==h.calibration_load) 
        if(length(calibration_data.load)==4096)
          calibration_data.load=[];
          set(h.calibration_use,"value",0);
          calibration_data.load_avg=0;
        else
          calibration_data.load=decoded_data;
          calibration_data.load_avg=1+round(63*get(h.device_average_slider, "value"));
        endif;
      endif;
      
      if (gcbo()==h.calibration_noise) 
        if(length(calibration_data.noise)==4096)
          calibration_data.noise=[];
          set(h.calibration_denoise,"value",0);
          calibration_data.noise_avg=0;
        else
          calibration_data.noise=decoded_data;
          calibration_data.noise_avg=1+round(63*get(h.device_average_slider, "value"));
        endif;
      endif;
      
    endif;
    
    update_graph_data([],[],h);
endfunction

function update_gui_state(h,state,data_length) 
    global calibration_data; 
  
    if length(state>2)
      if (state(1:2)==[13 10]) 
        state=state(3:end);
      endif;
    endif 
    switch(state)
      case{"STATE BOARD_INIT\r\n"}
        set(h.plot,"visible","off");
        set(h.graph_axes,"visible","off");
        set(h.graph_placeholder_text,"visible","on");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","off");
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off");
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off");
        set(h.device_state_text,"string","The device is initialising its peripherals.");
        set(h.device_instruction_text,"string","Please wait. No user action is required.");
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","off");
        set(h.device_slider_text,"visible","off");
        
      case{"STATE WAIT_EDGE\r\n"}
        set(h.plot,"visible","off");
        set(h.graph_axes,"visible","off");
        set(h.graph_placeholder_text,"visible","on");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","on");  %!!!!!!!%
        set(h.device_continue,"backgroundcolor",[0.5 0.94 0.5]);  %!!!!!!!%
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off"); 
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off");
        set(h.device_state_text,"string","The device is about to find the position\nof rising edge of the generator.");
        set(h.device_instruction_text,"string","Please disconnect everything form test port\nand connect directly an \"OPEN\" standard.\nThen press either the Continue button\nor button on the device.");
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","off");
        set(h.device_slider_text,"visible","off");
        
      case{"STATE CALIBRATING_SAMPLER\r\n"}
        set(h.plot,"visible","off");
        set(h.graph_axes,"visible","off");
        set(h.graph_placeholder_text,"visible","on");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","off");  %!!!!!!!%
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off"); 
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off"); 
        set(h.device_state_text,"string","The device is calibrating DC offset of the sampler.");
        set(h.device_instruction_text,"string","Please wait. No user action is required.");
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","off");
        set(h.device_slider_text,"visible","off");
        
      case{"STATE NOISE_ESTIMATION\r\n"}
        set(h.plot,"visible","off");
        set(h.graph_axes,"visible","off");
        set(h.graph_placeholder_text,"visible","on");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","off");
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off"); 
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off");  
        set(h.device_state_text,"string","The device is measuring its own noise.");
        set(h.device_instruction_text,"string","Please wait. No user action is required.");
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","off");
        set(h.device_slider_text,"visible","off");
        
      case{"STATE FINDING_EDGE\r\n"}
        set(h.plot,"visible","off");
        set(h.graph_axes,"visible","off");
        set(h.graph_placeholder_text,"visible","on");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","off");
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off");   
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off");
        set(h.device_state_text,"string","The device is trying to find the rising edge\n of the generator.");
        set(h.device_instruction_text,"string","Please wait. No user action is required.");
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","off");
        set(h.device_slider_text,"visible","off");
        
      case{"STATE WAIT_REFERENCE_PLANE\r\n"}
        set(h.plot,"visible","off");
        set(h.graph_axes,"visible","off");
        set(h.graph_placeholder_text,"visible","on");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","on");  %!!!!!!!%
        set(h.device_continue,"backgroundcolor",[0.5 0.94 0.5]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off"); 
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off");
        set(h.device_state_text,"string","The device is about to find the position\nof the measurement plane.");
        set(h.device_instruction_text,"string","Please connect airline/transmission line and connect \nan \"OPEN\" standard to its end. Then press either the \nContinue button or button on the device.");
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","off");
        set(h.device_slider_text,"visible","off");
        
      case{"STATE FINDING_REFERENCE_PLANE\r\n"}
        set(h.plot,"visible","off");
        set(h.graph_axes,"visible","off");
        set(h.graph_placeholder_text,"visible","on");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","off");  %!!!!!!!%
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off"); 
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off");
        set(h.device_state_text,"string","The device is trying to find the position\nof the measurement plane.");
        set(h.device_instruction_text,"string","Please wait. No user action is required."); 
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","off");
        set(h.device_slider_text,"visible","off");                
        
      case{"STATE READY\r\n"}
        %set(h.plot,"visible","on");
        %set(h.graph_axes,"visible","on");
        %set(h.graph_placeholder_text,"visible","off");
        set(h.vertical_amplitude_in,"enable","on");
        set(h.vertical_amplitude_out,"enable","on");
        set(h.vertical_position_up,"enable","on");
        set(h.vertical_position_down,"enable","on");
        set(h.vertical_reset,"enable","on");
        set(h.horizontal_amplitude_in,"enable","on");
        set(h.horizontal_amplitude_out,"enable","on");
        set(h.horizontal_position_up,"enable","on");
        set(h.horizontal_position_down,"enable","on");
        set(h.horizontal_reset,"enable","on");
        set(h.device_continue,"enable","off");
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.calibration_open,"enable","on");
        set(h.calibration_short,"enable","on");
        set(h.calibration_load,"enable","on");
        %set(h.calibration_use,"enable","on");
        %set(h.calibration_store,"enable","on");
        set(h.calibration_restore,"enable","on"); 
        set(h.calibration_noise,"enable","on");
        %set(h.calibration_denoise,"enable","off");
        set(h.device_state_text,"string","The device is ready for measurement.");
        set(h.device_instruction_text,"string","Now you can control the device."); 
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","off");
        set(h.device_slider_text,"visible","off");
        
      case{"STATE WAIT_OPEN\r\n"}
        set(h.plot,"visible","off");
        set(h.graph_axes,"visible","off");
        set(h.graph_placeholder_text,"visible","on");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","on");
        set(h.device_continue,"backgroundcolor",[0.5 0.94 0.5]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off");  
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off");
        set(h.device_state_text,"string","The device is about to measure a calibration normal.");
        set(h.device_instruction_text,"string","Please connect \"OPEN\" standard to the reference plane.\nThen press either the Continue button or button\non the device."); 
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","off");
        set(h.device_slider_text,"visible","off");
             
      case{"STATE WAIT_SHORT\r\n"}
        set(h.plot,"visible","off");
        set(h.graph_axes,"visible","off");
        set(h.graph_placeholder_text,"visible","on");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","on");
        set(h.device_continue,"backgroundcolor",[0.5 0.94 0.5]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off");  
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off");
        set(h.device_state_text,"string","The device is about to measure a calibration normal.");
        set(h.device_instruction_text,"string","Please connect \"SHORT\" standard to the reference plane.\Then press either the Continue button or button\non the device."); 
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","off");
        set(h.device_slider_text,"visible","off");
                 
      case{"STATE WAIT_LOAD\r\n"}
        set(h.plot,"visible","off");
        set(h.graph_axes,"visible","off");
        set(h.graph_placeholder_text,"visible","on");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","on");
        set(h.device_continue,"backgroundcolor",[0.5 0.94 0.5]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off");  
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off");
        set(h.device_state_text,"string","The device is about to measure a calibration normal.");
        set(h.device_instruction_text,"string","Please connect \"LOAD\" standard to the reference plane.\Then press either the Continue button or button\non the device."); 
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","off");
        set(h.device_slider_text,"visible","off");
      
      case{"STATE WAIT_DUT\r\n"}
        %set(h.plot,"visible","off");
        %set(h.graph_axes,"visible","off");
        %set(h.graph_placeholder_text,"visible","on");
        set(h.device_continue,"enable","off");
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.calibration_open,"enable","on");
        set(h.calibration_short,"enable","on");
        set(h.calibration_load,"enable","on");
        set(h.calibration_noise,"enable","on");
        
        if(length(calibration_data.open)==4096)
          set(h.calibration_open,"backgroundcolor",[0.94 0.94 0.5]);
        else
          set(h.calibration_open,"backgroundcolor",[0.94 0.94 0.94]);
        endif;
        
        if(length(calibration_data.load)==4096)
          set(h.calibration_load,"backgroundcolor",[0.94 0.94 0.5]);
        else
          set(h.calibration_load,"backgroundcolor",[0.94 0.94 0.94]);
        endif;
        
        if(length(calibration_data.short)==4096)
          set(h.calibration_short,"backgroundcolor",[0.94 0.94 0.5]);
        else
          set(h.calibration_short,"backgroundcolor",[0.94 0.94 0.94]);
        endif;
        
        if((length(calibration_data.open)==4096)&(length(calibration_data.load)==4096)&(length(calibration_data.short)==4096))
          set(h.calibration_use,"enable","on");
          set(h.calibration_store,"enable","on");
        else
          set(h.calibration_use,"enable","off");
          set(h.calibration_store,"enable","off");
        endif;
        
        if(length(calibration_data.noise)==4096)
          set(h.calibration_noise,"backgroundcolor",[0.94 0.94 0.5]);
        else
          set(h.calibration_noise,"backgroundcolor",[0.94 0.94 0.94]);
        endif;
        
        if((length(calibration_data.noise)==4096)&(length(calibration_data.load)==4096))
          set(h.calibration_denoise,"enable","on");
        else
          set(h.calibration_denoise,"enable","off");
        endif;
        
        set(h.calibration_restore,"enable","on");  
        set(h.device_state_text,"string","The device is ready to measure the DUT.");
        set(h.device_instruction_text,"string","Please connect the DUT. Then press \neither the Continue button or button\non the device.");
        set(h.device_run,"visible","on");
        set(h.device_stop,"visible","off");
        set(h.device_average_slider,"visible","on");
        set(h.device_slider_text,"visible","on");
        if(data_length==4096)
          set(h.vertical_amplitude_in,"enable","on");
          set(h.vertical_amplitude_out,"enable","on");
          set(h.vertical_position_up,"enable","on");
          set(h.vertical_position_down,"enable","on");
          set(h.vertical_reset,"enable","on");
          set(h.horizontal_amplitude_in,"enable","on");
          set(h.horizontal_amplitude_out,"enable","on");
          set(h.horizontal_position_up,"enable","on");
          set(h.horizontal_position_down,"enable","on");
          set(h.horizontal_reset,"enable","on");
        else
          set(h.vertical_amplitude_in,"enable","off");
          set(h.vertical_amplitude_out,"enable","off");
          set(h.vertical_position_up,"enable","off");
          set(h.vertical_position_down,"enable","off");
          set(h.vertical_reset,"enable","off");
          set(h.horizontal_amplitude_in,"enable","off");
          set(h.horizontal_amplitude_out,"enable","off");
          set(h.horizontal_position_up,"enable","off");
          set(h.horizontal_position_down,"enable","off");
          set(h.horizontal_reset,"enable","off");
        endif;
        
      case{"STATE NORMAL_CAL_RUNNING\r\n"}
        %set(h.plot,"visible","on");
        %set(h.graph_axes,"visible","on");
        set(h.graph_placeholder_text,"visible","off");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","off");
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off");  
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off");
        set(h.device_state_text,"string","The device is measuring a calibration normal.");
        set(h.device_instruction_text,"string","Please wait. No user action is required.");  
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","on");
        set(h.device_average_slider,"visible","on");
        set(h.device_slider_text,"visible","on");
       
      case{"STATE READY_TO_SEND\r\n"}
        %set(h.plot,"visible","on");
        %set(h.graph_axes,"visible","on");
        set(h.graph_placeholder_text,"visible","off");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","off");
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off");
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off");  
        set(h.device_state_text,"string","The device is ready to send data.");
        set(h.device_instruction_text,"string","Please wait. No user action is required."); 
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","on");
        set(h.device_average_slider,"visible","on");
        set(h.device_slider_text,"visible","on");
        
      case{"STATE MEASUREMENT_RUNNING\r\n"}
        %set(h.plot,"visible","on");
        %set(h.graph_axes,"visible","on");
        set(h.graph_placeholder_text,"visible","off");
        set(h.vertical_amplitude_in,"enable","off");
        set(h.vertical_amplitude_out,"enable","off");
        set(h.vertical_position_up,"enable","off");
        set(h.vertical_position_down,"enable","off");
        set(h.vertical_reset,"enable","off");
        set(h.horizontal_amplitude_in,"enable","off");
        set(h.horizontal_amplitude_out,"enable","off");
        set(h.horizontal_position_up,"enable","off");
        set(h.horizontal_position_down,"enable","off");
        set(h.horizontal_reset,"enable","off");
        set(h.device_continue,"enable","off");
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.calibration_open,"enable","off");
        set(h.calibration_short,"enable","off");
        set(h.calibration_load,"enable","off");
        set(h.calibration_use,"enable","off");
        set(h.calibration_store,"enable","off");
        set(h.calibration_restore,"enable","off"); 
        set(h.calibration_noise,"enable","off");
        set(h.calibration_denoise,"enable","off"); 
        set(h.device_state_text,"string","The device is running a measurement.");
        set(h.device_instruction_text,"string","Please wait. No user action is required.\nOnce the measurement is done, you will see the data.");  
        set(h.device_run,"visible","off");
        set(h.device_stop,"visible","on");
        set(h.device_average_slider,"visible","on");
        set(h.device_slider_text,"visible","on");  
        
    otherwise
        set(h.device_continue,"enable","off");
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.device_state_text,"string","The device returned an abnormal response.");
        set(h.device_instruction_text,"string","Please wait. If this error does not get solved\nin a few seconds,please reboot the reflectometer\nand restart this program."); 
        disp(strcat("Got response:",char(state)));
        disp(state);
    endswitch
endfunction

function update_plot_axes(obj)
    h=guidata(obj);
    
    switch(gcbo)
      case {h.vertical_amplitude_in}
        tmp=ylim(h.graph_axes);
        ylim(h.graph_axes, [((tmp(1)+tmp(2))/2)-(tmp(2)-tmp(1))/4 ((tmp(1)+tmp(2))/2)+(tmp(2)-tmp(1))/4]);
      case {h.vertical_amplitude_out}
        tmp=ylim(h.graph_axes);
        ylim(h.graph_axes, [((tmp(1)+tmp(2))/2)-(tmp(2)-tmp(1)) ((tmp(1)+tmp(2))/2)+(tmp(2)-tmp(1))]);
      case {h.vertical_position_up}
        tmp=ylim(h.graph_axes);
        ylim(h.graph_axes, [(tmp(1)+tmp(2))/2 (tmp(2)-tmp(1))+(tmp(1)+tmp(2))/2]);
      case {h.vertical_position_down}
        tmp=ylim(h.graph_axes);
        ylim(h.graph_axes, [(tmp(1)+tmp(2))/2-(tmp(2)-tmp(1)) (tmp(1)+tmp(2))/2]);
      case {h.vertical_reset}
        ylim([min(get(h.plot,"ydata")) max(get(h.plot,"ydata"))]);
      case {h.horizontal_amplitude_in}
        tmp=xlim(h.graph_axes);
        xlim(h.graph_axes, [((tmp(1)+tmp(2))/2)-(tmp(2)-tmp(1))/4 ((tmp(1)+tmp(2))/2)+(tmp(2)-tmp(1))/4]);
      case {h.horizontal_amplitude_out}
        tmp=xlim(h.graph_axes);
        xlim(h.graph_axes, [((tmp(1)+tmp(2))/2)-(tmp(2)-tmp(1)) ((tmp(1)+tmp(2))/2)+(tmp(2)-tmp(1))]);
      case {h.horizontal_position_up}
        tmp=xlim(h.graph_axes);
        xlim(h.graph_axes, [(tmp(1)+tmp(2))/2 (tmp(2)-tmp(1))+(tmp(1)+tmp(2))/2]);
      case {h.horizontal_position_down}
        tmp=xlim(h.graph_axes);
        xlim(h.graph_axes, [(tmp(1)+tmp(2))/2-(tmp(2)-tmp(1)) (tmp(1)+tmp(2))/2]);
      case {h.horizontal_reset}
        xlim([min(get(h.plot,"xdata")) max(get(h.plot,"xdata"))]); 
   endswitch  
endfunction

%------------------------------------------------------------------------------- 

window_size=[800 600];
GRAPH_BOX_POSITION=[0 1/2 1 1/2];
VERTICAL_BOX_POSITION=[0 1/2-1/6 1/4 1/6];
HORIZONTAL_BOX_POSITION=VERTICAL_BOX_POSITION + [VERTICAL_BOX_POSITION(3) 0 0 0];
AXIS_BOX_POSITION=[3/4 3/8 1/4 1/6];
DEVICE_BOX_POSITION=[1/2 0 1/2 1/2];
CALIBRATION_BOX_POSITION=[0 0 1/2 1/3];

DEVICE_STATE_TEXT_BOX_POSITION=[0.025 0.97-1/5 0.95 1/5];
DEVICE_INSTRUCTIONS_BOX_POSITION=[0.025 0.97-1/5-1/3 0.95 1/3];

VERTICAL_BUTTON_SIZE=[1/5 1/3];
HORIZONTAL_BUTTON_SIZE=VERTICAL_BUTTON_SIZE;
CALIBRATION_BUTTON_SIZE=[1/4 1/6];

GRAPH_POSITION=GetChildCoord(GRAPH_BOX_POSITION,[0.525 1.4 0.9 1.5]);
GRAPH_PLACEHOLDER_TEXT_COORD=[0 0 1 1];

VERTICAL_AMPLITUDE_IN_COORD=GetCornerCoord([1/4 2/3 VERTICAL_BUTTON_SIZE]);
VERTICAL_AMPLITUDE_OUT_COORD=GetCornerCoord([1/4 1/3 VERTICAL_BUTTON_SIZE]);
VERTICAL_POSITION_UP_COORD=GetCornerCoord([3/4 2/3 VERTICAL_BUTTON_SIZE]);
VERTICAL_POSITION_DOWN_COORD=GetCornerCoord([3/4 1/3 VERTICAL_BUTTON_SIZE]);
VERTICAL_RESET_COORD=GetCornerCoord([1/2 1/2 VERTICAL_BUTTON_SIZE]);

HORIZONTAL_AMPLITUDE_IN_COORD=VERTICAL_AMPLITUDE_IN_COORD;
HORIZONTAL_AMPLITUDE_OUT_COORD=VERTICAL_AMPLITUDE_OUT_COORD;
HORIZONTAL_POSITION_UP_COORD=GetCornerCoord([3/4-1/8+1/10 1/3 VERTICAL_BUTTON_SIZE]);
HORIZONTAL_POSITION_DOWN_COORD=GetCornerCoord([2/4+1/8-1/10 1/3 VERTICAL_BUTTON_SIZE]);
HORIZONTAL_RESET_COORD=GetCornerCoord([5/8 2/3 VERTICAL_BUTTON_SIZE]);

DEVICE_CONTINUE_BUTTON_COORD=GetCornerCoord([1/2 1/3 1/4 1/9]);
DEVICE_STATE_TEXT_COORD=[0 0 1 1];
DEVICE_INSTRUCTION_TEXT_COORD=DEVICE_STATE_TEXT_COORD;
DEVICE_AVERAGE_TEXT_COORD=GetCornerCoord([2/3 2/20 1/4 1/15]);
DEVICE_AVERAGE_SLIDER_COORD=GetCornerCoord([2/3 1/6 1/4 1/15]);
DEVICE_RUN_STOP_COORD=GetCornerCoord([1/3 1/6 1/4 1/9]);

CALIBRATION_OPEN_COORD=GetCornerCoord([1/5 4/5 CALIBRATION_BUTTON_SIZE]);
CALIBRATION_SHORT_COORD=GetCornerCoord([1/5 3/5 CALIBRATION_BUTTON_SIZE]);
CALIBRATION_LOAD_COORD=GetCornerCoord([1/5 2/5 CALIBRATION_BUTTON_SIZE]);
CALIBRATION_STORE_COORD=GetCornerCoord([1-1/5+1/8-1/4 3/5 CALIBRATION_BUTTON_SIZE(1)*2 CALIBRATION_BUTTON_SIZE(2)]);
CALIBRATION_RESTORE_COORD=GetCornerCoord([1-1/5+1/8-1/4 2/5 CALIBRATION_BUTTON_SIZE(1)*2 CALIBRATION_BUTTON_SIZE(2)]);
CALIBRATION_USE_COORD=GetCornerCoord([1-1/5+1/8-1/4 4/5 CALIBRATION_BUTTON_SIZE(1)*2 CALIBRATION_BUTTON_SIZE(2)]);
CALIBRATION_NOISE_COORD=GetCornerCoord([1/5 1/5 CALIBRATION_BUTTON_SIZE]);
CALIBRATION_DENOISE_COORD=GetCornerCoord([1-1/5+1/8-1/4 1/5 CALIBRATION_BUTTON_SIZE(1)*2 CALIBRATION_BUTTON_SIZE(2)]);
%------------------------------------------------------------------------------- 

main_window=figure();
set(main_window, "MenuBar", "none");
set(main_window, "ToolBar", "none");
%set (main_window, "color", get(0, "defaultuicontrolbackgroundcolor"))
set(main_window, "position", [get(main_window, "position")(1:2) window_size]);
%set(main_window, "position", [1600 1000 window_size]);
set(main_window, "Name", "TDR Control panel (Petr Polasek 2020-01-26)", "NumberTitle", "off");

h.serial_probe_message = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Probing for serial port accessibility",
                                "horizontalalignment", "center",
                                "position", [0 0.45 1 0.1]);
pause(0.5);                          
                                
if (exist("serial") != 3)
  delete(h.serial_probe_message);
  h.serial_access_error_message = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Serial port access is unsupported on your system or Octave build. \n If you are running Octave from Flatpak, please add the \"--device=all\" option to the launcher. \n Example launcher: \"/usr/bin/flatpak run --device=all --branch=stable --arch=x86_64 \n--command=/app/bin/octave --file-forwarding org.octave.Octave --gui @@ %f @@\"",
                                "horizontalalignment", "center",
                                "position", [0 0.4 1 0.2]);
    error("Serial port access is unsupported on your system or Octave build. \n If you are running Octave from Flatpak, please add the \"--device=all\" option to the launcher. \n Example launcher: \"/usr/bin/flatpak run --device=all --branch=stable --arch=x86_64 --command=/app/bin/octave --file-forwarding org.octave.Octave --gui @@ %f @@\"");
endif

delete(h.serial_probe_message);

device_found=0; 
while(device_found==0)
  h.serial_lookup_message = uicontrol ("style", "text",
                                  "units", "normalized",
                                  "string", "Looking for accessible serial ports",
                                  "horizontalalignment", "center",
                                  "position", [0 0.45 1 0.1]);
  pause(0.5);          

  serial_port_list=seriallist();
  delete(h.serial_lookup_message);
  if (sum(cell2mat(strfind(seriallist(),"ttyUSB")))==0)
        h.serial_no_device = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "No available serial ports. Please connect the reflectometer.",
                                "horizontalalignment", "center",
                                "position", [0 0.45 1 0.1]);                       
    do
      pause(0.5);                      
    until(sum(cell2mat(strfind(seriallist(),"ttyUSB")))!=0)
    
    delete(h.serial_no_device);
    serial_port_list=seriallist();
  endif

  h.serial_trying_to_connect = uicontrol ("style", "text",
                                  "units", "normalized",
                                  "string", "Serial port(s) found, trying to connect.",
                                  "horizontalalignment", "center",
                                  "position", [0 0.45 1 0.1]);     
                             
  for i=1:numel(serial_port_list)
    if (isempty(cell2mat(strfind(serial_port_list,"ttyUSB")(i)))) continue; endif;
    serial_port=serial(strcat("/dev/",serial_port_list{i}), 230400, 3);
    srl_flush(serial_port);
    srl_write(serial_port,"DEV?\n");
    data=srl_read(serial_port,255);
    device_name=char(data);
    if (strfind(device_name, "TDR5351_CORE")==1)
      delete(h.serial_trying_to_connect);
      h.serial_device_found = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", strcat("Serial device found, identifies itself as: \n",device_name,"\nRunning over: /dev/",serial_port_list{i}),
                                "horizontalalignment", "center",
                                "position", [0 0.4 1 0.2]);  
      pause(2);                          
      srl_write(serial_port,"REM!\n");
      data=srl_read(serial_port,255);
      delete(h.serial_device_found);
      if (strcmp(char(data),"REM.\r\n"))
        device_found=1; 
        h.serial_remote_accepted = uicontrol ("style", "text",
                          "units", "normalized",
                          "string", "Device accepted remote connection, starting GUI.",
                          "horizontalalignment", "center",
                          "position", [0 0.45 1 0.1]);  
        pause(1);
        delete(h.serial_remote_accepted);
        break;
      endif
    endif
    fclose(serial_port);
  endfor
endwhile

%------------------------------------------------------------------------------- 

h.graph_panel = uipanel ("title", "Measured data", 
                            "units", "normalized",
                            "titleposition", "centertop",
                            "position", GRAPH_BOX_POSITION,
                            "visible","off");
                 
h.graph_placeholder_text = uicontrol ("style", "text",
                               "units", "normalized",
                               "string", "There is no data to show right now.\n Please follow the instructions in Device panel.",
                               "horizontalalignment", "center",
                               "position", GRAPH_PLACEHOLDER_TEXT_COORD, "parent", h.graph_panel);         
      
h.graph_axes = axes ("position", GRAPH_POSITION, "parent", h.graph_panel);

x=linspace(0,1);
y=x.^3;
h.plot=plot(x,y,"visible","off");
set(h.graph_axes,"visible","off");
ylim(h.graph_axes, [-1 1]);
grid minor on;
h.graph_xlabel=xlabel("Time (ps)");
h.graph_ylabel=ylabel("Reflection coefficient (-)");
set(h.graph_panel,"visible","on");
%------------------------------------------------------------------------------- 

h.vertical_panel = uipanel ("title", "Vertical axis", 
                            "units", "normalized",
                            "titleposition", "centertop",
                            "position", VERTICAL_BOX_POSITION);
                         
h.vertical_amplitude_in = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "+",
                                "callback", @update_plot_axes,
                                "TooltipString", "Use this button to zoom into the graph vertically.\nTo reset changes made by this button, press the \'R\' button near this button.",
                                "position", VERTICAL_AMPLITUDE_IN_COORD, "parent", h.vertical_panel);
                                
h.vertical_amplitude_out = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "-",
                                "callback", @update_plot_axes,
                                "TooltipString", "Use this button to zoom out of the graph vertically.\nTo reset changes made by this button, press the \'R\' button near this button.",
                                "position", VERTICAL_AMPLITUDE_OUT_COORD, "parent", h.vertical_panel);  
  
h.vertical_position_up = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "↑",
                                "callback", @update_plot_axes,
                                "TooltipString", "Use this button to move up in the graph.\nTo reset changes made by this button, press the \'R\' button near this button.",
                                "position", VERTICAL_POSITION_UP_COORD, "parent", h.vertical_panel);  
                                
h.vertical_position_down = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "↓",
                                "callback", @update_plot_axes,
                                "TooltipString", "Use this button to move down in the graph.\nTo reset changes made by this button, press the \'R\' button near this button.",
                                "position", VERTICAL_POSITION_DOWN_COORD, "parent", h.vertical_panel);    
  
h.vertical_reset = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "R",
                                "callback", @update_plot_axes,
                                "TooltipString", "Use this button to reset any changes made to the graph using\nbuttons in this panel.",
                                "position", VERTICAL_RESET_COORD, "parent", h.vertical_panel);    
    
%------------------------------------------------------------------------------- 
  
h.horizontal_panel = uipanel ("title", "Horizontal axis", 
                            "units", "normalized",
                            "titleposition", "centertop",
                            "position", HORIZONTAL_BOX_POSITION);
                            
h.horizontal_amplitude_in = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "+",
                                "callback", @update_plot_axes,
                                "TooltipString", "Use this button to zoom into the graph horizontally.\nTo reset changes made by this button, press the \'R\' button near this button.",
                                "position", HORIZONTAL_AMPLITUDE_IN_COORD, "parent", h.horizontal_panel);
                                
h.horizontal_amplitude_out = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "-",
                                "callback", @update_plot_axes,
                                "TooltipString", "Use this button to zoom out of the graph horizontally.\nTo reset changes made by this button, press the \'R\' button near this button.",
                                "position", HORIZONTAL_AMPLITUDE_OUT_COORD, "parent", h.horizontal_panel);  
  
h.horizontal_position_up = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "→",
                                "callback", @update_plot_axes,
                                "TooltipString", "Use this button to move right in the graph.\nTo reset changes made by this button, press the \'R\' button near this button.",
                                "position", HORIZONTAL_POSITION_UP_COORD, "parent", h.horizontal_panel);  
                                
h.horizontal_position_down = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "←",
                                "callback", @update_plot_axes,
                                "TooltipString", "Use this button to move left in the graph.\nTo reset changes made by this button, press the \'R\' button near this button.",
                                "position", HORIZONTAL_POSITION_DOWN_COORD, "parent", h.horizontal_panel);    
 
h.horizontal_reset = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "R",
                                "callback", @update_plot_axes,
                                "TooltipString", "Use this button to reset any changes made to the graph using\nbuttons in this panel.",
                                "position", HORIZONTAL_RESET_COORD, "parent", h.horizontal_panel);    

%------------------------------------------------------------------------------- 

h.device_state_panel = uipanel ("title", "Device panel", 
                            "units", "normalized",
                            "titleposition", "centertop",
                            "position", DEVICE_BOX_POSITION);     
                               
h.device_continue = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "CONTINUE",
                                "callback", {@send_continue, serial_port},
                                "TooltipString", "Use this button to confirm that you have followed the required\nsteps as written in the \'Instructions\' box and to proceed to next step.",
                                "position", DEVICE_CONTINUE_BUTTON_COORD, "parent", h.device_state_panel); 
 
h.device_state_text_panel = uipanel ("title", "Device state", 
                            "units", "normalized",
                            "titleposition", "centertop",
                            "position", DEVICE_STATE_TEXT_BOX_POSITION, "parent", h.device_state_panel);  
                            
h.device_state_text = uicontrol ("style", "text",
                               "units", "normalized",
                               "string", "Waiting for state information",
                               "horizontalalignment", "center",
                               "position", DEVICE_STATE_TEXT_COORD, "parent", h.device_state_text_panel);   
                            
h.device_instruction_panel = uipanel ("title", "Instructions", 
                            "units", "normalized",
                            "titleposition", "centertop",
                            "position", DEVICE_INSTRUCTIONS_BOX_POSITION, "parent", h.device_state_panel);  
    
h.device_instruction_text = uicontrol ("style", "text",
                               "units", "normalized",
                               "string", "Please wait while the state\ninformation is updated",
                               "horizontalalignment", "center",
                               "position", DEVICE_INSTRUCTION_TEXT_COORD, "parent", h.device_instruction_panel);   
                            
h.device_slider_text = uicontrol ("style", "text",
                               "units", "normalized",
                               "string", "Averages: 1",
                               "horizontalalignment", "center",
                               "visible","off",
                               "position", DEVICE_AVERAGE_TEXT_COORD, "parent", h.device_state_panel); 
                               
h.device_average_slider = uicontrol ("style", "slider",
                            "units", "normalized",
                            "string", "slider",
                            "value", 0/63,
                            "sliderstep", [1/63 1/63],
                            "visible","off",
                            "TooltipString", "Use this slider to set how many times should be the measured data averaged.\nUnless you need to change this setting, let it be as it was initially set, since it is set to an optimal value.",
                            "position", DEVICE_AVERAGE_SLIDER_COORD, "parent", h.device_state_panel);
                            
set(h.device_average_slider, "callback",{@update_average, h});                            

h.device_run = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "RUN",
                                "callback", {@send_start, serial_port, h},
                                "visible","off",
                                "backgroundcolor",[0.5 0.94 0.5],
                                "TooltipString", "Use this button to start measurement.",
                                "position", DEVICE_RUN_STOP_COORD, "parent", h.device_state_panel); 

h.device_stop = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "STOP",
                                "callback", {@send_continue, serial_port},
                                "visible","off",
                                "backgroundcolor",[0.94 0.5 0.5],
                                "TooltipString", "Use this button to interrupt measurement. The device will\nfinish the running measurement cycle and send back averaged data.",
                                "position", DEVICE_RUN_STOP_COORD, "parent", h.device_state_panel); 
                                 
                            
%------------------------------------------------------------------------------- 

h.calibration_panel = uipanel ("title", "Calibration panel", 
                            "units", "normalized",
                            "titleposition", "centertop",
                            "position", CALIBRATION_BOX_POSITION);    
                            
h.calibration_open = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Open",
                                %"callback", {@store_calibration, h},
                                "TooltipString", "After performing a measurement of the OPEN standard, push this button to store the calibration.\nIf you wish to remove the calibration, push the button again. If it is yellow, then the calibration is set.",
                                "position", CALIBRATION_OPEN_COORD, "parent", h.calibration_panel);  
      
h.calibration_short = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Short",
                                %"callback", {@store_calibration, h},
                                "TooltipString", "After performing a measurement of the SHORT standard, push this button to store the calibration.\nIf you wish to remove the calibration, push the button again. If it is yellow, then the calibration is set.",
                                "position", CALIBRATION_SHORT_COORD, "parent", h.calibration_panel);    
                          
h.calibration_load = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Load",
                                %"callback", {@store_calibration, h},
                                "TooltipString", "After performing a measurement of the LOAD standard, push this button to store the calibration.\nIf you wish to remove the calibration, push the button again. If it is yellow, then the calibration is set.\nAt the moment this calibration is stored, it is non-conditionally applied to the displayed data, since it ALWAYS improves the displayed data.\nIf you wish to display the uncalibrated data, remove this calibration.",
                                "position", CALIBRATION_LOAD_COORD, "parent", h.calibration_panel);     

h.calibration_use = uicontrol ("style", "checkbox",
                                "units", "normalized",
                                "string", "Use calibration",
                                "value", 0,
                                "TooltipString", "To apply the OSL calibration to the measured data and display the calibrated data, check this box.\nThis box can be checked only after the OPEN, SHORT and LOAD calibration is performed or loaded from file.",
                                "position", CALIBRATION_USE_COORD, "parent", h.calibration_panel);                                             

h.calibration_store = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Store calibration",
                                %"callback", @update_plot_axes,
                                "TooltipString", "To store the OSL calibration to a file, push this button. It is stored to a file in the current working directory of this script.\nYou cannot select the file to which it will be stored.\nYou have to perform the OSL calibration to be able to use this button.",
                                "position", CALIBRATION_STORE_COORD, "parent", h.calibration_panel);  
      
h.calibration_restore = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Restore calibration",
                                %"callback", @update_plot_axes,
                                "TooltipString", "To restore the OSL calibration from a file, push this button. It is loaded from a file in the current working directory of this script.\nYou cannot select the file to which it will be stored.",
                                "position", CALIBRATION_RESTORE_COORD, "parent", h.calibration_panel);   
                                
h.calibration_denoise = uicontrol ("style", "checkbox",
                                "units", "normalized",
                                "string", "Noise reduction",
                                "value", 0,
                                "TooltipString", "To apply the noise reduction to the measured data and display the calibrated data, check this box.\nThis box can be checked only after the LOAD and NOISE calibration is performed or loaded from file.",
                                "position", CALIBRATION_DENOISE_COORD, "parent", h.calibration_panel);     
                                
h.calibration_noise = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Noise",
                                %"callback", {@store_calibration, h},
                                "TooltipString", "After performing a measurement of the LOAD standard with averagin set to 1, push this button to store the calibration.\nIf you wish to remove the calibration, push the button again. If it is yellow, then the calibration is set.",
                                "position", CALIBRATION_NOISE_COORD, "parent", h.calibration_panel);                                   
 
set(h.calibration_open, "callback",{@calibration_action, h});   
set(h.calibration_short, "callback",{@calibration_action, h}); 
set(h.calibration_load, "callback",{@calibration_action, h});  
set(h.calibration_use, "callback",{@update_graph_data, h}); 
set(h.calibration_store, "callback",{@calibration_io, h}); 
set(h.calibration_restore, "callback",{@calibration_io, h});  
set(h.calibration_denoise, "callback",{@update_graph_data, h}); 
set(h.calibration_noise, "callback",{@calibration_action, h}); 
 
guidata(main_window, h);

set(serial_port,"timeout",1);
avg_received=0;
last_state=0;
decoded_data=[];
levels=[0 4095];

while(1)
srl_write(serial_port,"STATE?\n");
device_state=srl_read(serial_port,255);
%set(h.device_state_text,"string",char(device_state));
update_gui_state(h, device_state, length(decoded_data));
if (strcmp(char(last_state),char(device_state))==0) avg_received=0; endif;
last_state=device_state;

if (avg_received==0)
  if (strcmp(char(device_state),"STATE WAIT_DUT\r\n"))
    srl_write(serial_port,"AVG?\r\n");
    averages=srl_read(serial_port,255);
    averages=sscanf(char(averages(4:end)),"%f");
    set(h.device_slider_text,"string",strcat("Averages: ",num2str(averages)));
    set(h.device_average_slider,"value",(averages-1)/63);
    
    srl_write(serial_port,"LEVELS!\r\n");
    levels=srl_read(serial_port,255);
    levels=sscanf(char(levels(8:end)),"%f %f");
  endif;
  avg_received=1;
endif;

if (strcmp(char(device_state),"STATE READY_TO_SEND\r\n"))
  srl_write(serial_port,"SEND_DATA!\r\n");
  set(serial_port,"timeout",10);
  [data,data_length]=srl_read(serial_port,8192);
  set(serial_port,"timeout",1);
  if (data_length!=8192) 
    disp("Data transmission failed for some reason, did not receive enough data");
    disp(cstrcat("Received only ",num2str(data_length)," bytes of data of 8192."));
    continue; 
  endif;
  set(h.plot,"visible","on");
  set(h.graph_axes,"visible","on");
  decoded_data=2*(double(4096-typecast(data,'uint16'))-levels(1))/(levels(2)-levels(1))-1;
  set(h.plot,"XData",1E12*(46*128/(24*25000000))*(1/(1+24*500000/24))*(0:4095));
  update_graph_data([],[],h);
  drawnow;
endif;

uiwait(main_window,1);
endwhile