/**
* @author       Global Desktop
* @date         02/03/2020
* @description  Batch para actualizar los campos de cliente relacionados con Revenues
*
* Version   Date            Author          Summary of changes
*
* ----------------------------------------------------------------------------------
*/
public without sharing class DES_Batch_ResetAccFields implements Database.Batchable<Sobject>, Database.Stateful{
	
    /*Variables globales*/
    private String query = 'SELECT Id, cf_previous_revenue_amount__c, gf_previous_revenue_amount__c, gm_previous_revenue_amount__c, ' +
                            + 'gtb_previous_revenue_amount__c, gf_ibf_previous_revenue_amount__c, cf_revenue_cyr_amount__c, gf_revenue_cyr_amount__c, ' +
                            + 'gm_revenue_cyr_amount__c, gtb_revenue_cyr_amount__c, gf_ibf_cyr_revenue_amount__c ' +
                            + 'FROM Account WHERE cf_revenue_cyr_amount__c != null AND gf_revenue_cyr_amount__c != null ' +
                            + 'AND gm_revenue_cyr_amount__c != null AND gtb_revenue_cyr_amount__c != null AND gf_ibf_cyr_revenue_amount__c != null LIMIT 1';

	/*Constructor method*/
	public DES_Batch_ResetAccFields() {
    	system.debug('>>>>> Query: ' + query);
  	}

	/*Start method*/
  	public Database.QueryLocator start(Database.BatchableContext bContext) {
    	return Database.getQueryLocator(query);
  	}

	/*Execute method*/
  	public void execute(Database.BatchableContext bContext, List<Account> accList) {
  		system.debug('>>>>> execute');
  		/*final List<Account> accUpdate = new List<Account>();
  		for(Account acc : accList) {
				acc.cf_previous_revenue_amount__c = acc.cf_revenue_cyr_amount__c;
				acc.gf_previous_revenue_amount__c = acc.gf_revenue_cyr_amount__c;
				acc.gm_previous_revenue_amount__c =  acc.gm_revenue_cyr_amount__c;
				acc.gtb_previous_revenue_amount__c = acc.gtb_revenue_cyr_amount__c;
				acc.gf_ibf_previous_revenue_amount__c = acc.gf_ibf_cyr_revenue_amount__c;

				acc.cf_revenue_cyr_amount__c = 0;
				acc.gf_revenue_cyr_amount__c = 0;
				acc.gm_revenue_cyr_amount__c = 0;
				acc.gtb_revenue_cyr_amount__c = 0;
				acc.gf_ibf_cyr_revenue_amount__c = 0;
  		}
  		accUpdate.addAll(accList);
  		update accUpdate;*/
	    
  	}

	/*Finish method*/
  	public void finish(Database.BatchableContext bContext) {
  		system.debug('>>>>> finish');
  		/*final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bContext.getJobId()];
	    System.debug('>>>>> SUMMARY: ');
	    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
	    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
	    System.debug('>>>>>   Status: ' + job.Status);*/
  	}

}