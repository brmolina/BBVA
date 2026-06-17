/**
* ────────────────────────────────────────────────────────────────────
* Cuco Participants CIB
* Implementation of the Participant_itf interface methods for CIB
* ────────────────────────────────────────────────────────────────────
* @author      Torcuato tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-06-09
* @modified
* @systemLayer BusinessLogic
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, sf:DMLWithoutSharingEnabled')
global with sharing class CucoParticipantCIB implements cuco.Participant_itf {

    /**
    * @description Returns a List of wrapper with the related info of each account id passed as a parameter in a Set
    * @param accountsIdsSet : Set of the related accounts Ids
    * @return List<cuco.Participants_Wrapper>
    */
    public List<cuco.Participant_Wrapper> getParticipantDetails(Set<Id> accountsIdsSet) {
        final List<cuco.Participant_Wrapper> participants = new List<cuco.Participant_Wrapper>();
        if (!accountsIdsSet.isEmpty()) {
            final List<Account> accounts = [SELECT Id, Name, AccountNumber, g_customer_id__c, DES_ID_Fiscal__c,CUCO_is_vulnerable__c, toLabel(Rating) FROM Account WHERE Id IN :accountsIdsSet];
            if (!accounts.isEmpty()) {
                // final Set<Id> localClients = getLocalClients(accountsIdsSet);
                for (Account account : accounts) {
                    final cuco.Participant_Wrapper participant = new cuco.Participant_Wrapper();
                    participant.participantId = account.Id;
                    participant.participantName = account.Name;
                    participant.documentNumber = account.DES_ID_Fiscal__c;
                    participant.documentType = 'CIF';
                    participant.documentTypeCode = '2';
                    participant.participantCode = account.g_customer_id__c;
                    participant.participantIntegrationId = account.g_customer_id__c + 'C';
                    // participant.rating = (localClients.contains(account.Id))? 'Yes': '';
                    participant.rating = 'Yes';
                    participants.add(participant);
                }
            }
        }
        return participants;
    }

    /**
    * @description Get the participant hierarchy related to param accountId
    * @param accId : Id of the account
    * @return cuco.ParticipantHierarchy_Wrapper with the participant hierarchy info
    *
    * In order to get clients from local client where entity = 0182
    * we would need to change the query to something like this:
    * final List<Account> accounts = [SELECT Cib_Client__c, Cib_Client__r.g_customer_id__c, Cib_Client__r.Name
    * FROM Local_Client__c
    * WHERE entity_id__c  = '0182'
    * AND Cib_Client__c IN (
    *   SELECT Id
    *   FROM Account
    *   WHERE g_customer_id__c != null
    *   AND DES_Main_Parent__c = :client.Id
    *   AND (
    *     (DES_Provisioning_Method__c = 'Datio' AND DES_Structure_Type__c = 'Subsidiary')
    *     OR
    *     (DES_Structure_Type__c = 'NIF Client')
    *   )
    * )];
    *
    */
    public cuco.ParticipantHierarchy_Wrapper getParticipantHierarchy(Id accountId) {

        cuco.ParticipantHierarchy_Wrapper participantHierarchy = new cuco.ParticipantHierarchy_Wrapper();

        final Account client = [SELECT Id, Name, DES_Main_Parent__c, DES_Main_Parent__r.Name, DES_Structure_Type__c, parentId, Parent.Name, g_customer_id__c, DES_ID_Fiscal__c, DES_Main_Parent__r.DES_Group_Code__c, AccountNumber FROM Account WHERE Id = :accountId];

        final Set<Id> children = new Set<Id>();
        final String groupTypes = System.Label.cuco_cib_group_types;
        final List<String> groupNames = groupTypes.split('\\s*,\\s*');

        participantHierarchy.name = client.Name;

        if (groupNames.contains(client.DES_Structure_Type__c)) {

            participantHierarchy.type = 'group';
            participantHierarchy.parentId = client.DES_Main_Parent__c;
            participantHierarchy.parentName = client.DES_Main_Parent__r.Name;
            participantHierarchy.integrationId = client.DES_Main_Parent__r.DES_Group_Code__c;

            final List<Account> accounts = [SELECT Id, g_customer_id__c, Name FROM Account WHERE g_customer_id__c like 'ES%' and DES_Main_Parent__c = :client.Id AND g_customer_id__c != null AND (((DES_Provisioning_Method__c = 'Datio' OR DES_Provisioning_Method__c = 'ADA') AND DES_Structure_Type__c = 'Subsidiary') OR (DES_Structure_Type__c = 'NIF Client'))]; //NOSONAR

            for (Account acc : accounts) {
                // If using local clients query -> children.add(acc.Cib_Client__c);
                children.add(acc.Id);
            }

        } else {

            if (client.DES_Main_Parent__c == null) {
                participantHierarchy.type = 'orphan';
                participantHierarchy.parentId = accountId;
                participantHierarchy.parentName = client.Name;
                participantHierarchy.integrationId = client.g_customer_id__c + 'C';
            } else {
                participantHierarchy.type ='subsidiary';
                participantHierarchy.parentId = client.DES_Main_Parent__c;
                participantHierarchy.parentName = client.DES_Main_Parent__r.Name;
                participantHierarchy.integrationId = client.DES_Main_Parent__r.DES_Group_Code__c;
            }
            children.add(accountId);
        }

        participantHierarchy.childIdsSet = children;
        return participantHierarchy;
    }

    /**
    * @description Returns a List of wrapper with the related info of each account id passed as a parameter in a Set
    * @param accountsIdsSet : Set of the related accounts Ids
    * @param userId: Context user id
    * @return List<cuco.Participants_Wrapper> fill with each participant info
    */
    public List<cuco.Participant_Wrapper> getParticipantsToSelect(Set<Id> accountsIdsSet, Id userId) {
      final List<cuco.Participant_Wrapper> participants = new List<cuco.Participant_Wrapper>();
        if (!accountsIdsSet.isEmpty()) {

            final List<Account> accounts = [SELECT Id, Name, AccountNumber, g_customer_id__c, DES_ID_Fiscal__c, Rating FROM Account WHERE Id IN :accountsIdsSet];
            // final Set<Id> localClients = getLocalClients(accountsIdsSet);

            if (!accounts.isEmpty()) {
                for (Account account : accounts) {
                    final cuco.Participant_Wrapper participant = new cuco.Participant_Wrapper();
                    participant.participantId = account.Id;
                    participant.participantName = account.Name;
                    participant.documentNumber = account.DES_ID_Fiscal__c;
                    participant.documentType = 'CIF';
                    participant.documentTypeCode = '2';
                    participant.participantCode = account.g_customer_id__c;
                    participant.participantIntegrationId = account.g_customer_id__c + 'C';
                    participant.isCustomer = true;
                    // participant.rating = (localClients.contains(account.Id))? 'Yes': '';
                    participant.rating = 'Yes';
                    participants.add(participant);
                }
            }
        }
        return participants;
    }

    /**
    * @description Returns a List of wrapper with the related info of each account id passed as a parameter in a Set
    * @param accountsIdsSet : Set of the related accounts Ids
    * @param userId: Context user id
    * @return Map<String,Id> fill with each participant info
    */
    public static Map<String,Id> getParticipantsIds(Set<String> partIntegrationIds) {
        final Map<String,Id> mapAcc = new Map<String,Id>();
        final Set<String> parInteIdsSplit = new Set<String>();
        if (!partIntegrationIds.isEmpty()) {
            for (String inte: partIntegrationIds) {
                parInteIdsSplit.add(inte.substring(0,15));
            }
            if (!parInteIdsSplit.isEmpty()) {
                final List<Account> lstAcc = [SELECT Id, g_customer_id__c, AccountNumber FROM Account WHERE g_customer_id__c IN :parInteIdsSplit];
                for (Account account: lstAcc) {
                    mapAcc.put(account.g_customer_id__c, account.Id);
                }
            }
        }
        return mapAcc;
    }

    /**
    * @description Returns descendants recursively
    * @param accountsIdsSet : Set of the related accounts Ids
    * @return Set<Id> descendantIds
    */
    public static Set<Id> getDescendants(Set<Id> accountsIdsSet) {

        final Set<Id> res = new Set<Id>();
        final List<AMH_GBL_Account_Relationship__c> relationships = [SELECT Id, AMH_Child_Account__c, AMH_Child_Account__r.Name, AMH_Child_Account__r.Is_Group__c FROM AMH_GBL_Account_Relationship__c WHERE AMH_Parent_Account__c IN :accountsIdsSet AND AMH_Vision__c = 'Negocio'];

        for (AMH_GBL_Account_Relationship__c relationship : relationships) {

            if(relationship.AMH_Child_Account__r.Is_Group__c) {
                final Set<Id> descendants = getDescendants(new Set<Id>{relationship.AMH_Child_Account__c});
                for (Id descendant : descendants) {
                    res.add(descendant);
                }
            } else {
                res.add(relationship.AMH_Child_Account__c);
            }
        }
        return res;
    }

    /**
    * @description Returns local clients with entity 0182
    * @param accountsIdsSet : Set of the related accounts Ids
    * @return Set<Id> accounts
    */
    // private static Set<Id> getLocalClients(Set<Id> accountsIdsSet) {
    //     final Set<Id> res = new Set<Id>();
    //     final List<Local_Client__c> localClients = [SELECT Cib_Client__c FROM Local_Client__c WHERE entity_id__c  = '0182' AND Cib_Client__c IN :accountsIdsSet];
    //     for (Local_Client__c localClient : localClients) {
    //         res.add(localClient.Cib_Client__c);
    //     }
    //     return res;
    // }
}