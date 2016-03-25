function data = fetchDBPriceData(startDate, endDate)

% Set preferences with setdbprefs.
s.DataReturnFormat = 'structure';
s.ErrorHandling = 'store';
s.NullNumberRead = 'NaN';
s.NullNumberWrite = 'NaN';
s.NullStringRead = 'null';
s.NullStringWrite = 'null';
s.JDBCDataSourceFile = '';
s.UseRegistryForSources = 'yes';
s.TempDirForRegistryOutput = 'C:\Temp';
s.DefaultRowPreFetch = '10000';
setdbprefs(s)

% Make connection to database.  Note that the password has been omitted.
% Using ODBC driver.
conn = database('EnergyData','','password');

% Read data from database.
e = exec(conn,['SELECT ALL Date,Hour,DryBulb,DewPnt,SYSLoad,NGPrice,ElecPrice FROM NEData WHERE Date BETWEEN #' startDate '# AND #' endDate '#  ']);
e = fetch(e);
close(e)

% Assign data to output variable.
data = e.Data;
data.NumDate = datenum(data.Date, 'yyyy-mm-dd') + (data.Hour-1)/24;

% Close database connection.
close(conn)
