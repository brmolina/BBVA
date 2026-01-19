/*********************************************************************************
* @author       Global Desktop
* @date         06/05/2019
* @description  Clase encargada de pruebas unitarias relativas al trigger de tramos
* @Revision
**********************************************************************************/
@isTest
private class ComplexProductSectionTriggerTest {

    /*
     *
     * @description Clase auxiliar tests
     **/
    private final static DES_UtilTestClass UTIL_TEST_CLASS = new DES_UtilTestClass();

    /*
     *
     * @description Literal recordtype grupos
     **/
    private final static String GROUP_RT = 'Group';

    /*
     *
     * @description Literal subsidiaria
     **/
    private final static String SUBSIDIARY = 'Subsidiary';

    /*
     *
     * @description Literal subsidiaria
     **/
    private final static String DEVTEST = 'DES_Test';

    /*
     *
     * @description Lista con recordtypes para grupo y subsidiaria
     **/
    private final static List<Recordtype> RECORDTYPE = [SELECT id, DeveloperName FROM Recordtype WHERE DeveloperName = :GROUP_RT OR DeveloperName = :SUBSIDIARY];

    /*
     *
     * @description Id cuenta filial
     **/
    private static Id accountFilialRT;

    /*
     *
     * @description Mapa con datos de objetos a usar en los diferentes test, al no poder usarse testSetup y seeAllData en la misma clase de test
     **/
    private final static Map<String,List<SObject>> MAP_TEST_DATA = fillTestData();

    /*
     *
     * @description Cuenta a usar en los diferentes test
     **/
    private final static Account ACC_FILIAL = (Account) MAP_TEST_DATA.get('accounts').get(0);

    /*
     *
     * @description Oportunidad a usar en los diferentes test
     **/
    private final static Opportunity OPP = (Opportunity) MAP_TEST_DATA.get('opps').get(0);

    /*
     *
     * @description Producto a usar en los diferentes test
     **/
    private final static OpportunityLineItem OPPLINEITEM = (OpportunityLineItem) MAP_TEST_DATA.get('ollis').get(0);

    /*
     *
     * @description Test que prueba validacion de tramos al pasar stage de la opp, y eliminacion de un tramo
     **/
    public static void productWithTranchesAndDeleteTest() {
        Test.startTest();

        insert ACC_FILIAL;

        OPP.AccountId = ACC_FILIAL.Id;
        insert OPP;

        OPPLINEITEM.OpportunityId = OPP.Id;
        insert OPPLINEITEM;

        final Product2 prd = UTIL_TEST_CLASS.createProduct('Product Test');
        insert prd;

        fprd__GBL_Product_Configuration__c pConfig;
        pConfig = new fprd__GBL_Product_Configuration__c();
        pConfig.fprd__Product__c = prd.Id;
        pConfig.fprd__DeveloperName__c = DEVTEST;
        pConfig.fprd__Version_from__c = 2;
        pConfig.fprd__Version_to__c = 2;
        insert pConfig;

        fprd__GBL_Complex_section__c cmplxSction;
        cmplxSction = new fprd__GBL_Complex_section__c();
        cmplxSction.fprd__Product_configuration__c = pConfig.Id;
        cmplxSction.fprd__DeveloperName__c = DEVTEST;
        insert cmplxSction;

        fprd__GBL_Complex_product_section__c cmplxItem;
        cmplxItem = new fprd__GBL_Complex_product_section__c();
        cmplxItem.fprd__GBL_Complex_section__c = cmplxSction.Id;
        cmplxItem.opportunity_product_tranche_desc__c = 'Term Loan A';
        cmplxItem.fprd__GBL_Opportunity_product__c = OPPLINEITEM.Id;
        cmplxItem.entity_role_type__c = 'Agent';
        cmplxItem.CurrencyIsoCode = 'USD';
        cmplxItem.pre_gross_margin_next_12m_per__c = 25;
        cmplxItem.syndicated_loan_drawn_amount__c = 1500;
        cmplxItem.deal_total_amount__c = 5000;
        cmplxItem.opening_fee_per__c = 25;
        //cmplxItem.opportunity_tenor_years_number__c = 5;
        cmplxItem.underwriting_agreement_type__c = Label.DES_YES;
        cmplxItem.underwriting_amount__c = 250;
        cmplxItem.operation_underwriting_per__c = 25;
        insert cmplxItem;
        OPP.StageName = Label.DES_Proposal;
        update OPP;
        Test.stopTest();
        OPP.StageName = Label.DES_Approvals;
        cmplxItem.fprd__GBL_Empty_visible_fields__c = 'bbva_prtcp_tranche_amount__c';
        update cmplxItem;
        try {
            update OPP;
        } catch(Exception e) {
            delete cmplxItem;
        }

        System.assertEquals(OPPLINEITEM.multi_tranche_type__c,Label.DES_YES,'productWithTranchesAndDeleteTest OK');
    }

    @isTest  //NOSONAR
    /*
     *
     * @description Test que prueba el cambio de multitranche YES a NO, eliminando ALL los tramos del producto existentes
     **/
    public static void productWithTranchesAndSwitchMultitrancheTest() {
        Test.startTest();

        insert ACC_FILIAL;

        OPP.AccountId = ACC_FILIAL.Id;
        insert OPP;

        OPPLINEITEM.OpportunityId = OPP.Id;
        insert OPPLINEITEM;
        OPPLINEITEM.multi_tranche_type__c = Label.DES_No;
        update OPPLINEITEM;
        OPPLINEITEM.multi_tranche_type__c = Label.DES_YES;
        update OPPLINEITEM;
        Test.stopTest();

        final Product2 prd = UTIL_TEST_CLASS.createProduct('Product Test');
        insert prd;

        fprd__GBL_Product_Configuration__c pConfig;
        pConfig = new fprd__GBL_Product_Configuration__c();
        pConfig.fprd__Product__c = prd.Id;
        pConfig.fprd__DeveloperName__c = DEVTEST;
        pConfig.fprd__Version_from__c = 2;
        pConfig.fprd__Version_to__c = 2;
        insert pConfig;

        fprd__GBL_Complex_section__c cmplxSction;
        cmplxSction = new fprd__GBL_Complex_section__c();
        cmplxSction.fprd__Product_configuration__c = pConfig.Id;
        cmplxSction.fprd__DeveloperName__c = DEVTEST;
        insert cmplxSction;

        fprd__GBL_Complex_product_section__c cmplxItem;
        cmplxItem = new fprd__GBL_Complex_product_section__c();
        cmplxItem.fprd__GBL_Complex_section__c = cmplxSction.Id;
        cmplxItem.opportunity_product_tranche_desc__c = 'Term Loan A';
        cmplxItem.fprd__GBL_Opportunity_product__c = OPPLINEITEM.Id;
        cmplxItem.CurrencyIsoCode = 'EUR';
        cmplxItem.pre_gross_margin_next_12m_per__c = 25;
        cmplxItem.bbva_prtcp_tranche_amount__c = 3000;
        cmplxItem.syndicated_loan_drawn_amount__c = 1500;
        cmplxItem.deal_total_amount__c = 5000;
        cmplxItem.opening_fee_per__c = 25;
        //cmplxItem.opportunity_tenor_years_number__c = 5;
        insert cmplxItem;

        System.assertEquals(Label.DES_YES,OPPLINEITEM.multi_tranche_type__c,'productWithTranchesAndSwitchMultitrancheTest OK');
    }

    /**
    *
    *
    * @description  Función auxiliar para rellenar datos de test
    */
    private static Map<String,List<SObject>> fillTestData() {
        for(Recordtype i : RECORDTYPE) {
            if(i.DeveloperName == SUBSIDIARY) {
                accountFilialRT = i.Id;
            }
        }

        final Product2 prod = UTIL_TEST_CLASS.createProduct(Label.DES_Corporate_Loans);
        insert prod;

        final PricebookEntry pBookEntry = UTIL_TEST_CLASS.createPricebookEntry(prod);
        insert pBookEntry;

        Account accFilial;
        accFilial = UTIL_TEST_CLASS.createClient();
        accFilial.Des_Main_Parent__c = accFilial.Id;
        accFilial.RecordTypeId = accountFilialRT;
        final List<Account> listAccounts = new List<Account>{accFilial};

        Opportunity opp2;
        opp2 = UTIL_TEST_CLASS.createOpportunity(accFilial);
        opp2.DES_Booking_Geography__c = 'BE';
        opp2.DES_Countries__c = 'BE';
        opp2.CurrencyIsoCode = 'EUR';
        opp2.DES_Booking_Geography__c = 'BE';
        opp2.DES_Countries__c = 'BE';
        opp2.CurrencyIsoCode = 'EUR';
        opp2.StageName = Label.DES_Draft;
        final List<Opportunity> listOpps = new List<Opportunity>{opp2};

        OpportunityLineItem oppLineItem2;
        oppLineItem2 = UTIL_TEST_CLASS.createOppLineItem(opp2, prod, pBookEntry);
        oppLineItem2.customer_cib_ind_type__c = Label.DES_YES;
        oppLineItem2.multi_tranche_type__c = Label.DES_YES;
        oppLineItem2.entity_role_type__c = 'Agent';
        oppLineItem2.origin_country_name__c = 'USA';
        oppLineItem2.product_scope_type__c = 'BEC';
        final List<OpportunityLineItem> listOllis = new List<OpportunityLineItem>{oppLineItem2};

        Map<String,List<SObject>> mapTestData;
        mapTestData = new Map<String,List<SObject>>();
        mapTestData.put('accounts',listAccounts);
        mapTestData.put('opps',listOpps);
        mapTestData.put('ollis',listOllis);

        return mapTestData;
    }

}