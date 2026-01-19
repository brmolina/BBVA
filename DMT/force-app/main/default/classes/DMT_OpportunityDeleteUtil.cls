public without sharing class DMT_OpportunityDeleteUtil {

    public class DeleteInput {
        @InvocableVariable public Opportunity opportunity;
        @InvocableVariable public DMT_Opportunity_Client__c opportunityClient;
        @InvocableVariable public List<OpportunityLineItem> opportunityLineItems;
        @InvocableVariable public List<DMT_Opportunity_Tenor__c> tenors;
        @InvocableVariable public List<DMT_Opportunity_Mitigant__c> mitigants;
        @InvocableVariable public List<DMT_X_Sell__c> xSells;
        @InvocableVariable public List<DMT_TeamMember__c> participants;
        @InvocableVariable public List<Case> cases;
        @InvocableVariable public List<Task> tasks;
        @InvocableVariable public List<Passport__c> passports;
    }

    public class DeleteResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
        @InvocableVariable public Id deletedOpportunityId;
    }

    @InvocableMethod(label='Eliminar oportunidad y datos relacionados desde Flow')
    public static List<DeleteResult> deleteData(List<DeleteInput> inputs) {
        List<DeleteResult> results = new List<DeleteResult>();

        for (DeleteInput input : inputs) {
            DeleteResult res = new DeleteResult();
            try {
                if (input.opportunity == null || input.opportunity.Id == null) {
                    throw new AuraHandledException('Debe proporcionar opportunity con Id.');
                }

                Id oppId = input.opportunity.Id;
                List<SObject> recordsToDelete = new List<SObject>();

                if (input.tenors != null) recordsToDelete.addAll(input.tenors);
                if (input.mitigants != null) recordsToDelete.addAll(input.mitigants);
                if (input.opportunityLineItems != null) recordsToDelete.addAll(input.opportunityLineItems);
                if (input.xSells != null) recordsToDelete.addAll(input.xSells);
                if (input.participants != null) recordsToDelete.addAll(input.participants);
                if (input.opportunityClient != null) recordsToDelete.add(input.opportunityClient);
                if (input.cases != null) recordsToDelete.addAll(input.cases);
                if (input.tasks != null) recordsToDelete.addAll(input.tasks);
                if (input.passports != null) recordsToDelete.addAll(input.passports);
                recordsToDelete.add(input.opportunity);

                List<SObject> cleanList = new List<SObject>();
                for (SObject s : recordsToDelete) {
                    if (s != null && s.Id != null) {
                        cleanList.add(s);
                    }
                }

                if (!cleanList.isEmpty()) {
                    delete cleanList;
                }
                
                res.success = true;
                res.deletedOpportunityId = oppId;

            } catch (Exception ex) {
                res.success = false;
                res.errorMessage = ex.getMessage();
            }

            results.add(res);
        }

        return results;
    }
}