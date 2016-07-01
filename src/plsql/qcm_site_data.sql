----------------------------------------------
-- Project: SCSQC
-- Author: Venkat Kaushik 
-- Purpose: QCM Site Mapping Data
-- Created: Thu Jun 09 2016
----------------------------------------------

REM INSERTING into HSSC_ETL.QCM_SITE
SET DEFINE OFF;
Insert into HSSC_ETL.QCM_SITE (RES_SITE,DATASOURCE_ROOT) values ('1004','2.16.840.1.113883.3.2489.2.1.2.1.3.1.2.4');
Insert into HSSC_ETL.QCM_SITE (RES_SITE,DATASOURCE_ROOT) values ('1007','2.16.840.1.113883.3.2489.2.3.4.1.2.4.3');
Insert into HSSC_ETL.QCM_SITE (RES_SITE,DATASOURCE_ROOT) values ('1002','2.16.840.1.113883.3.2489.2.4.4.1.2.4.2');
commit;

