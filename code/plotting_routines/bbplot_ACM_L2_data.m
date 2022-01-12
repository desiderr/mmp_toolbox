function bbplot_ACM_L2_data(ACM, xaxis_variable, figure0)
%=========================================================================
% DESCRIPTION
%   Creates 'pcolor' plots of ACM L2 sensor data
%
% USAGE:  bbplot_ACM_L2_data(ACM[, xaxis_variable[, figure0]])
%
%   INPUT
%      ACM is a scalar structure, the primary output of either MAIN:
%         Process_McLane_AD2CP_Deployment.m     (for coastal profilers)
%         Process_McLane_FSIACM_Deployment.m    (for global profilers)
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
%.. 2020-02-08: desiderio: initial code
%.. 2021-12-21: desiderio: combined coastal and global versions
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
    disp(['  ' main '(ACM)']);
    disp(['  ' main '(ACM, x-axisVariable)']);
    disp(['  ' main '(ACM, x-axisVariable, figureNumberOffset)']);
    disp(' ');
    disp('x-axisVariable [optional] can either be ''profile'' (default) or ''time''.');
    disp('figureNumberOffset [optional] is a positive integer (default = 0).');
    return
end

%.. for specifying datacolor limits for some plots
percentileLimits = [2 98];

%.. the "time" of each profile is a scalar determined by the nanmedian value
%.. of the engineering time record.
time            = ACM.profile_date;
profile         = ACM.profiles_selected;
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

APBV  = ACM.acm_pressure_bin_values;
%.. data common to both coastal and global
H     = ACM.binned_acm_heading;
E     = ACM.binned_acm_velENU(:, :, 1);
N     = ACM.binned_acm_velENU(:, :, 2);
U     = ACM.binned_acm_velENU(:, :, 3);
PV    = ACM.binned_acm_dpdt;  % profiler velocity

figure(1 + figure0)
pcolor(xVariable, APBV, H);
shading flat
title('heading')
ylabel('pressure [db]')
axis ij
colormap(hsv)
hcb = colorbar;
title(hcb, 'deg');
caxis([0 360])

figure(2 + figure0)
pcolor(xVariable, APBV, E);
shading flat
title('velEAST')
ylabel('pressure [db]')
axis ij
hcb = colorbar;
title(hcb, 'm/s')
caxis([-0.3 0.3])

figure(3 + figure0)
pcolor(xVariable, APBV, N);
shading flat
axis ij
ylabel('pressure [db]')
title('velNORTH')
hcb = colorbar;
title(hcb, 'm/s')
caxis([-0.3 0.3])

figure(4 + figure0)
pcolor(xVariable, APBV, U);
shading flat
title('velUP')
ylabel('pressure [db]')
axis ij
hcb = colorbar;
title(hcb, 'm/s')
caxis([-0.3 0.3])

figure(5 + figure0)
pcolor(xVariable, APBV, PV);
shading flat
title('Profiler Velocity')
ylabel('pressure [db]')
axis ij
hcb = colorbar;
title(hcb, 'm/s')
caxis([-0.3 0.3])

nFigures = 5;
fieldNames = fieldnames(ACM);
if ismember('binned_acm_aqd_temperature', fieldNames)
    %.. coastal
    AT = ACM.binned_acm_aqd_temperature;
    figure(6 + figure0)
    pcolor(xVariable, APBV, AT);
    shading flat
    title('AD2CP temperature sensor');
    ylabel('pressure [db]')
    axis ij
    hcb = colorbar;
    title(hcb, '\circC')
    set_caxis_limits(prctile(AT(:), percentileLimits));
    nFigures = nFigures + 1;
elseif sum(ismember(fieldNames, {'binned_acm_TY' 'binned_acm_TX'})) == 2
    %.. global
    TX = ACM.binned_acm_TX;
    TY = ACM.binned_acm_TY;
    %.. extremely high values of tilt can denote 'blowdown' events 
    %.. use TT as a metric
    PT = sqrt(TX.*TX + TY.*TY);
    figure(6 + figure0)
    pcolor(xVariable, APBV, PT);
    shading flat
    title('FSIACM: Pythagorean Tilt');
    ylabel('pressure [db]')
    axis ij
    hcb = colorbar;
    title(hcb, 'deg')
    caxis([0 20])
    nFigures = nFigures + 1; 
end

%.. add the deployment ID to the titles
depID = ACM.Deployment_ID;
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
