/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistencePolicies_service
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 2020-10-26
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages call policies persistence service
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-10-26 juanignacio.hita.contractor@bbva.com
*             Class creation.
* |2021-03-05 juanignacio.hita.contractor@bbva.com
*             Refactor callPoliciesPersService method and add CODES_ACCEPT
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_PersistencePolicies_service {
    /**
        * @Description: String with the name of service persistence
    */
    static final string SERVICE_NAME = 'policiesPersist';

    /**
        * @Description: Map unit field
    */
    private static final Map<String, String> POLICY_TYPE = new Map<String, String> {
        '1' => 'INCREASE',
        '2' => 'EXTINGUISH',
        '3' => 'MAINTAIN',
        '4' => 'DECREASE'
    };

    /**
        * @Description: Policy type values
    */
    private static final Map<String, String> POLICY_UNIT = new Map<String, String> {
        '1' => 'UNITS',
        '2' => 'THOUSANDS',
        '3' => 'MILLIONS',
        '4' => 'THOUSANDS_MILLIONS'
    };
    /**
        * @Description: Codes accepted by persistence services
    */
    static final List<String> CODES_ACCEPT = new List<String> {'200', '201', '202', '204'};

    /*------------------------------------------------------------------------------------------------------
    * @Description Builder Arc_Gen_PersistencePolicies_service
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2020-09-30
    * @param    null
    * @return   Arc_Gen_PersistencePolicies_service
    * @example  new Arc_Gen_PersistencePolicies_service()
    * */
    @TestVisible
    private Arc_Gen_PersistencePolicies_service() {}

    /*------------------------------------------------------------------------------------------------------
    * @Description Method that call policies persistence service
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2020-10-26
    * @param    arce__Account_has_Analysis__c accAha
    * @param    arce__Account_has_Analysis__c accAhaOld - account_has_analysis before save
    * @return   Boolean
    * @example  Boolean retSt = callPoliciesPersService(accAha);
    * */
    public static Boolean callPoliciesPersService(arce__Account_has_Analysis__c accAha, arce__Account_has_Analysis__c accAhaOld) {
        Boolean calloutOK = false;
        Map<String, Object> mapObj = createPoliciesJsonPers(accAha);
        if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(mapObj)) {
            final Map<Id, arce.Arc_Gen_Account_Wrapper> accWrapMap = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{accAhaOld.arce__Customer__c});
            final String participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient((String)accWrapMap.get(accAhaOld.arce__Customer__c).accNumber);
            final String jsonInput = '{"risk-assessment-id" : "' + accAhaOld.Name +
                                    '", "participant-id" : "' + participantId +
                                    '", "JSONIN" : ' + JSON.serialize(JSON.serialize(mapObj)) +'}';
            final arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME, jsonInput);
            if (CODES_ACCEPT.contains(iasoResponse.serviceCode)) {
                calloutOK = true;
            }
        }
        return calloutOK;
    }
    /*------------------------------------------------------------------------------------------------------
    * @Description Create policies json body for policy persistence service
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2020-10-26
    * @param    arce__Account_has_Analysis__c accAha
    * @return   Map<String, Object>
    * @example  Map<String, Object> mapObj = createPoliciesJsonPers(accAha);
    * */
    public static Map<String, Object> createPoliciesJsonPers(arce__Account_has_Analysis__c accAha) {
        Map<String, Object> mapObj = new Map<String, Object>();
        mapObj = Arc_Gen_Persistence_Utils.addifFilled(mapObj, 'amountSetting', addAmountSetting(accAha));
        Arc_Gen_Persistence_Utils.addDateToMap(mapObj, 'approvalDate', accAha.arce__Analysis__r.arce__analysis_risk_sanction_date__c );
        Arc_Gen_Persistence_Utils.addDateToMap(mapObj, 'expirationDate', accAha.arce__gf_anlys_risk_prps_expiry_date__c);
        // Policy type is mandatory in the service
        if (accAha.arce__risk_policy_type__c == null || accAha.arce__risk_policy_type__c == '') {
            mapObj = new Map<String, Object>();
        } else {
            final String riskPolicyType = POLICY_TYPE.get(accAha.arce__risk_policy_type__c);
            final Map<String, Object> mapPolicy = new Map<String, Object> { 'id' => riskPolicyType.toUpperCase() };
            mapObj = Arc_Gen_Persistence_Utils.addifFilled(mapObj, 'policyType', mapPolicy);
            if (accAha.arce__risk_request_desc__c != '' && accAha.arce__risk_request_desc__c != null) {
                //mapObj.put('comments', accAha.arce__risk_request_desc__c);
                String valueStr = (String) accAha.arce__risk_request_desc__c;
                valueStr = valueStr.length() > 1000 ? valueStr.substring(0,999) : valueStr;
                mapObj.put('comments', valueStr);
            }
        }
        return mapObj;
    }
    /*------------------------------------------------------------------------------------------------------
    * @Description Add amount setting to map for json body
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2020-10-26
    * @param    arce__Account_has_Analysis__c accAha
    * @return   Map<String, Object>
    * @example  Map<String, Object> mapObj = addAmountSetting(accAha);
    * */
    public static Map<String, Object> addAmountSetting(arce__Account_has_Analysis__c accAha) {
        final Map<String, Object> amountSet = new Map<String, Object>();
        amountSet.put('currency', accAha.arce__currency_id__c);
        if (accAha.arce__magnitude_unit_type__c != '' && accAha.arce__magnitude_unit_type__c != null) {
            amountSet.put('unit', POLICY_UNIT.get(accAha.arce__magnitude_unit_type__c));
        }
        return amountSet;
    }

}