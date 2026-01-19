/**********************************************************************************
* @author       Global Desktop
* @date         15/03/2019
* @description  Test de la case FamilyProductCards_Controller
* @Revision

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------
0.1            15/03/2019      Global Desktop    Testeo de la clase FamilyProductCards_Controller
**********************************************************************************/
@isTest
public class FamilyProductCardsTest {
	
	/**
	* @author Global Desktop
	* @description Test de la clase FamilyProductCards_Controller
	*/
	@isTest
    public static void familyProductCardsCont() {
    	
    	Test.StartTest();
    	final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final id accountGroupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        
    	//Creacion grupo
    	final Account accGroup = utilTestClass.createClient();
        accGroup.RecordTypeId = accountGroupRT;
        accGroup.DES_Structure_Type__c = 'Group';
        accGroup.DES_BBVA_Segmentation__c = 'C';
        accGroup.DES_Revenue_Update_Engloba__c = '20181205';
    	insert accGroup;
    	
    	//Crear Revenues
    	final DES_Booking__c relatedBooking = utilTestClass.createBooking(accGroup, 'España', 'España', 125.12, 'GM', '2018');
    	relatedBooking.DES_Year__c = '2018';
    	insert relatedBooking;
    	
    	FamilyProductCards_Controller.getRevenuesData(accGroup.Id, 'Account', 'Spain');
    	FamilyProductCards_Controller.currentUserISOCode();
    	FamilyProductCards_Controller.getInstance();
    	
    	System.assertEquals(accGroup.DES_Structure_Type__c, 'Group','Correcto');
    	
    	Test.StopTest();
    }

}