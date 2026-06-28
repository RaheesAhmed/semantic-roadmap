CREATE TABLE [dbo].[mLookUp] (
    [wType]       VARCHAR (50)   NOT NULL,
    [wCode]       NVARCHAR (50)  NOT NULL,
    [wParentCode] NVARCHAR (50)  CONSTRAINT [DF_mLookUpNew_wParentCode] DEFAULT ('') NOT NULL,
    [wLangCd]     VARCHAR (10)   CONSTRAINT [DF_mLookUpNew_wLangCd] DEFAULT ('zh-tw') NOT NULL,
    [wSeqNo]      SMALLINT       CONSTRAINT [DF_mLookUpNew_wSeqNo] DEFAULT ((1)) NOT NULL,
    [wTitle]      NVARCHAR (50)  CONSTRAINT [DF_mLookUpNew_wTitle] DEFAULT ('') NOT NULL,
    [wDescr]      NVARCHAR (500) CONSTRAINT [DF_mLookUpNew_wDescr] DEFAULT ('') NOT NULL,
    [wStatus]     CHAR (1)       CONSTRAINT [DF_mLookUpNew_wStatus] DEFAULT ('A') NOT NULL,
    [wCanEdit]    CHAR (1)       CONSTRAINT [DF_mLookUpNew_wCanEdit] DEFAULT ('N') NOT NULL,
    [wCanSelect]  CHAR (1)       CONSTRAINT [DF_mLookUpNew_wCanSelect] DEFAULT ('Y') NOT NULL,
    [wCrtBy]      BIGINT         NOT NULL,
    [wCrtDt]      DATETIME2 (7)  NOT NULL,
    [wUpdBy]      BIGINT         NOT NULL,
    [wUpdDt]      DATETIME2 (7)  NOT NULL,
    CONSTRAINT [PK_mLookUpNew] PRIMARY KEY CLUSTERED ([wType] ASC, [wCode] ASC, [wParentCode] ASC, [wLangCd] ASC)
);














GO





GO





GO
CREATE NONCLUSTERED INDEX [PI_mLookUp_02]
    ON [dbo].[mLookUp]([wType] ASC, [wCode] ASC, [wParentCode] ASC, [wLangCd] ASC);


GO
CREATE NONCLUSTERED INDEX [PI_mLookUp_01]
    ON [dbo].[mLookUp]([wType] ASC, [wCode] ASC, [wLangCd] ASC);

