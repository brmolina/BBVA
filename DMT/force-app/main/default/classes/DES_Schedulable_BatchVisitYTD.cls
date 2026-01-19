/**********************************************************************************
* @author
* @date
* @description Clase programable para lanzar el Batch de creación de Batch_Total_Visit_YTD
* @Revision
**********************************************************************************/
public without sharing class DES_Schedulable_BatchVisitYTD implements Schedulable {
    /*
    * Metod schedulable
    */
	public void execute(SchedulableContext scMain) {
        final Id batchInstanceId = Database.executeBatch(new Batch_Total_Visit_YTD(), 100);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    }
}