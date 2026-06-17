public with sharing class DMT_CommitmentsTableController {

    // Wrapper de una fila de la tabla
    public class CommitmentRowWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String country;
        @AuraEnabled public String businessLine;
        @AuraEnabled public Date estimatedClosingDate;
    }

    // Wrapper de respuesta completa
    public class CommitmentsResponseWrapper {
        @AuraEnabled public List<CommitmentRowWrapper> rows;
        @AuraEnabled public Boolean hasRows;
    }

    @AuraEnabled(cacheable=true)
    public static CommitmentsResponseWrapper loadCommitments(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id is required');
        }

        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

        if (opp.AccountId == null) {
            CommitmentsResponseWrapper emptyResponse = new CommitmentsResponseWrapper();
            emptyResponse.rows = new List<CommitmentRowWrapper>();
            emptyResponse.hasRows = false;
            return emptyResponse;
        }

        Id rootAccountId = getRootMainParentId(opp.AccountId);
        Set<Id> accountsInGroup = getAllAccountsFromRoot(rootAccountId);

        List<FCSC_Commitment__c> commitmentList = [SELECT Id, Name, FCSC_Estatus_Contacto__c, FCSC_Country__c, FCSC_Business_Line__c, FCSC_Fecha_Vencimiento__c, FCSC_Client__c, FCSC_Oportunidad_Generada__c, FCSC_Oportunidad_Origen__c
                                                   FROM FCSC_Commitment__c
                                                   WHERE FCSC_Client__c IN :accountsInGroup AND FCSC_Oportunidad_Generada__c = null
                                                   // WHERE FCSC_Client__c IN :accountsInGroup AND (FCSC_Oportunidad_Generada__c = null OR FCSC_Oportunidad_Generada__c = :opportunityId)
                                                   ORDER BY FCSC_Fecha_Vencimiento__c DESC];

        List<CommitmentRowWrapper> rowList = new List<CommitmentRowWrapper>();

        for (FCSC_Commitment__c commitmentRecord : commitmentList) {
            CommitmentRowWrapper row = new CommitmentRowWrapper();
            row.id = commitmentRecord.Id;
            row.name = commitmentRecord.Name;
            row.status = commitmentRecord.FCSC_Estatus_Contacto__c;
            row.country = commitmentRecord.FCSC_Country__c;
            row.businessLine = commitmentRecord.FCSC_Business_Line__c;
            row.estimatedClosingDate = commitmentRecord.FCSC_Fecha_Vencimiento__c;
            rowList.add(row);
        }

        CommitmentsResponseWrapper response = new CommitmentsResponseWrapper();
        response.rows = rowList;
        response.hasRows = !rowList.isEmpty();

        return response;
    }

    private static Id getRootMainParentId(Id accountId) {
        Id currentAccountId = accountId;
        Set<Id> visitedIds = new Set<Id>();

        Integer maxDepth = 10;
        Integer depth = 0;

        while (currentAccountId != null && !visitedIds.contains(currentAccountId) && depth < maxDepth) {
            depth++;
            visitedIds.add(currentAccountId);

            Account currentAccount = [SELECT Id, DES_Main_Parent__c FROM Account WHERE Id = :currentAccountId LIMIT 1];

            if (currentAccount.DES_Main_Parent__c == null) {
                return currentAccount.Id;
            }

            currentAccountId = currentAccount.DES_Main_Parent__c;
        }

        return accountId;
    }

    private static Set<Id> getAllAccountsFromRoot(Id rootAccountId) {
        Set<Id> allAccountIds = new Set<Id>();
        Set<Id> currentLevelIds = new Set<Id>();

        allAccountIds.add(rootAccountId);
        currentLevelIds.add(rootAccountId);

        while (!currentLevelIds.isEmpty()) {
            List<Account> childAccounts = [SELECT Id FROM Account WHERE DES_Main_Parent__c IN :currentLevelIds];
            Set<Id> nextLevelIds = new Set<Id>();

            for (Account child : childAccounts) {
                if (!allAccountIds.contains(child.Id)) {
                    allAccountIds.add(child.Id);
                    nextLevelIds.add(child.Id);
                }
            }

            currentLevelIds = nextLevelIds;
        }

        return allAccountIds;
    }
}