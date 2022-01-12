function bbcheck_MMP_L0_data(MMP)
%=========================================================================
% DESCRIPTION
%   Check value test for MMP L0 data
%
% USAGE:  bbcheck_MMP_L0_data(MMP)
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
%   filenameGOLD = 'WF9P_004_MMP__20211228_160410.mat';
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2022-01-03: desiderio: initial code
%.. 2022-01-12: desiderio: updated documentation
%=========================================================================

precision = '%.8f';

filenameGOLD = 'WF9P_004_MMP__20211228_160410.mat';  % must be in a folder on the Matlab path
GOLD = load(filenameGOLD, 'MMP');
%.. the gold standard values are contained in the MMP field of structure GOLD:
%. GOLD.MMP.(data fields)

idxProfileMax = GOLD.MMP.profiles_selected(end);
idxProfileCheck = input(['Select a profile number between 1 and ' num2str(idxProfileMax) ': ']);
disp(' ');

%.. L0 CTD section
disp('L0 (raw data) ctd variables to be checked: ')
ctd = {
    'time'
    'pressure'
    'temperature'
    'conductivity'
    'oxygen'
    };
disp(ctd)

ctdField = strcat('rawvec_ctd_', ctd);

%.. first, reality check.
%.. .. the dataset generated to be tested against the GOLD standard values *must* have been generated
%.. .. using the same adjustable parameters as used in the GOLD set. This is guaranteed if the test
%.. .. set was generated following the instructions in the Getting Started section of the repo EXACTLY.
%.. to forestall obvious incompatibilities
[sizeTest] = size(MMP.rawvec_ctd_time);
[sizeGold] = size(GOLD.MMP.rawvec_ctd_time);
if ~all(sizeTest==sizeGold)
    error('Dataset to be checked against GOLD testset values was not generated correctly.')
end

%.. the L0 data in the MMP L0 fields consist of column vectors, so that, for example, raw ctd temperature
%.. values for the entire deployment have been concatenated into one long column vector. the profile
%.. numbers for each point are also given in a correspondingly long column vector.
tf_inCTDprofile =  MMP.raw_ctd_profile_indices==idxProfileCheck; 
for ii = 1:length(ctdField)
    figure(ii)
    plot(     MMP.(ctdField{1})(tf_inCTDprofile),      MMP.(ctdField{ii})(tf_inCTDprofile), 'bx-'), hold on
    plot(GOLD.MMP.(ctdField{1})(tf_inCTDprofile), GOLD.MMP.(ctdField{ii})(tf_inCTDprofile), 'ro-'), hold off
    xlabel('time (UTC)')
    ylabel(strrep(ctdField{ii}, '_', '\_'))
    title({...
        ['CE09OSPM R004 MMP L0 data check: CTD ' strrep(ctd{ii}, '_', '\_')]                                 ...
        ['Profile number ' num2str(idxProfileCheck) ' acquired on ' datestr(MMP.profile_date(idxProfileCheck), 1)] ...
        '''Gold'' Standard check values are over-plotted as red circles.'
        });
    datetick
    val = maxabsdev(MMP.(ctdField{ii})(tf_inCTDprofile), GOLD.MMP.(ctdField{ii})(tf_inCTDprofile));
    disp([ctd{ii} ': maximum absolute difference = ' num2str(val, precision)]); 
end
iFigure = get(gcf, 'Number');
fprintf('\n\n')

%.. L0 ENG section
disp('L0 (raw data) eng (for coastal, flr and par) variables to be checked: ')
eng = {
    'time'
    'pressure'
    'bback'
    'cdom'
    'chl'
    'par'
    };
disp(eng)
engField = strcat('rawvec_eng_', eng);

tf_inENGprofile =  MMP.raw_eng_profile_indices==idxProfileCheck; 
for ii = 1:length(engField)
    figure(ii + iFigure)
    plot(     MMP.(engField{1})(tf_inENGprofile),      MMP.(engField{ii})(tf_inENGprofile), 'bx-'), hold on
    plot(GOLD.MMP.(engField{1})(tf_inENGprofile), GOLD.MMP.(engField{ii})(tf_inENGprofile), 'ro-'), hold off
    xlabel('time (UTC)')
    ylabel(strrep(engField{ii}, '_', '\_'))
    title({...
        ['CE09OSPM R004 MMP L0 data check: ENG ' strrep(eng{ii}, '_', '\_')]                                 ...
        ['Profile number ' num2str(idxProfileCheck) ' acquired on ' datestr(MMP.profile_date(idxProfileCheck), 1)] ...
        '''Gold'' Standard check values are over-plotted as red circles.'
        });
    datetick
    val = maxabsdev(MMP.(engField{ii})(tf_inENGprofile), GOLD.MMP.(engField{ii})(tf_inENGprofile));
    disp([eng{ii} ': maximum absolute difference = ' num2str(val, precision)]); 
end
fprintf('\n\n')

end  % main

function val = maxabsdev(data1, data2)
%.. maximum absolute value of the difference between corresponding points
%.. in two datasets
val = max(abs(data1(:) - data2(:)));
end




