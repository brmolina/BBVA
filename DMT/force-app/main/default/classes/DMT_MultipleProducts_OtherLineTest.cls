@isTest(SeeAllData=false)
private class DMT_MultipleProducts_OtherLineTest {

    @TestSetup
    static void setupTestData() {
        DMT_Test_DataFactory.generateAccount();
        DMT_Test_DataFactory.generatePricebook2();
        DMT_Test_DataFactory.generateTestOtherLines();

    }

    @isTest static void testNormalizeSingleFamilyCode() {

        DMT_Risk_Line_Term__c riskTest = [SELECT Id, DMT_Line__c FROM DMT_Risk_Line_Term__c LIMIT 1];
        DMT_MultipleProducts_OtherLine.Request req = new DMT_MultipleProducts_OtherLine.Request();
        req.recordId = riskTest.Id; 
        req.Family = '1200000000;1400000000';
        req.Subfamily = null;
        req.Category = null;
        req.Subcategory = null;
        req.Globalproduct = null;
        req.lineId = riskTest.DMT_Line__c;
        req.lastLevelId = 'LL1';
        req.groupPriorityLineId = '01';

        Test.startTest();
            List<DMT_MultipleProducts_OtherLine.Response> responses =
                DMT_MultipleProducts_OtherLine.splitRecords(new List<DMT_MultipleProducts_OtherLine.Request>{req});
        Test.stopTest();

        System.assert(responses.size() == 1, 'Debe devolver una sola respuesta');
        DMT_MultipleProducts_OtherLine.Response res = responses[0];
        DMT_Risk_Line_Term__c updated = res.updatedRecordId;
        System.assertEquals('1200000000', updated.g_global_product_family_id__c, 'Family debe estar asignada');
        System.assertEquals(null,updated.g_global_product_subfamily_id__c, 'Subfamily debe ser null');
        System.assertEquals(null,updated.g_global_product_category_id__c, 'Category debe ser null');
        System.assertEquals(null,updated.g_gbl_product_subcategory_id__c, 'Subcategory debe ser null');
        System.assertEquals(null,updated.g_global_product_id__c, 'GlobalProduct debe ser null');
    }

    @isTest static void testNormalizeSubfamilyAndClone() {

        DMT_Risk_Line_Term__c riskTest = [SELECT Id, DMT_Line__c FROM DMT_Risk_Line_Term__c LIMIT 1];
        DMT_MultipleProducts_OtherLine.Request req = new DMT_MultipleProducts_OtherLine.Request();
        req.recordId = riskTest.Id;
        req.Family = null;
        req.Subfamily = '1414000000;1212000000';
        req.Category = null;
        req.Subcategory = null;
        req.Globalproduct = null;
        req.lineId = riskTest.DMT_Line__c;
        req.lastLevelId = 'LL2';
        req.groupPriorityLineId = '01';

        Test.startTest();
            List<DMT_MultipleProducts_OtherLine.Response> responses =
                DMT_MultipleProducts_OtherLine.splitRecords(new List<DMT_MultipleProducts_OtherLine.Request>{req});
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Debe haber 1 respuesta');
        DMT_Risk_Line_Term__c updated = responses[0].updatedRecordId;
        System.assertEquals('1400000000', updated.g_global_product_family_id__c, 'Family correcto');
        System.assertEquals('1414000000', updated.g_global_product_subfamily_id__c, 'Subfamily correcto');
        System.assertEquals(null,updated.g_global_product_category_id__c, 'Category null');
        System.assertEquals(null,updated.g_gbl_product_subcategory_id__c, 'Subcategory null');
        System.assertEquals(null,updated.g_global_product_id__c, 'GlobalProduct null');

    }

    @isTest static void testNormalizeFullGlobalProduct() {

        DMT_Risk_Line_Term__c riskTest = [SELECT Id, DMT_Line__c FROM DMT_Risk_Line_Term__c LIMIT 1];
        DMT_MultipleProducts_OtherLine.Request req = new DMT_MultipleProducts_OtherLine.Request();
        req.recordId = riskTest.Id;
        req.Globalproduct = '1212121212;1111111111';
        req.Family = null;
        req.Subfamily = null;
        req.Category = null;
        req.Subcategory = null;
        req.lineId = riskTest.DMT_Line__c;
        req.lastLevelId = 'LL3';
        req.groupPriorityLineId = '01';

        Test.startTest();
            List<DMT_MultipleProducts_OtherLine.Response> responses =
                DMT_MultipleProducts_OtherLine.splitRecords(new List<DMT_MultipleProducts_OtherLine.Request>{req});
        Test.stopTest();

        DMT_Risk_Line_Term__c updated = responses[0].updatedRecordId;
        System.assertEquals('1200000000', updated.g_global_product_family_id__c, 'Family correcto');
        System.assertEquals('1212000000', updated.g_global_product_subfamily_id__c, 'Subfamily correcto');
        System.assertEquals('1212120000', updated.g_global_product_category_id__c, 'Category correcto');
        System.assertEquals('1212121200', updated.g_gbl_product_subcategory_id__c, 'Subcategory correcto');
        System.assertEquals('1212121212', updated.g_global_product_id__c, 'GlobalProduct correcto');
    }

}