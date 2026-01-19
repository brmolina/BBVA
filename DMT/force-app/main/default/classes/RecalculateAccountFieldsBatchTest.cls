/**********************************************************************************
 * @author       Global Desktop
 * @date         15/03/2019
 * @description  Test de la case RecalculateAccountFieldsBatch
 * @Revision

 Version        Date            Author            Summary of changes
 -------------------------------------------------------------------------------------
 0.1            15/03/2019      Global Desktop    Testeo de la clase RecalculateAccountFieldsBatch
 **********************************************************************************/
@isTest
public with sharing class RecalculateAccountFieldsBatchTest {
  /**
   * @author Global Desktop
   * @description Test de la clase RecalculateAccountFieldsBatch
   */
  @testSetup
  private static void setupTest() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final Id accountGroupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();

    //Creacion grupo
    final Account accGroup = utilTestClass.createClient();
    accGroup.RecordTypeId = accountGroupRT;
    accGroup.DES_Structure_Type__c = 'Group';
    accGroup.DES_BBVA_Segmentation__c = 'C';
    insert accGroup;

    final //Creacion producto
    Product2 prod1 = utilTestClass.createProduct(Label.DES_Mergers_Acquisitions);
    insert prod1;

    //Creacion pricebookEntry
    final PricebookEntry pbEntryTest1 = utilTestClass.createPricebookEntry(prod1);
    insert pbEntryTest1;

    Test.startTest();
    //Creacion oportunidad
    Date myDate = Date.Today();
    myDate = myDate.addMonths(-1);
    //myDate = myDate.addDays(4);
    System.debug('myDate::' + myDate);
    final Opportunity opp = utilTestClass.createOpportunity(accGroup);
    opp.DES_Booking_Geography__c = 'BE';
    opp.DES_Countries__c = 'BE';
    opp.CurrencyIsoCode = 'EUR';
    opp.DES_Date_Won_Lost__c = myDate;
    // opp.StageName = 'CloseWon';
    insert opp;

    //Creacion opportunity product
    final OpportunityLineItem oppLineItem = utilTestClass.createOppLineItem(opp, prod1, pbEntryTest1);
    insert oppLineItem;
    Test.stopTest();
  }

  @isTest
  public static void batchRecalculateAccountFields() {
    Opportunity opp = [SELECT Id, StageName, opportunity_correct_ind_type__c
                       FROM Opportunity
                       LIMIT 1];
    OpportunityLineItem oppLineItem = [SELECT Id, solution_name_path_desc__c, pre_oppy_revenue_next_12m_amount__c, oppy_target_industry_name__c, oppy_target_country_name__c
                                       FROM OpportunityLineItem
                                       LIMIT 1];
    Test.startTest(); //Actualizacion oportunidad
    opp.StageName = Label.DES_Proposal;
    update opp;
    opp.StageName = Label.DES_Ready_to_close;
    update opp;
    oppLineItem.solution_name_path_desc__c = 'Buyside';
    oppLineItem.pre_oppy_revenue_next_12m_amount__c = 2000;
    oppLineItem.oppy_target_industry_name__c = 'Construction & Infra';
    oppLineItem.oppy_target_country_name__c = 'AR';
    update oppLineItem;
    Test.stopTest();
    opp.StageName = Label.DES_Closed_Won;
    opp.opportunity_correct_ind_type__c = true;
    update opp;

    final Id batchInstanceId = Database.executeBatch(new RecalculateAccountFieldsBatch(), 100);
    Boolean response;
    response = batchInstanceId == null ? false : true;
    System.assert(response, 'Answer right');
  }

}