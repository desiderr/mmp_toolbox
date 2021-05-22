%.. setMetadataFileEntries.m
%.. 2020-04-20: desiderio: initial code
%.. 2021-05-07: desiderio: simplified, now easier to use
%.. 2021-05-10: desiderio: made sure comment lines are ignored
%
%.. modifies all the radMMP metadata text files in the working directory
%.. by changing metadata values within the file. 
%
%.. modify as needed

%     CHANGE THE WORKING DIRECTORY TO WHERE THE METADATA FILES RESIDE

setting = {
    'backtrack_processing_flag = 3'
    'correct_velU_for_dpdt = 0'
    'correct_velY_for_wag  = 0'
%    'acm_binning_parameters = [25 0.5 125]'
%    'ctd_binning_parameters = [25 0.5 125]'
%    'eng_binning_parameters = [25 2.0 125]'
    'acm_nptsMin              = 160'
    'ctd_pressure_nptsMin     = 80'
    'ctd_pressure_rangeMin_db = 20'
    'eng_pressure_nptsMin     = 10'
    'eng_pressure_rangeMin_db = 20'
    'eng_pressure_valueMin_db = 10'
    'profiles_to_process      = []'
    };

%.. create a cell array containing just the setting names
idx = strfind(setting, '=');
settingName = strtrim(cellfun(@(x,y)x(1:y-1), setting, idx, 'uni', 0));

listing = sort(cellstr(ls('metadata*.txt')));
for ii = 1:length(listing)
    filename = listing{ii};
    
%     %.. backup
%     copiedName = strrep(filename, '.txt', '.bak');
%     copyfile(filename, copiedName);
    
    fid = fopen(filename, 'rt');
    C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
    fclose(fid);
    C=C{1};
    
    %.. find comment lines so that they will be excluded
    tf_comment = strncmp(C, '%', 1);
    
    for jj = 1:length(setting)
        tf_entry = contains(C, settingName{jj});
        C(tf_entry & ~tf_comment) = setting(jj);
    end

%.. write out
    fid = fopen(filename, 'w');
    for jj = 1:length(C)
        fprintf(fid, '%s\r\n', C{jj});
    end
    fclose(fid);
end

