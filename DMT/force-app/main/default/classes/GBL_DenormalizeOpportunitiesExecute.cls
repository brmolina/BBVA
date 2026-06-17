public without sharing class GBL_DenormalizeOpportunitiesExecute implements Database.Batchable<Sobject>, Database.Stateful{
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  private Integer relationshipsCreated = 0;
  private String query = 'SELECT Id, AccountId FROM Opportunity';
  private String whereClause;
  private Integer pastMonths=12;

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public GBL_DenormalizeOpportunitiesExecute() {
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    getMetadataInfo();
    query = query + ' WHERE CreatedDate >= LAST_N_MONTHS:' + pastMonths;

    if (whereClause != null && whereClause != '') {
      query = query + ' AND ' + whereClause;
    }
    system.debug('Query: ' + query);

    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
    GBL_DenormalizeOpportunitiesUtils doUtil = new GBL_DenormalizeOpportunitiesUtils();

    for (Opportunity opty : scope) {
      relationshipsCreated = relationshipsCreated + doUtil.denormalize(opty);
      recordsProcessed++;
    }
  }

  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('SUMMARY: ');
    System.debug('  Batch Scope: ' + pastMonths + ' months');
    System.debug('  Batch Query: ' + query);
    System.debug('  Records Processed: ' + recordsProcessed);
    System.debug('  Relationships Created: ' + relationshipsCreated);
    System.debug('  Batches Created: ' + job.JobItemsProcessed);
    System.debug('  Number of Errors: ' + job.NumberOfErrors);
    System.debug('  Status: ' + job.Status);
  }

  private void getMetadataInfo(){
    List<AMH_GBL_Account_Multi_Hierarchy_denorm__mdt> lmdt = [SELECT Label, NamespacePrefix, DeveloperName, AMH_Delete_Batch_Size__c, AMH_Execute_Batch_Size__c, AMH_Lead_Lookup_Field_To_Account__c, AMH_past_months__c, AMH_Opportunity_Filter__c, AMH_Opportunity_Lookup_Field_To_Lead__c, AMH_Active__c FROM AMH_GBL_Account_Multi_Hierarchy_denorm__mdt WHERE AMH_Active__c=true LIMIT 1];

    if (lmdt.size() > 0) {
      whereClause = lmdt[0].AMH_Opportunity_Filter__c;
      pastMonths = Integer.valueOf(lmdt[0].AMH_past_months__c);
    }
  }
}