/*
 actualiza el parent de los grupos
*/
global class Batch_UpdateParentAccount implements Database.Batchable<sObject>, Database.Stateful {//NOSONAR
  /*
  * private attribute query
  */
  private String query = ''; //NOSONAR

  /*
  * global map
  */
  final Map<Id, Account> mapGroups = new Map<Id, Account>();
  /*
  * Constructor
  */
  public Batch_UpdateParentAccount() {
    System.debug('>>>>> Query: ' + query);
  }

  /*
  * Start method
  */
  global Database.QueryLocator start(Database.BatchableContext batchBC) {
    this.query = 'Select Id, DES_Main_Parent__c,SER_CClient__c, DES_Subsidiary_Group_Code__c from Account where DES_Entity_Hierarchy__c = \'S\' and DES_Main_Parent__c<>null';
    return Database.getQueryLocator(query);
  }

  /*
  * Execute method
  */
  global void execute(Database.BatchableContext batchBC, List<Account> accList) {
    system.debug('entro===='+accList);
    final List<Account> lstGroups = new List<Account>();
    final Set<Id> idsTransaction = new Set<Id>();
    // process each batch of records default size is 200
    for(Account acc : accList) {
      if(mapGroups.containsKey(acc.DES_Main_Parent__c)) {
        if(acc.DES_Subsidiary_Group_Code__c != null) {
          idsTransaction.add(acc.DES_Main_Parent__c);
          mapGroups.put(acc.DES_Main_Parent__c, acc);
        }
      } else {
        idsTransaction.add(acc.DES_Main_Parent__c);
        mapGroups.put(acc.DES_Main_Parent__c, acc);
      }
    }

    for(Id mainParentId : idsTransaction) {
        final Account objGrupo =new Account(Id = mainParentId, DES_Client_Matrix__c = mapGroups.get(mainParentId).Id);
        lstGroups.add(objGrupo);
    }

    system.debug('lstGroups===='+lstGroups);
    final Database.SaveResult[] srList = Database.update(lstGroups, false);
    for(Database.SaveResult sr : srList) {
      for(Database.Error err : sr.getErrors()) {
        System.debug('BatchUpdateParentAccount error: ' +err.getMessage()+'fields'+ err.getFields());
      }
    }
  }

  /*
  * Finish method
  */
  global void finish(Database.BatchableContext batchBC) {
    // execute any post-processing operations like sending email
  }
}