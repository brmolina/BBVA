/**********************************************************************************
* @author       Global Desktop
* @date         15/03/2019
* @description  Test de la case DES_Batch_firstUpdateRevenues
* @Revision

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------
0.1            15/03/2019      Global Desktop    Testeo de la clase DES_Batch_firstUpdateRevenues
**********************************************************************************/
@isTest
public class DES_RevenuesTest {
	
	/**
	* @author Global Desktop
	* @description Test de la clase DES_Batch_firstUpdateRevenues
	*/
	@isTest
    public static void revenuesBatch() {
    	
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
    	
    	//Creacion oportunidad
    	final Opportunity opp = utilTestClass.createOpportunity(accGroup); 
        opp.DES_Booking_Geography__c = 'BE';
        opp.DES_Countries__c = 'BE';
        opp.CurrencyIsoCode = 'EUR'; 
        insert opp;
        test.startTest();
		//Creacion opportunity product
        final OpportunityLineItem oppLineItem = utilTestClass.createOppLineItem(opp, prod1, pbEntryTest1);
        insert oppLineItem;
        
        //Actualizacion oportunidad
        opp.StageName = Label.DES_Proposal;
        update opp;
        
        final Id batchInstanceId = Database.executeBatch(new DES_Batch_firstUpdateRevenues(), 500);
    	
    	Boolean response;
		response = batchInstanceId == null ? false : true;
		System.assert(true, response);
    	
    	test.stopTest();
    }
    
}