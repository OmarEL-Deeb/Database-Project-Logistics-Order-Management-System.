/* =========================================
   STEP 1: Create Full Backup
   ========================================= */

BACKUP DATABASE LogisticsDB
TO DISK = 'C:\SQLBackups\LogisticsDB_Full.bak'
WITH 
    FORMAT,                     
    INIT,                       
    NAME = 'Full Backup of LogisticsDB',
    SKIP,
    STATS = 10;                 
GO

/* =========================================
   STEP 2: Check Logical File Names
   ========================================= */

RESTORE FILELISTONLY
FROM DISK = 'C:\SQLBackups\LogisticsDB_Full.bak';
GO

/* =========================================
   STEP 3: Drop Test Database if Exists
   ========================================= */

IF DB_ID('LogisticsDB_Test') IS NOT NULL
BEGIN
    ALTER DATABASE LogisticsDB_Test 
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE LogisticsDB_Test;
END
GO

/* =========================================
   STEP 4: Restore Database
   ========================================= */

RESTORE DATABASE LogisticsDB_Test
FROM DISK = 'C:\SQLBackups\LogisticsDB_Full.bak'
WITH 
    MOVE 'LogisticsDB' 
        TO 'C:\SQLData\LogisticsDB_Test.mdf',

    MOVE 'LogisticsDB_log' 
        TO 'C:\SQLData\LogisticsDB_Test_log.ldf',

    RECOVERY,
    REPLACE,
    STATS = 10;
GO
----
/* =========================================
   STEP 5: Verify Data Integrity
   ========================================= */

DBCC CHECKDB ('LogisticsDB_Test');
GO