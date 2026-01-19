/*
* Notificar Alertas GF
*/
@RestResource(urlMapping='/notificationAlertsGF')
global with sharing class DES_WS_NotificationNewAlertIBF {

  /*
  * SINGLETON PATTERN
  */
  private static DES_WS_NotificationNewAlertIBF instance;

  /*
  * Constructor
  */
  private DES_WS_NotificationNewAlertIBF() {
  }

  /*
  * getInstance
  */
  public static DES_WS_NotificationNewAlertIBF gtInstance() {  //NOSONAR
    if (instance == null) {
      instance = new DES_WS_NotificationNewAlertIBF();
    }
    return instance;
  }

  /*
  * Method notificar
  */
  @HttpGet
  global static Id runRelationBatch() {
    final DES_Batch_NewAlert_Notify batchNotification = new DES_Batch_NewAlert_Notify('Commercial Task IBF');
    final Id batchInstanceId = Database.executeBatch(batchNotification, 2000);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    return batchInstanceId;
  }
}