/*
* WS denormalize alerts
*/
@RestResource(urlMapping='/denormalizeAlerts')
global with sharing class DES_WS_AlertBatches {

  /*
  * SINGLETON PATTERN
  */
  private static DES_WS_AlertBatches instance;

  /*
  * Constructor
  */
  private DES_WS_AlertBatches() {
  }

  /*
  * getInstance
  */
  public static DES_WS_AlertBatches gtInstance() {  //NOSONAR
    if (instance == null) {
      instance = new DES_WS_AlertBatches();
    }
    return instance;
  }

  /*
  * Method denormalize delete
  */
    @HttpGet
  	global static Id runRelationBatch() {
    	final Id batchInstanceId = Database.executeBatch(new DES_DenormalizeAlertsDelete(), 100);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
		return batchInstanceId;
	}
}