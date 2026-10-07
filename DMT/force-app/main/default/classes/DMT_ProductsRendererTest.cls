/**
 * CIBGLOBALD-4117: dedicated coverage for Products' tracking methods (getTrackedFields /
 * getTrackedFieldsByObject / getChildSections), kept separate from DMT_ViewController_Test so this
 * component's deploy is self-contained - see DMT_ApprovalProcessDataRendererTest's header for the
 * same reasoning. All four Products record types are tracked - OtherProducts/Sanction assertions
 * below only check the fixed static-layout fields (guaranteed regardless of org CMDT config); they
 * don't assert on DMT_LineOtherTemplateConfig__mdt-derived fields since that config's active rows
 * can legitimately change over time - see DMT_OtherProductsRenderer/DMT_LineSanctionProductsRenderer
 * headers for how the two are unioned.
 */
@IsTest
private class DMT_ProductsRendererTest {

    private static Id treasuryRtId() {
        return Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement').getRecordTypeId();
    }

    private static Id otherRtId() {
        return Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId();
    }

    private static Id sanctionRtId() {
        return Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('Sanction').getRecordTypeId();
    }

    private static Id oppRtId() {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
    }

    @IsTest
    static void testGetTrackedFieldsByObjectTreasuryDefaultVariantFields() {
        // CIBGLOBALD-4117 - Treasury Products is single-route: a record with no Booking_Geography__c
        // value (or one that doesn't match CO/PE/MX) resolves to the base DMT_TreasuryProductsRenderer,
        // which only tracks its OWN fields - it no longer unions the CO/PE/MX variants' fields. Each
        // variant's own fields are covered by its own dedicated test class
        // (DMT_TreasuryProductsRenderer_CO/PE/MXTest's testTrackingMethodsAreSelfContained).
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Products', new DMT_Line__c(RecordTypeId = treasuryRtId()));

        Assert.isTrue(fieldsByObject.containsKey('DMT_Line__c'), 'Treasury Products must track DMT_Line__c fields.');
        Set<String> lineFields = new Set<String>(fieldsByObject.get('DMT_Line__c'));
        Assert.isTrue(lineFields.contains('DvP_Amount__c'), 'DvP_Amount__c is shown by the default variant.');
        Assert.isTrue(lineFields.contains('Repos_Limit__c'), 'Repos_Limit__c is a default-variant field.');
        Assert.isTrue(lineFields.contains('Booking_Geography__c'), 'Booking_Geography__c decides which variant renders and must be tracked.');
        // CIBGLOBALD-4117 - editable on the PRODUCTS tab's cfRiskTablesLine FlexCard but untracked
        // by any Treasury-side component before this fix; found via a field-drift audit.
        Assert.isTrue(lineFields.contains('DMT_Additional_Restrictions__c'), 'DMT_Additional_Restrictions__c (cfRiskTablesLine Additional Products field) must be tracked.');
        Assert.isTrue(lineFields.contains('DMT_Comments__c'), 'DMT_Comments__c (cfRiskTablesLine Comments field) must be tracked.');

        Assert.isTrue(fieldsByObject.containsKey('DMT_Risk_Line_Term__c'), 'Treasury Products must track DMT_Risk_Line_Term__c fields.');
        Set<String> riskFields = new Set<String>(fieldsByObject.get('DMT_Risk_Line_Term__c'));
        Assert.isTrue(riskFields.contains('DMT_Init_Term__c'), 'DMT_Init_Term__c is shown by the default variant.');

        Assert.isTrue(fieldsByObject.containsKey('DMT_Line_Product_Item__c'), 'Treasury Products must track DMT_Line_Product_Item__c fields.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Line_Product_Item__c')).contains('Max_Tenor_WC__c'), 'Max_Tenor_WC__c is shown by the default variant.');
    }

    @IsTest
    static void testGetTrackedFieldsTreasuryMatchesGetTrackedFieldsByObjectLineFields() {
        List<String> trackedFields = DMT_RendererFactory.getTrackedFields('Products', new DMT_Line__c(RecordTypeId = treasuryRtId()));
        Assert.isFalse(trackedFields.isEmpty(), 'Products must return DMT_Line__c-native fields for Treasury.');
        Assert.isTrue(new Set<String>(trackedFields).contains('DvP_Amount__c'), 'The flat list must include the same Line fields as getTrackedFieldsByObject.');
    }

    @IsTest
    static void testGetChildSectionsTreasuryReturnsRiskLineAndLineProductItem() {
        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = DMT_RendererFactory.getChildSections('Products', new DMT_Line__c(RecordTypeId = treasuryRtId()));

        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> byKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        for (DMT_ApprovalChangeStep_Helper.ChildSection s : sections) {
            byKey.put(s.snapshotSectionKey, s);
        }
        Assert.isTrue(byKey.containsKey('riskLineList'), 'Treasury Products must declare the riskLineList child section.');
        Assert.areEqual('DMT_Risk_Line_Term__c', byKey.get('riskLineList').childObjectApiName);
        Assert.areEqual('DMT_Line__c', byKey.get('riskLineList').childLookupField);
        Assert.areEqual('Id', byKey.get('riskLineList').parentValueField);
        Assert.areEqual('DMT_Init_Term__c ASC', byKey.get('riskLineList').orderBy);

        Assert.isTrue(byKey.containsKey('lineProductItemList'), 'Treasury Products must declare the lineProductItemList child section.');
        Assert.areEqual('DMT_Line_Product_Item__c', byKey.get('lineProductItemList').childObjectApiName);
        Assert.areEqual('Line__c', byKey.get('lineProductItemList').childLookupField);
    }

    @IsTest
    static void testGetTrackedFieldsByObjectOpportunityIncludesFourChildObjects() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Products', new Opportunity(RecordTypeId = oppRtId()));

        Assert.isTrue(fieldsByObject.containsKey('OpportunityLineItem'), 'Opportunity Products must track OpportunityLineItem fields.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('OpportunityLineItem')).contains('DMT_Deal_amount__c'), 'DMT_Deal_amount__c backs both dealAmount and lineAmount on the wrapper.');

        // CIBGLOBALD-4329 - none of these fee fields are editable in either layout's LWC anymore.
        Set<String> oppLineItemFields = new Set<String>(fieldsByObject.get('OpportunityLineItem'));
        Assert.isFalse(oppLineItemFields.contains('DMT_TXT_Commitment_Fees__c'), 'DMT_TXT_Commitment_Fees__c is no longer editable anywhere and must not be tracked.');
        Assert.isFalse(oppLineItemFields.contains('DMT_TXT_Extension_Duration_Fees__c'), 'DMT_TXT_Extension_Duration_Fees__c is no longer editable anywhere and must not be tracked.');
        Assert.isFalse(oppLineItemFields.contains('DMT_TXT_Other_Fees_Accrual__c'), 'DMT_TXT_Other_Fees_Accrual__c is no longer editable anywhere and must not be tracked.');
        Assert.isFalse(oppLineItemFields.contains('DMT_TXT_Other_Fees_NonAccrual__c'), 'DMT_TXT_Other_Fees_NonAccrual__c is no longer editable anywhere and must not be tracked.');
        Assert.isFalse(oppLineItemFields.contains('DMT_Utilisation_Fee__c'), 'DMT_Utilisation_Fee__c is no longer editable anywhere and must not be tracked.');
        Assert.isFalse(oppLineItemFields.contains('DES_Commitment_Fees__c'), 'DES_Commitment_Fees__c is no longer editable in the One-Off Deal layout and must not be tracked.');
        Assert.isFalse(oppLineItemFields.contains('DMT_Extension_Duration_Fees__c'), 'DMT_Extension_Duration_Fees__c is no longer editable in the One-Off Deal layout and must not be tracked here (still read by the separate DMT_OppEconomicsRenderer).');
        Assert.isFalse(oppLineItemFields.contains('DES_Other_Fees__c'), 'DES_Other_Fees__c is no longer editable in the One-Off Deal layout and must not be tracked.');
        Assert.isFalse(oppLineItemFields.contains('DMT_Liquidity_Fee__c'), 'DMT_Liquidity_Fee__c is no longer editable in the One-Off Deal layout and must not be tracked.');
        Assert.isTrue(oppLineItemFields.contains('DMT_bullet_amortization_indicator__c'), 'DMT_bullet_amortization_indicator__c must be tracked.');
        Assert.isTrue(oppLineItemFields.contains('DMT_balloon_amortization_indicator__c'), 'DMT_balloon_amortization_indicator__c must be tracked.');

        Assert.isTrue(fieldsByObject.containsKey('DMT_Opportunity_Tenor__c'), 'Opportunity Products must track DMT_Opportunity_Tenor__c fields.');
        Assert.isTrue(fieldsByObject.containsKey('DMT_Opportunity_Mitigant__c'), 'Opportunity Products must track DMT_Opportunity_Mitigant__c fields.');
        Assert.isTrue(fieldsByObject.containsKey('DMT_Underlying__c'), 'Opportunity Products must track DMT_Underlying__c fields - the Line-layout Underlyings tables.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Underlying__c')).contains('DMT_Max_Amount__c'), 'A restriction-table field should be present.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Underlying__c')).contains('DMT_Drawn_Reference_Amount__c'), 'A profitability-table field should be present - one section unions both tables.');
        // CIBGLOBALD-4117 - decides which of the two Underlying tables a row renders into (per this
        // renderer's own header comment); found untracked via a field-drift audit.
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Underlying__c')).contains('DMT_Underlying_Type__c'), 'DMT_Underlying_Type__c (the Restriction/Profitability branch selector) must be tracked.');
    }

    @IsTest
    static void testGetTrackedFieldsOpportunityHasNoRecordLevelFields() {
        // Every field this component reads lives on OpportunityLineItem or one of its three child
        // objects (see getTrackedFieldsByObject/getChildSections above), none directly on the
        // Opportunity itself, so the flat getTrackedFields() contract correctly returns empty here -
        // same shape as Approval Process Data's Opportunity side.
        List<String> trackedFields = DMT_RendererFactory.getTrackedFields('Products', new Opportunity(RecordTypeId = oppRtId()));
        Assert.isTrue(trackedFields.isEmpty(), 'Products has no Opportunity-native fields to track.');
    }

    @IsTest
    static void testGetChildSectionsOpportunityReturnsFourSectionsWithCorrectShape() {
        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = DMT_RendererFactory.getChildSections('Products', new Opportunity(RecordTypeId = oppRtId()));

        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> byKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        for (DMT_ApprovalChangeStep_Helper.ChildSection s : sections) {
            byKey.put(s.snapshotSectionKey, s);
        }
        Assert.areEqual(4, byKey.size(), 'Opportunity Products must declare exactly 4 child sections.');

        Assert.areEqual('OpportunityId', byKey.get('opportunityLineItem').childLookupField, 'OpportunityLineItem is a direct child - no relationship traversal needed.');
        Assert.areEqual('DMT_Opportunity_Product__r.OpportunityId', byKey.get('opportunityTenor').childLookupField, 'Tenor reaches the Opportunity through OpportunityLineItem.');
        Assert.areEqual('DMT_Opportunity_Product__r.OpportunityId', byKey.get('opportunityMitigant').childLookupField);
        Assert.areEqual('DMT_Opportunity_Product__r.OpportunityId', byKey.get('opportunityUnderlying').childLookupField);

        Assert.isNotNull(byKey.get('opportunityLineItem').orderBy);
        Assert.isNotNull(byKey.get('opportunityTenor').orderBy);
        Assert.isNotNull(byKey.get('opportunityMitigant').orderBy);
        Assert.isNull(byKey.get('opportunityUnderlying').orderBy);
    }

    @IsTest
    static void testGetTrackedFieldsByObjectOtherProductsIncludesStaticAndChildObjectFields() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Products', new DMT_Line__c(RecordTypeId = otherRtId()));

        Assert.isTrue(fieldsByObject.containsKey('DMT_Line__c'), 'OtherProducts must track DMT_Line__c fields.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Line__c')).contains('Line_Id__c'), 'Line_Id__c backs the static-layout parent product Id.');

        Assert.isTrue(fieldsByObject.containsKey('DMT_Risk_Line_Term__c'), 'OtherProducts must track DMT_Risk_Line_Term__c fields.');
        Set<String> riskFields = new Set<String>(fieldsByObject.get('DMT_Risk_Line_Term__c'));
        Assert.isTrue(riskFields.contains('DMT_Amount__c'), 'DMT_Amount__c is a static-layout field.');
        Assert.isTrue(riskFields.contains('g_branch_id__c'), 'g_branch_id__c is the raw field the Booking Geography taxonomy label derives from.');
        Assert.isTrue(riskFields.contains('DMT_Product__r.Name'), 'DMT_Product__r.Name backs the Global Product display value.');

        Assert.isTrue(fieldsByObject.containsKey('DMT_Warranty__c'), 'OtherProducts must track DMT_Warranty__c fields.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Warranty__c')).contains('Name'), 'Warranty Name backs the Required Mitigants display value.');

        Assert.isTrue(fieldsByObject.containsKey('DMT_Currency_Provision__c'), 'OtherProducts must track DMT_Currency_Provision__c fields.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Currency_Provision__c')).contains('g_currency_id__c'), 'g_currency_id__c backs the Available Currencies display value.');

        List<String> flatFields = DMT_RendererFactory.getTrackedFields('Products', new DMT_Line__c(RecordTypeId = otherRtId()));
        Assert.isTrue(new Set<String>(flatFields).contains('Line_Id__c'), 'The flat getTrackedFields() contract must return OtherProducts static Line fields.');
    }

    @IsTest
    static void testGetChildSectionsOtherProductsDeclaresRiskLineListCurrencyProvisionsAndWarranties() {
        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = DMT_RendererFactory.getChildSections('Products', new DMT_Line__c(RecordTypeId = otherRtId()));

        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> byKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        for (DMT_ApprovalChangeStep_Helper.ChildSection s : sections) {
            byKey.put(s.snapshotSectionKey, s);
        }
        Assert.areEqual(3, byKey.size(), 'OtherProducts must declare the riskLineList, currencyProvisions and warranties child sections.');
        Assert.areEqual('DMT_Risk_Line_Term__c', byKey.get('riskLineList').childObjectApiName, 'Without this section the watch gate has nothing to compare Risk rows under, even though Risk fields are tracked.');
        Assert.areEqual('DMT_Line__c', byKey.get('riskLineList').childLookupField);
        Assert.areEqual('DMT_Currency_Provision__c', byKey.get('currencyProvisions').childObjectApiName);
        Assert.areEqual('DMT_Risk_Line_Term__r.DMT_Line__c', byKey.get('currencyProvisions').childLookupField, 'Currency Provisions hang off the Risk, queried by the parent Line.');
        Assert.areEqual('Id', byKey.get('currencyProvisions').parentValueField);
        Assert.areEqual('DMT_Warranty__c', byKey.get('warranties').childObjectApiName);
        Assert.areEqual('DMT_Risk_Line_Term__r.DMT_Line__c', byKey.get('warranties').childLookupField);
    }

    @IsTest
    static void testGetTrackedFieldsByObjectSanctionIncludesStaticAndChildObjectFields() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Products', new DMT_Line__c(RecordTypeId = sanctionRtId()));

        Assert.isTrue(fieldsByObject.containsKey('DMT_Risk_Line_Term__c'), 'Sanction Products must track DMT_Risk_Line_Term__c fields.');
        Set<String> riskFields = new Set<String>(fieldsByObject.get('DMT_Risk_Line_Term__c'));
        Assert.isTrue(riskFields.contains('DMT_Amount__c'), 'DMT_Amount__c is a static-layout field.');
        Assert.isTrue(riskFields.contains('g_line_commitment_level_type__c'), 'g_line_commitment_level_type__c backs the Line / Opportunity display value.');

        Assert.isTrue(fieldsByObject.containsKey('DMT_Warranty__c'), 'Sanction Products must track DMT_Warranty__c fields.');
        Assert.isTrue(fieldsByObject.containsKey('DMT_Currency_Provision__c'), 'Sanction Products must track DMT_Currency_Provision__c fields.');

        List<String> flatFields = DMT_RendererFactory.getTrackedFields('Products', new DMT_Line__c(RecordTypeId = sanctionRtId()));
        Assert.isTrue(new Set<String>(flatFields).contains('CurrencyIsoCode'), 'The flat getTrackedFields() contract must return Sanction static Line fields.');
    }

    // CIBGLOBALD-4117 - these three cover DMT_ProductsRenderer.resolveRenderer()'s own
    // Booking_Geography__c branching (CO/PE/MX), which nothing else exercises through the
    // delegator - DMT_TreasuryProductsRenderer_CO/PE/MXTest call each variant class directly, never
    // through DMT_RendererFactory, so the routing itself was otherwise untested.
    @IsTest
    static void testGetTrackedFieldsByObjectTreasuryRoutesToCOVariant() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject(
            'Products', new DMT_Line__c(RecordTypeId = treasuryRtId(), Booking_Geography__c = 'CO')
        );
        Assert.isTrue(
            new Set<String>(fieldsByObject.get('DMT_Risk_Line_Term__c')).contains('DMT_Singular_Operation__c'),
            'CO geography must route to DMT_TreasuryProductsRenderer_CO, which tracks DMT_Singular_Operation__c.'
        );
    }

    @IsTest
    static void testGetTrackedFieldsByObjectTreasuryRoutesToPEVariant() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject(
            'Products', new DMT_Line__c(RecordTypeId = treasuryRtId(), Booking_Geography__c = 'PE')
        );
        Assert.isTrue(
            new Set<String>(fieldsByObject.get('DMT_Line_Product_Item__c')).contains('Max_Tenor_WC__c'),
            'PE geography must route to DMT_TreasuryProductsRenderer_PE, which tracks Max_Tenor_WC__c.'
        );
    }

    @IsTest
    static void testGetTrackedFieldsByObjectTreasuryRoutesToMXVariant() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject(
            'Products', new DMT_Line__c(RecordTypeId = treasuryRtId(), Booking_Geography__c = 'MX')
        );
        Assert.isTrue(
            new Set<String>(fieldsByObject.get('DMT_Line_Product_Item__c')).contains('Product_Code_Value__c'),
            'MX geography must route to DMT_TreasuryProductsRenderer_MX, which tracks Product_Code_Value__c.'
        );
        List<String> flatFields = DMT_RendererFactory.getTrackedFields(
            'Products', new DMT_Line__c(RecordTypeId = treasuryRtId(), Booking_Geography__c = 'MX')
        );
        Assert.isTrue(new Set<String>(flatFields).contains('FD_Amount__c'), 'The flat contract must also route through the MX variant.');
    }

    @IsTest
    static void testGetChildSectionsSanctionDeclaresCurrencyProvisionsAndWarranties() {
        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = DMT_RendererFactory.getChildSections('Products', new DMT_Line__c(RecordTypeId = sanctionRtId()));

        Set<String> keys = new Set<String>();
        for (DMT_ApprovalChangeStep_Helper.ChildSection s : sections) {
            keys.add(s.snapshotSectionKey);
        }
        Assert.isTrue(keys.contains('riskLineList'), 'Sanction Products must declare the riskLineList child section - without it the watch gate has nothing to compare Risk rows under.');
        Assert.isTrue(keys.contains('currencyProvisions'), 'Sanction Products must declare the currencyProvisions child section.');
        Assert.isTrue(keys.contains('warranties'), 'Sanction Products must declare the warranties child section.');
    }

    @IsTest
    static void testOtherProductsRenderHtmlReturnsPlaceholderWithNoRiskLines() {
        String html = new DMT_OtherProductsRenderer().renderHtml(new DMT_ViewController.LineDataWrapper());
        Assert.isTrue(html.contains('Product data not provided'), 'With no risk lines, OtherProducts must return its placeholder rather than an empty table.');
    }

    @IsTest
    static void testSanctionRenderHtmlReturnsPlaceholderWithNoRiskLines() {
        String html = new DMT_LineSanctionProductsRenderer().renderHtml(new DMT_ViewController.LineDataWrapper());
        Assert.isTrue(html.contains('Approval Product data not provided'), 'With no risk lines, Sanction must return its placeholder rather than an empty table.');
    }
}