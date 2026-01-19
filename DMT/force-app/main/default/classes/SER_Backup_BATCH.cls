/**
* Author: BBVA
* Description:   Batch que rellena el campo Backup de los objetos con su propìo Id.
*
* History:
*  <Date>           <Author>               <Description>
* 12/09/2019	        BBVA		           V 1.0 Initial version
*/
global without sharing class SER_Backup_BATCH  implements Database.Batchable<sObject> {
  /*Query que va a determinar el scope de el Batch*/
  final String query;
  /*Nombre del campo a actualizar*/
  final String field;

  /**
  * Constructor sin argumentos.
  */
  global SER_Backup_BATCH() {
    this.query = 'SELECT Id FROM Case where RecordType.DeveloperName LIKE \'SER_%\'';
    this.field = 'BKP_CASE_Backup_External_Id__c';
  }

  /**
  * Constructor con argumentos.
  * @Params String query. scope.
  * @Params String field. Campo a actualizar.
  */
  global SER_Backup_BATCH(String query, String field) {
    this.query = query;
    this.field = field;
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
    List<sObject> objectsList;
    objectsList = new List<sObject>();
    for(sObject o : scope) {
      o.put(field,o.Id);
      objectsList.add(o);
    }
    if(!objectsList.isEmpty()) {
      update objectsList;
    }
  }

  /**
  * Method que se ejecuta al finalizar el Batch.
  * @Params: Database.BatchableContext bcctx: contexto.
  * @Return: Void
  */
  global void finish(Database.BatchableContext bcctx) {
    System.debug('--->>> SER_Backup_BATCH has finished');
  }
}