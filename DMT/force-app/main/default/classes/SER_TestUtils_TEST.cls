/*---------------------------------------------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Test class for SER_TestUtils.

    History:
    <Date>          <Author>                <Description>
    16/03/1993		Juan Carlos Terrón		Initial Version
----------------------------------------------------------------------------------------------------*/
@isTest
private class SER_TestUtils_TEST {

  @isTest
  static void testCreateAccount() {
    Test.startTest();
    SER_TestUtils.ddCreateAccount(true);
    SER_TestUtils.ddCreateAccount(null);
    final List<account> lstAccount = [SELECT Id FROM account WHERE Name ='newAccount'];
    Test.stopTest();
    System.assertEquals (lstAccount.size(),1,'testCreateAccount');
  }

  @isTest
  static void testCreateContact() {
    Test.startTest();
    final Contact newContact = SER_TestUtils.ddCreateContact(true);
    System.assert (newContact!=null,'testCreateContact');
    Test.stopTest();
  }

  @isTest
  static void testCreateUser() {
    Test.startTest();
    SER_TestUtils.ddCreateUser('Service Integration', true);
    final List<User> lstContact = [SELECT Id FROM user WHERE Lastname='LastNameTest' AND Alias = 'Alias' AND Email = 'Alias@accenture.com'];
    Test.stopTest();
    System.assertEquals (lstContact.size(), 1,'testCreateUser');
  }
}