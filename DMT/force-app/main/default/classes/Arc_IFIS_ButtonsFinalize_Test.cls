/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsFinalize_Test
* @Author         marcos.gimeno.next@bbva.com
* @Date           04-09-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class for Arc_IFIS_ButtonsFinalize.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 04-09-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
@IsTest
public class Arc_IFIS_ButtonsFinalize_Test {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Setup test data.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void setup() {
        final Id ahaId = new arce.Arc_IFIS_Test_Utils().createFullData();

        final arce__Country_Ceiling__c countryCeiling = [SELECT id FROM arce__Country_Ceiling__c LIMIT 1];
        new arce.Arc_IFIS_Test_Utils().createRatingCopy(ahaId, countryCeiling.Id);
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for constructor.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCtrlConstructor() {
        final Arc_IFIS_ButtonsFinalize_Ctrl constructor = new Arc_IFIS_ButtonsFinalize_Ctrl();
        System.assertNotEquals(null, constructor, 'Constructor was init successfully');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Service] Unit test for constructor.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testServiceConstructor() {
        final Arc_IFIS_ButtonsFinalize_Service constructor = new Arc_IFIS_ButtonsFinalize_Service();
        System.assertNotEquals(null, constructor, 'Constructor was init successfully');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for getRatingData() rating.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCtrlGetRatingDataRating() {
        final Id ahaId = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1].Id;

        Test.startTest();
        final arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_ButtonsFinalize_Ctrl.getRatingData(ahaId);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for getRatingData() rating to recalculate.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCtrlGetRatingDataRatingRecalculate() {
        final arce__Account_has_Analysis__c aha = [
            SELECT Id, arce__recalculate_rating__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];
        aha.arce__recalculate_rating__c = '2';
        update aha;

        Test.startTest();
        final arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_ButtonsFinalize_Ctrl.getRatingData(aha.Id);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for getRatingData() prerating.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCtrlGetRatingDataPrerating() {
        final arce__Account_has_Analysis__c aha = [
            SELECT Id, arce__Analysis__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];
        update new arce__Analysis__c(Id = aha.arce__Analysis__c, arce__rating_prerating_type__c = 'Prerating');

        Test.startTest();
        final arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_ButtonsFinalize_Ctrl.getRatingData(aha.Id);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for getRatingData() prerating without final rating.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     05-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCtrlGetRatingDataPreratingEmpty() {
        final List<SObject> sObjToUpd = new List<SObject>();
        final arce__Account_has_Analysis__c aha = [
            SELECT
                Id,
                arce__Analysis__c,
                arce__ffss_for_rating_id__r.arce__rating_id__r.arce__rating_short_value_type__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];
        aha.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__rating_short_value_type__c = '';
        sObjToUpd.add(aha.arce__ffss_for_rating_id__r.arce__rating_id__r);
        sObjToUpd.add(new arce__Analysis__c(Id = aha.arce__Analysis__c, arce__rating_prerating_type__c = 'Prerating'));
        update sObjToUpd;
        Exception expectedException;

        Test.startTest();
        try {
            Arc_IFIS_ButtonsFinalize_Ctrl.getRatingData(aha.Id);
        } catch (Exception e) {
            expectedException = e;
        }
        Test.stopTest();

        System.assert(expectedException != null, 'Should throw an exception.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for getRatingData() prerating to recalculate.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     05-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCtrlGetRatingDataPreratingRecalculate() {
        final List<SObject> sObjToUpd = new List<SObject>();
        final arce__Account_has_Analysis__c aha = [
            SELECT Id, arce__Analysis__c, arce__recalculate_rating__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];
        aha.arce__recalculate_rating__c = '2';
        sObjToUpd.add(aha);
        sObjToUpd.add(new arce__Analysis__c(Id = aha.arce__Analysis__c, arce__rating_prerating_type__c = 'Prerating'));
        update sObjToUpd;

        Test.startTest();
        final arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_ButtonsFinalize_Ctrl.getRatingData(aha.Id);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for getRatingData() with invalid aha.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCtrlGetRatingDataInvalidAha() {
        Exception expectedException;

        Test.startTest();
        try {
            Arc_IFIS_ButtonsFinalize_Ctrl.getRatingData('invalid');
        } catch (Exception e) {
            expectedException = e;
        }
        Test.stopTest();
        
        System.assert(expectedException != null, 'Should throw an exception.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for getRatingData() with blank aha.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCtrlGetRatingDataBlankAha() {
        arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result;

        Test.startTest();

        try {
            result = arce.Arc_IFIS_ButtonsFinalize_Ctrl.getRatingData(''); 
        } catch (Exception e) {
            System.assertEquals(
                System.Label.arce.Arc_IFIS_Error_Aha_Not_Provided,
                result.message,
                'Result should return invalid aha message.'
            );
        }

        Test.stopTest();
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for callParticipantRelation().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCallParticipantRelation() {
        final String ahaId = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1].Id;

        Test.startTest();
        final arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_ButtonsFinalize_Ctrl.callParticipantRelation(
            ahaId
        );
        Test.stopTest();

        System.assert(result != null, 'Response should not be null.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for callParticipantRelation() with null account.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCallParticipantRelationNullAccount() {
        final String ahaId = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1].Id;

        Test.startTest();
        delete [SELECT Id FROM Account LIMIT 1];

        final arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_ButtonsFinalize_Ctrl.callParticipantRelation(
            ahaId
        );
        Test.stopTest();

        System.assert(result != null, 'Response should not be null.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for callParticipantRelation() with exception.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCallParticipantRelationException() {
        Test.startTest();
        final arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_ButtonsFinalize_Ctrl.callParticipantRelation(
            null
        );
        Test.stopTest();

        System.assert(!result.success, 'Should return a KO result.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for callRatingValidation() for rating.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCallRatingValidationRating() {
        arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result;
        final arce__Account_has_Analysis__c aha = [
            SELECT Id, arce__Customer__r.AccountNumber, arce__ffss_for_rating_id__r.arce__rating_id__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];
        final arce__rating__c rating = [
            SELECT Id, arce__rating_short_value_type__c
            FROM arce__rating__c
            WHERE Id = :aha.arce__ffss_for_rating_id__r.arce__rating_id__c
            LIMIT 1
        ];
        final Map<String, String> testMap = new Map<String, String>{
            'ahaId' => aha.Id,
            'validatedById' => System.UserInfo.getUserId(),
            'ratingId' => rating.Id,
            'ambit' => '',
            'description' => ''
        };

        Test.startTest();
        result = Arc_IFIS_ButtonsFinalize_Ctrl.callRatingValidation(JSON.serialize(testMap));
        Test.stopTest();

        System.assert(result.success, 'Result should return OK response.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for callRatingValidation() for prerating.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCallRatingValidationPrerating() {
        arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result;
        final arce__Account_has_Analysis__c aha = [
            SELECT
                Id,
                arce__Analysis__c,
                arce__Customer__r.AccountNumber,
                arce__ffss_for_rating_id__r.arce__rating_id__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];
        final arce__Analysis__c analysis = [SELECT Id, arce__rating_prerating_type__c FROM arce__Analysis__c LIMIT 1];
        analysis.arce__rating_prerating_type__c = 'Prerating';
        update analysis;
        final arce__rating__c rating = [
            SELECT Id, arce__rating_short_value_type__c
            FROM arce__rating__c
            WHERE Id = :aha.arce__ffss_for_rating_id__r.arce__rating_id__c
            LIMIT 1
        ];
        final Map<String, String> testMap = new Map<String, String>{
            'ahaId' => aha.Id,
            'validatedById' => System.UserInfo.getUserId(),
            'ratingId' => rating.Id,
            'ambit' => '',
            'description' => ''
        };

        Test.startTest();
        result = Arc_IFIS_ButtonsFinalize_Ctrl.callRatingValidation(JSON.serialize(testMap));
        Test.stopTest();

        System.assert(result.success, 'Result should return OK response.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for callRatingValidation() with exception.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCallRatingValidationException() {
        Exception expectedException;
        arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result;
        final Map<String, String> testData = new Map<String, String>{};
        final String testMapJson = JSON.serialize(testData);

        Test.startTest();
        try {
            result = Arc_IFIS_ButtonsFinalize_Ctrl.callRatingValidation(testMapJson);
        } catch (Exception e) {
            expectedException = e;
        }
        System.assert(expectedException != null && result == null, 'Result should be null.');

        Test.stopTest();
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for fetchUsers().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testFetchUsers() {
        Test.startTest();
        final arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_ButtonsFinalize_Ctrl.fetchUsers('selectedAmbit');
        Test.stopTest();

        System.assert(result != null, 'Response should not be null.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for fetchUsers() with blank ambit.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testFetchUsersBlank() {
        Test.startTest();
        final arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_ButtonsFinalize_Ctrl.fetchUsers('');
        Test.stopTest();

        System.assert(result != null, 'Response should not be null.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Service] Unit test for getRatingData().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testServiceGetRatingData() {
        final arce__Account_has_Analysis__c aha = [
            SELECT
                Id,
                arce__Analysis__r.arce__rating_prerating_type__c,
                arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c,
                arce__ffss_for_rating_id__r.arce__rating_id__c
            FROM arce__Account_has_Analysis__c
            LIMIT 1
        ];

        Test.startTest();
        final arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_ButtonsFinalize_Service.getRatingData(
            aha,
            arce.Arc_Gen_RatingGlobal_Constants.RATINGVAL
        );
        Arc_IFIS_ButtonsFinalize_Ctrl.fetchUsersAha('1', aha.Id);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Service] Unit test for handleValidationFailure().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     05-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testServiceHandleValidationFailure() {
        final String serviceMessage = '{"errorTitle":"Test Error","errorMessage":"Test Message"}';

        Test.startTest();
        final arce.Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_ButtonsFinalize_Service.handleValidationFailure(
            serviceMessage
        );
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test Arc_IFIS_ButtonsFinalize_Service.transformResponseMap method
    * -----------------------------------------------------------------------------------------------
    * @autor    francisco.munoz.torres.tech@bbva.com
    * @date     13/03/2024
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testProcessCountries() {
        final arce.Arc_Gen_getIASOResponse.ServiceResponse serviceResponse = new arce.Arc_Gen_getIASOResponse.ServiceResponse();
        serviceResponse.serviceResponse = (Map<String, Object>) JSON.deserializeUntyped(
            '{"data":{"ratingCalculation":{"countries":[{"id":"ES","participants":[{"id":"ES0182009071367","rating":{"id":"1100010312"}},{"id":"ES0182009071343","rating":{"id":"1100010313"}}]}]}}}'
        );

        Test.startTest();
        final Map<String, Map<String, String>> response = Arc_IFIS_ButtonsFinalize_Service.transformResponseMap(
            serviceResponse
        );
        Test.stopTest();

        System.assert(response != null, 'Result should not be null.');
    }
}