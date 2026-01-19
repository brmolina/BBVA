@isTest
public class DES_WS_RevenuesBookingTest {
	@isTest
	public static void testOK1() {
		DES_UtilTestClass testClass = new DES_UtilTestClass();
		Test.startTest();
		Account acc = testClass.createClient();
		insert acc;
		String paisEspana = 'ESPAÑA';
		List<DES_Booking__c> listBooking = new List<DES_Booking__c>();
		//Funcion createBooking(Account acc, String country, String region, Double revenues, String type, String year)
		DES_Booking__c boo1 = testClass.createBooking(acc, paisEspana, paisEspana, 125.12, 'GM', '2017');
		listBooking.add(boo1);
		DES_Booking__c boo2 = testClass.createBooking(acc, paisEspana, paisEspana, 12.06, 'GM', '2018');
		listBooking.add(boo2);
		DES_Booking__c boo3 = testClass.createBooking(acc, paisEspana, paisEspana, 13.24, 'IBF', '2017');
		listBooking.add(boo3);
		DES_Booking__c boo4 = testClass.createBooking(acc, paisEspana, paisEspana, 125.12, 'CF', '2017');
		listBooking.add(boo4);
		DES_Booking__c boo5 = testClass.createBooking(acc, paisEspana, paisEspana, 12.06, 'CO', '2018');
		listBooking.add(boo5);
		DES_Booking__c boo51 = testClass.createBooking(acc, paisEspana, paisEspana, 12.06, 'CO', '2017');
		listBooking.add(boo51);
		DES_Booking__c boo6 = testClass.createBooking(acc, paisEspana, paisEspana, 13.24, 'GL', '2017');
		listBooking.add(boo6);
		insert listBooking;
		Id batchInstanceId = Database.executeBatch(new Batch_Calcular_YOY_Revenues(), 2000);
		System.assertNotEquals(batchInstanceId,null,'error');
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/yoyByFamProducts';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_RevenuesBooking.runBookingBatch();
		Boolean response;
        response = idJobResultado == null ? false : true;
        System.assertEquals(true, response);
		System.abortJob(idJobResultado);
		Test.stopTest();
	}
	@isTest
	public static void testOK2() {
		DES_UtilTestClass testClass = new DES_UtilTestClass();
		Test.startTest();
		Account acc = testClass.createClient();
		insert acc;
		String paisEspana = 'ESPAÑA';
		List<DES_Booking__c> listBooking = new List<DES_Booking__c>();
		//Funcion createBooking(Account acc, String country, String region, Double revenues, String type, String year)
		DES_Booking__c boo1 = testClass.createBooking(acc, paisEspana, paisEspana, 125.12, 'GM', '2017');
		listBooking.add(boo1);
		DES_Booking__c boo2 = testClass.createBooking(acc, paisEspana, paisEspana, 12.06, 'GM', '2018');
		listBooking.add(boo2);
		DES_Booking__c boo3 = testClass.createBooking(acc, paisEspana, paisEspana, 13.24, 'IBF', '2017');
		listBooking.add(boo3);
		DES_Booking__c boo4 = testClass.createBooking(acc, paisEspana, paisEspana, 125.12, 'CF', '2017');
		listBooking.add(boo4);
		DES_Booking__c boo5 = testClass.createBooking(acc, paisEspana, paisEspana, 12.06, 'CO', '2018');
		listBooking.add(boo5);
		DES_Booking__c boo51 = testClass.createBooking(acc, paisEspana, paisEspana, 12.06, 'CO', '2017');
		listBooking.add(boo51);
		DES_Booking__c boo6 = testClass.createBooking(acc, paisEspana, paisEspana, 13.24, 'GL', '2017');
		listBooking.add(boo6);
		insert listBooking;
		Id batchInstanceId = Database.executeBatch(new DES_Booking_Batch(), 2000);
		System.abortJob(batchInstanceId);
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/bookLogic';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = WS_BookingLogic.runBookingBatch();
		Boolean response;
        response = idJobResultado == null ? false : true;
        System.assertEquals(true, response);
		System.abortJob(idJobResultado);
		Test.stopTest();
	}
}