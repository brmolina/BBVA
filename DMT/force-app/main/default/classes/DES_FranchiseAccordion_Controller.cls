/*
* @author Global Desktop
* @description Clase del componente lightning DES_FranchiseAccordion de la ficha de grupo.
*/
public class DES_FranchiseAccordion_Controller {
	/*
	* @author Global Desktop
	* @description Recupera las franchises relacionadas con la cuenta
	*/
    @AuraEnabled
    public static list<DES_Franchises__c> returnFracnhise(String accountId) {
    	try {
	        final list<DES_Franchises__c> franchises = [SELECT Id, DES_Client__c, Name, DES_MTD_Franchise__c, DES_PY_Franchise__c, DES_PYTD_Franchise__c,
	                                              DES_Type_of_vision__c, DES_Vision__c, DES_YTD_Franchise__c, DES_Entity__c, DES_Sales_Rooms__c,DES_Last_Trade_Date__c
	                                              FROM DES_Franchises__c
	                                              WHERE DES_Client__c =: accountId
	                                              ORDER BY DES_Vision__c ASC];
	        return franchises;
    	} catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
    }
}