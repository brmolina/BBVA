/**********************************************************************************
* @author       Accenture
* @date         
* @description  Clase programable para lanzar el Batch de borrado de DES_Batch_deleteGBMatrix
* @Revision     
**********************************************************************************/
global without sharing class DES_Schedulable_deleteGBMatrix implements Schedulable {

    global void execute(SchedulableContext scMain) {
        Id batchInstanceId = Database.executeBatch(new DES_Batch_deleteGBMatrix(), 50000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);    
    }

}