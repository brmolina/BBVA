/**********************************************************************************
* @author
* @date
* @description  Batch para el cálculo de Revenues en DES_Booking__c
* @Revision
**********************************************************************************/
public without sharing class DES_Booking_Batch implements Database.Batchable<Sobject>, Database.Stateful{

  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  //private Integer relationshipsCreated = 0;
  private String query = 'SELECT Id, DES_Client__c, DES_Type__c, DES_Year__c, DES_Revenues__c, DES_Year_Number__c, DES_Engloba_Load_Helper__c  FROM DES_Booking__c';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_Booking_Batch() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<DES_Booking__c> listBookings) {
    // system.debug('>>>>> BATCH listBookings: ' + listBookings);
    // DES_Booking_Batch_Handler.calcularRevenues(listBookings);
    // system.debug('>>>>> DESPUES calcularReveneus');
    // DES_Booking_Batch_Handler.calculateTopCountries(listBookings);
    DES_BookingTriggerHandler.identifyYearOfBooking(listBookings);
    recordsProcessed += listBookings.size();
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