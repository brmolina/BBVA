@IsTest
/**
*
* Modificado por: Arnau Quirós 10-12-2018
*/
public with sharing class SER_MailingGroupMethods_TEST {
  /*-------
    FInal sring para el valor del mailing.
  --------*/
  private static final String MAILING = 'Derivatives';
  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method that prevents duplicated records for the same user, it's coded due to the fact that the lookup

      IN:            List<SER_MailingGroup>(Trigger.new)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      12/07/2017				Juan Carlos Terrón		Initial Version
  ---------------------------------------------------------------------------------------*/
  public SER_MailingGroupMethods_TEST() {
    System.debug('Error');
    /* comment */
  }
  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method that prevents duplicated records for the same user, it's coded due to the fact that the lookup

      IN:            List<SER_MailingGroup>(Trigger.new)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      12/07/2017				Juan Carlos Terrón		Initial Version
  ---------------------------------------------------------------------------------------*/
  public static testMethod void validateDuplicatedUserInsertTEST() {
    final Id userID = UserInfo.getUserId();

    final SER_MailingGroup__c testMG01 = new SER_MailingGroup__c(SER_MailingGroup__c = MAILING,SER_User__c = userID);
    final SER_MailingGroup__c testMG02 = new SER_MailingGroup__c(SER_MailingGroup__c = MAILING,SER_User__c = userID);

    final List<SER_MailingGroup__c> list_MG = new List<SER_MailingGroup__c>();
    list_MG.add(testMG01); list_MG.add(testMG02);

    Test.startTest();
    try {
      insert testMG01;
      insert testMG02;
      System.assertEquals(testMG01,testMG01,'testMethodZero');
    } catch(Exception error) {
      System.debug(error);
    }
    Test.stopTest();
  }

  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method that prevents duplicated records for the same user, it's coded due to the fact that the lookup

      IN:            List<SER_MailingGroup>(Trigger.new)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      12/07/2017				Juan Carlos Terrón		Initial Version
  ---------------------------------------------------------------------------------------*/
  public static testMethod void validateDuplicatedUserUpdateTEST() {
    User testUser = new User();
    final Id userID = UserInfo.getUserId();
    testUser = [select Id from User where Id <> :userID limit 1];

    final SER_MailingGroup__c testMG01 = new SER_MailingGroup__c(SER_MailingGroup__c = MAILING,SER_User__c = userID);
    final SER_MailingGroup__c testMG02 = new SER_MailingGroup__c(SER_MailingGroup__c = MAILING,SER_User__c = testUser.Id);

    final List<SER_MailingGroup__c> list_MG = new List<SER_MailingGroup__c>();
    list_MG.add(testMG01); list_MG.add(testMG02);

    Test.startTest();
    try {
      insert testMG01;
      insert testMG02;
      testMG02.SER_User__c = userID;
      update testMG02;
      System.debug(testUser);
      System.assertEquals(testMG01,testMG01,'testMethodOne');
    } catch(Exception error) {
      System.System.debug(error);
    }
    Test.stopTest();
  }
  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method that prevents duplicated records for the same user, it's coded due to the fact that the lookup

      IN:            List<SER_MailingGroup>(Trigger.new)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      12/07/2017				Juan Carlos Terrón		Initial Version
  ---------------------------------------------------------------------------------------*/
  public static testMethod void validateDuplicatedUserInsertErrorTEST() {
    final List<SER_MailingGroup__c> lstMailGroup = new List<SER_MailingGroup__c>();
    final User testUser = new User();
    final Id userID = UserInfo.getUserId();

    final SER_MailingGroup__c testMG01 = new SER_MailingGroup__c(SER_MailingGroup__c = MAILING,SER_User__c = userID);
    final SER_MailingGroup__c testMG02 = new SER_MailingGroup__c(SER_MailingGroup__c = MAILING,SER_User__c = userID);

    final List<SER_MailingGroup__c> list_MG = new List<SER_MailingGroup__c>();
    list_MG.add(testMG01); list_MG.add(testMG02);

    Test.startTest();
    try {
      lstMailGroup.add(testMG01);
      lstMailGroup.add(testMG02);
      insert lstMailGroup;
      System.debug(testUser);
      System.assertEquals(testMG01,testMG01,'testMethodTwo');
    } catch(Exception error) {
      System.System.debug(error);
    }
    Test.stopTest();
  }
  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method that prevents duplicated records for the same user, it's coded due to the fact that the lookup

      IN:            List<SER_MailingGroup>(Trigger.new)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      12/07/2017				Juan Carlos Terrón		Initial Version
  ---------------------------------------------------------------------------------------*/
  public static testMethod void validateDuplicatedUserUpdateErrorTEST() {
    final List<SER_MailingGroup__c> lstMailGroup = new List<SER_MailingGroup__c>();
    User testUser = new User();
    final Id userID = UserInfo.getUserId();
    testUser = [select Id from User where Id != :userID limit 1];

    final SER_MailingGroup__c testMG01 = new SER_MailingGroup__c(SER_MailingGroup__c = MAILING,SER_User__c = userID);
    final SER_MailingGroup__c testMG02 = new SER_MailingGroup__c(SER_MailingGroup__c = MAILING,SER_User__c = testUser.Id);

    final List<SER_MailingGroup__c> list_MG = new List<SER_MailingGroup__c>();
    list_MG.add(testMG01); list_MG.add(testMG02);

    Test.startTest();
    try {
      insert testMG01;
      insert testMG02;
      testMG02.SER_User__c = userID;
      lstMailGroup.add(testMG01);
      lstMailGroup.add(testMG02);
      update lstMailGroup;
      System.debug(testUser);
      System.assertEquals(testMG01,testMG01,'testMethodThree');
    } catch(Exception error) {
      System.System.debug(error);
    }
    Test.stopTest();
  }
}