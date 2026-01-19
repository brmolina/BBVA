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
* |2020-04-22 mariohumberto.ramirez.contractor@bbva.com
*             The management of the response code 204 of the service has been added
* |2020-06-26 eduardoefrain.hernandez.contractor@bbva.com
*             Set leveraged currency from ffss currency
* |2020-06-30 joseluis.garcia4.contractor@bbva.com
*             Move PoliciesWrapper inner class from Arc_Gen_Save_Policies_ctrl (now deleted) to here.
* |2020-09-15 joseluis.garcia4.contractor@bbva.com
*             Remove "type == CLIENT" condition on callPersistence (group can also have leveraged).
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-09-24 joseluis.garcia4.contractor@bbva.com
*             Provide rating to leveragePersistence service only if test is not excluded.
* |2020-12-01 joseluis.garcia4.contractor@bbva.com
*             Provide materiality as '0.0' if it's null in Salesforce.
* |2022-02-24 juanignacio.hita.contractor@bbva.com
*             Refactoring callPersistence method
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_Persistence_Leverage_Service {
    /**
        * @Description: String with the name of the leverage persistence service
    */
    static final string SERVICE_NAME = 'leveragePersistence';
    /**
        * @Description: String with the name of the leverage persistence service
    */
    static final List<string> LIST_FIELDS = new List<String>{'arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c','arce__entity_covenants_type__c','arce__ll_before_adj_clsfn_type__c','arce__ll_after_adj_clsfn_type__c','arce__ll_previous_anlys_clsfn_type__c','arce__Customer__r.controlled_by_sponsor_type__c'};
    /**
        * @Description: String with the name of the leverage persistence service
    */
    static final string ANALYSIS_TYPE = 'arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c';
    /**
        * @Description: String with the name of the leverage persistence service
    */
    static final string COVENANT_TYPE = 'arce__entity_covenants_type__c';
    /**
        * @Description: String with the name of the leverage persistence service
    */
    static final string BEF_ADJ = 'arce__ll_before_adj_clsfn_type__c';
    /**
        * @Description: String with the name of the leverage persistence service
    */
    static final string AFT_ADJ = 'arce__ll_after_adj_clsfn_type__c';
    /**
        * @Description: String with the name of the leverage persistence service
    */
    static final string PREV_ANA_TYPE = 'arce__ll_previous_anlys_clsfn_type__c';
    /**
        * @Description: String with the api name of the financial sponsor record
    */
    static final string FIN_SPONSOR = 'arce__Customer__r.controlled_by_sponsor_type__c';
    /**
        * @Description: service code 200
    */
    static final string SUCCESS_CODE = '200';
    /**
        * @Description: service code 201
    */
    static final string CREATED = '201';
    /**
        * @Description: service code 204
    */
    static final string UPDATED = '204';
    /**
        * @Description: String with value "2"
    */
    static final string CLIENT = '2';
    /**
        * @Description: String with value "2"
    */
    static final string LEVERAGE = '2';
    /*
    * @Description Wrapper class to manage the save of the dynamic form
    */
    public class PoliciesWrapper {
        /*
            * @Description String to show the error message
        */
        @AuraEnabled public String messageError {get; set;}
        /*
            * @Description Boolean to save info
        */
        @AuraEnabled public Boolean success {get; set;}
        /*
            * @Description Boolean know if the leverage test was calculated
        */
        @AuraEnabled public Boolean leverageTest {get; set;}
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param void
    * @return coid
    * @example Arc_Gen_Persistence_Leverage_Service service = new Arc_Gen_Persistence_Leverage_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Persistence_Leverage_Service() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that manage the leverage persistence service
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param listObject - list of sObject
    * @return Boolean - true/false
    * @example callPersistence(listObject)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static PoliciesWrapper callPersistence(List<sObject> listObject) {
        final PoliciesWrapper policieWrapper = new PoliciesWrapper();
        arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        final List<arce__Account_has_Analysis__c> accHasAnLts = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)listObject[0].get('id')});

        final List<sObject> apiFieldTypeList = arce.Arc_Gen_AccHasAnalysis_Data.getRelatedData(LIST_FIELDS, String.valueOf(listObject[0].get('id')));
        final Map<Id,arce.Arc_Gen_Account_Wrapper> accWrapMap = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{accHasAnLts[0].arce__Customer__c});
        final String participantid = arce.Arc_Gen_CallEncryptService.getEncryptedClient((String)accWrapMap.get(accHasAnLts[0].arce__Customer__c).accNumber);
        final String riskid = accHasAnLts[0].Name;
        final String leverageId = accHasAnLts[0].Name;
        final String ratingBlock = Arc_Gen_Persistence_Leverage_Helper.getRatingBlock(accHasAnLts[0]);
        final String currencyIsoCode = accHasAnLts[0].arce__ffss_for_rating_id__r.currencyIsoCode;
        final Map<String,String> configInfoMap = Arc_Gen_ServicePersitence_Locator.retConfigurationInfo(SERVICE_NAME);
        final String variable0 = Arc_Gen_Persistence_Leverage_Helper.getmissingJsonKeys(0, accHasAnLts[0].arce__gross_fin_debt_ebitda_number__c, currencyIsoCode).escapeJava();
        final String variable1 = Arc_Gen_Persistence_Leverage_Helper.getmissingJsonKeys(1, accHasAnLts[0].arce__ll_adj_debt_amount__c,currencyIsoCode).escapeJava();
        final String variable2 = Arc_Gen_Persistence_Leverage_Helper.getmissingJsonKeys(2, accHasAnLts[0].arce__ll_adj_debt_ebitda_number__c,currencyIsoCode).escapeJava();
        final String variable3 = Arc_Gen_Persistence_Leverage_Helper.getmissingJsonKeys(3, accHasAnLts[0].arce__current_proposed_amount__c,currencyIsoCode).escapeJava();
        final Boolean finSponsor = Arc_Gen_ServicePersitence_Utils.getDataRelatedRadio(FIN_SPONSOR, apiFieldTypeList);
        final String levTestType = Arc_Gen_Persistence_Leverage_Helper.getTypeOfAnalysis(apiFieldTypeList, ANALYSIS_TYPE);
        final String covenantType = Arc_Gen_Persistence_Leverage_Helper.getCovenantType(apiFieldTypeList, COVENANT_TYPE);
        final String beforeAdjClassType = Arc_Gen_Persistence_Leverage_Helper.getClasificationsAdj(apiFieldTypeList, BEF_ADJ);
        final String afterAdjClassType = Arc_Gen_Persistence_Leverage_Helper.getClasificationsAdj(apiFieldTypeList, AFT_ADJ);
        final String prevAnalysClassType = Arc_Gen_Persistence_Leverage_Helper.getClasificationsAdj(apiFieldTypeList, PREV_ANA_TYPE);
        final String currencyType = Arc_Gen_Persistence_Leverage_Helper.getCurrencyType(currencyIsoCode).escapeJava();
        final String arcePropose = getArcePropose(accHasAnLts[0].arce__current_proposed_amount__c);
        final Boolean testExcluded = accHasAnLts[0].arce__ll_test_scope_ind_type__c == '1';
        final String excludeType = testExcluded ? '"MANUAL"' : 'null';
        final String finalExcludedReason = testExcluded ? '"' + accHasAnLts[0].arce__ll_test_manl_excl_rsn_type__c + '"' : 'null';
        String jsonInput = Arc_Gen_ServicePersitence_Utils.getJsonInput(configInfoMap, listObject);
        final String jsonEnd = '"totalRatioCommUafir": "' + accHasAnLts[0].arce__ll_adj_debt_ebitda_number__c + '","debtOverUafir": "' + accHasAnLts[0].arce__gf_total_debt_amount__c + '",' + '"excludeType":"' + excludeType.escapeJava() + '","finalExcludedReason":"' + finalExcludedReason.escapeJava() + '","arcePropose":"' + arcePropose + '","ratingBlock":"' + ratingBlock.escapeJava() + '","cur":"' + currencyType + '","riskid":"' + riskid + '","participantid":"' + participantid + '","leverageId":"' + leverageId + '","variable0":"' + variable0 + '","variable1":"' + variable1 + '","variable2":"' + variable2 + '","variable3":"' + variable3 + '","levTestType":"' + levTestType + '","covenantType":"' + covenantType + '","beforeAdjClassType":"' + beforeAdjClassType + '","afterAdjClassType":"' + afterAdjClassType + '","prevAnalysClassType":"' + prevAnalysClassType + '","hasFinSponsor":"' + finSponsor +'"}';
        jsonInput += jsonEnd;
        iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME, jsonInput);
        final Boolean res = iasoResponse.serviceCode == SUCCESS_CODE || iasoResponse.serviceCode == CREATED || iasoResponse.serviceCode == UPDATED ? true : false;
        policieWrapper.messageError = iasoResponse.serviceMessage;
        policieWrapper.success = res;
        policieWrapper.leverageTest = true;

        return policieWrapper;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Gets arcePropose parameter to persist.
    * ----------------------------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com
    * @Date 2020-12-01
    * @param arcePropose - Value of the field
    * @return Value to persist
    * ----------------------------------------------------------------------------------------------------
    **/
    private static String getArcePropose(Decimal arcePropose) {
        return arcePropose == null ? '0.0' : String.valueOf(arcePropose);
    }
}