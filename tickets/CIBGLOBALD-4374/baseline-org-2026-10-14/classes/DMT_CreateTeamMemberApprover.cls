public without sharing class DMT_CreateTeamMemberApprover {
    public class InputWrapper {
        @InvocableVariable
        public List<DMT_Approver_Member__c> listCreatedApproverMembers;
        @InvocableVariable
        public Id groupId;
        @InvocableVariable
        public List<DMT_Approver_Member__c> oldApproverMembers;
    }

    @InvocableMethod(label = 'createTeamMemberFromApproverMember' description = 'Se hacen comprobaciones para poder crear team members a partir de los approver members creados')
    public static void invokeCreateTeamMember(List<InputWrapper> input) {

        try {
            List<DMT_Approver_Member__c> listCreatedApproverMembers = input.get(0).listCreatedApproverMembers;
            Id groupId =  input.get(0).groupId;
            List<DMT_Approver_Member__c> oldApproverMembers = input.get(0).oldApproverMembers;
            Set<Id> usersFromCreatedApproverMembers = new Set<Id>();
            Set<Id> usersToDeleteFromParticipants = new Set<Id>();

            for (DMT_Approver_Member__c approverMember : listCreatedApproverMembers) {
                usersFromCreatedApproverMembers.add(approverMember.DMT_User__c);
            }

            if (oldApproverMembers != null) {
                for (DMT_Approver_Member__c approverMember : oldApproverMembers) {
                    if (approverMember != null && !usersFromCreatedApproverMembers.contains(approverMember.DMT_User__c)) {
                        usersToDeleteFromParticipants.add(approverMember.DMT_User__c);
                    }
                }
            }

            List<Case> caseRecords = [SELECT Id, DMT_Line__c, opportunity_id__c, OwnerId FROM Case WHERE OwnerId = :groupId WITH USER_MODE];
            List<DMT_TeamMember__c> newTeamMembers = new List<DMT_TeamMember__c>();
            List<DMT_TeamMember__c> teamMembersToDelete = new List<DMT_TeamMember__c>();
            Map<Id, Id> casesWithLines = new Map<Id, Id>();


            for (Case caseRecord : caseRecords) {
                casesWithLines.put(caseRecord.Id, caseRecord.DMT_Line__c);
            }
            Map<Id, List<DMT_TeamMember__c>> lineWithTeamMembers = new Map<Id, List<DMT_TeamMember__c>>();

            List<DMT_TeamMember__c> teamMembersFromLines = DMT_TeamMember_Selector.getTeamMemberLinesBaseInCaseLines(casesWithLines.values());
            for (DMT_TeamMember__c teamMember : teamMembersFromLines) {
                List<DMT_TeamMember__c> teamMembers = new List<DMT_TeamMember__c>();
                if (lineWithTeamMembers.containsKey(teamMember.Line__c)) {
                    teamMembers = lineWithTeamMembers.get(teamMember.Line__c);
                }
                teamMembers.add(teamMember);
                lineWithTeamMembers.put(teamMember.Line__c, teamMembers);
            }


            for (Id lineId : lineWithTeamMembers.keySet()) {
                List<DMT_TeamMember__c> teamMembersLine = lineWithTeamMembers.get(lineId);
                // Se realiza una query para comprobar los participantes que hay en una línea
                Map<Id, DMT_TeamMember__c> teamMembersLineMapUser = new Map<Id, DMT_TeamMember__c>();
                if (!teamMembersLine.isEmpty()) {
                    for (DMT_TeamMember__c teamMember : teamMembersLine) {
                        teamMembersLineMapUser.put(teamMember.User__c, teamMember);
                    }
                }

                Set<Id> processedApproverMembersSetId = new Set<Id>();

                // Se comprueban los miembros aprobadores y los participantes de la línea para no duplicar participantes
                if (!teamMembersLineMapUser.isEmpty()) {
                    for (DMT_Approver_Member__c approverMember : listCreatedApproverMembers) {
                        if ((!teamMembersLineMapUser.containsKey(approverMember.DMT_User__c) && !processedApproverMembersSetId.contains(approverMember.DMT_User__c))) {
                            DMT_TeamMember__c newTeamMember = new DMT_TeamMember__c();
                            newTeamMember.User__c = approverMember.DMT_User__c;
                            newTeamMember.AccessLevel__c = 'Read';
                            newTeamMember.Team_Role__c = 'approver';
                            newTeamMember.Name = approverMember.DMT_User__r.Name;
                            newTeamMember.Line__c = lineId;
                            newTeamMembers.add(newTeamMember);
                            processedApproverMembersSetId.add(approverMember.DMT_User__c);
                        }
                    }
                    for (Id userToDelete : usersToDeleteFromParticipants) {
                        if (teamMembersLineMapUser.containsKey(userToDelete) && teamMembersLineMapUser.get(userToDelete).AccessLevel__c != 'All') {
                            DMT_TeamMember__c teamMemberToDelete = new DMT_TeamMember__c();
                            teamMemberToDelete.Id = teamMembersLineMapUser.get(userToDelete).Id;
                            teamMembersToDelete.add(teamMemberToDelete);
                        }
                    }
                }
            }
            if (!newTeamMembers.isEmpty()) {
                insert newTeamMembers;
            }
            if (!teamMembersToDelete.isEmpty()) {
                delete teamMembersToDelete;
            }
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_CreateTeamMemberApprover', 'invokeCreateTeamMember', 'DMT', '');
        }
    }
}