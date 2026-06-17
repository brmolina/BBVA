/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_CallRatingSystems
* @Author   antonio.perez.hernandez.contractor@bbva.com
* @Date     Created: 06/02/2024
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Arc_Gen_CallRatingSystems
* -----------------------------------------------------------------------------------------------
* @Changes
*
* | 06/02/2024 antonio.perez.hernandez.contractor@bbva.com
*              Class creation
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_CallRatingSystems {
    /**
    * @description Service name
    */
    public static final String SERVICE_NAME = 'ratingSystems';
    /**
    *-------------------------------------------------------------------------------
    * @description Wrapper used to describe rating systems service response.
    *-------------------------------------------------------------------------------
    **/
    private class ServRespWrapper {
        /**
        * @Description: List<RatingSystem> ratingSystem
        */
        private List<RatingSystem> ratingSystem;
    }
    /**
    * @Description: class RatingSystem
    */
    private class RatingSystem {
        /**
        * @Description: String identifier
        */
        private String identifier;
    }

    /**
    * Constructor
    **/
    @TestVisible
    private Arc_Gen_CallRatingSystems() {
        System.debug(LoggingLevel.INFO, 'Arc_Gen_CallRatingSystems');
    }

    /*------------------------------------------------------------------------------------------------------
    *@Description Method to process Rating Systems service response
    * -----------------------------------------------------------------------------------------------------
    * @Author   antonio.perez.hernandez.contractor@bbva.com
    * @Date     07-02-2024
    * @param    String recordId - Account id
    * @param    Boolean isMock - true for testing
    * @return   String
    * @example  Arc_Gen_CallRatingSystems.callRatingSystems(recordId, isMock)
    * */
    public static String callRatingSystems(String recordId, Boolean isMock) {
        String result = '';
        final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> { recordId }).get(recordId);
        final String customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(accWrapper.accNumber);
        final Map<String,String> psMap = Arc_Gen_ParentSubsidiary_Service.callPSBeforeRatingSys(customerNumber, isMock);
        if (!psMap.isEmpty()) {
            final arce.Arc_Gen_User_Wrapper uInfo = arce.Arc_Gen_User_Locator.getUserInfo(UserInfo.getUserId());
            Map<String,Object> data = new Map<String,Object>();
            if (isMock) {
                final iaso__GBL_integration_service__mdt integServ = arce.Arc_Gen_getIASOResponse.getIntegrationServiceConfigFromServiceName(SERVICE_NAME);
                data = (Map<String,Object>) JSON.deserializeUntyped(integServ.iaso__Mock_LTA__c);
            } else {
                final Map<String,String> params = new Map<String,String>{
                    Arc_Gen_ArceCore_Constants.PARTICIPANT_ID => customerNumber,
                    Arc_Gen_ArceCore_Constants.ECONOMIC_GROUP_ID => psMap.get(Arc_Gen_ArceCore_Constants.ECONOMIC_GROUP_ID),
                    Arc_Gen_ArceCore_Constants.BUSINESS_AGENT_ID => uInfo.businessAgentId,
                    Arc_Gen_ArceCore_Constants.BANK_ID => accWrapper.bankId,
                    Arc_Gen_ArceCore_Constants.BANK_BRANCH_ID => uInfo.branchId,
                    Arc_Gen_ArceCore_Constants.BANK_BRANCH_L_ID => uInfo.branchlevel,
                    Arc_Gen_ArceCore_Constants.REL_PARENT_SUBS => psMap.get(Arc_Gen_ArceCore_Constants.REL_PARENT_SUBS)
                };
                final arce.Arc_Gen_getIASOResponse.ServiceResponse sResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME, JSON.serialize(params));
                if (sResponse.serviceCode != Arc_Gen_ArceCore_Constants.FOUR_HUNDRED && sResponse.serviceCode != Arc_Gen_ArceCore_Constants.FIVE_HUNDRED) {
                    data = (Map<String,Object>) sResponse.serviceResponse;
                }
            }
            if (!data.isEmpty()) {
                final ServRespWrapper respWrap = (ServRespWrapper) JSON.deserialize(JSON.serialize(data.get(arce.Arc_Gen_GenericUtilities.DATA_TEXT)).replaceAll(Arc_Gen_ParentSubsidiary_Service.ID_SERV,Arc_Gen_ParentSubsidiary_Service.ID_VAR_SERV), ServRespWrapper.class);
                result = respWrap.ratingSystem[0].identifier;
            }
        }
        return result;
    }
}