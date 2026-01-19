/*****************************************************************************************
Name:            RCFExpirationCnt
Description:     Controlador del componente lightning RCFExpiration

Version        Date            Author            Summary of changes
-----------------------------------------------------------------------------------------
0.1            23/05/2019      Global Desktop    Controlador del componente lightning RCFExpiration
*****************************************************************************************/
public with sharing class RCFExpirationCnt {

	/*
    * Variable EURVIVO
    */
    private final static String EURVIVO = 'Importe participación EUR BBVA Vivo';

	/*
    * Variable EURTOTAL
    */
    private final static String EURTOTAL = 'Importe participación EUR BBVA Total';

	/**
    * SINGLETON PATTERN
    */
    private static RCFExpirationCnt instance;

    /**
    * Constructor
    */
    private RCFExpirationCnt() {
    }

    /**
    * getInstance
    */
    public static RCFExpirationCnt gtInstance() {
        if (instance == null) {
            instance = new RCFExpirationCnt();
        }
        return instance;
    }

	/*
	* @author Global Desktop
	* @description Recupera los Revenues relacionados con el cliente
	*/
	@AuraEnabled
  	public static String getData(String clientId) {
  		try {
			String querySelect;
			String queryWhere;
			String queryOrder;
			querySelect = 'SELECT id, convertCurrency(bbva_prtcp_tranche_amount__c), convertCurrency(deal_total_amount__c), CurrencyIsoCode, current_expiry_date__c, LastModifiedDate, participant_id__c, solution_category_desc__c ';
			querySelect += ' FROM RCF_Expiration__c ';
			if(clientId != null) {
				queryWhere = ' WHERE participant_id__c = \'' + String.escapeSingleQuotes(clientId) + '\'';
			}
            queryOrder = ' ORDER BY current_expiry_date__c DESC';
			final String query = querySelect + queryWhere + queryOrder;
			final List <RCF_Expiration__c> listRCF = Database.query(query); //NOSONAR la variable ya está escapada

			final String dateCLIP = getDateCLIP(listRCF);

			final Map<String, Map<String, Decimal>> mapData = setMap(listRCF);
			final Map<String, String> mapColors = setMapColor();
			final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(mapColors, mapData, dateCLIP);
			system.debug('** JSON.serialize -> ' + JSON.serialize(wrapperGlobal));

			system.debug('** mapData -> ' + JSON.serialize(mapData));

        	return JSON.serialize(wrapperGlobal);
	  	} catch (Exception exc) {
        	throw new AuraHandledException(Label.DES_Error + exc);
    	}
	}

	/*
    * Aux method to set data
    */
    private static String getDateCLIP(List <RCF_Expiration__c> listRCF) {
		String dateCLIP = '';
        if(listRCF == null || listRCF.isEmpty() || listRCF.get(0).LastModifiedDate == null) {
			dateCLIP = 'no data';
		} else {
            final String dateColumns = DateTime.newInstance(listRCF.get(0).LastModifiedDate.year(),listRCF.get(0).LastModifiedDate.month(),listRCF.get(0).LastModifiedDate.day()).format('MMM YYYY');
			dateCLIP = dateColumns;
		}
		return dateCLIP;
	}

	/*
    * Aux method to set data
    */
    private static Map<String, Map<String, Decimal>> setMap(List <RCF_Expiration__c> listRCF) {
        final Map<String, Map<String, Decimal>> mapData = new Map<String, Map<String, Decimal>>();
        final Map<String, Decimal> mapValues1 = new Map<String, Decimal>();
        final Map<String, Decimal> mapValues2 = new Map<String, Decimal>();

        for(RCF_Expiration__c expiration : listRCF) {
			String dateString;
            if(expiration.current_expiry_date__c == null) {
				system.debug('** No data -> ' + mapValues1 + ' ' + mapValues2);
			} else {
                final Integer day = expiration.current_expiry_date__c.day();
                final Integer month = expiration.current_expiry_date__c.month();
				final Integer year = expiration.current_expiry_date__c.year();
				final String dayString = String.valueof(day);
				final String monthString = String.valueof(month);
				final String yearString = String.valueof(year);
				dateString = dayString.leftPad(2,'0') + '/' + monthString.leftPad(2,'0') + '/' + yearString.substring(yearString.length()-2, yearString.length());
			}

            if(expiration.bbva_prtcp_tranche_amount__c != null) {
                mapValues1.put(expiration.solution_category_desc__c + '<br>' + dateString, expiration.bbva_prtcp_tranche_amount__c);
            	mapData.put(RCFExpirationCnt.EURVIVO, mapValues1);
            }else {

                mapValues1.put(expiration.solution_category_desc__c + '<br>' + dateString, 0);
            	mapData.put(RCFExpirationCnt.EURVIVO, mapValues1);
            }

            if(expiration.bbva_prtcp_tranche_amount__c != null) {
				mapValues2.put(expiration.solution_category_desc__c + '<br>' + dateString, expiration.deal_total_amount__c - 0);
				mapData.put(RCFExpirationCnt.EURTOTAL, mapValues2);
            }else {
                mapValues2.put(expiration.solution_category_desc__c + '<br>' + dateString, 0 );
				mapData.put(RCFExpirationCnt.EURTOTAL, mapValues2);
            }
        }
		system.debug('** No data -> ' + mapValues1 + ' ' + mapValues2);
        return mapData;
    }

	/*
    * Aux method to set data
    */
	@AuraEnabled
    public static String getDataDetails(String clientId) {
		try {
			String querySelect;
			String queryWhere;
			String queryOrder;
            querySelect = 'SELECT id, convertCurrency(bbva_prtcp_tranche_amount__c), convertCurrency(deal_total_amount__c), CurrencyIsoCode, current_expiry_date__c, LastModifiedDate, participant_id__c, participant_id__r.name, solution_category_desc__c ';
			querySelect += ' FROM RCF_Expiration__c ';
				if(clientId != null) {
					queryWhere = ' WHERE participant_id__c = \'' + String.escapeSingleQuotes(clientId) + '\'';
				}
			queryOrder = ' ORDER BY LastModifiedDate DESC';
			final String query = querySelect + queryWhere + queryOrder;
			final List <RCF_Expiration__c> listRCF = Database.query(query); //NOSONAR la variable ya está escapada

			final List<WrapperDetailData> lDetailDate = new List<WrapperDetailData>();

			for(RCF_Expiration__c expiration : listRCF) {
				lDetailDate.add(new WrapperDetailData(expiration));
			}

			return JSON.serialize(lDetailDate);
		} catch (Exception exc) {
        	throw new AuraHandledException(Label.DES_Error + exc);
    	}
    }

    /*
    * Aux method to set color data
    */
    private static Map<String, String> setMapColor() {
        final Set<String> setColumns = new Set<String>();
        setColumns.add(RCFExpirationCnt.EURVIVO);
        setColumns.add(RCFExpirationCnt.EURTOTAL);
        return UtilsFichaGrupo.getCountryColor(setColumns);
    }

    /*
    * Wrapper to set Data and colors
    */
    public class WrapperGlobalData {
        /*
        * Attribute for colors
        */
        private final Map<String, String> mapColors;
        /*
        * Attribute for data
        */
        private final Map<String, Map<String, Decimal>> mapData;
        /*
        * Attribute for data
        */
        private final String dateCLIP;

		/*
		* Constructor for WrapperGlobalData
		*/
        public WrapperGlobalData (Map<String, String> colors, Map<String, Map<String, Decimal>> data, String dateCLIP) {
			this.dateCLIP = String.valueof(dateCLIP);
            this.mapColors = colors;
            this.mapData = data;
        }
    }

    /*
    * Aux method to format number
    */
    private static String formatNum(Decimal aux) {
        String auy = String.valueOf(aux);
        String auz = '.';
        String returnVal;
        returnVal = String.valueOf(aux);
        if(auy.contains(',')) {
            auz = ',';
        }
        auy = auy.substring(0, auy.indexOf(auz));
        if(aux - Decimal.valueOf(auy) == 0) {
            returnVal = aux.format() + auz + '00';
        } else {
            returnVal = aux.format();
        }
        return returnVal;
    }

	/*
	* @author Global Desktop
	* @description Construye la clase wrapper
	*/
    public class WrapperDetailData {
    	/*
		* @author Global Desktop
		* @description Variables de la clase wrapper
		*/
  		private String urlRecord; //NOSONAR
		/*
		* Variable expDate
		*/
  		private Date expDate; //NOSONAR
		/*
		* Variable lastModDate
		*/
  		private Datetime lastModDate; //NOSONAR
		/*
		* Variable participant
		*/
  		private String participant; //NOSONAR
		/*
		* Variable expDaproductTypete
		*/
  		private String productType; //NOSONAR
		/*
		* Variable creditAmount
		*/
  		private String creditAmount; //NOSONAR
		/*
		* Variable shareAmount
		*/
  		private String shareAmount; //NOSONAR

		/*
		* @author Global Desktop
		* @description Construye la lista wrapper
		*/
      	public WrapperDetailData(RCF_Expiration__c record) {

	        this.urlRecord = '/lightning/r/Account/' + record.participant_id__r.Id + '/view';
            this.expDate = record.current_expiry_date__c;
            this.lastModDate = record.LastModifiedDate;
	        this.participant = record.participant_id__r.name==null?'':record.participant_id__r.name;
            this.productType = record.solution_category_desc__c==null?'':record.solution_category_desc__c;
            this.creditAmount = record.deal_total_amount__c==null?'':formatNum(record.deal_total_amount__c) + ' ' + UserInfo.getDefaultCurrency();
            this.shareAmount = record.bbva_prtcp_tranche_amount__c==null?'':formatNum(record.bbva_prtcp_tranche_amount__c) + ' ' + UserInfo.getDefaultCurrency();
      	}
    }
}