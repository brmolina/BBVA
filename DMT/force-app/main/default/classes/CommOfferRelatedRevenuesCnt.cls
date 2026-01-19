/*
*   @author: GlobalDesktop
*   @Method: CommOfferRelatedRevenuesCnt
*   @Description: Recupera los datos de oportunidades relacionadas a la oferta comercial

*   @Versions:
        v1 - 2020/05/18 - Initial version
*/
public with sharing class CommOfferRelatedRevenuesCnt {
	/**
    * @author Global Desktop
    * @description SINGLETON PATTERN
    */
    private static CommOfferRelatedRevenuesCnt instance;

    /**
    * @author Global Desktop
    * @description getInstance
    */
    public static CommOfferRelatedRevenuesCnt getInstance() { //NOSONAR
        if (instance == null) {
            instance = new CommOfferRelatedRevenuesCnt();
        }
        return instance;
    }

   /*
    * Met0d0 para pasar sonar
    */
    private CommOfferRelatedRevenuesCnt() {}

	/*Recupera la información de los revenues de las oportunidades relacionadas a la oferta comercial*/
	@auraEnabled
    public static String getData(String offerId, String fieldSum) {
    	final List<Opportunity> relOpps = [SELECT Name, convertCurrency(DES_Expected_Revenues__c), convertCurrency(pre_oppy_revenue_next_12m_amount__c)
    								FROM Opportunity WHERE coff__gf_commercial_offer_id__c = :offerId];
		system.debug(relOpps);
    	final Map<String, Decimal> oppData = new Map<String, Decimal>();
    	Map<String, String> mapColors = new Map<String, String>();
    	if(fieldSum == Label.Expected) {
	    	for(Opportunity opp : relOpps) {
	    		oppData.put(opp.Name, opp.DES_Expected_Revenues__c);
	    	}
    	} else if(fieldSum == Label.Potential) {
    		for(Opportunity opp : relOpps) {
	    		oppData.put(opp.Name, opp.pre_oppy_revenue_next_12m_amount__c);
	    	}
    	}
    	mapColors = UtilsFichaGrupo.getCountryColor(oppData.keySet());
    	final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(mapColors, oppData);
        return JSON.serialize(wrapperGlobal);
    }
    
    /*
	* Global Desktop
	* Construye el formato de los datos que devuelve la clase
	*/
    public class WrapperGlobalData {
		/*
		* Mapa oportunidad-color
		*/
        private final Map<String, String> mapRowColors; //NOSONAR
		/*
		* mapa oportunidad-valor
		*/
        private final Map<String, Decimal> mapSimpleData; //NOSONAR
		/*
		* Public constructor
		*/
        public WrapperGlobalData (Map<String, String> prodColors, Map<String, Decimal> data) {
            this.mapRowColors = prodColors;
            this.mapSimpleData = data;
        }
    }
    
    /*Recupera la información de las oportunidades relacionadas a la oferta comercial y los devuelve en formato tabla*/
	@auraEnabled
    public static String getDataTable(String offerId) {
    	system.debug('Funciion getDataTable');
    	final List<Opportunity> oppsTable = [SELECT Id, Name, DES_Booking_Geography__c, convertCurrency(pre_oppy_revenue_next_12m_amount__c),
    									convertCurrency(DES_Expected_Revenues__c), Probability
    								FROM Opportunity WHERE coff__gf_commercial_offer_id__c = :offerId];
    								
		final List<wrapperClass> listWrapperClass = new List<wrapperClass>();
		for(Opportunity opp : oppsTable) {
			listWrapperClass.add(new wrapperClass(opp.Id, opp.Name, opp.DES_Booking_Geography__c, String.valueOf(opp.pre_oppy_revenue_next_12m_amount__c),
												String.valueOf(opp.DES_Expected_Revenues__c), String.valueOf(opp.Probability)));
		}
    	
    	return JSON.serialize(listWrapperClass);
    }
	
	/*
	* Clase wrapper para construir el JSON
	*/
    public class wrapperClass {
	  /*
  	  * @author Global Desktop
  	  * @description Declaracion de los campos de la lista wrapper
  	  */
      private String oppId; //NOSONAR
      private String oppUrl; //NOSONAR
      private String oppName; //NOSONAR
      private String oppCountry; //NOSONAR
      private String oppPotential; //NOSONAR
      private String oppExpected; //NOSONAR
      private String oppProb; //NOSONAR
 
        /*
		* @author Global Desktop
		* @description Construye la lista wrapper
		*/
        public wrapperClass(String oppIdP, String oppNameP, String oppCountryP, String oppPotentialP, String oppExpectedP, String oppProbP) { //NOSONAR
            this.oppId = oppIdP;
            this.oppUrl = '/lightning/r/Opportunity/' + oppId + '/view';
            this.oppName = oppNameP;
            this.oppCountry = oppCountryP;
            this.oppPotential = oppPotentialP+' '+UserInfo.getDefaultCurrency(); 
            this.oppExpected = oppExpectedP+' '+UserInfo.getDefaultCurrency();
            this.oppProb = oppProbP+'%';
        }
  	}

}