/**********************************************************************************
* @author       Accenture
* @date         01/10/2019
* @description  Clase que calcula los datos del componente DES_APRevenuesEvolutionChart
* @Revision
**********************************************************************************/
public with sharing class DES_APRevenuesEvolutionChartCnt {
 
    
    /*Mapa que contiene como key la familia y como value el color*/
    private static Map<String, String> familyColorMap = new Map<String, String>();
    /*Set que contiene la lista de familias de booking*/
    private static Set<String> bookingFamilySet = new Set<String>();
    /*Mapa que contiene year-family-revenues*/
    private static Map<String, Map<String, Double>> yearMap = new Map<String, Map<String, Double>>();
    /*Mapa que contiene year-family-revenues*/
    private static String clientId = '';
    
    /*
    * @author Global Desktop
    * @description Recupera el id del cliente del AP
    */
    @AuraEnabled
    public static String getClientId(String accountPlanId) {
        clientId = [SELECT acpl__participant_id__c FROM acpl__Account_Planning__c WHERE Id = :accountPlanId].acpl__participant_id__c;
        System.debug('clientId: ' + clientId);
        return clientId;
    }
    
    
    /*
    * @author Global Desktop
    * @description Recupera las oportunidades denormalizadas relacionadas con la cuenta
    */
    @AuraEnabled
    public static String getData(String accountPlanId, String country) {
        system.debug('>>>>> FUNCION getData. ID Account Plan : ' + accountPlanId);
        String currentYear = String.valueof(Date.Today().Year());
        String lastYear = String.valueof(Date.Today().Year() - 1);
        String nextYear = String.valueof(Date.Today().Year() + 1);
        
        clientId = getClientId(accountPlanId);
        final List<DES_Booking__c> bookingList = getBookingList(clientId, country);
        
        Set<String> familySet = new Set<String>();
        Map<String, Double> famRevenuesMap = new Map<String, Double>();
        //Map<String, Map<String, Double>> yearMap = new Map<String, Map<String, Double>>();
        System.debug('bookingList: ' + bookingList);
        //Creo el mapa(familia, suma de revenues)
        for(DES_Booking__c bookingAux : bookingList) {
            System.debug('bookingAux: ' + bookingAux);
            //si no tengo año, tampoco tengo familia
            if(yearMap.get(bookingAux.DES_Year__c) == null) {
                System.debug('yearMap - si no tengo año, tampoco tengo familia antes: ' + yearMap);
                Map<String, Double> famRevenuesMapAux = new Map<String, Double>(); 
                famRevenuesMapAux.put(bookingAux.DES_Type__c, bookingAux.DES_Revenues__c);    
                yearMap.put(bookingAux.DES_Year__c, famRevenuesMapAux);
                System.debug('famRevenuesMapAux - si no tengo año, tampoco tengo familia después: ' + famRevenuesMapAux);
                System.debug('yearMap - si no tengo año, tampoco tengo familia después: ' + yearMap);
                
                if(!bookingFamilySet.contains(bookingAux.DES_Type__c)) {
                	bookingFamilySet.add(bookingAux.DES_Type__c);
                }
            } else {
                //si tengo año
                //si no tengo familia
                if(yearMap.get(bookingAux.DES_Year__c).get(bookingAux.DES_Type__c) == null) {
                    System.debug('yearMap - si tengo año, si no tengo familia antes: ' + yearMap);
                    Map<String, Double> famRevenuesMapAux2 = new Map<String, Double>(); 
                	famRevenuesMapAux2.putAll(yearMap.get(bookingAux.DES_Year__c));                        
                    famRevenuesMapAux2.put(bookingAux.DES_Type__c, bookingAux.DES_Revenues__c);    
                	yearMap.put(bookingAux.DES_Year__c, famRevenuesMapAux2);
                    System.debug('famRevenuesMapAux - si tengo año, si no tengo familia después: ' + famRevenuesMapAux2);
                    System.debug('yearMap - si tengo año, si no tengo familia después: ' + yearMap);
                    
                    if(!bookingFamilySet.contains(bookingAux.DES_Type__c)) {
                        bookingFamilySet.add(bookingAux.DES_Type__c);
                    }
                } else {
                    //si tengo familia
                    System.debug('yearMap - si tengo año, si tengo familia antes: ' + yearMap);
                    Map<String, Double> famRevenuesMapAux3 = new Map<String, Double>();
					famRevenuesMapAux3 = yearMap.get(bookingAux.DES_Year__c);
                   	famRevenuesMapAux3.put(bookingAux.DES_Type__c ,
                    yearMap.get(bookingAux.DES_Year__c).get(bookingAux.DES_Type__c) + bookingAux.DES_Revenues__c  );
                    
                    //famRevenuesMapAux3.put(bookingAux.DES_Type__c, yearMap.get(bookingAux.DES_Year__c).put(bookingAux.DES_Type__c, famRevenuesMapAux3.get(bookingAux.DES_Type__c, yearMap.get(bookingAux.DES_Year__c).get(bookingAux.DES_Type__c) + bookingAux.DES_Revenues__c )));
                    yearMap.put(bookingAux.DES_Year__c, famRevenuesMapAux3);
                    System.debug('famRevenuesMapAux - si tengo año, si tengo familia después: ' + famRevenuesMapAux3);
                    System.debug('yearMap - si tengo año, si tengo familia después: ' + yearMap);
                }
            }
        }
        System.debug('yearMap final: ' + yearMap);
        System.debug('bookingFamilySet: ' + bookingFamilySet);
		
        getFamilyColor(bookingFamilySet);
        System.debug('familyColorMap = '+JSON.serialize(familyColorMap));
        
        final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(familyColorMap, yearMap);

        System.debug('jsonGlobal = '+JSON.serialize(wrapperGlobal));
        
        return JSON.serialize(wrapperGlobal);
    }

    /*
    * @author Global Desktop
    * @description Recupera la lista de booking
    */
    public static List<DES_Booking__c> getBookingList(String clientId, String country) {
        List<DES_Booking__c> bookingList;
        bookingList = new List<DES_Booking__c>();
        System.debug('country: ' + country);
        if(country == null || country == '') {
            bookingList = [SELECT Id, convertCurrency(DES_Revenues__c), DES_Type__c, DES_Year__c FROM DES_Booking__c WHERE DES_Client__c = :clientId];
        } else {
            bookingList = [SELECT Id, convertCurrency(DES_Revenues__c), DES_Type__c, DES_Year__c FROM DES_Booking__c WHERE DES_Client__c = :clientId
                                               AND toLabel(DES_Country__c) = :country];
        }
        return bookingList;
    }
    
    /**
	* @author Global Desktop
	* @description Recupera los departamentos del metadato
	*/
    public static void getFamilyColor(Set<String> bookingFamilySet) {
        final List<Booking_family_color__mdt> familyColorList = [select DeveloperName,  Color__c from Booking_family_color__mdt where DeveloperName IN :bookingFamilySet];

        if(!familyColorList.isEmpty()) {
           for(Booking_family_color__mdt famColorAux : familyColorList) {
               if(famColorAux.DeveloperName != null && famColorAux.Color__c != null
                && familyColorMap.get(famColorAux.DeveloperName) == null) {
                    familyColorMap.put(famColorAux.DeveloperName, famColorAux.Color__c);
                }
           }
        }
    }//getFamilyColor

    
    
    /**
	* @author Global Desktop
	* @description Clase wrapper para devolver los datos
	*/
    public class WrapperGlobalData {
        /**
        * @author Global Desktop
        * @description mapDepCols
        */
        private Map<String, String> familyColorMap;//NOSONAR . used in client side
        /**
        * @author Global Desktop
        * @description mapData
        */
        private Map<String, Map<String, Double>> yearMap; //NOSONAR
        /**
		* @author Global Desktop
		* @description Construye la lista wrapper
		*/
        public WrapperGlobalData (Map<String, String> familyColorMap, Map<String, Map<String, Double>> yearMap) {
            this.familyColorMap = familyColorMap;
            this.yearMap = yearMap;
        }
    }
    

    /*
    * @author Global Desktop
    * @description Recupera los datos de la tabla
    */
    @AuraEnabled
    public static String getTableData(String accountPlanId, String country) {
        clientId = getClientId(accountPlanId);
        List<DES_Booking__c> bookingList;
        bookingList = new List<DES_Booking__c>();
        System.debug('country d la tabla: ' + country);
        if(country == null || country == '') {
        	bookingList = [SELECT Id, DES_Client__c, DES_Client__r.Name, DES_Year__c, DES_Type__c, toLabel(DES_Country__c), SOLUTION_CATEGORY_NAME__c, convertCurrency(DES_Revenues__c) 
                           FROM DES_Booking__c WHERE DES_Client__c = :clientId order by DES_Year__c, DES_Type__c];
        } else {
        	bookingList = [SELECT Id, DES_Client__c, DES_Client__r.Name, DES_Year__c, DES_Type__c, toLabel(DES_Country__c), SOLUTION_CATEGORY_NAME__c, convertCurrency(DES_Revenues__c) 
                           FROM DES_Booking__c WHERE DES_Client__c = :clientId AND toLabel(DES_Country__c) = :country order by DES_Year__c, DES_Type__c];
        }
        List<WrapperClass> listWrapper = new List<WrapperClass>();
        Map<String, WrapperClass> wrapperMap;
        wrapperMap = new Map<String, WrapperClass>();
        
        for(DES_Booking__c bookingAux : bookingList) {
            if(wrapperMap.get(bookingAux.DES_Year__c + bookingAux.DES_Type__c + bookingAux.DES_Country__c + bookingAux.SOLUTION_CATEGORY_NAME__c) == null) {
                wrapperMap.put(bookingAux.DES_Year__c + bookingAux.DES_Type__c + bookingAux.DES_Country__c + bookingAux.SOLUTION_CATEGORY_NAME__c,
                               new WrapperClass(bookingAux.DES_Client__c, bookingAux.DES_Client__r.Name, bookingAux.DES_Year__c, bookingAux.DES_Type__c, bookingAux.DES_Country__c, bookingAux.SOLUTION_CATEGORY_NAME__c, 
                                                bookingAux.DES_Revenues__c));
            } else {
                WrapperClass wrapperClassAux = wrapperMap.get(bookingAux.DES_Year__c + bookingAux.DES_Type__c + bookingAux.DES_Country__c + bookingAux.SOLUTION_CATEGORY_NAME__c);
                wrapperClassAux.revenues += bookingAux.DES_Revenues__c;
                wrapperMap.put(bookingAux.DES_Year__c + bookingAux.DES_Type__c + bookingAux.DES_Country__c + bookingAux.SOLUTION_CATEGORY_NAME__c,
                               wrapperClassAux);
            }
        }
        
        system.debug('>>>>>wrapperMap : ' + wrapperMap);
        return JSON.serialize(wrapperMap.values()); 
        
    }


    /*
    * @author Global Desktop
    * @description Recuera el Iso code del usuario logado
    */
    @AuraEnabled
    public static String getCurrentUserISOCode() {
        return UserInfo.getDefaultCurrency();
    }
    
    /*
    * @author Global Desktop
    * @description construye la lista wrapper que devuelve la informacion al componente lightning
    */
    public class WrapperClass {
        /**
    * @author Global Desktop
    * @description Variables de la lista wrapper
    */
        private String clientUrl; //NOSONAR
        /*
        * wrapper field
        */
        private String clientName; //NOSONAR
        /*
        * wrapper field
        */
        private String year; //NOSONAR
        /*
        * wrapper field
        */
        private String family; //NOSONAR
        /*
        * wrapper field
        */
        private String country; //NOSONAR
        /*
        * wrapper field
        */
        private String product; //NOSONAR
        /*
        * wrapper field
        */
        private Decimal revenues; //NOSONAR
        
        /**
        * @author Global Desktop
        * @description Construye la clase wrapper
        */
        public WrapperClass(String clientId, String clientName, String year, String family, String country, String product, Decimal revenues) {
            this.clientUrl = '/lightning/r/Account/' + clientId + '/view';
            this.clientName = clientName;
            this.year = year;
            this.family = family;
            this.country = country;
            this.product = product;
            this.revenues = revenues;
        }
    }
    
    /*
    * @author Global Desktop
    * @description Recupera los países
    */
    @AuraEnabled
    public static List<String> getCountries(String accountPlanId) {
        System.debug('getCountries - accountPlanId: ' + accountPlanId);
        clientId = getClientId(accountPlanId);
        List<DES_Booking__c> bookingList = [SELECT toLabel(DES_Country__c) FROM DES_Booking__c WHERE DES_Client__c = :clientId ORDER BY DES_Country__c ASC];
        List<String> countryList;
        countryList = new List<String>();
        for(DES_Booking__c bookingAux : bookingList) {
            if(!countryList.contains(bookingAux.DES_Country__c)) {
                countryList.add(bookingAux.DES_Country__c);
            }
        }
        System.debug('countryList en apex: ' + countryList);
        return countryList; 
        
    }
}