function RelaxationLengthPlotting( Tire, Raw, Run, Idx, Mesh, Figure )
%% Relaxation Length Plotting - Transient Tire Model
% This plots surfaces for the tire relaxation length as a function of 
% inflation pressure and normal load for different slip angles.
%  
% Inputs:
%   Tire           - (struct)      Pacejka Parameters
%   SlipAngle      - (n,1 numeric) Slip Angle          {alpha} [deg]
%   NormalLoad     - (n,1 numeric) Normal Load         {F_z}   [N]
%   LateralForce   - (n,2 numeric) Lateral Force       {F_y}   [N]
%   AligningMoment - (n,3 numeric) Aligning Moment     {M_z}   [Nm]
%   Pressure       - (n,1 numeric) Inflation Pressure  {P_i}   [kPa]
%   Velocity       - (n,1 numeric) Center Velocity     {v_c}   [m/s]
%   Model          - (struct)      Fidelity Choices 
%
% Outputs:
%
% Notes:
%   2nd order curve fitting is currently not implemented (6/2/21) because
%   accuracy of relaxation length data is currently sufficient to justify 
%   tire choice.
%
% Author(s): 
% Blake Christierson (bechristierson@ucdavis.edu) [Sep 2018 - Jun 2021] 
% Leonardo Howard    (leohoward@ucdavis.edu     ) [Feb 2021 -         ]
% 
% Last Updated: 22-October-2021

%% Plotting The Cases of The Fit
Load = unique( [Mesh.Load] );
    
for z = 1 : numel( Load )
    Figure.Fy.Fit(z) = figure( ...
        'Name'       , ['Tire: ', Tire.Name, ...
            ', Lateral Force Fits, F_Z = ', num2str( Load(z) .* 4.44822 ), ' [N]'], ...
        'NumberTitle', 'off' , ...
        'Visible'    , 'off'  );
end

for j = 1 : numel(Raw)

    z = find( Mesh(j).Load == Load );

    figure( Figure.Fy.Fit(z) );
    
    for k = 1 : numel(Idx.NewBreaks)
        ax1 = nexttile;

        title( { 
            ['Pressure ($P$): $', ...
                num2str( Run.Fit(j,k).Pressure ), '$ [$psi$]'], ...
            ['Slip Angle ($\alpha$): $', ...   
                num2str( rad2deg( Run.Fit(j,k).Slip ) ), '$ [$deg$]'], ...
            ['Relaxation Length ($RL$): $', ...
                num2str( Run.Fit(j,k).RelaxationLength ), '$ [$m$]'] 
            } );

        yyaxis(ax1, 'left');
        scatter( Run.Response(j,k).Time - Run.Response(j,k).Time(1), ...
            Run.Response(j,k).Force );
        hold on;
        plot( Run.Fit(j,k).FyResponseFit{1,1} );

        xlabel( 'Time: $t$' );
        ylabel( 'Cornering Force: $F_{y}$' );

        ax1.XAxisLocation = 'origin';
        ax1.YAxis(2).Visible = 'off';
        if abs( max( Run.Response(j,k).Force ) ) > abs( min( Run.Response(j,k).Force ) )
            ylim( [ -abs( max( Run.Response(j,k).Force ) ) abs( max( Run.Response(j,k).Force ) ) ] );
        elseif abs( max( Run.Response(j,k).Force ) ) < abs( min( Run.Response(j,k).Force ) )
            ylim( [ -abs( min( Run.Response(j,k).Force ) ) abs( min( Run.Response(j,k).Force ) ) ] );
        else
            ylim auto;
        end
    end               
end    

%% 16" and 18" Hoosier R25B Lateral Force Comparison Figure
%{
%{
    This section of the code is to provide justification for the choice to
    use the 16" tire over the 18" tire in terms of transient vehicle 
    lateral response.

    To produce the lateral force comparison figure for the 16" and the 18"
    Hoosier R25B tires, the following tire data is required:
        1. Round 8 Run 1:  Hoosier R25B 16"
        2. Round 6 Run 20: Hoosier R25B 18"
    
    Hence, the file LateralTirePerformanceComparison.mat is created to 
    produce filtered tire data from RelaxationLengthFitting.m for
    use in RelaxationLengthPlotting.m to generate comparison figure which
    would be difficult to obtain from the tire data chosen routinely (Round 
    6: Run 1,2,4, and Round 8: Run 34,35,36).

    This .mat file is obtained by first running RelaxationLengthFitting.m 
    twice after setting a breakpoint right before 
    RelaxationLengthPlotting() is called. The reason for this is to save 
    the 'Run' variable as 'Run_16in' and 'Run_18in' variables for the 2 
    separate runs, respectively. Then, these two saved variables will be 
    saved as 'Run(1)' and 'Run(2)', respectively. The saving process is 
    done by running the following line which is used to save the 'Run_16in'
    variable: "save Models\LateralTirePerformanceComparison.mat Run_16in".
    into the command window.
%}
load('Models\LateralTirePerformanceComparison.mat'); %#ok<LOAD>

j=1;
k=2;

figure;
ax1=nexttile;

yyaxis(ax1, 'left');
scatter( Run(1).Response(j,k).Time - Run(1).Response(j,k).Time(1), ...
    Run(1).Response(j,k).Force );
hold on;
plot( Run(1).Fit(j,k).FyResponseFit{1,1}, 'm' );
hold on;
scatter( Run(2).Response(j,k).Time - Run(2).Response(j,k).Time(1), ...
    Run(2).Response(j,k).Force, 'r' );
hold on;
plot( Run(2).Fit(j,k).FyResponseFit{1,1}, 'g');

xlabel( 'Time: $t$' );
ylabel( 'Cornering Force: $F_{y}$' );

ax1.XAxisLocation = 'origin';
ax1.YAxis(2).Visible = 'off';

if abs( max( Run(1).Response(j,k).Force ) ) > abs( min( Run(1).Response(j,k).Force ) )
    ylim( [ -50 abs( max( Run(1).Response(j,k).Force ) ) ] );
elseif abs( max( Run(1).Response(j,k).Force ) ) < abs( min( Run(1).Response(j,k).Force ) )
    ylim( [ -50 abs( min( Run(1).Response(j,k).Force ) ) ] );
else
    ylim auto;
end

legend({'16" Tire Data','16" Tire Curve Fitting','18" Tire Data','18" Tire Curve Fitting'}, ...
    'Position',[0.6 0.4 0.2 0.1])

text(1.5, 50, append('16" Tire Relaxation Length: ', num2str(Run(1).Fit(j,k).RelaxationLength),' m'))
text(1.5, 40, append('18" Tire Relaxation Length: ', num2str(Run(2).Fit(j,k).RelaxationLength),' m'))
%}

%% Surface Plot of Relaxation Length as a Function of Pressure and Load for Different Slip Angles
for i = 1 : numel( Tire )
    Figure.Fy.SurfacePlot(z) = figure( ...
        'Name'       , ['Tire: ', Tire.Name, ', Surface Plot for Different Slip Angles'], ...
        'NumberTitle', 'off' , ...
        'Visible'    , 'off'  );
end

figure( Figure.Fy.SurfacePlot(z) );

for i = 1 : numel(Mesh(1).Slip.Angle)
    subplot( numel(Mesh(1).Slip.Angle), 1, i );

    surf( ...
        reshape( [Run.Fit(:,i).Pressure], ...
            [numel(Mesh(1).Slip.Angle), numel(Mesh(1).Slip.Angle)] ), ...
        reshape( [Run.Fit(:,i).Load], ...               
            [numel(Mesh(1).Slip.Angle), numel(Mesh(1).Slip.Angle)] ), ...
        reshape( [Run.Fit(:,i).RelaxationLength], ...   
            [numel(Mesh(1).Slip.Angle), numel(Mesh(1).Slip.Angle)] ) ...
    );

    xlabel('Pressure: $P$'); 
    ylabel('Load: $F_{z}$'); 
    zlabel('Relaxation Length: $RL$');

    title( ['Slip Angle ($\alpha$): $', num2str( Run.Fit(1,i).Slip ), '$ [$rad$]'] );
end