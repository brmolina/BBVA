/**
* @author       Operaciones (SBT)
* @date         15/03/2021
* @description  Batch para mejora del rendimiento en la carga de preguntas de AP
* @Revision
*/
public class DES_AP_Batch_DeleteFieldConfigs implements
    Database.Batchable<sObject>, Database.Stateful {
    // instance member to retain state across transactions
    /**
    * Datos borrados
    * @author Global hub
    */
    private  Integer recordsProcessed = 0;
    /**
    * Ids a borrar
    * @author Global hub
    */
    final  List<Id> idCatalogs = new List<Id>();
    /**
    * Funcioon que recupera los datos de dyfr__Field_Config__c aborrar
    * @author Global hub
    */
    public Database.QueryLocator start(Database.BatchableContext bachContex) {
		for (acpl__Account_Planning__c accPlan : [SELECT Id FROM acpl__Account_Planning__c Where RecordType.DeveloperName = 'Question_Catalog']) {
    	idCatalogs.add(accPlan.id);
		}
        return Database.getQueryLocator(
            'SELECT Id, dyfr__DeveloperName__c FROM dyfr__Field_Config__c WHERE dyfr__Tab__r.dyfr__Template__r.acpl__Account_Planning_Type__c != null'
        );
        
    }
     /**
    * método que ejecuta el batch
    * @author Global hub
    */
    public void execute(Database.BatchableContext bachContex, List<dyfr__Field_Config__c> scope) {
        final List<dyfr__Field_Config__c> lstFCDelete = new List<dyfr__Field_Config__c>();
        // process each batch of records
        for (dyfr__Field_Config__c fieldConfig : scope) {
            if (!idCatalogs.contains(fieldConfig.dyfr__DeveloperName__c.substringBefore('_'))) {
				lstFCDelete.add(fieldConfig);      
            	// increment the instance member counter
            	recordsProcessed = recordsProcessed + 1;
            }
        }
        if(!lstFCDelete.isEmpty()) {
        	delete lstFCDelete;
        }
    }
     /**
    * método que ejecuta el batch finish
    * @author Global hub
    */
    public void finish(Database.BatchableContext bachContex) {
        System.debug(recordsProcessed + 'Field Config records processed!');
        
    }
}