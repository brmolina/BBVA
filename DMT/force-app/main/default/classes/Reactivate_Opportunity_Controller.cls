/**
 * @author       Global Desktop
 * @date         13/04/2020
 * @description  Controller del botón Reactivate de la botonera de la Oportunidad
 */
public with sharing class Reactivate_Opportunity_Controller {
  /**
  * @author Global Desktop
  * @description Empty Constructor
  */
  private Reactivate_Opportunity_Controller() {
    System.debug('Constructor empty');
  }

  /**
  * @author Global Desktop
  * @description reactivateOpportunity
  */
  @AuraEnabled
  public static void reactivateOpportunity(String iRecordId, String iCloseDate) {
    try {
      System.debug('::::::::::iCloseDate: ' + iCloseDate);
      System.debug('::::::::::Date.valueOf(iCloseDate): ' + Date.valueOf(iCloseDate));
      final Opportunity iOpportunity = [SELECT Id,
                                          StageName,
                                          CloseDate,
                                          opportunity_correct_ind_type__c,
                                          gf_reactivation_oppy_date__c,
                                          gf_oppy_reactivated_ind_type__c
                                        FROM Opportunity
                                        WHERE Id = :iRecordId];

      iOpportunity.gf_reactivation_oppy_date__c = Date.today();
      iOpportunity.gf_oppy_reactivated_ind_type__c = true;
      iOpportunity.DES_Date_Won_Lost__c = null;
      iOpportunity.StageName = Label.DES_Proposal;
      iOpportunity.CloseDate = Date.valueOf(iCloseDate);
      iOpportunity.opportunity_correct_ind_type__c = false;

      update iOpportunity;
    } catch(Exception e) {
      throw new AuraHandledException('Error message. ' + e); //NOSONAR
    }
  }
}