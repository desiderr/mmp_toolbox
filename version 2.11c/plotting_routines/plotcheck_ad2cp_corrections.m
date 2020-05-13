function plotcheck_ad2cp_corrections(acm_L0, acm_L1, profileNumber) 
%.. desiderio 26-jun-2019

if nargin~=3
    disp(' ');
    disp('USAGE:');
    disp('check_ad2cp_corrections(acm_L0, acm_L1, profileNumber)');
    disp(' ');
    return
end

if contains(lower(acm_L0(profileNumber).data_status{1}), 'notselected')
    disp(['Profile number ' num2str(profileNumber) ...
        ' was not selected to be processed.'])
    return
end

idx = profileNumber;
L0 = acm_L0(idx);
L1 = acm_L1(idx);

%.. rough check on input structures:
%.. .. the program aqd_set_sensor_field_indices.m is run 3 times
%.. .. during processing, once to set L0 fields, once more for L1 
%.. .. processing, and once more for L2 processing. Therefore:
levelL0 = sum(contains(L0.code_history, 'indices')) - 1;
if levelL0 ~= 0
    error('First calling argument appears not to be an L0 structure.');
end
levelL1 = sum(contains(L1.code_history, 'indices')) - 1;
if levelL1 ~= 1
    error('Second calling argument appears not to be an L1 structure.');
end

%.. .. WAG CORRECTION
disp(' ');
disp('WAG CORRECTION IS APPLIED TO velY ONLY.')
disp(' ');
disp('WAG CORRECTION DATA ARE SHOWN PLOTTED AGAINST velBeam,');
disp('velX, velE, velN TO SHOW POSSIBLE ''LEAKAGE'' INTO');
disp('THESE VELOCITIES.');
disp(' ');

figure

L1_Y_beforeWagCorrection = L1.velXYZ(:, 2) + L1.wag_signal;

subplot(3, 1, [1,2])
plot(L1.time, L1_Y_beforeWagCorrection, '-bx')
hold on; 
plot(L1.time, L1.velXYZ(:, 2), '-go')
plot(L1.time, L1.wag_signal, 'ro-')
xxlim = get(gca, 'XLim');
plot(xxlim, [0 0], 'k-');
datetick('x')
ylabel('''Y'' velocity [m/s]');
xlabel(['Profile ' num2str(idx) ' time']);
title({'graphing depends upon wag correction switch!' ...
    'blue ''x'', raw;    red ''o'', wag signal;    green ''o'', corrected'});
hold off
subplot(3, 1, 3)
plot(L1.time, L1.pressure, '-bx')
ylabel('pressure [db]');
linkaxes([subplot(3, 1, [1,2]) subplot(3, 1, 3)], 'x');


%.. .. HEADING PITCH ROLL INTERPOLATION
figure
%
subplot(311)
plot(L0.time, L0.heading, 'bo-')
hold on; 
plot(L1.time, L1.heading, 'rx-')
datetick('x')
ylabel('heading');
xlabel(['Profile ' num2str(idx) ' time']);
title('blue ''o'', raw;    red ''x'', interpolated');
hold off
%
subplot(312)
plot(L0.time, L0.pitch, 'bo-')
hold on; 
plot(L1.time, L1.pitch, 'rx-')
datetick('x')
ylabel('pitch');
xlabel(['Profile ' num2str(idx) ' time']);
title('blue ''o'', raw;    red ''x'', interpolated');
hold off
%
subplot(313)
plot(L0.time, L0.roll, 'bo-')
hold on; 
plot(L1.time, L1.roll, 'rx-')
datetick('x')
ylabel('roll');
xlabel(['Profile ' num2str(idx) ' time']);
title('blue ''o'', raw;    red ''x'', interpolated');
hold off
%
linkaxes([subplot(311) subplot(312) subplot(313)], 'x');

%.. .. velBeam (radial beam velocities)
figure
velBeam = L0.velBeam(:, L0.beam_mapping);

subplot(311)
tchar = num2str(L0.beam_mapping(1));
plot(L0.time, velBeam(:, 1), 'bx-')
hold on
plot(L1.time, L1.wag_signal, 'ro-')
xxlim = get(gca, 'XLim');
plot(xxlim, [0 0], 'k-');
ylim([-1 1]);
datetick('x')
ylabel(['beam ' tchar]);
xlabel(['Profile ' num2str(idx) ' time']);
title(['BEAM ' tchar ' vs. theoretical wag correction velocity in red']);
hold off
%
subplot(312)
tchar = num2str(L0.beam_mapping(2));
plot(L1.time, velBeam(:, 2), 'bx-')
hold on
plot(L1.time, L1.wag_signal, 'ro-')
xxlim = get(gca, 'XLim');
plot(xxlim, [0 0], 'k-');
ylim([-1 1]);
datetick('x')
ylabel(['beam ' tchar]);
xlabel(['Profile ' num2str(idx) ' time']);
title(['BEAM ' tchar ' vs. theoretical wag correction velocity in red']);
hold off
%
subplot(313)
tchar = num2str(L0.beam_mapping(3));
plot(L1.time, velBeam(:, 3), 'bx-')
hold on
plot(L1.time, L1.wag_signal, 'ro-')
xxlim = get(gca, 'XLim');
plot(xxlim, [0 0], 'k-');
ylim([-1 1]);
datetick('x')
ylabel(['beam ' tchar]);
xlabel(['Profile ' num2str(idx) ' time']);
title(['BEAM ' tchar ' vs. theoretical wag correction velocity in red']);
hold off
%
linkaxes([subplot(311) subplot(312) subplot(313)], 'xy');

%.. .. velX, velY, velZ
figure
%
subplot(311)
plot(L1.time, L1.velXYZ(:, 1), 'bx-')
hold on
plot(L1.time, L1.wag_signal, 'ro-')
xxlim = get(gca, 'XLim');
plot(xxlim, [0 0], 'k-');
ylim([-1 1]);
datetick('x')
ylabel('velX');
xlabel(['Profile ' num2str(idx) ' time']);
title('velX and theoretical wag correction velocity in red');
hold off
%
subplot(312)
plot(L1.time, L1.velXYZ(:, 2), 'bx-')
hold on
plot(L1.time, L1.wag_signal, 'ro-')
xxlim = get(gca, 'XLim');
plot(xxlim, [0 0], 'k-');
ylim([-1 1]);
datetick('x')
ylabel('velY');
xlabel(['Profile ' num2str(idx) ' time']);
title('velY and theoretical wag correction velocity in red');
hold off
%
subplot(313)
plot(L1.time, L1.velXYZ(:, 3), 'b-')
hold on
plot(L1.time, L1.dpdt, 'm-')
xxlim = get(gca, 'XLim');
plot(xxlim, [0 0], 'k-');
ylim([-1 1]);
plot(L1.time, L1.velENU(:, 3), 'g-')
datetick('x')
ylabel('velZ');
xlabel(['Profile ' num2str(idx) ' time']);
title('velZ(b), velU(g), and dpdt in magenta');
hold off
%
linkaxes([subplot(311) subplot(312) subplot(313)], 'xy');

%.. .. velE, velN, velU
figure
%
subplot(311)
plot(L1.time, L1.velENU(:, 1), 'bx-')
hold on
plot(L1.time, L1.wag_signal, 'ro-')
ylim([-1 1]);
datetick('x')
ylabel('velE');
xlabel(['Profile ' num2str(idx) ' time']);
title('velE (red is theoretical wag signal)');
hold off
%
subplot(312)
plot(L1.time, L1.velENU(:, 2), 'bx-')
hold on
plot(L1.time, L1.wag_signal, 'ro-')
ylim([-1 1]);
datetick('x')
ylabel('velN');
xlabel(['Profile ' num2str(idx) ' time']);
title('velN (red is theoretical wag signal)');
hold off
%
subplot(313)
plot(L1.time, L1.velENU(:, 3), 'bx-')
hold on
plot(L1.time, L1.wag_signal, 'ro-')
xxlim = get(gca, 'XLim');
plot(xxlim, [0 0], 'k-');
ylim([-1 1]);
datetick('x')
ylabel('velU');
xlabel(['Profile ' num2str(idx) ' time']);
title('velU (red is theoretical wag signal)');
hold off
%
linkaxes([subplot(311) subplot(312) subplot(313)], 'xy');

%.. .. AMBIGUITY VELOCITY CORRECTION
%.. vertical beam number
bvert = setdiff(L0.beam_mapping, [2 4]);

figure
plot(L0.time, L0.velBeam(:, bvert), '-bx')
hold on; 
plot(L1.ambiguous_points(:, 1), L1.ambiguous_points(:, 2), 'ro-')
plot(L1.time, L1.velBeam(:, bvert), '-go')
datetick('x')
ylabel(['beam ' num2str(bvert) ' velocity [m/s]']);
xlabel(['Profile ' num2str(idx) ' time']);
title('blue ''x'', raw;    red ''o'', ambiguous;    green ''o'', fixed');
hold off

%.. display array elements in command window
disp('acm_L0'); disp(acm_L0(idx));
disp('acm_L1'); disp(acm_L1(idx));

%.. .. WAG CORRECTION
disp(' ');
disp('WAG CORRECTION IS APPLIED TO velY ONLY.')
disp(' ');
disp('WAG CORRECTION DATA ARE SHOWN PLOTTED AGAINST velBeam,');
disp('velX, velE, velN TO SHOW POSSIBLE ''LEAKAGE'' INTO');
disp('THESE VELOCITIES.');
disp(' ');

commandwindow
