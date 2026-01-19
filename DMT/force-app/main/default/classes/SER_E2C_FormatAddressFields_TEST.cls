/**
* Project:           BBVA
* Description:       Clase SER_E2C_FormatAddressFields_TEST
*
*            No.     Date            Author                  Description
*            -----   ----------      --------------------    ---------------
* @version   1.1     2020-03-23      Victor Velandia (VV)    Ajuste Clase TEST Sonar
***********************************************************************************/

@IsTest
public with sharing class SER_E2C_FormatAddressFields_TEST {

  /**
  * description: test1
  */
  @IsTest
  public static void test1() {
    SER_EmailDefaultValues_Assignment__c emailsetting = new SER_EmailDefaultValues_Assignment__c();
    emailsetting.Name = 'emailsetting';
    emailsetting.SER_FromAddres__c = 'lessthan40charactersaddressline1@fakeemial.com';
    emailsetting.SER_MailingGroup__c = 'ALL FI & RV & Derivatives';
    emailsetting.SER_OutboundFromAddress__c = 'lessthan40charactersaddressline1@fakeemial.com';
    emailsetting.SER_OutboundMailbox__c = 'Email CDS';
    emailsetting.SER_Queue__c = 'SER_Settlement_CDS';
    EmailMessage email;
    email = new EmailMessage();
    final SER_EmailDefaultValues_Assignment__c emailsetting2 = new SER_EmailDefaultValues_Assignment__c();
    emailsetting2.SER_FromAddres__c = 'morethan40charactersaddressline1@fakeemial.com';
    emailsetting2.Name = 'emailsetting2';
    emailsetting2.SER_OutboundFromAddress__c = 'morethan40charactersaddressline1@fakeemial.com';
    final SER_EmailDefaultValues_Assignment__c emailsetting3 = new SER_EmailDefaultValues_Assignment__c();
    emailsetting3.SER_FromAddres__c = 'lessthan40charactersaddressline2@fakeemial.com';
    emailsetting3.SER_OutboundFromAddress__c = 'lessthan40charactersaddressline2@fakeemial.com';
    emailsetting3.Name = 'emailsetting3';
    final SER_EmailDefaultValues_Assignment__c emailsetting4 = new SER_EmailDefaultValues_Assignment__c();
    emailsetting4.SER_FromAddres__c = 'morethan40charactersaddressline2@fakeemial.com';
    emailsetting4.SER_OutboundFromAddress__c = 'morethan40charactersaddressline2@fakeemial.com';
    emailsetting4.Name = 'emailsetting4';
    email.toaddress = 'lessthan40charactersaddressline1@fakeemial.com;morethan40charactersaddressline1@fakeemial.com';
    email.ccaddress = 'lessthan40charactersaddressline2@fakeemial.com;morethan40charactersaddressline2@fakeemial.com';
    List<SER_EmailDefaultValues_Assignment__c> settings;
    settings = new List<SER_EmailDefaultValues_Assignment__c> {emailsetting,emailsetting2,emailsetting3,emailsetting4};
    insert settings;
    final SER_E2C_FormatAddressFields formatter = new SER_E2C_FormatAddressFields(email);
    final Map<String,String> result = formatter.processEmailAddresses();
    System.assertequals( true,result != null, 'test1');
  }

  /**
  * description: test3
  */
  @istest
  public static void test3() {
    final SER_EmailDefaultValues_Assignment__c emailsetting = new SER_EmailDefaultValues_Assignment__c();
    emailsetting.Name = 'emailsetting';
    emailsetting.SER_FromAddres__c = 'email1@email.com';
    emailsetting.SER_MailingGroup__c = 'ALL FI & RV & Derivatives';
    emailsetting.SER_OutboundFromAddress__c = 'email1@email.com';
    emailsetting.SER_OutboundMailbox__c = 'Email CDS';
    emailsetting.SER_Queue__c = 'SER_Settlement_CDS';
    EmailMessage email;
    email = new EmailMessage();
    SER_EmailDefaultValues_Assignment__c emailsetting2 = new SER_EmailDefaultValues_Assignment__c();
    emailsetting2.SER_FromAddres__c = 'email2@email.com';
    emailsetting2.Name = 'emailsetting2';
    emailsetting2.SER_OutboundFromAddress__c = 'email2@email.com';
    final SER_EmailDefaultValues_Assignment__c emailsetting3 = new SER_EmailDefaultValues_Assignment__c();
    emailsetting3.SER_FromAddres__c = 'email3@email.com';
    emailsetting3.SER_OutboundFromAddress__c = 'email3@email.com';
    emailsetting3.Name = 'emailsetting3';
    final SER_EmailDefaultValues_Assignment__c emailsetting4 = new SER_EmailDefaultValues_Assignment__c();
    emailsetting4.SER_FromAddres__c = 'email4@email.com';
    emailsetting4.SER_OutboundFromAddress__c = 'email4@email.com';
    emailsetting4.Name = 'emailsetting4';
    email.toaddress = 'email1@email.com;email2@email.com;notdefinedaddress1@email.com;notdefinedaddress2@email.com';
    email.ccaddress = 'email3@email.com;email4@email.com;notdefinedaddress3@email.com;notdefinedaddress4@email.com';
    List<SER_EmailDefaultValues_Assignment__c> settings;
    settings = new List<SER_EmailDefaultValues_Assignment__c> {emailsetting,emailsetting2,emailsetting3,emailsetting4};
    insert settings;
    SER_E2C_FormatAddressFields formatter = new SER_E2C_FormatAddressFields(email);
    Map<String,String> result;
    result = formatter.processEmailAddresses();
    email.toaddress = 'email1@email.com;email2@email.com;notdefinedaddress1@email.com;notdefinedaddress2@email.com;notdefinedaddressA@email.com;notdefinedaddressB@email.com';
    email.ccaddress = 'email3@email.com;email4@email.com;notdefinedaddress3@email.com;notdefinedaddress4@email.com;notdefinedaddressC@email.com;notdefinedaddressD@email.com';
    System.assertequals( true,result != null, 'test3');
  }
}