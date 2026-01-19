/*
* Notificar Alertas GM
*/
@RestResource(urlMapping='/notificationAlertsGM')
global with sharing class DES_WS_NotificationNewAlertGM {

  /*
  * SINGLETON PATTERN
  */
  private static DES_WS_NotificationNewAlertGM instance;

  /*
  * Constructor
  */
  private DES_WS_NotificationNewAlertGM() {
  }

  /*
  * getInstance
  */
  public static DES_WS_NotificationNewAlertGM gtInstance() {  //NOSONAR
    if (instance == null) {
      instance = new DES_WS_NotificationNewAlertGM();
    }
    return instance;
  }

  /*
  * Method notificar
  */
  @HttpGet
  global static Id runRelationBatch() {
    final DES_Batch_NewAlert_Notify batchNotification = new DES_Batch_NewAlert_Notify('Commercial Task GM');
    final Id batchInstanceId = Database.executeBatch(batchNotification, 2000);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    return batchInstanceId;
  }
}