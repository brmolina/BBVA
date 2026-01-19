/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingVariablesTable_test
* @Author   José Luis García  joseluis.garcia4.contractor@bbva.com
* @Date     Created: 21/05/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class that covers: Arc_Gen_RatingVariablesTable_controller, Arc_Gen_RatingVariablesTable_service
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |21/05/2020 joseluis.garcia4.contractor@bbva.com
*             Class creation.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_RatingVariablesTable_test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * --------------------------------------------------------------------------------------
    **/
    @testSetup
    static void setupTest() {
        // Create account, analysis and rating.
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__Stage__c = '1';
        insert newArce;

        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArce.Id, groupAccount.accId, '1');
        newAnalysis.arce__InReview__c = true;
        newAnalysis.arce__path__c = 'MAC';
        insert newAnalysis;

        final arce__rating__c newRating = Arc_UtilitysDataTest_tst.crearRating('Default');
        newRating.arce__rating_id__c = '9999999999';
        insert newRating;

        final arce__Financial_Statements__c newFfss = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.Id, newRating.Id, 'Default');
        insert newFfss;

        // Create field configs.
        final dyfr__Template__c template = Arc_UtilitysDataTest_tst.crearTemplate('Test template');
        insert template;

        final dyfr__Tab__c tab = Arc_UtilitysDataTest_tst.crearTab('Test tab', template.Id);
        insert tab;

        final dyfr__Field_Config__c fc1 = Arc_UtilitysDataTest_tst.crearfieldConfigData('Section', tab.Id, 'test_field1__c');
        fc1.qualitative_question_code__c = '0001';
        final dyfr__Field_Config__c fc2 = Arc_UtilitysDataTest_tst.crearfieldConfigData('Section', tab.Id, 'test_field2__c');
        fc2.qualitative_question_code__c = '0002';
        final dyfr__Field_Config__c fc3 = Arc_UtilitysDataTest_tst.crearfieldConfigData('Section', tab.Id, 'test_field3__c');
        fc3.qualitative_question_code__c = '0003';
        insert fc1;
        insert fc2;
        insert fc3;

        // Create lists of values.
        final dyfr__Dependent_value__c dep1 = new dyfr__Dependent_value__c(dyfr__LoV_labels__c = 'YES,NO', dyfr__LoV_values__c = '1,2', dyfr__Field_Config__c = fc1.Id);
        final dyfr__Dependent_value__c dep2 = new dyfr__Dependent_value__c(dyfr__LoV_labels__c = 'A#B#C', dyfr__LoV_values__c = '1,2,3', dyfr__Field_Config__c = fc2.Id);
        final dyfr__Dependent_value__c dep3 = new dyfr__Dependent_value__c(dyfr__LoV_labels__c = 'Answer A,Answer B,Answer C', dyfr__LoV_values__c = '1,2,3', dyfr__Field_Config__c = fc3.Id);
        insert dep1;
        insert dep2;
        insert dep3;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method that checks that the correct answers are returned.
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testValuesWithinList() {
        // Setup. Create variables.
        final Id ratingId = [SELECT Id FROM arce__rating__c LIMIT 1].Id;

        final arce__rating_variables_detail__c var1 = new arce__rating_variables_detail__c(
            arce__rating_variable_large_id__c = '0001',
            arce__rating_id__c = ratingId,
            arce__rating_var_value_amount__c = 1,
            arce__parent_code_number__c = '2',
            arce__rating_variable_level_id__c = '2'
        );
        final arce__rating_variables_detail__c var2 = new arce__rating_variables_detail__c(
            arce__rating_variable_large_id__c = '0002',
            arce__rating_id__c = ratingId,
            arce__rating_var_value_amount__c = 2,
            arce__parent_code_number__c = '2',
            arce__rating_variable_level_id__c = '2'
        );
        insert var1;
        insert var2;

        // Test.
        Test.startTest();
        final Arc_Gen_RatingVariablesTable_controller.TableResponse response = Arc_Gen_RatingVariablesTable_controller.getQualitativeTable(ratingId);
        Test.stopTest();

        // Assert.
        final List<Arc_Gen_RatingVariablesTable_service.QualitativeItems> items = (List<Arc_Gen_RatingVariablesTable_service.QualitativeItems>)
            JSON.deserialize(response.tableJson, List<Arc_Gen_RatingVariablesTable_service.QualitativeItems>.class);
        System.assertEquals(2, items.size(), 'There must be two rows in the table');
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method that tests the correct behaviour when a variable has no value.
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testVarWithNoValue() {
        // Setup. Create variables.
        final Id ratingId = [SELECT Id FROM arce__rating__c LIMIT 1].Id;

        final arce__rating_variables_detail__c var1 = new arce__rating_variables_detail__c(
            arce__rating_variable_large_id__c = '0001',
            arce__rating_id__c = ratingId,
            arce__parent_code_number__c = '2',
            arce__rating_variable_level_id__c = '2'
        );
        insert var1;

        // Test.
        Test.startTest();
        final Arc_Gen_RatingVariablesTable_controller.TableResponse response = Arc_Gen_RatingVariablesTable_controller.getQualitativeTable(ratingId);
        Test.stopTest();

        // Assert.
        final List<Arc_Gen_RatingVariablesTable_service.QualitativeItems> items = (List<Arc_Gen_RatingVariablesTable_service.QualitativeItems>)
            JSON.deserialize(response.tableJson, List<Arc_Gen_RatingVariablesTable_service.QualitativeItems>.class);
        System.assertEquals(1, items.size(), 'There must be one row in the table');
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method that tests the correct behaviour when a value is out of the range of
    * the list of values for a field.
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testValueOutsideRange() {
        // Setup. Create variables.
        final Id ratingId = [SELECT Id FROM arce__rating__c LIMIT 1].Id;

        final arce__rating_variables_detail__c var1 = new arce__rating_variables_detail__c(
            arce__rating_variable_large_id__c = '0003',
            arce__rating_id__c = ratingId,
            arce__rating_var_value_amount__c = 4,
            arce__parent_code_number__c = '2',
            arce__rating_variable_level_id__c = '2'
        );
        insert var1;

        // Test.
        Test.startTest();
        final Arc_Gen_RatingVariablesTable_controller.TableResponse response = Arc_Gen_RatingVariablesTable_controller.getQualitativeTable(ratingId);
        Test.stopTest();

        // Assert.
        final List<Arc_Gen_RatingVariablesTable_service.QualitativeItems> items = (List<Arc_Gen_RatingVariablesTable_service.QualitativeItems>)
            JSON.deserialize(response.tableJson, List<Arc_Gen_RatingVariablesTable_service.QualitativeItems>.class);
        System.assertEquals(1, items.size(), 'There must be one row in the table');
    }
}