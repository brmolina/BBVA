/*****************************************************************************************
Name:            RevenuesByRegionAndProductsCont
Description:     Controlador del componente RevenuesByRegionAndProducts

Version        Date            Author            Summary of changes
-----------------------------------------------------------------------------------------
0.1            15/02/2019      Global Desktop    Controlador del componente RevenuesByRegionAndProducts
*****************************************************************************************/
public with sharing class RevenuesByRegionAndProductsCont {
	/*Variables mes*/
	private static String month;
	/*Variable año*/
    private static String year; //NOSONAR
    /*variable fecha*/
    private static String englobaDate;

    /*
	* @author Global Desktop
	* @description Method que recoge los Revenues relacionados al cliente
	*/
	@auraEnabled
    public static String getData(String clientId, String family) {
  		try {
        	System.debug('::::::getData init');
        	//Mapa que tiene como key la Familia y como value el color
	        Map<String, String> mapFamCol = new Map<String, String>();
           	// Mapa que tiene como key el País y como value el mapa mapFPPR para el país
	        final Map<String, Map<String, Double>> mapPais = new Map<String, Map<String, Double>>();


            final list<DES_Booking__c> revenuesList = [SELECT DES_Country__c, convertCurrency(DES_Revenues__c), DES_Region__c, SOLUTION_CATEGORY_NAME__c, Month_type__c,
            											DES_year__c, DES_Client__r.DES_Revenue_Update__c
                                                   FROM DES_Booking__c
                                                  WHERE DES_Engloba_Load_Helper__c = '0'
                                                    AND DES_Client__c = :clientId
                                                    //AND DES_XB__c = FALSE
                                                    AND DES_Type__c = :family
                                                  ORDER BY Month_type__c DESC];

  	  		final Set<String> setFams = new Set<String>();
           	if(!revenuesList.isEmpty()) {
           		englobaDate = revenuesList[0].DES_Client__r.DES_Revenue_Update__c;
                String lastMonthBooking = revenuesList[0].Month_type__c;
                month = lastMonthBooking;
                year = revenuesList[0].DES_year__c;

	            //Recorremos la lista de Booking
	          	for(DES_Booking__c book : revenuesList) {
	          		if(book.SOLUTION_CATEGORY_NAME__c != null){
	         			if(book.DES_Region__c != null && book.DES_Revenues__c != null && book.Month_type__c == lastMonthBooking) {

	         				//Mapa que tiene como key la Famlia y como value el Potencial revenue asociado
	        				Map<String, Double> mapFPPR = new Map<String, Double>();
	                        if(mapPais.get(book.DES_Country__c) == null) {
	                           mapFPPR = new Map<String, Double>();
	                           mapFPPR.put(book.SOLUTION_CATEGORY_NAME__c,  book.DES_Revenues__c);
	                           mapPais.put(book.DES_Country__c, mapFPPR);
	                        } else {
	                        	if (mapPais.get(book.DES_Country__c).get(book.SOLUTION_CATEGORY_NAME__c) == null) {
	                                mapFPPR = mapPais.get(book.DES_Country__c);
	                                mapFPPR.put(book.SOLUTION_CATEGORY_NAME__c,  book.DES_Revenues__c);
	                                mapPais.put(book.DES_Country__c, mapFPPR);
	                            } else {
	                                mapFPPR = mapPais.get(book.DES_Country__c);
	                                final Double revTot = mapPais.get(book.DES_Country__c).get(book.SOLUTION_CATEGORY_NAME__c) + book.DES_Revenues__c;
	                                mapFPPR.put(book.SOLUTION_CATEGORY_NAME__c, revTot);
	                                mapPais.put(book.DES_Country__c, mapFPPR);
	                           	}
	                      	}
	                   	}

                	}
                	setFams.add(book.SOLUTION_CATEGORY_NAME__c);
                }
            }
          	mapFamCol = getFamilyColor(setFams, family);
	        final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(mapFamCol, mapPais);
	        return JSON.serialize(wrapperGlobal);

        	} catch (Exception e) {
            	throw new AuraHandledException('Error en RevenuesByRegionAndProductsCont.getData ' + e);
        	}
		}

	/*
    * @author Global Desktop
    * @description Recupera el color asociado al producto
    */
	public static Map<String, String> getFamilyColor(Set<String> setFamilyData, String family) {
        final Map<String, String> mapFamColor = new Map<String, String>();
        final List<Product_Level_2_Color__mdt> listFamColor = [select MasterLabel, DeveloperName,  Color__c from Product_Level_2_Color__mdt //NOSONAR
        														where Product_Family__c = :family AND MasterLabel !=: Label.DES_FI_capital_Solutions
        														AND MasterLabel !=: Label.DES_Liability_Management AND MasterLabel !=: Label.DES_Rating_Advisory];
        system.debug('listFamColor: ' + listFamColor);

        if(!listFamColor.isEmpty()) {
            for(Product_Level_2_Color__mdt fam : listFamColor) {
                if(fam.MasterLabel != null && fam.Color__c != null && mapFamColor.get(fam.MasterLabel) == null) {
                    mapFamColor.put(fam.MasterLabel, fam.Color__c);
                }
            }
        }
        return mapFamColor;
    }

    /*
    * @author Global Desktop
    * @description Construye la wrapper list que se devolvera al componente lightning
    */
    public class WrapperGlobalData {
    	/*Declaracion de variables*/
        private Map<String, String> mapFamCol;
        /*Declaracion de variables*/
        private Map<String, Map<String, Double>> mapData;

        /*Method que construye le lista wraper*/
        public WrapperGlobalData (Map<String, String> fams, Map<String, Map<String, Double>> data) {
            this.mapFamCol = fams;
            this.mapData = data;
        }
        /*Method que devuelve la familia*/
        public Map<String, String> getMapFamCol() {
          return mapFamCol;
        }
        /*Method que devuelve el mapa de datos*/
        public Map<String, Map<String, Double>> getMapData() {
          return mapData;
        }
    }


    /**
	* @author Global Desktop
	* @description Method que recoge el mes de actualizacion de engloba
	*/
   	@AuraEnabled
    public static String getEnglobaDate() {
      final String dateEngloba = 'Revenues from Engloba - '+englobaDate;
      System.debug('>>>>> dateEngloba: ' +dateEngloba);
      //return dateEngloba;
		return dateEngloba;
    }//getEnglobaDate

	/**
	* @author Global Desktop
	* @description Construye el formato de la fecha
	*/
	private static Date getDate(String month, String year){

	  	final Integer monthInt = Integer.valueOf(month);
	  	final Integer monthLaterInt = Integer.valueOf(month)+1;
	  	final String monthLater = String.valueOf(monthLaterInt);
	  	Date dateBooking = Date.today();

	  	if(monthInt == 12) {
	 		dateBooking = Date.valueOf(year+'-'+month+'-31');
	 	} else {
	 		dateBooking = Date.valueOf(year+'-'+monthLater+'-01').addDays(-1);
	    }
	  	System.debug('>>>>> dateBooking: ' + dateBooking);
	  	return dateBooking;
    }//getDate

	/**
	* @author Global Desktop
	* @description Recupera la informacion que saldra en las columnas de la tabla
	*/
 	@AuraEnabled
	public static String getRowsData(String clientId, String family) {
   		final list<DES_Booking__c> revBookList = [SELECT DES_Client__r.Name, convertCurrency(DES_Revenues__c), DES_Region__c, SOLUTION_CATEGORY_NAME__c, DES_Country__c, Month_type__c, DES_Year__c, Des_Type__c
                                              FROM DES_Booking__c
                                             WHERE DES_Engloba_Load_Helper__c = '0'
                                               AND DES_Client__c = :clientId
                                               AND DES_XB__c = FALSE
                                               AND DES_Type__c = :family
                                              ORDER BY Month_type__c DESC];
        List<WrapperClass> listWrapper = new List<WrapperClass>();
        String lastMonthBookProd = revBookList[0].Month_type__c;

        for(DES_Booking__c i : revBookList) {
            if (i.Month_type__c == lastMonthBookProd) {
            	listWrapper.add(new WrapperClass(i.DES_Client__c,i.DES_Client__r.Name, i.DES_Revenues__c, i.DES_Region__c, i.SOLUTION_CATEGORY_NAME__c, i.DES_Country__c, i.Month_type__c, i.DES_Year__c, i.Des_Type__c));
            }
        }
        return JSON.serialize(listWrapper);
    }

	/**
	* @author Global Desktop
	* @description Clase que construye la lista wrapper
	*/
    public class WrapperClass {
    	private String accountId; //NOSONAR
        private String accountName; //NOSONAR
        private Decimal revenues; //NOSONAR
        private String region; //NOSONAR
        private String product; //NOSONAR
        private String country; //NOSONAR
        private String year; //NOSONAR
        private String month; //NOSONAR
        private Date dateBooking; //NOSONAR
        private String familyProd; //NOSONAR

		/**
		* @author Global Desktop
		* @description Method que construye la lista wrapper
		*/
        public WrapperClass(String accountIdPar, String accountNamePar, Decimal revenuesPar, String regionPar, String productPar, String countryPar, String monthPar, String yearPar, String familyProdPar) {
      		this.accountId = '/lightning/r/Account/' + accountIdPar + '/view';
            this.accountName = accountNamePar;
            this.revenues = revenuesPar;
            this.region = regionPar;
            this.product = productPar;
            this.country = countryPar;
            this.year = yearPar;
            this.month = monthPar;
            this.dateBooking = getDate(month,year);
            this.familyProd = familyProdPar;
        }
    }
}