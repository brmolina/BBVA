@RestResource(urlMapping='/cucoProfitabilityErrorWS')
/**
* ────────────────────────────────────────────────────────────────────
* CucoProfitabilityErrorWS
* WS to execute CucoProfitabilityErrorBatch Class
* ────────────────────────────────────────────────────────────────────
* @author      CuCo CIB <globalhub_components.group@bbva.com>
* @modifiedBy
* @version     1.0
* @created     July 2021
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('sf:UseSingleton')
global with sharing class CucoProfitabilityErrorWS {

    /**
	*  HTTP GET WS Method
	*/
    @HttpGet
    global static Id runBatch() {
        final Id batchInstanceId = Database.executeBatch(new CucoProfitabilityErrorBatch(), Integer.valueOf(System.Label.Batch_Size));
        system.debug('>>>>> Started CucoProfitabilityErrorBatch with instance ID: ' + batchInstanceId);
        return batchInstanceId;
    }
}