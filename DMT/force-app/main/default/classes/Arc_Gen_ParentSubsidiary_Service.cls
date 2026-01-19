/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ParentSubsidiary_Controller
* @Author   sergio.villaroel.contractor@bbva.com
* @Date     Created: 21-11-2023
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Arc_Gen_ParentSubsidiary_Service
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
public without sharing class Arc_Gen_ParentSubsidiary_Service {
    /**
    * @Description: 'AlphaCodeInterface' literal
    * @Author antonio.perez.hernandez.contractor@bbva.com
    */
    private static final String ALPHA_CODE_INTERF = 'AlphaCodeInterface';
    /**
    * @Description: 'incomplete' literal
    * @Author sergio.villaroel.contractor@bbva.com
    */
    static final string INCOMPLETE = 'incomplete';
    /**
    * @Description: 'incomplete' literal
    * @Author sergio.villaroel.contractor@bbva.com
    */
    static final string CLIENTNOTEXIST = 'clientNotExist';
    /**
    * @Description: 'incomplete' literal
    * @Author sergio.villaroel.contractor@bbva.com
    */
    static final string CLIENTNOTRELATION = 'clientNotRelations';
    /**
    * @Description: String with value 'qualitative'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string QUALITATIVE_LIT = 'qualitative';
    /**
    * @Description: String with value 'parentSubsidiaryServIdsMapping'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string PAR_SUBS_SERV_MAP = 'parentSubsidiaryServIdsMapping';
    /**
    * @Description: '"identifier":' literal
    * @Author antonio.perez.hernandez.contractor@bbva.com
    */
    public static final String ID_VAR_SERV = '"identifier":';
    /**
    * @Description: '"id":' literal
    * @Author antonio.perez.hernandez.contractor@bbva.com
    */
    public static final String ID_SERV = '"id":';
    /**
    * @description Service name
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final String SERVICE_NAME = 'parentSubsidiaryQualitatives';
    /**
    * @Description: String with value 'qualitativeVariables'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string QUALITATIVE_VARS = 'qualitativeVariables';
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
    * @Description: String with value 'relationPS'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string REL_PS = 'relationPS';
    /**
    * @Description: String with value 'arce__Arc_Gen_Parent_Relationship__c'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string FLD_PARENT_REL = 'arce__Arc_Gen_Parent_Relationship__c';
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
    * @Description: String with value 'RTC_GROUPS'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string RTC_GROUPS = 'RTCgroup';
    /**
    * @Description: String with value 'RTC_IRP_UserMex'
    * @Author sergio.villaroel.contractor@bbva.com
    */
    public static final string RTC_USERMEX = 'RTC_IRP_UserMex';
    /**
    * Constructor
    **/
    @TestVisible
    private Arc_Gen_ParentSubsidiary_Service() {}
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to get the local class name from arce config value
    * -----------------------------------------------------------------------------------------------------
    * @Author   antonio.perez.hernandez.contractor@bbva.com
    * @Date     13-02-2024
    * @example  Arc_Gen_ParentSubsidiary_Controller.localClassAlpha()
    * */
    public static String localClassAlpha() {
        String finRes = Arc_Gen_ArceCore_Constants.EMPTY_STR;
        final List<arce__Arce_Config__mdt> lstConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(ALPHA_CODE_INTERF);
        if(!lstConfig.isEmpty()) {
            finRes = lstConfig.get(0).arce__Value1__c;
        }
        return finRes;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to update extension
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    String customerNumber
    * @example  Arc_Gen_ParentSubsidiary_Controller.alphaCode(customerNumber)
    * */
    public static String alphaCode(String customerNumber) {
        String result = customerNumber;
        final String classLocator = localClassAlpha();
        final System.Type objType = Type.forName(classLocator);
        try {
            final Arc_Gen_AlphaCode_Interface localClass = (Arc_Gen_AlphaCode_Interface)objType.newInstance();
            result = localClass.retrieveAlphaCode(customerNumber);
        } catch(Exception ex) {
            System.debug(ex.getMessage());
        }
        return result;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to update extension
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    String ext Id of ahaExt
    * @param    Boolean suscce
    * @param    Boolean ratingSys
    * @param    String client
    * @example  Arc_Gen_ParentSubsidiary_Controller.updExt(ext, suscce, ratingSys, client)
    * */
    public static void updExt (arce__AHA_Extension__c ext, Boolean suscce, Boolean ratingSys, String clientExist) {
        ext.arce__PS_Successfully_Retrieved__c = suscce;
        ext.arce__ratingSystemValid__c = ratingSys;
        ext.arce__Arc_Gen_ClientExst__c = clientExist;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to update object
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    String ahaExt Id of ahaExt
    * @param    String accHasAnalysis Id of aha
    * @example  Arc_Gen_ParentSubsidiary_Controller.updatObj(ahaExt, accHasAnalysis)
    * */
    public static void updatObj(arce__AHA_Extension__c ahaExt , arce__Account_has_Analysis__c accHasAnalysis) {
        arce.Arc_Gen_AccHasAnalysis_Data.updateObjects (new List<arce__AHA_Extension__c> {ahaExt});
        arce.Arc_Gen_AccHasAnalysis_Data.updateObjects (new List<arce__Account_has_Analysis__c> {accHasAnalysis});
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to update object
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    statusCode ahaExt Id of ahaExt
    * @example  Arc_Gen_ParentSubsidiary_Controller.createMsgResp(statusCode)
    * */
    public static Arc_Gen_ParentSubsidiary_Controller.MessageResponse createMsgResp (String statusCode, String messa) {
        final Arc_Gen_ParentSubsidiary_Controller.MessageResponse saveRes = new Arc_Gen_ParentSubsidiary_Controller.MessageResponse();
        if (statusCode == INCOMPLETE) {
            saveRes.status = INCOMPLETE;
            saveRes.message = System.Label.Arc_Gen_PS_Incomplete;
        } else if (statusCode == Arc_Gen_ArceCore_Constants.TWO_HUNDRED_FOUR) {
            saveRes.status = CLIENTNOTEXIST;
            saveRes.message = System.Label.Arc_Gen_PS_RelNoExist;
        } else if (statusCode == Arc_Gen_ArceCore_Constants.TWO_HUNDRED_FOURB) {
            saveRes.status = CLIENTNOTRELATION;
            saveRes.message = System.Label.Arc_Gen_PS_ExistNoCalc;
        } else {
            saveRes.status = Arc_Gen_ArceCore_Constants.ERROR;
            saveRes.message = messa;
        }
        return saveRes;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to process service Parent Subsidiary response
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     21-11-2023
    * @param    arce.Arc_Gen_getIASOResponse.ServiceResponse sResponse
    * @param    arce__Overlay__c overlayObj
    * @param    arce.Arc_Gen_Account_Wrapper accWrapper
    * @param    Boolean isMock - true for testing
    * @example  Arc_Gen_ParentSubsidiary_Controller.processResponse(sResponse, overlayObj, accWrapper)
    * */
    public static void processResponse(arce.Arc_Gen_getIASOResponse.ServiceResponse sResponse, arce__Overlay__c overlayObj, Boolean isMock) {
        Map<String,Object> data = new Map<String,Object>();
        if (isMock) {
            final iaso__GBL_integration_service__mdt integServ = arce.Arc_Gen_getIASOResponse.getIntegrationServiceConfigFromServiceName(SERVICE_NAME);
            data = (Map<String,Object>) JSON.deserializeUntyped(integServ.iaso__Mock_LTA__c);
        } else {
            data = (Map<String,Object>)sResponse.serviceResponse;
        }
        final ServRespWrapper respWrap = (ServRespWrapper) JSON.deserialize(JSON.serialize(data.get(Arc_Gen_ArceCore_Constants.DATA)).replaceAll(QUALITATIVE_VARS, QUALITATIVE_LIT).replaceAll(ID_SERV,ID_VAR_SERV).replaceAll(Arc_Gen_ArceCore_Constants.REL_PARENT_SUBS, REL_PS), ServRespWrapper.class);
        final Map<String, arce.Arc_Gen_PersistModifiers_Data.ModifierVariableDefinition> modifyVarMap = arce.Arc_Gen_PersistModifiers_Data.getModifierVariablesDefinition(PAR_SUBS_SERV_MAP);
        final Map<String,String> fieldMapping = new Map<String,String>();
        for (String fieldApi : modifyVarMap.keySet()) {
            fieldMapping.put(modifyVarMap.get(fieldApi).id, fieldApi);
        }

        overlayObj.put(FLD_PS_REL, respWrap.relations[0].identifier);
        final Map<String,List<String>> structure = new Map<String,List<String>>{respWrap.relations[0].matrix.identifier => new List<String>{respWrap.relations[0].matrix.identifier}};
        overlayObj.put(FLD_PARENT_GROUPS, JSON.serialize(structure));
        overlayObj.put(FLD_VALIDATE_GCP, Arc_Gen_ArceCore_Constants.SUBSIDIARY_CODE);
        overlayObj.put(FLD_PARENT_REL, arce.Arc_Gen_Constants.ONE_S);
        overlayObj.put(FLD_GLOBAL_ID, respWrap.relations[0].matrix.identifier + Arc_Gen_ArceCore_Constants.SPACE_DASH_SPACE + respWrap.relations[0].matrix.name);
        overlayObj.put(FLD_LOCAL_ID, respWrap.relations[0].matrix.identifier + Arc_Gen_ArceCore_Constants.SPACE_DASH_SPACE + respWrap.relations[0].matrix.name);
        overlayObj.put(FLD_PS_REL_USR_ID, respWrap.relations[0].businessAgent.identifier);
        overlayObj.put(FLD_GR_REL_TYPE, respWrap.relations[0].relationPS.identifier);
        overlayObj.put(FLD_PS_REL_DATE, respWrap.relations[0].creationDate);
        Arc_Gen_ParentSubsidiary_Controller.updateOverlayObj(String.valueOf(overlayObj.get(Arc_Gen_ArceCore_Constants.AHA)), (arce__Overlay__c) overlayObj);
        for (QualitativeVar qVar : respWrap.relations[0].qualitative) {
            if (fieldMapping.keySet().contains(qVar.identifier)) {
                overlayObj.put(fieldMapping.get(qVar.identifier).split(Arc_Gen_ArceCore_Constants.BACKSLASHES_DOT)[1], qVar.value);
            }
        }
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to call service Parent Subsidiary before Rating Systems
    * -----------------------------------------------------------------------------------------------------
    * @Author   antonio.perez.hernandez.contractor@bbva.com
    * @Date     07-02-2024
    * @param    String customerNumber
    * @param    Boolean isMock - true for testing
    * @return   Map<String,String>
    * @example  Arc_Gen_ParentSubsidiary_Controller.callPSBeforeRatingSys(customerNumber)
    * */
    public static Map<String,String> callPSBeforeRatingSys(String customerNumber, Boolean isMock) {
        Map<String,String> result = new Map<String,String>();
        final Map<String,String> params = new Map<String,String>{ Arc_Gen_ArceCore_Constants.PARTICIPANT_ID => customerNumber};
        final arce.Arc_Gen_getIASOResponse.ServiceResponse sResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME, JSON.serialize(params));
        if (sResponse.serviceCode != Arc_Gen_ArceCore_Constants.FOUR_HUNDRED && sResponse.serviceCode != Arc_Gen_ArceCore_Constants.FIVE_HUNDRED
        && sResponse.serviceCode != Arc_Gen_ArceCore_Constants.TWO_HUNDRED_FOUR) {
            result = processResponse(sResponse, isMock);
        }
        return result;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to process service Parent Subsidiary response before Rating Systems
    * -----------------------------------------------------------------------------------------------------
    * @Author   antonio.perez.hernandez.contractor@bbva.com
    * @Date     07-02-2024
    * @param    arce.Arc_Gen_getIASOResponse.ServiceResponse sResponse
    * @param    Boolean isMock - true for testing
    * @return   Map<String,String>
    * @example  Arc_Gen_ParentSubsidiary_Controller.processResponse(sResponse, isMock)
    * */
    private static Map<String,String> processResponse(arce.Arc_Gen_getIASOResponse.ServiceResponse sResponse, Boolean isMock) {
        final Map<String,String> result = new Map<String,String>();
        Map<String,Object> data = new Map<String,Object>();
        if (isMock) {
            final iaso__GBL_integration_service__mdt integServ = arce.Arc_Gen_getIASOResponse.getIntegrationServiceConfigFromServiceName(SERVICE_NAME);
            data = (Map<String,Object>) JSON.deserializeUntyped(integServ.iaso__Mock_LTA__c);
        } else {
            data = (Map<String,Object>)sResponse.serviceResponse;
        }
        final Object obj = data.get(arce.Arc_Gen_GenericUtilities.DATA_TEXT);
        final String jsonStr = JSON.serialize(obj).replaceAll(GROUP_SERV,GROUP_VAR_SERV).replaceAll(ID_SERV,ID_VAR_SERV).replaceAll(Arc_Gen_ArceCore_Constants.REL_PARENT_SUBS, REL_PS);
        final ServRespWrapper respWrap = (ServRespWrapper) JSON.deserialize(jsonStr, ServRespWrapper.class);
        result.put(Arc_Gen_ArceCore_Constants.REL_PARENT_SUBS, respWrap.relations[0].relationPS?.identifier);
        result.put(Arc_Gen_ArceCore_Constants.ECONOMIC_GROUP_ID, respWrap.relations[0].groupVar?.identifier);
        return result;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to check user RTC permission
    * -----------------------------------------------------------------------------------------------------
    * @Author   sergio.villaroel.contractor@bbva.com
    * @Date     2024/04/04
    * @param    Boolean isMock
    * @example  checkUserPermission(Boolean isMock)
    * */
    public static Boolean checkUserPermission (Boolean isMock) {
        final Boolean checkBecOffice = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(RTC_USERMEX)[0].arce__Value1__c);
        Boolean checkUser;
        if (checkBecOffice || isMock) {
            final List<GroupMember> list_groupMember = [SELECT UserOrGroupId FROM GroupMember WHERE Group.Name =: RTC_GROUPS];
            final List<String> ids = new List<String>();
            for (GroupMember gm : list_groupMember) {
                ids.add(gm.UserOrGroupId);
            }
            if (ids.contains(UserInfo.getUserId())) {
                checkUser = true;
            } else {
                checkUser = false;
            }
        } else {
            checkUser = true;
        }
        return checkUser;
    }
    /**
    * @Description: ServRespWrapper
    */
    private class ServRespWrapper {
        /**
        * @Description: List
        */
        private List<Relations> relations;
    }
    /**
    * @Description: Matrix
    */
    private class Matrix {
        /**
        * @Description: String
        */
        private String identifier;
        /**
        * @Description: String
        */
        private String name;
    }
    /**
    * @Description: Status
    */
    private class Status {
        /**
        * @Description: String
        */
        private String identifier;
    }
    /**
    * @Description: RelationPS
    */
    private class RelationPS {
        /**
        * @Description: String
        */
        private String identifier;
    }
    /**
    * @Description: QualitativeVariables
    */
    private class QualitativeVar {
        /**
        * @Description: String
        */
        private String identifier;
        /**
        * @Description: String
        */
        private String value;
    }
    /**
    * @Description: GroupWrp
    */
    private class GroupWrp {
        /**
        * @Description: String
        */
        private String identifier;
    }
    /**
    * @Description: BusinessAgent
    */
    private class BusinessAgent {
        /**
        * @Description: String
        */
        private String identifier;
    }
    /**
    * @Description: Relations
    */
    private class Relations {
        /**
        * @Description: String
        */
        private String identifier;
        /**
        * @Description: Datetime
        */
        private Datetime creationDate;
        /**
        * @Description: Matrix
        */
        private Matrix matrix;
        /**
        * @Description: Status
        */
        private Status status;
        /**
        * @Description: BusinessAgent
        */
        private BusinessAgent businessAgent;
        /**
        * @Description: RelationPS
        */
        private RelationPS relationPS;
        /**
        * @Description: List
        */
        private List<QualitativeVar> qualitative;
        /**
        * @Description: group
        */
        private GroupWrp groupVar;
    }
}