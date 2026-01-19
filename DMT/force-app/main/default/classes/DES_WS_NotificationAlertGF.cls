/*
* Notificar Alertas GF
*/
@RestResource(urlMapping='/notificationAlertsGFdeprecated')
global with sharing class DES_WS_NotificationAlertGF {

  /*
  * SINGLETON PATTERN
  */
  private static DES_WS_NotificationAlertGF instance;

  /*
  * Constructor
  */
  private DES_WS_NotificationAlertGF() {
  }

  /*
  * getInstance
  */
  public static DES_WS_NotificationAlertGF gtInstance() {  //NOSONAR
    if (instance == null) {
      instance = new DES_WS_NotificationAlertGF();
    }
    return instance;
  }

  /*
  * Method notificar
  */
  @HttpGet
  global static Id runRelationBatch() {
    final DES_Batch_Commercial_Alert_Notify batchNotification = new DES_Batch_Commercial_Alert_Notify('Commercial Task IBF');
    final Id batchInstanceId = Database.executeBatch(batchNotification, 2000);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    return batchInstanceId;
  }
}