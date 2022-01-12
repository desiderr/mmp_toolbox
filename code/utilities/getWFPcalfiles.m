function [para] = getWFPcalfiles(para)
%=========================================================================
% DESCRIPTION
%   Downloads OOI calfiles for a McLane profiler deployment denoted by the
%   mooring sitecode and deployment number in the input structure's fields.
%
% USAGE:  [para] = getWFPcalfiles(para)
%
%   INPUT
%     para  = a scalar structure created by running getWFPmetadata.m 
%             followed by setUpFolderStructure.m
%
%   OUTPUT
%     para  = a scalar structure with the name(s) of the calfiles contained
%             in para.calfiles and with the calfiles downloaded to the 
%             folder designated by para.calibration_folder.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-06-21: desiderio: initial code (coastal calfiles from local master)
%.. 2019-11-18: desiderio: coastal calfiles from repo
%.. 2020-04-09: desiderio: updated URLs to 'oceanobservatories'
%.. 2021-05-29: desiderio: combined coastal and global versions; now named getMcLaneCalFiles.m
%.. 2021-10-18: desiderio: added graceful exit if deployment number out of bounds
%.. 2021-10-21: desiderio: adapted for repo processing sequence; now named getWFPcalfiles.m
%.. 2022-01-12: desiderio: updated revision history and documentation
%=========================================================================

%.. add a delimiter to the end of input localFolder in case one wasn't entered
localFolder = string(para.calibration_folder);  % in case it's a string or cell

%.. urls needed to access html file(s) (to get a folder's file listing) and
%.. the files themselves in the 'calibration' and\or 'deployment' folders in
%.. the OOI Asset Management oceanobservatories GitHub repository
urlForHTML = "https://github.com/oceanobservatories/asset-management/tree/master/";
urlForFile = "https://raw.githubusercontent.com/oceanobservatories/asset-management/master/";

startDate = strrep(para.start_date, '-', '');
%.. para.sensor_uid lists all the instruments on the profiler.
%.. sensorUID lists a subset of the above, the instruments that require calfiles.
if strcmpi(para.profiler_type, 'coastal')
    sensorUID = para.sensor_uid(contains(para.sensor_uid, {'DOFSTK' 'FLORTK' 'PARADK'}));
    if isempty(sensorUID)
        disp('Warning: sensor_uid seems not to contain any sensors that require cals.');
        para.calfiles = string.empty;
        return
    end
elseif strcmpi(para.profiler_type, 'global')
    sensorUID = para.sensor_uid(contains(para.sensor_uid, 'FLORDL'));
    if isempty(sensorUID)
        disp('Warning: sensor_uid seems not to contain any sensors that require cals.');
        para.calfiles = string.empty;
        return
    end
end

calFileName(1:numel(sensorUID), 1) = "";  % in case instrument not deployed

%.. find and download the calfiles for the specified deployment
for ii = 1:length(sensorUID)
    
    sensor = sensorUID{ii}(end-11:end-6);
    sensorHTML = strcat(localFolder, sensor, '.html');

    %.. get calfile listing from the html for the directory containing cals
    websave(sensorHTML, strcat(urlForHTML, 'calibration/', sensor) );
    fid = fopen(sensorHTML);
    C = textscan(fid,'%s','whitespace','','delimiter','\n');
    fclose(fid);
    C = C{1};  % unwrap
    
    %.. select rows that have the sensorUID in them
    tf_serialNumber = contains(C, sensorUID);
    C = C(tf_serialNumber);
    %.. the calfilenames generally show up 3 times in each row. parse for the
    %.. second one (the href entry), because it is the filename on the server.
    C = split(C, 'href="', 2);
    C = C(:, 2);  % the second piece of the above split contains the href entry
    C = split(C, '"', 2);
    C = C(:, 1);  % first piece of the above split contains the href entry
    C = split(C, {'/' '\'}, 2);
    C = sort(C(:, end));  % do a sort to be sure they are in chronological order
    %.. C now has all the calfilenames for this sensor in a cell array
    
    %.. get the relevant cal - the latest cal before the startDate
    calDates = cellfun(@(x)x(21:28), C, 'uni', false);
    %.. all calfiles should have been renamed with the vendor caldate;
    %.. just in case some survived with the deployment date, use >=
    idx_cal = find(startDate >= string(calDates), 1, 'last');
    if isempty(idx_cal)
        disp(' ')
        disp('WARNING: ***********************************************')
        disp(['There are no cals for ' char(sensorUID)  ...
            ' before the deployment date ' char(startDate) '.'])
        disp('Caldates:')
        disp(string(calDates));
        disp('WARNING: ***********************************************')
        disp(' ')
        error('See warning diagnostics above.')
    end
    calFileName(ii) = string(C(idx_cal));
    
    %.. and download file to folder specified in argument list
    websave(strcat(localFolder, calFileName(ii)), ...
        strcat(urlForFile,  'calibration/', sensor, '/', calFileName(ii)) );

    %.. delete html file on localFolder
    delete(sensorHTML);
end
%.. write out checks
disp(strcat(upper(para.mooring), '_', num2str(para.deployment, '%2.2u'), ":  startDate ", ...
    startDate));
disp(calFileName);
disp(' ')

para.calfiles = calFileName';

end
%