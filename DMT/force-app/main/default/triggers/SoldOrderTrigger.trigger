/*
 *
 *  @author   Global Desktop
 *  @Description  Trigger con la logica necesario para realizar las automatizaciones sobre el objeto 'Sold Order'
 *
 *
 **/
trigger SoldOrderTrigger on Sold_Order__c (before insert, before update, after insert, after update, after delete) {
  /*
   *  Instancia del Handler
  **/
  final SoldOrderTriggerHandler soldOrderHandler = new SoldOrderTriggerHandler();

  if(Trigger.isBefore) {
    if(Trigger.isInsert) {
      soldOrderHandler.logicBeforeInsert(trigger.new, trigger.oldMap);
    } else if(Trigger.isUpdate) {
      soldOrderHandler.logicBeforeUpdate(trigger.newMap, trigger.oldMap);
    }
  }

  if(Trigger.isAfter) {
    if(Trigger.isInsert) {
      soldOrderHandler.logicAfterInsert(trigger.newMap, trigger.oldMap);
    } else if(Trigger.isUpdate) {
      soldOrderHandler.logicAfterUpdate(trigger.newMap, trigger.oldMap);
    } else if(Trigger.isDelete) {
      soldOrderHandler.logicAfterDelete(trigger.newMap, trigger.oldMap);
    }
  }

  system.debug('FIN TRIGGER SOLD ORDER: ' + trigger.new);

}