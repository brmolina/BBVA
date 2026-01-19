/**
* @author       Victor Velandia
* Project:      BBVA
* Description:  Schedulable encargado de llamar DevOps_SendUserReport_bch
*
* -----------------------------------------------------------------------------
*             No.     Date            Author                  Description
*             -----   ----------      --------------------    -----------------
* @version    1.0     2020-04-13      Victor Velandia (VV)    Clase Initial
******************************************************************************/
global with sharing class DevOps_SendUserReport_sch implements Schedulable {
  global void execute(SchedulableContext sc) {
    DevOps_SendUserReport_cls objScheduler = new DevOps_SendUserReport_cls();
    objScheduler.loginHistoryByUser();
  }
}