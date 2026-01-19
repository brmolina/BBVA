/*---------------------------------------------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Class to store test helper methods, like creating dummy data or execution control.

    History:
    <Date>          <Author>                <Description>
    16/03/1993		Juan Carlos Terrón		Initial Version
----------------------------------------------------------------------------------------------------*/
public with sharing class SER_TestUtils {
  /*Cuenta vacía*/
  private static final Account NULL_ACCOUNT;
  /*Caso vacío*/
  private static final Case NULL_CASE;
  /*Contacto vacío*/
  private static final Contact NULL_CONTACT;
  /*Case Type para pruebas */
  private static final string TYPE_ACCESO = 'ACCESO';
  /*Case Type para pruebas */
  private static final string TYPE_GM_OTR = 'Otros';
  /*CONSTANTE 'TEST Subject'*/
  private static final string SUBJECT = 'TEST Subject';

  private SER_TestUtils() {
  }

  /*---------------------------------------------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Method to create a Dummy user with a profile given by parameter.

    History:
    <Date>          <Author>                <Description>
    16/03/1993		Juan Carlos Terrón		Initial Version
  ----------------------------------------------------------------------------------------------------*/
  public static User ddCreateUser(String profileName,Boolean forInsert) {
    final User usuario = new User();
    usuario.FirstName = 'TEST';
    usuario.LastName = 'USER';
    if(Test.isRunningTest()) {  //NOSONAR
      usuario.ProfileId = UserInfo.getProfileId();
    } else {
      usuario.ProfileId = SER_ProfileUtils.getProfileId(profileName);
    }

    usuario.Lastname='LastNameTest';
    usuario.Alias = 'Alias';
    usuario.Email = 'Alias@accenture.com';
    usuario.username= createUserName()+'test@accenture.com';
    usuario.CommunityNickname = 'ComunityNickNameTest2';
    usuario.EmailEncodingKey = 'UTF-8';
    usuario.Timezonesidkey='Europe/London';
    usuario.Localesidkey ='en_US';
    usuario.languagelocalekey='en_US';
    usuario.ID_User__c = string.valueOf(system.now());
    usuario.Asset_Class__c = 'FI;FX;EQ';

    if(forInsert) {
      insert usuario;
    }
    return usuario;
  }

  /*---------------------------------------------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Method to create a user name depending on the creation date.

    History:
    <Date>          <Author>                <Description>
    16/03/1993		Juan Carlos Terrón		Initial Version
  ----------------------------------------------------------------------------------------------------*/
  public static string createUserName() {
    /*Wrapping*/
    return 'test_' + DateTime.now().format('HHmmssSSS');
  }

  /*---------------------------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Method to create a dummy Account.

    History:
    <Date>          <Author>                <Description>
    16/03/1993		Juan Carlos Terrón		Initial Version
  -----------------------------------------------------------------------------------*/
  public static Account ddCreateAccount(Boolean forInsert) {
    Account newAccount = new Account();
    try {
      newAccount.Name = 'newAccount';
      newAccount.Asset_Class__c = 'TEST Asset Class';

      if (forInsert) {
        insert newAccount;
      }
    } catch(Exception error) {
      System.debug('JCT - ddCreateAccount : '+error);
      CIB_LogUtils.create_Log(error, 'ddCreateAccount');
      newAccount = NULL_ACCOUNT;
    }
    return newAccount;
  }

  /*---------------------------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Method to create a dummy Case.

    History:
    <Date>          <Author>                <Description>
    16/03/1993		Juan Carlos Terrón		Initial Version
  -----------------------------------------------------------------------------------*/
  public static Case ddCreateCase(Boolean forInsert) {
    Case newCase = new Case();
    try {
      if(forInsert) {
        insert newCase;
      }
    } catch(Exception error) {
      System.debug('JCT - ddCreateCase : '+error);
      CIB_LogUtils.create_Log(error, 'ddCreateCase');
      newCase = NULL_CASE;
    }
    return newCase;
  }

  /*---------------------------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Wrapping.

    History:
    <Date>          <Author>                <Description>
    16/03/1993		Juan Carlos Terrón		Initial Version
  -----------------------------------------------------------------------------------*/
  public static Case ddUpsertCase(Case caso) {
    /*Wrapping*/
    return null;
  }

  /*---------------------------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   CONTACT DUMMY DATA.

    History:
    <Date>          <Author>                <Description>
    16/03/1993		Juan Carlos Terrón		Initial Version
  -----------------------------------------------------------------------------------*/
  public static Contact ddCreateContact(Boolean forInsert) {
    Contact newContact = new Contact();
    try {
      newContact.FirstName = 'FirstName';
      newContact.Lastname = 'LastName';
      newContact.Phone = '000000000';
      newContact.AccountId=ddCreateAccount(true).Id;
      newContact.RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName('Contact','SER_Service_Contact_Global_Markets');

      if(forInsert) {
        insert newContact;
      }
    } catch(Exception error) {
      System.debug('JCT - ddCreateContact : '+error);
      CIB_LogUtils.create_Log(error, 'ddCreateContact');
      newContact = NULL_CONTACT;
    }

    return newContact;
  }
}