/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_NewAnalysis_Service_Helper
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-13-01
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Helper class for Arc_Gen_NewGroups_service.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-13-01 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-08-02 ricardo.almanza.contractor@bbva.com
*             Added Orphan
* |2020-08-28 juanignacio.hita.contractor@bbva.com
*             Added traceability in the method "setanalysis"
* |2020-03-09 eduardoefrain.hernandez.contractor@bbva.com
*             updated methods because of Indepentent Rating (RAIP)
* |2020-03-05 juanignacio.hita.contractor@bbva.com
*             Refactoring method "setAnalysis"
* |2020-03-30 eduardoefrain.hernandez.contractor@bbva.com
*             Add getSector method to choose the group or subsidiary sector in AccHasAnalysis
* |2020-04-01 eduardoefrain.hernandez.contractor@bbva.com
*             Change participant Type of RAIP from Group to Subsidiary
* |2020-04-02 joseluis.garcia4.contractor@bbva.com
*             Refactor of New Analysis + RAIP modal.
* |2020-04-05 ricardo.almanza.contractor@bbva.com
*             Refactoring method "getPreviousArceOnline"
* |2020-04-17 joseluis.garcia4.contractor@bbva.com
*             Fixes bug of RAIP creation on a group when one exists for a client, add change to recover subprocess label
* |2020-04-21 joseluis.garcia4.contractor@bbva.com
*             Allows RAIP creation even if no group structure is provided.
* |2020-05-04 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add new variables in PreviousARCEData method, modified getPreviousArceOnline to add modification ARCE flow logic
* |2020-05-05 juanmanuel.perez.ortiz.contractor@bbva.com
*             Create method called getArceData() and getAccHasAnaType() to avoid complexity error
* |2020-05-29 juanmanuel.perez.ortiz.contractor@bbva.com
*             Resolve issue on blocking start RAIP from group
* |2020-08-12 mariohumberto.ramirez.contractor@bbva.com
*             Added support for hu Renovation
* |2021-01-25 saimassimilianno.jordana.contractor@bbva.com
*             Modified getArceData meth0d to work with Custom Account.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-04-20 juanignacio.hita.contractor@bbva.com
*             Added getLocalCountryValue method
* |2021-10-27 francisco.munoz.torres.contractor@bbva.com
*             When recovering the last sanctioned ARCE, the expired and unexpired are included in the same step
* |2022-02-09 juanignacio.hita.contractor@bbva.com
*             Add fillAccountData method and modifiedStrucGroup for detect changes group structure over previous analysis
* |2022-03-31 juanignacio.hita.contractor@bbva.com
*             Add arceExistingId in wrapper and created getLatestArceRevoked method that invokes getPreviousArceOnline
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods, PMD.ExcessivePublicCount, sf:TooManyFields')
public with sharing class Arc_Gen_NewAnalysis_Service_Helper {
    /**
    * @Description Subprocess type of RAIP.
    */
    private static final String RAIP_SUBPROCESS_TYPE = '4';
    /**
    * @Description Local user config arce config name
    */
    public static final String LOCALUSER = 'LocalUserConfig';
    /**
        * @Description: Locator config arce config record of custom metadata
    */
    private final static String LOCATOR_CNF = 'LocatorARCEConfig';

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-13-01
    * @param void
    * @return void
    * @example Arc_Gen_NewAnalysis_Service_Helper helper = new Arc_Gen_NewAnalysis_Service_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    private Arc_Gen_NewAnalysis_Service_Helper() {

    }

    /**
    * @Class: PreviousARCEData
    * @Description: Wrapper that contain the data of a previously created ARCE
    * @author BBVA
    */
    public class PreviousARCEData {
        /**
        * @Description: Standard Id of the ARCE Analysis
        */
        @AuraEnabled public String idARCE {get;set;}
        /**
        * @Description: Workflow status of the Analysis
        */
        @AuraEnabled public String wfStatus {get;set;}
        /**
        * @Description: Number of the customer
        */
        @AuraEnabled public String accountNumber {get;set;}
        /**
        * @Description: Number of the bank
        */
        @AuraEnabled public String bankId {get;set;}
        /**
        * @Description: Standard Id of the customer account
        */
        @AuraEnabled public String accountId {get;set;}
        /**
        * @Description: Standard Id of the analyzed client chrome
        */
        @AuraEnabled public String accHasAnalysisId {get;set;}
        /**
        * @Description: Indicates if the analysis is of a group or an orphan customer
        */
        @AuraEnabled public String accHasAnaType {get;set;}
        /**
        * @Description: Indicates the subprocess of the ARCE (New, Modification, Renovation, Rating)
        */
        @AuraEnabled public String subProcess {get;set;}
        /**
        * @Description: Workflow stage of the Analysis
        */
        @AuraEnabled public String wfStage {get;set;}
        /**
        * @Description: Sanction type of the ARCE
        */
        @AuraEnabled public String sanctionType {get;set;}
        /**
        * @Description: Sanction type of the ARCE
        */
        @AuraEnabled public Date expiryDate {get;set;}
        /**
        * @Description: valid for renovation
        */
        @AuraEnabled public Boolean renovation {get;set;}
        /**
        * @Description: valid for modification
        */
        @AuraEnabled public Boolean modification {get;set;}
        /**
        * @Description: modification is active?
        */
        @AuraEnabled public Boolean modIsActive {get;set;}
        /**
        * @Description: renovation is active?
        */
        @AuraEnabled public Boolean renIsActive {get;set;}
        /**
        * @Description: changes in group structure over previous analysis?
        */
        @AuraEnabled public Boolean modifiedStrucGroup {get;set;}
        /**
        * @Description: redirect
        */
        @AuraEnabled public Boolean redirectRevoke {get;set;}
        /**
        * @Description: Arce id new existing in mod/renov process
        */
        @AuraEnabled public String arceExistingId {get;set;}
    }
    /**
    *--------------------------------------------------------------------------------
    * @Description method that gets previous arce
    *--------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-13-01
    * @param    recordId - Id of the client
    * @return   List<String>
    * @example  getPreviousArceOnline(recordId)
    * -------------------------------------------------------------------------------
    */
    public static PreviousARCEData getPreviousArceOnline(String recordId, String accountswraper, String subprocessType) {
        final List<Id> accIds = new List<Id>();
        arce.Arc_Gen_Account_Wrapper currentAcc = new arce.Arc_Gen_Account_Wrapper();
        final List<arce.Arc_Gen_Account_Wrapper> accountsWrapLts = (List<arce.Arc_Gen_Account_Wrapper>) JSON.deserialize(accountswraper, List<arce.Arc_Gen_Account_Wrapper>.Class);
        arce.Arc_Gen_Account_Wrapper groupWrapper = new arce.Arc_Gen_Account_Wrapper();

        if (accountsWrapLts.isEmpty()) {
            // Fetch information of current account.
            accountsWrapLts.add(arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> { recordId }).get(recordId));
        } else {
            groupWrapper = accountsWrapLts[accountsWrapLts.size() - 1];
        }

        // If subprocess type is RAIP, only look for ARCE whose account is the current account (recordId).
        if (subprocessType == RAIP_SUBPROCESS_TYPE) {
            accIds.add(recordId);
        }

        for (arce.Arc_Gen_Account_Wrapper accWrapper: accountsWrapLts) {
            if (accWrapper.accId == recordId) {
                currentAcc = accWrapper;
            }

            if (subprocessType != RAIP_SUBPROCESS_TYPE) {
                accIds.add(accWrapper.accId);
            }
        }
        PreviousARCEData prevArce = new PreviousARCEData();
        List<arce__analysis__c> analizedList = getArceData(accIds, subprocessType);
        // Fill common data.
        prevArce.idARCE = '';
        prevArce.wfStatus = '';
        prevArce.accountNumber = currentAcc.accNumber;
        prevArce.bankId = currentAcc.bankId;
        prevArce.accountId = fillPrevArceDataAccId(currentAcc, groupWrapper, recordId);
        prevArce.accHasAnaType = getAccHasAnaType(groupWrapper.accId,recordId);
        prevArce.modIsActive = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ActivateModification')[0].arce__Value1__c);
        prevArce.renIsActive = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ActivateRenovation')[0].arce__Value1__c);
        prevArce.modifiedStrucGroup = false;
        prevArce.redirectRevoke = false;

        if (!analizedList.isEmpty()) {
            // Fill existing ARCE data.
            prevArce.idARCE = analizedList[0].Id;
            prevArce.wfStatus = analizedList[0].arce__wf_status_id__c;
            prevArce.wfStage = analizedList[0].arce__Stage__c;
            prevArce.sanctionType = analizedList[0].arce__anlys_wkfl_sanction_rslt_type__c;
            prevArce.subProcess = analizedList[0].arce__anlys_wkfl_sub_process_type__c;
            prevArce.expiryDate = analizedList[0].arce__analysis_risk_expiry_date__c;
            prevArce = fillAccountData(prevArce, currentAcc, accIds);
        }

        return prevArce;
    }
    /**
    *----------------------------------------------------------------------------------
    * @description Fills accountId field on PreviousARCEData object.
    *----------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date    21/04/2022
    * @param arce.Arc_Gen_Account_Wrapper currentAcc
    * @param arce.Arc_Gen_Account_Wrapper groupWrapper
    * @param String recordId
    * @return Id accId
    * @example PreviousARCEData prevArce.accountId = fillPrevArceDataAccId(currentAcc, groupWrapper, recordId);
    **/
    private static Id fillPrevArceDataAccId(arce.Arc_Gen_Account_Wrapper currentAcc, arce.Arc_Gen_Account_Wrapper groupWrapper, String recordId) {
        Id accId;
        if (groupWrapper.accId == Id.valueOf(recordId)) {
            accId = groupWrapper.accId;
        } else {
            accId = currentAcc.accId;
        }
        return accId;
    }
    /**
    *--------------------------------------------------------------------------------
    * @Description
    *--------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2022-03-31
    * @param    List<Id> accountsIds
    * @param    List<String> subprocessType
    * @return   Boolean
    * @example  Boolean arce = getLatestArceRevoked(accountsIds, subprocessType);
    * -------------------------------------------------------------------------------
    */
    public static Boolean getLatestArceRevoked(List<Id> accountsIds, List<String> subprocessType, arce__Analysis__c lastAnalysis) {
        List<arce__Analysis__c> toReturn;
        toReturn = new List<arce__Analysis__c>();

        final String analysisId = [SELECT Id, arce__Customer__r.Name, arce__CustomAccountID__c, arce__Analysis__r.Name, arce__Analysis__r.arce__Stage__c,
                                arce__Analysis__r.arce__wf_status_id__c,arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c
                                FROM arce__Account_has_Analysis__c
                                WHERE arce__Customer__c = :accountsIds AND arce__Analysis__r.arce__Stage__c = '3' AND
                                arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c IN :subprocessType AND arce__CustomAccountID__c = null
                                AND CreatedDate > :lastAnalysis.CreatedDate ORDER BY CreatedDate DESC LIMIT 1]?.arce__Analysis__c;
        final string reason = Label.Cls_arce_ReturnReason + ' ' + Label.Arc_Gen_RevokeArceByChangesStrucGroup;
        final List<dwp_cvad__Action_Audit__c> lstActionAudit = [SELECT Id, Name, dwp_cvad__action_audit_record_id__c, dwp_cvad__audit_audit_comments__c
        FROM dwp_cvad__Action_Audit__c WHERE dwp_cvad__action_audit_record_id__c = :analysisId AND dwp_cvad__audit_audit_comments__c = :reason];
        return lstActionAudit.isEmpty() ? false : true;
    }
    /**
    *--------------------------------------------------------------------------------
    * @Description Fills PreviousARCEData wrapper with accounts data
    *--------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2022-02-10
    * @param    PreviousARCEData prevArce
    * @param    arce.Arc_Gen_Account_Wrapper currentAcc
    * @param    List<Id> accIds
    * @return   PreviousARCEData
    * @example  PreviousARCEData arce = fillAccountData(prevArce, currentAcc, analysisId);
    * -------------------------------------------------------------------------------
    */
    public static PreviousARCEData fillAccountData(PreviousARCEData prevArce, arce.Arc_Gen_Account_Wrapper currentAcc, List<Id> accIds) {
        final List<arce__analysis__c> lastAnalysis = arce.Arc_Gen_ArceAnalysis_Data.getLastSancArceByGroup(new Set<Id>(accIds));
        if (!lastAnalysis.isEmpty()) { // New analysis
            prevArce.arceExistingId = lastAnalysis[0].Id;
            if (prevArce.modIsActive || prevArce.renIsActive) {
                final List<String> subProcess = new List<String>{arce.Arc_Gen_Constants.SUBPROCESS_NEW, arce.Arc_Gen_Constants.SUBPROCESS_RENOVATION, arce.Arc_Gen_Constants.SUBPROCESS_MODIFICATION};
                prevArce.modifiedStrucGroup = getLatestArceRevoked(accIds, subProcess, lastAnalysis[0]);
                prevArce.redirectRevoke = prevArce.modifiedStrucGroup ? false : prevArce.redirectRevoke;
            }
        }
        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> lstArceClient = arce.Arc_Gen_AccHasAnalysis_Data.getARCEClientData(new Set<String>{prevArce.idARCE});
        if (!lstArceClient.isEmpty()) {
            for (arce.Arc_Gen_Account_Has_Analysis_Wrapper item : lstArceClient) {
                if (item.accWrapperObj == null) {
                    prevArce.modifiedStrucGroup = true;
                    prevArce.redirectRevoke = true;
                } else {
                    prevArce.accHasAnalysisId = item.accWrapperObj.participantType == 'GROUP' ?  String.valueOf(item.ahaObj.Id) : '';
                }
            }
        }
        return prevArce;
    }
    /**
    *--------------------------------------------------------------------------------
    * @Description Get ARCE data to redirect or return data of valid ARCE for modification
    *--------------------------------------------------------------------------------
    * @Author   Juan Manuel Perez Ortiz juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-05-05
    * @param    accIds - Account ids
    * @param    subprocessType - Subprocess ARCE type
    * @return   List<arce__Analysis__c>
    * @example  getArceData(accIds, subprocessType)
    * -------------------------------------------------------------------------------
    */
    public static List<arce__Analysis__c> getArceData(List<Id> accIds, String subprocessType) {

        //Fetch arce data to redirect
        List<arce__analysis__c> analizedList = new List<arce__analysis__c>();
        List<arce__Analysis__c> arceLts = new List<arce__Analysis__c>();
        Set<Id> setAccIds = new Set<Id>();
        setAccIds.addAll(accIds);

        //Get the AHAS to recognize to which object the accIds belong
        final List<arce__Account_has_Analysis__c> accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAhasWithNoacc(accIds, subprocessType);

        if (!accHasAnalysis.isEmpty() && accHasAnalysis[0].arce__CustomAccountID__c == accIds[0]) {
            final List<Id> toNext = new List<Id>();
            toNext.add(accHasAnalysis[0].arce__Analysis__c);
            arceLts.add(arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(toNext)[0]);
        } else if(accHasAnalysis.isEmpty()) {
            final List<arce__Analysis__c> auxList = arce.Arc_Gen_ArceAnalysis_Data.getLatestArceOfType(accIds, subprocessType);
            arceLts = auxList.isEmpty() && subprocessType == '2' ? arce.Arc_Gen_ArceAnalysis_Data.getArcesFromAccounts(accIds) : auxList;
        }

        //if there is no ARCE data to redirect, evaluate if the ARCE data is valid for modification
        if (arceLts.isEmpty()) {
            analizedList = arce.Arc_Gen_ArceAnalysis_Data.getLastSancArceByGroup(setAccIds);
        } else {
            analizedList = arceLts;
        }
        return analizedList;
    }

    /**
    *--------------------------------------------------------------------------------
    * @Description Method to get Account has analysis type
    *--------------------------------------------------------------------------------
    * @Author   Juan Manuel Perez Ortiz juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-05-05
    * @param    accId - Account id
    * @param    recordId - recordId
    * @return   List<arce__Analysis__c>
    * @example  getAccHasAnaType(accId, recordId)
    * -------------------------------------------------------------------------------
    */
    public static String getAccHasAnaType(String accId, String recordId) {
        String acchasAnaType = accId == Id.valueOf(recordId) ? 'Grupo' : 'Customer';
        return acchasAnaType;
    }

    /**
    *--------------------------------------------------------------------------------
    * @Description Method that return map with field name and value of local configuration for the user
    *--------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2021-04-20
    * @param    analysisId - analysis record id
    * @return   Map<String, Object> - Return a map with the custom permission key and arce config record object
    * @example  Map<String, Object> map = getLocalCountryValue(analysisId);
    * -------------------------------------------------------------------------------
    */
    public static Map<String, Object> getLocalCountryValue(Id analysisId) {
        final List<arce__Arce_Config__mdt> lstArceConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(LOCALUSER);
        final String nameField = lstArceConfig[0].arce__Value1__c;
        final Map<String, Object> mapLocalCountry = new Map<String, Object>();
        if (nameField != null) {
            String localConfig = '';
            final List<CustomPermission> lstCustPerm = arce.Arc_Gen_GenericUtilities.getCustomPermissions(LOCATOR_CNF);
            Boolean uniqueKey = false;
            for (CustomPermission custPerm : lstCustPerm) {
                if (FeatureManagement.checkPermission(custPerm.DeveloperName) && uniqueKey == false) {
                    localConfig = custPerm.DeveloperName;
                    uniqueKey = true;
                }
            }
            if(localConfig != '') {
                mapLocalCountry.put(nameField, localConfig);
            }
        }
        return mapLocalCountry;
    }
}