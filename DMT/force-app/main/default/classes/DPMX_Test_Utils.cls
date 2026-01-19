public with sharing class DPMX_Test_Utils {
    public DPMX_Test_Utils() {

    }
    
    public static User createUser(String idUser) {
        final Profile profi = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        final User usuario = new User(
            FederationIdentifier = '1234',
            Username = 'testProfi@example.com',
            FirstName = 'firstName',
            LastName = 'profi',
            Email = 'testProfi@test.com',
            Alias = 'profi',
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profi.Id,
            LanguageLocaleKey='en_US',
            ID_User__c = idUser
        );
        return usuario;
    }
    
    public static User createUserPersonalized(String idUser, string emailstr) {
        final Profile profi = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        final User usuario = new User(
            FederationIdentifier = '1234'+emailstr,
            Username = emailstr+'@example.com',
            FirstName = 'firstName',
            LastName = 'profi',
            Email = emailstr+'@test.com',
            Alias = 'profi',
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profi.Id,
            LanguageLocaleKey='en_US',
            ID_User__c = idUser
        );
        return usuario;
    }

    public static PermissionSetAssignment assignPermissionSet(String idUser, string permisionSetName) {
       	PermissionSet permSet = [SELECT Id, Name
                            FROM PermissionSet
                            WHERE Name = :permisionSetName];
        PermissionSetAssignment permSetAs = new PermissionSetAssignment();

        permSetAs.PermissionSetId = permSet.Id;
        permSetAs.AssigneeId = idUser;
        
        return permSetAs;
    }

    public static Account createAccount(String NameAccount) {
        try {
            Account newAccount = new Account();
            newAccount.Name = NameAccount;
            
            return newAccount;
        } catch (Exception e) {
            e.getMessage();
            return null;
        }
        
    }
    public static List<Account> createListAccount(Integer quantity) {
        try {
            List<Account> newListAccount = new List<Account>();
            for (Integer i = 0; i < quantity; i++) {
                Account acc = [SELECT RecordTypeId, Name, 
                DES_Country_Client__c,DES_ID_Fiscal__c FROM Account WHERE RecordType.Name = 'SER Service Account'];
                newListAccount.add(acc);
            }
            return newListAccount;
        } catch (Exception e) {
            e.getMessage();
            return null;
        }
    }
  
    public static List<DPMX_Dynamic_Pricing__c> createListDynamicPricing(Integer quantity) {
        try {
            List<DPMX_Dynamic_Pricing__c> newListDynamicPricing = new List<DPMX_Dynamic_Pricing__c>();
            for (Integer i = 0; i < quantity; i++) {
                newListDynamicPricing.add([SELECT Name, Client__c, Product__c, Company_Name__c 
                        FROM DPMX_Dynamic_Pricing__c]);
            }
            return newListDynamicPricing;
        } catch (Exception e) {
            e.getMessage();
            return null;
        }
    }
    
    
    public static DPMX_Dynamic_Pricing__c createDynamicPricing(String NameDydamicPricing, String idAccount) {
        try {
             Account acc = [SELECT id, DES_Main_Parent__c FROM Account WHERE id=:idAccount];
            
            DPMX_Dynamic_Pricing__c dynamicPricingTest = new DPMX_Dynamic_Pricing__c();
            dynamicPricingTest.Name = NameDydamicPricing;
            dynamicPricingTest.Product__c = 'Acquirer';
            dynamicPricingTest.Client__c = acc.id;
            dynamicPricingTest.Company_Name__c = acc.Id;
            dynamicPricingTest.familia__c = 'Otro';
        	dynamicPricingTest.familia_AcquiererCategories_Id__c = '13';
            dynamicPricingTest.debitLastMonth__c = 1;
            dynamicPricingTest.CreditLastMonth__c = 2;
            dynamicPricingTest.IntLastMonth__c = 3;
            dynamicPricingTest.RentabildiadLastMonth__c = 4;
            dynamicPricingTest.baiLastMonth__c = 5;
            dynamicPricingTest.debitSim__c = 1;
            dynamicPricingTest.creditSim__c = 2;
            dynamicPricingTest.interSim__c = 3;
            dynamicPricingTest.RentabildiadSim__c = 4;
            dynamicPricingTest.baiSim__c = 5;
            dynamicPricingTest.Sim_Tickets_Debit_Own_Amount__c = 10;
            dynamicPricingTest.Sim_Tickets_Credit_Own_Amount__c = 11;
            dynamicPricingTest.Sim_Tickets_International_Amount__c = 12;
            dynamicPricingTest.Sim_Billing_TotalAmount_Amount__c = 13;
            dynamicPricingTest.Sim_Tickets_TotalAmount_Amount__c = 14;
            dynamicPricingTest.Sim_Percentage_Total__c = 15;
            dynamicPricingTest.Sim_Transaction_Credit_Own__c =1;
            dynamicPricingTest.Sim_Transaction_International__c = 2;
            dynamicPricingTest.Sim_Transaction_AcquirerAffiliation__c = 5;
            String newDycPrgJSON = JSON.serialize(dynamicPricingTest);
            return dynamicPricingTest;
                        
        } catch (Exception e) {
            e.getMessage();
            return null;
        }
    }
    
    public static DPMX_Formalize__c createFormalize(DPMX_Dynamic_Pricing__c dynamicPricing, String idUser) {
        Integer num = 0;
        List<DPMX_Formalize__c> formalizeLst = DPMX_Utils.formalizeNameSelector();
            for(DPMX_Formalize__c formal : formalizeLst){
                if(formal.Name.contains(idUser)){
                    num ++;
                }
            }

        DPMX_Formalize__c newFormalize = new DPMX_Formalize__c();
        newFormalize.Name = idUser+'_'+num;
        newFormalize.Dynamic_Pricing__c = dynamicPricing.Id;
        return newFormalize;
    }
    
    public static Local_Client__c createLocalClient(account acc, string code){
        Local_Client__c locCli = new Local_Client__c();
        locCli.unique_id__c = code;
        locCli.Cib_Client__c = acc.Id;
        return locCli;
    }
    
    
    
    
    
    
    
    
    
}