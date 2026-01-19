/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 11-30-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class Des_GetPermission_Locator_test {
  /*
  * TEST2VAR
  */
  public static final String TESTVAR = 'test1';
/**
  * Test IRP
  */
  @isTest
  static void testIRPCross() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = TESTVAR;
    acc.Name = TESTVAR;
    acc.DES_Tier__c = '00000024'; //BEeIG-GCB
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.Name = 'Test';
    insert lclient1;

    String idProfile;
    idProfile = tstClass.createProfile();
    User userTest;
    userTest = tstClass.createUser(idProfile);
    userTest.gf_user_operation_ambit_name__c = 'E - OF0 - DT Sur Cadiz y Ceuta';
    insert userTest;

    Des_GetPermission_Locator locator = new Des_GetPermission_Locator();
    System.runAs(userTest) {
        Boolean irp = locator.irpEnabler(lclient1.Id);
        system.assertEquals(true, irp, 'IRP FAILED Cross');
    }
  }
  @isTest
  static void testARPCross() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = TESTVAR;
    acc.Name = TESTVAR;
    acc.DES_Tier__c = '00000024'; //BEeIG-GCB
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.Name = 'Test';
    insert lclient1;

    String idProfile;
    idProfile = tstClass.createProfile();
    User userTest;
    userTest = tstClass.createUser(idProfile);
    userTest.gf_user_operation_ambit_name__c = 'E - OF0 - DT Sur Cadiz y Ceuta';
    insert userTest;

    Des_GetPermission_Locator locator = new Des_GetPermission_Locator();
    System.runAs(userTest) {
        Boolean irp = locator.arpEnabler(lclient1.Id);
        system.assertEquals(true, irp, 'ARP FAILED Cross');
    }
  }
  @isTest
  static void testCRPCross() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = TESTVAR;
    acc.Name = TESTVAR;
    acc.DES_Tier__c = '00000024'; //BEeIG-GCB
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.Name = 'Test';
    insert lclient1;

    String idProfile;
    idProfile = tstClass.createProfile();
    User userTest;
    userTest = tstClass.createUser(idProfile);
    userTest.gf_user_operation_ambit_name__c = 'E - OF0 - DT Sur Cadiz y Ceuta';
    insert userTest;

    Des_GetPermission_Locator locator = new Des_GetPermission_Locator();
    System.runAs(userTest) {
        Boolean irp = locator.crpEnabler(lclient1.Id);
        system.assertEquals(false, irp, 'CRP FAILED Cross');
    }
  }

  @isTest
  static void testIRP() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = TESTVAR;
    acc.Name = TESTVAR;
    acc.DES_Tier__c = '00000010'; //BEeIG - Others
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.Name = 'Test';
    insert lclient1;

    String idProfile;
    idProfile = tstClass.createProfile();
    User userTest;
    userTest = tstClass.createUser(idProfile);
    userTest.gf_user_operation_ambit_name__c = 'E - OF0 - DT Sur Cadiz y Ceuta';
    insert userTest;

    Des_GetPermission_Locator locator = new Des_GetPermission_Locator();
    System.runAs(userTest) {
        Boolean irp = locator.irpEnabler(lclient1.Id);
        system.assertEquals(true, irp, 'IRP FAILED');
    }
  }
  @isTest
  static void testARP() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = TESTVAR;
    acc.Name = TESTVAR;
    acc.DES_Tier__c = '00000010'; //BEeIG - Others
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.Name = 'Test';
    insert lclient1;

    String idProfile;
    idProfile = tstClass.createProfile();
    User userTest;
    userTest = tstClass.createUser(idProfile);
    userTest.gf_user_operation_ambit_name__c = 'E - OF0 - DT Sur Cadiz y Ceuta';
    insert userTest;

    Des_GetPermission_Locator locator = new Des_GetPermission_Locator();
    System.runAs(userTest) {
        Boolean irp = locator.arpEnabler(lclient1.Id);
        system.assertEquals(true, irp, 'ARP FAILED');
    }
  }
  @isTest
  static void testCRP() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = TESTVAR;
    acc.Name = TESTVAR;
    acc.DES_Tier__c = '00000010'; //BEeIG - Others
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.Name = 'Test';
    insert lclient1;

    String idProfile;
    idProfile = tstClass.createProfile();
    User userTest;
    userTest = tstClass.createUser(idProfile);
    userTest.gf_user_operation_ambit_name__c = 'E - OF0 - DT Sur Cadiz y Ceuta';
    insert userTest;


    Des_GetPermission_Locator locator = new Des_GetPermission_Locator();
    System.runAs(userTest) {
        String ambit = locator.formatAmbitCountry('PE - OF1 - CIB Transaction banking');
        String ambit2 = locator.formatAmbitCountry('M - OF1 - CIB Transactional Banking');
        String ambit3 = locator.formatAmbitCountry('C - OF1 - CIB Transactional Banking');
        String ambit4 = locator.formatAmbitCountry('CIB - OF1 - Global Banker');
        String ambit5 = locator.formatAmbitCountry('P - OF0 - Banca Europa');
        String ambit6 = locator.formatAmbitCountry('A - R2 - Empresas Admision I');
        Boolean irp4 = locator.crpEnabler(acc.Id);
        Boolean irp3 = locator.getPermissionToEdit(acc.Id);
        Boolean irp2 = locator.accountCrpEnabler(acc.Id);
        Boolean irp = locator.crpEnabler(lclient1.Id);
        system.assertEquals(false, irp, 'CRP FAILED');
    }
  }

  @isTest
  static void testIRPCountry() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = TESTVAR;
    acc.Name = TESTVAR;
    acc.DES_Tier__c = '00000010'; //BEeIG - Others
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.Name = 'Test';
    insert lclient1;

    String idProfile;
    idProfile = tstClass.createProfile();
    User userTest;
    userTest = tstClass.createUser(idProfile);
    userTest.DES_Country__c = 'ESP';
    userTest.gf_user_operation_ambit_name__c = 'E - OF0 - DT Sur Cadiz y Ceuta';
    insert userTest;

    Des_GetPermission_Locator locator = new Des_GetPermission_Locator();
    System.runAs(userTest) {
        Boolean irp3 = locator.irpEnabler(acc.Id);
        Boolean irp2 = locator.accountIrpEnabler(acc.Id);
        Boolean irp = locator.irpEnabler(lclient1.Id);
        system.assertEquals(true, irp, 'IRP FAILED');
    }
  }
  @isTest
  static void testARPCountry() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = TESTVAR;
    acc.Name = TESTVAR;
    acc.DES_Tier__c = '00000010'; //BEeIG - Others
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.Name = 'Test';
    insert lclient1;

    String idProfile;
    idProfile = tstClass.createProfile();
    User userTest;
    userTest = tstClass.createUser(idProfile);
    userTest.DES_Country__c = 'ESP';
    userTest.gf_user_operation_ambit_name__c = 'E - OF0 - DT Sur Cadiz y Ceuta';
    insert userTest;

    Des_GetPermission_Locator locator = new Des_GetPermission_Locator();
    System.runAs(userTest) {
        Boolean irp3 = locator.arpEnabler(acc.Id);
        Boolean irp2 = locator.accountArpEnabler(acc.Id);
        Boolean irp = locator.arpEnabler(lclient1.Id);
        system.assertEquals(true, irp, 'ARP FAILED');
    }
  }
  @isTest
  static void testCRPCountry() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = TESTVAR;
    acc.Name = TESTVAR;
    acc.DES_Tier__c = '00000010'; //BEeIG - Others
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.Name = 'Test';
    insert lclient1;

    String idProfile;
    idProfile = tstClass.createProfile();
    User userTest;
    userTest = tstClass.createUser(idProfile);
    userTest.DES_Country__c = 'ESP';
    userTest.gf_user_operation_ambit_name__c = 'E - OF0 - DT Sur Cadiz y Ceuta';
    insert userTest;

    Des_GetPermission_Locator locator = new Des_GetPermission_Locator();
    System.runAs(userTest) {
        Boolean irp = locator.crpEnabler(lclient1.Id);
        system.assertEquals(false, irp, 'CRP FAILED');
    }
  }
}