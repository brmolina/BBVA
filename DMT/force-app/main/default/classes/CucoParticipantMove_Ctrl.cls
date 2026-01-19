/**
* ____________________________________________________________________________
* Controller class for participant_move.cmp aura Component
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-05-11
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global with sharing class CucoParticipantMove_Ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    public CucoParticipantMove_Ctrl() {

    }
    /**
    * @description Previous checks
    * @param iRecordId : Participant Id
    * @return Profitability Analysis Name
    */
	@AuraEnabled
	public static Map<String,Object> previousChecks (String iRecordId) {
        final cuco__profitability_analysis_participant__c pAParticipant = [SELECT Id, cuco__participant_id__c, cuco__gf_profitablity_analysis_id__c, cuco__gf_profitablity_analysis_id__r.cuco__gf_profitability_sheet_id__c FROM cuco__profitability_analysis_participant__c WHERE Id = :iRecordId];
		final List<cuco__profitability_analysis_participant__c> pAParticipants = [SELECT Id, cuco__gf_profitablity_analysis_id__c FROM cuco__profitability_analysis_participant__c WHERE cuco__gf_profitablity_analysis_id__c = :pAParticipant.cuco__gf_profitablity_analysis_id__c];
		Map<String, Object> retMap = new Map<String, Object>();
		if (pAParticipants.size() < 2) {
			retMap.put('errorParticipants', true);
			retMap.put('errorMessage', Label.cuco.remove_last_participant_error);
		} else {
			try {
				retMap = cuco.Participants_Service.doPreviousChecksDeletePAP(iRecordId);
				retMap.put('participantId', pAParticipant.cuco__participant_id__c);
                retMap.put('profAnId', pAParticipant.cuco__gf_profitablity_analysis_id__c);
			} catch (Exception e) { // NOSONAR
				throw new AuraHandledException(Label.cuco.generic_error + ' ' + e.getMessage()); // NOSONAR
			}
			final Map<String,Object> mapDetails = cuco.ProfitabilitySheet_Service.getProfSheetFullDetails(pAParticipant.cuco__gf_profitablity_analysis_id__r.cuco__gf_profitability_sheet_id__c);
			if((Boolean) mapDetails.get('success')) {
				final cuco.ProfitabilitySheet_Wrapper wrapperInfo = (cuco.ProfitabilitySheet_Wrapper) mapDetails.get('profSheetDetails');
				if(wrapperInfo.packagesList != null) {
					retMap.put('hasPackages',true);
				} else {
					retMap.put('hasPackages',false);
				}
				if(wrapperInfo.conditionsList.isEmpty()) {
					retMap.put('hasConditions',false);
				} else {
					retMap.put('hasConditions',true);
				}
				if(wrapperInfo.flatRates == null) {
					retMap.put('hasFlatRates',false);
				} else {
					retMap.put('hasFlatRates',true);
				}
			} else {
				retMap.put('success',false);
            	retMap.put('errMessage',mapDetails.get('errorMessage'));
			}
            
		}
        
        return retMap;
	}
	/**
    * @description Retrieve Profitability Sheets and Profitability Analysis related to the participant
    * @param iRecordId : Participant Id
    * @return List<cuco__profitability_sheet__c> with the list of  profitability sheets related to the participant
    */
	@AuraEnabled
	public static List<Move_Wrapper> getProfitabilitySheets (String iRecordId) {
		final cuco__pa_general_configuration__mdt genConfig = cuco.Utils.getGeneralConfiguration();
		List<Move_Wrapper> moveWrapperList = new List<Move_Wrapper>();
		// Get Profitability Sheets
		final cuco__profitability_analysis_participant__c pAParticipant = [SELECT Id, cuco__participant_id__r.DES_Main_Parent__c, cuco__gf_profitablity_analysis_id__r.cuco__gf_profitability_sheet_id__c FROM cuco__profitability_analysis_participant__c WHERE Id = :iRecordId];
		final List<cuco__profitability_sheet__c> profSheetList = [SELECT Id, Name FROM cuco__profitability_sheet__c WHERE cuco__participant_id__c = :pAParticipant.cuco__participant_id__r.DES_Main_Parent__c AND cuco__gf_prftbly_sheet_stt_desc__c = 'Valid' AND cuco__gf_prftbly_sheet_seg_type_name__c = :genConfig.cuco__segment_type__c ORDER BY Name];
		Set<Id> profitabilitySheetIdSet = new Set<Id>();
		List<cuco__profitability_sheet__c> profitabilitySheetListFiltered = new List<cuco__profitability_sheet__c>();
		for (cuco__profitability_sheet__c profitabilitySheet : profSheetList) {
			if(profitabilitySheet.Id != pAParticipant.cuco__gf_profitablity_analysis_id__r.cuco__gf_profitability_sheet_id__c){
				profitabilitySheetIdSet.add(profitabilitySheet.Id);
				profitabilitySheetListFiltered.add(profitabilitySheet);
			}
		}
		Set<Id> profitabilitySheetIddSet = new Set<Id>();
		// Profitability Sheets with an Analysis in Status 'Price Approval' or 'Formalization' should not appear on the list
		Set<String> profitabilityAnalysisStatusdSet = new Set<String>{'Price Approval', 'Formalization'};
		for (cuco__profitability_analysis__c profitabilityAnalysis : [SELECT Id, cuco__gf_profitability_sheet_id__c FROM cuco__profitability_analysis__c WHERE cuco__gf_profitability_sheet_id__c IN :profitabilitySheetidSet AND cuco__gf_pa_mgmt_stage_type_name__c IN :profitabilityAnalysisStatusdSet]) {
			profitabilitySheetIddSet.add(profitabilityAnalysis.cuco__gf_profitability_sheet_id__c);
		}
		for (cuco__profitability_sheet__c profitabilitySheet : profitabilitySheetListFiltered) {
			Move_Wrapper moveWrapper = new Move_Wrapper();
			if (!profitabilitySheetIddSet.contains(profitabilitySheet.Id)) {
				moveWrapper.name = profitabilitySheet.Name;
				moveWrapper.id = profitabilitySheet.Id;
				moveWrapperList.add(moveWrapper);
			}
		}
		// Get Profitability Analysis
		for (cuco__profitability_analysis__c profitabilityAnalysis : [SELECT Id, Name FROM cuco__profitability_analysis__c WHERE cuco__participant_id__c = :pAParticipant.cuco__participant_id__r.DES_Main_Parent__c AND cuco__gf_profitability_sheet_id__c = null AND cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis' AND cuco__segment_type__c = :genConfig.cuco__segment_type__c ORDER BY Name]) {
			Move_Wrapper moveWrapper = new Move_Wrapper();
			moveWrapper.name = profitabilityAnalysis.Name + ' ' + Label.cuco_move_request_in_analysis;
			moveWrapper.id = profitabilityAnalysis.Id;
			moveWrapperList.add(moveWrapper);
		}
        return moveWrapperList;
	}
	/**
    * @description Retrieve Profitability Analysis Name
    * @param profAId : Profitability Analysis Id
    * @return Profitability Analysis Name
    */
	@AuraEnabled
	public static String getProfitabilityAnalysisName (String profAId) {
		final cuco__profitability_analysis__c profA = [SELECT Name FROM cuco__profitability_analysis__c WHERE Id = :profAId];
		return profA.Name;
	}
	/**
    * @description Move participant
	* @param create : create new Profitability Analysis
	* @param existing : add participant to existing Profitability Analysis
    * @param name : Profitanility Analysis Name
	* @param profSheetId : Id of the Profitanility Sheet to clone from
	* @param iRecordId : Participant Id
	* @param profAnId : Profitability Analysis Id
	* @param clonefr : Boolean to clone Flat Rates
	* @param clonesc : Boolean to clone Special conditions
	* @param participantId: Account Id
    * @return Map<String,Object> with info of the new record of profitability analysis in case is created or creation errors
    */
	@AuraEnabled
	public static Map<String,Object> moveParticipant(Boolean create, Boolean existing, String name, Id profSheetId, String iRecordId, String profAnId, Boolean clonefr, Boolean clonesc, String participantId) {	
		final String partId = participantId;
		Id originId = profSheetId;
		if (profSheetId == null) {
			final cuco__profitability_analysis__c pAnalysis = [SELECT cuco__gf_profitability_sheet_id__c FROM cuco__profitability_analysis__c WHERE Id = :profAnId];
			originId = pAnalysis.cuco__gf_profitability_sheet_id__c;
		}
		Map<String, Object> retMap = new Map<String, Object>();
		if (create) {
			final String typology = 'New';
			retMap = createProfitabilityAnalysis(create, name, originId, partId, clonefr, clonesc, typology, profAnId);
		} else if (existing) {
			final String sObjectName = cuco.Utils.getObjectAPIName(profSheetId);
			if(sObjectName == 'cuco__profitability_sheet__c') {
				retMap = addParticipant(originId, partId, profAnId);
			} else if (sObjectName == 'cuco__profitability_analysis__c') {
				retMap = addParticipant(profSheetId, partId, profAnId);
			}
		}
		return retMap;
	}
	/**
    * @description Create Profitability Analysis
    * @param name : Profitanility Analysis Name
	* @param profSheetId : Id of the Profitanility Sheet to clone from
	* @param partId : Participant Id
	* @param clonefr : Boolean to clone Flat Rates
	* @param clonesc : Boolean to clone Special conditions
	* @param typology : String
	* @param profAnId : Original Profitability Analisys
    * @return Map<String,Object> with info of the new record of profitability analysis in case is created or creation errors
    */
	@AuraEnabled
	public static Map<String,Object> createProfitabilityAnalysis(Boolean create, String name, Id profSheetId, String partId, Boolean clonefr, Boolean clonesc, String typology, Id profAnId) {
		Map<String, Object> retMap = new Map<String, Object>();
		final Map<String,Object> mapDetails = cuco.ProfitabilitySheet_Service.getProfSheetFullDetails(profSheetId);
		if((Boolean) mapDetails.get('success')) {
			final cuco.ProfitabilitySheet_Wrapper wrapperInfo = (cuco.ProfitabilitySheet_Wrapper) mapDetails.get('profSheetDetails');
			final cuco.ProfitabilitySheet_Wrapper wrapperUpdated = updateWrapper(wrapperInfo, create, name, partId, clonefr, clonesc);
			final Map<String,Object> permissions = cuco.Request_Helper.checkPermissions(wrapperUpdated, userInfo.getUserId(),typology);
            if(permissions.get('canCreate') == true) {
                final Map<String,Object> mapAnalysisFinal = cuco.Request_Helper.createProfAnalysis(wrapperUpdated, typology);
                retMap = checkAnalysis(mapAnalysisFinal);
				string profAId = String.valueof(retMap.get('profAId'));
				retMap.put('profAName', getProfitabilityAnalysisName(profAId));
				retMap = updateProfAnPart(partId, profAnId, retMap);
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
    * @description Update Profitanility Sheet Wrapper
    * @param wrapperInfo : Profitanility Sheet Wrapper
	* @param create : create new Profitability Analysis
	* @param name : Profitanility Analysis Name
	* @param partId : Participant Id
	* @param clonefr : Boolean to clone Flat Rates
	* @param clonesc : Boolean to clone Special conditions
    * @return static cuco.ProfitabilitySheet_Wrapper> with Profitanility Sheet Wrapper updated
    */
	@AuraEnabled
	public static cuco.ProfitabilitySheet_Wrapper updateWrapper(cuco.ProfitabilitySheet_Wrapper wrapperInfo, Boolean create, String name, String partId, Boolean clonefr, Boolean clonesc) {
		cuco.ProfitabilitySheet_Wrapper wrapperUpdated = wrapperInfo;
		// Clear Profitability Sheet Id
		if(create) {
			wrapperUpdated.id = null;
            wrapperUpdated.participantsList.clear();
		}      
		cuco.ProfitabilitySheet_Wrapper.Participant participant = new cuco.ProfitabilitySheet_Wrapper.Participant();
        participant.Id = partId;
        wrapperUpdated.participantsList.add(participant);
		// Clear Packages
		wrapperUpdated.packagesList = new List<cuco.Package_Wrapper>();
		// Overwrite Name
		if (name != '') {
			wrapperUpdated.name = name;
		}
		// Clear Flat Rates
		if (clonefr == false) {
			wrapperUpdated.flatRates = null;
			List<cuco.ProfitabilitySheet_Wrapper.Condition> noFlatConditions = new List<cuco.ProfitabilitySheet_Wrapper.Condition>();
			for (cuco.ProfitabilitySheet_Wrapper.Condition condition : wrapperUpdated.conditionsList) {
				if (condition.source != 'COMMISSIONS_FLAT') {
					noFlatConditions.add(condition);
				}
			}
			wrapperUpdated.conditionsList = noFlatConditions;
		}
		// Clear Conditions
		if (clonesc == false) {
			List<cuco.ProfitabilitySheet_Wrapper.Condition> onlyFlatConditions = new List<cuco.ProfitabilitySheet_Wrapper.Condition>();
			for (cuco.ProfitabilitySheet_Wrapper.Condition condition : wrapperUpdated.conditionsList) {
				if (condition.source == 'COMMISSIONS_FLAT') {
					onlyFlatConditions.add(condition);
				}
			}
			wrapperUpdated.conditionsList = onlyFlatConditions;
		}
        return wrapperUpdated;
	}
	/**
    * @description Remove participant from origin Profitability Analysis
    * @param recordId : Id of the related profitability analysis participant
    * @param firstWarning : User selection of the first modal stage
    * @return Map<String, Object>, with the needed info
    */
	@AuraEnabled
	public static Map<String,Object> removeParticipant (Id recordId, String firstWarning) {
		try {
            return cuco.Participants_Service.doRemoveActions(recordId, firstWarning);
        } catch (Exception e) { // NOSONAR
            throw new AuraHandledException(Label.cuco.generic_error + ' ' + e.getMessage()); // NOSONAR
        }
	}
	/**
    * @description Add participant to existing or new Profitability Analysis
    * @param profSheetId : Profitanility Sheet Id
	* @param partId : Participant Id
	* @param profAnId : Original Profitability Analysis Id
    * @return Map<String,Object> with info of the new/updated record of profitability analysis or creation errors
    */
	@AuraEnabled
	public static Map<String,Object> addParticipant (Id profSheetId, String partId, String profAnId) {
		List<cuco__profitability_analysis__c> profitabilityAnalysis = new List<cuco__profitability_analysis__c>();
		final String sObjectName = cuco.Utils.getObjectAPIName(profSheetId);
		if(sObjectName == 'cuco__profitability_sheet__c') {
			profitabilityAnalysis = [SELECT Id, Name FROM cuco__profitability_analysis__c WHERE cuco__gf_profitability_sheet_id__c = :profSheetId AND cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis'];
		} else if (sObjectName == 'cuco__profitability_analysis__c') {
			profitabilityAnalysis = [SELECT Id, Name FROM cuco__profitability_analysis__c WHERE Id = :profSheetId AND cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis'];
		}
		Map<String, Object> retMap = new Map<String, Object>();
		if(profitabilityAnalysis.isEmpty()) {
			final String typology = 'Novation';
			retMap = createProfitabilityAnalysis(false, '', profSheetId, partId, true, true, typology, profAnId);
		} else {
			List<Id> lstAccsId = new List<Id>();
			lstAccsId.add(partId);
			retMap = cuco.Participants_Service.manageAddNewParticipants(profitabilityAnalysis[0].Id, lstAccsId);
			if ((Boolean) retMap.get('isSuccess')) {
				retMap = new Map<String, Object>();
				retMap.put('success', true);
				retMap.put('profAId', profitabilityAnalysis[0].Id);
				retMap.put('profAName', getProfitabilityAnalysisName(profitabilityAnalysis[0].Id));
				retMap = updateProfAnPart(partId, profAnId, retMap);
			}
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
    * @description private method to update cuco__profitability_analysis_participant__c record
    * @param partId : Participant Id
	* @param profAnId : Oiginal Profitability Analisis Id
	* @param retMap : Previous Response
    * @return Map<String,Object> map with info to return
    */
    private static Map<String,Object> updateProfAnPart(Id partId, Id profAnId, Map<String,Object> retMap) {
        cuco__profitability_analysis_participant__c profAnPart = [SELECT moved_from__c FROM cuco__profitability_analysis_participant__c WHERE cuco__participant_id__c = :partId AND cuco__gf_profitablity_analysis_id__c = :String.valueof(retMap.get('profAId')) limit 1];
		profAnPart.moved_from__c = profAnId;
		update profAnPart;
        return retMap;
    }
	/**
    * @description Wrapper used to show profitability sheet and profitability analysis
    */
	public class Move_Wrapper {
		@AuraEnabled
		public String name {get; set;}
		@AuraEnabled
		public String id {get; set;}
	}
}