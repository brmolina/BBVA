/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_AnalysisWizard_Service
  * @Author   joseluis.garcia4.contractor@bbva.com
  * @Date     Created: 2020-04-08
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Service of the analysis wizard of the new ARCE modal.
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-04-08 joseluis.garcia4.contractor@bbva.com
  *             Class creation.
  * |2020-04-17 Javier.soto.carrascosa@bbva.com
  *             Add change to recover subprocess label
  * |2020-05-14 joseluis.garcia4.contractor@bbva.com
  *             Only update ARCE status if it is not already finalized (e.g. by triage call)
  * |2020-06-26 joseluis.garcia4.contractor@bbva.com
  *             Only update ARCE status if it is not already finalized (e.g. by triage call)
  * |2020-07-02 mariohumberto.ramirez.contractor@bbva.com
  *             Added call to methods that insert policy and position records when sector selector is manual
  * |2020-08-11 javier.soto.carrascosa@bbva.com
  *             Update sector field
  * |2020-09-02 joseluis.garcia4.contractor@bbva.com
  *             Fix typologies not being loaded for orphans.
  * |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
  *             Added arce. namespace to all classes that are now in the arce-dependencies package
  * |2020-11-17 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Add line to insert dummy record for contracts and appraisals table
  * |2020-11-30 moises.martinez.dominguez.contractor@bbva.com
  *             add insert tables date and category
  * |2020-12-10 juanigacio.hita.contractor@bbva.com
  *             add analysisId attribute in traceability log
  * |2021-02-23 juanignacio.hita.contractor@bbva.com
  *             Modified updateSector method to add analysis type field update
  * |2020-02-24 brauliobaruchs.sanpedro.contractor@bbva.com
  *             Validate when to add the icon approve: Only when the ARCE is Arce scope
  * |2021-09-27 juanignacio.hita.contractor@bbva.com
  *             Add sector condition to insert records objects of the hotel sector
  * |2021-12-02 francisco.munoz.torres.contractor@bbva.com
  *             add callRatioEngineOnModification method
  * |2021-12-22 francisco.munoz.torres.contractor@bbva.com
  *             remove callRatioEngineOnModification method
  */
public with sharing class Arc_Gen_AnalysisWizard_Service {
    /**
    * @Description: String with the word Group
    */
    static final String GROUP_S = 'Group';
    /**
    * @Description: Verify the status ARCE
    */
    static final string STATUSARCE = '10';
    /**
    * @Description:
    */
    private static final String HOTEL_SECTOR = '3';

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Custom Exception for New Analysis process
    * ----------------------------------------------------------------------------------------------------
    * @Author   Javier Soto Carrascosa  javier.soto.carrascosa@bbva.com
    * @Date     Created: 2020-02-24
    * @example throw new NewAnalysisException('Unexpected Error');
    * ----------------------------------------------------------------------------------------------------
    **/
    public class NewAnalysisException extends Exception {}

    private Arc_Gen_AnalysisWizard_Service() { }   // NOPMD

    /**
    *-------------------------------------------------------------------------------
    * @description method that updates arce status
    *-------------------------------------------------------------------------------
    * @date 12/09/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @param List<arce__Account_has_Analysis__c> analyzedClientList
    * @return none
    * @example  private void setRatingVariables(List<arce__Account_has_Analysis__c> analyzedClientList)
    */
    public static void updateStatusArce(String arceId, String status, String analysisType) {
        final List<arce__Analysis__c> showStatus = [select arce__wf_status_id__c from arce__Analysis__c WHERE id =: arceId];
        final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id> { arceId })[0];

        // Update status only if ARCE is not already closed (stage = 3).
        if (arceVar.arce__Stage__c != arce.Arc_Gen_Constants.STAGE_FINALIZED) {
            Arc_Gen_NewAnalysis_data.upsertObjects(new List < arce__Analysis__c > {
                new arce__Analysis__c(id = arceId, arce__wf_status_id__c = status)
            });
            if (showStatus[0].arce__wf_status_id__c != STATUSARCE) {
            final arce__Account_has_Analysis__c accHasGroup = arce.Arc_Gen_AccHasAnalysis_Data.getAhaGroupOfArce(arceId);
            final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
            final string traceComments = Label.Arc_Gen_TraceabilityOffice + ': ' + wrpUser.branchText.abbreviate(60) + ' | ' + Label.Arc_Gen_TraceabilitySubprocess + ': ' + arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__analysis__c', 'arce__anlys_wkfl_sub_process_type__c', analysisType);
            final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Arc_Gen_Traceability_02, 'approve', traceComments.abbreviate(255), accHasGroup.Name);
            final Map<String, String> auditWF = new Map<String, String>();
            Arc_Gen_Traceability.saveTrace(arceId, auditAttr, auditWF);
            }
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Updates ARCE status and top-down/bottom-up indicator.
    *-------------------------------------------------------------------------------
    * @date 26/06/2020
    * @author joseluis.garcia4.contractor@bbva.com
    * @param String arceId - ID of the ARCE
    * @param String sector - Name of the sector
    * @param String indicator - Top-down/Bottom-up indicator
    */
    public static void updateSector(String arceId, String sector, String indicator) {
        final List<arce__Account_has_Analysis__c> ahas = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String> { arceId });
        arce__Account_has_Analysis__c ahaGroup = new arce__Account_has_Analysis__c();

        for (arce__Account_has_Analysis__c aha : ahas) {

            if (aha.arce__group_asset_header_type__c == '1' || aha.arce__Analysis__r.arce__analysis_customer_relation_type__c == '02') {
                ahaGroup = aha;
            }

            aha.arce__analysis_template_id__c = sector;
            aha.arce__anlys_wkfl_cnsld_ffss_type__c = indicator;
            aha.arce__customer_arce_scope_type__c = '1';
        }
        // Updates analysis type field depending ffss selected :Top down or bottom up
        final arce__Analysis__c analysis = new arce__Analysis__c(Id = arceId);
        analysis.arce__anlys_arce_type__c = Arc_Gen_NewAnalysis_Data.getTypeFfssAha(ahaGroup);
        Arc_Gen_NewAnalysis_data.upsertObjects(new List<sObject>{analysis});

        arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(ahas);

        Arc_Gen_Expandible_Table_Service.verifyTypologiesInserted(ahaGroup.Id);
        Arc_Gen_PotitionBankTable_Service.verifyDataInserted(ahaGroup.Id);
        if (ahaGroup.arce__analysis_template_id__c == HOTEL_SECTOR) {
            Arc_Gen_Analysis_Category_Service.insertTableRecord(ahaGroup.Id);
            Arc_Gen_Analysis_Date_Service.insertTableRecord(ahaGroup.Id);
            Arc_Gen_Contracts_Appraisals_Service.insertTableRecord(ahaGroup.Id);
        }

    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Method Split the arce configuration information
    *--------------------------------------------------------------------------------
    * @Author antonio.perez.hernandez.contractor@bbva.com
    * @Date 22/03/2023
    * @param arceConfigName - String with the Configuration Name
    * @return Configuration value splited

    * @example Arc_Gen_AnalysisWizard_Service.getSplittedMdtValue(arceConfigName)
    *--------------------------------------------------------------------------------
    **/
    public static List<String> getSplittedMdtValue(String arceConfigName) {
        return getStringFromArceConfig(arceConfigName).split(';');
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Method Get ARCE Configuration String value by Configuration Name
    *--------------------------------------------------------------------------------
    * @Author antonio.perez.hernandez.contractor@bbva.com
    * @Date 22/03/2023
    * @param arceConfigName - Name of the arce configuration
    * @return String - with the configuration value consulted
    * @example Arc_Gen_AnalysisWizard_Service.getStringFromArceConfig(arceConfigName)
    *--------------------------------------------------------------------------------
    **/
    public static String getStringFromArceConfig(String arceConfigName) {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(arceConfigName);
        String result;
        if (configs.isEmpty()) {
            result = '';
        } else {
            final arce__Arce_Config__mdt config = configs[0];
            result = String.valueOf(config.arce__Value1__c);
        }
        return result;
    }
}