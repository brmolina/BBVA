/*
 *  @author Global Desktop
 *  @Description Clase que contiene la logica para el tratamiento del objeto SoldOrder.
 *
**/
public with sharing class SoldOrderTriggerHelper {

  /*
   *
   *  Set comun que tiene los Id's de las oportunidades relacionadas
  **/
  public static Set<Id> setOppsIds = new Set<Id>();

  /*
   * CONSTRUCTOR
   */
  public SoldOrderTriggerHelper() {
    system.debug('SoldOrderTriggerHelper CONSTRUCTOR');
   }

  /*
   *  @author Global Desktop
   *  @description  Funcion que contiene el primer for que recorre el trigger.
   *                Usar este primer for cuando se quiere obtener un Set de determinados Id's o para generar Sets o listas que van a contener datos
   *                que sean potencialmente utiles para otros desarrollos o para desarrollos simples que solo van a necesitar recorrer el for 1 vez para
   *                validar o modificar un campo en el before
   *
  **/
  public void firstForExec(List<Sold_Order__c> triggerNew, Map<Id, Sold_Order__c> triggerOldMap) {
    system.debug('::::: firstForExec - triggerOldMap: ' + triggerOldMap);
    system.debug('::::: firstForExec - triggerNew: ' + triggerNew);
    for(Sold_Order__c soldOrder : triggerNew) {
      propagateISOCode(soldOrder, triggerOldMap);
    }
  }

  /*
   *  @author Global Desktop
   *  @description  Funcion que contiene el primer for que recorre el trigger.
   *                Usar este primer for cuando se quiere obtener un Set de determinados Id's o para generar Sets o listas que van a contener datos
   *                que sean potencialmente utiles para otros desarrollos o para desarrollos simples que solo van a necesitar recorrer el for 1 vez para
   *                validar o modificar un campo en el before
   *
  **/
  public void firstForAfterExec(List<Sold_Order__c> triggerNew, Map<Id, Sold_Order__c> triggerOldMap) {
    system.debug('::::: firstForAfterExec - triggerOldMap: ' + triggerOldMap);
    system.debug('::::: firstForAfterExec - triggerNew: ' + triggerNew);
    for(Sold_Order__c soldOrder : triggerNew) {
      fillSetOppsIds(soldOrder.opportunity_id__c);
    }
  }

  /*
   *  @author Global Desktop
   *  @description  Funcion que se encarga de poner en el CurrencyISOCode Estandar el valor del campo custom Currency__c
   *
  **/
  private void propagateISOCode(Sold_Order__c soldOrderNew, Map<Id, Sold_Order__c> triggerOldMap) {//NOSONAR
    system.debug('::::: propagateISOCode - triggerOldMap: ' + triggerOldMap);
    //Si es Update y ha cambiado el campo Currency__c lo propago al campo CurrencyISOCode
    if(triggerOldMap != null && triggerOldMap.get(soldOrderNew.Id) != null) {//NOSONAR //Si es Update
      if(soldOrderNew.Currency__c != triggerOldMap.get(soldOrderNew.Id).Currency__c) {//Si ha cambiado el Currency__c
        soldOrderNew.CurrencyISOCode = soldOrderNew.Currency__c;//Actualizo el CurrencyISOCode
      }
    } else { //Si es insert (ya que no tiene triggerOldMap)
      soldOrderNew.CurrencyISOCode = soldOrderNew.Currency__c;//Actualizo el CurrencyISOCode
    }
  }

  /*
   *  @author Global Desktop
   *  @description  Funcion que se encarga de completar el Set que contiene los Id's de las oportunidades
   *
  **/
  private void fillSetOppsIds(Id oppId) {//NOSONAR
    system.debug('::::: fillSetOppsIds');
    if(!setOppsIds.contains(oppId)) {
      setOppsIds.add(oppId);
    }
  }

  /*
   *  @author Global Desktop
   *  @description  Funcion que se encarga de completar el Set que contiene los Id's de las oportunidades
   *
  **/
  @Future
  public static void updateOppProdRelated(Set<Id> setOppsIds) {//NOSONAR
    system.debug('::::: updateOppProdRelated');
    final List<OpportunityLineItem> listOppLineItemRel = new List<OpportunityLineItem>([SELECT Id FROM OpportunityLineItem where OpportunityId IN :setOppsIds]);
    system.debug('::::: listOppLineItemRel: ' + listOppLineItemRel);
    update listOppLineItemRel;
    system.debug('::::: despues listOppLineItemRel: ' + listOppLineItemRel);
  }

}