close all; clear all; clf;
%pkg load image;

function load_demangle_show_save(filename)
figure();
fid=fopen(strcat(filename,".dat"));
val=fread(fid,1024,"uint8=>uint8")';
[screen,map]=gray2ind(demangle(val));
imshow(screen,map);
screen=interp2(screen,5,"nearest");
imwrite(screen,map,strcat('/home/msboss/Documents/diplomova_prace/LaTeX/images/',filename,'.png'));
endfunction

function demangled_data=demangle(screen)
  for page=0:7
    for row=0:7
      for column=0:127
        demangled_data(row+page*8+2,column+2)=bitget(screen(column+page*128+1),row+1);
      endfor
    endfor
  endfor
  border_color=0;
  demangled_data(1,:)=border_color;
  demangled_data(end+1,:)=border_color;
  demangled_data(:,1)=border_color;
  demangled_data(:,end+1)=border_color;
endfunction

%load_demangle_show_save('greeting_screen');
%load_demangle_show_save('init_5351');
%load_demangle_show_save('stability_5351');
%load_demangle_show_save('offset_user_wait');
%load_demangle_show_save('offset_wait');
%load_demangle_show_save('levels_user_wait');
%load_demangle_show_save('levels_complete');
%load_demangle_show_save('edge_wait');
%load_demangle_show_save('edge_user_wait');
%load_demangle_show_save('edge_sampling');
%load_demangle_show_save('edge_found');
%load_demangle_show_save('measurement_user_wait');
%load_demangle_show_save('measurement_avg_wait');
%load_demangle_show_save('measurement_running');
%load_demangle_show_save('measurement_complete');
load_demangle_show_save('zooming_start');
load_demangle_show_save('zooming_complete');
load_demangle_show_save('discontinuity_split');
load_demangle_show_save('discontinuity_open_after_split');
load_demangle_show_save('discontinuity_open');
load_demangle_show_save('discontinuity_open_report');
load_demangle_show_save('discontinuities_shown');

close all;