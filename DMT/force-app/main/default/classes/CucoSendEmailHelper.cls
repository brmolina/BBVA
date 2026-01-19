/**
* ────────────────────────────────────────────────────────────────────
* CucoSendEmailHelper
* Helper Class CucoSendEmail
* ────────────────────────────────────────────────────────────────────
* @author      CuCo CIB <globalhub_components.group@bbva.com>
* @modifiedBy
* @version     1.0
* @created     July 2021
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class CucoSendEmailHelper {

    /**
	* SINGLETON PATTERN
	*/
    private static CucoSendEmailHelper instance;

    /**
	* Constructor
	*/
    private CucoSendEmailHelper() {
    }

    /**
	* getInstance
	*/
    public static CucoSendEmailHelper gtInstance() {
        if(instance == null) {
            instance = new CucoSendEmailHelper();
        }
        return instance;
    }

    /**
    * @description Select cuco__profitability_analysis__c
    * @param idProfSheetSet : Set<Id> Id of cuco__profitability_sheet__c
    * @param setProfSheetCode : Set<String> cuco__gf_profitability_sheet_id__c of cuco__profitability_sheet__c
    * @return List<cuco__profitability_analysis__c>
    */
    public Static List<cuco__profitability_analysis__c> getPA (Set<Id> idProfSheetSet, Set<String> setProfSheetCode) { // NOSONAR
        return [SELECT Id, cuco__gf_auto_formalization_req_id__c, cuco__gf_profitability_sheet_id__c, cuco__gf_pa_mgmt_stage_type_name__c, cuco__gf_pa_mgmt_status_type_name__c, cuco__gf_pa_management_type_name__c, OwnerId, CreatedDate, Owner.Email FROM cuco__profitability_analysis__c WHERE (cuco__gf_pa_mgmt_stage_type_name__c = 'Formalization' OR cuco__gf_pa_mgmt_stage_type_name__c = 'Formalized') AND cuco__gf_pa_management_type_name__c != 'Cancellation' AND (cuco__gf_profitability_sheet_id__c IN :idProfSheetSet OR cuco__gf_auto_formalization_req_id__c IN : setProfSheetCode) WITH SECURITY_ENFORCED LIMIT 50000]; // NOSONAR
    }

    /**
    * @description Select last cuco__profitability_analysis__c related
    * @param lstPA : List<cuco__profitability_analysis__c>
    * @param books : List<cuco__profitability_sheet__c>
    * @return List<cuco__profitability_analysis__c>
    */
    public static List<cuco__profitability_analysis__c> getBookRelated (List<cuco__profitability_analysis__c> lstPA,List<cuco__profitability_sheet__c> books ) {
        final List<cuco__profitability_analysis__c> newLstPA = new List<cuco__profitability_analysis__c> ();
        for (cuco__profitability_sheet__c book : books) {
            cuco__profitability_analysis__c relatedPA;
            DateTime analysisTime;
            for (cuco__profitability_analysis__c analysis: lstPA) {
                if ((analysisTime == NULL || analysis.CreatedDate > analysisTime) && (analysis.cuco__gf_auto_formalization_req_id__c == Book.cuco__gf_profitability_sheet_id__c ||
                                                                                        analysis.cuco__gf_profitability_sheet_id__c == Book.Id)) {
                                                                                            analysisTime = analysis.CreatedDate;
                                                                                            relatedPA = analysis;
                                                                                        }
            }
            if(relatedPA != NULL) {
                newLstPA.add(relatedPA);
            }
        }
        return newLstPA;
    }

    /**
    * @description Select dwp_cvad__Action_Audit__c related
    * @param resultIds : Map<Id,SObject>(newLstPA)
    * @return auditMap, Map<String,String>
    */
    public Static Map<String,String> getAudits (Set<Id> resultIds) {
        final Map<String,String> auditMap = new Map<String,String> ();
        final String autoFormalized = System.Label.cuco.form_complete_sample + ' ' + System.Label.cuco.form_sent_success_sample;
        final String manualFormalized = System.Label.cuco.form_sent_sample + '%';
        final List<dwp_cvad__Action_Audit__c> actionAudit = [SELECT Id, dwp_cvad__action_audit_user_id__c,dwp_cvad__action_audit_record_id__c, dwp_cvad__action_audit_user_id__r.Email, dwp_cvad__action_audit_user_id__r.Id
                                                                FROM dwp_cvad__Action_Audit__c
                                                                WHERE dwp_cvad__action_audit_type__c = 'ProfitabilityAnalysis' AND (dwp_cvad__action_audit_name__c =: autoFormalized OR dwp_cvad__action_audit_name__c LIKE : manualFormalized) AND dwp_cvad__action_audit_record_id__c IN : resultIds WITH SECURITY_ENFORCED];
        for (dwp_cvad__Action_Audit__c audit : actionAudit) {
            auditMap.put(audit.dwp_cvad__action_audit_record_id__c, audit.dwp_cvad__action_audit_user_id__r.Id);
        }
        return auditMap;
    }

    /**
    * @description Select Users
    * @param idUsersToFind : Set<Id> (OwnerID sObject, Iddwp_cvad__action_audit_user_id__c)
    * @return userMap, Map<Id,User>
    */
    public Static Map<Id,User> getUsers (Set<Id> idUsersToFind) {
        final List<User> users = [SELECT Id, Name, Email FROM User WHERE Id In : idUsersToFind WITH SECURITY_ENFORCED];
        final Map<Id,User> userMap = new Map<Id,User> ();
        userMap.putAll(users);
        return userMap;
    }

    /**
    * @description Select cuco__profitability_sheet_participant__c
    * @param idProfSheetSet : Set<Id> Id of cuco__profitability_sheet__c
    * @return mapCurrentPP Map<Id of cuco__profitability_sheet__c,List<String>(names related)>
    */
    public static Map<Id,List<String>> getCurrentProfParticipants(Set<Id> profSheetSet) {
        final Map<Id,List<String>> mapCurrentPP = new Map<Id,List<String>> ();
        final cuco.ProfitabilitySheetParticipant_Selector pspSelector = new cuco.ProfitabilitySheetParticipant_Selector(new List<String>{'Error_Selector'});
        final List<cuco__profitability_sheet_participant__c> lstPSP = pspSelector.selectByProfSheet(profSheetSet);
        for (cuco__profitability_sheet_participant__c psp : lstPSP) {
            string[] lst = new string[]{};
                if (mapCurrentPP.containsKey(psp.cuco__gf_profitability_sheet_id__c)) {
                    lst = mapCurrentPP.get(psp.cuco__gf_profitability_sheet_id__c);
                    lst.add(psp.cuco__participant_id__r.Name);
                } else {
                    lst.add(psp.cuco__participant_id__r.Name);
                }
            mapCurrentPP.put(psp.cuco__gf_profitability_sheet_id__c,lst);
        }
        return mapCurrentPP;
    }

    /**
    * @description Select Users
    * @param newLstPA : List<cuco__profitability_analysis__c>
    * @param auditMap : Map<String,String> (OOwnerId cuco__profitability_analysis__c, analysis.Owner.Id)
    * @return idUsersToFind Set<Id>(users)
    */
    public static Set<Id> getIdUsersToFind (List<cuco__profitability_analysis__c> newLstPA, Map<String,String> auditMap) {
        final Set<Id> idUsersToFind = new Set<Id> ();
        for (cuco__profitability_analysis__c analysis : newLstPA) {
            idUsersToFind.add(analysis.Owner.Id);
            if (!auditMap.isEmpty() && auditMap.containsKey(analysis.Id) && (auditMap.get(analysis.Id) != analysis.Owner.Id)) {
                idUsersToFind.add(auditMap.get(analysis.Id));
            }
        }
        return idUsersToFind;
    }

    /**
    * @description method: Find users that have to be notified
    * @param newLstPA : List of cuco__profitability_analysis__c
    * @param auditMap : Map<String,String>()
    * @return myMapAnalysis Map<String,Set<Id>>(Identifier cuco__profitability_analysis__c,idUsers)
    */
    public static Map<String,Set<Id>> getMapAnalysis (List<cuco__profitability_analysis__c> newLstPA, Map<String,String> auditMap) {
        final Map<String,Set<Id>> myMapAnalysis = New Map<String,Set<Id>> ();
        for (cuco__profitability_analysis__c analysis : newLstPA) {
            final Set<Id> idUsers = new Set<Id> ();
            idUsers.add(analysis.Owner.Id);
            if (!auditMap.isEmpty() && auditMap.containsKey(analysis.Id) && (auditMap.get(analysis.Id) != analysis.Owner.Id)) {
                idUsers.add(auditMap.get(analysis.Id));
            }
            if (analysis.cuco__gf_profitability_sheet_id__c != NULL) { //NOSONAR
                myMapAnalysis.put(analysis.cuco__gf_profitability_sheet_id__c,idUsers);
            } else if (analysis.cuco__gf_auto_formalization_req_id__c != NULL) { //NOSONAR
                myMapAnalysis.put(analysis.cuco__gf_auto_formalization_req_id__c,idUsers);
            }
        }
        return myMapAnalysis;
    }

    /**
    * @description method: Prepares the data to be sent as notifications
    * @param books : List of cuco__profitability_sheet__c
    * @param mapCurrentPP : Map<Id,List<String>> Id cuco__profitability_analysis__c, List cuco__profitability_analysis_participant__c
    * @return Map<Id,CucoConstructor.DataBooks> Id cuco__profitability_sheet__c,
    * {OwnerId of cuco__profitability_sheet__c, List cuco__profitability_sheet_participant__c,cuco__profitability_sheet__c}
    */
    public static Map<Id,CucoConstructor.DataBooks> getMapToSend (List<cuco__profitability_sheet__c> books, Map<String,Set<Id>> mapAnalysis, Map<Id,List<String>> mapCurrentPP) {
        final Map<Id,CucoConstructor.DataBooks> mapToSend = new Map<Id,CucoConstructor.DataBooks>();
        for (cuco__profitability_sheet__c book: books) {
            Set<Id> idUsers = new Set<Id> ();
            if (mapAnalysis.containsKey(book.Id)) {
                idUsers = mapAnalysis.get(book.Id);
            } else if (mapAnalysis.containsKey(book.cuco__gf_profitability_sheet_id__c)) {
                idUsers = mapAnalysis.get(book.cuco__gf_profitability_sheet_id__c);
            }
            if (!idUsers.isEmpty()) {
                final CucoConstructor.DataBooks dataBooks = new CucoConstructor.DataBooks();
                dataBooks.idUser = idUsers;
                dataBooks.lstCurrentPP = mapCurrentPP.get(book.Id);
                dataBooks.book = book;
                mapToSend.put(book.Id,dataBooks);
            }
        }
        return mapToSend;
    }

}