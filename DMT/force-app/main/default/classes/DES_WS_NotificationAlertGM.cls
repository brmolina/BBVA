/*
* Notificar Alertas GM
*/
@RestResource(urlMapping='/notificationAlertsGMdeprecated')
global with sharing class DES_WS_NotificationAlertGM {

  /*
  * SINGLETON PATTERN
  */
  private static DES_WS_NotificationAlertGM instance;

  /*
  * Constructor
  */
  private DES_WS_NotificationAlertGM() {
  }

  /*
  * getInstance
  */
  public static DES_WS_NotificationAlertGM gtInstance() {  //NOSONAR
    if (instance == null) {
      instance = new DES_WS_NotificationAlertGM();
    }
    return instance;
  }

  /*
  * Method notificar
  */
  @HttpGet
  global static Id runRelationBatch() {
    final DES_Batch_Commercial_Alert_Notify batchNotification = new DES_Batch_Commercial_Alert_Notify('Commercial Task GM');
    final Id batchInstanceId = Database.executeBatch(batchNotification, 2000);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    return batchInstanceId;
  }
}