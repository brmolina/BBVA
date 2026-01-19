/**
* ____________________________________________________________________________
* CSTK_ScheduleToolkit
* Schedulable class for update data from Integration User after bulk api
* ____________________________________________________________________________
* @author      Olatz Urrutia <olatz.urrutia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-06-22
* @modified
* @systemLayer CSTK_ScheduleToolkit
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class CSTK_ScheduleToolkit implements Schedulable { //NOSONAR
  /**
  * @description Schedule class
  */
  global void execute(SchedulableContext sc) { //NOSONAR

    Database.executeBatch(new cstk.ScriptEnvironmentalSales(), 20); //NOSONAR
    Database.executeBatch(new cstk.ScriptGhgEmissionBatch()); //NOSONAR
    System.enqueueJob(new CSTK_ScriptQueueable(), 10); //NOSONAR
    System.scheduleBatch(new cstk.CompletenessPct(), 'Toolkit Completenes Calc', 45);
    System.scheduleBatch(new cstk.Controversies_Alerts_Batch(), 'Toolkit controversies alerts', 45, 130);
    //System.scheduleBatch(new cstk.OverallAwarenessQueueable(), 'Overall Awareness Calc', 45, 100); //NOSONAR
  }
}