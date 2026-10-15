/*----------------------------------------------------------------
    Description:   This class contains trigger of Case Object
------------------------------------------------------------------*/
trigger SER_Case_TRIGGER on Case (before insert, after insert, before update, after update) {
  if(TriggerBypass.bypassTrigger) return;

  final acpl.CasePlanningHandler caseHandler = acpl.CasePlanningHandler.getInstance();
  CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
  /*Constante para identificar los logs*/
  final static String JCT = 'JCT - BYPASS: ';
  String auxLog;
  auxLog = JCT + byPass;
  System.debug(auxLog);
  
    

  if(!byPass.CIB_skip_trigger__c) {
    SER_CaseTriggerHandler handler;
    handler = SER_CaseTriggerHandler.getInstance();

    if (Trigger.isBefore && Trigger.isInsert) {
      handler.onBeforeInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
      handler.onBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
      handler.onAfterInsert(Trigger.new, Trigger.newMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
      handler.onAfterUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
      //colocar la llamada de GDT OJO!!! pendiente de revisar en la clase del paquete que solo se haga para account planning
      //establecer un método para que no entre si no es necesario, solo para AP
      caseHandler.sendChatterChangeStatus(Trigger.new, Trigger.oldMap);
    }

    handler.resetSkipValidations(Trigger.new);
  }
}