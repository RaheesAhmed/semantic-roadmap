CREATE TABLE [util].[mUnitTest] (
    [RowID]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [wNamespace]    VARCHAR (50)   CONSTRAINT [DF_mUnitTest_wNameSpace] DEFAULT ('') NOT NULL,
    [wModule]       VARCHAR (200)  CONSTRAINT [DF_mUnitTest_wModule] DEFAULT ('') NOT NULL,
    [wVersion]      VARCHAR (50)   CONSTRAINT [DF_mUnitTest_wVersion] DEFAULT ('') NOT NULL,
    [wFunctionName] NVARCHAR (100) CONSTRAINT [DF_mUnitTest_wFunctionName] DEFAULT ('') NOT NULL,
    [wInputJson]    NVARCHAR (MAX) CONSTRAINT [DF_mUnitTest_wInputJson] DEFAULT ('') NOT NULL,
    [wResultJson]   NVARCHAR (MAX) CONSTRAINT [DF_mUnitTest_wResultJson] DEFAULT ('') NOT NULL,
    [wMaxSec]       INT            CONSTRAINT [DF_mUnitTest_wMaxSec] DEFAULT ((0)) NOT NULL,
    [wIsCoreCase]   CHAR (1)       CONSTRAINT [DF_mUnitTest_wIsCoreCase] DEFAULT ('N') NULL,
    [wResultCode]   VARCHAR (10)   CONSTRAINT [DF_mUnitTest_wResultCode] DEFAULT ('0') NOT NULL,
    [wStatus]       CHAR (1)       CONSTRAINT [DF_mUnitTest_wStatus] DEFAULT ('A') NOT NULL,
    [wType]         VARCHAR (50)   CONSTRAINT [DF_mUnitTest_wType] DEFAULT ('') NOT NULL,
    [wSeq]          INT            CONSTRAINT [DF_mUnitTest_wSeq] DEFAULT ((0)) NOT NULL,
    [wDesc]         NVARCHAR (200) CONSTRAINT [DF_mUnitTest_wDesc] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_mUnitTest] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

