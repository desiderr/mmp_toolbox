function bbplot_MMP_L2_data(MMP, xaxis_variable, figure0)
%=========================================================================
% DESCRIPTION
%   Creates 'pcolor' plots of CTD-ENG L2 sensor data
%
% USAGE:  bbplot_MMP_L2_data(MMP[, xaxis_variable[, figure0]])
%
%   INPUT
%      MMP is a scalar structure, the primary output of Process_OOI_McLane_CTDENG_Deployment
%
%      xaxis_variable [optional] can be either 'profile' (number) or 'time'
%         DEFAULT: 'profile'
%
%      figure0 [optional] is a non-negative integer setting the figure number offset
%         DEFAULT: 0
%
% DEPENDENCIES
%   set_caxis_limits (appended below)  
%
% NOTES
%   mmp_toolbox level-of-processing designations differ from those of OOI.
%      L0: 'raw' data, no processing.
%      L1: processed data, just before binning on pressure
%      L2: binned L1 data.
%
%   The figure offset figure0 is provided to provide a command line figure 
%   numbering mechanism so that consecutive runs of this code won't necessarily 
%   result in the plots of the second run overwriting those of the first.
%
%   For many deployments the profiles are not equally spaced in time; rather, 
%   pairs of profiles are scheduled to be equally spaced in time. This results
%   in a small temporal spacing between the first (usually ascending) and second
%   usually descending) profile in a pair, followed by a much larger spacing
%   between the last profile of a pair and the first profile of the next pairing.
%
%   For this reason when the xaxis_variable is 'time', overall plot coloration 
%   will be dominated by profiles at the start of long time intervals between 
%   them and the next profiles.
%
%   When the xaxis_variable is 'profile', ascending and descending profiles
%   will be equally weighted with respect to plot coloration if the difference
%   in the profile numbers is a constant.
%
%   As an example, compare 'time' and 'profile' pcolor plots 
%   of *coastal* profiler velocity dp/dt.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-02-07: desiderio: initial code
%.. 2021-12-15: desiderio: combined coastal and global versions
%.. 2021-12-16: desiderio: added percentile caxis limits
%.. 2022-01-12: desiderio: updated documentation
%=========================================================================

main = mfilename;
if nargin==3
    %.. all set
elseif nargin==2
    figure0 = 0;
elseif nargin==1
    figure0 = 0;
    xaxis_variable = 'profile';
else
    disp(' ');
    disp('USAGE (needs at least one calling argument):');
    disp(['  ' main '(MMP)']);
    disp(['  ' main '(MMP, x-axisVariable)']);
    disp(['  ' main '(MMP, x-axisVariable, figureNumberOffset)']);
    disp(' ');
    disp('x-axisVariable [optional] can either be ''profile'' (default) or ''time''.');
    disp('figureNumberOffset [optional] is a positive integer (default = 0).');
    return
end

%.. for specifying plot datacolor limits
percentileLimits = [2 98];

%.. the "time" of each profile is a scalar determined by the nanmedian value of the
%.. engineering time record.
time            = MMP.profile_date;
profile         = MMP.profiles_selected;
disp(['x-axis plot variable is ' xaxis_variable '.']);
if strcmpi(xaxis_variable, 'profile')
    xVariable = profile;
else
    xVariable = time;
end
if length(profile)==1
    disp('PCOLOR PLOTS REQUIRE MORE THAN ONE PROFILE.');
    disp(['PROGRAM ' main ' TERMINATED.']);
    return
end

%.. variables with processing pipelines common to both coastal and global,
%.. processed through ctd data stream
pressure    = MMP.ctd_pressure_bin_values;
temperature = MMP.binned_ctd_temperature;
salinity    = MMP.binned_ctd_salinity;
theta       = MMP.binned_ctd_theta;
sigma_theta = MMP.binned_ctd_sigma_theta;
dpdt        = MMP.binned_ctd_dpdt;
%
figure(1 + figure0)
pcolor(xVariable, pressure, temperature);
shading flat
title('L2 temperature')
axis ij
ylabel('pressure [db]')
hCTD311 = colorbar;
title(hCTD311, '\circC');
set_caxis_limits(prctile(temperature(:), percentileLimits));
drawnow
%
figure(2 + figure0)
pcolor(xVariable, pressure, salinity);
shading flat
title('L2 salinity')
axis ij
ylabel('pressure [db]')
hCTD312 = colorbar;
title(hCTD312, 'psu');
set_caxis_limits(prctile(salinity(:), percentileLimits));
drawnow
%
figure(3 + figure0)
pcolor(xVariable, pressure, theta);
shading flat
title('L2 potential temperature')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, '\circC');
set_caxis_limits(prctile(theta(:), percentileLimits));
drawnow
%
figure(4 + figure0)
pcolor(xVariable, pressure, sigma_theta);
shading flat
title('L2 potential density')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'kg/m3');
set_caxis_limits(prctile(sigma_theta(:), percentileLimits));
drawnow
%
figure(5 + figure0)
pcolor(xVariable, pressure, dpdt);
shading flat
title('profiler velocity')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'm/s');
set_caxis_limits(prctile(dpdt(:), percentileLimits));
drawnow

%.. determine OOI instrument suite
fieldNames = fieldnames(MMP);
if ismember('binned_ctd_oxygen', fieldNames)
    profiler_type = 'coastal';
    %.. Seabird oxygen sensor data are in CTD data stream
    oxygen       = MMP.binned_ctd_oxygen;
    pressure     = MMP.ctd_pressure_bin_values;  % for clarity
elseif ismember('binned_oxy_oxygen', fieldNames)
    profiler_type = 'global';
    %.. Aanderaa oxygen sensor data are in ENG data stream
    oxygen        = MMP.binned_oxy_oxygen;
    pressure      = MMP.oxy_pressure_bin_values;
else
    error('Could not determine profiler type.')
end
%
figure(6 + figure0)
pcolor(xVariable, pressure, oxygen);
shading flat
title('L2 oxygen')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'umole/kg');
set_caxis_limits(prctile(oxygen(:), percentileLimits));
drawnow

%.. variables with processing pipelines common to both coastal and global,
%.. processed through eng data stream
pressure = MMP.flr_pressure_bin_values;
chl      = MMP.binned_flr_chl;
bback    = MMP.binned_flr_bback;
%
figure(7 + figure0)
pcolor(xVariable, pressure, chl);
shading flat
title('L2 chlorophyll')
axis ij
hTriplet311 = colorbar;
title(hTriplet311, 'ug/l');
set_caxis_limits(prctile(chl(:), percentileLimits));
drawnow
%
figure(8 + figure0)
pcolor(xVariable, pressure, bback);
shading flat
title('L2 backscatter')
axis ij
hTriplet313 = colorbar;
title(hTriplet313, 'm^-1');
set_caxis_limits(prctile(bback(:), percentileLimits));
drawnow

if strcmpi(profiler_type, 'coastal')
    %.. the coastal flr fluorimeter also has a cdom sensor
    cdom = MMP.binned_flr_cdom;
    figure(9 + figure0)
    pcolor(xVariable, pressure, cdom);
    shading flat
    title('L2 CDOM')
    axis ij
    hTriplet312 = colorbar;
    title(hTriplet312, 'ppb');
    set_caxis_limits(prctile(cdom(:), percentileLimits));
    drawnow
    %.. the coastal profiler has a PAR sensor which detects how much
    %.. photosynthetically active radiation from the sun penetrates 
    %.. the surface of the ocean
    pressure = MMP.par_pressure_bin_values;
    par      = MMP.binned_par_par;
    figure(10 + figure0)
    pcolor(xVariable, pressure, par);
    ylim([0 60])
    shading flat
    title('L2 PAR')
    axis ij
    hPAR = colorbar;
    title(hPAR, 'uE/m^2/s');
    set(gca, 'ColorScale', 'log')
    set_caxis_limits(prctile(par(:), percentileLimits));
    drawnow
    nFigures = 10;
else
    %.. the global profilers have O2 optode temperature, good for diagnostics
    optodeTemperature = MMP.binned_oxy_optode_temperature;
    pressure = MMP.oxy_pressure_bin_values;
    figure(9 + figure0)
    pcolor(xVariable, pressure, optodeTemperature);
    shading flat
    title('L2 O2 optode Temperature')
    axis ij
    hOPTtemp = colorbar;
    title(hOPTtemp, '\circC');
    set_caxis_limits(prctile(optodeTemperature(:), percentileLimits));
    drawnow
    nFigures = 9;
end

%.. add the deployment ID to the titles
depID = MMP.Deployment_ID;
if depID(end)=='_', depID(end)=[]; end
depID = strrep(depID, '_', '\_');
%.. label the x-axis 
dateFormat = 'mm-yyyy';
for ii = nFigures:-1:1                % reset the figure foci order
    figure(ii + figure0)
    if strcmpi(xaxis_variable, 'time')
        datetick('x', dateFormat, 'keepLimits')
    else
        xlabel('profile number');
    end
    h = get(gca);
    h.Title.String = append(h.Title.String, ':  ', depID); 
end
commandwindow
end

function set_caxis_limits(limits)
%.. desiderio 2021-12-21
%.. trap out occurrences of no data
%.. (all fill values or all Nans)
if any(isnan(limits))
    %.. don't call caxis; use matlab defaults
    return
elseif limits(1) == limits(2)
    return
else
    caxis(limits);
end
end
