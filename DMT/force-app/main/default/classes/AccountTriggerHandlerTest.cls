@isTest
public class AccountTriggerHandlerTest {
  /*
   * Test method1
   */
  @isTest
  public static void AccountTriggerHandlerTest() {

    DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    String profileTest = utilTestClass.createProfile();
    User userTest1 = utilTestClass.createUser(profileTest);
    insert userTest1;
    CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
    insert userSettings;

    system.runAs(userTest1) {
      List<Account> listaCuentas = new List<Account>();
      Test.startTest();
      Account accBEC = utilTestClass.createClient();
      accBEC.DES_Structure_Type__c = Label.DES_STR_TYPE_Subsidiary;
      accBEC.DES_BBVA_Segmentation__c = Label.DES_Segmentation_B_BEC;
      listaCuentas.add(accBEC);
      Account accBEC2 = utilTestClass.createClient();
      accBEC2.DES_Structure_Type__c = Label.DES_STR_TYPE_Supragroup;
      accBEC2.DES_BBVA_Segmentation__c = Label.DES_Segmentation_B_BEC;
      listaCuentas.add(accBEC2);
      Account accShared = utilTestClass.createClient();
      accShared.DES_Structure_Type__c = Label.DES_STR_TYPE_Shared_Manag_Group;
      accShared.DES_BBVA_Segmentation__c = Label.DES_Segmentation_C_CIB;
      listaCuentas.add(accShared);
      Account aa1 = utilTestClass.createClient();
      aa1.DES_Structure_Type__c = Label.DES_STR_TYPE_Supragroup;
      aa1.DES_BBVA_Segmentation__c = Label.DES_Segmentation_C_CIB;
      listaCuentas.add(aa1);
      Account aa2 = utilTestClass.createClient();
      aa2.DES_Structure_Type__c = Label.DES_STR_TYPE_Subsidiary;
      aa2.DES_BBVA_Segmentation__c = Label.DES_Segmentation_C_CIB;
      listaCuentas.add(aa2);
      Account aa3 = utilTestClass.createClient();
      aa3.DES_Structure_Type__c = Label.DES_STR_TYPE_Subgroup;
      aa3.DES_BBVA_Segmentation__c = Label.DES_Segmentation_C_CIB;
      listaCuentas.add(aa3);

      insert listaCuentas;

      Account accManual = utilTestClass.createClient();
      insert accManual;
      Test.stopTest();

    }

  }
  /*
   * Test method2
   */
  @isTest
  public static void checkSubsidiaryTest() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final String profileTest = utilTestClass.createProfile();
    final User user = utilTestClass.createUser(profileTest);
    insert user;
    final Account acc = utilTestClass.createClient();
    final Account acc2 = utilTestClass.createClient();
    final List <Account> listAccs = new List <Account>();
    listAccs.add(acc);
    listAccs.add(acc2);
    insert listAccs;
    final DES_Subsidiary_Group_Relation__c matrix = utilTestClass.createMatrix(acc);
    matrix.participant_parent_id__c = acc2.Id;
    insert matrix;
    Test.startTest();
    acc2.survey_nps_contact_type__c = true;
    update acc2;
    final Account accResult = [SELECT Id, survey_nps_contact_type__c from Account WHERE Id = :acc2.Id LIMIT 1];
    system.assert (accResult.survey_nps_contact_type__c, 'npstrue');
    Test.stopTest();
  }

  /*
   * Test method2
   */
  @isTest
  public static void checkNPSGroupTest() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final Account acc = utilTestClass.createClient();
		acc.DES_BBVA_Segmentation__c = Label.DES_Segmentation_C_CIB;
		acc.DES_Structure_Type__c = Label.DES_STR_TYPE_Supragroup;
    acc.RecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Supragroup).getRecordTypeId();
		insert acc;
		final Account acc2 = utilTestClass.createClient();
		acc2.DES_BBVA_Segmentation__c = Label.DES_Segmentation_C_CIB;
		acc2.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
    acc2.RecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Group).getRecordTypeId();
		insert acc2;
    acc2.DES_BBVA_Segmentation__c = Label.DES_Segmentation_C_CIB;
    acc2.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
    update acc2;
    final dwp_acmh__GBL_Account_Relationship__c relation = utilTestClass.createAccRelationship(acc, acc2);
    insert relation;
    Test.startTest();
    acc.DES_BBVA_Segmentation__c = Label.DES_Segmentation_C_CIB;
    acc.DES_Structure_Type__c = Label.DES_STR_TYPE_Supragroup;
    acc.survey_nps_contact_type__c = true;
    update acc;
    final Account accResult = [SELECT Id, survey_nps_contact_type__c from Account WHERE Id = :acc.Id LIMIT 1];
    system.assert (accResult.survey_nps_contact_type__c, 'npstrue');
    Test.stopTest();
  }

  /*
  * Test method local
  */
  @isTest
  public static void localTest() {
    final DES_UtilTestClass util = new DES_UtilTestClass();
    final Account acc = util.createClient();
    final Account acc2 = util.createClient();
    acc.DES_BBVA_Segmentation__c = Label.DES_Segmentation_L_Local;
    acc2.DES_BBVA_Segmentation__c = Label.DES_Segmentation_L_Local;
    acc.DES_Structure_Type__c = Label.DES_STR_TYPE_Subsidiary;
    acc2.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
    Test.startTest();
    insert acc;
    insert acc2;
    system.assertEquals(Label.DES_Segmentation_L_Local, acc.DES_BBVA_Segmentation__c,'L');
    Test.stopTest();
  }
}