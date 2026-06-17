/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-07-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class GDT_Block_Studies_Proposal_Controller {
    
    @AuraEnabled
    public static List<Map<String, Object>> getTableData(String parentId) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Boolean fallbackToDB = false;
    
        try {
            Account acc = [
                SELECT Id, Name, DES_Group_Code__c
                FROM Account
                WHERE Id = :parentId
                LIMIT 1
            ];
            String groupId = acc.DES_Group_Code__c;
    
            if (String.isBlank(groupId)) {
                fallbackToDB = true;
            } else {
                String pageSize = '100';
                String paginationKey = '1';
                String queryString = 'groupId=' + groupId + '&pageSize=' + pageSize + '&paginationKey=' + paginationKey;
    
                Map<String, Object> request = new Map<String, Object>();
                request.put('userId', 'O010672');
                request.put('queryString', queryString);
    
                HttpResponse response = iaso.GBL_Integration_GenericService.invoke('GDT_BlockStudiesProposal', request);
    
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    if (json.containsKey('data')) {
                        List<Object> proposals = (List<Object>) json.get('data');
    
                        Set<String> proposalExternalIds = new Set<String>();
                        Set<String> federationIds = new Set<String>();
                        Set<String> groupCodes = new Set<String>(); 
                        Set<String> ratingCodes = new Set<String>();
    
                        for (Object po : proposals) {
                            Map<String, Object> p = (Map<String, Object>) po;
                            String proposalId = (String) p.get('proposalId');
                            if (proposalId != null) proposalExternalIds.add(proposalId);
    
                            String proposeUser = (String) p.get('proposeUser');
                            if (proposeUser != null) federationIds.add(proposeUser);
    
                            String contrastedUser = (String) p.get('contrastedUser');
                            if (contrastedUser != null) federationIds.add(contrastedUser);
    
                            Map<String, Object> groupP = (Map<String, Object>) p.get('group');
                            if (groupP != null) {
                                String gcode = (String) groupP.get('id');
                                if (!String.isBlank(gcode)) groupCodes.add(gcode);
                            }
    
                            List<Object> participants = (List<Object>) p.get('participant');
                            if (participants != null) {
                                for (Object part : participants) {
                                    Map<String, Object> participant = (Map<String, Object>) part;
                                    List<Object> ratings = (List<Object>) participant.get('rating');
                                    if (ratings != null) {
                                        for (Object r : ratings) {
                                            Map<String, Object> rMap = (Map<String, Object>) r;
                                            String rId = (String) rMap.get('id');
                                            if (!String.isBlank(rId)) ratingCodes.add(rId);
                                        }
                                    }
                                }
                            }
                        }
    
                        Map<String, arce__SP2_Proposal__c> extIdToProposal = new Map<String, arce__SP2_Proposal__c>();
                        if (!proposalExternalIds.isEmpty()) {
                            for (arce__SP2_Proposal__c pr : [
                                SELECT Id, Name, CreatedDate, arce__proposalExternalID__c
                                FROM arce__SP2_Proposal__c
                                WHERE arce__proposalExternalID__c IN :proposalExternalIds
                            ]) {
                                extIdToProposal.put(pr.arce__proposalExternalID__c, pr);
                            }
                        }
    
                        Map<String, String> fedIdToUserName = new Map<String, String>();
                        if (!federationIds.isEmpty()) {
                            for (User u : [
                                SELECT Name, FederationIdentifier
                                FROM User
                                WHERE FederationIdentifier IN :federationIds
                            ]) {
                                fedIdToUserName.put(u.FederationIdentifier, u.Name);
                            }
                        }
    
                        Map<String, Account> codeToAccount = new Map<String, Account>();
                        if (!groupCodes.isEmpty()) {
                            for (Account a : [
                                SELECT Id, Name, DES_Group_Code__c
                                FROM Account
                                WHERE DES_Group_Code__c IN :groupCodes
                            ]) {
                                codeToAccount.put(a.DES_Group_Code__c, a);
                            }
                        }
    
                        Map<String, arce__Analysis__c> ratingCodeToAnalysis = new Map<String, arce__Analysis__c>();
                        if (!ratingCodes.isEmpty()) {
                            for (arce__Analysis__c an : [
                                SELECT Id, Name
                                FROM arce__Analysis__c
                                WHERE Name IN :ratingCodes
                            ]) {
                                ratingCodeToAnalysis.put(an.Name, an);
                            }
                        }
    
                        for (Object po : proposals) {
                            Map<String, Object> p = (Map<String, Object>) po;
    
                            String proposalId        = (String) p.get('proposalId');
                            String validityDate      = (String) p.get('validityDate');
                            String policyExpDate     = (String) p.get('policyExpirationDate');
                            String statusType        = (String) p.get('statusType');
                            String contrastedUserRaw = (String) p.get('contrastedUser');
                            String ceilingCurrency   = (String) p.get('currency');
                            String unit              = (String) p.get('unit');
    
                            String contrastedUserName = (contrastedUserRaw != null && fedIdToUserName.containsKey(contrastedUserRaw))
                                ? fedIdToUserName.get(contrastedUserRaw) : contrastedUserRaw;
  
                            String groupName = '';
                            String groupCode = '';
                            Map<String, Object> groupT = (Map<String, Object>) p.get('group');
                            if (groupT != null) {
                                groupCode = (String) groupT.get('id'); 
                                if (!String.isBlank(groupCode)) {
                                    if (codeToAccount.containsKey(groupCode)) {
                                        groupName = codeToAccount.get(groupCode).Name;
                                    } else {
                                        groupName = groupCode; 
                                    }
                                }
                            }

                            String formattedValidity = '';
                            if (!String.isBlank(validityDate)) {
                                try { formattedValidity = Date.valueOf(validityDate).format(); }
                                catch (Exception e) { formattedValidity = validityDate; }
                            }
    
                            String formattedPolicyExp = '';
                            if (!String.isBlank(policyExpDate)) {
                                try { formattedPolicyExp = Date.valueOf(policyExpDate).format(); }
                                catch (Exception e) { formattedPolicyExp = policyExpDate; }
                            }

                            List<Object> participants = (List<Object>) p.get('participant');
                            if (participants == null) participants = new List<Object>{};
    
                            for (Object part : participants) {
                                Map<String, Object> participant = (Map<String, Object>) part;

                                String formattedCeiling = '';
                                String finalCeilingStr = (String) participant.get('finalCeiling');
                                if (!String.isBlank(finalCeilingStr)) {
                                    try {
                                        Decimal n = Decimal.valueOf(finalCeilingStr);
                                        formattedCeiling = n.format();
                                        if (!String.isBlank(ceilingCurrency)) {
                                            formattedCeiling += ' ' + ceilingCurrency;
                                        }
                                    } catch (Exception e) {
                                        formattedCeiling = finalCeilingStr;
                                        if (!String.isBlank(ceilingCurrency)) {
                                            formattedCeiling += ' ' + ceilingCurrency;
                                        }
                                    }
                                } else if (!String.isBlank(ceilingCurrency)) {
                                    formattedCeiling = ceilingCurrency;
                                }
    
                                List<Object> ratings = (List<Object>) participant.get('rating');
                                if (ratings == null || ratings.isEmpty()) {
                                    Map<String, Object> row = buildBaseRow(
                                        p, extIdToProposal, proposalId,
                                        groupName, statusType,
                                        formattedValidity, formattedPolicyExp,
                                        contrastedUserName,
                                        formattedCeiling, ceilingCurrency, unit,
                                        null, ratingCodeToAnalysis
                                    );
                                    rows.add(row);
                                } else {
                                    for (Object r : ratings) {
                                        Map<String, Object> rMap = (Map<String, Object>) r;
                                        String ratingCode = (String) rMap.get('id');
                                        Map<String, Object> row = buildBaseRow(
                                            p, extIdToProposal, proposalId,
                                            groupName, statusType,
                                            formattedValidity, formattedPolicyExp,
                                            contrastedUserName,
                                            formattedCeiling, ceilingCurrency, unit,
                                            ratingCode, ratingCodeToAnalysis
                                        );
                                        rows.add(row);
                                    }
                                }
                            }
                        }
                    } else {
                        fallbackToDB = true;
                    }
                } else {
                    fallbackToDB = true;
                }
            }
        } catch (Exception e) {
            fallbackToDB = true;
        }
    
        if (fallbackToDB) {
            return getTableDataFromDatabase(parentId);
        }
        return rows;
    }

    private static Map<String, Object> buildBaseRow(
        Map<String, Object> proposal,
        Map<String, arce__SP2_Proposal__c> extIdToProposal,
        String proposalId,
        String groupClientName,
        String statusType,
        String formattedValidity,
        String formattedPolicyExp,
        String contrastedUserName,
        String formattedCeiling,
        String ceilingCurrency,
        String unit,
        String ratingCode,
        Map<String, arce__Analysis__c> ratingCodeToAnalysis
    ) {
        Map<String, Object> row = new Map<String, Object>();

        if (extIdToProposal.containsKey(proposalId)) {
            arce__SP2_Proposal__c pr = extIdToProposal.get(proposalId);
            row.put('Id', pr.Id);
            row.put('name', pr.Name);
            row.put('createdDate', (pr.CreatedDate != null) ? pr.CreatedDate.date().format() : '');
        } else {
            row.put('name', proposalId);
            row.put('createdDate', '');
        }

        row.put('groupClient', groupClientName);
        if (!String.isBlank(statusType)) row.put('statusType', statusType);
        row.put('validityDate', formattedValidity);
        if (!String.isBlank(formattedPolicyExp)) row.put('policyExpirationDate', formattedPolicyExp);
        row.put('contrastedUser', contrastedUserName);
        row.put('finalCeiling', formattedCeiling);
        row.put('ceilingCurrency', ceilingCurrency);
        row.put('unit', unit);

        if (!String.isBlank(ratingCode)) {
            if (ratingCodeToAnalysis.containsKey(ratingCode)) {
                arce__Analysis__c an = ratingCodeToAnalysis.get(ratingCode);
                row.put('analysisId', an.Id);
                row.put('analysisName', an.Name);
            } else {
                row.put('analysisName', ratingCode);
            }
        }

        return row;
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