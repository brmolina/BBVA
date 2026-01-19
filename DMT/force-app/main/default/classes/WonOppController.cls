/**********************************************************************************
* @author       Global Desktop
* @date         06/04/2020
* @description  Controller of WonOpportunity
**********************************************************************************/
public with sharing class WonOppController {

  /**
  * Private constructor
  **/
  private WonOppController() {

  }

  /**
  * @author Global Desktop
  * @description Method to get Opportunity
  **/
  @auraEnabled
  public static Opportunity gtData(String recordId) {
    try {
      final List<Opportunity> opps = new List<Opportunity>([
        SELECT Id, Name, StageName, pre_oppy_revenue_next_12m_amount__c, toLabel(DES_Booking_Geography__c), DES_Expected_Revenues__c, opportunity_correct_ind_type__c, CurrencyIsoCode
        FROM Opportunity
        WHERE Id = :recordId
        LIMIT 1
      ]);
      return opps.get(0);
    } catch(Exception err) {
      throw new AuraHandledException(Label.DES_Error + err);
    }
  }

  /**
  * @author Global Desktop
  * @description Method to get CurrencyType
  **/
  @auraEnabled
  public static Map<String, Decimal> gtCurrencyData() {
    try {
      final Map<String, Decimal> mapCurrencyType = new Map<String, Decimal>();
      for(CurrencyType iCurrencyType : [SELECT Id,
                                          IsoCode,
                                          ConversionRate,
                                          DecimalPlaces,
                                          IsActive,
                                          IsCorporate
                                        FROM CurrencyType LIMIT 5000]) {
        mapCurrencyType.put(iCurrencyType.IsoCode, iCurrencyType.ConversionRate);
      }
      return mapCurrencyType;
    } catch(Exception err) {
      throw new AuraHandledException(Label.DES_Error + err);
    }
  }

  /**
  * @author Global Desktop
  * @description Method to won the opp
  **/
  @auraEnabled
  public static void saveOpportunity(String recordId) {
    try {
      final List<Opportunity> opps = new List<Opportunity>([
        SELECT Id, StageName, opportunity_correct_ind_type__c, CurrencyIsoCode
        FROM Opportunity
        WHERE Id = :recordId
        LIMIT 1
      ]);
      system.debug('**opps -> ' + JSON.serialize(opps));
      opps.get(0).StageName = Label.DES_Closed_Won;
      opps.get(0).opportunity_correct_ind_type__c = true;
      update opps.get(0);
    } catch(Exception err) {
      throw new AuraHandledException(Label.DES_Error + err);
    }
  }

}