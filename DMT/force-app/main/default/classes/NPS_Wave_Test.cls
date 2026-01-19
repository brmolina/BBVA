/******************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: Home_NPS_Wave_Test
*   @Description:  Home_NPS_Wave_Cnt - Tests

*   @Versions:
        v1 - 2019/11/06 - Initial version
******************************************************************************/
@isTest
public with sharing class NPS_Wave_Test {
  /**
   * Test method for NPS_Wave_Helper
   */
  @isTest
  public static void testNPSWave() { //NOSONAR
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

    final List<DES_Subsidiary_Group_Relation__c> listRelation = new List<DES_Subsidiary_Group_Relation__c>();
    final DES_Subsidiary_Group_Relation__c iRelation1 = iUtilClass.createSubsidiaryGroupRelation(iAccount, acc1);
    listRelation.add(iRelation1);
    final DES_Subsidiary_Group_Relation__c iRelation2 = iUtilClass.createSubsidiaryGroupRelation(iAccount, acc2);
    listRelation.add(iRelation2);
    final DES_Subsidiary_Group_Relation__c iRelation3 = iUtilClass.createSubsidiaryGroupRelation(iAccount, acc3);
    listRelation.add(iRelation3);
    insert listRelation;

    final String profile = iUtilClass.createProfile();
    final User iUser = iUtilClass.createUser(profile);
    insert iUser;

    final NPS_Wave__c iNPSWave = new NPS_Wave__c();
    iNPSWave.gf_nps_sv_cust_oper_cntry_desc__c = 'BE';
    iNPSWave.nps_start_date__c = Date.newInstance(Date.today().year(), Date.today().month(), 1);
    iNPSWave.nps_end_date__c = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month()));
    insert iNPSWave;

    Test.startTest();
      NPS_Wave_Helper.getInstance();
      Map<String,String> listContactsNPSMail = new Map<String,String>();
      Map<String,String> listGlobalBankerEmail = new Map<String,String>();

      NPS_Wave_Helper.npsNotification(new List<NPS_Wave__c> {iNPSWave}, new List<Account> {iAccount, acc1, acc2, acc3},listContactsNPSMail,listGlobalBankerEmail);
    Test.stopTest();
  }

  /**
   * Test method for NPS_Wave_Helper
   */
  @isTest
  public static void testNPSWave2() { //NOSONAR
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
      NPS_Wave_Helper_Aux.getInstance();
      Map<String,String> listContactsNPSMail = new Map<String,String>();
      Map<String,String> listGlobalBankerEmail = new Map<String,String>();

      NPS_Wave_Helper.npsNotification(new List<NPS_Wave__c> {iNPSWave}, new List<Account> {iAccount},listContactsNPSMail,listGlobalBankerEmail);
    Test.stopTest();
  }
}