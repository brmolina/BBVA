/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RiskFilters_Service
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 11/12/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |11/12/2020 juanignacio.hita.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyMethods, sf:TooManyFields')
public class Arc_Gen_RiskFilters_Service {
    /**
    * @Description: Risk filter arce config for local class implementation
    */
    static final string RISKFILTER_CONF = 'RiskFilterLocalServiceIASO';

    /**
    * @Description: Risk filter wrapper service
    */
    public class RiskFilterWrapper {
        /**
        * @Description: Risk filter data
        */
        public List<RiskFilter> data {get; set;}
    }
    /**
        * @Description: RiskFilter wrapper
    */
    public class RiskFilter {
        /**
            * @Description: Unique identifier of the risk and delinquency filter.
        */
        public String riskId {get; set;}
        /**
            * @Description: Description of the filter
        */
        public String description {get; set;}
        /**
            * @Description: Type of the risk and delinquency filter
        */
        public String riskFilterType {get; set;}
        /**
            * @Description: Bureau of the risk filter. Is an external company to which certain information relevant to the bank is consulted.
        */
        public BureauWrap bureau {get; set;}
        /**
            * @Description: Information Type identifier. Indicates the origin of the filter of the person involved in the operation.
        */
        public String informationType {get; set;}
        /**
            * @Description: Filter severity type identifier.
        */
        public String severity {get; set;}
        /**
            * @Description: This field is the result of the filter validation tool and indicates the filter that is not fulfilled by the customer.
        */
        public String detectedFilter {get; set;}
        /**
            * @Description: Monetary amount affected by the risk and delinquency filter.
        */
        public RiskFilterAmount riskFilterAmount {get; set;}
        /**
            * @Description: Information on customer contracts in the bank affected by risk and delinquency filters.
        */
        public ContractsInformation contractsInfo {get; set;}
        /**
            * @Description: Date of the oldest age of the risk and delinquency filter.
        */
        public String lastDate {get; set;}
        /**
            * @Description: Date of lowest age of the risk and delinquency filter.
        */
        public String firstDate {get; set;}
        /**
            * @Description: Historical filter indicator. This attribute only applies and is required if riskFilter
        */
        public Boolean isHistorical {get; set;}
        /**
            * @Description: Indicates the status of risk and deliquency filters for the consulted customer.
        */
        public String filterStatus {get; set;}
        /**
            * @Description: Risk calification filter for the customer.
        */
        public RiskCalification riskCalification {get; set;}
    }

    /**
        * @Description: Information Type identifier.
    */
    public class BureauWrap {
        /**
            * @Description: Bureau identifier.
        */
        public String bureauId {get; set;}
        /**
            * @Description: Bureau description
        */
        public String description {get; set;}
    }

    /**
        * @Description: Monetary amount affected by the risk and delinquency filter.
    */
    public class RiskFilterAmount {
        /**
            * @Description: Monetary amount.
        */
        public Decimal amount {get; set;}
        /**
            * @Description: String based on ISO-4217 for specifying the currency.
        */
        public String currencyRisk {get; set;}
    }

    /**
        * @Description: Information on customer contracts in the bank affected by risk and delinquency filters.
    */
    public class ContractsInformation {
        /**
            * @Description: Number of contracts affected by the risk and delinquency filter.
        */
        public Integer quantity {get; set;}
        /**
            * @Description: Status of the contracts affected by the risk and delinquency filter.
        */
        public String status {get; set;}
    }

    /**
        * @Description: Risk calification filter for the customer
    */
    public class RiskCalification {
        /**
            * @Description: Identifier of the value taken by the risk calification.
        */
        public String riskCalId {get; set;}
        /**
            * @Description: Description of the value taken by the risk calification.
        */
        public String name {get; set;}
        /**
            * @Description: Action to take for the risk and delinquency rating filter.
        */
        public String actionPolicy {get; set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Constructor method
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 11/12/2020
    * @param void
    * @return void
    * @example Arc_Gen_RiskFilters_Service()
    **/
    @TestVisible
    private Arc_Gen_RiskFilters_Service() {}

    /**
    *-------------------------------------------------------------------------------
    * @description Method that call to local service implementation for risk filter service
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    18/12/2020
    * @param   Map<String, Object> mapObj
    * @return  Arc_Gen_ServiceAndSaveResponse
    * @example Arc_Gen_ServiceAndSaveResponse riskFilter = calloutService(mapObj);
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse calloutService(Map<String, Object> mapObj) {
        final arce.Arc_Gen_IASO_Utils_Interface riskFilterLocal = Arc_Gen_GenericUtilitiesInterface.getLocalServiceIASO(RISKFILTER_CONF);
        final String reqJSON = riskFilterLocal.setServiceParams(mapObj);
        final arce.Arc_Gen_getIASOResponse.ServiceResponse resService = riskFilterLocal.callService(reqJSON);
        // Add participant type in mapObj
        final Map<String, Object> reqMap = (Map<String, Object>) JSON.deserializeUntyped(reqJSON);
        final String participantType = (String) reqMap.get('participantType');
        mapObj.put('participantType', participantType);
        arce.Arc_Gen_ServiceAndSaveResponse serv = riskFilterLocal.setupService(resService, mapObj);
        return serv;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that processes the service response
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    11/12/2020
    * @param   Map<String, Object> serviceResponse
    * @param   String participantType
    * @return  RiskFilterWrapper
    * @example RiskFilterWrapper riskFilter = processResponse(serviceResponse);
    **/
    public static RiskFilterWrapper processResponse(Map<String, Object> serviceResponse, String participantType) {
        final RiskFilterWrapper riskFilterWrap = new RiskFilterWrapper();
        final List<RiskFilter> lstRiskFilter = new List<RiskFilter>();
        List<Map<String, Object>> lstMapObj = new List<Map<String, Object>>();
        if (participantType == arce.Arc_Gen_Constants.GROUP_S) {
            lstMapObj = getListFromJson(serviceResponse, 'data');
        } else if (participantType == arce.Arc_Gen_Constants.SUBS_S) {
            lstMapObj = getListFromJson(serviceResponse, 'items');
        }
        for (Map<String, Object> mapObj : lstMapObj) {
            final RiskFilter riskFilter = new RiskFilter();
            riskFilter.riskId = (String) mapObj.get('id');
            riskFilter.description = (String) mapObj.get('description');
            riskFilter.riskFilterType = (String) mapObj.get('riskFilterType');
            riskFilter.bureau = getBureauMap(mapObj);
            riskFilter.informationType = (String) mapObj.get('informationType');
            riskFilter.severity = (String) mapObj.get('severity');
            riskFilter.detectedFilter = (String) mapObj.get('detectedFilter');
            riskFilter.riskFilterAmount = getRiskFilterAmount(mapObj);
            riskFilter.contractsInfo = getContractInfo(mapObj);
            riskFilter.lastDate = (String) mapObj.get('lastDate');
            riskFilter.firstDate = (String) mapObj.get('firstDate');
            riskFilter.isHistorical = (Boolean) mapObj.get('isHistorical');
            riskFilter.filterStatus = (String) mapObj.get('filterStatus');
            riskFilter.riskCalification = getRiskCalification(mapObj);
            lstRiskFilter.add(riskFilter);
        }
        riskFilterWrap.data = lstRiskFilter;
        return riskFilterWrap;

    }
    /**
    *-------------------------------------------------------------------------------
    * @description Get the risk calification from service response
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    11/12/2020
    * @param   Map<String, Object> mapObj
    * @return  RiskCalification
    * @example RiskCalification ret = getRiskCalification(mapObj);
    **/
    private static RiskCalification getRiskCalification(Map<String, Object> mapObj) {
        final Map<String, Object> riskCalifMap = getMapFromJson(mapObj, 'riskCalification');
        final RiskCalification riskCalif = new RiskCalification();
        if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(riskCalifMap)) {
            riskCalif.riskCalId = (String) riskCalifMap.get('id');
            riskCalif.name = (String) riskCalifMap.get('name');
            riskCalif.actionPolicy = (String) riskCalifMap.get('actionPolicy');
        }
        return riskCalif;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Get the contracts information from service response
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    11/12/2020
    * @param   Map<String, Object> mapObj
    * @return  ContractsInformation
    * @example ContractsInformation ret = getContractInfo(mapObj);
    **/
    private static ContractsInformation getContractInfo(Map<String, Object> mapObj) {
        final Map<String, Object> contractInfoMap = getMapFromJson(mapObj, 'contractsInformation');
        final ContractsInformation contractInfo = new ContractsInformation();
        if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(contractInfoMap)) {
            contractInfo.quantity = (Integer) contractInfoMap.get('quantity');
            contractInfo.status = (String) contractInfoMap.get('status');
        }
        return contractInfo;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Get the risk filter amount from service response
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    11/12/2020
    * @param   Map<String, Object> mapObj
    * @return  RiskFilterAmount
    * @example RiskFilterAmount ret = getRiskFilterAmount(mapObj);
    **/
    private static RiskFilterAmount getRiskFilterAmount(Map<String, Object> mapObj) {
        final Map<String, Object> riskFilterMap = getMapFromJson(mapObj, 'riskFilterAmount');
        final RiskFilterAmount riskFilter = new RiskFilterAmount();
        if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(riskFilterMap)) {
            riskFilter.amount = (Decimal) riskFilterMap.get('amount');
            riskFilter.currencyRisk = (String) riskFilterMap.get('currency');
        }
        return riskFilter;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Get the bureau from service response
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    11/12/2020
    * @param   Map<String, Object> mapObj
    * @return  BureauWrap
    * @example BureauWrap ret = getBureauMap(mapObj);
    **/
    private static BureauWrap getBureauMap(Map<String, Object> mapObj) {
        final Map<String, Object> bureauMap = getMapFromJson(mapObj, 'bureau');
        final BureauWrap bureau = new BureauWrap();
        if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(bureauMap)) {
            bureau.bureauId = (String) bureauMap.get('id');
            bureau.description = (String) bureauMap.get('description');
        }
        return bureau;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Helper method that get a list from json
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    11/12/2020
    * @param   Map<String, Object> prevMap
    * @param   String keyToRetrieve
    * @return  List<Map<String, Object>>
    * @example List<Map<String, Object>> ret = getListFromJson(prevMap, keyToRetrieve);
    **/
    public static List<Map<String, Object>> getListFromJson(Map<String, Object> prevMap, String keyToRetrieve) {
        final List<Map<String, Object>> listOfMap = new List<Map<String, Object>>();
        final List<Object> objectList = (List<Object>)prevMap.get(keyToRetrieve);
        for(Object element : objectList) {
            listOfMap.add((Map<String, Object>)element);
        }
        return listOfMap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Helper method that get a map from json
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    11/12/2020
    * @param   Map<String, Object> prevMap
    * @param   String keyToRetrieve
    * @return  Map<String, Object>
    * @example Map<String, Object> ret = getMapFromJson(prevMap, keyToRetrieve);
    **/
    public static Map<String, Object> getMapFromJson(Map<String, Object> prevMap, String keyToRetrieve) {
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(prevMap.get(keyToRetrieve)));
        if (data == null) {
            data = new Map<String, Object>();
        }
        return data;
    }
}