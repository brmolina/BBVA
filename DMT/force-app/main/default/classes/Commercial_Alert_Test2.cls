/**********************************************************************************
* @author       Global Desktop
* @date         05/02/2020
* @description  Test class for Commercial_Alert_Test
**********************************************************************************/
@isTest
public class Commercial_Alert_Test2 {
  @isTest
  /* Method 25 */
  public static void executeNewBatch() {
    final DES_UtilTestClass objUtil = new DES_UtilTestClass ();
    final String idProfile = objUtil.createProfile();
    String taskIBF = '';
    taskIBF = 'Commercial Task IBF';

    final Account acc1 = objUtil.createClient();
    final Account acc2 = objUtil.createClient();
    final List<Account> listAccs = new List<Account>();
    listAccs.add(acc1);
    listAccs.add(acc2);
    insert listAccs;

    final User iUser1 = objUtil.createUser(idProfile);
    iUser1.ID_User__c += '1';
    iUser1.FederationIdentifier += '1';
    iUser1.Username += '1';
    System.debug('::::::::::iUser1.ID_User__c: ' + iUser1.ID_User__c);
    insert iUser1;
    final User iUser2 = objUtil.createUser(idProfile);
    iUser2.ID_User__c += '2';
    iUser2.FederationIdentifier += '2';
    iUser2.Username += '2';
    System.debug('::::::::::iUser2.ID_User__c: ' + iUser2.ID_User__c);
    insert iUser2;

    Test.startTest();
      final altm__Commercial_Alert__c comAlert1 = objUtil.createNewAlert(iUser1, iUser2, listAccs.get(0), 1, taskIBF);
      // comAlert1.altm__Transaction_type_desc__c = 'Corporate Loans';
      // comAlert1.altm__commercial_alert_task_type__c = 'backup';
      // final altm__Commercial_Alert__c comAlert5 = objUtil.createNewAlert(iUser2, iUser1, listAccs.get(1), 5, 'Notification');
      final List<altm__Commercial_Alert__c> listCommAlert = new List<altm__Commercial_Alert__c>(); //NOSONAR
      listCommAlert.add(comAlert1);
      // listCommAlert.add(comAlert5);
      insert listCommAlert;
      Test.stopTest();

      final DES_WS_NotificationNewAlertIBF notifyGF = DES_WS_NotificationNewAlertIBF.gtInstance();
      final Id idJobResultadoGF = DES_WS_NotificationNewAlertIBF.runRelationBatch();
      system.debug('idJobResultadoGF -> ' + idJobResultadoGF + ' ' + notifyGF);

      final DES_WS_NotificationNewAlertGM notifyGM = DES_WS_NotificationNewAlertGM.gtInstance();
      final Id idJobResultadoGM = DES_WS_NotificationNewAlertGM.runRelationBatch();
      system.debug('idJobResultadoGM -> ' + idJobResultadoGM + ' ' + notifyGM);

      final DES_WS_NotificationNewAlertGTB notifyGTB = DES_WS_NotificationNewAlertGTB.gtInstance();
      final Id idJobResultadoGTB = DES_WS_NotificationNewAlertGTB.runRelationBatch();
      system.debug('idJobResultadoGTB -> ' + idJobResultadoGTB + ' ' + notifyGTB);
      System.assertNotEquals(comAlert1, null, 'isnull');
  }
}