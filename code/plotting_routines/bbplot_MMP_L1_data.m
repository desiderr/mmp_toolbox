function bbplot_MMP_L1_data(MMP, xaxis_variable, figure0)
%=========================================================================
% DESCRIPTION
%   Creates 'scatter' plots of CTD-ENG L1 sensor data
%
% USAGE:  bbplot_MMP_L1_data(MMP[, xaxis_variable[, figure0]])
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
%   may be dominated by profiles at the start of long time intervals between 
%   them and the next profiles, depending on marker size. 
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-02-07: desiderio: initial code
%.. 2021-12-16: desiderio: added percentile caxis limits
%.. 2021-12-17: desiderio: combined coastal and global versions
%.. 2022-01-12: desiderio: updated documentation
%=========================================================================

%.. 'fast'scatter plot settings
mrkr = '.';
mrkrSize = 3;
mrkrSizePAR = 9;

%.. the interaction of nan_processed data with fastscatter throws 
%.. warning messages when the data are all nans. Suppress the warnings
%.. because these plots appear with no data as desired.
warningIdentifier = 'MATLAB:gui:array:InvalidArrayShape';
warning('off', warningIdentifier);

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

%.. specify and calculate x-axis variables before plotting.
%.. .. the numbers of points in a given profile differ for ctd and eng
%.. .. data streams because of the slower eng acquisition rate. so there
%.. .. are 4 xaxis possibilities: (ctd and eng) x (time or profile index).
timeCTD = MMP.nan_processed_ctd_time;
timeENG = MMP.nan_processed_flr_time;  % flr data are always in eng streams
profile = MMP.profiles_selected;       % indices need not be contiguous
if strcmpi(xaxis_variable, 'time')
    xVarCTD = timeCTD;
    xVarENG = timeENG;
elseif strcmpi(xaxis_variable, 'profile')
    nProfiles = numel(profile);
    [nrow, ncol] = size(timeCTD);
    if nProfiles == ncol
       xVarCTD    = repmat(profile(:)', nrow, 1);
    else
        error('Cannot plot ctd with ''profile'' as x-axis; try ''time''.');
    end
    [nrow, ncol] = size(timeENG);
    if nProfiles == ncol
        xVarENG   = repmat(profile(:)', nrow, 1);
    else
        error('Cannot plot eng with ''profile'' as x-axis; try ''time''.');
    end
else
    error('xaxis_variable must be either ''profile'' or ''time''.');
end
disp(['x-axis plot variable is ' xaxis_variable '.']);

%.. variables with processing pipelines common to both coastal and global,
%.. processed through ctd data stream
pressure    = MMP.nan_processed_ctd_pressure;
temperature = MMP.nan_processed_ctd_temperature;
salinity    = MMP.nan_processed_ctd_salinity;
theta       = MMP.nan_processed_ctd_theta;
sigma_theta = MMP.nan_processed_ctd_sigma_theta;
dpdt        = MMP.nan_processed_ctd_dpdt;
%
figure(1 + figure0)
fastscatter(xVarCTD, pressure, temperature, mrkr, 'markersize',  mrkrSize);
title('L1 temperature')
axis ij
ylabel('pressure [db]')
hCTD311 = colorbar;
title(hCTD311, '\circC');
set_caxis_limits(prctile(temperature(:), percentileLimits));
drawnow
%
figure(2 + figure0)
fastscatter(xVarCTD, pressure, salinity, mrkr, 'markersize',  mrkrSize);
title('L1 salinity')
axis ij
ylabel('pressure [db]')
hCTD312 = colorbar;
title(hCTD312, 'psu');
set_caxis_limits(prctile(salinity(:), percentileLimits));
drawnow
%
figure(3 + figure0)
fastscatter(xVarCTD, pressure, theta, mrkr, 'markersize',  mrkrSize);
title('L1 potential temperature')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, '\circC');
set_caxis_limits(prctile(theta(:), percentileLimits));
drawnow
%
figure(4 + figure0)
fastscatter(xVarCTD, pressure, sigma_theta, mrkr, 'markersize',  mrkrSize);
title('L1 potential density')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'kg/m3');
set_caxis_limits(prctile(sigma_theta(:), percentileLimits));
drawnow
%
figure(5 + figure0)
fastscatter(xVarCTD, pressure, dpdt, mrkr, 'markersize',  mrkrSize);
title('L1 profiler velocity')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'm/s');
set_caxis_limits(prctile(dpdt(:), percentileLimits));%
drawnow

%.. find oxygen data
fieldNames = fieldnames(MMP);
if ismember('nan_processed_ctd_oxygen', fieldNames)
    profiler_type = 'coastal';
    %.. Seabird oxygen sensor data are in CTD data stream
    oxygen   = MMP.nan_processed_ctd_oxygen;
    pressure = MMP.nan_processed_ctd_pressure;
    xVariable = xVarCTD;
elseif ismember('nan_processed_oxy_oxygen', fieldNames)
    profiler_type = 'global';
    %.. Aanderaa oxygen sensor data are in ENG data stream
    oxygen   = MMP.nan_processed_oxy_oxygen;
    pressure = MMP.nan_processed_oxy_pressure;
    xVariable = xVarENG;
else
    error('Could not determine profiler type.')
end
%

figure(6 + figure0)
fastscatter(xVariable, pressure, oxygen, mrkr, 'markersize',  mrkrSize);
title('L1 oxygen')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'umole/kg');
set_caxis_limits(prctile(oxygen(:), percentileLimits));
drawnow

%.. variables with processing pipelines common to both coastal and global,
%.. processed through eng data stream
pressure = MMP.nan_processed_flr_pressure;
chl      = MMP.nan_processed_flr_chl;
bback    = MMP.nan_processed_flr_bback;
%
figure(7 + figure0)
fastscatter(xVarENG, pressure, chl, mrkr, 'markersize',  mrkrSize);
title('L1 chlorophyll')
axis ij
hTriplet311 = colorbar;
title(hTriplet311, 'ug/l');
set_caxis_limits(prctile(chl(:), percentileLimits));
drawnow
%
figure(8 + figure0)
fastscatter(xVarENG, pressure, bback, mrkr, 'markersize',  mrkrSize);
title('L1 backscatter')
axis ij
hTriplet313 = colorbar;
title(hTriplet313, 'm^-1');
set_caxis_limits(prctile(bback(:), percentileLimits));
drawnow

if strcmpi(profiler_type, 'coastal')
    %.. the coastal flr fluorimeter also has a cdom sensor
    cdom = MMP.nan_processed_flr_cdom;
    figure(9 + figure0)
    fastscatter(xVarENG, pressure, cdom, mrkr, 'markersize',  mrkrSize);
    title('L1 CDOM')
    axis ij
    hTriplet312 = colorbar;
    title(hTriplet312, 'ppb');
    set_caxis_limits(prctile(cdom(:), percentileLimits));
    drawnow
    %.. the coastal profiler has a PAR sensor which detects how much
    %.. photosynthetically active radiation from the sun penetrates
    %.. the surface of the ocean.
    %
    %.. the par time and profile index records are the same as for the
    %.. flr data. the pressure data differ because the sensors are not 
    %.. mounted side-by-side.
    pressure = MMP.nan_processed_par_pressure;
    par      = MMP.nan_processed_par_par;
    figure(10 + figure0)
    fastscatter(xVarENG, pressure, par, mrkr, 'markersize',  mrkrSizePAR);
    ylim([0 60])
    title('L1 PAR')
    axis ij
    hPAR = colorbar;
    title(hPAR, 'uE/m^2/s');
    set(gca, 'ColorScale', 'log')
    set_caxis_limits(prctile(par(:), percentileLimits));
    drawnow
    nFigures = 10;
else
    %.. global profiler also has flr and oxygen sensor temperatures
    ecoTemperature = MMP.nan_processed_flr_eco_temperature;
    figure(9 + figure0)
    fastscatter(xVarENG, pressure, ecoTemperature, mrkr, 'markersize',  mrkrSize);
    title('L1 FLR eco Temperature')
    axis ij
    hTriplet312 = colorbar;
    title(hTriplet312, 'counts');
    set_caxis_limits(prctile(ecoTemperature(:), percentileLimits));
    drawnow
    %
    optodeTemperature = MMP.nan_processed_oxy_optode_temperature;
    pressure = MMP.nan_processed_oxy_pressure;
    figure(10 + figure0)
    fastscatter(xVarENG, pressure, optodeTemperature, mrkr, 'markersize',  mrkrSizePAR);
    title('L1 O2 optode Temperature')
    axis ij
    hOPTtemp = colorbar;
    title(hOPTtemp, '\circC');
    set_caxis_limits(prctile(optodeTemperature(:), percentileLimits));
    drawnow
    nFigures = 10;
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

warning('on', warningIdentifier);
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
