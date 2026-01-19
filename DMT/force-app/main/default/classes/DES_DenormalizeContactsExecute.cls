/******************************************************************************************************************
Name:           DES_DenormalizeContactsExecute 
Description:    Clase batch para que se invoque puntualmente y se desnormalicen los contactos previos que no se han
               desnormalizado en la tabla estandar de "AccountContactRelation".
                Se lanzara el Batch desde el anonimous con la instrucción:
                  Database.executeBatch (new DES_DenormalizeContactsExecute(),30);

                Si falla por un error de Too many queries, reducir el batchsize, por ejemplo:
                Database.executeBatch (new DES_DenormalizeContactsExecute(),10);   

Test Class:     DES_DenormalizeContacts_Test

Version        Date            Author       Summary of changes
------------------------------------------------------------------------------------------------------------------------
0.1            13/11/2018      Accenture    Class creation    
0.2            11/12/2018      Accenture    Modificación de la query porque daba un error de QueryLimit, como hay que 
                                            realizar una query con un Aggregate y no son soportados en las clases Apex batch:
                                          "Aggregate query does not support queryMore(), use LIMIT to restrict the results to a single batch"
                                           Para solucionarlo, hay que modificar esta clase batch y 
                                           además crear 2 nuevas clases: DES_AggregateResultIterable, DES_AggregateResultIterator
****************************************************************************************************************************/
global with sharing class DES_DenormalizeContactsExecute implements Database.Batchable<AggregateResult>, Database.Stateful {
  //--------------------------------------- PRIVATE ATTRIBUTES ---------------------------------------------------------------
  
  private Integer recordsProcessed = 0;
  private Integer relationshipsCreated = 0;
  
  //se lanza directamente la query en la clase DES_AggregateResultIterator para que no de error al subir la clase en Bitbucket
  //private String query = 'SELECT ContactId,Contact.AccountId aid,Contact.CurrencyIsoCode cic, count(AccountId) cnt FROM AccountContactRelation 
                          //WHERE Contact.RecordType.Name = \'Desktop Contact\' AND Contact.Account.DES_Structure_Type__c = \'Subsidiary\' 
                          //GROUP BY ContactId,Contact.AccountId,Contact.CurrencyIsoCode HAVING count(AccountId)<2 LIMIT 2000';
  
  //Set used to avoid duplicate id's
  final private Set<String> setAccIdHierarchy = new Set<String>(); 

  //--------------------------------------- CONSTRUCTOR METHODS ----------------------------------------------------------------

  /*
  * public DES_DenormalizeContactsExecute() {
  * system.debug('>>>>>>>>>>> METODO CONSTRUCTOR <<<<<<<<<<<<< \r\n Query: ' + query);
  * } 
  */

  //--------------------------------------- BATCHABLE METHODS ------------------------------------------------------------------
  
  /**
  * 
  * @author       JSS
  * @description  The batch job starts
  */  
  global Iterable<AggregateResult> start(Database.BatchableContext batchContext) {    
    system.debug('>>>>>>>>>>> Inicio METODO start <<<<<<<<<<<<<'); 
    return new DES_AggregateResultIterable(); //DES_AggregateResultIterable(query);
  }


 /**
  * 
  * @author       JSS
  * @description  The batch job executes and operates on one batch of records
  */
  global void execute(Database.BatchableContext batchContext, List<sObject> scope) {     
    
    system.debug('>>>>>>>>>>> Inicio METODO execute <<<<<<<<<<<<<');  
      
    List<AccountContactRelation> contactToInsert = new List<AccountContactRelation>();
    for (sObject sObj : scope) {
      Final AggregateResult aggResult = (AggregateResult)sObj;      
      //system.debug('************** : aggResult.get(Contact.AccountId)' + aggResult.get('aid'));
      setAccIdHierarchy.clear();
            Final String accountId = (String)aggResult.get('aid');
            recursiveFxn(accountId, accountId);            
            if (!setAccIdHierarchy.isEmpty()) {                 
                for(String accId:setAccIdHierarchy) {                    
                    Final String cid = (String)aggResult.get('ContactId');
                    Final String cciso = (String)aggResult.get('cic');
                    AccountContactRelation accountContactRelation = new AccountContactRelation(AccountId=accId, ContactId=cid, CurrencyIsoCode=cciso);
                    contactToInsert.add(accountContactRelation);
                 }
            }
    } 
    
    if (!contactToInsert.isEmpty()) {
      insert contactToInsert;
      relationshipsCreated += scope.size();
      system.debug('>>>>>>>>>>> inserted AccountContactRelation: ' + contactToInsert); 
    }       
    
     recordsProcessed += scope.size();
  }


 /**
  * 
  * @author       JSS
  * @description  The batch job finishes
  */
  global void finish(Database.BatchableContext batchContext) {
    
    system.debug('>>>>>>>>>>> Inicio METODO finish <<<<<<<<<<<<<' + contact.Name);   
      
    Final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchContext.getJobId()];

    System.debug('>>>>>>>>>>> SUMMARY: ');
    System.debug('>>>>>>>>>>>   Records Processed: ' + recordsProcessed);
    System.debug('>>>>>>>>>>>   Relationships Created: ' + relationshipsCreated);
    System.debug('>>>>>>>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>>>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>>>>>>>   Status: ' + job.Status);
  }
  
    
  //--------------------------------------- PRIVATE METHODS ----------------------------------------------------------------------------
   
  //Recursive function to add the AccTeamMembers of the Account hierarchy for a given opportunity
  //starting from Opportunity.AccountId
  private void recursiveFxn(string accId, string accInicial) {
        
        if (accId != null && accId != accInicial) {
          setAccIdHierarchy.add(accId);
        }
        
        //Retrieve the parents for the account passed
        Final List<dwp_acmh__GBL_Account_Relationship__c> listAccRel = [SELECT Id, dwp_acmh__Parent_Account__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Child_Account__c = :accId];
        system.debug('listAccRel:' + listAccRel);
        
        //iterate to recursively add the opportunity to each parent in the hierarchy
        for (dwp_acmh__GBL_Account_Relationship__c accRel : listAccRel) {
        recursiveFxn(accRel.dwp_acmh__Parent_Account__c, accInicial);
        }
  }  
  
}