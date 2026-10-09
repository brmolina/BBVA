@IsTest
private class DMT_ProductMetadataRenderServiceTest {
    @IsTest
    static void buildSectionsForRisks_rendersConfiguredMetadata() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Risk_Line_Term__c risk = [
            SELECT Id, Name, DMT_Line__c, CurrencyIsoCode, gf_group_priority_line_id__c,
                DMT_Product__c, DMT_Product__r.Name, DMT_Amount__c, DMT_Operation_Type__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :line.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = line;
        data.currencyIsoCode = 'EUR';
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{ risk };
        data.riskLineToCurrencyProvisionMap.put(
            risk.Id,
            new DMT_Currency_Provision__c(g_currency_id__c = 'EUR')
        );
        data.riskLineToWarrantyListMap.put(
            risk.Id,
            new List<DMT_Warranty__c>{
                new DMT_Warranty__c(Name = 'Test Warranty', g_limits_grid_guarantee_type__c = 'W1')
            }
        );
        data.productLevelsByRiskLine.put(
            risk.Id,
            new Map<String, String>{
                'familyProduct' => 'Family Label',
                'subfamilyProduct' => 'Subfamily Label',
                'categoryProduct' => 'Category Label',
                'subcategoryProduct' => 'Subcategory Label'
            }
        );

        Test.startTest();
        Map<Id, List<DMT_ProductMetadataRenderService.RenderSection>> sectionsByRisk =
            DMT_ProductMetadataRenderService.buildSectionsForRisks(
                data,
                new List<DMT_Risk_Line_Term__c>{ risk },
                'OL',
                null
            );
        List<DMT_ProductMetadataRenderService.RenderSection> emptySections =
            DMT_ProductMetadataRenderService.buildSections(null, risk, 'OL', null);
        Test.stopTest();

        Assert.isTrue(sectionsByRisk.containsKey(risk.Id), 'Expected metadata sections for OL risk.');
        Assert.isTrue(sectionsByRisk.get(risk.Id).size() > 0, 'Expected at least one render section.');
        Assert.areEqual(0, emptySections.size(), 'Null data should not produce sections.');

        String html = DMT_ProductMetadataRenderService.renderSectionsHtml(sectionsByRisk.get(risk.Id));
        Assert.isTrue(html.contains('<table') || html.contains('<h4'), 'Expected rendered HTML content.');

    }

    @IsTest
    static void buildSectionsForRisks_handlesEmptyInputs() {
        Map<Id, List<DMT_ProductMetadataRenderService.RenderSection>> result =
            DMT_ProductMetadataRenderService.buildSectionsForRisks(
                new DMT_ViewController.LineDataWrapper(),
                new List<DMT_Risk_Line_Term__c>(),
                'OL',
                null
            );

        Assert.areEqual(0, result.size());
        Assert.areEqual('', DMT_ProductMetadataRenderService.renderSectionsHtml(new List<DMT_ProductMetadataRenderService.RenderSection>()));
    }

    // CIBGLOBALD-4117: exercises getConfiguredFieldsByObject's related/special-key resolution
    // branches the org's own current active config rows don't happen to use (confirmed by querying
    // DMT_TCM_DEV directly - only the plain risk/line-field and a couple of the taxonomy special
    // keys are exercised by real data). Uses testMetadataOverride for full, deterministic control -
    // Custom Metadata rows cannot be inserted via DML even in a test.
    @IsTest
    static void testGetConfiguredFieldsByObjectResolvesEveryConfigKind() {
        DMT_ProductMetadataRenderService.testMetadataOverride = new List<DMT_LineOtherTemplateConfig__mdt>{
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OL', FilterText__c = 'DMT_Comments__c'),
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OL', FilterText__c = 'Line_Id__c'),
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OL', FilterText__c = 'g_limits_grid_guarantee_type'),
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OL', FilterText__c = 'DMT_Currency_Provision__c.g_currency_id'),
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OL', FilterText__c = 'productName'),
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OL', FilterText__c = 'parent_product_id'),
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OL', FilterText__c = 'global_product_family'),
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OL', FilterText__c = 'global_product_subfamily'),
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OL', FilterText__c = 'global_product_category'),
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OL', FilterText__c = 'global_product_subcategory'),
            // Inactive and disabled rows must be ignored entirely.
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = false, LineType__c = 'OL', FilterText__c = 'DMT_Comments__c'),
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, Field_View_Is_Disabled__c = true, LineType__c = 'OL', FilterText__c = 'DMT_Comments__c'),
            // A different line type must never contribute.
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OP', FilterText__c = 'g_line_commitment_level_type__c')
        };

        Test.startTest();
        Map<String, List<String>> fieldsByObject = DMT_ProductMetadataRenderService.getConfiguredFieldsByObject('OL');
        Test.stopTest();

        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Risk_Line_Term__c')).contains('DMT_Comments__c'), 'Plain risk field must resolve directly.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Line__c')).contains('Line_Id__c'), 'Plain line field must resolve directly.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Warranty__c')).contains('Name'), 'The warranty related-key must resolve to Warranty Name, not the raw filter text field.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Currency_Provision__c')).contains('g_currency_id__c'), 'The currency provision related-key must resolve to its real field.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Risk_Line_Term__c')).contains('DMT_Product__r.Name'), 'The productName special key must resolve to the real relationship field.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Line__c')).contains('Line_Id__c'), 'The parentProductId special key contributes Line_Id__c on the Line side.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Risk_Line_Term__c')).contains('gf_group_priority_line_id__c'), 'The parentProductId special key contributes gf_group_priority_line_id__c on the Risk side.');
        Set<String> riskFields = new Set<String>(fieldsByObject.get('DMT_Risk_Line_Term__c'));
        Assert.isTrue(riskFields.contains('g_global_product_family_Id__c'), 'The familyProduct special key must resolve to its real field.');
        Assert.isTrue(riskFields.contains('g_global_product_subfamily_Id__c'), 'The subfamilyProduct special key must resolve to its real field.');
        Assert.isTrue(riskFields.contains('g_global_product_category_Id__c'), 'The categoryProduct special key must resolve to its real field.');
        Assert.isTrue(riskFields.contains('g_gbl_product_subcategory_Id__c'), 'The subcategoryProduct special key must resolve to its real field.');
        Assert.isFalse(riskFields.contains('g_line_commitment_level_type__c'), 'A row configured for a different line type (OP) must not contribute to OL.');
    }

    @IsTest
    static void testGetConfiguredFieldsByObjectReturnsEmptyWhenNoRowsMatch() {
        DMT_ProductMetadataRenderService.testMetadataOverride = new List<DMT_LineOtherTemplateConfig__mdt>();

        Test.startTest();
        Map<String, List<String>> fieldsByObject = DMT_ProductMetadataRenderService.getConfiguredFieldsByObject('OL');
        Test.stopTest();

        Assert.isTrue(fieldsByObject.isEmpty(), 'No config rows must resolve to no configured fields.');
    }

    // CIBGLOBALD-4117: fetchMetadata() (used by the render path - buildSectionsForRisks/
    // buildSections/enrichLineOnWrapper - as opposed to fetchMetadataForLineType, used by
    // getConfiguredFieldsByObject) has its own, separate override-filtering loop. An empty override
    // list never executes that loop body at all, so this exercises it with one real row instead.
    @IsTest
    static void testTestMetadataOverrideFiltersByEntificAndLineType() {
        DMT_ProductMetadataRenderService.testMetadataOverride = new List<DMT_LineOtherTemplateConfig__mdt>{
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OL', FilterText__c = 'DMT_Comments__c'),
            new DMT_LineOtherTemplateConfig__mdt(isActive__c = true, LineType__c = 'OP', FilterText__c = 'g_line_commitment_level_type__c')
        };

        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Risk_Line_Term__c risk = [
            SELECT Id, Name, DMT_Line__c, CurrencyIsoCode, gf_group_priority_line_id__c,
                DMT_Product__c, DMT_Product__r.Name, DMT_Amount__c, DMT_Operation_Type__c, DMT_Comments__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :line.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = line;

        Test.startTest();
        Map<Id, List<DMT_ProductMetadataRenderService.RenderSection>> sectionsByRisk =
            DMT_ProductMetadataRenderService.buildSectionsForRisks(data, new List<DMT_Risk_Line_Term__c>{ risk }, 'OL', null);
        Test.stopTest();

        Assert.isTrue(sectionsByRisk.containsKey(risk.Id), 'The OL-scoped override row must produce a rendered section.');
    }

    // CIBGLOBALD-4117: forces DMT_OtherProductsRenderer's static-layout fallback branch (the table
    // built when a risk line matches no CMDT config) - with the org's own live config, a permanent
    // catch-all row (no Entific__c/TemplateSubtype__c) means this branch never fires in practice.
    // testMetadataOverride removes that dependency entirely.
    @IsTest
    static void testOtherProductsRenderHtmlUsesStaticFallbackWhenNoConfigMatches() {
        DMT_ProductMetadataRenderService.testMetadataOverride = new List<DMT_LineOtherTemplateConfig__mdt>();

        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Risk_Line_Term__c risk = [
            SELECT Id, Name, DMT_Line__c, CurrencyIsoCode, gf_group_priority_line_id__c,
                DMT_Product__c, DMT_Product__r.Name, DMT_Amount__c, DMT_Operation_Type__c,
                DMT_Parent_Product_Name__c, g_bullet_ind_type__c, g_smscl_internal_ratg_type__c,
                DMT_Init_Term__c, DMT_End_Term__c, gf_inscol_months_grace_number__c, gf_loan_value_per__c,
                g_notary_crtfn_ind_type__c, gf_payment_frequency__c, g_gtee_public_adm_ind_type__c,
                gf_loan_eca_cntrb_per__c, gf_min_raroec_fcg_per__c, gf_min_raroec_wo_fcg_per__c,
                gf_min_rorc_fcg_per__c, gf_min_rorc_wo_fcg_per__c, gf_revolvence_pd_days_number__c,
                g_multioperation_ind_type__c, DMT_Comments__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :line.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = line;
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{ risk };
        data.productLevelsByRiskLine.put(risk.Id, new Map<String, String>());

        Test.startTest();
        String html = new DMT_OtherProductsRenderer().renderHtml(data);
        Test.stopTest();

        Assert.isTrue(html.contains('Amount:'), 'With no matching CMDT config, OtherProducts must render its static fallback table. Actual: ' + html);
    }
}