/*************************************************************************************************************************
Name:             Batch_updateCountryVisitsTests
Description:      Clase de test de la clase Batch_updateCountryVisits

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------------------------------
0.1            14/11/2018      Global Desktop    Test de la clase  Batch_updateCountryVisits
*************************************************************************************************************************/
@isTest
public with sharing class Batch_updateCountryVisitsTests {
	
	/* Instancia de la clase DES_UtilTestClass */
	final private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
	
	/**
	* @author Global Desktop
	* @description Declaracion de variables
	*/
	@testSetup 
	public static void setupRows() {
		
		final Account acc = utilTestClass.createClient();
    	insert acc;
    	final Opportunity opp = UTILTESTCLASS.createOpportunity(acc);
 		insert opp;
    	final List<dwp_kitv__Visit__c> lstVisitas = new List<dwp_kitv__Visit__c>();
	    final List<String> lstLabelsRegiones = new List<String>{Label.RegionAmesur, Label.RegionAsia, Label.RegionEEUU, 
	    						Label.RegionSpain, Label.RegionMexico, Label.RegionEuropa, Label.RegionRestoLatam};
	    						
	    for(Integer i = 0; i < lstLabelsRegiones.size(); i++) {
	    	dwp_kitv__Visit__c visita;
	    	visita = utilTestClass.createVisit(acc, opp);
    		visita.dwp_kitv__region_name__c = lstLabelsRegiones[i];
            visita.dwp_kitv__country_name__c = '';
    		visita.dwp_kitv__solution_name_path_desc__c = 'GTB';
	    	lstVisitas.add(visita);
	    }
	    insert lstVisitas;	
	}
	
	/**
	* @author Global Desktop
	* @description Method 1 Test
	*/
	@isTest
	public static void updateCountryTest() {
        Boolean response = false;
        Id batchInstanceId = Database.executeBatch(new Batch_updateCountryVisits(), 100);
		if(batchInstanceId != null) {
			response = true;
		}
    	System.assertEquals(response, true, 'Hay respuesta');
	}
}