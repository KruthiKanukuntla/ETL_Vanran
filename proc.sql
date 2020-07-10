
CREATE PROCEDURE [dbo].[sp_LoadArc_Address_Book] AS

BEGIN
BEGIN TRY
BEGIN TRANSACTION
SET NOCOUNT ON

;WITH D AS (
SELECT Root_Domain
      ,Customer
      ,Action
      ,first_name
      ,last_name
      ,sip_address
      ,businessphone
      ,mobilephone
      ,homephone
      ,email
      ,dw_eff_strt_dttm
	  ,dw_eff_end_dttm
	  ,dw_crte_usrid
	  ,current_flag
	  ,Delete_Flag
	  ,Checksumval
FROM DW_HIST.dbo.Address_Book
WHERE [current_flag] = 'Y' AND [dw_eff_end_dttm] = '9999-12-31 23:59:59'
)

MERGE D USING (SELECT * FROM DW_STG.dbo.Address_Book) AS S 
ON D.first_name = S.first_name AND D.last_name = S.last_name AND D.sip_address = S.sip_address

--Changed Updates

WHEN MATCHED AND D.checksumval <> s.checksumval

THEN UPDATE SET D.dw_eff_end_dttm = S.dw_eff_strt_dttm
				,D.current_flag = 'N';   

--Changed Inserts and new inserts

INSERT INTO DW_HIST.dbo.Address_Book
(
	   Root_Domain
	  ,Customer
	  ,Action
	  ,first_name
	  ,last_name
	  ,sip_address
	  ,businessphone
	  ,mobilephone
	  ,homephone
	  ,email
	  ,dw_eff_strt_dttm
	  ,dw_eff_end_dttm
	  ,dw_crte_usrid
	  ,current_flag
	  ,Delete_Flag
	  ,Checksumval
)

SELECT S.Root_Domain
      ,S.Customer
      ,S.Action
      ,S.first_name
      ,S.last_name
      ,S.sip_address
      ,S.businessphone
      ,S.mobilephone
      ,S.homephone
      ,S.email
      ,S.dw_eff_strt_dttm
	  ,'9999-12-31 23:59:59' dw_eff_end_dttm
	  ,dw_crte_usrid
	  ,'Y' current_flag
	  ,'N' Delete_Flag
	  ,S.Checksumval

FROM DW_STG.dbo.Address_Book S

--Update Delete_Flag if deleted from source

UPDATE hist
SET Delete_Flag = 'Y',dw_eff_end_dttm = DATEADD("Second",-1,DATEDIFF("Day",0,GETDATE())),current_flag = 'N'
FROM DW_HIST.dbo.Address_Book hist
LEFT OUTER JOIN ODS.dbo.Address_Book dump
ON hist.first_name = CAST(CASE WHEN LTRIM(RTRIM(dump.first_name)) = '' THEN 'UNKNOWN'  ELSE LTRIM(RTRIM(dump.first_name)) END AS VARCHAR(10))
AND hist.last_name = CAST(CASE WHEN LTRIM(RTRIM(dump.last_name)) = '' THEN 'UNKNOWN'  ELSE LTRIM(RTRIM(dump.last_name)) END AS VARCHAR(10))
AND hist.sip_address = CAST(CASE WHEN LTRIM(RTRIM(dump.sip_address)) = '' THEN 'UNKNOWN'  ELSE LTRIM(RTRIM(dump.sip_address)) END AS VARCHAR(10))
WHERE dump.first_name IS NULL AND dump.last_name IS NULL AND dump.sip_address IS NULL AND hist.current_flag = 'Y'

COMMIT
END TRY

BEGIN CATCH

IF @@TRANCOUNT>0

			 

			ROLLBACK

			

			Declare @err AS VARCHAR(1500)=ERROR_MESSAGE()

			RAISERROR (50050,11,1,'sp_LoadArc_sg_con_m1',@err);

			END CATCH

			

END