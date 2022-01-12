function [sss] = fcm_set_processing_fields(sss, meta)
%=========================================================================
% DESCRIPTION
%   Copies processing parameters from the structure meta to all elements 
%   of the structure array sss.
%
% USAGE:  [sss] = fcm_set_processing_fields(sss, meta)
%
%   INPUT
%     sss       = a structure array with appropriately named fields
%     meta      = a scalar structure containing processing parameters 
%
%   OUTPUT
%     sss       = a structure array with processing fields populated.
%
% DEPENDENCIES
%   Matlab 2018b
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-10-05: desiderio: global version created by modifying coastal version
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%.. 2021-05-24: desiderio: radMMP version 4.0
%=========================================================================

%.. append mfilename to all sss.code_history elements
Q = {sss.code_history}';  % extract
QQ = cellfun(@(x) [x {mfilename}], Q, 'uni', 0);  % append to each element
[sss.code_history] = QQ{:};
clearvars Q QQ

%.. import processing parameters from meta structure
[sss.deployment_ID]              = deal(meta.deployment_ID);
[sss.wag_radius]                 = deal(meta.wag_radius_m);
[sss.magnetic_declination]       = deal(meta.magnetic_declination_deg);
[sss.binning_parameters]         = deal(meta.acm_binning_parameters);
[sss.depth_offset_m]             = deal(meta.currentmeter_depth_offset_m);

[sss.correct_velY_for_wag]       = deal(meta.correct_velY_for_wag);
[sss.correct_velU_for_dpdt]      = deal(meta.correct_velU_for_dpdt);

%.. append to all sss elements
Q = {sss.data_status}';
QQ = cellfun(@(x) [x {'meta fields transferred'}], Q, 'uni', 0);
[sss.data_status] = QQ{:};
end
