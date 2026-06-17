@isTest
private without sharing class DMT_ProfitabilityAxisSelectorTest {
    /**
     * Utility to create a Profitability Axis with the needed fields.
     */
private static DMT_Profitability_Axis__c newAxis(String name, String dataType, String axisDesc, String incNumber) {
        return new DMT_Profitability_Axis__c(
            Name = name,
            g_active_ind_type__c = true,
            gf_data_type__c = dataType,
            gf_axis_data_type_desc__c = axisDesc,
            gf_incremental_axis_type_number__c = incNumber
        );
    }

    /**
     * Creates 3 axes and 2 active combinations that reference them.
     * Returns a map:
     *  x => axis used in X
     *  y => axis used in Y
     *  c => axis used in Center
     */
    private static Map<String, DMT_Profitability_Axis__c> setupAxesAndCombinations() {
        // Axes
DMT_Profitability_Axis__c axX = newAxis('Axis X', 'Number', 'X Desc', 'X001');
        DMT_Profitability_Axis__c axY = newAxis('Axis Y', 'Percent', 'Y Desc', 'Y001');
        DMT_Profitability_Axis__c axC = newAxis('Axis C', 'Text', 'C Desc', 'C001');

        // Also create one extra active axis that is NOT used by any combination to verify filtering
DMT_Profitability_Axis__c axUnused = newAxis('Axis Unused', 'Number', 'Unused Desc', 'U001');

        insert new List<DMT_Profitability_Axis__c>{ axX, axY, axC, axUnused };

        // Active combinations that use only the first three
        DMT_Profitability_Axis_Combination__c comb1 = new DMT_Profitability_Axis_Combination__c(
            g_active_ind_type__c = true,
            gf_x_axis_value_number__c = axX.Id,
            gf_y_axis_value_number__c = axY.Id,
            gf_center_axis_value_number__c = axC.Id
        );
        // Second combination using the same X and different Center (duplicate center also allowed/null handling)
        DMT_Profitability_Axis_Combination__c comb2 = new DMT_Profitability_Axis_Combination__c(
            g_active_ind_type__c = true,
            gf_x_axis_value_number__c = axX.Id,
            gf_y_axis_value_number__c = axY.Id,
            gf_center_axis_value_number__c = axC.Id
        );

        // Inactive combination should be ignored
        DMT_Profitability_Axis_Combination__c combInactive = new DMT_Profitability_Axis_Combination__c(
            g_active_ind_type__c = false,
            gf_x_axis_value_number__c = axUnused.Id,
            gf_y_axis_value_number__c = axUnused.Id,
            gf_center_axis_value_number__c = axUnused.Id
        );

        insert new List<DMT_Profitability_Axis_Combination__c>{ comb1, comb2, combInactive };

        return new Map<String, DMT_Profitability_Axis__c>{
            'x' => axX, 'y' => axY, 'c' => axC
        };
    }

    @isTest
    static void test_getInitialOptions_emptyWhenNoActiveCombinations() {
        Test.startTest();
        DMT_ProfitabilityAxisSelectorController.InitialOptionsResponse res =
            DMT_ProfitabilityAxisSelectorController.getInitialOptions();
        Test.stopTest();

        System.assertNotEquals(null, res, 'Response must not be null');
        System.assertEquals(0, res.xOptions.size(), 'No X options expected');
        System.assertEquals(0, res.yOptions.size(), 'No Y options expected');
        System.assertEquals(0, res.centralOptions.size(), 'No Central options expected');
        System.assertEquals(0, res.combinations.size(), 'No combinations expected');
    }

    @isTest
    static void test_getInitialOptions_returnsOnlyAxesInActiveCombinations() {
        Map<String, DMT_Profitability_Axis__c> axes = setupAxesAndCombinations();

        Test.startTest();
        DMT_ProfitabilityAxisSelectorController.InitialOptionsResponse res =
            DMT_ProfitabilityAxisSelectorController.getInitialOptions();
        Test.stopTest();

        System.assertNotEquals(null, res, 'Response must not be null');

        // Validate X options include only the referenced axis
        System.assertEquals(1, res.xOptions.size(), 'Exactly one X option expected');
        System.assertEquals(axes.get('x').Id, res.xOptions[0].id, 'X option must match referenced axis');
        System.assertEquals(axes.get('x').gf_axis_data_type_desc__c, res.xOptions[0].label, 'Label should map from gf_axis_data_type_desc__c');
        System.assertEquals(axes.get('x').gf_incremental_axis_type_number__c, res.xOptions[0].value, 'Value should map from gf_incremental_axis_type_number__c');
        System.assertEquals(axes.get('x').gf_data_type__c, res.xOptions[0].dataType, 'DataType should map from gf_data_type__c');

        // Validate Y options include only the referenced axis
        System.assertEquals(1, res.yOptions.size(), 'Exactly one Y option expected');
        System.assertEquals(axes.get('y').Id, res.yOptions[0].id, 'Y option must match referenced axis');
        System.assertEquals(axes.get('y').gf_axis_data_type_desc__c, res.yOptions[0].label, 'Label Y');
        System.assertEquals(axes.get('y').gf_incremental_axis_type_number__c, res.yOptions[0].value, 'Value Y');
        System.assertEquals(axes.get('y').gf_data_type__c, res.yOptions[0].dataType, 'DataType Y');

        // Validate Central options include only the referenced axis
        System.assertEquals(1, res.centralOptions.size(), 'Exactly one Central option expected');
        System.assertEquals(axes.get('c').Id, res.centralOptions[0].id, 'Central option must match referenced axis');
        System.assertEquals(axes.get('c').gf_axis_data_type_desc__c, res.centralOptions[0].label, 'Label C');
        System.assertEquals(axes.get('c').gf_incremental_axis_type_number__c, res.centralOptions[0].value, 'Value C');
        System.assertEquals(axes.get('c').gf_data_type__c, res.centralOptions[0].dataType, 'DataType C');

        // Validate combinations: two active combinations returned with proper ids
        System.assertEquals(2, res.combinations.size(), 'Two active combinations expected');
        for (DMT_ProfitabilityAxisSelectorController.ComboDTO cd : res.combinations) {
            System.assertEquals(axes.get('x').Id, cd.xId, 'X id must match');
            System.assertEquals(axes.get('y').Id, cd.yId, 'Y id must match');
            System.assertEquals(axes.get('c').Id, cd.centerId, 'Center id must match');
        }
    }

    @isTest
    static void test_getInitialOptions_multipleCalls_cacheableSafety() {
        // Data once
        setupAxesAndCombinations();

        Test.startTest();
        DMT_ProfitabilityAxisSelectorController.InitialOptionsResponse res1 =
            DMT_ProfitabilityAxisSelectorController.getInitialOptions();
        DMT_ProfitabilityAxisSelectorController.InitialOptionsResponse res2 =
            DMT_ProfitabilityAxisSelectorController.getInitialOptions();
        Test.stopTest();

        // Both calls should be consistent
        System.assertEquals(res1.xOptions.size(), res2.xOptions.size(), 'X size should be consistent');
        System.assertEquals(res1.yOptions.size(), res2.yOptions.size(), 'Y size should be consistent');
        System.assertEquals(res1.centralOptions.size(), res2.centralOptions.size(), 'Central size should be consistent');
        System.assertEquals(res1.combinations.size(), res2.combinations.size(), 'Combinations size should be consistent');
    }
}