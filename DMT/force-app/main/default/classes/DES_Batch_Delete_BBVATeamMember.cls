/**********************************************************************************
* @author       Accenture
* @date         
* @description  Batch para el borrado de BBVATeamMember (DES_BBVA_Management_team__c)
* @Revision     
                03/12/2018 Se añade la instrucción después de cada borrado masivo para vaciar la papelera de reciclaje
				28/01/2019 Modificado el trigger DES_BBVAManagementTeamTrigger de tal forma que el batch nunca va a ejecutar ese método
**********************************************************************************/
public without sharing class DES_Batch_Delete_BBVATeamMember implements Database.Batchable<Sobject>, Database.Stateful {
  
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  //private Integer relationshipsCreated = 0;
  private String query = 'SELECT Id FROM DES_BBVA_Management_team__c';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_Batch_Delete_BBVATeamMember() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<DES_BBVA_Management_team__c> listBBVATM) {
    system.debug('>>>>> BATCH listBBVATM: ' + listBBVATM);
    if(!listBBVATM.isEmpty()) {
            delete listBBVATM;
            Database.emptyRecycleBin(listBBVATM);
        }
    recordsProcessed+=listBBVATM.size();
    
  }

  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Records Processed: ' + recordsProcessed);
    //System.debug('>>>>>   Relationships Created: ' + relationshipsCreated);
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
  }
}