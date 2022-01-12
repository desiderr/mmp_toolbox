function plotcheck_ad2cp_binning(acm_L1, acm_L2, profileNumber)
%.. desiderio 24-jun-2019, revised 2020-02-08

if nargin~=3
    disp(' ');
    disp('USAGE:');
    disp('plotcheck_ad2cp_binning(acm_L1, acm_L2, profileNumber)');
    disp(' ');
    return
end
idx = profileNumber;
if contains(lower(acm_L1(idx).data_status{1}), 'notselected')
    disp(['Profile number ' num2str(idx) ...
        ' was not selected to be processed.'])
    return
end

%.. rough check on input structures:
%.. .. the program aqd_set_sensor_field_indices.m is run 3 times
%.. .. during processing, once to set L0 fields, once more for L1 
%.. .. processing, and once more for L2 processing. Therefore:
levelL1 = sum(contains(acm_L1(idx).code_history, 'indices')) - 1;
if levelL1 ~= 1
    error('First calling argument appears not to be an L1 structure.');
end
levelL2 = sum(contains(acm_L2(idx).code_history, 'indices')) - 1;
if levelL2 ~= 2
    error('Second calling argument appears not to be an L2 structure.');
end

L2.binValue = acm_L2(idx).pressure_bin_values;

L1.pressure = acm_L1(idx).pressure;
L1.heading  = acm_L1(idx).heading;
L1.velE     = acm_L1(idx).velENU(:, 1);
L1.velN     = acm_L1(idx).velENU(:, 2);
L1.velU     = acm_L1(idx).velENU(:, 3);
L1.time     = acm_L1(idx).time;
L1.dpdt     = acm_L1(idx).dpdt;
L1.pm       = acm_L1(idx).profile_mask;

L2.pressure = acm_L2(idx).pressure;
L2.heading  = acm_L2(idx).heading;
L2.velE     = acm_L2(idx).velENU(:, 1);
L2.velN     = acm_L2(idx).velENU(:, 2);
L2.velU     = acm_L2(idx).velENU(:, 3);
L2.time     = acm_L2(idx).time;
L2.dpdt     = acm_L2(idx).dpdt;

xlabeltxt = [':  profile ' num2str(idx)];
figure
plot(L1.heading, L1.pressure, 'bx-');
hold on
plot(L2.heading, L2.binValue, 'ro-');
hold off
axis ij
xlabel(['heading' xlabeltxt]);
ylabel('pressure')
title('blue ''x'': unbinned data;     red ''o'': binned data');

figure
plot(L1.velU, L1.pressure, 'bx-');
hold on
plot(L2.velU, L2.binValue, 'ro-');
hold off
axis ij
xlabel(['velUp' xlabeltxt]);
ylabel('pressure')
title('blue ''x'': unbinned data;     red ''o'': binned data');

figure
plot(L1.velN, L1.pressure, 'bx-');
hold on
plot(L2.velN, L2.binValue, 'ro-');
hold off
axis ij
xlabel(['velNorth' xlabeltxt]);
ylabel('pressure')
title('blue ''x'': unbinned data;     red ''o'': binned data');

figure
plot(L1.velE, L1.pressure, 'bx-');
hold on
plot(L2.velE, L2.binValue, 'ro-');
hold off
axis ij
xlabel(['velEast' xlabeltxt]);
ylabel('pressure')
title('blue ''x'': unbinned data;     red ''o'': binned data');

figure
plot(L2.binValue, L2.pressure, 'x');
hold on
maxPr = max(L2.pressure);
plot(1:maxPr, 1:maxPr, 'k-');
hold off
xlabel('L2 pressure bin values')
ylabel('L2 binned pressure');

%.. display array elements in command window
disp('acm_L2'); disp(acm_L2(idx));
disp('acm_L1'); disp(acm_L1(idx));

commandwindow
