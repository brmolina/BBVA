/**
* @description Test class for Arc_Gen_FieldConfig_Data.
*/
@isTest
private class Arc_Gen_FieldConfig_Data_Test {
    /**
    * @description Validates getMapFieldsInfo returns a map for the given field names.
    */
    @isTest static void testGetMapFieldsInfoValidFields() {
        final List<String> fieldNames = new List<String>{'NonExistentField__c'};

        Test.startTest();
        final Map<String, dyfr__Field_Config__c> result = Arc_Gen_FieldConfig_Data.getMapFieldsInfo(fieldNames);
        Test.stopTest();

        Assert.isNotNull(result, 'Result map should not be null');
    }

    /**
    * @description Validates getDevFieldsInfo returns a map for the given developer names.
    */
    @isTest static void testGetDevFieldsInfoValidNames() {
        final List<String> devNames = new List<String>{'NonExistentDevName'};

        Test.startTest();
        final Map<String, dyfr__Field_Config__c> result = Arc_Gen_FieldConfig_Data.getDevFieldsInfo(devNames);
        Test.stopTest();

        Assert.isNotNull(result, 'Result map should not be null');
    }

    /**
    * @description Validates fillMapTabset populates a section-keyed map from template and search maps.
    */
    @isTest static void testFillMapTabsetValidMaps() {
        final dyfr__Field_Config__c fc1 = new dyfr__Field_Config__c(dyfr__DeveloperName__c = 'field1');
        final Map<String, dyfr__Field_Config__c> mapSearchFc = new Map<String, dyfr__Field_Config__c>{
            'field1' => fc1
        };
        final Map<String, List<String>> mapTemplateFc = new Map<String, List<String>>{
            'Section1' => new List<String>{'field1'}
        };

        Test.startTest();
        final Map<String, List<dyfr__Field_Config__c>> result = Arc_Gen_FieldConfig_Data.fillMapTabset(mapSearchFc, mapTemplateFc);
        Test.stopTest();

        Assert.isTrue(result.containsKey('Section1') && result.get('Section1').size() == 1,
            'Result should contain the section key with one field config');
    }

    /**
    * @description Validates hasFieldSections returns true when all sections are present.
    */
    @isTest static void testHasFieldSectionsMatch() {
        final List<dyfr__Field_Config__c> lstFc = new List<dyfr__Field_Config__c>{
            new dyfr__Field_Config__c(dyfr__Section_name__c = 'SectionA'),
            new dyfr__Field_Config__c(dyfr__Section_name__c = 'SectionB')
        };
        final List<String> lstSections = new List<String>{'SectionA', 'SectionB'};

        Test.startTest();
        final Boolean result = Arc_Gen_FieldConfig_Data.hasFieldSections(lstFc, lstSections);
        Test.stopTest();

        Assert.isTrue(result, 'Should return true when all sections match');
    }

    /**
    * @description Validates hasFieldSections returns false when a section is missing.
    */
    @isTest static void testHasFieldSectionsMissing() {
        final List<dyfr__Field_Config__c> lstFc = new List<dyfr__Field_Config__c>{
            new dyfr__Field_Config__c(dyfr__Section_name__c = 'SectionA')
        };
        final List<String> lstSections = new List<String>{'SectionA', 'SectionC'};

        Test.startTest();
        final Boolean result = Arc_Gen_FieldConfig_Data.hasFieldSections(lstFc, lstSections);
        Test.stopTest();

        Assert.isFalse(result, 'Should return false when a section is missing');
    }

    /**
    * @description Validates getFieldConfigsByQualitativeCode returns empty map for non-existent codes.
    */
    @isTest static void testGetFieldConfigsByQualCodeEmpty() {
        final Set<String> codes = new Set<String>{'NONEXISTENT_CODE_XYZ'};

        Test.startTest();
        final Map<String, dyfr__Field_Config__c> result = Arc_Gen_FieldConfig_Data.getFieldConfigsByQualitativeCode(codes);
        Test.stopTest();

        Assert.isTrue(result != null && result.isEmpty(), 'Should return empty map for non-existent codes');
    }

    /**
    * @description Validates getDependValByQualitativeCode returns empty map for a non-existent code.
    */
    @isTest static void testGetDependValByQualCodeEmpty() {
        Test.startTest();
        final Map<String, String> result = Arc_Gen_FieldConfig_Data.getDependValByQualitativeCode('NONEXISTENT_CODE_XYZ');
        Test.stopTest();

        Assert.isTrue(result != null && result.isEmpty(), 'Should return empty map for non-existent code');
    }

    /**
    * @description Validates getQualQuestionByTabs returns empty map for non-existent tab codes.
    */
    @isTest static void testGetQualQuestionByTabsEmpty() {
        final Set<String> tabCodes = new Set<String>{'NONEXISTENT_TAB_CODE'};

        Test.startTest();
        final Map<String, dyfr__Field_Config__c> result = Arc_Gen_FieldConfig_Data.getQualQuestionByTabs(tabCodes);
        Test.stopTest();

        Assert.isTrue(result != null && result.isEmpty(), 'Should return empty map for non-existent tab codes');
    }
}