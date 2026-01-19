/**
 *
 * @author Global Desktop
 */
@isTest
public with sharing class NPS_ContactHistoryController_Test {
  /**
   * Test method for NPS_ContactHistory controller
   */
  @isTest
  public static void testNPSContactHistory() {
    final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();
    
    final Account iAccount = iUtilClass.createClient();
    iAccount.survey_nps_contact_type__c = true;
    iAccount.DES_Country_Client__c = 'BE';
    insert iAccount;

    final String profile = iUtilClass.createProfile();
    final User iUser = iUtilClass.createUser(profile);
    insert iUser;

    final NPS_Wave__c iNPSWave = new NPS_Wave__c();
    iNPSWave.gf_nps_sv_cust_oper_cntry_desc__c = 'BE';
    iNPSWave.nps_start_date__c = Date.newInstance(Date.today().year(), Date.today().month(), 1);
    iNPSWave.nps_end_date__c = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month()));
    insert iNPSWave;

    final Contact iContact = iUtilClass.createContact(iAccount);
    iContact.survey_nps_contact_type__c = false;
    insert iContact;

    iContact.survey_nps_contact_type__c = true;
    iContact.last_send_nps_user_id__c = iUser.Id;
    update iContact;
    
    Test.startTest();
      ContactHistory iContactHistory = new ContactHistory(
        ContactId = iContact.Id,
        Field = 'survey_nps_contact_type__c'
      );

      final NPS_ContactHistoryController.WrapperClass iWrapper = new NPS_ContactHistoryController.WrapperClass(iContactHistory);
      iWrapper.completeWrapperClass(iContactHistory);

      iContactHistory = new ContactHistory(
        ContactId = iContact.Id,
        Field = 'Owner'
      );
      iWrapper.completeWrapperClass(iContactHistory);
      iContactHistory = new ContactHistory(
        ContactId = iContact.Id,
        Field = 'last_send_nps_user_id__c'
      );
      iWrapper.completeWrapperClass(iContactHistory);
      iContactHistory = new ContactHistory(
        ContactId = iContact.Id,
        Field = 'nps_unavailable_date__c'
      );
      iWrapper.completeWrapperClass(iContactHistory);
      iContactHistory = new ContactHistory(
        ContactId = iContact.Id,
        Field = 'nps_discard_reason_type__c'
      );
      iWrapper.completeWrapperClass(iContactHistory);

      NPS_ContactHistoryController.getContactHistory('6', iContact.Id);
      System.assert(iContactHistory != null, 'Contact history is empty');
    Test.stopTest();
  }
}