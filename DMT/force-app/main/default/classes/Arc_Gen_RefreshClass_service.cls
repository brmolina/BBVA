/**
* @File Name          : Arc_Gen_RefreshClass_service.cls
* @Description        : Call services and motors to update ARCE information
* @Author             : Diego Miguel dmiguelt@minsait.com / diego.miguel.contractor@bbva.com
* @Group              : ARCE Team
* @Controller Class   : Arc_Gen_ProposeInPreparation_controller
* @Data Class         : Arc_Gen_RefreshClass_data
* @Test Class         : Arc_Gen_RefreshClass_test
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 04/12/2020
* @Modification Log   :
*============================================================================================================================================
* Ver         Date                     Author                                     Modification
*============================================================================================================================================
* 1.0         28/04/2019              diego.miguel.contractor@bbva.com            Initial Version
* 1.1         19/06/2019              diego.miguel.contractor@bbva.com            Added group structure
* 1.2         24/06/2019              mauricio.esquivel.contractor@bbva.com       Added analysis completness from Json
* 1.3         04/02/2020              juanmanuel.perez.ortiz.contractor@bbva.com  Add two new parameters in setupPath() and created SetupPathWrapper to avoid 'long parameter lists'
* 1.4         10/02/2020              juanignacio.hita.contractor@bbva.com        REFACTORIZACION
* 1.5         04/03/2020              juanignacio.hita.contractor@bbva.com        Add labels in the creation of traceability
* 1.6         13/05/2020              cesaroctavio.villanueva.cebal@bbva.com      Added call to setFinancialSponsor method
* 1.7         23/06/2020              joseluis.garcia4.contractor@bbva.com        Refactor call to setFinancialSponsor (remove from getter method).
* 1.8         24/06/2020              juanignacio.hita.contractor@bbva.com        Added isHolding parameter n the AHA buildAccHasAnalysis creation method
* 1.9         05/10/2020              joseluis.garcia4.contractor@bbva.com        Added logic to update SME indicator in all child AHAs (bottom-up).
* 1.8         23/09/2020        saimassimilianno.jordana.contractor@bbva.com      Added arce. namespace to all classes that are now in the arce-dependencies package
* 1.10        04/12/2020              juanignacio.hita.contractor@bbva.com        Adds aha name (analysisId) param in traceability record
* 1.11        06/17/2021              juanmanuel.perez.ortiz.contractor@bbva.com  Change method reference to avoid sonar major
* 1.12        12/01/2022              juanignacio.hita.contractor@bbva.com        Removes call updateChildAhaSmeMark method
**/
public class Arc_Gen_RefreshClass_service {
    /**
    *  @Description : Variable participant type to list customer service
    */
    static final String PART_TYPE = 'SUBSIDIARY';
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date     28/05/2019
    * @author   diego.miguel.contractor@bbva.com
    */
    @TestVisible
    private Arc_Gen_RefreshClass_service() {
    }

    public class RefreshMessagesResponse {
        @AuraEnabled public String serviceStatus {get;set;}
        @AuraEnabled public String message {get;set;}
        @AuraEnabled public String retToPreparing {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @description returns a list of account_has_analysis related to the given ARCE id
    *--------------------------------------------------------------------------------
    * @date     04/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param	recordId - id of the account has analysis
    * @return	List<arce.Arc_Gen_Account_Has_Analysis_Wrapper>
    * @example	List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> lst = Arc_Gen_RefreshClass_service.getAllAnalysis(recordId);
    */
    public static List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> getAllAnalysis(Id recordId) {
        final List<arce__Account_has_Analysis__c> lstAcc = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId});
        return arce.Arc_Gen_AccHasAnalysis_Data.getListAHAWrapper(arce.Arc_Gen_AccHasAnalysis_Data.getAllAccFromArce(lstAcc[0].arce__Analysis__c));
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Check new Aha to update
    *--------------------------------------------------------------------------------
    * @date     04/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @return   String - ahaswithoutgroupnumber
    * @return   String - ahaswithoutgroup
    * @return   List<Map<String, String>>
    * @example  List<Map<String, String>> listMap = Arc_Gen_RefreshClass_service.checkNewAha(wrapper);
    */
    public static List<Map<String, String>> checkNewAha(String[] ahaswithoutgroupnumber, String[] ahaswithoutgroup, List<String> allParticipantsAccNum) {
        Map<String, String> participantsDelete = new Map<String, String>();
        Map<String, String> participantsActivate = new Map<String, String>();
        for (Integer i = 0; i < ahaswithoutgroupnumber.size(); i++) {
            if (allParticipantsAccNum.contains(ahaswithoutgroupnumber[i])) {
                participantsActivate.put(ahaswithoutgroup[i], ahaswithoutgroupnumber[i]);
            } else {
                participantsDelete.put(ahaswithoutgroup[i], ahaswithoutgroupnumber[i]);
            }
        }
        return new List<Map<String, String>>{participantsDelete, participantsActivate};
    }
    /**
    *-------------------------------------------------------------------------------
    * @description evaluate the list of participants
    *--------------------------------------------------------------------------------
    * @date     04/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    List<Object> lstParams
    * @return   void
    * @example  Arc_Gen_RefreshClass_service.evaluateListParticipants(lstParams);
    */
    public static void evaluateListParticipants(List<Object> lstParams) {
        final Arc_Gen_CallListParticipant.Innertoreturnlistp wrapper = (Arc_Gen_CallListParticipant.Innertoreturnlistp) lstParams[0];
        final String[] ahaswithoutgroup = (String[]) lstParams[1];
        final String[] ahaswithoutgroupnumber = (String[]) lstParams[2];
        final Id recordId = (Id) lstParams[3];
        List<String> allParticipantsAccNum = new List<String>();
        List<String> participantNoExist = new List<String>();
        Map<String, Boolean> mapIsHolding = new Map<String, Boolean>();

        for (Arc_Gen_CallListParticipant.Participantobj participant : wrapper.customersdata) {
            final String participantId = participant.participantId;
            allParticipantsAccNum.add(participantId);

            if (!ahaswithoutgroupnumber.contains(participantId)) {
                participantNoExist.add(participantId);
                Boolean isHolding = participant.isHolding == null ? false : true;
                mapIsHolding.put(participantId, isHolding);
            }
        }

        final List<Map<String, String>> participantsCheck = checkNewAha(ahaswithoutgroupnumber, ahaswithoutgroup, allParticipantsAccNum);
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(recordId);
        List<arce__Account_has_Analysis__c> lstAccHasAnalysis = new List<arce__Account_has_Analysis__c>();

        if (!participantsCheck[0].isEmpty()) {
            // Update Account Has Analysis to deactivate, the response of the service doesn't contain these accounts participantsCheck[0]
            lstAccHasAnalysis.addAll(setDeleteLogic(participantsCheck[0], true));
        }
        if (!participantsCheck[1].isEmpty()) {
            // Update Account Has Analysis to activate, the response of the service contain accounts that exist in Salesforce
            lstAccHasAnalysis.addAll(setDeleteLogic(participantsCheck[1], false));
        }
        if (!participantNoExist.isEmpty()) {
            // Create new "Accounts has Analysis" that have Accounts related in Salesforce and appear in the response of service
            lstAccHasAnalysis.addAll(Arc_Gen_RefreshClass_data.createAHAParticipants(participantNoExist, analysis, mapIsHolding));
        }
        if (!lstAccHasAnalysis.isEmpty()) {
            arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(lstAccHasAnalysis);
            if (!participantsCheck[0].isEmpty()) {
                Arc_Gen_RefreshClass_service.createTraceability(analysis.Id, participantsCheck[0].values());
            }
        }
        // Update SME mark for all child AHAs (only bottom-up)
        //updateChildAhaSmeMark(analysis.Id);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Manage and return the accounts to active or deactivate with the new values
    *--------------------------------------------------------------------------------
    * @date     14/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    Map<String, String> - lstIds
    * @param    Boolean - action
    * @return   List<arce__Account_has_Analysis__c>
    * @example  Arc_Gen_RefreshClass_service.setDeleteLogic(lstIds, action);
    */
    public static List<arce__Account_has_Analysis__c> setDeleteLogic(Map<String, String> lstIds, Boolean action) {
        List<String> lstKeys = new List<String>();
        lstKeys.addAll(lstIds.keySet());
        final List<arce__Account_has_Analysis__c> lstAccHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(lstKeys);
        for (arce__Account_has_Analysis__c acc : lstAccHasAnalysis) {
            acc.arce__removed_from_structure__c = action;
            if (action == true) {
                acc.arce__InReview__c = false;
            }
        }
        return lstAccHasAnalysis;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Updates SME indicator of potentially new child AHAs (only bottom-up)
    *--------------------------------------------------------------------------------
    * @date     05/10/2020
    * @author   joseluis.garcia4.contractor@bbva.com
    * @param    analysisId ID of the arce__Analysis__c object
    */
    public static void updateChildAhaSmeMark(Id analysisId) {
        final List<arce__Account_has_Analysis__c> ahas = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String> { analysisId });
        final List<arce__Account_has_Analysis__c> ahasToUpdate = new List<arce__Account_has_Analysis__c>();
        String smeMark;
        for (arce__Account_has_Analysis__c aha : ahas) {
            if (aha.arce__group_asset_header_type__c == arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER) {
                smeMark = aha.arce__smes_eur_comuty_defn_type__c;
                break;
            }
        }

        for (arce__Account_has_Analysis__c aha : ahas) {
            if (aha.arce__group_asset_header_type__c != arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER &&
                    aha.arce__anlys_wkfl_cnsld_ffss_type__c == arce.Arc_Gen_Constants.TDBU_BOTTOM_UP) {
                aha.arce__smes_eur_comuty_defn_type__c = smeMark;
                ahasToUpdate.add(aha);
            }
        }

        arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(ahasToUpdate);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Create the traceability with the accounts deleted
    *--------------------------------------------------------------------------------
    * @date     07/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    recordId - Id : Analysis id
    * @param    participantsDelete - List<String>
    * @return   dwp_cvad__Action_Audit__c
    * @example  Arc_Gen_RefreshClass_service.createTraceability(recordId, participantsDeleted);
    */
    public static dwp_cvad__Action_Audit__c createTraceability(Id recordId, List<String> participantsDeleted) {
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        final string traceComments = Arc_Gen_RefreshClass_Helper.createCommentTrace(participantsDeleted);
        final arce__Account_has_Analysis__c accHasGroup = arce.Arc_Gen_AccHasAnalysis_Data.getAhaGroupOfArce(recordId);
        final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Arc_Gen_RefreshTraceability + ' ' + System.Label.Lc_arce_GroupStructure, 'deny', traceComments.abbreviate(255), accHasGroup.Name);
        final Map<String, String> auditWF = Arc_Gen_Traceability.genAuditWF(wrpUser.userBasicInfo.Name.abbreviate(60), '', '', System.Label.Arc_Gen_Refresh);
        return Arc_Gen_Traceability.saveTrace(recordId, auditAttr, auditWF);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls path and return data needed to visualizate response:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     28/05/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.RefreshMessagesResponse
    * @example  public static Arc_Gen_RefreshClass_service.RefreshMessagesResponse callRatingFromRefresh(String recordId)
    */
    public static RefreshMessagesResponse callListCustomers(String recordId) {
        RefreshMessagesResponse wrapRet = getRefreshMessagesResponse();
        final List<arce__Account_has_Analysis__c> lstAcc = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId});
        if (lstAcc[0].arce__group_asset_header_type__c == '1') {
            wrapRet.serviceStatus = 'OK';
            wrapRet.message = 'The account is a group';
        } else {
            final Map<String,Object> miniArceData = Arc_Gen_RefreshClass_data.getAnalysis(recordId);
            Arc_Gen_ListCustomersService_service listCustomServ = new Arc_Gen_ListCustomersService_service();
            if (miniArceData.get('participantType') == PART_TYPE) {
                final String customerNumber = (String) miniArceData.get('customerNumber');
                arce.Arc_Gen_ServiceAndSaveResponse response = listCustomServ.setupListCustomers(customerNumber, true);
                wrapRet.message = response.serviceMessage;
            }
        }
        return wrapRet;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Refreshes financial sponsor indicator for an analysis.
    *--------------------------------------------------------------------------------
    * @date     23/06/2020
    * @author   joseluis.garcia4.contractor@bbva.com
    */
    public static void refreshFinancialSponsor(String ahaId) {
        final List<arce__Account_has_Analysis__c> lstAcc = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId});
        Arc_Gen_SetFinancialSponsor_Service.setFinancialSponsorAndUpdate(lstAcc[0].arce__Analysis__c);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description returns RefreshMessagesResponse object init to OK
    *--------------------------------------------------------------------------------
    * @date     28/05/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    void
    * @return   RefreshMessagesResponse
    * @example  public RefreshMessagesResponse getRefreshMessagesResponse()
    */
    public static RefreshMessagesResponse getRefreshMessagesResponse() {
        RefreshMessagesResponse response = new RefreshMessagesResponse();
        response.serviceStatus = 'OK';
        response.message = '';
        response.retToPreparing = 'OK';
        return response;
    }
}