/**
* @author Global Desktop
* @description Test class for Web Service del batch BatchActiveAccounts
*/
@isTest
public class DES_WS_BatchActiveAccountsTest {

	/**
	* @description
	* @author Global Desktop | 4/5/2020
	* @return void
	**/
	@isTest
	public static void testOK1(){

		test.startTest();

		final RestRequest req = new RestRequest();
		final RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/activeAccounts';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_BatchActiveAccounts.runActiveAccounts();
		Boolean response;
        response = idJobResultado == null ? false : true;
        System.assert(response,'Ok');
		System.abortJob(idJobResultado);

		test.stopTest();
	}

}