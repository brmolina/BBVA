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

        Account accTest1 = new Account();
        accTest1.account_client__c='N';
        accTest1.Advising__c=false;
        accTest1.BBVA_Entity__c='BBVA SA';
        accTest1.BillingCity='MADRID';
        accTest1.BillingCountry='ES';
        accTest1.BillingPostalCode='28033';
        accTest1.BillingState='MADRID';
        accTest1.BillingStreet='AV GRAN Test DE HORTALEZA 0321';
        accTest1.CurrencyIsoCode='EUR';
        accTest1.cust_first_income_country_amount__c=4508815;
        accTest1.cust_first_income_country_name__c='ESPAÑA (2222815.0 EUR)';
        accTest1.DES_Activity__c='NDA';
        accTest1.Name='Test company 1';
        accTest1.CIB_Commercial_Prospect__c='Commercial';

        insert accTest1;

        Local_Client__c lc = new Local_Client__c(Cib_Client__c = accTest1.Id);

        insert lc;

        List<DMT_Line__c> linesInsert = new List<DMT_Line__c>();

        DMT_Line__c lineTest = new DMT_Line__c();
        lineTest.Allowed__c =false ;
        lineTest.Booking_Geography__c   ='ES' ;
        lineTest.Clearing__c    =false ;
        lineTest.Client_Code__c ='ES0182054986618' ;
        lineTest.CurrencyIsoCode    ='EUR';
        lineTest.DMT_Client_Entific__c  = 'ES';
        lineTest.DMT_Comments__c    ='Test comments' ;
        lineTest.DvP_Amount__c  = 100 ;
        lineTest.DvP_Currency__c    ='EUR' ;
        lineTest.End_Date__c    = date.newInstance(2024, 12, 21);
        lineTest.FD_Amount__c   = 100;
        lineTest.FD_Currency__c ='EUR' ;
        lineTest.Line_Id__c ='00001' ;
        lineTest.Name   ='Line Test ENERGIA FINANCIACION' ;
        lineTest.Start_Date__c  =date.newInstance(2024, 11, 21);
        lineTest.Status__c  ='Draft';
        lineTest.Treasury_Currency__c ='EUR' ;
        lineTest.Waiver__c =false;
        lineTest.Repos_Limit_6M__c=120000;
        lineTest.Repos_Limit__c=120000;
        lineTest.Client__c  = accTest1.Id;
        lineTest.RecordTypeId   = treasuryLineRecordTypeID;

        linesInsert.add(lineTest);

        DMT_Line__c lineTest2 = new DMT_Line__c();
        lineTest2.Allowed__c =false ;
        lineTest2.Booking_Geography__c   ='ES' ;
        lineTest2.Clearing__c    =false ;
        lineTest2.Client_Code__c ='ES0182054986618' ;
        lineTest2.CurrencyIsoCode    ='EUR';
        lineTest2.DMT_Client_Entific__c  = 'ES';
        lineTest2.DMT_Comments__c    ='Test comments' ;
        lineTest2.DvP_Amount__c  = 100 ;
        lineTest2.DvP_Currency__c    ='EUR' ;
        lineTest2.End_Date__c    = date.newInstance(2024, 12, 21);
        lineTest2.FD_Amount__c   = 100;
        lineTest2.FD_Currency__c ='EUR' ;
        lineTest2.Line_Id__c ='00002' ;
        lineTest2.Name   ='Line Test ENERGIA FINANCIACION' ;
        lineTest2.Start_Date__c  =date.newInstance(2024, 11, 21);
        lineTest2.Status__c  ='Draft';
        lineTest2.Treasury_Currency__c ='EUR' ;
        lineTest2.Waiver__c =false;
        lineTest2.Repos_Limit_6M__c=120000;
        lineTest2.Repos_Limit__c=120000;
        lineTest2.Client__c  = accTest1.Id;
        lineTest2.RecordTypeId   = treasuryLineRecordTypeID;
        lineTest2.DMT_Parent_Line__c = lineTest.Id;

        linesInsert.add(lineTest2);
        insert linesInsert;

        List<DMT_Feature__c> featureList = new List<DMT_Feature__c>{
            new DMT_Feature__c(
                gf_capability_engine_id_number__c = '123',
                gf_feature_name_desc__c = 'Feature Test A',
                gf_feature_deal_type__c = 'Type1',
                gf_global_feature_id_number__c = 'GF001',
                gf_approver_apply_ind_type__c = 'Test1',
                gf_user_audit_id__c = 'UserTest1',
                gf_audit_date__c = Date.today(),
                gf_code_value_id__c = '20'
            ),
            new DMT_Feature__c(
                gf_capability_engine_id_number__c = '456',
                gf_feature_name_desc__c = 'Feature Test B',
                gf_feature_deal_type__c = 'Type2',
                gf_global_feature_id_number__c = 'GF002',
                gf_approver_apply_ind_type__c = 'Test2',
                gf_user_audit_id__c = 'UserTest2',
                gf_audit_date__c = Date.today(),
                gf_code_value_id__c = '21'
            )
        };
        insert featureList;

        insert new List<DMT_Selected_Features__c>{
            new DMT_Selected_Features__c(
                Line__c = lineTest.Id,
                Feature__c = featureList[0].Id
            ),
            new DMT_Selected_Features__c(
                Line__c = lineTest2.Id,
                Feature__c = featureList[1].Id
            )
        };



        //Risk line terms
        DMT_Risk_Line_Term__c rsklt1 = new DMT_Risk_Line_Term__c();
        rsklt1.DMT_Line__c = lineTest2.Id;
        rsklt1.Name='Line test ENERGIA FINANCIACION	rsk line term 1';
        rsklt1.DMT_Init_Term__c='0';
        rsklt1.DMT_End_Term__c ='3';
        rsklt1.DMT_Amount__c   = 100000;
        rsklt1.CurrencyIsoCode ='EUR';
        rsklt1.gf_group_priority_line_id__c = '01';
        rsklt1.DMT_Risk_Type__c='Derivatives';

        List<DMT_Risk_Line_Term__c> listRsklt = new List<DMT_Risk_Line_Term__c>{rsklt1};
        insert listRsklt;

        Pricebook2 pb2 = generatePricebook2();
        //Productos
        Product2 p1 = new Product2(
            Name='DEPO',
            ProductCode='1611170000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='00',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        Product2 p2 = new Product2(
            Name='Derivatives',
            ProductCode='1600000000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='01',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        Product2 p3 = new Product2(
            Name='Equity',
            ProductCode='1610000000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='02',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        Product2 p4 = new Product2(
            Name='Repo',
            ProductCode='1611190000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='00',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        List<Product2> listProducts = new List<Product2>{p1, p2, p3, p4};
        insert listProducts;

        DMT_Line_Product_Item__c pli1 = new DMT_Line_Product_Item__c(
            Name ='Product line item DEPO',
            CurrencyIsoCode ='EUR',
            Line__c =lineTest2.Id,
            Product__c =p1.Id,
            Max_Tenor_WC__c = '7',
            DMT_DerivativeRestriction__c = true,
            DMT_DVPRestriction__c = true,
            DMT_FDRestriction__c = true,
            Product_Code_Value__c = 'DEPO'
        );

        insert pli1;

        return lineTest2;
    }

    public static DMT_Line__c generateTestOtherLines() {

        Account accTest1 = new Account();
        accTest1.account_client__c='N';
        accTest1.Advising__c=false;
        accTest1.BBVA_Entity__c='BBVA SA';
        accTest1.BillingCity='MADRID';
        accTest1.BillingCountry='ES';
        accTest1.BillingPostalCode='28033';
        accTest1.BillingState='MADRID';
        accTest1.BillingStreet='AV GRAN Test DE HORTALEZA 0321';
        accTest1.CurrencyIsoCode='EUR';
        accTest1.cust_first_income_country_amount__c=4508815;
        accTest1.cust_first_income_country_name__c='ESPAÑA (2222815.0 EUR)';
        accTest1.DES_Activity__c='Electric Power Generation';
        accTest1.Name='Test company 1';

        insert accTest1;

        Account accTest1Update = [SELECT Id FROM Account LIMIT 1];

        Local_Client__c lc = new Local_Client__c(Cib_Client__c = accTest1.Id);

        insert lc;

        DMT_Line__c lineTest = new DMT_Line__c();
        lineTest.Allowed__c =false ;
        lineTest.Booking_Geography__c   ='ES' ;
        lineTest.Clearing__c    =false ;
        lineTest.Client_Code__c ='ES0182054986618' ;
        lineTest.CurrencyIsoCode    ='EUR';
        lineTest.DMT_Client_Entific__c  = 'ES';
        lineTest.DMT_Comments__c    ='Test comments' ;
        lineTest.DvP_Amount__c  = 100 ;
        lineTest.DvP_Currency__c    ='EUR' ;
        lineTest.End_Date__c    = date.newInstance(2024, 12, 21);
        lineTest.FD_Amount__c   = 100;
        lineTest.FD_Currency__c ='EUR' ;
        lineTest.Line_Id__c ='00003' ;
        lineTest.Name   ='Line Test ENERGIA FINANCIACION' ;
        lineTest.Start_Date__c  =date.newInstance(2024, 11, 21);
        lineTest.Status__c  ='Draft';
        lineTest.Treasury_Currency__c ='EUR' ;
        lineTest.Waiver__c =false;
        lineTest.Repos_Limit_6M__c=120000;
        lineTest.Repos_Limit__c=120000;
        lineTest.DMT_LastLevelId__c = '61000';
        lineTest.Amount__c = 1000;

        lineTest.Client__c  = accTest1Update.Id;
        lineTest.RecordTypeId   = otherLineRecordTypeID;

        insert lineTest;
        List<DMT_Feature__c> featureList = new List<DMT_Feature__c>{
            new DMT_Feature__c(
                gf_capability_engine_id_number__c = '999',
                gf_feature_name_desc__c = 'Feature Test C',
                gf_feature_deal_type__c = 'Type3',
                gf_global_feature_id_number__c = 'GF003',
                gf_approver_apply_ind_type__c = 'Test3',
                gf_user_audit_id__c = 'UserTest',
                gf_audit_date__c = Date.today(),
                gf_code_value_id__c = '22'
            )
        };
        insert featureList;

        insert new List<DMT_Selected_Features__c>{
            new DMT_Selected_Features__c(
                Line__c = lineTest.Id,
                Feature__c = featureList[0].Id
            )
        };

        Pricebook2 pb2 = generatePricebook2();
         //Productos
        Product2 p1 = new Product2(
            Name='DEPO',
            ProductCode='2611170000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='00',
            CurrencyIsoCode='EUR',
            family='DMT Lines');


        List<Product2> listProducts = new List<Product2>{p1};
        insert listProducts;

        //Risk line terms
        DMT_Risk_Line_Term__c rsklt1 = new DMT_Risk_Line_Term__c();
        rsklt1.DMT_Line__c = lineTest.Id;
        rsklt1.Name='Line test ENERGIA FINANCIACION	rsk line term 1';
        rsklt1.DMT_Init_Term__c='0';
        rsklt1.DMT_End_Term__c ='3';
        rsklt1.DMT_Amount__c   = 100000;
        rsklt1.CurrencyIsoCode ='EUR';
        rsklt1.DMT_LastLevelId__c = '61000';
        rsklt1.DMT_Risk_Type__c='';
        rsklt1.gf_group_priority_line_id__c = '01';
        rsklt1.DMT_Product__c = p1.Id;


        List<DMT_Risk_Line_Term__c> listRsklt = new List<DMT_Risk_Line_Term__c>{rsklt1};
        insert listRsklt;



        DMT_Line_Product_Item__c pli1 = new DMT_Line_Product_Item__c(
            Name ='Product line item DEPO',
            CurrencyIsoCode ='EUR',
            Line__c =lineTest.Id,
            Product__c =p1.Id,
            Max_Tenor_WC__c = '7',
            DMT_DerivativeRestriction__c = true,
            DMT_DVPRestriction__c = true,
            DMT_FDRestriction__c = true,
            Product_Code_Value__c = 'DEPO'
        );

        insert pli1;

        return lineTest;
    }

    public static DMT_Line__c generateTestTreasurySingularLines() {

        Account accTest1 = new Account();
        accTest1.account_client__c='N';
        accTest1.Advising__c=false;
        accTest1.BBVA_Entity__c='BBVA SA';
        accTest1.BillingCity='MADRID';
        accTest1.BillingCountry='ES';
        accTest1.BillingPostalCode='28033';
        accTest1.BillingState='MADRID';
        accTest1.BillingStreet='AV GRAN Test DE HORTALEZA 0321';
        accTest1.CurrencyIsoCode='EUR';
        accTest1.cust_first_income_country_amount__c=4508815;
        accTest1.cust_first_income_country_name__c='ESPAÑA (2222815.0 EUR)';
        accTest1.DES_Activity__c='NDA';
        accTest1.Name='Test company 1';

        insert accTest1;
        Account accTest1Update = [SELECT Id FROM Account WHERE Id =: accTest1.Id LIMIT 1 FOR UPDATE];

        Local_Client__c lc = new Local_Client__c(Cib_Client__c = accTest1Update.Id);

        insert lc;

        DMT_Line__c lineTest = new DMT_Line__c();
        lineTest.Allowed__c =false ;
        lineTest.Booking_Geography__c   ='ES' ;
        lineTest.Clearing__c    =false ;
        lineTest.Client_Code__c ='ES0182054986618' ;
        lineTest.CurrencyIsoCode    ='EUR';
        lineTest.DMT_Client_Entific__c  = 'ES';
        lineTest.DMT_Comments__c    ='Test comments' ;
        lineTest.DvP_Amount__c  = 100 ;
        lineTest.DvP_Currency__c    ='EUR' ;
        lineTest.End_Date__c    = date.newInstance(2024, 12, 21);
        lineTest.FD_Amount__c   = 100;
        lineTest.FD_Currency__c ='EUR' ;
        lineTest.Line_Id__c ='00004' ;
        lineTest.Name   ='Line Test ENERGIA FINANCIACION' ;
        lineTest.Start_Date__c  =date.newInstance(2024, 11, 21);
        lineTest.Status__c  = 'Closed';
        lineTest.Closed__c = 'Won';
        lineTest.Treasury_Currency__c ='EUR' ;
        lineTest.Waiver__c =false;
        lineTest.Repos_Limit_6M__c=120000;
        lineTest.Repos_Limit__c=120000;

        lineTest.Client__c = accTest1Update.Id;
        lineTest.RecordTypeId = treasuryLineRecordTypeID;

        insert lineTest;

        DMT_Line__c lineTestUpdate = [SELECT Id FROM DMT_Line__c WHERE Id =: lineTest.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c lineTest2 = new DMT_Line__c();
        lineTest2.Allowed__c =false ;
        lineTest2.Booking_Geography__c   ='PE' ;
        lineTest2.Clearing__c    =false ;
        lineTest2.Client_Code__c ='ES0182054986618' ;
        lineTest2.CurrencyIsoCode    ='EUR';
        lineTest2.DMT_Client_Entific__c  = 'PE';
        lineTest2.DMT_Comments__c    ='Test comments' ;
        lineTest2.DvP_Amount__c  = 100 ;
        lineTest2.DvP_Currency__c    ='EUR' ;
        lineTest2.End_Date__c    = date.newInstance(2024, 12, 21);
        lineTest2.FD_Amount__c   = 100;
        lineTest2.FD_Currency__c ='EUR' ;
        lineTest2.Line_Id__c ='00005' ;
        lineTest2.Name   ='Line Test ENERGIA FINANCIACION' ;
        lineTest2.Start_Date__c  =date.newInstance(2024, 11, 21);
        lineTest2.Status__c  ='Closed';
        lineTest2.Closed__c  ='Won';
        lineTest2.Treasury_Currency__c ='EUR' ;
        lineTest2.Waiver__c =false;
        lineTest2.Repos_Limit_6M__c=120000;
        lineTest2.Repos_Limit__c=120000;

        lineTest2.Client__c  = accTest1Update.Id;
        lineTest2.RecordTypeId   = treasuryLineRecordTypeID;
        lineTest2.DMT_Parent_Line__c = lineTest.Id;

        insert lineTest2;

        DMT_Line__c lineTest2Update = [SELECT Id FROM DMT_Line__c WHERE Id =: lineTest2.Id LIMIT 1 FOR UPDATE];

        //Risk line terms
        DMT_Risk_Line_Term__c rsklt1 = new DMT_Risk_Line_Term__c();
        rsklt1.DMT_Line__c =lineTest2Update.Id;
        rsklt1.Name='Line test ENERGIA FINANCIACION	rsk line term 1';
        rsklt1.DMT_Init_Term__c='0';
        rsklt1.DMT_End_Term__c ='3';
        rsklt1.DMT_Amount__c   = 100000;
        rsklt1.CurrencyIsoCode ='EUR';
        rsklt1.DMT_Risk_Type__c='Derivatives';

        DMT_Risk_Line_Term__c rsklt2 = new DMT_Risk_Line_Term__c();
        rsklt2.DMT_Line__c =lineTest2Update.Id;
        rsklt2.Name='Line test ENERGIA FINANCIACION	rsk line term 2';
        rsklt2.DMT_Init_Term__c='0';
        rsklt2.DMT_End_Term__c ='5';
        rsklt2.DMT_Amount__c   = 100000;
        rsklt2.CurrencyIsoCode ='EUR';
        rsklt2.DMT_Singular__c = true;
        rsklt2.DMT_Singular_Operation__c = 'Operation Name';
        rsklt2.DMT_Max_Date__c = Date.today().addDays(-1);
        rsklt2.DMT_Risk_Type__c='Derivatives';

        DMT_Risk_Line_Term__c rsklt3 = new DMT_Risk_Line_Term__c();
        rsklt3.DMT_Line__c =lineTest2Update.Id;
        rsklt3.Name='Line test ENERGIA FINANCIACION	rsk line term 3';
        rsklt3.DMT_Init_Term__c='0';
        rsklt3.DMT_End_Term__c ='7';
        rsklt3.DMT_Amount__c   = 100000;
        rsklt3.CurrencyIsoCode ='EUR';
        rsklt3.DMT_Risk_Type__c='Depos';

        DMT_Risk_Line_Term__c rsklt4 = new DMT_Risk_Line_Term__c();
        rsklt4.DMT_Line__c =lineTest2Update.Id;
        rsklt4.Name='Line test ENERGIA FINANCIACION	rsk line term 4';
        rsklt4.DMT_Init_Term__c='0';
        rsklt4.DMT_End_Term__c ='9';
        rsklt4.DMT_Amount__c   = 10000;
        rsklt4.CurrencyIsoCode ='EUR';
        rsklt4.DMT_Risk_Type__c='Depos';

        DMT_Risk_Line_Term__c rsklt5 = new DMT_Risk_Line_Term__c();
        rsklt5.DMT_Line__c =lineTest2Update.Id;
        rsklt5.Name='Line test ENERGIA FINANCIACION	rsk line term 5';
        rsklt5.DMT_Init_Term__c='0';
        rsklt5.DMT_End_Term__c ='6';
        rsklt5.DMT_Amount__c   = 10000;
        rsklt5.CurrencyIsoCode ='EUR';
        rsklt5.DMT_Risk_Type__c='Equities';

        DMT_Risk_Line_Term__c rsklt6 = new DMT_Risk_Line_Term__c();
        rsklt6.DMT_Line__c = lineTest2Update.Id;
        rsklt6.Name='Line test ENERGIA FINANCIACION	rsk line term 6';
        rsklt6.DMT_Init_Term__c='6';
        rsklt6.DMT_End_Term__c ='30';
        rsklt6.DMT_Amount__c   = 1000000;
        rsklt6.CurrencyIsoCode ='EUR';
        rsklt6.DMT_Risk_Type__c='Equities';

        List<DMT_Risk_Line_Term__c> listRsklt = new List<DMT_Risk_Line_Term__c>{rsklt1,rsklt2,rsklt3,rsklt4,rsklt5,rsklt6};
        insert listRsklt;

        Pricebook2 pb2 = generatePricebook2();
        //Productos
        Product2 p1 = new Product2(
            Name='DEPO',
            ProductCode='1611170000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='00',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        Product2 p2 = new Product2(
            Name='Derivatives',
            ProductCode='1600000000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='01',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        Product2 p3 = new Product2(
            Name='Equity',
            ProductCode='1610000000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='02',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        Product2 p4 = new Product2(
            Name='Repo',
            ProductCode='1611190000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='03',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        Product2 p5 = new Product2(
            Name='Repo',
            ProductCode='1647895623',
            DMT_Global_Product_Id__c='04',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        List<Product2> listProducts = new List<Product2>{p1,p2,p3,p4,p5};

        insert listProducts;

        DMT_Line_Product_Item__c pli1 = new DMT_Line_Product_Item__c(
            Name ='Product line item DEPO',
            CurrencyIsoCode ='EUR',
            Line__c =lineTest2.Id,
            Product__c =p1.Id,
            Max_Tenor_WC__c = '7',
            DMT_DerivativeRestriction__c = true,
            DMT_DVPRestriction__c = true,
            DMT_FDRestriction__c = true,
            Product_Code_Value__c = 'DEPO'
        );

        insert pli1;

        return lineTest2Update;
    }


    public static Account generateAccount() {
        Account accTest1 = new Account();
        accTest1.account_client__c='N';
        accTest1.Advising__c=false;
        accTest1.BBVA_Entity__c='BBVA SA';
        accTest1.BillingCity='MADRID';
        accTest1.BillingCountry='ES';
        accTest1.BillingPostalCode='28033';
        accTest1.BillingState='MADRID';
        accTest1.BillingStreet='AV GRAN Test DE HORTALEZA 0321';
        accTest1.CurrencyIsoCode='EUR';
        accTest1.cust_first_income_country_amount__c=4508815;
        accTest1.cust_first_income_country_name__c='ESPAÑA (2222815.0 EUR)';
        accTest1.DES_Activity__c='NDA';
        accTest1.Name='Test company 1';
        accTest1.Past2_FY_Corp_Synd_Lending_amount__c = 13;
        accTest1.Revenues_Last_Year_number__c = 13;
        accTest1.DES_Group_Code__c = 'G20180109100427';

        insert accTest1;
        Account accTest1Update = [SELECT Id FROM Account WHERE Id =: accTest1.Id LIMIT 1 FOR UPDATE];
        return accTest1Update;
    }

    public static Opportunity generateOpportunity() {
        Account testAcc = generateAccount();

        Opportunity testOpportunity = new Opportunity();
        testOpportunity.StageName = 'Draft Opp';
        testOpportunity.CloseDate = Date.today();
        testOpportunity.Name = 'Test Opp';
        testOpportunity.AccountId = testAcc.Id;
        testOpportunity.DMT_Opp_Id__c = '00001';
        testOpportunity.RecordTypeId = opportunityRecordTypeID;
        testOpportunity.DMT_Entity__c = 'ES0182';
        testOpportunity.DMT_CUR_Notional_Amount__c = 100;
        testOpportunity.DMT_DATE_Initial_Date__c = Date.today();
        testOpportunity.DMT_DATE_Maturity_Date__c = Date.today() + 1;

        insert testOpportunity;
        Opportunity testOpportunityUpdate = [SELECT Id,AccountId FROM Opportunity WHERE Id =: testOpportunity.Id LIMIT 1 FOR UPDATE];
        return testOpportunityUpdate;
    }

    public static DMT_Opportunity_Client__c generateOpportunityClient(String oppId) {

        DMT_Opportunity_Client__c oppCl = new DMT_Opportunity_Client__c();
        oppCl.DMT_MDE_Opportunity__c = oppId;
        oppCl.Past2_FY_Corp_Synd_Lending_amount__c = 14;
        oppCl.Revenues_Last_Year_number__c = 14;
        oppCl.g_upd_lmscl_internal_ratg_type__c = 'AAA';
        oppCl.External_Rating__c = 'NR';
        oppCl.DMT_Subsector__c = 'ID';
        oppCl.DMT_Sector__c = 'I';
        oppCl.DMT_Activity__c = 'LBB';
        oppCl.Counterpart__c = 'Pub Inst';
        oppCl.SCRA__c = 'AA-';
        oppCl.AVC_Check__c = true ;
        oppCl.European_Bank_Check__c = true ;
        oppCl.Group_Sales_Check__c = true;

        insert oppCl;
        DMT_Opportunity_Client__c oppClUpdate = [SELECT Id FROM DMT_Opportunity_Client__c WHERE Id =: oppCl.Id LIMIT 1 FOR UPDATE];
        return oppClUpdate;
    }

    public static List<DMT_Global_Structure__c> generateOppGlobalStructure(String oppId) {
        List<DMT_Global_Structure__c> gsList = new List<DMT_Global_Structure__c>();

        // 8 records of Uses
        for(Integer i = 0; i < 8; i++) {
            DMT_Global_Structure__c gs = new DMT_Global_Structure__c();
            gs.Name = 'Uses ' + i;
            gs.DMT_Opportunity__c = oppId;
            gs.DMT_Type__c = 'Uses';
            gs.DMT_Funds__c = Integer.valueof((Math.random() * 10000)); // Random number
            gsList.add(gs);
        }

        // 4 records of Funding Debt
        for(Integer i = 0; i < 4; i++) {
            DMT_Global_Structure__c gs = new DMT_Global_Structure__c();
            gs.Name = 'Debt Fund ' + i;
            gs.DMT_Opportunity__c = oppId;
            gs.DMT_Type__c = 'Funding Debt';
            gs.DMT_Funds__c = Integer.valueof((Math.random() * 10000));
            gsList.add(gs);
        }

        // 4 records of Funding Equity
        for(Integer i = 0; i < 4; i++) {
            DMT_Global_Structure__c gs = new DMT_Global_Structure__c();
            gs.Name = 'Equity Fund ' + i;
            gs.DMT_Opportunity__c = oppId;
            gs.DMT_Type__c = 'Funding Equity';
            gs.DMT_Funds__c = Integer.valueof((Math.random() * 10000));
            gsList.add(gs);
        }

        insert gsList;
        return gsList;
    }

    public static void generateTestSanctionLines(){

        Account accTest1 = new Account();
        accTest1.account_client__c='N';
        accTest1.Advising__c=false;
        accTest1.BBVA_Entity__c='BBVA SA';
        accTest1.BillingCity='MADRID';
        accTest1.BillingCountry='ES';
        accTest1.BillingPostalCode='28033';
        accTest1.BillingState='MADRID';
        accTest1.BillingStreet='AV GRAN Test DE HORTALEZA 0321';
        accTest1.CurrencyIsoCode='EUR';
        accTest1.cust_first_income_country_amount__c=4508815;
        accTest1.cust_first_income_country_name__c='ESPAÑA (2222815.0 EUR)';
        accTest1.DES_Activity__c='NDA';
        accTest1.Name='Test company 1';
        accTest1.DES_Structure_Type__c = 'Subsidiary';

        insert accTest1;
        Account accTest1Update = [SELECT Id FROM Account WHERE Id =: accTest1.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c testLine = new DMT_Line__c(
                Name = 'Test Line ',
                Status__c = 'Draft',
                Client__c = accTest1Update.Id,
                Line_Id__c ='00009' ,
                DMT_Origin__c = 'AMIWEB',
                g_line_status_type__c = 'AP',
                Booking_Geography__c = 'ES' ,
                DMT_Client_Entific__c = 'ES',
                RecordTypeId = otherLineRecordTypeID,
                Client_Code__c = 'G00000000000201'
            );

        insert testLine;
        DMT_Line__c testLineUpdate = [SELECT Id FROM DMT_Line__c WHERE Id =: testLine.Id LIMIT 1 FOR UPDATE];

        Pricebook2 pb2 = generatePricebook2();

        Product2 p1 = new Product2(
            Name='DEPO',
            ProductCode='1611170000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='00',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        Product2 p2 = new Product2(
            Name='Derivatives',
            ProductCode='1600000000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='01',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        Product2 p3 = new Product2(
            Name='Equity',
            ProductCode='1610000000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='02',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        List<Product2> listProducts = new List<Product2>{p1,p2,p3};

        insert listProducts;

        DMT_Risk_Line_Term__c rsklt1 = new DMT_Risk_Line_Term__c();
        rsklt1.DMT_Line__c =testLineUpdate.Id;
        rsklt1.Name='Line test ENERGIA FINANCIACION	rsk line term 1';
        rsklt1.DMT_Init_Term__c='0';
        rsklt1.DMT_End_Term__c ='3';
        rsklt1.DMT_Amount__c   = 1000000;
        rsklt1.CurrencyIsoCode = 'EUR';
        rsklt1.DMT_Product__c = p1.Id;
        rsklt1.DMT_LastLevelId__c = '20';

        DMT_Risk_Line_Term__c rsklt2 = new DMT_Risk_Line_Term__c();
        rsklt2.DMT_Line__c =testLineUpdate.Id;
        rsklt2.Name='Line test ENERGIA FINANCIACION	rsk line term 2';
        rsklt2.DMT_Init_Term__c='0';
        rsklt2.DMT_End_Term__c ='5';
        rsklt2.DMT_Amount__c   = 100000;
        rsklt2.CurrencyIsoCode ='EUR';
        rsklt2.DMT_Product__c =  p2.Id;
        rsklt2.DMT_LastLevelId__c = '30';

        DMT_Risk_Line_Term__c rsklt3 = new DMT_Risk_Line_Term__c();
        rsklt3.DMT_Line__c =testLineUpdate.Id;
        rsklt3.Name='Line test ENERGIA FINANCIACION	rsk line term 3';
        rsklt3.DMT_Init_Term__c='0';
        rsklt3.DMT_End_Term__c ='7';
        rsklt3.DMT_Amount__c   = 1000000;
        rsklt3.CurrencyIsoCode ='EUR';
        rsklt3.DMT_Product__c = p3.Id;
        rsklt3.DMT_LastLevelId__c = '40';

        List<DMT_Risk_Line_Term__c> listRsklt = new List<DMT_Risk_Line_Term__c>{rsklt1,rsklt2,rsklt3};

        insert listRsklt;
    }
    public static void generateTestRiskApprovalLines(Id accountId){

        DMT_Line__c testLine = new DMT_Line__c(
                Name = 'Test Line ',
                Status__c = 'Draft',
                Client__c = accountId,
                Line_Id__c ='00089' ,
                Allowed__c = true ,
                DMT_Origin__c = 'Salesforce',
                g_line_status_type__c = 'AP',
                Booking_Geography__c = 'ES' ,
                DMT_Client_Entific__c = 'ES',
                RecordTypeId = riskApprovalLineRecordTypeID,
                Client_Code__c = 'G00000000000201'
            );

        insert testLine;

        Pricebook2 pb2 = generatePricebook2();

        Product2 p1 = new Product2(
            Name='DEPO',
            ProductCode='1611170000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='00',
            CurrencyIsoCode='EUR',
            family='DMT Lines');
        List<Product2> listProducts = new List<Product2>{p1};

        insert listProducts;

        DMT_Risk_Line_Term__c rsklt1 = new DMT_Risk_Line_Term__c();
        rsklt1.DMT_Line__c =testLine.Id;
        rsklt1.Name='Line test ENERGIA FINANCIACION	rsk line term 1';
        rsklt1.DMT_Init_Term__c='0';
        rsklt1.DMT_End_Term__c ='3';
        rsklt1.DMT_Amount__c   = 1000000;
        rsklt1.CurrencyIsoCode = 'EUR';
        rsklt1.DMT_Product__c = p1.Id;
        rsklt1.DMT_LastLevelId__c = '20';

        insert rsklt1;
    }
    
    public static void generateTestRiskApprovalLines(){

        Account accTest1 = new Account();
        accTest1.account_client__c='N';
        accTest1.Advising__c=false;
        accTest1.BBVA_Entity__c='BBVA SA';
        accTest1.BillingCity='MADRID';
        accTest1.BillingCountry='ES';
        accTest1.BillingPostalCode='28033';
        accTest1.BillingState='MADRID';
        accTest1.BillingStreet='AV GRAN Test DE HORTALEZA 0321';
        accTest1.CurrencyIsoCode='EUR';
        accTest1.cust_first_income_country_amount__c=4508815;
        accTest1.cust_first_income_country_name__c='ESPAÑA (2222815.0 EUR)';
        accTest1.DES_Activity__c='NDA';
        accTest1.Name='Test company 1';
        accTest1.DES_Structure_Type__c = 'Subsidiary';

        insert accTest1;
        Account accTest1Update = [SELECT Id FROM Account WHERE Id =: accTest1.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c testLine = new DMT_Line__c(
                Name = 'Test Line ',
                Status__c = 'Draft',
                Client__c = accTest1Update.Id,
                Line_Id__c ='00089' ,
                Allowed__c = true ,
                DMT_Origin__c = 'Salesforce',
                g_line_status_type__c = 'AP',
                Booking_Geography__c = 'ES' ,
                DMT_Client_Entific__c = 'ES',
                RecordTypeId = riskApprovalLineRecordTypeID,
                Client_Code__c = 'G00000000000201'
            );

        insert testLine;
        DMT_Line__c testLineUpdate = [SELECT Id FROM DMT_Line__c WHERE Id =: testLine.Id LIMIT 1 FOR UPDATE];

        Pricebook2 pb2 = generatePricebook2();

        Product2 p1 = new Product2(
            Name='DEPO',
            ProductCode='1611170000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='00',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        Product2 p2 = new Product2(
            Name='Derivatives',
            ProductCode='1600000000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='01',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        Product2 p3 = new Product2(
            Name='Equity',
            ProductCode='1610000000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='02',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        List<Product2> listProducts = new List<Product2>{p1,p2,p3};

        insert listProducts;

        DMT_Risk_Line_Term__c rsklt1 = new DMT_Risk_Line_Term__c();
        rsklt1.DMT_Line__c =testLineUpdate.Id;
        rsklt1.Name='Line test ENERGIA FINANCIACION	rsk line term 1';
        rsklt1.DMT_Init_Term__c='0';
        rsklt1.DMT_End_Term__c ='3';
        rsklt1.DMT_Amount__c   = 1000000;
        rsklt1.CurrencyIsoCode = 'EUR';
        rsklt1.DMT_Product__c = p1.Id;
        rsklt1.DMT_LastLevelId__c = '20';

        DMT_Risk_Line_Term__c rsklt2 = new DMT_Risk_Line_Term__c();
        rsklt2.DMT_Line__c =testLineUpdate.Id;
        rsklt2.Name='Line test ENERGIA FINANCIACION	rsk line term 2';
        rsklt2.DMT_Init_Term__c='0';
        rsklt2.DMT_End_Term__c ='5';
        rsklt2.DMT_Amount__c   = 100000;
        rsklt2.CurrencyIsoCode ='EUR';
        rsklt2.DMT_Product__c =  p2.Id;
        rsklt2.DMT_LastLevelId__c = '30';

        DMT_Risk_Line_Term__c rsklt3 = new DMT_Risk_Line_Term__c();
        rsklt3.DMT_Line__c =testLineUpdate.Id;
        rsklt3.Name='Line test ENERGIA FINANCIACION	rsk line term 3';
        rsklt3.DMT_Init_Term__c='0';
        rsklt3.DMT_End_Term__c ='7';
        rsklt3.DMT_Amount__c   = 1000000;
        rsklt3.CurrencyIsoCode ='EUR';
        rsklt3.DMT_Product__c = p3.Id;
        rsklt3.DMT_LastLevelId__c = '40';

        List<DMT_Risk_Line_Term__c> listRsklt = new List<DMT_Risk_Line_Term__c>{rsklt1,rsklt2,rsklt3};

        insert listRsklt;
    }


    public static DMT_Approver__c generateApprover() {
        DMT_Approver__c approver = new DMT_Approver__c();
        approver.Name = 'TestApproverDataFactory';
        approver.DMT_External_Id__c = 'TestExternalIdDATAFACTORY' + Integer.valueof((Math.random() * 100000000));
        approver.DMT_Approver_Code__c = '12222233134';
        insert approver;

        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }
    public static DMT_Approver_Type__c generateApproverTypeRisk() {
        DMT_Approver_Type__c  approverType = new DMT_Approver_Type__c ();
        approverType.Name = DMT_Constants.APPROVER_TYPE_RISK;
        approverType.DMT_External_Id__c = '1';
        insert approverType;

        DMT_Approver_Type__c approverTypeUpdate = [SELECT Id FROM DMT_Approver_Type__c WHERE Id =: approverType.Id LIMIT 1 FOR UPDATE];
        return approverTypeUpdate;
    }

    public static DMT_Approver_Type__c generateApproverTypeBusiness() {
        DMT_Approver_Type__c  approverType = new DMT_Approver_Type__c ();
        approverType.Name = DMT_Constants.APPROVER_TYPE_BUSINESS;
        approverType.DMT_External_Id__c = '32';
        insert approverType;
        System.debug('**** Approver type bsn In Factory: ' + approverType);
        DMT_Approver_Type__c approverTypeUpdate = [SELECT Id FROM DMT_Approver_Type__c WHERE Id =: approverType.Id LIMIT 1 FOR UPDATE];
        return approverTypeUpdate;
    }

    public static DMT_Approver__c generateApproverBussines() {
        DMT_Approver__c approver = new DMT_Approver__c();
        approver.Name = 'TestApproverDataFactoryBusiness';
        approver.DMT_External_Id__c = 'TestExternalIdDATAFACTORY32';
        approver.DMT_Approver_Code__c = '12222233135';
        approver.DMT_ApproverType__c = generateApproverTypeBusiness().Id;
        System.debug('**** Approver In Factory: ' + approver);
        insert approver;

        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }

    public static DMT_Approver__c generateApproverRisk() {
        DMT_Approver__c approver = new DMT_Approver__c();
        approver.Name = 'TestApproverDataFactoryRisk';
        approver.DMT_External_Id__c = 'TestExternalIdDATAFACTORY1';
        approver.DMT_Approver_Code__c = '12222233136';
        approver.DMT_ApproverType__c = generateApproverTypeRisk().Id;
        insert approver;

        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }

    public static DMT_Approver_Member__c generateApproverMember() {
        DMT_Approver__c approver = generateApprover();
        DMT_Approver_Member__c member = new DMT_Approver_Member__c();
        member.DMT_Access_Level__c = 'Edit';
        member.DMT_Approver__c = approver.Id;
        member.DMT_User__c = UserInfo.getUserId();
        insert member;

        DMT_Approver_Member__c memberUpdate = [SELECT Id FROM DMT_Approver_Member__c WHERE Id =: member.Id LIMIT 1 FOR UPDATE];
        return memberUpdate;
    }

    public static DMT_Approver_Member__c generateApproverMemberForUserWithUOS(Id userId, String uosCode) {
        DMT_Approver__c approver = generateApprover();
        DMT_Approver_Member__c member = new DMT_Approver_Member__c();
        member.DMT_Access_Level__c = 'Edit';
        member.DMT_Approver__c = approver.Id;
        member.DMT_User__c = userId;
        member.DMT_ApproverByUOs__c = uosCode;
        insert member;

        DMT_Approver_Member__c memberUpdate = [SELECT Id FROM DMT_Approver_Member__c WHERE Id =: member.Id LIMIT 1 FOR UPDATE];
        return memberUpdate;
    }

    public static Case generateCase(Id lineId, Id opportunityId, Id ownerId) {
        Case c = new Case();
        if (lineId != null) {
            c.DMT_Line__c = lineId;
        } else {
            c.opportunity_id__c = opportunityId;
        }
        c.DMT_Feature_Id__c = 'Test';
        c.DMT_Related_feature_name__c = 'Test1';
        c.Amount__c = 45;
        c.CurrencyIsoCode = 'EUR';
        c.Subject = 'Test Subject';
        c.DMT_ConditionsCloseCase__c = '{"dateMaximum": "2025-11-13","maximumLinePeriod": "365","maximumProductMaturity": "45000","products": ["Derivatives","Equities","Depos"],"clients": ["G00000000000200"], "derivativesAmount":"3", "dvpAmount":"3", "fdAmount":"0"}';
        c.RecordTypeId = approvalCaseRecordTypeID;
        c.OwnerId = ownerId;
        insert c;

        //Case caseUpdate = [SELECT Id FROM Case WHERE Id =: c.Id LIMIT 1 FOR UPDATE];
        return c;
    }

    public static void generatePassportCase(Id lineId, Id opportunityId, Id ownerId, Integer num) {
        List<DMT_Task_Type__c> taskTypes = generateTaskTypes();
        for (Integer i = 0; i < num; i++) {
        Case c = new Case();
        if (lineId != null) {
            c.DMT_Line__c = lineId;
        } else {
            c.opportunity_id__c = opportunityId;
        }
        c.DMT_Feature_Id__c = String.valueOf(num);
        c.DMT_Related_feature_name__c = 'Test' + String.valueOf(num);
        c.Amount__c = 100000;
        c.CurrencyIsoCode = 'EUR';
        c.Subject = 'Test Subject';
        c.DMT_ConditionsCloseCase__c = '{"dateMaximum": "2025-11-13","maximumLinePeriod": "365","maximumProductMaturity": "45000","products": ["Derivatives","Equities","Depos"],"clients": ["G00000000000200"], "derivativesAmount":"3", "dvpAmount":"3", "fdAmount":"0"}';
        c.RecordTypeId = approvalCaseRecordTypeID;
        c.OwnerId = ownerId;
        c.DMT_Passport_Sanction__c = 'passport';
        c.Status = DMT_Constants.FINISHED;
        insert c;
        Task t = new Task();
            t.OwnerId = ownerId;
            t.RecordTypeId = taskStepRecordTypeID;
            t.Status = DMT_Constants.FINISHED;
            t.Description = 'Test Description';
            t.WhatId = c.Id;
            t.Subject = 'Task' + i;
            t.DMT_Task_Type__c = taskTypes[i].Id;
            t.DMT_Step_Result__c = 'Yes';
        }

        //Case caseUpdate = [SELECT Id FROM Case WHERE Id =: c.Id LIMIT 1 FOR UPDATE];
        //return c;
    }

    public static void generateApprovalCase(Id lineId, Id opportunityId, Id ownerId, Integer num) {
        List<DMT_Task_Type__c> taskTypes = generateTaskTypes();
        for (Integer i = 0; i < num; i++) {
        Case c = new Case();
        if (lineId != null) {
            c.DMT_Line__c = lineId;
        } else {
            c.opportunity_id__c = opportunityId;
        }
        c.DMT_Feature_Id__c = String.valueOf(num);
        c.DMT_Related_feature_name__c = 'Test' + String.valueOf(num);
        c.Amount__c = 100000;
        c.CurrencyIsoCode = 'EUR';
        c.Subject = 'Test Subject';
        c.DMT_ConditionsCloseCase__c = '{"dateMaximum": "2025-11-13","maximumLinePeriod": "365","maximumProductMaturity": "45000","products": ["Derivatives","Equities","Depos"],"clients": ["G00000000000200"], "derivativesAmount":"3", "dvpAmount":"3", "fdAmount":"0"}';
        c.RecordTypeId = approvalCaseRecordTypeID;
        c.OwnerId = ownerId;
        c.DMT_Passport_Sanction__c = 'approval';
        c.Status = DMT_Constants.FINISHED;
        insert c;
        Task t = new Task();
            t.OwnerId = ownerId;
            t.RecordTypeId = taskStepRecordTypeID;
            t.Status = DMT_Constants.FINISHED;
            t.Description = 'Test Description';
            t.WhatId = c.Id;
            t.Subject = 'Task' + i;
            t.DMT_Task_Type__c = taskTypes[i].Id;
            t.DMT_Step_Result__c = 'Yes';
        }

        //Case caseUpdate = [SELECT Id FROM Case WHERE Id =: c.Id LIMIT 1 FOR UPDATE];
        //return c;
    }


    public static List<Task> generateTasksWithOwner(Id ownerId, Id recordTypeId, Id whatId, Integer numTasks) {
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < numTasks; i++) {
            Task t = new Task();
            t.OwnerId = ownerId;
            t.RecordTypeId = recordTypeId;
            t.Status = 'In Progress';
            t.Description = 'Test Description';
            t.WhatId = whatId;
            t.Subject = 'Task' + i;
            tasks.add(t);
        }

        insert tasks;

        //List<Task> tasksUpdate = [SELECT Id FROM Task WHERE Id IN :tasks FOR UPDATE];
        return tasks;
    }

    public static List<DMT_Task_Type__c> generateTaskTypes() {

        DMT_Task_Type__c tskType1 = new DMT_Task_Type__c(
            Name='Global Risk',
            CurrencyIsoCode='EUR',
            DMT_External_Id__c='1',
            DMT_Closing_Capacity__c=false,
            DMT_Yes_Flag__c='YES_YES_Global Risk',
            DMT_No_Flag__c='NO_NO_Global Risk',
            DMT_NA_Flag__c='NA_NA_Global Risk'
        );

        DMT_Task_Type__c tskType2 = new DMT_Task_Type__c(
            Name='Local Risk',
            CurrencyIsoCode='EUR',
            DMT_External_Id__c='6',
            DMT_Closing_Capacity__c=true,
            DMT_Yes_Flag__c='YES_YES_Local Risk',
            DMT_No_Flag__c='NO_NO_Local Risk',
            DMT_NA_Flag__c='NA_NA_Local Risk'
        );
        DMT_Task_Type__c tskType3 = new DMT_Task_Type__c(
            Name='Risk review 1',
            CurrencyIsoCode='EUR',
            DMT_External_Id__c='3',
            DMT_Closing_Capacity__c=false,
            DMT_Yes_Flag__c='YES_YES_Risk',
            DMT_No_Flag__c='NO_NO_Risk',
            DMT_NA_Flag__c='NA_NA_Risk'
        );

        List<DMT_Task_Type__c> taskTypes = new List<DMT_Task_Type__c>{tskType1,tskType2,tskType3};
        insert taskTypes;

        List<DMT_Task_Type__c> taskTypesUpdate = [SELECT Id FROM DMT_Task_Type__c WHERE Id IN :taskTypes LIMIT 3 FOR UPDATE];
        return taskTypesUpdate;
    }


    public static Id generateView() {

        DMT_ApproversView__c approverView = new DMT_ApproversView__c(
            Name='PruebaLinea',
            DMT_DeveloperName__c='DMT_PruebaLinea'
            );
        insert approverView;

        DMT_ApproversView__c approverViewUpdate = [SELECT Id FROM DMT_ApproversView__c WHERE Id =: approverView.Id LIMIT 1 FOR UPDATE];

        // If more items are added, remember to update the Assert on DMT_SnapshotEvaluationVersionsTest.testGetFilteredComponentItemOptionByVersionView_Positive
        DMT_Items__c item = new DMT_Items__c();
        item.Name = 'Basic client';
        item.DMT_Component_Item__c = 'Treasury Line';
        item.DMT_order_display__c = 1;
        item.DMT_Text__c = 'Esto es un texto normal';
        item.Type_Item__c = 'Component';
        item.DMT_View__c = approverViewUpdate.Id;

        DMT_Items__c item2 = new DMT_Items__c();
        item2.Name = 'Basic client2';
        item2.DMT_Component_Item__c = 'Participants';
        item2.DMT_order_display__c = 2;
        item2.DMT_Text__c = 'Esto es un texto normal';
        item2.Type_Item__c = 'Component';
        item2.DMT_View__c = approverViewUpdate.Id;

        DMT_Items__c item3 = new DMT_Items__c();
        item3.Name = 'Basic client3';
        item3.DMT_Component_Item__c = 'Client';
        item3.DMT_order_display__c = 3;
        item3.DMT_Text__c = 'Esto es un texto normal';
        item3.Type_Item__c = 'Component';
        item3.DMT_View__c = approverViewUpdate.Id;

        DMT_Items__c item4 = new DMT_Items__c();
        item4.Name = 'Basic client4';
        item4.DMT_Component_Item__c = 'Products';
        item4.DMT_order_display__c = 4;
        item4.DMT_Text__c = 'Esto es un texto normal';
        item4.Type_Item__c = 'Component';
        item4.DMT_View__c = approverViewUpdate.Id;

        insert new List<DMT_Items__c>{item, item2, item3, item4};

        return approverViewUpdate.Id;
    }


    public static DMT_Approver__c generateApproverWithView(Id approverViewId) {
        DMT_Approver__c approver = new DMT_Approver__c();
        approver.Name = 'TestApproverDataFactory';
        approver.DMT_External_Id__c = 'TestExternalIdDATAFACTORY' + Integer.valueof((Math.random() * 100000000));
        approver.DMT_Approver_Code__c = '12222233134';
        approver.Approvers_View_Treasury__c=approverViewId;
        //approver.DMT_Group__c='TestApproverDataFactory';

        insert approver;

        DMT_Approver__c approverUpdate = [SELECT Id FROM DMT_Approver__c WHERE Id =: approver.Id LIMIT 1 FOR UPDATE];
        return approverUpdate;
    }

    public static Custom_Association__c generateCustomAssociation(Id lineId, Id accountId) {

        Custom_Association__c ca = new Custom_Association__c();
        //ca.Name = 'TestCA';
        ca.Group__c = accountId;
        ca.DMT_Line__c = lineId;
        ca.gf_customer_group_id__c = 'ESCD25LIN00006610ES';
        ca.g_group_id__c = 'TestCustomerGroupId';

        insert ca;

        Custom_Association__c caUpdate = [SELECT Id FROM Custom_Association__c WHERE Id =: ca.Id LIMIT 1 FOR UPDATE];

        DMT_Line__c line = new DMT_Line__c(Id = lineId, Custom_Association__c = caUpdate.Id);
        update line;

        return caUpdate;
    }

    public static Custom_Association_Client__c generateCustomAssociationClient(Id caId) {
        Custom_Association_Client__c cac = new Custom_Association_Client__c();
        cac.alpha_code_client__c = 'ES0182000170441';
        cac.custom_association__c = caId;
        cac.Name = 'GRIFOLS S.A.';
        cac.CurrencyIsoCode = 'EUR';
        insert cac;

        return cac;
    }

    public static User generateUserWithoutPermissions() {
        User userTest = new User();
        userTest.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Read Only'].Id;
        userTest.FirstName = 'User Name Test';
        userTest.LastName = 'Without Permissions';
        userTest.Alias = 'ATest';
        userTest.Email = 'useremail@test.comm';
        userTest.username= String.valueof(DateTime.now().getTime()) + 'useremail@test.comm';
        userTest.CommunityNickname = 'useremail@test.comm';
        userTest.EmailEncodingKey = 'UTF-8';
        userTest.Timezonesidkey='Europe/London';
        userTest.Localesidkey ='en_US';
        userTest.languagelocalekey='en_US';
        userTest.ID_User__c ='iduserTest'+Integer.valueof((Math.random() * 100000000));

        insert userTest;

        return userTest;
    }

    public static List<DMT_Taxonomy_Values__c> generateTaxonomies() {

        Pricebook2 pb2 = generatePricebook2();

        List<DMT_Taxonomy_Values__c> taxonomies = new List<DMT_Taxonomy_Values__c>{
            new DMT_Taxonomy_Values__c(
                DMT_Name__c = 'Project Finance Advisory',
                DMT_Name_EN__c = 'Project Finance Advisory',
                DMT_External_Id__c = '2880',
                DMT_Key__c = '2880',
                CurrencyIsoCode = 'EUR',
                DMT_Catalog__c = 'C375'
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Name__c = 'Project Finance Advisory2',
                DMT_Name_EN__c = 'Project Finance Advisory2',
                DMT_External_Id__c = '28802',
                DMT_Key__c = '28802',
                CurrencyIsoCode = 'EUR',
                DMT_Catalog__c = 'C375'
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Name__c = 'Project Finance Advisory3',
                DMT_Name_EN__c = 'Project Finance Advisory3',
                DMT_External_Id__c = '28803',
                DMT_Key__c = '28803',
                CurrencyIsoCode = 'EUR',
                DMT_Catalog__c = 'C375'
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Name__c = 'Others > Surety guarantee',
                DMT_Name_EN__c = 'Others > Surety guarantee',
                DMT_External_Id__c = '3810',
                CurrencyIsoCode = 'EUR',
                DMT_Catalog__c = 'E895',
                DMT_Value__c = '01'
            )
        };

        insert taxonomies;

        return taxonomies;
    }

    public static DMT_Task_Approver_Relationship__c generateTaskApproverRelationship(DMT_Approver__c approver, DMT_Task_Type__c taskType) {
        DMT_Task_Approver_Relationship__c relationship = new DMT_Task_Approver_Relationship__c(
            DMT_Approver__c=approver.Id,
            DMT_Task_Type__c=taskType.Id
        );
        insert relationship;
        return relationship;
    }

    public static DMT_Task_Relationship__c generateTaskRelationship(DMT_Task_Type__c fromTaskType, DMT_Task_Type__c toTaskType) {
        DMT_Task_Relationship__c relationship = new DMT_Task_Relationship__c(
            DMT_From_Task_Type__c=fromTaskType.Id,
            DMT_To_Task_Type__c=toTaskType.Id
        );
        insert relationship;
        return relationship;
    }

    public static DMT_Taxonomy_Relationship__c generateTaxonomyRelationship(DMT_Taxonomy_Values__c initialValue, DMT_Taxonomy_Values__c finalValue) {
        DMT_Taxonomy_Relationship__c relationship = new DMT_Taxonomy_Relationship__c(
            DMT_Initial_Taxonomy_Value__c=initialValue.Id,
            DMT_Final_Taxonomy_Value__c=finalValue.Id,
            DMT_Value_Catalog_Initial__c = 'TestInitial',
            DMT_Value_Catalog_Final__c = 'TestFinal'
        );
        insert relationship;
        return relationship;
    }


    public static DMT_Taxonomy_Hierarchy__c generateTaxonomyHierarchy() {
        DMT_Taxonomy_Hierarchy__c hierarchy = new DMT_Taxonomy_Hierarchy__c(
            gf_cutoff_date__c=System.today(),
            g_hierarchy_id__c='TestId',
            gf_lvl_1_hier_catalog_val_id__c	 = 'TestValueLevel1'
        );
        insert hierarchy;
        return hierarchy;
    }

    public static DMT_Consolidated_Line__c generateConsolidatedLine(String LineId) {
        DMT_Consolidated_Line__c cl = new DMT_Consolidated_Line__c();
        cl.Line_Id__c = LineId;
        cl.gf_group_line_id__c = 'ESCD25LIN00003597ES';
        cl.gf_group_priority_line_id__c = '00';
        cl.g_entific_id__c = 'ES';
        cl.g_line_template_type__c = 'TL';
        insert cl;

        return cl;
    }

    public static DMT_Consolidated_Line__c generateConsolidatedLineOther(String LineId) {
        DMT_Consolidated_Line__c cl = new DMT_Consolidated_Line__c();
        cl.Line_Id__c = LineId;
        cl.gf_group_line_id__c = 'ESCD25LIN00003598ES';
        cl.gf_group_priority_line_id__c = '00';
        cl.g_entific_id__c = 'ES';
        cl.g_line_template_type__c = 'OL';
        insert cl;

        return cl;
    }

    public static DMT_Currency_Provision__c generateCurrencyProvision(Id riskLineTermId) {
        DMT_Currency_Provision__c cp = new DMT_Currency_Provision__c();
        cp.dmt_risk_line_term__c = riskLineTermId;
        cp.Name = 'EUR';
        cp.CurrencyIsoCode = 'EUR';
        insert cp;

        return cp;
    }

    public static DMT_Warranty__c generateWarranty(Id riskLineTermId) {
        DMT_Warranty__c wa = new DMT_Warranty__c();
        wa.dmt_risk_line_term__c = riskLineTermId;
        wa.Name = 'Others > Confort letter';
        wa.CurrencyIsoCode = 'EUR';
        insert wa;

        return wa;
    }

    public static Product2 generateProduct2() {
        Pricebook2 pb2 = generatePricebook2();
        Product2 product = new Product2();
        product.Family = 'DMT';
        product.Name = 'DMT-TEST';
        product.ProductCode = 'DMT-TEST';
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
            pbStandard = new Pricebook2(
                Name = 'Standard Price Book',
                IsActive = true
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

    public static PricebookEntry generatePricebookEntry(Product2 product) {
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pricebookEntry;
        return pricebookEntry;
    }

    public static OpportunityLineItem generateOpportunityLineItem(Product2 product,PricebookEntry pricebookEntry, Opportunity opp) {

        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            Product2Id = product.Id,
            OpportunityId = opp.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            TotalPrice = 100.00,
            g_currency_id__c='EUR'
        );
        insert opportunityLineItem;
        return opportunityLineItem;
    }

    public static OpportunityLineItem generateOpportunityLineItem(Opportunity opp) {
        Product2 product = generateProduct2();
        PricebookEntry pricebookEntry = generatePricebookEntry(product);
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            Product2Id = product.Id,
            OpportunityId = opp.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            TotalPrice = 100.00
        );
        insert opportunityLineItem;
        return opportunityLineItem;
    }

    public static DMT_Opportunity_Tenor__c generateOpportunityTenor(OpportunityLineItem opportunityLineItem) {
        DMT_Opportunity_Tenor__c oppTenor = new DMT_Opportunity_Tenor__c(
            DMT_Opportunity_Product__c = opportunityLineItem.Id
        );
        insert oppTenor;
        return oppTenor;
    }

    public static DMT_Opportunity_Mitigant__c generateOpportunityMitigant(OpportunityLineItem opportunityLineItem) {
        DMT_Opportunity_Mitigant__c oppMitigant = new DMT_Opportunity_Mitigant__c(
            DMT_Opportunity_Product__c = opportunityLineItem.Id,
            Political_Percentage__c = 1,
            Commercial_Percentage__c = 1
        );
        insert oppMitigant;
        return oppMitigant;
    }

    public static DMT_Selected_Features__c generateSelectedFeaturesOpp(Opportunity opp) {
        List<DMT_Feature__c> featureList = new List<DMT_Feature__c>{
            new DMT_Feature__c(
                gf_capability_engine_id_number__c = '789',
                gf_feature_name_desc__c = 'Feature Test Opp',
                gf_feature_deal_type__c = 'TypeOPP',
                gf_global_feature_id_number__c = 'GF007',
                gf_approver_apply_ind_type__c = 'TestOPP',
                gf_user_audit_id__c = 'UserTest3',
                gf_audit_date__c = Date.today(),
                gf_code_value_id__c = '201'
            ),
            new DMT_Feature__c(
                gf_capability_engine_id_number__c = '987',
                gf_feature_name_desc__c = 'Feature Test OPPB',
                gf_feature_deal_type__c = 'TypeOPP2',
                gf_global_feature_id_number__c = 'GF008',
                gf_approver_apply_ind_type__c = 'TestOPP2',
                gf_user_audit_id__c = 'UserTest4',
                gf_audit_date__c = Date.today(),
                gf_code_value_id__c = '210'
            )
        };
        insert featureList;

        DMT_Selected_Features__c selectedFeature = new DMT_Selected_Features__c(
            Opportunity__c = opp.Id,
            Feature__c = featureList[0].Id
        );

        insert selectedFeature;
        return selectedFeature;
    }

     public static DMT_X_Sell__c generatexSell(Opportunity opp) {
        DMT_X_Sell__c xsell = new DMT_X_Sell__c(
            Opportunity__c = opp.Id,
            Year__c = '2035'
        );
        insert xsell;
        return xsell;
    }

}