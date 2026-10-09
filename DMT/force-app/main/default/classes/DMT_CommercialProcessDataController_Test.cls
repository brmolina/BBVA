/**
 * @description Test class for DMT_CommercialProcessDataController.
 *              Uses DMT_Test_DataFactory to build test data.
 */
@isTest
private class DMT_CommercialProcessDataController_Test {

    // ═══════════════════════════════════════════════════════════════════════════
    // getCommercialProcessData
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testGetCommercialProcessData_Success() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        update new Opportunity(
            Id = opp.Id,
            DES_Countries__c = 'AR;AE',
            DES_Description_rich__c = 'Test description',
            DES_Comments__c = 'Some comments'
        );

        Test.startTest();
        Opportunity result = DMT_CommercialProcessDataController.getCommercialProcessData(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(opp.Id, result.Id, 'Returned Opportunity Id should match');
        // Salesforce normalizes multiselect picklist storage order to match the field's
        // valueSet definition order (AB, AE, AR, ...), not insertion order.
        System.assertEquals('AE;AR', result.DES_Countries__c, 'Countries should match');
        System.assertEquals('Some comments', result.DES_Comments__c, 'Comments should match');
    }

    @isTest
    static void testGetCommercialProcessData_NoRecordFound_ThrowsException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            DMT_CommercialProcessDataController.getCommercialProcessData(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'An exception should be thrown when no matching Opportunity is found');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // saveCommercialProcessData - Success flows
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testSaveCommercialProcessData_Success_FullFlow() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        Passport__c passport = new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = '{}');
        insert passport;

        Map<String, Object> fieldValues = new Map<String, Object>{
            'DES_Comments__c' => 'Updated comments'
        };
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => oli.Id,
                'deferred_fee_amount__c' => 10,
                'no_deferred_fee_amount__c' => 20,
                'undrawn_fee_next_12m_amount__c' => 30,
                'pre_net_margin_next_12m_amount__c' => 40,
                'periodic_fee_amount__c' => 50,
                'fee_next_12m_amount__c' => 60,
                'pre_oppy_revenue_next_12m_amount__c' => 70,
                'funding_cost_per__c' => 1,
                'credit_drawn_next_12m_per__c' => 2,
                'pre_gross_margin_next_12m_per__c' => 3
            }
        };

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, lineItems);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DES_Comments__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Updated comments', updatedOpp.DES_Comments__c, 'Opportunity field should be updated');

        OpportunityLineItem updatedOli = [SELECT deferred_fee_amount__c, periodic_fee_amount__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        System.assertEquals(10, updatedOli.deferred_fee_amount__c, 'Line item field should be updated');
        System.assertEquals(50, updatedOli.periodic_fee_amount__c, 'Line item field should be updated');

        // Note: the "AfterCreateOpportunity" record-triggered flow (RecordAfterSave, CreateAndUpdate)
        // also creates its own Passport__c on Opportunity insert and marks a Passport__c obsolete
        // on Opportunity update. That means more than one Passport__c can exist for this Opportunity,
        // and the controller's "LIMIT 1" query (no ORDER BY) may not pick this test's own record.
        // Assert on the intent (some Passport for this Opportunity got flagged obsolete) rather than
        // on this specific record's Id, so the test isn't coupled to that automation's ordering.
        List<Passport__c> updatedPassports = [
            SELECT DMT_Is_Obsoleted_Passport_Save__c
            FROM Passport__c
            WHERE Opportunity__c = :opp.Id
        ];
        Boolean anyObsoleted = false;
        for (Passport__c p : updatedPassports) {
            if (p.DMT_Is_Obsoleted_Passport_Save__c == true) {
                anyObsoleted = true;
                break;
            }
        }
        System.assert(anyObsoleted, 'Passport should be flagged as obsoleted');
    }

    @isTest
    static void testSaveCommercialProcessData_NullLineItems_SkipsLineItemUpdate() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Map<String, Object> fieldValues = new Map<String, Object>{
            'DES_Comments__c' => 'No line items'
        };

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, null);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DES_Comments__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('No line items', updatedOpp.DES_Comments__c, 'Opportunity field should still be updated');
    }

    @isTest
    static void testSaveCommercialProcessData_EmptyLineItems_SkipsLineItemUpdate() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Map<String, Object> fieldValues = new Map<String, Object>{
            'DES_Comments__c' => 'Empty line items'
        };

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, new List<Map<String, Object>>());
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DES_Comments__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Empty line items', updatedOpp.DES_Comments__c, 'Opportunity field should still be updated');
    }

    @isTest
    static void testSaveCommercialProcessData_LineItemWithNullId_IsSkipped() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(opp);

        Map<String, Object> fieldValues = new Map<String, Object>{
            'DES_Comments__c' => 'Line item without id'
        };
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => null,
                'deferred_fee_amount__c' => 999
            }
        };

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, lineItems);
        Test.stopTest();

        OpportunityLineItem unchangedOli = [SELECT deferred_fee_amount__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        System.assertNotEquals(999, unchangedOli.deferred_fee_amount__c, 'Line item without Id should not be updated');
    }

    @isTest
    static void testSaveCommercialProcessData_NoPassportRecord_DoesNotFail() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Map<String, Object> fieldValues = new Map<String, Object>{
            'DES_Comments__c' => 'No passport'
        };

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, null);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DES_Comments__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('No passport', updatedOpp.DES_Comments__c, 'Should complete successfully with no Passport__c records');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // saveCommercialProcessData - putFieldValue type coercion
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testSaveCommercialProcessData_FieldCoercion_DecimalFromString() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Map<String, Object> fieldValues = new Map<String, Object>{
            'DES_Expected_Probability__c' => '45'
        };

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, null);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DES_Expected_Probability__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(45, updatedOpp.DES_Expected_Probability__c, 'String should be coerced to Decimal for Percent field');
    }

    @isTest
    static void testSaveCommercialProcessData_FieldCoercion_IntegerFromString() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Map<String, Object> fieldValues = new Map<String, Object>{
            'DMT_NUM_Time_Limit__c' => '24'
        };

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, null);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DMT_NUM_Time_Limit__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(24, updatedOpp.DMT_NUM_Time_Limit__c, 'String should be coerced to Integer for Number(scale 0) field');
    }

    @isTest
    static void testSaveCommercialProcessData_FieldCoercion_BlankStringForNumericField_SetsNull() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        update new Opportunity(Id = opp.Id, DES_Expected_Probability__c = 10);

        Map<String, Object> fieldValues = new Map<String, Object>{
            'DES_Expected_Probability__c' => ''
        };

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, null);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DES_Expected_Probability__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, updatedOpp.DES_Expected_Probability__c, 'Blank string should be coerced to null for numeric field');
    }

    @isTest
    static void testSaveCommercialProcessData_FieldCoercion_MultipicklistFromList() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Map<String, Object> fieldValues = new Map<String, Object>{
            'DES_Countries__c' => new List<Object>{ 'AR', 'AE' }
        };

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, null);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DES_Countries__c FROM Opportunity WHERE Id = :opp.Id];
        // Salesforce normalizes multiselect picklist storage order to match the field's
        // valueSet definition order (AB, AE, AR, ...), not insertion/join order.
        System.assertEquals('AE;AR', updatedOpp.DES_Countries__c, 'List values should be joined with semicolons');
    }

    @isTest
    static void testSaveCommercialProcessData_FieldCoercion_MultipicklistEmptyList_SetsNull() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        update new Opportunity(Id = opp.Id, DES_Countries__c = 'AR');

        Map<String, Object> fieldValues = new Map<String, Object>{
            'DES_Countries__c' => new List<Object>()
        };

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, null);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DES_Countries__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, updatedOpp.DES_Countries__c, 'Empty list should result in null field value');
    }

    @isTest
    static void testSaveCommercialProcessData_FieldCoercion_NullValue_SetsFieldNull() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        update new Opportunity(Id = opp.Id, DES_Comments__c = 'Initial value');

        Map<String, Object> fieldValues = new Map<String, Object>();
        fieldValues.put('DES_Comments__c', null);

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, null);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DES_Comments__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, updatedOpp.DES_Comments__c, 'Field should be set to null');
    }

    @isTest
    static void testSaveCommercialProcessData_FieldCoercion_CheckboxValuePassedThrough() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Map<String, Object> fieldValues = new Map<String, Object>{
            'DMT_Credentials__c' => true
        };

        Test.startTest();
        DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, null);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DMT_Credentials__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, updatedOpp.DMT_Credentials__c, 'Boolean value should be set directly without coercion');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // saveCommercialProcessData - Exception handling
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testSaveCommercialProcessData_DmlException_RollsBackAndThrowsAuraHandledException() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        Id deletedOliId = oli.Id;
        delete oli;

        Map<String, Object> fieldValues = new Map<String, Object>{
            'DES_Comments__c' => 'Should be rolled back'
        };
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => deletedOliId,
                'deferred_fee_amount__c' => 10
            }
        };

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, lineItems);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'AuraHandledException should be thrown when the DML operation fails');

        Opportunity notUpdatedOpp = [SELECT DES_Comments__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertNotEquals('Should be rolled back', notUpdatedOpp.DES_Comments__c, 'Opportunity update should have been rolled back');
    }

    @isTest
    static void testSaveCommercialProcessData_GenericException_InvalidFieldName_ThrowsAuraHandledException() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Map<String, Object> fieldValues = new Map<String, Object>{
            'This_Field_Does_Not_Exist__c' => 'some value'
        };

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            DMT_CommercialProcessDataController.saveCommercialProcessData(opp.Id, fieldValues, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'AuraHandledException should be thrown for an invalid field name');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // getOppLineItems
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testGetOppLineItems_Success_OrderedByGroupPriority() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem oli1 = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        OpportunityLineItem oli2 = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        update new List<OpportunityLineItem>{
            new OpportunityLineItem(Id = oli1.Id, gf_group_priority_opportunity_id__c = '02'),
            new OpportunityLineItem(Id = oli2.Id, gf_group_priority_opportunity_id__c = '01')
        };

        Test.startTest();
        List<OpportunityLineItem> result = DMT_CommercialProcessDataController.getOppLineItems(opp.Id);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return both line items');
        System.assertEquals(oli2.Id, result[0].Id, 'Line item with lower group priority should be returned first');
        System.assertEquals(oli1.Id, result[1].Id, 'Line item with higher group priority should be returned last');
    }

    @isTest
    static void testGetOppLineItems_NoLines_ReturnsEmptyList() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        Test.startTest();
        List<OpportunityLineItem> result = DMT_CommercialProcessDataController.getOppLineItems(opp.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return an empty list when there are no line items');
    }
}