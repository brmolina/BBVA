@IsTest
private class DMT_ProductSanctionControllerTest {
    @IsTest
    static void getData_returnsRiskRows() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();

        Test.startTest();
        DMT_ProductSanctionMigrationController.DataResponse response =
            DMT_ProductSanctionMigrationController.getData(line.Id);
        Test.stopTest();

        Assert.areEqual(line.Id, response.lineId);
        Assert.areNotEqual(null, response.risks);
        Assert.isTrue(response.risks.size() > 0, 'Expected at least one risk row');
    }

    @IsTest
    static void saveData_createsUpdatesAndDeletes() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();

        DMT_ProductSanctionMigrationController.RiskRow newRow =
            new DMT_ProductSanctionMigrationController.RiskRow();
        newRow.name = 'Risk Migration Test';
        newRow.amount = 12345;
        newRow.currencyIsoCode = 'EUR';
        newRow.initTerm = '1';
        newRow.endTerm = '6';
        newRow.riskType = 'Derivatives';
        newRow.priority = '99';

        DMT_ProductSanctionMigrationController.SaveResponse createResponse =
            DMT_ProductSanctionMigrationController.saveData(
                line.Id,
                new List<DMT_ProductSanctionMigrationController.RiskRow>{ newRow },
                null
            );

        Assert.areEqual(1, createResponse.upsertedCount);

        DMT_Risk_Line_Term__c createdRisk = [
            SELECT Id, Name, DMT_Amount__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :line.Id
            AND Name = 'Risk Migration Test'
            LIMIT 1
        ];

        DMT_ProductSanctionMigrationController.RiskRow updateRow =
            new DMT_ProductSanctionMigrationController.RiskRow();
        updateRow.id = createdRisk.Id;
        updateRow.name = 'Risk Migration Updated';
        updateRow.amount = 99999;
        updateRow.currencyIsoCode = 'EUR';
        updateRow.initTerm = '2';
        updateRow.endTerm = '7';
        updateRow.riskType = 'Derivatives';
        updateRow.priority = '98';

        DMT_ProductSanctionMigrationController.SaveResponse updateResponse =
            DMT_ProductSanctionMigrationController.saveData(
                line.Id,
                new List<DMT_ProductSanctionMigrationController.RiskRow>{ updateRow },
                null
            );

        Assert.areEqual(1, updateResponse.upsertedCount);

        DMT_Risk_Line_Term__c updatedRisk = [
            SELECT Id, Name, DMT_Amount__c
            FROM DMT_Risk_Line_Term__c
            WHERE Id = :createdRisk.Id
            LIMIT 1
        ];
        Assert.areEqual('Risk Migration Updated', updatedRisk.Name);
        Assert.areEqual(99999, updatedRisk.DMT_Amount__c);

        DMT_ProductSanctionMigrationController.SaveResponse deleteResponse =
            DMT_ProductSanctionMigrationController.saveData(
                line.Id,
                null,
                new List<Id>{ updatedRisk.Id }
            );

        Assert.areEqual(1, deleteResponse.deletedCount);
        Assert.areEqual(
            0,
            [SELECT COUNT() FROM DMT_Risk_Line_Term__c WHERE Id = :updatedRisk.Id]
        );
        }
    }

    private static User grantCurrentUserWriteRole() {
        User currentUser = [
            SELECT Id, DMT_User_Role__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        currentUser.DMT_User_Role__c = 'DMT_Proyecto';
        update currentUser;
        return currentUser;
    }

    @IsTest
    static void relatedSelections_roundTripReplacesWarrantyAndCurrency() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            DMT_Risk_Line_Term__c risk = firstRisk(line.Id);
            Map<String, Object> relatedValues = new Map<String, Object>{
                'DMT_Warranty__c.g_limits_grid_guarantee_type__c' => new List<Object>{ 'W1', 'W2', 'W1' },
                'DMT_Currency_Provision__c.g_currency_id__c' => 'EUR;USD;EUR'
            };

            Test.startTest();
            DMT_ProductSanctionMigrationController.saveRelatedSelections(line.Id, risk.Id, relatedValues);
            Map<String, List<String>> selected = DMT_ProductSanctionMigrationController.getRelatedSelections(risk.Id);
            Test.stopTest();

            Assert.areEqual(2, selected.get('DMT_Warranty__c.g_limits_grid_guarantee_type__c').size());
            Assert.areEqual(true, selected.get('DMT_Currency_Provision__c.g_currency_id__c').contains('EUR'));
            Assert.areEqual(true, selected.get('DMT_Currency_Provision__c.g_currency_id__c').contains('USD'));
        }
    }

    // CIBGLOBALD-3779: also covers parentProductName being persisted onto
    // DMT_Commercial_Product_Description__c.
    @IsTest
    static void addProducts_supportsIdsCodesAndOperationTypes() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            Product2 product = DMT_Test_DataFactory.generateProduct2();

            Test.startTest();
            DMT_ProductSanctionMigrationController.AddProductsResponse byIdResponse =
                DMT_ProductSanctionMigrationController.addProducts(
                    line.Id,
                    new List<Id>{ product.Id },
                    '12M',
                    null,
                    'Named Product From Id',
                    'Parent Category A',
                    'OPP'
                );
            DMT_ProductSanctionMigrationController.AddProductsResponse byCodeResponse =
                DMT_ProductSanctionMigrationController.addProducts(
                    line.Id,
                    null,
                    '18M',
                    product.ProductCode,
                    null,
                    'Parent Category B',
                    'LIN'
                );
            Test.stopTest();

            Assert.areEqual(1, byIdResponse.createdCount);
            Assert.areEqual(1, byCodeResponse.createdCount);

            List<DMT_Risk_Line_Term__c> insertedRows = [
                SELECT Id, Name, DMT_End_Term__c, DMT_Operation_Type__c, gf_group_priority_line_id__c,
                       DMT_Commercial_Product_Description__c
                FROM DMT_Risk_Line_Term__c
                WHERE DMT_Line__c = :line.Id AND DMT_Product__c = :product.Id
                ORDER BY CreatedDate ASC
            ];
            Assert.areEqual(2, insertedRows.size());
            Assert.areEqual('Named Product From Id', insertedRows[0].Name);
            Assert.areEqual('OPP', insertedRows[0].DMT_Operation_Type__c);
            Assert.areEqual('Parent Category A', insertedRows[0].DMT_Commercial_Product_Description__c);
            Assert.areEqual('LIN', insertedRows[1].DMT_Operation_Type__c);
            Assert.areEqual('Parent Category B', insertedRows[1].DMT_Commercial_Product_Description__c);
        }
    }

    @IsTest
    static void cloneRisk_copiesRelatedRecordsAndProductAssociation() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            DMT_Risk_Line_Term__c risk = firstRisk(line.Id);
            Map<String, Object> relatedValues = new Map<String, Object>{
                'DMT_Warranty__c.g_limits_grid_guarantee_type__c' => new List<Object>{ 'W1' },
                'DMT_Currency_Provision__c.g_currency_id__c' => new List<Object>{ 'EUR' }
            };
            DMT_ProductSanctionMigrationController.saveRelatedSelections(line.Id, risk.Id, relatedValues);
            Custom_Association__c sourceAssociation = createProductAssociation(line, risk.gf_group_priority_line_id__c);
            createProductAssociationClient(sourceAssociation.Id, sourceAssociation.gf_customer_group_id__c, 'ALPHA_SOURCE');

            Test.startTest();
            DMT_ProductSanctionMigrationController.CloneResponse response =
                DMT_ProductSanctionMigrationController.cloneRisk(risk.Id, line.Id);
            Test.stopTest();

            Assert.areNotEqual(null, response.clonedRiskId);
            DMT_Risk_Line_Term__c clonedRisk = [
                SELECT Id, Name, gf_group_priority_line_id__c
                FROM DMT_Risk_Line_Term__c
                WHERE Id = :response.clonedRiskId
            ];
            Assert.areNotEqual(null, clonedRisk.Name);
            Assert.areEqual(1, [SELECT COUNT() FROM DMT_Warranty__c WHERE DMT_Risk_Line_Term__c = :clonedRisk.Id]);
            Assert.areEqual(1, [SELECT COUNT() FROM DMT_Currency_Provision__c WHERE DMT_Risk_Line_Term__c = :clonedRisk.Id]);
            String clonedAssociationExternalId = line.Line_Id__c + '_' + clonedRisk.gf_group_priority_line_id__c;
            Assert.areEqual(
                1,
                [SELECT COUNT() FROM Custom_Association__c WHERE gf_customer_group_id__c = :clonedAssociationExternalId]
            );
            Assert.areEqual(
                1,
                [SELECT COUNT() FROM Custom_Association_Client__c WHERE gf_customer_group_id__c = :clonedAssociationExternalId]
            );
        }
    }

    @IsTest
    static void deleteRisk_removesProductAssociationAndResequencesRelatedRows() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            DMT_Risk_Line_Term__c firstRisk = firstRisk(line.Id);
            Product2 product = DMT_Test_DataFactory.generateProduct2();
            DMT_ProductSanctionMigrationController.addProducts(
                line.Id,
                new List<Id>{ product.Id },
                '9M',
                null,
                'Second Product',
                null,
                'LIN'
            );
            Custom_Association__c sourceAssociation = createProductAssociation(line, firstRisk.gf_group_priority_line_id__c);
            createProductAssociationClient(sourceAssociation.Id, sourceAssociation.gf_customer_group_id__c, 'ALPHA_DELETE');

            Test.startTest();
            DMT_ProductSanctionMigrationController.deleteRisk(firstRisk.Id, line.Id);
            Test.stopTest();

            Assert.areEqual(0, [SELECT COUNT() FROM DMT_Risk_Line_Term__c WHERE Id = :firstRisk.Id]);
            Assert.areEqual(0, [SELECT COUNT() FROM Custom_Association__c WHERE Id = :sourceAssociation.Id]);
            DMT_Risk_Line_Term__c remainingRisk = [
                SELECT gf_group_priority_line_id__c
                FROM DMT_Risk_Line_Term__c
                WHERE DMT_Line__c = :line.Id
                LIMIT 1
            ];
            Assert.areEqual('01', remainingRisk.gf_group_priority_line_id__c);
        }
    }

    private static DMT_Risk_Line_Term__c firstRisk(Id lineId) {
        return [
            SELECT Id, Name, gf_group_priority_line_id__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :lineId
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
    }

    private static Custom_Association__c createProductAssociation(DMT_Line__c line, String priorityId) {
        String externalId = line.Line_Id__c + '_' + priorityId;
        TriggerBypass.setBypass();
        Custom_Association__c association = new Custom_Association__c(
            Name = 'Product Association ' + externalId,
            DMT_Line__c = line.Id,
            gf_customer_group_id__c = externalId,
            g_customer_id__c = 'ALPHA_MAIN'
        );
        insert association;
        TriggerBypass.removeBypass();
        return association;
    }

    private static Custom_Association_Client__c createProductAssociationClient(
        Id associationId,
        String externalId,
        String alphaCode
    ) {
        TriggerBypass.setBypass();
        Custom_Association_Client__c client = new Custom_Association_Client__c(
            Custom_Association__c = associationId,
            Alpha_Code_Client__c = alphaCode,
            g_customer_id__c = alphaCode,
            gf_customer_group_id__c = externalId,
            Name = 'Client ' + alphaCode
        );
        insert client;
        TriggerBypass.removeBypass();
        return client;
    }

    @IsTest
    static void taxonomyFilterRule_supportsValAttributesAndContains() {
        DMT_Taxonomy_Values__c taxonomyValue = new DMT_Taxonomy_Values__c(
            DMT_Value__c = 'TEST_VALUE',
            DMT_Name__c = 'Test Taxonomy',
            DMT_Name_EN__c = 'Test Taxonomy EN',
            gf_catalog_atrb_val1_name_c__c = 'OL, OP, TO',
            gf_catalog_atrb_val5_name__c = 'OL;OP',
            gf_catalog_atrb_val10_name__c = 'FinalAttribute'
        );
        Map<String, Object> valuesByField =
            DMT_ProductSanctionMigrationController.buildTaxonomyFilterValues(taxonomyValue);

        Assert.areEqual(
            true,
            DMT_ProductSanctionMigrationController.matchesRuleAgainstValues(
                'gf_catalog_atrb_val1_name_c__c contains \'OL\'',
                valuesByField
            )
        );
        Assert.areEqual(
            true,
            DMT_ProductSanctionMigrationController.matchesRuleAgainstValues(
                'val5 contains \'OL\'',
                valuesByField
            )
        );
        Assert.areEqual(
            true,
            DMT_ProductSanctionMigrationController.matchesRuleAgainstValues(
                'gf_catalog_atrb_val5_name__c contains \'op\'',
                valuesByField
            )
        );
        Assert.areEqual(
            true,
            DMT_ProductSanctionMigrationController.matchesRuleAgainstValues(
                'val10 == \'FinalAttribute\' && val1 not contains \'Other\'',
                valuesByField
            )
        );
        Assert.areEqual(
            true,
            DMT_ProductSanctionMigrationController.matchesRuleAgainstValues(
                'val1 contains \'TL\' || val1 contains \'OL\'',
                valuesByField
            )
        );
    }

    @IsTest
    static void taxonomyCategoryOptionValue_usesVal1() {
        DMT_Taxonomy_Values__c categoryTaxonomyValue = new DMT_Taxonomy_Values__c(
            DMT_Value__c = 'INTERNAL_CATEGORY_VALUE',
            DMT_Name__c = 'Category Taxonomy',
            gf_catalog_atrb_val1_name_c__c = 'CATEGORY_CODE',
            gf_catalog_atrb_val4_name__c = 'Category'
        );
        DMT_Taxonomy_Values__c productTaxonomyValue = new DMT_Taxonomy_Values__c(
            DMT_Value__c = 'PRODUCT_VALUE',
            DMT_Name__c = 'Product Taxonomy',
            gf_catalog_atrb_val1_name_c__c = 'PRODUCT_ALIAS',
            gf_catalog_atrb_val4_name__c = 'Product'
        );

        Assert.areEqual(
            'CATEGORY_CODE',
            DMT_ProductSanctionMigrationController.resolveTaxonomyOptionValue(categoryTaxonomyValue),
            'Las categorías deben usar val1 como value para resolver la label.'
        );
        Assert.areEqual(
            'PRODUCT_VALUE',
            DMT_ProductSanctionMigrationController.resolveTaxonomyOptionValue(productTaxonomyValue),
            'Los productos deben seguir usando DMT_Value__c.'
        );
    }

    @IsTest
    static void controllerValidationBranches_returnExpectedErrors() {
        Boolean saveDataFailed = false;
        Boolean cloneFailed = false;
        Boolean deleteFailed = false;
        Boolean addProductsFailed = false;

        Test.startTest();
        try {
            DMT_ProductSanctionMigrationController.saveData(null, null, null);
        } catch (AuraHandledException ex) {
            saveDataFailed = true;
        }
        try {
            DMT_ProductSanctionMigrationController.cloneRisk(null, null);
        } catch (AuraHandledException ex) {
            cloneFailed = true;
        }
        try {
            DMT_ProductSanctionMigrationController.deleteRisk(null, null);
        } catch (AuraHandledException ex) {
            deleteFailed = true;
        }
        try {
            DMT_ProductSanctionMigrationController.addProducts(null, null, null, null, null, null, null);
        } catch (AuraHandledException ex) {
            addProductsFailed = true;
        }
        Test.stopTest();

        Assert.areEqual(true, saveDataFailed);
        Assert.areEqual(true, cloneFailed);
        Assert.areEqual(true, deleteFailed);
        Assert.areEqual(true, addProductsFailed);
    }

    @IsTest
    static void relatedSelections_acceptsEmptyAndNullValues() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            DMT_Risk_Line_Term__c risk = firstRisk(line.Id);
            Map<String, Object> relatedValues = new Map<String, Object>{
                'DMT_Warranty__c.g_limits_grid_guarantee_type__c' => new List<Object>{ null, '', 'W3', 'W3' },
                'DMT_Currency_Provision__c.g_currency_id__c' => ' ;EUR; ;EUR'
            };

            Test.startTest();
            DMT_ProductSanctionMigrationController.saveRelatedSelections(line.Id, risk.Id, null);
            DMT_ProductSanctionMigrationController.saveRelatedSelections(line.Id, risk.Id, relatedValues);
            Map<String, List<String>> selected = DMT_ProductSanctionMigrationController.getRelatedSelections(risk.Id);
            Test.stopTest();

            Assert.areEqual(1, selected.get('DMT_Warranty__c.g_limits_grid_guarantee_type__c').size());
            Assert.areEqual(1, selected.get('DMT_Currency_Provision__c.g_currency_id__c').size());
        }
    }

    @IsTest
    static void taxonomyFilterRule_supportsInNotInAndInequality() {
        Map<String, Object> valuesByField = new Map<String, Object>{
            'val1' => 'OL',
            'val2' => 'ACTIVE',
            'val3' => Decimal.valueOf(7)
        };

        Assert.areEqual(
            true,
            DMT_ProductSanctionMigrationController.matchesRuleAgainstValues(
                'val1 in [OL, OP] && val2 != "INACTIVE"',
                valuesByField
            )
        );
        Assert.areEqual(
            true,
            DMT_ProductSanctionMigrationController.matchesRuleAgainstValues(
                'val1 not in [TL, TO]',
                valuesByField
            )
        );
        Assert.areEqual(
            false,
            DMT_ProductSanctionMigrationController.matchesRuleAgainstValues(
                'val1 in [TL] && val3 == 7',
                valuesByField
            )
        );
    }

    @IsTest
    static void addProducts_throwsWhenNoProductIdentifiersProvided() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            Boolean threw = false;

            Test.startTest();
            try {
                DMT_ProductSanctionMigrationController.addProducts(
                    line.Id, null, null, null, null, null, 'LIN'
                );
            } catch (AuraHandledException ex) {
                threw = true;
            }
            Test.stopTest();

            Assert.isTrue(threw, 'Expected addProducts to reject a call with no productIds and no selectedCodes');
        }
    }

    @IsTest
    static void addProducts_blankSelectedTermsLeavesEndTermNull() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            Product2 product = DMT_Test_DataFactory.generateProduct2();

            Test.startTest();
            DMT_ProductSanctionMigrationController.addProducts(
                line.Id, new List<Id>{ product.Id }, null, null, 'No Term Product', null, 'LIN'
            );
            Test.stopTest();

            DMT_Risk_Line_Term__c inserted = [
                SELECT Id, DMT_End_Term__c
                FROM DMT_Risk_Line_Term__c
                WHERE DMT_Line__c = :line.Id AND DMT_Product__c = :product.Id
                LIMIT 1
            ];
            Assert.areEqual(null, inserted.DMT_End_Term__c);
        }
    }

    @IsTest
    static void addProducts_priorityAboveNineUsesRawNumber() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            List<Id> productIds = new List<Id>();
            for (Integer i = 0; i < 10; i++) {
                Product2 product = new Product2(
                    Name = 'Bulk Product ' + i,
                    ProductCode = 'BULK-' + i,
                    IsActive = true
                );
                insert product;
                productIds.add(product.Id);
            }

            Test.startTest();
            DMT_ProductSanctionMigrationController.addProducts(
                line.Id, productIds, null, null, null, null, 'LIN'
            );
            Test.stopTest();

            Integer totalRisks = [SELECT COUNT() FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id];
            Assert.isTrue(totalRisks >= 10, 'Expected at least 10 risk rows to push priority past 9');
            Integer doubleDigitPriorityRisks = [
                SELECT COUNT()
                FROM DMT_Risk_Line_Term__c
                WHERE DMT_Line__c = :line.Id AND gf_group_priority_line_id__c = '10'
            ];
            Assert.areEqual(1, doubleDigitPriorityRisks, 'Expected a risk row with the unpadded priority 10');
        }
    }

    @IsTest
    static void applyProductHierarchy_allLevelsFromNumericCode() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            Map<String, String> codeByLevel = new Map<String, String>{
                'L1' => '1200000000',
                'L2' => '1234000000',
                'L3' => '1234560000',
                'L4' => '1234567800',
                'L5' => '1234567891'
            };
            Map<String, Id> productIdByLevel = new Map<String, Id>();
            for (String level : codeByLevel.keySet()) {
                Product2 product = new Product2(
                    Name = 'Hierarchy Product ' + level,
                    ProductCode = codeByLevel.get(level),
                    IsActive = true
                );
                insert product;
                productIdByLevel.put(level, product.Id);
            }

            Test.startTest();
            for (String level : productIdByLevel.keySet()) {
                DMT_ProductSanctionMigrationController.addProducts(
                    line.Id, new List<Id>{ productIdByLevel.get(level) }, null, null, null, null, 'LIN'
                );
            }
            Test.stopTest();

            DMT_Risk_Line_Term__c level1Risk = [
                SELECT g_global_product_family_id__c, g_global_product_subfamily_id__c
                FROM DMT_Risk_Line_Term__c
                WHERE DMT_Product__c = :productIdByLevel.get('L1')
                LIMIT 1
            ];
            Assert.areEqual('1200000000', level1Risk.g_global_product_family_id__c);
            Assert.areEqual(null, level1Risk.g_global_product_subfamily_id__c);

            DMT_Risk_Line_Term__c level5Risk = [
                SELECT g_global_product_id__c
                FROM DMT_Risk_Line_Term__c
                WHERE DMT_Product__c = :productIdByLevel.get('L5')
                LIMIT 1
            ];
            Assert.areEqual('1234567891', level5Risk.g_global_product_id__c);
        }
    }

    @IsTest
    static void deleteRisk_lastRiskOnLineLeavesLineEmpty() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            DMT_Risk_Line_Term__c onlyRisk = firstRisk(line.Id);

            Test.startTest();
            DMT_ProductSanctionMigrationController.deleteRisk(onlyRisk.Id, line.Id);
            Test.stopTest();

            Assert.areEqual(0, [SELECT COUNT() FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id]);
        }
    }

    @IsTest
    static void resequenceRiskPriorities_remapsWarrantyAndCurrencyRows() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            DMT_Risk_Line_Term__c firstRisk = firstRisk(line.Id);
            Product2 product = DMT_Test_DataFactory.generateProduct2();
            DMT_ProductSanctionMigrationController.addProducts(
                line.Id, new List<Id>{ product.Id }, null, null, 'Second Risk', null, 'LIN'
            );
            DMT_Risk_Line_Term__c secondRisk = [
                SELECT Id
                FROM DMT_Risk_Line_Term__c
                WHERE DMT_Line__c = :line.Id AND Id != :firstRisk.Id
                LIMIT 1
            ];
            DMT_ProductSanctionMigrationController.saveRelatedSelections(
                line.Id,
                secondRisk.Id,
                new Map<String, Object>{
                    'DMT_Warranty__c.g_limits_grid_guarantee_type__c' => new List<Object>{ 'W1' },
                    'DMT_Currency_Provision__c.g_currency_id__c' => new List<Object>{ 'EUR' }
                }
            );

            Test.startTest();
            DMT_ProductSanctionMigrationController.deleteRisk(firstRisk.Id, line.Id);
            Test.stopTest();

            DMT_Risk_Line_Term__c resequencedRisk = [
                SELECT gf_group_priority_line_id__c
                FROM DMT_Risk_Line_Term__c
                WHERE Id = :secondRisk.Id
            ];
            Assert.areEqual('01', resequencedRisk.gf_group_priority_line_id__c);
            DMT_Warranty__c remappedWarranty = [
                SELECT gf_group_priority_line_id__c
                FROM DMT_Warranty__c
                WHERE DMT_Risk_Line_Term__c = :secondRisk.Id
                LIMIT 1
            ];
            Assert.areEqual('01', remappedWarranty.gf_group_priority_line_id__c);
        }
    }

    @IsTest
    static void cloneRisk_withNoRelatedRecords_skipsCloningRelated() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            DMT_Risk_Line_Term__c risk = firstRisk(line.Id);

            Test.startTest();
            DMT_ProductSanctionMigrationController.CloneResponse response =
                DMT_ProductSanctionMigrationController.cloneRisk(risk.Id, line.Id);
            Test.stopTest();

            Assert.areNotEqual(null, response.clonedRiskId);
            Assert.areEqual(0, [SELECT COUNT() FROM DMT_Warranty__c WHERE DMT_Risk_Line_Term__c = :response.clonedRiskId]);
            Assert.areEqual(0, [SELECT COUNT() FROM DMT_Currency_Provision__c WHERE DMT_Risk_Line_Term__c = :response.clonedRiskId]);
        }
    }

    @IsTest
    static void getRelatedSelections_skipsBlankStoredValues() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            DMT_Risk_Line_Term__c risk = firstRisk(line.Id);

            TriggerBypass.setBypass();
            insert new DMT_Warranty__c(
                DMT_Risk_Line_Term__c = risk.Id,
                g_limits_grid_guarantee_type__c = null
            );
            insert new DMT_Currency_Provision__c(
                DMT_Risk_Line_Term__c = risk.Id,
                g_currency_id__c = null
            );
            TriggerBypass.removeBypass();

            Test.startTest();
            Map<String, List<String>> selected = DMT_ProductSanctionMigrationController.getRelatedSelections(risk.Id);
            Test.stopTest();

            Assert.areEqual(0, selected.get('DMT_Warranty__c.g_limits_grid_guarantee_type__c').size());
            Assert.areEqual(0, selected.get('DMT_Currency_Provision__c.g_currency_id__c').size());
        }
    }

    @IsTest
    static void saveRelatedSelections_throwsWhenRiskIdMissing() {
        Boolean threw = false;

        Test.startTest();
        try {
            DMT_ProductSanctionMigrationController.saveRelatedSelections(null, null, null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'Expected saveRelatedSelections to require a riskId');
    }

    @IsTest
    static void relatedSelections_secondSaveDeletesPreviousRows() {
        User currentUser = grantCurrentUserWriteRole();

        System.runAs(currentUser) {
            DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
            DMT_Risk_Line_Term__c risk = firstRisk(line.Id);
            Map<String, Object> firstPayload = new Map<String, Object>{
                'DMT_Warranty__c.g_limits_grid_guarantee_type__c' => new List<Object>{ 'W1' },
                'DMT_Currency_Provision__c.g_currency_id__c' => new List<Object>{ 'EUR' }
            };
            DMT_ProductSanctionMigrationController.saveRelatedSelections(line.Id, risk.Id, firstPayload);

            Map<String, Object> secondPayload = new Map<String, Object>{
                'DMT_Warranty__c.g_limits_grid_guarantee_type__c' => new List<Object>{ 'W2' },
                'DMT_Currency_Provision__c.g_currency_id__c' => new List<Object>{ 'USD' }
            };

            Test.startTest();
            DMT_ProductSanctionMigrationController.saveRelatedSelections(line.Id, risk.Id, secondPayload);
            Test.stopTest();

            List<DMT_Warranty__c> warranties = [
                SELECT g_limits_grid_guarantee_type__c
                FROM DMT_Warranty__c
                WHERE DMT_Risk_Line_Term__c = :risk.Id
            ];
            Assert.areEqual(1, warranties.size());
            Assert.areEqual('W2', warranties[0].g_limits_grid_guarantee_type__c);

            List<DMT_Currency_Provision__c> currencies = [
                SELECT g_currency_id__c
                FROM DMT_Currency_Provision__c
                WHERE DMT_Risk_Line_Term__c = :risk.Id
            ];
            Assert.areEqual(1, currencies.size());
            Assert.areEqual('USD', currencies[0].g_currency_id__c);
        }
    }

    // Note: a dedicated "no access" test was attempted here but dropped — the test-running user
    // (whoever deploys/runs this suite) already carries the DMT_Line_God custom permission, which
    // resolveLineAccess() checks first and short-circuits to canEdit=true for any Draft line
    // regardless of DMT_User_Role__c/team membership. FeatureManagement.checkPermission isn't
    // mockable via test DML, so exercising the hasWriteAccess()==false / team-member branches in
    // resolveLineAccess (lines ~708-742) needs a genuinely separate, purpose-built test user
    // without that permission — out of scope for this coverage pass.

    @IsTest
    static void resolveFieldApiName_resolvesDirectLowerAndUnsuffixedCandidates() {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.DMT_Risk_Line_Term__c.fields.getMap();
        Map<String, String> lowerToFieldApi = new Map<String, String>();
        Map<String, String> lowerNoSuffixToFieldApi = new Map<String, String>();
        for (String apiName : fieldMap.keySet()) {
            String lowerApi = apiName.toLowerCase();
            lowerToFieldApi.put(lowerApi, apiName);
            String noSuffix = lowerApi.endsWith('__c') ? lowerApi.substring(0, lowerApi.length() - 3) : lowerApi;
            if (!lowerNoSuffixToFieldApi.containsKey(noSuffix)) {
                lowerNoSuffixToFieldApi.put(noSuffix, apiName);
            }
        }

        Assert.areEqual(
            null,
            DMT_ProductSanctionMigrationController.resolveFieldApiName(null, fieldMap, lowerToFieldApi, lowerNoSuffixToFieldApi)
        );
        Assert.areEqual(
            'DMT_Amount__c',
            DMT_ProductSanctionMigrationController.resolveFieldApiName('DMT_Risk_Line_Term__c.DMT_Amount__c', fieldMap, lowerToFieldApi, lowerNoSuffixToFieldApi)
        );
        Assert.areEqual(
            'dmt_amount__c',
            DMT_ProductSanctionMigrationController.resolveFieldApiName('DMT_Amount', fieldMap, lowerToFieldApi, lowerNoSuffixToFieldApi)
        );
        Assert.areEqual(
            null,
            DMT_ProductSanctionMigrationController.resolveFieldApiName('Not_A_Real_Field', fieldMap, lowerToFieldApi, lowerNoSuffixToFieldApi)
        );
    }

    @IsTest
    static void parseTaxonomyLiteral_parsesQuotedBooleanNumericAndPlainValues() {
        Assert.areEqual('abc', DMT_ProductSanctionMigrationController.parseTaxonomyLiteral('\'abc\''));
        Assert.areEqual('abc', DMT_ProductSanctionMigrationController.parseTaxonomyLiteral('"abc"'));
        Assert.areEqual(true, DMT_ProductSanctionMigrationController.parseTaxonomyLiteral('true'));
        Assert.areEqual(false, DMT_ProductSanctionMigrationController.parseTaxonomyLiteral('FALSE'));
        Assert.areEqual(Decimal.valueOf('7.5'), DMT_ProductSanctionMigrationController.parseTaxonomyLiteral('7.5'));
        Assert.areEqual('plain', DMT_ProductSanctionMigrationController.parseTaxonomyLiteral('plain'));
    }

    @IsTest
    static void toDecimalValue_convertsSupportedTypes() {
        Assert.areEqual(null, DMT_ProductSanctionMigrationController.toDecimalValue(null));
        Assert.areEqual(Decimal.valueOf('3'), DMT_ProductSanctionMigrationController.toDecimalValue(Decimal.valueOf('3')));
        Assert.areEqual(Decimal.valueOf(4), DMT_ProductSanctionMigrationController.toDecimalValue(4));
        Assert.areEqual(Decimal.valueOf('5'), DMT_ProductSanctionMigrationController.toDecimalValue((Long)5));
        Assert.areEqual(null, DMT_ProductSanctionMigrationController.toDecimalValue('not-a-number'));
    }

    @IsTest
    static void resolveTemplateType_mapsRecordTypeNamesToBuckets() {
        Assert.areEqual('OL', DMT_ProductSanctionMigrationController.resolveTemplateType('Line (Other Products)'));
        Assert.areEqual('SANCTION', DMT_ProductSanctionMigrationController.resolveTemplateType('Approval'));
        Assert.areEqual('OP', DMT_ProductSanctionMigrationController.resolveTemplateType('Settlement'));
    }

    @IsTest
    static void getDefaultFieldConfigs_returnsOrderedDefaults() {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.DMT_Risk_Line_Term__c.fields.getMap();

        List<DMT_ProductSanctionMigrationController.FieldConfig> defaults =
            DMT_ProductSanctionMigrationController.getDefaultFieldConfigs(fieldMap);

        Assert.isTrue(defaults.size() > 0, 'Expected at least one default field config');
        Assert.areEqual('Name', defaults[0].fieldApiName);
        Assert.areEqual(1, defaults[0].fieldOrder);
        Assert.areEqual(false, defaults[0].isRequired);
    }
}