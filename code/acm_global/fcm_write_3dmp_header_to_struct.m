function [mmm] = fcm_write_3dmp_header_to_struct(inFilename, mmm)
%=========================================================================
% DESCRIPTION
%   Extracts the 3DMP instrument data header and writes it to structure mmm
%
% USAGE:  meta = fcm_write_3dmp_header_to_struct(inFilename, meta);
%
%   INPUT
%     inFilename = filename of an FSI ACM data file (text)
%     mmm = a scalar structure
%
%   OUTPUT
%     mmm = the input structure with an added field 
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   Global McLane Profiler deployments in the OOI program utilize the
%   FSI model 3DMP acoustic current meter; for a given deployment all of
%   the extracted text data files contain the same header appended to the
%   end of the data section. This function extracts the 3dmp header from 
%   inFilename and writes it out as a field to structure mmm.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-10-05: desiderio: initial code
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%.. 2021-05-24: desiderio: radMMP version 4.0
%=========================================================================

fid = fopen(inFilename, 'r');
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
C = C{1};  % unwrap

idx = find(contains(C, 'ACM+ Header Contents:'));
if isempty(idx)
    disp('Warning: no ACM+ header found in infile.');
    fieldText = strings(0);  % empty string *array*, different entity than ""
elseif numel(idx)>1
    disp('Warning: more than one ''ACM+ Header Contents:'' row found in infile.');
    disp('All rows after and including the first will be copied to the outfile.');
    fieldText = string(C(idx(1):end));
else
    %.. normal case
    fieldText = string(C(idx(1):end));
end
mmm.fsi_3dmp_header = fieldText;
