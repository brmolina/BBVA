/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_NewAnalysis_Controller
  * @Author   luisarturo.parra.contractor@bbva.com
  * @Date     Created: 2019-04-30
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Controller of the new analysis clients generator
  * ------------------------------------------------------------------------------------------------
  * @Changes
  *
  * |2019-04-30 eduardoefrain.hernandez.contractor@bbva.com
  *             Class creation.
  * |2019-05-02 diego.miguel.contractor@bbva.com
  *             Added logic to redirect to valid ARCE
  * |2019-05-03 diego.miguel.contractor@bbva.com
  *             Added functions to save ARCE name AND subtype
  * |2019-05-09 diego.miguel.contractor@bbva.com
  *             Added functions to redirect acording to ARCE satatus AND update status
  * |2019-05-14 diego.miguel.contractor@bbva.com
  *             Added methods to groups ws support
  * |2019-05-28 eduardoefrain.hernandez.contractor@bbva.com
  *             Added method to call list customer service
  * |2019-08-13 mariohumberto.ramirez.contractor@bbva.com
  *             clientId param deleted in the setClientSector method
  * |2019-08-13 luisruben.quinto.munoz@bbva.com
  *             arce__Id__c deleted in the class
  * |2019-11-04 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Remove FINAL statement in variable called response inside callPersistence method
  * |2019-11-27 mariohumberto.ramirez.contractor@bbva.com
  *             Added new param to the method setClientSector
  * |2019-11-27 luis.arturo.parra.contractor@bbva.com
  *             Refactorizacion
  * |2019-12-04 manuelhugo.castillo.contractor@bbva.com
  *             Modify method 'getaccdataforservices' replace Account to AccountWrapper
  * |2020-01-13 mariohumberto.ramirez.contractor@bbva.com
  *             Modify methods constructgroupstructure, getPreviousArce and setanalysis
  * |2020-01-09 javier.soto.carrascosa@bbva.com
  *             Remove unused class
  * |2020-02-04 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Add two new parameters in setupPath() and created SetupPathWrapper to avoid 'long parameter lists'
  * |2020-02-08 ricardo.almanza.contractor@bbva.com
  *             Added orphan
  * |2020-02-28 juanignacio.hita.contractor@bbva.com
  *             Added parameter "analysisType" in the method updateArceToPreparing
  * |2020-03-09 eduardoefrain.hernandez.contractor@bbva.com
  *             adedd methods because of Indepentent Rating (RAIP)
  * |2020-04-08 joseluis.garcia4.contractor@bbva.com
  *             refactor of new analysis dialog
  * |2020-04-27 ricardo.almanza.contractor@bbva.com
  *             added method callTriage for triage
  * |2020-04-27 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Added new static variables and modified getExistingArce method to add modified arce logic
  * |2020-05-13 cesaroctavio.villanueva.cebal@bbva.com
  *             added call to setFinancialSponsor method
  * |2020-05-15 cesaroctavio.villanueva.cebal@bbva.com
  *             Moved setFinancialSponsor method to avoid pending operation error
  * |2020-05-19 joseluis.garcia4.contractor@bbva.com
  *             Error management in triage call.
  * |2020-05-26 joseluis.garcia4.contractor@bbva.com
  *             Implement test call to check consolidated FFSS for groups.
  * |2020-06-18 joseluis.garcia4.contractor@bbva.com
  *             Add isOrphan in the call to the listParticipant service.
  * |2020-06-23 joseluis.garcia4.contractor@bbva.com
  *             Refactor call to setFinancialSponsor to avoid uncommited work pending error.
  * |2020-08-12 mariohumberto.ramirez.contractor@bbva.com
  *             Updated getExistingArce method for hu Renovation
  * |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
  *             Added arce. namespace to all classes that are now in the arce-dependencies package
  * |2020-09-28 juanignacio.hita.contractor@bbva.com
  *             Add getGroupId method for ContinueARCE_CMP component
  * |2021-04-30 otiliaramona.veres.contractor@bbva.com
  * 			Added an empty constructor method.
  * |2021-05-04 otiliaramona.veres.contractor@bbva.com
  * 			Added annotation '@testVisible' to the empty constructor method.
  * |2021-11-23 amunguia.contractor@bbva.com
          A setting has been added to control the checking of the credit lens service.
  * |2021-12-16 juanignacio.hita.contractor@bbva.com
  *             Add getIrpConfigCustomer method
  * |2022-01-21 saimassimilianno.jordana.contractor@bbva.com
  *             profilingResult method added to get flows permissions.
  * |2022-04-01 juanignacio.hita.contractor@bbva.com
  *             Add checkChangesTriage, compareStructOnline method and refactoring getExistingArce for add structure param
  * |2022-04-11 saimassimilianno.jordana.contractor@bbva.com
  *             sp2Analysis type added to getExistingArce method.
  * -----------------------------------------------------------------------------------------------
  */
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyMethods')
public with sharing class Arc_Gen_NewAnalysis_Controller {
    /**
    * @Description: String with SUBSIDIARY string
    */
    static final string SUBSIDIARY = 'SUBSIDIARY';
    /**
    * @Description: String with GROUP string
    */
    static final string GROUP_NAME = 'GROUP';
    /**
    * @Description: Status ID of the RAIP finalized status.
    */
    static final String RAIP_WF_FINALIZED_STATUS = '13';
    /**
    * @Description: Status ID of a finalized analysis.
    */
    static final String ANALYSIS_WF_FINALIZED_STATUS = '10';
    /**
    * @Description: Stage ID of a finalized analysis.
    */
    static final String ANALYSIS_WF_FINALIZED_STAGE = '3';
    /**
    * @Description: Sanction reason (Authorized w/out changes) of a finalized analysis.
    */
    static final String SANCTIONREASON_AUTHWITHOUTCHAN = '1';
    /**
    * @Description: Sanction reason (Authorized with changes) of a finalized analysis.
    */
    static final String SANCTIONREASON_AUTHWITHCHAN = '2';
    /**
    * @Description: Remove reason when arce is revoked.
    */
    static final String REMOVE_REASON = '2';
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@date 2021-04-30
    */
    @TestVisible
    private Arc_Gen_NewAnalysis_Controller() { }
    /**
    *-------------------------------------------------------------------------------
    * @description set the analysis in the response
    *--------------------------------------------------------------------------------
    * @date 02/11/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @param recordId recordId - id of the account_has_analysis
    * @param String analysisType (arce__anlys_wkfl_sub_process_type__c)
    * @return AnalysisResponse - Response of the created ARCE
    * @example setupAnalysis(String recordId, String analysisType) {
    */
    @AuraEnabled
    public static arce.Arc_Gen_Account_Wrapper getaccdataforservices(String recordId) {
        return Arc_Gen_NewAnalysis_data.getUniqueCustomerDatacl(recordId);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description set the analysis in the response
    *--------------------------------------------------------------------------------
    * @date 02/11/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @param recordId recordId - id of the account_has_analysis
    * @param String analysisType (arce__anlys_wkfl_sub_process_type__c)
    * @return AnalysisResponse - Response of the created ARCE
    * @example setupAnalysis(String recordId, String analysisType) {
    */
    @AuraEnabled
    public static String economicarticipants(String encryptedClient) {
        return JSON.serialize(Arc_Gen_CallEconomicParticipants.callEconomicParticipations(encryptedClient));
    }
     /**
    * --------------------------------------------------------------------------------------
    * @Description Method that use ContinueARCE_CMP component for get group
    * --------------------------------------------------------------------------------------
    * @Author   ArceCorpo
    * @Date     Created: 25/09/2020
    * @param    String : recordId
    * @return   object type arce__Analysis__c
    * @example  getGroupId(recordId)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static arce__Analysis__c getGroupId(String recordId) {
        return [select Id,arce__Group__c,arce__wf_status_id__c, arce__analysis_type_selected__c,arce__anlys_wkfl_sub_process_type__c, arce__is_RTC__c from arce__Analysis__c where Id=: recordId limit 1];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description set the analysis in the response
    *--------------------------------------------------------------------------------
    * @date 02/11/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @param recordId recordId - id of the account_has_analysis
    * @param String analysisType (arce__anlys_wkfl_sub_process_type__c)
    * @return AnalysisResponse - Response of the created ARCE
    * @example setupAnalysis(String recordId, String analysisType) {
    */
    @AuraEnabled
    public static String listparticipant(String encryptedgroup, Boolean isOrphan) {
        return JSON.serialize(Arc_Gen_CallListParticipant.callListParticipants(encryptedgroup, isOrphan));
    }
    /**
    *-------------------------------------------------------------------------------
    * @description set the analysis in the response
    *--------------------------------------------------------------------------------
    * @date 02/11/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @param recordId recordId - id of the account_has_analysis
    * @param String analysisType (arce__anlys_wkfl_sub_process_type__c)
    * @return AnalysisResponse - Response of the created ARCE
    * @example setupAnalysis(String recordId, String analysisType) {
    */
    @AuraEnabled
    public static String constructgroupstructure(String listparticipant, String economicparticipant, String accountNumber, Boolean isOrphan) {
        Arc_Gen_CallEconomicParticipants.innertoreturn economicparticipants = new Arc_Gen_CallEconomicParticipants.innertoreturn();
        Arc_Gen_CallEconomicParticipants.Groupdata groupData = new Arc_Gen_CallEconomicParticipants.Groupdata();
        Boolean orphan = isOrphan;
        groupData.groupid = accountNumber;
        if (orphan == null) {
          orphan = false;
        }
        if(economicparticipant == null){
            economicparticipants.groupinfo = groupData;
        } else {
          economicparticipants = (Arc_Gen_CallEconomicParticipants.innertoreturn) JSON.deserialize(economicparticipant, Arc_Gen_CallEconomicParticipants.innertoreturn.Class);

        }
        Arc_Gen_CallListParticipant.innertoreturnlistp listparticipants = (Arc_Gen_CallListParticipant.innertoreturnlistp) JSON.deserialize(listparticipant, Arc_Gen_CallListParticipant.innertoreturnlistp.Class);
        Arc_Gen_NewGroups_service structure = new Arc_Gen_NewGroups_service();
        return JSON.serialize(structure.handleGroupStructureOnline(economicparticipants, listparticipants, accountNumber, orphan));
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Performs a test call to the corresponding financial statements service
    * (depending on the participant type of the account). This call is to check whether
    * any financial statement is returned from the service and therefore to check if the
    * RAIP creation process can proceed.
    *--------------------------------------------------------------------------------
    * @date 25/05/2020
    * @author joseluis.garcia4.contractor@bbva.com
    * @param String accountNumber - Number of the account of the RAIP to be created
    * @return arce.Arc_Gen_ServiceAndSaveResponse - The response from the service
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse performFfssTestCall(String accountNumber) {
        return Arc_Gen_Balance_Tables_service.financialStatementsTestCall(accountNumber);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that calls the Persistance service.
    *-------------------------------------------------------------------------------
    * @date 09/04/2019
    * @author ricardo.almanza.contractor@bbva.com
    * @param String analysisId - Analysis Id
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse callPersistence(String customerId, String analysisId)
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callPersistence(String analysisId) {
        Arc_Gen_PersistanceArceId_service service = new Arc_Gen_PersistanceArceId_service();
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            // Fetch financial sponsor status from implementation.
            final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<String> { analysisId })[0];
            Arc_Gen_SetFinancialSponsor_Service.setFinancialSponsor(analysis);
            // Call persistence.
            response = service.setupRiskAssHeader(analysisId, analysis.arce__controlled_by_sponsor_type__c);
            // Update financial sponsor indicator.
            arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c> { analysis });
        } catch (Arc_Gen_SetFinancialSponsor_Service.SetFinancialSponsorException ex) {
            response.serviceMessage = ex.getMessage();
            response.serviceCode = '500';
        } catch (Exception ex) {
            response.serviceMessage = ex.getMessage();
        }
        Return response;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that calls the triage service.
    *-------------------------------------------------------------------------------
    * @date 09/04/2019
    * @author ricardo.almanza.contractor@bbva.com
    * @param String analysisId - Analysis Id
    * @param String customerId - Account Id
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse callTriage(String analysisId,String customerId)
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callTriage(String analysisId,String customerId, String clientId) {
        Arc_Gen_Triage_helper.TriageResponse response;
        arce.Arc_Gen_ServiceAndSaveResponse resp = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
          response = Arc_Gen_Triage_service.setupTriageService(analysisId, Arc_Gen_Triage_service.setServiceParameters(analysisId, customerId), '');
          resp = response.response;
        } catch (Exception ex) {
          resp.serviceCode = '500';
          resp.serviceMessage = ex.getMessage()+ex.getStackTraceString();
        }
        final Id accHasGroupId = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Customer__c = :clientId AND arce__Analysis__c = :analysisId].Id;
        Arc_Gen_Expandible_Table_Service.verifyTypologiesInserted(accHasGroupId);
        Arc_Gen_PotitionBankTable_Service.verifyDataInserted(accHasGroupId);
        Return resp;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Gets the ARCE types available for user selection from the configuratior.
    * 1 - Consolidated group code for analysis_type field of analysis object TD
    * 2 - Not consolidated group code for analysis_type field of analysis object BU
    * 3 - Orphan code for analysis_type field of analysis object
    * 4 - IRP Code for analysis_type field of analysis object
    *-------------------------------------------------------------------------------
    * @Author juanignacio.hita.contractor@bbva.com
    * @param String analysisId - Analysis Id
    * @param String existArceIdToMod - Analysis Id
    * @return Boolean if has changes of analysis type
    *-------------------------------------------------------------------------------
    */
    public static Boolean checkChangesTriage(String analysisId, String existArceIdToMod) {
        Boolean changes = false;
        final List<arce__Analysis__c> analysis = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{analysisId, existArceIdToMod});
        final arce__Account_has_Analysis__c accHasGroup = arce.Arc_Gen_AccHasAnalysis_Data.getAhaGroupOfArce(analysisId);
        final arce__Account_has_Analysis__c accHasGroupExist = arce.Arc_Gen_AccHasAnalysis_Data.getAhaGroupOfArce(existArceIdToMod);
        final String typeAnalysis = Arc_Gen_NewAnalysis_data.getTypeWkflAnalysis(analysis[0], new List<arce__Account_has_Analysis__c>{accHasGroup});
        final String typeExistAnalysis = Arc_Gen_NewAnalysis_data.getTypeWkflAnalysis(analysis[1], new List<arce__Account_has_Analysis__c>{accHasGroupExist});
        if (typeAnalysis != typeExistAnalysis) {
            Arc_Gen_Remove_Service.updateRemoveInfo(accHasGroup.Id, REMOVE_REASON, System.Label.Arc_Gen_RevokeArceByChangesStrucGroup, '');
            changes = true;
        }
        return changes;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Checks triage selection (sector and ffss type) in renov/mod process for revoke arce
    *-------------------------------------------------------------------------------
    * @Author juanignacio.hita.contractor@bbva.com
    * @param   Id accHasId
    * @param   Map<String, String> data
    * @return  Boolean if has changes
    * @example Boolean ret = checkManualTriage(accHasId, data);
    *-------------------------------------------------------------------------------
    */
    public static Boolean checkManualTriage(Id accHasId, Map<String, String> data) {
        Boolean changes = false;
        if (data.get('prevTemplate') != data.get('postSector') || data.get('prevFfss') != data.get('postFfss')) {
            Arc_Gen_Remove_Service.updateRemoveInfo(accHasId, REMOVE_REASON, System.Label.Arc_Gen_RevokeArceByChangesStrucGroup, '');
            changes = true;
        }
        return changes;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Gets the ARCE types available for user selection from the configuratior.
    *-------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com | 8/4/2020
    * @return the list of available ARCE types ('Analysis', 'RAIP' or both).
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static List<String> getAvailableArceTypes() {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('AvailableARCETypes');
        List<String> arceTypes;
        if (configs.isEmpty()) {
            arceTypes = new List<String>();
        } else {
            final arce__Arce_Config__mdt config = configs[0];
            arceTypes = config.arce__Value1__c.split(',');
        }

        return arceTypes;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Gets the ARCE types available for user selection from the configuratior.
    *-------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com | 8/4/2020
    * @return the list of available ARCE types ('Analysis', 'RAIP' or both).
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static Boolean shouldShowRaipGroupStructure() {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPDisplayGroupStructure');

        return configs.isEmpty() ? false : Boolean.valueOf(configs[0].arce__Value1__c);
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Gets the ARCE types available for user selection from the configuratior.
    *-------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com | 8/4/2020
    * @return the list of available ARCE types ('Analysis', 'RAIP' or both).
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static List<String> getIrpConfigCustomer() {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('IRPAvailableTypeCustomer');
        List<String> customerTypes;
        if (configs.isEmpty()) {
            customerTypes = new List<String>();
        } else {
            final arce__Arce_Config__mdt config = configs[0];
            customerTypes = config.arce__Value1__c.split(',');
        }
        return customerTypes;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description gets info of already existing arce of the specified type (if it exists).
    *--------------------------------------------------------------------------------
    * @date 02/11/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @param recordId recordId - ID of the Account
    * @param String accountswraper - Wrapper that contains all account data
    * @param String arceType - Type of ARCE ('raip' or 'analysis').
    * @param String structure - JSON Serialize
    * @return   Arc_Gen_NewAnalysis_Service_Helper.PreviousARCEData - Wrapper that contains all the Previous ARCE data
    */
    @AuraEnabled
    public static Arc_Gen_NewAnalysis_Service_Helper.PreviousARCEData getExistingArce(String recordId, String accountswraper, String arceType, String structure) {
        final Arc_Gen_NewAnalysis_Service_Helper.PreviousARCEData previousArce =
            Arc_Gen_NewAnalysis_Service.getPreviousArceOnline(recordId, accountswraper, arceType);
        final Boolean previousArceExists = !String.isEmpty(previousArce.idARCE);
        String currentArceId = null;
        if (previousArceExists) {
            // Is the latest ARCE in a "finalized" state?
            final Boolean isRaip = arceType == 'raip' || arceType == 'sp2Analysis';
            final Boolean isCurrentRaip = isRaip && previousArce.wfStatus != RAIP_WF_FINALIZED_STATUS;
            final Boolean isCurrentAnalysis = !isRaip && previousArce.wfStatus != ANALYSIS_WF_FINALIZED_STATUS;
            previousArce.modification = getValidToModification(previousArce);
            previousArce.renovation = getValidToRenovation(previousArce);
            if (isCurrentRaip || isCurrentAnalysis || previousArce.modification || previousArce.renovation) {
                currentArceId = previousArce.idARCE;
                if (!isRaip) {
                    compareStructOnline(previousArce, structure); // Compare analysis structure
                }
            }
        }

        previousArce.idARCE = currentArceId;
        return previousArce;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Compare structure online and previousArce
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 01/04/2022
    * @param    Arc_Gen_NewAnalysis_Service_Helper.PreviousARCEData previousArce
    * @param    String structure
    * @return   void
    * @example  compareStructOnline(previousArce, structure)
    * --------------------------------------------------------------------------------------
    **/
    public static void compareStructOnline(Arc_Gen_NewAnalysis_Service_Helper.PreviousARCEData previousArce, String structure) {
        final Boolean arceNotFinalized = previousArce.wfStage != arce.Arc_Gen_Constants.STAGE_FINALIZED;
        final Boolean checkStructGroup = !Test.isRunningTest() && !previousArce.modifiedStrucGroup && !previousArce.redirectRevoke && structure != null;
        if (checkStructGroup) {
            final Arc_Gen_NewGroups_service.Returnstructure retStruct = (Arc_Gen_NewGroups_service.Returnstructure) JSON.deserialize(structure, Arc_Gen_NewGroups_service.Returnstructure.Class);
            final Arc_Gen_NewGroups_service newGroups = new Arc_Gen_NewGroups_service();
            previousArce.modifiedStrucGroup = newGroups.comparePrevStructOnline(previousArce, retStruct);
            if (arceNotFinalized) {
                previousArce.redirectRevoke = previousArce.modifiedStrucGroup ? previousArce.modifiedStrucGroup : false;
            }
        }
        final Boolean revokeArce = previousArce.modifiedStrucGroup && previousArce.redirectRevoke && arceNotFinalized;
        if (revokeArce) { // changes group structure
            String accHasId = previousArce.accHasAnalysisId;
            if (String.isEmpty(accHasId)) {
                final List<arce__Account_has_Analysis__c> lstAha = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{previousArce.idARCE});
                accHasId = lstAha[0].Id;
            }
            Arc_Gen_Remove_Service.updateRemoveInfo(accHasId, REMOVE_REASON, System.Label.Arc_Gen_RevokeArceByChangesStrucGroup, '');
        }
    }
    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Validates if the analysis can be modified
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 07/07/2020
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @param prevArce wrapper with the info of the analysis
    * @return true/fasle
    * @example getValidToModification(prevArce);
    *---------------------------------------------------------------------------------------------------------------------
    */
    private static Boolean getValidToModification (Arc_Gen_NewAnalysis_Service_Helper.PreviousARCEData prevArce) {
        return prevArce.wfStatus == ANALYSIS_WF_FINALIZED_STATUS && prevArce.wfStage == ANALYSIS_WF_FINALIZED_STAGE && (prevArce.sanctionType == SANCTIONREASON_AUTHWITHOUTCHAN || prevArce.sanctionType == SANCTIONREASON_AUTHWITHCHAN) && prevArce.expiryDate > system.today() && prevArce.modIsActive ? true : false;
    }
    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Validate if the analysis can be renewed
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 07/07/2020
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @param prevArce wrapper with the info of the analysis
    * @return true/fasle
    * @example getValidToRenovation(prevArce);
    *---------------------------------------------------------------------------------------------------------------------
    */
    private static Boolean getValidToRenovation (Arc_Gen_NewAnalysis_Service_Helper.PreviousARCEData prevArce) {
        return prevArce.wfStatus == ANALYSIS_WF_FINALIZED_STATUS && prevArce.wfStage == ANALYSIS_WF_FINALIZED_STAGE && (prevArce.sanctionType == SANCTIONREASON_AUTHWITHOUTCHAN || prevArce.sanctionType == SANCTIONREASON_AUTHWITHCHAN) && prevArce.renIsActive ? true : false;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Get EEFF Service Check.
    *-------------------------------------------------------------------------------
    * @Author amunguia.contractor@bbva.com | 23/11/2021
    * @return Boolean.
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static Boolean getEEFFServiceCheck() {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPEEFFServiceCheck');

        return configs.isEmpty() ? false : Boolean.valueOf(configs[0].arce__Value1__c);
    }
    /**
    * @description
    * @author Global Desktop | 02-12-2021
    * @param recordId
    * @return Boolean
    **/
    @AuraEnabled
    public static Boolean isCountryAvailable(String recordId) {
        Boolean hasCountry = true;
        final List<Local_Client__c> local = [Select g_residence_country_id__c from Local_Client__c where Id =:recordId LIMIT 1];
        if (!local.isEmpty()) {
            if(String.isBlank(local.get(0).g_residence_country_id__c)) {
                hasCountry = false;
            }
        }
        return hasCountry;
    }
    
	/**
    *-------------------------------------------------------------------------------
    * @Description Get allowed flows by profiling, IrpTypesFilterByModel configuration and ARP-ClientGroup behavior.
    *-------------------------------------------------------------------------------
    * @Author saimassimilianno.jordana.contractor@bbva.com | 19/01/2022
    * @return String.
    * @Example Arc_Gen_NewAnalysis_Controller.profilingResult(clientId)
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String profilingResult(String clientId) {

        String activeFlows = Test.isRunningTest() ? 'false' : arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('IrpTypesFilterByModel')[0].arce__Value1__c; //NOSONAR
        Final Boolean irpWizard = Test.isRunningTest() ? true : Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPSelectWorkflow')[0].arce__Value1__c); //NOSONAR

        if (irpWizard) {
            activeFlows = activeFlows == 'false' ? System.Label.Arc_Gen_AllFlowsAllowed : activeFlows;

            // ARP with client goup behavior
            activeFlows = Arc_Gen_NewAnalysis_Service.arpGroup(clientId,activeFlows);

            // Applying profiling filters.
            activeFlows = Arc_Gen_NewAnalysis_Service.flowsFilterResult(clientId,activeFlows);

        } else {
            activeFlows = 'false';
        }


        return activeFlows;

    }
    /**
    *-------------------------------------------------------------------------------
    * @Description get analisis Id
    *-------------------------------------------------------------------------------
    * @date 17/01/2024
    * @author alberto.martinez.carrero.next@bbva.com
    * @return String
    * @example checkArceAnalisysExist(clientId)
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String checkArceAnalisysExist(String clientId) {
        return Arc_Gen_NewAnalysis_data.checkArceAnalisysExist(clientId);
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description get account or local client Id
    *-------------------------------------------------------------------------------
    * @date 17/01/2024
    * @author alberto.martinez.carrero.next@bbva.com
    * @return String
    * @example getAccOrLocalClientId(clientId)
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String getAccOrLocalClientId(String analysisId) {
        final arce__Account_has_Analysis__c aha = Arc_Gen_NewAnalysis_data.getAnalysisAnalizedClients(analysisId)[0];
        return arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(aha);
    }
}