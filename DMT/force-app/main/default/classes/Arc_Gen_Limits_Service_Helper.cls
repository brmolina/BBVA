/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Limits_Service_Helper
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-01-28
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Helper class to manage the service call of getLimits
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-04-26 javier.soto.carrascosa@bbva.com
*             Changed mapping of limit service response
* |2020-06-01 joseluis.garcia4.contractor@bbva.com
*             Add check for currency.
* |2020-11-30 juanignacio.hita.contractor@bbva.com
*             Created validationCurrency method
* |2021-03-17 juanignacio.hita.contractor@bbva.com
*             Removes currency validation for add before of the call to limit service
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_Limits_Service_Helper {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-01-28
    * @param void
    * @return void
    * @example Arc_Gen_Limits_Service service = new Arc_Gen_Limits_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Limits_Service_Helper() {

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description get limit service data
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param mapResponse - service response
    * @param currencyToCheck - The currency used to get data from service (null if there is no need to check currency).
    * @return Map<String,Arc_Gen_Limits_Service.LimitsResponse> - Map with the info of the service
    * @example getServiceData(mapResponse)
    * --------------------------------------------------------------------------------------
    **/
    public static Map<String,Arc_Gen_Limits_Service.LimitsResponse> getServiceData(Map<String,Object> mapResponse, String currencyToCheck) {
        final Map<String,Arc_Gen_Limits_Service.LimitsResponse> limitsRespMap = new Map<String,Arc_Gen_Limits_Service.LimitsResponse>();
        final Map<String,Object> data = (Map<String,Object>)mapResponse.get('data');
        final List<Object> ownerData = (List<Object>)data.get('owners');

        for(integer i = 0; i < ownerData.size(); i++) {
            final Map<String,Object> ownerMap = (Map<String,Object>)ownerData[i];
            final List<Object> limitsLts=(List<Object>)ownerMap.get('limits');
            for (integer j = 0; j < limitsLts.size(); j++) {
                final Arc_Gen_Limits_Service.LimitsResponse limitWrapp = new Arc_Gen_Limits_Service.LimitsResponse();
                Map<String,Object> authorizedLimitMap = new Map<String,Object>();
                Map<String,Object> currentLimitMap = new Map<String,Object>();
                Map<String,Object> outstandingMap = new Map<String,Object>();
                Map<String,Object> commitedMap =  new Map<String,Object>();
                Map<String,Object> uncommitedMap =  new Map<String,Object>();
                Map<String,Object> limitMap = (Map<String,Object>)limitsLts[j];
                Map<String,Object> lineMap = getMap(limitMap,'line');
                Map<String,Object> directRiskMap = getMap(limitMap,'directRisk');
                authorizedLimitMap = getMap(limitMap,'authorizedLimit');
                currentLimitMap = getMap(directRiskMap,'formalized');
                outstandingMap = getMap(directRiskMap,'disposed');
                commitedMap = getMap(directRiskMap,'approvedCommitted');
                uncommitedMap = getMap(directRiskMap,'approvedUncommitted');
                limitWrapp.name = String.valueOf(lineMap.get('name'));
                limitWrapp.lastApproved = getAmount(authorizedLimitMap, 'amount', currencyToCheck);
                limitWrapp.currentLimit = getAmount(currentLimitMap, 'amount', currencyToCheck);
                limitWrapp.outstanding = getAmount(outstandingMap, 'amount', currencyToCheck);
                limitWrapp.commited = getAmount(commitedMap, 'amount', currencyToCheck);
                limitWrapp.uncommited = getAmount(uncommitedMap, 'amount', currencyToCheck);
                limitWrapp.currencyType = getCurrency(authorizedLimitMap, 'currency');
                limitsRespMap.put(String.valueOf(lineMap.get('id')), limitWrapp);
            }
        }
        return limitsRespMap;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validate Map
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param mapParam - (Map<String,Object>)
    * @param param - Map key
    * @return Map<String,Object>
    * @example getMap(mapParam, param)
    * --------------------------------------------------------------------------------------
    **/
    public static Map<String,Object> getMap(Map<String,Object> mapParam, String param) {
        return mapParam.get(param) == null ? new Map<String,Object>() : (Map<String,Object>)mapParam.get(param);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validate Map
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param mapParam - (Map<String,Object>)
    * @param param - Map key
    * @param currencyToCheck - Check that the currency matches. null = no check.
    * @return Map<String,Object>
    * @example getAmount(mapParam, param)
    * --------------------------------------------------------------------------------------
    **/
    public static Double getAmount(Map<String,Object> mapParam, String param, String currencyToCheck) {
        final String amountCurrency = (String) mapParam.get('currency');
        Double returnedAmount;

        if (currencyToCheck == null || (amountCurrency == currencyToCheck && mapParam.get(param) != null)) {
            returnedAmount = Double.valueOf(mapParam.get(param));
        } else {
            returnedAmount = 0;
        }
        return returnedAmount;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description validate Map
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param mapParam - (Map<String,Object>)
    * @param param - Map key
    * @return Map<String,Object>
    * @example getCurrency(mapParam, param)
    * --------------------------------------------------------------------------------------
    **/
    public static String getCurrency(Map<String,Object> mapParam, String param) {
        return mapParam.get(param) == null ? 'N/A' : String.valueOf(mapParam.get(param));
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Currency validation between the one returned by the service and the one selected by the user
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   2020-11-27
    * @param  Map<String, Arc_Gen_Limits_Service.LimitsResponse> map with the service response retrieved
    * @param  String selectedCurrency
    * @return void
    * @example validationCurrency(limitRespMap, selectedCurrency);
    **/
    public static void validationCurrency(Map<String,Arc_Gen_Limits_Service.LimitsResponse> limitRespMap, String selectedCurrency) {
        String currencyService = '';
        for (String keyMap : limitRespMap.keySet()) {
            final String currencyTemp = limitRespMap.get(keyMap).currencyType;
            if (currencyService == '' || currencyService == currencyTemp ) {
                currencyService = currencyTemp;
            }
        }

        if (currencyService != selectedCurrency) {
            final Map<String, String> mapData = new Map<String, String> {
                'selectedCurrency' => selectedCurrency,
                'currencyService' => currencyService
            };
            final String message = arce.Arc_Gen_GenericUtilities.fillMapDynamicLabel(mapData, System.Label.Arc_Gen_CurrencyValidationPolicies);
            final AuraHandledException excep = new AuraHandledException(message);
            excep.setMessage(message);
            throw excep;
        }
    }
}