public class ONB_MasterAgreementsController {

    private static final String CONTACT_TYPE_INTERNAL_NOTIFICATION = 'Internal_Notification';
    private static final String CATEGORY_REPOS = 'REPOS';
    private static final String CATEGORY_DERIVATIVES = 'DERIVATIVES';
    private static final String CATEGORY_SECURITY_LENDING = 'SECURITY_LENDING';

    public class ContractLineCategoryStatus {
        @AuraEnabled public Boolean hasAssociatedContracts;
        @AuraEnabled public Boolean hasReposContracts;
        @AuraEnabled public Boolean hasDerivativesContracts;
        @AuraEnabled public Boolean hasSecurityLendingContracts;

        public ContractLineCategoryStatus() {
            hasAssociatedContracts = false;
            hasReposContracts = false;
            hasDerivativesContracts = false;
            hasSecurityLendingContracts = false;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Contrato_Marco__c> getContractItems(Id onboardingId) {
        if (onboardingId == null) return new List<Contrato_Marco__c>();
        Set<Id> ids = new Set<Id>();

        for (Contrato_Marco__c c : [
            SELECT Id
            FROM Contrato_Marco__c
            WHERE OnboardingId__c = :onboardingId
        ]) {
            ids.add(c.Id);
        }

        for (ONB_Onboarding_Contract__c j : [
            SELECT Contract__c
            FROM ONB_Onboarding_Contract__c
            WHERE Onboarding__c = :onboardingId
              AND Contract__c != null
        ]) {
            ids.add(j.Contract__c);
        }

        if (ids.isEmpty()) return new List<Contrato_Marco__c>();

        return [
            SELECT Id, master_agreement_type__c, ONB_Origin__c, ONB_Geography__c, ONB_Digital_signature__c, ONB_Who_provides__c, ONB_Annex__c, ONB_Assets__c, ONB_IM_monitorization_required__c, ONB_Is_the_contract_associated__c, OnboardingId__c, ONB_Entry_phase__c, ONB_Counterpartys_custodians__c, ONB_Name_custodian__c, ONB_Reconciliation_system__c, ONB_Name_of_the_Reconciliation_System__c, ONB_Name_of_Counterparty_in_Acadia__c, ONB_Margin_call_automatized__c, ONB_Name_margin_call__c, ONB_BBVAs_Custodian__c
            FROM Contrato_Marco__c
            WHERE Id IN :ids
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static ContractLineCategoryStatus getContractLineCategoryStatus(Id onboardingId, String cacheBuster) {
        ContractLineCategoryStatus status = new ContractLineCategoryStatus();
        if (onboardingId == null) {
            return status;
        }

        List<Contrato_Marco__c> contracts = getContractItems(onboardingId);
        status.hasAssociatedContracts = !contracts.isEmpty();
        if (contracts.isEmpty()) {
            return status;
        }

        Set<String> contractTypes = new Set<String>();
        for (Contrato_Marco__c contractRecord : contracts) {
            String contractType = (contractRecord.master_agreement_type__c == null)
                ? null
                : contractRecord.master_agreement_type__c.trim().toLowerCase();

            if (!String.isBlank(contractType)) {
                contractTypes.add(contractType);
            }
        }

        if (contractTypes.isEmpty()) {
            return status;
        }

        Map<String, Set<String>> categoriesToTypes = loadContractTypesByCategory();
        status.hasReposContracts = hasTypeIntersection(contractTypes, categoriesToTypes.get(CATEGORY_REPOS));
        status.hasDerivativesContracts = hasTypeIntersection(contractTypes, categoriesToTypes.get(CATEGORY_DERIVATIVES));
        status.hasSecurityLendingContracts = hasTypeIntersection(contractTypes, categoriesToTypes.get(CATEGORY_SECURITY_LENDING));

        return status;
    }

    private static Boolean hasTypeIntersection(Set<String> contractTypes, Set<String> categoryTypes) {
        if (contractTypes == null || contractTypes.isEmpty() || categoryTypes == null || categoryTypes.isEmpty()) {
            return false;
        }
        for (String value : contractTypes) {
            if (categoryTypes.contains(value)) {
                return true;
            }
        }
        return false;
    }

    private static Map<String, Set<String>> loadContractTypesByCategory() {
        Map<String, Set<String>> categoriesToTypes = new Map<String, Set<String>>{
            CATEGORY_REPOS => new Set<String>(),
            CATEGORY_DERIVATIVES => new Set<String>(),
            CATEGORY_SECURITY_LENDING => new Set<String>()
        };

        try {
            List<SObject> metadataRows = Database.query(
                'SELECT Master_Agreement_Type__c, Line_Category__c ' +
                'FROM ONB_ContractLineCategory__mdt ' +
                'WHERE Master_Agreement_Type__c != null AND Line_Category__c != null'
            );

            for (SObject row : metadataRows) {
                String contractType = ((String) row.get('Master_Agreement_Type__c'));
                String category = ((String) row.get('Line_Category__c'));
                String normalizedType = String.isBlank(contractType) ? null : contractType.trim().toLowerCase();
                String normalizedCategory = String.isBlank(category) ? null : category.trim().toUpperCase();

                if (!String.isBlank(normalizedType) && categoriesToTypes.containsKey(normalizedCategory)) {
                    categoriesToTypes.get(normalizedCategory).add(normalizedType);
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Unable to load ONB_ContractLineCategory__mdt values: ' + ex.getMessage());
        }

        return categoriesToTypes;
    }

    @AuraEnabled
    public static List<Contrato_Marco__c> getExistingContracts(Id onboardingId) {
        return [
            SELECT Id, master_agreement_type__c, ONB_Origin__c, ONB_Geography__c, ONB_Digital_signature__c, ONB_Who_provides__c, ONB_Annex__c, ONB_Assets__c, ONB_IM_monitorization_required__c, ONB_Is_the_contract_associated__c
            FROM Contrato_Marco__c
            WHERE ONB_Origin__c = 'Existing'
            AND Id NOT IN (
                SELECT Contract__c FROM ONB_Onboarding_Contract__c WHERE Onboarding__c = :onboardingId
            )
            ORDER BY CreatedDate ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Id> getInternalNotificationUserIds(Id onboardingId) {
        if (onboardingId == null) return new List<Id>();

        List<ONB_Onboarding_Contact_Relationship__c> rels = [
            SELECT Id, UserId__c
            FROM ONB_Onboarding_Contact_Relationship__c
            WHERE OnboardingId__c = :onboardingId
              AND ONB_Contact_Type__c = :CONTACT_TYPE_INTERNAL_NOTIFICATION
              AND UserId__c != null
            ORDER BY CreatedDate ASC
        ];

        List<Id> userIds = new List<Id>();
        for (ONB_Onboarding_Contact_Relationship__c r : rels) {
            userIds.add(r.UserId__c);
        }
        return userIds;
    }

    @AuraEnabled
    public static void addInternalNotificationUser(Id onboardingId, Id userId) {
        if (onboardingId == null || userId == null) return;

        List<ONB_Onboarding_Contact_Relationship__c> existing = [
            SELECT Id
            FROM ONB_Onboarding_Contact_Relationship__c
            WHERE OnboardingId__c = :onboardingId
              AND ONB_Contact_Type__c = :CONTACT_TYPE_INTERNAL_NOTIFICATION
              AND UserId__c = :userId
            LIMIT 1
        ];
        if (!existing.isEmpty()) return;

        insert new ONB_Onboarding_Contact_Relationship__c(
            OnboardingId__c = onboardingId,
            UserId__c = userId,
            ONB_Contact_Type__c = CONTACT_TYPE_INTERNAL_NOTIFICATION
        );
    }

    @AuraEnabled
    public static void removeInternalNotificationUser(Id onboardingId, Id userId) {
        if (onboardingId == null || userId == null) return;

        List<ONB_Onboarding_Contact_Relationship__c> toDelete = [
            SELECT Id
            FROM ONB_Onboarding_Contact_Relationship__c
            WHERE OnboardingId__c = :onboardingId
              AND ONB_Contact_Type__c = :CONTACT_TYPE_INTERNAL_NOTIFICATION
              AND UserId__c = :userId
        ];
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }

    @AuraEnabled
    public static void createOnboardingContractsJunction(Id onboardingId, List<Id> contractIds) {
        if (onboardingId == null || contractIds == null || contractIds.isEmpty()) return;

        Set<Id> contractIdSet = new Set<Id>();
        for (Id cid : contractIds) {
            if (cid != null) contractIdSet.add(cid);
        }
        if (contractIdSet.isEmpty()) return;

        Set<Id> existingContractIds = new Set<Id>();
        for (Contrato_Marco__c c : [
            SELECT Id
            FROM Contrato_Marco__c
            WHERE Id IN :contractIdSet
        ]) {
            existingContractIds.add(c.Id);
        }
        if (existingContractIds.isEmpty()) return;

        Set<Id> alreadyLinked = new Set<Id>();
        for (ONB_Onboarding_Contract__c j : [
            SELECT Contract__c
            FROM ONB_Onboarding_Contract__c
            WHERE Onboarding__c = :onboardingId
              AND Contract__c IN :existingContractIds
        ]) {
            alreadyLinked.add(j.Contract__c);
        }

        List<ONB_Onboarding_Contract__c> toInsert = new List<ONB_Onboarding_Contract__c>();
        for (Id cid : existingContractIds) {
            if (alreadyLinked.contains(cid)) continue;

            toInsert.add(new ONB_Onboarding_Contract__c(
                Onboarding__c = onboardingId,
                Contract__c   = cid
            ));
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    @AuraEnabled
    public static void removeOnboardingContractJunction(Id onboardingId, Id contractId) {
        if (onboardingId == null || contractId == null) return;

        List<ONB_Onboarding_Contract__c> rels = [
            SELECT Id
            FROM ONB_Onboarding_Contract__c
            WHERE Onboarding__c = :onboardingId
              AND Contract__c = :contractId
        ];
        if (!rels.isEmpty()) delete rels;
    }

    @AuraEnabled(cacheable=false)
    public static List<String> getAllowedContractsForOnboarding(Id onboardingId) {
        List<ONB_Onboarding_Line__c> lines = [
            SELECT Product2Id__r.Name
            FROM ONB_Onboarding_Line__c
            WHERE OnboardingId__c = :onboardingId
        ];

        Set<String> productNames = new Set<String>();
        for(ONB_Onboarding_Line__c line : lines) {
            if(line.Product2Id__r != null && line.Product2Id__r.Name != null) {
                productNames.add(line.Product2Id__r.Name);
            }
        }

        if(productNames.isEmpty()) {
            return new List<String>();
        }

        if(productNames.size() > 1) {
            Set<String> allContractsSet = new Set<String>();
            List<ONB_Mapeo_Producto_Contrato__mdt> allMetadatas = [
                SELECT Contratos_Permitidos__c
                FROM ONB_Mapeo_Producto_Contrato__mdt
            ];

            for(ONB_Mapeo_Producto_Contrato__mdt mdt : allMetadatas) {
                if(String.isNotBlank(mdt.Contratos_Permitidos__c)) {
                    List<String> contratos = mdt.Contratos_Permitidos__c.split(',');
                    for(String contrato : contratos) {
                        allContractsSet.add(contrato.trim());
                    }
                }
            }
            return new List<String>(allContractsSet);
        }

        List<ONB_Mapeo_Producto_Contrato__mdt> metadatas = [
            SELECT Contratos_Permitidos__c
            FROM ONB_Mapeo_Producto_Contrato__mdt
            WHERE Producto__c IN :productNames
        ];

        Set<String> allowedContractsSet = new Set<String>();
        for(ONB_Mapeo_Producto_Contrato__mdt mdt : metadatas) {
            if(String.isNotBlank(mdt.Contratos_Permitidos__c)) {
                List<String> contratos = mdt.Contratos_Permitidos__c.split(',');
                for(String contrato : contratos) {
                    allowedContractsSet.add(contrato.trim());
                }
            }
        }

        return new List<String>(allowedContractsSet);
    }
}