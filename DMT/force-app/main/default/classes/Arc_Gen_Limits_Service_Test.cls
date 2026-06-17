/**
* @description Test class for Arc_Gen_Limits_Service.
*/
@isTest
private class Arc_Gen_Limits_Service_Test {
    /**
    * @description Validates the service constructor instantiates successfully.
    */
    @isTest static void testConstructor() {
        Test.startTest();
        final Arc_Gen_Limits_Service svc = new Arc_Gen_Limits_Service();
        Test.stopTest();

        Assert.isNotNull(svc, 'Constructor should create an instance');
    }

    /**
    * @description Validates LimitsResponse wrapper fields are accessible and assignable.
    */
    @isTest static void testLimitsResponseFields() {
        Test.startTest();
        final Arc_Gen_Limits_Service.LimitsResponse resp = new Arc_Gen_Limits_Service.LimitsResponse();
        resp.typoModId = 'TM001';
        resp.name = 'Test Typology';
        resp.currentLimit = 1000000;
        resp.outstanding = 500000;
        resp.commited = 300000;
        resp.uncommited = 200000;
        resp.lastApproved = 900000;
        resp.currencyType = 'EUR';
        resp.unit = 'MILLIONS';
        resp.gblCodeResponse = '200';
        resp.gblSuccess = true;
        Test.stopTest();

        Assert.isTrue(
            resp.typoModId == 'TM001' &&
            resp.currentLimit == 1000000 &&
            resp.gblSuccess == true,
            'LimitsResponse fields should be set correctly'
        );
    }
}