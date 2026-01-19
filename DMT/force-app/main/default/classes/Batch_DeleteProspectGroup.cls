/*
 * @author Global Desktop
 * @Description: batch para borrar grupos prospect
 */
public with sharing class Batch_DeleteProspectGroup implements Database.Batchable<Sobject>, Database.Stateful {
  /*
  * private attribute query
  */
  private String query = 'select id, old_participant_id__c from Account where old_participant_id__c != null'; //NOSONAR

  /*
  * Constructor
  */
  public Batch_DeleteProspectGroup() {
	system.debug('Constructor Batch_DeleteProspectGroup');
  }

  /*
	* @author Global Desktop
	* @Description: batchable method
	*/
	public Database.QueryLocator start(Database.BatchableContext bch) {
		return Database.getQueryLocator(query);
	}

	/*
	* @author Global Desktop
	* @Description: batch para borrar grupos prospect
	*/
	public void execute(Database.BatchableContext bch, List<Account> clientsConverted) {
    final List<Account> lUpdate = new List<Account>();

    final Set<String> oldGroup = new Set<String>();
    for (Account acc : clientsConverted) {
      oldGroup.add(acc.old_participant_id__c);
    }

    final List <Account> prospSubsidiary = new List <Account>([
      SELECT Id, DES_ID_Fiscal__c, participant_id__c FROM Account WHERE participant_id__c IN :oldGroup AND RecordType.DeveloperName = 'Prospect_Subsidiary']);

    for(Account acc : prospSubsidiary) {
      oldGroup.remove(acc.participant_id__c);
    }

    final List <Account> lDelete = new List <Account>([SELECT Id, DES_ID_Fiscal__c, participant_id__c FROM Account WHERE id IN :oldGroup AND RecordType.DeveloperName = 'Prospect_Group']);

    for(Account acc : clientsConverted) {
      if(oldGroup.contains(acc.old_participant_id__c)) {
        acc.old_participant_id__c = null; //NOSONAR
        lUpdate.add(acc);
      }
    }

    if(!lDelete.isEmpty()) {
      delete lDelete;
    }
    if(!lUpdate.isEmpty()) {
      update lUpdate;
    }
  }

	/*
	* @author Global Desktop
	* @Description: finish batch method
	*/
	public void finish(Database.BatchableContext bch) {
		final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];

		System.debug('>>>>> SUMMARY: ');
		System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
		System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
		System.debug('>>>>>   Status: ' + job.Status);
	}
}