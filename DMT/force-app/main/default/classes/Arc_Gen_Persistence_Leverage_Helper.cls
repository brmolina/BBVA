/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Persistence_Leverage_Service
* @Author   mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 28/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that get data and create json to persist.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-02-28 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-04-06 mariohumberto.ramirez.contractor@bbva.com
*             Added currency value to the final Json
* |2020-04-20 mariohumberto.ramirez.contractor@bbva.com
*             Set INVESTMENT_GRADE when apiValue = null in the method getClasificationsAdj
* |2020-04-15 berthaelena.tellez.contractor@bbva.com
*             Added value defoult on persistance service
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-09-24 joseluis.garcia4.contractor@bbva.com
*             Add getRatingBlock() method for obtaining rating info, delete unused getRatingId().
* |2022-02-24 juanignacio.hita.contractor@bbva.com
*             Add mapping fields for getmissingJsonKeys method
* |2022-02-24 francisco.munoz.torres.contractor@bbva.com
*             In leverage persistance, if TOTAL_CREDIT_RISK is null, it replaces by 0
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_Persistence_Leverage_Helper {
    /**
    * @Description: Value of LL scope type when it is not excluded.
    */
    private static final String TEST_LL_SCOPE_NOT_EXCLUDED = '2';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param void
    * @return coid
    * @example Arc_Gen_Persistence_Leverage_Helper helper = new Arc_Gen_Persistence_Leverage_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Persistence_Leverage_Helper() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description return static json key and values to persist
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param var integer
    * @return String
    * @example getmissingJsonKeys(var)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static string getmissingJsonKeys(Integer var, decimal amount, String currencyType) {
        String auxStr;
        switch on var {
            when 0 {
                /*
                *   LABEL DYNFORM : Gross financial debt over EBITDA
                *   MAP SF : arce__gross_fin_debt_ebitda_number__c = arce__gross_fin_debt_ebitda_number__c = arce__gross_financial_debt_local_amount__c / arce__ebitda_interest_local_number__c
                *   ORACLE MAP : GROSS_FIN_DEBT_EBITDA_NUMBER
                */
                auxStr = '"grossDebtEbitdaRatio":' + amount;
            }
            when 1 {
                /*
                *   LABEL DYNFORM : Adjustments to Total Debt Amount
                *   MAP SF : arce__ll_adj_debt_amount__c = arce__gf_total_debt_amount__c + arce__ll_adj_debt_auditor_amount__c + arce__ll_adj_deb_excl_amount__c + arce__ll_other_adj_debt_amount__c
                *   ORACLE MAP : LL_ADJ_DEBT_AMOUNT

                */
                auxStr = '"id": "ADJUSTED_DEBT","amount": ' + amount + ',"currency":"' + currencyType + '"';
            }
            when 2 {
                /*
                *   LABEL DYNFORM : Ratio Deuda/EBITDA after adjustments
                *   MAP SF : arce__ll_adj_ebitda_amount__c = arce__ll_adj_debt_amount__c / arce__ll_adj_ebitda_amount__c
                *   ORACLE MAP : LL_ADJ_DEBT_EBITDA_NUMBER
                */
                auxStr = '"id": "ADJUSTED_EBITDA","amount": ' + amount + ',"currency":"' + currencyType + '"';
            }
            when 3 {
                /*
                *   LABEL DYNFORM : Limit Exposure Total
                *   MAP SF : arce__current_proposed_amount__c
                *   ORACLE MAP : LIMIT_EXPOSURE_CR_RISK_AMOUNT
                */
                auxStr = '"id": "TOTAL_CREDIT_RISK","amount": ' + (amount == null?0:amount) + ',"currency":"' + currencyType + '"';
            }
        }
        return auxStr;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description get the id of the rating to persist
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param List<sObject> listObject - account has analysis object data
    * @return apifieldName - api name of the field to consult
    * @example getTypeOfAnalysis(listObject,apifieldName)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String getTypeOfAnalysis(List<sObject> listObject, String apifieldName) {
        String retStr = '';
        List<String> auxLts = apifieldName.split('\\.');
        String apiValue = listObject[0].getSobject(auxLts[0]).get(auxLts[1]) == null ? '' : String.valueOf(listObject[0].getSobject(auxLts[0]).get(auxLts[1]));
        switch on apiValue {
            when '1' {
                retStr = 'CONSOLIDATED';
            }
            when '2' {
                retStr = 'INDIVIDUAL';
            }
        }
        return retStr;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description get the id of the rating to persist
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param List<sObject> listObject - account has analysis object data
    * @return apifieldName - api name of the field to consult
    * @example getCovenantType(listObject,apifieldName)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String getCovenantType(List<sObject> listObject, String apifieldName) {
        String retStr = '';
        String apiValue = listObject[0].get(apifieldName) == null ? '' : String.valueOf(listObject[0].get(apifieldName));
        switch on apiValue {
            when '1' {
                retStr = 'NO_COVENANT';
            }
            when '2' {
                retStr = 'COVENANT_LOOSE';
            }
            when '3' {
                retStr = 'COVENANT_LITE';
            }
            when '4' {
                retStr = 'FULL_COVENANT';
            }
            when else {
                retStr = 'NO_COVENANT';
            }
        }
        return retStr;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description get the id of the rating to persist
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param List<sObject> listObject - account has analysis object data
    * @return apifieldName - api name of the field to consult
    * @example getClasificationsAdj(listObject,apifieldName)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String getClasificationsAdj(List<sObject> listObject, String apifieldName) {
        String retStr = '';
        String apiValue = listObject[0].get(apifieldName) == null ? 'N/A' : String.valueOf(listObject[0].get(apifieldName));
        switch on apiValue {
            when 'NI' {
                retStr = 'INVESTMENT_GRADE';
            }
            when 'FS' {
                retStr = 'FINANCIAL_SPONSOR';
            }
            when 'R4' {
                retStr = 'LEVERAGE_RATIO_GREATER_OR_EQUAL_4';
            }
            when 'R6' {
                retStr = 'LEVERAGE_RATIO_GREATER_OR_EQUAL_6';
            }
            when else {
                retStr = 'INVESTMENT_GRADE';
            }
        }
        return retStr;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description get the currency selected in policies table
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param List<sObject> listObject - account has analysis object data
    * @return apifieldName - api name of the field to consult
    * @example getCurrencyType(currencyType)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String getCurrencyType(String currencyType) {
        return '"currency":' + '"' + currencyType + '"';
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description get the rating information of the rating to persist
    * ----------------------------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com
    * @Date 2020-09-24
    * @param arce__Account_has_Analysis__c aha listObject - account has analysis object data
    * @return rating block to be sent with the service input
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String getRatingBlock(arce__Account_has_Analysis__c aha) {
        String output = '';

        if (aha.arce__ll_test_scope_ind_type__c == TEST_LL_SCOPE_NOT_EXCLUDED) {
            // Only populate rating when test is not excluded.
            final String ratingId = aha.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__rating_id__c;
            final String ratingValue = aha.arce__ffss_for_rating_id__r.arce__rating_final__c;
            output = '"rating": { "id": "' + ratingId + '", "shortScaleValue": "' + ratingValue +'" },';
        }

        return output;
    }
}