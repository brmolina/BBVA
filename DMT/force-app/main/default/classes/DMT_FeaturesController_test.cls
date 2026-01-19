@isTest
public with sharing class DMT_FeaturesController_test {
    static Id testLineId;

    @TestSetup
    static void setupTestData() {

        DMT_Line__c line = new DMT_Line__c(
        Name = 'Línea de prueba',
        Line_Id__c = '00002'
        );
        insert line;
        testLineId = line.Id;


        List<DMT_Feature__c> features = new List<DMT_Feature__c>{
            new DMT_Feature__c(
                gf_capability_engine_id_number__c = '123',
                gf_feature_name_desc__c = 'Feature Test A',
                gf_feature_deal_type__c = 'Type1',
                gf_global_feature_id_number__c = 'GF001',
                gf_approver_apply_ind_type__c = 'Test1',
                gf_user_audit_id__c = 'UserTest',
                gf_audit_date__c = Date.today(),
                gf_operation_type_name__c = 'ALL'
            ),
            new DMT_Feature__c(
                gf_capability_engine_id_number__c = '456',
                gf_feature_name_desc__c = 'Feature Test B',
                gf_feature_deal_type__c = 'Type2',
                gf_global_feature_id_number__c = 'GF002',
                gf_approver_apply_ind_type__c = 'Test2',
                gf_user_audit_id__c = 'UserTest',
                gf_audit_date__c = Date.today(),
                gf_operation_type_name__c = 'LIN'
            )
        };
        insert features;

        DMT_Selected_Features__c selected = new DMT_Selected_Features__c(
            Line__c = line.Id,
            Feature__c = features[0].Id
        );
        insert selected;

        Passport__c passport = new Passport__c(
            DMT_Line__c = line.Id,
            DMT_Is_Obsoleted_Passport_Save__c = false
        );
        insert passport;
    }

    @isTest
    static void testLoadFeatures() {
        Test.startTest();
        List<Map<String, Object>> result = DMT_FeaturesController.loadFeatures(testLineId, 'Type1');
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.size() > 0, 'Debe haber al menos una feature devuelta');
        System.assert(result[0].containsKey('isSelected'), 'Debe contener el campo isSelected');
    }

    @isTest
    static void testGetPassportIdFromLineOrOpportunity() {
        
        Passport__c passport = [SELECT Id, DMT_Line__c FROM Passport__c WHERE DMT_Line__c != null LIMIT 1];
        Id lineId = passport.DMT_Line__c;

        Test.startTest();
        Id passportId = DMT_FeaturesController.getPassportIdFromLineOrOpportunity(lineId);
        Test.stopTest();

        System.assertNotEquals(null, passportId, 'Debe devolver un Id de Passport');
    }

    @isTest
    static void testGetObligatoryFeatures() {
        DMT_Line__c testLine = new DMT_Line__c(Name = 'Test Line');
        insert testLine;

        String jsonData = '{"data":{"features":[{"id":"Test1","name":"Global validations","stateName":"RED"},{"id":"Test2","name":"Limit Feature test 1","stateName":"GREEN"}]}}';

        List<Passport__c> existingPassports = [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testLine.Id];
        delete existingPassports;

        Passport__c testPassport = new Passport__c(
            DMT_Line__c = testLine.Id,
            DMT_Passport_Save__c = jsonData
        );
        insert testPassport;

        Passport__c retrievedPassport = [SELECT Id, DMT_Passport_Save__c, DMT_Line__c FROM Passport__c WHERE DMT_Line__c = :testLine.Id];

        Test.startTest();
        List<Map<String, Object>> features = DMT_FeaturesController.getObligatoryFeatures(testLine.Id);
        Test.stopTest();

        System.debug('Features List: ' + features);

        Assert.isNotNull(features, 'Features list should not be null.');
        Assert.areEqual(2, features.size(), 'Features list should contain 2 items.');
        Assert.areEqual('Global validations', features[0].get('name'), 'First feature name should match.');
        Assert.areEqual('Limit Feature test 1', features[1].get('name'), 'Second feature name should match.');
        Assert.areEqual('RED', features[0].get('stateName'), 'First feature stateName should match.');
        Assert.areEqual('GREEN', features[1].get('stateName'), 'Second feature stateName should match.');
    }
}