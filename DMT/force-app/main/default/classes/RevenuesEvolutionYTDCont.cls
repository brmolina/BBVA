/*****************************************************************************************
Name:            RevenuesEvolutionYTD
Description:     Controlador del componente lightning RevenuesEvolutionYTD

Version        Date            Author            Summary of changes
-----------------------------------------------------------------------------------------
0.1            15/02/2019      Global Desktop    Controlador del componente lightning RevenuesEvolutionYTD
*****************************************************************************************/
public with sharing class RevenuesEvolutionYTDCont {

	/*
	* @author Global Desktop
	* @description Recupera los Revenues relacionados con el cliente
	*/
	@AuraEnabled
  	public static String getData(String clientId) {
  		try {
		    system.debug('>>>>> FUNCION getData. ID CLIENTE : ' + clientId);

		    final list<DES_Booking__c> revenuesYTDList = [SELECT convertCurrency(DES_Revenues__c), Month_type__c, DES_Year__c, DES_Type__c, SOLUTION_CATEGORY_NAME__c
		                                              FROM DES_Booking__c
		                                             WHERE DES_Engloba_Load_Helper__c IN ('0','1')
		                                               AND DES_Client__c = :clientId
		                                               AND DES_XB__c = FALSE
		                                          ORDER BY DES_Year__c DESC, Month_type__c DESC];

		    //Mapa que tiene como key el Family Product y como Value el Revenue total asociado de esa familia
		    final Map<String, Double> mapFPPR_LastYear = new Map<String, Double>();
		    final Map<String, Double> mapFPPR_CurrYear = new Map<String, Double>();

		    //Mapa que tiene como key el Año y como Value el mapa mapFPPR
		    final Map<String, Map<String, Double>> mapYear = new Map<String, Map<String, Double>>();

		    final List<String> listFamProd = familyValuesIntoList();
		    system.debug('>>>>> listFamProd : ' + listFamProd);
		    for(String fp : listFamProd) {

	      		if(mapFPPR_LastYear.get(fp) == null) {
		        	mapFPPR_LastYear.put(fp,0);
		      	}
		      	if(mapFPPR_CurrYear.get(fp) == null) {
		        	mapFPPR_CurrYear.put(fp,0);
		      	}
		    }

		    //Si la lista no está vacia
		    if(!revenuesYTDList.isEmpty()) {
	    		final String lastMonthBooking = revenuesYTDList[0].Month_type__c;
		      	for(DES_Booking__c booking : revenuesYTDList) {
		          	//Si tiene informado el revenue y el mes es el último informado este año
		          	if(booking.DES_Revenues__c != null && booking.Month_type__c == lastMonthBooking) {
			          	final Integer currentYearInt = Integer.valueOf(revenuesYTDList[0].DES_Year__c);
			          	final Integer lastYearInt = currentYearInt - 1;
			          	final String lastYear = String.valueOf(lastYearInt);
			          	final String currentYear = String.valueOf(currentYearInt);

		              	if(booking.DES_Year__c == lastYear) {
		                	if(mapFPPR_LastYear.get(booking.DES_Type__c) == null) {
			                   //Le pongo el valor del Potential Revenue a la key que tenga ese Product Family
			                   mapFPPR_LastYear.put(booking.DES_Type__c, booking.DES_Revenues__c);
			                   mapYear.put(booking.DES_Year__c, mapFPPR_LastYear);
		                  	} else {
			                    //Si ya tiene valor, le sumo el revenue al que tenía
			                    mapFPPR_LastYear.put(booking.DES_Type__c, mapFPPR_LastYear.get(booking.DES_Type__c) + booking.DES_Revenues__c);
			                    mapYear.put(booking.DES_Year__c, mapFPPR_LastYear);
		                  	}
		                  	system.debug('mapFPPR_LastYear: ' + mapFPPR_LastYear);
		              	} else if(booking.DES_Year__c == currentYear) {
		                	if(mapFPPR_CurrYear.get(booking.DES_Type__c) == null) {
			                  	//Le pongo el valor del Revenue a la key que tenga ese Product Family
			                  	mapFPPR_CurrYear.put(booking.DES_Type__c, booking.DES_Revenues__c );
			                  	mapYear.put(booking.DES_Year__c, mapFPPR_CurrYear);
		                	} else{
			                  	//Si ya tiene valor, le sumo el potential revenue a ese mismo valor
			                  	mapFPPR_CurrYear.put(booking.DES_Type__c, mapFPPR_CurrYear.get(booking.DES_Type__c) + booking.DES_Revenues__c );
			                  	mapYear.put(booking.DES_Year__c, mapFPPR_CurrYear);
		                	}
		                system.debug('mapFPPR_CurrYear: ' + mapFPPR_CurrYear);
		              	}
	             	}
	          	}
	      	}//FIN !RevenuesYTDList.isEmpty()

	      	system.debug('>>>>> mapYear ANTES RELLENAR TODAS LAS FAMILIAS: ' + mapYear);
	      	return JSON.serialize(mapYear);
	  	} catch (Exception exc) {
        	throw new AuraHandledException(Label.DES_Error + exc);
    	}
	}


	/*
	* @author Global Desktop
	* @description Funcion para recuperar los valores de picklist del campo Type del objeto Booking
	*/
    private static List<String> familyValuesIntoList() {
      final List<String> picksValList= new List<String>();

      final Schema.DescribeFieldResult fieldResult = DES_Booking__c.DES_Type__c.getDescribe();
      final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
      system.debug('>>>>> ple: ' + ple);
      for(Schema.PicklistEntry pickListVal : ple) {
        picksValList.add(pickListVal.getLabel());
      }
      system.debug('>>>>> picksValList: ' + picksValList);
      return picksValList;
    }//familyValuesIntoList


   	/*
	* @author Global Desktop
	* @description Funcion para construir la fecha de los Booking
	*/
    private static Date getDate(String month, String year) {
    	Date dateBooking = Date.today();
    	if(month != null && year != null) {
		  	final Integer monthInt = Integer.valueOf(month);
		  	final Integer monthLaterInt = Integer.valueOf(month)+1;
			System.debug('monthLaterInt: ' + monthLaterInt);
		  	//Date dateBooking = Date.today();
		  	if (monthInt == Integer.ValueOf(Label.DES_LastMonth)) {
	 			dateBooking = Date.valueOf(year+'-'+month+'-31');
	     	} else {
	     		final String monthLater = String.valueOf(monthLaterInt);
	     		dateBooking = Date.valueOf(year+'-'+monthLater+'-01').addDays(-1);
			}
		  	System.debug('>>>>> dateBooking: ' + dateBooking);
    	} else {
    		dateBooking = null;
    	}
	  	return dateBooking;
    }//getDate


    /*
	* @author Global Desktop
	* @description Construye la lista wrapper que se mandara al componente lightning
	*/
    @AuraEnabled
    public static String getBookingProd (String clientId) {
	  	List<DES_Booking__c> RevBookProdList = [SELECT Id, DES_Client__r.Name, DES_Country__c, DES_Region__c, convertCurrency(DES_Revenues__c), Month_type__c, DES_Year__c, DES_Type__c, SOLUTION_CATEGORY_NAME__c
	                                              FROM DES_Booking__c
	                                             WHERE DES_Engloba_Load_Helper__c IN ('0','1')
	                                               AND DES_Client__c = :clientId
	                                               AND DES_XB__c = FALSE
	                                          ORDER BY DES_Year__c DESC, Month_type__c DESC];

	  	String lastMonthBookProd = RevBookProdList[0].Month_type__c;
	  	List<WrapperClass> listWrapper = new List<WrapperClass>();
	  	for(DES_Booking__c bookProd : RevBookProdList) {
	  		if (bookProd.Month_type__c == lastMonthBookProd) {
	      		listWrapper.add(new WrapperClass(bookProd, bookProd.DES_Client__r.Name, bookProd.DES_Country__c, bookProd.DES_Region__c, bookProd.DES_Type__c, bookProd.SOLUTION_CATEGORY_NAME__c, bookProd.DES_Year__c, bookProd.Month_type__c, bookProd.DES_Revenues__c ));
	 		}
	  	}
	  	system.debug('>>>>>listWrapper : ' + listWrapper);
	  	return JSON.serialize(listWrapper);
    }

    /*
	* @author Global Desktop
	* @description recupera el iso code del usuario logado en el sistema
	*/
    @AuraEnabled
    public static String getCurrentUserISOCode() {
    	try {
    	return UserInfo.getDefaultCurrency();
    	} catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
    }


	/*
	* @author Global Desktop
	* @description Construye la clase wrapper
	*/
    public class WrapperClass {
    	/*
		* @author Global Desktop
		* @description Variables de la clase wrapper
		*/
  		private String cliName;
  		private String prodFam;
  		@TestVisible
  		private String prodName;
  		private Decimal revenues;
  		private String urlBook;
  		@TestVisible
  		private String year;
  		@TestVisible
  		private String month;
  		private Date dateBooking;
  		private String country;
  		private String region;

		/*
		* @author Global Desktop
		* @description Construye la lista wrapper
		*/
      	public WrapperClass(DES_Booking__c book, String clientName, String country, String region, String prodFam, String prodName, String year,String month, Decimal revenues) {
	        this.urlBook = '/lightning/r/DES_Booking__c/' + book.Id + '/view';
	        this.cliName = clientName;
	        this.prodFam = prodFam;
	        this.prodName = prodName;
	        this.year = year;
	        this.month = month;
	        this.revenues = revenues;
	        this.dateBooking = getDate(month,year);
	        this.country = country;
	        this.region = region;
      	}
    }

}