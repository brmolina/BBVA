/*-----------------------------------------------------------------------------------------------
    Author:        Rodrigo Fdez-Victorio
    Company:       Accenture
    Description:   Subclass to handle parent to child methods called when the triggers over Case
    object are fired

    History:
    <Date>          <Author>                <Description>
    08/07/2017      Juan Carlos Terrón        Initial version
-------------------------------------------------------------------------------------------------*/
public without sharing class SER_CaseMethodsParent {
    /*Constante identificador Usuario*/
    final static string ID_USER = '005';
    /*Constante texto identificador de test*/
    final static string LOG_TEST = 'Catch testing';
    /*Constante cerrado (status CASO) */
    final static string STATUS_CLOSED = 'Closed';
    /*Constante contestado (status CASO) */
    final static string STATUS_ANSWERED = 'Answered';
    /*Constante Primer contacto de la lista no repetido*/
    final static string FIRST_CTCT_NO_REC = 'First Contact No Recurrence';
    /*Constante Query needed*/
    final static string QRY_NEEDED = 'bl_QueryNeeded';
    /*Constante Updating master cases*/
    final static string UPD_MASTER_CASE = 'bl_UpdatingMasterCases';
    /*Constante Inserting master cases*/
    final static string INS_MASTER_CASE = 'bl_InsertingMasterCases';

    private SER_CaseMethodsParent() {}

    /*------------------------------------------------------------------------------------------
        Author:        Juan Carlos Terrón
        Company:       Accenture
        Description:   Method that copies the parent case fields into the children cases fields.

        IN:            Trigger.New, Trigger.Old, Trigger.newMap, Trigger.oldMap
        OUT:           void

        History:
        <Date>                  <Author>                <Change Description>
        10/03/2017              Juan Carlos Terrón      Initial Version.
        12/11/2018              Jose Luis Aranda        Add GNC
    --------------------------------------------------------------------------------------------*/
    public static void copyParentCaseFieldsToChildrenCaseFields(
        String event,
        List<Case> newList,
        List<Case> oldList,
        Map<Id,Case> newMap,
        Map<Id,Case> oldMap) {
        try {
            /*Case Status field storage START*/
            Map<String,Schema.SObjectField> mapCaseFields = new Map<String,Schema.SObjectField>();
            mapCaseFields = Case.getSObjectType().getDescribe().fields.getMap();
            Map<String,String> mapPicklistValues;
            mapPicklistValues = new Map<String,String>();
            for(Schema.PicklistEntry plv : mapCaseFields.get('Status').getDescribe().getPickListValues()) {
                mapPicklistValues.put(plv.getLabel(), plv.getValue());
            }

            /*Case Status field storage END*/
            if(event.equalsIgnoreCase('update')) {//Update event
                copyParentUpdate(newMap, oldMap,mapPicklistValues);
            } else if(event.equalsIgnoreCase('insert')) { //Insert Event
                copyParentInsert(newMap, mapPicklistValues);
            }
            if(runTest()) {  throw new HandledException(LOG_TEST); }//Catch testing for code coverage.
        } catch (Exception ex) {
            cibLog(ex, 'SER_CaseMethods.copyParentCaseFieldsToChildrenCaseFields()');
        }
    }
    private static void copyParentUpdate (
        Map<Id,Case> newMap,
        Map<Id,Case> oldMap,
        Map<String,String> mapPicklistValues) {
        Set<Id> setMasterCasesID;
        setMasterCasesID = new Set<Id>();
        Map<String,Boolean> mapBL;
        mapBL = new Map<String,Boolean>{QRY_NEEDED => false,UPD_MASTER_CASE => false,INS_MASTER_CASE => false};
        Map<Id,List<Case>> mapMasterIDCC;
        mapMasterIDCC = new Map<Id,List<Case>>();
        Map<Id,Case> mapMasterCases;
        mapMasterCases = new Map<Id,Case>();
        Boolean blQueryNeeded = false; //Flag to avoid doing unnecesary queries
        Boolean blUpdMasterCases  = false; //Flag to know if we have to process

        Set<Id> setAlrExiMastCase;
        setAlrExiMastCase = new Set<Id>();

        for(Case casoItem : newMap.valueS()) { //for every case we check if we're updating a master case and
            //if its necessary we build up the maps needed to process it.
            final Case oldcase = oldMap.get(casoItem.Id);
            SER_CaseMethods_HELPER_Parent.fillParentChildrenMaps(casoItem, oldcase, mapBL, setMasterCasesID, setAlrExiMastCase, mapMasterCases, mapMasterIDCC);
        }
        blQueryNeeded = mapBL.get(QRY_NEEDED);
        blUpdMasterCases = mapBL.get(UPD_MASTER_CASE);
        System.debug('JCT - bl_QueryNeeded : '+blQueryNeeded);
        System.debug('JCT - bl_UpdatingMasterCases : '+blUpdMasterCases);
        if(blUpdMasterCases) {//Updating at leat 1 master case.
            List<Case> listChildCaseUpd;
            listChildCaseUpd = new List<Case>();
            if(blQueryNeeded) {//We need to query in order to process
                queryNeededUp (mapMasterCases, mapMasterIDCC, setAlrExiMastCase,setMasterCasesID);
            } else {
                queryNotNeededUp (mapMasterIDCC,setMasterCasesID);
            }
            System.debug('JCT - mapa de padres y listas de hijos : '+mapMasterIDCC.size());
            for(Case caso : mapMasterCases.values()) {//Group all children cases in one list
                final List<Case> lista = mapMasterIDCC.get(caso.Id);
                if(lista.isEmpty()) {
                    mapMasterIDCC.remove(caso.Id);
                    mapMasterCases.remove(caso.Id);
                } else {
                    listChildCaseUpd.addAll(lista);
                }
            }
            System.debug('JCT - listChildCaseUpd SIZE : '+listChildCaseUpd.size());
            if(!listChildCaseUpd.isEmpty()) {
                //Mapa dpara los casos actualizados.
                Map<Id,Case> mapChildCaseToUpd;
                mapChildCaseToUpd  = new Map<Id,Case>();
                for(Case casoItem : listChildCaseUpd) {

                    //Mapa de los casos que queremos actualizar
                    mapChildCaseToUpd.put(casoItem.Id, casoItem);
                }
                final SER_CloseCase_BATCH closeCases = new SER_CloseCase_BATCH(mapMasterCases,mapChildCaseToUpd,mapPicklistValues);
                Id batchId;
                batchId = Database.executeBatch(closeCases);
                System.debug('Ejecutado batch:' + batchID);
            }
        }
    }
    private static void copyParentInsert (
        Map<Id,Case> newMap,
        Map<String,String> mapPicklistValues) {
        Set<Id> setMasterCasesID;
        setMasterCasesID = new Set<Id>();
        Map<Id,Case> mapMasterCases;
        mapMasterCases = new Map<Id,Case>();
        Map<Id,Case> mapChildrenCases;
        mapChildrenCases = new Map<Id,Case>();
        Map<String,Boolean> mapBL;
        mapBL = new Map<String,Boolean>{QRY_NEEDED => false,UPD_MASTER_CASE => false,INS_MASTER_CASE => false};
        Map<Id,List<Case>> mapMasterIDCC;
        mapMasterIDCC = new Map<Id,List<Case>>();
        Boolean blInsMasterCase = false; //Flag to check if we're creating master cases.
        Set<Id> setAlrExiMastCase;
        setAlrExiMastCase = new Set<Id>();
        for(Case casoItem : newMap.values()) {//Fill the maps.
            SER_CaseMethods_HELPER_Parent.fillParentChildrenMaps(casoItem, mapBL, setMasterCasesID, setAlrExiMastCase, mapMasterCases, mapChildrenCases, mapMasterIDCC);
        }
        blInsMasterCase = mapBL.get(INS_MASTER_CASE);
        if(blInsMasterCase) {//We're isnerting mastercases
            Boolean blQueryNeeded = false; //Flag to avoid doing unnecesary queries
            blQueryNeeded = mapBL.get(QRY_NEEDED);
            List<Case> listChildCaseUpd;
            listChildCaseUpd = new List<Case>();
            if(blQueryNeeded) {//We need to query
                for(Case casoItem :
                    [
                        SELECT  Id,Parent.Id,SER_Business_Case_Type__c,
                                Status,Subject,Description,SER_Asset__c,
                                SER_MailingGroup__c,SER_Outbound_Mailbox__c,
                                SER_Solution__c,SER_Classification__c,
                                SER_Is_Master_Case__c,SER_Master_Case__c,
                                SER_Type_EST__c,
                                SER_Pre_liquidacion__c,SER_Post_liquidation__c,
                                SER_Type_GM__c,SER_Subtype_GM__c,
                                SER_Web_App__c,SER_RemedyId__c,SER_Close__c ,
                                AccountId,SER_Country__c,SER_Type_GNC__c,
                                SER_Subtype_GNC__c,SER_IsSernova__c, 
                                gf_case_channel_source_name__c,case_channel_source_type__c,
                                case_status_type__c,activity_status_type__c,
                                validation_criticality_type__c,gf_case_environment_name__c,
                                gf_case_countries_desc__c,gf_case_area_name__c,gf_case_creation_type__c,
                                gf_case_cause_on_closure_desc__c,RecordTypeId,SER_Initial_Classification__c
                        FROM    Case
                        WHERE   (SER_Is_Master_Case__c = true OR ParentId = null)
                                AND Id IN :setAlrExiMastCase]) {
                    mapMasterCases.put(casoItem.Id, casoItem);
                }
            }
            for(Id mcid : mapMasterIDCC.keySet()) {//Iterate over mcidmaster cases
                final Case mastercase = mapMasterCases.get(mcid);
                for(Case casoItem : mapMasterIDCC.get(mcid)) {//Iterate over the children cases for the current master case.
                    //Modify and add to update the children cases.
                    final Case auxcase = new Case(Id = casoItem.Id,SER_Business_Case_Type__c = casoItem.SER_Business_Case_Type__c, SER_IsSernova__c = casoItem.SER_IsSernova__c);
                    SER_CaseMethods_HELPER_ParentCp.copyParentFieldsINSERT(auxcase, mastercase, mapPicklistValues);
                    listChildCaseUpd.add(auxcase);
                }
            }
            if(!listChildCaseUpd.isEmpty()) {
                update listChildCaseUpd; //Update children cases.
            }
        }
    }
    private static void queryNeededUp (Map<Id,Case> mapMasterCases, Map<Id,List<Case>> mapMasterIDCC, Set<Id> setAlrExiMastCase,Set<Id> setMasterCasesID) {
        for(Case casoItem :
                        [
                            SELECT  Id,Parent.Id,SER_Business_Case_Type__c,
                                    Status,Subject,Description,SER_Asset__c,
                                    SER_MailingGroup__c,SER_Outbound_Mailbox__c,
                                    SER_Solution__c,SER_Classification__c,
                                    SER_Is_Master_Case__c,SER_Master_Case__c,
                                    SER_Type_EST__c,
                                    SER_Pre_liquidacion__c,SER_Post_liquidation__c,
                                    SER_Type_GM__c,SER_Subtype_GM__c,
                                    SER_Web_App__c,SER_RemedyId__c,SER_Close__c,
                                    AccountId,SER_Country__c,SER_Type_GNC__c,
                                    SER_Subtype_GNC__c,
                                    gf_case_channel_source_name__c,case_channel_source_type__c,
                                    case_status_type__c,activity_status_type__c,
                                    validation_criticality_type__c, gf_case_environment_name__c,
                                    gf_case_countries_desc__c,gf_case_area_name__c,gf_case_creation_type__c,
                                    gf_case_cause_on_closure_desc__c,RecordTypeId,SER_Initial_Classification__c
                            FROM    CASE
                            WHERE   ((SER_Is_Master_Case__c = false
                                    AND SER_Master_Case__c IN :setMasterCasesID)
                                    OR
                                    (SER_Is_Master_Case__c = true
                                    AND Id IN :setAlrExiMastCase))
                                    OR
                                    ((ParentId IN :setMasterCasesID)
                                    OR
                                    (ParentId = null
                                    AND Id IN :setAlrExiMastCase))
                        ]) {
                            if(setAlrExiMastCase.contains(casoItem.Id)) {//Overwrite the value, its a parent case.
                                mapMasterCases.put(casoItem.Id, casoItem);
                            } else if(casoItem.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GM || casoItem.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GNC) {//We add the case to list related to its parent case in the map.
                                mapMasterIDCC.get(casoItem.ParentId).add(casoItem);
                            }
                        }
    }
    private static void queryNotNeededUp (Map<Id,List<Case>> mapMasterIDCC,Set<Id> setMasterCasesID) {
        for(Case casoItem :
                        [
                            SELECT  Id,Parent.Id,SER_Business_Case_Type__c,
                                    Status,Subject,Description,SER_Asset__c,
                                    SER_MailingGroup__c,SER_Outbound_Mailbox__c,
                                    SER_Solution__c,SER_Classification__c,
                                    SER_Is_Master_Case__c,SER_Master_Case__c,
                                    SER_Type_EST__c,
                                    SER_Pre_liquidacion__c,SER_Post_liquidation__c,
                                    SER_Type_GM__c,SER_Subtype_GM__c,
                                    SER_Web_App__c,SER_RemedyId__c,SER_Close__c,
                                    AccountId,SER_Country__c,SER_Type_GNC__c,
                                    SER_Subtype_GNC__c,
                                    gf_case_channel_source_name__c,case_channel_source_type__c,
                                    case_status_type__c,activity_status_type__c,
                                    validation_criticality_type__c,gf_case_environment_name__c,
                                    gf_case_countries_desc__c,gf_case_area_name__c,gf_case_creation_type__c,
                                    gf_case_cause_on_closure_desc__c,RecordTypeId,SER_Initial_Classification__c
                            FROM    CASE
                            WHERE   (SER_Is_Master_Case__c = false
                                    AND SER_Master_Case__c IN :setMasterCasesID)
                                    OR
                                    ((SER_Business_Case_Type__c = 'GM'
                                    OR SER_Business_Case_Type__c = 'GNC')
                                    AND Parent.Id IN :setMasterCasesID)
                        ]) {
                            if(casoItem.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GM || casoItem.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GNC) { //We add the case to list related to its parent case in the map.
                                mapMasterIDCC.get(casoItem.ParentId).add(casoItem);
                            }
                        }
    }

    //Comprueba si nos encontramos en ejecución de un test
    private static boolean runTest() {
        return Test.isRunningTest();
    }
    private static void cibLog(Exception pEx, String pMetodo) {
        CIB_Log__c logToInsert;
        logToInsert = new CIB_Log__c();
        logToInsert.CIB_ErrorMessage__c = pEx.getStackTraceString()+'\n'+pEx.getMessage();
        logToInsert.CIB_Subject__c = pMetodo+' ERROR';
        insert logToInsert;
    }
}