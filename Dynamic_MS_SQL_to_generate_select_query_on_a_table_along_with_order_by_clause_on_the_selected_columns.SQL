SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF EXISTS(SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'[dbo].[usp_generate_select_and_order_by_clause]')
AND TYPE IN (N'P', N'PC'))
BEGIN
DROP PROCEDURE [dbo].[usp_generate_select_and_order_by_clause]
END
GO
/*
########################################################################################################################################
#+# Name: [dbo].[usp_generate_select_and_order_by_clause]
#+# Purpose: Stored Procedure to generate select statement and order by clause. For Development and QA environment usage. Do NOT execute in Production environment without successful Development and QA environment testing.
#+# Sample Usage: USE MASTER; EXEC usp_generate_select_and_order_by_clause 'dbo.spt_monitor'
#+# Author: Shaibal Kanti Shil
#+# Earlier Publication: https://aceitpro.wordpress.com/2014/07/12/dynamic-sql-to-generate-select-query-on-a-table-along-with-order-by-clause-on-the-selected-columns/
########################################################################################################################################
*/
CREATE PROCEDURE [dbo].[usp_generate_select_and_order_by_clause]
@table_to_select VARCHAR(MAX) -- Parameter to hold table name which we want to select & apply order by
AS
BEGIN

BEGIN TRY
DECLARE @index INT = 0
DECLARE @select_statement_with_order_by NVARCHAR(MAX)
DECLARE @comma_separator VARCHAR(1) = ', '

- #columns_to_select: Temp table to store columns of the table.
IF OBJECT_ID('TempDB..#columns_to_select') IS NOT NULL DROP TABLE #columns_to_select

- Get all columns of the table from INFORMATION_SCHEMA.COLUMNS.
SELECT column_name, ROW_NUMBER() OVER(ORDER BY column_name) AS id
INTO #columns_to_select
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA + '.' + TABLE_NAME = @table_to_select

DECLARE @total_columns_to_select INT = (SELECT COUNT(id) FROM #columns_to_select)

- Initialize the the select query
SELECT @select_statement_with_order_by = 'SELECT '

- Loop through all the columns that need to be selected.
WHILE @index <= @total_columns_to_select
BEGIN

IF (@index = @total_columns_to_select)
BEGIN
SET @comma_separator = ''
END

SELECT @select_statement_with_order_by = @select_statement_with_order_by + COLUMN_NAME + ' AS '
+ COLUMN_NAME + @comma_separator
FROM #columns_to_select
WHERE id = @index

SELECT @index = @index + 1
END

SET @select_statement_with_order_by = @select_statement_with_order_by + ' FROM ' + @table_to_select

SET @comma_separator = ', '
SET @index = 0

SELECT @select_statement_with_order_by = @select_statement_with_order_by + ' ORDER BY '

- Loop through all the columns that need to be selected.
WHILE @index <= @total_columns_to_select
BEGIN

IF (@index = @total_columns_to_select)
BEGIN
SET @comma_separator = ''
END

SELECT @select_statement_with_order_by = @select_statement_with_order_by + COLUMN_NAME
+ @comma_separator
FROM #columns_to_select
WHERE id = @index

SELECT @index = @index+1
END

SELECT @select_statement_with_order_by AS select_statement_with_order_by
END TRY
BEGIN CATCH
SELECT 'Error in Procedure ' + ERROR_PROCEDURE() + '; Message: ' + ERROR_MESSAGE()
+ '; DSQL Generated: ' + @select_statement_with_order_by
END CATCH
END
GO

/*
This Stored Procedure has been tested in SQL Server 2008.
Deploy the Stored Procedure in a Development environment Database and execute as shown below:

EXEC usp_generate_select_and_order_by_clause 'schema.your_table'

Sample output of the Stored Procedure:
SELECT connections AS connections,cpu_busy AS cpu_busy,idle AS idle,io_busy AS io_busy,lastrun AS lastrun,pack_errors AS pack_errors,pack_received AS pack_received,pack_sent AS pack_sent,total_errors AS total_errors,total_read AS total_read,total_write AS total_write FROM dbo.spt_monitor ORDER BY connections,cpu_busy,idle,io_busy,lastrun,pack_errors,pack_received,pack_sent,total_errors,total_read,total_write
*/