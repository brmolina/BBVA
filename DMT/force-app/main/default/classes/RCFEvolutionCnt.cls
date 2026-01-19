/*
* Controller of component RCFEvolution
*/
public with sharing class RCFEvolutionCnt {

    /*
    * Variable Use
    */
    private final static String USE = '% of Use';

    /**
    * SINGLETON PATTERN
    */
    private static RCFEvolutionCnt instance;

    /**
    * Constructor
    */
    private RCFEvolutionCnt() {
    }

    /**
    * getInstance
    */
    public static RCFEvolutionCnt gtInstance() {
        if (instance == null) {
            instance = new RCFEvolutionCnt();
        }
        return instance;
    }

    /*
    *   @author: GlobalDesktop
    *   @Method: getData
    *   @Description:
    *   @Versions:
            v1 - 2019/05/23 - Initial version
    */
    @AuraEnabled
    public static String getData(String clientId) {
        try {
            String querySelect;
            String queryWhere;
            querySelect = 'SELECT Id, credit_drawn_per__c, CurrencyIsoCode, year_month_day_date__c, LastModifiedDate, participant_id__r.Name, ';
            querySelect += 'participant_id__c, bbva_prtcp_tranche_amount__c, credit_drawn_amount__c FROM RCF_Evolution__c';
            if(clientId != null) {
                queryWhere = ' WHERE participant_id__c = \'' + String.escapeSingleQuotes(clientId) + '\'';
                queryWhere += ' ORDER BY year_month_day_date__c DESC';
            }
            final String query = querySelect + queryWhere;
            final List <RCF_Evolution__c> listRCF = Database.query(query); //NOSONAR la variable ya está escapada

            final String dateCLIP = getDateCLIP(listRCF);

            final Map<String, Map<String, Decimal>> mapData = setMap(listRCF);
            final Map<String, String> mapColors = setMapColor();
            final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(mapColors, mapData, dateCLIP);

            return JSON.serialize(wrapperGlobal);
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /*
    * Method to get data for report
    */
    @AuraEnabled
    public static String getDataReport(String clientId) {
        try {
            String querySelect;
            String queryWhere;
            querySelect = 'SELECT Id, credit_drawn_per__c, CurrencyIsoCode, year_month_day_date__c, LastModifiedDate, participant_id__r.Name, ';
            querySelect += 'participant_id__c, bbva_prtcp_tranche_amount__c, credit_drawn_amount__c FROM RCF_Evolution__c';
            if(clientId != null) {
                queryWhere = ' WHERE participant_id__c = \'' + String.escapeSingleQuotes(clientId) + '\'';
                queryWhere += ' ORDER BY year_month_day_date__c DESC';
            }
            final String query = querySelect + queryWhere;
            final List <RCF_Evolution__c> listRCF = Database.query(query); //NOSONAR la variable ya está escapada
            final List<WrapperReport> listWrapper = new List<WrapperReport>();
            for(RCF_Evolution__c ev : listRCF) {
                listWrapper.add(new WrapperReport(ev));
            }
            system.debug('>>>>>listWrapper : ' + listWrapper);
            return JSON.serialize(listWrapper);
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /*
    * Aux method to set data
    */
    private static Map<String, Map<String, Decimal>> setMap(List <RCF_Evolution__c> listRCF) {
        final Map<String, Map<String, Decimal>> mapData = new Map<String, Map<String, Decimal>>();
        final Map<String, Decimal> mapValues = new Map<String, Decimal>();

        for(RCF_Evolution__c ev : listRCF) {
            if(ev.year_month_day_date__c == null) {
                system.debug('** No data -> ' + mapValues);
            } else {
                final Integer month = ev.year_month_day_date__c.month();
                final Integer year = ev.year_month_day_date__c.year();
                final String monthString = String.valueof(month);
                final String yearString = String.valueof(year);
                final String dateString = monthString.leftPad(2,'0') + '/' + yearString.substring(yearString.length()-2, yearString.length());
                mapValues.put(dateString, ev.credit_drawn_per__c);
                mapData.put(RCFEvolutionCnt.USE, mapValues);
            }
        }
        return mapData;
    }

    /*
    * Aux method to set date
    */
    private static String getDateCLIP(List <RCF_Evolution__c> listRCF) {
		String dateCLIP = '';
		if(listRCF == null || listRCF.isEmpty() || listRCF.get(0).LastModifiedDate == null) {
			dateCLIP = 'no data';
		} else {
			final String dateaux = DateTime.newInstance(listRCF.get(0).LastModifiedDate.year(),listRCF.get(0).LastModifiedDate.month(),listRCF.get(0).LastModifiedDate.day()).format('MMM YYYY');
			dateCLIP = dateaux;
		}
		return dateCLIP;
	}
 
    
    /*
    * Aux method to set color data
    */
    private static Map<String, String> setMapColor() {
        final Set<String> setColumns = new Set<String>();
        setColumns.add(RCFEvolutionCnt.USE);
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
        * Attribute for date
        */
        private final String dateCLIP;
        /*
        * Constructor for Wrapper
        */
        public WrapperGlobalData (Map<String, String> colors, Map<String, Map<String, Decimal>> data, String dateCLIP) {
            this.mapColors = colors;
            this.mapData = data;
            this.dateCLIP = dateCLIP;
        }
    }

    /*
    * Wrapper to set data for report
    */
    public class WrapperReport {
        /*
        * Attributes for accountName
        */
        private String accountName; //NOSONAR
        /*
        * Attributes for urlAccount
        */
        private String urlAccount; //NOSONAR
        /*
        * Attributes for accId
        */
        private String accId; //NOSONAR
        /*
        * Attributes for saldoVivo
        */
        private String saldoVivo; //NOSONAR
        /*
        * Attributes for importe
        */
        private String importe; //NOSONAR
        /*
		* Variable lastModDate
		*/
  		private Datetime lastModDate; //NOSONAR
        /*
        * Attributes for dateEv
        */
        private Date dateEv; //NOSONAR
        /*
        * Attributes for usePercent
        */
        private String usePercent; //NOSONAR
        /*
        * Attributes for currencyIso
        */
        private String currencyIso; //NOSONAR
        /*
        * Constructor for Wrapper
        */
        public WrapperReport (RCF_Evolution__c evolution) {
            this.urlAccount = '/lightning/r/Account/' + evolution.participant_id__c + '/view';
            this.accountName = evolution.participant_id__r.Name;
            this.accId = evolution.participant_id__c;
            this.lastModDate = evolution.LastModifiedDate;
            this.saldoVivo = evolution.credit_drawn_amount__c == null ? '' : evolution.credit_drawn_amount__c + ' ' + evolution.CurrencyIsoCode;
            this.importe = evolution.bbva_prtcp_tranche_amount__c == null ? '' : evolution.bbva_prtcp_tranche_amount__c + ' ' + evolution.CurrencyIsoCode;
            this.dateEv = evolution.year_month_day_date__c;
            this.usePercent = evolution.credit_drawn_per__c == null ? '' : evolution.credit_drawn_per__c + '%';
            this.currencyIso = evolution.CurrencyIsoCode;
        }
    }
}