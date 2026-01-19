/**********************************************************************************
* @author       Global Desktop
* @date         15/03/2019
* @description  Test de la case DES_DetailsTable_Controller
* @Revision

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------
0.1            15/03/2019      Global Desktop    Testeo de la clase DES_DetailsTable_Controllerr
**********************************************************************************/
@isTest
public class DES_DetailsTable_Test {
	
	/**
	* @author Global Desktop
	* @description Test de la clase DES_DetailsTable_Controller
	*/
	@isTest
    public static void detailsTable() {
    	
    	final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
            
        final Account acc1 = utilTestClass.createClient();
        insert acc1;
        
        DES_DetailsTable_Controller.getTableJSON(acc1.Id,'Account','DES_GTB_Revenues__c,DES_GF_Revenues__c,DES_GM_Revenues__c,DES_CF_Revenues__c','Spain');
        System.assertEquals(acc1.Name, 'Test Client','Correcto');
    	
    }

}