function plotcheck_ctd_binning(ctd_L0, ctd_L1, ctd_L2, profileNumber)
%.. desiderio 2020-02-12
%
%.. checks the binning of ctd variables on pressure by plotting profile
%.. data from the L0, L1, and L2 ctd data structures.

if nargin~=4
    disp(' ');
    disp('USAGE:');
    disp('plotcheck_ctd_binning(ctd_L0, ctd_L1, ctd_L2, profileNumber)');
    disp(' ');
    return
end
idx = profileNumber;

if contains(lower(ctd_L0(profileNumber).data_status{1}), 'notselected')
    disp(['Profile number ' num2str(idx) ' was not selected to be processed.'])
    return
end

figure(11101)
plot(ctd_L1(idx).time, ctd_L1(idx).pressure, 'bx-');
hold on
plot(ctd_L2(idx).time, ctd_L2(idx).pressure_bin_values, 'ro');
plot(ctd_L0(idx).time, ctd_L0(idx).pressure, 'gx-');
hold off
axis ij
xlabel(['TIME:  profile ' num2str(idx)]);
ylabel('pressure')
title({'**PRESSURE**  red ''o'': binned L2 data', ...
       'blue ''x-'': unbinned L1 data;      green ''x-'': L0 data'});

figure(11102)
plot(ctd_L2(idx).pressure_bin_values, ctd_L2(idx).pressure, 'x');
xlabel('pressureBin values');
ylabel('binned pressure data');
title(['profile number ' num2str(idx)])
hold on
maxPr = max(ctd_L2(idx).pressure);
plot(1:maxPr, 1:maxPr, 'k-');
hold off

figure(11103)
plot(ctd_L1(idx).temperature, ctd_L1(idx).pressure, 'bx-');
hold on
plot(ctd_L2(idx).temperature, ctd_L2(idx).pressure_bin_values, 'ro');
plot(ctd_L0(idx).temperature, ctd_L0(idx).pressure, 'gx-');
hold off
axis ij
xlabel(['temperature:  profile ' num2str(idx)]);
ylabel('pressure')
title({'**TEMPERATURE**', 'blue ''x-'': unbinned L1 data;     red ''o'': binned L2 data' ...
       'green ''x-'': L0 data'});

figure(11104)
plot(ctd_L1(idx).conductivity, ctd_L1(idx).pressure, 'bx-');
hold on
plot(ctd_L0(idx).conductivity, ctd_L0(idx).pressure, 'gx-');
hold off
axis ij
xlabel(['conductivity:  profile ' num2str(idx)]);
ylabel('pressure')
title({'**CONDUCTIVITY**', 'blue ''x-'': unbinned L1 data;      green ''x-'': L0 data'});

figure(11105)
plot(ctd_L1(idx).salinity, ctd_L1(idx).pressure, 'bx-');
hold on
plot(ctd_L2(idx).salinity, ctd_L2(idx).pressure_bin_values, 'ro');
hold off
axis ij
xlabel(['salinity:  profile ' num2str(idx)]);
ylabel('pressure')
title({'**SALINITY**', 'blue ''x-'': unbinned L1 data;     red ''o'': binned L2 data'});

figure(11106)
plot(ctd_L1(idx).oxygen, ctd_L1(idx).pressure, 'bx-');
hold on
plot(ctd_L2(idx).oxygen, ctd_L2(idx).pressure_bin_values, 'ro');
plot(ctd_L0(idx).oxygen/10, ctd_L0(idx).pressure, 'gx-');
hold off
axis ij
xlabel(['oxygen:  profile ' num2str(idx)]);
ylabel('pressure')
title({'blue ''x-'': unbinned L1 data;     red ''o'': binned L2 data' ...
       'green ''x-'': L0 data / 10'});
   
for ii=11106:-1:11101
    figure(ii)
end

%.. in case want to code further tests 
P = ctd_L1(idx).pressure;
S = ctd_L1(idx).salinity;
T = ctd_L1(idx).temperature;
time = ctd_L1(idx).time;
O = ctd_L1(idx).oxygen;
dpdt = ctd_L1(idx).dpdt;
pm = ctd_L1(idx).profile_mask;

%.. display array elements in command window
ctd_L0(idx)
ctd_L1(idx)
ctd_L2(idx)

disp('*********************************************************');
disp('L0 data is unprocessed: no lags, filtering, etc. applied.');
disp('*********************************************************');

commandwindow
