/**
 * @author       Global Desktop
 * @date         07/04/2020
 * @description  Controller del botón Close Lost de la botonera de la Oportunidad
 */
public with sharing class Close_Lost_Opportunity_Controller {
  /**
  * @author Global Desktop
  * @description Empty Constructor
  */
  private Close_Lost_Opportunity_Controller() {
    System.debug('Constructor empty');
  }

  /**
  * @author Global Desktop
  * @description getPickListValues
  */
  @AuraEnabled
  public static Map<String, String> getPickListValues(String iField) {
    final Map<String, String> mapValueLabel= new Map<String, String>();

    final DescribeSObjectResult iSObjectResult = Schema.getGlobalDescribe().get('Opportunity').getDescribe();
    Map<String, Schema.SObjectField> desribedFields = new Map<String, Schema.SObjectField>();
    desribedFields = iSObjectResult.fields.getMap();

    final Schema.SObjectField field = desribedFields.get(iField);
		final List<Schema.PicklistEntry> listPicklistEntry = field.getDescribe().getPicklistValues();
		for(Schema.PicklistEntry iPicklistEntry : listPicklistEntry) {
			mapValueLabel.put(iPicklistEntry.getValue(), iPicklistEntry.getLabel());
		}

		return mapValueLabel;
  }

  /**
  * @author Global Desktop
  * @description getPickListValues
  */
  @AuraEnabled
  public static OpportunityWrapper gtOpportunity(String iRecordId) {
    final Opportunity iOpportunity = [SELECT Id,
                                        Name,
                                        toLabel(DES_Booking_Geography__c),
                                        CurrencyIsoCode,
                                        pre_oppy_revenue_next_12m_amount__c,
                                        // convertCurrency(pre_oppy_revenue_next_12m_amount__c),
                                        DES_Expected_Revenues__c,
                                        // convertCurrency(DES_Expected_Revenues__c),
                                        opportunity_correct_ind_type__c,
                                        DES_Reasons_Lost__c,
                                        DES_Description_reason_for_lost_deal__c
                                      FROM Opportunity
                                      WHERE Id = :iRecordId];

    final OpportunityWrapper iOppWrapper = new OpportunityWrapper();
    iOppWrapper.name = iOpportunity.Name;
    iOppWrapper.booking = iOpportunity.DES_Booking_Geography__c;
    iOppWrapper.iCurrency = iOpportunity.CurrencyIsoCode;
    final Decimal totalPotRevScale = iOpportunity.pre_oppy_revenue_next_12m_amount__c;
    iOppWrapper.totalPotentialRev = String.valueOf(totalPotRevScale.setScale(2));
    final Decimal totalExpRevScale = iOpportunity.DES_Expected_Revenues__c;
    iOppWrapper.totalExpectedRev = String.valueOf(totalExpRevScale.setScale(2));
    iOppWrapper.confirmOpp = iOpportunity.opportunity_correct_ind_type__c;
    iOppWrapper.iReason = iOpportunity.DES_Reasons_Lost__c;
    iOppWrapper.iDescription = iOpportunity.DES_Description_reason_for_lost_deal__c;

    if(iOpportunity.CurrencyIsoCode == 'EUR'
      || iOpportunity.CurrencyIsoCode == 'USD') {
      iOppWrapper.moreThan10M = iOpportunity.pre_oppy_revenue_next_12m_amount__c > 10000000;
    } else {
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
      if(mapCurrencyType.get('USD') > 1) { //NOSONAR
        iOppWrapper.moreThan10M = ((iOpportunity.pre_oppy_revenue_next_12m_amount__c / mapCurrencyType.get(iOpportunity.CurrencyIsoCode)) * mapCurrencyType.get('USD')) > 10000000;
      } else {
        iOppWrapper.moreThan10M = (iOpportunity.pre_oppy_revenue_next_12m_amount__c / mapCurrencyType.get(iOpportunity.CurrencyIsoCode)) > 10000000;
      }
    }

    return iOppWrapper;
  }

  /**
  * @author Global Desktop
  * @description getPickListValues
  */
  @AuraEnabled
  public static void updateClosedLostOpportunity(String iRecordId, String iReason, String iDescription) {
    try {
      final Opportunity iOpportunity = [SELECT Id,
                                          StageName,
                                          opportunity_correct_ind_type__c,
                                          DES_Reasons_Lost__c,
                                          DES_Description_reason_for_lost_deal__c
                                        FROM Opportunity
                                        WHERE Id = :iRecordId];

      iOpportunity.opportunity_correct_ind_type__c = true;
      iOpportunity.StageName = 'Closed Lost';
      iOpportunity.DES_Reasons_Lost__c = iReason;
      iOpportunity.DES_Description_reason_for_lost_deal__c = iDescription;

      update iOpportunity;
    } catch(Exception e) {
      throw new AuraHandledException('Error message. ' + e); //NOSONAR
    }
  }

  /**
   * Clase Wrapper para construir el formato de cuentas del treeGrid
   */
  public Class OpportunityWrapper {
    /**
    * @author Global Desktop
    * @description id
    */
    @AuraEnabled
    public String id {get; set;} //NOSONAR
    /**
    * @author Global Desktop
    * @description name
    */
    @AuraEnabled
    public String name {get; set;}
    /**
    * @author Global Desktop
    * @description booking
    */
    @AuraEnabled
    public String booking {get; set;}
    /**
    * @author Global Desktop
    * @description currency
    */
    @AuraEnabled
    public String iCurrency {get; set;}
    /**
    * @author Global Desktop
    * @description totalPotentialRevenues
    */
    @AuraEnabled
    public String totalPotentialRev {get; set;}
    /**
    * @author Global Desktop
    * @description totalExpectedRevenues
    */
    @AuraEnabled
    public String totalExpectedRev {get; set;}
    /**
    * @author Global Desktop
    * @description confirmOpp
    */
    @AuraEnabled
    public Boolean confirmOpp {get; set;}
    /**
    * @author Global Desktop
    * @description iReason
    */
    @AuraEnabled
    public String iReason {get; set;}
    /**
    * @author Global Desktop
    * @description iDescription
    */
    @AuraEnabled
    public String iDescription {get; set;}
    /**
    * @author Global Desktop
    * @description moreThan10M
    */
    @AuraEnabled
    public Boolean moreThan10M {get; set;}
  }
}