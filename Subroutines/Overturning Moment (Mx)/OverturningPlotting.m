function [] = OverturningPlotting(Mesh, Raw, ~, ~, Tire)
%% Overturning Plotting = Plots Results from Overturning (Mx) Fitting
% Plots Variant Values from fitting process for Overturning Process for the
% equations given in Pacejka's "Tire and Vehicle Dynamics" [3rd Edition] in
% section 4.3.2 (page 176). 

%% Declare Global Variables 
global Figure

%% Evaluate Variant Surface
[Mx] = VariantEval( Tire );

%% Variant Surface Plotting
Figure.Mx.Surfaces = figure( 'Name'       , 'Overturning Moment Surfaces', ...
                              'NumberTitle', 'off', ...
                              'Visible'    , 'on' );

for p = 1 : size( Raw, 1 )
    for c = 1 : size( Raw, 3 )
        subplot( size( Raw, 3 ), size( Raw, 1 ), ...
            sub2ind( [size( Raw, 1 ), size( Raw, 3 )], p, c ) );
        
        plot3( [Raw(p,:,c).Load], rad2deg([Raw(p,:,c).Alpha]), [Raw(p,:,c).Moment], 'k.' ); hold on;
        fsurf( @(Fz, Alpha) Mx( Mesh(p,1,c).Pressure, Fz, ...
            Mesh(p,1,c).Inclination, Alpha ), [1 2500 -15 15] )
        
        xlabel( 'Normal Load ($F_{z}$) [$N$]' )
        ylabel( 'Slip Angle ($\alpha$) [$deg$]' )
        zlabel( 'Overturning Moment ($M_{x}$) [$Nm$]' )
        title( { ['Pressure ($P_{i}$): $'    , num2str(Mesh(p,1,c).Pressure)   , '$ [$psi$]'], ...
                 ['Inclination ($\gamma$): $', num2str(Mesh(p,1,c).Inclination), '$ [$deg$]'] } )
    end
end

sgtitle( 'Overturning MF6.1 Pacejka Fit' )
Figure.Mx.Surfaces.WindowState = Figure.State;
%% Local Functions

function [Mx] = VariantEval( Tire )
    
        dPi = @(Pi) (Pi - Tire.Pacejka.Pio) ./ Tire.Pacejka.Pio;
        dFz = @(Fz) (Fz - Tire.Pacejka.Fzo) ./ Tire.Pacejka.Fzo;
        
        % Lateral Force Evaluation (Inclination = 0)
        Cy = Tire.Pacejka.p.C.y(1);
        
        Dy = @(Pi, Fz, Gam) (Tire.Pacejka.p.D.y(1) + Tire.Pacejka.p.D.y(2).*dFz(Fz)) .* ...
            (1 + Tire.Pacejka.p.P.y(3).*dPi(Pi) + Tire.Pacejka.p.P.y(4).*dPi(Pi).^2) .* ...
            (1 - Tire.Pacejka.p.D.y(3).*Gam.^2).*Fz;
        
        Kya = @(Pi, Fz, Gam) Tire.Pacejka.p.K.y(1) .* Tire.Pacejka.Fzo .* ( 1 + Tire.Pacejka.p.P.y(1).*dPi(Pi) ) .* ...
            ( 1 - Tire.Pacejka.p.K.y(3).*abs(Gam) ) .* sin( Tire.Pacejka.p.K.y(4) .* ...
            atan( (Fz./Tire.Pacejka.Fzo) ./ ...
            ( ( Tire.Pacejka.p.K.y(2) + Tire.Pacejka.p.K.y(5).*Gam.^2 ) .* ( 1 + Tire.Pacejka.p.P.y(2).*dPi(Pi) ) ) ) );
        
        Kyg0 = @(Pi, Fz) Fz.*(Tire.Pacejka.p.K.y(6) + Tire.Pacejka.p.K.y(7).*dFz(Fz) ) .* (1 + Tire.Pacejka.p.P.y(5).*dPi(Pi) );
        
        By = @(Pi, Fz, Gam) Kya(Pi, Fz, Gam) ./ ( Cy.*Dy(Pi, Fz, Gam) );
        
        Vyg = @(Fz, Gam) Fz.*(Tire.Pacejka.p.V.y(3) + Tire.Pacejka.p.V.y(4).*dFz(Fz) ).*Gam;
        
        Vy = @(Fz, Gam) Fz.*(Tire.Pacejka.p.V.y(1) + Tire.Pacejka.p.V.y(2).*dFz(Fz) ) + Vyg(Fz, Gam);
        
        Hy = @(Pi, Fz, Gam) (Tire.Pacejka.p.H.y(1) + Tire.Pacejka.p.H.y(2).*dFz(Fz) ) .* ...
            (Kyg0(Pi, Fz).*Gam - Vyg(Fz, Gam) ) ./ Kya(Pi, Fz, Gam);
        
        Ey = @(Fz, Gam, Slip, Hy) ( Tire.Pacejka.p.E.y(1) + Tire.Pacejka.p.E.y(2).*dFz(Fz) ) .* ...
            ( 1 + Tire.Pacejka.p.E.y(5).*Gam.^2 - ...
            ( Tire.Pacejka.p.E.y(3) + Tire.Pacejka.p.E.y(4).*Gam ).*sign(Slip + Hy) );

        Fy0 = @(Pi, Fz, Gam, Slip) Dy(Pi, Fz, Gam) .* ...
            sin( Cy .* atan( (1-Ey(Fz, Gam, Slip, Hy(Pi, Fz, Gam) )) .* ...
            By(Pi, Fz, Gam).*(Slip + Hy(Pi, Fz, Gam) ) + ...
            Ey(Fz, Gam, Slip, Hy(Pi, Fz, Gam) ).*atan( ...
            By(Pi, Fz, Gam).*(Slip + Hy(Pi, Fz, Gam) ) ) ) ) + Vy(Fz, Gam); 
        
        % Evaluate P6 Pacejka
        Cx = Tire.Pacejka.p.C.x(1) .* Tire.Pacejka.L.C.x;
        
        Dx = @(Fz, Pi)(Tire.Pacejka.p.D.x(1) + Tire.Pacejka.p.D.x(2).*dFz(Fz)) .* ...
            (1 + Tire.Pacejka.p.P.x(3).*dPi + Tire.Pacejka.p.P.x(4).*dPi(Pi).^2) .* ...
            (1 - Tire.Pacejka.p.D.x(3).*Inc.^2).*Fz .* Tire.Pacejka.L.mu.x;
        
        Ex = @(Gam, Fz, Kappa) ( Tire.Pacejka.p.E.x(1) + Tire.Pacejka.p.E.x(2).*dFz(Fz) ...
            + Tire.Pacejka.p.E.x(3).*dFz(Fz).^2 ) .* ( 1 - Tire.Pacejka.p.E.x(4).*sign(Kappa) ) .* ...
            Tire.Pacejka.L.E.x;
        
        Kxk = @(Fz, Pi) Fz.*(Tire.Pacejka.p.K.x(1) + Tire.Pacejka.p.K.x(2).*dFz(Fz) ) .* ...
            exp( Tire.Pacejka.p.K.x(3) .* dFz(Fz) ) .* ...
            (1 + Tire.Pacejka.p.P.x(1).*dPi(Pi) + Tire.Pacejka.p.P.x(2).*dPi(Pi).^2) .* ...
            Tire.Pacejka.L.K.x.k;
        
        Bx = @(Fz, Pi) Kxk(Fz,Pi) ./ ( Cx.*Dx(Fz,Pi ));
        
        Vx = @(Fz)Fz.*(Tire.Pacejka.p.V.x(1) + Tire.Pacejka.p.V.x(2).*dFz(Fz) ) .* ...
            Tire.Pacejka.L.V.x;
        
        Hx = @(Fz)(Tire.Pacejka.p.H.x(1) + Tire.Pacejka.p.H.x(2).*dFz) .* ...
            Tire.Pacejka.L.H.x;        
                
        Fx0 = @(Gam, Fz, Pi, Kappa) Dx(Fz,Pi) .* sin( Cx .* ... 
            atan( (1-Ex(Gam,Fz)) .* Bx(Fz,Pi).*(Kappa + Hx(Fz)) + ...
            Ex(Gam, Fz).*atan( Bx(Fz, Pi).*(Kappa + Hx(Fz)) ) ) ) + Vx(Fz); 

        %Defining Alpha0 and Kappa0
        Kappa0 = ((Fx0 .* Hx)./Kxk) + Vx;
        Alpha0 = ((Fy0 .* Hy)./Kya) + Vy;    
        
        % Defining Fy
        Fy = abs( Fx0 .* Fy0 ./ sqrt( (Kappa - Kappa0).^2 .* Fy0.^2 + Fx0.^2 .* tan(Alpha - Alpha0).^2 ) .* ...
            sqrt( (1 - abs(Kappa - Kappa0)).^2 .* cos(Alpha - Alpha0).^2 .* Fy0.^2 + sin(Alpha - Alpha0).^2 .* Kxk.^2 ) ./ ...
            ( Kxk .* cos(Alpha - Alpha0)) ) .* sign(Fy0);           
        
        Mx.Surface = @(Fz, Gam, Pi, x0) (Tire.Pacejka.Ro * Tire.Pacejka.Fzo) * ... 
            ( x0.qsx1 - ((x0.qsx2 .* Gam) * (1 + x0.ppMx1 .* dPi(Pi))) +(x0.qsx3 .* ...
            (Fy(Fz, Gam, Pi, x0)./Tire.Pacejka.Fzo)) + (x0.qsx4 .* cos(x0.qsx5 * ...
            atan(x0.qsx6 .* (Fz./Tire.Pacejka.Fzo).^2)).* sin((x0.qsx7 .* Gam) + ...
            (x0.qsx8 .* atan( x0.qsx9 .* (Fy(Fz,Gam,Pi,x0)./Tire.Pacejka.Fzo))))) + ... 
            (x0.qsx10 .* atan(x0.qsx11 .* (Fz./Tire.Pacejka.Fzo)) .* Gam));
end
end