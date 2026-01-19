/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-07-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class GDT_Block_Studies_Proposal_Controller {
    
    @AuraEnabled
    public static List<Map<String, Object>> getTableData(String parentId) {
        List<Map<String, Object>> resultRows = new List<Map<String, Object>>();
        Boolean fallbackToDB = false;
    
        try {
            String groupId = null;
            Account acc = [
                SELECT Id, Name, DES_Group_Code__c
                FROM Account
                WHERE Id = :parentId
                LIMIT 1
            ];
            groupId = acc.DES_Group_Code__c;
    
            if(String.isBlank(groupId)){
                fallbackToDB = true;
            } else {
                String pageSize = '100';
                String paginationKey = '1';
                String queryString = 'groupId=' + groupId + '&pageSize=' + pageSize + '&paginationKey=' + paginationKey;
    
                Map<String, Object> request = new Map<String, Object>();
                request.put('userId', 'O010672');
                request.put('queryString', queryString);
    
                HttpResponse response = iaso.GBL_Integration_GenericService.invoke('GDT_BlockStudiesProposal', request);
    
                if(response.getStatusCode() == 200 && String.isNotBlank(response.getBody())){
                    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    if(jsonResponse.containsKey('data')){
                        List<Object> proposals = (List<Object>) jsonResponse.get('data');
                        Set<String> proposalExternalIds = new Set<String>();
                        Set<String> federationIds = new Set<String>();
    
                        for(Object proposalObj : proposals){
                            Map<String, Object> proposal = (Map<String, Object>)proposalObj;
                            String proposalId = (String)proposal.get('proposalId');
                            if (proposalId != null) proposalExternalIds.add(proposalId);
    
                            String proposeUser = (String)proposal.get('proposeUser');
                            if (proposeUser != null) federationIds.add(proposeUser);
    
                            String contrastedUser = (String)proposal.get('contrastedUser');
                            if (contrastedUser != null) federationIds.add(contrastedUser);
                        }

                        Map<String, arce__SP2_Proposal__c> externalIdToProposal = new Map<String, arce__SP2_Proposal__c>();
                        if(!proposalExternalIds.isEmpty()) {
                            for(arce__SP2_Proposal__c prop : [
                                SELECT Id, Name, CreatedDate, arce__proposalExternalID__c 
                                FROM arce__SP2_Proposal__c 
                                WHERE arce__proposalExternalID__c IN :proposalExternalIds
                            ]) {
                                externalIdToProposal.put(prop.arce__proposalExternalID__c, prop);
                            }
                        }
    
                        Map<String, String> federationIdToUserName = new Map<String, String>();
                        if(!federationIds.isEmpty()) {
                            for(User u : [
                                SELECT Name, FederationIdentifier 
                                FROM User 
                                WHERE FederationIdentifier IN :federationIds
                            ]) {
                                federationIdToUserName.put(u.FederationIdentifier, u.Name);
                            }
                        }
    
                        for(Object proposalObj : proposals){
                            Map<String, Object> proposal = (Map<String, Object>)proposalObj;
    
                            String proposalId = (String)proposal.get('proposalId');
                            String proposalDate = (String)proposal.get('proposalDate');
                            String approvalDate = (String)proposal.get('approvalDate');
                            String validityDate = (String)proposal.get('validityDate');
                            String proposeUser = (String)proposal.get('proposeUser');
                            String contrastedUser = (String)proposal.get('contrastedUser');
                            String sanctionCommittee = (String)proposal.get('sanctionCommittee');
    
                            String proposeUserName = (proposeUser != null && federationIdToUserName.containsKey(proposeUser)) 
                                ? federationIdToUserName.get(proposeUser) : proposeUser;
                            String contrastedUserName = (contrastedUser != null && federationIdToUserName.containsKey(contrastedUser))
                                ? federationIdToUserName.get(contrastedUser) : contrastedUser;
    
                            List<Object> participants = (List<Object>) proposal.get('participant');
                            for(Object participantObj : participants){
                                Map<String, Object> participant = (Map<String, Object>) participantObj;
    
                                Map<String, Object> row = new Map<String, Object>();
    
                                if(externalIdToProposal.containsKey(proposalId)){
                                    arce__SP2_Proposal__c proposalRecord = externalIdToProposal.get(proposalId);
                                    row.put('Id', proposalRecord.Id);
                                    row.put('name', proposalRecord.Name);
                                    row.put('Participant', (String)participant.get('name')); 
                                    row.put('Created Date', (proposalRecord.CreatedDate != null) 
                                        ? proposalRecord.CreatedDate.date().format()
                                        : ''
                                    );
                                    String formattedValidityDate = '';
                                    if (validityDate != null && validityDate != '') {
                                        try {
                                            Date vDate = Date.valueOf(validityDate);
                                            formattedValidityDate = vDate.format();
                                        } catch (Exception e) {
                                            formattedValidityDate = validityDate;
                                        }
                                    }
                                    row.put('Validity Date', formattedValidityDate);
                                } else {
                                    row.put('name', proposalId); 
                                    row.put('Participant', (String)participant.get('name')); 
                                    row.put('Created Date', ''); 
                                    String formattedValidityDate = '';
                                    if (validityDate != null && validityDate != '') {
                                        try {
                                            Date vDate = Date.valueOf(validityDate);
                                            formattedValidityDate = vDate.format();
                                        } catch (Exception e) {
                                            formattedValidityDate = validityDate;
                                        }
                                    }
                                    row.put('validity Date', formattedValidityDate);
                                }
                                
                                row.put('propose User', proposeUserName); 
                                row.put('contrasted User', contrastedUserName); 
                                row.put('sanction Committee', sanctionCommittee);
                                String formattedCeiling = '';
                                String finalCeilingStr = (String)participant.get('finalCeiling');
                                String ceilingCurrency = (String)proposal.get('currency'); 
                                
                                if (finalCeilingStr != null && finalCeilingStr != '') {
                                    try {
                                        Decimal ceilingNum = Decimal.valueOf(finalCeilingStr);
                                        formattedCeiling = ceilingNum.format();
                                        if (ceilingCurrency != null && ceilingCurrency != '') {
                                            formattedCeiling = formattedCeiling + ' ' + ceilingCurrency;
                                        }
                                    } catch (Exception e) {
                                        formattedCeiling = finalCeilingStr;
                                        if (ceilingCurrency != null && ceilingCurrency != '') {
                                            formattedCeiling = formattedCeiling + ' ' + ceilingCurrency;
                                        }
                                    }
                                } else if (ceilingCurrency != null && ceilingCurrency != '') {
                                    formattedCeiling = ceilingCurrency;
                                }
                                row.put('final Ceiling', formattedCeiling);
    
                                resultRows.add(row);
                            }
                        }
                    } else {
                        fallbackToDB = true;
                    }
                } else {
                    fallbackToDB = true;
                }
            }
        } catch(Exception ex){
            fallbackToDB = true;
        }
    
        if(fallbackToDB){
            return getTableDataFromDatabase(parentId);
        }
        return resultRows;
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> getTableDataFromDatabase(Id parentId) {
        List<arce__SP2_Proposal__c> proposal = [
            select Id, name, CreatedDate, CreatedBy.name, arce__Stage__c, arce__SanctBusinessSanction__c, arce__SanctComitteePropose__c, arce__SanctComment_Fin__c,  arce__SanctSanctionDate_Fin__c 
            from arce__SP2_Proposal__c 
            where arce__main_group__c = :parentId
        ];

        List<Map<String, Object>> output = new List<Map<String, Object>>();
        for (arce__SP2_Proposal__c acc : proposal) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('Id', acc.Id);
            row.put('Created by', acc.CreatedBy.name);
            row.put('Sanction Date', acc.arce__SanctSanctionDate_Fin__c);
            output.add(row);
        }

        return output;
    }
}