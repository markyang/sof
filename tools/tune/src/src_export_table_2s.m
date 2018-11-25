function sfl = src_export_table_2s(fs_in, fs_out, l_2s, m_2s, ...
        pb_2s, sb_2s, taps_2s, ctype, vtype, ppath, hdir, profile)

% src_export_table_2s - Export src setup table
%
% src_export_table_2s(fs_in, fs_out, l, m, pb, sb, ctype, vtype, hdir, profile)
%
% The parameters are used to differentiate files for possibly many same
% conversion factor filters with possibly different characteristic.
%
% fs_in   - input sample rates
% fs_out  - output sample rates
% l       - interpolation factors
% m       - decimation factors
% pb      - passband widths
% sb      - stopband start frequencies
% ctype   - coefficient quantization
% vtype   - C variable type
% ppath   - print directory prefix to header file name include
% hdir    - directory for header files
% profile - string to append to file name
%

% Copyright (c) 2016, Intel Corporation
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%   * Redistributions of source code must retain the above copyright
%     notice, this list of conditions and the following disclaimer.
%   * Redistributions in binary form must reproduce the above copyright
%     notice, this list of conditions and the following disclaimer in the
%     documentation and/or other materials provided with the distribution.
%   * Neither the name of the Intel Corporation nor the
%     names of its contributors may be used to endorse or promote products
%     derived from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
%
% Author: Seppo Ingalsuo <seppo.ingalsuo@linux.intel.com>
%

if nargin < 12
        profile = '';
end

if isempty(profile)
        hfn = sprintf('src_%s_table.h', ctype);
else
        hfn = sprintf('src_%s_%s_table.h', profile, ctype);
end
fh = fopen(fullfile(hdir,hfn), 'w');

fprintf(fh, '/* SRC conversions */\n');
sfl = 0;
n_in = length(fs_in);
n_out = length(fs_out);
i=1;
all_modes = zeros(2*n_in*n_out, 7);
for n=1:2
        for b=1:n_out
                for a=1:n_in
                        all_modes(i,:) = [ l_2s(n,a,b) m_2s(n,a,b) ...
                                pb_2s(n,a,b) sb_2s(n,a,b) n a b ];
                        i=i+1;
                end
        end
end

all_modes_sub = all_modes(:,1:4);
[unique_modes, ia] = unique(all_modes_sub,'rows');
sm = size(unique_modes);

if isempty(profile)
        prof_ctype = ctype;
else
        prof_ctype = sprintf('%s_%s', profile, ctype);
end
for i=1:sm(1)
        um_tmp = unique_modes(i,:);
        if isequal(um_tmp(1:2),[1 1]) || isequal(um_tmp(1:2),[0 0])
        else
                fprintf(fh, '#include <%ssrc_%s_%d_%d_%d_%d.h>\n', ...
                        ppath, prof_ctype, um_tmp(1:4));

                n = all_modes(ia(i), 5);
                a = all_modes(ia(i), 6);
                b = all_modes(ia(i), 7);
                sfl = sfl +taps_2s(n, a, b); % Count sum of filter lengths
        end
end
fprintf(fh,'\n');

fprintf(fh, '/* SRC table */\n');
switch ctype
        case 'float'
                fprintf(fh, '%s fir_one = 1.0;\n', vtype);
                fprintf(fh, 'struct src_stage src_double_1_1_0_0 =  { 0, 0, 1, 1, 1, 1, 1, 0, 1.0, &fir_one };\n');
                fprintf(fh, 'struct src_stage src_double_0_0_0_0 =  { 0, 0, 0, 0, 0, 0, 0, 0, 0.0, &fir_one };\n');
        case 'int16'
                scale16 = 2^15;
                fprintf(fh, '%s fir_one = %d;\n', vtype, round(scale16*0.5));
                fprintf(fh, 'struct src_stage src_int16_1_1_0_0 =  { 0, 0, 1, 1, 1, 1, 1, 0, -1, &fir_one };\n');
                fprintf(fh, 'struct src_stage src_int16_0_0_0_0 =  { 0, 0, 0, 0, 0, 0, 0, 0,  0, &fir_one };\n');
        case 'int24'
                scale24 = 2^23;
                fprintf(fh, '%s fir_one = %d;\n', vtype, round(scale24*0.5));
                fprintf(fh, 'struct src_stage src_int24_1_1_0_0 =  { 0, 0, 1, 1, 1, 1, 1, 0, -1, &fir_one };\n');
                fprintf(fh, 'struct src_stage src_int24_0_0_0_0 =  { 0, 0, 0, 0, 0, 0, 0, 0,  0, &fir_one };\n');
        case 'int32'
                scale32 = 2^31;
                fprintf(fh, '%s fir_one = %d;\n', vtype, round(scale32*0.5));
                fprintf(fh, 'struct src_stage src_int32_1_1_0_0 =  { 0, 0, 1, 1, 1, 1, 1, 0, -1, &fir_one };\n');
                fprintf(fh, 'struct src_stage src_int32_0_0_0_0 =  { 0, 0, 0, 0, 0, 0, 0, 0,  0, &fir_one };\n');
        otherwise
                error('Unknown coefficient type!');
end

fprintf(fh, 'int src_in_fs[%d] = {', n_in);
j = 1;
for i=1:n_in
        fprintf(fh, ' %d', fs_in(i));
	if i < n_in
		fprintf(fh, ',');
	end
	j = j + 1;
	if (j > 8)
		fprintf(fh, '\n\t');
		j = 1;
	end
end
fprintf(fh, '};\n');

fprintf(fh, 'int src_out_fs[%d] = {', n_out);
j = 1;
for i=1:n_out
        fprintf(fh, ' %d', fs_out(i));
	if i < n_out
		fprintf(fh, ',');
	end
	j = j + 1;
	if (j > 8)
		fprintf(fh, '\n\t');
		j = 1;
	end
end
fprintf(fh, '};\n');

for n = 1:2
        fprintf(fh, 'struct src_stage *src_table%d[%d][%d] = {\n', ...
                n, n_out, n_in);
	i = 1;
        for b = 1:n_out
                fprintf(fh, '\t{');
                for a = 1:n_in
                        fprintf(fh, ' &src_%s_%d_%d_%d_%d', ...
                                ctype, l_2s(n,a,b), m_2s(n,a,b), ...
                                pb_2s(n,a,b), sb_2s(n,a,b));
                        if a < n_in
                                fprintf(fh, ',');
                        end
			i = i + 1;
			if i  > 2
				fprintf(fh, '\n\t');
				i = 1;
			end
                end
                fprintf(fh, '}');
                if b < n_out
                        fprintf(fh, ',\n');
                else
                        fprintf(fh, '\n');
                end
        end
        fprintf(fh, '};\n');
end

fclose(fh);

end
