/**********************************************************************************
* @author       Global Desktop
* @date         21/02/2020
* @description  Handler auxiliar del trigger de Opportunity
**********************************************************************************/
public with sharing class OpportunityTriggerHandler2 {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private OpportunityTriggerHandler2() {
    System.debug('Empty constructor');
  }

  /*
 *  Funcion actualiza los el estado de una bandera para que no se salten las validaciones cuando se reabre la oportunidad
 *
 **/
    public static void UpdateReopenOpportunity(List<Opportunity> lstNewOpportunity,List<Opportunity> lstOldOpportunity) {

      List<Opportunity> lstReopenOpp=new List<Opportunity>();

      //carga los ids de los productos que hayan cambiado de estado de cerrado a abierto y luego carga los tramos
      for(Integer i=0;i<lstNewOpportunity.size();i++) {

        if((lstNewOpportunity[i].StageName!=lstOldOpportunity[i].StageName&&(lstOldOpportunity[i].StageName==system.Label.DES_Closed_Won||lstOldOpportunity[i].StageName==system.Label.DES_Closed_Lose))) {
          lstReopenOpp.add(new Opportunity(opportunity_expiration_ind_type__c=false,id=lstNewOpportunity[i].id));
        }
      }

      if(lstReopenOpp.size()>0) {
        update lstReopenOpp;
      }

    }

  /**
  * @author Global Desktop
  * @Description onAfterInsert
  */
  public static void onAfterInsert(List<Opportunity> newList) {
    Opportunity_Helper_Comm_Alert.changeCommAlertStatusInsert(newList);
  }

  /**
  * @author Global Desktop
  * @Description onAfterUpdate
  */
  public static void onAfterUpdate(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
    Opportunity_Helper_Comm_Alert.changeCommAlertStatusUpdate(newMap, oldMap);
  }
}