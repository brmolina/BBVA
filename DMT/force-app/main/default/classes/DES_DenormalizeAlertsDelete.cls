public without sharing class DES_DenormalizeAlertsDelete implements Database.Batchable<Sobject>, Database.Stateful {
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsDeleted = 0;
  private String pQuery = 'SELECT Id FROM DES_Denorm_AccountAlert__c'+(Test.isRunningTest()?' LIMIT 1':'');
  private Boolean pCreateRecords = false;

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_DenormalizeAlertsDelete(){
  }

  /*
  * Constructor
  */
  public DES_DenormalizeAlertsDelete(Boolean createRecords) {
    //Delete all relationships. If createRecords=True, launches the Recreation Batchable class
    pCreateRecords = createRecords;
    system.debug('pCreateRecords: ' + pCreateRecords);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc){
    return Database.getQueryLocator(pQuery);
  }

  public  void execute(Database.BatchableContext bc,List<SObject> scope){
    recordsDeleted = recordsDeleted + scope.size();
    delete scope;
    system.debug('recordsDeleted -> ' + recordsDeleted);
  }

  public void finish(Database.BatchableContext bc){
    final Id batchInstanceId = Database.executeBatch(new DES_DenormalizeAlertsExecute(), 2);
    system.debug('batchInstanceId -> ' + batchInstanceId);
  }
}