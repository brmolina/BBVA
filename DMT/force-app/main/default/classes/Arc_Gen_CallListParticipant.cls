/**
* @File Name          : Arc_Gen_CallListParticipant.cls
* @Description        : Contain logic to process participants ASO WS (getEconomiclistpart)
* @Author             : Luis Arturo Parra Rosas / luisarturo.parra.contractor@bbva.com
* @Group              : ARCE Team
* @Data Class         : Arc_Gen_Groups_data
* @Main ctr Class     : Arc_Gen_Groups_Service
* @Test Class         : Arc_Gen_Groups_controller_test
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 24/06/2020
* @Modification Log   :
*==========================================================================================
* Ver         Date                     Author                            Modification
*==========================================================================================
* 1.0         30/08/2019                luisarturo.parra.contractor@bbva.com     Initial Version
* 1.1         26/02/2020                javier.soto.carrascosa@bbva.com     	 Add support to filter groups in listparticipants
* 1.2         27/02/2020                juanignacio.hita.contractor@bbva.com     Add pagination  service
* 1.3         18/06/2020                joseluis.garcia4.contractor@bbva.com     Add isOrphan in the call to the listParticipant service.
* 1.4         07/07/2020                juanignacio.hita.contractor@bbva.com     Add isHolding Participantobj wrapper of listParticipant service.
* 1.5         25/08/2020                mariohumberto.ramirez.contractor@bbva.com Add getLegalName method and modify processDataListParticipants method
* 1.6         11/09/2020                mariohumberto.ramirez.contractor@bbva.com Fix error when isHolding or isConsolidated are 'true'
* 1.7         14/09/2020                mariohumberto.ramirez.contractor@bbva.com Fix default value for 'vision'
* 1.8         16/09/2020                juanignacio.hita.contractor@bbva.com     First call to the service "listParticipant", the attribute is removed.
* 1.9         23/09/2020                saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are
*                                                                                now in the arce-dependencies package
* 1.10        21/05/2021                otiliaramona.veres.contracto@bbva.com
*                                                                                Deleted some unused local variables.
****************************************************************************************************************/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyMethods, sf:TooManyFields')
public without sharing class Arc_Gen_CallListParticipant {
    /**
    * @Description : Static variable used in the first call service (callWithPagination method)
    */
    private final static Integer FIRSTCALL = 1;
    /**
    * @Description : Wrapper participant object
    */
    public class Participantobj {
        /**
        * @Description : id of the participant
        */
        public String participantId {get; set;}
        /**
        * @Description : name of the participant
        */
        public String  participname{get; set;}
        /**
        * @Description : level of the participant
        */
        public String  pRelLevel {get; set;}
        /**
        * @Description : holding type of the participant
        */
        public Boolean isHolding {get; set;}
        /**
        * @Description : Relation type of the participant
        */
        public String  pRelRelationTypeId {get; set;}
        /**
        * @Description : group id of the participant
        */
        public String  parentEconomicGroupId {get; set;}
        /**
        * @Description : legal name of the participant
        */
        public String legalName {get; set;}
        /**
        * @Description : start date of the relation of the participant
        */
        public String relationStartDate {get; set;}
        /**
        * @Description : participant id of the participant
        */
        public String participantTypeId {get; set;}
        /**
        * @Description : vision of the participant
        */
        public String vision {get; set;}
        /**
        * @Description : direct percentage of the participant
        */
        public Double directPercentage {get; set;}
        /**
        * @Description : indirect percentage of the participant
        */
        public Double indirectPercentage {get; set;}
        /**
        * @Description : computable risk of the participant
        */
        public Double computableRisk {get; set;}
        /**
        * @Description : total percentage of the participant
        */
        public Double totalPercentage {get; set;}
        /**
        * @Description : consolidation of the participant
        */
        public Boolean isConsolidated {get; set;}
        /**
        * @Description : document type id of the participant
        */
        public String documentTypeId {get; set;}
        /**
        * @Description : document type name of the participant
        */
        public String documentTypeName {get; set;}
        /**
        * @Description : document number of the participant
        */
        public String documentNumber {get; set;}
        /**
        * @Description : relation type name of the participant
        */
        public String relationTypeName {get; set;}
        /**
        * @Description : relation type id of the participant
        */
        public String relationTypeId {get; set;}
    }
    /**
    * @Description : Wrapper used in the error managed
    */
    public class Innertoreturnlistp{
        public String error204message {get; set;}
        public String errormessage {get; set;}
        public String servicecallerror {get; set;}
        public List<Participantobj> customersdata {get; set;}

        /**
        * @Description : Constructor of the wrapper Innertoreturnlistp
        */
        void constructor() {
            error204message = '';
            errormessage = '';
            servicecallerror = '';
            customersdata = new List<Participantobj>();
        }
    }
    /**
    * @Description : Wrapper of links
    */
    public class WrapperLinks {
        /**
        * @Description: Links
        */
        public LinkUnit links {get;set;}
    }
    /**
    * @Description : Wrapper of links  (first and next of the key service)
    */
    public class LinkUnit {
        /**
        * @Description : First link
        */
        public String first {get;set;}
        /**
        * @Description : Next link
        */
        public String next {get;set;}
    }
    /**
    * @Description : return data init
    */
    private Innertoreturnlistp returndata = new Innertoreturnlistp();
    /**
    *-------------------------------------------------------------------------------
    * @description get return data structure
    *--------------------------------------------------------------------------------
    * @date     13/04/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @return   Arc_Gen_CallListParticipant.Innertoreturnlistp
    * @example  Arc_Gen_CallListParticipant.Innertoreturnlistp returnData = getReturnData();
    */
    public Innertoreturnlistp getReturnData() {
        return this.returnData;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description set return data structure
    *--------------------------------------------------------------------------------
    * @date     13/04/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    Innertoreturnlistp returnData
    * @return   void
    * @example  settReturnData(returnData);
    */
    public void setReturnData(Innertoreturnlistp returnData) {
        this.returnData = returnData;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_CallListParticipant.Innertoreturnlistp
    * @example  Arc_Gen_CallListParticipant.Innertoreturnlistp return =  Arc_Gen_CallListParticipant.callListParticipants(encryptedGroup);
    */
    public static Arc_Gen_CallListParticipant.Innertoreturnlistp callListParticipants(String encryptedGroup, Boolean isOrphan) {
        final Arc_Gen_CallListParticipant callClass = new Arc_Gen_CallListParticipant();
        return callClass.callService(encryptedGroup, isOrphan);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_CallListParticipant.Innertoreturnlistp
    * @example  Arc_Gen_CallListParticipant.Innertoreturnlistp return = callClass.callService(encryptedGroup);
    */
    private Arc_Gen_CallListParticipant.Innertoreturnlistp callService(String encryptedGroup, Boolean isOrphan) {
        Integer maxCalls = Integer.valueOf(verifyPaginationService());
        List<arce.Arc_Gen_getIASOResponse.serviceResponse> lstResponses = new List<arce.Arc_Gen_getIASOResponse.serviceResponse>();
        Arc_Gen_CallListParticipant.Innertoreturnlistp returnData = getReturnData();
        returndata.constructor();

        if (Test.isRunningTest()) {
            maxCalls = 1;
        }

        try {
            if (!isOrphan) {
                // Call list participants only if account is not orphan.
                lstResponses = callWithPagination(encryptedGroup, maxCalls);
                if (!lstResponses.isEmpty()) {
                    for (arce.Arc_Gen_getIASOResponse.serviceResponse response : lstResponses) {
                        final List<Participantobj> participantObj = processDataListParticipants(response.serviceResponse);
                        returndata.customersdata.addAll(participantObj);
                    }
                    setReturnData(returnData);
                }
                if (returndata.errormessage != '') {
                    throw new AuraHandledException(returndata.errormessage);//NOSONAR
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());//NOSONAR
        }
        return returndata;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description call to list participant service with pagination and return an array of response
    *--------------------------------------------------------------------------------
    * @date     10/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    encryptedGroup
    * @param    maxCalls
    * @return   List<arce.Arc_Gen_getIASOResponse.serviceResponse>
    * @example  callWithPagination(encryptedGroup, maxCalls);
    */
    public List<arce.Arc_Gen_getIASOResponse.serviceResponse> callWithPagination(String encryptedGroup, Integer maxCalls) {
        List<arce.Arc_Gen_getIASOResponse.serviceResponse> lstResponses = new List<arce.Arc_Gen_getIASOResponse.serviceResponse>();
        final arce.Arc_Gen_CustomServiceMessages serviceMessages = new arce.Arc_Gen_CustomServiceMessages();
        String linkNext = '';
        Integer currentCalls = 1;
        Boolean errorService = false;
        Arc_Gen_CallListParticipant.Innertoreturnlistp returnData = getReturnData();

        do {
            String paramsReq = '{"groupId":"' + encryptedGroup + '", "paginationKey":"' + linkNext + '"}';
            if (currentCalls == FIRSTCALL) {
                paramsReq = '{"groupId":"' + encryptedGroup + '", "paginationKey":"1"}';
            }
            final arce.Arc_Gen_getIASOResponse.serviceResponse sResponse = callListParticipant(paramsReq);
            if (sResponse.serviceCode == String.valueOf(serviceMessages.CODE_200)) {
                lstResponses.add(sResponse);
                linkNext = getNextLinkParticipants(sResponse.serviceResponse);
                currentCalls++;
            } else if (sResponse.serviceCode == String.valueOf(serviceMessages.CODE_204) && sResponse.serviceMessage == serviceMessages.SUCCESSFUL_204) {
                returndata.error204message = System.Label.Lc_arce_GRP_noExstGrp;
                lstResponses = new List<arce.Arc_Gen_getIASOResponse.serviceResponse>();
                errorService = true;
                setReturnData(returnData);
            } else {
                returndata.errormessage= System.Label.Cls_arce_GRP_servError + ': ' + sResponse.serviceCode + ' / ' + sResponse.serviceMessage;
                lstResponses = new List<arce.Arc_Gen_getIASOResponse.serviceResponse>();
                errorService = true;
                setReturnData(returnData);
            }
        } while (currentCalls <= maxCalls && linkNext != '' && !errorService);
        return lstResponses;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description return true if the pagination service configuration is active
    *--------------------------------------------------------------------------------
    * @date     10/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    nameConfig - configuration name of the metadata
    * @return   Boolean
    * @example  verifyPaginationService('PagintationParticipants');
    */
    public static Integer verifyPaginationService() {
        Integer valueMax = 1;
        final List<arce__Arce_Config__mdt> lstArceConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('PaginationParticipants');
        if (!lstArceConfig.isEmpty()) {
            valueMax = Integer.valueOf(lstArceConfig[0].arce__Value1__c);
            valueMax = valueMax < 0 ? 1 : valueMax;
        }
        return valueMax;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Process the response, to get the following next link to service call
    *--------------------------------------------------------------------------------
    * @date     10/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    serviceResponse - Map<String, Object>
    * @return   String
    * @example  getNextLinkParticipants(serviceResponse);
    */
    public static String getNextLinkParticipants(Map<String, Object> serviceResponse) {
        String nextLink = '';
        final Map<String, Object> mapPagination = getMapFromJson(serviceResponse, 'pagination');
        Map<String, String> mapParams = new Map<String, String>();
        if (mapPagination != null && mapPagination.size() > 0) {
            final String strPagination = JSON.serialize(serviceResponse.get('pagination'));
            final WrapperLinks wrpLink = (WrapperLinks) System.JSON.deserialize(strPagination, WrapperLinks.class);

            if (wrpLink.links.next != null) {
                final String subUrl = wrpLink.links.next.subString(wrpLink.links.next.indexOf('?') + 1);
                final List<String> subUrlAmp = subUrl.split('&');
                for (String strUrl : subUrlAmp) {
                    final List<String> paramsUrl = strUrl.split('=');
                    mapParams.put(paramsUrl[0], paramsUrl[1]);
                }
                nextLink = mapParams.get('paginationKey');
            }
        }
        return nextLink;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  private static List<Participantobj> processDataListParticipants(Map<String, Object> serviceResponse) {
    */
    private static List<Participantobj> processDataListParticipants(Map<String, Object> serviceResponse) {
        List<Participantobj> participantreturlist = new List<Participantobj>();
        for(Map<String, Object> participant : getListFromJson(serviceResponse, 'data')) {
            Participantobj participants = new Participantobj();
            participants.participantId = (String) participant.get('id');
            final Map<String, Object> participantName = getMapFromJson(participant, 'participantName');
            participants.legalName = (String) participantName.get('legalName') == null ? getLegalName(participantName) : (String) participantName.get('legalName');
            participants.isHolding = Boolean.valueOf(getValuesFromMap(participant, 'isHolding', 'false'));
            Map<String, Object> participantRelation = getMapFromJson(participant, 'relation');
            participants.pRelLevel = (String) participantRelation.get('level');
            final Map<String, Object> pRelRelationType = getMapFromJson(participant, 'participantType');
            participants.pRelRelationTypeId = (String) pRelRelationType.get('id');
            final Map<String, Object> pRelationType = getMapFromJson(participantRelation, 'relationType');
            participants.relationTypeId = (String) pRelationType.get('id');
            participants.relationTypeName = getValuesFromMap(pRelationType, 'name', 'Business');
            participants.relationStartDate = getValuesFromMap(participantRelation, 'startDate', '0001-01-01');
            Map<String, Object> pRelParentEconomicGroup = getMapFromJson(participantRelation, 'parentEconomicGroup');
            String pRelParentEconomicGroupId = (String)pRelParentEconomicGroup.get('id');
            participants.parentEconomicGroupId = pRelParentEconomicGroupId;

            final Map<String, Object> identityDocMap = getMapFromJson(participant, 'identityDocument');
            participants.documentNumber = (String)identityDocMap.get('documentNumber');
            final Map<String, Object> documentTypeMap = getMapFromJson(identityDocMap, 'documentType');
            participants.documentTypeId = (String)documentTypeMap.get('id');
            participants.documentTypeName = (String)documentTypeMap.get('name');

            final Map<String, Object> participantType = getMapFromJson(participant, 'participantType');
            participants.participantTypeId = getValuesFromMap(participantType, 'id', 'SUBSIDIARY');
            participants.vision = getValuesFromMap(participant, 'vision', 'RISKS');

            final Map<String, Object> participation = getMapFromJson(participant, 'participation');
            participants.directPercentage = Double.valueOf(getValuesFromMap(participation, 'directPercentage', '0.0'));
            participants.indirectPercentage = Double.valueOf(getValuesFromMap(participation, 'indirectPercentage', '0.0'));
            participants.computableRisk = Double.valueOf(getValuesFromMap(participation, 'computableRisk', '0.0'));
            participants.totalPercentage = Double.valueOf(getValuesFromMap(participation, 'totalPercentage', '0.0'));
            participants.isConsolidated = Boolean.valueOf(getValuesFromMap(participant, 'isConsolidated', 'false'));
            if(! String.isEmpty(pRelParentEconomicGroupId)) {// do not recover group from list participants
                participantreturlist.add(participants);
            }
        }
        return participantreturlist;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  private static List<Map<String, Object>> getListFromJson(Map<String, Object> prevMap, String keyToRetrieve) {
    */
    private static List<Map<String, Object>> getListFromJson(Map<String, Object> prevMap, String keyToRetrieve) {
        List<Map<String, Object>> listOfMap = new List<Map<String, Object>>();
        List<Object> objectList = (List<Object>)prevMap.get(keyToRetrieve);
        for(Object element : objectList) {
            listOfMap.add((Map<String, Object>)element);
        }
        return listOfMap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  private static Map<String, Object> getMapFromJson(Map<String, Object> prevMap, String keyToRetrieve) {
    */
    private static Map<String, Object> getMapFromJson(Map<String, Object> prevMap, String keyToRetrieve) {
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(prevMap.get(keyToRetrieve)));
        if (data == null) {
            data = new Map<String, Object>();
        }
        return data;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  public static arce.Arc_Gen_getIASOResponse.serviceResponse callListParticipant(String params) {
    */
    private static arce.Arc_Gen_getIASOResponse.serviceResponse callListParticipant(String params) {
        return arce.Arc_Gen_getIASOResponse.calloutIASO('listParticipants', params);
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Return the full name of the customer
    *-------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     24/04/2020
    * @param    participantName - map object with the name of the customer
    * @return   full name of the customer
    * @example  getLegalName(participantName)
    *-------------------------------------------------------------------------------
    */
    private static String getLegalName(Map<String, Object> participantName) {
        return (String)participantName.get('firstName') + ' ' + (String)participantName.get('middleName') + ' ' + (String)participantName.get('lastName') + ' ' + (String)participantName.get('secondLastName');
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Return the value of a map
    *-------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     25/08/2020
    * @param    participantData - map object
    * @param    keyValue - key of the map
    * @param    defaultValue - default value to return if the key does'n exist
    * @return   A string
    * @example  getValuesFromMap(participantData, keyValue, defaultValue)
    *-------------------------------------------------------------------------------
    */
    private static String getValuesFromMap(Map<String, Object> participantData, String keyValue, String defaultValue ) {
        return participantData.get(keyValue) == null ? defaultValue :  String.valueOf(participantData.get(keyValue));
    }
}