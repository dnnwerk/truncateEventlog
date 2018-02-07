/* Truncate EventLog - Version 0.9.8 (2015-07-25)
   ================================================================================
   (c) Sebastian Leupold, dnnWerk/gamma concept mbH 2014-2015

   Run this Script to remove all entries of EventLog in DNN Platform V.5.0.0 - 7.4.0
      
   == Please make sure to use latest version from http://dnnscript.codeplex.com ===
   
   Instructions:
   =============
   - Install by running as script from SQL item in Host menu inside DNN or run in 
     SQL Server Management Studio, after replacing placeholders {databaseOwner} and
	 {objectQualifier} by its proper values from web.config file.

   - Make sure that the currently used account is member of dbOwner database role.
   
   License and Disclaimer:
   =======================
   Published under Microsoft Open Source Reciprocal License (Ms-RL). For details, 
   please read http://dnnscript.codeplex.com/license.
   Feel free to use this script as you need, but there is no warranty or liability 
   for any damage or effort, eventually been caused.

   Please report issues at https://dnnscript.codeplex.com/WorkItem/Create
   ================================================================================
*/

IF EXISTS (SELECT * FROM sys.sysobjects WHERE id = object_id(N'{databaseOwner}[{objectQualifier}sys_currentDNNVersion]') AND Type = N'FN')
	DROP FUNCTION {databaseOwner}[{objectQualifier}sys_currentDNNVersion]
GO
-- --------- create tooling: --------- 

CREATE FUNCTION {databaseOwner}[{objectQualifier}sys_currentDNNVersion]()
	RETURNS Int
AS	
BEGIN
	DECLARE @Vers Int;
	SELECT Top(1) @Vers = Major * 10000 + Minor * 100 + Build FROM {databaseOwner}[{objectQualifier}Version] ORDER BY CreatedDate DESC;
	RETURN @Vers;
END
GO

IF {databaseOwner}[{objectQualifier}sys_currentDNNVersion]() >= 70400 BEGIN
	-- Drop Foreign Key Constraints:
	DECLARE @fkName nVarChar(100) = Null;
	SELECT @fkName = name FROM sys.foreign_keys 
	 WHERE parent_object_id = OBJECT_ID(N'{databaseOwner}[{objectQualifier}ExceptionEvents]')
	   AND Object_id IN (SELECT constraint_object_id  
	                      FROM  sys.foreign_key_columns F 
						  JOIN  sys.columns C ON F.parent_object_id = C.object_id AND F.parent_column_id = C.column_ID 
						  WHERE C.Name = N'LogEventID');
	IF Not @fkName Is Null
		Exec(N'ALTER TABLE {databaseOwner}[{objectQualifier}ExceptionEvents] DROP CONSTRAINT [' + @fkName +'];');

	SET @fkName = Null;
	SELECT @fkName = name FROM sys.foreign_keys 
	 WHERE parent_object_id = OBJECT_ID(N'{databaseOwner}[{objectQualifier}EventLog]')
	   AND Object_id IN (SELECT constraint_object_id  
	                      FROM  sys.foreign_key_columns F 
						  JOIN  sys.columns C ON F.parent_object_id = C.object_id AND F.parent_column_id = C.column_ID 
						  WHERE C.Name = N'ExceptionHash');
	IF Not @fkName Is Null
		Exec(N'ALTER TABLE {databaseOwner}[{objectQualifier}EventLog] DROP CONSTRAINT [' + @fkName +']')
END
GO

-- Truncate tables:
IF {databaseOwner}[{objectQualifier}sys_currentDNNVersion]() >= 70400 BEGIN
	TRUNCATE TABLE {databaseOwner}[{objectQualifier}Exceptions]
	TRUNCATE TABLE {databaseOwner}[{objectQualifier}ExceptionEvents]
	TRUNCATE TABLE {databaseOwner}[{objectQualifier}EventLog]
END ELSE
	TRUNCATE TABLE {databaseOwner}[{objectQualifier}EventLog]
GO

IF {databaseOwner}[{objectQualifier}sys_currentDNNVersion]() >= 70400 BEGIN
	-- Recreate Foreign Key Constraints (using common naming):
	ALTER TABLE {databaseOwner}[{objectQualifier}ExceptionEvents] 
	  WITH CHECK ADD CONSTRAINT [FK_{objectQualifier}ExceptionEvents_EventLog] 
		FOREIGN KEY([LogEventID])
		REFERENCES {databaseOwner}[{objectQualifier}EventLog] ([LogEventID])
	  ON DELETE CASCADE;
	  
	ALTER TABLE {databaseOwner}[{objectQualifier}EventLog] 
	  WITH CHECK ADD CONSTRAINT [FK_{objectQualifier}EventLog_Exceptions] 
		FOREIGN KEY([ExceptionHash])
		REFERENCES {databaseOwner}[{objectQualifier}Exceptions] ([ExceptionHash])
	  ON DELETE NO ACTION;
END
GO

DROP FUNCTION {databaseOwner}[{objectQualifier}sys_currentDNNVersion]
GO