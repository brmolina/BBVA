/**
* ____________________________________________________________________________
* CSTK_MonthlyScheduleToolkit
* Schedulable class for running scheduled jobs the first sunday of every month.
* ____________________________________________________________________________
* @author      Markel Landa <markel.landa.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2025-11-04
* @modified
* @systemLayer CSTK_MonthlyScheduleToolkit
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global with sharing class CSTK_MonthlyScheduleToolkit implements Schedulable{
    /**
    * @description Schedule class
    */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new CSTK_ES_Framework_Automation());
    }
}