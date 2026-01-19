/**
* @author       Accenture
* @date         01/04/2019
* @description  Batch para cerrar las oportunidades vencidas
*
* Version   Date            Author          Summary of changes
* 0.1       2019/09/12      JSS             Se ha rehecho completamente este batch para que se programe su ejecución y 
                                            sustituya el processBuilder de cerrado de oportunidades vencidas.
* 0.2       2019/09/23      JSS             Se modifica para que denormalize en esta clase directamente y no haya que esperar al proceso de denorm semanal.
                                            Se modifica la query para que el batch se lance diariamente.
* ----------------------------------------------------------------------------------
*/
public without sharing class Batch_CloseExpiredOpportunities implements Database.Batchable<sObject>, Database.Stateful {

  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsUpdated = 0;
  private Date closingDate;
  private string oppInsideValue = Label.DES_OP_Inside;
  private String bQuery = 'SELECT Id,DES_Prospect__c,DES_Prospect__r.DES_Group__c,StageName, DES_Reasons_Lost__c, opportunity_correct_ind_type__c, DES_Description_reason_for_lost_deal__c, ' + 
                          'opportunity_expiration_ind_type__c, CloseDate, IsClosed, RecordTypeId ' + 
                          'FROM Opportunity ' + 
                          'WHERE CloseDate <= :closingDate AND IsClosed = false AND disclosure_info_type__c != :oppInsideValue';


  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public Batch_CloseExpiredOpportunities() {
    this.closingDate = Date.today().addDays(-30);
  }

  public Batch_CloseExpiredOpportunities(Integer numDays) {
    this.closingDate = Date.today().addDays(-numDays);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------

  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(bQuery);
  }

  public  void execute(Database.BatchableContext bc,List<Opportunity> scope) {
    recordsUpdated = recordsUpdated + scope.size();
    final dwp_acmh.GBL_DenormalizeOpportunitiesUtils doUtil = new dwp_acmh.GBL_DenormalizeOpportunitiesUtils();
    final set<Id> oppToDenormalize = new Set<Id>();
    for (Opportunity opp : scope){
      if ( opp.StageName == Label.DES_Draft&&opp.DES_Prospect__c!=null&&opp.DES_Prospect__r.DES_Group__c!=null) { //Only Draft_Opp
            oppToDenormalize.add(opp.Id);
      }
      opp.StageName = Label.DES_Closed_Lose;
      opp.DES_Reasons_Lost__c = LABEL.Opportunity_expired;
      opp.opportunity_correct_ind_type__c = true;
      opp.DES_Description_reason_for_lost_deal__c = LABEL.Opportunity_expired;
      opp.opportunity_expiration_ind_type__c = true;
    }
    update scope; //update opp records
   
    // denorm draft opp. In case of DML sql limit error, batchsize must be reduced
	for (Id oppId : oppToDenormalize){
        doUtil.restore(String.valueOf(oppId));
    }  
  }

  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('>>>>>>> SUMMARY: ');
    System.debug('>>>>>>>   Records Updated: ' + recordsUpdated);
    System.debug('>>>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>>>   Status: ' + job.Status);
  }

}