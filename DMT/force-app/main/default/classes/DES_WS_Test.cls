@isTest
public class DES_WS_Test {

	@isTest
	public static void testDeleteBooking(){
		test.startTest();
		//getData();

		/*Account acc = utilTestClass.createClient();
		insert acc;
		String paisEspana = 'ESPAÑA';
		List<DES_Booking__c> listBooking = new List<DES_Booking__c>();
        DES_Booking__c boo1 = utilTestClass.createBooking(acc, paisEspana, paisEspana, 125.12, 'GM', '2017');
        listBooking.add(boo1);
        DES_Booking__c boo2 = utilTestClass.createBooking(acc, paisEspana, paisEspana, 12.06, 'GM', '2018');
        listBooking.add(boo2);
        DES_Booking__c boo3 = utilTestClass.createBooking(acc, paisEspana, paisEspana, 13.24, 'GF', '2017');
        listBooking.add(boo3);
        insert listBooking;
        */
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/deleteBooking';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_Delete_Booking.runBookingBatch();

		testGetApexJobInfo(idJobResultado);

		System.abortJob(idJobResultado);
		test.stopTest();
	}


	@isTest
	public static void testDeleteAccRel(){
		test.startTest();
		//getData();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/deleteAccRel';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_Delete_AccRel.runBookingBatch();

		testGetApexJobInfo(idJobResultado);

		System.abortJob(idJobResultado);
		test.stopTest();
	}

	@isTest
	public static void testDeleteEVARAR(){
		test.startTest();
		//getData();
		/*DES_Historic_RAR_EVA_RORC__c historic = new DES_Historic_RAR_EVA_RORC__c();
        historic.DES_Client__c = acc.Id;
        historic.DES_EVA_Amount__c = 80.08;
        historic.DES_RAR_Amount__c = 32.93;
        historic.DES_RORC_Amount__c = 27.31;
        historic.DES_Year_Text__c = '2017';
        insert historic;*/

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/deleteEVARAR';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_Delete_EVA_RAR.runBookingBatch();

		testGetApexJobInfo(idJobResultado);

		System.abortJob(idJobResultado);
		test.stopTest();
	}

    @isTest
	public static void testDeleteAccSBSClas(){
		test.startTest();

        String testWSComentado;
        testWSComentado = DES_WS_Delete_SBS_CLASSIF.runBookingBatch();
        System.assertNotEquals(testWSComentado, null,'Error');

		test.stopTest();
	}

    @isTest
	public static void testDeleteAccBBVAClas(){
		test.startTest();

        String testWSComentado;
        testWSComentado = DES_WS_Delete_BBVA_CLASSIF.runBookingBatch();
		System.assertNotEquals(testWSComentado, null,'Error');

		test.stopTest();
	}

    @isTest
	public static void testDeleteAccCommStraRes(){
		test.startTest();

        String testWSComentado;
        testWSComentado = DES_WS_Delete_COMMERCIAL_STRAT_RES.runBookingBatch();
        System.assertNotEquals(testWSComentado, null,'Error');

		test.stopTest();
	}

    @isTest
	public static void testDeleteAccIndicator(){
		test.startTest();

        String testWSComentado;
        testWSComentado = DES_WS_Delete_INDICATOR.runBookingBatch();
        System.assertNotEquals(testWSComentado, null,'Error');

		test.stopTest();
	}

    @isTest
	public static void testDeleteAccPayroll(){
		test.startTest();

        String testWSComentado;
        testWSComentado = DES_WS_Delete_Account_Payroll.runBookingBatch();
        System.assertNotEquals(testWSComentado, null,'Error');

		test.stopTest();
	}

    @isTest
	public static void testDeleteAccProfitability(){
		test.startTest();

        String testWSComentado;
        testWSComentado = DES_WS_Delete_PROFITABILITY.runBookingBatch();
        System.assertNotEquals(testWSComentado, null,'Error');

		test.stopTest();
	}

    @isTest
	public static void testDeleteAccSBSInfo(){
		test.startTest();

        String testWSComentado;
        testWSComentado = DES_WS_Delete_SBS_INFORM.runBookingBatch();
        System.assertNotEquals(testWSComentado, null,'Error');

		test.stopTest();
	}

    @isTest
	public static void testDeleteAccBBVAInfo(){
		test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/deleteAccBBVAInfo';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_Delete_ACCOUNT_BBVA_INFOR.runBookingBatch();
        System.assertNotEquals(idJobResultado, null,'Error');

		testGetApexJobInfo(idJobResultado);

		System.abortJob(idJobResultado);
		test.stopTest();
	}

    @isTest
	public static void testDeleteVisitTopicLocal(){
		test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/deleteVisitTopicLocal';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_Delete_Visit_Topic_Local.runBookingBatch();
        System.assertNotEquals(idJobResultado, null,'Error');

		testGetApexJobInfo(idJobResultado);

		System.abortJob(idJobResultado);
		test.stopTest();
	}
	/**
	* Meth0d0 para DeleteManagementTeamLocal
	*/
    @isTest
	public static void testDeleteManagementTeamLocal() {
		test.startTest();
        
		Final RestRequest req = new RestRequest();
		Final RestResponse res = new RestResponse();
		
		req.requestURI = '/services/apexrest/deleteVisitManagTeamLocal';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;
		
		Id idJobResultado;
		idJobResultado = DWA_WS_Delete_Visit_Manag_Team_Local.runBookingBatch();
        System.assertNotEquals(idJobResultado, null,'Error');
		
		testGetApexJobInfo(idJobResultado);
		
		System.abortJob(idJobResultado);
		test.stopTest();
	}
    @isTest
	public static void testDeleteVisitContactLocal(){
		test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/deleteVisitContactLocal';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_Delete_Visit_Contact_Local.runBookingBatch();
        System.assertNotEquals(idJobResultado, null,'Error');

		testGetApexJobInfo(idJobResultado);

		System.abortJob(idJobResultado);
		test.stopTest();
	}

    @isTest
	public static void testDeleteAccSBSInfoSumm(){
		test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/deleteAccSBSInfoSumm';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_Delete_SBS_INFORM_SUMMARY.runBookingBatch();
        System.assertNotEquals(idJobResultado, null,'Error');

		testGetApexJobInfo(idJobResultado);

		System.abortJob(idJobResultado);
		test.stopTest();
	}

    @isTest
	public static void testDeleteDwpCvadActAudD(){
		test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/deleteDwpCvadActAudD';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_Delete_dwp_cvad_ActAudD.runBookingBatch();
        System.assertNotEquals(idJobResultado, null,'Error');

		testGetApexJobInfo(idJobResultado);

		System.abortJob(idJobResultado);
		test.stopTest();
	}

    @isTest
	public static void testDeleteAccRenewals(){
		test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/deleteAccRenewals';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_Delete_Renewals.runBookingBatch();
        System.assertNotEquals(idJobResultado, null,'Error');

		testGetApexJobInfo(idJobResultado);

		System.abortJob(idJobResultado);
		test.stopTest();
	}

    @isTest
	public static void testCommitInterGarant(){
		test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/deleteCommitInterGarant';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_Delete_Commit_Inter_Garant.runBookingBatch();
        System.assertNotEquals(idJobResultado, null,'Error');

		testGetApexJobInfo(idJobResultado);

		System.abortJob(idJobResultado);
		test.stopTest();
	}

    @isTest
	public static void testProductConfiLocal(){
		test.startTest();

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/deleteProductConfiLocal';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		Id idJobResultado;
		idJobResultado = DES_WS_Delete_Product_Confi_Local.runBookingBatch();
        System.assertNotEquals(idJobResultado, null,'Error');

		testGetApexJobInfo(idJobResultado);

		System.abortJob(idJobResultado);
		test.stopTest();
	}

	private static void getData(){
		DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

		Account acc = utilTestClass.createClient();
		insert acc;
		String paisEspana = 'ESPAÑA';
		List<DES_Booking__c> listBooking = new List<DES_Booking__c>();
        DES_Booking__c boo1 = utilTestClass.createBooking(acc, paisEspana, paisEspana, 125.12, 'GM', '2017');
        listBooking.add(boo1);
        DES_Booking__c boo2 = utilTestClass.createBooking(acc, paisEspana, paisEspana, 12.06, 'GM', '2018');
        listBooking.add(boo2);
        DES_Booking__c boo3 = utilTestClass.createBooking(acc, paisEspana, paisEspana, 13.24, 'IBF', '2017');
        listBooking.add(boo3);
        insert listBooking;

        DES_Historic_RAR_EVA_RORC__c historic = new DES_Historic_RAR_EVA_RORC__c();
        historic.DES_Client__c = acc.Id;
        historic.DES_EVA_Amount__c = 80.08;
        historic.DES_RAR_Amount__c = 32.93;
        historic.DES_RORC_Amount__c = 27.31;
        historic.DES_Year_Text__c = '2017';
        insert historic;

	}//FIN getData

	public static void testGetApexJobInfo(Id idJob){
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/getApexJobInfo/?jobId=' + idJob;
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;
		DES_WS_GetApexJobInfo.WrapperClass wrclass = DES_WS_GetApexJobInfo.getApexJob();
	}
}