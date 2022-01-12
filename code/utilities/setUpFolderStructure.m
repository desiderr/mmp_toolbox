function [para] = setUpFolderStructure(para)
%=========================================================================
% DESCRIPTION
%   Constructs folder structure on local machine to contain WFP data
%
% USAGE:  [para] = setUpFolderStructure(para)
%
%   INPUT
%     para  = a scalar structure created by getWFPmetadata.m
%
%   OUTPUT
%     para  = a scalar structure with fields denoting local folder names populated.
%
% NOTES
%   It is expected that this routine will be run each time a new OOI WFP dataset is to
%   be downloaded and processed. Each dataset will have its own unique folder locations
%   and paths differentiated by the mooring sitecodes, deployment numbers, and for the
%   deeper global sites where 2 profilers are deployed, the profiler location.
% 
%   Folder structure created on local machine:
%
%      initialWorkingDir
%                   |
%                   OOI_WFP
%                         |
%                         mooringSitecode
%                                       |
%                                       dplymntNmbr 
%                                                 |
%                                                 binary
%                                                 cals
%                                                 unpacked
%
%.. dplymntNmbr will always start with 'R' even when telemetered data are accessed.
%.. For the deep global sites where two profilers are deployed at the same site,
%      an 'A' for 'Above' is appended to dplymntNmbr for 'upper' profilers, and
%      a  'B' for 'Below' is appended to dplymntNmbr for 'lower' profilers.
%
%   OOI_WFP is the "tent" folder; all mooringSitecode folders will be subfolders of it.
%   Therefore the entire toolbox-generated folder structure can be deleted or moved 
%   in its entirety by manipulating the tent folder.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2021-11-04: desiderio: initial code
%.. 2022-01-12: desiderio: added documentation
%=========================================================================

wdir = strrep([pwd '/'], '\', '/');
wdir = strrep(wdir, '://', ':/'); 
disp(['Initial working directory: ' wdir])

para.working_directory = wdir;
subFolder = 'OOI_WFP/';
if isfolder(subFolder)
    disp(['Note that folder ' subFolder ' already exists.']);
    disp('This is to be expected if more than one dataset is to be processed.');
else
    mkdir(subFolder);
end
para.tent_directory = [para.working_directory subFolder];

mooringFolderName = [para.mooring '/'];
para.sitecode_folder_path = [para.tent_directory mooringFolderName];

deploymentFolderName = ['R' num2str(para.deployment, '%3.3u')];
if strcmpi(para.profiler_coverage, 'upper')
    addOn = 'A';  % A-bove
elseif strcmpi(para.profiler_coverage, 'lower')
    addOn = 'B';  % B-elow
else
    addOn = '';
end
deploymentFolderName = [deploymentFolderName addOn '/'];

wpath = [para.working_directory subFolder mooringFolderName deploymentFolderName];
para.deployment_folder_path = wpath;
mkdir(wpath)

para.binary_data_folder  = [wpath 'binary/'];
para.calibration_folder  = [wpath 'cals/'];
para.unpacked_data_folder= [wpath 'unpacked/'];

mkdir(para.binary_data_folder);
mkdir(para.calibration_folder);
mkdir(para.unpacked_data_folder);
