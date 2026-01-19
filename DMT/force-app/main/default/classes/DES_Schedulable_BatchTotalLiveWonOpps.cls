/**********************************************************************************
* @author
* @date
* @description Clase programable para lanzar el Batch de creación de Batch_Total_Live_Won_Opps
* @Revision
**********************************************************************************/
public without sharing class DES_Schedulable_BatchTotalLiveWonOpps implements Schedulable {
    /*
    * Metod schedulable
    */
	public void execute(SchedulableContext scMain) {
        final Id batchInstanceId = Database.executeBatch(new Batch_UpdateSubsidiary_Total_Won_opps(), 200);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    }
}