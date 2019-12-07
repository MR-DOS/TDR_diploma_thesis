pkg load instrument-control;
close all;
clear all;
graphics_toolkit qt;

%------------------------------------------------------------------------------- 

function ret=GetChildCoord(parent_coord, child_coord)
    ret=[parent_coord(1)+parent_coord(3)*(child_coord(1)-child_coord(3)/2) parent_coord(2)-parent_coord(4)*(child_coord(2)-child_coord(4)/2) parent_coord(3)*child_coord(3) parent_coord(4)*child_coord(4)];
endfunction

function ret=GetCornerCoord(middle_coord)
    ret=[middle_coord(1)-middle_coord(3)/2 middle_coord(2)-middle_coord(4)/2 middle_coord(3) middle_coord(4)];
endfunction

function send_continue(calling_object,event_data,ser_port)
    srl_write(ser_port,"CONTINUE!\n\n");
endfunction  

function update_gui_state(h,state)  
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
        set(h.device_state_text,"string","The device is initialising its peripherals.");
        set(h.device_instruction_text,"string","Please wait. No user action is required.");
        
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
        set(h.device_state_text,"string","The device is about to find the position\nof rising edge of the generator.");
        set(h.device_instruction_text,"string","Please disconnect everything form test port\nand connect directly an \"OPEN\" standard.\nThen press either the Continue button\nor button on the device.");
        
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
        set(h.device_state_text,"string","The device is calibrating DC offset of the sampler.");
        set(h.device_instruction_text,"string","Please wait. No user action is required.");
        
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
        set(h.device_state_text,"string","The device is measuring its own noise.");
        set(h.device_instruction_text,"string","Please wait. No user action is required.");
        
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
        set(h.device_state_text,"string","The device is trying to find the rising edge\n of the generator.");
        set(h.device_instruction_text,"string","Please wait. No user action is required.");
        
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
        set(h.device_state_text,"string","The device is about to find the position\nof the measurement plane.");
        set(h.device_instruction_text,"string","Please connect airline/transmission line and connect \nan \"OPEN\" standard to its end. Then press either the \nContinue button or button on the device.");
        
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
        set(h.device_state_text,"string","The device is trying to find the position\nof the measurement plane.");
        set(h.device_instruction_text,"string","Please wait. No user action is required."); 
        
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
        set(h.device_state_text,"string","The device is ready for measurement.");
        set(h.device_instruction_text,"string","Now you can control the device."); 
        
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
        set(h.device_state_text,"string","The device is about to measure a calibration normal.");
        set(h.device_instruction_text,"string","Please connect \"OPEN\" standard to the reference plane.\nThen press either the Continue button or button\non the device.");
        
        
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
        set(h.device_state_text,"string","The device is about to measure a calibration normal.");
        set(h.device_instruction_text,"string","Please connect \"SHORT\" standard to the reference plane.\Then press either the Continue button or button\non the device.");
                 
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
        set(h.device_state_text,"string","The device is about to measure a calibration normal.");
        set(h.device_instruction_text,"string","Please connect \"LOAD\" standard to the reference plane.\Then press either the Continue button or button\non the device.");
      
      case{"STATE WAIT_DUT\r\n"}
        %set(h.plot,"visible","off");
        %set(h.graph_axes,"visible","off");
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
        set(h.device_state_text,"string","The device is ready to measure the DUT.");
        set(h.device_instruction_text,"string","Please connect the DUT. Then press \neither the Continue button or button\non the device.");
        
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
        set(h.device_state_text,"string","The device is measuring a calibration normal.");
        set(h.device_instruction_text,"string","Please wait. No user action is required."); 
       
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
        set(h.device_state_text,"string","The device is ready to send data.");
        set(h.device_instruction_text,"string","Please wait. No user action is required."); 
        
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
        set(h.device_state_text,"string","The device is ready to send data.");
        set(h.device_instruction_text,"string","Please wait. No user action is required.");   
        
    otherwise
        set(h.device_continue,"enable","off");
        set(h.device_continue,"backgroundcolor",[0.94 0.94 0.94]);
        set(h.device_state_text,"string","The device ireturned an abnormal response.");
        set(h.device_instruction_text,"string","Please wait. If this error does not get solved\nin a few seconds,please reboot the reflectometer\nand restart this program."); 
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
        ylim([-1 1]);
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

CALIBRATION_OPEN_COORD=GetCornerCoord([1/5 3/4 CALIBRATION_BUTTON_SIZE]);
CALIBRATION_SHORT_COORD=GetCornerCoord([1/5 2/4 CALIBRATION_BUTTON_SIZE]);
CALIBRATION_LOAD_COORD=GetCornerCoord([1/5 1/4 CALIBRATION_BUTTON_SIZE]);
CALIBRATION_STORE_COORD=GetCornerCoord([1-1/5+1/8-1/4 2/4 CALIBRATION_BUTTON_SIZE(1)*2 CALIBRATION_BUTTON_SIZE(2)]);
CALIBRATION_RESTORE_COORD=GetCornerCoord([1-1/5+1/8-1/4 1/4 CALIBRATION_BUTTON_SIZE(1)*2 CALIBRATION_BUTTON_SIZE(2)]);
CALIBRATION_USE_COORD=GetCornerCoord([1-1/5+1/8-1/4 3/4 CALIBRATION_BUTTON_SIZE(1)*2 CALIBRATION_BUTTON_SIZE(2)]);
%------------------------------------------------------------------------------- 

main_window=figure();
set(main_window, "MenuBar", "none");
set(main_window, "ToolBar", "none");
%set (main_window, "color", get(0, "defaultuicontrolbackgroundcolor"))
%set(main_window, "position", [get(main_window, "position")(1:2) window_size]);
set(main_window, "position", [1600 1000 window_size]);
set(main_window, "Name", "TDR Control panel (Petr Polasek 2019-11-28)", "NumberTitle", "off");

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
                                "position", VERTICAL_AMPLITUDE_IN_COORD, "parent", h.vertical_panel);
                                
h.vertical_amplitude_out = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "-",
                                "callback", @update_plot_axes,
                                "position", VERTICAL_AMPLITUDE_OUT_COORD, "parent", h.vertical_panel);  
  
h.vertical_position_up = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "↑",
                                "callback", @update_plot_axes,
                                "position", VERTICAL_POSITION_UP_COORD, "parent", h.vertical_panel);  
                                
h.vertical_position_down = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "↓",
                                "callback", @update_plot_axes,
                                "position", VERTICAL_POSITION_DOWN_COORD, "parent", h.vertical_panel);    
  
h.vertical_reset = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "R",
                                "callback", @update_plot_axes,
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
                                "position", HORIZONTAL_AMPLITUDE_IN_COORD, "parent", h.horizontal_panel);
                                
h.horizontal_amplitude_out = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "-",
                                "callback", @update_plot_axes,
                                "position", HORIZONTAL_AMPLITUDE_OUT_COORD, "parent", h.horizontal_panel);  
  
h.horizontal_position_up = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "→",
                                "callback", @update_plot_axes,
                                "position", HORIZONTAL_POSITION_UP_COORD, "parent", h.horizontal_panel);  
                                
h.horizontal_position_down = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "←",
                                "callback", @update_plot_axes,
                                "position", HORIZONTAL_POSITION_DOWN_COORD, "parent", h.horizontal_panel);    
 
h.horizontal_reset = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "R",
                                "callback", @update_plot_axes,
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
                               
%------------------------------------------------------------------------------- 

h.calibration_panel = uipanel ("title", "Calibration panel", 
                            "units", "normalized",
                            "titleposition", "centertop",
                            "position", CALIBRATION_BOX_POSITION);    
                            
h.calibration_open = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Open",
                                "callback", @update_plot_axes,
                                "position", CALIBRATION_OPEN_COORD, "parent", h.calibration_panel);  
      
h.calibration_short = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Short",
                                "callback", @update_plot_axes,
                                "position", CALIBRATION_SHORT_COORD, "parent", h.calibration_panel);    
                          
h.calibration_load = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Load",
                                "callback", @update_plot_axes,
                                "position", CALIBRATION_LOAD_COORD, "parent", h.calibration_panel);     

h.calibration_use = uicontrol ("style", "checkbox",
                                "units", "normalized",
                                "string", "Use calibration",
                                "value", 0,
                                "callback", @update_plot_axes,
                                "position", CALIBRATION_USE_COORD, "parent", h.calibration_panel);                                             

h.calibration_store = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Store calibration",
                                "callback", @update_plot_axes,
                                "position", CALIBRATION_STORE_COORD, "parent", h.calibration_panel);  
      
h.calibration_restore = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Restore calibration",
                                "callback", @update_plot_axes,
                                "position", CALIBRATION_RESTORE_COORD, "parent", h.calibration_panel);   
                                
guidata(main_window, h);

set(serial_port,"timeout",1);
while(1)
srl_write(serial_port,"STATE?\n");
device_state=srl_read(serial_port,255);
%set(h.device_state_text,"string",char(device_state));
update_gui_state(h, device_state);
if (strcmp(char(device_state),"STATE READY_TO_SEND\r\n"))
  srl_write(serial_port,"SEND_DATA!\r\n");
  set(serial_port,"timeout",20);
  data=srl_read(serial_port,8192);
  set(h.plot,"visible","on");
  set(h.graph_axes,"visible","on");
  set(serial_port,"timeout",1);
  decoded_data=4096-typecast(data,'uint16');
  set(h.plot,"XData",20*(0:4095));
  set(h.plot,"YData",decoded_data);
  xlim(h.graph_axes,[0 20*numel(decoded_data)]);
  ylim(h.graph_axes, [min(decoded_data) max(decoded_data)]);
endif;
drawnow();
endwhile