function struct_out = amalgamate_scalar_structures(CAoSS)
%=========================================================================
% DESCRIPTION
%   Consolidates the fields of multiple structures into the output structure
%
% USAGE:  struct_out = amalgamate_scalar_structures(CAoSS)
%
%   INPUT
%     CAoSS is a vector Cell Array of Scalar Structures, for example,
%     {structA, structB, ..., structN}
%
%   OUTPUT
%     struct_out is a scalar structure whose fields are taken from CAoSS
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   All fieldnames in the structures comprising CAoSS must be unique.
%
%   The structures composing CAoSS are converted to cell arrays which are
%   vertically concatenated and then converted back to a structure 
%   (struct_out) so that all of the fields in the constituent structures
%   are present in structout. 
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-04: desiderio: radMMP version 3.00 (OOI coastal and global)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%.. 2021-05-14: desiderio: radMMP version 3.10 (OOI coastal and global)
%.. 2021-05-24: desiderio: radMMP version 4.0
%=========================================================================

nstruct = length(CAoSS);
if nstruct<2
    error('Input cell array must contain at least 2 scalar structures');
end
%.. minimal performance hit if don't pre-allocate cell arrays
%.. make sure they are column vectors
for ii = 1:nstruct
    Ntemp  = fieldnames(CAoSS{ii});
    Names{ii}  = Ntemp(:);  %#ok<*AGROW>
    Ftemp = struct2cell(CAoSS{ii});
    Fields{ii} = Ftemp(:);
end

vertcat_Names  = Names{1};
vertcat_Fields = Fields{1};
for ii = 2:nstruct
    vertcat_Names  = [vertcat_Names;  Names{ii} ];
    vertcat_Fields = [vertcat_Fields; Fields{ii}];
end
struct_out = cell2struct(vertcat_Fields, vertcat_Names, 1);
