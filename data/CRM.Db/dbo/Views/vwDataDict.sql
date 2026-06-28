



CREATE VIEW [dbo].[vwDataDict]
AS
      SELECT TOP 100 PERCENT
                a.name AS [Table], b.name AS Attribute, 
				{ FN CONCAT(c.name, CASE WHEN c.name = 'numeric' THEN CONCAT('(', b.prec, ',', b.scale, ')') 
                      WHEN c.NAME LIKE '%CHAR' THEN CONCAT('(', CASE WHEN b.length = - 1 THEN 'MAX' ELSE CAST(b.length AS VARCHAR(100)) END, ')') ELSE '' END) } AS DataType, 
				b.isnullable AS [Allow Nulls?], 
				CASE WHEN d.name IS NULL THEN 0	ELSE 1 END AS [PKey?], 
				CASE WHEN e.parent_object_id IS NULL THEN 0 END AS [FKey?], 
				CASE WHEN e.parent_object_id IS NULL THEN '-' ELSE g.name END AS [Ref Table], 
				CASE WHEN h.value IS NULL THEN '-' ELSE h.value END AS Description,
				a.crDate, sm.text AS default_value
      FROM      sys.sysobjects AS a
                INNER JOIN sys.syscolumns AS b ON a.id = b.id
                INNER JOIN sys.systypes AS c ON b.xtype = c.xtype
                LEFT OUTER JOIN (
                                 SELECT so.id, sc.colid, sc.name
                                 FROM   sys.syscolumns AS sc
                                        INNER JOIN sys.sysobjects AS so ON so.id = sc.id
                                        INNER JOIN sys.sysindexkeys AS si ON so.id = si.id
                                                                             AND sc.colid = si.colid
                                 WHERE  (si.indid = 1)) AS d ON a.id = d.id
                                                                AND b.colid = d.colid
                LEFT OUTER JOIN sys.foreign_key_columns AS e ON a.id = e.parent_object_id
                                                                AND b.colid = e.parent_column_id
                LEFT OUTER JOIN sys.objects AS g ON e.referenced_object_id = g.object_id
                LEFT OUTER JOIN sys.extended_properties AS h ON a.id = h.major_id
                                                                AND b.colid = h.minor_id
				LEFT JOIN sys.syscomments sm ON sm.id = b.cdefault
      WHERE     (a.type = 'U')
                AND (c.name <> 'sysname')
                AND (a.name <> 'sysdiagrams')
      ORDER BY  [Table]