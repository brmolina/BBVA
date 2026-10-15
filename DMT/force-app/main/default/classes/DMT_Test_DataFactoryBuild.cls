/*
================================================================================
DMT_Test_DataFactoryBuild - Test Data Factory Build Implementation
================================================================================

ARCHITECTURE:

* PATTERN: Build/Create separation
* PURPOSE: Contains build* methods only (memory-only, no DML, no SOQL)
* OVERRIDES: buildX(..., Map<SObjectField, Object>) applies scenario-specific values
* FACADE: DMT_Test_DataFactory keeps create/generate methods and existing DML
* BULK: Build records here and insert collections from DMT_Test_DataFactory

RULES:

* No DML in this class.
* No SOQL in this class.
* One canonical build method per SObject.
* Scenario-specific differences must be supplied through overrides.
* Existing generate* methods remain in DMT_Test_DataFactory for compatibility.
================================================================================
*/
@IsTest
public class DMT_Test_DataFactoryBuild {

    // ─── CONSTANTS ───────────────────────────────────────────────────────────

    private static final String DEFAULT_CURRENCY = 'EUR';
    private static final String DEFAULT_COUNTRY = 'ES';
    private static final String DEFAULT_CASE_SUBJECT = 'Test Subject';
    private static final String DEFAULT_CASE_CONDITIONS =
        '{"dateMaximum": "2025-11-13","maximumLinePeriod": "365","maximumProductMaturity": "45000",' +
        '"products": ["Derivatives","Equities","Depos"],"clients": ["G00000000000200"], ' +
        '"derivativesAmount":"3", "dvpAmount":"3", "fdAmount":"0"}';

    private static final String DEFAULT_TASK_DESCRIPTION = 'Test Description';

    private static final String DEFAULT_APPROVER_ACCESS_LEVEL = 'Edit';

    private static final String DEFAULT_ITEM_TEXT = 'Esto es un texto normal';
    private static final String DEFAULT_ITEM_TYPE = 'Component';

    private static final String DEFAULT_CUSTOM_ASSOCIATION_CUSTOMER_GROUP_ID =
        'ESCD25LIN00006610ES';
    private static final String DEFAULT_CUSTOM_ASSOCIATION_GROUP_ID =
        'TestCustomerGroupId';

    private static final String DEFAULT_GROUP_PRIORITY = '00';

    private static final Id DEFAULT_DMT_OPPORTUNITY_RECORD_TYPE_ID =
        Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get(DMT_Constants.RT_OPP_DMT_NAME)
            .getRecordTypeId();

    // ─── PRIVATE HELPERS ─────────────────────────────────────────────────────

    private class ApplyOverridesException extends Exception {}

    @TestVisible
    private static SObject applyOverrides(
        SObject record,
        Map<Schema.SObjectField, Object> overrides
    ) {
        if (overrides == null || overrides.isEmpty()) {
            return record;
        }

        final Map<String, Schema.SObjectField> writableFieldsByName =
            record.getSObjectType().getDescribe().fields.getMap();

        for (Schema.SObjectField field : overrides.keySet()) {
            if (field == null) {
                throw new ApplyOverridesException(
                    'applyOverrides received a null field token.'
                );
            }

            final String fieldApiName = field.getDescribe().getName();
            final Schema.SObjectField writableField =
                writableFieldsByName.get(fieldApiName);

            if (writableField == null) {
                throw new ApplyOverridesException(
                    'Field ' + fieldApiName +
                    ' does not exist on target SObject ' +
                    String.valueOf(record.getSObjectType()) + '.'
                );
            }

            final Schema.DescribeFieldResult dfr = writableField.getDescribe();

            if (!dfr.isCreateable() && !dfr.isUpdateable()) {
                throw new ApplyOverridesException(
                    'Field ' + fieldApiName +
                    ' is not createable/updateable on target SObject ' +
                    String.valueOf(record.getSObjectType()) + '.'
                );
            }

            record.put(writableField, overrides.get(field));
        }

        return record;
    }

    // ─── BUILD METHODS — NO DML / NO SOQL ───────────────────────────────────

    // Standard Salesforce objects used by DMT.
    // Layering rule: DES defaults -> DMT defaults -> explicit caller overrides.

    public static Account buildAccount() {
        Account acc = DES_UtilTestClassBuild.buildAccount();

        return (Account) applyOverrides(
            acc,
            new Map<Schema.SObjectField, Object>{
                Account.account_client__c => 'N',
                Account.Advising__c => false,
                Account.BBVA_Entity__c => 'BBVA SA',
                Account.BillingCity => 'MADRID',
                Account.BillingCountry => DEFAULT_COUNTRY,
                Account.BillingPostalCode => '28033',
                Account.BillingState => 'MADRID',
                Account.BillingStreet => 'AV GRAN Test DE HORTALEZA 0321',
                Account.CurrencyIsoCode => DEFAULT_CURRENCY,
                Account.cust_first_income_country_amount__c => 4508815,
                Account.cust_first_income_country_name__c =>
                    'ESPAÑA (2222815.0 EUR)',
                Account.DES_Activity__c => 'NDA',
                Account.Name => 'Test company 1'
            }
        );
    }

    public static Account buildAccount(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (Account) applyOverrides(
            buildAccount(),
            overrides
        );
    }

    public static Opportunity buildOpportunity(
        Id accountId
    ) {
        Opportunity opp =
            DES_UtilTestClassBuild.buildOpportunity(accountId);

        return (Opportunity) applyOverrides(
            opp,
            new Map<Schema.SObjectField, Object>{
                Opportunity.StageName => 'Draft Opp',
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => 'Test Opp',
                Opportunity.DMT_Opp_Id__c => '00001',
                Opportunity.RecordTypeId =>
                    DEFAULT_DMT_OPPORTUNITY_RECORD_TYPE_ID,
                Opportunity.DMT_CUR_Notional_Amount__c => 100,
                Opportunity.DMT_CurrencyText__c => DEFAULT_CURRENCY,
                Opportunity.DMT_DATE_Initial_Date__c => Date.today(),
                Opportunity.DMT_DATE_Maturity_Date__c => Date.today() + 1,
                Opportunity.Entific__c => DEFAULT_COUNTRY,
                Opportunity.DMT_Entity__c => 'ES0182',
                Opportunity.DMT_Product_Area__c => 'GTB',
                Opportunity.DMT_Threshold_Type__c => 'Global'
            }
        );
    }

    public static Opportunity buildOpportunity(
        Id accountId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (Opportunity) applyOverrides(
            buildOpportunity(accountId),
            overrides
        );
    }

    public static OpportunityLineItem buildOpportunityLineItem(
        Id opportunityId,
        Id productId,
        Id pricebookEntryId
    ) {
        OpportunityLineItem oli =
            DES_UtilTestClassBuild.buildOppLineItem(
                opportunityId,
                productId,
                pricebookEntryId
            );

        return (OpportunityLineItem) applyOverrides(
            oli,
            new Map<Schema.SObjectField, Object>{
                OpportunityLineItem.g_currency_id__c => DEFAULT_CURRENCY
            }
        );
    }

    public static OpportunityLineItem buildOpportunityLineItem(
        Id opportunityId,
        Id productId,
        Id pricebookEntryId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (OpportunityLineItem) applyOverrides(
            buildOpportunityLineItem(
                opportunityId,
                productId,
                pricebookEntryId
            ),
            overrides
        );
    }

    public static Pricebook2 buildPricebook() {
        return DES_UtilTestClassBuild.buildPricebook();
    }

    public static Pricebook2 buildPricebook(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (Pricebook2) applyOverrides(
            buildPricebook(),
            overrides
        );
    }

    public static PricebookEntry buildPricebookEntry(
        Id productId
    ) {
        return DES_UtilTestClassBuild.buildPricebookEntry(productId);
    }

    public static PricebookEntry buildPricebookEntry(
        Id productId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (PricebookEntry) applyOverrides(
            buildPricebookEntry(productId),
            overrides
        );
    }

    public static Product2 buildProduct() {
        return DES_UtilTestClassBuild.buildProduct();
    }

    public static Product2 buildProduct(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (Product2) applyOverrides(
            buildProduct(),
            overrides
        );
    }

    public static User buildUser(
        String profileId
    ) {
        User usr = DES_UtilTestClassBuild.buildUser(profileId);

        // Common DMT User defaults layered on top of DES.
        usr.EmailEncodingKey = 'UTF-8';
        usr.Timezonesidkey = 'Europe/London';
        usr.Localesidkey = 'en_US';
        usr.languagelocalekey = 'en_US';

        // DMT users intentionally do not mirror ID_User__c into FederationIdentifier.
        usr.FederationIdentifier = null;
        return usr;
    }

    public static User buildUser(
        String profileId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (User) applyOverrides(
            buildUser(profileId),
            overrides
        );
    }

    public static DMT_Approver__c buildApprover() {
        return new DMT_Approver__c();
    }

    public static DMT_Approver__c buildApprover(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Approver__c) applyOverrides(
            buildApprover(),
            overrides
        );
    }

    public static DMT_Approver_Member__c buildApproverMember(
        Id approverId,
        Id userId
    ) {
        return new DMT_Approver_Member__c(
            DMT_Access_Level__c =
                DEFAULT_APPROVER_ACCESS_LEVEL,
            DMT_Approver__c = approverId,
            DMT_User__c = userId
        );
    }

    public static DMT_Approver_Member__c buildApproverMember(
        Id approverId,
        Id userId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Approver_Member__c) applyOverrides(
            buildApproverMember(approverId, userId),
            overrides
        );
    }

    public static DMT_Approver_Type__c buildApproverType(
        String name,
        String externalId
    ) {
        return new DMT_Approver_Type__c(
            Name = name,
            DMT_External_Id__c = externalId
        );
    }

    public static DMT_Approver_Type__c buildApproverType(
        String name,
        String externalId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Approver_Type__c) applyOverrides(
            buildApproverType(name, externalId),
            overrides
        );
    }

    public static DMT_ApproversView__c buildApproversView() {
        return new DMT_ApproversView__c(
            Name = 'PruebaLinea',
            DMT_DeveloperName__c = 'DMT_PruebaLinea'
        );
    }

    public static DMT_ApproversView__c buildApproversView(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_ApproversView__c) applyOverrides(
            buildApproversView(),
            overrides
        );
    }

    public static Case buildCase(
        Id ownerId,
        Id recordTypeId
    ) {
        return new Case(
            OwnerId = ownerId,
            RecordTypeId = recordTypeId,
            CurrencyIsoCode = DEFAULT_CURRENCY,
            Subject = DEFAULT_CASE_SUBJECT,
            DMT_ConditionsCloseCase__c =
                DEFAULT_CASE_CONDITIONS
        );
    }

    public static Case buildCase(
        Id ownerId,
        Id recordTypeId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (Case) applyOverrides(
            buildCase(ownerId, recordTypeId),
            overrides
        );
    }

    public static DMT_Consolidated_Line__c buildConsolidatedLine(
        String lineId
    ) {
        return new DMT_Consolidated_Line__c(
            Line_Id__c = lineId,
            gf_group_priority_line_id__c =
                DEFAULT_GROUP_PRIORITY,
            g_entific_id__c = DEFAULT_COUNTRY
        );
    }

    public static DMT_Consolidated_Line__c buildConsolidatedLine(
        String lineId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Consolidated_Line__c) applyOverrides(
            buildConsolidatedLine(lineId),
            overrides
        );
    }

    public static DMT_Currency_Provision__c buildCurrencyProvision(
        Id riskLineTermId
    ) {
        return new DMT_Currency_Provision__c(
            dmt_risk_line_term__c = riskLineTermId,
            Name = DEFAULT_CURRENCY,
            CurrencyIsoCode = DEFAULT_CURRENCY
        );
    }

    public static DMT_Currency_Provision__c buildCurrencyProvision(
        Id riskLineTermId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Currency_Provision__c) applyOverrides(
            buildCurrencyProvision(riskLineTermId),
            overrides
        );
    }

    public static Custom_Association_Opportunity__c buildCustomAssociationOpportunity(
        Id opportunityId
    ) {
        return new Custom_Association_Opportunity__c(
            Opportunity__c = opportunityId
        );
    }

    public static Custom_Association_Opportunity__c buildCustomAssociationOpportunity(
        Id opportunityId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (Custom_Association_Opportunity__c) applyOverrides(
            buildCustomAssociationOpportunity(opportunityId),
            overrides
        );
    }

    public static DMT_Custom_Association_ClientOpportunity__c buildCustomAssociationClientOpportunity(
        Id customAssociationOpportunityId,
        Id clientId
    ) {
        return new DMT_Custom_Association_ClientOpportunity__c(
            DMT_Custom_Association_Opportunity__c = customAssociationOpportunityId,
            DMT_Client__c = clientId
        );
    }

    public static DMT_Custom_Association_ClientOpportunity__c buildCustomAssociationClientOpportunity(
        Id customAssociationOpportunityId,
        Id clientId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Custom_Association_ClientOpportunity__c) applyOverrides(
            buildCustomAssociationClientOpportunity(
                customAssociationOpportunityId,
                clientId
            ),
            overrides
        );
    }

    public static Custom_Association__c buildCustomAssociation(
        Id lineId,
        Id accountId
    ) {
        return new Custom_Association__c(
            Group__c = accountId,
            DMT_Line__c = lineId,
            gf_customer_group_id__c =
                DEFAULT_CUSTOM_ASSOCIATION_CUSTOMER_GROUP_ID,
            g_group_id__c =
                DEFAULT_CUSTOM_ASSOCIATION_GROUP_ID
        );
    }

    public static Custom_Association__c buildCustomAssociation(
        Id lineId,
        Id accountId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (Custom_Association__c) applyOverrides(
            buildCustomAssociation(lineId, accountId),
            overrides
        );
    }

    public static Custom_Association_Client__c buildCustomAssociationClient(
        Id customAssociationId
    ) {
        return new Custom_Association_Client__c(
            alpha_code_client__c = 'ES0182000170441',
            custom_association__c = customAssociationId,
            Name = 'GRIFOLS S.A.',
            CurrencyIsoCode = DEFAULT_CURRENCY
        );
    }

    public static Custom_Association_Client__c buildCustomAssociationClient(
        Id customAssociationId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (Custom_Association_Client__c) applyOverrides(
            buildCustomAssociationClient(customAssociationId),
            overrides
        );
    }

    public static DMT_Feature__c buildFeature() {
        return new DMT_Feature__c(
            gf_audit_date__c = Date.today()
        );
    }

    public static DMT_Feature__c buildFeature(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Feature__c) applyOverrides(
            buildFeature(),
            overrides
        );
    }

    public static DMT_Global_Structure__c buildGlobalStructure(
        String opportunityId
    ) {
        return new DMT_Global_Structure__c(
            DMT_Opportunity__c = opportunityId,
            DMT_Funds__c = Integer.valueOf((Math.random() * 10000))
        );
    }

    public static DMT_Global_Structure__c buildGlobalStructure(
        String opportunityId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Global_Structure__c) applyOverrides(
            buildGlobalStructure(opportunityId),
            overrides
        );
    }

    public static DMT_Items__c buildItem(
        Id viewId
    ) {
        return new DMT_Items__c(
            DMT_Text__c = DEFAULT_ITEM_TEXT,
            Type_Item__c = DEFAULT_ITEM_TYPE,
            DMT_View__c = viewId
        );
    }

    public static DMT_Items__c buildItem(
        Id viewId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Items__c) applyOverrides(
            buildItem(viewId),
            overrides
        );
    }

    public static Local_Client__c buildLocalClient(
        Id accountId,
        String alphaCode
    ) {
        return new Local_Client__c(
            Cib_Client__c = accountId,
            Alpha_code__c = alphaCode
        );
    }

    public static Local_Client__c buildLocalClient(
        Id accountId,
        String alphaCode,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (Local_Client__c) applyOverrides(
            buildLocalClient(accountId, alphaCode),
            overrides
        );
    }

    public static DMT_Line__c buildLine(
        Id clientId,
        Id recordTypeId,
        String lineId
    ) {
        return new DMT_Line__c(
            Client__c = clientId,
            RecordTypeId = recordTypeId,
            Line_Id__c = lineId
        );
    }

    public static DMT_Line__c buildLine(
        Id clientId,
        Id recordTypeId,
        String lineId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Line__c) applyOverrides(
            buildLine(clientId, recordTypeId, lineId),
            overrides
        );
    }

    public static DMT_Line_Product_Item__c buildLineProductItem(
        Id lineId,
        Id productId
    ) {
        return new DMT_Line_Product_Item__c(
            Name = 'Product line item DEPO',
            CurrencyIsoCode = DEFAULT_CURRENCY,
            Line__c = lineId,
            Product__c = productId,
            Max_Tenor_WC__c = '7',
            DMT_DerivativeRestriction__c = true,
            DMT_DVPRestriction__c = true,
            DMT_FDRestriction__c = true,
            Product_Code_Value__c = 'DEPO'
        );
    }

    public static DMT_Line_Product_Item__c buildLineProductItem(
        Id lineId,
        Id productId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Line_Product_Item__c) applyOverrides(
            buildLineProductItem(lineId, productId),
            overrides
        );
    }

    public static DMT_Opportunity_Client__c buildOpportunityClient(
        String opportunityId
    ) {
        return new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opportunityId
        );
    }

    public static DMT_Opportunity_Client__c buildOpportunityClient(
        String opportunityId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Opportunity_Client__c) applyOverrides(
            buildOpportunityClient(opportunityId),
            overrides
        );
    }

    public static DMT_Opportunity_Mitigant__c buildOpportunityMitigant(
        Id opportunityLineItemId
    ) {
        return new DMT_Opportunity_Mitigant__c(
            DMT_Opportunity_Product__c = opportunityLineItemId
        );
    }

    public static DMT_Opportunity_Mitigant__c buildOpportunityMitigant(
        Id opportunityLineItemId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Opportunity_Mitigant__c) applyOverrides(
            buildOpportunityMitigant(opportunityLineItemId),
            overrides
        );
    }

    public static DMT_Opportunity_Tenor__c buildOpportunityTenor(
        Id opportunityLineItemId
    ) {
        return new DMT_Opportunity_Tenor__c(
            DMT_Opportunity_Product__c = opportunityLineItemId
        );
    }

    public static DMT_Opportunity_Tenor__c buildOpportunityTenor(
        Id opportunityLineItemId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Opportunity_Tenor__c) applyOverrides(
            buildOpportunityTenor(opportunityLineItemId),
            overrides
        );
    }

    public static DMT_Risk_Line_Term__c buildRiskLineTerm(
        Id lineId
    ) {
        return new DMT_Risk_Line_Term__c(
            DMT_Line__c = lineId,
            CurrencyIsoCode = DEFAULT_CURRENCY
        );
    }

    public static DMT_Risk_Line_Term__c buildRiskLineTerm(
        Id lineId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Risk_Line_Term__c) applyOverrides(
            buildRiskLineTerm(lineId),
            overrides
        );
    }

    public static DMT_Selected_Features__c buildSelectedFeature(
        Id featureId
    ) {
        return new DMT_Selected_Features__c(
            Feature__c = featureId
        );
    }

    public static DMT_Selected_Features__c buildSelectedFeature(
        Id featureId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Selected_Features__c) applyOverrides(
            buildSelectedFeature(featureId),
            overrides
        );
    }

    public static Task buildTask(
        Id ownerId,
        Id recordTypeId,
        Id whatId
    ) {
        return new Task(
            OwnerId = ownerId,
            RecordTypeId = recordTypeId,
            WhatId = whatId,
            Description = DEFAULT_TASK_DESCRIPTION
        );
    }

    public static Task buildTask(
        Id ownerId,
        Id recordTypeId,
        Id whatId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (Task) applyOverrides(
            buildTask(ownerId, recordTypeId, whatId),
            overrides
        );
    }

    public static DMT_Task_Approver_Relationship__c buildTaskApproverRelationship(
        Id approverId,
        Id taskTypeId
    ) {
        return new DMT_Task_Approver_Relationship__c(
            DMT_Approver__c = approverId,
            DMT_Task_Type__c = taskTypeId
        );
    }

    public static DMT_Task_Approver_Relationship__c buildTaskApproverRelationship(
        Id approverId,
        Id taskTypeId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Task_Approver_Relationship__c) applyOverrides(
            buildTaskApproverRelationship(approverId, taskTypeId),
            overrides
        );
    }

    public static DMT_Task_Relationship__c buildTaskRelationship(
        Id fromTaskTypeId,
        Id toTaskTypeId
    ) {
        return new DMT_Task_Relationship__c(
            DMT_From_Task_Type__c = fromTaskTypeId,
            DMT_To_Task_Type__c = toTaskTypeId
        );
    }

    public static DMT_Task_Relationship__c buildTaskRelationship(
        Id fromTaskTypeId,
        Id toTaskTypeId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Task_Relationship__c) applyOverrides(
            buildTaskRelationship(fromTaskTypeId, toTaskTypeId),
            overrides
        );
    }

    public static DMT_Task_Type__c buildTaskType() {
        return new DMT_Task_Type__c(
            CurrencyIsoCode = DEFAULT_CURRENCY
        );
    }

    public static DMT_Task_Type__c buildTaskType(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Task_Type__c) applyOverrides(
            buildTaskType(),
            overrides
        );
    }

    public static DMT_Taxonomy_Hierarchy__c buildTaxonomyHierarchy() {
        return new DMT_Taxonomy_Hierarchy__c(
            gf_cutoff_date__c = System.today(),
            g_hierarchy_id__c = 'TestId',
            gf_lvl_1_hier_catalog_val_id__c = 'TestValueLevel1'
        );
    }

    public static DMT_Taxonomy_Hierarchy__c buildTaxonomyHierarchy(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Taxonomy_Hierarchy__c) applyOverrides(
            buildTaxonomyHierarchy(),
            overrides
        );
    }

    public static DMT_Taxonomy_Relationship__c buildTaxonomyRelationship(
        Id initialTaxonomyValueId,
        Id finalTaxonomyValueId
    ) {
        return new DMT_Taxonomy_Relationship__c(
            DMT_Initial_Taxonomy_Value__c = initialTaxonomyValueId,
            DMT_Final_Taxonomy_Value__c = finalTaxonomyValueId,
            DMT_Value_Catalog_Initial__c = 'TestInitial',
            DMT_Value_Catalog_Final__c = 'TestFinal'
        );
    }

    public static DMT_Taxonomy_Relationship__c buildTaxonomyRelationship(
        Id initialTaxonomyValueId,
        Id finalTaxonomyValueId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Taxonomy_Relationship__c) applyOverrides(
            buildTaxonomyRelationship(
                initialTaxonomyValueId,
                finalTaxonomyValueId
            ),
            overrides
        );
    }

    public static DMT_Taxonomy_Values__c buildTaxonomyValue(
        String name,
        String externalId,
        String catalog
    ) {
        return new DMT_Taxonomy_Values__c(
            DMT_Name__c = name,
            DMT_Name_EN__c = name,
            DMT_External_Id__c = externalId,
            CurrencyIsoCode = DEFAULT_CURRENCY,
            DMT_Catalog__c = catalog
        );
    }

    public static DMT_Taxonomy_Values__c buildTaxonomyValue(
        String name,
        String externalId,
        String catalog,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Taxonomy_Values__c) applyOverrides(
            buildTaxonomyValue(name, externalId, catalog),
            overrides
        );
    }

    public static DMT_Underlying__c buildUnderlying(
        Id opportunityLineItemId
    ) {
        return new DMT_Underlying__c(
            DMT_Opportunity_Product__c = opportunityLineItemId,
            Name = 'Test Underlying Restriction',
            DMT_Underlying_Type__c = 'Restriction',
            DMT_Max_Amount__c = 50000,
            DMT_Currency__c = DEFAULT_CURRENCY,
            DMT_Max_Term__c = '366'
        );
    }

    public static DMT_Underlying__c buildUnderlying(
        Id opportunityLineItemId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Underlying__c) applyOverrides(
            buildUnderlying(opportunityLineItemId),
            overrides
        );
    }

    public static DMT_Warranty__c buildWarranty(
        Id riskLineTermId
    ) {
        return new DMT_Warranty__c(
            dmt_risk_line_term__c = riskLineTermId,
            Name = 'Others > Confort letter',
            CurrencyIsoCode = DEFAULT_CURRENCY
        );
    }

    public static DMT_Warranty__c buildWarranty(
        Id riskLineTermId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Warranty__c) applyOverrides(
            buildWarranty(riskLineTermId),
            overrides
        );
    }

    public static DMT_X_Sell__c buildXSell(
        Id opportunityId
    ) {
        return new DMT_X_Sell__c(
            Opportunity__c = opportunityId,
            Year__c = '2035'
        );
    }

    public static DMT_X_Sell__c buildXSell(
        Id opportunityId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_X_Sell__c) applyOverrides(
            buildXSell(opportunityId),
            overrides
        );
    }

    // ─── CIBGLOBALD-4374 - DMT_TeamMember__c ───────────────────────────────────

    private static final String DEFAULT_TEAM_MEMBER_ACCESS_LEVEL = 'Read';

    // A team member belongs to a Line OR to an Opportunity: pass the one it belongs to and null for the other.
    public static DMT_TeamMember__c buildTeamMember(
        Id userId,
        Id lineId,
        Id opportunityId
    ) {
        return new DMT_TeamMember__c(
            User__c = userId,
            Line__c = lineId,
            Opportunity__c = opportunityId,
            AccessLevel__c = DEFAULT_TEAM_MEMBER_ACCESS_LEVEL
        );
    }

    public static DMT_TeamMember__c buildTeamMember(
        Id userId,
        Id lineId,
        Id opportunityId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_TeamMember__c) applyOverrides(
            buildTeamMember(userId, lineId, opportunityId),
            overrides
        );
    }

    // ─── CIBGLOBALD-4374 - Attachment ───────────────────────────────────────────

    public static Attachment buildAttachment(Id parentId, String name) {
        return new Attachment(
            ParentId = parentId,
            Name = name,
            Body = Blob.valueOf('CIBGLOBALD-4374 test attachment')
        );
    }
}
