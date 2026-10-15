/**
 * CIBGLOBALD-4374 - Creates (or links) the Sanction Line of an Opportunity when a Risk feature is
 * requested in Approval. Replaces the autolaunched flow DMT_CreateLineFROMOppFeature, step by step:
 *
 *   1. existing Sanction / OtherProducts Line of the Opportunity -> reuse it (link the Opportunity if needed);
 *   2. otherwise: ask the external service for the Line code (the ONLY callout, done before any DML),
 *      create the Line, the Multiholder association and clients, the risk lines and warranties, the
 *      Line Passport, the participants and link the Opportunity.
 *
 * Query / DML cost does not depend on the number of holders, products or participants: every child
 * collection is read with one query and written with one DML statement.
 *
 * Parity note: for a client that is not a Subsidiary and has NO Multiholder association the flow
 * created the Line and then ended without risk lines, Passport, participants or Opportunity link, and
 * returned no Line Id. That behavior is kept (the method returns null in that case).
 */
public without sharing class DMT_SanctionLine_Service {

    private static final String RT_SANCTION = 'Sanction';
    private static final String RT_OTHER_PRODUCTS = 'OtherProducts';
    private static final String RT_LINE_PASSPORT = 'DMT_Line_passport';
    private static final String CODE_ORIGIN = 'ESCD';
    private static final String CODE_OPERATION = 'LIN';
    private static final String CLIENT_TYPE_SUBSIDIARY = 'Subsidiary';
    private static final Integer APPROVAL_LINE_MONTHS = 3;

    public class SanctionLineException extends Exception {}

    /**
     * @param opportunityId Opportunity the Risk feature was requested for
     * @return Id of the Sanction Line to relate the Case to, or null when the flow behavior was to end without one
     */
    public static Id createFromOpportunity(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }

        Opportunity opp = [
            SELECT Id, Name, AccountId, OwnerId, Entific__c, DMT_CurrencyText__c, DMT_Entity__c,
                   DMT_ApproverGlobalBanker__c, DMT_Approver__c, DMT_Booking_Unit_Risk_Analyst__c, DMT_Sanction__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        Id sanctionRecordTypeId = lineRecordTypeId(RT_SANCTION);
        Id otherProductsRecordTypeId = lineRecordTypeId(RT_OTHER_PRODUCTS);

        // One query for every Line already related to the Opportunity.
        Id existingSanctionLineId;
        Boolean hasSanctionOrOtherLine = false;
        for (DMT_Line__c existing : [
            SELECT Id, RecordTypeId
            FROM DMT_Line__c
            WHERE DMT_Opportunity__c = :opportunityId
            ORDER BY CreatedDate ASC
        ]) {
            if (existingSanctionLineId == null) {
                existingSanctionLineId = existing.Id;
            }
            if (existing.RecordTypeId == sanctionRecordTypeId || existing.RecordTypeId == otherProductsRecordTypeId) {
                hasSanctionOrOtherLine = true;
            }
        }

        if (hasSanctionOrOtherLine) {
            if (opp.DMT_Sanction__c == null) {
                update new Opportunity(Id = opp.Id, DMT_Sanction__c = existingSanctionLineId);
            }
            return existingSanctionLineId;
        }

        // The callout comes first: nothing has been written yet, so the integration framework can
        // log without an 'uncommitted work pending' error.
        String lineCode = requestLineCode(opp.Entific__c);

        Account account = [
            SELECT Id, DES_Client_Type__c, g_customer_id__c, DES_Group_Code__c
            FROM Account
            WHERE Id = :opp.AccountId
            LIMIT 1
        ];
        DMT_PassportProfitabilityProcessor.ProfitabilityResult profitability = opportunityProfitability(opp.Id);

        Boolean isSubsidiary = account.DES_Client_Type__c == CLIENT_TYPE_SUBSIDIARY;
        Custom_Association_Opportunity__c sourceAssociation;
        List<DMT_Custom_Association_ClientOpportunity__c> sourceClients = new List<DMT_Custom_Association_ClientOpportunity__c>();
        DMT_Line__c line;

        if (isSubsidiary) {
            List<DMT_Opportunity_Client__c> opportunityClients = [
                SELECT Id, External_Rating__c
                FROM DMT_Opportunity_Client__c
                WHERE DMT_MDE_Opportunity__c = :opp.Id
                LIMIT 1
            ];
            line = buildApprovalLine(opp, lineCode, profitability);
            line.Client_Code__c = account.g_customer_id__c;
            line.OwnerId = opp.OwnerId;
            line.DMT_ClientRating__c = opportunityClients.isEmpty() ? null : opportunityClients[0].External_Rating__c;
        } else {
            List<Custom_Association_Opportunity__c> associations = [
                SELECT Id, CurrencyIsoCode, Group__c, g_customer_id__c, g_group_id__c, gf_origin_application_type__c
                FROM Custom_Association_Opportunity__c
                WHERE Opportunity__c = :opp.Id
                LIMIT 1
            ];
            if (!associations.isEmpty()) {
                sourceAssociation = associations[0];
                sourceClients = [
                    SELECT Id, CurrencyIsoCode, DMT_g_customer_id__c
                    FROM DMT_Custom_Association_ClientOpportunity__c
                    WHERE DMT_Custom_Association_Opportunity__c = :sourceAssociation.Id
                ];
            }
            line = buildApprovalLine(opp, lineCode, profitability);
            line.Client_Code__c = account.DES_Group_Code__c;
        }

        insert line;

        if (!isSubsidiary) {
            if (sourceAssociation == null) {
                // Same as the flow: the Line exists but nothing else is created and no Line Id is returned.
                return null;
            }
            createMultiholderAssociation(line, sourceAssociation, sourceClients, lineCode);
        }

        Id lineId = line.Id;

        // Risk lines, warranties and currency provisions (already bulk).
        DMT_OppToSanctionUtils.OpportunityLineItemWrapper wrapper = new DMT_OppToSanctionUtils.OpportunityLineItemWrapper();
        wrapper.listOli = DMT_Opportunity_Selector.getOpportunityLineItems(opp.Id);
        wrapper.idLine = lineId;
        DMT_OppToSanctionUtils.createRiskLinesAndWarranties(new List<DMT_OppToSanctionUtils.OpportunityLineItemWrapper>{ wrapper });

        insert new Passport__c(DMT_Line__c = lineId, RecordTypeId = passportRecordTypeId());

        // The participants of the Opportunity become Read participants of the new Line.
        List<DMT_TeamMember__c> participants = new List<DMT_TeamMember__c>();
        for (DMT_TeamMember__c opportunityMember : [
            SELECT Id, User__c
            FROM DMT_TeamMember__c
            WHERE Opportunity__c = :opp.Id
        ]) {
            participants.add(DMT_TeamMember_Service.buildLineMember(
                opportunityMember.User__c, lineId, null, DMT_TeamMember_Service.READ_ACCESS, null, null
            ));
        }
        DMT_TeamMember_Service.insertMembers(participants);

        update new Opportunity(Id = opp.Id, DMT_Sanction__c = lineId);

        return lineId;
    }

    private static DMT_Line__c buildApprovalLine(Opportunity opp, String lineCode, DMT_PassportProfitabilityProcessor.ProfitabilityResult profitability) {
        Date today = Date.today();
        DMT_Line__c line = new DMT_Line__c();
        line.Booking_Geography__c = opp.Entific__c;
        line.Client__c = opp.AccountId;
        line.CurrencyIsoCode = opp.DMT_CurrencyText__c;
        line.DMT_ApproverGlobalBanker__c = opp.DMT_ApproverGlobalBanker__c;
        line.DMT_Approver__c = opp.DMT_Approver__c;
        line.DMT_Booking_Unit_Risk_Analyst__c = opp.DMT_Booking_Unit_Risk_Analyst__c;
        line.DMT_Client_Entific__c = opp.Entific__c;
        line.DMT_Entity__c = opp.DMT_Entity__c;
        line.DMT_Opportunity__c = opp.Id;
        line.DMT_Origin__c = 'Salesforce';
        line.End_Date__c = today.addMonths(APPROVAL_LINE_MONTHS);
        line.Line_Id__c = lineCode;
        line.Name = approvalLineName(opp.Name);
        line.RecordTypeId = lineRecordTypeId(System.Label.DMT_RTLineApproval);
        line.Start_Date__c = today;
        line.Status__c = DMT_Constants.APPROVAL;
        if (profitability != null) {
            line.gf_min_raroec_wo_fcg_per__c = profitability.raroec;
            line.gf_min_rorc_wo_fcg_per__c = profitability.rorc;
        }
        return line;
    }

    // Flow formula: SUBSTITUTE(SUBSTITUTE(Name, 'Opportunity', 'Approval'), 'Oportunidad', 'Approval')
    @TestVisible
    private static String approvalLineName(String opportunityName) {
        if (opportunityName == null) {
            return null;
        }
        return opportunityName.replace('Opportunity', 'Approval').replace('Oportunidad', 'Approval');
    }

    // Alpha_Code__c is not writeable (the flow assignment to it had no effect); Alpha_Code_Client__c carries the value.
    private static void createMultiholderAssociation(
        DMT_Line__c line,
        Custom_Association_Opportunity__c source,
        List<DMT_Custom_Association_ClientOpportunity__c> sourceClients,
        String lineCode
    ) {
        Custom_Association__c association = new Custom_Association__c(
            CurrencyIsoCode = source.CurrencyIsoCode,
            DMT_Line__c = line.Id,
            Group__c = source.Group__c,
            g_customer_id__c = source.g_customer_id__c,
            g_group_id__c = source.g_group_id__c,
            gf_customer_group_id__c = lineCode,
            gf_origin_application_type__c = source.gf_origin_application_type__c
        );
        insert association;

        List<Custom_Association_Client__c> clients = new List<Custom_Association_Client__c>();
        for (DMT_Custom_Association_ClientOpportunity__c sourceClient : sourceClients) {
            clients.add(new Custom_Association_Client__c(
                Custom_Association__c = association.Id,
                CurrencyIsoCode = sourceClient.CurrencyIsoCode,
                Alpha_Code_Client__c = sourceClient.DMT_g_customer_id__c,
                g_customer_id__c = sourceClient.DMT_g_customer_id__c,
                g_entific_id__c = association.g_entific_id__c,
                gf_customer_group_id__c = association.gf_customer_group_id__c,
                gf_origin_application_type__c = association.gf_origin_application_type__c
            ));
        }
        if (!clients.isEmpty()) {
            insert clients;
        }

        update new DMT_Line__c(Id = line.Id, Custom_Association__c = association.Id);
    }

    private static String requestLineCode(String entific) {
        List<String> codes = DMT_OpportunityCodes.getOpportunityCodeByFlow(
            new List<List<String>>{ new List<String>{ CODE_ORIGIN, CODE_OPERATION, entific } }
        );
        if (codes == null || codes.isEmpty() || String.isBlank(codes[0])) {
            throw new SanctionLineException('The external service did not return a Line code for the Sanction Line.');
        }
        return codes[0];
    }

    private static DMT_PassportProfitabilityProcessor.ProfitabilityResult opportunityProfitability(Id opportunityId) {
        DMT_PassportProfitabilityProcessor.ProfitabilityRequest request = new DMT_PassportProfitabilityProcessor.ProfitabilityRequest();
        request.opportunityDMTId = opportunityId;
        request.isOpportunityLevel = true;
        List<DMT_PassportProfitabilityProcessor.ProfitabilityResult> results =
            DMT_PassportProfitabilityProcessor.obtenerProfitability(new List<DMT_PassportProfitabilityProcessor.ProfitabilityRequest>{ request });
        return results.isEmpty() ? null : results[0];
    }

    private static Id lineRecordTypeId(String developerName) {
        Schema.RecordTypeInfo info = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get(developerName);
        return info == null ? null : info.getRecordTypeId();
    }

    private static Id passportRecordTypeId() {
        Schema.RecordTypeInfo info = Schema.SObjectType.Passport__c.getRecordTypeInfosByDeveloperName().get(RT_LINE_PASSPORT);
        return info == null ? null : info.getRecordTypeId();
    }
}
