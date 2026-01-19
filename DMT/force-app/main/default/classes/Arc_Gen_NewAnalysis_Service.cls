/**
  * @File Name          : Arc_Gen_NewAnalysis_Service.cls
  * @Description        : Service Class for newAnalysis
  * @Author             : lUISARTURO.PARRA.CONTACTOR@bbva.com
  * @Group              : ARCE
  * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
  * @Last Modified On   : 08-09-2024
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                 Modification
  *==============================================================================
  * 1.0    30/04/2019           eduardoefrain.hernandez.contractor@bbva.com     Initial Version
  * 1.1    02/04/2019           diego.miguel.contractor@bbva.com                Added logic to redirect to valid ARCE
  * 1.2    03/05/2019           diego.miguel.contractor@bbva.com                Added functions to save ARCE name AND subtype
  * 1.3    09/05/2019           diego.miguel.contractor@bbva.com                Added functions to redirect acording to ARCE satatus AND update status
  * 1.4    14/05/2019           diego.miguel.contractor@bbva.com                Added methods to groups ws support
  * 1.5    27/08/2019           luisruben.quinto.munoz@bbva.com                 deleted comment and reference to arce__parent_analysis_id__c
  * 1.6    27/08/2019           luisarturo.parra.contractor@bbva.com            refactorizacion
  * 1.7    04/12/2019           manuelhugo.castillo.contractor@bbva.com         Modify methods 'getPreviousArce','fillcustomedata' replace Account to AccountWrapper
  * 1.8    13/01/2020           mariohumberto.ramirez.contractor@bbva.com       Added new methods getPreviousArceOnline and setanalysis
  *                                                                             Deleted unused param analysisSubType
  *
  * 1.8    14/01/2020           juanmanuel.perez.ortiz.contractor@bbva.com      Add custom labels in traceability
  * 1.9    22/01/2020           juanmanuel.perez.ortiz.contractor@bbva.com      Add logic to fix customer orphan assigment
  * 1.10   29/01/2020           javier.soto.carrascosa@bbva.com                 Fix too many queries Financial Statements
  * 1.11   25/02/2020           juanignacio.hita.contractor@bbva.com            Added new methods to traceability
  * 1.12   09/03/2020           eduardoefrain.hernandez.contractor@bbva.com     adedd methods because of Indepentent Rating (RAIP)
  * 1.13   02/04/2020           joseluis.garcia4.contractor@bbva.com            Refactor of New Analysis + RAIP modal.
  * 1.14   08/04/2020           juanmanuel.perez.ortiz.contractor@bbva.com      Refactor of New Analysis, change methods from Arc_Gen_Analysis_Service_Helper to avoid problem in Sonar
  * 1.15   14/05/2020           joseluis.garcia4.contractor@bbva.com            Sets arce__customer_arce_scope_type__c field to '1' as default value.
  * 1.16   19/05/2020           joseluis.garcia4.contractor@bbva.com            Create RAIP in '01' status initially to support RAIP resumption.
  * 1.17   20/05/2020           juanignacio.hita.contractor@bbva.com            Added traceability for RAIP
  * 1.18   26/06/2020           joseluis.garcia4.contractor@bbva.com            Revert change introduced in 1.15.
  * 1.19   26/06/2020           juanignacio.hita.contractor@bbva.com            Add ambit current user to subprocess type in arce creation.
  * 1.20   02/07/2020           javier.soto.carrascosa@bbva.com                 Remove g-01 as record
  * 1.21   07/07/2020           juanignacio.hita.contractor@bbva.com            Added isHolding parameter n the AHA buildAccHasAnalysis creation method
  * 1.22   10/07/2020           ricardo.almanza.contractor@bbva.com             Modified buildAccHasAnalysis to add acc on manual triage.
  * 1.23   10/07/2020           javier.soto.carrascosa@bbva.com                 Add setTraceabilityStep1 because of missing traceability for orphans
  * 1.23   10/07/2020           javier.soto.carrascosa@bbva.com                 Modified configTriage for sectors
  * 1.24   11/08/2020           javier.soto.carrascosa@bbva.com                 Update sector field
  * 1.25   23/09/2020           saimassimilianno.jordana.contractor@bbva.com    Added arce. namespace to all classes that are now in the
  *                                                                             arce-dependencies package
  * 1.26   30/09/2020           eduardoefrain.hernandez.contractor@bbva.com     Set arce__persistance_callback_status_type__c field to AHA
  * 1.26   10/12/2020           juanignacio.hita.contractor@bbva.com            Add aha name (analysisId) param in traceability record
  * 1.27   16/12/2020           antonio.munoz.perez.contractor@bbva.com         Added Matrix Name and Matrix CIF population.
  * 1.28   20/01/2021           joseluis.garcia4.contractor@bbva.com            Refactor creationArce to reduce complexity.
  * 1.29   25/01/2021      saimassimilianno.jordana.contractor@bbva.com         modified buildAccHasAnalysis meth0d to work with CustomAccount.
  * 1.30   23/02/2021           juanignacio.hita.contractor@bbva.com            Added update of type analysis in the creation of arce
  * 1.31   11/03/2021           juanmanuel.perez.ortiz.contractor@bbva.com      Modified emptyIfNull and getIsHolding methods to be accessed from another methods
  * 1.32   10/05/2021           joseluis.garcia4.contractor@bbva.com            Create overlay records on ARCE creation.
  * 1.33   13/05/2021           brauliobaruchs.sanpedro.contractor@bbva.com     Modified params to add a new account has analysis to refresh
  * 1.34   01/09/2021           juanignacio.hita.contractor@bbva.com            Skip call to allocation package if running in tests
  * 1.35   19/11/2021           javier.soto.carrascosa@bbva.com                 Ensure territory and analysis name length
  * 1.36   24/01/2022           saimassimilianno.jordana.contractor@bbva.com    flowsFilterResult meth0d Added to get flows permissions.
  * 1.37   04/03/2022           amunguia@bbva.com                               the client type is a function of the participantType and is not always created
  *                                                                             as a subsidiary.
  * 1.38   24/01/2022           saimassimilianno.jordana.contractor@bbva.com    typeSelected parameter added to work with new SP2Analysis button.

  **/
@SuppressWarnings('sf:TooManyMethods, PMD.ExcessivePublicCount, PMD.ExcessiveParameterList')
public without sharing class Arc_Gen_NewAnalysis_Service {
    /**
    * @Description Subprocess type.
    */
    private static final String ARCTYPESEL = 'typeSelected';
    /**
    * @Description: Aha Group Header of the analysis
    */
    private static arce__Account_has_Analysis__c ahaGroupHeader {get; set;}
    /**
    * @Description "isCorp" literal.
    */
    private static final String ISCORP_LIT = 'isCorp';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_NewAnalysis_Service service = new Arc_Gen_NewAnalysis_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_NewAnalysis_Service() {

    }
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

      /**class type to save return data**/
      public class AnalysisResponse {
          /**
              * @Description: String analysisId
          */
          public String analysisId {get;set;}
          /**
              * @Description: String Account has analysis Id group
          */
          public String accAnalyGpId {get;set;}
          /**
              * @Description: String status
          */
          public String status {get;set;}
          /**
              * @Description: String errorMessage
          */
          public String errorMessage {get;set;}
      }

    /** Wrapper used for build account has analysis **/
    public class BuildAhaWrapper {
        /**
            * @Description: arce analysis object
        */
        public arce__Analysis__c arce {get;set;}
        /**
            * @Description: account wrapper object
        */
        public arce.Arc_Gen_Account_Wrapper accData {get;set;}
        /**
            * @Description: empty financial statements list
        */
        public List<arce__Financial_Statements__c> emptyFFSS {get;set;}
        /**
            * @Description: client type (Group, Client, Orphan)
        */
        public String clientType {get;set;}
        /**
            * @Description: is holding, matrix customer
        */
        public Boolean isHolding {get;set;}
        /**
            * @Description: matrix customer Name
        */
        public String mName {get;set;}
        /**
            * @Description: matrix customer docNumber
        */
          public String mDocNumber {get;set;}

        /**
        *--------------------------------------------------------------------------------
        * @Description Constructor BuildAha wrapper with analysis and account wrapper
        *--------------------------------------------------------------------------------
        * @param    arce__Analysis__c analysis
        * @param    arce.Arc_Gen_Account_Wrapper accountswraper - Wrapper that contains all account data
        * @example  new BuildAhaWrapper(arce, accData);
        * -------------------------------------------------------------------------------
        */
        public BuildAhaWrapper(arce__Analysis__c arceVar,arce.Arc_Gen_Account_Wrapper accData) {
            this.arce = arceVar;
            this.accData = accData;
        }
    }

    /** Wrapper used to provide parameters to ARCE creation methods. */
    private class ArceCreationParams {
        /**
            * @Description: list of initial dummy FFSS.
        */
        public List<arce__Financial_Statements__c> emptyFFSS { get; set; }
        /**
            * @Description: list of AHAs to create.
        */
        public List<arce__Account_has_Analysis__c> accHas2CreateLts { get; set; }
        /**
            * @Description: record type of the analysis
        */
        public Id analisysRecordTypeId { get; set; }
        /**
            * @Description: wrapper of the orphan account
        */
        public arce.Arc_Gen_Account_Wrapper orphanAcc { get; set; }
        /**
            * @Description: true if orphan
        */
        public Boolean checkOrphan { get; set; }
        /**
            * @Description: subprocess type of the analysis.
        */
        public String analysisSubType { get; set; }
        /**
            * @Description: Map of holding marks.
        */
        public String isHolding { get; set; }
        /**
            * @Description: Arce type selected.
        */
        public String typeSelected { get; set; }
        /**
            * @Description: is corporate.
        */
        public Boolean isCorp { get; set; }
    }
    /**
    * @Description: String with the word TOTAL
    */
    static final String TOTAL_S = 'TOTAL';
    /**
    *--------------------------------------------------------------------------------
    * @Description method that gets previous arce
    *--------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-13-01
    * @param    recordId - Id of the client
    * @param    String accountswraper - Wrapper that contains all account data
    * @return   Arc_Gen_NewAnalysis_Service_Helper.PreviousARCEData - Wrapper that contains all the Previous ARCE data
    * @example  getPreviousArceOnline(recordId)
    * -------------------------------------------------------------------------------
    */
    public static Arc_Gen_NewAnalysis_Service_Helper.PreviousARCEData getPreviousArceOnline(String recordId, String accountswraper, String arceType) {
        final String subprocessType = arceType == 'raip' || arceType == 'sp2Analysis' ? '4' : '2';

          return Arc_Gen_NewAnalysis_Service_Helper.getPreviousArceOnline(recordId, accountswraper, subprocessType);
      }
      /**
      *--------------------------------------------------------------------------------
      * @Description method that gets previous arce
      *--------------------------------------------------------------------------------
      * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
      * @Date     Created: 2020-13-01
      * @param    recordId - Id of the client
      * @param    isorphan - boolean
      * @param    orphanNumber - numbert of the orphan
      * @return   String
      * @example  setanalysis(recordId)
      * -------------------------------------------------------------------------------
      */
      @SuppressWarnings('sf:NPathComplexity')
      public static Arc_Gen_NewAnalysis_Service.AnalysisResponse setanalysis(Map<string,string> data) {
          final Boolean isorphan = Boolean.valueOf(data.get('isorphan'));
          final Boolean boolOrphan = isorphan == null ? false : isorphan;
          final String orphanNumber = data.get('orphanNumber');
          final String analysisType = data.get('analysisType');
          final String actualClientNum = data.get('actualClient');
          final String isHolding = data.get('isHolding');
          final Boolean isCorp = data.get('isCorp') == null ? false : Boolean.valueOf(data.get('isCorp'));

        Arc_Gen_NewAnalysis_Service.AnalysisResponse response = new Arc_Gen_NewAnalysis_Service.AnalysisResponse();
        final Map<String, Object> creationArceData = new Map<String, Object> {
            'analysisSubType'  => analysisType ,
            'actualClientNum'  => actualClientNum,
            'isCorp' => isCorp
        };
        if (boolOrphan) {
            final String arceTypeSlctd = data.get('typeSelected');
            final Map<String, arce.Arc_Gen_Account_Wrapper> orphan = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{orphanNumber});
            creationArceData.put('orphanAcc', orphan.get(orphanNumber));
            final List<arce__Analysis__c> arceLts = arce.Arc_Gen_ArceAnalysis_Data.getArcesFromAccounts(new List<Id>{orphan.get(orphanNumber).accId});
            if (arceLts.isEmpty()) {
                creationArceData.put('accounts', null);
                creationArceData.put('checkOrphan', true);
                creationArceData.put('isHolding', isHolding);
                creationArceData.put('typeSlcted', arceTypeSlctd);
                response = creationArce(creationArceData);
                setTraceabilityStep1(response, analysisType);
            }
        } else {
            final String arceTypeSlctd = data.get('typeSelected');
            final String accounts = data.get('accounts');
            final List<arce__Analysis__c> arceLts = arce.Arc_Gen_ArceAnalysis_Data.getArcesFromAccounts(getAccIdWrap(accounts));
            if (arceLts.isEmpty()) {
                creationArceData.put('accounts', accounts);
                creationArceData.put('checkOrphan', false);
                creationArceData.put('isHolding', isHolding);
                creationArceData.put('typeSlcted', arceTypeSlctd);
                response = creationArce(creationArceData);
                setTraceabilityStep1(response, analysisType);
            }
        }
        return response;
    }
    /**
    *--------------------------------------------------------------------------------
    * @Description method creation of arce
    *--------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-13-01
    * @param    orphanNumber - Account wrapper
    * @param    isorphan - boolean
    * @param    orphanNumber - numbert of the orphan
    * @return   String
    * @example  setanalysis(recordId)
    * -------------------------------------------------------------------------------
    */
    private static Arc_Gen_NewAnalysis_Service.AnalysisResponse creationArce(Map<String, Object> data) {
        final arce.Arc_Gen_Account_Wrapper orphanAcc = (arce.Arc_Gen_Account_Wrapper)data.get('orphanAcc');
        final String accounts = (String)data.get('accounts');
        final Boolean checkOrphan = Boolean.valueOf(data.get('checkOrphan'));
        final String analysisSubType = (String)data.get('analysisSubType');
        final String actualClientNum = (String)data.get('actualClientNum');
        final String isHolding = (String) data.get('isHolding');
        final String typeSlctd = (String) data.get('typeSlcted');
        final Boolean isCorp = Boolean.valueOf(data.get('isCorp'));

        final Arc_Gen_NewAnalysis_Service.AnalysisResponse response = new Arc_Gen_NewAnalysis_Service.AnalysisResponse();
        final List<arce__Account_has_Analysis__c> accHas2CreateLts = new List<arce__Account_has_Analysis__c>();
        final Id analisysRecordTypeId = Arc_Gen_NewAnalysis_data.getRecordTypes('arce__Analysis__c');
        List<arce__Analysis__c> newArceAnalysis = new List<arce__Analysis__c>();
        final List<arce__Financial_Statements__c> emptyFFSS = arce.Arc_Gen_FinancialStatements_locator.getEmptyFFSS();

        final ArceCreationParams params = new ArceCreationParams();
        params.emptyFFSS = emptyFFSS;
        params.accHas2CreateLts = accHas2CreateLts;
        params.analisysRecordTypeId = analisysRecordTypeId;
        params.orphanAcc = orphanAcc;
        params.checkOrphan = checkOrphan;
        params.analysisSubType = analysisSubType;
        params.isHolding = isHolding;
        params.typeSelected = typeSlctd;
        params.isCorp = isCorp;

        //checkOrphan
        if (checkOrphan) {
            newArceAnalysis = createArceAnalysis(orphanAcc, analisysRecordTypeId, checkOrphan, analysisSubType, typeSlctd);
            final Map<String, Object> mapParams = new Map<String, Object> {
                'newArceAnalysis' => newArceAnalysis,
                'accHas2CreateLts' => accHas2CreateLts,
                'groupWrapper' => null,
                'orphanAcc' => orphanAcc,
                'checkOrphan' => checkOrphan
            };
            insertRating(mapParams);
        } else if (analysisSubType == '4') {
            newArceAnalysis = creationArceRaip(params, actualClientNum);
        } else {
            newArceAnalysis = creationArceAnalysis(params, accounts);
        }
        createPretestLeveraged(accHas2CreateLts[0]);
        response.status = 'NUEVO';
        response.analysisId = newArceAnalysis[0].Id;
        response.accAnalyGpId = accHas2CreateLts[accHas2CreateLts.size() - 1].Id;

        Arc_Gen_NewAnalysis_data.updateArceName(newArceAnalysis[0].Id);
        Arc_Gen_NewAnalysis_data.updateTypeAnalysis(newArceAnalysis[0], accHas2CreateLts);
        return response;
    }

    /**
    *--------------------------------------------------------------------------------
    * @Description method creation of arce for RAIP
    *--------------------------------------------------------------------------------
    * @Author   José Luis García joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2021-01-19
    * @param    params - Parameters for the creation of the ARCE
    * @param    actualClientNum - number of the orphan
    * @return   Created analysis
    * -------------------------------------------------------------------------------
    */
    private static List<arce__Analysis__c> creationArceRaip(ArceCreationParams params, String actualClientNum) {
        // If RAIP
        final List<arce__Analysis__c> newArceAnalysis;
        final arce.Arc_Gen_Account_Wrapper actualClient = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String> { actualClientNum }).get(actualClientNum);
        if (actualClient == null) {
            throw new AuraHandledException(System.Label.Arc_Gen_Error_NoAccountWithNumber);
        }
        Boolean isCorp = params.isCorp;
        if(isCorp) {
            newArceAnalysis = createArceAnalysisCorp(actualClient, params);
        } else {
            newArceAnalysis = createArceAnalysis(actualClient, params.analisysRecordTypeId, params.checkOrphan, params.analysisSubType, params.typeSelected);
        }


        BuildAhaWrapper buildAhaWrapper = new BuildAhaWrapper(newArceAnalysis[0], actualClient);
        buildAhaWrapper.emptyFFSS = params.emptyFFSS;
        buildAhaWrapper.clientType = actualClient.participantType;
        buildAhaWrapper.isHolding = false;
        params.accHas2CreateLts.add(buildAccHasAnalysis(buildAhaWrapper));

        arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(params.accHas2CreateLts);
        final Map<String, Object> mapParams = new Map<String, Object> {
            'newArceAnalysis'  => newArceAnalysis        ,
            'accHas2CreateLts' => params.accHas2CreateLts,
            'groupWrapper'     => null                   ,
            'orphanAcc'        => params.orphanAcc       ,
            'checkOrphan'      => params.checkOrphan     ,
            'analysisSubType'  => params.analysisSubType
        };
        insertRating(mapParams);

        return newArceAnalysis;
    }

    /**
    *--------------------------------------------------------------------------------
    * @Description method creation of arce for analysis
    *--------------------------------------------------------------------------------
    * @Author   José Luis García joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2021-01-19
    * @param    params - Parameters for the creation of the ARCE
    * @param    accounts - participants of the analysis
    * @return   Created analysis
    * -------------------------------------------------------------------------------
    */
    private static List<arce__Analysis__c> creationArceAnalysis(ArceCreationParams params, String accounts) {
        // If analysis
        final List<arce.Arc_Gen_Account_Wrapper> accountsWrapLts = (List<arce.Arc_Gen_Account_Wrapper>) JSON.deserialize(accounts, List<arce.Arc_Gen_Account_Wrapper>.Class);
        final arce.Arc_Gen_Account_Wrapper groupWrapper = accountsWrapLts[accountsWrapLts.size() - 1];
        final List<arce__Analysis__c> newArceAnalysis = createArceAnalysis(groupWrapper, params.analisysRecordTypeId, params.checkOrphan, params.analysisSubType, params.typeSelected);
        final Map<String, Boolean> mapIsHolding = (Map<String, Boolean>) JSON.deserialize(params.isHolding, Map<String, Boolean>.Class);

        String mName = ''; //Matrix Name
        String mDocNumber = ''; //Matrix CIF
        for (arce.Arc_Gen_Account_Wrapper acw : accountsWrapLts) {
            if (mapIsHolding.get(acw.accNumber) != null && mapIsHolding.get(acw.accNumber)) {
                mName = acw.Name;
                mDocNumber = acw.docNumber;
            }
        }

        // Creation subsidiary
        for (integer i = 0; i < accountsWrapLts.size() - 1; i++) {
            final Boolean holdingValue = mapIsHolding.get(accountsWrapLts[i].accNumber);
            BuildAhaWrapper buildAhaWrapper = new BuildAhaWrapper(newArceAnalysis[0], accountsWrapLts[i]);
            buildAhaWrapper.emptyFFSS = params.emptyFFSS;
            buildAhaWrapper.clientType = arce.Arc_Gen_Constants.SUBSID_S;
            buildAhaWrapper.isHolding = holdingValue;
            buildAhaWrapper.mName = mName;
            buildAhaWrapper.mDocNumber = mDocNumber;
            params.accHas2CreateLts.add(buildAccHasAnalysis(buildAhaWrapper));
        }
        // Creation group client
        BuildAhaWrapper buildAhaWrapper = new BuildAhaWrapper(newArceAnalysis[0], groupWrapper);
        buildAhaWrapper.emptyFFSS = params.emptyFFSS;
        buildAhaWrapper.clientType = arce.Arc_Gen_Constants.S_GROUP;
        buildAhaWrapper.isHolding = false;
        buildAhaWrapper.mName = mName;
        buildAhaWrapper.mDocNumber = mDocNumber;
        params.accHas2CreateLts.add(buildAccHasAnalysis(buildAhaWrapper));

        arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(params.accHas2CreateLts);
        final Map<String, Object> mapParams = new Map<String, Object> {
            'newArceAnalysis'  => newArceAnalysis ,
            'accHas2CreateLts' => params.accHas2CreateLts,
            'groupWrapper'     => groupWrapper           ,
            'orphanAcc'        => params.orphanAcc       ,
            'checkOrphan'      => params.checkOrphan     ,
            'analysisSubType'  => params.analysisSubType
        };
        insertRating(mapParams);

        return newArceAnalysis;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description method that organize the customer data in wrapper class
    *-------------------------------------------------------------------------------
    * @Date 12/09/2019
    * @Author luisarturo.parra.contractor@bbva.com
    * @param Account firstaccountanalized
    * @param client type group or customer
    * @return List<arce__Analysis__c> type class
    * @example private SaveResponse createarcefromcustomer(accData, analisysRecordTypeId, isorphan)
    * ------------------------------------------------------------------------------
    */
    private static List<arce__Analysis__c> createArceAnalysis(arce.Arc_Gen_Account_Wrapper accData, Id recordTypeId, Boolean isorphan, String analysisSubType, String typeSlctd) {
        final arce.Arc_Gen_User_Wrapper wrpUserCurrent = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        final boolean noPermissionCreate = !customerAllocation(accData.accId);
        if (noPermissionCreate) {
            NewAnalysisException excp = new NewAnalysisException();
            excp.setMessage(System.Label.Customer_Allocation_Error_1);
            throw excp;
        }

        arce__Analysis__c newAnalysis = new arce__Analysis__c();
        newAnalysis.Name = Arc_Gen_Persistence_Utils.cutString(accData.name,80);
        newAnalysis.arce__Group__c = accData.accId;
        newAnalysis.arce__Stage__c = newAnalysis.arce__anlys_wkfl_stage_type__c = '1';
        // Even in RAIP, set to '01' until the ARCE has been correctly persisted and triage call has been successful.
        newAnalysis.arce__wf_status_id__c = newAnalysis.arce__anlys_wkfl_status_stage_type__c = '01';
        newAnalysis.arce__raip_wkfl_stage_type__c = getRaipStageType(analysisSubType);
        newAnalysis.arce__raip_wkfl_status_stage_type__c = getRaipStatusStageType(analysisSubType);
        newAnalysis.arce__analysis_customer_relation_type__c = getAnalysisCustomerRelationType(isorphan);
        newAnalysis.arce__anlys_wkfl_sub_process_type__c = analysisSubType;
        newAnalysis.arce__anlys_wkfl_edit_br_level_type__c = wrpUserCurrent.ambitUser;
        newAnalysis.RecordTypeId = recordTypeId;
        newAnalysis.OwnerId = userinfo.getuserId();
        newAnalysis.arce__anlys_arce_type__c = getAnalysisArceType(analysisSubType, isorphan);
        newAnalysis.arce__analysis_type_selected__c = getAnalysisTypeSelected(newAnalysis.arce__anlys_arce_type__c, typeSlctd);
        newAnalysis.arce__territory_name__c = Arc_Gen_Persistence_Utils.cutString(wrpUserCurrent.territory, 255);
        newAnalysis.arce__is_prospect__c = String.isNotBlank(String.valueOf(accData.isProspect)) && accData.isProspect ? '1' : '0';
        return arce.Arc_Gen_ArceAnalysis_Data.insertArce(new List<arce__Analysis__c>{newAnalysis});
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description method that create ARCE records to corporate flow
    *-------------------------------------------------------------------------------
    * @Date 28/09/2023
    * @Author alberto.martinez.carrero.next@bbva.com
    * @param  accData - account wrapper
    * @param  params - Parameters for the creation of the ARCE
    * @return List<arce__Analysis__c> type class
    * @example private SaveResponse createArceAnalysisCorp(accData, params)
    * ------------------------------------------------------------------------------
    */
    private static List<arce__Analysis__c> createArceAnalysisCorp(arce.Arc_Gen_Account_Wrapper accData, ArceCreationParams params) {
        Id recordTypeId = params.analisysRecordTypeId;
        Boolean isorphan = params.checkOrphan;
        String analysisSubType = params.analysisSubType;
        String typeSlctd = params.typeSelected;
        Boolean isCorp = params.isCorp;

        final arce.Arc_Gen_User_Wrapper wrpUserCurrent = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        final boolean noPermissionCreate = !customerAllocation(accData.accId);
        if (noPermissionCreate) {
            NewAnalysisException excp = new NewAnalysisException();
            excp.setMessage(System.Label.Customer_Allocation_Error_1);
            throw excp;
        }

        arce__Analysis__c newAnalysis = new arce__Analysis__c();
        newAnalysis.Name = Arc_Gen_Persistence_Utils.cutString(accData.name,80);
        newAnalysis.arce__Group__c = accData.accId;
        newAnalysis.arce__Stage__c = newAnalysis.arce__anlys_wkfl_stage_type__c = '1';
        // Even in RAIP, set to '01' until the ARCE has been correctly persisted and triage call has been successful.
        newAnalysis.arce__wf_status_id__c = newAnalysis.arce__anlys_wkfl_status_stage_type__c = '01';
        newAnalysis.arce__raip_wkfl_stage_type__c = getRaipStageType(analysisSubType);
        newAnalysis.arce__raip_wkfl_status_stage_type__c = getRaipStatusStageType(analysisSubType);
        newAnalysis.arce__analysis_customer_relation_type__c = getAnalysisCustomerRelationType(isorphan);
        newAnalysis.arce__anlys_wkfl_sub_process_type__c = analysisSubType;
        newAnalysis.arce__anlys_wkfl_edit_br_level_type__c = wrpUserCurrent.ambitUser;
        newAnalysis.RecordTypeId = recordTypeId;
        newAnalysis.OwnerId = userinfo.getuserId();
        newAnalysis.arce__anlys_arce_type__c = getAnalysisArceType(analysisSubType, isorphan);
        newAnalysis.arce__analysis_type_selected__c = getAnalysisTypeSelected(newAnalysis.arce__anlys_arce_type__c, typeSlctd);
        newAnalysis.arce__territory_name__c = Arc_Gen_Persistence_Utils.cutString(wrpUserCurrent.territory, 255);
        newAnalysis.arce__is_prospect__c = String.isNotBlank(String.valueOf(accData.isProspect)) && accData.isProspect ? '1' : '0';
        newAnalysis.arce__is_RTC__c = isCorp;
        return arce.Arc_Gen_ArceAnalysis_Data.insertArce(new List<arce__Analysis__c>{newAnalysis});
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Returns the value to set on the arce__anlys_arce_type__c field
    *-------------------------------------------------------------------------------
    * @Date 2023-01-23
    * @Author antonio.vazquez.aguado.contractor@bbva.com
    * @param String analysisSubType
    * @param Boolean isorphan
    * @return String the value of the arce__anlys_arce_type__c field
    * ------------------------------------------------------------------------------
    */
    private static String getAnalysisArceType(String analysisSubType, Boolean isorphan) {
        return analysisSubType == '4' ? '4' : isOrphan == true ? '3' : '1';
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Returns the value to set on the arce__analysis_type_selected__c field
    *-------------------------------------------------------------------------------
    * @Date 2023-01-23
    * @Author antonio.vazquez.aguado.contractor@bbva.com
    * @param String analysisArceType
    * @param Boolean isorphan
    * @return String the value of the arce__analysis_type_selected__c field
    * ------------------------------------------------------------------------------
    */
    private static String getAnalysisTypeSelected(String analysisArceType, String typeSlctd) {
        return String.isBlank(typeSlctd) ? analysisArceType == '4' ? 'raip' : 'analysis' : typeSlctd;
    }
    /**
    *--------------------------------------------------------------------------------
    * @Description method insert rating
    *--------------------------------------------------------------------------------
    * @Author   Juan Ignacio Hita - juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2020-03-05
    * @param    mapParams - Map of params
    * @return   void
    * @example  insertRating(mapParams);
    * -------------------------------------------------------------------------------
    */
    private static void insertRating(Map<String, Object> mapParams) {
        final List<arce__Analysis__c> newArceAnalysis = (List<arce__Analysis__c>) mapParams.get('newArceAnalysis');
        final List<arce__Account_has_Analysis__c> accHas2CreateLts = (List<arce__Account_has_Analysis__c>) mapParams.get('accHas2CreateLts');
        final Boolean checkOrphan = (Boolean) mapParams.get('checkOrphan');
        final String analysisSubType = (String)mapParams.get('analysisSubType');

        final List < arce__rating_variables_detail__c > ratingVariablesLts = new List <arce__rating_variables_detail__c> ();
        final List<arce__Financial_Statements__c> emptyFFSS = arce.Arc_Gen_FinancialStatements_locator.getEmptyFFSS();
        final List<arce__Overlay__c> overlayObjs;

        if (checkOrphan) {
            final arce.Arc_Gen_Account_Wrapper orphanAcc = (arce.Arc_Gen_Account_Wrapper) mapParams.get('orphanAcc');
            BuildAhaWrapper buildAhaWrapper = new BuildAhaWrapper(newArceAnalysis[0], orphanAcc);
            buildAhaWrapper.emptyFFSS = emptyFFSS;
            buildAhaWrapper.clientType = arce.Arc_Gen_Constants.ORPHAN;
            buildAhaWrapper.isHolding = false;
            accHas2CreateLts.add(buildAccHasAnalysis(buildAhaWrapper));
            arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(accHas2CreateLts);
            ratingVariablesLts.add(arce.Arc_Gen_Rating_Var_detail_Data.setEmptyRatingVariable(accHas2CreateLts[0].Id));
        } else if(analysisSubType == '2' || analysisSubType == '3') {
            final arce.Arc_Gen_Account_Wrapper groupWrapper = (arce.Arc_Gen_Account_Wrapper) mapParams.get('groupWrapper');
            BuildAhaWrapper buildAhaWrapper = new BuildAhaWrapper(newArceAnalysis[0], groupWrapper);
            buildAhaWrapper.emptyFFSS = emptyFFSS;
            buildAhaWrapper.clientType = arce.Arc_Gen_Constants.S_GROUP;
            buildAhaWrapper.isHolding = false;
            accHas2CreateLts.add(buildAccHasAnalysis(buildAhaWrapper));
            for (arce__Account_has_Analysis__c accHas: accHas2CreateLts) {
                ratingVariablesLts.add(arce.Arc_Gen_Rating_Var_detail_Data.setEmptyRatingVariable(accHas.Id));
            }
        }
        overlayObjs = createOverlays(accHas2CreateLts);

        arce.Arc_Gen_Rating_Var_detail_Data.insertRatingVariables(ratingVariablesLts);
        insert overlayObjs;
    }

    /**
    *--------------------------------------------------------------------------------
    * @Description creates overlay records for rating if overlays are enabled.
    *--------------------------------------------------------------------------------
    * @Author   José Luis García Díaz - joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2021-04-22
    * @param    accHas2CreateLts - List of account has analysis records.
    * @return   list of overlays.
    * -------------------------------------------------------------------------------
    */
    private static List<arce__Overlay__c> createOverlays(List<arce__Account_has_Analysis__c> accHas2CreateLts) {
        // Check if overlays enabled.
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('EnableOverlays');
        Boolean overlaysEnabled = configs.isEmpty() ? false : Boolean.valueOf(configs[0].arce__Value1__c);

        final List<arce__Overlay__c> overlayObjs = new List<arce__Overlay__c>();
        if (overlaysEnabled) {
            for (arce__Account_has_Analysis__c aha : accHas2CreateLts) {
                overlayObjs.add(arce.Arc_Gen_Overlays_Utils.createOverlay(aha.Id));
            }
        }
        return overlayObjs;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description method that organize the customer data in wrapper class
    *-------------------------------------------------------------------------------
    * @Date 12/09/2019
    * @Author luisarturo.parra.contractor@bbva.com
    * @param arce__Analysis__c analysis
    * @param arce.Arc_Gen_Account_Wrapper account wrapper
    * @param List<arce__Financial_Statements__c> emptyFFSS
    * @param client type group or customer
    * @param isHolding boolean
    * @return arce__Account_has_Analysis__c type class
    * @example buildAccHasAnalysis()
    * ------------------------------------------------------------------------------
    */
    public static arce__Account_has_Analysis__c buildAccHasAnalysis(BuildAhaWrapper wrapper) {
        final arce__Analysis__c arceVar = wrapper.arce;
        final arce.Arc_Gen_Account_Wrapper accData = wrapper.accData;
        final String clientType = wrapper.clientType;
        final Boolean isHolding = wrapper.isHolding;
        final String mName = emptyIfNull(wrapper.mName);
        final String mDocNumber = emptyIfNull(wrapper.mDocNumber);
        final arce__Account_has_Analysis__c newAccHasAn = new arce__Account_has_Analysis__c();
        final arce__AHA_Extension__c newAHAExt = new arce__AHA_Extension__c();
        insert newAHAExt;

        newAccHasAn.arce__Analysis__c = arceVar.Id;
        newAccHasAn.arce__Customer__c = accData.accId;
        newAccHasAn.arce__customer_arce_scope_type__c = '1';
        newAccHasAn.arce__anlys_wkfl_cnsld_ffss_type__c = '1';
        newAccHasAn.arce__AHA_Extension__c = newAHAExt.Id;
        // if customAccount field is filled then use it.
        if(!String.isBlank(accData.customAccount)) {
            newAccHasAn.arce__CustomAccountID__c = accData.customAccount;
        }
        newAccHasAn.arce__InReview__c = getInReview(clientType, arceVar);
        newAccHasAn.arce__participant_name__c = Arc_Gen_Persistence_Utils.cutString(accData.name,75);
        if (clientType == arce.Arc_Gen_Constants.S_GROUP) {
            newAccHasAn.arce__group_risk_detail_part_name__c = TOTAL_S;
            newAccHasAn.arce__group_asset_header_type__c = '1';
        } else {
            newAccHasAn.arce__group_risk_detail_part_name__c = accData.name;
            newAccHasAn.arce__group_asset_header_type__c = '2';
        }
        newAccHasAn.arce__anlys_wkfl_sbanlys_status_type__c = '1';
        configTriage(newAccHasAn, arceVar);
        newAccHasAn.arce__ffss_for_rating_id__c = getRatingId(wrapper.emptyFFSS);
        newAccHasAn.arce__main_subsidiary_ind_type__c = getIsHolding(isHolding);
        newAccHasAn.arce__persistance_callback_status_type__c = '4';
        if(String.isNotBlank(accData.lookupName)) {
            try {
                newAccHasAn.put(accData.lookupName,accData.customAccount);
            } catch(Exception e) {
                System.debug('There is no field <'+accData.lookupName+'> in AccountHasAnalysis');
            }
        }
        newAccHasAn.arce__gf_matrix_house_name__c = mName;
        newAccHasAn.arce__gf_matrix_house_cif_id__c = mDocNumber;
        return newAccHasAn;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Returns empty string if parameter is null.
    *-------------------------------------------------------------------------------
    * @date 09/02/2021
    * @author joseluis.garcia4.contractor@bbva.com
    * @param str - String to check
    * @return the original string or the empty string if null
    */
    public static String emptyIfNull(String str) {
        return String.isBlank(str) ? '' : str;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method configure triage
    *-------------------------------------------------------------------------------
    * @date 22/07/2020
    * @author juanignacio.hita.contractor@bbva.com
    * @param arce__Account_has_Analysis__c newAccHasAn
    * @param arce__Analysis__c arce
    * @return void
    * @example configTriage(newAccHasAn, arce);
    */
    private static void configTriage(arce__Account_has_Analysis__c newAccHasAn, arce__Analysis__c arceVar) {
        final arce__Account_has_Analysis__c parAnalysis;
        try {
            parAnalysis = Arc_Gen_PersistanceArceId_data.persistanceDataAcc(arceVar.Id);
        } catch (QueryException qex) {
            parAnalysis = new arce__Account_has_Analysis__c();
            parAnalysis.arce__anlys_wkfl_cnsld_ffss_type__c = '1';
            parAnalysis.arce__analysis_template_id__c = '1';
        }
        newAccHasAn.arce__anlys_wkfl_cnsld_ffss_type__c = parAnalysis.arce__anlys_wkfl_cnsld_ffss_type__c;
        newAccHasAn.arce__analysis_template_id__c = parAnalysis.arce__analysis_template_id__c;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that return rating id
    *-------------------------------------------------------------------------------
    * @date 22/07/2020
    * @author juanignacio.hita.contractor@bbva.com
    * @param List<arce__Financial_Statements__c> emptyFFSS
    * @return Value rating id
    * @example String idSelected = getRatingId(emptyFFSS);
    */
    private static String getRatingId(List<arce__Financial_Statements__c> emptyFFSS) {
        return emptyFFSS.isEmpty() ? arce.Arc_Gen_FinancialStatements_locator.setFFSS().Id : emptyFFSS[0].Id;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that get the isHolding value
    *-------------------------------------------------------------------------------
    * @date 22/07/2020
    * @author juanignacio.hita.contractor@bbva.com
    * @param Boolean isHolding
    * @return Value of isHolding
    * @example Boolean newVal = getIsHolding(isHolding);
    */
    public static Boolean getIsHolding(Boolean isHolding) {
        return isHolding == null ? false : isHolding;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that calls customer allocation service and validates the permission
    *-------------------------------------------------------------------------------
    * @date 09/09/2019
    * @author antonio.munoz.perez.contractor@bbva.com
    * @param String customerId - Customer Id
    * @return Boolean - result of the customer allocation validations
    * @example public static Boolean customerAllocation(Id customerId)
    */
    public static Boolean customerAllocation(Id customerId) {
        final List<ID> records = new List<ID>();
        records.add(customerId);
        final Type inter = Type.forName('arcealloc.Allocation_Service');
        Return String.isNotBlank(String.valueOf(inter)) && !Test.isRunningTest() ? ((Map<Id,boolean>) ((Callable) inter.newInstance()).call('checkBulkCreationPrivilegesFromAcc', new Map<String, Object> {'accIdsLst' => records})).get(customerId) : true ;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description method that returns if the client is in the carousel
    *-------------------------------------------------------------------------------
    * @Date 01/04/2020
    * @Author eduardoefrain.hernandez.contractor@bbva.com
    * @param String clientType - Indicates if the cliente is a group, a subsidiary or an orphan
    * @param arce__Analysis__c arce - ARCE analysis record
    * @return String - Indicates if the cliente is a group or an orphan
    * @example getInReview(String clientType, String participantType)
    * ------------------------------------------------------------------------------
    */
    private static Boolean getInReview(String clientType, arce__Analysis__c arceVar) {
        Return clientType == arce.Arc_Gen_Constants.S_GROUP || clientType == arce.Arc_Gen_Constants.ORPHAN || arceVar.arce__anlys_wkfl_sub_process_type__c == '4' ? true : false;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Returns the value to set on the arce__analysis_customer_relation_type__c field
    *-------------------------------------------------------------------------------
    * @Date 16/03/2020
    * @Author joseluis.garcia4.contractor@bbva.com
    * @param Boolean isOrphan
    * @return String the value of the arce__analysis_customer_relation_type__c field
    * ------------------------------------------------------------------------------
    */
    private static String getAnalysisCustomerRelationType(Boolean isOrphan) {
        return isOrphan == true ? '02' : '01';
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Returns the value to set on the arce__raip_wkfl_stage_type__c field
    *-------------------------------------------------------------------------------
    * @Date 16/03/2020
    * @Author joseluis.garcia4.contractor@bbva.com
    * @param String analysisSubType
    * @return String the value of the arce__raip_wkfl_stage_type__c field
    * ------------------------------------------------------------------------------
    */
    private static String getRaipStageType(String analysisSubType) {
        return analysisSubType == '4' ? '1' : '';
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Returns the value to set on the arce__raip_wkfl_status_stage_type__c field
    *-------------------------------------------------------------------------------
    * @Date 16/03/2020
    * @Author joseluis.garcia4.contractor@bbva.com
    * @param String analysisSubType
    * @return String the value of the arce__raip_wkfl_status_stage_type__c field
    * ------------------------------------------------------------------------------
    */
    private static String getRaipStatusStageType(String analysisSubType) {
        return analysisSubType == '4' ? '01' : '';
    }
    /**
    *--------------------------------------------------------------------------------
    * @Description method that return a list of id of the accounts
    *--------------------------------------------------------------------------------
    * @Author   Juan Ignacio Hita - juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2020-03-05
    * @param    accounts - String JSON serialize with the accounts
    * @return   List<Id>
    * @example  List<Id> lstId = getAccIdWrap(accounts)
    * -------------------------------------------------------------------------------
    */
    private static List<Id> getAccIdWrap(String accounts) {
        final List<Id> accIds = new List<Id>();
        final List<arce.Arc_Gen_Account_Wrapper> accountsWrapLts = (List<arce.Arc_Gen_Account_Wrapper>) JSON.deserialize(accounts, List<arce.Arc_Gen_Account_Wrapper>.Class);
        for (integer i = 0; i < accountsWrapLts.size() - 1; i++) {
            accIds.add(accountsWrapLts[i].accId);
        }
        return accIds;
    }
    /**
    *--------------------------------------------------------------------------------
    * @Description method saves traceability step 1
    *--------------------------------------------------------------------------------
    * @Author   javier.soto.carrascosa@bbva.com
    * @Date     Created: 2020-07-14
    * @param    Arc_Gen_NewAnalysis_Service.AnalysisResponse response
    * @param    String analysisType
    * @return   void
    * @example  setTraceabilityStep1(response, analysisType)
    * -------------------------------------------------------------------------------
    */
    private static void setTraceabilityStep1(Arc_Gen_NewAnalysis_Service.AnalysisResponse response, String analysisType) {
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        final String anlysTypeStr = arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__analysis__c', 'arce__anlys_wkfl_sub_process_type__c', analysisType);
        String traceComments = '';
        String traceTitle = '';
        arce__Account_has_Analysis__c accHasAnalysis = new arce__Account_has_Analysis__c();
        if (analysisType == arce.Arc_Gen_Constants.SUBPROCESS_NEW) {
            traceComments = Label.Arc_Gen_TraceabilityOffice + ': ' + wrpUser.branchText.abbreviate(60) + ' | ' + Label.Arc_Gen_TraceabilitySubprocess + ': ' + anlysTypeStr;
            traceTitle = System.Label.Arc_Gen_Traceability_01;
            accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAhaGroupOfArce(response.analysisId);
        } else if (analysisType == arce.Arc_Gen_Constants.SUBPROCESS_RATING) {
            traceComments = Label.Arc_Gen_TraceabilitySubprocess + ': ' + anlysTypeStr;
            traceTitle = System.Label.Arc_Gen_Traceability_01_RAIP;
            final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{response.analysisId});
            accHasAnalysis = ahaList[0];
        }
        final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(traceTitle, 'approve', traceComments.abbreviate(255), accHasAnalysis.Name);
        final Map<String, String> auditWF = new Map<String, String>();
        Arc_Gen_Traceability.saveTrace(response.analysisId, auditAttr, auditWF);
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Get allowed flows by profiling.
    *-------------------------------------------------------------------------------
    * @Author saimassimilianno.jordana.contractor@bbva.com | 24/01/2022
    * @return String.
    * @Example Arc_Gen_NewAnalysis_Service.flowsFilterResult(clientId, activeFlws)
    *-------------------------------------------------------------------------------
    */
    public static String flowsFilterResult(String clientId, String activeFlws) {
        String toReturn = activeFlws;
        //getting IRP profiling permission.
        if (!arce.Arc_Gen_GetPermissions_Locator.irpEnabler(clientId)) {
            toReturn = toReturn.remove('IRP');
        }

        //getting ARP profiling permission.
        if (!arce.Arc_Gen_GetPermissions_Locator.arpEnabler(clientId)) {
            toReturn = toReturn.remove('ARP');
        }

        //getting CRP profiling permission.
        if (!arce.Arc_Gen_GetPermissions_Locator.crpEnabler(clientId)) {
            toReturn = toReturn.remove('CRP');
        }

        return toReturn;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Get allowed flows by profiling.
    *-------------------------------------------------------------------------------
    * @Author saimassimilianno.jordana.contractor@bbva.com | 24/01/2022
    * @return String.
    * @Example Arc_Gen_NewAnalysis_Service.arpGroup(clientId, activeFlws)
    *-------------------------------------------------------------------------------
    */
    public static String arpGroup(String clientId, String activeFlws) {
        String toReturn;

        //ARP-ClientGroup behavior
        final arce.Arc_Gen_Account_Wrapper actualClient = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<String> { clientId }).get(clientId);
        final Boolean groupClient = actualClient.participantType == 'GROUP';
        toReturn = groupClient ? activeFlws.remove('ARP') : activeFlws;

        return toReturn;
    }
    /**
    *------------------------------------------------------------------------------------------------------------
    * @description Create Leveraged Record basic structure
    *------------------------------------------------------------------------------------------------------------
    * @Author joseluis.miralles.contractor@bbva.com
    * @Date 12/06/2024
    * @param arce__Account_has_Analysis__c aha record
    * -----------------------------------------------------------------------------------------------------------
    */
    public static void createPretestLeveraged(arce__Account_has_Analysis__c ahaId) {
        final List<arce__Arce_Config__mdt> arceConfList = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('Is_Corporate');
        if (!arceConfList.isEmpty() && Boolean.valueOf(arceConfList[0].arce__Value1__c)) {
            arce__Leveraged__c leverReco = new arce__Leveraged__c ();
            leverReco.arce__Account_has_Analysis_Id__c = ahaId.Id;
            leverReco.arce__Arc_Gen_Type__c = '1';
            leverReco.arce__Arc_Gen_Leveraged_Record_Type__c = 'PRE_LEVERAGED';
            Database.insert(leverReco, AccessLevel.SYSTEM_MODE);
        }
    }

}