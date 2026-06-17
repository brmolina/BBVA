public with sharing class DMT_OpportunityCloneUtil {
   public class CloneInput {
        @InvocableVariable
        public Opportunity originalOpportunity;

        @InvocableVariable
        public DMT_Opportunity_Client__c opportunityClient;

        @InvocableVariable
        public List<OpportunityLineItem> opportunityLineItems;

        @InvocableVariable
        public List<DMT_Opportunity_Tenor__c> tenors;

        @InvocableVariable
        public List<DMT_Opportunity_Mitigant__c> mitigants;

        @InvocableVariable
        public List<DMT_X_Sell__c> xSells;

        @InvocableVariable
        public Local_Client__c localClient;

        @InvocableVariable
        public List<DMT_TeamMember__c> participants;
    }
    

    public class CloneResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
        @InvocableVariable public Id newOpportunityId;
    }

    @InvocableMethod(label='Clonar oportunidad y datos relacionados desde Flow')
    public static List<CloneResult> clone(List<CloneInput> inputs) {
        List<CloneResult> results = new List<CloneResult>();

        for (CloneInput input : inputs) {
            CloneResult result = new CloneResult();
            try {
                // 1. Clonar Opportunity (sin Id)
                Opportunity newOpp = input.originalOpportunity.clone(false, false, false, false);
                newOpp.Id = null;
                newOpp.AccountId = input.localClient.Cib_Client__c;
                newOpp.DMT_Opp_Id__c = getOppIdExternal(input.originalOpportunity.Entific__c);
                newOpp.StageName = system.Label.Draft_Status;
                newOpp.OwnerId = UserInfo.getUserId();
                newOpp.DMT_Sanction__c = null;
                newOpp.DMT_Parent_Opportunity__c = null;
              //  newOpp.DMT_Ready_to_close__c = false;
                newOpp.DMT_Opp_User_Lock__c = null;
                insert newOpp;
                result.newOpportunityId = newOpp.Id;

                // 2. Map original OLI por Id
                Map<Id, OpportunityLineItem> originalOLIsById = new Map<Id, OpportunityLineItem>();
                Map<Id, Id> oldOLItoNewOLI = new Map<Id, Id>();
                List<SObject> recordsToInsert = new List<SObject>();              
                if(input.opportunityClient != null) {
                    DMT_Opportunity_Client__c clone = input.opportunityClient.clone(false, false, false, false);
                    clone.Id = null;
                    clone.DMT_MDE_Opportunity__c = newOpp.Id;
                    recordsToInsert.add(clone);
                }
                // 5. Clonar Tenors, Mitigants y XSells agregándolos a una lista común
                if(input.opportunityLineItems != null) {
                    for (OpportunityLineItem oli : input.opportunityLineItems) {
                        originalOLIsById.put(oli.Id, oli);
                    }
                    // 3. Clonar OLIs con referencia a nueva Opportunity
                    Map<Id, OpportunityLineItem> clonedOLIsByOriginalId = new Map<Id, OpportunityLineItem>();
                    for (OpportunityLineItem originalOli : input.opportunityLineItems) {
                        if (originalOli != null) {
                            OpportunityLineItem clone = originalOli.clone(false, false, false, false);
                            clone.Id = null;
                            clone.OpportunityId = newOpp.Id;
                            //Added the if to avoid the exception: only one of unit price or total price may be specified
                            if(clone.UnitPrice != null && clone.TotalPrice != null) {
                                    clone.UnitPrice = null;
                            }
                            clonedOLIsByOriginalId.put(originalOli.Id, clone);
                        }
                    }
                    insert clonedOLIsByOriginalId.values();
                    // 4. Map de Id original -> Id nuevo                   
                    for (Id originalId : clonedOLIsByOriginalId.keySet()) {
                        oldOLItoNewOLI.put(originalId, clonedOLIsByOriginalId.get(originalId).Id);
                    }                     
                    if(input.tenors != null) {
                        for (DMT_Opportunity_Tenor__c tenor : input.tenors) {
                            if (tenor != null) {
                                DMT_Opportunity_Tenor__c clone = tenor.clone(false, false, false, false);
                                clone.Id = null;
                                clone.OwnerId = UserInfo.getUserId();
                                clone.DMT_Opportunity_Product__c = oldOLItoNewOLI.get(tenor.DMT_Opportunity_Product__c);
                                recordsToInsert.add(clone);
                            }
                        }
                    }
                    if(input.mitigants != null) {
                        for (DMT_Opportunity_Mitigant__c mit : input.mitigants) {
                            if (mit != null) {
                                DMT_Opportunity_Mitigant__c clone = mit.clone(false, false, false, false);
                                clone.Id = null;
                                clone.OwnerId = UserInfo.getUserId();
                                clone.DMT_Opportunity_Product__c = oldOLItoNewOLI.get(mit.DMT_Opportunity_Product__c);
                                recordsToInsert.add(clone);
                            }
                        }
                    }
                }
                if(input.xSells != null) {
                    for (DMT_X_Sell__c xs : input.xSells) {
                        if (xs != null) {
                            DMT_X_Sell__c clone = xs.clone(false, false, false, false);
                            clone.Id = null;
                            clone.OwnerId = UserInfo.getUserId();
                            clone.Opportunity__c = newOpp.Id;
                            recordsToInsert.add(clone);
                        }
                    }
                }
                if (!recordsToInsert.isEmpty()) {
                    insert recordsToInsert;
                }
                //6. Clone the Participants
                cloneParticipants(newOpp, input.participants, input.originalOpportunity.AccountId);
                result.success = true;
            } catch (Exception ex) {
                result.success = false;
                result.errorMessage = ex.getMessage();
            }
            results.add(result);
        }
        return results;
    }

    
    public static void cloneParticipants(Opportunity newOpp, List<DMT_TeamMember__c> participants, Id originalAccountId) {
        List<DMT_TeamMember__c> existingParticipants = DMT_cloneParticipantForLine_Selector.getTeamMember(newOpp.Id);
        List<SObject> participantsToInsert = new List<SObject>();

        if (newOpp.AccountId == originalAccountId) {
            if (!existingParticipants.isEmpty()) {
                delete existingParticipants;
            }
            if (participants != null) {
                for (DMT_TeamMember__c participant : participants) {
                    if (participant != null) {
                        DMT_TeamMember__c clone = participant.clone(false, false, false, false);
                        clone.Id = null;
                        clone.OwnerId = UserInfo.getUserId();
                        clone.Opportunity__c = newOpp.Id;
                        participantsToInsert.add(clone);
                    }
                }
            }
        }
        if (!participantsToInsert.isEmpty()) {
            insert participantsToInsert;
        }
    }

    public static String getOppIdExternal(String entific) {
        Map<String, Object> inputMap = new Map<String, Object>{
            'linOropp' => 'OPP',
            'DMT_Client_Entific__c' => entific
        };

        Map<String, Object> wrapperMap = new Map<String, Object>{
            'input' => inputMap,
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        DMT_DealManagement_Handler handler = new DMT_DealManagement_Handler();
        Map<String, Object> response = (Map<String, Object>)handler.call('getLineId', wrapperMap);

        String lineId = (String)response.get('lineId');
        System.debug('Resultado lineId: ' + lineId);
        return lineId;
    }



}