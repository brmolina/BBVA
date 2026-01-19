/*
 *  @author Global Desktop
 *  @description  Clase que tiene las funciones que dan soporte al componente del formulario de creacion de SoldOrder
 *
 *
**/
@SuppressWarnings('sf:UseSingleton')
public with sharing class SoldOrderFormController {

  /*
   *  @author Global Desktop
   *  @description  Devuelve el currencyISOCode de la oportunidad que recibe por parámetro
   *
   *
   **/
  @AuraEnabled
  public static String obtainOppCurrency(Id oppId) {
    String oppCurrISOCode;//NOSONAR
    try {
      String oppISOCodeAux;//NOSONAR
      oppISOCodeAux = [SELECT CurrencyISOCode FROM Opportunity WHERE Id = :oppId LIMIT 1].CurrencyISOCode;
      final Set<String> setPickValues = Util_PickList.getLabelFromAPI('Sold_Order__c', 'Currency__c').keySet();
      system.debug('::::: setPickValues: ' + setPickValues);
      if(setPickValues.contains(oppISOCodeAux)) {
        oppCurrISOCode = oppISOCodeAux;
      }
      system.debug('::::: oppISOCodeAux: ' + oppISOCodeAux);
    } catch (Exception e) {
      throw new AuraHandledException('EXCEPTION: ' + e);//NOSONAR
    }
    system.debug('::::: oppCurrISOCode: ' + oppCurrISOCode);
    return oppCurrISOCode;
  }

  /*
   *  @author Global Desktop
   *  @description  Devuelve el [%Underwriting oportunidad] del opportunity product de la oportunidad que recibe por parámetro
   *
   *
   **/
  @AuraEnabled
  public static Decimal obtainBBVAParticipationPer(Id oppId) {
    Decimal bbvaParticipationPer;
    bbvaParticipationPer = 0;

    try {
      final List<OpportunityLineItem> uwOLIList = [SELECT bbva_participation_per__c 
                                              FROM OpportunityLineItem 
                                              WHERE bbva_participation_per__c > 0
                                              AND OpportunityId = :oppId];
                                              
      for(OpportunityLineItem oLineItem : uwOLIList) {
        bbvaParticipationPer = oLineItem.bbva_participation_per__c;
      }
    } catch (Exception e) {
      throw new AuraHandledException('EXCEPTION: ' + e);//NOSONAR
    }

    return bbvaParticipationPer;
  }

}