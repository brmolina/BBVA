/*----------------------------------------------------------------------------------------------
================================================================================
DMT_UtilTestClassConstants - DMT Test Data Constants
================================================================================

TYPE:Apex@TestConstants(@IsTest)
DOMAIN:DMT
PRIORITY:DMTReusableDefaults>NoDuplication>ScenarioSeparation

PURPOSE:

* Centralize reusable DMT-specific default values and DMT test metadata identifiers.
* Mirror the organizational role of DES_UtilTestClassConstants without copying DES-owned constants unnecessarily.
* Keep scenario-specific values out of global constants.

OWNERSHIP RULE:

* DES-owned/default value already available in DES_UtilTestClassConstants -> reuse through DES behavior; do not duplicate it here merely for convenience.
* DMT-specific reusable default -> define it here.
* Record Type DeveloperName/Id repeatedly required by DMT test infrastructure -> may be centralized here.
* One-off scenario value -> keep it in DMT_Test_DataFactory as an explicit override.

API_CONTRACT:

* CONSTANTS_ONLY: No DML, no SOQL and no scenario orchestration.
* DETERMINISTIC: Defaults should be stable and predictable for tests.
* CLEAR_NAMING: Reusable defaults use DEFAULT_* names; metadata IDs/names must identify their target clearly.
* NO_DUPLICATED_DES_CONSTANTS: Do not shadow a DES constant unless DMT intentionally has a different value/semantic.
* NO_SCENARIO_POLLUTION: Do not move a value here solely because it is repeated in several scenario methods.
* SCHEMA_DESCRIBE_ALLOWED: Metadata-derived IDs may use Schema describe; do not query RecordType with SOQL.

AI / AUTOMATED EDITING RULES:

* Search DMT_Constants and this class before adding a new string/identifier.
* Search DES_UtilTestClassConstants before introducing a value that may already be owned by DES.
* Do not create aliases that add no DMT meaning.
* Do not move dates, names, amounts, statuses or IDs from a specific scenario here unless they are truly reusable DMT defaults.
* Do not introduce mutable shared state unless explicitly required for test behavior.

PRE_EDIT_CHECKLIST:

* Is the value genuinely reusable across DMT tests?
* Is it DMT-owned rather than already owned by DES?
* Is it a default/infrastructure identifier rather than a scenario override?
* Can an existing DMT_Constants value be reused instead of creating a duplicate literal?
* Does the name clearly identify the object/meaning?

History
-------
2026-10-19  Added DMT architecture/AI operating contract aligned with DES conventions.
            Documented constant ownership and DES/DMT/scenario separation.
================================================================================
----------------------------------------------------------------------------------------------*/
@IsTest
public class DMT_UtilTestClassConstants {

    // ─── EXCEPTIONS ───────────────────────────────────────────────────
    public static final String EXCEPTION_APPLYOVERRIDES_NULL = 'applyOverrides received a null field token.';
    public static final String EXCEPTION_FIELD = 'Field ';
    public static final String EXCEPTION_NOTEXIST = ' does not exist on target SObject';
    public static final String EXCEPTION_NOTCREATEABLE_UPDATEABLE = ' is not createable/updateable on target SObject';



    // ─── GENERIC / SHARED ───────────────────────────────────────────────────

    public static final Boolean DEFAULT_BOOLEAN_TRUE = true;
    public static final Boolean DEFAULT_BOOLEAN_FALSE = false;
    public static final String DEFAULT_CURRENCY = 'EUR';
    public static final String DEFAULT_COUNTRY = 'ES';
    public static final String DEFAULT_UNDERSCORE = '_';
    public static final String DEFAULT_DOT = '.';


    // ─── RECORD TYPES ───────────────────────────────────────────────────────

    public static final String DEFAULT_TREASURY_LINE_RECORD_TYPE_DEVELOPER_NAME = 'TreasurySettlement';
    public static final String DEFAULT_OTHER_LINE_RECORD_TYPE_DEVELOPER_NAME = 'OtherProducts';
    public static final String DEFAULT_RISK_APPROVAL_LINE_RECORD_TYPE_DEVELOPER_NAME = 'Sanction';

    public static final Id DEFAULT_TREASURY_LINE_RECORD_TYPE_ID =
        Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName()
            .get(DEFAULT_TREASURY_LINE_RECORD_TYPE_DEVELOPER_NAME)
            .getRecordTypeId();

    public static final Id DEFAULT_OTHER_LINE_RECORD_TYPE_ID =
        Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName()
            .get(DEFAULT_OTHER_LINE_RECORD_TYPE_DEVELOPER_NAME)
            .getRecordTypeId();

    public static final Id DEFAULT_RISK_APPROVAL_LINE_RECORD_TYPE_ID =
        Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName()
            .get(DEFAULT_RISK_APPROVAL_LINE_RECORD_TYPE_DEVELOPER_NAME)
            .getRecordTypeId();

    public static final Id DEFAULT_APPROVAL_CASE_RECORD_TYPE_ID =
        Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get(DMT_Constants.CASE_RT_APPROVAL)
            .getRecordTypeId();

    public static final Id DEFAULT_TASK_STEP_RECORD_TYPE_ID =
        Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
            .get(DMT_Constants.TASK_RT_APPROVAL_STEP)
            .getRecordTypeId();

    public static final Id DEFAULT_DMT_OPPORTUNITY_RECORD_TYPE_ID =
        Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get(DMT_Constants.RT_OPP_DMT_NAME)
            .getRecordTypeId();

    // ─── ACCOUNT ────────────────────────────────────────────────────────────

    public static final String DEFAULT_ACCOUNT_NAME = 'Test company 1';
    public static final Boolean DEFAULT_ACCOUNT_ADVISING = DEFAULT_BOOLEAN_FALSE;
    public static final String DEFAULT_ACCOUNT_BBVA_ENTITY = 'BBVA SA';
    public static final String DEFAULT_ACCOUNT_BILLING_CITY = 'MADRID';
    public static final String DEFAULT_ACCOUNT_BILLING_POSTAL_CODE = '28033';
    public static final String DEFAULT_ACCOUNT_BILLING_STATE = 'MADRID';
    public static final String DEFAULT_ACCOUNT_BILLING_STREET = 'AV GRAN Test DE HORTALEZA 0321';
    public static final Decimal DEFAULT_ACCOUNT_FIRST_INCOME_AMOUNT = 4508815;
    public static final String DEFAULT_ACCOUNT_FIRST_INCOME_NAME = 'ESPAÑA (2222815.0 EUR)';
    public static final String DEFAULT_ACCOUNT_ACTIVITY = 'NDA';
    public static final String DEFAULT_ACCOUNT_ACTIVITYEPG = 'Electric Power Generation';

    // ─── APPROVER ───────────────────────────────────────────────────────────

    public static final String DEFAULT_APPROVER_ACCESS_LEVEL = 'Edit';
    public static final String DEFAULT_APPROVERS_VIEW_NAME = 'PruebaLinea';
    public static final String DEFAULT_APPROVERS_VIEW_DEVELOPER_NAME = 'DMT_PruebaLinea';
    public static final String DEFAULT_APPROVERS_NAME = 'TestApproverDataFactory';
    public static final String DEFAULT_APPROVERS_EXTERNAL = 'TestExternalIdDATAFACTORY';
    public static final String DEFAULT_APPROVERS_TYPE = 'Type_';


    // ─── ATTACHMENT ───────────────────────────────────────────────────────────────

    public static final String DEFAULT_ATTACHMENT_NAME = 'Test Attachment';
    public static final String DEFAULT_ATTACHMENT_CONTENT = 'Test Content';

    // ─── BANKING POOL ───────────────────────────────────────────────────────────────

    public static final String DEFAULT_BANKING_POOL_NAME = 'Test Pool';

    // ─── CASE ───────────────────────────────────────────────────────────────

    public static final String DEFAULT_CASE_SUBJECT = 'Test Subject';
    public static final String DEFAULT_CASE_CONDITIONS =
        '{"dateMaximum": "2025-11-13","maximumLinePeriod": "365","maximumProductMaturity": "45000",' +
        '"products": ["Derivatives","Equities","Depos"],"clients": ["G00000000000200"], ' +
        '"derivativesAmount":"3", "dvpAmount":"3", "fdAmount":"0"}';
    public static final String DEFAULT_CASE_FEATURE = 'Test';
    public static final String DEFAULT_CASE_RELATED_FEATURE = 'Test1';
    public static final Decimal DEFAULT_CASE_AMOUNT = 45;

    // ─── CONSOLIDATED LINE ──────────────────────────────────────────────────

    public static final String DEFAULT_GROUP_PRIORITY = '00';

    // ─── GROUP ──────────────────────────────────────────────────

    public static final String DEFAULT_GROUP_TYPE = 'Queue';


    // ─── CUSTOM ASSOCIATION ─────────────────────────────────────────────────

    public static final String DEFAULT_CUSTOM_ASSOCIATION_CUSTOMER_GROUP_ID = 'ESCD25LIN00006610ES';
    public static final String DEFAULT_CUSTOM_ASSOCIATION_GROUP_ID = 'TestCustomerGroupId';
    public static final String DEFAULT_CUSTOM_ASSOCIATION_CLIENT_ALPHA_CODE = 'ES0182000170441';
    public static final String DEFAULT_CUSTOM_ASSOCIATION_CLIENT_NAME = 'GRIFOLS S.A.';

    // ─── GLOBAL STRUCTURE ───────────────────────────────────────────────────

    public static final Integer DEFAULT_GLOBAL_STRUCTURE_FUNDS_MAX = 10000;

    // ─── ITEM ───────────────────────────────────────────────────────────────

    public static final String DEFAULT_ITEM_TEXT = 'Esto es un texto normal';
    public static final String DEFAULT_ITEM_TYPE = 'Component';

    // ─── LINE PRODUCT ITEM ──────────────────────────────────────────────────

    public static final String DEFAULT_LINE_PRODUCT_ITEM_NAME = 'Product line item DEPO';
    public static final String DEFAULT_LINE_PRODUCT_ITEM_MAX_TENOR = '7';
    public static final String DEFAULT_LINE_PRODUCT_ITEM_PRODUCT_CODE = 'DEPO';

    // ─── OPPORTUNITY ────────────────────────────────────────────────────────

    public static final String DEFAULT_OPPORTUNITY_STAGE = 'Draft Opp';
    public static final String DEFAULT_OPPORTUNITY_NAME = 'Test Opp';
    
    public static String DEFAULT_OPPORTUNITY_DMT_ID {
        get {
            return String.valueOf(DateTime.now().getTime());
        }
    }

    public static final Decimal DEFAULT_OPPORTUNITY_NOTIONAL_AMOUNT = 100;
    public static final Integer DEFAULT_OPPORTUNITY_MATURITY_DAYS = 1;
    public static final String DEFAULT_OPPORTUNITY_ENTITY = 'ES0182';
    public static final String DEFAULT_OPPORTUNITY_PRODUCT_AREA = 'GTB';
    public static final String DEFAULT_OPPORTUNITY_THRESHOLD_TYPE = 'Global';

    // ─── NOTIFICATION ───────────────────────────────────────────────────────────────

    public static final String DEFAULT_NOTIFICATION_TYPE = 'Closed_Won';


    // ─── TASK ───────────────────────────────────────────────────────────────

    public static final String DEFAULT_TASK_DESCRIPTION = 'Test Description';

    // ─── TAXONOMY ───────────────────────────────────────────────────────────

    public static final String DEFAULT_TAXONOMY_HIERARCHY_ID = 'TestId';
    public static final String DEFAULT_TAXONOMY_HIERARCHY_LEVEL_1 = 'TestValueLevel1';
    public static final String DEFAULT_TAXONOMY_RELATIONSHIP_INITIAL_CATALOG = 'TestInitial';
    public static final String DEFAULT_TAXONOMY_RELATIONSHIP_FINAL_CATALOG = 'TestFinal';

    // ─── UNDERLYING ─────────────────────────────────────────────────────────

    public static final String DEFAULT_UNDERLYING_NAME = 'Test Underlying Restriction';
    public static final String DEFAULT_UNDERLYING_TYPE = 'Restriction';
    public static final Decimal DEFAULT_UNDERLYING_MAX_AMOUNT = 50000;
    public static final String DEFAULT_UNDERLYING_MAX_TERM = '366';

    // ─── WARRANTY ───────────────────────────────────────────────────────────

    public static final String DEFAULT_WARRANTY_NAME = 'Others > Confort letter';

    // ─── X-SELL ─────────────────────────────────────────────────────────────

    public static final String DEFAULT_XSELL_YEAR = '2035';

    // ─── PASSPORT ───────────────────────────────────────────────────────────

    public static final String DEFAULT_PASSPORT_JSON = '{"data":{}}';
    public static final Boolean DEFAULT_PASSPORT_OBSOLETE = false;

    //────  FEATURES  ───────────────────────────────────────────────────────────────

    public static final String DEFAULT_FEATURE_APPROVER_APPLY_IND_TYPE = 'Test3';
    public static final String DEFAULT_FEATURE_GLOBAL_FEATURE_ID_NUMBER = 'GF003';
    public static final String DEFAULT_FEATURE_USER_AUDIT_ID = 'UserTest';

}