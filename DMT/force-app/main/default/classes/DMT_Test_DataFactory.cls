/*----------------------------------------------------------------------------------------------
================================================================================
DMT_Test_DataFactory - DMT Test Scenario Factory
================================================================================

TYPE:Apex@TestDataFactory(@IsTest)
DOMAIN:DMT
PRIORITY:PreserveExistingBehavior>ReuseDES>ReuseDMTUtilities>AvoidDuplication>Style

ARCHITECTURE:

* ROLE: Public scenario-oriented entry point used by DMT tests.
* DMT_UTIL: Use DMT_UtilTestClass only when DMT owns the object or adds DMT-specific defaults/behavior.
* DES_UTIL: Use DES_UtilTestClass directly when DES already provides the complete build/create behavior required by DMT.
* NO_REDUNDANT_DMT_WRAPPERS: Do not add a DMT method that only delegates unchanged to an existing DES method.
* SCENARIOS: Multi-record setup, relationships, scenario-specific overrides, SOQL and orchestration belong here.
* DEFAULTS: Reusable DMT defaults belong in DMT_UtilTestClassConstants and are applied by DMT_UtilTestClassBuild.
* BULK: Preserve single-DML collection inserts whenever the existing scenario is bulkified.

DEPENDENCY_FLOW:

* DES-only behavior:
  DMT_Test_DataFactory -> DES_UtilTestClass -> DES_UtilTestClassBuild

* DMT-specific behavior/defaults:
  DMT_Test_DataFactory -> DMT_UtilTestClass -> DMT_UtilTestClassBuild -> DES_UtilTestClass (when applicable)

* FORBIDDEN FLOW:
  DMT_Test_DataFactory -> DES_UtilTestClassBuild
  DMT_Test_DataFactory -> DMT_UtilTestClassBuild

DECISION_RULE — BEFORE ADDING OR CALLING A METHOD:

1. Does DES already provide the required object and behavior?
   * YES, and DMT adds nothing -> call DES_UTIL directly.
   * YES, but DMT adds minimum/default fields -> call DMT_UTIL; DMT Build layers on top of DES_UTIL.
   * NO -> call DMT_UTIL for the DMT-owned object.

2. Is the value reusable across DMT tests?
   * YES, common/default value -> DMT_UtilTestClassConstants.
   * NO, scenario-specific value -> keep it as an override in this DataFactory.

3. Is this a new reusable scenario involving several records/relations?
   * YES -> add/extend a generate* method here, reusing existing build/create APIs.

API_CONTRACT:

* PRESERVE_PUBLIC_API: Existing public generateX/setX methods are compatibility points for the DMT test suite.
* DO_NOT_CHANGE_WITHOUT_EXPLICIT_REQUIREMENT: Method names, signatures, return types, visibility, static modifier or observable behavior.
* PRESERVE_BEHAVIOR: DML count/pattern, SOQL, FOR UPDATE queries, default values, null handling, side effects and returned records.
* NO_HIDDEN_SIDE_EFFECTS: Generic generators must not silently create unrelated relationships or records.
* NO_DUPLICATED_FACTORIES: Do not reproduce DES build/create methods in DMT when DMT does not change them.
* NO_DIRECT_DES_BUILD: Never call DES_UtilTestClassBuild from this class; DES_UtilTestClass is the supported DES facade.
* NO_DIRECT_DMT_BUILD: Prefer DMT_UtilTestClass from this class; do not bypass the DMT facade.
* SCENARIO_OVERRIDES_WIN: Explicit test/scenario overrides must remain the highest-priority values.
* LEGACY_BEHAVIOR: If a method has historical DML/SOQL or side effects, preserve them unless the change is explicitly requested and validated.

DML / BULK RULES:

* Single-record canonical create operations should normally use DMT_UTIL.createX() or DES_UTIL.createX().
* Bulk scenarios may use buildX() plus one collection insert when this preserves a single DML operation.
* Never replace one bulk insert with DML inside a loop.
* Do not move scenario queries into Build classes.

IMPORTANT PRESERVATION RULE:

* In generateAccount(), Account.Past2_FY_Corp_Synd_Lending_amount__c is intentionally disabled.
* Keep the existing line commented; do not activate or reintroduce it as live test data.

AI / AUTOMATED EDITING RULES:

* Read DMT_UtilTestClass, DMT_UtilTestClassBuild and DMT_UtilTestClassConstants before adding new factory logic.
* Review DES_UtilTestClass, DES_UtilTestClassBuild and DES_UtilTestClassConstants before introducing an API for a standard/DES-owned object.
* Search for an existing DES method before creating any DMT build/create wrapper.
* Search for an existing DMT canonical build/create method before adding another method for the same SObject.
* Prefer delegation over copied initialization logic.
* Do not "clean up" legacy behavior merely for style; compatibility has priority.
* Do not move scenario-specific literals into global defaults merely because they appear more than once.
* Do not introduce random test data when deterministic values already exist.

PRE_EDIT_CHECKLIST:

* Identify whether the object is DES-owned, DMT-owned, or DES + DMT-defaulted.
* Check whether DES already has the required build/create API.
* Check whether DMT really adds behavior before adding a DMT wrapper.
* Check existing DMT constants before adding a literal/default.
* Preserve DML/SOQL count and ordering.
* Preserve public signatures and return behavior.
* Preserve bulk inserts and avoid DML in loops.
* Confirm no direct reference to DES_UtilTestClassBuild or DMT_UtilTestClassBuild is introduced here.
* Confirm scenario overrides still win over defaults.

History
-------
2026-10-19  Added DMT architecture/AI operating contract aligned with DES conventions.
            Documented DES-direct reuse, DMT ownership rules, compatibility and anti-duplication rules.

Autor: vido
Fecha original: 2024-02-27
================================================================================
----------------------------------------------------------------------------------------------*/
@isTest
public with sharing class  DMT_Test_DataFactory {

    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();
    private static final DES_UtilTestClass DES_UTIL = new DES_UtilTestClass();


    /**
     * Builds a DMT Lines product on top of the DES Product2 defaults.
     * DML remains with the caller so existing bulk inserts are preserved.
     */
    private static Product2 buildDmtLineProduct(String productName, String productCode, String globalProductId) {
        return DES_UTIL.buildProduct(new Map<Schema.SObjectField, Object>{
            Product2.Name => productName,
            Product2.ProductCode => productCode,
            Product2.DMT_Product_family__c => '01',
            Product2.DMT_Product_Subfamily__c => '02',
            Product2.DMT_Product_category__c => '02',
            Product2.DMT_Product_Subcategory__c => '01',
            Product2.DMT_Global_Product_Id__c => globalProductId,
            Product2.CurrencyIsoCode => 'EUR',
            Product2.Family => 'DMT Lines'
        });
    }

    // Método para setear custom settings
    public static iaso__GBL_Rest_Services_Url__c setIasoCustomSetting(String name, String url, String partition) {
        // Default behavior: perform insert
        return setIasoCustomSetting(name, url, partition, true);
    }

    // Overloaded version: allows control over insert execution
    public static iaso__GBL_Rest_Services_Url__c setIasoCustomSetting(String name, String url, String partition, Boolean isInsert) {
        final iaso__GBL_Rest_Services_Url__c iasoCustomSetting = new iaso__GBL_Rest_Services_Url__c(
            Name = name,
            iaso__Url__c = url,
            iaso__Cache_Partition__c = partition,
            iaso__cacheTTLInSecs__c = 0,
            iaso__Enable_Log__c = false,
            iaso__isCacheInOrg__c = true,
            iaso__Timeout__c = 20.000
        );

        if (isInsert) {
        insert iasoCustomSetting;
        }

        return iasoCustomSetting;
    }


    public static DMT_Line__c generateTestTreasuryLines() {

        Account accTest1 = DMT_UTIL.createAccount(
            new Map<Schema.SObjectField, Object>{
                Account.CIB_Commercial_Prospect__c => 'Commercial'
            }
        );

        List<DMT_Line__c> linesInsert = new List<DMT_Line__c>();

        DMT_Line__c lineTest = DMT_UTIL.buildLine(
            accTest1.Id,
            DMT_UtilTestClassConstants.DEFAULT_TREASURY_LINE_RECORD_TYPE_ID,
            '00001',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Allowed__c => false,
                DMT_Line__c.Booking_Geography__c => 'ES',
                DMT_Line__c.Clearing__c => false,
                DMT_Line__c.Client_Code__c => 'ES0182054986618',
                DMT_Line__c.CurrencyIsoCode => 'EUR',
                DMT_Line__c.DMT_Client_Entific__c => 'ES',
                DMT_Line__c.DMT_Comments__c => 'Test comments',
                DMT_Line__c.DvP_Amount__c => 100,
                DMT_Line__c.DvP_Currency__c => 'EUR',
                DMT_Line__c.End_Date__c => date.newInstance(2024, 12, 21),
                DMT_Line__c.FD_Amount__c => 100,
                DMT_Line__c.FD_Currency__c => 'EUR',
                DMT_Line__c.Name => 'Line Test ENERGIA FINANCIACION',
                DMT_Line__c.Start_Date__c => date.newInstance(2024, 11, 21),
                DMT_Line__c.Status__c => 'Draft',
                DMT_Line__c.Treasury_Currency__c => 'EUR',
                DMT_Line__c.Waiver__c => false,
                DMT_Line__c.Repos_Limit_6M__c => 120000,
                DMT_Line__c.Repos_Limit__c => 120000
            }
        );

        linesInsert.add(lineTest);

        DMT_Line__c lineTest2 = DMT_UTIL.buildLine(
            accTest1.Id,
            DMT_UtilTestClassConstants.DEFAULT_TREASURY_LINE_RECORD_TYPE_ID,
            '00002',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Allowed__c => false,
                DMT_Line__c.Booking_Geography__c => 'ES',
                DMT_Line__c.Clearing__c => false,
                DMT_Line__c.Client_Code__c => 'ES0182054986618',
                DMT_Line__c.CurrencyIsoCode => 'EUR',
                DMT_Line__c.DMT_Client_Entific__c => 'ES',
                DMT_Line__c.DMT_Comments__c => 'Test comments',
                DMT_Line__c.DvP_Amount__c => 100,
                DMT_Line__c.DvP_Currency__c => 'EUR',
                DMT_Line__c.End_Date__c => date.newInstance(2024, 12, 21),
                DMT_Line__c.FD_Amount__c => 100,
                DMT_Line__c.FD_Currency__c => 'EUR',
                DMT_Line__c.Name => 'Line Test ENERGIA FINANCIACION',
                DMT_Line__c.Start_Date__c => date.newInstance(2024, 11, 21),
                DMT_Line__c.Status__c => 'Draft',
                DMT_Line__c.Treasury_Currency__c => 'EUR',
                DMT_Line__c.Waiver__c => false,
                DMT_Line__c.Repos_Limit_6M__c => 120000,
                DMT_Line__c.Repos_Limit__c => 120000,
                DMT_Line__c.DMT_Parent_Line__c => lineTest.Id
            }
        );

        linesInsert.add(lineTest2);
        insert linesInsert;

        List<DMT_Feature__c> featureList = new List<DMT_Feature__c>{
            DMT_UTIL.buildFeature(
                new Map<Schema.SObjectField, Object>{
                    DMT_Feature__c.gf_capability_engine_id_number__c => '123',
                    DMT_Feature__c.gf_feature_name_desc__c => 'Feature Test A',
                    DMT_Feature__c.gf_feature_deal_type__c => 'Type1',
                    DMT_Feature__c.gf_global_feature_id_number__c => 'GF001',
                    DMT_Feature__c.gf_approver_apply_ind_type__c => 'Test1',
                    DMT_Feature__c.gf_user_audit_id__c => 'UserTest1',
                    DMT_Feature__c.gf_code_value_id__c => '20'
                }
            ),
            DMT_UTIL.buildFeature(
                new Map<Schema.SObjectField, Object>{
                    DMT_Feature__c.gf_capability_engine_id_number__c => '456',
                    DMT_Feature__c.gf_feature_name_desc__c => 'Feature Test B',
                    DMT_Feature__c.gf_feature_deal_type__c => 'Type2',
                    DMT_Feature__c.gf_global_feature_id_number__c => 'GF002',
                    DMT_Feature__c.gf_approver_apply_ind_type__c => 'Test2',
                    DMT_Feature__c.gf_user_audit_id__c => 'UserTest2',
                    DMT_Feature__c.gf_code_value_id__c => '21'
                }
            )
        };
        insert featureList;

        insert new List<DMT_Selected_Features__c>{
            DMT_UTIL.buildSelectedFeature(
                featureList[0].Id,
                new Map<Schema.SObjectField, Object>{
                    DMT_Selected_Features__c.Line__c => lineTest.Id
                }
            ),
            DMT_UTIL.buildSelectedFeature(
                featureList[1].Id,
                new Map<Schema.SObjectField, Object>{
                    DMT_Selected_Features__c.Line__c => lineTest2.Id
                }
            )
        };



        //Risk line terms
        DMT_Risk_Line_Term__c rsklt1 = DMT_UTIL.buildRiskLineTerm(
            lineTest2.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 1',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '3',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 100000,
                DMT_Risk_Line_Term__c.gf_group_priority_line_id__c => '01',
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => 'Derivatives'
            }
        );

        List<DMT_Risk_Line_Term__c> listRsklt = new List<DMT_Risk_Line_Term__c>{rsklt1};
        insert listRsklt;

        Pricebook2 pb2 = generatePricebook2();
        //Productos
        Product2 p1 = buildDmtLineProduct('DEPO', '1611170000', '00');

        Product2 p2 = buildDmtLineProduct('Derivatives', '1600000000', '01');

        Product2 p3 = buildDmtLineProduct('Equity', '1610000000', '02');

        Product2 p4 = buildDmtLineProduct('Repo', '1611190000', '00');

        List<Product2> listProducts = new List<Product2>{p1, p2, p3, p4};
        insert listProducts;

        DMT_Line_Product_Item__c pli1 = DMT_UTIL.createLineProductItemRecord(lineTest2.Id, p1.Id);


        return lineTest2;
    }

    public static DMT_Line__c generateTestOtherLines() {

        Account accTest1 = DMT_UTIL.createAccount(
            new Map<Schema.SObjectField, Object>{
                Account.DES_Activity__c => 'Electric Power Generation'
            }
        );

        Account accTest1Update = [SELECT Id FROM Account LIMIT 1];

        DMT_Line__c lineTest = DMT_UTIL.createLineRecord(
            accTest1Update.Id,
            DMT_UtilTestClassConstants.DEFAULT_OTHER_LINE_RECORD_TYPE_ID,
            '00003',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Allowed__c => false,
                DMT_Line__c.Booking_Geography__c => 'ES',
                DMT_Line__c.Clearing__c => false,
                DMT_Line__c.Client_Code__c => 'ES0182054986618',
                DMT_Line__c.CurrencyIsoCode => 'EUR',
                DMT_Line__c.DMT_Client_Entific__c => 'ES',
                DMT_Line__c.DMT_Comments__c => 'Test comments',
                DMT_Line__c.DvP_Amount__c => 100,
                DMT_Line__c.DvP_Currency__c => 'EUR',
                DMT_Line__c.End_Date__c => date.newInstance(2024, 12, 21),
                DMT_Line__c.FD_Amount__c => 100,
                DMT_Line__c.FD_Currency__c => 'EUR',
                DMT_Line__c.Name => 'Line Test ENERGIA FINANCIACION',
                DMT_Line__c.Start_Date__c => date.newInstance(2024, 11, 21),
                DMT_Line__c.Status__c => 'Draft',
                DMT_Line__c.Treasury_Currency__c => 'EUR',
                DMT_Line__c.Waiver__c => false,
                DMT_Line__c.Repos_Limit_6M__c => 120000,
                DMT_Line__c.Repos_Limit__c => 120000,
                DMT_Line__c.DMT_LastLevelId__c => '61000',
                DMT_Line__c.Amount__c => 1000
            }
        );

        List<DMT_Feature__c> featureList = new List<DMT_Feature__c>{
            DMT_UTIL.buildFeature(
                new Map<Schema.SObjectField, Object>{
                    DMT_Feature__c.gf_capability_engine_id_number__c => '999',
                    DMT_Feature__c.gf_feature_name_desc__c => 'Feature Test C',
                    DMT_Feature__c.gf_feature_deal_type__c => 'Type3',
                    DMT_Feature__c.gf_global_feature_id_number__c => 'GF003',
                    DMT_Feature__c.gf_approver_apply_ind_type__c => 'Test3',
                    DMT_Feature__c.gf_user_audit_id__c => 'UserTest',
                    DMT_Feature__c.gf_code_value_id__c => '22'
                }
            )
        };
        insert featureList;

        insert new List<DMT_Selected_Features__c>{
            DMT_UTIL.buildSelectedFeature(
                featureList[0].Id,
                new Map<Schema.SObjectField, Object>{
                    DMT_Selected_Features__c.Line__c => lineTest.Id
                }
            )
        };

        Pricebook2 pb2 = generatePricebook2();
         //Productos
        Product2 p1 = buildDmtLineProduct('DEPO', '2611170000', '00');


        List<Product2> listProducts = new List<Product2>{p1};
        insert listProducts;

        //Risk line terms
        DMT_Risk_Line_Term__c rsklt1 = DMT_UTIL.buildRiskLineTerm(
            lineTest.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 1',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '3',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 100000,
                DMT_Risk_Line_Term__c.DMT_LastLevelId__c => '61000',
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => '',
                DMT_Risk_Line_Term__c.gf_group_priority_line_id__c => '01',
                DMT_Risk_Line_Term__c.DMT_Product__c => p1.Id
            }
        );


        List<DMT_Risk_Line_Term__c> listRsklt = new List<DMT_Risk_Line_Term__c>{rsklt1};
        insert listRsklt;



        DMT_Line_Product_Item__c pli1 = DMT_UTIL.createLineProductItemRecord(lineTest.Id, p1.Id);


        return lineTest;
    }

    public static DMT_Line__c generateTestTreasurySingularLines() {

        Account accTest1 = DMT_UTIL.createAccount();
        Account accTest1Update = [SELECT Id FROM Account WHERE Id =: accTest1.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c lineTest = DMT_UTIL.createLineRecord(
            accTest1Update.Id,
            DMT_UtilTestClassConstants.DEFAULT_TREASURY_LINE_RECORD_TYPE_ID,
            '00004',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Allowed__c => false,
                DMT_Line__c.Booking_Geography__c => 'ES',
                DMT_Line__c.Clearing__c => false,
                DMT_Line__c.Client_Code__c => 'ES0182054986618',
                DMT_Line__c.CurrencyIsoCode => 'EUR',
                DMT_Line__c.DMT_Client_Entific__c => 'ES',
                DMT_Line__c.DMT_Comments__c => 'Test comments',
                DMT_Line__c.DvP_Amount__c => 100,
                DMT_Line__c.DvP_Currency__c => 'EUR',
                DMT_Line__c.End_Date__c => date.newInstance(2024, 12, 21),
                DMT_Line__c.FD_Amount__c => 100,
                DMT_Line__c.FD_Currency__c => 'EUR',
                DMT_Line__c.Name => 'Line Test ENERGIA FINANCIACION',
                DMT_Line__c.Start_Date__c => date.newInstance(2024, 11, 21),
                DMT_Line__c.Status__c => 'Closed',
                DMT_Line__c.Closed__c => 'Won',
                DMT_Line__c.Treasury_Currency__c => 'EUR',
                DMT_Line__c.Waiver__c => false,
                DMT_Line__c.Repos_Limit_6M__c => 120000,
                DMT_Line__c.Repos_Limit__c => 120000
            }
        );


        DMT_Line__c lineTestUpdate = [SELECT Id FROM DMT_Line__c WHERE Id =: lineTest.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c lineTest2 = DMT_UTIL.createLineRecord(
            accTest1Update.Id,
            DMT_UtilTestClassConstants.DEFAULT_TREASURY_LINE_RECORD_TYPE_ID,
            '00005',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Allowed__c => false,
                DMT_Line__c.Booking_Geography__c => 'PE',
                DMT_Line__c.Clearing__c => false,
                DMT_Line__c.Client_Code__c => 'ES0182054986618',
                DMT_Line__c.CurrencyIsoCode => 'EUR',
                DMT_Line__c.DMT_Client_Entific__c => 'PE',
                DMT_Line__c.DMT_Comments__c => 'Test comments',
                DMT_Line__c.DvP_Amount__c => 100,
                DMT_Line__c.DvP_Currency__c => 'EUR',
                DMT_Line__c.End_Date__c => date.newInstance(2024, 12, 21),
                DMT_Line__c.FD_Amount__c => 100,
                DMT_Line__c.FD_Currency__c => 'EUR',
                DMT_Line__c.Name => 'Line Test ENERGIA FINANCIACION',
                DMT_Line__c.Start_Date__c => date.newInstance(2024, 11, 21),
                DMT_Line__c.Status__c => 'Closed',
                DMT_Line__c.Closed__c => 'Won',
                DMT_Line__c.Treasury_Currency__c => 'EUR',
                DMT_Line__c.Waiver__c => false,
                DMT_Line__c.Repos_Limit_6M__c => 120000,
                DMT_Line__c.Repos_Limit__c => 120000,
                DMT_Line__c.DMT_Parent_Line__c => lineTest.Id
            }
        );


        DMT_Line__c lineTest2Update = [SELECT Id FROM DMT_Line__c WHERE Id =: lineTest2.Id LIMIT 1 FOR UPDATE];

        //Risk line terms
        DMT_Risk_Line_Term__c rsklt1 = DMT_UTIL.buildRiskLineTerm(
            lineTest2Update.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 1',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '3',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 100000,
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => 'Derivatives'
            }
        );

        DMT_Risk_Line_Term__c rsklt2 = DMT_UTIL.buildRiskLineTerm(
            lineTest2Update.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 2',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '5',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 100000,
                DMT_Risk_Line_Term__c.DMT_Singular__c => true,
                DMT_Risk_Line_Term__c.DMT_Singular_Operation__c => 'Operation Name',
                DMT_Risk_Line_Term__c.DMT_Max_Date__c => Date.today().addDays(-1),
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => 'Derivatives'
            }
        );

        DMT_Risk_Line_Term__c rsklt3 = DMT_UTIL.buildRiskLineTerm(
            lineTest2Update.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 3',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '7',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 100000,
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => 'Depos'
            }
        );

        DMT_Risk_Line_Term__c rsklt4 = DMT_UTIL.buildRiskLineTerm(
            lineTest2Update.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 4',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '9',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 10000,
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => 'Depos'
            }
        );

        DMT_Risk_Line_Term__c rsklt5 = DMT_UTIL.buildRiskLineTerm(
            lineTest2Update.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 5',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '6',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 10000,
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => 'Equities'
            }
        );

        DMT_Risk_Line_Term__c rsklt6 = DMT_UTIL.buildRiskLineTerm(
            lineTest2Update.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 6',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '6',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '30',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 1000000,
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => 'Equities'
            }
        );

        List<DMT_Risk_Line_Term__c> listRsklt = new List<DMT_Risk_Line_Term__c>{rsklt1,rsklt2,rsklt3,rsklt4,rsklt5,rsklt6};
        insert listRsklt;

        Pricebook2 pb2 = generatePricebook2();
        //Productos
        Product2 p1 = buildDmtLineProduct('DEPO', '1611170000', '00');

        Product2 p2 = buildDmtLineProduct('Derivatives', '1600000000', '01');

        Product2 p3 = buildDmtLineProduct('Equity', '1610000000', '02');

        Product2 p4 = buildDmtLineProduct('Repo', '1611190000', '03');

        Product2 p5 = DES_UTIL.buildProduct(new Map<Schema.SObjectField, Object>{
            Product2.Name => 'Repo',
            Product2.ProductCode => '1647895623',
            Product2.DMT_Global_Product_Id__c => '04',
            Product2.CurrencyIsoCode => 'EUR',
            Product2.Family => 'DMT Lines'
        });

        List<Product2> listProducts = new List<Product2>{p1,p2,p3,p4,p5};

        insert listProducts;

        DMT_Line_Product_Item__c pli1 = DMT_UTIL.createLineProductItemRecord(lineTest2.Id, p1.Id);


        return lineTest2Update;
    }


    public static Account generateAccount() {
        return generateAccount(null);
    }

    public static Account generateAccount(Map<Schema.SObjectField, Object> overrides) {
        Map<Schema.SObjectField, Object> accountOverrides = new Map<Schema.SObjectField, Object>{
            Account.Revenues_Last_Year_number__c => 13,
            Account.DES_Group_Code__c => 'G20180109100427'
        };

        accountOverrides.put(Account.Past2_FY_Corp_Synd_Lending_amount__c, 13);

        if (overrides != null) {
            accountOverrides.putAll(overrides);
        }

        Account accTest1 = DMT_UTIL.createAccount(accountOverrides);

        Account accTest1Update = [
            SELECT Id
            FROM Account
            WHERE Id = :accTest1.Id
            LIMIT 1
            FOR UPDATE
        ];

        return accTest1Update;
    }

    public static AMH_GBL_Account_Relationship__c generateAccRelationship(Id accParentId, Id accChildId) {
        return generateAccRelationship(accParentId, accChildId, null);
    }

    public static AMH_GBL_Account_Relationship__c generateAccRelationship(Id accParentId, Id accChildId, Map<Schema.SObjectField, Object> overrides) {
        return DES_UTIL.createAccRelationshipRecord(accParentId, accChildId, overrides);
    }

    /**
     * Creates a DES Group Account and optionally links subsidiary Accounts
     * and a Global Banker.
     *
     * DES_UtilTestClass owns the Group/Subsidiary relationship logic; DMT adds no wrapper.
     *
     * @param groupAccountName   Name of the Group Account.
     * @param subsidiaryAccountIds Account Ids to relate as subsidiaries.
     *                             Pass null to create the Group without subsidiaries.
     * @param globalBankerUserId User Id for the Global Banker.
     *                           Pass null when no Global Banker is required.
     */
    public static Account generateGroupAccount(String groupAccountName, Set<Id> subsidiaryAccountIds, Id globalBankerUserId) {
        return DES_UTIL.createGroupClient(groupAccountName, subsidiaryAccountIds, globalBankerUserId);
    }

    /**
     * Creates a DMT Subsidiary Account for an existing Group Account and
     * persists the standard DES AMH parent/child relationship.
     */
    public static Account generateSubsidiaryForGroup(Id groupAccountId) {
        return generateSubsidiaryForGroup(groupAccountId, null, null);
    }

    public static Account generateSubsidiaryForGroup(Id groupAccountId, Map<Schema.SObjectField, Object> accountOverrides) {
        return generateSubsidiaryForGroup(groupAccountId, accountOverrides, null);
    }

    public static Account generateSubsidiaryForGroup(Id groupAccountId, Map<Schema.SObjectField, Object> accountOverrides, Map<Schema.SObjectField, Object> relationshipOverrides) {
        Map<Schema.SObjectField, Object> subsidiaryOverrides = new Map<Schema.SObjectField, Object>{
            Account.DES_Main_Parent__c => groupAccountId,
            Account.DES_Structure_Type__c => 'Subsidiary'
        };

        if (accountOverrides != null) {
            subsidiaryOverrides.putAll(accountOverrides);
        }

        Account subsidiary = DMT_UTIL.createAccount(subsidiaryOverrides);

        generateAccRelationship(groupAccountId, subsidiary.Id, relationshipOverrides);

        return subsidiary;
    }

    /**
     * Creates the standard DMT Opportunity for an existing Account.
     *
     * The Account may be a regular/subsidiary Account or a DES Group Account.
     */
    public static Opportunity generateOpportunityForAccount(Id accountId) {
        return generateOpportunityForAccount(accountId, null);
    }

    public static Opportunity generateOpportunityForAccount(Id accountId, Map<Schema.SObjectField, Object> overrides) {
        Opportunity testOpportunity = DMT_UTIL.createOpportunityForAccount(accountId, overrides);

        Opportunity testOpportunityUpdate = [
            SELECT Id, AccountId, DMT_Opp_Id__c
            FROM Opportunity
            WHERE Id = :testOpportunity.Id
            LIMIT 1
            FOR UPDATE
        ];
        return testOpportunityUpdate;
    }

    /**
     * Creates the minimum valid DMT Group Opportunity scenario:
     * Opportunity + one Group association + one Client association.
     */
    public static Opportunity generateGroupOpportunity(Id groupAccountId, Id clientId) {
        return generateGroupOpportunity(groupAccountId, clientId, null, null, null);
    }

    public static Opportunity generateGroupOpportunity(Id groupAccountId, Id clientId, Map<Schema.SObjectField, Object> opportunityOverrides, Map<Schema.SObjectField, Object> associationOverrides, Map<Schema.SObjectField, Object> clientAssociationOverrides) {
        Opportunity opportunity = generateOpportunityForAccount(groupAccountId, opportunityOverrides);

        Map<Schema.SObjectField, Object> groupAssociationOverrides = new Map<Schema.SObjectField, Object>{
            Custom_Association_Opportunity__c.Group__c => groupAccountId
        };
        if (associationOverrides != null) {
            groupAssociationOverrides.putAll(associationOverrides);
        }

        Custom_Association_Opportunity__c association = generateCustomAssociationOpportunity(opportunity.Id, groupAssociationOverrides);
        generateCustomAssociationClientOpportunity(association.Id, clientId, clientAssociationOverrides);

        return opportunity;
    }

    /**
     * Backward-compatible helper.
     * Preserves the existing behavior: create a DMT Account first and then
     * create the standard DMT Opportunity for that Account.
     */
    public static Opportunity generateOpportunity() {
        return generateOpportunity(null);
    }

    public static Opportunity generateOpportunity(Map<Schema.SObjectField, Object> overrides) {
        Account testAcc = generateAccount();
        return generateOpportunityForAccount(testAcc.Id, overrides);
    }

    public static DMT_Opportunity_Client__c generateOpportunityClient(String oppId) {
        return generateOpportunityClient(
            oppId,
            new Map<Schema.SObjectField, Object>{
                DMT_Opportunity_Client__c.Past2_FY_Corp_Synd_Lending_amount__c => 14,
                DMT_Opportunity_Client__c.Revenues_Last_Year_number__c => 14,
                DMT_Opportunity_Client__c.Counterpart__c => 'Corporates',
                DMT_Opportunity_Client__c.DMT_Sector__c => 'N',
                DMT_Opportunity_Client__c.g_upd_lmscl_internal_ratg_type__c => '-A'
            }
        );
    }

    public static DMT_Opportunity_Client__c generateOpportunityClient(String oppId, Map<Schema.SObjectField, Object> overrides) {
        DMT_Opportunity_Client__c oppCl = DMT_UTIL.createOpportunityClientRecord(oppId, overrides);

        DMT_Opportunity_Client__c oppClUpdate = [
            SELECT Id
            FROM DMT_Opportunity_Client__c
            WHERE Id = :oppCl.Id
            LIMIT 1
            FOR UPDATE
        ];
        return oppClUpdate;
    }

    public static List<DMT_Global_Structure__c> generateOppGlobalStructure(String oppId) {
        List<DMT_Global_Structure__c> gsList = new List<DMT_Global_Structure__c>();

        // 8 records of Uses
        for(Integer i = 0; i < 8; i++) {
            DMT_Global_Structure__c gs = DMT_UTIL.buildGlobalStructure(
                oppId,
                new Map<Schema.SObjectField, Object>{
                    DMT_Global_Structure__c.Name => 'Uses ' + i,
                    DMT_Global_Structure__c.DMT_Type__c => 'Uses'
                }
            );
            gsList.add(gs);
        }

        // 4 records of Funding Debt
        for(Integer i = 0; i < 4; i++) {
            DMT_Global_Structure__c gs = DMT_UTIL.buildGlobalStructure(
                oppId,
                new Map<Schema.SObjectField, Object>{
                    DMT_Global_Structure__c.Name => 'Debt Fund ' + i,
                    DMT_Global_Structure__c.DMT_Type__c => 'Funding Debt'
                }
            );
            gsList.add(gs);
        }

        // 4 records of Funding Equity
        for(Integer i = 0; i < 4; i++) {
            DMT_Global_Structure__c gs = DMT_UTIL.buildGlobalStructure(
                oppId,
                new Map<Schema.SObjectField, Object>{
                    DMT_Global_Structure__c.Name => 'Equity Fund ' + i,
                    DMT_Global_Structure__c.DMT_Type__c => 'Funding Equity'
                }
            );
            gsList.add(gs);
        }

        insert gsList;
        return gsList;
    }

    public static void generateTestSanctionLines(){

        Account accTest1 = DMT_UTIL.createAccount(
            new Map<Schema.SObjectField, Object>{
                Account.DES_Structure_Type__c => 'Subsidiary'
            }
        );
        Account accTest1Update = [SELECT Id FROM Account WHERE Id =: accTest1.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c testLine = DMT_UTIL.createLineRecord(
            accTest1Update.Id,
            DMT_UtilTestClassConstants.DEFAULT_OTHER_LINE_RECORD_TYPE_ID,
            '00009',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Name => 'Test Line ',
                DMT_Line__c.Status__c => 'Draft',
                DMT_Line__c.DMT_Origin__c => 'AMIWEB',
                DMT_Line__c.g_line_status_type__c => 'AP',
                DMT_Line__c.Booking_Geography__c => 'ES',
                DMT_Line__c.DMT_Client_Entific__c => 'ES',
                DMT_Line__c.Client_Code__c => 'G00000000000201'
            }
        );

        DMT_Line__c testLineUpdate = [SELECT Id FROM DMT_Line__c WHERE Id =: testLine.Id LIMIT 1 FOR UPDATE];

        Pricebook2 pb2 = generatePricebook2();

        Product2 p1 = buildDmtLineProduct('DEPO', '1611170000', '00');

        Product2 p2 = buildDmtLineProduct('Derivatives', '1600000000', '01');

        Product2 p3 = buildDmtLineProduct('Equity', '1610000000', '02');

        List<Product2> listProducts = new List<Product2>{p1,p2,p3};

        insert listProducts;

        DMT_Risk_Line_Term__c rsklt1 = DMT_UTIL.buildRiskLineTerm(
            testLineUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 1',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '3',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 1000000,
                DMT_Risk_Line_Term__c.DMT_Product__c => p1.Id,
                DMT_Risk_Line_Term__c.DMT_LastLevelId__c => '20'
            }
        );

        DMT_Risk_Line_Term__c rsklt2 = DMT_UTIL.buildRiskLineTerm(
            testLineUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 2',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '5',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 100000,
                DMT_Risk_Line_Term__c.DMT_Product__c => p2.Id,
                DMT_Risk_Line_Term__c.DMT_LastLevelId__c => '30'
            }
        );

        DMT_Risk_Line_Term__c rsklt3 = DMT_UTIL.buildRiskLineTerm(
            testLineUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 3',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '7',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 1000000,
                DMT_Risk_Line_Term__c.DMT_Product__c => p3.Id,
                DMT_Risk_Line_Term__c.DMT_LastLevelId__c => '40'
            }
        );

        List<DMT_Risk_Line_Term__c> listRsklt = new List<DMT_Risk_Line_Term__c>{rsklt1,rsklt2,rsklt3};

        insert listRsklt;
    }
    public static void generateTestRiskApprovalLines(Id accountId){

        DMT_Line__c testLine = DMT_UTIL.createLineRecord(
            accountId,
            DMT_UtilTestClassConstants.DEFAULT_RISK_APPROVAL_LINE_RECORD_TYPE_ID,
            '00089',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Name => 'Test Line ',
                DMT_Line__c.Status__c => 'Draft',
                DMT_Line__c.Allowed__c => true,
                DMT_Line__c.DMT_Origin__c => 'Salesforce',
                DMT_Line__c.g_line_status_type__c => 'AP',
                DMT_Line__c.Booking_Geography__c => 'ES',
                DMT_Line__c.DMT_Client_Entific__c => 'ES',
                DMT_Line__c.Client_Code__c => 'G00000000000201'
            }
        );


        Pricebook2 pb2 = generatePricebook2();

        Product2 p1 = buildDmtLineProduct('DEPO', '1611170000', '00');
        List<Product2> listProducts = new List<Product2>{p1};

        insert listProducts;

        DMT_Risk_Line_Term__c rsklt1 = DMT_UTIL.createRiskLineTermRecord(
            testLine.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 1',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '3',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 1000000,
                DMT_Risk_Line_Term__c.DMT_Product__c => p1.Id,
                DMT_Risk_Line_Term__c.DMT_LastLevelId__c => '20'
            }
        );

    }

    public static void generateTestRiskApprovalLines(){

        Account accTest1 = DMT_UTIL.createAccount(
            new Map<Schema.SObjectField, Object>{
                Account.DES_Structure_Type__c => 'Subsidiary'
            }
        );
        Account accTest1Update = [SELECT Id FROM Account WHERE Id =: accTest1.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c testLine = DMT_UTIL.createLineRecord(
            accTest1Update.Id,
            DMT_UtilTestClassConstants.DEFAULT_RISK_APPROVAL_LINE_RECORD_TYPE_ID,
            '00089',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Name => 'Test Line ',
                DMT_Line__c.Status__c => 'Draft',
                DMT_Line__c.Allowed__c => true,
                DMT_Line__c.DMT_Origin__c => 'Salesforce',
                DMT_Line__c.g_line_status_type__c => 'AP',
                DMT_Line__c.Booking_Geography__c => 'ES',
                DMT_Line__c.DMT_Client_Entific__c => 'ES',
                DMT_Line__c.Client_Code__c => 'G00000000000201'
            }
        );

        DMT_Line__c testLineUpdate = [SELECT Id FROM DMT_Line__c WHERE Id =: testLine.Id LIMIT 1 FOR UPDATE];

        Pricebook2 pb2 = generatePricebook2();

        Product2 p1 = buildDmtLineProduct('DEPO', '1611170000', '00');

        Product2 p2 = buildDmtLineProduct('Derivatives', '1600000000', '01');

        Product2 p3 = buildDmtLineProduct('Equity', '1610000000', '02');

        List<Product2> listProducts = new List<Product2>{p1,p2,p3};

        insert listProducts;

        DMT_Risk_Line_Term__c rsklt1 = DMT_UTIL.buildRiskLineTerm(
            testLineUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 1',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '3',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 1000000,
                DMT_Risk_Line_Term__c.DMT_Product__c => p1.Id,
                DMT_Risk_Line_Term__c.DMT_LastLevelId__c => '20'
            }
        );

        DMT_Risk_Line_Term__c rsklt2 = DMT_UTIL.buildRiskLineTerm(
            testLineUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 2',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '5',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 100000,
                DMT_Risk_Line_Term__c.DMT_Product__c => p2.Id,
                DMT_Risk_Line_Term__c.DMT_LastLevelId__c => '30'
            }
        );

        DMT_Risk_Line_Term__c rsklt3 = DMT_UTIL.buildRiskLineTerm(
            testLineUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 3',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '7',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 1000000,
                DMT_Risk_Line_Term__c.DMT_Product__c => p3.Id,
                DMT_Risk_Line_Term__c.DMT_LastLevelId__c => '40'
            }
        );

        List<DMT_Risk_Line_Term__c> listRsklt = new List<DMT_Risk_Line_Term__c>{rsklt1,rsklt2,rsklt3};

        insert listRsklt;
    }


    public static DMT_Approver__c generateApprover() {
        DMT_Approver__c approver = DMT_UTIL.createApproverRecord(
            new Map<Schema.SObjectField, Object>{
                DMT_Approver__c.Name => 'TestApproverDataFactory',
                DMT_Approver__c.DMT_External_Id__c => 'TestExternalIdDATAFACTORY' + Integer.valueof((Math.random() * 100000000)),
                DMT_Approver__c.DMT_Approver_Code__c => '12222233134'
            }
        );

        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }
    public static DMT_Approver_Type__c generateApproverTypeRisk() {
        DMT_Approver_Type__c approverType = DMT_UTIL.createApproverTypeRecord(DMT_Constants.APPROVER_TYPE_RISK, '1');

        DMT_Approver_Type__c approverTypeUpdate = [SELECT Id FROM DMT_Approver_Type__c WHERE Id =: approverType.Id LIMIT 1 FOR UPDATE];
        return approverTypeUpdate;
    }

    public static DMT_Approver_Type__c generateApproverTypeBusiness() {
        DMT_Approver_Type__c approverType = DMT_UTIL.createApproverTypeRecord(DMT_Constants.APPROVER_TYPE_BUSINESS, '32');
        System.debug('**** Approver type bsn In Factory: ' + approverType);
        DMT_Approver_Type__c approverTypeUpdate = [SELECT Id FROM DMT_Approver_Type__c WHERE Id =: approverType.Id LIMIT 1 FOR UPDATE];
        return approverTypeUpdate;
    }

    public static DMT_Approver__c generateApproverBussines() {
        DMT_Approver__c approver = DMT_UTIL.createApproverRecord(
            new Map<Schema.SObjectField, Object>{
                DMT_Approver__c.Name => 'TestApproverDataFactoryBusiness',
                DMT_Approver__c.DMT_External_Id__c => 'TestExternalIdDATAFACTORY32',
                DMT_Approver__c.DMT_Approver_Code__c => '12222233135',
                DMT_Approver__c.DMT_ApproverType__c => generateApproverTypeBusiness().Id
            }
        );
        System.debug('**** Approver In Factory: ' + approver);

        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }

    public static DMT_Approver__c generateApproverRisk() {
        DMT_Approver__c approver = DMT_UTIL.createApproverRecord(
            new Map<Schema.SObjectField, Object>{
                DMT_Approver__c.Name => 'TestApproverDataFactoryRisk',
                DMT_Approver__c.DMT_External_Id__c => 'TestExternalIdDATAFACTORY1',
                DMT_Approver__c.DMT_Approver_Code__c => '12222233136',
                DMT_Approver__c.DMT_ApproverType__c => generateApproverTypeRisk().Id
            }
        );

        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }

    public static DMT_Approver_Member__c generateApproverMember() {
        DMT_Approver__c approver = generateApprover();
        DMT_Approver_Member__c member = DMT_UTIL.createApproverMemberRecord(approver.Id, UserInfo.getUserId());

        DMT_Approver_Member__c memberUpdate = [SELECT Id FROM DMT_Approver_Member__c WHERE Id =: member.Id LIMIT 1 FOR UPDATE];
        return memberUpdate;
    }

    public static DMT_Approver_Member__c generateApproverMemberForUserWithUOS(Id userId, String uosCode) {
        DMT_Approver__c approver = generateApprover();
        DMT_Approver_Member__c member = DMT_UTIL.createApproverMemberRecord(
            approver.Id,
            userId,
            new Map<Schema.SObjectField, Object>{
                DMT_Approver_Member__c.DMT_ApproverByUOs__c => uosCode
            }
        );

        DMT_Approver_Member__c memberUpdate = [SELECT Id FROM DMT_Approver_Member__c WHERE Id =: member.Id LIMIT 1 FOR UPDATE];
        return memberUpdate;
    }

    public static Case generateCase(Id lineId, Id opportunityId, Id ownerId) {
        Map<Schema.SObjectField, Object> caseOverrides = new Map<Schema.SObjectField, Object>{
            Case.DMT_Feature_Id__c => 'Test',
            Case.DMT_Related_feature_name__c => 'Test1',
            Case.Amount__c => 45
        };
        if (lineId != null) {
            caseOverrides.put(Case.DMT_Line__c, lineId);
        } else {
            caseOverrides.put(Case.opportunity_id__c, opportunityId);
        }

        Case c = DMT_UTIL.createCaseRecord(
            ownerId,
            DMT_UtilTestClassConstants.DEFAULT_APPROVAL_CASE_RECORD_TYPE_ID,
            caseOverrides
        );

        //Case caseUpdate = [SELECT Id FROM Case WHERE Id =: c.Id LIMIT 1 FOR UPDATE];
        return c;
    }

    public static Case generateCase(Id ownerId, Map<Schema.SObjectField, Object> overrides) {
        Case caseRecord = DMT_UTIL.createCaseRecord(
            ownerId,
            DMT_UtilTestClassConstants.DEFAULT_APPROVAL_CASE_RECORD_TYPE_ID,
            overrides
        );

        return caseRecord;
    }

    public static Case generateCaseOppLine(Id lineId, Id opportunityId, Id ownerId) {
        Case c = DMT_UTIL.createCaseRecord(
            ownerId,
            DMT_UtilTestClassConstants.DEFAULT_APPROVAL_CASE_RECORD_TYPE_ID,
            new Map<Schema.SObjectField, Object>{
                Case.DMT_Line__c => lineId,
                Case.opportunity_id__c => opportunityId,
                Case.DMT_Feature_Id__c => 'Test',
                Case.DMT_Related_feature_name__c => 'Test1',
                Case.Amount__c => 45
            }
        );

        //Case caseUpdate = [SELECT Id FROM Case WHERE Id =: c.Id LIMIT 1 FOR UPDATE];
        return c;
    }

    public static void generatePassportCase(Id lineId, Id opportunityId, Id ownerId, Integer num) {
        List<DMT_Task_Type__c> taskTypes = generateTaskTypes();
        for (Integer i = 0; i < num; i++) {
        Map<Schema.SObjectField, Object> caseOverrides = new Map<Schema.SObjectField, Object>{
            Case.DMT_Feature_Id__c => String.valueOf(num),
            Case.DMT_Related_feature_name__c => 'Test' + String.valueOf(num),
            Case.Amount__c => 100000,
            Case.DMT_Passport_Sanction__c => 'passport',
            Case.Status => DMT_Constants.FINISHED
        };
        if (lineId != null) {
            caseOverrides.put(Case.DMT_Line__c, lineId);
        } else {
            caseOverrides.put(Case.opportunity_id__c, opportunityId);
        }

        Case c = DMT_UTIL.createCaseRecord(
            ownerId,
            DMT_UtilTestClassConstants.DEFAULT_APPROVAL_CASE_RECORD_TYPE_ID,
            caseOverrides
        );
        Task t = DMT_UTIL.buildTask(
            ownerId,
            DMT_UtilTestClassConstants.DEFAULT_TASK_STEP_RECORD_TYPE_ID,
            c.Id,
            new Map<Schema.SObjectField, Object>{
                Task.Status => DMT_Constants.FINISHED,
                Task.Subject => 'Task' + i,
                Task.DMT_Task_Type__c => taskTypes[i].Id,
                Task.DMT_Step_Result__c => 'Yes'
            }
        );
        }

        //Case caseUpdate = [SELECT Id FROM Case WHERE Id =: c.Id LIMIT 1 FOR UPDATE];
        //return c;
    }

    public static void generateApprovalCase(Id lineId, Id opportunityId, Id ownerId, Integer num) {
        List<DMT_Task_Type__c> taskTypes = generateTaskTypes();
        for (Integer i = 0; i < num; i++) {
        Map<Schema.SObjectField, Object> caseOverrides = new Map<Schema.SObjectField, Object>{
            Case.DMT_Feature_Id__c => String.valueOf(num),
            Case.DMT_Related_feature_name__c => 'Test' + String.valueOf(num),
            Case.Amount__c => 100000,
            Case.DMT_Passport_Sanction__c => 'approval',
            Case.Status => DMT_Constants.FINISHED
        };
        if (lineId != null) {
            caseOverrides.put(Case.DMT_Line__c, lineId);
        } else {
            caseOverrides.put(Case.opportunity_id__c, opportunityId);
        }

        Case c = DMT_UTIL.createCaseRecord(
            ownerId,
            DMT_UtilTestClassConstants.DEFAULT_APPROVAL_CASE_RECORD_TYPE_ID,
            caseOverrides
        );
        Task t = DMT_UTIL.buildTask(
            ownerId,
            DMT_UtilTestClassConstants.DEFAULT_TASK_STEP_RECORD_TYPE_ID,
            c.Id,
            new Map<Schema.SObjectField, Object>{
                Task.Status => DMT_Constants.FINISHED,
                Task.Subject => 'Task' + i,
                Task.DMT_Task_Type__c => taskTypes[i].Id,
                Task.DMT_Step_Result__c => 'Yes'
            }
        );
        }

        //Case caseUpdate = [SELECT Id FROM Case WHERE Id =: c.Id LIMIT 1 FOR UPDATE];
        //return c;
    }


    public static List<Task> generateTasksWithOwner(Id ownerId, Id recordTypeId, Id whatId, Integer numTasks) {
        return generateTasksWithOwner(ownerId, recordTypeId, whatId, numTasks, null);
    }

    public static List<Task> generateTasksWithOwner(Id ownerId, Id recordTypeId, Id whatId, Integer numTasks, Map<Schema.SObjectField, Object> overrides) {
        List<Task> tasks = new List<Task>();

        for (Integer i = 0; i < numTasks; i++) {
            Map<Schema.SObjectField, Object> taskOverrides = new Map<Schema.SObjectField, Object>{
                Task.Status => 'In Progress',
                Task.Subject => 'Task' + i
            };

            if (overrides != null) {
                taskOverrides.putAll(overrides);
            }

            tasks.add(DMT_UTIL.buildTask(ownerId, recordTypeId, whatId, taskOverrides));
        }

        insert tasks;

        //List<Task> tasksUpdate = [SELECT Id FROM Task WHERE Id IN :tasks FOR UPDATE];
        return tasks;
    }

    public static List<DMT_Task_Type__c> generateTaskTypes() {

        DMT_Task_Type__c tskType1 = DMT_UTIL.buildTaskType(
            new Map<Schema.SObjectField, Object>{
                DMT_Task_Type__c.Name => 'Global Risk',
                DMT_Task_Type__c.DMT_External_Id__c => '1',
                DMT_Task_Type__c.DMT_Closing_Capacity__c => false,
                DMT_Task_Type__c.DMT_Yes_Flag__c => 'YES_YES_Global Risk',
                DMT_Task_Type__c.DMT_No_Flag__c => 'NO_NO_Global Risk',
                DMT_Task_Type__c.DMT_NA_Flag__c => 'NA_NA_Global Risk'
            }
        );

        DMT_Task_Type__c tskType2 = DMT_UTIL.buildTaskType(
            new Map<Schema.SObjectField, Object>{
                DMT_Task_Type__c.Name => 'Local Risk',
                DMT_Task_Type__c.DMT_External_Id__c => '6',
                DMT_Task_Type__c.DMT_Closing_Capacity__c => true,
                DMT_Task_Type__c.DMT_Yes_Flag__c => 'YES_YES_Local Risk',
                DMT_Task_Type__c.DMT_No_Flag__c => 'NO_NO_Local Risk',
                DMT_Task_Type__c.DMT_NA_Flag__c => 'NA_NA_Local Risk'
            }
        );
        DMT_Task_Type__c tskType3 = DMT_UTIL.buildTaskType(
            new Map<Schema.SObjectField, Object>{
                DMT_Task_Type__c.Name => 'Risk review 1',
                DMT_Task_Type__c.DMT_External_Id__c => '3',
                DMT_Task_Type__c.DMT_Closing_Capacity__c => false,
                DMT_Task_Type__c.DMT_Yes_Flag__c => 'YES_YES_Risk',
                DMT_Task_Type__c.DMT_No_Flag__c => 'NO_NO_Risk',
                DMT_Task_Type__c.DMT_NA_Flag__c => 'NA_NA_Risk'
            }
        );

        List<DMT_Task_Type__c> taskTypes = new List<DMT_Task_Type__c>{tskType1,tskType2,tskType3};
        insert taskTypes;

        List<DMT_Task_Type__c> taskTypesUpdate = [SELECT Id FROM DMT_Task_Type__c WHERE Id IN :taskTypes LIMIT 3 FOR UPDATE];
        return taskTypesUpdate;
    }


    public static Id generateView() {

        DMT_ApproversView__c approverView = DMT_UTIL.createApproversViewRecord();

        DMT_ApproversView__c approverViewUpdate = [SELECT Id FROM DMT_ApproversView__c WHERE Id =: approverView.Id LIMIT 1 FOR UPDATE];

        // If more items are added, remember to update the Assert on DMT_SnapshotEvaluationVersionsTest.testGetFilteredComponentItemOptionByVersionView_Positive
        DMT_Items__c item = DMT_UTIL.buildItem(
            approverViewUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Items__c.Name => 'Basic client',
                DMT_Items__c.DMT_Component_Item__c => 'Treasury Line',
                DMT_Items__c.DMT_order_display__c => 1
            }
        );

        DMT_Items__c item2 = DMT_UTIL.buildItem(
            approverViewUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Items__c.Name => 'Basic client2',
                DMT_Items__c.DMT_Component_Item__c => 'Participants',
                DMT_Items__c.DMT_order_display__c => 2
            }
        );

        DMT_Items__c item3 = DMT_UTIL.buildItem(
            approverViewUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Items__c.Name => 'Basic client3',
                DMT_Items__c.DMT_Component_Item__c => 'Client',
                DMT_Items__c.DMT_order_display__c => 3
            }
        );

        DMT_Items__c item4 = DMT_UTIL.buildItem(
            approverViewUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Items__c.Name => 'Basic client4',
                DMT_Items__c.DMT_Component_Item__c => 'Products',
                DMT_Items__c.DMT_order_display__c => 4
            }
        );

        insert new List<DMT_Items__c>{item, item2, item3, item4};

        return approverViewUpdate.Id;
    }


    public static DMT_Approver__c generateApproverWithView(Id approverViewId) {
        DMT_Approver__c approver = DMT_UTIL.createApproverRecord(
            new Map<Schema.SObjectField, Object>{
                DMT_Approver__c.Name => 'TestApproverDataFactory',
                DMT_Approver__c.DMT_External_Id__c => 'TestExternalIdDATAFACTORY' + Integer.valueof((Math.random() * 100000000)),
                DMT_Approver__c.DMT_Approver_Code__c => '12222233134',
                DMT_Approver__c.Approvers_View_Treasury__c => approverViewId
            }
        );
        //approver.DMT_Group__c='TestApproverDataFactory';


        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }

    public static Custom_Association_Opportunity__c generateCustomAssociationOpportunity(Id opportunityId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UTIL.createCustomAssociationOpportunityRecord(opportunityId, overrides);
    }

    public static DMT_Custom_Association_ClientOpportunity__c generateCustomAssociationClientOpportunity(Id customAssociationOpportunityId, Id clientId, Map<Schema.SObjectField, Object> overrides) {
        return DMT_UTIL.createCustomAssociationClientOpportunityRecord(customAssociationOpportunityId, clientId, overrides);
    }

    public static Local_Client__c generateLocalClient(Id accountId, String alphaCode) {
        return DMT_UTIL.createLocalClientRecord(accountId, alphaCode);
    }

    public static Custom_Association__c generateCustomAssociation(Id lineId, Id accountId) {

        Custom_Association__c ca = DMT_UTIL.createCustomAssociationRecord(
            lineId,
            accountId
        );
        //ca.Name = 'TestCA';


        Custom_Association__c caUpdate = [SELECT Id FROM Custom_Association__c WHERE Id =: ca.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c line = new DMT_Line__c(Id = lineId, Custom_Association__c = caUpdate.Id);
        update line;

        return caUpdate;
    }

    public static Custom_Association_Client__c generateCustomAssociationClient(Id caId) {
        Custom_Association_Client__c cac = DMT_UTIL.createCustomAssociationClientRecord(caId);

        return cac;
    }

    public static User generateUserWithoutPermissions() {
        return generateUserWithoutPermissions(null);
    }

    public static User generateUserWithoutPermissions(Map<Schema.SObjectField, Object> overrides) {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Read Only'].Id;

        Map<Schema.SObjectField, Object> userOverrides = new Map<Schema.SObjectField, Object>{
            User.FirstName => 'User Name Test',
            User.LastName => 'Without Permissions',
            User.Alias => 'ATest',
            User.Email => 'useremail@test.comm',
            User.Username =>
                String.valueof(DateTime.now().getTime()) +
                'useremail@test.comm',
            User.CommunityNickname => 'useremail@test.comm',
            User.ID_User__c =>
                'iduserTest' +
                Integer.valueof((Math.random() * 100000000))
        };

        if (overrides != null) {
            userOverrides.putAll(overrides);
        }

        User user = DMT_UTIL.createUserRecord(
            String.valueOf(profileId),
            userOverrides
        );
        return user;
    }

    public static User generateDesktopIntegrationUser() {
        return generateDesktopIntegrationUser(null);
    }

    public static User generateDesktopIntegrationUser(Map<Schema.SObjectField, Object> overrides) {
        // Targeting the profile that bypasses the Validation Rule in Opportunity 'NotBackFromApproval'
        Id profileId = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Desktop Integration'
            LIMIT 1
        ].Id;
        Long timestamp = DateTime.now().getTime();

        Map<Schema.SObjectField, Object> userOverrides = new Map<Schema.SObjectField, Object>{
            User.FirstName => 'Integration',
            User.LastName => 'User',
            User.Alias => 'DskInt',
            User.Email => 'desktop-int@test.bbva.com',
            User.Username =>
                'desktop-int' + timestamp + '@test.bbva.com',
            User.CommunityNickname =>
                'desktopint' + timestamp,
            User.ID_User__c =>
                'dsk-int-' +
                Integer.valueOf((Math.random() * 100000000))
        };

        if (overrides != null) {
            userOverrides.putAll(overrides);
        }

        User user = DMT_UTIL.createUserRecord(
            String.valueOf(profileId),
            userOverrides
        );
        return user;
    }

    public static List<DMT_Taxonomy_Values__c> generateTaxonomies() {

        Pricebook2 pb2 = generatePricebook2();

        List<DMT_Taxonomy_Values__c> taxonomies = new List<DMT_Taxonomy_Values__c>{
            DMT_UTIL.buildTaxonomyValue(
                'Project Finance Advisory',
                '2880',
                'C375',
                new Map<Schema.SObjectField, Object>{
                    DMT_Taxonomy_Values__c.DMT_Key__c => '2880'
                }
            ),
            DMT_UTIL.buildTaxonomyValue(
                'Project Finance Advisory2',
                '28802',
                'C375',
                new Map<Schema.SObjectField, Object>{
                    DMT_Taxonomy_Values__c.DMT_Key__c => '28802'
                }
            ),
            DMT_UTIL.buildTaxonomyValue(
                'Project Finance Advisory3',
                '28803',
                'C375',
                new Map<Schema.SObjectField, Object>{
                    DMT_Taxonomy_Values__c.DMT_Key__c => '28803'
                }
            ),
            DMT_UTIL.buildTaxonomyValue(
                'Others > Surety guarantee',
                '3810',
                'E895',
                new Map<Schema.SObjectField, Object>{
                    DMT_Taxonomy_Values__c.DMT_Value__c => '01'
                }
            )
        };

        insert taxonomies;

        return taxonomies;
    }

    // CIBGLOBALD-4630 - Single active taxonomy value of a catalog (e.g. a rating of catalog C204)
    public static DMT_Taxonomy_Values__c generateTaxonomyValue(String catalog, String value) {
        DMT_Taxonomy_Values__c taxonomy = DMT_UTIL.createTaxonomyValueRecord(
            value,
            catalog + '_' + value,
            catalog,
            new Map<Schema.SObjectField, Object>{
                DMT_Taxonomy_Values__c.DMT_Value__c  => value,
                DMT_Taxonomy_Values__c.DMT_Active__c => true
            }
        );
        return taxonomy;
    }

    public static DMT_Task_Approver_Relationship__c generateTaskApproverRelationship(DMT_Approver__c approver, DMT_Task_Type__c taskType) {
        DMT_Task_Approver_Relationship__c relationship = DMT_UTIL.createTaskApproverRelationshipRecord(approver.Id, taskType.Id);
        return relationship;
    }

    public static DMT_Task_Relationship__c generateTaskRelationship(DMT_Task_Type__c fromTaskType, DMT_Task_Type__c toTaskType) {
        DMT_Task_Relationship__c relationship = DMT_UTIL.createTaskRelationshipRecord(fromTaskType.Id, toTaskType.Id);
        return relationship;
    }

    public static DMT_Taxonomy_Relationship__c generateTaxonomyRelationship(DMT_Taxonomy_Values__c initialValue, DMT_Taxonomy_Values__c finalValue) {
        DMT_Taxonomy_Relationship__c relationship = DMT_UTIL.createTaxonomyRelationshipRecord(initialValue.Id, finalValue.Id);
        return relationship;
    }


    public static DMT_Taxonomy_Hierarchy__c generateTaxonomyHierarchy() {
        DMT_Taxonomy_Hierarchy__c hierarchy = DMT_UTIL.createTaxonomyHierarchyRecord();
        return hierarchy;
    }

    public static DMT_Consolidated_Line__c generateConsolidatedLine(String LineId) {
        DMT_Consolidated_Line__c cl = DMT_UTIL.createConsolidatedLineRecord(
            LineId,
            new Map<Schema.SObjectField, Object>{
                DMT_Consolidated_Line__c.gf_group_line_id__c => 'ESCD25LIN00003597ES',
                DMT_Consolidated_Line__c.g_line_template_type__c => 'TL'
            }
        );

        return cl;
    }

    public static DMT_Consolidated_Line__c generateConsolidatedLineOther(String LineId) {
        DMT_Consolidated_Line__c cl = DMT_UTIL.createConsolidatedLineRecord(
            LineId,
            new Map<Schema.SObjectField, Object>{
                DMT_Consolidated_Line__c.gf_group_line_id__c => 'ESCD25LIN00003598ES',
                DMT_Consolidated_Line__c.g_line_template_type__c => 'OL'
            }
        );

        return cl;
    }

    public static DMT_Currency_Provision__c generateCurrencyProvision(Id riskLineTermId) {
        DMT_Currency_Provision__c cp = DMT_UTIL.createCurrencyProvisionRecord(riskLineTermId);

        return cp;
    }

    public static DMT_Warranty__c generateWarranty(Id riskLineTermId) {
        DMT_Warranty__c wa = DMT_UTIL.createWarrantyRecord(riskLineTermId);

        return wa;
    }

    public static Product2 generateProduct2() {
        return generateProduct2(null);
    }

    public static Product2 generateProduct2(Map<Schema.SObjectField, Object> overrides) {
        // Preserve the existing side effect: ensure the Standard Pricebook is active.
        Pricebook2 pb2 = generatePricebook2();

        Map<Schema.SObjectField, Object> productOverrides = new Map<Schema.SObjectField, Object>{
            Product2.Family => 'DMT',
            Product2.Name => 'DMT-TEST',
            Product2.ProductCode => 'DMT-TEST'
        };

        if (overrides != null) {
            productOverrides.putAll(overrides);
        }

        return DES_UTIL.createProductRecord(productOverrides);
    }

    public static Pricebook2 generatePricebook2() {
        List<Pricebook2> pricebooks = [
            SELECT Id, IsActive
            FROM Pricebook2
            WHERE IsStandard = true
            LIMIT 1
        ];

        Pricebook2 pbStandard;

        if (pricebooks.isEmpty()) {
            pbStandard = DES_UTIL.createPricebookRecord(
                new Map<Schema.SObjectField, Object>{
                    Pricebook2.Name => 'Standard Price Book',
                    Pricebook2.IsActive => true
                }
            );
        } else {
            pbStandard = pricebooks[0];
            if (!pbStandard.IsActive) {
                pbStandard.IsActive = true;
                update pbStandard;
            }
        }
        return pbStandard;
    }

    public static PricebookEntry generatePricebookEntry(Product2 product) {
        return generatePricebookEntry(product, null);
    }

    public static PricebookEntry generatePricebookEntry(Product2 product, Map<Schema.SObjectField, Object> overrides) {
        return DES_UTIL.createPricebookEntryRecord(product.Id, overrides);
    }

    public static OpportunityLineItem generateOpportunityLineItem(Product2 product, PricebookEntry pricebookEntry, Opportunity opp) {
        return generateOpportunityLineItem(product, pricebookEntry, opp, null);
    }

    public static OpportunityLineItem generateOpportunityLineItem(Product2 product, PricebookEntry pricebookEntry, Opportunity opp, Map<Schema.SObjectField, Object> overrides) {
        Map<Schema.SObjectField, Object> opportunityLineItemOverrides = new Map<Schema.SObjectField, Object>{
            OpportunityLineItem.gf_group_priority_opportunity_id__c => '01',
            OpportunityLineItem.g_branch_id__c => 'ES0182-US',
            OpportunityLineItem.DMT_Risk_Type__c => '3000000',
            OpportunityLineItem.gf_initial_date__c => System.today(),
            OpportunityLineItem.gf_maturity_date__c =>
                System.today().addDays(365),
            OpportunityLineItem.gf_amortization_type__c => 'Bullet',
            OpportunityLineItem.gf_payment_frequency__c => 'Quarterly',
            OpportunityLineItem.DMT_Deal_Amount_Tenors__c => 200000,
            OpportunityLineItem.gf_accrual_fees_bp__c => 1,
            OpportunityLineItem.DMT_Extension_Duration_Fees__c => 1,
            OpportunityLineItem.Life_Funding_Type__c => 'Term',
            OpportunityLineItem.g_line_commitment_level_type__c =>
                'COMMITED'
        };

        if (overrides != null) {
            opportunityLineItemOverrides.putAll(overrides);
        }

        return DMT_UTIL.createOppLineItemRecord(opp.Id, product.Id, pricebookEntry.Id, opportunityLineItemOverrides);
    }

    public static OpportunityLineItem generateOpportunityLineItem(Opportunity opp) {
        return generateOpportunityLineItem(opp, null);
    }

    public static OpportunityLineItem generateOpportunityLineItem(Opportunity opp, Map<Schema.SObjectField, Object> overrides) {
        Product2 product = generateProduct2();
        PricebookEntry pricebookEntry = generatePricebookEntry(product);

        return DMT_UTIL.createOppLineItemRecord(opp.Id, product.Id, pricebookEntry.Id, overrides);
    }

    public static DMT_Opportunity_Tenor__c generateOpportunityTenor(OpportunityLineItem opportunityLineItem) {
        DMT_Opportunity_Tenor__c oppTenor = DMT_UTIL.createOpportunityTenorRecord(opportunityLineItem.Id);
        return oppTenor;
    }

    public static DMT_Opportunity_Mitigant__c generateOpportunityMitigant(OpportunityLineItem opportunityLineItem) {
        return generateOpportunityMitigant(opportunityLineItem, null);
    }

    public static DMT_Opportunity_Mitigant__c generateOpportunityMitigant(OpportunityLineItem opportunityLineItem, Map<Schema.SObjectField, Object> overrides) {
        Map<Schema.SObjectField, Object> mitigantOverrides = new Map<Schema.SObjectField, Object>{
            DMT_Opportunity_Mitigant__c.Political_Percentage__c => 1,
            DMT_Opportunity_Mitigant__c.Commercial_Percentage__c => 1
        };

        if (overrides != null) {
            mitigantOverrides.putAll(overrides);
        }

        DMT_Opportunity_Mitigant__c oppMitigant = DMT_UTIL.createOpportunityMitigantRecord(opportunityLineItem.Id, mitigantOverrides);
        return oppMitigant;
    }

    public static DMT_Selected_Features__c generateSelectedFeaturesOpp(Opportunity opp) {
        List<DMT_Feature__c> featureList = new List<DMT_Feature__c>{
            DMT_UTIL.buildFeature(
                new Map<Schema.SObjectField, Object>{
                    DMT_Feature__c.gf_capability_engine_id_number__c => '789',
                    DMT_Feature__c.gf_feature_name_desc__c => 'Feature Test Opp',
                    DMT_Feature__c.gf_feature_deal_type__c => 'TypeOPP',
                    DMT_Feature__c.gf_global_feature_id_number__c => 'GF007',
                    DMT_Feature__c.gf_approver_apply_ind_type__c => 'TestOPP',
                    DMT_Feature__c.gf_user_audit_id__c => 'UserTest3',
                    DMT_Feature__c.gf_code_value_id__c => '201'
                }
            ),
            DMT_UTIL.buildFeature(
                new Map<Schema.SObjectField, Object>{
                    DMT_Feature__c.gf_capability_engine_id_number__c => '987',
                    DMT_Feature__c.gf_feature_name_desc__c => 'Feature Test OPPB',
                    DMT_Feature__c.gf_feature_deal_type__c => 'TypeOPP2',
                    DMT_Feature__c.gf_global_feature_id_number__c => 'GF008',
                    DMT_Feature__c.gf_approver_apply_ind_type__c => 'TestOPP2',
                    DMT_Feature__c.gf_user_audit_id__c => 'UserTest4',
                    DMT_Feature__c.gf_code_value_id__c => '210'
                }
            )
        };
        insert featureList;

        DMT_Selected_Features__c selectedFeature = DMT_UTIL.createSelectedFeatureRecord(
            featureList[0].Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Selected_Features__c.Opportunity__c => opp.Id
            }
        );

        return selectedFeature;
    }

     public static DMT_X_Sell__c generatexSell(Opportunity opp) {
        DMT_X_Sell__c xsell = DMT_UTIL.createXSellRecord(opp.Id);
        return xsell;
    }

    public static void loadCurrencies() {

         DateTime today = DateTime.now();
	    String currencyDate = today.format('yyyy-MM-dd');

        Map<String, Double> currencies = new Map<String, Double>{
            'EUR' => 1.0,
            'ARS' => 800.0,
            'COP' => 4000,
            'MXN' => 18.0,
            'PEN' => 4.0,
            'USD' => 1.2,
            'UYU' => 40.0,
            'VEF' => 300000.0,
			'GBP' => 0.8
        };

        List<SER_EUR_Currency_exchange_rate__c> exRateList = new List<SER_EUR_Currency_exchange_rate__c>();
        for(String curr : currencies.keySet()) {
            SER_EUR_Currency_exchange_rate__c exRate = new SER_EUR_Currency_exchange_rate__c(
                SER_Base_currency__c = 'EUR',
                SER_Counter_currency__c = curr,
                SER_Exchange_rate__c = currencies.get(curr),
                SER_Process_date__c = Date.valueOf(currencyDate).addDays(-1),
                SER_Unlisted__c = false
            );
            exRateList.add(exRate);
        }
        insert exRateList;
    }
    public static DMT_Underlying__c generateUnderlyingRestriction(OpportunityLineItem opportunityLineItem) {
        DMT_Underlying__c underlying = DMT_UTIL.createUnderlyingRecord(opportunityLineItem.Id);
        return underlying;
    }

    public static DMT_Opportunity_Mitigant__c generateOpportunityGuarantor(OpportunityLineItem opportunityLineItem) {
        return generateOpportunityGuarantor(opportunityLineItem, null);
    }

    public static DMT_Opportunity_Mitigant__c generateOpportunityGuarantor(OpportunityLineItem opportunityLineItem, Map<Schema.SObjectField, Object> overrides) {
        Map<Schema.SObjectField, Object> guarantorOverrides = new Map<Schema.SObjectField, Object>{
            DMT_Opportunity_Mitigant__c.Mitigant_Type__c => 'Guarantee',
            DMT_Opportunity_Mitigant__c.Garantor_European_ECA__c => true,
            DMT_Opportunity_Mitigant__c.Commercial_Percentage__c => 80,
            DMT_Opportunity_Mitigant__c.Political_Percentage__c => 20,
            DMT_Opportunity_Mitigant__c.End_Date__c =>
                Date.today().addYears(1),
            DMT_Opportunity_Mitigant__c.Internal_Rating__c => 'A1',
            DMT_Opportunity_Mitigant__c.External_Rating__c => 'AA',
            DMT_Opportunity_Mitigant__c.DMT_Scoring__c => 95,
            DMT_Opportunity_Mitigant__c.SCRA__c => 'A+',
            DMT_Opportunity_Mitigant__c.AVC_Check__c => true
        };

        if (overrides != null) {
            guarantorOverrides.putAll(overrides);
        }

        DMT_Opportunity_Mitigant__c oppMitigant = DMT_UTIL.createOpportunityMitigantRecord(opportunityLineItem.Id, guarantorOverrides);
        return oppMitigant;
    }
}