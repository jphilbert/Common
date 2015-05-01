/* ******************************************************
	To connect / link to MedVentive DB
   ****************************************************** */
EXEC sp_addlinkedserver
   @server = N'MedVentive',		-- Local Name
   --@srvproduct = '',
   @provider = N'SQLNCLI',
   @datasrc = N'168.75.170.137'	-- Server
 
EXEC sp_addlinkedsrvlogin
   @useself='FALSE',
   @rmtsrvname='MedVentive',
   @rmtuser='mcelender',
   @rmtpassword='Gauguin<85'
GO

/* ******************************************************
	To disconnect
   ****************************************************** */
--exec sp_dropserver 'MedVentive'
--exec sp_droplinkedsrvlogin 'MedVentive', null


/* ******************************************************
	Some Examples
	Note: it appears that you cannot select a table in tempdb the usual way
   ****************************************************** */
-- Does Not Work
-- select * from Medventive.tempdb.dbo.##temp where NPI like '1609911%';

-- Works
-- select * into SandBox.dbo.Temp From OPENQUERY(MedVentive, 'select * from ##temp')
