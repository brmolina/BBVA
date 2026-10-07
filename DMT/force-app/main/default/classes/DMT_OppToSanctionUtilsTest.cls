@IsTest
public class DMT_OppToSanctionUtilsTest {

    @TestSetup
    static void loadTestData() {
        TriggerBypass.setBypass();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product2 = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product2, pricebookEntry, opp);
        DMT_Opportunity_Mitigant__c mitigant = DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);
    }

    @IsTest
    static void testCreateRiskLinesAndWarranties() {
        Test.startTest();

        DMT_Test_DataFactory.generateTestSanctionLines();

        // Obtener OpportunityLineItems de los datos de TestSetup
        List<OpportunityLineItem> olis = [SELECT Id, Product2Id,OpportunityId, DMT_Risk_Type__c, gf_amortization_type__c, opportunity_risk_name__c, gf_maturity_date__c, DMT_TXT_Comentarios__c, g_currency_id__c, DMT_Deal_Amount_Tenors__c,
        gf_initial_date__c, g_branch_id__c,gf_group_priority_opportunity_id__c, g_line_commitment_level_type__c, g_multioperation_ind_type__c, gf_payment_frequency__c,DMT_Line_Tenor__c, DMT_Line_Oneoffdeal__c, DMT_Line_Amount__c, gf_country_risk__c
                                          FROM OpportunityLineItem];
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c LIMIT 1];
        // Preparar wrapper
        List<DMT_OppToSanctionUtils.OpportunityLineItemWrapper> wrappers = new List<DMT_OppToSanctionUtils.OpportunityLineItemWrapper>();
        DMT_OppToSanctionUtils.OpportunityLineItemWrapper wrapper = new DMT_OppToSanctionUtils.OpportunityLineItemWrapper();
        wrapper.listOli = olis;
        wrapper.idLine = line.Id;
        wrappers.add(wrapper);

        DMT_OppToSanctionUtils.createRiskLinesAndWarranties(wrappers);
        Test.stopTest();



        // Verificar que se crearon Warranties
        List<DMT_Warranty__c> warranties = [SELECT Id, DMT_Risk_Line_Term__c, Name FROM DMT_Warranty__c];
        System.assertEquals([SELECT count() FROM DMT_Opportunity_Mitigant__c], warranties.size(), 'Se deben crear Warranties por cada mitigante');
    }

    //  @IsTest
    // static void testCreateRiskLinesAndWarrantiesDeduplicatesMitigantType() {
    //     DMT_Test_DataFactory.generateTestSanctionLines();

    //     OpportunityLineItem oli = [SELECT Id, Product2Id, OpportunityId, DMT_Risk_Type__c, gf_amortization_type__c, opportunity_risk_name__c, gf_maturity_date__c, DMT_TXT_Comentarios__c, g_currency_id__c, DMT_Deal_Amount_Tenors__c,
    //     gf_initial_date__c, g_branch_id__c,gf_group_priority_opportunity_id__c, g_line_commitment_level_type__c, g_multioperation_ind_type__c, gf_payment_frequency__c
    //                               FROM OpportunityLineItem LIMIT 1];
    //     DMT_Opportunity_Mitigant__c mitigant = [SELECT Id, DMT_Opportunity_Product__c, Mitigant_Type__c FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c = :oli.Id LIMIT 1];
    //     mitigant.Mitigant_Type__c = 'Guarantee';
    //     update mitigant;
    //     mitigant = [SELECT Id, DMT_Opportunity_Product__c, Mitigant_Type__c FROM DMT_Opportunity_Mitigant__c WHERE Id = :mitigant.Id];
    //     insert new DMT_Opportunity_Mitigant__c(
    //         DMT_Opportunity_Product__c = oli.Id,
    //         Mitigant_Type__c = mitigant.Mitigant_Type__c,
    //         Political_Percentage__c = 1,
    //         Commercial_Percentage__c = 1
    //     );

    //     DMT_Line__c line = [SELECT Id FROM DMT_Line__c LIMIT 1];
    //     DMT_OppToSanctionUtils.OpportunityLineItemWrapper wrapper = new DMT_OppToSanctionUtils.OpportunityLineItemWrapper();
    //     wrapper.listOli = new List<OpportunityLineItem>{oli};
    //     wrapper.idLine = line.Id;

    //     Test.startTest();
    //     DMT_OppToSanctionUtils.createRiskLinesAndWarranties(new List<DMT_OppToSanctionUtils.OpportunityLineItemWrapper>{wrapper});
    //     Test.stopTest();

    //     List<DMT_Warranty__c> warranties = [SELECT Name FROM DMT_Warranty__c];
    //     System.assertEquals(1, warranties.size(), 'Debe crearse una sola Warranty por Mitigant_Type__c');
    //     System.assertEquals(mitigant.Mitigant_Type__c, warranties[0].Name, 'La Warranty creada debe tomar el Mitigant_Type__c persistido');
    // }


    @IsTest
    static void testEndTermFromDates() {
        DMT_Test_DataFactory.generateTestSanctionLines();
        Set<Id> existingRiskTermIds = new Set<Id>();

        for (DMT_Risk_Line_Term__c rt : [SELECT Id FROM DMT_Risk_Line_Term__c]) {
            existingRiskTermIds.add(rt.Id);
        }

        OpportunityLineItem oli = [SELECT Id,OpportunityId, Product2Id, DMT_Risk_Type__c, gf_amortization_type__c, opportunity_risk_name__c, gf_maturity_date__c, DMT_TXT_Comentarios__c, g_currency_id__c,
        DMT_Deal_Amount_Tenors__c, gf_initial_date__c, g_branch_id__c,gf_group_priority_opportunity_id__c, g_line_commitment_level_type__c, g_multioperation_ind_type__c, gf_payment_frequency__c,DMT_Line_Tenor__c, DMT_Line_Oneoffdeal__c, DMT_Line_Amount__c, gf_country_risk__c
         FROM OpportunityLineItem LIMIT 1];

        oli.gf_initial_date__c = Date.today();
        oli.gf_maturity_date__c = Date.today().addDays(25);
        update oli;

        DMT_Line__c line = [SELECT Id FROM DMT_Line__c LIMIT 1];

        DMT_OppToSanctionUtils.OpportunityLineItemWrapper wrapper = new DMT_OppToSanctionUtils.OpportunityLineItemWrapper();
        wrapper.listOli = new List<OpportunityLineItem>{oli};
        wrapper.idLine = line.Id;

        Test.startTest();
        DMT_OppToSanctionUtils.createRiskLinesAndWarranties(new List<DMT_OppToSanctionUtils.OpportunityLineItemWrapper>{wrapper});
        Test.stopTest();

        List<DMT_Risk_Line_Term__c> newRiskTerms = [SELECT Id, DMT_End_Term__c, DMT_Line__c, DMT_Product__c FROM DMT_Risk_Line_Term__c WHERE Id NOT IN :existingRiskTermIds];

        System.assert(!newRiskTerms.isEmpty(), 'Debe crearse al menos un DMT_Risk_Line_Term__c nuevo.');
        System.assertEquals('31', newRiskTerms[0].DMT_End_Term__c, 'Para 25 días, End Term debe ser 31 (plazo mínimo superior).');
    }

    @IsTest
    static void testGetCachedEndTermDayOptions() {
        Test.startTest();
        List<Integer> dayOptions = DMT_OppToSanctionUtils.getCachedEndTermDayOptions();
        List<Integer> cachedOptions = DMT_OppToSanctionUtils.getCachedEndTermDayOptions();
        Test.stopTest();

        System.assert(!dayOptions.isEmpty(), 'Day options should not be empty');
        System.assertEquals(dayOptions, cachedOptions, 'Cached options should return the same list');
        
        // Verify the list is sorted
        Boolean isSorted = true;
        for (Integer i = 0; i < dayOptions.size() - 1; i++) {
            if (dayOptions[i] > dayOptions[i + 1]) {
                isSorted = false;
                break;
            }
        }
        System.assert(isSorted, 'Day options should be sorted in ascending order');
    }

    @IsTest
    static void testLowerBound() {
        List<Integer> sortedList = new List<Integer>{0, 10, 20, 30, 40, 50};

        Test.startTest();
        // Test cases for lower_bound
        Integer result1 = DMT_OppToSanctionUtils.lowerBound(sortedList, 0);  // Should return 0
        Integer result2 = DMT_OppToSanctionUtils.lowerBound(sortedList, 15); // Should return 2 (first >= 15 is 20)
        Integer result3 = DMT_OppToSanctionUtils.lowerBound(sortedList, 25); // Should return 3 (first >= 25 is 30)
        Integer result4 = DMT_OppToSanctionUtils.lowerBound(sortedList, 50); // Should return 5 (exact match)
        Integer result5 = DMT_OppToSanctionUtils.lowerBound(sortedList, 60); // Should return 6 (beyond range)
        Test.stopTest();

        System.assertEquals(0, result1, 'lowerBound(0) should return 0');
        System.assertEquals(2, result2, 'lowerBound(15) should return 2');
        System.assertEquals(3, result3, 'lowerBound(25) should return 3');
        System.assertEquals(5, result4, 'lowerBound(50) should return 5');
        System.assertEquals(6, result5, 'lowerBound(60) should return size of list');
    }

    @IsTest
    static void testToMaxAllowedEndTermPicklistValueNullDates() {
        Test.startTest();
        String result1 = DMT_OppToSanctionUtils.toMaxAllowedEndTermPicklistValue(null, Date.today());
        String result2 = DMT_OppToSanctionUtils.toMaxAllowedEndTermPicklistValue(Date.today(), null);
        String result3 = DMT_OppToSanctionUtils.toMaxAllowedEndTermPicklistValue(null, null);
        Test.stopTest();

        System.assertEquals(null, result1, 'Should return null when start date is null');
        System.assertEquals(null, result2, 'Should return null when end date is null');
        System.assertEquals(null, result3, 'Should return null when both dates are null');
    }

    @IsTest
    static void testToMaxAllowedEndTermPicklistValueVariousDayDifferences() {
        Date startDate = Date.today();

        Test.startTest();
        String result1 = DMT_OppToSanctionUtils.toMaxAllowedEndTermPicklistValue(startDate, startDate);           // 0 days
        String result2 = DMT_OppToSanctionUtils.toMaxAllowedEndTermPicklistValue(startDate, startDate.addDays(5));  // 5 days
        String result3 = DMT_OppToSanctionUtils.toMaxAllowedEndTermPicklistValue(startDate, startDate.addDays(50)); // 50 days
        String result4 = DMT_OppToSanctionUtils.toMaxAllowedEndTermPicklistValue(startDate, startDate.addDays(365)); // 365 days
        Test.stopTest();

        System.assertNotEquals(null, result1, 'Should return a value for 0 days');
        System.assertNotEquals(null, result2, 'Should return a value for 5 days');
        System.assertNotEquals(null, result3, 'Should return a value for 50 days');
        System.assertNotEquals(null, result4, 'Should return a value for 365 days');
    }

    @IsTest
    static void testCreateRiskLinesWithUserDefinedAmortization() {
        DMT_Test_DataFactory.generateTestSanctionLines();

        OpportunityLineItem oli = [SELECT Id,OpportunityId, Product2Id, DMT_Risk_Type__c, gf_amortization_type__c, opportunity_risk_name__c, gf_maturity_date__c, DMT_TXT_Comentarios__c, g_currency_id__c, gf_payment_frequency__c,
        DMT_Deal_Amount_Tenors__c, gf_initial_date__c, g_branch_id__c,gf_group_priority_opportunity_id__c, DMT_balloon_amortization_indicator__c, DMT_bullet_amortization_indicator__c, g_line_commitment_level_type__c, g_multioperation_ind_type__c,DMT_Line_Tenor__c, DMT_Line_Oneoffdeal__c, DMT_Line_Amount__c, gf_country_risk__c
         FROM OpportunityLineItem LIMIT 1];

        oli.gf_amortization_type__c = 'User-Defined';
        oli.DMT_balloon_amortization_indicator__c = true;
        oli.DMT_bullet_amortization_indicator__c = false;
        update oli;

        DMT_Line__c line = [SELECT Id FROM DMT_Line__c LIMIT 1];
        DMT_OppToSanctionUtils.OpportunityLineItemWrapper wrapper = new DMT_OppToSanctionUtils.OpportunityLineItemWrapper();
        wrapper.listOli = new List<OpportunityLineItem>{oli};
        wrapper.idLine = line.Id;

        Test.startTest();
        DMT_OppToSanctionUtils.createRiskLinesAndWarranties(new List<DMT_OppToSanctionUtils.OpportunityLineItemWrapper>{wrapper});
        Test.stopTest();

        List<DMT_Risk_Line_Term__c> riskTerms = [SELECT Id, g_amortization_type__c FROM DMT_Risk_Line_Term__c WHERE DMT_Product__c = :oli.Product2Id];
        System.assert(!riskTerms.isEmpty(), 'Risk line should be created');
        System.assertEquals('05', riskTerms[0].g_amortization_type__c, 'Balloon amortization should map to 5');
    }

    @IsTest
    static void testCreateRiskLinesWithBulletAmortization() {
        DMT_Test_DataFactory.generateTestSanctionLines();

        OpportunityLineItem oli = [SELECT Id,OpportunityId, Product2Id, DMT_Risk_Type__c, gf_amortization_type__c, opportunity_risk_name__c, gf_maturity_date__c, DMT_TXT_Comentarios__c, g_currency_id__c, gf_payment_frequency__c,
        DMT_Deal_Amount_Tenors__c, gf_initial_date__c, g_branch_id__c,gf_group_priority_opportunity_id__c, DMT_balloon_amortization_indicator__c, DMT_bullet_amortization_indicator__c, g_line_commitment_level_type__c, g_multioperation_ind_type__c,DMT_Line_Tenor__c, DMT_Line_Oneoffdeal__c, DMT_Line_Amount__c, gf_country_risk__c
         FROM OpportunityLineItem LIMIT 1];

        oli.gf_amortization_type__c = 'Bullet';
        update oli;

        DMT_Line__c line = [SELECT Id FROM DMT_Line__c LIMIT 1];
        DMT_OppToSanctionUtils.OpportunityLineItemWrapper wrapper = new DMT_OppToSanctionUtils.OpportunityLineItemWrapper();
        wrapper.listOli = new List<OpportunityLineItem>{oli};
        wrapper.idLine = line.Id;

        Test.startTest();
        DMT_OppToSanctionUtils.createRiskLinesAndWarranties(new List<DMT_OppToSanctionUtils.OpportunityLineItemWrapper>{wrapper});
        Test.stopTest();

        List<DMT_Risk_Line_Term__c> riskTerms = [SELECT g_amortization_type__c FROM DMT_Risk_Line_Term__c WHERE DMT_Product__c = :oli.Product2Id];
        System.assert(!riskTerms.isEmpty(), 'Risk line should be created');
        System.assertEquals('04', riskTerms[0].g_amortization_type__c, 'Bullet amortization should map to 4');
    }

    @IsTest
    static void testCreateRiskLinesWithLinearAmortization() {
        DMT_Test_DataFactory.generateTestSanctionLines();

        OpportunityLineItem oli = [SELECT Id,OpportunityId, Product2Id, DMT_Risk_Type__c, gf_amortization_type__c, opportunity_risk_name__c, gf_maturity_date__c, DMT_TXT_Comentarios__c, g_currency_id__c,
        DMT_Deal_Amount_Tenors__c, gf_initial_date__c, g_branch_id__c,gf_group_priority_opportunity_id__c, g_line_commitment_level_type__c, g_multioperation_ind_type__c, gf_payment_frequency__c,DMT_Line_Tenor__c, DMT_Line_Oneoffdeal__c, DMT_Line_Amount__c, gf_country_risk__c
         FROM OpportunityLineItem LIMIT 1];

        oli.gf_amortization_type__c = 'Linear';
        update oli;

        DMT_Line__c line = [SELECT Id FROM DMT_Line__c LIMIT 1];
        DMT_OppToSanctionUtils.OpportunityLineItemWrapper wrapper = new DMT_OppToSanctionUtils.OpportunityLineItemWrapper();
        wrapper.listOli = new List<OpportunityLineItem>{oli};
        wrapper.idLine = line.Id;

        Test.startTest();
        DMT_OppToSanctionUtils.createRiskLinesAndWarranties(new List<DMT_OppToSanctionUtils.OpportunityLineItemWrapper>{wrapper});
        Test.stopTest();

        List<DMT_Risk_Line_Term__c> riskTerms = [SELECT g_amortization_type__c FROM DMT_Risk_Line_Term__c WHERE DMT_Product__c = :oli.Product2Id];
        System.assert(!riskTerms.isEmpty(), 'Risk line should be created');
        System.assertEquals('03', riskTerms[0].g_amortization_type__c, 'Linear amortization should map to 3');
    }

    /**
     * Helper que prepara los datos necesarios para ejercitar updateRiskLinesAndWarranties:
     *  - Una DMT_Line__c vinculada a la oportunidad de TestSetup (DMT_Opportunity__c)
     *  - Un DMT_Risk_Line_Term__c sobre esa línea
     *  - Una DMT_Warranty__c y DMT_Currency_Provision__c "existentes" para forzar la rama de update
     *  - El OpportunityLineItem queda apuntando al RiskLineTerm vía DMT_Associated_Line_Product__c
     * Devuelve el Id de la oportunidad sobre la que se debe ejecutar la lógica.
     */
    private static Id prepareDataForUpdate(String amortizationType, Boolean balloon, Boolean bullet) {
        TriggerBypass.setBypass();
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        DMT_Line__c line = new DMT_Line__c(
            Name              = 'Line linked to Opp',
            Status__c         = 'Draft',
            Client__c         = opp.AccountId,
            Line_Id__c        = '00099',
            DMT_Origin__c     = 'AMIWEB',
            g_line_status_type__c = 'AP',
            Booking_Geography__c  = 'ES',
            DMT_Client_Entific__c = 'ES',
            Client_Code__c    = 'G00000000000201',
            DMT_Opportunity__c = opp.Id
        );
        insert line;

        OpportunityLineItem oli = [
            SELECT Id, Product2Id, gf_amortization_type__c, DMT_balloon_amortization_indicator__c,
                   DMT_bullet_amortization_indicator__c, DMT_Associated_Line_Product__c,DMT_Line_Tenor__c, DMT_Line_Oneoffdeal__c, DMT_Line_Amount__c, gf_country_risk__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];

        DMT_Risk_Line_Term__c rlt = new DMT_Risk_Line_Term__c(
            DMT_Line__c       = line.Id,
            Name              = 'RLT to update',
            DMT_Init_Term__c  = '0',
            DMT_End_Term__c   = '3',
            DMT_Amount__c     = 100,
            CurrencyIsoCode   = 'EUR',
            DMT_Product__c    = oli.Product2Id,
            gf_group_priority_line_id__c = '01'
        );
        insert rlt;

        oli.DMT_Associated_Line_Product__c   = rlt.Id;
        oli.gf_amortization_type__c          = amortizationType;
        oli.DMT_balloon_amortization_indicator__c = balloon;
        oli.DMT_bullet_amortization_indicator__c  = bullet;
        update oli;

        // Nota: el @TestSetup ya inserta un único Mitigante para este OLI.
        // No se inserta otro porque varios mitigantes con el mismo gf_group_priority_opportunity_id__c
        // resolverían al mismo Warranty.Id en mapGroupPriorityToWarranty y provocarían
        // "Duplicate id in list" al hacer update warrantiesToUpdate.

        // Warranty y CurrencyProvision existentes (para forzar la rama de update con Id != null)
        insert new DMT_Warranty__c(
            DMT_Risk_Line_Term__c            = rlt.Id,
            Name                             = 'Existing W',
            gf_group_priority_line_id__c     = '01',
            g_limits_grid_guarantee_type__c  = 'O3',
            gf_origin_application_type__c    = '04',
            g_entific_id__c                  = 'HO'
        );
        insert new DMT_Currency_Provision__c(
            DMT_Risk_Line_Term__c            = rlt.Id,
            Name                             = 'EUR',
            g_currency_id__c                 = 'EUR',
            gf_group_priority_line_id__c     = '01',
            gf_origin_application_type__c    = '04',
            g_entific_id__c                  = 'HO'
        );

        return opp.Id;
    }

    @IsTest
    static void testUpdateRiskLinesAndWarranties() {
        Id oppId = prepareDataForUpdate('Bullet', false, false);

        Test.startTest();
        DMT_OppToSanctionUtils.updateRiskLinesAndWarranties(oppId, new List<String>(),'risk');
        Test.stopTest();

        // Se actualizó el RiskLineTerm con datos del OLI
        List<DMT_Risk_Line_Term__c> rlts = [
            SELECT Id, g_amortization_type__c, DMT_Product__c, gf_group_priority_line_id__c
            FROM DMT_Risk_Line_Term__c
        ];
        System.assert(!rlts.isEmpty(), 'Debe existir el RiskLineTerm tras el update');
        System.assertEquals('04', rlts[0].g_amortization_type__c, 'Bullet amortization debe mapear a 04');

        // No se crean nuevos warranties/currency provisions, sólo se actualizan los existentes
        Integer warrantyCount = [SELECT count() FROM DMT_Warranty__c];
        Integer cpCount       = [SELECT count() FROM DMT_Currency_Provision__c];
        System.assertEquals(1, warrantyCount, 'Debe seguir existiendo un único Warranty (actualizado)');
        System.assertEquals(1, cpCount,       'Debe seguir existiendo un único Currency Provision (actualizado)');

        // La línea asociada a la oportunidad debe haberse actualizado con datos de la opp
        DMT_Line__c lineAfter = [SELECT Id, DMT_Opportunity__c, Booking_Geography__c FROM DMT_Line__c WHERE Line_Id__c = '00099' LIMIT 1];
        System.assertEquals(oppId, lineAfter.DMT_Opportunity__c, 'La línea debe quedar enlazada a la oportunidad');
        System.assertEquals('ES',  lineAfter.Booking_Geography__c, 'Booking Geography debe heredarse del Entific de la opp');
    }

    
    // @IsTest
    // static void testUpdateRiskLinesAndWarrantiesDeduplicatesMitigantType() {
    //     Id oppId = prepareDataForUpdate('Bullet', false, false);
    //     OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :oppId LIMIT 1];
    //     DMT_Opportunity_Mitigant__c mitigant = [SELECT Id, DMT_Opportunity_Product__c, Mitigant_Type__c FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c = :oli.Id LIMIT 1];
    //     mitigant.Mitigant_Type__c = 'Guarantee';
    //     update mitigant;
    //     mitigant = [SELECT Id, DMT_Opportunity_Product__c, Mitigant_Type__c FROM DMT_Opportunity_Mitigant__c WHERE Id = :mitigant.Id];
    //     insert new DMT_Opportunity_Mitigant__c(
    //         DMT_Opportunity_Product__c = oli.Id,
    //         Mitigant_Type__c = mitigant.Mitigant_Type__c,
    //         Political_Percentage__c = 1,
    //         Commercial_Percentage__c = 1
    //     );

    //     Test.startTest();
    //     DMT_OppToSanctionUtils.updateRiskLinesAndWarranties(oppId, new List<String>(),'risk');
    //     Test.stopTest();

    //     System.assertEquals(1, [SELECT count() FROM DMT_Warranty__c], 'Debe actualizarse una sola Warranty por Mitigant_Type__c duplicado');
    //     DMT_Warranty__c warranty = [SELECT Name FROM DMT_Warranty__c LIMIT 1];
    //     System.assertEquals(mitigant.Mitigant_Type__c, warranty.Name, 'La Warranty conservada debe tomar el Mitigant_Type__c persistido');
    // }

    @IsTest
    static void testUpdateRiskLinesWithUserDefinedBalloonAmortization() {
        Id oppId = prepareDataForUpdate('User-Defined', true, false);

        Test.startTest();
        DMT_OppToSanctionUtils.updateRiskLinesAndWarranties(oppId, new List<String>(),'risk');
        Test.stopTest();

        DMT_Risk_Line_Term__c rlt = [SELECT g_amortization_type__c FROM DMT_Risk_Line_Term__c LIMIT 1];
        System.assertEquals('05', rlt.g_amortization_type__c, 'User-Defined + balloon debe mapear a 05');
    }

    @IsTest
    static void testUpdateRiskLinesWithUserDefinedBulletAmortization() {
        Id oppId = prepareDataForUpdate('User-Defined', false, true);

        Test.startTest();
        DMT_OppToSanctionUtils.updateRiskLinesAndWarranties(oppId, new List<String>(),'risk');
        Test.stopTest();

        DMT_Risk_Line_Term__c rlt = [SELECT g_amortization_type__c FROM DMT_Risk_Line_Term__c LIMIT 1];
        System.assertEquals('04', rlt.g_amortization_type__c, 'User-Defined + bullet debe mapear a 04');
    }

    @IsTest
    static void testUpdateRiskLinesWithUserDefinedDefaultAmortization() {
        Id oppId = prepareDataForUpdate('User-Defined', false, false);

        Test.startTest();
        DMT_OppToSanctionUtils.updateRiskLinesAndWarranties(oppId, new List<String>(),'risk');
        Test.stopTest();

        DMT_Risk_Line_Term__c rlt = [SELECT g_amortization_type__c FROM DMT_Risk_Line_Term__c LIMIT 1];
        System.assertEquals('09', rlt.g_amortization_type__c, 'User-Defined sin balloon ni bullet debe mapear a 09');
    }

    @IsTest
    static void testUpdateRiskLinesWithLinearAmortization() {
        Id oppId = prepareDataForUpdate('Linear', false, false);

        Test.startTest();
        DMT_OppToSanctionUtils.updateRiskLinesAndWarranties(oppId, new List<String>(),'risk');
        Test.stopTest();

        DMT_Risk_Line_Term__c rlt = [SELECT g_amortization_type__c FROM DMT_Risk_Line_Term__c LIMIT 1];
        System.assertEquals('03', rlt.g_amortization_type__c, 'Linear amortization debe mapear a 03');
    }

    @IsTest
    static void testUpdateRiskLinesNoAssociatedLineProduct() {
        // Si ningún OLI tiene DMT_Associated_Line_Product__c, no hay nada que actualizar
        // pero la línea sí debe existir asociada a la opp para que la actualización de la
        // DMT_Line__c no falle por Id nulo.
        TriggerBypass.setBypass();
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        insert new DMT_Line__c(
            Name              = 'Line linked to Opp NoAssoc',
            Status__c         = 'Draft',
            Client__c         = opp.AccountId,
            Line_Id__c        = '00098',
            DMT_Origin__c     = 'AMIWEB',
            g_line_status_type__c = 'AP',
            Booking_Geography__c  = 'ES',
            DMT_Client_Entific__c = 'ES',
            Client_Code__c    = 'G00000000000201',
            DMT_Opportunity__c = opp.Id
        );

        Test.startTest();
        DMT_OppToSanctionUtils.updateRiskLinesAndWarranties(opp.Id, new List<String>(),'risk');
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM DMT_Risk_Line_Term__c], 'No debe crearse ningún RiskLineTerm');
    }
    @IsTest
    static void testCommentsTextWithUnderlyingAndGuarantor() {
        OpportunityLineItem baseOli = [SELECT Id, Product2Id FROM OpportunityLineItem LIMIT 1];

        // Underlying -> rama "Underlying Restriction"
        DMT_Test_DataFactory.generateUnderlyingRestriction(baseOli);

        // Mitigant con Guarantor_Display -> rama "Guarantor"
        // (el mitigant del TestSetup, sin Guarantor_Display, ya cubre "Collateral")
        DMT_Test_DataFactory.generateOpportunityGuarantor(baseOli);

        DMT_Test_DataFactory.generateTestSanctionLines();

        List<OpportunityLineItem> olis = [
            SELECT Id, Product2Id, OpportunityId, DMT_Risk_Type__c, gf_amortization_type__c,
                opportunity_risk_name__c, gf_maturity_date__c, DMT_TXT_Comentarios__c,
                g_currency_id__c, DMT_Deal_Amount_Tenors__c, gf_initial_date__c,
                g_branch_id__c, gf_group_priority_opportunity_id__c,
                g_line_commitment_level_type__c, g_multioperation_ind_type__c,
                gf_payment_frequency__c, DMT_Line_Tenor__c, DMT_Line_Oneoffdeal__c,
                DMT_Line_Amount__c, gf_country_risk__c
            FROM OpportunityLineItem
        ];
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c LIMIT 1];

        DMT_OppToSanctionUtils.OpportunityLineItemWrapper wrapper = new DMT_OppToSanctionUtils.OpportunityLineItemWrapper();
        wrapper.listOli = olis;
        wrapper.idLine = line.Id;
        List<DMT_Risk_Line_Term__c> rlts = [
            SELECT DMT_Comments__c 
            FROM DMT_Risk_Line_Term__c 
            WHERE DMT_Line__c = :line.Id
        ];
        Test.startTest();
        DMT_OppToSanctionUtils.createRiskLinesAndWarranties(
            new List<DMT_OppToSanctionUtils.OpportunityLineItemWrapper>{wrapper}
        );
        Test.stopTest();


    }
}