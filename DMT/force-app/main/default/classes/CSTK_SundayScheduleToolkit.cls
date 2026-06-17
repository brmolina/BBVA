/**
* ____________________________________________________________________________
* CSTK_SundayScheduleToolkit
* Schedulable class for running Sunday scheduled jobs.
* ____________________________________________________________________________
* @author      Jose Marti <jose.marti.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2025-11-04
* @modified
* @systemLayer CSTK_SundayScheduleToolkit
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class CSTK_SundayScheduleToolkit implements Schedulable {
    /**
    * @description Schedule class
    */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new cstk.ToolkitNameCorrection_Batch(), 100);
        System.scheduleBatch(new CSTK_Sustainable_Turnover_Alerts_Batch(), 'Toolkit Turnover Alerts ', 60, 100);
        System.scheduleBatch(new cstk.Tri_Alerts_Batch(), 'Toolkit Tri Alerts', 120, 100);
    }
}