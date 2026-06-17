/**
* ____________________________________________________________________________
* Controller class for cuco_clone_profitability_sheet.cmp aura Component
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-04-21
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class CucoCloneProfitabilitySheet_Ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    @TestVisible
    private CucoCloneProfitabilitySheet_Ctrl() {}
    /**
    * @description clone profitability sheet
    * @param name : Profitanility Analysis Name
	* @param profSheetId : Id of the Profitanility Sheet to clone from
	* @param groupId : Group Id
	* @param clonefr : Boolean to clone Flat Rates
	* @param clonesc : Boolean to clone Special conditions
    * @return Map<String,Object> with info of the new record of profitability analysis in case is created or creation errors
    */
    @AuraEnabled
    public static Map<String,Object> clone(String name, Id profSheetId, Id groupId, Boolean clonefr, Boolean clonesc) {
        Map<String, Object> retMap = new Map<String, Object>();

        // First check for inactive participants before proceeding
        if(hasInactiveParticipant(profSheetId)) {
            retMap.put('success', false);
            retMap.put('errMessage', 'Cannot clone profitability sheet that contains inactive participants.');
            return retMap;
        }

        final Map<String,Object> mapDetails = cuco.ProfitabilitySheet_Service.getProfSheetFullDetails(profSheetId);
        if((Boolean) mapDetails.get('success')) {
            final cuco.ProfitabilitySheet_Wrapper wrapperInfo = (cuco.ProfitabilitySheet_Wrapper) mapDetails.get('profSheetDetails');
            final String typology = 'New';
            // Clear Profitability Sheet Id
            wrapperInfo.id = null;
            // Clear Participants
            wrapperInfo.participantsList = new List<cuco.ProfitabilitySheet_Wrapper.Participant>();
            // Clear Packages
            wrapperInfo.packagesList = new List<cuco.Package_Wrapper>();
            // Overwrite Name
            wrapperInfo.name = name;
            // Overwrite groupId
            wrapperInfo.groupId = groupId;
            // Clear Flat Rates
            if (clonefr == false) {
                wrapperInfo.flatRates = null;
                List<cuco.ProfitabilitySheet_Wrapper.Condition> noFlatConditions = new List<cuco.ProfitabilitySheet_Wrapper.Condition>();
                for (cuco.ProfitabilitySheet_Wrapper.Condition condition : wrapperInfo.conditionsList) {
                    if (condition.source != 'COMMISSIONS_FLAT') {
                        noFlatConditions.add(condition);
                    }
                }
                wrapperInfo.conditionsList = noFlatConditions;
            }
            // Clear Conditions
            if (clonesc == false) {
                List<cuco.ProfitabilitySheet_Wrapper.Condition> onlyFlatConditions = new List<cuco.ProfitabilitySheet_Wrapper.Condition>();
                for (cuco.ProfitabilitySheet_Wrapper.Condition condition : wrapperInfo.conditionsList) {
                    if (condition.source == 'COMMISSIONS_FLAT') {
                        onlyFlatConditions.add(condition);
                    }
                }
                wrapperInfo.conditionsList = onlyFlatConditions;
            }
            final Map<String,Object> permissions = cuco.Request_Helper.checkPermissions(wrapperInfo, userInfo.getUserId(),typology);
            if(permissions.get('canCreate') == true) {
                final Map<String,Object> mapAnalysisFinal = cuco.Request_Helper.createProfAnalysis(wrapperInfo, typology);
                retMap = CucoCloneProfitabilitySheet_Ctrl.checkAnalysis(mapAnalysisFinal);
            } else {
                retMap.put('success',false);
                retMap.put('errMessage',permissions.get('message'));
            }
        } else {
            retMap.put('success',false);
            retMap.put('errMessage',mapDetails.get('errorMessage'));
        }
        return retMap;
    }
    /**
    * @description private method to check if profitability analysis has been created
    * @param mapAnalysisFinal : Map with info to catch
    * @return Map<String,Object> map with info to return
    */
    private static Map<String,Object> checkAnalysis(Map<String,Object> mapAnalysisFinal) {
        final Map<String,Object> retMap = new Map<String,Object>();
        if(mapAnalysisFinal.get('isSuccess') == true) {
            retMap.put('success',true);
            retMap.put('profAId',mapAnalysisFinal.get('profAId'));
        } else {
            retMap.put('success',false);
            retMap.put('errMessage',Label.cuco.creation_error + mapAnalysisFinal.get('errMessage'));
        }
        return retMap;
    }

    /**
    * @description Checks if the profitability sheet has any inactive participants
    * @param profSheetId The ID of the profitability sheet
    * @return Boolean true if inactive participants exist, false otherwise
    */
    private static Boolean hasInactiveParticipant(Id profSheetId) {
        // Query the participants related to the profitability sheet and check their status
        List<cuco__profitability_sheet_participant__c> inactiveParticipants = [
            SELECT Id 
            FROM cuco__profitability_sheet_participant__c 
            WHERE cuco__gf_profitability_sheet_id__c = :profSheetId 
            AND cuco__participant_id__r.gf_prtcpt_act_status_ind_type__c != true
        ];
        
        return !inactiveParticipants.isEmpty();
    }
}