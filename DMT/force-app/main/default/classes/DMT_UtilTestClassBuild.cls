/*----------------------------------------------------------------------------------------------
================================================================================
DMT_UtilTestClassBuild - DMT Test Data Build Implementation
================================================================================
TYPE:Apex@TestBuildUtility(@IsTest)
DOMAIN:DMT
PRIORITY:MemoryOnly>ReuseDESFacade>DMTDefaults>CallerOverrides>AvoidDuplication
ARCHITECTURE:
* PATTERN: Build/Create separation aligned with DES.
* PURPOSE: Contains only canonical build* methods for DMT-owned objects or objects requiring DMT-specific defaults.
* MEMORY_ONLY: All build methods return in-memory SObjects; this class performs no DML and no SOQL.
* DES_BRIDGE: For DES-owned/standard objects requiring DMT defaults, start from DES_UtilTestClass.
* NEVER_CALL_DES_BUILD_DIRECTLY: DES_UtilTestClassBuild is an implementation detail behind the DES facade.
* LAYERING: DES defaults -> DMT defaults -> explicit caller/test overrides.
* DMT_ONLY: For DMT-owned objects, construct the minimum reusable DMT object and apply caller overrides last.
WHEN THIS CLASS MUST NOT BE USED:
* If DES already builds the object and DMT adds no field/default/behavior, do not add a method here.
* In that case DMT_Test_DataFactory calls DES_UtilTestClass directly.
* Do not create passthrough methods for AMH relationships, Pricebook2, PricebookEntry, Product2 or other DES-complete objects unless DMT later adds real behavior.
API_CONTRACT:
* BUILD_ONLY: Public API is buildX()/buildX(..., overrides) for DMT-owned/defaulted objects.
* NO_DML: insert, update, upsert, delete, undelete and Database.* DML operations are forbidden.
* NO_SOQL: Queries are forbidden. Use Schema.describe when metadata resolution is required.
* NO_HIDDEN_DML: Do not call a helper/create method that performs DML indirectly.
* NO_HIDDEN_SOQL: Do not call a helper that queries data indirectly.
* ONE_CANONICAL_BUILD_PER_OBJECT: Do not introduce multiple builders for the same SObject under different names.
* OVERRIDES_LAST: Caller overrides have the highest priority and must remain a null-safe no-op when absent.
* VALIDATE_OVERRIDES: Preserve writable-field validation before record.put().
* NO_SCENARIO_DEFAULTS: Values specific to one test scenario belong in DMT_Test_DataFactory overrides.
* NO_RANDOM_TEST_DATA: Prefer deterministic defaults. Preserve legacy random behavior only where changing it would alter existing behavior.
DEFAULT OWNERSHIP:
* DES defaults -> DES_UtilTestClassConstants / DES build implementation.
* DMT reusable defaults -> DMT_UtilTestClassConstants.
* Scenario/test-specific values -> DMT_Test_DataFactory overrides.
AI / AUTOMATED EDITING RULES:
* Before adding a builder for a DES/standard object, search DES_UtilTestClass first.
* If DMT adds nothing to the DES result, STOP and do not add the builder.
* Never replace DES_UTIL.buildX() with DES_UtilTestClassBuild.buildX().
* Never move inserts, updates, queries or scenario orchestration into this class.
* Never duplicate DES defaults in DMT constants/builders unless DMT intentionally overrides them.
* When adding a DMT default, define reusable literal values in DMT_UtilTestClassConstants and reference them here.
* Preserve field precedence: DES < DMT < caller override.
PRE_EDIT_CHECKLIST:
* Confirm the object actually requires a DMT layer.
* Confirm DES cannot already satisfy the requirement unchanged.
* Confirm there is no DML or SOQL in the new code path.
* Confirm reusable literals are in DMT_UtilTestClassConstants.
* Confirm explicit overrides are applied last.
* Confirm no duplicate canonical builder is introduced.
* Confirm DES is accessed through DES_UtilTestClass, not DES_UtilTestClassBuild.
History
-------
2026-10-19  Added DMT architecture/AI operating contract aligned with DES conventions.
            Documented strict build-only behavior, DES-facade bridge and anti-wrapper rules.
================================================================================
----------------------------------------------------------------------------------------------*/

@IsTest
public class DMT_UtilTestClassBuild {

    // ─── DES FACADE ─────────────────────────────────────────────────────────

    private static final DES_UtilTestClass DES_UTIL = new DES_UtilTestClass();

    // ─── PRIVATE HELPERS ─────────────────────────────────────────────────────

    private class ApplyOverridesException extends Exception {}

    @TestVisible
    private static SObject applyOverrides(SObject record, Map<Schema.SObjectField, Object> overrides) {
        if (overrides == null || overrides.isEmpty()) {
            return record;
        }
        final Map<String, Schema.SObjectField> writableFieldsByName = record.getSObjectType().getDescribe().fields.getMap();
        for (Schema.SObjectField field : overrides.keySet()) {
            if (field == null) {
                throw new ApplyOverridesException(
                    'applyOverrides received a null field token.'
                );
            }
            final String fieldApiName = field.getDescribe().getName();
            final Schema.SObjectField writableField = writableFieldsByName.get(fieldApiName);
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
        Account acc = DES_UTIL.buildAccount();
        return (Account) applyOverrides(
            acc,
            new Map<Schema.SObjectField, Object>{
                Account.Advising__c => DMT_UtilTestClassConstants.DEFAULT_ACCOUNT_ADVISING,
                Account.BBVA_Entity__c => DMT_UtilTestClassConstants.DEFAULT_ACCOUNT_BBVA_ENTITY,
                Account.BillingCity => DMT_UtilTestClassConstants.DEFAULT_ACCOUNT_BILLING_CITY,
                Account.BillingCountry => DMT_UtilTestClassConstants.DEFAULT_COUNTRY,
                Account.BillingPostalCode => DMT_UtilTestClassConstants.DEFAULT_ACCOUNT_BILLING_POSTAL_CODE,
                Account.BillingState => DMT_UtilTestClassConstants.DEFAULT_ACCOUNT_BILLING_STATE,
                Account.BillingStreet => DMT_UtilTestClassConstants.DEFAULT_ACCOUNT_BILLING_STREET,
                Account.CurrencyIsoCode => DMT_UtilTestClassConstants.DEFAULT_CURRENCY,
                Account.cust_first_income_country_amount__c => DMT_UtilTestClassConstants.DEFAULT_ACCOUNT_FIRST_INCOME_AMOUNT,
                Account.cust_first_income_country_name__c => DMT_UtilTestClassConstants.DEFAULT_ACCOUNT_FIRST_INCOME_NAME,
                Account.DES_Activity__c => DMT_UtilTestClassConstants.DEFAULT_ACCOUNT_ACTIVITY,
                Account.Name => DMT_UtilTestClassConstants.DEFAULT_ACCOUNT_NAME
            }
        );
    }

    public static Account buildAccount(Map<Schema.SObjectField, Object> overrides) {
        return (Account) applyOverrides(buildAccount(), overrides);
    }

    public static Opportunity buildOpportunity(Id accountId) {
        Opportunity opp = DES_UTIL.buildOpportunity(accountId);
        return (Opportunity) applyOverrides(
            opp,
            new Map<Schema.SObjectField, Object>{
                Opportunity.StageName => DMT_UtilTestClassConstants.DEFAULT_OPPORTUNITY_STAGE,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => DMT_UtilTestClassConstants.DEFAULT_OPPORTUNITY_NAME,
                Opportunity.DMT_Opp_Id__c => DMT_UtilTestClassConstants.DEFAULT_OPPORTUNITY_DMT_ID,
                Opportunity.RecordTypeId =>
                    DMT_UtilTestClassConstants.DEFAULT_DMT_OPPORTUNITY_RECORD_TYPE_ID,
                Opportunity.DMT_CUR_Notional_Amount__c => DMT_UtilTestClassConstants.DEFAULT_OPPORTUNITY_NOTIONAL_AMOUNT,
                Opportunity.DMT_CurrencyText__c => DMT_UtilTestClassConstants.DEFAULT_CURRENCY,
                Opportunity.DMT_DATE_Initial_Date__c => Date.today(),
                Opportunity.DMT_DATE_Maturity_Date__c => Date.today().addDays(DMT_UtilTestClassConstants.DEFAULT_OPPORTUNITY_MATURITY_DAYS),
                Opportunity.Entific__c => DMT_UtilTestClassConstants.DEFAULT_COUNTRY,
                Opportunity.DMT_Entity__c => DMT_UtilTestClassConstants.DEFAULT_OPPORTUNITY_ENTITY,
                Opportunity.DMT_Product_Area__c => DMT_UtilTestClassConstants.DEFAULT_OPPORTUNITY_PRODUCT_AREA,
                Opportunity.DMT_Threshold_Type__c => DMT_UtilTestClassConstants.DEFAULT_OPPORTUNITY_THRESHOLD_TYPE
            }
        );
    }

    public static Opportunity buildOpportunity(Id accountId, Map<Schema.SObjectField, Object> overrides) {
        return (Opportunity) applyOverrides(buildOpportunity(accountId), overrides);
    }

    public static OpportunityLineItem buildOppLineItem(Id opportunityId, Id productId, Id pricebookEntryId) {
        OpportunityLineItem oli = DES_UTIL.buildOppLineItem(opportunityId, productId, pricebookEntryId);
        return (OpportunityLineItem) applyOverrides(
            oli,
            new Map<Schema.SObjectField, Object>{
                OpportunityLineItem.g_currency_id__c => DMT_UtilTestClassConstants.DEFAULT_CURRENCY
            }
        );
    }

    public static OpportunityLineItem buildOppLineItem(Id opportunityId, Id productId, Id pricebookEntryId, Map<Schema.SObjectField, Object> overrides) {
        return (OpportunityLineItem) applyOverrides(buildOppLineItem(opportunityId, productId, pricebookEntryId), overrides);
    }

    public static User buildUser(String profileId) {
        User usr = DES_UTIL.buildUser(profileId);
        // DMT users intentionally do not mirror ID_User__c into FederationIdentifier.
        usr.FederationIdentifier = null;
        return usr;
    }

    public static User buildUser(String profileId, Map<Schema.SObjectField, Object> overrides) {
        return (User) applyOverrides(buildUser(profileId), overrides);
    }

    public static DMT_Approver__c buildApprover() {
        return new DMT_Approver__c();
    }

    public static DMT_Approver__c buildApprover(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Approver__c) applyOverrides(buildApprover(), overrides);
    }

    public static DMT_Approver_Member__c buildApproverMember(Id approverId, Id userId) {
        return new DMT_Approver_Member__c(
            DMT_Access_Level__c = DMT_UtilTestClassConstants.DEFAULT_APPROVER_ACCESS_LEVEL,
            DMT_Approver__c = approverId,
            DMT_User__c = userId
        );
    }

    public static DMT_Approver_Member__c buildApproverMember(Id approverId, Id userId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Approver_Member__c) applyOverrides(buildApproverMember(approverId, userId), overrides);
    }

    public static DMT_Approver_Type__c buildApproverType(String name, String externalId) {
        return new DMT_Approver_Type__c(Name = name, DMT_External_Id__c = externalId);
    }

    public static DMT_Approver_Type__c buildApproverType(String name, String externalId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Approver_Type__c) applyOverrides(buildApproverType(name, externalId), overrides);
    }

    public static DMT_ApproversView__c buildApproversView() {
        return new DMT_ApproversView__c(
            Name = DMT_UtilTestClassConstants.DEFAULT_APPROVERS_VIEW_NAME,
            DMT_DeveloperName__c = DMT_UtilTestClassConstants.DEFAULT_APPROVERS_VIEW_DEVELOPER_NAME
        );
    }

    public static DMT_ApproversView__c buildApproversView(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_ApproversView__c) applyOverrides(buildApproversView(), overrides);
    }

    public static Case buildCase(Id ownerId, Id recordTypeId) {
        return new Case(
            OwnerId = ownerId,
            RecordTypeId = recordTypeId,
            CurrencyIsoCode = DMT_UtilTestClassConstants.DEFAULT_CURRENCY,
            Subject = DMT_UtilTestClassConstants.DEFAULT_CASE_SUBJECT,
            DMT_ConditionsCloseCase__c = DMT_UtilTestClassConstants.DEFAULT_CASE_CONDITIONS);
    }

    public static Case buildCase(Id ownerId, Id recordTypeId, Map<Schema.SObjectField, Object> overrides) {
        return (Case) applyOverrides(buildCase(ownerId, recordTypeId), overrides);
    }

    public static DMT_Consolidated_Line__c buildConsolidatedLine(String lineId) {
        return new DMT_Consolidated_Line__c(
            Line_Id__c = lineId,
            gf_group_priority_line_id__c = DMT_UtilTestClassConstants.DEFAULT_GROUP_PRIORITY,
            g_entific_id__c = DMT_UtilTestClassConstants.DEFAULT_COUNTRY
        );
    }

    public static DMT_Consolidated_Line__c buildConsolidatedLine(String lineId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Consolidated_Line__c) applyOverrides(buildConsolidatedLine(lineId), overrides);
    }

    public static DMT_Currency_Provision__c buildCurrencyProvision(Id riskLineTermId) {
        return new DMT_Currency_Provision__c(
            dmt_risk_line_term__c = riskLineTermId,
            Name = DMT_UtilTestClassConstants.DEFAULT_CURRENCY,
            CurrencyIsoCode = DMT_UtilTestClassConstants.DEFAULT_CURRENCY
        );
    }

    public static DMT_Currency_Provision__c buildCurrencyProvision(Id riskLineTermId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Currency_Provision__c) applyOverrides(buildCurrencyProvision(riskLineTermId), overrides);
    }

    public static Custom_Association_Opportunity__c buildCustomAssociationOpportunity(Id opportunityId) {
        return new Custom_Association_Opportunity__c(Opportunity__c = opportunityId);
    }

    public static Custom_Association_Opportunity__c buildCustomAssociationOpportunity(Id opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return (Custom_Association_Opportunity__c) applyOverrides(buildCustomAssociationOpportunity(opportunityId), overrides);
    }

    public static DMT_Custom_Association_ClientOpportunity__c buildCustomAssociationClientOpportunity(Id customAssociationOpportunityId, Id clientId) {
        return new DMT_Custom_Association_ClientOpportunity__c(DMT_Custom_Association_Opportunity__c = customAssociationOpportunityId, DMT_Client__c = clientId);
    }

    public static DMT_Custom_Association_ClientOpportunity__c buildCustomAssociationClientOpportunity(Id customAssociationOpportunityId, Id clientId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Custom_Association_ClientOpportunity__c) applyOverrides(buildCustomAssociationClientOpportunity(customAssociationOpportunityId, clientId), overrides);
    }

    public static Custom_Association__c buildCustomAssociation(Id lineId, Id accountId) {
        return new Custom_Association__c(
            Group__c = accountId,
            DMT_Line__c = lineId,
            gf_customer_group_id__c = DMT_UtilTestClassConstants.DEFAULT_CUSTOM_ASSOCIATION_CUSTOMER_GROUP_ID,
            g_group_id__c = DMT_UtilTestClassConstants.DEFAULT_CUSTOM_ASSOCIATION_GROUP_ID
        );
    }

    public static Custom_Association__c buildCustomAssociation(Id lineId, Id accountId, Map<Schema.SObjectField, Object> overrides) {
        return (Custom_Association__c) applyOverrides(buildCustomAssociation(lineId, accountId), overrides);
    }

    public static Custom_Association_Client__c buildCustomAssociationClient() {
        return new Custom_Association_Client__c(
            alpha_code_client__c = DMT_UtilTestClassConstants.DEFAULT_CUSTOM_ASSOCIATION_CLIENT_ALPHA_CODE,
            Name = DMT_UtilTestClassConstants.DEFAULT_CUSTOM_ASSOCIATION_CLIENT_NAME,
            CurrencyIsoCode = DMT_UtilTestClassConstants.DEFAULT_CURRENCY
        );
    }

    public static Custom_Association_Client__c buildCustomAssociationClient(Map<Schema.SObjectField, Object> overrides) {
        return (Custom_Association_Client__c) applyOverrides(buildCustomAssociationClient(), overrides);
    }

    public static DMT_Feature__c buildFeature() {
        return new DMT_Feature__c(gf_audit_date__c = Date.today());
    }

    public static DMT_Feature__c buildFeature(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Feature__c) applyOverrides(buildFeature(), overrides);
    }

    public static DMT_Global_Structure__c buildGlobalStructure(String opportunityId) {
        return new DMT_Global_Structure__c(
            DMT_Opportunity__c = opportunityId,
            DMT_Funds__c = Integer.valueOf((Math.random() * DMT_UtilTestClassConstants.DEFAULT_GLOBAL_STRUCTURE_FUNDS_MAX))
        );
    }

    public static DMT_Global_Structure__c buildGlobalStructure(String opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Global_Structure__c) applyOverrides(buildGlobalStructure(opportunityId), overrides);
    }

    public static DMT_Items__c buildItem(Id viewId) {
        return new DMT_Items__c(
            DMT_Text__c = DMT_UtilTestClassConstants.DEFAULT_ITEM_TEXT,
            Type_Item__c = DMT_UtilTestClassConstants.DEFAULT_ITEM_TYPE,
            DMT_View__c = viewId
        );
    }

    public static DMT_Items__c buildItem(Id viewId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Items__c) applyOverrides(buildItem(viewId), overrides);
    }

    public static Local_Client__c buildLocalClient(Id accountId, String alphaCode) {
        return new Local_Client__c(Cib_Client__c = accountId, Alpha_code__c = alphaCode);
    }

    public static Local_Client__c buildLocalClient(Id accountId, String alphaCode, Map<Schema.SObjectField, Object> overrides) {
        return (Local_Client__c) applyOverrides(buildLocalClient(accountId, alphaCode), overrides);
    }

    public static DMT_Line__c buildLine() {
        return new DMT_Line__c();
    }

    public static DMT_Line__c buildLine(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Line__c) applyOverrides(buildLine(), overrides);
    }

    public static DMT_Line_Product_Item__c buildLineProductItem() {
        return new DMT_Line_Product_Item__c(
            Name = DMT_UtilTestClassConstants.DEFAULT_LINE_PRODUCT_ITEM_NAME,
            CurrencyIsoCode = DMT_UtilTestClassConstants.DEFAULT_CURRENCY,
            Max_Tenor_WC__c = DMT_UtilTestClassConstants.DEFAULT_LINE_PRODUCT_ITEM_MAX_TENOR,
            DMT_DerivativeRestriction__c = DMT_UtilTestClassConstants.DEFAULT_BOOLEAN_TRUE,
            DMT_DVPRestriction__c = DMT_UtilTestClassConstants.DEFAULT_BOOLEAN_TRUE,
            DMT_FDRestriction__c = DMT_UtilTestClassConstants.DEFAULT_BOOLEAN_TRUE,
            Product_Code_Value__c = DMT_UtilTestClassConstants.DEFAULT_LINE_PRODUCT_ITEM_PRODUCT_CODE
        );
    }

    public static DMT_Line_Product_Item__c buildLineProductItem(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Line_Product_Item__c) applyOverrides(buildLineProductItem(), overrides);
    }

    public static DMT_Opportunity_Client__c buildOpportunityClient(String opportunityId) {
        return new DMT_Opportunity_Client__c(DMT_MDE_Opportunity__c = opportunityId);
    }

    public static DMT_Opportunity_Client__c buildOpportunityClient(String opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Opportunity_Client__c) applyOverrides(buildOpportunityClient(opportunityId), overrides);
    }

    public static DMT_Opportunity_Mitigant__c buildOpportunityMitigant(Id opportunityLineItemId) {
        return new DMT_Opportunity_Mitigant__c(DMT_Opportunity_Product__c = opportunityLineItemId);
    }

    public static DMT_Opportunity_Mitigant__c buildOpportunityMitigant(Id opportunityLineItemId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Opportunity_Mitigant__c) applyOverrides(buildOpportunityMitigant(opportunityLineItemId), overrides);
    }

    public static DMT_Opportunity_Tenor__c buildOpportunityTenor(Id opportunityLineItemId) {
        return new DMT_Opportunity_Tenor__c(DMT_Opportunity_Product__c = opportunityLineItemId);
    }

    public static DMT_Opportunity_Tenor__c buildOpportunityTenor(Id opportunityLineItemId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Opportunity_Tenor__c) applyOverrides(buildOpportunityTenor(opportunityLineItemId), overrides);
    }

    public static DMT_Risk_Line_Term__c buildRiskLineTerm() {
        return new DMT_Risk_Line_Term__c(CurrencyIsoCode = DMT_UtilTestClassConstants.DEFAULT_CURRENCY);
    }

    public static DMT_Risk_Line_Term__c buildRiskLineTerm(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Risk_Line_Term__c) applyOverrides(buildRiskLineTerm(), overrides);
    }

    public static DMT_Selected_Features__c buildSelectedFeature(Id featureId) {
        return new DMT_Selected_Features__c(Feature__c = featureId);
    }

    public static DMT_Selected_Features__c buildSelectedFeature(Id featureId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Selected_Features__c) applyOverrides(buildSelectedFeature(featureId), overrides);
    }

    public static Task buildTask(Id ownerId, Id recordTypeId, Id whatId) {
        return new Task(
            OwnerId = ownerId,
            RecordTypeId = recordTypeId,
            WhatId = whatId,
            Description = DMT_UtilTestClassConstants.DEFAULT_TASK_DESCRIPTION
        );
    }

    public static Task buildTask(Id ownerId, Id recordTypeId, Id whatId, Map<Schema.SObjectField, Object> overrides) {
        return (Task) applyOverrides(buildTask(ownerId, recordTypeId, whatId), overrides);
    }

    public static DMT_Task_Approver_Relationship__c buildTaskApproverRelationship(Id approverId, Id taskTypeId) {
        return new DMT_Task_Approver_Relationship__c(DMT_Approver__c = approverId, DMT_Task_Type__c = taskTypeId);
    }

    public static DMT_Task_Approver_Relationship__c buildTaskApproverRelationship(Id approverId, Id taskTypeId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Task_Approver_Relationship__c) applyOverrides(buildTaskApproverRelationship(approverId, taskTypeId), overrides);
    }

    public static DMT_Task_Relationship__c buildTaskRelationship(Id fromTaskTypeId, Id toTaskTypeId) {
        return new DMT_Task_Relationship__c(DMT_From_Task_Type__c = fromTaskTypeId, DMT_To_Task_Type__c = toTaskTypeId);
    }

    public static DMT_Task_Relationship__c buildTaskRelationship(Id fromTaskTypeId, Id toTaskTypeId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Task_Relationship__c) applyOverrides(buildTaskRelationship(fromTaskTypeId, toTaskTypeId), overrides);
    }

    public static DMT_Task_Type__c buildTaskType() {
        return new DMT_Task_Type__c(CurrencyIsoCode = DMT_UtilTestClassConstants.DEFAULT_CURRENCY);
    }

    public static DMT_Task_Type__c buildTaskType(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Task_Type__c) applyOverrides(buildTaskType(), overrides);
    }

    public static DMT_Taxonomy_Hierarchy__c buildTaxonomyHierarchy() {
        return new DMT_Taxonomy_Hierarchy__c(
            gf_cutoff_date__c = System.today(),
            g_hierarchy_id__c = DMT_UtilTestClassConstants.DEFAULT_TAXONOMY_HIERARCHY_ID,
            gf_lvl_1_hier_catalog_val_id__c = DMT_UtilTestClassConstants.DEFAULT_TAXONOMY_HIERARCHY_LEVEL_1
        );
    }

    public static DMT_Taxonomy_Hierarchy__c buildTaxonomyHierarchy(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Taxonomy_Hierarchy__c) applyOverrides(buildTaxonomyHierarchy(), overrides);
    }

    public static DMT_Taxonomy_Relationship__c buildTaxonomyRelationship(Id initialTaxonomyValueId, Id finalTaxonomyValueId) {
        return new DMT_Taxonomy_Relationship__c(
            DMT_Initial_Taxonomy_Value__c = initialTaxonomyValueId,
            DMT_Final_Taxonomy_Value__c = finalTaxonomyValueId,
            DMT_Value_Catalog_Initial__c = DMT_UtilTestClassConstants.DEFAULT_TAXONOMY_RELATIONSHIP_INITIAL_CATALOG,
            DMT_Value_Catalog_Final__c = DMT_UtilTestClassConstants.DEFAULT_TAXONOMY_RELATIONSHIP_FINAL_CATALOG
        );
    }

    public static DMT_Taxonomy_Relationship__c buildTaxonomyRelationship(Id initialTaxonomyValueId, Id finalTaxonomyValueId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Taxonomy_Relationship__c) applyOverrides(buildTaxonomyRelationship(initialTaxonomyValueId, finalTaxonomyValueId), overrides);
    }

    public static DMT_Taxonomy_Values__c buildTaxonomyValue(String name, String externalId, String catalog) {
        return new DMT_Taxonomy_Values__c(
            DMT_Name__c = name,
            DMT_Name_EN__c = name,
            DMT_External_Id__c = externalId,
            CurrencyIsoCode = DMT_UtilTestClassConstants.DEFAULT_CURRENCY,
            DMT_Catalog__c = catalog
        );
    }

    public static DMT_Taxonomy_Values__c buildTaxonomyValue(String name, String externalId, String catalog, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Taxonomy_Values__c) applyOverrides(buildTaxonomyValue(name, externalId, catalog), overrides);
    }

    public static DMT_Underlying__c buildUnderlying(Id opportunityLineItemId) {
        return new DMT_Underlying__c(
            DMT_Opportunity_Product__c = opportunityLineItemId,
            Name = DMT_UtilTestClassConstants.DEFAULT_UNDERLYING_NAME,
            DMT_Underlying_Type__c = DMT_UtilTestClassConstants.DEFAULT_UNDERLYING_TYPE,
            DMT_Max_Amount__c = DMT_UtilTestClassConstants.DEFAULT_UNDERLYING_MAX_AMOUNT,
            DMT_Currency__c = DMT_UtilTestClassConstants.DEFAULT_CURRENCY,
            DMT_Max_Term__c = DMT_UtilTestClassConstants.DEFAULT_UNDERLYING_MAX_TERM
        );
    }

    public static DMT_Underlying__c buildUnderlying(Id opportunityLineItemId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Underlying__c) applyOverrides(buildUnderlying(opportunityLineItemId), overrides);
    }

    public static DMT_Warranty__c buildWarranty(Id riskLineTermId) {
        return new DMT_Warranty__c(
            dmt_risk_line_term__c = riskLineTermId,
            Name = DMT_UtilTestClassConstants.DEFAULT_WARRANTY_NAME,
            CurrencyIsoCode = DMT_UtilTestClassConstants.DEFAULT_CURRENCY
        );
    }

    public static DMT_Warranty__c buildWarranty(Id riskLineTermId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Warranty__c) applyOverrides(buildWarranty(riskLineTermId), overrides);
    }

    public static DMT_X_Sell__c buildXSell(Id opportunityId) {
        return new DMT_X_Sell__c(
            Opportunity__c = opportunityId,
            Year__c = DMT_UtilTestClassConstants.DEFAULT_XSELL_YEAR
        );
    }

    public static DMT_X_Sell__c buildXSell(Id opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_X_Sell__c) applyOverrides(buildXSell(opportunityId), overrides);
    }

    public static Passport__c buildPassport() {
        Passport__c passport = new Passport__c();
        return (Passport__c) applyOverrides(
            passport,
            new Map<Schema.SObjectField, Object>{
                Passport__c.DMT_Passport_Save__c => DMT_UtilTestClassConstants.DEFAULT_PASSPORT_JSON,
                Passport__c.DMT_Is_Obsoleted_Passport_Save__c => DMT_UtilTestClassConstants.DEFAULT_PASSPORT_OBSOLETE
            }
        );
    }

    public static Passport__c buildPassport(Map<Schema.SObjectField, Object> overrides) {
        return (Passport__c) applyOverrides(buildPassport(), overrides);
    }

    public static DMT_TaskStatusWhenCompleted__c buildTaskStatusWhenCompleted() {
        return new DMT_TaskStatusWhenCompleted__c();
    }

    public static DMT_TaskStatusWhenCompleted__c buildTaskStatusWhenCompleted(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_TaskStatusWhenCompleted__c) applyOverrides(buildTaskStatusWhenCompleted(), overrides);
    }

}