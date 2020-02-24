function plot_MMP_L1_data(MMP, figure0)
%.. desiderio 07-feb-2020
%
%.. creates scatter plots of L1 sensor data
%
% MMP is the output of Process_McLane_WFP_Deployment
% figure0 is optional and sets the figure number sequence

if nargin==0
    disp(' ');
    disp('USAGE (needs at least one calling argument):');
    disp('plot_MMP_L1_data(MMP)');
    disp('plot_MMP_L1_data(MMP, figureNumberOffset)');
    disp(' ');
    return
elseif nargin==1
    figure0 = 160;
end

mrkr = '.';
mrkrSize = 3;
mrkrSizePAR = 9;

xaxis_variable = 'time';
dateFormat = 'mm-yyyy';      % same as ctd
disp(['fastscatter x-axis variable is ' xaxis_variable '.']);

%.. CTD plots
%.. .. data variables from MMP data structure
time        = MMP.nan_processed_ctd_time;

pressure    = MMP.nan_processed_ctd_pressure;
temperature = MMP.nan_processed_ctd_temperature;
salinity    = MMP.nan_processed_ctd_salinity;
oxygen      = MMP.nan_processed_ctd_oxygen;
theta       = MMP.nan_processed_ctd_theta;
sigma_theta = MMP.nan_processed_ctd_sigma_theta;
dpdt        = MMP.nan_processed_ctd_dpdt;

%.. .. plotting parameters
climTemperature = [4 14];       % degC
climSalinity    = [32 34.5];    % psu
climOxygen      = [0 250];      % umole/kg
climTheta       = [4 14];       % degC
climSigmaTheta  = [23.5 27.5];  % kg/m3
climDpDt        = [-0.4 0.4];   % m/s

xVar = time;

figure(1 + figure0)
fastscatter(xVar, pressure, temperature, mrkr, 'markersize',  mrkrSize);
title('L1 temperature')
axis ij
ylabel('pressure [db]')
hCTD311 = colorbar;
title(hCTD311, '\circC');
caxis(climTemperature)
%
drawnow

figure(2 + figure0)
fastscatter(xVar, pressure, salinity, mrkr, 'markersize',  mrkrSize);
title('L1 salinity')
axis ij
ylabel('pressure [db]')
hCTD312 = colorbar;
title(hCTD312, 'psu');
caxis(climSalinity)
%
drawnow

figure(3 + figure0)
fastscatter(xVar, pressure, oxygen, mrkr, 'markersize',  mrkrSize);
title('L1 oxygen')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'umole/kg');
caxis(climOxygen)
%
drawnow

figure(4 + figure0)
fastscatter(xVar, pressure, theta, mrkr, 'markersize',  mrkrSize);
title('L1 potential temperature')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, '\circC');
caxis(climTheta)
%
drawnow

figure(5 + figure0)
fastscatter(xVar, pressure, sigma_theta, mrkr, 'markersize',  mrkrSize);
title('L1 potential density')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'kg/m3');
caxis(climSigmaTheta)
%
drawnow

figure(6 + figure0)
fastscatter(xVar, pressure, dpdt, mrkr, 'markersize',  mrkrSize);
title('L1 profiler velocity')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'm/s');
caxis(climDpDt)
%
drawnow

%.. ECO-TRIPLET plots
%.. .. data variables from MMP data structure
time     = MMP.nan_processed_flr_time;
xVar = time;

pressure = MMP.nan_processed_flr_pressure;
chl      = MMP.nan_processed_flr_chl;
cdom     = MMP.nan_processed_flr_cdom;
bback    = MMP.nan_processed_flr_bback;
%.. .. plotting parameters
climChl    = [0 1];          % ug/l
climCDOM   = [0 3];          % ppb
climBback  = [0 0.005];      % m^-1
%
figure(7 + figure0)
fastscatter(xVar, pressure, chl, mrkr, 'markersize',  mrkrSize);
title('L1 chlorophyll')
axis ij
hTriplet311 = colorbar;
title(hTriplet311, 'ug/l');
caxis(climChl)
%
figure(8 + figure0)
fastscatter(xVar, pressure, cdom, mrkr, 'markersize',  mrkrSize);
title('L1 CDOM')
axis ij
hTriplet312 = colorbar;
title(hTriplet312, 'ppb');
caxis(climCDOM)
%
figure(9 + figure0)
fastscatter(xVar, pressure, bback, mrkr, 'markersize',  mrkrSize);
title('L1 backscatter')
axis ij
hTriplet313 = colorbar;
title(hTriplet313, 'm^-1');
caxis(climBback)


%.. PAR plot
%.. .. data variables from MMP data structure
time     = MMP.nan_processed_par_time;
xVar = time;
pressure = MMP.nan_processed_par_pressure;
par      = MMP.nan_processed_par_par;
%.. .. plotting parameters
%.. limits for log plot
climPAR    = [1 100];        % microEinsteins/m^2/s
%
figure(10 + figure0)
fastscatter(xVar, pressure, par, mrkr, 'markersize',  mrkrSizePAR);
ylim([0 60]);
title('L1 PAR')
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
    end
    if tf_chelle
        colormap(chelle);
    end
end

commandwindow
