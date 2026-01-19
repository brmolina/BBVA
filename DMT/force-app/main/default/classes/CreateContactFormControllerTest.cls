/***
 *   @author: GlobalDesktop - JASS
 *   @Class: Test class for CreateContactFormController class
 *   @Description:
 *   @Versions:
 *	2019/03/21 - Initial version
 */

@isTest
public class CreateContactFormControllerTest {


  /*Declaracion variable global*/
  private final static String DMLUPDATE = 'Update';
  /*Declaracion variable global*/
  private final static String DMLINSERT = 'Insert';

  /*
   * @author Global Desktop
   * Description: accGroup
   */
  static Account accGroup {
    get {
      if ( accGroup == null ) {
        final List<Account> accList = [SELECT id, DES_Country_Client__c, Name FROM Account WHERE Name = 'Grupo_A_ES' LIMIT 1];
        accGroup = accList.get(0);
      }
      return accGroup;
    }
    set;
  }

  /*
   * @author Global Desktop
   * Description: conGroup
   */
  static Contact conGroup {
    get {
      if ( conGroup == null ) {
        final List<Contact> conList = [SELECT id, LastName, Email_ExternalID__c, OwnerId FROM Contact WHERE LastName = 'Dummy' LIMIT 1];
        conGroup = conList.get(0);
      }
      return conGroup;
    }
    set;
  }

  /*
   * @author Global Desktop
   * Description: usTest1
   */
  static User usTest1 {
    get {
      if ( usTest1 == null ) {
        final List<User> usList = [SELECT id, FirstName, LastName FROM User WHERE FirstName = 'userName1 Test' LIMIT 1];
        usTest1 = usList.get(0);
      }
      return usTest1;
    }
    set;
  }

  /*
   * @author Global Desktop
   * Description: usTest2
   */
  static User usTest2 {
    get {
      if ( usTest2 == null ) {
        final List<User> usList = [SELECT id, FirstName, LastName FROM User WHERE FirstName = 'userName2 Test' LIMIT 1];
        usTest2 = usList.get(0);
      }
      return usTest2;
    }
    set;
  }


  /*
   * @author Global Desktop
   * Description: dataNeeded
   */
  @testSetup
  public static void dataNeeded() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

    final String profileTest = [SELECT Id, Name FROM Profile WHERE Name = 'Desktop Integration' LIMIT 1].Id;
    final User userTest1 = utilTestClass.createUser(profileTest);
    userTest1.FirstName = 'userName1 Test';
    insert userTest1;

    final User userTest2 = utilTestClass.createUser(profileTest,'NickAlias@t.com');
    userTest2.FirstName = 'userName2 Test';
    insert userTest2;

    final Account accGroup2 = utilTestClass.createClient();
    accGroup2.Name = 'Grupo_A_ES';
    accGroup2.DES_BBVA_Segmentation__c = 'B';
    accGroup2.DES_Structure_Type__c = 'Group';
    accGroup2.DES_Country_Client__c = 'ES';
    insert accGroup2;

    final Contact conGroup2 = utilTestClass.createContact(accGroup2);
    conGroup2.LastName = 'Dummy';
    conGroup2.Email_ExternalID__c = 'dummy' + DateTime.now().getTime() + '@dummy.es';
    conGroup2.DES_Department__c  = 'Finance';
    conGroup2.DES_Scope__c = 'SL; Global';
    conGroup2.OwnerId = userTest1.id;
    insert conGroup2;
  }

  /*
   * @author Global Desktop
   * Description: getContactDataTest01
   */
  @isTest
  public static void getContactDataTest01() {
    //Data needed

    //Test
    test.startTest();
    final CreateContactFormController.WrapperContact testCon = CreateContactFormController.getContactData(conGroup.id);
    test.stopTest();

    //Verify the expressions are the same
    System.assertEquals(testCon.contact.Email_ExternalID__c,conGroup.Email_ExternalID__c, 'Correcto');

  }

  /*
   * @author Global Desktop
   * Description: getContactDataTest02
   */
  @isTest
  public static void getContactDataTest02() {
    //Data needed

    //Test
    test.startTest();
    delete conGroup;
    final CreateContactFormController.WrapperContact testCon = CreateContactFormController.getContactData(conGroup.id);
    test.stopTest();

    //Verify the expressions are the same
    System.assertEquals(testCon.contact.Email_ExternalID__c,null, 'Correcto');

  }

  /*
   * @author Global Desktop
   * Description: currentDomainTest
   */
  @isTest
  public static void currentDomainTest() {
    //Data needed

    //Test
    test.startTest();
    final String testDomain = CreateContactFormController.currentDomain();
    test.stopTest();

    //Verify the expressions are the same
    System.assertNotEquals(testDomain,'');
  }

  /*
   * @author Global Desktop
   * Description: getCreateContactTest01
   */
  @isTest
  public static void getCreateContactTest01() {
    //Data needed
    final String attributes = JSON.serialize(conGroup);
    final String contactOwnerId = usTest2.id;

    //Test
    test.startTest();
    final CreateContactFormController.WrResponse testResponse = CreateContactFormController.createContact(attributes,DMLUPDATE,contactOwnerId);
    test.stopTest();


    //Verify the expressions are the same
    System.assertNotEquals(testResponse,null);
  }

  /*
   * @author Global Desktop
   * Description: getCreateContactTest02
   */
  @isTest
  public static void getCreateContactTest02() {
    //Data needed
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final Contact conGroup2 = utilTestClass.createContact(accGroup);
    conGroup2.LastName = 'Dummy2';
    conGroup2.Email_ExternalID__c = conGroup.Email_ExternalID__c;
    conGroup2.DES_Department__c  = 'Finance';
    conGroup2.DES_Scope__c = 'SL; Global';
    //conGroup2.OwnerId = usTest1.id;
    final String attributes = JSON.serialize(conGroup2);
    final String contactOwnerId = usTest1.id;

    //Test
    System.runAs(usTest1) {
      test.startTest();
      final CreateContactFormController.WrResponse testResponse = CreateContactFormController.createContact(attributes,DMLINSERT,contactOwnerId);
      test.stopTest();

      //Verify the expressions are the same
      System.assertEquals(testResponse.type,'Duplicado', 'Correcto');
    }
  }


  /*
   * @author Global Desktop
   * Description: getCreateContactTest03
   */
  @isTest
  public static void getCreateContactTest03() {
    //Data needed
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final Contact conGroup2 = utilTestClass.createContact(accGroup);
    conGroup2.LastName = 'Dummy2';
    conGroup2.Email_ExternalID__c = conGroup.Email_ExternalID__c;
    conGroup2.DES_Department__c  = 'Finance';
    conGroup2.DES_Scope__c = 'SL; Global';
    //conGroup2.OwnerId = usTest1.id;
    final String attributes = JSON.serialize(conGroup2);
    final String contactOwnerId = usTest1.id;

    //Test
    test.startTest();
    final CreateContactFormController.WrResponse testResponse = CreateContactFormController.createContact(attributes,DMLUPDATE,contactOwnerId);
    test.stopTest();

    //Verify the expressions are the same
    System.assertNotEquals(testResponse,null);
  }
  /*
   * @author Global Desktop
   * Description: handleInitValues01
   */
  @isTest
  public static void handleInitValues01() {
    CreateContactFormController ccForm = CreateContactFormController.getInstance();

    //Test
    test.startTest();
    final CreateContactFormController.WrResponse testResponse = CreateContactFormController.handleInitValues(accGroup.Id);
    test.stopTest();


    //Verify the expressions are the same
    System.assertEquals(testResponse.accId, accGroup.Id, 'Same Id');
  }
  /*
   * @author Global Desktop
   * Description: handleInitValues02
   */
  @isTest
  public static void handleInitValues02() {
    CreateContactFormController ccForm = CreateContactFormController.getInstance();
    UpdateContactDML withSharing = UpdateContactDML.getInstance();
    NewContactDML withoutSharing = NewContactDML.getInstance();

    //Test
    test.startTest();
    final CreateContactFormController.WrResponse testResponse = CreateContactFormController.handleInitValues(null);
    test.stopTest();


    //Verify the expressions are the same
    System.assertEquals(testResponse.accId, null, 'Expected null ok');
  }
}