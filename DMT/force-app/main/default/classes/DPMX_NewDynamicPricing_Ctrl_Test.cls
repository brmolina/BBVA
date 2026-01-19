/**
* ────────────────────────────────────────────────────────────────────────────────────
* DPMX_NewDynamicPricing_Ctrl_Test
* Test class for DPMX_NewDynamicPricing_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-07-11
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class DPMX_NewDynamicPricing_Ctrl_Test {
	@TestSetup
    static void createData() {
    }
    @IsTest
    static void createAccountWitoutLocalClientTest(){   
        Account acc = new Account();
        acc.Name = 'AccountTest';
        insert acc;
        
        Test.startTest();
        	Map<String, Object> retMap = DPMX_NewDynamicPricing_Ctrl.getInitialData(acc.id); 
    	    final Account clientExpected = [SELECT Id, Name FROM Account WHERE Id =: acc.id];
        	final Account clientActual = (Account) Json.deserialize(JSON.serialize(retMap.get('client')), Account.class);
        	final List<Account> listClientExpected = [SELECT Id, Name FROM Account WHERE business_group_header_type__c = true AND DES_Main_Parent__c = :acc.id];
			System.assertEquals(clientExpected.Id , clientActual.Id, 'createAccountTest client OK');
            System.assertEquals(retMap.get('clientLabel'), Schema.DPMX_Dynamic_Pricing__c.fields.Client__c.getDescribe().getLabel(), 'createAccountTest clientLabel OK');
        	System.assertEquals(retMap.get('product'), 'Acquirer' ,'createAccountTest product OK');
        	System.assertEquals(retMap.get('productLabel'), Schema.DPMX_Dynamic_Pricing__c.fields.Product__c.getDescribe().getLabel() ,'createAccountTest productLabel OK');
        	Test.stopTest();
    }
    
    @IsTest
    static void createAccountTest(){   
        Account acc = new Account();
        acc.Name = 'AccountTest';
        insert acc;
        
        Local_Client__c locCl = new Local_Client__c();
        locCl.unique_id__c = '98717946';
        locCl.Cib_Client__c = acc.Id;
        insert locCl;
        
        Test.startTest();
        	Map<String, Object> retMap = DPMX_NewDynamicPricing_Ctrl.getInitialData(acc.id); 
    	    final Account clientExpected = [SELECT Id, Name FROM Account WHERE Id =: acc.id];
        	final Account clientActual = (Account) Json.deserialize(JSON.serialize(retMap.get('client')), Account.class);
        	final List<Account> listClientExpected = [SELECT Id, Name FROM Account WHERE business_group_header_type__c = true AND DES_Main_Parent__c = :acc.id];
			System.assertEquals(clientExpected.Id , clientActual.Id, 'createAccountTest client OK');
            System.assertEquals(retMap.get('clientLabel'), Schema.DPMX_Dynamic_Pricing__c.fields.Client__c.getDescribe().getLabel(), 'createAccountTest clientLabel OK');
        	System.assertEquals(retMap.get('product'), 'Acquirer' ,'createAccountTest product OK');
        	System.assertEquals(retMap.get('productLabel'), Schema.DPMX_Dynamic_Pricing__c.fields.Product__c.getDescribe().getLabel() ,'createAccountTest productLabel OK');
            System.assertEquals(retMap.get('companyNameLabel'), Schema.DPMX_Dynamic_Pricing__c.fields.Company_Name__c.getDescribe().getLabel() ,'createAccountTest existingSubsList OK');
        	Test.stopTest();
    }
    
    @IsTest
    static void saveDynamicPricingTest(){  
        Account acc = new Account();
        acc.Name = 'AccountTest';
        insert acc;
        Account acc1 = new Account();
        acc1.Name = 'AccountTest1';
        insert acc1;
        Local_Client__c lc = new Local_Client__c();
        lc.unique_id__c = 'test';
        lc.Cib_Client__c = acc.Id;
        insert lc;
        
        acc.DES_Main_Parent__c = acc1.id;
        update acc;
        
        DPMX_Dynamic_Pricing__c newDycPrg = new DPMX_Dynamic_Pricing__c();
        newDycPrg.Name = 'Dynamic Pricing Test';
        newDycPrg.Client__c = acc.id;
        newDycPrg.Product__c = 'Acquirer';
        newDycPrg.Company_Name__c = acc.DES_Main_Parent__c;
        newDycPrg.Frequency_of_Revision__c = 'Biannual';
        newDycPrg.familia__c = 'Otro';
        newDycPrg.familia_AcquiererCategories_Id__c = '13';
        String newDycPrgJSON = JSON.serialize(newDycPrg);
        insert newDycPrg;

        Test.startTest();
            Map<String, Object> retMap = DPMX_NewDynamicPricing_Ctrl.saveDynamicPricing(newDycPrgJSON, 'Otro' ,'13', false); 
            System.assertEquals(retMap.get('success'), true,'saveDynamicPricingTest OK');

        Test.stopTest();
    }
 
}