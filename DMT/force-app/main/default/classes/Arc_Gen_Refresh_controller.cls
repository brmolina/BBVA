/*------------------------------------------------------------------
* @Author:       Luisarturo.parra.contractor@bbva.com
* @Project:      ARCE - BBVA Bancomer
* @Description:  Class controller for refresh component lightning
* @Class:        Arc_Gen_RefreshClass_controlelr
*_______________________________________________________________________________________
* Version    Date           Author                                       Description
* 1.0        11/04/2019     Luisarturo.parra.contractor@bbva.com           REFACTORIZACION.
* 1.2        13/01/2020     mariohumberto.ramirez.contractor@bbva.com      Modify method constructgroupstructure and added new comments
* 1.3        08/02/2020     ricardo.almanza.contractor@bbva.com            added for orphan
* 1.4        10/02/2020     juanignacio.hita.contractor@bbva.com           REFACTORIZACION
* 1.5        10/02/2020     juanignacio.hita.contractor@bbva.com           Fix condition for participants evaluation
* 1.6        18/06/2020     joseluis.garcia4.contractor@bbva.com           Add isOrphan in the call to the listParticipant service.
* 1.7        23/06/2020     joseluis.garcia4.contractor@bbva.com           Add refreshFinancialSponsor method.
* 1.8        13/07/2020     joseluis.garcia4.contractor@bbva.com           Add checks for edit permissions.
* 1.9        18/08/2020     joseluis.garcia4.contractor@bbva.com           Change reference from Arc_Gen_StatusButtons to Arc_Gen_GenericUtilities
* 1.10       25/08/2020     mariohumberto.ramirez.contractor@bbva.com      Add callEcoGroupParticipantsPersistence method
* 1.10       23/09/2020     saimassimilianno.jordana.contractor@bbva.com   Added arce. namespace to all classes that are now in the arce-dependencies package
* 1.11       04/01/2021     joseluis.garcia4.contractor@bbva.com           Add methods for orphan analysis refresh.
* 1.12       01/09/2021     juanignacio.hita.contractor@bbva.com           Add throwAuraExcept in callEconomicParticipants solved test class
* 1.13       27/09/2021     juanignacio.hita.contractor@bbva.com           Add sector condition to insert records objects of the hotel sector
* 1.14       01/04/2022     juanignacio.hita.contractor@bbva.com           Refactoring refreshFinancialSponsor for catch redirect exception 204
-----------------------------------------------------------------------------------------*/
public class Arc_Gen_Refresh_controller {
    /**
    * @Description: Hotel sector constant
    */
    private static final String HOTEL_SECTOR = '3';

    /**
    *-------------------------------------------------------------------------------
    * @description Empty private constructor
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 2020-02-21
    * @example private Arc_Gen_Refresh_controller ()
    **/
    @TestVisible
    private Arc_Gen_Refresh_controller () {
    }
    /**
    *--------------------------------------------------------------------------------
    * @description getAHARefresh
    *--------------------------------------------------------------------------------
    * @date     06/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    recordId
    * @return   List<arce.Arc_Gen_Account_Has_Analysis_Wrapper>
    * @example  arce.Arc_Gen_Account_Has_Analysis_Wrapper wrapp = Arc_Gen_Refresh_controller.getAHARefresh(recordId);
    * -------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> getAHARefresh(String recordId) {
        try {
            return Arc_Gen_RefreshClass_service.getAllAnalysis(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
    }
    /**
    *--------------------------------------------------------------------------------
    * @description Call list participant service.
    *--------------------------------------------------------------------------------
    * @date     06/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    encryptedgroup - String
    * @param    ahaswithoutgroup - String []
    * @param    ahaswithoutgroupnumber - String []
    * @param    recordId - String
    * @return   String
    * @example  String ret = Arc_Gen_Refresh_controller.getListParticipants(encryptedgroup, ahaswithoutgroup, ahaswithoutgroupnumber, recordId);
    * -------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String getListParticipants(String encryptedgroup, String[] ahaswithoutgroup, String[] ahaswithoutgroupnumber, String recordId) {
        if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(recordId, 'Arc_Gen_Refresh')) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
        }

        try {
            final Arc_Gen_CallListParticipant.Innertoreturnlistp wrapper = Arc_Gen_CallListParticipant.callListParticipants(encryptedgroup, false);
            if (wrapper.customersdata.size() > 0 && wrapper.servicecallerror == '') {
                Arc_Gen_RefreshClass_service.evaluateListParticipants(new List<Object>{wrapper, ahaswithoutgroup, ahaswithoutgroupnumber, recordId});
            }
            return JSON.serialize(wrapper);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description function that validate if the customer has a valid rating.
    *--------------------------------------------------------------------------------
    * @date     06/02/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  Arc_Gen_RefreshClass_service.refreshMessagesResponse wrap = Arc_Gen_Refresh_controller.callListCustomers(recordId);
    */
    @AuraEnabled
    public static Arc_Gen_RefreshClass_service.refreshMessagesResponse callListCustomers(String recordId) {
        if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(recordId, 'Arc_Gen_Refresh')) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
        }

        try {
            return Arc_Gen_RefreshClass_service.callListCustomers(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Updates the financial sponsor indicator according to the logic implemented
    * by the geography.
    *--------------------------------------------------------------------------------
    * @date     23/06/2020
    * @author   joseluis.garcia4.contractor@bbva.com
    * @param    ahaId - account_has_analysis Id
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse refreshFinancialSponsor(String ahaId) {
        final arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            Arc_Gen_RefreshClass_service.refreshFinancialSponsor(ahaId);
            response.serviceCode = '200';
        } catch (Arc_Gen_SetFinancialSponsor_Service.SetFinancialSponsorException ex) {
            response.serviceMessage = System.Label.Lc_arce_wizardRedirectRevokeArce;
            response.serviceCode = '204';
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
        return response;
    }
    /**
    *------------------------------------------------------------------------------------------------------------
    * @description Method that calls the economic group participant persitance service.
    *------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 24/04/2020
    * @param String listparticipant - list participant wrapper
    * @param String accountsParticipants - accounts participants info
    * @param String analysisId - Analysis Id
    * @return arce.Arc_Gen_getIASOResponse.serviceResponse - Wrapper that contains the response of the called service
    * @example callEcoGroupParticipantsPer(listparticipant, accountsParticipants, analysisId)
    * -----------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callEcoGroupParticipantsPersistence(String listparticipant, String accParticipants, String analysisId) {
        return Arc_Gen_AnalysisWizard_Controller.callEcoGroupParticipantsPer(listparticipant, accParticipants, analysisId);
    }

    /* METHODS SPECIFIC FOR ORPHAN REFRESH. */
    /**
    *------------------------------------------------------------------------------------------------------------
    * @description Performs a call to economicParticipants service to check if there is now a group for an orphan
    * client.
    *------------------------------------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com
    * @Date 04/01/2021
    * @param String encryptedClient - account number of the client
    * @param String recordId - Id of the AHA
    * @return wrapper with the service response
    * -----------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String callEconomicParticipants(String encryptedClient, String recordId) {
        if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(recordId, 'Arc_Gen_Refresh')) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
        }

        final Arc_Gen_CallEconomicParticipants.Innertoreturn econPartResult = Arc_Gen_CallEconomicParticipants.callEconomicParticipations(encryptedClient);

        if (econPartResult.isorphan) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Arc_Gen_Orphan_CouldntRefresh);
        }

        econPartResult.groupinfo.decryptedgroupid = arce.Arc_Gen_CallEncryptService.getEncryptedClient(econPartResult.groupinfo.decryptedgroupid);
        return JSON.serialize(econPartResult);
    }

    /**
    *------------------------------------------------------------------------------------------------------------
    * @description Performs a call to listParticipants service to check if there are more subsidiaries below the
    * economic group obtained in the callEconomicParticipants call.
    *------------------------------------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com
    * @Date 04/01/2021
    * @param String encryptedClient - account number of the group
    * @param String recordId - Id of the AHA
    * @return wrapper with the service response
    * -----------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String getListParticipantsOrphan(String encryptedClient, String recordId) {
        if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(recordId, 'Arc_Gen_Refresh')) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
        }

        try {
            final Arc_Gen_CallListParticipant.Innertoreturnlistp wrapper = Arc_Gen_CallListParticipant.callListParticipants(encryptedClient, false);
            return JSON.serialize(wrapper);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
    }

    /**
    *------------------------------------------------------------------------------------------------------------
    * @description Reflects the new group structure into the existing analysis
    *------------------------------------------------------------------------------------------------------------
    * @Author joseluis.garcia4.contractor@bbva.com
    * @Date 04/01/2021
    * @param String listparticipant - wrapper with the response of listparticipants service
    * @param String economicparticipant - wrapper with the response of economicparticipants service
    * @param String recordId - Id of the AHA
    * @return Id of the AHA for the group
    * -----------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static string constructGroupStructure(String listparticipant, String economicparticipant, String recordId) {
        if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(recordId, 'Arc_Gen_Refresh')) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
        }

        final Arc_Gen_CallEconomicParticipants.innertoreturn economicparticipants = (Arc_Gen_CallEconomicParticipants.innertoreturn) JSON.deserialize(economicparticipant, Arc_Gen_CallEconomicParticipants.innertoreturn.Class);
        final Arc_Gen_CallListParticipant.innertoreturnlistp listparticipants = (Arc_Gen_CallListParticipant.innertoreturnlistp) JSON.deserialize(listparticipant, Arc_Gen_CallListParticipant.innertoreturnlistp.Class);
        final Arc_Gen_NewGroups_service structure = new Arc_Gen_NewGroups_service();
        final Arc_Gen_NewGroups_service.Returnstructure groupStructure = structure.handleGroupStructureOnline(economicparticipants, listparticipants, economicparticipants.groupinfo.groupid, false);

        // It is required for the group to be an account in SF.
        if (groupStructure.noGroupsInSf) {
            throw new AuraHandledException(System.Label.Arc_Gen_Orphan_CouldntRefreshStructure);
        }

        // Get current AHA and ARCE.
        final arce__Account_has_Analysis__c orphanAha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId);
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id> { orphanAha.arce__Analysis__c })[0];

        // Get subsidiaries whose AHAs have to be created (excepting the orphan, which already has an AHA).
        final List<arce__Financial_Statements__c> emptyFFSS = arce.Arc_Gen_FinancialStatements_locator.getEmptyFFSS();
        final List<arce.Arc_Gen_Account_Wrapper> accountsWrapLts = groupStructure.participantsOnline;

        final List<arce__Account_has_Analysis__c> accHas2Create = new List<arce__Account_has_Analysis__c>();
        // Creation of non-existing subsidiaries.
        for (integer i = 0; i < accountsWrapLts.size() - 1; i++) {
            if (accountsWrapLts[i].accId != orphanAha.arce__Customer__c) {
                final Boolean holdingValue = groupStructure.isHolding.get(accountsWrapLts[i].accNumber);
                final Arc_Gen_NewAnalysis_Service.BuildAhaWrapper buildAhaWrapper = new Arc_Gen_NewAnalysis_Service.BuildAhaWrapper(analysis, accountsWrapLts[i]);
                buildAhaWrapper.emptyFFSS = emptyFFSS;
                buildAhaWrapper.clientType = arce.Arc_Gen_Constants.SUBSID_S;
                buildAhaWrapper.isHolding = holdingValue;
                accHas2Create.add(Arc_Gen_NewAnalysis_Service.buildAccHasAnalysis(buildAhaWrapper));
            }
        }
        // Creation group AHA
        final arce.Arc_Gen_Account_Wrapper groupWrapper = accountsWrapLts[accountsWrapLts.size() - 1];
        final Arc_Gen_NewAnalysis_Service.BuildAhaWrapper buildAhaWrapper = new Arc_Gen_NewAnalysis_Service.BuildAhaWrapper(analysis, groupWrapper);
        buildAhaWrapper.emptyFFSS = emptyFFSS;
        buildAhaWrapper.clientType = arce.Arc_Gen_Constants.S_GROUP;
        buildAhaWrapper.isHolding = false;
        final arce__Account_has_Analysis__c groupAha = Arc_Gen_NewAnalysis_Service.buildAccHasAnalysis(buildAhaWrapper);
        accHas2Create.add(groupAha);

        // Adjust ARCE object.
        analysis.arce__Group__c = groupWrapper.accId;
        analysis.arce__analysis_customer_relation_type__c = arce.Arc_Gen_Constants.CUSTOMER_RELATION_NON_ORPHAN;

        // Update data.
        arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c> { analysis });
        arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(accHas2Create);
        Arc_Gen_NewAnalysis_data.updateArceName(analysis.Id);

        // Insert empty rating variables.
        final List<arce__rating_variables_detail__c> ratingVarLts = new List<arce__rating_variables_detail__c>();
        for (arce__Account_has_Analysis__c accHas: accHas2Create) {
            ratingVarLts.add(arce.Arc_Gen_Rating_Var_detail_Data.setEmptyRatingVariable(accHas.Id));
        }
        arce.Arc_Gen_Rating_Var_detail_Data.insertRatingVariables(ratingVarLts);

        // Insert auxiliary data in group AHA.
        Arc_Gen_Expandible_Table_Service.verifyTypologiesInserted(groupAha.Id);
        Arc_Gen_PotitionBankTable_Service.verifyDataInserted(groupAha.Id);
        if (groupAha.arce__analysis_template_id__c == HOTEL_SECTOR) {
            Arc_Gen_Analysis_Category_Service.insertTableRecord(groupAha.Id);
            Arc_Gen_Analysis_Date_Service.insertTableRecord(groupAha.Id);
            Arc_Gen_Contracts_Appraisals_Service.insertTableRecord(groupAha.Id);
        }
        return String.valueOf(groupAha.Id);
    }
}