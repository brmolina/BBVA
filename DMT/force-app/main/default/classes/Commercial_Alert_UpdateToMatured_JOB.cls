/**
* Author: BBVA
* Description:  Clase que implemente la interface Schedulable para poder programar el 
*               batch Commercial_Alert_UpdateToMatured_BATCH.
* History:
*   <Date>       <Author>          <Description>
* 22/01/2021   Javier Touchard   V 1.0 Initial version
*/
global without sharing class Commercial_Alert_UpdateToMatured_JOB implements Schedulable {
  /**
  * Method execute
  */
  global void execute(SchedulableContext scctx) {
    Commercial_Alert_UpdateToMatured_BATCH comAlerBactch;
    comAlerBactch = new Commercial_Alert_UpdateToMatured_BATCH();
    Database.executebatch(comAlerBactch);
  }

  /**
  * Method execute
  */
  global void execute(SchedulableContext scctx, String query) {
    Commercial_Alert_UpdateToMatured_BATCH comAlerBactch;
    comAlerBactch = new Commercial_Alert_UpdateToMatured_BATCH(query);
    Database.executebatch(comAlerBactch);
  }
}