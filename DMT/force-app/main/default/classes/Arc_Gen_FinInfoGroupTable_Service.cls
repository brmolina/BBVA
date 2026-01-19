/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_FinInfoGroupTable_Service
* @Author   BBVA
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_FinInfoGroupTable_Service component
* ------------------------------------------------------------------------------------------------
* @Changes
* |2020-04-14 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-06-29 mariohumberto.ramirez.contractor@bbva.com
*             Update class for HU GADRDCDE-1577 Mejora Tabla Información Financiera
* |2020-07-20 mariohumberto.ramirez.contractor@bbva.com
*             fix percent visibility
* |2020-08-05 juanmanuel.perez.ortiz.contractor@bbva.com
*             Modified logic to show grossFinancialDebtOverEbitda and interestCoverageWithEbitda without dividing it by a thousand
* |2020-08-07 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add logic when not exists FFSS, set N/A in data rows
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-13 joseluis.garcia4.contractor@bbva.com
*             Fetch currency and units from FFSS.
* |2020-11-18 juanignacio.hita.contractor@bbva.com
*             Adds the rating value based on the scale type selected, created a new getRatingValue and getFinalRatingValue methods
* |2021-02-25 juanmanuel.perez.ortiz.contractor@bbva.com
*             Avoid set rating in previous year
* |2021-09-27 juanignacio.hita.contractor@bbva.com
*             Adds condition depends status of rating in getRatingValue method
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_FinInfoGroupTable_Service {
    /*
        * @Description List<String> developer name of the ratios
    */
    static final List<String> CODE_TERM_LTS = new List<String>{'totalLiabilitiesAndEquity','netWorth','grossFinancialDebt','totalRevenues','ebitda','netResultsAfterTaxes','grossFinancialDebtOverEbitda','interestCoverageWithEbitda'};
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-04-14
    * @param void
    * @return void
    * @example Arc_Gen_FinInfoGroupTable_Service service = new Arc_Gen_FinInfoGroupTable_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_FinInfoGroupTable_Service() {

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the column information financial info group table
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-04-14
    * @param void
    * @return columns information of the policy table
    * @example getColumnsInfo()
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableColumns> getColumnsInfo() {
        Arc_Gen_TableColumns name = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'name',
            'label'=>Label.Arc_Gen_ColumnHeader_Shareholder_Name,
            'initialWidth'=>'400'
        });
        Arc_Gen_TableColumns rating = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'rating',
            'label'=> 'Rating'
        });
        Arc_Gen_TableColumns totalBalance = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'totalBalance',
            'label'=> Label.Arc_Gen_TotalBalance
        });
        Arc_Gen_TableColumns ffpp = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'ffpp',
            'label'=>Label.Arc_Gen_FFPP
        });
        Arc_Gen_TableColumns netDebt = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'netDebt',
            'label'=>Label.Arc_Gen_GrossDebt
        });
        Arc_Gen_TableColumns sales = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'sales',
            'label'=>Label.Arc_Gen_Sales
        });
        Arc_Gen_TableColumns ebitda = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'ebitda',
            'label'=>Label.Arc_Gen_Ebitda
        });
        Arc_Gen_TableColumns netProfit = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'netProfit',
            'label'=>Label.Arc_Gen_NetProfit
        });
        Arc_Gen_TableColumns debtEbitda = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'debtEbitda',
            'label'=>Label.Arc_Gen_Debt_Ebitda
        });
        Arc_Gen_TableColumns intCov = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'intCov',
            'label'=>Label.Arc_Gen_InterestCoverage
        });
        Arc_Gen_TableColumns margEbtda = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'margEbtda',
            'label'=>Label.Arc_Gen_MarginEbitda
        });
        Arc_Gen_TableColumns year = new Arc_Gen_TableColumns(new Map<String,String>{
            'type'=>'text',
            'fieldName'=>'year',
            'label'=>Label.Arc_Gen_Year
        });
        List<Arc_Gen_TableColumns> columns = new List<Arc_Gen_TableColumns>{name,rating,totalBalance,ffpp,netDebt,sales,ebitda,netProfit,debtEbitda,intCov,margEbtda,year};
        return columns;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the rows information financial info group table
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-04-14
    * @param recordId - arce__Account_has_Analysis__c object id
    * @param typeInfo - string with the code to retrieve the info of the tables
    * @return List<Arc_Gen_FinancialInfoRow> rows information to build the table
    * @example getRowInfo(recordId, typeInfo)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_FinancialInfoRow> getRowInfo(String recordId, String typeInfo) {
        List<Arc_Gen_FinancialInfoRow> jsonRow = new List<Arc_Gen_FinancialInfoRow>();
        final List<arce__Account_has_Analysis__c> accHasAnInfo = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId});
        final List<arce__Account_has_Analysis__c> allAccHasAnLts = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(accHasAnInfo[0].arce__Analysis__c);
        final List<Id> accHasAnIdLts = getAcchasAnIdLts(allAccHasAnLts);
        Double multiplicationFactor = 0;
        Map<Id,Map<String,Double>> tableContInfo = typeInfo == 'valid' ? Arc_Gen_TableContentPerAnalysis_Data.getTableContentValidByCode(accHasAnIdLts,CODE_TERM_LTS) : Arc_Gen_TableContentPerAnalysis_Data.getTableContentPrevValidByCode(accHasAnIdLts,CODE_TERM_LTS);
        String margEbt = '';
        final Map<String, String> mapUnits = arce.Arc_Gen_GenericUtilities.getMapLabelFromValue('arce__Financial_Statements__c', 'arce__magnitude_unit_type__c');
        if (!tableContInfo.isEmpty()) {
            for(arce__Account_has_Analysis__c accHasAn: allAccHasAnLts) {
                Arc_Gen_FinancialInfoRow rowInfoAux = new Arc_Gen_FinancialInfoRow();
                if (accHasAn.arce__group_asset_header_type__c == '2') {
                    multiplicationFactor = getmultFactor(accHasAn.arce__magnitude_unit_type__c);
                    rowInfoAux.name = accHasAn.arce__participant_name__c;
                    rowInfoAux.totalBalance = getTableContInfo(tableContInfo,accHasAn,'totalLiabilitiesAndEquity',multiplicationFactor);
                    rowInfoAux.rating = setRatingValue(typeInfo, getFinalRatingValue(accHasAn), rowInfoAux.totalBalance);
                    rowInfoAux.ffpp = getTableContInfo(tableContInfo,accHasAn,'netWorth',multiplicationFactor);
                    rowInfoAux.netDebt = getTableContInfo(tableContInfo,accHasAn,'grossFinancialDebt',multiplicationFactor);
                    rowInfoAux.sales = getTableContInfo(tableContInfo,accHasAn,'totalRevenues',multiplicationFactor);
                    rowInfoAux.ebitda = getTableContInfo(tableContInfo,accHasAn,'ebitda',multiplicationFactor);
                    rowInfoAux.netProfit = getTableContInfo(tableContInfo,accHasAn,'netResultsAfterTaxes',multiplicationFactor);
                    rowInfoAux.debtEbitda = getTableContInfo(tableContInfo,accHasAn,'grossFinancialDebtOverEbitda',1);
                    rowInfoAux.intCov = getTableContInfo(tableContInfo,accHasAn,'interestCoverageWithEbitda',1);
                    margEbt = getTableContInfo(tableContInfo,accHasAn,'ebitda_per',1);
                    rowInfoAux.margEbtda = margEbt == 'N/A' ? 'N/A' : margEbt + '%';
                    rowInfoAux.year = getYearInfo(tableContInfo,accHasAn,'ebitda_year');
                    getCurrencyAndUnits(rowInfoAux, accHasAn.arce__ffss_for_rating_id__r, mapUnits);
                    jsonRow.add(rowInfoAux);
                }
            }
        }
        return jsonRow;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description manage null values from maps
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-04-14
    * @param tableContInfo - Map<Id,Map<String,Double>> with the ratios info
    * @param accHasAn - arce__Account_has_Analysis__c object
    * @param codeTerm - key to get the info of tableContInfo
    * @return Double value
    * @example getTableContInfo(tableContInfo, accHasAn codeTerm)
    * --------------------------------------------------------------------------------------
    **/
    public static String getTableContInfo(Map<Id,Map<String,Double>> tableContInfo, arce__Account_has_Analysis__c accHasAn, String codeTerm, Double multiplicationFactor) {
        String value = tableContInfo.get(accHasAn.Id) == null ? '' : tableContInfo.get(accHasAn.Id).get(codeTerm) == null ? '-' : Decimal.valueOf(tableContInfo.get(accHasAn.Id).get(codeTerm)*multiplicationFactor).setscale(1).format();
        value = value == '' ? 'N/A' : value;
        return value;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description manage null values from maps
    * --------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-04-14
    * @param tableContInfo - Map<Id,Map<String,Double>> with the ratios info
    * @param accHasAn - arce__Account_has_Analysis__c object
    * @param codeTerm - key to get the info of tableContInfo
    * @return Double value
    * @example getYearInfo(tableContInfo, accHasAn codeTerm)
    * --------------------------------------------------------------------------------------
    **/
    public static String getYearInfo(Map<Id,Map<String,Double>> tableContInfo, arce__Account_has_Analysis__c accHasAn, String codeTerm) {
        return tableContInfo.get(accHasAn.Id) == null ? '' : tableContInfo.get(accHasAn.Id).get(codeTerm) == null ? '-' : String.valueOf(Integer.valueOf(tableContInfo.get(accHasAn.Id).get(codeTerm)));
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Return the multiplication factor to convert the ratios value in thousands
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 29/06/2020
    * @param unitSelected - unit of the ratio
    * @return multiFactor - fthe multiplication factor to convert the ratios value in thousands
    * @example getmultFactor(unitSelected)
    * --------------------------------------------------------------------------------------
    **/
    public static Double getmultFactor(String unitSelected) {
        Double multiFactor = 1;
        switch on unitSelected {
            when '1' {
                multiFactor = 0.001;
            }
            when '2' {
                multiFactor = 1;
            }
            when '3' {
                multiFactor = 1000;
            }
        }
        return multiFactor;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description fills currency and units information from FFSS
    * --------------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 2020-11-13
    * @param rowInfoAux - Row for the financial information table.
    * @param ffss - FFSS selected for rating.
    * @param mapUnits - Map to translate unit values.
    * --------------------------------------------------------------------------------------
    **/
    private static void getCurrencyAndUnits(Arc_Gen_FinancialInfoRow rowInfoAux, arce__Financial_Statements__c ffss, Map<String, String> mapUnits) {
        if (ffss == null) {
            rowInfoAux.currencyVal = rowInfoAux.unitsVal = 'N/A';
        } else {
            rowInfoAux.currencyVal = ffss.CurrencyIsoCode;
            rowInfoAux.unitsVal = mapUnits.get(ffss.arce__magnitude_unit_type__c);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Return a List<Id> of account has analysis
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 29/06/2020
    * @param allAccHasAn - List of account has analysis object
    * @return List<Id> of account has analysis
    * @example getAcchasAnIdLts(allAccHasAn)
    * --------------------------------------------------------------------------------------
    **/
    private static List<Id> getAcchasAnIdLts(List<arce__Account_has_Analysis__c> allAccHasAn) {
        List<Id> accHasIdLts = new List<Id>();
        for(arce__Account_has_Analysis__c accHasAn: allAccHasAn) {
            if (accHasAn.arce__group_asset_header_type__c == '2') {
                accHasIdLts.add(accHasAn.Id);
            }
        }
        return accHasIdLts;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Return the rating value to show in the table
    * --------------------------------------------------------------------------------------
    * @Author   Juan Manuel Perez Ortiz  juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 07/08/2020
    * @param typeInfo - Field with the indication (previous, valid)
    * @param longRatingValue - Field with the long rating value
    * @param totalBalance - Field with the total balance
    * @return String
    * @example setRatingValue(typeInfo, longRatingValue, totalBalance)
    * --------------------------------------------------------------------------------------
    **/
    public static String setRatingValue(String typeInfo, String longRatingValue, String totalBalance) {
        String ratingValue;
        if(typeInfo == 'valid' && totalBalance != 'N/A') {
            ratingValue = longRatingValue;
        }
        else {
            ratingValue = 'N/A';
        }
        return ratingValue;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Return rating value depending scale rating type of the customer
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     18/11/2020
    * @param    accHasAn - arce__Account_has_Analysis__c
    * @return   String
    * @example  String ratingVal = getRatingValue(accHasAn);
    * --------------------------------------------------------------------------------------
    **/
    public static String getRatingValue(arce__Account_has_Analysis__c accHasAn) {
        String ratingValue;
        if (accHasAn.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__status_type__c == arce.Arc_Gen_Constants.THREE_S) {
            if(accHasAn.arce__rating_adj_ind_type__c == arce.Arc_Gen_Constants.ONE_S) {
                if (accHasAn.arce__rating_scale_type__c == arce.Arc_Gen_Constants.SHORT_SCALE_RATING) {
                    ratingValue = accHasAn.arce__adj_short_rating_value_type__c;
                } else if (accHasAn.arce__rating_scale_type__c == arce.Arc_Gen_Constants.LONG_SCALE_RATING) {
                    ratingValue = accHasAn.arce__adj_long_rating_value_type__c;
                }
            } else if (accHasAn.arce__rating_adj_ind_type__c == arce.Arc_Gen_Constants.TWO_S) {
                if (accHasAn.arce__rating_scale_type__c == arce.Arc_Gen_Constants.SHORT_SCALE_RATING) {
                    ratingValue = accHasAn.arce__short_rating_value_type__c;
                } else if (accHasAn.arce__rating_scale_type__c == arce.Arc_Gen_Constants.LONG_SCALE_RATING) {
                    ratingValue = accHasAn.arce__long_rating_value_type__c;
                }
            }
        }
        return ratingValue;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Return final rating value depending scale rating type of the customer
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     18/11/2020
    * @param    accHasAn - arce__Account_has_Analysis__c
    * @return   String
    * @example  String ratingVal = getFinalRatingValue(accHasAn);
    * --------------------------------------------------------------------------------------
    **/
    public static String getFinalRatingValue(arce__Account_has_Analysis__c accHasAn) {
        String ratingValue;
        if (accHasAn.arce__rating_scale_type__c == arce.Arc_Gen_Constants.SHORT_SCALE_RATING) {
            ratingValue = accHasAn.arce__ffss_for_rating_id__r.arce__rating_final__c;
        } else if (accHasAn.arce__rating_scale_type__c == arce.Arc_Gen_Constants.LONG_SCALE_RATING) {
            ratingValue = accHasAn.arce__ffss_for_rating_id__r.arce__rating_long_value_type__c;
        }
        return ratingValue;
    }
}