/**
* @author Global Desktop
* @description Test para DES_WS_ResetAccFieldsTest
*/
@isTest
public class DES_WS_ResetAccFieldsTest {

	@isTest
	public static void testOK1(){

		test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/resetAccFields';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_ResetAccFields.runResetAccFields();
		Boolean response;
        response = idJobResultado == null ? false : true;
        System.assertEquals(true, response);
		System.abortJob(idJobResultado);
		test.stopTest();
	}

}