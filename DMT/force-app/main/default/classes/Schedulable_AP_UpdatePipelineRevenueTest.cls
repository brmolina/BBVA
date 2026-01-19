/**
*FECHA          -   AUTOR           -   DESCRIPCIÓN DEL CAMBIO
*27/12/2019     -   JSS   -   Creación: Clase de test para el Batch_AP_UpdatePipelineAndRevenues y Schedulable_AP_UpdatePipelineAndRevenues
*/ 
@isTest
public without sharing class Schedulable_AP_UpdatePipelineRevenueTest {


    @isTest
    static void test_01(){
        // Inseramos datos necesarios
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        Id idGroupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Id idSubsidiaryRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Subsidiary').getRecordTypeId();        

        final acpl__AP_PeriodConfiguration__c apConfig = testClass.createAPConfig();
        insert apConfig;
        
        final Account accGroup = testClass.createClient();
        accGroup.RecordTypeId = idGroupRT;
        accGroup.DES_Structure_Type__c = 'Group';
        accGroup.DES_BBVA_Segmentation__c = 'C';
        accGroup.DES_Revenue_Update_Engloba__c = '20191031';
        insert accGroup;

        final Account accFilial = testClass.createClient();    
        accFilial.DES_Entity_Hierarchy__c = 'S';
        accFilial.DES_Main_Parent__c = accGroup.Id;
        accFilial.RecordTypeId = idSubsidiaryRT;
        accFilial.DES_Revenue_Update_Engloba__c = '20191031';
        insert accFilial;

        final Opportunity opp1 = testClass.createOpportunity(accGroup);
        opp1.DES_Booking_Geography__c = 'AR';
        insert opp1;

        Product2 pd = testClass.createProduct('Cash Management');
        insert pd;

        fprd__GBL_Product_version__c pdv = testClass.createVersionProduct(pd);
        insert pdv;

        Pricebook2 pb = testClass.createPricebook();
        insert pb;

        PricebookEntry pbe = testClass.createPricebookEntry(pd);
        insert pbe;

        OpportunityLineItem oli = testClass.createOppLineItem(opp1, pd, pbe);
        insert oli;

        final DES_Booking__c booking_1 = testClass.createBooking(accGroup, 'ARGENTINA', 'AMESUR', 444000, 'GTB', '2019');
        booking_1.SOLUTION_CATEGORY_NAME__c = 'Cash Management';
        insert booking_1;

        acpl__Account_Planning__c ap = new acpl__Account_Planning__c();
        ap.acpl__participant_id__c = accGroup.Id;
        ap.acpl__gf_mandatory_type__c = 'Optional';
        ap.acpl__gf_ap_launch_period_desc__c = '19/20';
        ap.Name = accGroup.Name + '_' + ap.acpl__gf_ap_launch_period_desc__c;
        ap.acpl__gf_account_planning_name__c = 'Full';
        ap.acpl__gf_ap_priority_type_name__c = 'Wave 1';
        ap.acpl__gf_ap_req_validation_ind_type__c = 'No';
        ap.acpl__month_number__c = 12;
        ap.acpl__gf_ap_launch_name__c = 'General period';
        ap.acpl__Group_has_PF__c	= 'No';
        ap.acpl__external_reference_id__c = 'Group test 1_19/20';
        insert ap;

        booking_1.DES_Revenues__c = 555000;
        update booking_1;

        final DES_Booking__c booking_2 = testClass.createBooking(accGroup, 'FRANCIA', 'R.EUROPA', 2220000, 'GTB', '2019');
        booking_2.SOLUTION_CATEGORY_NAME__c = 'Cash Management';
        insert booking_2;

        final DES_Booking__c booking_3 = testClass.createBooking(accGroup, 'FRANCIA', 'R.EUROPA', 3330000, 'GTB', '2018');
        booking_3.SOLUTION_CATEGORY_NAME__c = 'Cash Management';
        insert booking_3;

        final DES_Booking__c booking_4 = testClass.createBooking(accGroup, 'FRANCIA', 'R.EUROPA', 4440000, 'GTB', '2017');
        booking_4.SOLUTION_CATEGORY_NAME__c = 'Cash Management';
        insert booking_4;

        //inicio del test y validación
        Test.startTest();
            String jobId = system.schedule('Test Check', '0 0 2 * * ?', new Schedulable_AP_UpdatePipelineAndRevenues());
            System.assertNotEquals(jobId, null);
        Test.stopTest();
    }

}