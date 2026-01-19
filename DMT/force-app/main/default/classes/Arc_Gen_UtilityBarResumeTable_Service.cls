/**
* @File Name          : Arc_Gen_UtilityBarResumeTable_Service.cls
* @Description        : Utility bar resume service class
* @Author             : luisarturo.parra.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 11/06/2020 9:37:00
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    15/10/2019           luisarturo.parra.contractor@bbva.com     Initial Version
* 1.1    11/06/2020           juanignacio.hita.contractor@bbva.com     Added currency type, units and hidden total row to group resume
* 1.1    23/09/2020     saimassimilianno.jordana.contractor@bbva.com   Added arce. namespace to all classes that are now in the arce-dependencies package
**/
public class Arc_Gen_UtilityBarResumeTable_Service {
    /**
    *-------------------------------------------------------------------------------
    * @description Wrapper for build group resume table of analysis
    *-------------------------------------------------------------------------------
    */
    public class UtilityBarWrp {
        /*
        * @description Limits list to fill group resume
        */
        List<List<String>> limits {get;set;}
        /*
        * @description Currency list of each subsidiary
        */
        List<String> currencyType {get;set;}
        /*
        * @description Unit list of each subsidiary
        */
        List<String> unitType {get;set;}
        /*
        * @description It is marked when there are several different currencies or units
        */
        Boolean multiCurrency {get;set;}
    }
    /**private constructor for sonar**/
    private Arc_Gen_UtilityBarResumeTable_Service(){}
    /**
    *-------------------------------------------------------------------------------
    * @description get data for the table
    *-------------------------------------------------------------------------------
    * @date 30/04/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @param recordId analysisId of the account has analysis
    * @return  List < arce__limits_exposures__c >
    * @example public static List < arce__limits_exposures__c > getTableData(Id recordId) {
    */
    public static String getTableData(Id recordId) {
        UtilityBarWrp wrapper = new UtilityBarWrp();
        List<arce__Account_has_Analysis__c> ahas = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(recordId);
        set < Id > accountHAIds = new set < Id > ();
        List<String> lstUnitType = new List<String>();
        List<String> lstCurrencyType = new List<String>();
        Boolean multiCurrency = false;
        for (arce__Account_has_Analysis__c childAHA: ahas) {
            if (childAHA.arce__group_asset_header_type__c  != '1') {
                accountHAIds.add(childAHA.Id);
                lstUnitType.add(arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Account_has_Analysis__c', 'arce__magnitude_unit_type__c', childAHA.arce__magnitude_unit_type__c));
                lstCurrencyType.add(childAHA.arce__currency_id__c);
                if (childAHA.arce__magnitude_unit_type__c != ahas[0].arce__magnitude_unit_type__c || childAHA.arce__currency_id__c != ahas[0].arce__currency_id__c) {
                    multiCurrency = true;
                }
            }
        }
        List < arce__limits_exposures__c > limits = arce.Arc_Gen_LimitsExposures_Data.getExposureDatafromIds(accountHAIds);
        wrapper.limits = orderdata(limits);
        wrapper.currencyType = lstCurrencyType;
        wrapper.unitType = lstUnitType;
        wrapper.multiCurrency = multiCurrency;
        return JSON.serialize(wrapper);
    }
    /**
*-------------------------------------------------------------------------------
* @description method to order the data
*-------------------------------------------------------------------------------
* @date 30/04/2019
* @author luisarturo.parra.contractor@bbva.com
* @param multidimensionarray array with wrapper objects serialized
* @param operationvalues wrapper object serialized
* @return String
* @example public static String orderdata(String multidimensionarray, String operationvalues) {
*/
    public static List<List<String>> orderdata(List < arce__limits_exposures__c > limits) {
        Map<String, List<String>> orderbyfieldmap = new Map<String,List<String>>();
        List<Arc_Gen_typologiesDataJunction> typowrap = new List<Arc_Gen_typologiesDataJunction>();
        for (arce__limits_exposures__c data : limits) {
            if(orderbyfieldmap.containsKey(data.arce__account_has_analysis_id__r.arce__Customer__c)) {
                Arc_Gen_typologiesDataJunction typos = new Arc_Gen_typologiesDataJunction();
                typos.typonames.typologyname = data.arce__limits_typology_id__r.Name;
                typos.typonames.typologyammount =  data.arce__current_proposed_amount__c;
                typos.typonames.typologykey = data.arce__limits_typology_id__r.arce__risk_typology_level_id__c;
                typos.customerinfo.customerName = data.arce__account_has_analysis_id__r.arce__Customer__r.Name;
                typos.customerinfo.customerId = data.arce__account_has_analysis_id__r.arce__Customer__c;
                orderbyfieldmap.get(data.arce__account_has_analysis_id__r.arce__Customer__c).add(JSON.serialize(typos));
            } else {
                List<String> typowraps = new List<String>();
                Arc_Gen_typologiesDataJunction typos = new Arc_Gen_typologiesDataJunction();
                typos.typonames.typologyname = data.arce__limits_typology_id__r.Name;
                typos.typonames.typologyammount =  data.arce__current_proposed_amount__c;
                typos.typonames.typologykey = data.arce__limits_typology_id__r.arce__risk_typology_level_id__c;
                typos.customerinfo.customerName = data.arce__account_has_analysis_id__r.arce__Customer__r.Name;
                typos.customerinfo.customerId = data.arce__account_has_analysis_id__r.arce__Customer__c;
                typowraps.add(JSON.serialize(typos));
                orderbyfieldmap.put(typos.customerinfo.customerId,typowraps );
            }
        }
        List<List<String>> fulldata = new List<List<String>>();
        for(String key : orderbyfieldmap.keyset()){
          fulldata.add(orderbyfieldmap.get(key));
        }
        return fulldata;
    }
}