public with sharing class DTM_Task_Helper {

    // CIBGLOBALD-4617 - operations carried by DMT_Task__e.Operation__c. records__c now holds the
    // Line / Opportunity Ids affected (not Task Ids), so a subscribed Passport can match on the
    // record it is open on, including brand-new replacement Tasks it has never seen.
    // MODIFY_MULTI = more than one approval Task of the same record changed in the same transaction
    // (e.g. all Tasks of a Case finished at once on Close Task).
    @TestVisible private static final String OP_CREATE = 'CREATE';
    @TestVisible private static final String OP_MODIFY = 'MODIFY';
    @TestVisible private static final String OP_MODIFY_MULTI = 'MODIFY_MULTI';
    // The Passport__c record itself changed (JSON recalculated or Obsolete flag flipped).
    @TestVisible private static final String OP_PASSPORT = 'PASSPORT';

    // CIBGLOBALD-4617 - Task fields that feed the Passport traffic lights / step info
    // (DMT_Case_Steps_Controller.getCurrentStepsFromCases). A change on any other field does not
    // need to wake up the open Passports.
    private static final List<Schema.SObjectField> WATCHED_FIELDS = new List<Schema.SObjectField>{
        Task.Status,
        Task.OwnerId,
        Task.DMT_Step_Result__c,
        Task.DMT_Step_Type__c,
        Task.DMT_Task_Type__c,
        Task.DMT_UserClosedTask__c,
        Task.DMT_Committee_Label__c
    };

    /**
     * CIBGLOBALD-4617 - Publishes DMT_Task__e only for DMT approval Tasks that belong to a Case of a
     * Line or an Opportunity and, on update, only when a watched field changed. Previously it
     * published for every Task of the org.
     * @param newList   Trigger.new
     * @param oldMap    Trigger.oldMap on update, null on insert
     * @param operation CREATE or MODIFY (the trigger context)
     */
    public static void processTask(List<Task> newList, Map<Id, Task> oldMap, String operation) {
        publish(buildTaskEvents(newList, oldMap, operation));
    }

    @TestVisible
    private static List<DMT_Task__e> buildTaskEvents(List<Task> newList, Map<Id, Task> oldMap, String operation) {
        List<DMT_Task__e> events = new List<DMT_Task__e>();
        CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
        if (byPass.CIB_skip_platform_event__c) {
            return events;
        }

        List<Task> relevantTasks = new List<Task>();
        Set<Id> caseIds = new Set<Id>();
        for (SObject record : DES_RecordType_Utils.filter((List<SObject>) newList, 'Task', DMT_Constants.TASK_RT_APPROVAL_STEP)) {
            Task t = (Task) record;
            if (t.WhatId == null || t.WhatId.getSObjectType() != Case.SObjectType) {
                continue;
            }
            if (oldMap != null && !hasWatchedChange(t, oldMap.get(t.Id))) {
                continue;
            }
            relevantTasks.add(t);
            caseIds.add(t.WhatId);
        }
        if (relevantTasks.isEmpty()) {
            return events;
        }

        Map<Id, Case> casesById = new Map<Id, Case>([
            SELECT Id, DMT_LineOpportunity__c, DMT_Line__c, opportunity_id__c
            FROM Case
            WHERE Id IN :caseIds
            WITH SYSTEM_MODE
        ]);

        // Line / Opportunity Id -> how many of its approval Tasks changed in this transaction
        Map<Id, Integer> changedTasksByRecordId = new Map<Id, Integer>();
        for (Task t : relevantTasks) {
            Case relatedCase = casesById.get(t.WhatId);
            // A Case belongs to either a Line ('L') or an Opportunity ('O'), never both
            // (DMT_LineOpportunity__c, the same discriminator DMT_ApprovalChangeStep_Handler uses)
            Id recordId = relatedCase == null ? null
                : (relatedCase.DMT_LineOpportunity__c == 'L' ? relatedCase.DMT_Line__c
                    : (relatedCase.DMT_LineOpportunity__c == 'O' ? relatedCase.opportunity_id__c : null));
            if (recordId == null) {
                continue;
            }
            Integer count = changedTasksByRecordId.get(recordId);
            changedTasksByRecordId.put(recordId, count == null ? 1 : count + 1);
        }

        List<Id> singleRecordIds = new List<Id>();
        List<Id> multiRecordIds = new List<Id>();
        for (Id recordId : changedTasksByRecordId.keySet()) {
            if (operation == OP_MODIFY && changedTasksByRecordId.get(recordId) > 1) {
                multiRecordIds.add(recordId);
            } else {
                singleRecordIds.add(recordId);
            }
        }

        if (!singleRecordIds.isEmpty()) {
            events.add(new DMT_Task__e(Operation__c = operation, records__c = String.join(singleRecordIds, ',')));
        }
        if (!multiRecordIds.isEmpty()) {
            events.add(new DMT_Task__e(Operation__c = OP_MODIFY_MULTI, records__c = String.join(multiRecordIds, ',')));
        }
        return events;
    }

    /**
     * CIBGLOBALD-4617 - Replaces the Passport__ChangeEvent subscription: publishes DMT_Task__e
     * (Operation PASSPORT, keyed by Line / Opportunity Id) only when the Passport JSON or its
     * Obsolete flag actually changed, instead of delivering every change of every Passport__c.
     * Called from DMT_Passport_TriggerHandler.afterUpdate.
     */
    public static void processPassportChange(List<Passport__c> newList, Map<Id, Passport__c> oldMap) {
        publish(buildPassportEvents(newList, oldMap));
    }

    @TestVisible
    private static List<DMT_Task__e> buildPassportEvents(List<Passport__c> newList, Map<Id, Passport__c> oldMap) {
        List<DMT_Task__e> events = new List<DMT_Task__e>();
        CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
        if (byPass.CIB_skip_platform_event__c || oldMap == null) {
            return events;
        }

        Set<Id> recordIds = new Set<Id>();
        for (Passport__c passport : newList) {
            Passport__c oldPassport = oldMap.get(passport.Id);
            if (oldPassport == null) {
                continue;
            }
            Boolean changed = passport.DMT_Is_Obsoleted_Passport_Save__c != oldPassport.DMT_Is_Obsoleted_Passport_Save__c
                || passport.DMT_Passport_Save__c != oldPassport.DMT_Passport_Save__c;
            Id recordId = passport.DMT_Line__c != null ? passport.DMT_Line__c : passport.Opportunity__c;
            if (changed && recordId != null) {
                recordIds.add(recordId);
            }
        }
        if (!recordIds.isEmpty()) {
            events.add(new DMT_Task__e(Operation__c = OP_PASSPORT, records__c = String.join(new List<Id>(recordIds), ',')));
        }
        return events;
    }

    private static void publish(List<DMT_Task__e> events) {
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }

    private static Boolean hasWatchedChange(Task newTask, Task oldTask) {
        if (oldTask == null) {
            return true;
        }
        for (Schema.SObjectField field : WATCHED_FIELDS) {
            if (newTask.get(field) != oldTask.get(field)) {
                return true;
            }
        }
        return false;
    }
}
