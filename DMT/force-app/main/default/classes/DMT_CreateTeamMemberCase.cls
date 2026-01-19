public without sharing class DMT_CreateTeamMemberCase {
    public class InputWrapper {
        @InvocableVariable
        public Id caseId;
        @InvocableVariable
        public Boolean sanctionEdit;
    }

    @InvocableMethod(label = 'Create Team Member' description = 'Se hacen comprobaciones para poder crear team members con acceso Read Only')
    public static void createTeamMemberCase(List<InputWrapper> inputIds) {

        try {
            Id caseId = inputIds[0].caseId;
            Boolean sanctionEdit = inputIds[0].sanctionEdit;

            Case caseRecord = [SELECT Id, DMT_Line__c, opportunity_id__c, OwnerId FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED LIMIT 1];

            // Se comprueba que el OwnerId es una cola y empieza con 00G
            if (String.valueOf(caseRecord.OwnerId).startsWith('00G') && caseRecord.DMT_Line__c != null) {
                Group caseOwner = [SELECT DeveloperName, Name FROM Group WHERE Id = :caseRecord.OwnerId WITH SECURITY_ENFORCED LIMIT 1];

                // Se comprueba que hay un grupo aprobador con la misma cola
                if (caseOwner != null) {
                    DMT_Approver__c approver = [SELECT Id, DMT_Group__c FROM DMT_Approver__c WHERE DMT_Group__c = :caseOwner.DeveloperName WITH SECURITY_ENFORCED LIMIT 1];

                    // Se comprueba que hay miembros aprobadores en el grupo aprobador
                    if(approver != null) {
                        List<DMT_Approver_Member__c> approverMembers = [SELECT Id, DMT_Approver__c, DMT_Approver__r.Name, DMT_User__c, DMT_User__r.Name FROM DMT_Approver_Member__c WHERE DMT_Approver__c = :approver.Id WITH SECURITY_ENFORCED];

                        if (!approverMembers.isEmpty()) {
                            // Se realiza una query para comprobar los participantes que hay en una línea
                            List<DMT_TeamMember__c> teamMembersLine = DMT_TeamMember_Selector.getTeamMemberLines(caseRecord.DMT_Line__c);

                            Set<Id> teamMembersLineSetId = new Set<Id>();
                            Set<Id> approversLineSetId = new Set<Id>();
                            String currentLineStatus = 'Draft';

                            if (!teamMembersLine.isEmpty()) {
                                for (DMT_TeamMember__c teamMember : teamMembersLine) {
                                    teamMembersLineSetId.add(teamMember.User__c);
                                }
                            }
                            system.debug('approverMembers '+ approverMembers.size());
                            if (sanctionEdit && !approverMembers.isEmpty()) {
                                for (DMT_Approver_Member__c approverMember : approverMembers) {
                                    approversLineSetId.add(approverMember.DMT_User__c);
                                }
                            system.debug('approversLineSetId '+ approversLineSetId.size());
                            List<DMT_TeamMember__c> currentMembersLine = DMT_TeamMember_Selector.getTeamMemberLinesApprover(caseRecord.DMT_Line__c, approversLineSetId);



                            system.debug('current '+ currentMembersLine.size());
                            if(!currentMembersLine.isEmpty()){

                                currentLineStatus = currentMembersLine[0].Line__r.Status__c;

                                for(DMT_TeamMember__c currentTeamMember : currentMembersLine){
                                    currentTeamMember.AccessLevel__c = 'Edit';

                                    if(currentLineStatus == 'Draft'){
                                        currentTeamMember.Team_Role__c = 'validator';
                                    } else {
                                        currentTeamMember.Team_Role__c = 'approver';
                                    }

                                    currentTeamMember.DMT_ApprovalEdit__c = true;
                                }
                                update currentMembersLine;
                            }
                            }

                            List<DMT_TeamMember__c> newTeamMembers = new List<DMT_TeamMember__c>();
                            Set<Id> processedApproverMembersSetId = new Set<Id>();

                            // Se comprueban los miembros aprobadores y los participantes de la línea para no duplicar participantes
                            for (DMT_Approver_Member__c approverMember : approverMembers) {
                                if ((teamMembersLine.isEmpty() && !processedApproverMembersSetId.contains(approverMember.DMT_User__c)) || (!teamMembersLineSetId.contains(approverMember.DMT_User__c) && !processedApproverMembersSetId.contains(approverMember.DMT_User__c))) {
                                    DMT_TeamMember__c newTeamMember = new DMT_TeamMember__c();
                                    newTeamMember.User__c = approverMember.DMT_User__c;
                                    newTeamMember.AccessLevel__c = sanctionEdit ? 'Edit' : 'Read';
                                    newTeamMember.Team_Role__c = 'approver';

                                    if(currentLineStatus == 'Draft'){
                                        newTeamMember.Team_Role__c = 'validator';
                                    } else {
                                        newTeamMember.Team_Role__c = 'approver';
                                    }

                                    newTeamMember.DMT_ApprovalEdit__c = sanctionEdit;
                                    newTeamMember.Name = approverMember.DMT_User__r.Name;
                                    newTeamMember.Line__c = caseRecord.DMT_Line__c;
                                    newTeamMember.Opportunity__c = caseRecord.opportunity_id__c;

                                    newTeamMembers.add(newTeamMember);

                                    processedApproverMembersSetId.add(approverMember.DMT_User__c);
                                }
                            }
                            system.debug('size '+ newTeamMembers.size());
                            if (!newTeamMembers.isEmpty()) {
                                insert newTeamMembers;
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_CreateTeamMemberCase', 'invokeCreateTeamMember', 'DMT', '');
        }
    }


}