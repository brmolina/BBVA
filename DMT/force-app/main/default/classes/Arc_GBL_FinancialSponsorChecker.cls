/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_GBL_FinancialSponsorChecker
* @Author   joseluis.garcia4.contractor@bbva.com
* @Date     Created: 22/06/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Global class that implements a generic logic to check if a economicGroup has a financial
* sponsor. This default implementation queries the economic group details service.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-06-22 joseluis.garcia4.contractor@bbva.com
*             Class creation
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2022-03-29 juanignacio.hita.contractor@bbva.com
*             Added throw CODE_204 specific exception
* -----------------------------------------------------------------------------------------------
*/
global without sharing class Arc_GBL_FinancialSponsorChecker implements Arc_Gen_FinancialSponsor_Interface { //NOSONAR
    /**
    * @Description: Name of the service to query.
    */
    private static final String SERVICE_NAME = 'economicGroupDetails';

    /**
    *-------------------------------------------------------------------------------
    * @description Queries economicGroupDetails service to check if the economic group
    * has financial sponsor
    --------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 2020-06-22
    * @param encryptedGroup - The encrypted number of the group
    * @return whether or not the group has financial sponsor according to the service.
    **/
    public Boolean getFinancialSponsorStatus(String encryptedGroup) {
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
        // Service parameters.
        final Map<String, String> parameterMap = new Map<String, String>();
        parameterMap.put('economicGroupId', encryptedGroup);

        // Call engine.
        final String jsonInput = JSON.serialize(parameterMap);
        final arce.Arc_Gen_getIASOResponse.ServiceResponse iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME, jsonInput);

        // Process response.
        Boolean result;
        if (iasoResponse.serviceCode == String.valueOf(serviceMessage.CODE_200)) {
            result = getHasFinancialSponsorFromResponse(iasoResponse);
        } else if (iasoResponse.serviceCode == String.valueOf(serviceMessage.CODE_204)) {
            throw new QueryException(String.valueOf(serviceMessage.CODE_204));
        } else {
            throw new QueryException(System.Label.Arc_Gen_EconomicGroupDetailsError);
        }

        return result;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Parses result of economicGroupDetails service to extract "hasFinancialSponsor"
    * field.
    --------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 2020-06-22
    * @param iasoResponse - The response wrapper from the IASO service call.
    * @return whether or not the group has financial sponsor according to the service.
    **/
    private Boolean getHasFinancialSponsorFromResponse(arce.Arc_Gen_getIASOResponse.ServiceResponse iasoResponse) {
        final Map<String, Object> dataObj = (Map<String, Object>) iasoResponse.serviceResponse.get('data');
        final Map<String, Object> financialSponsorObj = (Map<String, Object>) dataObj.get('financialSponsor');
        return (Boolean) financialSponsorObj.get('hasFinancialSponsor');
    }
}