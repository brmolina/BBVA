public without sharing class DMT_CreateTeamMemberCase implements Queueable {

    private Id caseId;
    private Boolean sanctionEdit;

    public class InputWrapper {
        @InvocableVariable public Id caseId;
        @InvocableVariable public Boolean sanctionEdit;
    }

    public DMT_CreateTeamMemberCase(Id caseId, Boolean sanctionEdit) {
        this.caseId = caseId;
        this.sanctionEdit = sanctionEdit;
    }

    @InvocableMethod(
        label = 'Create Team Member'
        description = 'Se hacen comprobaciones para poder crear team members con acceso Read Only'
    )
    public static void createTeamMemberCase(List<InputWrapper> inputIds) {
        if (inputIds == null || inputIds.isEmpty()) {
            return;
        }

        // Si ya estamos en un contexto asíncrono (p.ej. este Flow disparado desde el Case
        // creado dentro de DMT_Case_Steps_Controller.StartCaseQueueable), no podemos encolar
        // otro Queueable: el límite de jobs anidados en contexto async es 1, y ya lo consume
        // el Queueable que nos ha traído hasta aquí. Ejecutamos la lógica de forma síncrona
        // en su lugar, ya que processCase no hace callouts.
        Boolean isAlreadyAsync = System.isQueueable() || System.isBatch() || System.isFuture();

        for (InputWrapper input : inputIds) {
            if (input == null || input.caseId == null) {
                continue;
            }

            if (isAlreadyAsync) {
                processCase(input.caseId, input.sanctionEdit == true);
            } else {
                System.enqueueJob(
                    new DMT_CreateTeamMemberCase(
                        input.caseId,
                        input.sanctionEdit == true
                    )
                );
            }
        }
    }

    public void execute(QueueableContext context) {
        processCase(this.caseId, this.sanctionEdit);
    }

    private static void processCase(Id caseId, Boolean sanctionEdit) {
        try {
            Case caseRecord = [
                SELECT Id, DMT_Line__c, opportunity_id__c, OwnerId, DMT_Passport_Sanction__c
                FROM Case
                WHERE Id = :caseId
                WITH USER_MODE
                LIMIT 1
            ];

            if (caseRecord.DMT_Line__c == null && caseRecord.opportunity_id__c == null) {
                return;
            }

            if (!String.valueOf(caseRecord.OwnerId).startsWith('00G')) {
                return;
            }

            Group caseOwner = [
                SELECT DeveloperName, Name
                FROM Group
                WHERE Id = :caseRecord.OwnerId
                WITH USER_MODE
                LIMIT 1
            ];

            List<DMT_Approver__c> approvers = [
                SELECT Id, DMT_Group__c, DMT_ApproverType__r.Name
                FROM DMT_Approver__c
                WHERE DMT_Group__c = :caseOwner.DeveloperName
                WITH USER_MODE
                LIMIT 1
            ];

            if (approvers.isEmpty()) {
                return;
            }

            DMT_Approver__c approver = approvers[0];

            List<DMT_Approver_Member__c> approverMembers = [
                SELECT Id, DMT_Approver__c, DMT_Approver__r.Name, DMT_User__c, DMT_User__r.Name
                FROM DMT_Approver_Member__c
                WHERE DMT_Approver__c = :approver.Id
                AND DMT_User__r.IsActive = true
                WITH USER_MODE
            ];

            if (approverMembers.isEmpty()) {
                return;
            }

            Set<Id> existingTeamMemberUsersByLine = new Set<Id>();
            Set<Id> existingTeamMemberUsersByOpportunity = new Set<Id>();

            Map<String, DMT_TeamMember__c> teamMembersToUpdateMap = new Map<String, DMT_TeamMember__c>();

            if (caseRecord.DMT_Line__c != null) {
                List<DMT_TeamMember__c> teamMembersLine =
                    DMT_TeamMember_Selector.getTeamMemberLines(caseRecord.DMT_Line__c);

                for (DMT_TeamMember__c tm : teamMembersLine) {
                    String key = String.valueOf(tm.User__c) + '_Line';
                    existingTeamMemberUsersByLine.add(tm.User__c);
                    teamMembersToUpdateMap.put(key, tm);
                }
            }

            if (caseRecord.opportunity_id__c != null) {
                List<DMT_TeamMember__c> teamMembersOpportunity = [
                    SELECT Id, User__c, AccessLevel__c, Team_Role__c, DMT_ApprovalEdit__c,
                           Line__c, Opportunity__c, Line__r.Status__c
                    FROM DMT_TeamMember__c
                    WHERE Opportunity__c = :caseRecord.opportunity_id__c
                    WITH USER_MODE
                ];

                for (DMT_TeamMember__c tm : teamMembersOpportunity) {
                    String key = String.valueOf(tm.User__c) + '_Opportunity';
                    existingTeamMemberUsersByOpportunity.add(tm.User__c);
                    teamMembersToUpdateMap.put(key, tm);
                }
            }

            if (sanctionEdit) {
                Set<Id> approverUserIds = new Set<Id>();

                for (DMT_Approver_Member__c am : approverMembers) {
                    approverUserIds.add(am.DMT_User__c);
                }

                if (caseRecord.DMT_Line__c != null) {
                    List<DMT_TeamMember__c> lineMembersToUpdate = new List<DMT_TeamMember__c>();

                    for (Id userId : approverUserIds) {
                        String key = String.valueOf(userId) + '_Line';

                        if (teamMembersToUpdateMap.containsKey(key)) {
                            DMT_TeamMember__c tm = teamMembersToUpdateMap.get(key);
                            tm.AccessLevel__c =
                                approver.DMT_ApproverType__r.Name == DMT_Constants.APPROVER_TYPE_RISK
                                ? 'Edit'
                                : 'Read';
                            tm.DMT_ApprovalEdit__c =
                                approver.DMT_ApproverType__r.Name == DMT_Constants.APPROVER_TYPE_RISK;

                            lineMembersToUpdate.add(tm);
                        }
                    }

                    if (!lineMembersToUpdate.isEmpty()) {
                        update lineMembersToUpdate;
                    }
                }

                if (caseRecord.opportunity_id__c != null) {
                    List<DMT_TeamMember__c> oppMembersToUpdate = new List<DMT_TeamMember__c>();

                    for (Id userId : approverUserIds) {
                        String key = String.valueOf(userId) + '_Opportunity';

                        if (teamMembersToUpdateMap.containsKey(key)) {
                            DMT_TeamMember__c tm = teamMembersToUpdateMap.get(key);
                            tm.AccessLevel__c =
                                approver.DMT_ApproverType__r.Name == DMT_Constants.APPROVER_TYPE_BUSINESS
                                ? 'Edit'
                                : 'Read';
                            tm.DMT_ApprovalEdit__c =
                                approver.DMT_ApproverType__r.Name == DMT_Constants.APPROVER_TYPE_BUSINESS;

                            oppMembersToUpdate.add(tm);
                        }
                    }

                    if (!oppMembersToUpdate.isEmpty()) {
                        update oppMembersToUpdate;
                    }
                }
            }

            List<DMT_TeamMember__c> newTeamMembers = new List<DMT_TeamMember__c>();
            Set<String> processedKeys = new Set<String>();

            for (DMT_Approver_Member__c approverMember : approverMembers) {
                Id userId = approverMember.DMT_User__c;

                if (caseRecord.DMT_Line__c != null) {
                    String lineKey = String.valueOf(userId) + '_Line';

                    if (
                        !existingTeamMemberUsersByLine.contains(userId)
                        && !processedKeys.contains(lineKey)
                    ) {
                        DMT_TeamMember__c newTm = new DMT_TeamMember__c();
                        newTm.User__c = userId;
                        newTm.Name = approverMember.DMT_User__r.Name;
                        newTm.Line__c = caseRecord.DMT_Line__c;
                        newTm.AccessLevel__c =
                            sanctionEdit
                            && approver.DMT_ApproverType__r.Name == DMT_Constants.APPROVER_TYPE_RISK
                            ? 'Edit'
                            : 'Read';
                        newTm.Team_Role__c =
                            caseRecord.DMT_Passport_Sanction__c == 'passport'
                            ? 'validator'
                            : 'approver';
                        newTm.DMT_ApprovalEdit__c = sanctionEdit;

                        newTeamMembers.add(newTm);
                        processedKeys.add(lineKey);
                    }
                }

                if (caseRecord.opportunity_id__c != null) {
                    String oppKey = String.valueOf(userId) + '_Opportunity';

                    if (
                        !existingTeamMemberUsersByOpportunity.contains(userId)
                        && !processedKeys.contains(oppKey)
                    ) {
                        DMT_TeamMember__c newTm = new DMT_TeamMember__c();
                        newTm.User__c = userId;
                        newTm.Name = approverMember.DMT_User__r.Name;
                        newTm.Opportunity__c = caseRecord.opportunity_id__c;
                        newTm.AccessLevel__c =
                            sanctionEdit
                            && approver.DMT_ApproverType__r.Name == DMT_Constants.APPROVER_TYPE_BUSINESS
                            ? 'Edit'
                            : 'Read';
                        newTm.Team_Role__c =
                            caseRecord.DMT_Passport_Sanction__c == 'passport'
                            ? 'validator'
                            : 'approver';
                        newTm.DMT_ApprovalEdit__c = sanctionEdit;

                        newTeamMembers.add(newTm);
                        processedKeys.add(oppKey);
                    }
                }
            }

            if (!newTeamMembers.isEmpty()) {
                insert newTeamMembers;
            }

        } catch (Exception e) {
            DMT_LogExceptionPayload errorPayload = new DMT_LogExceptionPayload(
                e.getMessage(),
                e.getStackTraceString(),
                e.getLineNumber(),
                e.getTypeName(),
                'DMT_CreateTeamMemberCase',
                'processCase',
                'DMT',
                'Case/TeamMember'
            );

            DMT_AsyncOrchestrator.enqueue(errorPayload);
            DMT_AsyncOrchestrator.flush();
        }
    }
}