/**
* @name           ClearCIBLOG_BATCH
* @description    
* @author         BBVA. Service team.
* @date           Agosto 2020.
*/
public without sharing class CIB_LogClear_BATCH implements Database.Batchable<sObject> {
  /* Query that determines the scope of the batch */
  String stQuery;
  /* Data type constant Objeto CIB LOG */
  public final static String OBJCASE = 'CIB_Log__c';
  /* Data type constant Scope query */
  public final static String SCOPE = 'CreatedDate < LAST_N_MONTHS:4';
  /**
  * @description    Constructor whith arguments.
  * @param          csName: String. Representing Custom setting name.
  */
  public CIB_LogClear_BATCH() {

      this.stQuery = 'SELECT Id FROM ';
      this.stQuery += OBJCASE;
      this.stQuery += ' WHERE ' + SCOPE;  
  }

  /**
  * @description    Method start. Method that determines the scope.
  * @param          btchCtx: Database.BatchableContext. Batch context.
  * @return         Database.QueryLocator: Scope.
  */
  public Database.QueryLocator start(Database.BatchableContext btchCtx) {
    return Database.getQueryLocator(this.stQuery);
  }

  /**
  * @description    Method execute. This method contains the logic of the batch.
  * @param          btchCtx: Database.BatchableContext. Batch context.
  * @param          scope: List<sObject>. Scope.
  * @return         Void.
  */
  public void execute(Database.BatchableContext btchCtx, List<sObject> scope) {

  System.debug('INI execute CIBLog Clear');

    if(scope.isEmpty()) {
      System.debug('No records of more than 3 months');
    } else {
      System.debug(scope.size()+' CIB_Log records older than 3 months will be delete');
      delete scope; 
    }

  }
  /**
  * @description    Method finish. This method is executed at the end of the batch.
  * @param          btchCtx: Database.BatchableContext. Batch context.
  * @return         Void.
  */
  
  public void finish(Database.BatchableContext btchCtx) {
      System.debug('FIN execute CIBLog Clear'); 
  }
  /**
  * @description    Private job exception.
  */
  public class JobException extends Exception {}

}