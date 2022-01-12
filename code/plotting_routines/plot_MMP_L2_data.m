function plot_MMP_L2_data(MMP, figure0, cclimIN)
%.. desiderio 07-feb-2020 added par; theta, sigmaTheta, dpdt
%.. desiderio 04-may-2021 added optional 3rd input, for when called
%..                       by master processing scripts (processing multiple
%..                       deployments).
%
%.. cclimIN is a structure containing plot limits: see cclim, following
%
%.. creates 'pcolor' plots of L2 sensor data
%
% MMP     is the output of Process_McLane_WFP_Deployment
% figure0 is optional and sets the figure number sequence
% cclimIN is optional and overwrites the default pcolor "caxis" plot limits.

%.. xaxis_variable can be either 'time' or 'profile';
xaxis_variable = 'time';

%.. .. default plotting parameters (for ce09ospm)
cclim.Temperature = [4 12];       % degC
cclim.Salinity    = [32 34.5];    % psu
cclim.Oxygen      = [0 250];      % umole/kg
cclim.Theta       = [4 12];       % degC
cclim.SigmaTheta  = [25 27.5];  % kg/m3
cclim.DpDt        = [-0.4 0.4];   % m/s
%.. .. more plotting parameters
cclim.Chl         = [0 1];        % ug/l
cclim.CDOM        = [0 3];        % ppb
cclim.Bback       = [0 0.005];    % m^-1
%.. limits for log plot
cclim.PAR         = [1 100];      % microEinsteins/m^2/s

if nargin==0
    disp(' ');
    disp('USAGE (needs at least one calling argument):');
    disp('plot_MMP_L2_data(MMP)');
    disp('plot_MMP_L2_data(MMP, figureNumberOffset)');
    disp('plot_MMP_L2_data(MMP, figureNumberOffset, cclimIN)');
    disp(' ');
    return
elseif nargin==1
    figure0 = 100;
elseif nargin==2
    %.. nothing needs be done
elseif nargin==3
    cclim = cclimIN;
end

%.. changed the name of the structure field denoting date of profile
%.. from 'datenum' to 'profile_date'. older MMP variables use 'datenum',
%.. currently 'profile_date' is used. for backwards compatibility:
fieldNames      = fieldnames(MMP);
tf_datenum      = strcmp(fieldNames, 'datenum');
tf_profile_date = strcmp(fieldNames, 'profile_date'); 
time            = MMP.(fieldNames{tf_datenum|tf_profile_date});
profile         = MMP.profiles_selected;

disp(['pcolor x-axis variable is ' xaxis_variable '.']);
if strcmpi(xaxis_variable, 'profile')
    xVariable = profile;
else
    xVariable = time;
end

if length(profile)==1
    disp('PCOLOR PLOTS REQUIRE MORE THAN ONE PROFILE.');
    disp('PROGRAM plot_MMP_L2_data TERMINATED.');
    return
end

pressure    = MMP.ctd_pressure_bin_values;
temperature = MMP.binned_ctd_temperature;
salinity    = MMP.binned_ctd_salinity;
oxygen      = MMP.binned_ctd_oxygen;
theta       = MMP.binned_ctd_theta;
sigma_theta = MMP.binned_ctd_sigma_theta;
dpdt        = MMP.binned_ctd_dpdt;


figure(1 + figure0)
pcolor(xVariable, pressure, temperature);
shading flat
title('L2 temperature')
axis ij
ylabel('pressure [db]')
hCTD311 = colorbar;
title(hCTD311, '\circC');
caxis(cclim.Temperature)
%
drawnow

figure(2 + figure0)
pcolor(xVariable, pressure, salinity);
shading flat
title('L2 salinity')
axis ij
ylabel('pressure [db]')
hCTD312 = colorbar;
title(hCTD312, 'psu');
caxis(cclim.Salinity)
%
drawnow

figure(3 + figure0)
pcolor(xVariable, pressure, oxygen);
shading flat
title('L2 oxygen')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'umole/kg');
caxis(cclim.Oxygen)

drawnow

figure(4 + figure0)
pcolor(xVariable, pressure, theta);
shading flat
title('L2 potential temperature')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, '\circC');
caxis(cclim.Theta)
%
drawnow

figure(5 + figure0)
pcolor(xVariable, pressure, sigma_theta);
shading flat
title('L2 potential density')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'kg/m3');
caxis(cclim.SigmaTheta)
%
drawnow

figure(6 + figure0)
pcolor(xVariable, pressure, dpdt);
shading flat
title('L2 profiler velocity')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'm/s');
caxis(cclim.DpDt)
%
drawnow

%.. ECO-TRIPLET plots
%.. .. data variables from MMP data structure
% time same as ctd
pressure = MMP.flr_pressure_bin_values;      % different
chl      = MMP.binned_flr_chl;
cdom     = MMP.binned_flr_cdom;
bback    = MMP.binned_flr_bback;
%
figure(7 + figure0)
pcolor(xVariable, pressure, chl);
shading flat
title('L2 chlorophyll')
axis ij
hTriplet311 = colorbar;
title(hTriplet311, 'ug/l');
caxis(cclim.Chl)
%
figure(8 + figure0)
pcolor(xVariable, pressure, cdom);
shading flat
title('L2 CDOM')
axis ij
hTriplet312 = colorbar;
title(hTriplet312, 'ppb');
caxis(cclim.CDOM)
%
figure(9 + figure0)
pcolor(xVariable, pressure, bback);
shading flat
title('L2 backscatter')
axis ij
hTriplet313 = colorbar;
title(hTriplet313, 'm^-1');
caxis(cclim.Bback)


%.. PAR plot
%.. .. data variables from MMP data structure
% time same as ctd
pressure = MMP.par_pressure_bin_values;      % different
par      = MMP.binned_par_par;
%.. .. plotting parameters
dateFormat = 'mm-yyyy';      % same as ctd
%
figure(10 + figure0)
pcolor(xVariable, pressure, par);
ylim([0 60])
shading flat
title('L2 PAR')
axis ij
hPAR = colorbar;
title(hPAR, 'uE/m^2/s');
caxis(cclim.PAR)
set(gca, 'ColorScale', 'log')
drawnow

%..load chelle colormap if it can be found
tf_chelle = false;
if exist('chelle.mat', 'file')
    load('chelle.mat', 'chelle')
    if exist('chelle', 'var'), tf_chelle = true; end
end
%.. reverse figure 'focus' order;
%.. add dateticks if xaxis is time
%.. change colormap if possible
for ii = 10:-1:1
    figure(ii + figure0)
    if strcmpi(xaxis_variable, 'time')
        datetick('x', dateFormat, 'keepLimits')
    else
        xlabel('profile number');
    end
    if tf_chelle
        colormap(chelle);
    end
end

commandwindow
