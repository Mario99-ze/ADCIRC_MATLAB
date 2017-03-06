% Read kml file created in google maps to get new coordinates of stations 
% (we move the stations to reasonable locations off land etc in google maps
% before exporting to kml). 
% Automatically finds the boundary of your grid and selects only those
% ones. 
clearvars; clc;

%% Reading the kml
kmlStruct = kml2struct('Global_tide_gauge_database.kml');

% Getting rid of unnecessary shit
T = struct2table(kmlStruct);
T.Geometry = [];
T.BoundingBox = [];
T.Description = [];

%% Only select nodes within the bounds of your domain
grid = '../IDIOMS_v7.1_SSG+TPXAnt_D2G.grd';

% Get the boundaries
[ev,pv,~,~,~,~] = readfort14(grid);

% Extrace edges on the boundaries from a given mesh, pv, ev %
[etbv,vxe,etoe,etof] = extdom_edges( ev, pv ) ;

iedbeg  = 1 ;
start   = 1;
poly    = [];
% Extract the outter domain 
while ~isempty(etbv)
    pacw = 0; nn = 0;
    while pacw == 0
        nn = nn + 1;
        if nn == 1
            ipsbeg = 1 ; % polygon travese in 'ipsbeg' --> 'ipsend' 
            ipsend = 2 ; %
        else
            ipsbeg = 2 ; % polygon travese in 'ipsbeg' --> 'ipsend' 
            ipsend = 1 ; %   
        end
        [vso,~,ide] = extdom_polygon( etbv, pv, iedbeg, ipsbeg, ipsend ) ;
        pacw = ~ispolycw(vso(:,1),vso(:,2));
        if start == 1 && pacw == 0; 
            start = 0;
            break; 
        end
        % vso(:,2) - coordinate of an extracted polygon 
        % idv  -- indices of extracted ploygon in the global mesh,  vso = pv(idv,:)  
        % ide  -- indeces of edges in etbv that constitute vso,  
        % ie. vso = vxe(reshape(etbv(:,ide),length(ide)*2),:)  
    end
    poly = [poly; vso; NaN NaN];
    etbv(:,ide) = [];
end

%% Write to the .csv
% Do the inpolygon and change to lon, lat, name order for fort.15 input
T = T(InPolygon(T.Lon,T.Lat,poly(:,1),poly(:,2)) == 1,[2 3 1]);

% Output table of the names and positions
writetable(T,'IDIOMS_v7.1_HC_March5_2017.csv')
