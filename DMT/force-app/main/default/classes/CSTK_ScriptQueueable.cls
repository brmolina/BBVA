/**
* ────────────────────────────────────────────────────────────────────
* ScriptQueueable
* ScriptQueueable class
* ────────────────────────────────────────────────────────────────────
* @author      Olatz Urrutia <olatz.urrutia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-04-13
* @modified
* @systemLayer Business
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods')
public with sharing class CSTK_ScriptQueueable implements Queueable { //NOSONAR
    /**
    * @description Exeute schedulable on year zero
    */
    public void execute(SchedulableContext qContextSch) {
        System.enqueueJob(this);
    }
    /**
    * @description Exeute queueable on year zero
    */
    public void execute(QueueableContext qCntxt) {
        List<cstk__Toolkit__c> scope = [SELECT Id, cstk__toolkit_unique_id__c FROM cstk__Toolkit__c WHERE cstk__account_id__c != null]; //NOSONAR
        Set<Id> toolIds = new Set<Id>(); //NOSONAR
        for (cstk__Toolkit__c tool : scope) {
            toolIds.add(tool.Id);
        }
        processRecordsGD(toolIds); //GENERAL DATA
        processRecordsET(toolIds); //EMISION TARGET
        processRecordsST(toolIds); //STARTEGY
        processRecordsSA(toolIds); //SECTOR AUTO
        processRecordsSE(toolIds); //SECTOR ENERGY
        processRecordsSU(toolIds); //SECTOR UTILTIES
        processRecordsSC(toolIds); //SECTOR CEMENT
        processRecordsSS(toolIds); //SECTOR STEEL
        processRecordsSAT(toolIds); //SECTOR AUTOPARTS
        //processRecordsRA(toolIds); //Rating
        //processRecordsTG(toolIds); //TOP5Geographies
        processRecordsPR(toolIds); //PHYSICAL RISK
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    public static void processRecordsGD(Set<Id> recordIds) {
        System.scheduleBatch(new CSTK_RecordZeroActions(new List<Id>(recordIds), 'cstk__General_Data__c'), 'General Data', 22, 100); //NOSONAR
        //Database.executeBatch(new CSTK_RecordZeroActions(new List<Id>(recordIds), 'cstk__General_Data__c'), 100);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */ 
    public static void processRecordsET(Set<Id> recordIds) {
        Database.executeBatch(new CSTK_RecordZeroActions(new List<Id>(recordIds), 'cstk__EmissionTarget__c'), 100);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    public static void processRecordsST(Set<Id> recordIds) {
        Database.executeBatch(new CSTK_RecordZeroActions(new List<Id>(recordIds), 'cstk__Strategy__c'), 100);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    public static void processRecordsSA(Set<Id> recordIds) {
        Database.executeBatch(new CSTK_RecordZeroActions(new List<Id>(recordIds), 'cstk__Sector_Auto__c'), 100);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    public static void processRecordsSE(Set<Id> recordIds) {
        Database.executeBatch(new CSTK_RecordZeroActions(new List<Id>(recordIds), 'cstk__Sector_Energy__c'), 100);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    public static void processRecordsSC(Set<Id> recordIds) {
        Database.executeBatch(new CSTK_RecordZeroActions(new List<Id>(recordIds), 'cstk__Sector_Cement__c'), 100);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    public static void processRecordsSS(Set<Id> recordIds) {
        Database.executeBatch(new CSTK_RecordZeroActions(new List<Id>(recordIds), 'cstk__Sector_Steel__c'), 100);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    public static void processRecordsSAT(Set<Id> recordIds) {
        Database.executeBatch(new CSTK_RecordZeroActions(new List<Id>(recordIds), 'cstk__Sector_Autoparts__c'), 100);
    }

    /**
    * @description Consolidate Record Zero of Physical Risk
    * @param toolkitId List of toolkit Id
    * @return void
    */
    public static void processRecordsPR(Set<Id> recordIds) {
        Database.executeBatch(new CSTK_RecordZeroActions(new List<Id>(recordIds), 'cstk__Physical_Risk__c'), 100);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    public static void processRecordsSU(Set<Id> recordIds) {
        Database.executeBatch(new CSTK_RecordZeroActions(new List<Id>(recordIds), 'cstk__Sector_Utilities__c'), 100);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    public static void processRecordsRA(Set<Id> recordIds) {
        processRecordsRAENV(recordIds);
        processRecordsRASOC(recordIds);
        processRecordsRAGOV(recordIds);
        processRecordsRAGLO(recordIds);
        processRecordsRACAR(recordIds);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    @future 
    public static void processRecordsRAENV(Set<Id> recordIds) {
        final cstk.Utils.DML_Wrapper res = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'environmental', 'snp'); //NOSONAR
        system.debug('environmental snp' + res);
        final cstk.Utils.DML_Wrapper res1 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'environmental', 'sustainalytics'); //NOSONAR
        system.debug('environmental sustainalytics' + res1);
        final cstk.Utils.DML_Wrapper res2 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'environmental', 'cdp'); //NOSONAR
        system.debug('environmental cdp' + res2);
        final cstk.Utils.DML_Wrapper res3 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'environmental', 'other'); //NOSONAR
        system.debug('environmental other' + res3);
        final cstk.Utils.DML_Wrapper res4 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'environmental', 'bbva'); //NOSONAR
        system.debug('environmental bbva' + res4);
        final cstk.Utils.DML_Wrapper res5 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'environmental', 'companyreport'); //NOSONAR
        system.debug('environmental companyreport' + res5);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    @future 
    public static void processRecordsRASOC(Set<Id> recordIds) {
        final cstk.Utils.DML_Wrapper res = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'social', 'snp'); //NOSONAR
        system.debug('social snp' + res);
        final cstk.Utils.DML_Wrapper res1 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'social', 'sustainalytics'); //NOSONAR
        system.debug('social sustainalytics' + res1);
        final cstk.Utils.DML_Wrapper res2 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'social', 'cdp'); //NOSONAR
        system.debug('social cdp' + res2);
        final cstk.Utils.DML_Wrapper res3 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'social', 'other'); //NOSONAR
        system.debug('social other' + res3);
        final cstk.Utils.DML_Wrapper res4 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'social', 'bbva'); //NOSONAR
        system.debug('social bbva' + res4);
        final cstk.Utils.DML_Wrapper res5 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'social', 'companyreport'); //NOSONAR
        system.debug('social companyreport' + res5);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    @future 
    public static void processRecordsRAGOV(Set<Id> recordIds) {
        final cstk.Utils.DML_Wrapper res = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'governance', 'snp'); //NOSONAR
        system.debug('governance snp' + res);
        final cstk.Utils.DML_Wrapper res1 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'governance', 'sustainalytics'); //NOSONAR
        system.debug('governance sustainalytics' + res1);
        final cstk.Utils.DML_Wrapper res2 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'governance', 'cdp'); //NOSONAR
        system.debug('governance cdp' + res2);
        final cstk.Utils.DML_Wrapper res3 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'governance', 'other'); //NOSONAR
        system.debug('governance other' + res3);
        final cstk.Utils.DML_Wrapper res4 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'governance', 'bbva'); //NOSONAR
        system.debug('governance bbva' + res4);
        final cstk.Utils.DML_Wrapper res5 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'governance', 'companyreport'); //NOSONAR
        system.debug('governance companyreport' + res5);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    @future 
    public static void processRecordsRAGLO(Set<Id> recordIds) {
        final cstk.Utils.DML_Wrapper res = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'global', 'snp'); //NOSONAR
        system.debug('global snp' + res);
        final cstk.Utils.DML_Wrapper res1 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'global', 'sustainalytics'); //NOSONAR
        system.debug('global sustainalytics' + res1);
        final cstk.Utils.DML_Wrapper res2 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'global', 'cdp'); //NOSONAR
        system.debug('global cdp' + res2);
        final cstk.Utils.DML_Wrapper res3 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'global', 'other'); //NOSONAR
        system.debug('global other' + res3);
        final cstk.Utils.DML_Wrapper res4 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'global', 'bbva'); //NOSONAR
        system.debug('global bbva' + res4);
        final cstk.Utils.DML_Wrapper res5 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'global', 'companyreport'); //NOSONAR
        system.debug('global companyreport' + res5);
    }

    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    @future 
    public static void processRecordsRACAR(Set<Id> recordIds) {
        final cstk.Utils.DML_Wrapper res = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'carbonrisk', 'snp'); //NOSONAR
        system.debug('carbonrisk snp' + res);
        final cstk.Utils.DML_Wrapper res1 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'carbonrisk', 'sustainalytics'); //NOSONAR
        system.debug('carbonrisk sustainalytics' + res1);
        final cstk.Utils.DML_Wrapper res2 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'carbonrisk', 'cdp'); //NOSONAR
        system.debug('carbonrisk cdp' + res2);
        final cstk.Utils.DML_Wrapper res3 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'carbonrisk', 'other'); //NOSONAR
        system.debug('carbonrisk other' + res3);
        final cstk.Utils.DML_Wrapper res4 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'carbonrisk', 'bbva'); //NOSONAR
        system.debug('carbonrisk bbva' + res4);
        final cstk.Utils.DML_Wrapper res5 = CSTK_RecordZeroActions.consolidateObjectRating(new List<Id>(recordIds), 'carbonrisk', 'companyreport'); //NOSONAR
        system.debug('carbonrisk companyreport' + res5);
    }
    
    /**
    * @description Consolidate Record Zero of General_Data
    * @param toolkitId List of toolkit Id
    * @return void
    */
    @future 
    public static void processRecordsTG(Set<Id> recordIds) {
        final cstk.Utils.DML_Wrapper resA = CSTK_RecordZeroActions.consolidateObjectTopGeography(new List<Id>(recordIds), 'cstk__Sector_Auto__c');
        system.debug('geography auto' + resA);
        final cstk.Utils.DML_Wrapper resE = CSTK_RecordZeroActions.consolidateObjectTopGeography(new List<Id>(recordIds), 'cstk__Sector_Cement__c');
        system.debug('geography energy' + resE);
        final cstk.Utils.DML_Wrapper resU = CSTK_RecordZeroActions.consolidateObjectTopGeography(new List<Id>(recordIds), 'cstk__Sector_Energy__c');
        system.debug('geography utilities' + resU);
        final cstk.Utils.DML_Wrapper resC = CSTK_RecordZeroActions.consolidateObjectTopGeography(new List<Id>(recordIds), 'cstk__Sector_Steel__c');
        system.debug('geography cement' + resC);
        final cstk.Utils.DML_Wrapper resS = CSTK_RecordZeroActions.consolidateObjectTopGeography(new List<Id>(recordIds), 'cstk__Sector_Utility__c');
        system.debug('geography steel' + resS);
    }
    //system.enqueueJob(new CSTK_ScriptQueueable());
}