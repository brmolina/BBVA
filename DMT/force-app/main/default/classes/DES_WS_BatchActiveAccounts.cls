/**
* @author Global Desktop
* @description Web Service del batch BatchActiveAccounts
*/
@RestResource(urlMapping='/activeAccounts')
global with sharing class DES_WS_BatchActiveAccounts {
    private DES_WS_BatchActiveAccounts() { }
	/**
	* @author Global Desktop
	* @description Llamada al batch BatchActiveAccounts
	*/
	@HttpGet
    global static Id runActiveAccounts() {
        final Id batchInstanceId = Database.executeBatch(new BatchActiveAccounts(), 1200);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }

}