/**
* ────────────────────────────────────────────────────────────────────
* Prospect Utils class.
* ────────────────────────────────────────────────────────────────────
* @author     
* @modifiedBy
* @version     1.0
* @created     2026-05-27
* @modified
* ────────────────────────────────────────────────────────────────────
*/
public without sharing class DES_DMT_ProspectUtils {

    /**
     * ________________________________________________________________________________________
     * @description: After Insert — Prospect Groups only.
     *      → POST DES_PostCreateProspect
     * ________________________________________________________________________________________
     */
    public static void callCreateProspect(List<Account> newAccounts) {
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();

        for (Account acc : newAccounts) {
            // Only process Prospect Groups
            Boolean isProspectGroup = acc.RecordTypeId == groupRtId && acc.DES_Group_Code__c != null;
            if (!isProspectGroup) {
                continue;
            }

            // Validate status (not Discarded, null or empty)
            Boolean validStatusProspectGroup = acc.DES_Prospect_Status_Funnel__c != DES_Constants.PROSPECT_STATUS_FUNNEL_DISCARDED &&
                                               acc.DES_Prospect_Status_Funnel__c != null && 
                                               acc.DES_Prospect_Status_Funnel__c != '';

            // Only send to HPG if not already synced
            Boolean existsInHPG = acc.DMT_Prospect_HPG_Sync__c == true;

            // CREATE Prospect Group in HPG - only if valid status and not already in HPG
            if (!existsInHPG && validStatusProspectGroup) {
                DMT_AsyncOrchestrator.enqueue(new DES_ProspectStructurePayload(acc, null, 'DES_PostCreateProspect'));
            }
        }
    }

    /**
     * __________________________________________________________________________________________________
     * @description: After Update — unified create/edit logic for Groups and Subsidiaries.
     *
     * If NOT yet in HPG (DES_HPG_Synced__c = false) 
     *     → POST DES_PostCreateProspect
     * If already in HPG (DES_HPG_Synced__c = true)
     *     → PUT DES_PutEditProspect
     * __________________________________________________________________________________________________
     */
    public static void callCreateEditProspect(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();

        for (Account acc : newAccounts) {
            Account oldAcc = oldAccounts.get(acc.Id);

            Boolean isProspectGroup      = acc.RecordTypeId == groupRtId      && acc.DES_Group_Code__c != null;
            Boolean isProspectSubsidiary = acc.RecordTypeId == subsidiaryRtId && acc.g_customer_id__c  != null;

            if (!isProspectGroup && !isProspectSubsidiary) {
                continue;
            }

            Boolean validStatusProspectSubsidiary = acc.DES_Prospect_Status_Funnel__c != DES_Constants.PROSPECT_STATUS_FUNNEL_IDENTIFIED &&
                                                    acc.DES_Prospect_Status_Funnel__c != DES_Constants.PROSPECT_STATUS_FUNNEL_DISCARDED &&
                                                    acc.DES_Prospect_Status_Funnel__c != null && 
                                                    acc.DES_Prospect_Status_Funnel__c != '';

            Boolean validStatusProspectGroup =  acc.DES_Prospect_Status_Funnel__c != DES_Constants.PROSPECT_STATUS_FUNNEL_DISCARDED &&
                                                acc.DES_Prospect_Status_Funnel__c != null && 
                                                acc.DES_Prospect_Status_Funnel__c != '';
            
            Boolean existsInHPG       = acc.DMT_Prospect_HPG_Sync__c == true;

            // Check if relevant fields changed
            Boolean relevantFieldsChanged = hasRelevantFieldChanges(acc, oldAcc);

            // Check that g_customer_id does not start with P0 and it's not empty or null (only for Prospect Subsidiaries)
            Boolean validCustomerId = String.isNotBlank(acc.g_customer_id__c) && !acc.g_customer_id__c.startsWith('P0');

            // CREATE in HPG - record doesn't exist yet
            if (!existsInHPG && ((isProspectGroup && validStatusProspectGroup) || (isProspectSubsidiary && validStatusProspectSubsidiary && validCustomerId))) {
                DMT_AsyncOrchestrator.enqueue(new DES_ProspectStructurePayload(acc, oldAcc, 'DES_PostCreateProspect'));
            }
            // UPDATE in HPG - record already exists
            else if (existsInHPG && relevantFieldsChanged && ((isProspectGroup && validStatusProspectGroup) || (isProspectSubsidiary && validStatusProspectSubsidiary && validCustomerId))) {
                DMT_AsyncOrchestrator.enqueue(new DES_ProspectStructurePayload(acc, oldAcc, 'DES_PutEditProspect'));
            }
        }
    }

    /**
     * @description Check if relevant fields changed for HPG sync
     * @param newAccount Updated account
     * @param oldAccount Previous account state  
     * @return true if Name, Country, participant_id or g_golden_customer_id changed (depending if Prospect Group or Prospect Subsidiary), false otherwise
     * 
     */
    public static Boolean hasRelevantFieldChanges(Account newAccount, Account oldAccount) {
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();
        
        Boolean isProspectGroup = newAccount.RecordTypeId == groupRtId;
        Boolean isProspectSubsidiary = newAccount.RecordTypeId == subsidiaryRtId;
        
        Boolean isProspectGroupEdit = isProspectGroup && (
                   newAccount.Name != oldAccount.Name
        );
        Boolean isProspectSubsidiaryEdit = isProspectSubsidiary && (
            newAccount.Name != oldAccount.Name ||
            newAccount.DES_Country_Client__c != oldAccount.DES_Country_Client__c ||
            newAccount.participant_id__c != oldAccount.participant_id__c ||
            newAccount.g_golden_customer_id__c != oldAccount.g_golden_customer_id__c
        );
        
        return isProspectGroupEdit || isProspectSubsidiaryEdit;
    }

    /**
    * @description Actualiza Custom_Association__c y Custom_Association_Client__c del Prospect con datos del cliente final en lineas
    * Actualiza DMT_Custom_Association_Opportunity__c y DMT_Opportunity_Client__c del Prospect con datos del cliente final en oportunidades
    * Se utiliza en el flujo de mergeo manual de prospects MergeProspectFlow.
    * @param prospectId Id del prospect
    * @param clientToMerge Account del cliente final
    */
    public static void updateCustomAssociationsForMerge(Id prospectId, Account clientToMerge) {
        // 1. Reasignar primero las lineas que apuntan directamente al prospect.
        final List<DMT_Line__c> linesToUpdate = [
            SELECT Id, Client__c, Custom_Association__c
            FROM DMT_Line__c
            WHERE Client__c = :prospectId
        ];
        final Set<Id> customAssociationIds = new Set<Id>();
        for (DMT_Line__c line : linesToUpdate) {
            line.Client__c = clientToMerge.Id;
            if (line.Custom_Association__c != null) {
            customAssociationIds.add(line.Custom_Association__c);
            }
        }
        // 2. Obtener el g_customer_id__c del Prospect
        final List<Account> prospectAccounts = [
            SELECT Id, g_customer_id__c
            FROM Account
            WHERE Id = :prospectId
            LIMIT 1
        ];
        if (prospectAccounts.isEmpty()) {
            System.debug('log::Prospect not found');
            return;
        }
        final String prospectCustomerId = prospectAccounts[0].g_customer_id__c;
        if (String.isBlank(prospectCustomerId)) {
            System.debug('log::Prospect g_customer_id__c is blank, fallback to line associations');
        }
        // 3. Obtener groupStructure y determinar el código del grupo
        final Map<String, Object> groupStructure = DMT_HPG_Utils.buildClientGroupStructure(clientToMerge.Id);
        String groupCode = null;
        if (groupStructure.get('supragroupId') != null) {
            groupCode = (String) groupStructure.get('supragroupId');
        } else if (groupStructure.get('groupCode') != null) {
            groupCode = (String) groupStructure.get('groupCode');
        }
        // 5. Extraer g_entific_id__c del clientToMerge
        final String entificId = String.isNotBlank(clientToMerge.g_customer_id__c) && clientToMerge.g_customer_id__c.length() >= 2 ? clientToMerge.g_customer_id__c.substring(0, 2) : null;
        // 6. Buscar el Account del Group usando el código determinado
        Id groupAccountId = null;
        if (String.isNotBlank(groupCode)) {
            final List<Account> groupAccounts = [
            SELECT Id
            FROM Account
            WHERE DES_Group_Code__c = :groupCode
            LIMIT 1
            ];
            if (!groupAccounts.isEmpty()) {
            groupAccountId = groupAccounts[0].Id;
            }
        }
        // 7-11. Consultar registros del prospect a actualizar
        List<Custom_Association__c> customAssociationsLine = new List<Custom_Association__c>();
        List<Custom_Association_Opportunity__c> customAssociationsOpp = new List<Custom_Association_Opportunity__c>();
        List<Custom_Association_Client__c> customAssociationClients = new List<Custom_Association_Client__c>();
        List<DMT_Opportunity_Client__c> opportunityClients = new List<DMT_Opportunity_Client__c>();
        
        List<DMT_Custom_Association_ClientOpportunity__c> multiholderAccs = new List<DMT_Custom_Association_ClientOpportunity__c>();

        if (String.isNotBlank(prospectCustomerId)) {
            customAssociationsLine = [
                SELECT Id, Group__c, g_customer_id__c, g_group_id__c
                FROM Custom_Association__c
                WHERE g_customer_id__c = :prospectCustomerId AND DMT_Line__c != null
            ];
            customAssociationsOpp = [
                SELECT Id, Group__c, g_customer_id__c, g_group_id__c
                FROM Custom_Association_Opportunity__c
                WHERE g_customer_id__c = :prospectCustomerId AND Opportunity__c != null
            ];
            customAssociationClients = [
                SELECT Id, Name, Alpha_Code_Client__c, g_customer_id__c, g_entific_id__c
                FROM Custom_Association_Client__c
                WHERE g_customer_id__c = :prospectCustomerId
            ];
            opportunityClients = [
                SELECT Id, Alpha_Code_Client__c
                FROM DMT_Opportunity_Client__c
                WHERE Alpha_Code_Client__c = :prospectCustomerId
            ];
            multiholderAccs = [
                SELECT Id, DMT_g_customer_id__c, DMT_g_entific_id__c, DMT_Custom_Association_Opportunity__c
                FROM DMT_Custom_Association_ClientOpportunity__c
                WHERE DMT_g_customer_id__c = :prospectCustomerId
            ];
        } else if (!customAssociationIds.isEmpty()) {
            customAssociationsLine = [
                SELECT Id, Group__c, g_customer_id__c, g_group_id__c
                FROM Custom_Association__c
                WHERE Id IN :customAssociationIds
            ];
            customAssociationClients = [
                SELECT Id, Name, Alpha_Code_Client__c, g_customer_id__c, g_entific_id__c
                FROM Custom_Association_Client__c
                WHERE Custom_Association__c IN :customAssociationIds
            ];
        }
        
        for (Custom_Association__c ca : customAssociationsLine) {
            ca.Group__c = groupAccountId;
            ca.g_customer_id__c = clientToMerge.g_customer_id__c;
            ca.g_group_id__c = groupCode;
        }
        for (Custom_Association_Opportunity__c cao : customAssociationsOpp) {
            cao.Group__c = groupAccountId;
            cao.g_customer_id__c = clientToMerge.g_customer_id__c;
            cao.g_group_id__c = groupCode;
        }
        for (Custom_Association_Client__c cac : customAssociationClients) {
            cac.Alpha_Code_Client__c = clientToMerge.g_customer_id__c;
            cac.g_customer_id__c = clientToMerge.g_customer_id__c;
            cac.g_entific_id__c = entificId;
            cac.Name = clientToMerge.Name;
        }
        for (DMT_Opportunity_Client__c oc : opportunityClients) {
            oc.Alpha_Code_Client__c = clientToMerge.g_customer_id__c;
        }
        
        // 12. Evitar duplicados: si el cliente final ya está asociado como partícipe de la misma
        // Custom_Association_Opportunity__c (multiholder), eliminar el registro del prospect en vez de actualizarlo.
        final Set<Id> associationOppIdsWithClient = new Set<Id>();
        if (!multiholderAccs.isEmpty() && String.isNotBlank(clientToMerge.g_customer_id__c)) {
            final List<DMT_Custom_Association_ClientOpportunity__c> existingClientAssociations = [
                SELECT Id, DMT_Custom_Association_Opportunity__c
                FROM DMT_Custom_Association_ClientOpportunity__c
                WHERE DMT_g_customer_id__c = :clientToMerge.g_customer_id__c
            ];
            for (DMT_Custom_Association_ClientOpportunity__c existingAssoc : existingClientAssociations) {
                if (existingAssoc.DMT_Custom_Association_Opportunity__c != null) {
                    associationOppIdsWithClient.add(existingAssoc.DMT_Custom_Association_Opportunity__c);
                }
            }
        }
        final List<DMT_Custom_Association_ClientOpportunity__c> multiholderAccsToUpdate = new List<DMT_Custom_Association_ClientOpportunity__c>();
        final List<DMT_Custom_Association_ClientOpportunity__c> multiholderAccsToDelete = new List<DMT_Custom_Association_ClientOpportunity__c>();
        for (DMT_Custom_Association_ClientOpportunity__c associationClientOpp : multiholderAccs) {
            if (associationOppIdsWithClient.contains(associationClientOpp.DMT_Custom_Association_Opportunity__c)) {
                // El cliente final ya está asociado a esta misma oportunidad: descartar el duplicado del prospect.
                multiholderAccsToDelete.add(associationClientOpp);
            } else {
                associationClientOpp.DMT_g_customer_id__c = clientToMerge.g_customer_id__c;
                associationClientOpp.DMT_g_entific_id__c = entificId;
                multiholderAccsToUpdate.add(associationClientOpp);
            }
        }
        
        // Actualizaciones directas sin usar updateList
        if (!linesToUpdate.isEmpty()) {
            update linesToUpdate;
        }
        if (!customAssociationsLine.isEmpty()) {
            update customAssociationsLine;
        }
        if (!customAssociationsOpp.isEmpty()) {
            update customAssociationsOpp;
        }
        if (!customAssociationClients.isEmpty()) {
            update customAssociationClients;
        }
        if (!opportunityClients.isEmpty()) {
            update opportunityClients;
        }
        if (!multiholderAccsToUpdate.isEmpty()) {
            update multiholderAccsToUpdate;
        }
        if (!multiholderAccsToDelete.isEmpty()) {
            delete multiholderAccsToDelete;
        }
    }

    /**
     * @description Reasigna líneas y oportunidades DMT del Prospect al cliente final a mergear. 
     * Se utiliza en el flujo de mergeo manual de prospects MergeProspectFlow.
     * @param sourceGroupId Id del Prospect Group de origen
     * @param targetGroupId Id del grupo del cliente a mergear
     */
    public static void transferProspectRecords(String sourceGroupId, String targetGroupId) {
        Id dmtOppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();        
        List<DMT_Line__c> groupLines = [SELECT Id, Client__c FROM DMT_Line__c WHERE Client__c = :sourceGroupId];        
        List<Opportunity> groupOpps = [SELECT Id, AccountId FROM Opportunity WHERE AccountId = :sourceGroupId AND RecordTypeId = :dmtOppRtId];
        
        // Reasignar al grupo destino
        List<SObject> recordsToUpdate = new List<SObject>();        
        for (DMT_Line__c line : groupLines) {
            line.Client__c = targetGroupId;
            recordsToUpdate.add(line);
        }        
        for (Opportunity opp : groupOpps) {
            opp.AccountId = targetGroupId;
            recordsToUpdate.add(opp);
        }
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
}