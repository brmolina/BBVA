/**********************************************************************************
* @author       Accenture
* @date         
* @description  Batch para el borrado de Booking (DES_Booking__c)
* @Revision     
                03/12/2018 Se añade la instrucción después de cada borrado masivo para vaciar la papelera de reciclaje
**********************************************************************************/
public without sharing class DES_Batch_Delete_Booking implements Database.Batchable<Sobject>, Database.Stateful{
  
  /* Private attributes */
  //private Integer recordsProcessed = 0;
  /* Batch Query */
  private String query = 'SELECT Id, DES_Client__c, DES_Type__c, DES_Year__c, DES_Revenues__c  FROM DES_Booking__c';

  /* Constructor */
  public DES_Batch_Delete_Booking() {
    system.debug('>>>>> Query: ' + query);
  }

  /* Batchable methods */
  public Database.QueryLocator start(Database.BatchableContext batchContext) {
    return Database.getQueryLocator(query);
  }
  
  /*
  * @author Global Desktop
  * @description Actualiza los campos de cuenta con el sumatorio de los revenues asociados
  */
  public void execute(Database.BatchableContext batchContext, List<DES_Booking__c> listBookings) {
    /*system.debug('>>>>> BATCH listBookings: ' + listBookings);
    
    set<Id> accountIds = new set<Id>();
    for(DES_Booking__c book : listBookings) {
    	accountIds.add(book.DES_Client__c);		
    }

    final list<Account> accList = [SELECT id,cf_previous_revenue_amount__c,gf_previous_revenue_amount__c,gm_previous_revenue_amount__c,gtb_previous_revenue_amount__c,
    					DES_CF_Revenues__c,DES_GF_Revenues__c,DES_GM_Revenues__c,DES_GTB_Revenues__c
    					FROM Account WHERE Id IN :accountIds];
	for(Account acc : accList) {
		acc.cf_previous_revenue_amount__c = acc.DES_CF_Revenues__c;
		acc.gf_previous_revenue_amount__c = acc.DES_GF_Revenues__c;
		acc.gm_previous_revenue_amount__c =  acc.DES_GM_Revenues__c;
		acc.gtb_previous_revenue_amount__c = acc.DES_GTB_Revenues__c;
	}
	update accList;*/
    
	if(!listBookings.isEmpty()) {
	  delete listBookings;
	  Database.emptyRecycleBin(listBookings);             
    }
    //recordsProcessed += listBookings.size();    
  }

  /*
  * @author Global Desktop
  * @description Finaliza el Batch
  */
  public void finish(Database.BatchableContext batchContext) {
    /*AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchContext.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Records Processed: ' + recordsProcessed);
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);*/
  }
}