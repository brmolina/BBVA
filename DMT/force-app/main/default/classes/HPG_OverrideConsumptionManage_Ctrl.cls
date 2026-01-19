/**
* ____________________________________________________________________________
* Controller class for HPG_OverrideConsumptionManage.cmp Aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-11-15
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class HPG_OverrideConsumptionManage_Ctrl {
    /**
    * @description Get initial data
    * @param params - : params
    * @return retMap initial data
    */
    @AuraEnabled
    public static Map<String,Object> initialData(Map<String, Object> params) {
        Map<String, Object> retMap = new Map<String, Object>();
        Map<String, Object> paramsNew = params;
        Date todayDate = Date.today();
        retMap.put('consumptionLastLevelPicklist', getConsumptionLastLevelIdPicklist());
        final String action = paramsNew.containsKey('action') ? (String) paramsNew.get('action') : '';
        if (action == 'CREATE') {
            paramsNew.put('riskAnalystId', HPG_utils.getFederationIdentifier());
            paramsNew.put('overrideUploadDate', todayDate);
            paramsNew.put('overrideStartDate', todayDate - 1);
            paramsNew.put('overrideEndDate', todayDate - 1);
        }
        retMap.put('overrideStartDateMin', todayDate - 1);
        retMap.put('overrideEndDateMin', todayDate - 1);
        retMap.put('paramsNew', paramsNew);
        return retMap;
    }
    /**
    * @description Get XXXXXXX
    * @param paramsNew : paramsNew
    * @return XXXXXXX
    */
    @AuraEnabled
    public static Map<String,Object> validateChangeField(Map<String, Object> paramsNew) {
        // QUITAR params que ya no se usa
        Map<String, Object> retMap = new Map<String, Object>();
        Date overrideStartDateNew = Date.today() - 1;
        try {
            overrideStartDateNew = (Date) Date.valueOf((String)(paramsNew.get('overrideStartDate')));
        } catch (Exception e) { //NOSONAR
            System.debug(e.getMessage());//NOSONAR
            paramsNew.put('overrideStartDate', overrideStartDateNew);
        }
        if (overrideStartDateNew < Date.today() - 1) {
            paramsNew.put('overrideStartDate', Date.today() - 1);
        }
        Date overrideEndDateNew = overrideStartDateNew;
        try {
            overrideEndDateNew = (Date) Date.valueOf((String)(paramsNew.get('overrideEndDate')));
        } catch (Exception e) { //NOSONAR
            System.debug(e.getMessage());//NOSONAR
            paramsNew.put('overrideEndDate', overrideEndDateNew);
        }
        // End date has to be equal or later than Start date
        if (overrideEndDateNew < overrideStartDateNew) {
            overrideEndDateNew = overrideStartDateNew;
            paramsNew.put('overrideEndDate', overrideEndDateNew);
        }
        retMap.put('overrideStartDateMin', Date.today() - 1);
        retMap.put('overrideEndDateMin', overrideStartDateNew);
        retMap.put('paramsNew', paramsNew);
        return retMap;
    }
    /**
    * @description Get consumptionLastLevelId picklist values
    * @param - : No param
    * @return ConsumptionLastLevelId picklist values
    */
    @AuraEnabled
    public static List<HPG_Utils.PicklistValue_Wrapper> getConsumptionLastLevelIdPicklist() {
        List<HPG_Utils.PicklistValue_Wrapper> consumptionLastLevelPicklist = new List<HPG_Utils.PicklistValue_Wrapper>();
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper('', ''));
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper(Label.grid_field_10100, '10100'));
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper(Label.grid_field_10200, '10200'));
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper(Label.grid_field_20100, '20100'));
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper(Label.grid_field_20200, '20200'));
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper(Label.grid_field_30000, '30000'));
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper(Label.grid_field_40000, '40000'));
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper(Label.grid_field_60000, '60000'));
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper(Label.grid_field_80100, '80100'));
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper(Label.grid_field_80200, '80200'));
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper(Label.grid_field_130000, '130000'));
        consumptionLastLevelPicklist.add(new HPG_Utils.PicklistValue_Wrapper(Label.grid_field_140000, '140000'));
        return consumptionLastLevelPicklist;
    }
    /**
    * @description Create Override Consumption
    * @param paramsNew : paramsNew
    * @return retMap success
    */
    @AuraEnabled
    public static HPG_OverrideConsumption.Wrapper manageOverrideConsumption(Map<String, Object> paramsNew) {
        Boolean missingFields = false;
        final Map<String, Object> request = new Map<String, Object>();
        final Map<String, Object> jsonInputTemplate = new Map<String, Object>();
        String action = paramsNew.containsKey('action') ? (String) paramsNew.get('action') : '';
        if (action == 'CLIENT' || action == 'CONTRACT') {
            action = 'CREATE';
        }
        // customerId - Mandatory
        String customerId = paramsNew.containsKey('customerId') ? (String) paramsNew.get('customerId') : '';
        if (customerId == null || customerId == '') {
            missingFields = true;
        }
        jsonInputTemplate.put('customerId', customerId);
        // internalContractCodeDesc - Mandatory
        String internalContractCodeDesc = paramsNew.containsKey('internalContractCodeDesc') ? (String) paramsNew.get('internalContractCodeDesc') : '';
        if (internalContractCodeDesc == null || internalContractCodeDesc == '') {
            missingFields = true;
        }
        jsonInputTemplate.put('internalContractCodeDesc', internalContractCodeDesc);
        // overrideUploadDate - System date
        String overrideUploadDate = paramsNew.containsKey('overrideUploadDate') ? (String) paramsNew.get('overrideUploadDate') : '';
        jsonInputTemplate.put('overrideUploadDate', overrideUploadDate);
        // consumptionLastLevelId - Consumption Last Level Id - Mandatory
        String consumptionLastLevelId = paramsNew.containsKey('consumptionLastLevelId') ? (String) paramsNew.get('consumptionLastLevelId') : '';
        jsonInputTemplate.put('consumptionLastLevelId', consumptionLastLevelId);
        if (consumptionLastLevelId == null || consumptionLastLevelId == '') {
            missingFields = true;
        }
        // committedContractsDisposedAmount - Committed Contracts Drawn Amount
        if (paramsNew.containsKey('committedContractsDisposedAmount') && String.valueOf(paramsNew.get('committedContractsDisposedAmount')) != '') {
            jsonInputTemplate.put('committedContractsDisposedAmount', Decimal.valueOf(String.valueOf(paramsNew.get('committedContractsDisposedAmount'))));
        }
        // uncommittedContractsDisposedAmount - Uncommitted Contracts Drawn Amount
        if (paramsNew.containsKey('uncommittedContractsDisposedAmount') && String.valueOf(paramsNew.get('uncommittedContractsDisposedAmount')) != '') {
            jsonInputTemplate.put('uncommittedContractsDisposedAmount', Decimal.valueOf(String.valueOf(paramsNew.get('uncommittedContractsDisposedAmount'))));
        }
        // committedContractsNonDisposedAmount - Committed Contracts Undrawn Amount
        if (paramsNew.containsKey('committedContractsNonDisposedAmount') && String.valueOf(paramsNew.get('committedContractsNonDisposedAmount')) != '') {
            jsonInputTemplate.put('committedContractsNonDisposedAmount', Decimal.valueOf(String.valueOf(paramsNew.get('committedContractsNonDisposedAmount'))));
        }
        // uncommittedContractsNonDisposedAmount - Uncommitted Contracts Undrawn Amount
        if (paramsNew.containsKey('uncommittedContractsNonDisposedAmount') && String.valueOf(paramsNew.get('uncommittedContractsNonDisposedAmount')) != '') {
            jsonInputTemplate.put('uncommittedContractsNonDisposedAmount', Decimal.valueOf(String.valueOf(paramsNew.get('uncommittedContractsNonDisposedAmount'))));
        }
        // authorizedRiskAmount - Pending Authorized
        if (paramsNew.containsKey('authorizedRiskAmount') && String.valueOf(paramsNew.get('authorizedRiskAmount')) != '') {
            jsonInputTemplate.put('authorizedRiskAmount', Decimal.valueOf(String.valueOf(paramsNew.get('authorizedRiskAmount'))));
        }
        // riskAnalystId - Federation ID
        String riskAnalystId = paramsNew.containsKey('riskAnalystId') ? (String) paramsNew.get('riskAnalystId') : HPG_Utils.getFederationIdentifier();
        jsonInputTemplate.put('riskAnalystId', riskAnalystId);
        // overrideStartDate - System date - 1 or later - Mandatory
        String overrideStartDate = paramsNew.containsKey('overrideStartDate') ? (String) paramsNew.get('overrideStartDate') : '';
        jsonInputTemplate.put('overrideStartDate', overrideStartDate);
        // overrideEndDate - Equal or later to overrideStartDate - Mandatory
        String overrideEndDate = paramsNew.containsKey('overrideEndDate') ? (String) paramsNew.get('overrideEndDate') : '';
        jsonInputTemplate.put('overrideEndDate', overrideEndDate);
        // overrideComments - Mandatory
        String overrideComments = paramsNew.containsKey('overrideComments') ? (String) paramsNew.get('overrideComments') : '';
        if (overrideComments == null || overrideComments == '') {
            missingFields = true;
        }
        jsonInputTemplate.put('overrideComments', overrideComments);
        // currencyId - EUR
        jsonInputTemplate.put('currencyId', 'EUR');
        request.put('jsonInputTemplate' , JSON.serialize(jsonInputTemplate));
        HPG_OverrideConsumption.Wrapper overrideConsumption = new HPG_OverrideConsumption.Wrapper();
        if (missingFields) {
            overrideConsumption.success = false;
            overrideConsumption.errorMessage = 'Missing mandatory fields';
        }else {
            If(action == 'CREATE') {
                overrideConsumption = HPG_OverrideConsumption.callOverrideConsumption('HPG_CreateOverrideConsumption', request);
            } else if (action == 'EDIT') {
                overrideConsumption = HPG_OverrideConsumption.callOverrideConsumption('HPG_UpdateOverrideConsumption', request);
            }
        }
        return overrideConsumption;
    }
}