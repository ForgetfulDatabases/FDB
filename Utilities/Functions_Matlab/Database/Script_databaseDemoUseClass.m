% This program is used to verify the basic database operation
%
% Author: Liming Gao
% Create Date: 2020-02-18
% =======update=======
% 1. add connection error type check (2020-04-22)
%======== to do list ============
% 1. test databaseDatastore, https://www.mathworks.com/help/database/ug/matlab.io.datastore.databasedatastore.html
%
clear,clc
close all
restoredefaultpath
format longg

%% ------------------------ CONNECT TO  DATABASE ------------------------ %
% choose different database name to connect to them
database_name = 'mapping_van_raw';
% database_name = 'nsf_roadtraffic_friction_v2';
% database_name = 'volvo_truck_raw';

%javaaddpath('F:\Program Files\MATLAB\R2019b\drivers\PostgreSQL_JDBC_Driver\postgresql-42.2.9.jar')

% Connect raw data database
DB = Database(database_name);  % instance of Database class
MDB = MapDatabase(database_name); % instance of MapDatabase Class
% DB.db_connection % show connection details
MDB.db.db_connection

%% use databaseDatastore
% Notes: need further exploration
%{
sqlquery = 'select * from novatel_gps';

dbds = databaseDatastore(MDB.db.db_connection,sqlquery);
preview(dbds)

dbds.ReadSize = 10;
read(dbds)

data = readall(dbds);

%Reset the DatabaseDatastore object to its original state, where no data has been read from it. Resetting allows you to reread from the same DatabaseDatastore object.
reset(dbds)
read(dbds)
% while(hasdata(dbds))
%      read(dbds)
% end

close(dbds)
%}
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
% Find tables in the database
%%show tables
tables = DB.ShowTables();

%%show trips
sql_query = 'select * from trips';
trips = fetch(DB.db_connection, sql_query); %#ok<NASGU>

%%show trajectory if database_name = 'nsf_roadtraffic_friction_v2';
% ddd= 'select * from road_traffic_raw where vehicle_id = 99';
% trajectory = fetch(DB.db_connection, ddd);
% %
% yaw_diff = atan2(diff(trajectory.positioncg_y), diff(trajectory.positioncg_x));
% yaw = [yaw_diff(1); yaw_diff]*180/pi;
%
% figure(2)
% plot(trajectory.station_total,yaw)
% grid on

%{
%%show example data at volvo_truck_raw
trip_name = 'StateCollegeTocityA 2019-12-04';

% 1) find bag files
sql_bagfiles = ['select * from bag_files where trips_id in (select id from trips where name = ''',trip_name,''')'];
results_bagfiles = fetch(DB.db_connection,sql_bagfiles);

% 2) query data
disp('Query hemisphere data..:');
sql_hemisphere_left=[ 'select * from hemisphere_gps_left where bag_files_id in (', strjoin(sprintfc('%d',results_bagfiles.id),','), ');'];
results_hemisphere_left = fetch(DB.db_connection,sql_hemisphere_left);

sql_hemisphere_right=[ 'select * from hemisphere_gps_right where bag_files_id in (', strjoin(sprintfc('%d',results_bagfiles.id),','), ');'];
results_hemisphere_right = fetch(DB.db_connection,sql_hemisphere_right);

disp('Hemisphere data query done');
%}


%% previleges test
% can query
sql_select_test=[ 'select * from airports where code = ''KEF'';'];
results_test = fetch(DB.db_connection,sql_select_test);

% cannot delete
sql_test=[ 'delete from airports where code = ''KEF'';'];
execute(DB.db_connection,sql_test);

% cannot update/insert
sql_test=[ 'update airports SET geog = ''POINT(-22.333,77.345)'' where code = ''KEF'';'];
execute(DB.db_connection,sql_test);

%% Find infomation about a table
pattern =  'hemisphere_gps'; %
table_info = sqlfind(DB.db_connection,pattern);

%% query data from the table
% step 1: to see what trips and bag files we have in the raw data database
bag_table = 'bag_files';
[bag_result] = DB.select(bag_table,'all'); % all columns

trip_table = 'trips';
[trip_result] = DB.select(trip_table,'all');

%% step 2: query the data as you expected()
%% Example 1:give selected sensors data of trip "Test Track MappingVan2019-10-19"
% query parameters
MDB.zero_time = 0;  % offset the timestamps starting from zero
MDB.verbose = 1;  % show the processing details
MDB.convert_GPS_to_ENU = 1; % default reference point 'LTI, Larson  Transportation Institute'
MDB.separate_by_lap = 0;

% check all the trips
trips = MDB.fetchTrips();

% pick trips you want to query
% trip_names = {'Test Track Decision Points with Lane Change MappingVan 2020-03-13','Test Track MappingVan 2019-10-19'};
trip_names = {'Test Track Decision Points with Lane Change MappingVan 2020-03-13'};

% trip_id = trips.id(trips.name == {'Test Track Decision Points with Lane Change MappingVan 2020-03-13'});
trip_id = [];
for i = 1:length(trip_names)
    trip_id = cat(1,trip_id,trips.id(strcmp(trips.name, trip_names(i))));
end

% 1 means query data from that sensor
options = {};
options.sensors.base_station = 1;  % default is 1
options.sensors.hemisphere_gps = 1; % default is 1
options.sensors.NovAtel_gps = 1; % default is 1
options.sensors.garmin_gps = 1; % default is 1
options.sensors.garmin_velocity = 1; % default is 0
options.sensors.steering_angle =1; % default is 1
options.sensors.NovAtel_imu = 1;% default is 1
options.sensors.adis_imu = 1;% default is 1
options.sensors.encoder_left_right = 1;% default is 1
options.sensors.laser = 0;
options.sensors.front_left_camera = 0;
options.sensors.front_right_camera = 0;
options.sensors.front_center_camera = 0;
options.ENU_ref = 0; % 0 default, 1 test track, 2 LTI

result = MDB.fetchByTripID(trip_id,options); %result of query, format is struct

%% Example 2:query Hemisphere Data of trip "Test Track MappingVan2019-10-19"
% 1) find bag files
where = "trips_id in (select id from trips where name = 'Test Track MappingVan 2019-10-19')";
[results_bagfiles] = DB.select( 'bag_files', 'all', where);

% 2) query data
disp('Query hemisphere data..:');
%sql=[ 'select * from hemisphere_gps where bag_files_id in (', strjoin(sprintfc('%d',results_bagfiles.id),','), ');'];
% results_hemisphere = fetch(conn,sql);

where = {['bag_files_id in (', strjoin(sprintfc('%d',results_bagfiles.id),','), ')']};
[results_hemisphere] = DB.select( 'hemisphere_gps', 'all', where);
%
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
lat0=40.862311;  %#ok<NASGU>
lon0=-77.836270; %#ok<NASGU>
h0 = 337.6654968261719; %need to be comfimed
%base station lla? LTI
Base_Latitude = 40+48/60+ 24.81098/3600; %cenvert to degree units
Base_longitude = -77 - 50/60 - 59.26859/3600;
lat0 =Base_Latitude;
lon0 = Base_longitude ;

[Route_mapping_van.Hemisphere_DGPS.xEast, Route_mapping_van.Hemisphere_DGPS.yNorth,Route_mapping_van.Hemisphere_DGPS.zUp] =...
    geodetic2enu(results_hemisphere.latitude',results_hemisphere.longitude',results_hemisphere.altitude',lat0,lon0,h0,spheroid);

disp('Hemisphere data query done');

%% Example 3:query selected sensors data by time reange
% step1: set query parameters
MDB.zero_time = 0;  % offset the timestamps starting from zero
MDB.verbose = 1;  % show the processing details
MDB.convert_GPS_to_ENU = 1; % default reference point 'LTI, Larson  Transportation Institute'
MDB.separate_by_lap = 0;

% check all the trips and date
trips = MDB.fetchTrips();
trips_id = trips.id;

% update the datetime_end of trips(only needto do it once)
if 1==0
    for i_trip = 1:length(trips_id)
        
        sql_datetime_end= ['select bag_files_id,timestamp from Hemisphere_gps where bag_files_id in ( select id from bag_files where trips_id = ' num2str(trips_id(i_trip)) ') ORDER BY timestamp DESC LIMIT 1;'];
        result_datetime_end = fetch(DB.db_connection, sql_datetime_end);
        
        datetime_end = result_datetime_end.timestamp;
        
        %update datetime_end of trips table
        colnames = {'datetime_end'};
        %Define a cell array containing the new data.
        data = datetime_end;
        tablename = 'bag_files';
        whereclause = ['WHERE trips_id = ', num2str(trips_id(i_trip))];
        update(DB.db_connection,tablename,colnames,data,whereclause)
        
    end
end

bagfiles = MDB.fetchBagFileIDs();

%%step2: pick time range you want to query 

[trip_names,ia,ic] = unique(trips.name,'stable'); % find trips

% find daterange for each trip
trip_withDate = trip_names;
for i_trip= 1:length(trip_names)
    rows = strcmp(trips.name, trip_names{i_trip});
    id_trips = trips.id(rows); %find trip_ids for each trips
    bags_ofTrip = bagfiles(ismember(bagfiles.trips_id, id_trips),:); %find bagfiles_ids for each trips
    
    trip_startTime = bags_ofTrip.datetime(1); % this works because the data were sorted by datetime 
    trip_endTime = bags_ofTrip.datetime_end(end);
    trip_withDate{i_trip} = [' ' num2str(i_trip) '.TripName:' trip_names{i_trip},'. Start_time:',trip_startTime{1},'. End_time:',trip_endTime{1}];
end

%%show available trips and time range
fprintf([newline 'Available trips and time range:' newline strjoin(trip_withDate,'\n') newline]);

% input start and end time
prompt_InputStartTime =[newline 'Input Strat Time(Format: yyyy-mm-dd HH:MM:ss): '];
User_InputStartTime = input(prompt_InputStartTime,'s');

prompt_InputEndTime =[newline 'Input End Time(Format: yyyy-mm-dd HH:MM:ss): '];
User_InputEndTime = input(prompt_InputEndTime,'s');

prompt = [newline 'Are you going to query the data from : ' User_InputStartTime ' to ' User_InputEndTime '?[y/n]'];
User_input = input(prompt,'s');

% dateformat
try
    datetime(User_InputStartTime,'InputFormat','yyyy-MM-dd HH:mm:ss');
    datetime(User_InputEndTime,'InputFormat','yyyy-MM-dd HH:mm:ss');
    
catch
    fprintf(1,'Your Input date format is wrong.Please try again. \nQuery is aborted..\n');
    return
end
% confrim the information with user
if strcmpi(User_input,'y')
    fprintf(1,'Thanks. Let''s query it...\n');
else
    fprintf(1,'Query is aborted. \nYou can Re-pick the time range.\n');
    return
end

%
sql_test = ['SELECT * FROM hemisphere_gps WHERE timestamp >= ''2019-09-17 15:07:19'' AND timestamp < ''2019-09-17 15:07:21'';'];
result_test = fetch(DB.db_connection, sql_test); 

% Step3: query data by time range ------------------------ %

% 1 means query data from that sensor
options = {};
options.sensors.base_station = 1;  % default is 1
options.sensors.hemisphere_gps = 1; % default is 1
options.sensors.NovAtel_gps = 1; % default is 1
options.sensors.garmin_gps = 1; % default is 1
options.sensors.garmin_velocity = 1; % default is 0
options.sensors.steering_angle =1; % default is 1
options.sensors.NovAtel_imu = 1;% default is 1
options.sensors.adis_imu = 1;% default is 1
options.sensors.encoder_left_right = 1;% default is 1
options.sensors.laser = 0;
options.sensors.front_left_camera = 0;
options.sensors.front_right_camera = 0;
options.sensors.front_center_camera = 0;
options.ENU_ref = 0; % 0 default, 1 test track, 2 LTI

result = MDB.fetchByTimeRange(User_InputStartTime,User_InputEndTime,options); %result of query, format is struct

%% =========== save the data to .mat file

prompt = 'Do you want to save the query result to .mat file?[y/n] ';
User_input = input(prompt,'s');

if strcmpi(User_input,'y')
    prompt = 'Do you want to custom your filenane? [y/n] ';
    IsEnterName = input(prompt,'s');
    if strcmpi(IsEnterName,'y')
        prompt = 'Input the filename you want to save:';
        fileName = input(prompt,'s');
    else
        fileName ='Route_Wahba';
    end
    eval([fileName,'=Route_mapping_van'])
    save(strcat(fileName,'.mat'),fileName)
    fprintf(' %s.mat has been saved. \n ',fileName);
else
    disp("The variable name will be 'Route_mapping_van' .");
    %  eval([fileName,'=Route_test_track'])
end

%% example 4: give me Hemisphere Data when the van was driven by Dr. Brennan

where = "trips_id in (select id from trips where driver = 'Dr. Brennan')";
[results_bagfiles] = DB.select( 'bag_files', 'all', where);

%% Disconnect from the database
DB.disconnect();
MDB.disconnect();

return
% edit stop here
%% ================== data Process demo ======================

%method 1:  run RoadProfile_read_2019_11_24_snb.m

prompt = 'Do you want to save the cleaned data to .mat file?[y/n] ';
User_input = input(prompt,'s')

%% method 2: data process for specific table
%%some example data
[friction_results] = DB.select( 'road_friction', 'all');

% covert the data format from table to struct
friction_processed = table2struct(friction_results,'ToScalar',true);

% change the values in one fields
friction_processed.friction_coefficient = friction_processed.friction_coefficient *0.8;

%add one field indicating the updating time
formatOut = 'yyyy-mm-dd HH:MM:SS:FFF';
time_updated = cell(length(friction_processed.friction_coefficient),1);
time_updated(:) =  {datestr(now,formatOut)};
friction_processed. time_updated =time_updated;

%% =========== Store processed data Database =======================

% ------------------------ CONNECT TO processed data DATABASE ------------------------ %
database_name = 'mapping_van_processed';
% Connect raw data database
DB_pro = Database(database_name);
%
%% preprocess cleaned data
load('Route_WahbaLoop_cleaned.mat')
eval(['cleaned_data','=Route_WahbaLoop_cleaned'])

tables = fieldnames(cleaned_data); %read the subfield name of a structure, and each subfiled will be stored as a table
for i_table = 1:length(tables)
    table_name = tables{i_table};
    field_content = cleaned_data.(table_name); % extract field  data
    table_content = struct2table(field_content); % error
    
end

%% convert the struct data to table
friction_processed =  struct2table(friction_processed);

%% Create a new table in  processed database and insert the processd table into it.
%check if the same table is existed
tablename = 'friction_processed';
sql_checkTableExist = ['DROP TABLE IF EXISTS ' tablename];
execute(DB_pro.db_connection,sql_checkTableExist)
%% insert data into it
sqlwrite(DB_pro.db_connection,tablename,friction_processed)  % the DB will create a table if the table is not exist, or append the data to the table

%% query the data use fetch to check
sqlquery = ['SELECT * FROM ' tablename];
friction_updated = fetch(DB_pro.db_connection,sqlquery,'DataReturnFormat','structure','MaxRows',5);
friction_updated
%% Close the database connection.
DB_pro.disconnect();
%%

error('stop here ')

%% also we can query the data use sqlread, the Options help us get a big picture of the table
%Create an SQLImportOptions object using the patients database table and the databaseImportOptions function.
opts = databaseImportOptions(conn_processed,tablename);
%Display the current import options for the variables selected in the SelectedVariableNames property of the SQLImportOptions object.

vars = opts.SelectedVariableNames;
varOpts = getoptions(opts,vars);
%
data = sqlread(conn_processed,tablename);
%Delete the patients database table using the execute function.
%%
sqlquery = ['DROP TABLE ' tablename];
execute(conn_processed,sqlquery)




