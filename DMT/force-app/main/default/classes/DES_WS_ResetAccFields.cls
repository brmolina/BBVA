/**
* @author Global Desktop
* @description Web Service del batch DES_Batch_ResetAccFields
*/
@RestResource(urlMapping='/resetAccFields')
global with sharing class DES_WS_ResetAccFields {

	/**
	* @author Global Desktop
	* @description Llamada al batch DES_Batch_ResetAccFields
	*/
	@HttpGet
    global static Id runResetAccFields() {
        Id batchInstanceId = Database.executeBatch(new DES_Batch_ResetAccFields(), 2000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }

}