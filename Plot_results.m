%% Plot SPR and distance dependent/power depedent absolute photon count rate. 

directories = dir();

dirFlags = [directories.isdir];
subFolders = directories(dirFlags);

pcles = length(subFolders) - 2; 

% set quantum yield for analysis. 
QY_idx = 6 ; % index 6, QY - 0.65, index 6 QY - 0.05
d = 4 ; 
%[~, dist_idx] = min(abs(decayrates.d_BEM - d));

for i = 3 : length(subFolders)
    cd(subFolders(i).name)
    load PCR
    load decayrates
    [~, dist_idx] = min(abs(decayrates.d_BEM - d));
    NonenhDistDepend_HI{i - 2} = PCR.NonenhCountRateDistQYdepend_HI;
    EnhDistDepend_HI{i -2} = PCR.EnhCountRateDistQYdepend_HI;
    NonenhDistDepend_LO{i - 2} = PCR.NonenhCountRateDistQYdepend_LO;
    EnhDistDepend_LO{i -2} = PCR.EnhCountRateDistQYdepend_LO;
    NonenhPowerQYDepend{i - 2} = PCR.NonenhCountRatePowerQYdepend;
    EnhPowerQYDepend{i - 2} = PCR.EnhCountRatePowerQYdepend;
    I_satenh(i - 2) = PCR.I_satenh(dist_idx)./decayrates.ee(dist_idx);% index 11, at 3 nm. 
    maxPCRenh (i - 2) = PCR.maxPCRenh(QY_idx); % index 6, at quantum yield 0.65, index 2, at quantum yield of 0.02
    maxPCRenhfactor(i - 2) = PCR.maximumPCRenhancement(QY_idx); % index 6, at quantum yield 0.65 ,index 2, at quantum yield of 0.02
    WL(i - 2) = 1248/decayrates.Lorentz(3);
    maxFE(i - 2) = max(decayrates.ee'.*decayrates.Q_avg(QY_idx,:)./decayrates.QY(QY_idx));
    FE_location(i - 2) = decayrates.ee(dist_idx).*decayrates.Q_avg(QY_idx,dist_idx)./decayrates.QY(QY_idx); % enhancement factor at surveyed location, 3 nm or 7 nm.
    [startIndex,endIndex] = regexp( subFolders(i).name,'H[0-9]+D');
    height(i - 2) = str2num(subFolders(i).name(2:endIndex-1));
     [startIndex,endIndex] = regexp( subFolders(i).name,'D[0-9]\w');
    diameter(i - 2) = str2num(subFolders(i).name(startIndex+1:endIndex));
    cd ..
end 


%% Plot SPR dependent, power dependent, QY = 0.5
figure
x = PCR.I_inc ;
%pcles_id = [ 3, 6, 9, 11];
pcles_id = 3 : 9; 
for i = 1 : length(pcles_id)
    loglog(x, EnhPowerQYDepend{pcles_id(i)}(QY_idx,:))
    %vline(I_satenh(pcles_id(i)))
    %hline(maxPCRenh(pcles_id(i)))
    hold on 
end
nonenh_PCR = PCR.NonenhCountRatePowerQYdepend(QY_idx,:) ;
loglog(x, nonenh_PCR,'-')
%vline(PCR.I_sat)
%hline(PCR.maxPCR(6))
xlabel('Power Wm^{-2}')
ylabel('Photon count rate')
lg = split(num2str(round(WL(pcles_id))),'  ');
for i = 1 : length(lg)
    lg{i} = [lg{i},' nm'];
end 
lg{end + 1} = 'Non-enhanced';
legend( lg )
MinWhitSpace
saveas( gcf,'AbsPCR_power_depend.fig' )
saveas( gcf,'AbsPCR_power_depend.png' )
save incidentpowerdensity x 
save nonenh_PCR_QY0.65.mat nonenh_PCR
%% Plot diameter dependent enhancement. 
scatter(diameter,maxPCRenhfactor)

%% Plot enhanced I_sat and non-enhanced I_sat
figure
plot(abs(WL),I_satenh./PCR.I_sat)


%% Plot QY and SPR dependent PCR
figure
% use particle 11. SPR = 667 nm. 

plot(x, EnhPowerQYDepend{1,10}(QY_idx,:))
hold on
%plot(x, PCR.NonenhCountRatePowerQYdepend(i,:))

lg = {'0.01', '0.02', '0.05', '0.10', '0.20', '0.65', '1' };
legend(lg(QY_idx))
xlabel('Power density (W m^{-2})')
ylabel('Photon s^{-1}')
saveas( gcf,'AbsPCR_power_QY_depend_667nm.fig' )
saveas( gcf,'AbsPCR_power_QY_depend_667nm.png' )
%% Plot SPR dependent, at fixed powers, QY = 0.5, QY is 0.02 for CV
figure
idx = [36, 41,43, 46, 48, 50];
%idx = 1 : 50;
power = PCR.I_inc(idx);
for i = 1 : pcles
    for j = 1 : length(power)
        enhpqydepend(i,j) = EnhPowerQYDepend{i}(QY_idx,idx(j));
    end
end
str = cell(1, length(idx));
for j = 1 : length(idx)
    semilogy(abs(WL),enhpqydepend(:,j),'o-')
    hold on
    str{j} = num2str(PCR.I_inc(idx(j)),'%.E');
end 
legend(strcat(str, ' W m^{-2}'))
xlabel( 'SPR wavelength (nm)' )
ylabel('Photon count rate')

saveas( gcf,'AbsPCR_SPR_depend.fig' )
saveas( gcf,'AbsPCR_SPR_depend.png' )

%% Plot SPR dependent brightness enhancement at 7 nm. index 23
figure
for i = 1 : pcles
scatter(abs(WL(i)), EnhDistDepend_HI{i}(QY_idx,dist_idx)./NonenhDistDepend_HI{i}(QY_idx))
hold on
end 

%% Plot SPR_max dependent brightness enhancement, QY = 0.5
figure
plot(abs(WL),maxPCRenhfactor,'o-',abs(WL), FE_location)
lgd = legend('PCR_{max} enhancement (at saturated regime)','Enhancement factor (excitation independent)');
lgd.Location = 'northoutside'; 
xlabel( 'SPR wavelength (nm)' )
ylabel('Enhancement')
save WL WL
save maxPCRenhfactor maxPCRenhfactor
saveas( gcf,'SPR_vs_Brightness_enh.fig' )
saveas( gcf,'SPR_vs_Brightness_enh.png' )

%% Plot SPR dependent PCR enhancement at 2e7 wm-2
figure
semilogy(abs(WL),enhpqydepend(:,6)./NonenhPowerQYDepend{1,1}(QY_idx,idx(6)),'o-')
xlabel( 'SPR wavelength (nm)' )
ylabel('Brightness enhancement')
saveas( gcf,'Brightness_enhancement_2e7wm-2.fig' )
saveas( gcf,'Brightness_enhancement_2e7wm-2.png' )

figure
semilogy(abs(WL),enhpqydepend(:,6),'o-')
xlabel( 'SPR wavelength (nm)' )
ylabel('Photon s^{-1}')
saveas( gcf,'Brightness_PCR_2e7wm-2.fig' )
saveas( gcf,'Brightness_PCR_2e7wm-2.png' )



%% Plot SPR dependent, at fixed powers

figure
idx = [36, 41,43, 46, 48, 50];
power = PCR.I_inc(idx);
for i = 1 : pcles
    for j = 1 : length(power)
        enhpqydepend(i,j) = EnhPowerQYDepend{i}(QY_idx,idx(j));
    end
end
str = cell(1, length(idx));
for j = 1 : length(idx)
    semilogy(abs(WL),enhpqydepend(:,j),'o-')
    hold on
    str{j} = num2str(PCR.I_inc(idx(j)),'%.E');
end 
legend(strcat(str, ' W m^{-2}'))
xlabel( 'SPR wavelength (nm)' )
ylabel('Photon count rate')

saveas( gcf,'AbsPCR_SPR_depend.fig' )
saveas( gcf,'AbsPCR_SPR_depend.png' )

% plot SPR of maximum enhancement as a function power
figure
[maxi, id_max_1 ] = max( enhpqydepend(:,1) );
[maxi, id_max_2 ] = max( enhpqydepend(:,2) );
[maxi, id_max_3 ] = max( enhpqydepend(:,3) );
[maxi, id_max_4 ] = max( enhpqydepend(:,4) );
[maxi, id_max_5 ] = max( enhpqydepend(:,5) );
[maxi, id_max_6 ] = max( enhpqydepend(:,6) );
id_max = [WL(id_max_1),WL(id_max_2),WL(id_max_3),WL(id_max_4),WL(id_max_5),WL(id_max_6)];
plot(PCR.I_inc(idx), id_max )

save id_max id_max
save idx idx

%% Plot SPR and distance dependent SPR. Distance = 1, 3, 10, 30, 100. 

%idx_d = [ 3, 10, 35, 90, 200 ];

figure
for i = 1 : pcles
    loglog(decayrates.d_BEM, EnhDistDepend_HI{i}(QY_idx,:))
    hold on 
end 
legend(lg)
hline(NonenhDistDepend_HI{1,6}(QY_idx),'r:','Non-enhanced' )
xlabel( 'd (nm)' )
ylabel('Photon count rate')

MinWhitSpace
saveas( gcf,'Distance_depend.fig' )
saveas( gcf,'Distance_depend.png' )

%% Plot 2D correlation of SPR WLs (x) - Distance (y) - PCR (z) heat maps, fixed QY = 0.5

% At high power

figure
for i = 1 : pcles
    z(i,:) = EnhDistDepend_HI{i}(QY_idx,:);
end 
    
    
imagesc( WL, decayrates.d_BEM, z');
colorbar
colormap jet
set(gca,'ColorScale','log')
xlabel('SPR wavelength (nm)')
ylabel('molecule-particle separation d (nm)')
zlabel('Photon s^{-1}')

saveas(gcf,'SPR-d-PCR correlation HIGH exc.fig')
saveas(gcf,'SPR-d-PCR correlation HIGH exc.png')

% At low power

figure
for i = 1 : pcles
    z(i,:) = EnhDistDepend_LO{i}(QY_idx,:);
end 
    
    
imagesc( WL, decayrates.d_BEM, z');
colorbar
colormap jet
set(gca,'ColorScale','log')
xlabel('SPR wavelength (nm)')
ylabel('molecule-particle separation d (nm)')
zlabel('Photon s^{-1}')

saveas(gcf,'SPR-d-PCR correlation LOW exc.fig')
saveas(gcf,'SPR-d-PCR correlation LOW exc.png')

%% Plot distance-dependent brightness enhancement, at HIGH power
figure
for i = 1 : pcles
    z(i,:) = EnhDistDepend_HI{i}(QY_idx,:)./NonenhDistDepend_HI{i}(QY_idx);
end 

imagesc( WL, decayrates.d_BEM, z');
colorbar
colormap jet
set(gca,'ColorScale','log')
xlabel('SPR wavelength (nm)')
ylabel('molecule-particle separation d (nm)')
zlabel('Brightness enhancement')

saveas(gcf,'SPR-d-PCR correlation enhancement HIGH exc.fig')
saveas(gcf,'SPR-d-PCR correlation enhancement HIGH exc.png')