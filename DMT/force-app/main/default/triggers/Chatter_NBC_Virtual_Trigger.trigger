/**********************************************************************************
* @author       VASS
* @date         20/11/2019
* @description  Trigger para objeto Chatter_NBC_Virtual__c
* @Revision
                2019/11/20 Se crea el trigger para el objeto Chatter_NBC_Virtual__c. Se agrega lógica de compartición manual.
**********************************************************************************/
trigger Chatter_NBC_Virtual_Trigger on Chatter_NBC_Virtual__c (after insert) {

    /*
     * Chatter_NBC_Virtual_TriggerHandler Class
     */
    final Chatter_NBC_Virtual_TriggerHandler classController = Chatter_NBC_Virtual_TriggerHandler.getInstance();

    if(Trigger.isAfter) {
      if(Trigger.isInsert) {
        Chatter_NBC_Virtual_TriggerHandler.logicAfterInsert(trigger.newMap);
      }
    }

}