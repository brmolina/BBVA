public with sharing class ONB_createOnboardingController {

    private static final String CONS_RELATIONSHIP_TYPE = 'Sales Person';

    public class ONB_createOnboardingResult {
        @AuraEnabled public Id accountId;
        @AuraEnabled public Id onboardingId;
    }
    public class ONB_clientInfo {
        @AuraEnabled public String clientName;
        @AuraEnabled public String clientLei;
    }

    @AuraEnabled
    public static ONB_createOnboardingResult createAccountAndOnboarding(
        String clientName,
        String clientLei,
        String clientCif,
        Boolean pendingLei,
        String requestType,
        String parentAccountId,
        String accRecordTypeId,
        String prioritization,
        String branch,
        String segment,
        String legalEntityType,
        String isSalesPerson,
        String clientSalesId,
        String operationInPlatform,
        String anyMasterAgreement,
        Boolean existingClient,
        String clientId
    ) {
        Account acc = new Account();
        if(!existingClient){
            ONB_Client_Field_Autofill__mdt config =ONB_Client_Field_Autofill__mdt.getInstance(legalEntityType.replace(' ', '_'));

            acc.Name = clientName;
            acc.lei_id__c = pendingLei ? '': clientLei;
            acc.ONB_LEI_Pending_Create__c = pendingLei;
            acc.CIF_local__c = clientCif;
            acc.RecordTypeId = accRecordTypeId;
            acc.ParentId = parentAccountId;
            if (config != null) {
                acc.DES_Segment__c = config.ONB_Segment__c;
                acc.DES_Subsegment__c = config.ONB_Subsegment__c;
                acc.DES_Activity__c = config.ONB_Activity__c;
            }
            insert acc;

            if(!String.isEmpty(parentAccountId)){
                AMH_GBL_Account_Relationship__c accRel = new AMH_GBL_Account_Relationship__c();
                accRel.AMH_Child_Account__c = acc.Id;
                accRel.AMH_Parent_Account__c = parentAccountId;
                accRel.AMH_Type__c = '07 - Fondo';
                accRel.AMH_Vision__c = 'Negocio';
                insert accRel;
            }
        }

        ONB_Onboarding__c onb = new ONB_Onboarding__c();
        if (requestType == 'Add funds (without derivations)' || requestType == 'Add funds to an existing contract (with derivatives/repos)') {
            onb.Step__c = 'PRODUCTS';
        } else {
            onb.Step__c = 'AML_KYC';
        }
        onb.Prioritization__c = prioritization;
        onb.Branch__c = branch;
        onb.Segment__c = segment;
        onb.Legal_Entity_Type__c = legalEntityType;
        onb.Is_Sales_Person__c = isSalesPerson;
        onb.Operation_in_Platform__c = operationInPlatform;
        onb.Any_Master_Agreement__c = anyMasterAgreement;
        onb.Client__c = existingClient ? clientId: acc.Id;
        onb.Request_Type__c = requestType;
        onb.Client_Sales_Person__c = String.isEmpty(clientSalesId) ? UserInfo.getUserId() : clientSalesId;
        insert onb;

        ONB_Onboarding_Contact_Relationship__c contactRel = new ONB_Onboarding_Contact_Relationship__c();
        contactRel.OnboardingId__c = onb.Id;
        contactRel.UserId__c = onb.Client_Sales_Person__c;
        contactRel.Relationship_Type__c = CONS_RELATIONSHIP_TYPE;
        insert contactRel;

        ONB_createOnboardingResult res = new ONB_createOnboardingResult();
        res.accountId = existingClient ? clientId: acc.Id;
        res.onboardingId = onb.Id;
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static ONB_clientInfo getClientInfo(Id recordId){
        Account acc = [SELECT Id, Name, lei_id__c FROM Account WHERE Id = :recordId LIMIT 1];

       	ONB_clientInfo res = new ONB_clientInfo();
        res.clientName = acc.Name;
        res.clientLei = acc.lei_id__c;
        return res;
    }
}