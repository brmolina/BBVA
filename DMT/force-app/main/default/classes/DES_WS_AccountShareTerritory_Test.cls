@SuppressWarnings('sf:AvoidUsingSeeAllData')

/*
 *
 *  Global Desktop
 *
**/
 @isTest
public class DES_WS_AccountShareTerritory_Test {

  /*
   *
   *  Global Desktop
   *
  **/
	@isTest
	public static void testOK1() {

		test.startTest();

		RestRequest req;
    req = new RestRequest();
		RestResponse res;
    res = new RestResponse();
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final String profileTest = utilTestClass.createProfile();
    final User userTest = utilTestClass.createUser(profileTest);
    insert userTest;
		req.requestURI = '/services/apexrest/accShareTerritory';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
    idJobResultado = DES_WS_AccountShareTerritory.runAccShareTerritory();
		Boolean response;
    response = idJobResultado == null ? false : true;
    System.assert(true, response);
		System.abortJob(idJobResultado);
		test.stopTest();
	}

  /*
   *
   *  Global Desktop
   *
  **/
  @isTest
	public static void testOKBatchUserTerritory1() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final String profileTest = utilTestClass.createProfile();
    final User userTest = utilTestClass.createUser(profileTest);
    insert userTest;
		Id idJobResultado;
    idJobResultado = Database.executeBatch(new UserToTerritoryBatch(), 2000);
		Boolean response;
    response = idJobResultado == null ? false : true;
    System.assert(true, response);
		System.abortJob(idJobResultado);
	}

  /*
   *
   *  Global Desktop
   *
  **/
  @isTest
	public static void testOKBatchAccTerritory1() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final String profileTest = utilTestClass.createProfile();
    final User userTest = utilTestClass.createUser(profileTest);
    insert userTest;
		Id idJobResultado;
    idJobResultado = Database.executeBatch(new AccountTerritoryBatch(), 2);
		Boolean response;
    response = idJobResultado == null ? false : true;
    System.assert(true, response);
		System.abortJob(idJobResultado);
	}

}