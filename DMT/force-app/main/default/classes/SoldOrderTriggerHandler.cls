/*
 *  @author Global Desktop
 *  @Description Clase que gestiona la logica para el tratamiento del objeto SoldOrder.
 *
**/
public with sharing class SoldOrderTriggerHandler {

  /*
   *  Instancia del Helper
  **/
  final SoldOrderTriggerHelper soldOrderHelper = new SoldOrderTriggerHelper();

  /*
   * CONSTRUCTOR
   */
  public SoldOrderTriggerHandler() {
    system.debug('SoldOrderTriggerHandler CONSTRUCTOR');
  }

  /*
   *  @author Global Desktop
   *  @description  Funcion que se encarga de ejecutar los methods necesarios para la logica beforeInsert del objeto Sold Order
   *
  **/
  public void logicBeforeInsert(List<Sold_Order__c> triggerNew, Map<Id, Sold_Order__c> triggerOldMap) {
    soldOrderHelper.firstForExec(triggerNew, triggerOldMap);
  }

  /*
   *  @author Global Desktop
   *  @description  Funcion que se encarga de ejecutar los methods necesarios para la logica beforeInsert del objeto Sold Order
   *
  **/
  public void logicBeforeUpdate(Map<Id, Sold_Order__c> triggerNewMap, Map<Id, Sold_Order__c> triggerOldMap) {
    soldOrderHelper.firstForExec(triggerNewMap.values(), triggerOldMap);
  }


  /*
   *  @author Global Desktop
   *  @description  Funcion que se encarga de ejecutar los methods necesarios para la logica afterInsert del objeto Sold Order
   *
  **/
  public void logicAfterInsert(Map<Id, Sold_Order__c> triggerNewMap, Map<Id, Sold_Order__c> triggerOldMap) {
    soldOrderHelper.firstForAfterExec(triggerNewMap.values(), triggerOldMap);
    SoldOrderTriggerHelper.updateOppProdRelated(SoldOrderTriggerHelper.setOppsIds);
  }

  /*
   *  @author Global Desktop
   *  @description  Funcion que se encarga de ejecutar los methods necesarios para la logica afterUpdate del objeto Sold Order
   *
  **/
  public void logicAfterUpdate(Map<Id, Sold_Order__c> triggerNewMap, Map<Id, Sold_Order__c> triggerOldMap) {
    soldOrderHelper.firstForAfterExec(triggerNewMap.values(), triggerOldMap);
    SoldOrderTriggerHelper.updateOppProdRelated(SoldOrderTriggerHelper.setOppsIds);
  }

  /*
   *  @author Global Desktop
   *  @description  Funcion que se encarga de ejecutar los methods necesarios para la logica afterUpdate del objeto Sold Order
   *
  **/
  public void logicAfterDelete(Map<Id, Sold_Order__c> triggerNewMap, Map<Id, Sold_Order__c> triggerOldMap) {
    soldOrderHelper.firstForAfterExec(triggerOldMap.values(), triggerOldMap);
    SoldOrderTriggerHelper.updateOppProdRelated(SoldOrderTriggerHelper.setOppsIds);
  }

}