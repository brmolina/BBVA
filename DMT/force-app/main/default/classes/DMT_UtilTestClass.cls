/*----------------------------------------------------------------------------------------------
================================================================================
DMT_UtilTestClass - DMT Test Data Facade
================================================================================
TYPE:Apex@TestUtilityFacade(@IsTest)
DOMAIN:DMT
PRIORITY:ReuseCanonicalBuild>CreateExplicitly>AvoidDESDuplication>Style
ARCHITECTURE:
* PATTERN: Build/Create separation aligned with DES_UtilTestClass.
* ROLE: DMT facade for objects that are DMT-owned or require DMT-specific defaults/behavior.
* BUILD: buildX() delegates to DMT_UtilTestClassBuild and performs no DML itself.
* CREATE: createX() delegates to the canonical buildX() and performs explicit DML.
* NO_DES_PASSTHROUGHS: Do not expose methods that merely repeat an existing DES_UtilTestClass method unchanged.
* CALLER: DMT_Test_DataFactory decides whether to use this facade or DES_UtilTestClass directly.
OWNERSHIP RULE:
* DES object + no DMT-specific defaults/behavior -> DO NOT add build/create methods here.
  DMT_Test_DataFactory must call DES_UtilTestClass directly.
* DES object + DMT-specific defaults/behavior -> expose the canonical DMT build/create pair here.
  The build implementation belongs in DMT_UtilTestClassBuild.
* DMT-owned object -> expose the canonical DMT build/create pair here.
EXAMPLES OF DES-DIRECT OBJECTS — DO NOT REINTRODUCE WRAPPERS WITHOUT DMT LOGIC:
* AMH_GBL_Account_Relationship__c
* Pricebook2
* PricebookEntry
* Product2
* DES Group client creation
EXAMPLES OF OBJECTS THAT REQUIRE THE DMT LAYER:
* Account — DMT-specific account defaults are layered on DES defaults.
* Opportunity — DMT opportunity defaults are layered on DES defaults.
* OpportunityLineItem — DMT-specific OLI defaults are layered on DES defaults.
* User — DMT-specific user behavior/defaults are applied.
* DMT_* objects — owned by DMT.
API_CONTRACT:
* ONE_CANONICAL_BUILD_PER_OBJECT: Prefer one buildX() plus the required override overload.
* ONE_CANONICAL_CREATE_PER_OBJECT: Prefer one createX() plus the required override overload.
* BUILD_IS_MEMORY_ONLY: A buildX() method must not perform DML or SOQL.
* CREATE_IS_EXPLICIT_DML: A createX() method may perform the explicit insert required by the Build/Create pattern.
* OVERRIDES: Explicit caller overrides must be applied by the canonical Build implementation and win over defaults.
* NO_SCENARIO_LOGIC: Multi-record scenarios, queries and relationship orchestration belong in DMT_Test_DataFactory.
* NO_DUPLICATED_DES_API: Never add a DMT method only to rename or forward a DES method.
* NO_DIRECT_DES_BUILD: This class must not call DES_UtilTestClassBuild.
DML / BULK RULES:
* DML belongs only in create/bulk methods, never in build methods.
* New collection create methods must use a single DML statement whenever possible.
* Never introduce DML inside loops.
AI / AUTOMATED EDITING RULES:
* Before adding a method, search DES_UtilTestClass for an equivalent API.
* If DES already satisfies the requirement and DMT adds nothing, STOP: use DES directly from DMT_Test_DataFactory.
* Before adding a second method for the same SObject, search for the canonical DMT build/create pair.
* Do not copy DES field initialization into this facade.
* Do not place constants or scenario-specific values in this class.
* Do not bypass DMT_UtilTestClassBuild for DMT-owned/defaulted build logic.
* Preserve existing method signatures once consumed by DMT tests/DataFactory.
PRE_EDIT_CHECKLIST:
* Does DMT genuinely add behavior/defaults for this object?
* Does DES already provide the same build/create method?
* Is the method a canonical build/create method rather than a convenience duplicate?
* Is all build logic memory-only?
* Is DML confined to create/bulk methods?
* Are scenario concerns left in DMT_Test_DataFactory?
History
-------
2026-10-19  Added DMT architecture/AI operating contract aligned with DES conventions.
            Explicitly prohibited unchanged DES passthrough APIs in the DMT facade.
================================================================================
----------------------------------------------------------------------------------------------*/

@IsTest
public class DMT_UtilTestClass {

    // ─── 2. HELPER METHODS ──────────────────────────────────────────────────

    @TestVisible
    private static SObject insertAndReturn(SObject record) {
        insert record;
        return record;
    }

    // ─── 4. BUILD METHODS ───────────────────────────────────────────────────

    public Account buildAccount() {
        return DMT_UtilTestClassBuild.buildAccount();
    }

    public Account buildAccount(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildAccount(overrides);
    }

    public Case buildCase(Id ownerId, Id recordTypeId) {
        return DMT_UtilTestClassBuild.buildCase(ownerId, recordTypeId);
    }

    public Case buildCase(Id ownerId, Id recordTypeId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildCase(ownerId, recordTypeId, overrides);
    }

    public Opportunity buildOpportunity(Id accountId) {
        return DMT_UtilTestClassBuild.buildOpportunity(accountId);
    }

    public Opportunity buildOpportunity(Id accountId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildOpportunity(accountId, overrides);
    }

    public OpportunityLineItem buildOppLineItem(Id opportunityId, Id productId, Id pricebookEntryId) {
        return DMT_UtilTestClassBuild.buildOppLineItem(opportunityId, productId, pricebookEntryId);
    }

    public OpportunityLineItem buildOppLineItem(Id opportunityId, Id productId, Id pricebookEntryId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildOppLineItem(opportunityId, productId, pricebookEntryId, overrides);
    }

    public Task buildTask(Id ownerId, Id recordTypeId, Id whatId) {
        return DMT_UtilTestClassBuild.buildTask(ownerId, recordTypeId, whatId);
    }

    public Task buildTask(Id ownerId, Id recordTypeId, Id whatId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildTask(ownerId, recordTypeId, whatId, overrides);
    }

    public User buildUser(String profileId) {
        return DMT_UtilTestClassBuild.buildUser(profileId);
    }

    public User buildUser(String profileId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildUser(profileId, overrides);
    }

    public DMT_Approver__c buildApprover() {
        return DMT_UtilTestClassBuild.buildApprover();
    }

    public DMT_Approver__c buildApprover(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildApprover(overrides);
    }

    public DMT_Approver_Member__c buildApproverMember(Id approverId, Id userId) {
        return DMT_UtilTestClassBuild.buildApproverMember(approverId, userId);
    }

    public DMT_Approver_Member__c buildApproverMember(Id approverId, Id userId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildApproverMember(approverId, userId, overrides);
    }

    public DMT_Approver_Type__c buildApproverType(String name, String externalId) {
        return DMT_UtilTestClassBuild.buildApproverType(name, externalId);
    }

    public DMT_Approver_Type__c buildApproverType(String name, String externalId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildApproverType(name, externalId, overrides);
    }

    public DMT_ApproversView__c buildApproversView() {
        return DMT_UtilTestClassBuild.buildApproversView();
    }

    public DMT_ApproversView__c buildApproversView(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildApproversView(overrides);
    }

    public DMT_Consolidated_Line__c buildConsolidatedLine(String lineId) {
        return DMT_UtilTestClassBuild.buildConsolidatedLine(lineId);
    }

    public DMT_Consolidated_Line__c buildConsolidatedLine(String lineId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildConsolidatedLine(lineId, overrides);
    }

    public DMT_Currency_Provision__c buildCurrencyProvision(Id riskLineTermId) {
        return DMT_UtilTestClassBuild.buildCurrencyProvision(riskLineTermId);
    }

    public DMT_Currency_Provision__c buildCurrencyProvision(Id riskLineTermId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildCurrencyProvision(riskLineTermId, overrides);
    }

    public Custom_Association__c buildCustomAssociation(Id lineId, Id accountId) {
        return DMT_UtilTestClassBuild.buildCustomAssociation(lineId, accountId);
    }

    public Custom_Association__c buildCustomAssociation(Id lineId, Id accountId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildCustomAssociation(lineId, accountId, overrides);
    }

    public Custom_Association_Client__c buildCustomAssociationClient() {
        return DMT_UtilTestClassBuild.buildCustomAssociationClient();
    }

    public Custom_Association_Client__c buildCustomAssociationClient(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildCustomAssociationClient(overrides);
    }

    public DMT_Custom_Association_ClientOpportunity__c buildCustomAssociationClientOpportunity(Id customAssociationOpportunityId, Id clientId) {
        return DMT_UtilTestClassBuild.buildCustomAssociationClientOpportunity(customAssociationOpportunityId, clientId);
    }

    public DMT_Custom_Association_ClientOpportunity__c buildCustomAssociationClientOpportunity(Id customAssociationOpportunityId, Id clientId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildCustomAssociationClientOpportunity(customAssociationOpportunityId, clientId, overrides);
    }

    public Custom_Association_Opportunity__c buildCustomAssociationOpportunity(Id opportunityId) {
        return DMT_UtilTestClassBuild.buildCustomAssociationOpportunity(opportunityId);
    }

    public Custom_Association_Opportunity__c buildCustomAssociationOpportunity(Id opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildCustomAssociationOpportunity(opportunityId, overrides);
    }

    public DMT_Feature__c buildFeature() {
        return DMT_UtilTestClassBuild.buildFeature();
    }

    public DMT_Feature__c buildFeature(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildFeature(overrides);
    }

    public DMT_Global_Structure__c buildGlobalStructure(String opportunityId) {
        return DMT_UtilTestClassBuild.buildGlobalStructure(opportunityId);
    }

    public DMT_Global_Structure__c buildGlobalStructure(String opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildGlobalStructure(opportunityId, overrides);
    }

    public DMT_Items__c buildItem(Id viewId) {
        return DMT_UtilTestClassBuild.buildItem(viewId);
    }

    public DMT_Items__c buildItem(Id viewId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildItem(viewId, overrides);
    }

    public Local_Client__c buildLocalClient(Id accountId, String alphaCode) {
        return DMT_UtilTestClassBuild.buildLocalClient(accountId, alphaCode);
    }

    public Local_Client__c buildLocalClient(Id accountId, String alphaCode, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildLocalClient(accountId, alphaCode, overrides);
    }

    public DMT_Line__c buildLine() {
        return DMT_UtilTestClassBuild.buildLine();
    }

    public DMT_Line__c buildLine(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildLine(overrides);
    }

    public DMT_Line_Product_Item__c buildLineProductItem() {
        return DMT_UtilTestClassBuild.buildLineProductItem();
    }

    public DMT_Line_Product_Item__c buildLineProductItem(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildLineProductItem(overrides);
    }

    public DMT_Opportunity_Client__c buildOpportunityClient(String opportunityId) {
        return DMT_UtilTestClassBuild.buildOpportunityClient(opportunityId);
    }

    public DMT_Opportunity_Client__c buildOpportunityClient(String opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildOpportunityClient(opportunityId, overrides);
    }

    public DMT_Opportunity_Mitigant__c buildOpportunityMitigant(Id opportunityLineItemId) {
        return DMT_UtilTestClassBuild.buildOpportunityMitigant(opportunityLineItemId);
    }

    public DMT_Opportunity_Mitigant__c buildOpportunityMitigant(Id opportunityLineItemId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildOpportunityMitigant(opportunityLineItemId, overrides);
    }

    public DMT_Opportunity_Tenor__c buildOpportunityTenor(Id opportunityLineItemId) {
        return DMT_UtilTestClassBuild.buildOpportunityTenor(opportunityLineItemId);
    }

    public DMT_Opportunity_Tenor__c buildOpportunityTenor(Id opportunityLineItemId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildOpportunityTenor(opportunityLineItemId, overrides);
    }

    public DMT_Risk_Line_Term__c buildRiskLineTerm() {
        return DMT_UtilTestClassBuild.buildRiskLineTerm();
    }

    public DMT_Risk_Line_Term__c buildRiskLineTerm(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildRiskLineTerm(overrides);
    }

    public DMT_Selected_Features__c buildSelectedFeature(Id featureId) {
        return DMT_UtilTestClassBuild.buildSelectedFeature(featureId);
    }

    public DMT_Selected_Features__c buildSelectedFeature(Id featureId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildSelectedFeature(featureId, overrides);
    }

    public DMT_Task_Approver_Relationship__c buildTaskApproverRelationship(Id approverId, Id taskTypeId) {
        return DMT_UtilTestClassBuild.buildTaskApproverRelationship(approverId, taskTypeId);
    }

    public DMT_Task_Approver_Relationship__c buildTaskApproverRelationship(Id approverId, Id taskTypeId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildTaskApproverRelationship(approverId, taskTypeId, overrides);
    }

    public DMT_Task_Relationship__c buildTaskRelationship(Id fromTaskTypeId, Id toTaskTypeId) {
        return DMT_UtilTestClassBuild.buildTaskRelationship(fromTaskTypeId, toTaskTypeId);
    }

    public DMT_Task_Relationship__c buildTaskRelationship(Id fromTaskTypeId, Id toTaskTypeId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildTaskRelationship(fromTaskTypeId, toTaskTypeId, overrides);
    }

    public DMT_Task_Type__c buildTaskType() {
        return DMT_UtilTestClassBuild.buildTaskType();
    }

    public DMT_Task_Type__c buildTaskType(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildTaskType(overrides);
    }

    public DMT_Taxonomy_Hierarchy__c buildTaxonomyHierarchy() {
        return DMT_UtilTestClassBuild.buildTaxonomyHierarchy();
    }

    public DMT_Taxonomy_Hierarchy__c buildTaxonomyHierarchy(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildTaxonomyHierarchy(overrides);
    }

    public DMT_Taxonomy_Relationship__c buildTaxonomyRelationship(Id initialTaxonomyValueId, Id finalTaxonomyValueId) {
        return DMT_UtilTestClassBuild.buildTaxonomyRelationship(initialTaxonomyValueId, finalTaxonomyValueId);
    }

    public DMT_Taxonomy_Relationship__c buildTaxonomyRelationship(Id initialTaxonomyValueId, Id finalTaxonomyValueId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildTaxonomyRelationship(initialTaxonomyValueId, finalTaxonomyValueId, overrides);
    }

    public DMT_Taxonomy_Values__c buildTaxonomyValue(String name, String externalId, String catalog) {
        return DMT_UtilTestClassBuild.buildTaxonomyValue(name, externalId, catalog);
    }

    public DMT_Taxonomy_Values__c buildTaxonomyValue(String name, String externalId, String catalog, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildTaxonomyValue(name, externalId, catalog, overrides);
    }

    public DMT_Underlying__c buildUnderlying(Id opportunityLineItemId) {
        return DMT_UtilTestClassBuild.buildUnderlying(opportunityLineItemId);
    }

    public DMT_Underlying__c buildUnderlying(Id opportunityLineItemId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildUnderlying(opportunityLineItemId, overrides);
    }

    public DMT_Warranty__c buildWarranty(Id riskLineTermId) {
        return DMT_UtilTestClassBuild.buildWarranty(riskLineTermId);
    }

    public DMT_Warranty__c buildWarranty(Id riskLineTermId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildWarranty(riskLineTermId, overrides);
    }

    public DMT_X_Sell__c buildXSell(Id opportunityId) {
        return DMT_UtilTestClassBuild.buildXSell(opportunityId);
    }

    public DMT_X_Sell__c buildXSell(Id opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildXSell(opportunityId, overrides);
    }

    // ─── 5. CREATE METHODS — EXPLICIT DML ─────────────────────────────────

    public Account createAccount() {
        return (Account) insertAndReturn(buildAccount());
    }

    public Account createAccount(Map<Schema.SObjectField, Object> overrides) {
        return (Account) insertAndReturn(buildAccount(overrides));
    }

    public Case createCaseRecord(Id ownerId, Id recordTypeId) {
        return (Case) insertAndReturn(buildCase(ownerId, recordTypeId));
    }

    public Case createCaseRecord(Id ownerId, Id recordTypeId, Map<Schema.SObjectField, Object> overrides) {
        return (Case) insertAndReturn(buildCase(ownerId, recordTypeId, overrides));
    }

    public Opportunity createOpportunityForAccount(Id accountId) {
        return (Opportunity) insertAndReturn(buildOpportunity(accountId));
    }

    public Opportunity createOpportunityForAccount(Id accountId, Map<Schema.SObjectField, Object> overrides) {
        return (Opportunity) insertAndReturn(buildOpportunity(accountId, overrides));
    }

    public OpportunityLineItem createOppLineItemRecord(Id opportunityId, Id productId, Id pricebookEntryId) {
        return (OpportunityLineItem) insertAndReturn(buildOppLineItem(opportunityId, productId, pricebookEntryId));
    }

    public OpportunityLineItem createOppLineItemRecord(Id opportunityId, Id productId, Id pricebookEntryId, Map<Schema.SObjectField, Object> overrides) {
        return (OpportunityLineItem) insertAndReturn(buildOppLineItem(opportunityId, productId, pricebookEntryId, overrides));
    }

    public Task createTaskRecord(Id ownerId, Id recordTypeId, Id whatId) {
        return (Task) insertAndReturn(buildTask(ownerId, recordTypeId, whatId));
    }

    public Task createTaskRecord(Id ownerId, Id recordTypeId, Id whatId, Map<Schema.SObjectField, Object> overrides) {
        return (Task) insertAndReturn(buildTask(ownerId, recordTypeId, whatId, overrides));
    }

    public User createUserRecord(String profileId) {
        return (User) insertAndReturn(buildUser(profileId));
    }

    public User createUserRecord(String profileId, Map<Schema.SObjectField, Object> overrides) {
        return (User) insertAndReturn(buildUser(profileId, overrides));
    }

    public DMT_Approver__c createApproverRecord() {
        return (DMT_Approver__c) insertAndReturn(buildApprover());
    }

    public DMT_Approver__c createApproverRecord(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Approver__c) insertAndReturn(buildApprover(overrides));
    }

    public DMT_Approver_Member__c createApproverMemberRecord(Id approverId, Id userId) {
        return (DMT_Approver_Member__c) insertAndReturn(buildApproverMember(approverId, userId));
    }

    public DMT_Approver_Member__c createApproverMemberRecord(Id approverId, Id userId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Approver_Member__c) insertAndReturn(buildApproverMember(approverId, userId, overrides));
    }

    public DMT_Approver_Type__c createApproverTypeRecord(String name, String externalId) {
        return (DMT_Approver_Type__c) insertAndReturn(buildApproverType(name, externalId));
    }

    public DMT_Approver_Type__c createApproverTypeRecord(String name, String externalId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Approver_Type__c) insertAndReturn(buildApproverType(name, externalId, overrides));
    }

    public DMT_ApproversView__c createApproversViewRecord() {
        return (DMT_ApproversView__c) insertAndReturn(buildApproversView());
    }

    public DMT_ApproversView__c createApproversViewRecord(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_ApproversView__c) insertAndReturn(buildApproversView(overrides));
    }

    public DMT_Consolidated_Line__c createConsolidatedLineRecord(String lineId) {
        return (DMT_Consolidated_Line__c) insertAndReturn(buildConsolidatedLine(lineId));
    }

    public DMT_Consolidated_Line__c createConsolidatedLineRecord(String lineId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Consolidated_Line__c) insertAndReturn(buildConsolidatedLine(lineId, overrides));
    }

    public DMT_Currency_Provision__c createCurrencyProvisionRecord(Id riskLineTermId) {
        return (DMT_Currency_Provision__c) insertAndReturn(buildCurrencyProvision(riskLineTermId));
    }

    public DMT_Currency_Provision__c createCurrencyProvisionRecord(Id riskLineTermId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Currency_Provision__c) insertAndReturn(buildCurrencyProvision(riskLineTermId, overrides));
    }

    public Custom_Association__c createCustomAssociationRecord(Id lineId, Id accountId) {
        return (Custom_Association__c) insertAndReturn(buildCustomAssociation(lineId, accountId));
    }

    public Custom_Association__c createCustomAssociationRecord(Id lineId, Id accountId, Map<Schema.SObjectField, Object> overrides) {
        return (Custom_Association__c) insertAndReturn(buildCustomAssociation(lineId, accountId, overrides));
    }

    public Custom_Association_Client__c createCustomAssociationClientRecord() {
        return (Custom_Association_Client__c) insertAndReturn(
            buildCustomAssociationClient()
        );
    }

    public Custom_Association_Client__c createCustomAssociationClientRecord(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (Custom_Association_Client__c) insertAndReturn(
            buildCustomAssociationClient(overrides)
        );
    }

    public DMT_Custom_Association_ClientOpportunity__c createCustomAssociationClientOpportunityRecord(Id customAssociationOpportunityId, Id clientId) {
        return (DMT_Custom_Association_ClientOpportunity__c) insertAndReturn(buildCustomAssociationClientOpportunity(customAssociationOpportunityId, clientId));
    }

    public DMT_Custom_Association_ClientOpportunity__c createCustomAssociationClientOpportunityRecord(Id customAssociationOpportunityId, Id clientId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Custom_Association_ClientOpportunity__c) insertAndReturn(buildCustomAssociationClientOpportunity(customAssociationOpportunityId, clientId, overrides));
    }

    public Custom_Association_Opportunity__c createCustomAssociationOpportunityRecord(Id opportunityId) {
        return (Custom_Association_Opportunity__c) insertAndReturn(buildCustomAssociationOpportunity(opportunityId));
    }

    public Custom_Association_Opportunity__c createCustomAssociationOpportunityRecord(Id opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return (Custom_Association_Opportunity__c) insertAndReturn(buildCustomAssociationOpportunity(opportunityId, overrides));
    }

    public DMT_Feature__c createFeatureRecord() {
        return (DMT_Feature__c) insertAndReturn(buildFeature());
    }

    public DMT_Feature__c createFeatureRecord(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Feature__c) insertAndReturn(buildFeature(overrides));
    }

    public DMT_Global_Structure__c createGlobalStructureRecord(String opportunityId) {
        return (DMT_Global_Structure__c) insertAndReturn(buildGlobalStructure(opportunityId));
    }

    public DMT_Global_Structure__c createGlobalStructureRecord(String opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Global_Structure__c) insertAndReturn(buildGlobalStructure(opportunityId, overrides));
    }

    public DMT_Items__c createItemRecord(Id viewId) {
        return (DMT_Items__c) insertAndReturn(buildItem(viewId));
    }

    public DMT_Items__c createItemRecord(Id viewId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Items__c) insertAndReturn(buildItem(viewId, overrides));
    }

    public Local_Client__c createLocalClientRecord(Id accountId, String alphaCode) {
        return (Local_Client__c) insertAndReturn(buildLocalClient(accountId, alphaCode));
    }

    public Local_Client__c createLocalClientRecord(Id accountId, String alphaCode, Map<Schema.SObjectField, Object> overrides) {
        return (Local_Client__c) insertAndReturn(buildLocalClient(accountId, alphaCode, overrides));
    }

    public DMT_Line__c createLineRecord() {
        return (DMT_Line__c) insertAndReturn(
            buildLine()
        );
    }

    public DMT_Line__c createLineRecord(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Line__c) insertAndReturn(
            buildLine(overrides)
        );
    }

    public DMT_Line_Product_Item__c createLineProductItemRecord() {
        return (DMT_Line_Product_Item__c) insertAndReturn(
            buildLineProductItem()
        );
    }

    public DMT_Line_Product_Item__c createLineProductItemRecord(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Line_Product_Item__c) insertAndReturn(
            buildLineProductItem(overrides)
        );
    }

    public DMT_Opportunity_Client__c createOpportunityClientRecord(String opportunityId) {
        return (DMT_Opportunity_Client__c) insertAndReturn(buildOpportunityClient(opportunityId));
    }

    public DMT_Opportunity_Client__c createOpportunityClientRecord(String opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Opportunity_Client__c) insertAndReturn(buildOpportunityClient(opportunityId, overrides));
    }

    public DMT_Opportunity_Mitigant__c createOpportunityMitigantRecord(Id opportunityLineItemId) {
        return (DMT_Opportunity_Mitigant__c) insertAndReturn(buildOpportunityMitigant(opportunityLineItemId));
    }

    public DMT_Opportunity_Mitigant__c createOpportunityMitigantRecord(Id opportunityLineItemId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Opportunity_Mitigant__c) insertAndReturn(buildOpportunityMitigant(opportunityLineItemId, overrides));
    }

    public DMT_Opportunity_Tenor__c createOpportunityTenorRecord(Id opportunityLineItemId) {
        return (DMT_Opportunity_Tenor__c) insertAndReturn(buildOpportunityTenor(opportunityLineItemId));
    }

    public DMT_Opportunity_Tenor__c createOpportunityTenorRecord(Id opportunityLineItemId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Opportunity_Tenor__c) insertAndReturn(buildOpportunityTenor(opportunityLineItemId, overrides));
    }

    public DMT_Risk_Line_Term__c createRiskLineTermRecord() {
        return (DMT_Risk_Line_Term__c) insertAndReturn(
            buildRiskLineTerm()
        );
    }

    public DMT_Risk_Line_Term__c createRiskLineTermRecord(
        Map<Schema.SObjectField, Object> overrides
    ) {
        return (DMT_Risk_Line_Term__c) insertAndReturn(
            buildRiskLineTerm(overrides)
        );
    }

    public DMT_Selected_Features__c createSelectedFeatureRecord(Id featureId) {
        return (DMT_Selected_Features__c) insertAndReturn(buildSelectedFeature(featureId));
    }

    public DMT_Selected_Features__c createSelectedFeatureRecord(Id featureId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Selected_Features__c) insertAndReturn(buildSelectedFeature(featureId, overrides));
    }

    public DMT_Task_Approver_Relationship__c createTaskApproverRelationshipRecord(Id approverId, Id taskTypeId) {
        return (DMT_Task_Approver_Relationship__c) insertAndReturn(buildTaskApproverRelationship(approverId, taskTypeId));
    }

    public DMT_Task_Approver_Relationship__c createTaskApproverRelationshipRecord(Id approverId, Id taskTypeId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Task_Approver_Relationship__c) insertAndReturn(buildTaskApproverRelationship(approverId, taskTypeId, overrides));
    }

    public DMT_Task_Relationship__c createTaskRelationshipRecord(Id fromTaskTypeId, Id toTaskTypeId) {
        return (DMT_Task_Relationship__c) insertAndReturn(buildTaskRelationship(fromTaskTypeId, toTaskTypeId));
    }

    public DMT_Task_Relationship__c createTaskRelationshipRecord(Id fromTaskTypeId, Id toTaskTypeId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Task_Relationship__c) insertAndReturn(buildTaskRelationship(fromTaskTypeId, toTaskTypeId, overrides));
    }

    public DMT_Task_Type__c createTaskTypeRecord() {
        return (DMT_Task_Type__c) insertAndReturn(buildTaskType());
    }

    public DMT_Task_Type__c createTaskTypeRecord(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Task_Type__c) insertAndReturn(buildTaskType(overrides));
    }

    public DMT_Taxonomy_Hierarchy__c createTaxonomyHierarchyRecord() {
        return (DMT_Taxonomy_Hierarchy__c) insertAndReturn(buildTaxonomyHierarchy());
    }

    public DMT_Taxonomy_Hierarchy__c createTaxonomyHierarchyRecord(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Taxonomy_Hierarchy__c) insertAndReturn(buildTaxonomyHierarchy(overrides));
    }

    public DMT_Taxonomy_Relationship__c createTaxonomyRelationshipRecord(Id initialTaxonomyValueId, Id finalTaxonomyValueId) {
        return (DMT_Taxonomy_Relationship__c) insertAndReturn(buildTaxonomyRelationship(initialTaxonomyValueId, finalTaxonomyValueId));
    }

    public DMT_Taxonomy_Relationship__c createTaxonomyRelationshipRecord(Id initialTaxonomyValueId, Id finalTaxonomyValueId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Taxonomy_Relationship__c) insertAndReturn(buildTaxonomyRelationship(initialTaxonomyValueId, finalTaxonomyValueId, overrides));
    }

    public DMT_Taxonomy_Values__c createTaxonomyValueRecord(String name, String externalId, String catalog) {
        return (DMT_Taxonomy_Values__c) insertAndReturn(buildTaxonomyValue(name, externalId, catalog));
    }

    public DMT_Taxonomy_Values__c createTaxonomyValueRecord(String name, String externalId, String catalog, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Taxonomy_Values__c) insertAndReturn(buildTaxonomyValue(name, externalId, catalog, overrides));
    }

    public DMT_Underlying__c createUnderlyingRecord(Id opportunityLineItemId) {
        return (DMT_Underlying__c) insertAndReturn(buildUnderlying(opportunityLineItemId));
    }

    public DMT_Underlying__c createUnderlyingRecord(Id opportunityLineItemId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Underlying__c) insertAndReturn(buildUnderlying(opportunityLineItemId, overrides));
    }

    public DMT_Warranty__c createWarrantyRecord(Id riskLineTermId) {
        return (DMT_Warranty__c) insertAndReturn(buildWarranty(riskLineTermId));
    }

    public DMT_Warranty__c createWarrantyRecord(Id riskLineTermId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_Warranty__c) insertAndReturn(buildWarranty(riskLineTermId, overrides));
    }

    public DMT_X_Sell__c createXSellRecord(Id opportunityId) {
        return (DMT_X_Sell__c) insertAndReturn(buildXSell(opportunityId));
    }

    public DMT_X_Sell__c createXSellRecord(Id opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return (DMT_X_Sell__c) insertAndReturn(buildXSell(opportunityId, overrides));
    }

    public Passport__c buildPassport() {
        return DMT_UtilTestClassBuild.buildPassport();
    }

    public Passport__c buildPassport(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildPassport(overrides);
    }

    public Passport__c createPassportRecord() {
        return (Passport__c) insertAndReturn(buildPassport());
    }

    public Passport__c createPassportRecord(Map<Schema.SObjectField, Object> overrides) {
        return (Passport__c) insertAndReturn(buildPassport(overrides));
    }

    public DMT_TaskStatusWhenCompleted__c buildTaskStatusWhenCompleted() {
        return DMT_UtilTestClassBuild.buildTaskStatusWhenCompleted();
    }

    public DMT_TaskStatusWhenCompleted__c buildTaskStatusWhenCompleted(Map<Schema.SObjectField, Object> overrides) {
        return DMT_UtilTestClassBuild.buildTaskStatusWhenCompleted(overrides);
    }


    public DMT_TaskStatusWhenCompleted__c createTaskStatusWhenCompletedRecord() {
        return (DMT_TaskStatusWhenCompleted__c) insertAndReturn(buildTaskStatusWhenCompleted());
    }

    public DMT_TaskStatusWhenCompleted__c createTaskStatusWhenCompletedRecord(Map<Schema.SObjectField, Object> overrides) {
        return (DMT_TaskStatusWhenCompleted__c) insertAndReturn(buildTaskStatusWhenCompleted(overrides));
    }
}