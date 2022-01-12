function bbplot_MMP_L0_data(MMP, xaxis_variable, figure0)
%=========================================================================
% DESCRIPTION
%   Creates 'scatter' plots of CTD-ENG L0 sensor data
%
% USAGE:  bbplot_MMP_L0_data(MMP[, xaxis_variable[, figure0]])
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
mrkrSize = 2;
mrkrSizePAR = 9;

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

%.. specify x-axis variables before plotting.
%.. .. the numbers of points in a given profile differ for ctd and eng
%.. .. data streams because of the slower eng acquisition rate. so there
%.. .. are 4 xaxis possibilities: (ctd and eng) x (time or profile index).
if strcmpi(xaxis_variable, 'time')
    xVarCTD = MMP.rawvec_ctd_time;
    xVarENG = MMP.rawvec_eng_time;
elseif strcmpi(xaxis_variable, 'profile')
    xVarCTD = MMP.raw_ctd_profile_indices;
    xVarENG = MMP.raw_eng_profile_indices;
else
    error('xaxis_variable must be either ''profile'' or ''time''.');
end
disp(['x-axis plot variable is ' xaxis_variable '.']);

%.. variables with processing pipelines common to both coastal and global,
%.. processed through ctd data stream
pressure     = MMP.rawvec_ctd_pressure;
temperature  = MMP.rawvec_ctd_temperature;
conductivity = MMP.rawvec_ctd_conductivity;
figure(1 + figure0)
fastscatter(xVarCTD, pressure, temperature, mrkr, 'markersize',  mrkrSize);
title('L0 temperature')
axis ij
ylabel('pressure [db]')
hCTD311 = colorbar;
title(hCTD311, '\circC');
set_caxis_limits(prctile(temperature(:), percentileLimits));
drawnow
%
figure(2 + figure0)
fastscatter(xVarCTD, pressure, conductivity, mrkr, 'markersize',  mrkrSize);
title('L0 conductivity')
axis ij
ylabel('pressure [db]')
hCTD312 = colorbar;
title(hCTD312, 'mS/cm');
set_caxis_limits(prctile(conductivity(:), percentileLimits));
drawnow

%.. find oxygen data
fieldNames = fieldnames(MMP);
if ismember('rawvec_ctd_oxygen', fieldNames)
    profiler_type = 'coastal';
    %.. Seabird oxygen sensor data are in CTD data stream
    oxygen   = MMP.rawvec_ctd_oxygen;
    pressure = MMP.rawvec_ctd_pressure;
    xVariable = xVarCTD;
    unitsO2   = 'Hz';
elseif ismember('rawvec_eng_oxygen', fieldNames)
    profiler_type = 'global';
    %.. Aanderaa oxygen sensor data are in ENG data stream
    oxygen   = MMP.rawvec_eng_oxygen;
    pressure = MMP.rawvec_eng_pressure;
    xVariable = xVarENG;
    unitsO2   = 'uM';
else
    error('Could not determine profiler type.')
end

figure(3 + figure0)
fastscatter(xVariable, pressure, oxygen, mrkr, 'markersize',  mrkrSize);
title('L0 oxygen')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, unitsO2);
set_caxis_limits(prctile(oxygen(:), percentileLimits));
drawnow

%.. variables with processing pipelines common to both coastal and global,
%.. processed through eng data stream
pressure = MMP.rawvec_eng_pressure;
chl      = MMP.rawvec_eng_chl;
bback    = MMP.rawvec_eng_bback;
%
figure(4 + figure0)
fastscatter(xVarENG, pressure, chl, mrkr, 'markersize',  mrkrSize);
title('L0 chlorophyll')
axis ij
hTriplet311 = colorbar;
title(hTriplet311, 'counts');
set_caxis_limits(prctile(chl(:), percentileLimits));
drawnow
%
figure(5 + figure0)
fastscatter(xVarENG, pressure, bback, mrkr, 'markersize',  mrkrSize);
title('L0 backscatter')
axis ij
hTriplet312 = colorbar;
title(hTriplet312, 'counts');
set_caxis_limits(prctile(bback(:), percentileLimits));
drawnow
%
if strcmpi(profiler_type, 'coastal')
    cdom = MMP.rawvec_eng_cdom;
    figure(6 + figure0)
    fastscatter(xVarENG, pressure, cdom, mrkr, 'markersize',  mrkrSize);
    title('L0 CDOM')
    axis ij
    hTriplet312 = colorbar;
    title(hTriplet312, 'counts');
    set_caxis_limits(prctile(cdom(:), percentileLimits));
    drawnow
    %.. the coastal profiler has a PAR sensor which detects how much
    %.. photosynthetically active radiation from the sun penetrates
    %.. the surface of the ocean.
    %
    %.. the par time and profile index records are the same as for the
    %.. flr data. the pressure data differ because the sensors are not 
    %.. mounted side-by-side.
    par      = MMP.rawvec_eng_par;
    pressure = MMP.rawvec_eng_pressure;
    figure(7 + figure0)
    fastscatter(xVarENG, pressure, par, mrkr, 'markersize',  mrkrSizePAR);
    ylim([0 60])
    title('L0 PAR')
    axis ij
    hPAR = colorbar;
    title(hPAR, 'mV');
    %set(gca, 'ColorScale', 'log')
    set_caxis_limits(prctile(par(:), percentileLimits));
    drawnow
    nFigures = 7;
else
    %.. global profiler also has flr and oxygen sensor temperatures
    ecoTemperature = MMP.rawvec_eng_eco_temperature;
    figure(6 + figure0)
    fastscatter(xVarENG, pressure, ecoTemperature, mrkr, 'markersize',  mrkrSize);
    title('L0 FLR eco Temperature')
    axis ij
    hTriplet312 = colorbar;
    title(hTriplet312, 'counts');
    set_caxis_limits(prctile(ecoTemperature(:), percentileLimits));
    drawnow
    %
    optodeTemperature = MMP.rawvec_eng_optode_temperature;
    pressure = MMP.rawvec_eng_pressure;
    figure(7 + figure0)
    fastscatter(xVarENG, pressure, optodeTemperature, mrkr, 'markersize',  mrkrSizePAR);
    title('L0 O2 optode Temperature')
    axis ij
    hOPTtemp = colorbar;
    title(hOPTtemp, '\circC');
    set_caxis_limits(prctile(optodeTemperature(:), percentileLimits));
    drawnow
    nFigures = 7;
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
