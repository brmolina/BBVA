/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ParentSubsidiary_Controller
* @Author   sergio.villaroel.contractor@bbva.com
* @Date     Created: 21-11-2023
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Arc_Gen_ParentSubsidiary_Controller
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |21-11-2023 sergio.villaroel.contractor@bbva.com
*             Class creation.
* |02-02-2024 sergio.villaroel.contractor@bbva.com
*             Sonnar.
* |07-02-2024 antonio.perez.hernandez.contractor@bbva.com
*             Call Parent Subsidiary service before Rating Systems service
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_ParentSubsidiary_Controller {
    /**
    * @Description: '"group":' literal
    * @Author antonio.perez.hernandez.contractor@bbva.com
    */
    public static final String GROUP_SERV = '"group":';
    /**
    * @Description: '"groupVar":' literal
    * @Author antonio.perez.hernandez.contractor@bbva.com
    */
    public static final String GROUP_VAR_SERV = '"groupVar":';
    /**
    * @Description: '"id":' literal
    * @Author antonio.perez.hernandez.contractor@bbva.com
    */
    public static final String ID_SERV = '"id":';
    /**
    * @Description: '"identifier":' literal
    * @Author antonio.perez.hernandez.contractor@bbva.com
    */
    public static final String ID_VAR_SERV = '"identifier":';
    /**
    * @Description: 'incomplete' literal
    * @Author sergio.villaroel.contractor@bbva.com
    */
    static final string INCOMPLETE = 'incomplete';
    /**
    * @Description: String with value 'arce__Arc_Gen_Parent_Relationship__c'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string FLD_PARENT_REL = 'arce__Arc_Gen_Parent_Relationship__c';
    /**
    * @Description: String with value 'arce__Arc_Gen_PS_Relationship_Id__c'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string FLD_PS_REL = 'arce__Arc_Gen_PS_Relationship_Id__c';
    /**
    * @Description: String with value 'arce__Arc_Gen_ParentGroups__c'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string FLD_PARENT_GROUPS = 'arce__Arc_Gen_ParentGroups__c';
    /**
    * @Description: String with value 'arce__Arc_Gen_Validate_GCP__c'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string FLD_VALIDATE_GCP = 'arce__Arc_Gen_Validate_GCP__c';
    /**
    * @Description: String with value 'arce__Arc_Gen_GlobalId__c'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string FLD_GLOBAL_ID = 'arce__Arc_Gen_GlobalId__c';
    /**
    * @Description: String with value 'arce__Arc_Gen_Local_Id__c'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string FLD_LOCAL_ID = 'arce__Arc_Gen_Local_Id__c';
    /**
    * @Description: String with value 'arce__Arc_Gen_PS_Relationship_UserId__c'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string FLD_PS_REL_USR_ID = 'arce__Arc_Gen_PS_Relationship_UserId__c';
    /**
    * @Description: String with value 'arce__gf_prtcpt_gr_relation_type__c'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string FLD_GR_REL_TYPE = 'arce__gf_prtcpt_gr_relation_type__c';
    /**
    * @Description: String with value 'arce__Arc_Gen_PS_Relationship_Date__c'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string FLD_PS_REL_DATE = 'arce__Arc_Gen_PS_Relationship_Date__c';
    /**
    * @Description: String with value 'arce__rating_system_type__c'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string FLD_RAT_SYST_TYPE = 'arce__rating_system_type__c';
    /**
    * @Description: String with value 'responsewarningdescription'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string RES_WARNING_DESC = 'ResponseWarningDescription';
    /**
    * @Description: String with value 'qualitativeVariables'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string QUALITATIVE_VARS = 'qualitativeVariables';
    /**
    * @Description: String with value 'qualitative'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string QUALITATIVE_LIT = 'qualitative';
    /**
    * @Description: String with value 'relationPS'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string REL_PS = 'relationPS';
    /**
    * @Description: String with value 'parentSubsidiaryServIdsMapping'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string PAR_SUBS_SERV_MAP = 'parentSubsidiaryServIdsMapping';
    /**
    * @description Service name
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final String SERVICE_NAME = 'parentSubsidiaryQualitatives';
    /**
    * @Description: 'RTC_IRP_CallEngine' literal
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string IRPAUTO = 'RTC_IRP_CallEngine';
    /**
    * @Description: 'PS_URL' literal
    * @Author sergio.villaroel.contractor@bbva.com
    */
    static final String PS_URL = 'ParentSubsidiaryUrl';
    /**
    * @Description: String label Arc_Gen_ApexCallError
    * @Author adrian.caro.next@bbva.com
    */
    static final String APEX_CALL = System.Label.Arc_Gen_ApexCallError;
    /**
    /**
    * @Description: Initialize configurations.
    */
    static List<arce__Arce_Config__mdt> alphaConfigs;
    /**
    * @Description: Initialize configurations.
    */
    static List<arce__Arce_Config__mdt> rtcAutoConfigs;
    /**
    * @Description: Encrypt configurations.
    */
    static {
        alphaConfigs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(Arc_Gen_ArceCore_Constants.ALPHAMETA);
    }
    /**
    * @Description: Encrypt configurations.
    */
    static {
        rtcAutoConfigs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(IRPAUTO);
    }
    /**
    * Constructor
    **/
    @TestVisible
    private Arc_Gen_ParentSubsidiary_Controller() {}
    /**
    * @Class: MessageResponse
    * @Description: Container that contains the message for the Lightning component as a response
    * @Author   sergio.villaroel.contractor@bbva.com
    */
    public class MessageResponse {
        /**
        * @Description: Indicates status
        */
        @AuraEnabled public String status {get;set;}
        /**
        * @Description: Indicates message
        */
        @AuraEnabled public String message {get;set;}
        /**
        * @description MessageResponse constructor
        * @author sergio.villaroel.contractor@bbva.com | 21-11-2023
        **/
        public MessageResponse() {
            status = arce.Arc_Gen_Overlays_Utils.VALUE_SUCCESS;
            message = arce.Arc_Gen_Constants.OK_S;
        }
    }
    /**
    * @Class: UserInfo
    * @Description: Container that contains the message for the Lightning component as a response
    * @Author   sergio.villaroel.contractor@bbva.com
    */
    public class UserInfo {
        /**
        * @Description: Indicates status
        */
        @AuraEnabled public String userName {get;set;}
        /**
        * @Description: Indicates message
        */
        @AuraEnabled public Datetime dateCreate {get;set;}
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to call service Parent Subsidiary
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    String ahaId Id of aha
    * @param    Boolean isMock - true for testing
    * @param    String serviceName
    * @return   MessageResponse
    * @example  Arc_Gen_ParentSubsidiary_Controller.callParentSubsidiary(ahaId, false, null)
    * */
    @AuraEnabled
    public static MessageResponse callParentSubsidiary(String ahaId, Boolean isMock, String serviceName) {
        MessageResponse msgResp = new MessageResponse();
        String localServiceName = serviceName;
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId})[0];
        final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(accHasAnalysis);
        final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> { clientId }).get(clientId);
        final String customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(accWrapper.accNumber);
        final Map<String,String> params = new Map<String,String>{ Arc_Gen_ArceCore_Constants.PARTICIPANT_ID => Arc_Gen_ParentSubsidiary_Service.alphaCode(customerNumber)};
        final Map<Id, List<arce__Overlay__c>> overlayMap = arce.Arc_Gen_Overlays_Utils.getOverlayMapByAha(new Set<Id>{ahaId});
        final arce__Overlay__c newOverlay = arce.Arc_Gen_Overlays_Utils.crteOvrlyCorp(accHasAnalysis.Id, overlayMap.get(ahaId));
        newOverlay.put(FLD_PARENT_REL, arce.Arc_Gen_Constants.ONE_S);
        localServiceName = String.isBlank(localServiceName) ? SERVICE_NAME : localServiceName;
        final arce.Arc_Gen_getIASOResponse.ServiceResponse sResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(localServiceName, JSON.serialize(params));
        if (sResponse.serviceCode == Arc_Gen_ArceCore_Constants.TWO_HUNDRED) {
            Arc_Gen_ParentSubsidiary_Service.processResponse(sResponse, newOverlay, isMock);
        }
        final arce.Arc_Gen_GenericUtilities.SaveResult saveRes = arce.Arc_Gen_GenericUtilities.upsertRecords(new List<SObject>{newOverlay});
        final arce__AHA_Extension__c ahaExt = (arce__AHA_Extension__c) arce.Arc_Gen_ParentSubsidiary_utils.getSObjectInfo(Arc_Gen_ArceCore_Constants.EXTENSION, accHasAnalysis.arce__AHA_Extension__c, null);
        if (sResponse.serviceCode == Arc_Gen_ArceCore_Constants.TWO_HUNDRED && saveRes.status == Arc_Gen_ArceCore_Constants.TRUE_LIT) {
            if (newOverlay.arce__gf_prtcpt_gr_relation_type__c == null) {
                msgResp = Arc_Gen_ParentSubsidiary_Service.createMsgResp(INCOMPLETE, '');
                accHasAnalysis.Arc_Gen_Ent_CalculateOverlay_Enabled__c = arce.Arc_Gen_Constants.ONE_S;
            } else {
                Arc_Gen_ParentSubsidiary_Service.updExt(ahaExt, true, true, Arc_Gen_ArceCore_Constants.ZERO);
                accHasAnalysis.Arc_Gen_Ent_CalculateOverlay_Enabled__c = arce.Arc_Gen_Constants.ONE_S;
            }
        } else if (sResponse.serviceCode == Arc_Gen_ArceCore_Constants.TWO_HUNDRED_FOUR) {
            String respWarDesc204;
            respWarDesc204 = sResponse.serviceHeaders.get(RES_WARNING_DESC);
            accHasAnalysis.Arc_Gen_Ent_CalculateOverlay_Enabled__c = arce.Arc_Gen_Constants.TWO_S;
            if (respWarDesc204 == System.Label.Arc_Gen_RTC_ClientNotExist) {
                accHasAnalysis.Arc_Gen_Ent_CalculateOverlay_Enabled__c = arce.Arc_Gen_Constants.ONE_S;
                msgResp = Arc_Gen_ParentSubsidiary_Service.createMsgResp(Arc_Gen_ArceCore_Constants.TWO_HUNDRED_FOUR, '');
                Arc_Gen_ParentSubsidiary_Service.updExt(ahaExt, true, true, arce.Arc_Gen_Constants.ONE_S);
            } else if (respWarDesc204 == System.Label.Arc_Gen_RTC_ClientExistNotCalculated) {
                msgResp = Arc_Gen_ParentSubsidiary_Service.createMsgResp(Arc_Gen_ArceCore_Constants.TWO_HUNDRED_FOURB, '');
                Arc_Gen_ParentSubsidiary_Service.updExt(ahaExt, false, false, Arc_Gen_ArceCore_Constants.TWO);
            } else {
                msgResp = Arc_Gen_ParentSubsidiary_Service.createMsgResp('', respWarDesc204);
                Arc_Gen_ParentSubsidiary_Service.updExt(ahaExt, false, false, Arc_Gen_ArceCore_Constants.TWO);
            }
        } else {
            msgResp = Arc_Gen_ParentSubsidiary_Service.createMsgResp(Arc_Gen_ArceCore_Constants.FOUR_HUNDRED, '');
            Arc_Gen_ParentSubsidiary_Service.updExt(ahaExt, false, false, Arc_Gen_ArceCore_Constants.ZERO);
            accHasAnalysis.Arc_Gen_Ent_CalculateOverlay_Enabled__c = arce.Arc_Gen_Constants.TWO_S;
        }
        Arc_Gen_ParentSubsidiary_Service.updatObj(ahaExt, accHasAnalysis);
        return msgResp;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to check arce__PS_Successfully_Retrieved__c field
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    String ahaId Id of aha
    * @return   Boolean
    * @example  Arc_Gen_ParentSubsidiary_Controller.getUserData(ahaId)
    * */
    @AuraEnabled
    public static UserInfo getUserData(String ahaId) {
        final UserInfo userinf = new UserInfo();
        try {
            final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId})[0];
            final arce__Overlay__c ahaOverlay = (arce__Overlay__c) arce.Arc_Gen_ParentSubsidiary_utils.getSObjectInfoOverlay(Arc_Gen_ArceCore_Constants.OVERLAY, aha.Id, null);
            final List<User> us = arce.Arc_Gen_ParentSubsidiary_utils.getBasicInfoUser(ahaOverlay.arce__Arc_Gen_PS_Relationship_UserId__c);
            if (us == null) {
                userinf.userName = Arc_Gen_ArceCore_Constants.NOTFOUND;
                userinf.dateCreate = ahaOverlay.arce__Arc_Gen_PS_Relationship_Date__c;
            } else {
                userinf.userName = us[0].Name;
                userinf.dateCreate = ahaOverlay.arce__Arc_Gen_PS_Relationship_Date__c;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e + Arc_Gen_ArceCore_Constants.SPACE_PIPE_SPACE + APEX_CALL + Arc_Gen_ArceCore_Constants.COLON_SPACE + e.getMessage());
        }
        return userinf;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method that return the string Rating System value
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    String ahaId Id of aha
    * @return   String
    * @example  Arc_Gen_ParentSubsidiary_Controller.ratingSystemType(ahaId)
    * */
    @AuraEnabled
    public static List<String> ratingSystemType(String ahaId, Boolean isMock) {
        final List<String> valueRetr = new List<String>();
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId})[0];
        final Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        final Schema.SObjectType sObjectType = globalDescribe.get(Arc_Gen_ArceCore_Constants.ANALISIS);
        final Schema.DescribeSObjectResult sObjectDescribe = sObjectType.getDescribe();
        final Schema.DescribeFieldResult fieldDescribe = sObjectDescribe.fields.getMap().get(FLD_RAT_SYST_TYPE).getDescribe();
        for (Schema.PicklistEntry ple : fieldDescribe.getPicklistValues()) {
            if (ple.getValue().equals(accHasAnalysis.arce__Analysis__r.arce__rating_system_type__c)) {
                valueRetr.add(ple.getLabel());
            }
        }
        if (Boolean.valueOf(rtcAutoConfigs[0].arce__Value1__c)) {
            final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(accHasAnalysis);
            final String valu = Arc_Gen_CallRatingSystems.callRatingSystems(clientId, isMock);
            final Integer inicio = valu.indexOf('RS') + 2;
            final Integer fin = valu.indexOf('-');
            String valorDeseado;
            if (inicio > 1 && fin > inicio) {
                valorDeseado = valu.substring(inicio, fin);
            }
            for (Schema.PicklistEntry ple : fieldDescribe.getPicklistValues()) {
                if (ple.getValue().equals(valorDeseado)) {
                    valueRetr.add(ple.getLabel());
                }
            }
        }
        return valueRetr;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to update arce__Overlay__c object
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    String ahaId Id of aha
    * @param    overlayObj object arce__Overlay__c
    * @example  Arc_Gen_ParentSubsidiary_Controller.updateOverlayObj(ahaId, overlayObj)
    * */
    @AuraEnabled
    public static void updateOverlayObj(String ahaId, arce__Overlay__c overlayObj) {
        try {
            if(!String.isBlank(overlayObj.arce__Arc_Gen_LocalId_VC__c)) {
                final Set<String> cclientsSet = new Set<String>();
                final List<dyfr__Dependent_value__c> localIdList = (List<dyfr__Dependent_value__c>) JSON.deserialize(overlayObj.arce__Arc_Gen_LocalId_VC__c, List<dyfr__Dependent_value__c>.class);
                for(dyfr__Dependent_value__c dependent : localIdList) {
                    cclientsSet.addAll(dependent.dyfr__LoV_values__c.split(Arc_Gen_ArceCore_Constants.COMMA));
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e + Arc_Gen_ArceCore_Constants.SPACE_PIPE_SPACE + APEX_CALL + Arc_Gen_ArceCore_Constants.COLON_SPACE + e.getMessage());
        }
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method that return pick list values
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @return   List<String>
    * @example  Arc_Gen_ParentSubsidiary_Controller.getPicklistValues()
    * */
    @AuraEnabled(cacheable=true)
    public static List<String> picklistLabels() {
        final List<String> values = new List<String>();
        final Schema.DescribeFieldResult fieldResult = arce__Analysis__c.arce__rating_system_type__c.getDescribe();
        final List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry entry : picklistEntries) {
            values.add(entry.getLabel());
        }
        return values;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method that save new Rating System state
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    String systemName
    * @param    String ahaId
    * @return   List<String>
    * @example  Arc_Gen_ParentSubsidiary_Controller.saveSystem(systemName, ahaId)
    * */
    @AuraEnabled
    public static Boolean saveSystem(String systemName, String ahaId) {
        Boolean valueRetr;
        final List<Id> arceId = new List<Id>();
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId})[0];
        arceId.add(accHasAnalysis.arce__Analysis__c);
        final List<arce__Analysis__c> anaList =  arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisDataToModification(arceId);
        if (anaList.isEmpty()) {
            valueRetr = false;
        } else {
            String valueAPI;
            final Schema.DescribeFieldResult field = arce__Analysis__c.arce__rating_system_type__c.getDescribe();
            for (Schema.PicklistEntry entry : field.getPicklistValues()) {
                if (entry.getLabel() == systemName) {
                    valueAPI = entry.getValue();
                }
            }
            final arce__AHA_Extension__c ahaExt = (arce__AHA_Extension__c) arce.Arc_Gen_ParentSubsidiary_utils.getSObjectInfo(Arc_Gen_ArceCore_Constants.EXTENSION, accHasAnalysis.arce__AHA_Extension__c, null);
            if (anaList[0].arce__rating_system_type__c == valueAPI) {
                ahaExt.arce__ratingSystemValid__c = true;
            } else {
                anaList[0].arce__rating_system_type__c = valueAPI;
                ahaExt.arce__ratingSystemValid__c = false;
            }
            arce.Arc_Gen_AccHasAnalysis_Data.updateObjects (new List<arce__AHA_Extension__c> {ahaExt});
            valueRetr = true;
        }
        return valueRetr;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method that save new Rating System state
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    String systemName
    * @param    String ahaId
    * @return   List<String>
    * @example  Arc_Gen_ParentSubsidiary_Controller.extensionData(ahaId)
    * */
    @AuraEnabled
    public static arce__AHA_Extension__c extensionData(String ahaId) {
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId})[0];
        return (arce__AHA_Extension__c) arce.Arc_Gen_ParentSubsidiary_utils.getSObjectInfo(Arc_Gen_ArceCore_Constants.EXTENSION, accHasAnalysis.arce__AHA_Extension__c, null);
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method that save new Rating System state
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    String systemName
    * @param    String ahaId
    * @return   List<String>
    * @example  Arc_Gen_ParentSubsidiary_Controller.rtcAutoMeta(ahaId)
    * */
    @AuraEnabled
    public static Boolean rtcAutoMeta() {
        return Boolean.valueOf(rtcAutoConfigs[0].arce__Value1__c);
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method that save new Rating System state
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @return   List<String>
    * @example  Arc_Gen_ParentSubsidiary_Controller.rtcAutoMeta(ahaId)
    * */
    @AuraEnabled
    public static String urlsConfig () {
        return (String) Arc_Gen_ArceUrlsConfigs_locator.getConfigurationInfo(PS_URL).url__c;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method that check button permissions
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     30-05-2024
    * @return   List<String>
    * @example  Arc_Gen_ParentSubsidiary_Controller.checkPermission(ahaId)
    * */
    @AuraEnabled
    public static Boolean checkPermission(String ahaId) {
        Boolean finalValue;
        final String checkPermission = Arc_Gen_TabSet_service.getPermissionToEdit(ahaId);
        if (checkPermission == Arc_Gen_ArceCore_Constants.TRUE_LIT) {
            finalValue = true;
        } else {
            finalValue = false;
        }
        return finalValue;
    }
}