@IsTest
private class DMT_BasicFinancialsYearShiftBatch_Test {

    @TestSetup
    static void makeData() {
        /*
         * La factory genera un Account con valores únicos,
         * por lo que solo debe invocarse una vez.
         */
        Opportunity opportunityRecord =
            DMT_Test_DataFactory.generateOpportunity();

        opportunityRecord.StageName = 'Draft';
        update opportunityRecord;

        DMT_Test_DataFactory.generateOpportunityClient(
            opportunityRecord.Id
        );
    }

    @IsTest
    static void testAccountAnnualShift() {
        Opportunity opportunityRecord = [
            SELECT AccountId
            FROM Opportunity
            WHERE AccountId != null
            LIMIT 1
        ];

        Account accountRecord = new Account(
            Id = opportunityRecord.AccountId
        );

        setCommonAnnualValues(accountRecord);
        update accountRecord;

        Test.startTest();

        Database.executeBatch(
            new DMT_BasicFinancialsYearShiftBatch(
                'Account',
                accountRecord.Id
            ),
            1
        );

        Test.stopTest();

        Account result = (Account) queryResult(
            'Account',
            accountRecord.Id
        );

        assertCommonValuesShifted(result);
    }

    @IsTest
    static void testOpenOpportunityAnnualShift() {
        DMT_Opportunity_Client__c opportunityClient = [
            SELECT
                Id,
                DMT_MDE_Opportunity__c
            FROM DMT_Opportunity_Client__c
            LIMIT 1
        ];

        update new Opportunity(
            Id = opportunityClient.DMT_MDE_Opportunity__c,
            StageName = 'Draft'
        );

        setCommonAnnualValues(opportunityClient);
        setOpportunityOnlyValues(opportunityClient);
        update opportunityClient;

        Test.startTest();

        Database.executeBatch(
            new DMT_BasicFinancialsYearShiftBatch(
                'DMT_Opportunity_Client__c',
                opportunityClient.Id
            ),
            1
        );

        Test.stopTest();

        DMT_Opportunity_Client__c result =
            (DMT_Opportunity_Client__c) queryResult(
                'DMT_Opportunity_Client__c',
                opportunityClient.Id
            );

        assertCommonValuesShifted(result);
        assertOpportunityOnlyValuesShifted(result);
    }

    @IsTest
    static void testClosedWonIsNotShifted() {
        assertClosedOpportunityIsNotShifted(
            'Closed Won'
        );
    }

    @IsTest
    static void testClosedLostIsNotShifted() {
        assertClosedOpportunityIsNotShifted(
            'Closed Lost'
        );
    }

    @IsTest
    static void testNullValuesAreShifted() {
        Opportunity opportunityRecord = [
            SELECT AccountId
            FROM Opportunity
            WHERE AccountId != null
            LIMIT 1
        ];

        Account accountRecord = new Account(
            Id = opportunityRecord.AccountId,
            Revenues_Last_Year_number__c = 10,
            Revenues_Current_Year_number__c = null,
            Revenues_Next_Year_number__c = 30,
            Revenues_Next_Year_1_number__c = null,
            Revenues_Next_Year_2_number__c = 50
        );

        update accountRecord;

        Test.startTest();

        Database.executeBatch(
            new DMT_BasicFinancialsYearShiftBatch(
                'Account',
                accountRecord.Id
            ),
            1
        );

        Test.stopTest();

        Account result = [
            SELECT
                Revenues_Last_Year_number__c,
                Revenues_Current_Year_number__c,
                Revenues_Next_Year_number__c,
                Revenues_Next_Year_1_number__c,
                Revenues_Next_Year_2_number__c
            FROM Account
            WHERE Id = :accountRecord.Id
        ];

        Assert.isNull(
            result.Revenues_Last_Year_number__c,
            'Last Year must receive null'
        );

        Assert.areEqual(
            Decimal.valueOf('30'),
            result.Revenues_Current_Year_number__c,
            'Current Year must receive Next Year'
        );

        Assert.isNull(
            result.Revenues_Next_Year_number__c,
            'Next Year must receive null'
        );

        Assert.areEqual(
            Decimal.valueOf('50'),
            result.Revenues_Next_Year_1_number__c,
            'Next Year 1 must receive Next Year 2'
        );

        Assert.isNull(
            result.Revenues_Next_Year_2_number__c,
            'Next Year 2 must be cleared'
        );
    }

    @IsTest
    static void testUnsupportedObject() {
        Boolean exceptionThrown = false;

        try {
            new DMT_BasicFinancialsYearShiftBatch(
                'Opportunity'
            );
        } catch (
            IllegalArgumentException exceptionRecord
        ) {
            exceptionThrown = true;

            Assert.isTrue(
                exceptionRecord.getMessage().contains(
                    'Unsupported object: Opportunity'
                ),
                'The exception must identify the object'
            );
        }

        Assert.isTrue(
            exceptionThrown,
            'Unsupported objects must be rejected'
        );
    }

    @IsTest
    static void testRecordIdObjectValidation() {
        Opportunity opportunityRecord = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Boolean exceptionThrown = false;

        try {
            new DMT_BasicFinancialsYearShiftBatch(
                'Account',
                opportunityRecord.Id
            );
        } catch (
            IllegalArgumentException exceptionRecord
        ) {
            exceptionThrown = true;

            Assert.isTrue(
                exceptionRecord.getMessage().contains(
                    'The record does not belong to Account'
                ),
                'The exception must identify the mismatch'
            );
        }

        Assert.isTrue(
            exceptionThrown,
            'A mismatched ID must be rejected'
        );
    }

    private static void assertClosedOpportunityIsNotShifted(
        String stageName
    ) {
        DMT_Opportunity_Client__c opportunityClient = [
            SELECT
                Id,
                DMT_MDE_Opportunity__c
            FROM DMT_Opportunity_Client__c
            LIMIT 1
        ];

        update new Opportunity(
            Id = opportunityClient.DMT_MDE_Opportunity__c,
            StageName = stageName
        );

        Opportunity closedOpportunity = [
            SELECT Id, StageName, IsClosed
            FROM Opportunity
            WHERE Id =
                :opportunityClient.DMT_MDE_Opportunity__c
        ];

        Assert.isTrue(
            closedOpportunity.IsClosed,
            stageName + ' must be configured as closed'
        );

        setCommonAnnualValues(opportunityClient);
        setOpportunityOnlyValues(opportunityClient);
        update opportunityClient;

        Test.startTest();

        Database.executeBatch(
            new DMT_BasicFinancialsYearShiftBatch(
                'DMT_Opportunity_Client__c',
                opportunityClient.Id
            ),
            1
        );

        Test.stopTest();

        DMT_Opportunity_Client__c result =
            (DMT_Opportunity_Client__c) queryResult(
                'DMT_Opportunity_Client__c',
                opportunityClient.Id
            );

        assertCommonValuesNotShifted(result);
        assertOpportunityOnlyValuesNotShifted(result);
    }

    private static void setCommonAnnualValues(
        SObject record
    ) {
        /*
         * Basic Financials.
         */
        record.put(
            'Revenues_Last_Year_number__c',
            Decimal.valueOf('10')
        );
        record.put(
            'Revenues_Current_Year_number__c',
            Decimal.valueOf('20')
        );
        record.put(
            'Revenues_Next_Year_number__c',
            Decimal.valueOf('30')
        );
        record.put(
            'Revenues_Next_Year_1_number__c',
            Decimal.valueOf('40')
        );
        record.put(
            'Revenues_Next_Year_2_number__c',
            Decimal.valueOf('50')
        );

        /*
         * Los campos posicionales de Business Plan no
         * existen para Account en DMTTCM.
         */
        if (
            record.getSObjectType() ==
            DMT_Opportunity_Client__c.SObjectType
        ) {
            record.put(
                'Past2_FY_Cash_Management_amount__c',
                Decimal.valueOf('10')
            );
            record.put(
                'Past_FY_Cash_Management_amount__c',
                Decimal.valueOf('20')
            );
            record.put(
                'Current_FY_Cash_Management_amount__c',
                Decimal.valueOf('30')
            );
            record.put(
                'Next_FY_Cash_Management_amount__c',
                Decimal.valueOf('40')
            );
        }

        /*
         * Cross Sell: Transactional KPI.
         */
        record.put(
            'gf_kpi_trans_fees_2ya_amount__c',
            Decimal.valueOf('10')
        );
        record.put(
            'gf_kpi_trans_fees_ly_amount__c',
            Decimal.valueOf('20')
        );
        record.put(
            'gf_kpi_trans_fees_cyr_amount__c',
            Decimal.valueOf('30')
        );
        record.put(
            'gf_kpi_trans_fees_nxy_amount__c',
            Decimal.valueOf('40')
        );

        /*
         * Cross Sell: Cross Border Revenues.
         */
        record.put(
            'gf_xb_cust_ope_revenue_2ya_per__c',
            Decimal.valueOf('10')
        );
        record.put(
            'gf_xb_cust_ope_revenue_ly_per__c',
            Decimal.valueOf('20')
        );
        record.put(
            'gf_xb_cust_ope_revenue_cyr_per__c',
            Decimal.valueOf('30')
        );
        record.put(
            'gf_xb_cust_ope_revenue_nxy_per__c',
            Decimal.valueOf('40')
        );
    }

    private static void setOpportunityOnlyValues(
        DMT_Opportunity_Client__c record
    ) {
        record.Past2_FY_Child_X_Sell_amount__c = 10;
        record.Past_FY_Child_X_Sell_amount__c = 20;
        record.Current_FY_Child_X_Sell_amount__c = 30;
        record.Next_FY_Child_X_Sell_amount__c = 40;
    }

    private static void assertCommonValuesShifted(
        SObject record
    ) {
        assertValue(
            record,
            'Revenues_Last_Year_number__c',
            20
        );
        assertValue(
            record,
            'Revenues_Current_Year_number__c',
            30
        );
        assertValue(
            record,
            'Revenues_Next_Year_number__c',
            40
        );
        assertValue(
            record,
            'Revenues_Next_Year_1_number__c',
            50
        );

        Assert.isNull(
            record.get(
                'Revenues_Next_Year_2_number__c'
            ),
            'The last Basic Financials field must be cleared'
        );

        if (
            record.getSObjectType() ==
            DMT_Opportunity_Client__c.SObjectType
        ) {
            assertFourYearChainShifted(
                record,
                'Past2_FY_Cash_Management_amount__c',
                'Past_FY_Cash_Management_amount__c',
                'Current_FY_Cash_Management_amount__c',
                'Next_FY_Cash_Management_amount__c'
            );
        }

        assertFourYearChainShifted(
            record,
            'gf_kpi_trans_fees_2ya_amount__c',
            'gf_kpi_trans_fees_ly_amount__c',
            'gf_kpi_trans_fees_cyr_amount__c',
            'gf_kpi_trans_fees_nxy_amount__c'
        );

        assertFourYearChainShifted(
            record,
            'gf_xb_cust_ope_revenue_2ya_per__c',
            'gf_xb_cust_ope_revenue_ly_per__c',
            'gf_xb_cust_ope_revenue_cyr_per__c',
            'gf_xb_cust_ope_revenue_nxy_per__c'
        );
    }

    private static void assertCommonValuesNotShifted(
        SObject record
    ) {
        assertValue(
            record,
            'Revenues_Last_Year_number__c',
            10
        );
        assertValue(
            record,
            'Revenues_Current_Year_number__c',
            20
        );
        assertValue(
            record,
            'Revenues_Next_Year_number__c',
            30
        );
        assertValue(
            record,
            'Revenues_Next_Year_1_number__c',
            40
        );
        assertValue(
            record,
            'Revenues_Next_Year_2_number__c',
            50
        );

        if (
            record.getSObjectType() ==
            DMT_Opportunity_Client__c.SObjectType
        ) {
            assertFourYearChainNotShifted(
                record,
                'Past2_FY_Cash_Management_amount__c',
                'Past_FY_Cash_Management_amount__c',
                'Current_FY_Cash_Management_amount__c',
                'Next_FY_Cash_Management_amount__c'
            );
        }

        assertFourYearChainNotShifted(
            record,
            'gf_kpi_trans_fees_2ya_amount__c',
            'gf_kpi_trans_fees_ly_amount__c',
            'gf_kpi_trans_fees_cyr_amount__c',
            'gf_kpi_trans_fees_nxy_amount__c'
        );

        assertFourYearChainNotShifted(
            record,
            'gf_xb_cust_ope_revenue_2ya_per__c',
            'gf_xb_cust_ope_revenue_ly_per__c',
            'gf_xb_cust_ope_revenue_cyr_per__c',
            'gf_xb_cust_ope_revenue_nxy_per__c'
        );
    }

    private static void assertOpportunityOnlyValuesShifted(
        DMT_Opportunity_Client__c record
    ) {
        assertFourYearChainShifted(
            record,
            'Past2_FY_Child_X_Sell_amount__c',
            'Past_FY_Child_X_Sell_amount__c',
            'Current_FY_Child_X_Sell_amount__c',
            'Next_FY_Child_X_Sell_amount__c'
        );
    }

    private static void assertOpportunityOnlyValuesNotShifted(
        DMT_Opportunity_Client__c record
    ) {
        assertFourYearChainNotShifted(
            record,
            'Past2_FY_Child_X_Sell_amount__c',
            'Past_FY_Child_X_Sell_amount__c',
            'Current_FY_Child_X_Sell_amount__c',
            'Next_FY_Child_X_Sell_amount__c'
        );
    }

    private static void assertFourYearChainShifted(
        SObject record,
        String firstField,
        String secondField,
        String thirdField,
        String fourthField
    ) {
        assertValue(record, firstField, 20);
        assertValue(record, secondField, 30);
        assertValue(record, thirdField, 40);

        Assert.isNull(
            record.get(fourthField),
            fourthField + ' must be cleared'
        );
    }

    private static void assertFourYearChainNotShifted(
        SObject record,
        String firstField,
        String secondField,
        String thirdField,
        String fourthField
    ) {
        assertValue(record, firstField, 10);
        assertValue(record, secondField, 20);
        assertValue(record, thirdField, 30);
        assertValue(record, fourthField, 40);
    }

    private static void assertValue(
        SObject record,
        String fieldName,
        Integer expectedValue
    ) {
        Assert.areEqual(
            Decimal.valueOf(
                String.valueOf(expectedValue)
            ),
            record.get(fieldName),
            fieldName
        );
    }

    private static SObject queryResult(
        String objectApiName,
        Id recordId
    ) {
        List<String> fields = new List<String>{
            'Id',
            'Revenues_Last_Year_number__c',
            'Revenues_Current_Year_number__c',
            'Revenues_Next_Year_number__c',
            'Revenues_Next_Year_1_number__c',
            'Revenues_Next_Year_2_number__c',
            'gf_kpi_trans_fees_2ya_amount__c',
            'gf_kpi_trans_fees_ly_amount__c',
            'gf_kpi_trans_fees_cyr_amount__c',
            'gf_kpi_trans_fees_nxy_amount__c',
            'gf_xb_cust_ope_revenue_2ya_per__c',
            'gf_xb_cust_ope_revenue_ly_per__c',
            'gf_xb_cust_ope_revenue_cyr_per__c',
            'gf_xb_cust_ope_revenue_nxy_per__c'
        };

        if (
            objectApiName ==
            'DMT_Opportunity_Client__c'
        ) {
            fields.add(
                'Past2_FY_Cash_Management_amount__c'
            );
            fields.add(
                'Past_FY_Cash_Management_amount__c'
            );
            fields.add(
                'Current_FY_Cash_Management_amount__c'
            );
            fields.add(
                'Next_FY_Cash_Management_amount__c'
            );
            fields.add(
                'Past2_FY_Child_X_Sell_amount__c'
            );
            fields.add(
                'Past_FY_Child_X_Sell_amount__c'
            );
            fields.add(
                'Current_FY_Child_X_Sell_amount__c'
            );
            fields.add(
                'Next_FY_Child_X_Sell_amount__c'
            );
        }

        return Database.query(
            'SELECT ' +
            String.join(fields, ', ') +
            ' FROM ' +
            objectApiName +
            ' WHERE Id = \'' +
            String.escapeSingleQuotes(
                String.valueOf(recordId)
            ) +
            '\' LIMIT 1'
        );
    }
}