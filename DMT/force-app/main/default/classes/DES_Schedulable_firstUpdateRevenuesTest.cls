/**************************************************************************************************************
Name:            DES_Schedulable_firstUpdateRevenuesTest
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            28/05/2019      Global Desktop    Test del schedulable DES_Schedulable_firstUpdateRevenues
**************************************************************************************************************/
@isTest
public class DES_Schedulable_firstUpdateRevenuesTest {
	
	@isTest
    public static void DES_Schedulable_firstUpdateRevenuesTest(){
    	
    	final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final id accountGroupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        
        //Creacion grupo
    	final Account accGroup = utilTestClass.createClient();
        accGroup.RecordTypeId = accountGroupRT;
        accGroup.DES_Structure_Type__c = 'Group';
        accGroup.DES_BBVA_Segmentation__c = 'C';
    	insert accGroup;
    	
    	//Creacion producto
    	final Product2 prod1 = utilTestClass.createProduct(Label.DES_Mergers_Acquisitions);
        insert prod1;
        
        //Creacion pricebookEntry
        final PricebookEntry pbEntryTest1 = utilTestClass.createPricebookEntry(prod1);
        insert pbEntryTest1;
    	Test.startTest();
    	//Creacion oportunidad
    	final Opportunity opp = utilTestClass.createOpportunity(accGroup); 
        opp.DES_Booking_Geography__c = 'BE';
        opp.DES_Countries__c = 'BE';
        opp.CurrencyIsoCode = 'EUR'; 
        insert opp;
        
		//Creacion opportunity product
        final OpportunityLineItem oppLineItem = utilTestClass.createOppLineItem(opp, prod1, pbEntryTest1);
        insert oppLineItem;
        Test.stopTest();
        //Actualizacion oportunidad
        opp.StageName = Label.DES_Proposal;
        update opp;
        
        
		String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_firstUpdateRevenues()); 
		System.assertNotEquals(jobId, null);
		
    	
    }
	
}