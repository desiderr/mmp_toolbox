function para = getNumberOfProfiles(para)
%=========================================================================
% DESCRIPTION
%   Finds the largest profile number by doing a listing of the unpacked
%   'C' and 'E' files and using the larger number.
%
% USAGE:  para = getNumberOfProfiles(para)
%
%   INPUT
%     para  = a scalar structure with para.unpacked_data_folder containing a
%             foldername containing unpacked profiler 'C' and 'E' data files.
%
%   OUTPUT
%     para  = a scalar structure with para.number_of_profiles containing the
%             number of profiles in the deployment denoted by the input.
%
% NOTES
%   The result is used as the number_of_profiles parameter in deployemnt 
%   processing; note that the first test profile in an OOI deployment
%   is profile #0 and is not processed by the mmp_toolbox software.
%
%   When the input 'para' is text (string or character vector) then the
%   output 'para' is the highest numbered profile.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2021-11-04: desiderio: initial code
%.. 2022-01-12: desiderio: added documentation
%=========================================================================

fPath = 'unpacked_data_folder';
if isstruct(para)
    fNames = fieldnames(para);
    if ~contains(fNames, fPath)
        error(['Input structure does not have field named ''' fPath '''.'])
    else
        ppath = para.(fPath);
    end
elseif ischar(para) || isstring(para)
    ppath = para;
else
    error(['Input must be either a char or string, or structure with fieldname ''' fPath '''.']) 
end
    
listingC    = sort(cellstr(ls([ppath 'C0*.TXT'])));
[~, str, ~] = fileparts(listingC{end});
profHiC     = str2double(str(2:end));

listingE    = sort(cellstr(ls([ppath 'E0*.TXT'])));
[~, str, ~] = fileparts(listingE{end});
profHiE     = str2double(str(2:end));

diffCheck = abs(profHiC-profHiE);
if diffCheck > 5
    disp('Warning! Profile numbering difference, ''C'' v. ''E'', exceeds 5.')
    disp(['[profHiC profHiE]  =  [' num2str([profHiC profHiE]) ']']);
end

answr = max([profHiC profHiE]);

if isstruct(para)
    para.number_of_profiles = answr;
else
    para = answr;
end
