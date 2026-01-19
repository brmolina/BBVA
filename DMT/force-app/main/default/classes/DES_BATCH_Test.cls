@isTest
public class DES_BATCH_Test {

    static Local_Visit__c createVisit(){
        Local_Visit__c vis = new Local_Visit__c();
        vis.Name = 'Test Visit';
        vis.Email__c = 'test@test.com';
        vis.visit_start_date__c=system.now();
        return vis;
    }
    static OpportunityLineItem_Local__c createOpp(){
        OpportunityLineItem_Local__c opp = new OpportunityLineItem_Local__c();
        opp.Name = 'Test Opportunity';
        opp.Email__c = 'test@test.com';
        return opp;
    }
    
    @isTest
    static void deleteSBSINFOSUM(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Client__c acc = TestFactory.createLocalClient();
        	Account_Banking_System_Debt_Summary__c SBSINFOSUM = new Account_Banking_System_Debt_Summary__c();
            SBSINFOSUM.Local_Client_id__c = acc.Id;
	        insert SBSINFOSUM;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_SBS_INFORM_SUMMARY(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteACCBBVAINF(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Client__c acc = TestFactory.createLocalClient();
        	ACCOUNT_BBVA_INFORMATION__c ACCBBVAINF = new ACCOUNT_BBVA_INFORMATION__c();
            ACCBBVAINF.Local_Client_id__c = acc.Id;
	        insert ACCBBVAINF;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_ACCOUNT_BBVA_INFOR(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteACCPROF(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Client__c acc = TestFactory.createLocalClient();
        	ACCOUNT_PROFITABILITY__c ACCPROF = new ACCOUNT_PROFITABILITY__c();
            ACCPROF.Local_Client_id__c = acc.Id;
	        insert ACCPROF;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_PROFITABILITY(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteACCREN(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Client__c acc = TestFactory.createLocalClient();
        	Account_Renewals__c ACCREN = new Account_Renewals__c();
            ACCREN.Local_Client_id__c = acc.Id;
	        insert ACCREN;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Renewals(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteACCIND(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Client__c acc = TestFactory.createLocalClient();
        	ACCOUNT_INDICATOR__c ACCIND = new ACCOUNT_INDICATOR__c();
            ACCIND.Local_Client_id__c = acc.Id;
	        insert ACCIND;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_INDICATOR(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteCOMMSTRARES(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Client__c acc = TestFactory.createLocalClient();
        	ACCOUNT_COMMERCIAL_STRATEGY_RESULTS__c COMMSTRARES = new ACCOUNT_COMMERCIAL_STRATEGY_RESULTS__c();
            COMMSTRARES.Local_Client_id__c = acc.Id;
	        insert COMMSTRARES;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_COMMERCIAL_STRAT_RES(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteSBSINFO(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Client__c acc = TestFactory.createLocalClient();
        	ACCOUNT_BANKING_SYSTEM_DEBT__c SBSINFO = new ACCOUNT_BANKING_SYSTEM_DEBT__c();
            SBSINFO.Local_Client_id__c = acc.Id;
	        insert SBSINFO;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_SBS_INFORM(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteACCPAY(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Client__c acc = TestFactory.createLocalClient();
        	Account_Payroll__c ACCPAY = new Account_Payroll__c();
            ACCPAY.Local_Client_id__c = acc.Id;
	        insert ACCPAY;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Account_Payroll(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteSBSCLAS(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Client__c acc = TestFactory.createLocalClient();
        	ACCOUNT_BANKING_SYSTEM_CLASSIFICATION__c SBSCLAS = new ACCOUNT_BANKING_SYSTEM_CLASSIFICATION__c();
            SBSCLAS.Local_Client_id__c = acc.Id;
	        insert SBSCLAS;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_SBS_CLASSIF(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteACCBBVACLA(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Client__c acc = TestFactory.createLocalClient();
        	ACCOUNT_BBVA_CLASSIFICATION__c ACCBBVACLA = new ACCOUNT_BBVA_CLASSIFICATION__c();
            ACCBBVACLA.Local_Client_id__c = acc.Id;
	        insert ACCBBVACLA;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_BBVA_CLASSIF(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteCOMINTGAR(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	OpportunityLineItem_Local__c opp = createOpp();
            insert opp;
        	Commit_Inter_Garant__c COMINTGAR = new Commit_Inter_Garant__c();
            COMINTGAR.Opportunity_Product_Local_id__c = opp.Id;
	        insert COMINTGAR;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Commit_Inter_Garant(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deletePROCONLOC(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Product_Configuration_Local__c PROCONLOC = new Product_Configuration_Local__c();
            PROCONLOC.Product__c = 'Test Product';
	        insert PROCONLOC;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Product_Confi_Local(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteACTAUDDET(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
            OpportunityLineItem_Local__c opp = createOpp();
            insert opp;
        	dwp_cvad__Action_Audit__c aud = new dwp_cvad__Action_Audit__c();
        	aud.dwp_cvad__action_audit_name__c = 'Test Audit';
            aud.dwp_cvad__action_audit_object_api_name__c = 'OpportunityLineItem_Local__c';
            aud.dwp_cvad__action_audit_record_id__c = opp.Id;
            aud.dwp_cvad__action_audit_style__c = 'approve';
            aud.dwp_cvad__action_audit_type__c = 'Risk Approval';
            insert aud;
        	dwp_cvad__Action_Audit_Detail__c ACTAUDDET = new dwp_cvad__Action_Audit_Detail__c();
            ACTAUDDET.dwp_cvad__action_audit_id__c = aud.Id;
            ACTAUDDET.dwp_cvad__action_audit_detail_display_order__c = 1;
            ACTAUDDET.dwp_cvad__action_audit_detail_display_type__c = 'Embedded';
	        insert ACTAUDDET;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_dwp_cvad_ActAudD(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteVISMAGLOC(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Visit__c vis = createVisit();
            insert vis;
        	Visit_Management_Team_Local__c VISMAGLOC = new Visit_Management_Team_Local__c();
            VISMAGLOC.visit_id__c = vis.Id;
	        insert VISMAGLOC;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Visit_Manag_Team_Local(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteVISTOPLOC(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Visit__c vis = createVisit();
            insert vis;
        	Visit_Topic_Local__c VISTOPLOC = new Visit_Topic_Local__c();
            VISTOPLOC.visit_id__c = vis.Id;
	        insert VISTOPLOC;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Visit_Topic_Local(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
    @isTest
    static void deleteVISCONLOC(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Local_Visit__c vis = createVisit();
            insert vis;
        	Visit_Contact_Local__c VISCONLOC = new Visit_Contact_Local__c();
            VISCONLOC.visit_id__c = vis.Id;
	        insert VISCONLOC;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Visit_Contact_Local(), 1);
            System.assertNotEquals(batchInstanceId, null,'Error');
        }
    }
    
}