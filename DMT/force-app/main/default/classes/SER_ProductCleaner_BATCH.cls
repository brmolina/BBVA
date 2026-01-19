/**
* Author: BBVA
* Description:	Batch de borrado de sstt products que esten en estado 'CANCELADO'
*   o 'BAJA', que lleven en este estado mas de 3 meses y que no tengan ningun caso
*   asociado.
* History:
* <Date>			<Author>					<Description>
* 15/11/201/8	    BBVA		                V 1.0 Initial version
*/
global without sharing class SER_ProductCleaner_BATCH implements Database.Batchable<sObject> {

  /*Query que va a determinar el scope de el Batch*/
  final String query;

  /**
  * Constructor 1.
  * @Params String query: scope.
  */
  global SER_ProductCleaner_BATCH(String query) {
    this.query = query;
  }

  /**
  * Constructor 2.
  */
  global SER_ProductCleaner_BATCH() {
    this.query = Label.SER_ProductCleaner_QUERY;
  }

  /**
  * Method que determina el scope del job.
  * @Params Database.BatchableContext bcctx: contexto.
  * @Return Database.QueryLocator: Scope.
  */
  global Database.QueryLocator start(Database.BatchableContext bcctx) {
    return Database.getQueryLocator(this.query);
  }

  /**
  * Method principal donde se encuentra toda la logica del Batch.
  * @Params: Database.BatchableContext bcctx: contexto.
  * @Params: List<sObject> scope: Registros que van a ser tratados.
  * @Return: Void
  */
  global void execute(Database.BatchableContext bcctx, List<sObject> scope) {
    /*Mensaje que se va a insertar en el CIB_Log__c*/
    String logMSG = 'PRODUCTOS BORRADOS: ';
    /*Log que se inserta para realizar un seguimiento de el Batch*/
    CIB_Log__c logToInsert;
    logToInsert = new CIB_Log__c();
    /*Contador de los productos borradas*/
    Integer contador = 0;
    /*Set ids scope*/
    Set<Id> productIdSet;
    productIdSet = new Set<Id>();
    /*List productos a borrar*/
    List<SER_Transactional__c> productsToDelete;
    productsToDelete = new List<SER_Transactional__c>();

    for(Object obj : scope) {
      SER_Transactional__c producto = new SER_Transactional__c();
      producto = (SER_Transactional__c) obj;
      productIdSet.add(producto.Id);
    }
    for(SER_Transactional__c stt : [select Id,SER_Product_Status__c,Name,SER_Product_Cancellation_Date_FORMULA__c,
                                    (select Id from Cases__r) from SER_Transactional__c where Id in :productIdSet]) {
      if(stt.Cases__r.isEmpty()) {
        productsToDelete.add(stt);
        logMSG += ' [PRODUCTO ' + stt.Name + ', ' + stt.SER_Product_Status__c + ', '
                  + stt.SER_Product_Cancellation_Date_FORMULA__c
                  + ', CASOS ASOCIADOS: ' + !stt.Cases__r.isEmpty() + '] ';
        contador += 1;
      }
    }

    if(!productsToDelete.isEmpty()) {
      delete productsToDelete;
    }

    logToInsert.CIB_Subject__c = 'PRODUCT CLEANER, PRODUCTOS BORRADOS: ' + contador;
    logToInsert.CIB_ErrorMessage__c = logMSG;
    insert logToInsert;
  }

  /**
  * Method que se ejecuta al finalizar el Batch.
  * @Params: Database.BatchableContext bcctx: contexto.
  * @Return: Void
  */
  global void finish(Database.BatchableContext bcctx) {

    final AsyncApexJob job = [SELECT NumberOfErrors,ExtendedStatus
                              FROM AsyncApexJob WHERE Id =: bcctx.getJobId()];

    if(job.NumberOfErrors > 0) {
      //Mandamos un mensaje a ans ans_clientcloud@bbva.com
      Messaging.SingleEmailMessage mail;
      mail = new Messaging.SingleEmailMessage();
      final String[] toAddresses = new String[] {SER_Constant.ANS_EMAIL};
      mail.setToAddresses(toAddresses);
      mail.setSubject('ERROR PRODUCT CLEANER');
      mail.setPlainTextBody('Número de errores al intentar borrar los productos: '
                            + job.NumberOfErrors +
                            +'\n' + 'Para más información mirar el CIB_Log__c.');
      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

      //Insertamos un CIB_Log con la excepcion
      CIB_Log__c logToInsert;
      logToInsert = new CIB_Log__c();
      logToInsert.CIB_Subject__c = 'PRODUCT CLEANER, SE HA PRODUCIO UN ERROR';
      logToInsert.CIB_ErrorMessage__c = JOB.ExtendedStatus;
      insert logToInsert;
    }
  }
}