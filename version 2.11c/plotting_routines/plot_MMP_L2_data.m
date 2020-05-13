function plot_MMP_L2_data(MMP, figure0)
%.. desiderio 07-feb-2020 added par; theta, sigmaTheta, dpdt
%
%.. creates 'pcolor' plots of L1 sensor data
%
% MMP is the output of Process_McLane_WFP_Deployment
% figure0 is optional and sets the figure number sequence

%.. xaxis_variable can be either 'time' or 'profile';
if nargin==0
    disp(' ');
    disp('USAGE (needs at least one calling argument):');
    disp('plot_MMP_L2_data(MMP)');
    disp('plot_MMP_L2_data(MMP, figureNumberOffset)');
    disp(' ');
    return
elseif nargin==1
    figure0 = 180;
end

xaxis_variable = 'profile';
disp(['pcolor x-axis variable is ' xaxis_variable '.']);

%.. CTD plots
%.. .. data variables from MMP data structure
time        = MMP.datenum;  % one per profile;
profile     = MMP.profiles_selected;

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

%.. .. plotting parameters
climTemperature = [4 14];       % degC
climSalinity    = [32 34.5];    % psu
climOxygen      = [0 250];      % umole/kg
climTheta       = [4 14];       % degC
climSigmaTheta  = [23.5 27.5];  % kg/m3
climDpDt        = [-0.4 0.4];   % m/s

if strcmpi(xaxis_variable, 'profile')
    xVariable = profile;
else
    xVariable = time;
end

figure(1 + figure0)
pcolor(xVariable, pressure, temperature);
shading flat
title('L2 temperature')
axis ij
ylabel('pressure [db]')
hCTD311 = colorbar;
title(hCTD311, '\circC');
caxis(climTemperature)
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
caxis(climSalinity)
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
caxis(climOxygen)
%
drawnow

figure(4 + figure0)
pcolor(xVariable, pressure, theta);
shading flat
title('L2 potential temperature')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, '\circC');
caxis(climTheta)
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
caxis(climSigmaTheta)
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
caxis(climDpDt)
%
drawnow

%.. ECO-TRIPLET plots
%.. .. data variables from MMP data structure
time        = MMP.datenum;                      % same as ctd
pressure    = MMP.flr_pressure_bin_values;      % different
chl      = MMP.binned_flr_chl;
cdom     = MMP.binned_flr_cdom;
bback    = MMP.binned_flr_bback;
%.. .. plotting parameters
climChl    = [0 1];          % ug/l
climCDOM   = [0 3];          % ppb
climBback  = [0 0.005];      % m^-1
%
figure(7 + figure0)
pcolor(xVariable, pressure, chl);
shading flat
title('L2 chlorophyll')
axis ij
hTriplet311 = colorbar;
title(hTriplet311, 'ug/l');
caxis(climChl)
%
figure(8 + figure0)
pcolor(xVariable, pressure, cdom);
shading flat
title('L2 CDOM')
axis ij
hTriplet312 = colorbar;
title(hTriplet312, 'ppb');
caxis(climCDOM)
%
figure(9 + figure0)
pcolor(xVariable, pressure, bback);
shading flat
title('L2 backscatter')
axis ij
hTriplet313 = colorbar;
title(hTriplet313, 'm^-1');
caxis(climBback)


%.. PAR plot
%.. .. data variables from MMP data structure
time        = MMP.datenum;                      % same as ctd
pressure    = MMP.par_pressure_bin_values;      % different
par      = MMP.binned_par_par;
%.. .. plotting parameters
dateFormat = 'mm-yyyy';      % same as ctd
%.. limits for log plot
climPAR    = [1 100];        % microEinsteins/m^2/s
%
figure(10 + figure0)
pcolor(xVariable, pressure, par);
ylim([0 60])
shading flat
title('L2 PAR')
axis ij
hPAR = colorbar;
title(hPAR, 'uE/m^2/s');
caxis(climPAR)
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
