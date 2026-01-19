/**********************************************************************************
* @author
* @date
* @description  Batch para el cálculo de Revenues de Bookings desde Account
* @Revision
**********************************************************************************/
public without sharing class Batch_Calcular_YOY_Revenues implements Database.Batchable<Sobject>, Database.Stateful {

  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  //private Integer relationshipsCreated = 0;
  private String query = 'SELECT Id, Name, DES_GF_YOY__c, DES_GTB_YOY__c, DES_GM_YOY__c, DES_CF_YOY__c, DES_GTB_Revenues__c, DES_GM_Revenues__c, DES_GF_Revenues__c, DES_CF_Revenues__c, DES_Revenue_Update_Engloba__c, DES_Previous_Revenue_Update_Engloba__c,'
  + ' cust_first_income_country_name__c, cust_first_income_country_amount__c, cust_second_income_country_name__c, cust_second_income_cntry_amount__c, cust_third_income_country_name__c, cust_third_income_country_amount__c FROM Account WHERE DES_Structure_Type__c != null ORDER BY DES_Revenue_Update_Engloba__c DESC'+ (Test.isRunningTest()?' LIMIT 1':'');

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public Batch_Calcular_YOY_Revenues() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    system.debug('>>>>> query : ' + query);
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<Account> listAccount) {
    system.debug('>>>>> Batch_Calcular_YOY_Revenues - listAccount : ' + listAccount);
    // DES_Booking_Batch_Handler.calcRevFromAcc(listAccount);
    DES_Booking_Batch_Handler.alternativeTopCountries(listAccount);
    recordsProcessed += listAccount.size();
  }

  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Records Processed: ' + recordsProcessed);
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
  }
}