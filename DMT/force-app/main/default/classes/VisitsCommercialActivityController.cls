/**********************************************************************************
* @author       Global Desktop
* @date         15/03/2019
* @description  Controlador del lightning component VisitsCommercialActivity
* @Revision

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------
0.1            15/03/2019      Global Desktop    Controlador del lightning component VisitsCommercialActivity
**********************************************************************************/
public with sharing class VisitsCommercialActivityController {
	
	/**
	* @author Global Desktop
	* @description Constructor de la clase
	*/
	public VisitsCommercialActivityController() {
		
	}
	
	//SINGLETON PATTERN
    private static VisitsCommercialActivityController instance;
    public static VisitsCommercialActivityController getInstance(){
        if (instance == null) instance = new VisitsCommercialActivityController();
        return instance;
    }
	
	/**
	* @author Global Desktop
	* @description Recupera las visitas relacionadas con la cuenta
	*/
  	@auraEnabled
  	public static String getVisitInfo(String accId, String country){
	    List<wrapperClass> listWrapperClass = new List<wrapperClass>();
	    Date todayMinusOneYear = Date.today().addYears(-1);
	    
	    List<DES_Denorm_AccountVisits__c> denormRelatedVisits = new List<DES_Denorm_AccountVisits__c>();
	    if(country == null || string.isBlank(country) || string.isEmpty(country) || country == 'Todos') {
	    denormRelatedVisits = [SELECT id, DES_Start_Date__c
								FROM DES_Denorm_AccountVisits__c
								WHERE DES_Client__c = :accId AND
								((DES_Start_Date__c = THIS_YEAR AND DES_Start_Date__c <= TODAY)
								OR (DES_Start_Date__c > :todayMinusOneYear.addDays(1) AND DES_Start_Date__c <= TODAY)
								OR(DES_Start_Date__c = LAST_YEAR))];
    	} else {
	    	final Map<String,String> mapContryCodes= GroupGeographyCnt.helperCreateMapCountryCodes('LABEL');
	  		final String countryDevName = mapContryCodes.get(country);
	        final set<Id> countryAccountIds = OpportunitiesInProgressByFamilyCont.getFieldLabels(accId, country);
	        denormRelatedVisits = [SELECT id, DES_Start_Date__c
									FROM DES_Denorm_AccountVisits__c
									WHERE DES_Client__c IN :countryAccountIds 
									AND DES_Client__r.DES_Country_Client__c = :countryDevName
									AND ((DES_Start_Date__c = THIS_YEAR AND DES_Start_Date__c <= TODAY)
									OR (DES_Start_Date__c > :todayMinusOneYear.addDays(1) AND DES_Start_Date__c <= TODAY)
									OR(DES_Start_Date__c = LAST_YEAR))];
    	}															
    
	    Integer numVisitsYTD = 0;
	    Integer numVisitsFY = 0;
	    Integer numVisitsLY = 0;
	    final Date dateOfThisYear = Date.newInstance(Date.Today().year(),1,1);
	    final Date dateOfLastYear = Date.newInstance(Date.Today().year()-1,1,1);
	    for(DES_Denorm_AccountVisits__c i : denormRelatedVisits) {
		    if(i.DES_Start_Date__c > dateOfThisYear && i.DES_Start_Date__c <= Date.Today()) {
		    	numVisitsYTD = numVisitsYTD + 1;
		    } 
		    if(i.DES_Start_Date__c > todayMinusOneYear.addDays(1) && i.DES_Start_Date__c <= Date.Today()) {
		    	numVisitsFY = numVisitsFY + 1;
		    } 
		    if(i.DES_Start_Date__c > dateOfLastYear && i.DES_Start_Date__c < dateOfThisYear) {
		    	numVisitsLY = numVisitsLY + 1;
		    }	
	    }           
	                              
	    final Integer thisMonth = Integer.valueOf(System.today().month());
	
	    Decimal numVisitsTRYOY;
	    Decimal numVisitsYOY;
	    final Decimal avgVisitsLYpm = (Decimal) numVisitsLY/12*thisMonth;
	    if (avgVisitsLYpm != 0) {
	      numVisitsTRYOY =  (((Decimal) numVisitsYTD - avgVisitsLYpm)/avgVisitsLYpm) * 100;
	      numVisitsYOY = numVisitsTRYOY.setScale(2);
	    }
	
	    if(numVisitsYTD != 0 || numVisitsFY != 0 || numVisitsYOY != null) {
	      listWrapperClass.add(new wrapperClass(numVisitsYTD,numVisitsFY,numVisitsYOY));
	    }
	    return JSON.serialize(listWrapperClass);
	  }

	/**
	* @author Global Desktop
	* @description Clase que construye la clase wrapper
	*/
	public class wrapperClass {
		//Declaracion de variable para devolver en la lista wrapper
		private Integer returnTotalVisitsYTD;
		//Declaracion de variable para devolver en la lista wrapper
		private Integer returnTotalVisitsYF;
		//Declaracion de variable para devolver en la lista wrapper
		private Decimal returnTotalVisitsYOY;
		/**
		* @author Global Desktop
		* @description Method que construye la clase wrapper
		*/
		public wrapperClass(Integer totalVisitsYTD, Integer totalVisitsYF, Decimal totalVisitsYOY) {
  			this.returnTotalVisitsYTD = totalVisitsYTD;
  			this.returnTotalVisitsYF = totalVisitsYF;
  			this.returnTotalVisitsYOY = totalVisitsYOY;
		}
	}
}