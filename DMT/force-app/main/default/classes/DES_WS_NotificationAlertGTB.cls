/*
* Notificar Alertas GTB
*/
@RestResource(urlMapping='/notificationAlertsGTBdeprecated')
global with sharing class DES_WS_NotificationAlertGTB {

  /*
  * SINGLETON PATTERN
  */
  private static DES_WS_NotificationAlertGTB instance;

  /*
  * Constructor
  */
  private DES_WS_NotificationAlertGTB() {
  }

  /*
  * getInstance
  */
  public static DES_WS_NotificationAlertGTB gtInstance() {  //NOSONAR
    if (instance == null) {
      instance = new DES_WS_NotificationAlertGTB();
    }
    return instance;
  }

  /*
  * Method notificar
  */
  @HttpGet
  global static Id runRelationBatch() {
    final DES_Batch_Commercial_Alert_Notify batchNotification = new DES_Batch_Commercial_Alert_Notify('Commercial Task GTB');
    final Id batchInstanceId = Database.executeBatch(batchNotification, 2000);
    system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
    return batchInstanceId;
  }
}