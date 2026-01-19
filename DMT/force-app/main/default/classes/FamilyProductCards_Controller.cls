/************************************************************************************************************************************
Name:           FamilyProductCards_Controller class
Description:    Controlador para devolver la informacion al componente lightning FamilyProductCards

Version        Date            Author                       Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------
0.1            22/11/2018      GlobalDesktop         		Initial Version
**************************************************************************************************************************************/
public with sharing class FamilyProductCards_Controller {

	/**
	* @author Global Desktop
	* @escription Campo para instanciar la clase
	*/
    private static FamilyProductCards_Controller instance;


	/**
	* @author Global Desktop
	* @escription Constructor
	*/
    private FamilyProductCards_Controller() {

    }

    /**
	* @author Global Desktop
	* @escription Singleton Pattern
	*/
    public static FamilyProductCards_Controller getInstance() {  //NOSONAR
        if (instance == null) {
        	instance = new FamilyProductCards_Controller();
        }
        return instance;
    }

	/**
	* @author Global Desktop
	* @escription Recupera el iso code del usuario
	*/
	@AuraEnabled
    public static String currentUserISOCode() {
    	try {
        return UserInfo.getDefaultCurrency();
    	} catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
    }


	/**
	* @author Global Desktop
	* @escription Recupera los Revenues relacionados con la cuenta
	*/
	@AuraEnabled
    public static String getRevenuesData(String recordId, String objectName, String country) {
    	try {

	    	final Account relatedAcc = [SELECT id, DES_Revenue_Update_Engloba__c FROM Account WHERE Id = :recordId LIMIT 1];
	    	final Integer anioCarga = Integer.valueOf(relatedAcc.DES_Revenue_Update_Engloba__c.substring(0,4));

	    	final List<DES_Booking__c> relatedBook = getRelatedBookings(recordId, country, anioCarga);

	    	final map<String, DES_Booking__c> familyMapBooking = new map<String, DES_Booking__c>();
	    	final Schema.DescribeFieldResult fieldResult = DES_Booking__c.DES_Type__c.getDescribe();
			final List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

			for( Schema.PicklistEntry v : values) {
			    if(v.getValue() != 'CO' && v.getValue() != 'GL' && v.getValue() != 'GF' && v.getValue() != 'CF') {
			    	familyMapBooking.put(v.getLabel(), new DES_Booking__c(DES_Revenues__c = 0,DES_Type__c=v.getLabel()));
			    }
			}

			for(DES_Booking__c bAux : relatedBook) {
	    		sumRevInFamilies(familyMapBooking, bAux);
	    	}

	    	final List<wrapperClass> listWrapperClass = new List<wrapperClass>();
	    	for(DES_Booking__c bMapAux : familyMapBooking.values()) {
				Final Decimal valueM = bMapAux.DES_Revenues__c / 1000000;
	    		listWrapperClass.add(new wrapperClass(bMapAux.DES_Type__c, valueM.setScale(2, RoundingMode.HALF_UP)));
	    	}

	    	return JSON.serialize(listWrapperClass);
    	} catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
    }


    /**
	* @author Global Desktop
	* @description Clase auxiliar agrupar en mapas por familias el valor de los Revenues
	*/
    public static void sumRevInFamilies(map<String, DES_Booking__c> familyMapBooking, DES_Booking__c bAux) {
    	if(familyMapBooking.get(bAux.DES_Type__c) != null && familyMapBooking.get(bAux.DES_Type__c).DES_Revenues__c == null) {
			familyMapBooking.put(bAux.DES_Type__c, bAux);
		} else if(familyMapBooking.get(bAux.DES_Type__c) != null && familyMapBooking.get(bAux.DES_Type__c).DES_Revenues__c != null) {
			familyMapBooking.get(bAux.DES_Type__c).DES_Revenues__c = familyMapBooking.get(bAux.DES_Type__c).DES_Revenues__c + bAux.DES_Revenues__c;
		}
    }


    /**
	* @author Global Desktop
	* @description Clase auxiliar para recoger los revenues relacionados filtrados por país
	*/
    public static List<DES_Booking__c> getRelatedBookings(String recordId, String country, Integer anioCarga) {
		List<DES_Booking__c> relatedBookAux = new List<DES_Booking__c>();
		if(country == null || string.isBlank(country) || string.isEmpty(country) || country == 'Todos') {
	    		relatedBookAux = [SELECT Id, DES_Type__c, convertCurrency(DES_Revenues__c)
								 FROM DES_Booking__c
							    WHERE DES_Client__c = :recordId AND DES_Year_Number__c = :anioCarga];
	    	} else {
	    		final Map<String,String> mapContryCodes= GroupGeographyCnt.helperCreateMapCountryCodes('BOOKCOUNTRY');
	  			final String countryDevName = mapContryCodes.get(country);
	  			relatedBookAux = [SELECT Id, DES_Type__c, convertCurrency(DES_Revenues__c)
							     FROM DES_Booking__c
							    WHERE DES_Client__c = :recordId AND DES_Year_Number__c = :anioCarga AND DES_Country__c = :countryDevName];
	    	}
	    	return relatedBookAux;
	}


	/**
	* @author Global Desktop
	* @description Clase que devuelve la lista con los datos necesarios al componente lightning
	*/
    public class wrapperClass {
    	/**
    	* @author Global Desktop
    	* @description Variables de la lista wrapper
    	*/
    	private String familyName; //NOSONAR
    	private Decimal amountRevenues; //NOSONAR

		/**
		* @author Global Desktop
		* @description Contruye la lista de la clase wrapper
		*/
    	public wrapperClass(String familyNameInput, Decimal amountRevInput) {
    		this.familyName = familyNameInput;
    		this.amountRevenues = amountRevInput;
    	}
    }

}