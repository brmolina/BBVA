@IsTest
public with sharing class DMT_OpportunityCloneUtilTest {

    private static final String SAME_ACCOUNT_OPPORTUNITY = 'Clone Same Account';
    private static final String SUBSIDIARY_TO_GROUP_OPPORTUNITY = 'Clone Subsidiary To Group';
    private static final String GROUP_TO_GROUP_OPPORTUNITY = 'Clone Group To Group';
    private static final String MOCK_MAIN_HOLDER_CUSTOMER_ID = 'ES0000000000001';

    @TestSetup
    static void loadTestData() {
        TriggerBypass.setBypass();

        insert new List<iaso__GBL_Rest_Services_Url__c>{
            DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT', 'https://service.ok', 'ServicesPartition', false),
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket_INT', 'https://validation.ok', 'ServicesPartition', false),
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPG_CommonEndPoint', 'https://group-position.ok', 'ServicesPartition', false),
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint_AUS', 'https://leveraged-lending.ok', 'ServicesPartition', false),
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket_AUS', 'https://validation.ok', 'ServicesPartition', false)
        };

        //Creamos grupos 
        Account targetGroup = DMT_Test_DataFactory.generateGroupAccount(
            'Clone Target Group',
            null,
            null
        );
        targetGroup.DES_Group_Code__c = 'GCLONETARGET001';
        update targetGroup;

        
        Account sourceGroup = DMT_Test_DataFactory.generateGroupAccount(
            'Clone Source Group',
            null,
            null
        );
        sourceGroup.DES_Group_Code__c = 'GCLONESOURCE002';
        update sourceGroup;

        //Creamos subsidiarias para cada grupo

        Account targetGroupSubsidiary = DMT_Test_DataFactory.generateSubsidiaryForGroup((Id)targetGroup.Id, new Map<Schema.SObjectField, Object>
        {
            Account.Name => 'Mock Main Holder Subsidiary',
            Account.g_customer_id__c => MOCK_MAIN_HOLDER_CUSTOMER_ID
        } );

        Account sourceGroupSubsidiary = DMT_Test_DataFactory.generateSubsidiaryForGroup((Id)sourceGroup.Id, new Map<Schema.SObjectField, Object>{
            Account.Name => 'Clone Source Group Subsidiary',
            Account.g_customer_id__c => 'ES0000000000004'
        });
        
        createOpportunityData(
            sourceGroupSubsidiary.Id,
            new Map<String, String>{
                'Name' => SAME_ACCOUNT_OPPORTUNITY,
                'Entific__c' => 'ES'
            }
        );
        

        Opportunity subsidiaryOpportunity = createOpportunityData(
            sourceGroupSubsidiary.Id,
            new Map<String, String>{
                'Name' => SUBSIDIARY_TO_GROUP_OPPORTUNITY,
                'Entific__c' => 'ES',
                'DMT_Opp_Id__c' => 'ESCD26OPP00001112ES'
            }
        );
        //createMultiholderAssociations(subsidiaryOpportunity.Id, sourceGroupSubsidiary);


        Opportunity groupOpportunity = createOpportunityData(
            sourceGroup.Id,
            new Map<String, String>{
                'Name' => GROUP_TO_GROUP_OPPORTUNITY,
                'Entific__c' => 'ES',
                'DMT_Opp_Id__c' => 'ESCD26OPP00001114ES'
            }
        );
        createMultiholderAssociations(groupOpportunity.Id, sourceGroupSubsidiary);

        TriggerBypass.removeBypass();
    }

    @IsTest
    static void clonesSingleHolderOpportunityToSameSubsidiary() {
        Opportunity originalOpportunity = getOpportunity(SAME_ACCOUNT_OPPORTUNITY);
        Account targetAccount = getAccount(originalOpportunity.AccountId);

        DMT_OpportunityCloneUtil.CloneResult result = cloneWithMock(
            originalOpportunity,
            targetAccount
        );

        Assert.isTrue(result.success, 'The same-account clone should succeed. Error: ' + result.errorMessage);
        Assert.isNotNull(result.newOpportunityId, 'The clone must return its Opportunity Id.');

        Opportunity clonedOpportunity = [
            SELECT Id, AccountId, StageName
            FROM Opportunity
            WHERE Id = :result.newOpportunityId
        ];
        Assert.areEqual(targetAccount.Id, clonedOpportunity.AccountId, 'The clone must keep the subsidiary account.');
        Assert.areEqual(System.Label.Draft_Status, clonedOpportunity.StageName, 'The clone must start in Draft status.');
        assertRelatedRecordsWereCloned(originalOpportunity.Id, clonedOpportunity.Id, true);
    }

    @IsTest
    static void clonesSubsidiaryOpportunityToGroupUsingMockMainHolder() {
        Opportunity originalOpportunity = getOpportunity(SUBSIDIARY_TO_GROUP_OPPORTUNITY);
        Account targetGroup = getAccountByName('Clone Target Group');
        Account expectedMainHolder = getAccountByCustomerId(MOCK_MAIN_HOLDER_CUSTOMER_ID);

        DMT_OpportunityCloneUtil.CloneResult result = cloneWithMock(
            originalOpportunity,
            targetGroup
        );

        Assert.isTrue(result.success, 'The subsidiary-to-group clone should succeed. Error: ' + result.errorMessage);
        Assert.isNotNull(result.newOpportunityId, 'The clone must return its Opportunity Id.');

        Opportunity clonedOpportunity = [SELECT Id, AccountId FROM Opportunity WHERE Id = :result.newOpportunityId];
        Assert.areEqual(targetGroup.Id, clonedOpportunity.AccountId, 'The clone must belong to the destination group.');
        assertMainHolderAssociations(result.newOpportunityId, expectedMainHolder);
        assertRelatedRecordsWereCloned(originalOpportunity.Id, result.newOpportunityId, false);
    }

    @IsTest
    static void clonesGroupOpportunityToDifferentGroupUsingTargetSubsidiary() {
        Opportunity originalOpportunity = getOpportunity(GROUP_TO_GROUP_OPPORTUNITY);
        Account targetGroup = getAccountByName('Clone Target Group');
        Account expectedMainHolder = getAccountByCustomerId(MOCK_MAIN_HOLDER_CUSTOMER_ID);

        DMT_OpportunityCloneUtil.CloneResult result = cloneWithMock(
            originalOpportunity,
            targetGroup
        );

        Assert.isTrue(result.success, 'The group-to-group clone should succeed. Error: ' + result.errorMessage);
        Assert.isNotNull(result.newOpportunityId, 'The clone must return its Opportunity Id.');

        Opportunity clonedOpportunity = [SELECT Id, AccountId FROM Opportunity WHERE Id = :result.newOpportunityId];
        Assert.areEqual(targetGroup.Id, clonedOpportunity.AccountId, 'The clone must belong to the new group.');
        assertMainHolderAssociations(result.newOpportunityId, expectedMainHolder);
        assertRelatedRecordsWereCloned(originalOpportunity.Id, result.newOpportunityId, false);
    }

    @IsTest
    static void clonesGroupOpportunityToSameGroup() {
        Opportunity originalOpportunity = getOpportunity(GROUP_TO_GROUP_OPPORTUNITY);
        Account sourceGroup = getAccountByName('Clone Source Group');
        Account expectedMainHolder = getAccountByCustomerId('ES0000000000004');

        DMT_OpportunityCloneUtil.CloneResult result = cloneWithMock(
            originalOpportunity,
            sourceGroup
        );

        Assert.isNotNull(result.newOpportunityId, 'The clone must return its Opportunity Id.');

        Opportunity clonedOpportunity = [SELECT Id, AccountId FROM Opportunity WHERE Id = :result.newOpportunityId];
        Assert.areEqual(sourceGroup.Id, clonedOpportunity.AccountId, 'The clone must belong to the same group.');
        assertMainHolderAssociations(result.newOpportunityId, expectedMainHolder);
        assertRelatedRecordsWereCloned(originalOpportunity.Id, result.newOpportunityId, true);

        // CIBGLOBALD-4806 - the cloned Opportunity Client points to the clone's own Main Holder association
        Custom_Association_Opportunity__c clonedAssociation = [
            SELECT Id FROM Custom_Association_Opportunity__c WHERE Opportunity__c = :result.newOpportunityId LIMIT 1
        ];
        DMT_Opportunity_Client__c clonedClient = [
            SELECT Custom_Association__c FROM DMT_Opportunity_Client__c WHERE DMT_MDE_Opportunity__c = :result.newOpportunityId LIMIT 1
        ];
        Assert.areEqual(clonedAssociation.Id, clonedClient.Custom_Association__c, 'The cloned Opportunity Client must point to the cloned association.');
    }

    private static Opportunity createOpportunityData(Id accountId, Map<String,String> opportunityOverrides) {
        Opportunity opportunity = DMT_Test_DataFactory.generateOpportunityForAccount(
            accountId,
            new Map<Schema.SObjectField, Object>{
                Opportunity.Name => opportunityOverrides.get('Name'),
                Opportunity.Entific__c => opportunityOverrides.get('Entific__c'),
                Opportunity.DMT_Opp_Id__c => opportunityOverrides.get('DMT_Opp_Id__c')
            }
        );
        DMT_Test_DataFactory.generateOpportunityClient(opportunity.Id);

        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(opportunity);
        opportunityLineItem = [
            SELECT Id, UnitPrice
            FROM OpportunityLineItem
            WHERE Id = :opportunityLineItem.Id
        ];
        opportunityLineItem.UnitPrice = 200;
        update opportunityLineItem;

        DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
        DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);
        DMT_Test_DataFactory.generateUnderlyingRestriction(opportunityLineItem);
        insert new DMT_TeamMember__c(
            Opportunity__c = opportunity.Id,
            User__c = UserInfo.getUserId(),
            AccessLevel__c = 'Read'
        );
        return opportunity;
    }

    private static void createMultiholderAssociations(Id opportunityId, Account subsidiary) {
        Custom_Association_Opportunity__c association =
            DMT_Test_DataFactory.generateCustomAssociationOpportunity(
                opportunityId,
                new Map<Schema.SObjectField, Object>{
                    Custom_Association_Opportunity__c.Group__c => subsidiary.Id,
                    Custom_Association_Opportunity__c.g_customer_id__c => subsidiary.g_customer_id__c,
                    Custom_Association_Opportunity__c.g_group_id__c => subsidiary.DES_Group_Code__c,
                    Custom_Association_Opportunity__c.gf_customer_group_id__c => 'SOURCE-' + opportunityId
                }
            );
        DMT_Test_DataFactory.generateCustomAssociationClientOpportunity(
            association.Id,
            subsidiary.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Custom_Association_ClientOpportunity__c.DMT_g_customer_id__c => subsidiary.g_customer_id__c,
                DMT_Custom_Association_ClientOpportunity__c.DMT_gf_customer_group_id__c => 'SOURCE-' + opportunityId,
                DMT_Custom_Association_ClientOpportunity__c.DMT_g_entific_id__c => 'ES'
            }
        );
    }

    private static DMT_OpportunityCloneUtil.CloneResult cloneWithMock(
        Opportunity originalOpportunity,
        Account targetAccount
    ) {
        List<OpportunityLineItem> opportunityLineItems = [
            SELECT Id, OpportunityId, PricebookEntryId, Quantity, UnitPrice, TotalPrice,
                   DMT_Line_Amount__c, DMT_Commitment_Line_Amount__c, DMT_NewMoney_BBVA__c,
                   DMT_OldMoney_BBVA__c, DMT_ExpectedFinal_Take__c, DMT_Expected_Drawn__c,
                   DMT_Liquidity_Fee__c, DES_Commitment_Fees__c, DMT_Extension_Duration_Fees__c,
                   DES_Other_Fees__c, DMT_Reference_Upfront_Fees__c, DMT_Line_Currency__c,
                   entity_role_type__c, DMT_Sub_Limit__c, bbva_prtcp_tranche_amount__c,
                   syndicated_loan_drawn_amount__c, DMT_Deal_amount__c, g_currency_id__c,
                   DMT_TXT_Commitment_Fees__c, DMT_TXT_Extension_Duration_Fees__c,
                   DMT_TXT_Other_Fees_Accrual__c, DMT_TXT_Other_Fees_NonAccrual__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :originalOpportunity.Id
        ];
        List<DMT_Opportunity_Tenor__c> tenors = [
            SELECT Id, DMT_Opportunity_Product__c
            FROM DMT_Opportunity_Tenor__c
            WHERE DMT_Opportunity_Product__c IN :opportunityLineItems
        ];
        List<DMT_Opportunity_Mitigant__c> mitigants = [
            SELECT Id, DMT_Opportunity_Product__c
            FROM DMT_Opportunity_Mitigant__c
            WHERE DMT_Opportunity_Product__c IN :opportunityLineItems
        ];

        DMT_OpportunityCloneUtil.CloneInput input = new DMT_OpportunityCloneUtil.CloneInput();
        input.originalOpportunity = originalOpportunity;
        input.opportunityLineItems = opportunityLineItems;
        input.tenors = tenors;
        input.mitigants = mitigants;
        input.opportunityClient = [
            SELECT Id, DMT_MDE_Opportunity__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :originalOpportunity.Id
            LIMIT 1
        ];
        input.localClient = targetAccount;
        input.participants = [
            SELECT Id, Opportunity__c, AccessLevel__c, User__c
            FROM DMT_TeamMember__c
            WHERE Opportunity__c = :originalOpportunity.Id
        ];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        List<DMT_OpportunityCloneUtil.CloneResult> results =
            DMT_OpportunityCloneUtil.clone(new List<DMT_OpportunityCloneUtil.CloneInput>{ input });
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'The clone invocation must return one result.');
        return results[0];
    }

    private static Opportunity getOpportunity(String opportunityName) {
        return [
            SELECT Id, Name, Entific__c, AccountId, RecordTypeId, gf_opportunity_product_desc__c,
                   StageName, CloseDate
            FROM Opportunity
            WHERE Name = :opportunityName
            LIMIT 1
        ];
    }

    private static Account getAccount(Id accountId) {
        return [
            SELECT Id, Name, DES_Structure_Type__c, DES_Client_Type__c, DES_Group_Code__c,
                   g_customer_id__c
            FROM Account
            WHERE Id = :accountId
        ];
    }

    private static Account getAccountByName(String accountName) {
        return [
            SELECT Id, Name, DES_Structure_Type__c, DES_Client_Type__c, DES_Group_Code__c,
                   g_customer_id__c
            FROM Account
            WHERE Name = :accountName
            LIMIT 1
        ];
    }

    private static Account getAccountByCustomerId(String customerId) {
        return [
            SELECT Id, Name, DES_Structure_Type__c, g_customer_id__c
            FROM Account
            WHERE g_customer_id__c = :customerId
            LIMIT 1
        ];
    }

    private static void assertMainHolderAssociations(Id opportunityId, Account expectedMainHolder) {
        Custom_Association_Opportunity__c association = [
            SELECT Id, Opportunity__c, Group__c, g_customer_id__c, gf_customer_group_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opportunityId
            LIMIT 1
        ];
        Assert.areEqual(expectedMainHolder.Id, association.Group__c, 'The association must use the resolved target subsidiary.');
        Assert.areEqual(expectedMainHolder.g_customer_id__c, association.g_customer_id__c, 'The main holder customer Id must come from the HPG response.');
        Assert.isNotNull(association.gf_customer_group_id__c, 'The association must reference the cloned opportunity external Id.');

        DMT_Custom_Association_ClientOpportunity__c clientAssociation = [
            SELECT DMT_Custom_Association_Opportunity__c, DMT_g_customer_id__c,
                   DMT_gf_customer_group_id__c, DMT_g_entific_id__c
            FROM DMT_Custom_Association_ClientOpportunity__c
            WHERE DMT_Custom_Association_Opportunity__c = :association.Id
            LIMIT 1
        ];
        Assert.areEqual(association.Id, clientAssociation.DMT_Custom_Association_Opportunity__c, 'The client association must be linked to the cloned association.');
        Assert.areEqual(expectedMainHolder.g_customer_id__c, clientAssociation.DMT_g_customer_id__c, 'The client association must use the resolved subsidiary.');
        Assert.areEqual('ES', clientAssociation.DMT_g_entific_id__c, 'The client association must retain the HPG country.');
    }

    private static void assertRelatedRecordsWereCloned(
        Id originalOpportunityId,
        Id clonedOpportunityId,
        Boolean shouldCloneParticipants
    ) {
        List<OpportunityLineItem> originalLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :originalOpportunityId];
        List<OpportunityLineItem> clonedLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :clonedOpportunityId];
        Assert.areEqual(originalLineItems.size(), clonedLineItems.size(), 'All opportunity line items must be cloned.');

        Integer originalTenors = [SELECT COUNT() FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c IN :originalLineItems];
        Integer clonedTenors = [SELECT COUNT() FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c IN :clonedLineItems];
        Assert.areEqual(originalTenors, clonedTenors, 'All tenors must be cloned.');

        Integer originalMitigants = [SELECT COUNT() FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c IN :originalLineItems];
        Integer clonedMitigants = [SELECT COUNT() FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c IN :clonedLineItems];
        Assert.areEqual(originalMitigants, clonedMitigants, 'All mitigants must be cloned.');

        Integer originalUnderlyings = [SELECT COUNT() FROM DMT_Underlying__c WHERE DMT_Opportunity_Product__c IN :originalLineItems];
        Integer clonedUnderlyings = [SELECT COUNT() FROM DMT_Underlying__c WHERE DMT_Opportunity_Product__c IN :clonedLineItems];
        Assert.areEqual(originalUnderlyings, clonedUnderlyings, 'All underlyings must be cloned.');

        Integer clonedParticipants = [SELECT COUNT() FROM DMT_TeamMember__c WHERE Opportunity__c = :clonedOpportunityId];
        Assert.areEqual(shouldCloneParticipants ? 1 : 0, clonedParticipants, 'Participants must only be cloned when the target account is unchanged.');
    }
}