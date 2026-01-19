/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Auto_ExpTable_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-01-28
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class for policie table
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-05-31 javier.soto.carrascosa@bbva.com
*             Change parameter getColumns method
* |2020-06-01 joseluis.garcia4.contractor@bbva.com
*             Add check for currency.
* |2020-06-16 joseluis.garcia4.contractor@bbva.com
*             Don't refresh limits from service if user has no permissions on analysis.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-03-17 juanignacio.hita.contractor@bbva.com
*             Set status persistence of the customer in insertProducts method when it is outdated
*             Add call to limits persistence in getData method
* |2021-03-17 juanignacio.hita.contractor@bbva.com
*             Fixed some string literal as static final string
*             Added a static final string
* |2021-05-17 juanignacio.hita.contractor@bbva.com
*             Refactoring class
* |2021-05-24 juanignacio.hita.contractor@bbva.com
*             Add to call hasManualTablePerm method and currency aura exception
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_Auto_ExpTable_Service implements Arc_Gen_Expandible_Table_Interface {
    /**
        * @Description: Param to call limits service
    */
    static final string S_GROUP = 'GROUP';
    /**
        * @Description: Param to call limits service
    */
    static final string SUBSIDIARY = 'SUBSIDIARY';
    /**
        * @Description: String with value 'true'
    */
    static final string COND_TRUE = 'true';
    /**
    * --------------------------------------------------------------------------------------
    * @Description get data to build table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-01-28
    * @param recordId - id of the acc has analysis object
    * @return Arc_Gen_DataTable - wrapper with the info to build the table
    * @example getData(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public Arc_Gen_DataTable getData(Id recordId) {
        final arce__Account_has_Analysis__c accHas = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)recordId})[0];

        if (Arc_Gen_Auto_ExpTable_Service_Helper.hasManualTablePerm(recordId)) {
            // Check if is fill currency
            if (accHas.arce__currency_id__c == null || accHas.arce__currency_id__c == '') {
                throw new AuraHandledException(
                    String.format(System.Label.Arc_Gen_CouldNotLoadPolicies, new List<String> { System.Label.Arc_Gen_PoliciesErrorNoCurrency }));
            }
            if (accHas.arce__call_limit_service__c == false) {
                Arc_Gen_Auto_ExpTable_Service_Helper.generateLimExpo(recordId);
                accHas.arce__call_limit_service__c = true;
                accHas.arce__magnitude_unit_type__c = '1';
                accHas.arce__prev_magnitude_unit_type__c = '1';
                accHas.arce__last_update_policie__c = System.now();
                arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(new List<arce__Account_has_Analysis__c>{accHas});
            }
        } else {
            if (accHas.arce__call_limit_service__c == false) {
                Arc_Gen_Auto_ExpTable_Service_Helper.fillServiceData(recordId, accHas.arce__currency_id__c);
            }
        }
        final Arc_Gen_DataTable dataJson = new Arc_Gen_DataTable();
        final arce__analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce((String)recordId);
        final string sanctionResult = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(New List<Id>{arceVar.Id})[0].arce__anlys_wkfl_sanction_rslt_type__c;
        dataJson.columns = Arc_Gen_Expandible_Table_Service.getColumns(sanctionResult);
        dataJson.data = Arc_Gen_Expandible_Table_Service.buildNestedData(recordId);
        return dataJson;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Change the flag to consult limit service
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-01-28
    * @param recordId - id of the acc has analysis object
    * @return void
    * @example changeServiceFlag(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static void changeServiceFlag(Id recordId) {
        // Do not force refresh of table if user has no permission to edit this analysis.
        if (Arc_Gen_TabSet_service.getPermissionToEdit(recordId) == COND_TRUE) {
            final List<arce__Account_has_Analysis__c> acchasAn = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)recordId});
            acchasAn[0].arce__call_limit_service__c = false;
            arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(acchasAn);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description get a list of products
    * --------------------------------------------------------------------------------------
    * @param tipologia - name of the typology
    * @return lista.
    * @example getProductsService(tipologia)
    * --------------------------------------------------------------------------------------
    **/
    public static Map<String,Double> insertProducts(String accHasAId, String tipologia, String prodId) {
        final Map<String,Double> prodResp = new Map<String,Double>();
        Map<String,Arc_Gen_Limits_Service.LimitsResponse> limitRespMap = new Map<String,Arc_Gen_Limits_Service.LimitsResponse>();
        final String typoOfCustomer = arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(accHasAId) == 'Group' ? S_GROUP : SUBSIDIARY;
        final arce__Account_has_Analysis__c accHasRel = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(accHasAId);
        final Map<Id,arce.Arc_Gen_Account_Wrapper> accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{accHasRel.arce__customer__c});
        final Map<Id,Arc_Gen_Product_Wrapper> pWrap = Arc_Gen_Product_Locator.getProductsFromTypology(tipologia);
        final String selectedCurrency = accHasRel.arce__currency_id__c == null ? '' : accHasRel.arce__currency_id__c;
        limitRespMap = Arc_Gen_Limits_Service.callLimitsService(typoOfCustomer,accWrapper.get(accHasRel.arce__customer__c).accNumber, 'limits', selectedCurrency);
        if (limitRespMap.containsKey('ERROR')) {
            // Set status persistence of the customer in insertProducts method when it is outdated
            Arc_Gen_Validate_Customer_Data.updateStatusLimitPers(accHasAId, false);
            throw new QueryException(Label.serviceFailure + ' ' + limitRespMap.get('ERROR').gblCodeResponse);
        }
        if (limitRespMap.containsKey(pWrap.get(prodId).externalId)) {
            prodResp.put('lastApproved',limitRespMap.get(pWrap.get(prodId).externalId).lastApproved);
            prodResp.put('commited',limitRespMap.get(pWrap.get(prodId).externalId).commited);
            prodResp.put('uncommited',limitRespMap.get(pWrap.get(prodId).externalId).uncommited);
            prodResp.put('currentLimit',limitRespMap.get(pWrap.get(prodId).externalId).currentLimit);
            prodResp.put('outstanding',limitRespMap.get(pWrap.get(prodId).externalId).outstanding);
        }
        return prodResp;
    }
}