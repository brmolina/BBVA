/**
* Clase de TEST para las clases Commercial_Alert_UpdateToMatured_JOB y Commercial_Alert_UpdateToMatured_BATCH.
*/
@isTest
public class Commercial_Alert_UpdateToMatured_TEST {

  /*
  * @author Global Desktop
  * @description Helper method to create account
  */
  private static Account createAccount() {
    final Account iAccount = new Account();
    iAccount.Name = 'Test';
    insert iAccount;
    return iAccount;
  }

  /*
  * @author Global Desktop
  * @description Helper method to create alert
  */
  private static altm__Commercial_Alert__c createAlert(Account iAccount) {
    User obj;
    obj=[SELECT Id,IsActive,FederationIdentifier FROM User where FederationIdentifier!=null and IsActive=true limit 1];
    final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
    iCommercialAlert.altm__gf_last_upload_alerts_ind_type__c = false;
    iCommercialAlert.altm__participant_id__c = iAccount.Id;
    iCommercialAlert.altm__owner_access_alert_id__c = obj.FederationIdentifier;
    iCommercialAlert.altm__priority_alert_type__c ='High' ;
    iCommercialAlert.altm__alert_stage_type__c='Matured';
    iCommercialAlert.altm__commercial_alert_end_date__c=Date.today()-1;
   // iCommercialAlert.ownerid = UserInfo.getUserId();
    insert iCommercialAlert;
    return iCommercialAlert;
  }

  /**
  * @author Global Desktop
  * @description Test para Flow_Update_Mature
  */
  public static testMethod void test1() {
    Test.startTest();
    insert new CIB_Bypass__c( CIB_Skip_Commercial_Alert_trigger__c=true );
    final Account iAccount = createAccount();
    final altm__Commercial_Alert__c iCommercialAlert = createAlert(iAccount);
    iCommercialAlert.altm__alert_stage_type__c=Label.COMMERCIAL_ALERT_STATUS_PENDING;
    update iCommercialAlert;

    Commercial_Alert_UpdateToMatured_JOB job;
    job = new Commercial_Alert_UpdateToMatured_JOB();
    job.execute(null);

    Commercial_Alert_UpdateToMatured_JOB job2;
    job2 = new Commercial_Alert_UpdateToMatured_JOB();
    job2.execute(null, 'SELECT Id, altm__alert_stage_type__c, altm__owner_access_alert_id__c FROM altm__Commercial_Alert__c WHERE altm__alert_stage_type__c = \'Pending\' and altm__commercial_alert_end_date__c <= TODAY');

    System.assertNotEquals(null, job2, 'Error');

    Test.stopTest();
  }

}