/*
* @author       Global Desktop
* @date         23/07/2020
* @description  Batch to denorm opps created in the last two last years and opened opps
*/
public without sharing class GBL_DenormalizeOppExecuteLocal implements Database.Batchable<Sobject>, Database.Stateful {
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  /* recordsProcessed */
  private Integer recordsProcessed = 0; //NOSONAR
  /* relationshipsCreated */
  private Integer relationshipsCreated = 0; //NOSONAR
  /* Two years Date */
  private Date twoYears = Date.newInstance(date.today().year()-1, 1, 1); //NOSONAR
  /* Query */
  private String query = 'SELECT Id, AccountId FROM Opportunity WHERE (StageName != \'Draft Opp\') AND ((AccountId != null) OR (DES_Prospect__c != null AND DES_Prospect__r.DES_Group__c != null)) AND (IsClosed = false OR (IsClosed = true AND CreatedDate >= :twoYears))'; //NOSONAR

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    system.debug('twoYears1: ' + twoYears);
    system.debug('Query1: ' + query);
    return Database.getQueryLocator(query);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext bch, List<Opportunity> scope) {
    final dwp_acmh.GBL_DenormalizeOpportunitiesUtils doUtil = new dwp_acmh.GBL_DenormalizeOpportunitiesUtils();

    for (Opportunity opty : scope) {
      relationshipsCreated = relationshipsCreated + doUtil.denormalize(opty);
      recordsProcessed++;
    }
  }

  /*
  * Finsih method
  */
  public void finish(Database.BatchableContext bch) {
    final AsyncApexJob job2 = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
    system.debug('job2: ' + job2);
  }

}