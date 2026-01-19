public without sharing class DMT_Case_Steps_Selector {

    public static List<DMT_Approver_Member__c> getApproverMembersByUser(Id userId) {
        return [SELECT Id, DMT_Approver__c, DMT_Approver__r.Name, DMT_Approver__r.DMT_Group__c, DMT_FieldsHistoryView__c from DMT_Approver_Member__c where DMT_User__c =: userId WITH SECURITY_ENFORCED];
    }

    public static List<Group> getGroupsByDeveloperName(Set<String> developerName) {
        return [SELECT Id, DeveloperName FROM Group WHERE Type =: DMT_Constants.TYPE_GROUP_QUEUE AND DeveloperName IN :developerName WITH SECURITY_ENFORCED];
    }

    public static List<Case> getCasesByIdAndOwner(Set<Id> owners, Set<Id> casesSet) {
        return [SELECT Id,CreatedDate FROM Case where (OwnerId IN : owners OR Status=:DMT_Constants.FINISHED) AND RecordType.DeveloperName =:DMT_Constants.CASE_RT_APPROVAL AND Id IN :casesSet WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
    }

    public static List<Task> getTasksByCase(Set<Id> whatIds) {
        return [SELECT Id, WhatId, Owner.Name, Status, LastModifiedBy.Name, CreatedDate, CompletedDateTime, TOLABEL(DMT_Step_Type__c), DMT_Step_Result__c, Description, DMT_Task_Type__r.Name, DMT_Task_Type__r.DMT_Yes_Flag__c, DMT_Task_Type__r.DMT_No_Flag__c, DMT_Task_Type__r.DMT_NA_Flag__c 
        FROM Task WHERE RecordType.DeveloperName =: DMT_Constants.TASK_RT_APPROVAL_STEP AND WhatId IN : whatIds WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
    }

    public static List<Task> getTasksByOwner(Set<Id> owners) {
        return [SELECT Id, WhatId, Owner.Name, Status, LastModifiedBy.Name, CreatedDate, CompletedDateTime, TOLABEL(DMT_Step_Type__c), DMT_Step_Result__c, Description, DMT_Task_Type__r.Name, DMT_Task_Type__r.DMT_Yes_Flag__c, DMT_Task_Type__r.DMT_No_Flag__c, DMT_Task_Type__r.DMT_NA_Flag__c 
        FROM Task WHERE OwnerId IN : owners AND RecordType.DeveloperName =: DMT_Constants.TASK_RT_APPROVAL_STEP AND WhatId != null WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
    }

    public static Map<Id, Task> getTasksByNotInTaskMap(Set<Id> whatIds, Set<Id> taskIds) {
        return new Map<Id, Task>([SELECT Id, WhatId, Owner.Name, Status, LastModifiedBy.Name, CreatedDate, CompletedDateTime,  TOLABEL(DMT_Step_Type__c), DMT_Step_Result__c, Description, DMT_Task_Type__r.Name, DMT_Task_Type__r.DMT_Yes_Flag__c, DMT_Task_Type__r.DMT_No_Flag__c, DMT_Task_Type__r.DMT_NA_Flag__c 
        FROM Task WHERE  RecordType.DeveloperName =: DMT_Constants.TASK_RT_APPROVAL_STEP AND WhatId != null AND WhatId IN : whatIds AND Id NOT IN : taskIds WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC]);
    }

    public static List<Task> getTasksById(Set<Id> taskIds) {
        return [SELECT Id, WhatId, Owner.Name, Status, LastModifiedBy.Name, DMT_UserClosedTask__c, DMT_UserClosedTask__r.Name, DMT_Completed_Date_Time__c, CreatedDate, CompletedDateTime,  TOLABEL(DMT_Step_Type__c), DMT_Step_Result__c, Description, DMT_Task_Type__r.Name, DMT_Task_Type__r.DMT_Yes_Flag__c, DMT_Task_Type__r.DMT_No_Flag__c, DMT_Task_Type__r.DMT_NA_Flag__c 
        FROM Task WHERE Id IN : taskIds WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
    }

    public static List<Case> getCasesFromTasks(Set<Id> caseIdWithTasks) {
        return [SELECT Id, Status, DMT_LineOpportunity__c, opportunity_id__c, description, opportunity_id__r.Name, Opportunity_Id__r.StageName, opportunity_id__r.DMT_Opp_Id__c, DMT_Line__r.Line_Id__c, DMT_Line__c, DMT_Line__r.Name, DMT_Line__r.Status__c, DMT_Line__r.Line_Details__c, DMT_Line__r.Line_Term__c, DMT_Line__r.Product__c, DMT_Line__r.Booking_Geography__c, DMT_Line__r.End_Date__c, DMT_Line__r.CurrencyIsoCode, DMT_Line__r.Start_Date__c, Amount__c, Account.DES_Client_Type__c, Account.DES_Main_Parent__r.Name, Account.Name, CaseNumber, CurrencyIsoCode,DMT_Feature_Id__c, DMT_LineOppDateToProposal__c,DMT_Related_feature_name__c,(SELECT Id FROM Tasks WHERE RecordType.DeveloperName='DMT_Step_Approval' ), DMT_Passport_Sanction__c FROM Case WHERE Id IN :caseIdWithTasks WITH SECURITY_ENFORCED];
    }

    public static List<Passport__c> getPassportsByLineIds(Set<Id> lineIds) {
        return [SELECT Id, DMT_Line__c, DMT_Passport_Save__c, CreatedDate FROM Passport__c WHERE DMT_Line__c IN :lineIds ORDER BY CreatedDate DESC];
    }

    public static List<Passport__c> getPassportsByOpportunityIds(Set<Id> oppIds) {
        return [SELECT Id, Opportunity__c, DMT_Passport_Save__c, CreatedDate FROM Passport__c WHERE Opportunity__c IN :oppIds ORDER BY CreatedDate DESC];
    }

    public static List<Case> getApprovalCasesByLineIds(Set<Id> lineIds) {
        return [SELECT Id,CreatedDate, LastModifiedBy.Name, DMT_Line__c, opportunity_id__c, RecordType.DeveloperName, Status, DMT_Closing_Tasks__c, IsClosed, DMT_Feature_Id__c FROM Case WHERE RecordType.DeveloperName = 'Approval' AND DMT_Line__c IN :lineIds ORDER BY CreatedDate DESC];
    }

    public static List<Case> getApprovalCasesByOpportunityIds(Set<Id> oppIds) {
        return [SELECT Id,CreatedDate, LastModifiedBy.Name, DMT_Line__c, opportunity_id__c, RecordType.DeveloperName, Status, DMT_Closing_Tasks__c, IsClosed, DMT_Feature_Id__c FROM Case WHERE RecordType.DeveloperName = 'Approval' AND opportunity_id__c IN :oppIds ORDER BY CreatedDate DESC];
    }

}