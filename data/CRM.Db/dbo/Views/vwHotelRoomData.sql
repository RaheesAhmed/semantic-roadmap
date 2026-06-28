

CREATE VIEW [dbo].[vwHotelRoomData]
AS
SELECT h.wName AS Hotel, regL.wTitle AS [Location], brB.wRefNo AS ReservationNo, reqA.wAgentCodeIn, reqA.wAgentCode, reqA.wAgentCode_Old, 
	hr.wName AS RoomType, actionL.wTitle AS [Status], hcB.wDebitDt AS ReservationDt, 
	(CASE hc.wAction
		WHEN 'C'	THEN FORMAT(hc.wNewStartDate, 'yyyy-MM-dd')
		WHEN 'RF'	THEN FORMAT(hc.wOriStartDate, 'yyyy-MM-dd')
		WHEN 'EX'	THEN FORMAT(hc.wOriEndDate, 'yyyy-MM-dd')
		WHEN 'ECI'	THEN FORMAT(hc.wNewStartDate, 'yyyy-MM-dd')
		WHEN 'LC'	THEN FORMAT(hc.wOriStartDate, 'yyyy-MM-dd')
		WHEN 'ECO'	THEN FORMAT(hc.wNewEndDate, 'yyyy-MM-dd')
		ELSE NULL END) AS CheckinDt,
	(CASE hc.wAction
		WHEN 'C'	THEN FORMAT(hc.wNewEndDate, 'yyyy-MM-dd')
		WHEN 'RF'	THEN FORMAT(hc.wOriEndDate, 'yyyy-MM-dd')
		WHEN 'EX'	THEN FORMAT(hc.wNewEndDate, 'yyyy-MM-dd')
		WHEN 'ECI'	THEN FORMAT(hc.wOriStartDate, 'yyyy-MM-dd')
		WHEN 'LC'	THEN FORMAT(hc.wNewStartDate, 'yyyy-MM-dd')
		WHEN 'ECO'	THEN FORMAT(hc.wOriEndDate, 'yyyy-MM-dd')
		ELSE NULL END) AS CheckoutDt,
	payL.wTitle AS Payment,
	hc.wAmountChange AS RoomPrice,
	hc.wCostChange AS RoomCost,
	hc.wCurrCode AS Currency,
	rqUsr.wCName AS Sales
	FROM dbo.eHotelChange AS hc 
		 INNER JOIN dbo.eBookingRoom AS br ON hc.wRoomBookingRid = br.RowID 
		 INNER JOIN dbo.eBooking AS brB ON br.wBookingRid = brB.RowID
		 INNER JOIN dbo.ebooking AS hcB ON hc.wBookingRid = hcB.RowID
		 INNER JOIN dbo.mHotel AS h ON br.wHotelRid = h.RowID 
		 LEFT JOIN dbo.mLookUp AS regL ON h.wRegion = regL.wCode AND regL.wType = 'REGION' AND regL.wLangCd = 'zh-tw'
		 LEFT JOIN RollsMary.dbo.mAgent AS reqA ON	reqA.wAgentCodeIn = hcB.wReqAgentCodeIn
		 LEFT JOIN dbo.mHotelRoom AS hr ON br.wHotelRoomRid = hr.RowID
		 LEFT JOIN dbo.mLookUp AS actionL ON hc.wAction = actionL.wCode AND actionL.wType = 'HOTEL_BOOKING_ACTION' AND actionL.wLangCd = 'zh-tw'
		 LEFT JOIN dbo.mLookUp AS payL ON hc.wPaymentMethod = payL.wCode AND payL.wType = 'PAYMENT_TYPE_HOTEL' AND payL.wLangCd = 'zh-tw'
		 LEFT JOIN [RollsMary].[dbo].[mUsr] rqUsr ON rqUsr.RowID = hcB.wReqUserRid
GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 2, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'vwHotelRoomData';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane2', @value = N'     End
         Begin Table = "hr"
            Begin Extent = 
               Top = 138
               Left = 515
               Bottom = 268
               Right = 685
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "actionL"
            Begin Extent = 
               Top = 138
               Left = 723
               Bottom = 268
               Right = 893
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "payL"
            Begin Extent = 
               Top = 138
               Left = 931
               Bottom = 268
               Right = 1101
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "rqUsr"
            Begin Extent = 
               Top = 138
               Left = 1139
               Bottom = 268
               Right = 1360
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'vwHotelRoomData';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "hc"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 260
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "br"
            Begin Extent = 
               Top = 6
               Left = 298
               Bottom = 136
               Right = 520
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "brB"
            Begin Extent = 
               Top = 6
               Left = 558
               Bottom = 136
               Right = 774
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "hcB"
            Begin Extent = 
               Top = 6
               Left = 812
               Bottom = 136
               Right = 1028
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "h"
            Begin Extent = 
               Top = 6
               Left = 1066
               Bottom = 136
               Right = 1236
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "regL"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "reqA"
            Begin Extent = 
               Top = 138
               Left = 246
               Bottom = 268
               Right = 477
            End
            DisplayFlags = 280
            TopColumn = 0
    ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'vwHotelRoomData';

