/**
 *
 * @author Global Desktop
 */
@isTest
public with sharing class NPS_GetGroupsGB_Test {
  /**
   * Test method for NPS_ContactHistory controller
   */
  @isTest
  public static void testGetGroupsGB() {
    final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();

    final List<Account> accList = new List<Account>();
    final Set<Id> accIdList = new Set<Id>();

    final Account acc1 = iUtilClass.createClient();
    acc1.DES_Country_Client__c = 'AR';
    accList.add(acc1);
    final Account acc2 = iUtilClass.createClient();
    acc2.DES_Country_Client__c = 'BE';
    accList.add(acc2);
    final Account acc3 = iUtilClass.createClient();
    acc3.DES_Country_Client__c = 'FR';
    accList.add(acc3);
    insert accList;

    final Account iAccount = iUtilClass.createGroupClient('Group test', accIdList, UserInfo.getUserId());
    iAccount.survey_nps_contact_type__c = true;
    iAccount.DES_Country_Client__c = 'BE';
    update iAccount;

    final String profile = iUtilClass.createProfile();
    final User iUser = iUtilClass.createUser(profile);
    insert iUser;

    final NPS_Wave__c iNPSWave = new NPS_Wave__c();
    iNPSWave.gf_nps_sv_cust_oper_cntry_desc__c = 'BE';
    iNPSWave.nps_start_date__c = Date.newInstance(Date.today().year(), Date.today().month(), 1);
    iNPSWave.nps_end_date__c = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month()));
    insert iNPSWave;

    Test.startTest();
      final NPS_GetGroupsGB_Controller iController = new NPS_GetGroupsGB_Controller();
      iController.varUserId = UserInfo.getUserId();
      iController.varWave = iNPSWave.Id;
      iController.varInit = '';

      System.assert(iController.listClient != null, 'listClient is null');
    Test.stopTest();
  }
}