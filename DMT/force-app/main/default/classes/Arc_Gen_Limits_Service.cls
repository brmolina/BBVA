/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Limits_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-01-28
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class to manage the service call of getLimits
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-06-01 joseluis.garcia4.contractor@bbva.com
*             Add check for currency.
* |2020-04-15 javier.soto.carrascosa@bbva.com
*             Changed the params of the service call
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-27 juanignacio.hita.contractor@bbva.com
*             Created callLimitById method and add PMD warning
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount')
public without sharing class Arc_Gen_Limits_Service {
    /**
        * @Description: param to call limits service
    */
    static final string S_GROUP = 'GROUP';
    /**
        * @Description: param to call limits service
    */
    static final string SUBSIDIARY = 'SUBSIDIARY';
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
    private Arc_Gen_Limits_Service() {

    }
    /**
        * @Description : wrapper for limits service
    */
    public class LimitsResponse {
        /**
        * @Description : Id of the typology/modality from limits service
        */
        public String typoModId {get;set;}
        /**
        * @Description : name of the typology/modality from limits service
        */
        public String name {get;set;}
        /**
        * @Description : currentLimit amount of the typology/modality from limits service
        */
        public Double currentLimit {get;set;}
        /**
        * @Description : outstanding amount of the typology/modality from limits service
        */
        public Double outstanding {get;set;}
        /**
        * @Description : commited amount of the typology/modality from limits service
        */
        public Double commited {get;set;}
        /**
        * @Description : uncommited amount of the typology/modality from limits service
        */
        public Double uncommited {get;set;}
        /**
        * @Description : lastApproved amount of the typology/modality from limits service
        */
        public Double  lastApproved {get;set;}
        /**
        * @Description : currencyType of the typology/modality from limits service
        */
        public String currencyType {get;set;}
        /**
        * @Description : unit of the typology/modality from limits service
        */
        public String unit {get;set;}
        /**
        * @Description : gblCodeResponse error of the limits service
        */
        public String gblCodeResponse {get;set;}
        /**
        * @Description : gblSuccess response of the limits service
        */
        public Boolean gblSuccess {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the parameters to the list customer service
    --------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-01-28
    * @param String typeOfClient
    * @param String client number
    * @param String serviceName
    * @return Map<String,LimitsResponse> - Map that contains the response of the called service
    * @example callLimitsService(typeOfClient,accNumber,serviceName)
    **/
    public static Map<String,LimitsResponse> callLimitsService(String typeOfClient, String accNumber, String serviceName) {
        return callLimitsService(typeOfClient, accNumber, serviceName, null);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the parameters to the list customer service
    --------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-01-28
    * @param String typeOfClient
    * @param String client number
    * @param String serviceName
    * @param String currencyToCheck - Checks that limits are in the same currency as the provided
    * @return Map<String,LimitsResponse> - Map that contains the response of the called service
    * @example callLimitsService(typeOfClient,accNumber,serviceName)
    **/
    public static Map<String,LimitsResponse> callLimitsService(String typeOfClient, String accNumber, String serviceName, String currencyToCheck) {
        arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
        LimitsResponse limRespWrap = new LimitsResponse();
        Map<String,LimitsResponse> limitsResponseMap = new Map<String,LimitsResponse>();
        final String customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(accNumber);
        final String params = '{"ownerType":"' + typeOfClient + '","ownerId":"' + customerNumber + '"}';
        iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(serviceName, params);
        if (iasoResponse.serviceCode == String.valueOf(serviceMessage.CODE_200)) {
            limitsResponseMap = Arc_Gen_Limits_Service_Helper.getServiceData(iasoResponse.serviceResponse, currencyToCheck);
        } else {
            limRespWrap.gblCodeResponse = iasoResponse.serviceCode;
            limitsResponseMap.put('ERROR', limRespWrap);
        }
        return limitsResponseMap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Call limit service from record id of account has analysis
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   2020-11-27
    * @param  String recordId : record id of account has analysis
    * @param  String selectedCurrency
    * @return Map<String, Arc_Gen_Limits_Service.LimitsResponse>
    * @example Map<String,Arc_Gen_Limits_Service.LimitsResponse> map = callLimitById(String recordId, String selectedCurrency)
    **/
    public static Map<String,Arc_Gen_Limits_Service.LimitsResponse> callLimitById(String recordId, String selectedCurrency) {
        final String typoOfCustomer = arce.Arc_Gen_GenericUtilities.getTypeOfCustomer(recordId) == 'Group' ? S_GROUP : SUBSIDIARY;
        final arce__Account_has_Analysis__c accHasRel = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId);
        final Map<Id, arce.Arc_Gen_Account_Wrapper> accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{accHasRel.arce__customer__c});
        final Map<String,Arc_Gen_Limits_Service.LimitsResponse> mapLimits = Arc_Gen_Limits_Service.callLimitsService(typoOfCustomer,accWrapper.get(accHasRel.arce__customer__c).accNumber, 'limits', selectedCurrency);
        if (mapLimits.get('ERROR') != null) {
            final String message = System.Label.Arc_Gen_ServicePersistenceError;
            final AuraHandledException excep = new AuraHandledException(message);
            excep.setMessage(message);
            throw excep;
        }
        return mapLimits;
    }
}