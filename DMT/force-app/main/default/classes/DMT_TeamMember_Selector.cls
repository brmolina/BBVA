/*
Autor: fernando Gonzalez
Fecha: 2025-12-03
*/
public with sharing  class DMT_TeamMember_Selector {
    // Método para obtener los teamMember en base a la linea y los approvers
    public static List<DMT_TeamMember__c> getTeamMemberLinesApprover(Id lineId, Set<Id> approversLineSetId) {
        return [SELECT Id, User__c, Full_Name_User__c, Line__c, Line__r.Status__c, AccessLevel__c, Opportunity__c FROM DMT_TeamMember__c WHERE Line__c = :lineId AND User__c IN :approversLineSetId  WITH USER_MODE];
    }

    // Método para obtener los teamMember en base a la linea
    public static List<DMT_TeamMember__c> getTeamMemberLines(Id lineId) {
        return [SELECT Id, User__c, Full_Name_User__c, Line__c, Line__r.Status__c, AccessLevel__c, Opportunity__c FROM DMT_TeamMember__c WHERE Line__c = :lineId WITH USER_MODE];
    }

    // Método para obtener los teamMember en base a las lineas de los casos
    public static List<DMT_TeamMember__c> getTeamMemberLinesBaseInCaseLines(List<Id> linesIds) {
        return [SELECT Id, User__c, Full_Name_User__c, Line__c, Line__r.Status__c, AccessLevel__c, Opportunity__c FROM DMT_TeamMember__c WHERE Line__c IN :linesIds WITH USER_MODE];
    }
}