/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsPropose_Test
* @Author         marcos.gimeno.next@bbva.com
* @Date           28-08-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class for Arc_IFIS_ProposeRating.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 28-08-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
@IsTest
public class Arc_IFIS_ButtonsPropose_Test {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Setup test data.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void setup() {
        new arce.Arc_IFIS_Test_Utils().createFullData();
        User u = new User();
        Double random = Math.random();
        u.Username = 'thisIsTestu2@u.com.u' + random;
        u.LastName = 'thisIsTestLast2';
        u.Email = 'thisIsTestu2@u.com';
        u.Alias = 'TesHV12';
        u.TimeZoneSidKey = 'America/Mexico_City';
        u.IsActive = true;
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
        List<Profile> prof = new List<Profile>([SELECT Id, Name FROM Profile WHERE Name = :'BBVA Standard User']);
        u.ProfileId = prof[0].Id;
        u.LanguageLocaleKey = 'es';
        u.ID_User__c = 'hvTest' + u.Username.substring(0, 3) + String.valueOf(random).substring(0, 3);
        insert u;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for constructor.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCtrlConstructor() {
        final Arc_IFIS_ButtonsPropose_Ctrl constructor = new Arc_IFIS_ButtonsPropose_Ctrl();
        System.assertNotEquals(null, constructor, 'Constructor was init successfully');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for initDelegation().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testInitDelegationCtrl() {
        final arce__Account_has_Analysis__c aha = [
            SELECT Id, arce__ffss_for_rating_id__r.arce__rating_id__r.arce__status_type__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];
        aha.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__status_type__c = '2';
        update aha.arce__ffss_for_rating_id__r.arce__rating_id__r;

        Test.startTest();
        final String result = Arc_IFIS_ButtonsPropose_Ctrl.initDelegation(aha.Id);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for initDelegation().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testInitDelegationCtrlException() {
        final String fakeId = new arce.Arc_IFIS_Test_Utils().getFakeId();
        Exception expectedException;

        Test.startTest();
        try {
            Arc_IFIS_ButtonsPropose_Ctrl.initDelegation(fakeId);
        } catch (AuraHandledException e) {
            expectedException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, expectedException, 'Exception should be triggered.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for proposeRating().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testProposeRating() {
        final Id analysisId = [SELECT Id FROM arce__Analysis__c LIMIT 1].Id;
        final String userId = [SELECT Id FROM User LIMIT 1].Id;
        Test.startTest();
        final String result = Arc_IFIS_ButtonsPropose_Ctrl.proposeRating(analysisId, 'selectedAmbitValue', userId);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for proposeRating() with invalid aha.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testProposeRatingInvalidAha() {
        final String fakeId = new arce.Arc_IFIS_Test_Utils().getFakeId();
        final String userId = [SELECT Id FROM User LIMIT 1].Id;
        Test.startTest();
        try {
            final String result = Arc_IFIS_ButtonsPropose_Ctrl.proposeRating(fakeId, 'selectedAmbit', userId);
        } catch (AuraHandledException e) {
            System.assertEquals(e.getMessage(), 'Script-thrown exception', 'Exception should be triggered.');
        }
        Test.stopTest();
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for proposeRating() with exception.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testProposeRatingException() {
        final String userId = [SELECT Id FROM User LIMIT 1].Id;
        Test.startTest();
        try {
            final String result = Arc_IFIS_ButtonsPropose_Ctrl.proposeRating(
                'invalidAnalysisId',
                'selectedAmbit',
                userId
            );
        } catch (AuraHandledException e) {
            System.assertEquals(e.getMessage(), 'Script-thrown exception', 'Exception should be triggered.');
        }
        Test.stopTest();
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Service] Unit test for toPropose().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testToPropose() {
        final Id analysisId = [SELECT Id, OwnerId FROM arce__Analysis__c LIMIT 1].Id;
        final String userId = [SELECT Id FROM User LIMIT 1].Id;
        final arce__Account_has_Analysis__c aha = [
            SELECT
                Id,
                Name,
                arce__ffss_for_rating_id__r.arce__rating_id__c,
                arce__ffss_for_rating_id__r.arce__rating_id__r.arce__total_rating_score_number__c,
                arce__total_rating_score_number__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];

        Test.startTest();
        final arce.Arc_Gen_RatingGlobal_data.SaveResult result = Arc_IFIS_ButtonsPropose_Service.toPropose(
            analysisId,
            '1',
            userId,
            aha
        );
        Arc_IFIS_ButtonsPropose_Ctrl.getPermissionOverlay(aha.Id);
        Arc_IFIS_ButtonsPropose_Ctrl.fetchUsers('1');
        Arc_IFIS_ButtonsPropose_Ctrl.fetchRegionLevel('España', '2', aha.Id);
        Arc_IFIS_ButtonsPropose_Ctrl.proposeRating(analysisId, '1', userId);
        Test.stopTest();

        System.assertEquals('true', result.status, 'Result status should be true.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description .
    * -----------------------------------------------------------------------------------------------
    * @autor    joseluis.miralles.contractor@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testrefreshParentSubsidiary() {
        final Id analysisId = [SELECT Id, OwnerId FROM arce__Analysis__c LIMIT 1].Id;
        final arce__Account_has_Analysis__c aha = [
            SELECT
                Id,
                Name,
                arce__ffss_for_rating_id__r.arce__rating_id__c,
                arce__ffss_for_rating_id__r.arce__rating_id__r.arce__total_rating_score_number__c,
                arce__total_rating_score_number__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];

        Test.startTest();
        final arce.Arc_IFIS_RetrievePS_Controller.MessageResponse result = Arc_IFIS_ButtonsPropose_Ctrl.refreshParentSubsidiary(
            aha.Id
        );
        Test.stopTest();
        System.assertEquals('Success', result.status, 'Result status should be Success.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description .
    * -----------------------------------------------------------------------------------------------
    * @autor    joseluis.miralles.contractor@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testvalidateParentSubsidiary() {
        final Id analysisId = [SELECT Id, OwnerId FROM arce__Analysis__c LIMIT 1].Id;
        final arce__Account_has_Analysis__c aha = [
            SELECT
                Id,
                Name,
                arce__ffss_for_rating_id__r.arce__rating_id__c,
                arce__ffss_for_rating_id__r.arce__rating_id__r.arce__total_rating_score_number__c,
                arce__total_rating_score_number__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];

        Test.startTest();
        final arce.Arc_IFIS_ValidatePS.MessageResponse result = Arc_IFIS_ButtonsPropose_Ctrl.validateParentSubsidiary(
            aha.Id
        );
        Test.stopTest();
        system.debug(result);
        System.assertEquals('Success', result.status, 'Result status should be Success.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description .
    * -----------------------------------------------------------------------------------------------
    * @autor    joseluis.miralles.contractor@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testgetPermissionOverlay() {
        final Id analysisId = [SELECT Id, OwnerId FROM arce__Analysis__c LIMIT 1].Id;
        final arce__Account_has_Analysis__c aha = [
            SELECT
                Id,
                Name,
                arce__ffss_for_rating_id__r.arce__rating_id__c,
                arce__ffss_for_rating_id__r.arce__rating_id__r.arce__total_rating_score_number__c,
                arce__total_rating_score_number__c,
                arce__Analysis__r.arce__is_RTC__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];
        aha.arce__Analysis__r.arce__is_RTC__c = true;
        update aha.arce__Analysis__r;

        Test.startTest();
        final String result = Arc_IFIS_ButtonsPropose_Ctrl.getPermissionOverlay(aha.Id);
        Test.stopTest();
        System.assertEquals(System.Label.arce.Arc_Gen_ProposeOverlay, 'Please, before proposing it is necessary to calculate Final Rating', 'Result should ask for calculate rating');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Service] Unit test for fieldsValidation().
    * -----------------------------------------------------------------------------------------------
    * @autor    francisco.munoz.torres.tech@bbva.com
    * @date     13/02/2024
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testFieldsValidation() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        final String result = Arc_IFIS_ButtonsPropose_Ctrl.fieldsValidation(analysis.id);
        Test.stopTest();

        System.assertEquals('false', result, 'Result status should be false.');
    }


    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for getArceConfigs().
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        22-05-2024
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testGetArceConfigs() {
        // When
        Test.startTest();
        final String result = Arc_IFIS_ButtonsPropose_Ctrl.getArceConfigs();
        Test.stopTest();

        // Then
        System.assert(String.isNotEmpty(result), 'Result should not be empty.');
    }
}