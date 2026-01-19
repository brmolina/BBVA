/**********************************************************************************
* @author       Accenture
* @date         
* @description  Clase programable para lanzar el Batch de creación de DES_Batch_createGBMatrix
* @Revision     
**********************************************************************************/
global without sharing class DES_Schedulable_createGBMatrix implements Schedulable {

    global void execute(SchedulableContext scMain) {
        Id batchInstanceId = Database.executeBatch(new DES_Batch_createGBMatrix(), 10);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);    
    }

}