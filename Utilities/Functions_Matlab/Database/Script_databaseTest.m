% This program is used to verify the databse connection
%
% Author: Liming Gao
% Create Date: 2020-02-18
% =======update=======
% 1.add connection error type check (2020-04-22)
%======== to do list ============
% 1. 

clear,clc
close all

format longg

%% ------------------------ CONNECT TO  DATABASE ------------------------ %

% choose different database name to connect to them
%%raw data database parameters
ip_address = '130.203.223.234'; %Ip address of server host
% nsf_roadtraffic_friction_v2  
database_name = 'mapping_van_raw';  %%,simulator - this is the database server we will push to
username = 'ivsg_db_user'; % user name for the server
password = 'ivsg@*****'; % password
driver = 'org.postgresql.Driver'; % tells MATLAB what driver to use?

url = ['jdbc:postgresql://' ip_address ':' num2str(5432) '/',database_name];
%url = ['jdbc:postgresql://130.203.223.234:5432/',databasename];  % This defines the IP address and port of the computer hosting the data (MOST important)

% connect to databse
conn = database(database_name,username,password,driver,url);
if strncmp(conn.Message,'JDBC Driver Error: No suitable driver found',42)     % Database connection status message
    error('MyComponent:incorrectDriver','JDBC Driver Error: No suitable driver found! \nPlease run javaclasspath to check if the JDBC java driver path has been added.\n')
elseif strncmp(conn.Message,'JDBC Driver Error: The connection attempt failed.',48)
    error('MyComponent:incorrectNetwork','JDBC Driver Error: The connection attempt failed! \nPlease check your VPN or Internet connection!\n')
elseif isempty(conn.Message)
    fprintf(['Connected to ' database_name ' database!\n'])
else
    fprintf(['The connection status is ' conn.Message ' !\n'])
end

%% ====================================================
% (see https://www.askapache.com/online-tools/figlet-ascii/ to make this)
%  ______                           _
% |  ____|                         | |
% | |__  __  ____ _ _ __ ___  _ __ | | ___  ___
% |  __| \ \/ / _` | '_ ` _ \| '_ \| |/ _ \/ __|
% | |____ >  < (_| | | | | | | |_) | |  __/\__ \
% |______/_/\_\__,_|_| |_| |_| .__/|_|\___||___/
%                            | |
%                            |_|
% ====================================================

%% ============== Query the data from database =====================
% Find Catalogs and Schemas in the database
tables = sqlfind(conn,'','Schema','public');

%% Find infomation about a table
pattern =  'hemisphere_gps'; %
table_info = sqlfind(conn,pattern);

%% query data from the table

% step 1: to see what trips and bag files we have in the raw data database
bag_table = 'bag_files';
trip_table = 'trips';
sqlquery =['SELECT * FROM ' trip_table ';']; % be carefule with the space
trips = fetch(conn,sqlquery);

sqlquery =['SELECT * FROM ' bag_table ';']; % be carefule with the space
bags = fetch(conn,sqlquery);

%% step 2: query the data as you expected(eg. 1. give me all sensors data  at Test Track MappingVan 2019-10-19, 2.give me Hemisphere Data when the van was driven by Dr. Brennan)
%example1:give me Hemisphere Data data  at Test Track MappingVan 2019-10-19
sql_bagfiles =[ "select * from bag_files where trips_id in (select id from trips where name = 'Test Track MappingVan 2019-10-19');"];
results_bagfiles = fetch(conn,sql_bagfiles)

% convert numeric array to cell array:
% cellstr(num2str(results_bagfiles.id)) or sprintfc('%d',results_bagfiles.id)
disp('Query hemisphere data..:');
sql=[ 'select * from hemisphere_gps where bag_files_id in (', strjoin(sprintfc('%d',results_bagfiles.id),','), ');'];
results_hemisphere = fetch(conn,sql);

Route_mapping_van.Hemisphere_DGPS.AgeOfDiff= results_hemisphere.ageofdiff';
Route_mapping_van.Hemisphere_DGPS.GPSWeek= results_hemisphere.gps_week';%GPS week associated with this message
Route_mapping_van.Hemisphere_DGPS.GPSTimeOfWeek= results_hemisphere.gps_seconds'; %GPS tow (sec) associated with this message
Route_mapping_van.Hemisphere_DGPS.StdDevResid= results_hemisphere.stddevresid';%Standard deviation of residuals in meters
Route_mapping_van.Hemisphere_DGPS.ExtendedAgeOfDiff= results_hemisphere.extendedageofdiff';
Route_mapping_van.Hemisphere_DGPS.ROSTime=results_hemisphere.seconds'+ results_hemisphere.nanoseconds'*10^(-9);
Route_mapping_van.Hemisphere_DGPS.Time=results_hemisphere.time'*10^(-9);  %ROStime
Route_mapping_van.Hemisphere_DGPS.Latitude=results_hemisphere.latitude';  %Latitude in degrees north
Route_mapping_van.Hemisphere_DGPS.Longitude=results_hemisphere.longitude'; %Longitude in degrees East
Route_mapping_van.Hemisphere_DGPS.Height=results_hemisphere.altitude'; %Altitude  above the ellipsoid in meters
Route_mapping_van.Hemisphere_DGPS.NavMode=results_hemisphere.navmode'; % Navigation mode:0 = No fix?1 = Fix 2d no diff ?2 = Fix 3d no diff ?3 = Fix 2D with diff? 4 = Fix 3D with diff? 5 = RTK float?6 = RTK integer fixed
Route_mapping_van.Hemisphere_DGPS.VNorth=results_hemisphere.vnorth';  %Velocity north in m/s
Route_mapping_van.Hemisphere_DGPS.VEast=results_hemisphere.veast'; %Velocity east in m/s
Route_mapping_van.Hemisphere_DGPS.VUp=results_hemisphere.vup'; %Velocity up in m/s
Route_mapping_van.Hemisphere_DGPS.NumOfSats=results_hemisphere.numofsats';
%convert to ENU
spheroid = referenceEllipsoid('wgs84');
%reference station at test track
lat0=40.862311;
lon0=-77.836270;
h0 = 337.6654968261719; %need to be comf imed
%base station lla? LTI
Base_Latitude = 40+48/60+ 24.81098/3600; %cenvert to degree units
Base_longitude = -77 - 50/60 - 59.26859/3600;
lat0 =Base_Latitude;
lon0 = Base_longitude ;

[Route_mapping_van.Hemisphere_DGPS.xEast, Route_mapping_van.Hemisphere_DGPS.yNorth,Route_mapping_van.Hemisphere_DGPS.zUp] =...
    geodetic2enu(results_hemisphere.latitude',results_hemisphere.longitude',results_hemisphere.altitude',lat0,lon0,h0,spheroid);

disp('Hemisphere data query done');

fprintf('\n===================================\n')
fprintf('Congratulation! \nYour Database setup is successful!\n')
fprintf('===================================\n')

