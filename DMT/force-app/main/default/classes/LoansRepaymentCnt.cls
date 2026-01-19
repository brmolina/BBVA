/************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: LoansRepaymentCnt
*   @Description:  LoansRepaymentCnt


*   @Versions:
        v1 - 2019/06/10 - Initial version
***********************************************************************************/
public with sharing class LoansRepaymentCnt {

    /* BBVAREPAYMENT */
    static Final String BBVAREPAYMENT = 'Repayment BBVA';
    /* OUTREPAYMENT */
    static Final String OUTREPAYMENT = 'External Repayment';
    /* PENDING */
    static Final String PENDING = 'Pending Balance';

    /*SINGLETON PATTERN*/
    private static LoansRepaymentCnt instance;
    /*SINGLETON PATTERN*/
    public static LoansRepaymentCnt getInstance() { //NOSONAR
        if (instance == null) {
            instance = new LoansRepaymentCnt();
        }
        return instance;
    }
     /*
    *   Empty Constructor
    */
	private LoansRepaymentCnt() {
        System.debug('Constructor empty');
	}


    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getData
    *   @Description:

    *   @Inputs:    String clientId
    *   @Output:    String => WrapperGlobalData Serialized:
                        -
    *   @Versions:
            v1 - 2019/06/10 - Initial version
    */
    @auraEnabled
    public static String getData(String clientId, String operationType) {
        try {
            System.debug('::::::getDataLoans INIT : ' +  clientId + ' - ' + operationType);
            Final String QUERY = generateQuery(clientId, operationType, false);
            Final List<Loans_Repayment__c> lstLoans = Database.query(QUERY);//NOSONAR -> SQL Injection managed in generateQuery() method
            System.debug('::::::lstLoans : ' + JSON.serialize(lstLoans));

            Map<String, String> mapColors;
            Map<Decimal, Map<String, Double>> mapResponse;
            mapResponse = new Map<Decimal, Map<String, Double>>();
            if(!lstLoans.isEmpty()) {
                /* Static Set of labels*/
                Final Set<String> setLabels = new Set<String>{BBVAREPAYMENT, OUTREPAYMENT, PENDING};

                for(Loans_Repayment__c loan : lstLoans) {
                    mapResponse = getMapResponse(loan, mapResponse);
                }
                mapColors = UtilsFichaGrupo.getCountryColor(setLabels);
            }

            Final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(mapColors, mapResponse);
            System.debug('::::response: ' + JSON.serialize(wrapperGlobal));
            return JSON.serialize(wrapperGlobal);
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getRowsData
    *   @Description:

    *   @Inputs:    String clientId
    *   @Output:    String => WrapperGlobalData Serialized:
                        -
    *   @Versions:
            v1 - 2019/06/14 - Initial version
    */
    @auraEnabled
    public static String getRowsData(String clientId, String operationType) {
        try {
            Final String QUERY = generateQuery(clientId, operationType, true);
            Final List<Loans_Repayment__c> lstLoans = Database.query(QUERY);//NOSONAR -> SQL Injection managed in generateQuery() method
            System.debug('::::::lstLoans to table: ' + JSON.serialize(lstLoans));

            Final List<WrapperClass> listWrapper = new List<WrapperClass>();

            for(Loans_Repayment__c loan : lstLoans) {
                listWrapper.add(new WrapperClass(loan));
            }
            // System.debug('::::::return ' + JSON.serialize(listWrapper));

            return JSON.serialize(listWrapper);
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }
    /*
    *
    * SELECT Id, participant_id__c, participant_id__r.Name, gf_settlement_date__c, solution_classification_desc__c,
                                                convertCurrency(bbva_repayment_amount__c), convertCurrency(synd_loan_amortization_amount__c), convertCurrency(unrepayment_capital_amount__c),
                                                audit_date__c, CurrencyIsoCode
                                                    FROM Loans_Repayment__c
                                                    WHERE participant_id__c = :clientId
                                                    AND solution_classification_desc__c = :operationType
    */
     private static String generateQuery(String clientId,String operationType, Boolean tableDetails) {
        String querySelect;
        // Opportunity.region_name__c,
        querySelect = 'SELECT Id, participant_id__c, gf_settlement_date__c, solution_classification_desc__c';
        querySelect += ', convertCurrency(bbva_repayment_amount__c), convertCurrency(synd_loan_amortization_amount__c), convertCurrency(unrepayment_capital_amount__c), convertCurrency(applied_fees_amount__c), convertCurrency(gf_loan_fund_cost_amount__c), convertCurrency(gf_nominal_interest_amount__c)';
        querySelect += ', country_name__c, CurrencyIsoCode';

        if(tableDetails) {
            querySelect += ', participant_id__r.Name ';
        }
        querySelect += ' FROM Loans_Repayment__c';

        String queryWhere;
        queryWhere = ' WHERE participant_id__c =\'' + String.escapeSingleQuotes(clientId) + '\' AND solution_classification_desc__c=\'' + String.escapeSingleQuotes(operationType) + '\'';

       //final query
        return querySelect + queryWhere;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getMapResponse
    *   @Description:

    *   @Inputs:
    *   @Output:
                        -
    *   @Versions:
            v1 - 2019/06/10 - Initial version
    */
    private static Map<Decimal, Map<String, Double>> getMapResponse(Loans_Repayment__c loan, Map<Decimal, Map<String, Double>> mapRespInput) {
        Map<Decimal, Map<String, Double>> mapResp;
        mapResp = mapRespInput;
        Map<String, Double> mapData;
        if(mapResp.get(loan.gf_settlement_date__c) == null) {
            mapData = mapResp.get(loan.gf_settlement_date__c); 
        } else {
            mapData = new Map<String, Double>();
        }
        mapResp.put(loan.gf_settlement_date__c, mapData);

        mapResp = fillMapData(loan, mapResp);
        System.debug(':::mapResp after filling: ' + JSON.serialize(mapResp));
        return mapResp;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: fillMapData
    *   @Description:

    *   @Inputs:    Loans_Repayment__c loan, Map<String, Double> mapDataInput
    *   @Output:    Map<String, Double> mapData
                        -
    *   @Versions:
            v1 - 2019/06/10 - Initial version
    */
    private static Map<Decimal, Map<String, Double>> fillMapData(Loans_Repayment__c loan, Map<Decimal, Map<String, Double>> mapResponseInput) {
        /* mapData: key(label), value(double) */
        Final Map<Decimal, Map<String, Double>> mapResponse = mapResponseInput;
        Map<String, Double> mapData;

        mapData = initMapData(loan, mapResponse);
        // if(mapResponse.isEmpty() || mapResponse.get(loan.gf_settlement_date__c) == null) {
        //     mapData = new Map<String, Double>();
        // } else {
        //     mapData = mapResponse.get(loan.gf_settlement_date__c);
        // }

        mapData = bbvaData(loan, mapData);
        // if(!mapData.isEmpty() && mapData.get(BBVAREPAYMENT) == null) {
        //     mapData.put(BBVAREPAYMENT, loan.bbva_repayment_amount__c);
        // } else {
        //     Final Double OLDVALUE = mapData.get(BBVAREPAYMENT) == null ? 0 : mapData.get(BBVAREPAYMENT);
        //     mapData.put(BBVAREPAYMENT, OLDVALUE + loan.bbva_repayment_amount__c);
        // }

        mapData = externalData(loan, mapData);
        // if(!mapData.isEmpty() && mapData.get(OUTREPAYMENT) == null) {
        //     mapData.put(OUTREPAYMENT, loan.repayment_amount__c);
        // } else {
        //     Final Double OLDVALUE = mapData.get(OUTREPAYMENT) == null ? 0 : mapData.get(OUTREPAYMENT);
        //     mapData.put(OUTREPAYMENT, OLDVALUE + loan.bbva_repayment_amount__c);
        // }

        mapData = pendingData(loan, mapData);
        // if(!mapData.isEmpty() && mapData.get(PENDING) == null) {
        //     mapData.put(PENDING, loan.unrepayment_capital_amount__c);
        // } else {
        //     Final Double OLDVALUE = mapData.get(PENDING) == null ? 0 : mapData.get(PENDING);
        //     mapData.put(PENDING, OLDVALUE + loan.unrepayment_capital_amount__c);
        // }
        mapResponse.put(loan.gf_settlement_date__c, mapData);

        return mapResponse;
    }
     /*
    *   @author: GlobalDesktop - APC
    *   @Method: initMapData
    *   @Description:

    *   @Inputs:    Loans_Repayment__c loan, Map<String, Double> mapDataInput
    *   @Output:    Map<String, Double> mapData
                        -
    *   @Versions:
            v1 - 2019/06/10 - Initial version
    */
    private static Map<String, Double> initMapData(Loans_Repayment__c loan, Map<Decimal, Map<String, Double>> mapResponse) {
        Map<String, Double> mapData;

        if(mapResponse.isEmpty() || mapResponse.get(loan.gf_settlement_date__c) == null) {
            mapData = new Map<String, Double>();
        } else {
            mapData = mapResponse.get(loan.gf_settlement_date__c);
        }

        return mapData;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: bbvaData
    *   @Description:

    *   @Inputs:    Loans_Repayment__c loan, Map<String, Double> mapDataInput
    *   @Output:    Map<String, Double> mapData
                        -
    *   @Versions:
            v1 - 2019/06/10 - Initial version
    */
    private static Map<String, Double> bbvaData(Loans_Repayment__c loan, Map<String, Double> mapDataInput) {
        Final Map<String, Double> mapData = mapDataInput;

        if(!mapData.isEmpty() && mapData.get(BBVAREPAYMENT) == null) {
            mapData.put(BBVAREPAYMENT, loan.bbva_repayment_amount__c);
        } else {
            Final Double OLDVALUE = mapData.get(BBVAREPAYMENT) == null ? 0 : mapData.get(BBVAREPAYMENT);
            if(loan.bbva_repayment_amount__c!=null) {
                mapData.put(BBVAREPAYMENT, OLDVALUE + loan.bbva_repayment_amount__c);
            } else {
                mapData.put(BBVAREPAYMENT, OLDVALUE );
            }
            
        }

        return mapData;
    }
     /*
    *   @author: GlobalDesktop - APC
    *   @Method: externalData
    *   @Description:

    *   @Inputs:    Loans_Repayment__c loan, Map<String, Double> mapDataInput
    *   @Output:    Map<String, Double> mapData
                        -
    *   @Versions:
            v1 - 2019/06/10 - Initial version
    */
    private static Map<String, Double> externalData(Loans_Repayment__c loan, Map<String, Double> mapDataInput) {
        Final Map<String, Double> mapData = mapDataInput;

        if(!mapData.isEmpty() && mapData.get(OUTREPAYMENT) == null) {
            mapData.put(OUTREPAYMENT, loan.synd_loan_amortization_amount__c);
        } else {
            Final Double OLDVALUE = mapData.get(OUTREPAYMENT) == null ? 0 : mapData.get(OUTREPAYMENT);
            if(loan.bbva_repayment_amount__c!=null) {
                mapData.put(OUTREPAYMENT, OLDVALUE + loan.bbva_repayment_amount__c);
            } else {
                mapData.put(OUTREPAYMENT, OLDVALUE );
            } 
        }

        return mapData;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: pendingData
    *   @Description:

    *   @Inputs:    Loans_Repayment__c loan, Map<String, Double> mapDataInput
    *   @Output:    Map<String, Double> mapData
                        -
    *   @Versions:
            v1 - 2019/06/10 - Initial version
    */
    private static Map<String, Double> pendingData(Loans_Repayment__c loan, Map<String, Double> mapDataInput) {
        Final Map<String, Double> mapData = mapDataInput;

       if(!mapData.isEmpty() && mapData.get(PENDING) == null) {
            mapData.put(PENDING, loan.unrepayment_capital_amount__c);
        } else {
            Final Double OLDVALUE = mapData.get(PENDING) == null ? 0 : mapData.get(PENDING);
            if(loan.unrepayment_capital_amount__c!=null) {
                mapData.put(PENDING, OLDVALUE + loan.unrepayment_capital_amount__c);
            } else {
                mapData.put(PENDING, OLDVALUE);
            }
            
        }

        return mapData;
    }

    /*
    * @author GlobalDesktop - APC
    * @description Construye la wrapper list que se devolvera al componente lightning
    */
    public class WrapperGlobalData {
        /* Map<String, String> mapRowColors */
        final private Map<String, String> mapRowColors;//NOSONAR used in client side
        /* Map<Decimal, Map<String, Double>> mapData */
        final private Map<Decimal, Map<String, Double>> mapData;//NOSONAR used in client side
        /* String userCurrency */
        final private String userCurrency;//NOSONAR used in client side
        /*
        * Constructor
        */
        public WrapperGlobalData (Map<String, String> prodColors, Map<Decimal, Map<String, Double>> data) {
            this.mapRowColors = prodColors;
            this.mapData = data;
            this.userCurrency = UserInfo.getDefaultCurrency();
        }
    }
    /*
    * WrapperClass to build the JSON to be sent to client-side to display table
    */
     public class WrapperClass {
	/*
	* bbvaRepayment
	*/
      final private Decimal bbvaRepayment;//NOSONAR used in client side
    /*
	* totalRepayment
	*/
      final private Decimal totalRepayment;//NOSONAR used in client side
    /*
	* pending
	*/
      final private Decimal pending;//NOSONAR used in client side
	/*
	* urlAccount
	*/
      final private String urlAccount;//NOSONAR used in client side
	/*
	* accountName
	*/
      final private String accountName;//NOSONAR used in client side
      /*
	* year
	*/
      final private String year;//NOSONAR used in client side
      /*
	* operation
	*/
      final private String operation;//NOSONAR used in client side
    /*
	* country
	*/
      final private String country;//NOSONAR used in client side
      /*
	* commissions
	*/
      final private Decimal commissions;//NOSONAR used in client side
      /*
	* interests
	*/
      final private Decimal interests;//NOSONAR used in client side
	/*
	* averageCost
	*/
      final private Decimal averageCost;//NOSONAR used in client side

    /*
    * Constructor
    */
        public WrapperClass(Loans_Repayment__c loan) {
            this.urlAccount = '/lightning/r/Account/' + loan.participant_id__c + '/view';
            this.accountName = loan.participant_id__r.Name;
            this.bbvaRepayment = loan.bbva_repayment_amount__c;
            this.totalRepayment = loan.synd_loan_amortization_amount__c;
            this.pending = loan.unrepayment_capital_amount__c;
            this.year = String.valueOf(loan.gf_settlement_date__c);
            this.operation = loan.solution_classification_desc__c;
            this.country = loan.country_name__c;
            this.commissions = loan.applied_fees_amount__c;
            this.interests = loan.gf_nominal_interest_amount__c;
            this.averageCost = loan.gf_loan_fund_cost_amount__c;
        }
    }
}