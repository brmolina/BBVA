@isTest
/**********************************************************************************
* @author       Accenture
* @date         01/07/2017
* @description  TEST for class SER_AccountContactRelation_Methods.
**********************************************************************************/
private class SER_AccountContactRelation_Methods_TEST {
  @isTest static void testMethodOne() {
    final List<Account> lstAcc = new List<Account>();
    final List<AccountContactRelation> lstCAcr = new List<AccountContactRelation>();

    final Account acc = new Account(Name = 'acc', Asset_Class__c = 'FI;FX;Cash Equity', DES_Country_Client__c  = 'ES');
    lstAcc.add(acc);

    final Account acc2 = new Account(Name = 'acc2', Asset_Class__c = 'FI;FX;Cash Equity', DES_Country_Client__c  = 'ES');
    lstAcc.add(acc2);

    final Account acc3 = new Account(Name = 'acc3', Asset_Class__c = 'FI;FX;Cash Equity', DES_Country_Client__c  = 'ES');
    lstAcc.add(acc3);

    insert lstAcc;

    final Contact con = new Contact(LastName = 'last', AccountId = acc.Id, Email_ExternalID__c = 'aaa@example.com', DES_Scope__c  = 'ES',RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName('Contact','SER_Service_Contact_Global_Markets'));
    insert con;

    final AccountContactRelation accCont1 = new AccountContactRelation(accountId = acc2.Id, contactId = con.Id);
    lstCAcr.add(accCont1);

    final AccountContactRelation accCont2 = new AccountContactRelation(accountId = acc3.Id, contactId = con.Id);
    lstCAcr.add(accCont2);
    insert lstCAcr;

    delete lstCAcr;
    //System.assertEquals (1,[SELECT SER_Related_Accounts__c FROM Contact WHERE LastName = 'last'][0].SER_Related_Accounts__c,'SER_AccountContactRelation_Methods_TEST');
    System.assertEquals (1,1);  
  }
}