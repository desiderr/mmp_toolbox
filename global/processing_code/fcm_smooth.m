function [acm] = fcm_smooth(acm, meta)
%=========================================================================
% DESCRIPTION
%   Smooths data.
%
% USAGE:  [acm] = fcm_smooth(acm)
%
%   INPUT
%     acm  = a scalar structure containing fields to be smoothed. see the
%            code variable fieldsToSmooth.
%     meta = a scalar structure with the populated field:
%            meta.acm_filter_time_constant_sec
%
%   OUTPUT
%     acm = a scalar structure replacing these fields with smoothed data.
%
% DEPENDENCIES
%   sbefilter
%   Matlab 2018b
%
% NOTES
%   Default setting is a 12-second smooth as used by Toole (1999).
%
% REFERENCES
%   "Velocity Measurements from a Moored Profiling Instrument", J.M. Toole,
%   K.W. Doherty, D.E. Frye, and S.P. Liberatore, in Proceedings of the
%   IEEE Sixth Working Conference on Current Measurement, March 1999,
%   San Diego, CA, pp 144-149. ISBN 0-7803-5505-9.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-10-23: desiderio: initial code
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%=========================================================================

acm.code_history(end+1) = {mfilename};
if isempty(acm.heading)
    acm.data_status(end+1) = {'[]: no action taken'};
    return
end

fieldsToSmooth = {
    'heading'
    'TX'
    'TY'
    'magnetometer'
    'velBeam'
    'velXYZ'
    'velENU'
    'wag_signal'
};

daq = round(acm.acquisition_rate_Hz_calculated);
ftc = meta.acm_filter_time_constant_sec;
%.. heading values are discontinuous at 0 = 360.
acm.heading = unwrap(acm.heading / 180 * pi);  % radians
for ii = 1:length(fieldsToSmooth)
    acm.(fieldsToSmooth{ii}) = sbefilter(acm.(fieldsToSmooth{ii}), daq, ftc);
end
acm.heading = mod(acm.heading / pi * 180, 360);
acm.data_status(end+1) = {'dataSmoothed'};

end

