/**********************************************************************************
* @Company BBVA
* @description: Clase de Test de SER_Backup_BATCH.
**********************************************************************************/
@isTest
public class SER_Backup_BATCH_TEST {

  /*---------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   insertCase.
    OUT:           Case Id
  ---------------------------------------------------------------------------------------*/
  static Id insertCase() {
    Case caso;
    caso = new Case();
    insert caso;
    return caso.Id;
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   insertContact.
    OUT:           Contact Id
  ---------------------------------------------------------------------------------------*/
  static Id insertContact() {
    Account account;
    account = UnitTestUtils.GetStandardAccount();
    insert account;

    Contact contact;
    contact = new Contact();
    contact = UnitTestUtils.GetContact(account.id);
    contact.Logical_Delete__c = False;
    contact.Asset_Class_Text__c = ConstantsUtils.EQ;
    contact.Email = 'test@example.com';
    contact.RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName('Contact','SER_Service_Contact_Global_Markets');
    insert contact;
    return contact.Id;
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   Test1.
  ---------------------------------------------------------------------------------------*/
  @isTest
  static void batchTest1() {
    insertCase();
    test.startTest();
      SER_Backup_BATCH bubtch;
      bubtch = new SER_Backup_BATCH();
      Database.executeBatch(bubtch);
    test.stopTest();
    System.assertNotEquals(null,bubtch, 'Error1');
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   Test2.
  ---------------------------------------------------------------------------------------*/
  @isTest
  static void batchTest2() {
    insertContact();
    test.startTest();
      SER_Backup_BATCH bubtch;
      bubtch = new SER_Backup_BATCH('Select Id from Contact where RecordType.DeveloperName LIKE \'SER_%\'','BKP_CON_Backup_External_Id__c');
      Database.executeBatch(bubtch);
    test.stopTest();
    System.assertNotEquals(null,bubtch, 'Error2');
  }

}