/**
* ────────────────────────────────────────────────────────────────────
* PA_Validations_Controller_Sample
* Sample implementation of profitability analysis validations controller
* ────────────────────────────────────────────────────────────────────
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-06-10
* @modified
* @systemLayer Service
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class CucoValidationsCIB implements dwp_dbpn.DynamicFlowValidationInterface {

    /**
    * @description interfaz method implementation
    */
    global List<String> getErrorMessagesList(String recordId, String sObjectName, String source) {
        return checkButtonValidations(recordId, source);
    }

    /**
    * @description validate buttons
    */
    global static List<String> checkButtonValidations(String recordId, String sourceButtonId) {
        final List<String> retList = new List<String>();
        final cuco__pa_general_configuration__mdt genConfig = cuco.Utils.getGeneralConfiguration();
        final cuco.ProfitabilityAnalysis_Wrapper paWrapper = cuco.ProfitabilityAnalysis_Helper.getProfAnalysis(recordId);
        switch on sourceButtonId {
            when 'PA_Formalization_Sample' {
                retList.addAll(checkPAFormalization(paWrapper, genConfig));
            }
        }
        return retList;
    }

    /**
    * @description return check of prof analysis formalization sample
    */
    private static List<String> checkPAFormalization(cuco.ProfitabilityAnalysis_Wrapper paWrapper, cuco__pa_general_configuration__mdt genConfig) {
        final List<String> retList = new List<String>();
        retList.addAll(cuco.ValidationsProfAnalysis_Helper.checkBranch(paWrapper));
        retList.addAll(cuco.ValidationsProfAnalysis_Helper.checkMainParticipant(paWrapper));
        retList.addAll(cuco.ValidationsProfAnalysis_Helper.checkSegment(paWrapper, genConfig));

        retList.addAll(checkParticipant(paWrapper, genConfig));
        retList.addAll(checkParticipantMoved(paWrapper));

        if (retList.size() == 0) {
            final Map<String,Map<String,Map<String,String>>> condPerFamily = cuco.ValidationsCondGeneral_Helper.getConditionsPerFamily(paWrapper);
            retList.addAll(cuco.ValidationsProfAnalysis_Helper.checkRenewalMargin(paWrapper, genConfig));
            retList.addAll(cuco.ValidationsProfAnalysis_Helper.checkBackendLastDate(paWrapper));
            retList.addAll(cuco.ValidationsPrice_Helper.checkNegValidity(paWrapper, genConfig));
            retList.addAll(cuco.ValidationsPackages_Helper.checkNumExtendedPkgs(paWrapper));
            retList.addAll(cuco.ValidationsPackages_Helper.checkNumParticipants(paWrapper));
            retList.addAll(cuco.ValidationsPackages_Helper.checkExtendedPkgsStatus(paWrapper));
            retList.addAll(cuco.ValidationsFlat_Helper.checkMandatoryInfo(paWrapper));
            retList.addAll(cuco.ValidationsCondGeneral_Helper.checkValuesRange(paWrapper));
            retList.addAll(cuco.ValidationsCondGeneral_Helper.checkMailExpenses(paWrapper));
            retList.addAll(cuco.ValidationsCondGeneral_Helper.checkNPTransCond(condPerFamily));
            retList.addAll(cuco.ValidationsCondGeneral_Helper.checkDuplicateConditions(paWrapper));
            retList.addAll(cuco.ValidationsCondGeneral_Helper.checkSEPAPriceClass(condPerFamily));
            retList.addAll(cuco.ValidationsCondGeneral_Helper.checkRate55Cond(condPerFamily));
            retList.addAll(cuco.ValidationsCondGeneral_Helper.checkRate(condPerFamily));
            retList.addAll(cuco.ValidationsCondGeneral_Helper.checkRateWhenBonus(condPerFamily));
            retList.addAll(checkExemptMailWhenBonus(condPerFamily));
        }
        return retList;
    }

    /**
    * @description CUSTOM Check if the participants hierarchy is valid
    * CIB Workaround to not check whether all participants belong to the same group (by metadata setting)
    * CIB Workaround to not check when cancelling
    * @param paWrapper : Prof analysis wrapper info
    * @param genConfig : Metadata record with the general configuration of classes
    * @return List<String>, with check errors
    */
    global static List<String> checkParticipant(cuco.ProfitabilityAnalysis_Wrapper paWrapper, cuco__pa_general_configuration__mdt genConfig) {

        final List<String> res = new List<String>();
        final cuco__pa_general_configuration__mdt extConfig = cuco__pa_general_configuration__mdt.getInstance(genConfig.DeveloperName);
        final Boolean validateGroups = extConfig.validate_participants_group__c;
        Type participantClass;

        if(Test.isRunningTest()) {
            participantClass = Type.forName('cuco.' + genConfig.cuco__participants_itf_name__c);
        } else {
            participantClass = Type.forName(genConfig.cuco__participants_itf_name__c);
        }

        final cuco.Participant_itf participantItf = (cuco.Participant_itf) participantClass.newInstance();
        final cuco.ParticipantHierarchy_Wrapper partHierWrapp = participantItf.getParticipantHierarchy(paWrapper.mainParticipant.accountid);

        if (paWrapper.typology != 'Cancellation') { //NOSONAR
            switch on partHierWrapp.type {
                when 'group' {
                    res.addAll(validateGroups(paWrapper, partHierWrapp, validateGroups));
                } when 'orphan' {
                    res.addAll(validateOrphans(paWrapper));
                } when else {
                    res.add(Label.cuco.error_main_participant_type);
                }
            }
        }
        return res;
    }

    /**
    * @description validate group participants.
    */
    private static List<String> validateGroups(cuco.ProfitabilityAnalysis_Wrapper paWrapper, cuco.ParticipantHierarchy_Wrapper partHierWrapp, Boolean validateGroups) {

       final List<String> res = new List<String>();
       final Integer numParticipants = paWrapper.participantsList == null ? 0 : paWrapper.participantsList.size();

        if (numParticipants == 0) {
            res.add(Label.cuco.error_group_participant_num);
        }

        if(numParticipants > 0 && validateGroups) {
            final List<String> outsiders = getOutsiders(paWrapper.participantsList, partHierWrapp.childIdsSet);
            if (outsiders.size() > 0) {
                res.add(Label.cuco.error_group_participants_childs);
                final List<Account> clients = [SELECT Id, Name, DES_ID_Fiscal__c, DES_Main_Parent__r.Name from Account WHERE Id IN :outsiders];
                for (Account client : clients) {
                    res.add(client.DES_ID_Fiscal__c + ' - ' + client.Name + ' belongs to ' + client.DES_Main_Parent__r.Name);
                }
            }
        }
        return res;
    }

    /**
    * @description validate orphan participants.
    */
    private static List<String> validateOrphans(cuco.ProfitabilityAnalysis_Wrapper paWrapper) {
        final List<String> res = new List<String>();
        final Integer numParticipants = paWrapper.participantsList == null ? 0 : paWrapper.participantsList.size();
        if (numParticipants > 1) {
            res.add(Label.cuco.error_orphan_participant_num);
        } else if (numParticipants == 1 && paWrapper.participantsList[0].accountid != paWrapper.mainParticipant.accountid) {
            res.add(Label.cuco.error_orphan_participant_match);
        }
        return res;
    }

    /**
    * @description Method to check condition 'np.bonus' and 'np.exempt.mail' are selected together
    * @param condMap : Map with conditions
    * @return List<String>, with errors response
    */
    global static List<String> checkExemptMailWhenBonus(Map<String, Map<String, Map<String, String>>> condMap) {
        final List<String> retList = new List<String>();
        final Map<String,Map<String,String>> conditions = condMap.get('np.check');
        if (conditions != null && conditions.containsKey('np.bonus') != conditions.containsKey('np.exempt.mail')) {
            retList.add(Label.cuco_error_np_exempt_bonus_together);
        }
        return retList;
    }

    /**
    * @description return list of participants that do not belong to the group.
    */
    private static List<String> getOutsiders(List<cuco.ProfitabilityAnalysis_Wrapper.Participants> participantsList, Set<Id> childIdsSet) {
        final List<String> res = new List<String>();
        for (cuco.ProfitabilityAnalysis_Wrapper.Participants participant : participantsList) {
            if (!childIdsSet.contains(participant.accountid)) {
                res.add(participant.accountid);
            }
        }
        return res;
    }
    /**
    * @description Method to check if when a participant was moved original Profitability analysis has been formalized/dismissed
    * @return List<String>, with errors response
    */
    global static List<String> checkParticipantMoved(cuco.ProfitabilityAnalysis_Wrapper paWrapper) {

        final List<String> res = new List<String>();

        final Integer numParticipants = paWrapper.participantsList == null ? 0 : paWrapper.participantsList.size();

        if (numParticipants != 0) {
            Set<Id> participantsSet = new Set<Id>();
            for (cuco.ProfitabilityAnalysis_Wrapper.Participants participant : paWrapper.participantsList) {
                participantsSet.add(participant.Id);
            }
            Set<Id> profitabilityAnalysisSet = new Set<Id>();
            Map<Id, cuco__profitability_analysis_participant__c> participantsMovedMap = new Map<Id, cuco__profitability_analysis_participant__c>();
            for(cuco__profitability_analysis_participant__c participant : [SELECT moved_from__c FROM cuco__profitability_analysis_participant__c WHERE Id IN :participantsSet AND moved_from__c != null]) {
                profitabilityAnalysisSet.add(participant.moved_from__c);
                participantsMovedMap.put(participant.Id, participant);
            }
            Map<Id,cuco__profitability_analysis__c> profitabilityAnalysisMap = new Map<Id,cuco__profitability_analysis__c>();
            for(cuco__profitability_analysis__c profitabilityAnalysis : [SELECT Name, cuco__gf_pa_mgmt_stage_type_name__c FROM cuco__profitability_analysis__c WHERE Id IN :profitabilityAnalysisSet]) {
                profitabilityAnalysisMap.put(profitabilityAnalysis.Id, profitabilityAnalysis);
            }
            for(cuco.ProfitabilityAnalysis_Wrapper.Participants participant : paWrapper.participantsList) {
                if(participantsMovedMap.get(participant.Id) != null) {
                    cuco__profitability_analysis_participant__c profitabilityAnalysisParticipant = participantsMovedMap.get(participant.Id);
                    cuco__profitability_analysis__c profitabilityAnalysis = profitabilityAnalysisMap.get(profitabilityAnalysisParticipant.moved_from__c);
                    switch on profitabilityAnalysis.cuco__gf_pa_mgmt_stage_type_name__c {
                        when 'Formalization', 'Formalized' {
                        } when 'Dismissed' {
                            res.add(participant.name + ' ' + label.cuco_move_check_formalize_pre + ' ' +  profitabilityAnalysis.Name + ' ' + Label.cuco_move_check_formalize_dismissed_post);
                        } when else {
                            res.add(participant.name + ' ' + label.cuco_move_check_formalize_pre + ' ' +  profitabilityAnalysis.Name + ' ' + Label.cuco_move_check_formalize_post);
                        }
                    }
                }
            }
        }
        return res;
    }
}