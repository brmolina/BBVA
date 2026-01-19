/**
   Name:            Batch_ContactScopeTest
   Description:
   Test Class:      Batch_ContactScope
 */@isTest
public class Batch_ContactScopeTest {

  /* Declarando variable */
  private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
  /* Declarando variable */
  public static final String BECVALUE = 'B';
  /* Declarando variable */
  public static final String SUBSIDIARYVALUE = 'Subsidiary';
  /* Declarando variable */
  public static final String DUMMYVALUE = 'dummy';
  /* Declarando variable */
  public static final String DUMMYEMAIL = '@dummy.es';
  /* Declarando variable */
  public static final String FINANCEVALUE = 'Finance';

  @testSetup
  /*
   * @author Global Desktop
   * @Description establece los registros necesarios
   */
  public static void setupRows() {       //NOSONAR
    //ACCOUNTS
    List<Account> lstAccounts;
    lstAccounts = new List<Account>();

    final Account accGroup = utilTestClass.createClient();
    accGroup.Name = 'Grupo_A_ES';
    accGroup.DES_BBVA_Segmentation__c = BECVALUE;
    accGroup.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
    accGroup.DES_Country_Client__c = 'ES';
    lstAccounts.add(accGroup);
    final Account accGroup2 = utilTestClass.createClient();
    accGroup2.Name = 'Grupo_B_MX';
    accGroup2.DES_BBVA_Segmentation__c = 'C';
    accGroup2.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
    accGroup2.DES_Country_Client__c = 'MX';
    lstAccounts.add(accGroup2);
    final Account accGroup3 = utilTestClass.createClient();
    accGroup3.Name = 'Grupo_C_ES';
    accGroup3.DES_BBVA_Segmentation__c = BECVALUE;
    accGroup3.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
    accGroup3.DES_Country_Client__c = 'ES';
    lstAccounts.add(accGroup3);
    insert lstAccounts;
    lstAccounts.clear();

    final Account accMatrix = utilTestClass.createClient();
    accMatrix.Name = 'Matriz_A_ES';
    accMatrix.DES_BBVA_Segmentation__c = BECVALUE;
    accMatrix.DES_Structure_Type__c = SUBSIDIARYVALUE;
    accMatrix.DES_Entity_Hierarchy__c = 'S';
    accMatrix.DES_Main_Parent__c = accGroup.Id;
    accMatrix.DES_Country_Client__c = 'ES';
    lstAccounts.add(accMatrix);
    final Account accFilial = utilTestClass.createClient();
    accFilial.Name = 'Filial_A_JP';
    accFilial.DES_BBVA_Segmentation__c = BECVALUE;
    accFilial.DES_Structure_Type__c = SUBSIDIARYVALUE;
    accFilial.DES_Entity_Hierarchy__c = 'N';
    accFilial.DES_Main_Parent__c = accGroup.Id;
    accFilial.DES_Country_Client__c = 'JP';
    lstAccounts.add(accFilial);
    final Account accMatrix2 = utilTestClass.createClient();
    accMatrix2.Name = 'Matrix_B_FR';
    accMatrix2.DES_BBVA_Segmentation__c = 'C';
    accMatrix2.DES_Structure_Type__c = SUBSIDIARYVALUE;
    accMatrix2.DES_Entity_Hierarchy__c = 'S';
    accMatrix2.DES_Main_Parent__c = accGroup2.Id;
    accMatrix2.DES_Country_Client__c = 'FR';
    lstAccounts.add(accMatrix2);
    final Account accFilial2 = utilTestClass.createClient();
    accFilial2.Name = 'Filial_B_SL';
    accFilial2.DES_BBVA_Segmentation__c = 'C';
    accFilial2.DES_Structure_Type__c = SUBSIDIARYVALUE;
    accFilial2.DES_Entity_Hierarchy__c = 'N';
    accFilial2.DES_Main_Parent__c = accGroup2.Id;
    accFilial2.DES_Country_Client__c = 'SL';
    lstAccounts.add(accFilial2);
    insert lstAccounts;


    lstAccounts.clear();
    final Account accGroupMatrix = new Account();
    accGroupMatrix.DES_Client_Matrix__c = accMatrix.Id;
    accGroupMatrix.Id = accGroup.Id;
    lstAccounts.add(accGroupMatrix);
    final Account accGroup2Matrix = new Account();
    accGroup2Matrix.DES_Client_Matrix__c = accMatrix2.Id;
    accGroup2Matrix.Id = accGroup2.Id;
    lstAccounts.add(accGroup2Matrix);
    update lstAccounts;

    //CONTACTS:
    final List<Account> lstAccountsACR = new List<Account> {accGroup,accGroup2,accGroup3,accMatrix,accMatrix2,accFilial,accFilial2};
    crearContsRel(lstAccountsACR);
  }

  /*
   * @author Global Desktop
   * @Description Method auxiliar parar crear registros
   */
  private static void crearContsRel(List<Account> lstAccountsACR) {       //NOSONAR - is related to testSetup and the long is lower than 100lines
    Integer cont = 1;
    List<Contact> lstContacts;
    lstContacts = new List<Contact>();
    final Contact conGroup = utilTestClass.createContact(lstAccountsACR[0]);
    conGroup.LastName = DUMMYVALUE;
    conGroup.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conGroup.DES_Department__c  = FINANCEVALUE;
    conGroup.DES_Scope__c = 'SL; Global';
    lstContacts.add(conGroup);
    final Contact conGroup1 = utilTestClass.createContact(lstAccountsACR[0]);
    conGroup1.LastName = DUMMYVALUE;
    conGroup1.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conGroup1.DES_Department__c  = FINANCEVALUE;
    conGroup1.DES_Scope__c = 'SL; Global';
    lstContacts.add(conGroup1);
    final Contact conGroup2 = utilTestClass.createContact(lstAccountsACR[0]);
    conGroup2.LastName = DUMMYVALUE;
    conGroup2.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conGroup2.DES_Department__c  = FINANCEVALUE;
    conGroup2.DES_Scope__c = 'SL; Global';
    lstContacts.add(conGroup2);
    final Contact conGroupExtra = utilTestClass.createContact(lstAccountsACR[0]);
    conGroupExtra.LastName = DUMMYVALUE;
    conGroupExtra.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conGroupExtra.DES_Department__c  = FINANCEVALUE;
    conGroupExtra.DES_Scope__c = 'SL';
    lstContacts.add(conGroupExtra);
    final Contact conMatrix = utilTestClass.createContact(lstAccountsACR[3]);
    conMatrix.LastName = DUMMYVALUE;
    conMatrix.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conMatrix.DES_Department__c  = FINANCEVALUE;
    conMatrix.DES_Scope__c = 'SL; Compass';
    lstContacts.add(conMatrix);
    final Contact conMatrixExtra = utilTestClass.createContact(lstAccountsACR[3]);
    conMatrixExtra.LastName = DUMMYVALUE;
    conMatrixExtra.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conMatrixExtra.DES_Department__c  = FINANCEVALUE;
    conMatrixExtra.DES_Scope__c = 'SL';
    lstContacts.add(conMatrixExtra);
    final Contact conMatrixB = utilTestClass.createContact(lstAccountsACR[4]);
    conMatrixB.LastName = DUMMYVALUE;
    conMatrixB.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conMatrixB.DES_Department__c  = FINANCEVALUE;
    conMatrixB.DES_Scope__c = 'SL; Global; FR';
    lstContacts.add(conMatrixB);
    final Contact conMatrixBExtra = utilTestClass.createContact(lstAccountsACR[4]);
    conMatrixBExtra.LastName = DUMMYVALUE;
    conMatrixBExtra.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conMatrixBExtra.DES_Department__c  = FINANCEVALUE;
    conMatrixBExtra.DES_Scope__c = 'SL; FR';
    lstContacts.add(conMatrixBExtra);
    final Contact conFilial = utilTestClass.createContact(lstAccountsACR[5]);
    conFilial.LastName = DUMMYVALUE;
    conFilial.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conFilial.DES_Department__c  = FINANCEVALUE;
    conFilial.DES_Scope__c = 'SL; FR';
    lstContacts.add(conFilial);
    final Contact conFilialExtra = utilTestClass.createContact(lstAccountsACR[5]);
    conFilialExtra.LastName = DUMMYVALUE;
    conFilialExtra.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conFilialExtra.DES_Department__c  = FINANCEVALUE;
    conFilialExtra.DES_Scope__c = 'SL';
    lstContacts.add(conFilialExtra);
    final Contact conFilialExtra1 = utilTestClass.createContact(lstAccountsACR[5]);
    conFilialExtra1.LastName = DUMMYVALUE;
    conFilialExtra1.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conFilialExtra1.DES_Department__c  = FINANCEVALUE;
    conFilialExtra1.DES_Scope__c = 'SL';
    lstContacts.add(conFilialExtra1);
    final Contact conFilialExtra2 = utilTestClass.createContact(lstAccountsACR[5]);
    conFilialExtra2.LastName = DUMMYVALUE;
    conFilialExtra2.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conFilialExtra2.DES_Department__c  = FINANCEVALUE;
    conFilialExtra2.DES_Scope__c = 'SL';
    lstContacts.add(conFilialExtra2);
    final Contact conFilialB = utilTestClass.createContact(lstAccountsACR[6]);
    conFilialB.LastName = DUMMYVALUE;
    conFilialB.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conFilialB.DES_Department__c  = FINANCEVALUE;
    conFilialB.DES_Scope__c = 'SL; FR';
    lstContacts.add(conFilialB);
    final Contact conFilialBExtra = utilTestClass.createContact(lstAccountsACR[6]);
    conFilialBExtra.LastName = DUMMYVALUE;
    conFilialBExtra.Email_ExternalID__c = DUMMYVALUE + cont++ + DUMMYEMAIL;
    conFilialBExtra.DES_Department__c  = FINANCEVALUE;
    conFilialBExtra.DES_Scope__c = 'SL';
    lstContacts.add(conFilialBExtra);

    insert lstContacts;

    final List<AccountContactRelation> lstACR = new List<AccountContactRelation>();
    final AccountContactRelation acr1 = new AccountContactRelation();
    acr1.AccountId = lstAccountsACR[1].Id;
    acr1.ContactId = conGroup.Id;
    lstACR.add(acr1);
    final AccountContactRelation acr2 = new AccountContactRelation();
    acr2.AccountId = lstAccountsACR[4].Id;
    acr2.ContactId = conGroup1.Id;
    lstACR.add(acr2);
    final AccountContactRelation acr3 = new AccountContactRelation();
    acr3.AccountId = lstAccountsACR[2].Id;
    acr3.ContactId = conGroup2.Id;
    lstACR.add(acr3);
    final AccountContactRelation acr4 = new AccountContactRelation();
    acr4.AccountId = lstAccountsACR[4].Id;
    acr4.ContactId = conFilial.Id;
    lstACR.add(acr4);
    final AccountContactRelation acr5 = new AccountContactRelation();
    acr5.AccountId = lstAccountsACR[3].Id;
    acr5.ContactId = conFilialBExtra.Id;
    lstACR.add(acr5);
    final AccountContactRelation acr6 = new AccountContactRelation();
    acr6.AccountId = lstAccountsACR[6].Id;
    acr6.ContactId = conFilialExtra.Id;
    lstACR.add(acr6);
    final AccountContactRelation acr7 = new AccountContactRelation();
    acr7.AccountId = lstAccountsACR[1].Id;
    acr7.ContactId = conFilialExtra1.Id;
    lstACR.add(acr7);
    final AccountContactRelation acr8 = new AccountContactRelation();
    acr8.AccountId = lstAccountsACR[2].Id;
    acr8.ContactId = conFilialExtra2.Id;
    lstACR.add(acr8);
    Insert lstACR;
  }


  /******************************************************************************************************************************************************
  *   @author: GlobalDesktop - APC
  *   @Class: scopeGroupGlobal
  *   @Description:  run batch Batch_ContactScope


  *   @Versions:
      v1 - 2019/02/05 - Initial version
  ******************************************************************************************************************************************************/
  @isTest
  public static void batchContactScope() {
    Test.startTest();

    List<Contact> lstContacts = [SELECT Name, DES_Scope__c FROM Contact LIMIT 500];
    System.System.debug('::::ANTES: - ' + JSON.serialize(lstContacts));

    final Id jobContactScope = Database.executeBatch(new Batch_ContactScope(), 200);

    lstContacts = [SELECT Name, DES_Scope__c FROM Contact LIMIT 500];
    System.System.debug('::::DESPUES: - ' + JSON.serialize(lstContacts));

    Boolean response;
    response = jobContactScope == null ? false : true;
    System.asserT( response, 'Correcto');
    Test.stopTest();
  }

}