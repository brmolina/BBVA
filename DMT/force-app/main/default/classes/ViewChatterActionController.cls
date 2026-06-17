public with sharing class ViewChatterActionController {

    public class ChatterContext {
        @AuraEnabled public Id feedRecordId;
        @AuraEnabled public Id opportunityFeedRecordId;
        @AuraEnabled public Boolean showLineFeed;
        @AuraEnabled public Boolean showOpportunityFeed;
        @AuraEnabled public String widgetTitle;
    }

    @AuraEnabled(cacheable=true)
    public static ChatterContext getChatterContext(Id recordId) {
        ChatterContext context = new ChatterContext();
        context.feedRecordId = recordId;
        context.showLineFeed = false;
        context.showOpportunityFeed = false;
        context.widgetTitle = 'Live Chatter';

        if (recordId == null) {
            return context;
        }

        String objectApiName = String.valueOf(recordId.getSObjectType());

        if (objectApiName == 'Opportunity') {
            context.feedRecordId = recordId;
            context.showLineFeed = true;
            context.widgetTitle = 'Opportunity Chatter';
            return context;
        }

        if (objectApiName == 'Case') {
            Case caseRecord = [
                SELECT Id, DMT_LineOpportunity__c, opportunity_id__c, DMT_Line__c
                FROM Case
                WHERE Id = :recordId
                LIMIT 1
            ];

            if (caseRecord.DMT_LineOpportunity__c == 'O' && caseRecord.opportunity_id__c != null) {
                context.feedRecordId = caseRecord.opportunity_id__c;
                context.showLineFeed = true;
                context.widgetTitle = 'Opportunity Chatter';
            } else if (caseRecord.DMT_LineOpportunity__c == 'L' && caseRecord.DMT_Line__c != null) {
                context.feedRecordId = caseRecord.DMT_Line__c;
                context.showLineFeed = true;
                context.widgetTitle = 'Line Chatter';
            } else {
                context.feedRecordId = recordId;
                context.showLineFeed = true;
                context.widgetTitle = 'Case Chatter';
            }

            return context;
        }

        if (objectApiName == 'DMT_Line__c') {
            Map<String, Schema.SObjectField> lineFields = Schema.SObjectType.DMT_Line__c.fields.getMap();
            String lineTemplateType = null;
            Id opportunityId = null;

            if (lineFields.containsKey('DMT_line_template_type__c') || lineFields.containsKey('opportunity_id__c') || lineFields.containsKey('Opportunity__c')) {
                String query = 'SELECT Id, DMT_line_template_type__c';
                if (lineFields.containsKey('opportunity_id__c')) {
                    query += ', opportunity_id__c';
                } else if (lineFields.containsKey('Opportunity__c')) {
                    query += ', Opportunity__c';
                }
                query += ' FROM DMT_Line__c WHERE Id = :recordId LIMIT 1';

                SObject lineRecord = Database.query(query);
                lineTemplateType = (String) lineRecord.get('DMT_line_template_type__c');

                if (lineFields.containsKey('opportunity_id__c')) {
                    opportunityId = (Id) lineRecord.get('opportunity_id__c');
                } else if (lineFields.containsKey('Opportunity__c')) {
                    opportunityId = (Id) lineRecord.get('Opportunity__c');
                }
            }

            context.feedRecordId = recordId;
            context.showLineFeed = true;
            context.widgetTitle = 'Line Chatter';

            if (lineTemplateType == 'OP' && opportunityId != null) {
                context.opportunityFeedRecordId = opportunityId;
                context.showOpportunityFeed = true;
            }

            return context;
        }

        return context;
    }
}