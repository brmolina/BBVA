/******************************************************************************************************************************************************
 *   @author: GlobalDesktop - APC
 *   @Class: FilteredLookUpControllerTest
 *   @Description:  FilteredLookUpController - Tests


 *   @Versions:
        v1 - 2019/02/XX - Initial version
 ************************************************************************************************************/
@isTest
public class FilteredLookUpControllerTest {

  /**
   * @author Global Desktop
   * @description declaracion de variable
   */
  final static private String TESTSTRING = 'Test';
  /*
   * @Description Clase de test para el filtered lookup de usuarios
   * @Author Global
   */
  @isTest
  public static void testingCustomLookUpUserController() {
    final String profile = createProfile();
    final User user = createUser(profile, true, true, true, 'One to One',10);
    user.FirstName = 'fetchLookUpValuesEmailTest';
    insert user;
    Test.startTest();
    final List<User> returnListUser = (List<User>) FilteredLookUpController.fetchLookUpValuesEmail('fetchLookUpValuesEmailTest', 'User');
    
    system.runAs(user) {
      final User returnUser = (User) FilteredLookUpController.getLookupValue('User', user.Id);
      system.debug(returnUser);
    }
    Test.stopTest();
    System.assertEquals( returnListUser.size(), 1,'Correcto' );
  }

  /*
   * @Description Clase de test para el filtered lookup de contactos
   * @Author Global
   */
  @isTest
  public static void testingCustomLookUpContactController() {
    final DES_UtilTestClass util = new DES_UtilTestClass();
    final Account acc = util.createClient();
    insert acc;
    final Contact contact = util.createContact(acc);
    contact.FirstName = 'testingCustomLookUpContactController';
    insert contact;
    Test.startTest();
    Contact returnContact = (Contact) FilteredLookUpController.getRelatedAccount('Contact', contact.Id);
    final Account returnAccount = (Account) FilteredLookUpController.getRelatedAccount('Account', acc.Id);
    system.debug(returnAccount);
    final List<Contact> returnListContact = (List<Contact>) FilteredLookUpController.fetchLookUpValuesEmail('testingCustomLookUpContactController', 'Contact');
    returnListContact.add(returnContact);
    returnContact = (Contact) FilteredLookUpController.getLookupValue('Contact', contact.Id);
    system.debug(returnContact);
    Test.stopTest();
    System.assertEquals( returnListContact.size(), 1,'Correcto' );
  }


  /*
   * @Description Clase de test para el filtered lookup de opps privilegiadas
   * @Author David R.
   */
    @isTest
    public static void testLookUpDisclosureController() {
        final DES_UtilTestClass util = new DES_UtilTestClass();
        final Account acc = util.createClient();
        insert acc;
        final Opportunity opp = util.createOpportunity(acc);
        opp.disclosure_info_type__c = Label.DES_OP_CONFIDENTIAL;
        insert opp;
        Test.startTest();
        final List<Opportunity> returnList = (List<Opportunity>) FilteredLookUpController.fetchLookUpValuesDisclosure('Test Opportunity', 'Opportunity', Label.DES_OP_CONFIDENTIAL);
        Test.stopTest();
        System.assertEquals(returnList.size(), 1, 'disclosure');
    }

      /*
  * @Description Clase de test para el filtered lookup de opps
  * @Author David R.
  */
    @isTest
    public static void testLookUpDisclosureController1() {
        final DES_UtilTestClass util = new DES_UtilTestClass();
        final Account acc = util.createClient();
        insert acc;
        final Opportunity opp = util.createOpportunity(acc);
        opp.disclosure_info_type__c = Label.DES_OP_Inside;
        insert opp;
        Test.startTest();
        final List<Opportunity> returnList = (List<Opportunity>) FilteredLookUpController.fetchLookUpValuesDisclosure('Test Opportunity', 'Opportunity', '');
        Test.stopTest();
        System.assertEquals(returnList.size(), 1, 'disclosure');
    }

  /*
   * @Description Clase de test para el filtered lookup de product
   * @Author David R.
   */
  @isTest
  public static void testLookUpFamilyController() {
    final DES_UtilTestClass util = new DES_UtilTestClass();
    final Product2 prod = util.createProduct('Test product');
    prod.Family = 'GTB';
    insert prod;
    Test.startTest();
    final List<Product2> returnList = (List<Product2>) FilteredLookUpController.fetchLookUpValuesFamily(TESTSTRING, 'Product2', 'GTB');
    Test.stopTest();
    System.assertEquals(returnList.size(), 1,'family');
  }

  /*
   * @Description Clase de test para el filtered lookup de product
   * @Author David R.
   */
  @isTest
  public static void testLookUpFamilyController1() {
    final DES_UtilTestClass util = new DES_UtilTestClass();
    final Product2 prod = util.createProduct('Test product');
    prod.Family = 'GTB';
    insert prod;
    Test.startTest();
    final List<Product2> returnList = (List<Product2>) FilteredLookUpController.fetchLookUpValuesFamily(TESTSTRING, 'Product2', '');
    Test.stopTest();
    System.assertEquals(returnList.size(), 1,'family');
  }

  /*
   * @Description Clase de test para el gtInstance
   * @Author David R.
   */
  @isTest
  public static void testLookUpgtInstance() {
    Test.startTest();
    final FilteredLookUpController inst = FilteredLookUpController.gtInstance();
    Test.stopTest();
    system.assertNotEquals(inst, null, 'notnull');
  }


  //Nuevo perfil
  private static String createProfile() {
    return userinfo.getProfileId();
  }

  //Nuevo usuario
  private static User createUser(String profileTest, boolean high, boolean medium, boolean low, String notType, Integer ctrlnum) {
    final User userTest = new User();
    userTest.ProfileId = profileTest;
    userTest.FirstName = 'User Name Test' + ctrlnum;
    userTest.LastName = 'User Last Name Test' + ctrlnum;
    userTest.Email = 'useremail' + ctrlnum + '@test.comm';
    userTest.FederationIdentifier = 'TEST' + ctrlnum;
    userTest.ID_User__c = 'TEST' + ctrlnum;
    userTest.username = 'useremail' + ctrlnum + '@test.comm';
    userTest.CommunityNickname = 'ComunityNickNameTest2' + ctrlnum;
    userTest.almd__alert_notification_type__c = notType;
    User userTestReturn = new User();
    userTestReturn = createUser2(userTest, high, medium, low);
    System.debug('Valor de userTestReturn: ' + userTestReturn);
    return userTestReturn;
  }

  /*
   * @Description Clase de test para el filtered lookup de usuarios
   * @Author Global
   */
  private static User createUser2(User user, boolean high, boolean medium, boolean low) {
    user.EmailEncodingKey = 'UTF-8';
    user.Timezonesidkey ='Europe/London';
    user.Localesidkey ='en_US';
    user.languagelocalekey ='en_US';
    user.Alias = 'ATest';
    user.almd__notification_priority_high_type__c = high;
    user.almd__notification_priority_low_type__c = low;
    user.almd__notification_priority_med_type__c = medium;
    return user;
  }
}