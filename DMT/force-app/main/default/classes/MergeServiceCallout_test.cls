/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-20-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
global with sharing class MergeServiceCallout_test {
    
      /*
      * CIBVAR
      */
      private static final String CIBVAR = 'C';
    
      /*
      * CIBVAR
      */
      private static final String SUBSIDIARYVAR = 'Subsidiary';
    
      /*
      * CIBVAR
      */
      private static final String TESTVAR = 'Test';

  
    @TestSetup
    static void testSetup() {
        Local_Client__c lclAcc = TestFactory.createLocalClient();
        Account testAcc1 = new Account();
        testAcc1.Name = 'grupo padre';
        testAcc1.Phone = '646171717';
        testAcc1.DES_Country_Client__c = 'ES';
        insert testAcc1;
        
        Local_Client__c lclAcc2 = TestFactory.createLocalClient();
        final List<Account> lstAccountSearch = [SELECT Id, Name, account_client__c FROM Account WHERE Id =: lclAcc2.Cib_Client__c LIMIT 1];
        System.debug('REVISAR PADRE 2 ' + lstAccountSearch);
        lstAccountSearch[0].account_client__c = 'S'; 
        lstAccountSearch[0].DES_Entity_Hierarchy__c = 'S'; 
        update lstAccountSearch;
        
        AMH_GBL_Account_Relationship__c testRelation2 = new AMH_GBL_Account_Relationship__c();
        testRelation2.AMH_Parent_Account__c = testAcc1.Id;
        testRelation2.AMH_Child_Account__c = lclAcc2.Cib_Client__c;
        testRelation2.AMH_Vision__c = 'Riesgos';
        testRelation2.DES_Main_Parent__c = 'S';
        insert testRelation2;
    }
    
    @isTest
    global static void checkService() {
        final DES_UtilTestClass tstClass = new DES_UtilTestClass();
        final Account accGrupo = tstClass.createClient();
        accGrupo.Name = 'Prospect grupo';
        accGrupo.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        insert accGrupo;
    
        final Account accCliente = tstClass.createClient();
        accCliente.Name = 'Prospect cliente';
        accCliente.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
        accCliente.participant_id__c = accGrupo.Id;
        accCliente.Website_Prospect__c = TESTVAR;
        accCliente.CIB_Commercial_Prospect__c = 'CIB';
        accCliente.DES_ID_Fiscal__c = '89960';
        insert accCliente;
    
        final Opportunity opp = tstClass.createOpportunity(accCliente);
        insert opp;
    
        final dwp_kitv__Visit__c visit = tstClass.createVisit(accCliente, null);
        insert visit;
    
        final Contact contact = tstClass.createContact(accCliente);
        insert contact;
    
        final arce__Analysis__c analysis = new arce__Analysis__c();
        analysis.name = 'test - test - test';
        insert analysis;
    
        final List<arce__Account_has_Analysis__c> listaArce = new List<arce__Account_has_Analysis__c>();
        final arce__Account_has_Analysis__c aHa = new arce__Account_has_Analysis__c();
        aHa.arce__Customer__c = accCliente.Id;
        aHa.arce__Analysis__c = analysis.Id;
        listaArce.add(aHa);
        insert listaArce;
    
        final Account acc = tstClass.createClient();
        acc.Name = 'Cliente prueba';
        acc.DES_BBVA_Segmentation__c = CIBVAR;
        acc.DES_Structure_Type__c = SUBSIDIARYVAR;
        acc.g_customer_id__c = 'client prueba';
        insert acc;
    
        final Local_Client__c lclient1 = new Local_Client__c();
        lclient1.participant_name__c = TESTVAR;
        lclient1.Cib_Client__c = acc.Id;
        lclient1.unique_id__c = TESTVAR;
        lclient1.country_id__c = 'ES';
        lclient1.g_residence_country_id__c = 'ES';
        insert lclient1;
    
        final dwp_kitv__Visit_validations_acc_cs__c   validation = new dwp_kitv__Visit_validations_acc_cs__c();
        validation.dwp_kitv__bypass__c = true;
        insert validation;
    
        final dwp_kitv__Visit_validations_lead_cs__c validation1 = new dwp_kitv__Visit_validations_lead_cs__c();
        validation1.dwp_kitv__bypass__c = true;
        insert validation1;
    
        final List<MergeServiceCallout.WrapperMerge> mgList = new List<MergeServiceCallout.WrapperMerge>();
        final MergeServiceCallout.WrapperMerge wrap = new MergeServiceCallout.WrapperMerge();
        wrap.arceList = listaArce;
        wrap.hasNoArce = false;
        wrap.idClient = acc.Id;
        wrap.idProspect = accCliente.Id;
        wrap.lClientName = lclient1.participant_name__c;
        wrap.idLocalClient =  lclient1.Id;
        mgList.add(wrap);
        
        final List<MergeServiceOracleCallout.WrapperMerge> mgList2 = new List<MergeServiceOracleCallout.WrapperMerge>();
        final MergeServiceOracleCallout.WrapperMerge wrap2 = new MergeServiceOracleCallout.WrapperMerge();
        wrap2.arceList = listaArce;
        wrap2.hasNoArce = false;
        wrap2.idClient = acc.Id;
        wrap2.idProspect = accCliente.Id;
        wrap2.lClientName = lclient1.participant_name__c;
        wrap2.idLocalClient =  lclient1.Id;
        mgList2.add(wrap2);
        
        Test.startTest();
        MergeServiceCallout.serviceCallout(mgList);
        MergeServiceOracleCallout.serviceCallout(mgList2);
        Test.stopTest();
        system.assertNotEquals(null, lclient1.id, 'not null');
    }
}