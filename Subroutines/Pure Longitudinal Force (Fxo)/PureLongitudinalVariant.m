function [ Variant, Tire ] = PureLongitudinalVariant( Tire, Raw, Response )
%% PureLongitudinalVariant - Variant Pure Slip Longitudinal Fitting
% Inputs:
%   Tire     - Tire Model
%   Raw      - Raw Data for a Given Experimental Operating Condition
%   Response - Fitted Response Surface Parameters
%
% Inputs:
%   Variant - Full Variant Fit 
%   Tire    - Tire Model w/ Pure Slip Longitudinal Force Model
%
% Author(s): 
% Blake Christierson (bechristierson@ucdavis.edu) [Sep 2018 - Jun 2021] 
% Carlos Lopez       (calopez@ucdavis.edu       ) [Jan 2019 -         ]
% 
% Last Updated: 02-May-2021

x0 = Response.x0;

%% Optimization Variables
pcx1 = optimvar( 'pcx1', 'Lowerbound',  0.5 , 'Upperbound',  1.5 );

pdx1 = optimvar( 'pdx1', 'Lowerbound',  0   , 'Upperbound',  x0.pdx1 );
pdx2 = optimvar( 'pdx2', 'Lowerbound',- 5   , 'Upperbound',- 0.1 );
pdx3 = optimvar( 'pdx3', 'Lowerbound',  0   , 'Upperbound',  5   );

pex1 = optimvar( 'pex1', 'Lowerbound',- 5   , 'Upperbound',  5   );
pex2 = optimvar( 'pex2', 'Lowerbound',- 5   , 'Upperbound',  5   );
pex3 = optimvar( 'pex3', 'Lowerbound',- 2   , 'Upperbound',  5   );
pex4 = optimvar( 'pex4', 'Lowerbound',- 5   , 'Upperbound',  5   );

pkx1 = optimvar( 'pkx1', 'Lowerbound',  0   , 'Upperbound', 25   );
pkx2 = optimvar( 'pkx2', 'Lowerbound',- 0.1 , 'Upperbound',  0.1 );
pkx3 = optimvar( 'pkx3', 'Lowerbound',- 5   , 'Upperbound',  5   );

phx1 = optimvar( 'phx1', 'Lowerbound',- 5   , 'Upperbound',  5   );
phx2 = optimvar( 'phx2', 'Lowerbound',- 5   , 'Upperbound',  5   );

pvx1 = optimvar( 'pvx1', 'Lowerbound',- 0.03, 'Upperbound',  0.03);
pvx2 = optimvar( 'pvx2', 'Lowerbound',- 0.1 , 'Upperbound',  0.1 );

ppx1 = optimvar( 'ppx1', 'Lowerbound',- 5   , 'Upperbound',  5   );
ppx2 = optimvar( 'ppx2', 'Lowerbound',- 5   , 'Upperbound',  5   );
ppx3 = optimvar( 'ppx3', 'Lowerbound',- 5   , 'Upperbound',  5   );
ppx4 = optimvar( 'ppx4', 'Lowerbound',- 5   , 'Upperbound',  5   );

%% Optimization Objective
Obj = fcn2optimexpr( @ErrorFyo, pcx1, ...
    pdx1, pdx2, pdx3, ...
    pex1, pex2, pex3, pex4, ...
    pkx1, pkx2, pkx3, ...
    phx1, phx2, ...
    pvx1, pvx2, ...
    ppx1, ppx2, ppx3, ppx4 );

%% Optimization Constraint
Constr(1) = fcn2optimexpr( @ExBound, pex1, pex2, pex3, pex4, 0,  1 ) <= 0.99;
Constr(2) = fcn2optimexpr( @ExBound, pex1, pex2, pex3, pex4, 0, -1 ) <= 0.99;

Constr(3) = fcn2optimexpr( @ExBound, pex1, pex2, pex3, pex4, -1,  1 ) <= 0.99;
Constr(4) = fcn2optimexpr( @ExBound, pex1, pex2, pex3, pex4, -1, -1 ) <= 0.99;

Constr(5) = fcn2optimexpr( @ExBound, pex1, pex2, pex3, pex4, -pex2./(2*pex3),  1 ) <= 0.99;
Constr(6) = fcn2optimexpr( @ExBound, pex1, pex2, pex3, pex4, -pex2./(2*pex3), -1 ) <= 0.99;

%% Solving Optimization Problem
[Variant.Solution, Variant.Log] = Runfmincon( Obj, x0, Constr, 3 );

%% Clearing Optimization Figure
delete( findobj( 'Type', 'figure', 'Name', 'Optimization PlotFcns' ) );

%% Allocating Solution
Tire.Pacejka.p.C.x = Variant.Solution.pcx1;

Tire.Pacejka.p.D.x(1) = Variant.Solution.pdx1;
Tire.Pacejka.p.D.x(2) = Variant.Solution.pdx2;
Tire.Pacejka.p.D.x(3) = Variant.Solution.pdx3;

Tire.Pacejka.p.E.x(1) = Variant.Solution.pex1;
Tire.Pacejka.p.E.x(2) = Variant.Solution.pex2;
Tire.Pacejka.p.E.x(3) = Variant.Solution.pex3;
Tire.Pacejka.p.E.x(4) = Variant.Solution.pex4;

Tire.Pacejka.p.K.x(1) = Variant.Solution.pkx1;
Tire.Pacejka.p.K.x(2) = Variant.Solution.pkx2;
Tire.Pacejka.p.K.x(3) = Variant.Solution.pkx3;

Tire.Pacejka.p.H.x(1) = Variant.Solution.phx1;
Tire.Pacejka.p.H.x(2) = Variant.Solution.phx2;

Tire.Pacejka.p.V.x(1) = Variant.Solution.pvx1;
Tire.Pacejka.p.V.x(2) = Variant.Solution.pvx2;

Tire.Pacejka.p.P.x(1) = Variant.Solution.ppx1;
Tire.Pacejka.p.P.x(2) = Variant.Solution.ppx2;
Tire.Pacejka.p.P.x(3) = Variant.Solution.ppx3;
Tire.Pacejka.p.P.x(4) = Variant.Solution.ppx4;

%% Local Functions
function Ex = ExBound( pex1, pex2, pex3, pex4, dFz, Sign )
    if dFz > 0 || dFz < -1
        Ex = 0;
    else
        Ex = ( pex1 + pex2.*dFz + pex3.*dFz.^2 ) .* ( 1 + pex4 .* sign(Sign) );
    end
end

function RMSE = ErrorFyo( pcx1, ...
        pdx1, pdx2, pdx3, ...
        pex1, pex2, pex3, pex4, ...
        pkx1, pkx2, pkx3, ...
        phx1, phx2, ...
        pvx1, pvx2, ...
        ppx1, ppx2, ppx3, ppx4 )

    Cx = pcx1;

    Dx = (pdx1 + pdx2.*[Raw.dFz]) .* ...
        (1 + ppx3.*[Raw.dPi] + ppx4.*[Raw.dPi].^2) .* ...
        (1 - pdx3.*[Raw.Inclination].^2).*[Raw.Load];

    Ex = ( pex1 + pex2.*[Raw.dFz] + pex3.*[Raw.dFz].^2 ) .* ...
        ( 1 - pex4.*sign([Raw.Slip] ) );

    Kxk = [Raw.Load].*(pkx1 + pkx2.*[Raw.dFz]).*exp( pkx3.*[Raw.dFz] ).* ...
        (1 + ppx1.*[Raw.dPi] + ppx2.*[Raw.dPi].^2);

    Bx = Kxk ./ (Cx.*Dx);

    Vx = [Raw.Load].*(pvx1 + pvx2.*[Raw.dFz]);

    Hx = (phx1 + phx2.*[Raw.dFz]);

    Fxo = Dx.*sin( Cx.*atan( (1-Ex).*Bx.*([Raw.Slip] + Hx) + ...
        Ex.*atan(Bx.*([Raw.Slip] + Hx) ) ) ) + Vx;

    RMSE = sqrt( mean( ([Raw.Force] - Fxo).^2 ) );
end

end