function [sp] = read_touchstone(fname, mode);
%  [sp] = read_touchstone(fname);
%
if nargin < 2, mode = 'magph'; end

fid = fopen (fname, 'rt');
sp.freq = [];

if strcmpi(mode,'complex')
   sp.s11 = [];
else
   sp.mag = [];
   sp.ph = [];
end

while ( ~feof(fid) )
   str = fgets (fid);
   if ((str(1) == '!')||(str(1) == '#'))
      continue;
   end
   [val, len]= sscanf (str, '%f %f %f');
   % Ignore lines with less than 3 elements
   if (len == 3)
     sp.freq = [sp.freq; val(1)];

     if strcmpi(mode,'complex')
        sp.s11 = [sp.s11; ( val(2) .* exp(i*val(3)) ) ];
      else % mode == 'magph'
        sp.mag = [sp.mag; val(2)];
        sp.ph = [sp.ph; val(3)];
      end
   end
end

fclose(fid); 
