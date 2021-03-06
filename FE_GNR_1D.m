%% Fluorescence enhancement of nanorods, results are calculated along the long axis
%  as a function of distance.
%  The script can calculate the overall fluorescence enhancement as a function of molecule
%  surface distance and dipole wavelength
%  Output: [FE] is the fluorescence enhancement factors as a function of distance and QY.
%                along row, distance-dependent total fluorescence enhancement
%                along column, QY in the input
function [PCR, FE, Lorentz, ee] = FE_GNR_1D( height, diameter, metal, enei_field, enei_dipole )
    
    %%  initialization
    %  options for BEM simulation
    op = bemoptions( 'sim', 'ret', 'interp', 'curv' );
    
    switch metal
        case 'Au'
            %  table of dielectric functions
            epstab = { epsconst( 1.33^2 ), epstable( 'gold.dat' ) };
        case 'AgPalik'
            %  table of dielectric functions
            epstab = { epsconst( 1.33^2 ), epstable( 'silver_palik.dat' ) };
        case 'AgJC'
            %  table of dielectric functions
            epstab = { epsconst( 1.33^2 ), epstable( 'silver.dat' ) };
            
    end
    
    
    %  nanorod geometries
    %mesh = [ 11, 11, 11]; % n1 for the circumference of the rod, n2 for the polar angles of the rod caps, n3 for the cylinder-shaped middle part of the rod
    mesh = [ 41, 41, 41]; % n1 for the circumference of the rod, n2 for the polar angles of the rod caps, n3 for the cylinder-shaped middle part of the rod
    
    QY = [ 0.01 0.02 0.05 0.1 0.2 0.65 1]; % series of QY for calculation
    
    
    %  nanosphere with finer discretization at the top
    %  To calculate decay rates close to spheres, the mesh close to the
    %  positions of dipoles need to refined.
    p = trirod ( diameter, height, mesh, 'triangles' );
    
    %  initialize sphere
    p = comparticle( epstab, { p }, [ 2, 1 ], 1, op );
    
    %  rotate the particle for 90 degrees
    p = rot (p, 90, [0, -1, 0]);
    
    
    %% make a new directory
    
    directory = pwd;
    switch metal
        case 'Au'
            ndir = ['H',num2str(height),'D',num2str(diameter),'_GNR'] ;%,'_Exc', num2str(enei_field),'_Dip_',num2str(enei_dipole)];
        case 'AgPalik'
            ndir = ['H',num2str(height),'D',num2str(diameter),'_AgNR_palik','_Exc', num2str(enei_field),'_Dip_',num2str(enei_dipole)];
        case 'AgJC'
            ndir = ['H',num2str(height),'D',num2str(diameter),'_AgNR_JC','_Exc', num2str(enei_field),'_Dip_',num2str(enei_dipole)];
    end
    mkdir(ndir)
    cd(ndir)
    
    %% Calculate and save the scattering spectrum for reference
    enei = linspace(500,1000,50 );
    
    [ sca, ~, ~, Lorentz, ~ ] = spect_GNR_BEM( epstab, height, diameter, enei);
    
    %%  set wavelength of planewave and dipole oscillator
    if nargin == 3
        enei_field = 1248./Lorentz(3) ;  % 637
        enei_dipole = enei_field + 25 ; % 670
    else
    end
    vline(enei_dipole, 'r-','\lambda_{dip}');
    vline(enei_field,  'b-','\lambda_{exc}');
    saveas (gcf, [ndir,'.fig'], 'fig')
    saveas (gcf, [ndir,'.png'], 'png')
    
    
    %% Dipole positions
        %1D positions of dipole
    %choose the minimum distance by setting the values of x vector
    %x = reshape( logspace( log10(0.51 * height), log10( 100 + 0.5 * height ), 200 ), [], 1 );

    x = reshape( linspace( 0.51, (50 + 0.5 * height )/height, 20 ) * height, [], 1 );
    
    % compoint
    %pt = compoint( p, [ x, 0 .* x, 0 .* x ], 'mindist' , 1 );
    
    pt = compoint( p, [ x,  x, 0 .* x ], 'mindist' , 1 );
    
    dir_dip = [ 1, 0, 0 ; 0 , 1 , 0 ; 0, 0, 1];
    
    % dipole excitation , x and z direction
    dip = dipole( pt, dir_dip, op );

    
    %% plot dipole orientation and nanorod
    figure
    plot(p)
    axis on
    hold on
    plot3(pt.pos(:,1), pt.pos(:,2),pt.pos(:,3) ,'r.')
    xlabel('x(nm)')
    ylabel('z(nm)')
    hold off
    view([0 0])
    saveas(gcf,'dipole-particle.fig')
    saveas(gcf,'dipole-particle.png')
    %%  BEM simulation for decay rates
    %  set up BEM solver
    bem = bemsolver( p, op );
    %  surface charge
    sig = bem \ dip( p, enei_dipole );
    %  total and radiative decay rate
    [ tot, rad, ~] = dip.decayrate( sig );
    %% decay rate plot for intrinsic quantum yield of 1%. These plots are generated as examples and previews.
    d_BEM = pt.pos(:,1) - height/2;
    
    figure
    semilogy( pt.pos(:,1), tot, '-'  );  hold on;
    semilogy( pt.pos(:,1), rad, 'o-' );
    xlim( [ min( pt.pos(:,1) ), max( pt.pos(:,1) ) ] );
    title( 'Total and radiaitve decay rate for dipole oriented along x and z' );
    legend( 'tot_x BEM','tot_y BEM','tot_z BEM','rad_x BEM','rad_y BEM', 'rad_z BEM' )
    
    xlabel( 'Position (nm)' );
    ylabel( 'Decay rate' );
    MinWhitSpace
    saveas(gcf,'Decay rates.fig')
    saveas(gcf,'Decay rates.png')
    
    Qx = rad(:, 1)./( tot(:, 1) + (1 - 0.01 ) / 0.01);
    Qy = rad(:, 2)./( tot(:, 2) + (1 - 0.01 ) / 0.01);
    Qz = rad(:, 3)./( tot(:, 3) + (1 - 0.01 ) / 0.01);
    
    rad_average = ( rad(:, 1) + rad(:, 2) + rad(:, 3) )./3 ;
    tot_average = ( tot(:, 1) + tot(:, 2) + tot(:, 3) )./3 ;
    
    Q_exam =  rad_average./( tot_average + (1 - 0.01 ) / 0.01 ) ;
    
    figure
    plot(d_BEM, Qx , d_BEM, Qy, d_BEM, Qz, d_BEM, Q_exam  )
    legend('QY_x BEM', 'QY_y BEM', 'QY_z BEM','QY_average BEM')
    xlabel('Distance to surface (nm)')
    ylabel(['Quantum yield (intrinsic QY = ', num2str(0.01), ' )'])
    title(['Wavelength of dipole ', num2str(enei_dipole),' nm'])
    xlim( [ 0 , max(d_BEM) ]  )
    MinWhitSpace
    saveas(gcf,'QY_axis.fig')
    saveas(gcf,'QY_axis.png')
    
    %% BEM solver for near field intensity
    
    %  TM mode, excitation from above
    dir = [ 0, 0, -1];
    pol = [ 1, 0, 0 ];
    
    %  initialize BEM solver
    bem = bemsolver( p, op );
    %  initialize plane wave excitation
    exc = planewave( pol, dir, op );
    %  solve BEM equation
    sig = bem \ exc( p, enei_field );
    
    multiWaitbar( 'BEM solver', 0, 'Color', 'g', 'CanCancel', 'on' );
    %  close waitbar
    multiWaitbar( 'CloseAll' );
    
    % %  set up Green function object between PT and P
    % %  use the pt object calculated from above dipole positions
    % g = greenfunction( pt, p, op );
    % %  compute electric field
    % f = field( g, sig );
    
    
    
    % ee = sqrt( dot (f.e , f.e, 2 ) ) ;
    % ee = ee.^2 ;
    % ee_norm = vecnorm( f.e ) ;
    % ee_normsquared = ee_norm.^2;
    
    %%  computation of electric field
    %  object for electric field
    %    MINDIST controls the minimal distance of the field points to the
    %    particle boundary, MESHFIELD must receive the OP structure which also
    %    stores the table of precomputed reflected Green functions
    emesh = meshfield( p, pt.pos(:,1), 0 .* pt.pos(:,1), 0 .* pt.pos(:,1), op, 'mindist', 0.2, 'nmax', 2000 , 'waibar', 1 );
    %  induced and incoming electric field
    e = emesh( sig ) + emesh( exc.field( emesh.pt, enei_field ) );
    %  norm of electric field
    enorm = vecnorm(e);
    
    ee = enorm.^2;
    
    % plot near field
    % get electric field
    ex = sqrt( dot (e(: ,1) , e(: ,1), 	2 ) );
    ey = sqrt( dot (e(: ,2) , e(: ,2), 	2 ) );
    ez = sqrt( dot (e(: ,3) , e(: ,3), 	2 ) );
    
    % plot enhanced field in averaged orietation
    figure
    loglog(d_BEM ,ee(:))
    xlabel('x (nm)')
    ylabel('y (nm)')
    title('Near field intensity')
    MinWhitSpace
    saveas(gcf, 'nearfield_axis.fig')
    saveas(gcf, 'nearfield_axis.png')
    
    % plot electric field vector
    figure
    coneplot( pt.pos, e )
    axis on
    grid on
    hold on;
    plot(p)
    % saveas( gcf, 'Electric field vector.fig' )
    % saveas( gcf, 'Electric field vector.png' )
    
    % plot enhanced field in every component
    figure
    loglog(d_BEM, ex.^2,d_BEM, ey.^2,d_BEM, ez.^2);
    legend('E_x^2/E_0^2','E_y^2/E_0^2','E_z^2/E_0^2')
    xlabel('d (nm)')
    ylabel('Near field enhancement')
    MinWhitSpace
    saveas( gcf, 'nearfield_xyz.fig' )
    saveas( gcf, 'nearfield_xyz.png' )
    
    %% Orientation averaging of emission enhancement, and calculation of position dependent total fluorescence enhancement.
    rad_average = ( rad(:, 1) + rad(:, 2) + rad(:, 3) )./3 ;
    tot_average = ( tot(:, 1) + tot(:, 2) + tot(:, 3) )./3 ;
    enei_field = 637;
    enei_dipole = 670;
    %QY = [ 0.01 0.02 0.05 0.1 0.2 0.65 1]; % series of QY for calculation
    
    for i = 1 : length(QY)
        
        Q_avg(i,:) =  rad_average./( tot_average + (1 - QY(i) ) / QY(i) ) ;
        FE(i,:) = ee(:)'.*Q_avg(i,:)./QY(i) ;
        
        
        figure
        semilogy(d_BEM, FE(i,:), 'r-o','LineWidth',1)
        legend('\xi')
        xlabel('d (nm)')
        ylabel('Fluorescence enhancement')
        str = ['\lambda_{dipole} = ', num2str(enei_dipole),' nm \newline \lambda_{exc} = ', ...
            num2str(enei_field), ' nm'];
        annotation('TextBox',[0.5 0.3 0.5 0.6],'String',str,'FitBoxToText','on','LineStyle','none','FontSize',14);
        MinWhitSpace
        saveas(gcf,[num2str(QY(i)),'_fluorescence_enhancement_on_axis.fig'])
        saveas(gcf,[num2str(QY(i)),'_fluorescence_enhancement_on_axis.png'])
        
    end
    
    %% Plot QY vs Max. FE
    
    phi = linspace( 0, 1, 1000 );
    
    for i = 1 : length(phi)
        
        Q_line =  rad_average./( tot_average + (1 - phi(i) )./ phi(i) ) ;
        
        factor = Q_line./phi(i).*ee;
        
        %[FE_allphi(i),idx] = max(factor);
        idx = 11; % fixed distance 3 nm.
        tot_mod(i) = tot_average(idx);
        
        QY_mod(i) = Q_line(idx)./phi(i);
        
    end
    %%
    
    % figure
    % semilogx( phi, FE_allphi )
    % xlabel('QY')
    % ylabel('\xi_{EF}')
    % hline(max(ee),'r-','max. exc. enhancement')
    % MinWhitSpace
    % saveas(gcf,'MaxFEvsphi.fig')
    % saveas(gcf,'MaxFEvsphi.png')
    %
    % save FE_allphi FE_allphi
    % save phi phi
    
    %% Initialize structural array for results and save results
    
    decayrates = struct();
    decayrates.d_BEM = d_BEM;
    decayrates.rad = rad;
    decayrates.tot = tot;
    decayrates.rad_average = rad_average;
    decayrates.tot_average = tot_average;
    decayrates.ee = ee;
    decayrates.ex = ex;
    decayrates.ey = ey;
    decayrates.ez = ez;
    decayrates.QY = QY;
    decayrates.Lorentz = Lorentz;
    decayrates.enei_field = enei_field;
    decayrates.enei_dipole = enei_dipole;
    decayrates.enei = enei;
    decayrates.sca = sca;
    decayrates.Q_avg = Q_avg;
    decayrates.phi = phi; % continuous quantum yield from 0 to 1 for plotting
    decayrates.tot_mod = tot_mod; % lifetime reduction at fixed for all phi. Should be almost flat due to fixed location
    decayrates.QY_mod = QY_mod; % QY modifications for all phi. Should decrease with increasing phi.
    save decayrates decayrates
    %% Photon count rate calculation.
    [PCR] = PhotonCountRate( decayrates );
    
end
