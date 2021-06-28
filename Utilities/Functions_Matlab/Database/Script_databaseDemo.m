% This program is used to verify the basic database operation
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
h0 = 337.6654968261719; %need to be comfimed
%base station lla? LTI
Base_Latitude = 40+48/60+ 24.81098/3600; %cenvert to degree units 
Base_longitude = -77 - 50/60 - 59.26859/3600;
lat0 =Base_Latitude;
lon0 = Base_longitude ;

[Route_mapping_van.Hemisphere_DGPS.xEast, Route_mapping_van.Hemisphere_DGPS.yNorth,Route_mapping_van.Hemisphere_DGPS.zUp] =...
    geodetic2enu(results_hemisphere.latitude',results_hemisphere.longitude',results_hemisphere.altitude',lat0,lon0,h0,spheroid);

disp('Hemisphere data query done');
%%

prompt = 'Do you want to save the query result to .mat file?[y/n] ';
User_input = input(prompt,'s')

if strcmpi(User_input,'y')
    prompt = 'Do you want to custom your filenane? [y/n] ';
    IsEnterName = input(prompt,'s')
    if strcmpi(IsEnterName,'y')
        prompt = 'Input the filename you want to save:';
        fileName = input(prompt,'s')
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

%% example2: give me Hemisphere Data when the van was driven by Dr. Brennan
sql_bagfiles =[ "select * from bag_files where trips_id in (select id from trips where driver = 'Dr. Brennan');"];
results_bagfiles = fetch(conn,sql_bagfiles)

%% specific table 
friction_table = 'road_friction';
sqlquery =['SELECT * FROM ' friction_table ';']; % be carefule with the space 
results = fetch(conn,sqlquery);

%% close the connection 
close(conn)


 %% ================== data Process demo======================
 
 %method 1:  run RoadProfile_read_2019_11_24_snb.m
 
 %method 2: data process for specific table 
 % covert the data format from table to struct 
friction_processed = table2struct(results,'ToScalar',true); 

% change the values in one fields
friction_processed.friction_coefficient = friction_processed.friction_coefficient *0.8; 

%add one field indicating the updating time 
formatOut = 'yyyy-mm-dd HH:MM:SS:FFF';
time_updated = cell(length(friction_processed.friction_coefficient),1);
time_updated(:) =  {datestr(now,formatOut)};
friction_processed. time_updated =time_updated;

prompt = 'Do you want to save the cleaned data to .mat file?[y/n] ';
User_input = input(prompt,'s')

%% =========== update processed data Database =======================

%%processed data database parameters
databasename = 'mapping_van_processed';  %'simulator_processed';
username = 'brennan';
password = 'password';
driver = 'org.postgresql.Driver';
%url = 'jdbc:postgresql://host:port/dbname';
url = ['jdbc:postgresql://130.203.223.234:5432/',databasename];  % This defines the IP address and port of the computer hosting the data (MOST important)
% ------------------------ CONNECT TO processed data DATABASE ------------------------ %
conn_processed = database(databasename,username,password,driver,url);

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
execute(conn_processed,sql_checkTableExist)
%% insert data into it 
sqlwrite(conn_processed,tablename,friction_processed)

%% query the dat use fetch, recommended 
sqlquery = ['SELECT * FROM ' tablename];
friction_updated = fetch(conn_processed,sqlquery,'DataReturnFormat','structure', ...
    'MaxRows',5);

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

%% Close the database connection.
close(conn_processed)
%%

error('stop here ')

%%
% fetchBagFileIDs();
% fetchTripIDs();


%% call procedures 
% CREATE PROCEDURE create_table 
% 	
% AS
% BEGIN
% %	-- SET NOCOUNT ON added to prevent extra result sets from
% %	-- interfering with SELECT statements.
% 	SET NOCOUNT ON;
% 
% CREATE TABLE test_table
% 	 (
% 		CATEGORY_ID     INTEGER     IDENTITY PRIMARY KEY,
% 		CATEGORY_DESC   CHAR(50)    NOT NULL
%         );
% 	
% END
% GO
%Connect to the Microsoft SQL Server database. This code assumes that you are connecting to a data source named MS SQL Server with a user name and password.
% 
% conn = database('MS SQL Server','username','pwd');
% %Call the stored procedure create_table.
% 
% execute(conn,'create_table')
% results = runstoredprocedure(conn,'create_table')
