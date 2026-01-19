/**********************************************************************************
* @author
* @date
* @description Clase programable para lanzar el Batch de DES_Batch_SaveMatrixInGroup
* @Revision
**********************************************************************************/
public without sharing class DES_Schedulable_ParentField implements Schedulable {
    /*
    * Metod schedulable
    */
	public void execute(SchedulableContext scMain) {
        final Id batchInstanceId = Database.executeBatch(new DES_Batch_SaveMatrixInGroup(), 100);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    }
}