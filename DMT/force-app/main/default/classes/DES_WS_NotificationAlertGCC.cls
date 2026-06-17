/*
* Notificar Alertas GCC
*/
@RestResource(urlMapping='/notificationAlertsGCC')
global with sharing class DES_WS_NotificationAlertGCC {

  /*
  * SINGLETON PATTERN
  */
  private static DES_WS_NotificationAlertGCC instance;

  /*
  * Constructor
  */
  private DES_WS_NotificationAlertGCC() {
  }

  /*
  * getInstance
  */
  public static DES_WS_NotificationAlertGCC gtInstance() {  //NOSONAR
    if (instance == null) {
      instance = new DES_WS_NotificationAlertGCC();
    }
    return instance;
  }

  /*
  * Method notificar
  */
  @HttpGet
  global static Id runRelationBatch() {
    final DES_Batch_NewAlert_Notify batchNotification = new DES_Batch_NewAlert_Notify('Commercial Task GCC');
    final Id batchInstanceId = Database.executeBatch(batchNotification, 2000);
    system.debug('>>>>> id BATCH JOB: ' + batchInstanceId);
    return batchInstanceId;
  }
}