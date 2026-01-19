public with sharing class OppsCommercialActivityController {

	/*
	* @author Global Desktop
	* @description Fucion para recuperar la informacion de las oportunidades relacionadas a la cuenta
	*/
    @auraEnabled
    public static String getOppInfo(String accId, String country) {
    	try {
			//Label.DES_RT_Subsidiary;
	        List<wrapperClass> listWrapperClass = new List<wrapperClass>();
	        List<dwp_acmh__Denorm_Account_Opportunity__c> oppDenormList = new List<dwp_acmh__Denorm_Account_Opportunity__c>();
	        if(country == null || string.isBlank(country) || string.isEmpty(country) || country == 'Todos') {
				oppDenormList = [SELECT Id, convertCurrency(dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c), convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c),dwp_acmh__OpportunityId__r.StageName, dwp_acmh__AccountId__r.CurrencyIsoCode, dwp_acmh__AccountId__r.DES_Structure_Type__c
		                           FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE dwp_acmh__AccountId__c =: accId
	                         		AND dwp_acmh__OpportunityId__r.CreatedDate = THIS_YEAR];
	        } else {
	            final List<Opp_Countries__mdt> lstCountryCodes = GroupGeographyCnt.mapCountryCodesSelector();
	            final Map<String,String> mapContryCodes= GroupGeographyCnt.helperCreateMapCountryCodes('LABEL', lstCountryCodes);
	  			final String countryDevName = mapContryCodes.get(country);
	        	final set<Id> countryAccountIds = OpportunitiesInProgressByFamilyCont.getFieldLabels(accId, country);
	        	oppDenormList = [SELECT Id, convertCurrency(dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c), convertCurrency(dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c),dwp_acmh__OpportunityId__r.StageName, dwp_acmh__AccountId__r.CurrencyIsoCode, dwp_acmh__AccountId__r.DES_Country_Client__c, dwp_acmh__AccountId__r.DES_Structure_Type__c
	                         	   FROM dwp_acmh__Denorm_Account_Opportunity__c
	                         	  WHERE dwp_acmh__OpportunityId__r.CreatedDate = THIS_YEAR AND dwp_acmh__AccountId__c IN :countryAccountIds
	                             	AND dwp_acmh__AccountId__r.DES_Country_Client__c = :countryDevName];
            }


            if(oppDenormList.size()>0) {
                listWrapperClass = wrapperListToReturn(oppDenormList);
            }

	        return JSON.serialize(listWrapperClass);

    	} catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
    }

    /*
	* @author Global Desktop
	* @description Fucion auxiliar para formar la lista wrapper
	*/
    public static List<wrapperClass> wrapperListToReturn(List<dwp_acmh__Denorm_Account_Opportunity__c> oppDenormList) {

    	Decimal sumWon = 0;
        Integer sizeWon = 0;
        Decimal sumLost = 0;
        Integer sizeLost = 0;
        Decimal sumLive = 0;
        Integer sizeLive = 0;
        Integer numOpp = oppDenormList.size();
        String oppType = '';
        for(dwp_acmh__Denorm_Account_Opportunity__c i : oppDenormList) {
            if(i.dwp_acmh__OpportunityId__r.StageName == Label.DES_Closed_Won) {
                sumWon = sumWon + i.dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c;
                sizeWon = sizeWon + 1;
            } else if(i.dwp_acmh__OpportunityId__r.StageName == Label.DES_Closed_Lose) {
                sumLost = sumLost + (i.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c == null ? 0 : i.dwp_acmh__OpportunityId__r.pre_oppy_revenue_next_12m_amount__c);
                sizeLost = sizeLost + 1;
            } else {
                sumLive = sumLive + i.dwp_acmh__OpportunityId__r.DES_Expected_Revenues__c;
                sizeLive = sizeLive + 1;
			}

			oppType = i.dwp_acmh__AccountId__r.DES_Structure_Type__c;
        }

		//parsing values to X.XX M (Millions)
		sumWon = sumWon!=0?sumWon / 1000000:sumWon;
		sumLost = sumLost!=0?sumLost / 1000000:sumLost;
		sumLive = sumLive!=0?sumLive / 1000000:sumLive;


        final List<wrapperClass> lWrapClassAux = new List<wrapperClass>();
        lWrapClassAux.add(new wrapperClass(numOpp,sumWon,sumLost,sizeWon,sizeLost,oppType,sizeLive,sumLive));
        return lWrapClassAux;
    }


	/*
	* @author Global Desktop
	* @description Construye la clase wrapper que devolvera al componente
	*/
    public class wrapperClass {
    	/**
		* @author Global Desktop
		* @description Declaracion de variables de la lista wrapper
		*/
		/*
		* Attribute
		*/
        private Integer returnTotalOpp; //NOSONAR
		/*
		* Attribute
		*/
        private String returnWon; //NOSONAR
		/*
		* Attribute
		*/
        private String returnLost; //NOSONAR
		/*
		* Attribute
		*/
        private String returnCurrencyCode; //NOSONAR
		/*
		* Attribute
		*/
        private Integer oppWonNumber; //NOSONAR
		/*
		* Attribute
		*/
        private Integer oppLostNumber; //NOSONAR
		/*
		* Attribute
		*/
        private String oppType; //NOSONAR
		/*
		* Attribute
		*/
        private String hitMiss; //NOSONAR
		/*
		* Attribute
		*/
        private Integer oppLiveNumber; //NOSONAR
		/*
		* Attribute
		*/
        private String returnLive; //NOSONAR

		/**
		* @author Global Desktop
		* @description Contruye la lista wrapper
		*/
        public wrapperClass(Integer totalOpp, Decimal won, Decimal lost, Integer sizeOppWon, Integer sizeOppLost, String oppType, Integer sizeOppLive, Decimal live) {
            this.returnTotalOpp = totalOpp;

			final List<String> args = new String[] {'0','number','###.###.##0,00'};
			final Decimal wonFormat = won.setScale(2);
			final String sWonFormat = String.format(wonFormat.format(), args);
	        this.returnWon = sWonFormat;

	        final Decimal lostFormat = lost.setScale(2);
	        final String sLostFormat = String.format(lostFormat.format(), args);
	        this.returnLost = sLostFormat;

	        final Decimal liveFormat = live.setScale(2);
	        final String sLiveFormat = String.format(liveFormat.format(), args);
	        this.returnLive = sLiveFormat;

			this.returnCurrencyCode = UserInfo.getDefaultCurrency();
	        this.oppWonNumber = sizeOppWon;
	        this.oppLostNumber = sizeOppLost;
	        this.oppLiveNumber = sizeOppLive;
	        this.oppType = oppType;


			final Decimal value = (oppWonNumber==0&&oppWonNumber+oppLostNumber==0)||oppWonNumber+oppLostNumber==0?0:(oppWonNumber*100.0)/(oppWonNumber+oppLostNumber);
            final Decimal hitMissFormat = value.setScale(2);
	        final String sHitMissFormat = String.format(hitMissFormat.format(), args);
	        this.hitMiss = sHitMissFormat;
        }
    }
}