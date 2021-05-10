%.. readMeta_template.m
%.. 2021-05-04: desiderio: initial code
%
%.. reads all the radMMP metadata text files in the working directory
%.. and writes the entries chosen at program top to the screen.

%     CHANGE THE WORKING DIRECTORY TO WHERE THE METADATA FILES RESIDE

entries = {
    'number_of_profiles'
    'profiles_to_process'
    'backtrack_processing_flag'
    'correct_velY_for_wag'
    'correct_velXYZ_for_pitch_and_roll'
    'correct_velU_for_dpdt'
    };
nQueries = length(entries);

disp(' ')
listing = sort(cellstr(ls('metadata*.txt')));
for ii = 1:length(listing)
    filename = listing{ii};
    fid = fopen(filename, 'rt');
    C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
    fclose(fid);
    C=C{1};
    
    tf_commentLine = strncmp(C, '%', 1);
    C(tf_commentLine) = [];
    
    disp(filename)
    for jj = 1:nQueries
        tf_query  = contains(C, entries{jj});
        disp(C{tf_query})
    end
    disp(' ')
end
