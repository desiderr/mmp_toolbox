function bbcheck_MMP_L2_data(MMP)
%=========================================================================
% DESCRIPTION
%   Check value test for MMP L2 data
%
% USAGE:  bbcheck_MMP_L2_data(MMP)
%
%   INPUT
%      MMP is a scalar structure, the primary output of Process_OOI_McLane_CTDENG_Deployment
%
%   OUTPUT
%      Plots user-calculated MMP processed data versus Gold Standard values archived 
%      on the mmp_toolbox repo: CE09OSPM, deployment R004.
%
% DEPENDENCIES
%    maxabsdev (appended below)
%
% NOTES
%   mmp_toolbox level-of-processing designations differ from those of OOI.
%      L0: 'raw' data, no processing.
%      L1: processed data, just before binning on pressure
%      L2: binned L1 data.
%
%.. Valid only for CE09OSPM, deployment R004, calculated using the metadata
%.. text file defaults as established in the Demonstration section of the
%.. mmp_toolbox repository.
%
%.. Because Matlab automatically runs in double precision, it is expected
%.. that the difference between user (MMP) and check values will be
%.. good to single precision, even if MMP is derived from this code running
%.. in a different operating system environment from which it was developed.
%
%   % must be in a folder on the Matlab path:
%   filenameGOLD = 'WF9P_004_MMP__20220301_151321.mat';
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2021-12-30: desiderio: initial code
%.. 2022-01-12: desiderio: updated documentation
%.. 2022-03-01: desiderio: coded and implemented testDeployment function check
%=========================================================================
precision = '%.8f';

filenameGOLD = 'WF9P_004_MMP__20220301_151321.mat';  % must be in a folder on the Matlab path
GOLD = load(filenameGOLD, 'MMP');
%.. the gold standard values are contained in the MMP field of structure GOLD:
%. GOLD.MMP.(data fields)

idxProfileMax = GOLD.MMP.profiles_selected(end);
idxProfileCheck = input(['Select a profile number between 1 and ' num2str(idxProfileMax) ': ']);
disp(' ');

%.. L2 CTD section
disp('L2 (binned) ctd variables to be checked: ')
ctd = {
    'time'
    'pressure'
    'temperature'
    'conductivity'
    'salinity'
    'theta'
    'sigma_theta'
    'oxygen'
    'dpdt'
    };
disp(ctd)

ctdField = strcat('binned_ctd_', ctd);

%.. first, reality check
%.. .. the dataset generated to be tested against the GOLD standard values *must* have been generated
%.. .. using the same adjustable parameters as used in the GOLD set. This is guaranteed if the test
%.. .. set was generated following the instructions in the Getting Started section of the repo EXACTLY.
%.. ascertain whether the deployment being tested against the GOLD standard is the same deployment,
%.. and, whether the processing parameters were the same by comparing the entries in the META files
%.. archived in the META fields of structure MMP.
tf_testDeployment = testDeployment(MMP, GOLD);
if ~tf_testDeployment
    errmsg = ['Dataset to be checked against GOLD testset was not generated with the correct calfiles; ' ...
        'the correct deployment is CE09OSPM R04.'];
    error(errmsg);
end

for ii = 1:length(ctdField)
    figure(ii)
    plot(     MMP.(ctdField{1})(:, idxProfileCheck),      MMP.(ctdField{ii})(:, idxProfileCheck), 'bx-'), hold on
    plot(GOLD.MMP.(ctdField{1})(:, idxProfileCheck), GOLD.MMP.(ctdField{ii})(:, idxProfileCheck), 'ro-'), hold off
    xlabel('time (UTC)')
    ylabel(strrep(ctdField{ii}, '_', '\_'))
    title({...
        ['CE09OSPM R004 MMP L2 data check: CTD ' strrep(ctd{ii}, '_', '\_')]                                 ...
        ['Profile number ' num2str(idxProfileCheck) ' acquired on ' datestr(MMP.profile_date(idxProfileCheck), 1)] ...
        '''Gold'' Standard check values are over-plotted as red circles.'
        });
    datetick
    val = maxabsdev(MMP.(ctdField{ii})(:, idxProfileCheck), GOLD.MMP.(ctdField{ii})(:, idxProfileCheck));
    disp([ctd{ii} ': maximum absolute difference = ' num2str(val, precision)]); 
end
iFigure = get(gcf, 'Number');
fprintf('\n\n')

%.. L2 FLR section
disp('L2 (binned) flr variables to be checked: ')
flr = {
    'time'
    'pressure'
    'bback'
    'cdom'
    'chl'
    };
disp(flr)

flrField = strcat('binned_flr_', flr);

for ii = 1:length(flrField)
    figure(ii + iFigure)
    plot(     MMP.(flrField{1})(:, idxProfileCheck),      MMP.(flrField{ii})(:, idxProfileCheck), 'bx-'), hold on
    plot(GOLD.MMP.(flrField{1})(:, idxProfileCheck), GOLD.MMP.(flrField{ii})(:, idxProfileCheck), 'ro-'), hold off
    xlabel('time (UTC)')
    ylabel(strrep(flrField{ii}, '_', '\_'))
    title({...
        ['CE09OSPM R004 MMP L2 data check: FLR ' strrep(flr{ii}, '_', '\_')]                                 ...
        ['Profile number ' num2str(idxProfileCheck) ' acquired on ' datestr(MMP.profile_date(idxProfileCheck), 1)] ...
        '''Gold'' Standard check values are over-plotted as red circles.'
        });
    datetick
    val = maxabsdev(MMP.(flrField{ii})(:, idxProfileCheck), GOLD.MMP.(flrField{ii})(:, idxProfileCheck));
    disp([flr{ii} ': maximum absolute difference = ' num2str(val, precision)]); 
end
iFigure = get(gcf, 'Number');
fprintf('\n\n')

%.. L2 PAR section
disp('L2 (binned) par variables to be checked: ')
par = {
    'time'
    'pressure'
    'par'
    };
disp(par)

parField = strcat('binned_par_', par);

for ii = 1:length(parField)
    figure(ii + iFigure)
    plot(     MMP.(parField{1})(:, idxProfileCheck),      MMP.(parField{ii})(:, idxProfileCheck), 'bx-'), hold on
    plot(GOLD.MMP.(parField{1})(:, idxProfileCheck), GOLD.MMP.(parField{ii})(:, idxProfileCheck), 'ro-'), hold off
    xlabel('time (UTC)')
    ylabel(strrep(parField{ii}, '_', '\_'))
    title({...
        ['CE09OSPM R004 MMP L2 data check: PAR ' strrep(par{ii}, '_', '\_')]                                 ...
        ['Profile number ' num2str(idxProfileCheck) ' acquired on ' datestr(MMP.profile_date(idxProfileCheck), 1)] ...
        '''Gold'' Standard check values are over-plotted as red circles.'
        });
    datetick
    val = maxabsdev(MMP.(parField{ii})(:, idxProfileCheck), GOLD.MMP.(parField{ii})(:, idxProfileCheck));
    disp([par{ii} ': maximum absolute difference = ' num2str(val, precision)]); 
end
fprintf('\n\n')

end  % main

function val = maxabsdev(data1, data2)
%.. maximum absolute value of the difference between corresponding points
%.. in two datasets
val = max(abs(data1(:) - data2(:)));
end  % function val

function tf = testDeployment(MMP, GOLD)
%.. check metadata processing fields
fields2check = [1 3 4 7:9 15:43];  % didn't include binning parms, a little trickier
fields = fieldnames(MMP.META);

for ii = fields2check
    if ~strcmpi(strtrim(num2str(GOLD.MMP.META.(fields{ii}))), strtrim(num2str(MMP.META.(fields{ii}))))
        tf = false;
        return
    end
end
tf = true;
end  % function testDeployment
