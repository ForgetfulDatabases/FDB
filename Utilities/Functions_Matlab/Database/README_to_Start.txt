SERVER demonstration and instructions
Authors: Liming Gao and Sean Brennan, sbrennan@psu.edu
Date: 2020_03_17

The goal of this software is to demonstrate the following:
* How to pull data out of a server via MATLAB commands
* Processing the data using existing MATLAB scripts (this is documented elsewhere, and this code is borrowed here)
* Pushing the processed data into another server

The demonstration here is pulling from the rawdata server that is hosting mapping van data, and is specifically querying data from the "Wahba Loop" data collection which is 4 laps in the local area. The results are pushed into the "Mapping_Test" database. In practice though, the raw data after it is processed would be pushed into a database for processed data. We do not do that here to avoid messing up that data flow process.

To get started:

Step 1: Install PostGreSQL onto your computer
1a: go to: https://www.postgresql.org/download/
1b: pick your version (Brennan is using Windows, for example) - this will go to an installer page
1c: click download the Installer, which opens up a page of versions. 
1d: pick 10.12 for now (as of 2020_03_15) as this version supports Windows, Linux, etc.
1e: it will download the install files to your computer after you click. Run the executable. If in Windows, it will give you an Admin "confirm install?" prompt.
1f: it will then open an install wizard. Just use the defaults on everything for now (unless you know this software well and want to do otherwise - at your own risk). Make sure all components are selected though (there were 4 items on the Windows install of version 10.2, for example)
1g: it will ask you to set a password. This is for any local databases that you may create. This doesn't much matter at this point. (Brennan's is Reber320)
1h: it will ask you for the port number the server should listen on. Use the default, it should be: 5432
1i: it will ask you for the default location for the database cluster. Use the default.
1j: it will then confirm the scripts to you, and if you agree, it will take you to the "Ready to Install" screen. Hit "next" to start the install. This may take a while.
1k: when done, it will ask if you want to install Stack Builder at exit. You WANT to install this, so leave it checked when you hit "finish".
1l: The Stack Builder install will then launch. Select the installation you want - in our case it will be PostgreSQL 10 on port 5432.
1m: You will be presented with a question: "Please select the applications you would like to install" and this presents to you a HUGE tree of software. We want the "Spatial Extensions" sub-tree, specifically the "PostGIS 2.5 Bundle for PostgreSQL v 2.5.3".  Then select "next" after you select the packages. It will ask you to review the installs, and ask for a directory where you want to download the install files. When you hit next, it will download the files and should give you a "Next" button to start installation.

Step 2: For the PostGIS Bundle 2.5.3:
It will then give you a license agreement. Agree to this, if you wish. It will ask you to install components, pick both the PostGIS *and* the Create spatial database options. It will ask for a username (Brennan chose the default: postgres) and password (Brennan: Reber320). It will then ask for a spatial database name. We just chose the default (for us, it was "postgis_25_sample"). Then click "Install". It may ask you if you want to set some environment variables. Select "yes" to the questions that follow to enable variables to be set for the drivers. Once completed, hit "finish".

Step 3: Download the driver to allow MATLAB to communicate to PostGreSQL.
Open up MATLAB, and check which version of Java you are using. To do this, open MATLAB, and type "ver" at the command prompt. Near the top, it will tell you what version of Java is being used. The line below is cut/paste from Brennan's computer, as an example:

"Java Version: Java 1.8.0_202-b08 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM mixed mode"

The second number "8" here, in Java 1.8, means that version 8 is being used.

To download the JDBC driver, open the link: https://jdbc.postgresql.org/download.html

From the link, we know that ??If you are using Java 8 or newer then you should use the JDBC 4.2 version.?? This probably applies to you.

Scroll down, and look under the list of JDBC 4.2 drivers. We are using the 42.2.9 JDBC 42 version JAR file. "42.2.9 JDBC 42". Click on this, and it will ask you to save the file to a folder, for example : F:\Program Files\MATLAB\R2019b\drivers\PostgreSQL_JDBC_Driver\jar8\postgresql-42.2.9.jar2.2
We suggest that you keep it someplace with MATLAB's install, such as a "drivers" subfolder within the MATLAB install. If you want to see where MATLAB is installed on your own computer, type "which matlab".

Make sure MATLAB can see the path to your driver by using the command: 
method 1(recommened):
-run "prefdir" in your command line, it gives your matlab preference path
-Under that path, open the javaclasspath.txt file(if it does not exist, create one), append the your jar path to it. 
for example,F:\Program Files\MATLAB\R2019b\drivers\PostgreSQL_JDBC_Driver\postgresql-42.2.9.jar
-then save it.
-restart matlab to active the path !!!!

method 2:
javaaddpath(path) 
where path is the location of your path and the jar file (MUST have both).
for example:
javaaddpath('F:\Program Files\MATLAB\R2019b\drivers\PostgreSQL_JDBC_Driver\postgresql-42.2.9.jar')

To be sure the path was added, run "javaclasspath". The path you added should appear on the bottom of the very long list.

Step 4: Make sure your PSU VPN is up and running to the Penn State campus, so you can access the server that is currently hosting the Mapping Van data.

Step 5: Run Script_databaseTest.m to test your connection. Your configuration is successful if no error appears. Otherwise, check the JDBC driver or VPN. 

Step 6: (optional for setup, recommended for learn)Run Script_databaseDemo.m and Script_databaseDemoUseClass.m to learn more databse operations.

NOTES: DO NOT test the command deleting data in any IVSG database without approval.
