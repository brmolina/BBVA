@isTest
/*---------------------------------------------------------
    Author:
    Company:
    Description:   Test Class  PrePhoneCase

    History:
    <Date>          <Author>                <Description>
                                              Initial version
-----------------------------------------------------------*/
private class SER_PrePhoneCase_TEST {
  /*---------------------------------------------------------
    Description:   Test Class  testMethodOne
  -----------------------------------------------------------*/
  @isTest static void testMethodOne() {
    Case caso;
    caso = new Case();
    insert caso;

    SER_PrePhoneCase serPre;
    serPre = new SER_PrePhoneCase(new ApexPages.StandardController(caso));
    serPre.actionRedirect();
    caso = serPre.myCase;
    System.assertEquals(caso, caso, 'SER_PrePhoneCase_TEST.testMethodOne');
  }

  /*---------------------------------------------------------
    Description:   Test Class  testMethodtwo
  -----------------------------------------------------------*/
  @isTest static void testMethodtwo() {
    Id userID;
    userID = UserInfo.getUserId();

    Case caso;
    caso = new Case();
    insert caso;

    SER_MailingGroup__c testMG01;
    testMG01 = new SER_MailingGroup__c(SER_MailingGroup__c = 'Customer & Claim Support',SER_DefaultMailbox__c = 'Email Claim Support & Investigations',SER_User__c = userID);
    insert testMG01;

    SER_PrePhoneCase serPre;
    serPre = new SER_PrePhoneCase(new ApexPages.StandardController(caso));
    serPre.presetMailingGroup();

    System.assertEquals(EncodingUtil.urlEncode(testMG01.SER_MailingGroup__c, 'UTF-8'), serPre.stMailgroup, 'Error');
  }

  /*---------------------------------------------------------
    Description:   Test Class  testMethodThree
  -----------------------------------------------------------*/
  @isTest static void testMethodthree() {
    User usuario;
    usuario = new User();
    usuario.FirstName = 'TEST';
    usuario.LastName = 'USER';
    usuario.ProfileId = SER_ProfileUtils.getProfileId('Service Client Service Manager GM');
    usuario.Lastname='LastNameTest';
    usuario.Alias = 'Alias';
    usuario.Email = 'Alias@accenture.com';
    usuario.username= SER_TestUtils.createUserName() + 'test@accenture.com';
    usuario.CommunityNickname = 'ComunityNickNameTest2';
    usuario.EmailEncodingKey = 'UTF-8';
    usuario.Timezonesidkey='Europe/London';
    usuario.Localesidkey ='en_US';
    usuario.languagelocalekey='en_US';
    usuario.ID_User__c = string.valueOf(system.now());
    usuario.Asset_Class__c = 'FI;FX;EQ';
    insert usuario;

    Case caso;
    caso = new Case();
    insert caso;

    System.runAs(usuario) {
      SER_PrePhoneCase serPre;
      serPre = new SER_PrePhoneCase(new ApexPages.StandardController(caso));
      serPre.stMailgroup = 'Customer & Claim Support';
      serPre.stOutboundMailbox = 'Email Claim Support & Investigations';
      serPre.actionRedirect();
      caso = serPre.myCase;
      System.assertEquals(caso, caso, 'SER_PrePhoneCase_TEST.testMethodOne');
    }
  }
}