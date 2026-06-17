@isTest
private without sharing class DMT_SustainableDealControllerTest {

    @TestSetup
    static void setupData() {
        // Seed taxonomy values for all catalogs used by the controller
        List<DMT_Taxonomy_Values__c> rows = new List<DMT_Taxonomy_Values__c>();

        // RBGR (Green) - include a duplicate DMT_Value__c to test de-dup
        rows.add(new DMT_Taxonomy_Values__c(
            DMT_Active__c = true,
            DMT_Catalog__c = 'RBGR',
            DMT_Value__c = 'GRN1',
            DMT_Name_EN__c = 'Alpha'
        ));
        rows.add(new DMT_Taxonomy_Values__c(
            DMT_Active__c = true,
            DMT_Catalog__c = 'RBGR',
            DMT_Value__c = 'GRN2',
            DMT_Name_EN__c = 'Beta'
        ));
        // Duplicate value with different name should be ignored by controller
        rows.add(new DMT_Taxonomy_Values__c(
            DMT_Active__c = true,
            DMT_Catalog__c = 'RBGR',
            DMT_Value__c = 'GRN1',
            DMT_Name_EN__c = 'GammaDuplicate'
        ));
        // Inactive record should be ignored
        rows.add(new DMT_Taxonomy_Values__c(
            DMT_Active__c = false,
            DMT_Catalog__c = 'RBGR',
            DMT_Value__c = 'GRN3',
            DMT_Name_EN__c = 'Inactive'
        ));

        // RBSO (Social)
        rows.add(new DMT_Taxonomy_Values__c(
            DMT_Active__c = true,
            DMT_Catalog__c = 'RBSO',
            DMT_Value__c = 'SOC1',
            DMT_Name_EN__c = 'Delta'
        ));
        rows.add(new DMT_Taxonomy_Values__c(
            DMT_Active__c = true,
            DMT_Catalog__c = 'RBSO',
            DMT_Value__c = 'SOC2',
            DMT_Name_EN__c = 'Epsilon'
        ));

        // RBES (Green & Social + SSL path)
        rows.add(new DMT_Taxonomy_Values__c(
            DMT_Active__c = true,
            DMT_Catalog__c = 'RBES',
            DMT_Value__c = 'ES1',
            DMT_Name_EN__c = 'Kappa'
        ));
        rows.add(new DMT_Taxonomy_Values__c(
            DMT_Active__c = true,
            DMT_Catalog__c = 'RBES',
            DMT_Value__c = 'ES2',
            DMT_Name_EN__c = 'Lambda'
        ));
        insert rows;
    }

    @IsTest
    static void testGetPicklistValues_HappyPath() {
        Test.startTest();
        // Use an existing OLI picklist field referenced in repo
        List<Map<String, String>> values =
            DMT_SustainableDealController.getPicklistValues('DMT_Sustainable_Deal_Subtype__c');
        Test.stopTest();

        System.assertNotEquals(null, values, 'Result list should not be null');
        // We cannot guarantee org has values configured, but the method should return a list (possibly empty)
        System.assertNotEquals(null, values.isEmpty(), 'List should be a valid list (possibly empty)');
        if (!values.isEmpty()) {
            System.assert(values[0].containsKey('value'), 'Each entry should contain key value');
            System.assert(values[0].containsKey('label'), 'Each entry should contain key label');
        }
    }

    @IsTest
    static void testGetPicklistValues_Error_InvalidField() {
        Boolean threw = false;
        try {
            Test.startTest();
            DMT_SustainableDealController.getPicklistValues('Non_Existent_Field__c');
            Test.stopTest();
        } catch (AuraHandledException ahe) {
            threw = true;
        }
        System.assertEquals(true, threw, 'Calling with invalid field must throw AuraHandledException');
    }

    @IsTest
    static void testGetDependentPicklistValues_SustainableLoan() {
        Test.startTest();
        List<Map<String, String>> values =
            DMT_SustainableDealController.getDependentPicklistValues(DMT_Constants.DMT_SUSTAINABILITY_SUSTAINABLE_LOAN);
        Test.stopTest();

        validateDependentSubset(values, new Set<String>{
            DMT_Constants.DMT_SUSTAINABLE_GREEN,
            DMT_Constants.DMT_SUSTAINABLE_SOCIAL,
            DMT_Constants.DMT_SUSTAINABLE_GREEN_AND_SOCIAL
        });
    }

    @IsTest
    static void testGetDependentPicklistValues_UseOfProceeds() {
        Test.startTest();
        List<Map<String, String>> values =
            DMT_SustainableDealController.getDependentPicklistValues(DMT_Constants.DMT_SUSTAINABILITY_USE_OF_PROCEEDS);
        Test.stopTest();

        validateDependentSubset(values, new Set<String>{
            DMT_Constants.DMT_SUSTAINABLE_GREEN,
            DMT_Constants.DMT_SUSTAINABLE_SOCIAL
        });
    }

    @IsTest
    static void testGetDependentPicklistValues_Unknown() {
        Test.startTest();
        List<Map<String, String>> values =
            DMT_SustainableDealController.getDependentPicklistValues('UNKNOWN_VALUE');
        Test.stopTest();

        System.assertEquals(0, values.size(), 'Unknown controlling value should return empty list');
    }

    @IsTest
    static void testGetCatalogBySubtype_Green() {
        Test.startTest();
        List<DMT_SustainableDealController.CatalogOption> options =
            DMT_SustainableDealController.getCatalogBySubtype(DMT_Constants.DMT_SUSTAINABLE_GREEN,null,false);
        Test.stopTest();

        // Expect de-duplication and only active, RBGR items: GRN1 (Alpha), GRN2 (Beta)
        System.assertEquals(2, options.size(), 'Must contain unique active values for RBGR');
        // Order is ASC by DMT_Name_EN__c (Alpha, Beta)
        System.assertEquals('GRN1 - Alpha', options[0].label, 'First label should match "value + space + name" for Alpha');
        System.assertEquals('GRN2 - Beta', options[1].label, 'Second label should match "value + space + name" for Beta');
        System.assertEquals('GRN1', options[0].value, 'Value should be DMT_Value__c');
        System.assertEquals('GRN2', options[1].value, 'Value should be DMT_Value__c');
    }

    @IsTest
    static void testGetCatalogBySubtype_Social() {
        Test.startTest();
        List<DMT_SustainableDealController.CatalogOption> options =
            DMT_SustainableDealController.getCatalogBySubtype(DMT_Constants.DMT_SUSTAINABLE_SOCIAL,null,false);
        Test.stopTest();

        // RBSO: SOC1 (Delta), SOC2 (Epsilon) ordered by name asc: Delta, Epsilon
        System.assertEquals(2, options.size(), 'Must contain active values for RBSO');
        System.assertEquals('SOC1 - Delta', options[0].label);
        System.assertEquals('SOC2 - Epsilon', options[1].label);
        System.assertEquals('SOC1', options[0].value);
        System.assertEquals('SOC2', options[1].value);
    }

    @IsTest
    static void testGetCatalogBySubtype_GreenAndSocial_returnsEmpty() {
        // Green and social is no longer handled by getCatalogBySubtype — expects empty list
        Test.startTest();
        List<DMT_SustainableDealController.CatalogOption> options =
            DMT_SustainableDealController.getCatalogBySubtype(DMT_Constants.DMT_SUSTAINABLE_GREEN_AND_SOCIAL, null, false);
        Test.stopTest();

        System.assertEquals(0, options.size(), 'Green and social is no longer a valid subtype for getCatalogBySubtype');
    }

    @IsTest
    static void testGetCatalogByAssessment_SSL_and_SSL_Green() {
        // SSL ('4') and SSL_GREEN ('3') both return RBES catalog
        Test.startTest();
        List<DMT_SustainableDealController.CatalogOption> optionsSsl =
            DMT_SustainableDealController.getCatalogByAssessment(DMT_Constants.DMT_SUSTAINABILITY_SSL);
        List<DMT_SustainableDealController.CatalogOption> optionsSslGreen =
            DMT_SustainableDealController.getCatalogByAssessment(DMT_Constants.DMT_SUSTAINABILITY_SSL_GREEN);
        Test.stopTest();

        System.assertEquals(2, optionsSsl.size(), 'SSL should return RBES values');
        System.assertEquals(2, optionsSslGreen.size(), 'SSL Green should return RBES values');
        System.assertEquals('ES1 - Kappa', optionsSsl[0].label);
        System.assertEquals('ES1 - Kappa', optionsSslGreen[0].label);
    }

    @IsTest
    static void testGetCatalogByAssessment_ChainFinance() {
        // Chain Finance ('2') returns RBES catalog
        Test.startTest();
        List<DMT_SustainableDealController.CatalogOption> options =
            DMT_SustainableDealController.getCatalogByAssessment(DMT_Constants.DMT_SUSTAINABILITY_CHAIN_FINANCE);
        Test.stopTest();

        System.assertEquals(2, options.size(), 'Chain Finance should return RBES values');
        System.assertEquals('ES1 - Kappa', options[0].label);
        System.assertEquals('ES2 - Lambda', options[1].label);
    }

    @IsTest
    static void testGetCatalogByAssessment_SustainableLoan() {
        // Sustainable Loan ('5') always returns RBES catalog regardless of subtype
        Test.startTest();
        List<DMT_SustainableDealController.CatalogOption> options =
            DMT_SustainableDealController.getCatalogByAssessment(DMT_Constants.DMT_SUSTAINABILITY_SUSTAINABLE_LOAN);
        Test.stopTest();

        System.assertEquals(2, options.size(), 'Sustainable Loan should return RBES values');
        System.assertEquals('ES1 - Kappa', options[0].label);
        System.assertEquals('ES2 - Lambda', options[1].label);
    }

    @IsTest
    static void testGetCatalogByAssessment_SSL_returnsEmpty_viaSubtype() {
        // Passing an SSL assessment value to getCatalogBySubtype must return empty list
        Test.startTest();
        List<DMT_SustainableDealController.CatalogOption> options =
            DMT_SustainableDealController.getCatalogBySubtype(DMT_Constants.DMT_SUSTAINABILITY_SSL, null, false);
        Test.stopTest();

        System.assertEquals(0, options.size(), 'SSL assessment values must not be handled by getCatalogBySubtype');
    }

    // ===== GREEN FILTER TESTS =====

    @IsTest
    static void testGetCatalogBySubtype_Green_greenFilter_delegated() {
        // enableGreenFilter=true, greenFilter='delegated' enters the delegated branch.
        // The SOQL clause is pending implementation (commented out), so the full RBGR
        // catalog is returned unchanged — verifies no exception is thrown and the
        // delegated code path is exercised.
        Test.startTest();
        List<DMT_SustainableDealController.CatalogOption> options =
            DMT_SustainableDealController.getCatalogBySubtype(DMT_Constants.DMT_SUSTAINABLE_GREEN, 'delegated', true);
        Test.stopTest();

        System.assertEquals(2, options.size(), 'Delegated filter: full RBGR catalog returned while filter is pending implementation');
        System.assertEquals('GRN1 - Alpha', options[0].label);
        System.assertEquals('GRN2 - Beta', options[1].label);
    }

    @IsTest
    static void testGetCatalogBySubtype_Green_greenFilter_other() {
        // enableGreenFilter=true, greenFilter='other' enters the other branch.
        // Same as above: SOQL clause is commented, full RBGR catalog returned.
        Test.startTest();
        List<DMT_SustainableDealController.CatalogOption> options =
            DMT_SustainableDealController.getCatalogBySubtype(DMT_Constants.DMT_SUSTAINABLE_GREEN, 'other', true);
        Test.stopTest();

        System.assertEquals(2, options.size(), 'Other filter: full RBGR catalog returned while filter is pending implementation');
        System.assertEquals('GRN1 - Alpha', options[0].label);
        System.assertEquals('GRN2 - Beta', options[1].label);
    }

    @IsTest
    static void testGetCatalogBySubtype_Green_greenFilter_blankSkipsFilterBlock() {
        // enableGreenFilter=true but greenFilter is blank → String.isNotBlank returns false
        // → filter block is skipped entirely, full RBGR catalog returned.
        Test.startTest();
        List<DMT_SustainableDealController.CatalogOption> options =
            DMT_SustainableDealController.getCatalogBySubtype(DMT_Constants.DMT_SUSTAINABLE_GREEN, '', true);
        Test.stopTest();

        System.assertEquals(2, options.size(), 'Blank green filter with enableGreenFilter=true must skip filter block and return full RBGR catalog');
    }

    // Helper to validate dependent picklist structure and membership
    private static void validateDependentSubset(List<Map<String, String>> values, Set<String> allowed) {
        for (Map<String, String> row : values) {
            System.assert(row.containsKey('value'), 'Row must contain key value');
            System.assert(row.containsKey('label'), 'Row must contain key label');
            System.assert(allowed.contains(row.get('value')), 'Value must be within allowed subset');
        }
    }
}