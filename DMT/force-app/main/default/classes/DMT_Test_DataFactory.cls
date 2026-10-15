/*
Autor: vido
Fecha: 2024-02-27
*/
@isTest
public with sharing class  DMT_Test_DataFactory {

    static String treasuryLineRecordTypeID = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement').getRecordTypeId();
    static String otherLineRecordTypeID = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId();
    static String riskApprovalLineRecordTypeID = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('Sanction').getRecordTypeId();
    static String approvalCaseRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(DMT_Constants.CASE_RT_APPROVAL).getRecordTypeId();
    static String taskStepRecordTypeID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();
    static String opportunityRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();

    private static final DES_UtilTestClass DES_FACTORY = new DES_UtilTestClass();


    /**
     * Builds a DMT Lines product on top of the DES Product2 defaults.
     * DML remains with the caller so existing bulk inserts are preserved.
     */
    private static Product2 buildDmtLineProduct(String productName, String productCode, String globalProductId) {
        return DMT_Test_DataFactoryBuild.buildProduct(new Map<Schema.SObjectField, Object>{
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

        Account accTest1 = DMT_Test_DataFactoryBuild.buildAccount(
            new Map<Schema.SObjectField, Object>{
                Account.CIB_Commercial_Prospect__c => 'Commercial'
            }
        );
        insert accTest1;

        List<DMT_Line__c> linesInsert = new List<DMT_Line__c>();

        DMT_Line__c lineTest = DMT_Test_DataFactoryBuild.buildLine(
            accTest1.Id,
            treasuryLineRecordTypeID,
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

        DMT_Line__c lineTest2 = DMT_Test_DataFactoryBuild.buildLine(
            accTest1.Id,
            treasuryLineRecordTypeID,
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
            DMT_Test_DataFactoryBuild.buildFeature(
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
            DMT_Test_DataFactoryBuild.buildFeature(
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
            DMT_Test_DataFactoryBuild.buildSelectedFeature(
                featureList[0].Id,
                new Map<Schema.SObjectField, Object>{
                    DMT_Selected_Features__c.Line__c => lineTest.Id
                }
            ),
            DMT_Test_DataFactoryBuild.buildSelectedFeature(
                featureList[1].Id,
                new Map<Schema.SObjectField, Object>{
                    DMT_Selected_Features__c.Line__c => lineTest2.Id
                }
            )
        };



        //Risk line terms
        DMT_Risk_Line_Term__c rsklt1 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
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

        DMT_Line_Product_Item__c pli1 = DMT_Test_DataFactoryBuild.buildLineProductItem(lineTest2.Id, p1.Id);

        insert pli1;

        return lineTest2;
    }

    public static DMT_Line__c generateTestOtherLines() {

        Account accTest1 = DMT_Test_DataFactoryBuild.buildAccount(
            new Map<Schema.SObjectField, Object>{
                Account.DES_Activity__c => 'Electric Power Generation'
            }
        );
        insert accTest1;

        Account accTest1Update = [SELECT Id FROM Account LIMIT 1];

        DMT_Line__c lineTest = DMT_Test_DataFactoryBuild.buildLine(
            accTest1Update.Id,
            otherLineRecordTypeID,
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

        insert lineTest;
        List<DMT_Feature__c> featureList = new List<DMT_Feature__c>{
            DMT_Test_DataFactoryBuild.buildFeature(
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
            DMT_Test_DataFactoryBuild.buildSelectedFeature(
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
        DMT_Risk_Line_Term__c rsklt1 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
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



        DMT_Line_Product_Item__c pli1 = DMT_Test_DataFactoryBuild.buildLineProductItem(lineTest.Id, p1.Id);

        insert pli1;

        return lineTest;
    }

    public static DMT_Line__c generateTestTreasurySingularLines() {

        Account accTest1 = DMT_Test_DataFactoryBuild.buildAccount();
        insert accTest1;
        Account accTest1Update = [SELECT Id FROM Account WHERE Id =: accTest1.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c lineTest = DMT_Test_DataFactoryBuild.buildLine(
            accTest1Update.Id,
            treasuryLineRecordTypeID,
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

        insert lineTest;

        DMT_Line__c lineTestUpdate = [SELECT Id FROM DMT_Line__c WHERE Id =: lineTest.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c lineTest2 = DMT_Test_DataFactoryBuild.buildLine(
            accTest1Update.Id,
            treasuryLineRecordTypeID,
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

        insert lineTest2;

        DMT_Line__c lineTest2Update = [SELECT Id FROM DMT_Line__c WHERE Id =: lineTest2.Id LIMIT 1 FOR UPDATE];

        //Risk line terms
        DMT_Risk_Line_Term__c rsklt1 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
            lineTest2Update.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 1',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '3',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 100000,
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => 'Derivatives'
            }
        );

        DMT_Risk_Line_Term__c rsklt2 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
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

        DMT_Risk_Line_Term__c rsklt3 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
            lineTest2Update.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 3',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '7',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 100000,
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => 'Depos'
            }
        );

        DMT_Risk_Line_Term__c rsklt4 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
            lineTest2Update.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 4',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '9',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 10000,
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => 'Depos'
            }
        );

        DMT_Risk_Line_Term__c rsklt5 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
            lineTest2Update.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.Name => 'Line test ENERGIA FINANCIACION	rsk line term 5',
                DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '6',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 10000,
                DMT_Risk_Line_Term__c.DMT_Risk_Type__c => 'Equities'
            }
        );

        DMT_Risk_Line_Term__c rsklt6 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
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

        Product2 p5 = DMT_Test_DataFactoryBuild.buildProduct(new Map<Schema.SObjectField, Object>{
            Product2.Name => 'Repo',
            Product2.ProductCode => '1647895623',
            Product2.DMT_Global_Product_Id__c => '04',
            Product2.CurrencyIsoCode => 'EUR',
            Product2.Family => 'DMT Lines'
        });

        List<Product2> listProducts = new List<Product2>{p1,p2,p3,p4,p5};

        insert listProducts;

        DMT_Line_Product_Item__c pli1 = DMT_Test_DataFactoryBuild.buildLineProductItem(lineTest2.Id, p1.Id);

        insert pli1;

        return lineTest2Update;
    }


    public static Account generateAccount() {
        return generateAccount(null);
    }

    public static Account generateAccount(
        Map<Schema.SObjectField, Object> overrides
    ) {
        Map<Schema.SObjectField, Object> accountOverrides =
            new Map<Schema.SObjectField, Object>{
                Account.Revenues_Last_Year_number__c => 13,
                Account.DES_Group_Code__c => 'G20180109100427'
            };

        // Keep intentionally disabled forever for this factory scenario.
        // accountOverrides.put(Account.Past2_FY_Corp_Synd_Lending_amount__c, 13);

        if (overrides != null) {
            accountOverrides.putAll(overrides);
        }

        Account accTest1 =
            DMT_Test_DataFactoryBuild.buildAccount(accountOverrides);
        insert accTest1;

        Account accTest1Update = [
            SELECT Id
            FROM Account
            WHERE Id = :accTest1.Id
            LIMIT 1
            FOR UPDATE
        ];

        return accTest1Update;
    }

    /**
     * Creates a DES Group Account and optionally links subsidiary Accounts
     * and a Global Banker.
     *
     * DES_UtilTestClass owns the Group/Subsidiary relationship logic.
     *
     * @param groupAccountName   Name of the Group Account.
     * @param subsidiaryAccountIds Account Ids to relate as subsidiaries.
     *                             Pass null to create the Group without subsidiaries.
     * @param globalBankerUserId User Id for the Global Banker.
     *                           Pass null when no Global Banker is required.
     */
    public static Account generateGroupAccount(
        String groupAccountName,
        Set<Id> subsidiaryAccountIds,
        Id globalBankerUserId
    ) {
        return DES_FACTORY.createGroupClient(
            groupAccountName,
            subsidiaryAccountIds,
            globalBankerUserId
        );
    }

    /**
     * Creates the standard DMT Opportunity for an existing Account.
     *
     * The Account may be a regular/subsidiary Account or a DES Group Account.
     */
    public static Opportunity generateOpportunityForAccount(
        Id accountId
    ) {
        return generateOpportunityForAccount(accountId, null);
    }

    public static Opportunity generateOpportunityForAccount(
        Id accountId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        Opportunity testOpportunity =
            DMT_Test_DataFactoryBuild.buildOpportunity(
                accountId,
                overrides
            );
        insert testOpportunity;

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
     * Backward-compatible helper.
     * Preserves the existing behavior: create a DMT Account first and then
     * create the standard DMT Opportunity for that Account.
     */
    public static Opportunity generateOpportunity() {
        return generateOpportunity(null);
    }

    public static Opportunity generateOpportunity(
        Map<Schema.SObjectField, Object> overrides
    ) {
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

    public static DMT_Opportunity_Client__c generateOpportunityClient(
        String oppId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        DMT_Opportunity_Client__c oppCl =
            DMT_Test_DataFactoryBuild.buildOpportunityClient(
                oppId,
                overrides
            );

        insert oppCl;

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
            DMT_Global_Structure__c gs = DMT_Test_DataFactoryBuild.buildGlobalStructure(
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
            DMT_Global_Structure__c gs = DMT_Test_DataFactoryBuild.buildGlobalStructure(
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
            DMT_Global_Structure__c gs = DMT_Test_DataFactoryBuild.buildGlobalStructure(
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

        Account accTest1 = DMT_Test_DataFactoryBuild.buildAccount(
            new Map<Schema.SObjectField, Object>{
                Account.DES_Structure_Type__c => 'Subsidiary'
            }
        );
        insert accTest1;
        Account accTest1Update = [SELECT Id FROM Account WHERE Id =: accTest1.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c testLine = DMT_Test_DataFactoryBuild.buildLine(
            accTest1Update.Id,
            otherLineRecordTypeID,
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

        insert testLine;
        DMT_Line__c testLineUpdate = [SELECT Id FROM DMT_Line__c WHERE Id =: testLine.Id LIMIT 1 FOR UPDATE];

        Pricebook2 pb2 = generatePricebook2();

        Product2 p1 = buildDmtLineProduct('DEPO', '1611170000', '00');

        Product2 p2 = buildDmtLineProduct('Derivatives', '1600000000', '01');

        Product2 p3 = buildDmtLineProduct('Equity', '1610000000', '02');

        List<Product2> listProducts = new List<Product2>{p1,p2,p3};

        insert listProducts;

        DMT_Risk_Line_Term__c rsklt1 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
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

        DMT_Risk_Line_Term__c rsklt2 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
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

        DMT_Risk_Line_Term__c rsklt3 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
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

        DMT_Line__c testLine = DMT_Test_DataFactoryBuild.buildLine(
            accountId,
            riskApprovalLineRecordTypeID,
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

        insert testLine;

        Pricebook2 pb2 = generatePricebook2();

        Product2 p1 = buildDmtLineProduct('DEPO', '1611170000', '00');
        List<Product2> listProducts = new List<Product2>{p1};

        insert listProducts;

        DMT_Risk_Line_Term__c rsklt1 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
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

        insert rsklt1;
    }

    public static void generateTestRiskApprovalLines(){

        Account accTest1 = DMT_Test_DataFactoryBuild.buildAccount(
            new Map<Schema.SObjectField, Object>{
                Account.DES_Structure_Type__c => 'Subsidiary'
            }
        );
        insert accTest1;
        Account accTest1Update = [SELECT Id FROM Account WHERE Id =: accTest1.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c testLine = DMT_Test_DataFactoryBuild.buildLine(
            accTest1Update.Id,
            riskApprovalLineRecordTypeID,
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

        insert testLine;
        DMT_Line__c testLineUpdate = [SELECT Id FROM DMT_Line__c WHERE Id =: testLine.Id LIMIT 1 FOR UPDATE];

        Pricebook2 pb2 = generatePricebook2();

        Product2 p1 = buildDmtLineProduct('DEPO', '1611170000', '00');

        Product2 p2 = buildDmtLineProduct('Derivatives', '1600000000', '01');

        Product2 p3 = buildDmtLineProduct('Equity', '1610000000', '02');

        List<Product2> listProducts = new List<Product2>{p1,p2,p3};

        insert listProducts;

        DMT_Risk_Line_Term__c rsklt1 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
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

        DMT_Risk_Line_Term__c rsklt2 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
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

        DMT_Risk_Line_Term__c rsklt3 = DMT_Test_DataFactoryBuild.buildRiskLineTerm(
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
        DMT_Approver__c approver = DMT_Test_DataFactoryBuild.buildApprover(
            new Map<Schema.SObjectField, Object>{
                DMT_Approver__c.Name => 'TestApproverDataFactory',
                DMT_Approver__c.DMT_External_Id__c => 'TestExternalIdDATAFACTORY' + Integer.valueof((Math.random() * 100000000)),
                DMT_Approver__c.DMT_Approver_Code__c => '12222233134'
            }
        );
        insert approver;

        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }
    public static DMT_Approver_Type__c generateApproverTypeRisk() {
        DMT_Approver_Type__c approverType = DMT_Test_DataFactoryBuild.buildApproverType(DMT_Constants.APPROVER_TYPE_RISK, '1');
        insert approverType;

        DMT_Approver_Type__c approverTypeUpdate = [SELECT Id FROM DMT_Approver_Type__c WHERE Id =: approverType.Id LIMIT 1 FOR UPDATE];
        return approverTypeUpdate;
    }

    public static DMT_Approver_Type__c generateApproverTypeBusiness() {
        DMT_Approver_Type__c approverType = DMT_Test_DataFactoryBuild.buildApproverType(DMT_Constants.APPROVER_TYPE_BUSINESS, '32');
        insert approverType;
        System.debug('**** Approver type bsn In Factory: ' + approverType);
        DMT_Approver_Type__c approverTypeUpdate = [SELECT Id FROM DMT_Approver_Type__c WHERE Id =: approverType.Id LIMIT 1 FOR UPDATE];
        return approverTypeUpdate;
    }

    public static DMT_Approver__c generateApproverBussines() {
        DMT_Approver__c approver = DMT_Test_DataFactoryBuild.buildApprover(
            new Map<Schema.SObjectField, Object>{
                DMT_Approver__c.Name => 'TestApproverDataFactoryBusiness',
                DMT_Approver__c.DMT_External_Id__c => 'TestExternalIdDATAFACTORY32',
                DMT_Approver__c.DMT_Approver_Code__c => '12222233135',
                DMT_Approver__c.DMT_ApproverType__c => generateApproverTypeBusiness().Id
            }
        );
        System.debug('**** Approver In Factory: ' + approver);
        insert approver;

        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }

    public static DMT_Approver__c generateApproverRisk() {
        DMT_Approver__c approver = DMT_Test_DataFactoryBuild.buildApprover(
            new Map<Schema.SObjectField, Object>{
                DMT_Approver__c.Name => 'TestApproverDataFactoryRisk',
                DMT_Approver__c.DMT_External_Id__c => 'TestExternalIdDATAFACTORY1',
                DMT_Approver__c.DMT_Approver_Code__c => '12222233136',
                DMT_Approver__c.DMT_ApproverType__c => generateApproverTypeRisk().Id
            }
        );
        insert approver;

        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }

    public static DMT_Approver_Member__c generateApproverMember() {
        DMT_Approver__c approver = generateApprover();
        DMT_Approver_Member__c member = DMT_Test_DataFactoryBuild.buildApproverMember(approver.Id, UserInfo.getUserId());
        insert member;

        DMT_Approver_Member__c memberUpdate = [SELECT Id FROM DMT_Approver_Member__c WHERE Id =: member.Id LIMIT 1 FOR UPDATE];
        return memberUpdate;
    }

    public static DMT_Approver_Member__c generateApproverMemberForUserWithUOS(Id userId, String uosCode) {
        DMT_Approver__c approver = generateApprover();
        DMT_Approver_Member__c member = DMT_Test_DataFactoryBuild.buildApproverMember(
            approver.Id,
            userId,
            new Map<Schema.SObjectField, Object>{
                DMT_Approver_Member__c.DMT_ApproverByUOs__c => uosCode
            }
        );
        insert member;

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

        Case c = DMT_Test_DataFactoryBuild.buildCase(
            ownerId,
            approvalCaseRecordTypeID,
            caseOverrides
        );
        insert c;

        //Case caseUpdate = [SELECT Id FROM Case WHERE Id =: c.Id LIMIT 1 FOR UPDATE];
        return c;
    }

    public static Case generateCaseOppLine(Id lineId, Id opportunityId, Id ownerId) {
        Case c = DMT_Test_DataFactoryBuild.buildCase(
            ownerId,
            approvalCaseRecordTypeID,
            new Map<Schema.SObjectField, Object>{
                Case.DMT_Line__c => lineId,
                Case.opportunity_id__c => opportunityId,
                Case.DMT_Feature_Id__c => 'Test',
                Case.DMT_Related_feature_name__c => 'Test1',
                Case.Amount__c => 45
            }
        );
        insert c;

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

        Case c = DMT_Test_DataFactoryBuild.buildCase(
            ownerId,
            approvalCaseRecordTypeID,
            caseOverrides
        );
        insert c;
        Task t = DMT_Test_DataFactoryBuild.buildTask(
            ownerId,
            taskStepRecordTypeID,
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

        Case c = DMT_Test_DataFactoryBuild.buildCase(
            ownerId,
            approvalCaseRecordTypeID,
            caseOverrides
        );
        insert c;
        Task t = DMT_Test_DataFactoryBuild.buildTask(
            ownerId,
            taskStepRecordTypeID,
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
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < numTasks; i++) {
            Task t = DMT_Test_DataFactoryBuild.buildTask(
                ownerId,
                recordTypeId,
                whatId,
                new Map<Schema.SObjectField, Object>{
                    Task.Status => 'In Progress',
                    Task.Subject => 'Task' + i
                }
            );
            tasks.add(t);
        }

        insert tasks;

        //List<Task> tasksUpdate = [SELECT Id FROM Task WHERE Id IN :tasks FOR UPDATE];
        return tasks;
    }

    public static List<DMT_Task_Type__c> generateTaskTypes() {

        DMT_Task_Type__c tskType1 = DMT_Test_DataFactoryBuild.buildTaskType(
            new Map<Schema.SObjectField, Object>{
                DMT_Task_Type__c.Name => 'Global Risk',
                DMT_Task_Type__c.DMT_External_Id__c => '1',
                DMT_Task_Type__c.DMT_Closing_Capacity__c => false,
                DMT_Task_Type__c.DMT_Yes_Flag__c => 'YES_YES_Global Risk',
                DMT_Task_Type__c.DMT_No_Flag__c => 'NO_NO_Global Risk',
                DMT_Task_Type__c.DMT_NA_Flag__c => 'NA_NA_Global Risk'
            }
        );

        DMT_Task_Type__c tskType2 = DMT_Test_DataFactoryBuild.buildTaskType(
            new Map<Schema.SObjectField, Object>{
                DMT_Task_Type__c.Name => 'Local Risk',
                DMT_Task_Type__c.DMT_External_Id__c => '6',
                DMT_Task_Type__c.DMT_Closing_Capacity__c => true,
                DMT_Task_Type__c.DMT_Yes_Flag__c => 'YES_YES_Local Risk',
                DMT_Task_Type__c.DMT_No_Flag__c => 'NO_NO_Local Risk',
                DMT_Task_Type__c.DMT_NA_Flag__c => 'NA_NA_Local Risk'
            }
        );
        DMT_Task_Type__c tskType3 = DMT_Test_DataFactoryBuild.buildTaskType(
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

        DMT_ApproversView__c approverView = DMT_Test_DataFactoryBuild.buildApproversView();
        insert approverView;

        DMT_ApproversView__c approverViewUpdate = [SELECT Id FROM DMT_ApproversView__c WHERE Id =: approverView.Id LIMIT 1 FOR UPDATE];

        // If more items are added, remember to update the Assert on DMT_SnapshotEvaluationVersionsTest.testGetFilteredComponentItemOptionByVersionView_Positive
        DMT_Items__c item = DMT_Test_DataFactoryBuild.buildItem(
            approverViewUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Items__c.Name => 'Basic client',
                DMT_Items__c.DMT_Component_Item__c => 'Treasury Line',
                DMT_Items__c.DMT_order_display__c => 1
            }
        );

        DMT_Items__c item2 = DMT_Test_DataFactoryBuild.buildItem(
            approverViewUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Items__c.Name => 'Basic client2',
                DMT_Items__c.DMT_Component_Item__c => 'Participants',
                DMT_Items__c.DMT_order_display__c => 2
            }
        );

        DMT_Items__c item3 = DMT_Test_DataFactoryBuild.buildItem(
            approverViewUpdate.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Items__c.Name => 'Basic client3',
                DMT_Items__c.DMT_Component_Item__c => 'Client',
                DMT_Items__c.DMT_order_display__c => 3
            }
        );

        DMT_Items__c item4 = DMT_Test_DataFactoryBuild.buildItem(
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
        DMT_Approver__c approver = DMT_Test_DataFactoryBuild.buildApprover(
            new Map<Schema.SObjectField, Object>{
                DMT_Approver__c.Name => 'TestApproverDataFactory',
                DMT_Approver__c.DMT_External_Id__c => 'TestExternalIdDATAFACTORY' + Integer.valueof((Math.random() * 100000000)),
                DMT_Approver__c.DMT_Approver_Code__c => '12222233134',
                DMT_Approver__c.Approvers_View_Treasury__c => approverViewId
            }
        );
        //approver.DMT_Group__c='TestApproverDataFactory';

        insert approver;

        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }

    public static Custom_Association_Opportunity__c generateCustomAssociationOpportunity(
        Id opportunityId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        Custom_Association_Opportunity__c association =
            DMT_Test_DataFactoryBuild.buildCustomAssociationOpportunity(
                opportunityId,
                overrides
            );
        insert association;
        return association;
    }

    public static DMT_Custom_Association_ClientOpportunity__c generateCustomAssociationClientOpportunity(
        Id customAssociationOpportunityId,
        Id clientId,
        Map<Schema.SObjectField, Object> overrides
    ) {
        DMT_Custom_Association_ClientOpportunity__c association =
            DMT_Test_DataFactoryBuild.buildCustomAssociationClientOpportunity(
                customAssociationOpportunityId,
                clientId,
                overrides
            );
        insert association;
        return association;
    }

    public static Local_Client__c generateLocalClient(
        Id accountId,
        String alphaCode
    ) {
        Local_Client__c localClient =
            DMT_Test_DataFactoryBuild.buildLocalClient(
                accountId,
                alphaCode
            );
        insert localClient;
        return localClient;
    }

    public static Custom_Association__c generateCustomAssociation(Id lineId, Id accountId) {

        Custom_Association__c ca = DMT_Test_DataFactoryBuild.buildCustomAssociation(
            lineId,
            accountId
        );
        //ca.Name = 'TestCA';

        insert ca;

        Custom_Association__c caUpdate = [SELECT Id FROM Custom_Association__c WHERE Id =: ca.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c line = new DMT_Line__c(Id = lineId, Custom_Association__c = caUpdate.Id);
        update line;

        return caUpdate;
    }

    public static Custom_Association_Client__c generateCustomAssociationClient(Id caId) {
        Custom_Association_Client__c cac = DMT_Test_DataFactoryBuild.buildCustomAssociationClient(caId);
        insert cac;

        return cac;
    }

    public static User generateUserWithoutPermissions() {
        return generateUserWithoutPermissions(null);
    }

    public static User generateUserWithoutPermissions(
        Map<Schema.SObjectField, Object> overrides
    ) {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Read Only'].Id;

        Map<Schema.SObjectField, Object> userOverrides =
            new Map<Schema.SObjectField, Object>{
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

        User user = DMT_Test_DataFactoryBuild.buildUser(
            String.valueOf(profileId),
            userOverrides
        );
        insert user;
        return user;
    }

    public static User generateDesktopIntegrationUser() {
        return generateDesktopIntegrationUser(null);
    }

    public static User generateDesktopIntegrationUser(
        Map<Schema.SObjectField, Object> overrides
    ) {
        // Targeting the profile that bypasses the Validation Rule in Opportunity 'NotBackFromApproval'
        Id profileId = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Desktop Integration'
            LIMIT 1
        ].Id;
        Long timestamp = DateTime.now().getTime();

        Map<Schema.SObjectField, Object> userOverrides =
            new Map<Schema.SObjectField, Object>{
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

        User user = DMT_Test_DataFactoryBuild.buildUser(
            String.valueOf(profileId),
            userOverrides
        );
        insert user;
        return user;
    }

    public static List<DMT_Taxonomy_Values__c> generateTaxonomies() {

        Pricebook2 pb2 = generatePricebook2();

        List<DMT_Taxonomy_Values__c> taxonomies = new List<DMT_Taxonomy_Values__c>{
            DMT_Test_DataFactoryBuild.buildTaxonomyValue(
                'Project Finance Advisory',
                '2880',
                'C375',
                new Map<Schema.SObjectField, Object>{
                    DMT_Taxonomy_Values__c.DMT_Key__c => '2880'
                }
            ),
            DMT_Test_DataFactoryBuild.buildTaxonomyValue(
                'Project Finance Advisory2',
                '28802',
                'C375',
                new Map<Schema.SObjectField, Object>{
                    DMT_Taxonomy_Values__c.DMT_Key__c => '28802'
                }
            ),
            DMT_Test_DataFactoryBuild.buildTaxonomyValue(
                'Project Finance Advisory3',
                '28803',
                'C375',
                new Map<Schema.SObjectField, Object>{
                    DMT_Taxonomy_Values__c.DMT_Key__c => '28803'
                }
            ),
            DMT_Test_DataFactoryBuild.buildTaxonomyValue(
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

    public static DMT_Task_Approver_Relationship__c generateTaskApproverRelationship(DMT_Approver__c approver, DMT_Task_Type__c taskType) {
        DMT_Task_Approver_Relationship__c relationship = DMT_Test_DataFactoryBuild.buildTaskApproverRelationship(approver.Id, taskType.Id);
        insert relationship;
        return relationship;
    }

    public static DMT_Task_Relationship__c generateTaskRelationship(DMT_Task_Type__c fromTaskType, DMT_Task_Type__c toTaskType) {
        DMT_Task_Relationship__c relationship = DMT_Test_DataFactoryBuild.buildTaskRelationship(fromTaskType.Id, toTaskType.Id);
        insert relationship;
        return relationship;
    }

    public static DMT_Taxonomy_Relationship__c generateTaxonomyRelationship(DMT_Taxonomy_Values__c initialValue, DMT_Taxonomy_Values__c finalValue) {
        DMT_Taxonomy_Relationship__c relationship = DMT_Test_DataFactoryBuild.buildTaxonomyRelationship(initialValue.Id, finalValue.Id);
        insert relationship;
        return relationship;
    }


    public static DMT_Taxonomy_Hierarchy__c generateTaxonomyHierarchy() {
        DMT_Taxonomy_Hierarchy__c hierarchy = DMT_Test_DataFactoryBuild.buildTaxonomyHierarchy();
        insert hierarchy;
        return hierarchy;
    }

    public static DMT_Consolidated_Line__c generateConsolidatedLine(String LineId) {
        DMT_Consolidated_Line__c cl = DMT_Test_DataFactoryBuild.buildConsolidatedLine(
            LineId,
            new Map<Schema.SObjectField, Object>{
                DMT_Consolidated_Line__c.gf_group_line_id__c => 'ESCD25LIN00003597ES',
                DMT_Consolidated_Line__c.g_line_template_type__c => 'TL'
            }
        );
        insert cl;

        return cl;
    }

    public static DMT_Consolidated_Line__c generateConsolidatedLineOther(String LineId) {
        DMT_Consolidated_Line__c cl = DMT_Test_DataFactoryBuild.buildConsolidatedLine(
            LineId,
            new Map<Schema.SObjectField, Object>{
                DMT_Consolidated_Line__c.gf_group_line_id__c => 'ESCD25LIN00003598ES',
                DMT_Consolidated_Line__c.g_line_template_type__c => 'OL'
            }
        );
        insert cl;

        return cl;
    }

    public static DMT_Currency_Provision__c generateCurrencyProvision(Id riskLineTermId) {
        DMT_Currency_Provision__c cp = DMT_Test_DataFactoryBuild.buildCurrencyProvision(riskLineTermId);
        insert cp;

        return cp;
    }

    public static DMT_Warranty__c generateWarranty(Id riskLineTermId) {
        DMT_Warranty__c wa = DMT_Test_DataFactoryBuild.buildWarranty(riskLineTermId);
        insert wa;

        return wa;
    }

    public static Product2 generateProduct2() {
        return generateProduct2(null);
    }

    public static Product2 generateProduct2(
        Map<Schema.SObjectField, Object> overrides
    ) {
        // Preserve the existing side effect: ensure the Standard Pricebook is active.
        Pricebook2 pb2 = generatePricebook2();

        Map<Schema.SObjectField, Object> productOverrides =
            new Map<Schema.SObjectField, Object>{
                Product2.Family => 'DMT',
                Product2.Name => 'DMT-TEST',
                Product2.ProductCode => 'DMT-TEST'
            };

        if (overrides != null) {
            productOverrides.putAll(overrides);
        }

        Product2 product =
            DMT_Test_DataFactoryBuild.buildProduct(productOverrides);
        insert product;
        return product;
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
            pbStandard = DMT_Test_DataFactoryBuild.buildPricebook(
                new Map<Schema.SObjectField, Object>{
                    Pricebook2.Name => 'Standard Price Book',
                    Pricebook2.IsActive => true
                }
            );
            insert pbStandard;
        } else {
            pbStandard = pricebooks[0];
            if (!pbStandard.IsActive) {
                pbStandard.IsActive = true;
                update pbStandard;
            }
        }
        return pbStandard;
    }

    public static PricebookEntry generatePricebookEntry(
        Product2 product
    ) {
        return generatePricebookEntry(product, null);
    }

    public static PricebookEntry generatePricebookEntry(
        Product2 product,
        Map<Schema.SObjectField, Object> overrides
    ) {
        PricebookEntry pricebookEntry =
            DMT_Test_DataFactoryBuild.buildPricebookEntry(
                product.Id,
                overrides
            );
        insert pricebookEntry;
        return pricebookEntry;
    }

    public static OpportunityLineItem generateOpportunityLineItem(
        Product2 product,
        PricebookEntry pricebookEntry,
        Opportunity opp
    ) {
        return generateOpportunityLineItem(
            product,
            pricebookEntry,
            opp,
            null
        );
    }

    public static OpportunityLineItem generateOpportunityLineItem(
        Product2 product,
        PricebookEntry pricebookEntry,
        Opportunity opp,
        Map<Schema.SObjectField, Object> overrides
    ) {
        Map<Schema.SObjectField, Object> opportunityLineItemOverrides =
            new Map<Schema.SObjectField, Object>{
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

        OpportunityLineItem opportunityLineItem =
            DMT_Test_DataFactoryBuild.buildOpportunityLineItem(
                opp.Id,
                product.Id,
                pricebookEntry.Id,
                opportunityLineItemOverrides
            );
        insert opportunityLineItem;
        return opportunityLineItem;
    }

    public static OpportunityLineItem generateOpportunityLineItem(
        Opportunity opp
    ) {
        return generateOpportunityLineItem(opp, null);
    }

    public static OpportunityLineItem generateOpportunityLineItem(
        Opportunity opp,
        Map<Schema.SObjectField, Object> overrides
    ) {
        Product2 product = generateProduct2();
        PricebookEntry pricebookEntry = generatePricebookEntry(product);

        OpportunityLineItem opportunityLineItem =
            DMT_Test_DataFactoryBuild.buildOpportunityLineItem(
                opp.Id,
                product.Id,
                pricebookEntry.Id,
                overrides
            );
        insert opportunityLineItem;
        return opportunityLineItem;
    }

    public static DMT_Opportunity_Tenor__c generateOpportunityTenor(OpportunityLineItem opportunityLineItem) {
        DMT_Opportunity_Tenor__c oppTenor = DMT_Test_DataFactoryBuild.buildOpportunityTenor(opportunityLineItem.Id);
        insert oppTenor;
        return oppTenor;
    }

    public static DMT_Opportunity_Mitigant__c generateOpportunityMitigant(
        OpportunityLineItem opportunityLineItem
    ) {
        return generateOpportunityMitigant(opportunityLineItem, null);
    }

    public static DMT_Opportunity_Mitigant__c generateOpportunityMitigant(
        OpportunityLineItem opportunityLineItem,
        Map<Schema.SObjectField, Object> overrides
    ) {
        Map<Schema.SObjectField, Object> mitigantOverrides =
            new Map<Schema.SObjectField, Object>{
                DMT_Opportunity_Mitigant__c.Political_Percentage__c => 1,
                DMT_Opportunity_Mitigant__c.Commercial_Percentage__c => 1
            };

        if (overrides != null) {
            mitigantOverrides.putAll(overrides);
        }

        DMT_Opportunity_Mitigant__c oppMitigant =
            DMT_Test_DataFactoryBuild.buildOpportunityMitigant(
                opportunityLineItem.Id,
                mitigantOverrides
            );
        insert oppMitigant;
        return oppMitigant;
    }

    public static DMT_Selected_Features__c generateSelectedFeaturesOpp(Opportunity opp) {
        List<DMT_Feature__c> featureList = new List<DMT_Feature__c>{
            DMT_Test_DataFactoryBuild.buildFeature(
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
            DMT_Test_DataFactoryBuild.buildFeature(
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

        DMT_Selected_Features__c selectedFeature = DMT_Test_DataFactoryBuild.buildSelectedFeature(
            featureList[0].Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Selected_Features__c.Opportunity__c => opp.Id
            }
        );

        insert selectedFeature;
        return selectedFeature;
    }

     public static DMT_X_Sell__c generatexSell(Opportunity opp) {
        DMT_X_Sell__c xsell = DMT_Test_DataFactoryBuild.buildXSell(opp.Id);
        insert xsell;
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
        DMT_Underlying__c underlying = DMT_Test_DataFactoryBuild.buildUnderlying(opportunityLineItem.Id);
        insert underlying;
        return underlying;
    }

    public static DMT_Opportunity_Mitigant__c generateOpportunityGuarantor(
        OpportunityLineItem opportunityLineItem
    ) {
        return generateOpportunityGuarantor(opportunityLineItem, null);
    }

    public static DMT_Opportunity_Mitigant__c generateOpportunityGuarantor(
        OpportunityLineItem opportunityLineItem,
        Map<Schema.SObjectField, Object> overrides
    ) {
        Map<Schema.SObjectField, Object> guarantorOverrides =
            new Map<Schema.SObjectField, Object>{
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

        DMT_Opportunity_Mitigant__c oppMitigant =
            DMT_Test_DataFactoryBuild.buildOpportunityMitigant(
                opportunityLineItem.Id,
                guarantorOverrides
            );
        insert oppMitigant;
        return oppMitigant;
    }
}