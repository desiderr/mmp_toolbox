%.. plotcheck_MMP_vs_structure_data
%.. desiderio 12-feb-2020
%
%***********************************************************************
%.. MMP and ctd, flr, par structure arrays must exist in the workspace.
%.. Compares data in MMP against that in sensor structure arrays.
%***********************************************************************
%
% NOTES:
%
% L0 data are unprocessed:
%     Shifts and filters have not been applied.
%     eng L0 data will have pressure values of 0 at the start of profiles
% L1:
%     there are variants of L1 data - whether or not they have been
%     Nan-processed.
% L2:
%     pressure_bin_values, not binned pressure data, should be used in
%     plots.
%     there is other code that plots pressure_bin_values v. binned
%     pressure data as a processing check.

disp(' ');
disp('*********************************************************************');
disp('To run plotcheck_MMP_vs_structure_data.m, the following structures')
disp('must be exist in the base workspace:')
disp(' ');
disp('MMP')
disp('ctd_L0, ctd_L1, ctd_L2');
disp('eng_L0, flr_L1, flr_L2, par_L1, parL2');
disp(' ')
disp('profileNumber must also be assigned a value, then run this code as')
disp('a script with no calling arguments, eg:');
disp(' ');
disp('>> profileNumber = 137; plotcheck_MMP_vs_structure_data   ');
disp('*********************************************************************');
disp(' ');

if ~exist('profileNumber', 'var')
    return
end

figure0 = 1100;

ith = find(MMP.profiles_selected==profileNumber);
if isempty(ith)
    disp(['Profile number ' num2str(profileNumber) ' was not imported.'])
    return
end

qq = profileNumber;
%.. CTD plots
%.. .. data variables from MMP data structure
profileMask = MMP.raw_ctd_profile_indices==qq;
pressureL0     = MMP.rawvec_ctd_pressure(profileMask);
temperatureL0  = MMP.rawvec_ctd_temperature(profileMask);
conductivityL0 = MMP.rawvec_ctd_conductivity(profileMask);
oxygenL0       = MMP.rawvec_ctd_oxygen(profileMask);

pressureL1    = MMP.nan_processed_ctd_pressure(:, ith);
temperatureL1 = MMP.nan_processed_ctd_temperature(:, ith);
salinityL1    = MMP.nan_processed_ctd_salinity(:, ith);
oxygenL1      = MMP.nan_processed_ctd_oxygen(:, ith);
thetaL1       = MMP.nan_processed_ctd_theta(:, ith);
sigma_thetaL1 = MMP.nan_processed_ctd_sigma_theta(:, ith);
dpdtL1        = MMP.nan_processed_ctd_dpdt(:, ith);

%.. use the pressure bin values, not the binned pressure data
pressureL2    = MMP.ctd_pressure_bin_values;
temperatureL2 = MMP.binned_ctd_temperature(:, ith);
salinityL2    = MMP.binned_ctd_salinity(:, ith);
oxygenL2      = MMP.binned_ctd_oxygen(:, ith);
thetaL2       = MMP.binned_ctd_theta(:, ith);
sigma_thetaL2 = MMP.binned_ctd_sigma_theta(:, ith);
dpdtL2        = MMP.binned_ctd_dpdt(:, ith);

%.. ctd correspondence check

figure(1 + figure0)
plot(ctd_L0(qq).temperature, ctd_L0(qq).pressure, 'bx-');
hold on
plot(temperatureL0, pressureL0, 'ro-');
xlabel('temperature')
axis ij
ylabel('pressure [db]')
title({'TEMPERATURE' 'blue is from ctd\_L0, red from MMP'});
hold off
drawnow

figure(2 + figure0)
plot(ctd_L1(qq).temperature, ctd_L1(qq).pressure, 'bx-');
hold on
plot(temperatureL1, pressureL1, 'ro-');
xlabel('temperature')
axis ij
ylabel('pressure [db]')
title({'TEMPERATURE:' 'blue is from ctd\_L1, red from MMP'});
hold off
drawnow

figure(3 + figure0)
plot(ctd_L2(qq).temperature, ctd_L2(qq).pressure_bin_values, 'bx-');
hold on
plot(temperatureL2, pressureL2, 'ro-');
xlabel('temperature')
axis ij
ylabel('pressure [db]')
title({'TEMPERATURE:' 'blue is from ctd\_L2, red from MMP'});
hold off
drawnow

%.. ENG plots
%.. .. data variables from MMP data structure
profileMask   = MMP.raw_eng_profile_indices==qq;
engPressureL0 = MMP.rawvec_eng_pressure(profileMask);
bbackL0       = MMP.rawvec_eng_bback(profileMask);
cdomL0        = MMP.rawvec_eng_cdom(profileMask);
chlL0         = MMP.rawvec_eng_chl(profileMask);
parL0         = MMP.rawvec_eng_par(profileMask);

flrPressureL1 = MMP.nan_processed_flr_pressure(:, ith);
bbackL1       = MMP.nan_processed_flr_bback(:, ith);
cdomL1        = MMP.nan_processed_flr_cdom(:, ith);
chlL1         = MMP.nan_processed_flr_chl(:, ith);
parPressureL1 = MMP.nan_processed_par_pressure(:, ith);
parL1         = MMP.nan_processed_par_par(:, ith);

flrPressureL2 = MMP.flr_pressure_bin_values;
bbackL2       = MMP.binned_flr_bback(:, ith);
cdomL2        = MMP.binned_flr_cdom(:, ith);
chlL2         = MMP.binned_flr_chl(:, ith);
parPressureL2 = MMP.par_pressure_bin_values;
parL2          = MMP.binned_par_par(:, ith);

%.. eng-flr correspondence check
figure(4 + figure0)
plot(eng_L0(qq).chl, eng_L0(qq).pressure, 'bx-');
hold on
plot(chlL0, engPressureL0, 'ro-');
xlabel('chl')
axis ij
ylabel('pressure [db]')
title({'CHL' 'blue is from eng\_L0, red from MMP'});
hold off
drawnow

figure(5 + figure0)
plot(flr_L1(qq).chl, flr_L1(qq).pressure, 'bx-');
hold on
plot(chlL1, flrPressureL1, 'ro-');
xlabel('chl')
axis ij
ylabel('pressure [db]')
title({'CHL:' 'blue is from flr\_L1, red from MMP'});
hold off
drawnow

figure(6 + figure0)
plot(flr_L2(qq).chl, flr_L2(qq).pressure_bin_values, 'bx-');
hold on
plot(chlL2, flrPressureL2, 'ro-');
xlabel('chl')
axis ij
ylabel('pressure [db]')
title({'CHL:' 'blue is from flr\_L2, red from MMP'});
hold off
drawnow

%.. eng-par correspondence check
figure(7 + figure0)
plot(eng_L0(qq).par, eng_L0(qq).pressure, 'bx-');
hold on
plot(parL0, engPressureL0, 'ro-');
xlabel('par')
axis ij
ylabel('pressure [db]')
title({'PAR' 'blue is from eng\_L0, red from MMP'});
hold off
drawnow

figure(8 + figure0)
plot(par_L1(qq).par, par_L1(qq).pressure, 'bx-');
hold on
plot(parL1, parPressureL1, 'ro-');
xlabel('chl')
axis ij
ylabel('pressure [db]')
title({'PAR:' 'blue is from par\_L1, red from MMP'});
hold off
drawnow

figure(9 + figure0)
plot(par_L2(qq).par, par_L2(qq).pressure_bin_values, 'bx-');
hold on
plot(parL2, parPressureL2, 'ro-');
xlabel('par')
axis ij
ylabel('pressure [db]')
title({'PAR:' 'blue is from par\_L2, red from MMP'});
hold off
drawnow

commandwindow