/*
* Notificar Alertas GTB
*/
@RestResource(urlMapping='/notificationAlertsGTB')
global with sharing class DES_WS_NotificationNewAlertGTB {

  /*
  * SINGLETON PATTERN
  */
  private static DES_WS_NotificationNewAlertGTB instance;

  /*
  * Constructor
  */
  private DES_WS_NotificationNewAlertGTB() {
  }

  /*
  * getInstance
  */
  public static DES_WS_NotificationNewAlertGTB gtInstance() {  //NOSONAR
    if (instance == null) {
      instance = new DES_WS_NotificationNewAlertGTB();
    }
    return instance;
  }

  /*
  * Method notificar
  */
  @HttpGet
  global static Id runRelationBatch() {
    final DES_Batch_NewAlert_Notify batchNotification = new DES_Batch_NewAlert_Notify('Commercial Task GTB');
    final Id batchInstanceId = Database.executeBatch(batchNotification, 2000);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    return batchInstanceId;
  }
}