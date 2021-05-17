function setMeta_profiles2process(first, stride, last)
%.. 2020-05-04: desiderio: initial code
%
%
%.. setMeta_profiles2process(101, 3, 540)
%..        sets profiles_to_process value to 101:3:540
%
%.. setMeta_profiles2process(1, 3, Inf)
%..        sets profiles_to_process value to 1:3:number_of_profiles
%
%.. setMeta_profiles2process(1, [], Inf)
%..        sets profiles_to_process value to [],
%..        which will process all profiles
%
%     CHANGE THE WORKING DIRECTORY TO WHERE THE METADATA FILES RESIDE

if nargin~=3
    disp(' ')
    disp(['Usage: ' mfilename '(first, stride, last)'])
    disp(' ')
    disp('  if any entry is [] then all profiles are processed:')
    disp('  ([] is written as the profiles_to_process value).');
    disp(' ')
    disp('  if last==Inf then last is set to file''s number_of_profiles value.');
    disp(' ');
    return
end

disp(' ')
listing = sort(cellstr(ls('metadata*.txt')));
for ii = 1:length(listing)
    filename = listing{ii};
    fid = fopen(filename, 'rt');
    C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
    fclose(fid);
    C=C{1};
    
%     %.. should not be any metadata lines starting with 'aqd'!
%     tf_aqd = strncmp(C, 'aqd', 3);
%     C(tf_aqd) = [];

%     %.. this version deletes comments on output
%     tf_commentLine = strncmp(C, '%', 1);
%     C(tf_commentLine) = [];

    tf_numberOfProfiles  = strncmp(C, 'number_of_profiles', 18);
    tf_profilesToProcess = strncmp(C, 'profiles_to_process', 19);
    disp(filename)
    disp(C{tf_numberOfProfiles})
    disp(C{tf_profilesToProcess})
    disp('    CHANGED TO:')
    
    if numel([first stride last]) < 3  % then at least one of the entries is []
        C{tf_profilesToProcess} = 'profiles_to_process = []';
    else
        if isinf(last)
            eval([C{tf_numberOfProfiles} ';']);
            nProfiles = num2str(number_of_profiles);
        else
            nProfiles = last;
        end
        
        if nProfiles<first
            error('last profile number must not be less than first.')
        end
        
        a = [num2str(first) ':'];
        b = [num2str(stride) ':'];
        c = num2str(nProfiles);       
        C{tf_profilesToProcess} = ['profiles_to_process = ' a b c];
    end
    disp(C{tf_profilesToProcess})
    disp(' ')
    
    %.. write out
    fid = fopen(filename, 'w');
    for jj = 1:length(C)
        fprintf(fid, '%s\r\n', C{jj});
    end
    fclose(fid);
end

