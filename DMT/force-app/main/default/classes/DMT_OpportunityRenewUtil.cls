/**
 * @description Utility class responsible for renewing one or multiple Opportunities.
 *              Clones the original Opportunity and all its related child records:
 *              OppClients, OpportunityLineItems, Tenors, Mitigants, XSells and Participants.
 *              Tenor dates are recalculated proportionally based on the original duration.
 *              XSell values are shifted forward by 1 year (PY←CY, CY←NY, NY←NY1, NY1←null).
 *              Designed to be invoked from LWC components via @AuraEnabled methods.
 *
 * @author      Jimmy Tonato
 * @date        2025
 */
public without sharing class DMT_OpportunityRenewUtil {

    // ─── Input ────────────────────────────────────────────────────────────────────

    public class OppRenewInput {
        @AuraEnabled public String newName { get; set; }
    }

    // ─── Output ───────────────────────────────────────────────────────────────────

    public class OppRenewResult {
        @AuraEnabled public Id      originalOppId { get; set; }
        @AuraEnabled public Id      newOppId      { get; set; }
        @AuraEnabled public Boolean success       { get; set; }
        @AuraEnabled public String  errorMessage  { get; set; }

        public OppRenewResult(Id originalOppId, Id newOppId) {
            this.originalOppId = originalOppId;
            this.newOppId      = newOppId;
            this.success       = true;
        }

        public OppRenewResult(Id originalOppId, String errorMessage) {
            this.originalOppId = originalOppId;
            this.newOppId      = null;
            this.success       = false;
            this.errorMessage  = errorMessage;
        }
    }

    // ─── Field Names Utility ──────────────────────────────────────────────────────

    private static List<String> getFieldNames(Schema.SObjectType objectType, Set<String> fieldsToExclude) {
        Map<String, Schema.SObjectField> fields = objectType.getDescribe().fields.getMap();
        List<String> fieldNames = new List<String>();
        for (String fieldName : fields.keySet()) {
            if (fieldsToExclude == null || !fieldsToExclude.contains(fieldName)) {
                fieldNames.add(fieldName);
            }
        }
        return fieldNames;
    }

    private static List<String> getFieldNames(Schema.SObjectType objectType) {
        return getFieldNames(objectType, null);
    }

    // ─── getFullMonths ────────────────────────────────────────────────────────────

    /**
     * @description Calculates the number of full months between two dates.
     *              Mid-month rounding rule: if the end day falls in the first half
     *              of the month and is before the start day, the month count is decremented.
     *              Returns a minimum of 1 to avoid zero-duration renewals.
     */
    private static Integer getFullMonths(Date startDate, Date endDate) {
        if (startDate == null || endDate == null || startDate > endDate) return 0;
        Integer months         = (endDate.year() - startDate.year()) * 12 + (endDate.month() - startDate.month());
        Integer daysInEndMonth = Date.daysInMonth(endDate.year(), endDate.month());
        Decimal middleOfMonth  = (Decimal) daysInEndMonth / 2;
        if (endDate.day() < startDate.day()) {
            if (endDate.day() <= middleOfMonth) {
                months--;
            }
        }
        return (months <= 0) ? 1 : months;
    }

    // ─── recalculateTenorDates ────────────────────────────────────────────────────

    /**
     * @description Recalculates tenor dates proportionally when renewing an Opportunity.
     *              Tenors must be passed ordered ASC by GF_Tenor_Date__c (as queried).
     *              Rules:
     *                - First tenor  : set to newInitialDate.
     *                - Middle tenors: original day interval from previous tenor applied
     *                                 from the new previous date; capped at newMaturityDate.
     *                - Last tenor   : always set to newMaturityDate.
     */
    private static List<DMT_Opportunity_Tenor__c> recalculateTenorDates(
        List<DMT_Opportunity_Tenor__c> tenors,
        Date originalInitialDate,
        Date newInitialDate,
        Date newMaturityDate
    ) {
        List<DMT_Opportunity_Tenor__c> clones = new List<DMT_Opportunity_Tenor__c>();
        if (tenors == null || tenors.isEmpty()) return clones;

        Date previousOriginalDate = originalInitialDate;
        Date previousNewDate      = newInitialDate;

        for (Integer i = 0; i < tenors.size(); i++) {
            DMT_Opportunity_Tenor__c tenor = tenors[i];
            Boolean isLast = (i == tenors.size() - 1);

            DMT_Opportunity_Tenor__c renewedTenor = tenor.clone(false, false, false, false);
            renewedTenor.Id      = null;
            renewedTenor.OwnerId = UserInfo.getUserId();

            if (isLast) {
                renewedTenor.GF_Tenor_Date__c = newMaturityDate;
            } else {
                Integer days        = previousOriginalDate.daysBetween(tenor.GF_Tenor_Date__c);
                Date calculatedDate = previousNewDate.addDays(days);
                renewedTenor.GF_Tenor_Date__c = (calculatedDate >= newMaturityDate) ? newMaturityDate : calculatedDate;
            }

            previousOriginalDate = tenor.GF_Tenor_Date__c;
            previousNewDate      = renewedTenor.GF_Tenor_Date__c;
            clones.add(renewedTenor);
        }
        return clones;
    }

    // ─── Bulk Queries ─────────────────────────────────────────────────────────────

    private static Map<Id, Opportunity> getOriginalOpportunities(List<Id> opportunityIds) {
        List<String> fieldNames = getFieldNames(Schema.SObjectType.Opportunity.getSObjectType());
        String query = 'SELECT ' + String.join(fieldNames, ', ')
                     + ' FROM Opportunity WHERE Id IN :opportunityIds';
        Map<Id, Opportunity> result = new Map<Id, Opportunity>();
        for (Opportunity opp : (List<Opportunity>) Database.query(query)) {
            result.put(opp.Id, opp);
        }
        return result;
    }

    // Only one OppClient per Opportunity is expected and stored.
    private static Map<Id, DMT_Opportunity_Client__c> getOppClients(List<Id> opportunityIds) {
        List<String> fieldNames = getFieldNames(Schema.SObjectType.DMT_Opportunity_Client__c.getSObjectType());
        String query = 'SELECT ' + String.join(fieldNames, ', ')
                     + ' FROM DMT_Opportunity_Client__c WHERE DMT_MDE_Opportunity__c IN :opportunityIds';
        Map<Id, DMT_Opportunity_Client__c> result = new Map<Id, DMT_Opportunity_Client__c>();
        for (DMT_Opportunity_Client__c oc : (List<DMT_Opportunity_Client__c>) Database.query(query)) {
            result.put(oc.DMT_MDE_Opportunity__c, oc);
        }
        return result;
    }

    private static Map<Id, List<OpportunityLineItem>> getOpportunityLineItems(List<Id> opportunityIds) {
        List<String> fieldNames = getFieldNames(Schema.SObjectType.OpportunityLineItem.getSObjectType());
        String query = 'SELECT ' + String.join(fieldNames, ', ')
                     + ' FROM OpportunityLineItem WHERE OpportunityId IN :opportunityIds';
        Map<Id, List<OpportunityLineItem>> result = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : (List<OpportunityLineItem>) Database.query(query)) {
            if (!result.containsKey(oli.OpportunityId)) {
                result.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            result.get(oli.OpportunityId).add(oli);
        }
        return result;
    }

    // Ordered ASC by GF_Tenor_Date__c as required by recalculateTenorDates().
    private static Map<Id, List<DMT_Opportunity_Tenor__c>> getTenors(List<Id> oliIds) {
        List<String> fieldNames = getFieldNames(Schema.SObjectType.DMT_Opportunity_Tenor__c.getSObjectType());
        String query = 'SELECT ' + String.join(fieldNames, ', ')
                     + ' FROM DMT_Opportunity_Tenor__c'
                     + ' WHERE DMT_Opportunity_Product__c IN :oliIds'
                     + ' ORDER BY GF_Tenor_Date__c ASC';
        Map<Id, List<DMT_Opportunity_Tenor__c>> result = new Map<Id, List<DMT_Opportunity_Tenor__c>>();
        for (DMT_Opportunity_Tenor__c tenor : (List<DMT_Opportunity_Tenor__c>) Database.query(query)) {
            if (!result.containsKey(tenor.DMT_Opportunity_Product__c)) {
                result.put(tenor.DMT_Opportunity_Product__c, new List<DMT_Opportunity_Tenor__c>());
            }
            result.get(tenor.DMT_Opportunity_Product__c).add(tenor);
        }
        return result;
    }

    // Ordered ASC by Year__c to preserve relative year offsets on renewal.
    private static Map<Id, List<DMT_X_Sell__c>> getXSells(List<Id> opportunityIds) {
        List<String> fieldNames = getFieldNames(Schema.SObjectType.DMT_X_Sell__c.getSObjectType());
        String query = 'SELECT ' + String.join(fieldNames, ', ')
                     + ' FROM DMT_X_Sell__c WHERE Opportunity__c IN :opportunityIds'
                     + ' ORDER BY Year__c ASC';
        Map<Id, List<DMT_X_Sell__c>> result = new Map<Id, List<DMT_X_Sell__c>>();
        for (DMT_X_Sell__c xs : (List<DMT_X_Sell__c>) Database.query(query)) {
            if (!result.containsKey(xs.Opportunity__c)) {
                result.put(xs.Opportunity__c, new List<DMT_X_Sell__c>());
            }
            result.get(xs.Opportunity__c).add(xs);
        }
        return result;
    }

    private static Map<Id, List<DMT_Opportunity_Mitigant__c>> getMitigants(List<Id> oliIds) {
        List<String> fieldNames = getFieldNames(Schema.SObjectType.DMT_Opportunity_Mitigant__c.getSObjectType());
        String query = 'SELECT ' + String.join(fieldNames, ', ')
                     + ' FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c IN :oliIds';
        Map<Id, List<DMT_Opportunity_Mitigant__c>> result = new Map<Id, List<DMT_Opportunity_Mitigant__c>>();
        for (DMT_Opportunity_Mitigant__c mit : (List<DMT_Opportunity_Mitigant__c>) Database.query(query)) {
            if (!result.containsKey(mit.DMT_Opportunity_Product__c)) {
                result.put(mit.DMT_Opportunity_Product__c, new List<DMT_Opportunity_Mitigant__c>());
            }
            result.get(mit.DMT_Opportunity_Product__c).add(mit);
        }
        return result;
    }

    private static Map<Id, List<DMT_TeamMember__c>> getParticipants(List<Id> opportunityIds) {
        List<String> fieldNames = getFieldNames(Schema.SObjectType.DMT_TeamMember__c.getSObjectType());
        String query = 'SELECT ' + String.join(fieldNames, ', ')
                     + ' FROM DMT_TeamMember__c WHERE Opportunity__c IN :opportunityIds';
        Map<Id, List<DMT_TeamMember__c>> result = new Map<Id, List<DMT_TeamMember__c>>();
        for (DMT_TeamMember__c p : (List<DMT_TeamMember__c>) Database.query(query)) {
            if (!result.containsKey(p.Opportunity__c)) {
                result.put(p.Opportunity__c, new List<DMT_TeamMember__c>());
            }
            result.get(p.Opportunity__c).add(p);
        }
        return result;
    }

    /**
     * @description Returns the New Money records (DMT_Is_Old_Money__c = false) for a set of OLI Ids.
     *              Used during renewal to carry New Money values forward as Old Money on the child.
     */
    private static List<DMT_Opportunity_Money__c> getNewMoneyRecords(Set<Id> oliIds) {
        return [
            SELECT Id, DMT_Opportunity_Product__c,
                   DMT_Up_Front_Fee_Accrual__c,
                   DMT_Up_Front_Fee_Non_Accrual__c,
                   DMT_Funding_Cost__c,
                   DMT_Liquidity_Fee__c,
                   DMT_Interest_Rate_Period__c,
                   DMT_Applicable_Margin__c,
                   DMT_Pricing_Grid_or_Step_ups__c,
                   DMT_Commitment_Fee__c,
                   DMT_Utilisation_Fee__c,
                   DMT_Extension_Duration_Fee__c,
                   DMT_Other_Fees_Accrual__c,
                   DMT_Other_Fees_Non_Accrual__c,
                   DMT_Expected_Drawn__c,
                   DMT_All_in_Drawn__c,
                   DMT_All_in_Undrawn__c
            FROM DMT_Opportunity_Money__c
            WHERE DMT_Opportunity_Product__c IN :oliIds
            AND   DMT_Is_Old_Money__c = false
        ];
    }

    // ─── Main Methods ─────────────────────────────────────────────────────────────

    @AuraEnabled
    public static OppRenewResult renewOpportunity(Id opportunityId, OppRenewInput input) {
        List<OppRenewResult> results = renewOpportunities(
            new Map<Id, OppRenewInput>{ opportunityId => input }
        );
        return results.isEmpty() ? null : results[0];
    }

    /**
     * @description Renews multiple Opportunities in a single transaction.
     *              For each Opportunity:
     *                1. Retrieves an external line Id via DMT_DealManagement_Handler.
     *                2. Clones the Opportunity with reset fields and updated dates.
     *                3. Clones all child records: OppClients, OLIs, XSells, Tenors, Mitigants, Participants.
     *              Uses partial DML (allOrNone=false) so one failure does not roll back the entire batch.
     */
    @AuraEnabled
    public static List<OppRenewResult> renewOpportunities(Map<Id, OppRenewInput> inputByOppId) {
        
        System.debug(LoggingLevel.DEBUG, '### [renewOpportunity] Called with opportunityId: ' + inputByOppId);
        List<Id>             opportunityIds = new List<Id>(inputByOppId.keySet());
        List<OppRenewResult> results        = new List<OppRenewResult>();

        // ── Bulk queries ──────────────────────────────────────────────────────────
        Map<Id, Opportunity>                       originalOppsMap = getOriginalOpportunities(opportunityIds);
        Map<Id, DMT_Opportunity_Client__c>         clientsMap      = getOppClients(opportunityIds);
        Map<Id, List<OpportunityLineItem>>         olisMap         = getOpportunityLineItems(opportunityIds);

        List<Id> allOliIds = new List<Id>();
        for (List<OpportunityLineItem> olis : olisMap.values()) {
            for (OpportunityLineItem oli : olis) {
                allOliIds.add(oli.Id);
            }
        }

        Map<Id, List<DMT_Opportunity_Tenor__c>>    tenorsMap       = getTenors(allOliIds);
        Map<Id, List<DMT_Opportunity_Mitigant__c>> mitigantsMap    = getMitigants(allOliIds);
        Map<Id, List<DMT_TeamMember__c>>           participantsMap = getParticipants(opportunityIds);
        Map<Id, List<DMT_X_Sell__c>>               xSellsMap       = getXSells(opportunityIds);

        // ── Build renewed Opportunities ───────────────────────────────────────────
        List<Opportunity>    renewedOpps            = new List<Opportunity>();
        Map<Id, Opportunity> originalIdToRenewedOpp = new Map<Id, Opportunity>();

        for (Id oppId : opportunityIds) {
            Opportunity originalOpp = originalOppsMap.get(oppId);
            if (originalOpp == null) {
                results.add(new OppRenewResult(oppId, 'Opportunity not found'));
                continue;
            }

            String lineId = getOppIdExternal(originalOpp.Entific__c);
            if (String.isBlank(lineId)) {
                results.add(new OppRenewResult(oppId,
                    'Could not obtain external ID for Entific: ' + originalOpp.Entific__c));
                continue;
            }

            Opportunity renewedOpp               = originalOpp.clone(false, false, false, false);
            renewedOpp.Id                        = null;
            renewedOpp.AccountId                 = originalOpp.AccountId;
            renewedOpp.DMT_Opp_Id__c             = lineId;
            renewedOpp.StageName                 = System.Label.Draft_Status;
            renewedOpp.OwnerId                   = UserInfo.getUserId();
            renewedOpp.DMT_Sanction__c           = null;
            renewedOpp.DMT_Opp_User_Lock__c      = null;
            renewedOpp.CoreDocsTaxonomyValues__c = '';
          //  renewedOpp.DMT_Ready_to_close__c     = false;
            renewedOpp.DMT_Parent_Opportunity__c = originalOpp.Id;
            renewedOpp.DMT_Parent_Code__c        = originalOpp.DMT_Opp_Id__c;
            renewedOpp.DMT_DATE_Initial_Date__c  = Date.today();
            renewedOpp.DMT_DATE_Maturity_Date__c = Date.today().addMonths(
                getFullMonths(originalOpp.DMT_DATE_Initial_Date__c, originalOpp.DMT_DATE_Maturity_Date__c)
            );

            OppRenewInput input = inputByOppId.get(oppId);
            if (input != null && String.isNotBlank(input.newName)) {
                renewedOpp.Name = input.newName;
            }

            renewedOpps.add(renewedOpp);
            originalIdToRenewedOpp.put(originalOpp.Id, renewedOpp);
        }

        // ── Insert renewed Opportunities (partial DML) ────────────────────────────
        if (!renewedOpps.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.insert(renewedOpps, false);
            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult sr         = saveResults[i];
                Opportunity         renewedOpp = renewedOpps[i];
                Id                  originalId = renewedOpp.DMT_Parent_Opportunity__c;

                if (sr.isSuccess()) {
                    System.debug(LoggingLevel.DEBUG, '### [renewOpportunities] Opp inserted OK → originalId: ' + originalId + ' | newId: ' + sr.getId());
                    results.add(new OppRenewResult(originalId, sr.getId()));
                } else {
                    String errors = '';
                    for (Database.Error err : sr.getErrors()) {
                        errors += err.getMessage() + '; ';
                    }
                    System.debug(LoggingLevel.WARN, '### [renewOpportunities] Opp insert FAILED → originalId: ' + originalId + ' | errors: ' + errors);
                    results.add(new OppRenewResult(originalId, errors));
                    originalIdToRenewedOpp.remove(originalId);
                }
            }
        }

        // ── Clone OppClients, OLIs and XSells ────────────────────────────────────
        List<DMT_Opportunity_Client__c>       renewedClients        = new List<DMT_Opportunity_Client__c>();
        List<DMT_X_Sell__c>                   renewedXSells         = new List<DMT_X_Sell__c>();
        List<OpportunityLineItem>             renewedOlis           = new List<OpportunityLineItem>();
        Map<Id, Map<Id, OpportunityLineItem>> oppIdToRenewedOlisMap = new Map<Id, Map<Id, OpportunityLineItem>>();

        for (Id oppId : originalIdToRenewedOpp.keySet()) {
            Opportunity renewedOpp = originalIdToRenewedOpp.get(oppId);

            // OppClient
            DMT_Opportunity_Client__c oppClient = clientsMap.get(oppId);
            if (oppClient != null) {
                DMT_Opportunity_Client__c renewedClient = oppClient.clone(false, false, false, false);
                renewedClient.Id                     = null;
                renewedClient.DMT_MDE_Opportunity__c = renewedOpp.Id;
                renewedClients.add(renewedClient);
            }

            // OLIs — UnitPrice cleared when TotalPrice also exists (read-only conflict)
            List<OpportunityLineItem> olis = olisMap.get(oppId);
            if (olis != null && !olis.isEmpty()) {
                Map<Id, OpportunityLineItem> renewedOlisByOriginalId = new Map<Id, OpportunityLineItem>();
                for (OpportunityLineItem oli : olis) {
                    OpportunityLineItem renewedOli = oli.clone(false, false, false, false);
                    // One-off deal uses tenor amount; Add Line uses the line commitment amount
                    renewedOli.DMT_OldMoney_BBVA__c = oli.DMT_Line_Oneoffdeal__c == 'One-off deal'
                        ? oli.DMT_Deal_Amount_Tenors__c
                        : oli.DMT_Deal_amount__c;
                    renewedOli.Id                   = null;
                    renewedOli.OpportunityId       = renewedOpp.Id;
                    renewedOli.opportunity_stage_type__c = System.Label.Draft_Status;
                    renewedOli.gf_initial_date__c  = Date.today();
                    renewedOli.gf_maturity_date__c = Date.today().addMonths(
                        getFullMonths(oli.gf_initial_date__c, oli.gf_maturity_date__c)
                    );
                    if (renewedOli.UnitPrice != null && renewedOli.TotalPrice != null) {
                        renewedOli.UnitPrice = null;
                    }
                    renewedOlisByOriginalId.put(oli.Id, renewedOli);
                    renewedOlis.add(renewedOli);
                }
                oppIdToRenewedOlisMap.put(oppId, renewedOlisByOriginalId);
            }

            // XSells — shift values forward by 1 year on renewal:
            //   new PY  ← old CY  (what was current year is now previous year)
            //   new CY  ← old NY
            //   new NY  ← old NY1
            //   new NY1 ← null    (unknown future year)
            List<DMT_X_Sell__c> xSells = xSellsMap.get(oppId);
            if (xSells != null && !xSells.isEmpty()) {
                for (DMT_X_Sell__c xs : xSells) {
                    DMT_X_Sell__c renewedXSell      = xs.clone(false, false, false, false);
                    renewedXSell.Id                 = null;
                    renewedXSell.OwnerId            = UserInfo.getUserId();
                    renewedXSell.Opportunity__c     = renewedOpp.Id;
                    renewedXSell.XSELL_Value_PY__c  = xs.XSELL_Value_CY__c;
                    renewedXSell.XSELL_Value_CY__c  = xs.XSELL_Value_NY__c;
                    renewedXSell.XSELL_Value_NY__c  = xs.XSELL_Value_NY1__c;
                    renewedXSell.XSELL_Value_NY1__c = null;
                    renewedXSells.add(renewedXSell);
                }
            }
        }

        if (!renewedClients.isEmpty()) insert renewedClients;
        if (!renewedOlis.isEmpty())    insert renewedOlis;
        if (!renewedXSells.isEmpty())  insert renewedXSells;

        // ── Build old OLI Id → new OLI Id cross-reference ────────────────────────
        Map<Id, OpportunityLineItem> originalOliById        = new Map<Id, OpportunityLineItem>();
        Map<Id, OpportunityLineItem> renewedOliByOriginalId = new Map<Id, OpportunityLineItem>();

        for (List<OpportunityLineItem> oliList : olisMap.values()) {
            for (OpportunityLineItem oli : oliList) {
                originalOliById.put(oli.Id, oli);
            }
        }
        for (Map<Id, OpportunityLineItem> renewedMap : oppIdToRenewedOlisMap.values()) {
            for (Id originalId : renewedMap.keySet()) {
                renewedOliByOriginalId.put(originalId, renewedMap.get(originalId));
            }
        }

        Map<Id, Id> oldOLItoNewOLI = new Map<Id, Id>();
        for (Id originalOliId : renewedOliByOriginalId.keySet()) {
            oldOLItoNewOLI.put(originalOliId, renewedOliByOriginalId.get(originalOliId).Id);
        }

        // ── Clone Tenors and Mitigants linked to each renewed OLI ────────────────
        List<DMT_Opportunity_Tenor__c>    renewedTenorList    = new List<DMT_Opportunity_Tenor__c>();
        List<DMT_Opportunity_Mitigant__c> renewedMitigantList = new List<DMT_Opportunity_Mitigant__c>();

        for (Id originalOliId : oldOLItoNewOLI.keySet()) {
            OpportunityLineItem originalOli = originalOliById.get(originalOliId);
            OpportunityLineItem renewedOli  = renewedOliByOriginalId.get(originalOliId);

            List<DMT_Opportunity_Tenor__c> tenors = tenorsMap.get(originalOliId);
            if (tenors != null && originalOli != null && renewedOli != null) {
                List<DMT_Opportunity_Tenor__c> renewedTenors = recalculateTenorDates(
                    tenors,
                    originalOli.gf_initial_date__c,
                    Date.today(),
                    renewedOli.gf_maturity_date__c
                );
                for (DMT_Opportunity_Tenor__c renewedTenor : renewedTenors) {
                    renewedTenor.DMT_Opportunity_Product__c = oldOLItoNewOLI.get(originalOliId);
                    renewedTenorList.add(renewedTenor);
                }
            }

            // Mitigants cloned as-is, relinked to the new OLI
            List<DMT_Opportunity_Mitigant__c> mitigants = mitigantsMap.get(originalOliId);
            if (mitigants != null) {
                for (DMT_Opportunity_Mitigant__c mit : mitigants) {
                    DMT_Opportunity_Mitigant__c renewedMitigant = mit.clone(false, false, false, false);
                    renewedMitigant.Id                         = null;
                    renewedMitigant.OwnerId                    = UserInfo.getUserId();
                    renewedMitigant.DMT_Opportunity_Product__c = oldOLItoNewOLI.get(originalOliId);
                    renewedMitigantList.add(renewedMitigant);
                }
            }
        }

        if (!renewedTenorList.isEmpty())    insert renewedTenorList;
        if (!renewedMitigantList.isEmpty()) insert renewedMitigantList;

        // ── Clone Money Records (parent New Money → child Old Money) ─────────────
        List<DMT_Opportunity_Money__c> parentNewMoneyList = getNewMoneyRecords(oldOLItoNewOLI.keySet());
        List<DMT_Opportunity_Money__c> childOldMoneyList  = new List<DMT_Opportunity_Money__c>();
        for (DMT_Opportunity_Money__c parentRec : parentNewMoneyList) {
            Id childOliId = oldOLItoNewOLI.get(parentRec.DMT_Opportunity_Product__c);
            if (childOliId == null) { continue; }
            DMT_Opportunity_Money__c childRec = parentRec.clone(false, true, false, false);
            childRec.Id                         = null;
            childRec.DMT_Opportunity_Product__c = childOliId;
            childRec.DMT_Is_Old_Money__c        = true;
            childRec.Name                       = 'OM-OLD-' + childOliId;
            childOldMoneyList.add(childRec);
        }
        if (!childOldMoneyList.isEmpty()) insert childOldMoneyList;

        // ── Clone Participants ────────────────────────────────────────────────────
        List<DMT_TeamMember__c> renewedParticipants = new List<DMT_TeamMember__c>();
        for (Id oppId : originalIdToRenewedOpp.keySet()) {
            Opportunity renewedOpp = originalIdToRenewedOpp.get(oppId);
            List<DMT_TeamMember__c> participants = participantsMap.get(oppId);
            if (participants != null) {
                for (DMT_TeamMember__c participant : participants) {
                    DMT_TeamMember__c renewedParticipant = participant.clone(false, false, false, false);
                    renewedParticipant.Id             = null;
                    renewedParticipant.OwnerId        = UserInfo.getUserId();
                    renewedParticipant.Opportunity__c = renewedOpp.Id;
                    renewedParticipants.add(renewedParticipant);
                }
            }
        }

        if (!renewedParticipants.isEmpty()) insert renewedParticipants;

        return results;
    }

    // ─── Data Retrieval ───────────────────────────────────────────────────────────

    /**
     * @description Returns all data needed to render the renew Opportunity screen in LWC:
     *              the Opportunity with its Account and OLIs, plus the matching Taxonomy Values
     *              for the Entific (catalog CD07) and the Entity (catalog H006).
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRenewOpportunityData(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id is required.');
        }
        try {
            Opportunity opp = [
                SELECT
                    Id,
                    Name,
                    AccountId,
                    Entific__c,
                    DMT_Entity__c,
                    DMT_RecordTypeName__c,
                    Account.Name,
                    Account.DES_Client_Type__c,
                    Account.DES_Group_Code__c,
                    Account.g_customer_id__c,
                    Account.DES_Country_Client__c,
                    (SELECT Id, OpportunityId, DES_Product_Name__c FROM OpportunityLineItems)
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];

            List<DMT_Taxonomy_Values__c> entificList = [
                SELECT Id, DMT_Key__c, DMT_Value__c, DMT_Name__c, DMT_Catalog__c, DMT_Active__c, DMT_Name_EN__c
                FROM DMT_Taxonomy_Values__c
                WHERE DMT_Catalog__c = 'CD07'
                  AND DMT_Active__c  = true
                  AND DMT_Key__c     = :opp.Entific__c
                LIMIT 1
            ];

            List<DMT_Taxonomy_Values__c> entityList = [
                SELECT Id, DMT_Key__c, DMT_Value__c, DMT_Name__c, DMT_Catalog__c, DMT_Name_EN__c
                FROM DMT_Taxonomy_Values__c
                WHERE DMT_Catalog__c = 'H006'
                  AND DMT_Value__c   = :opp.DMT_Entity__c
                LIMIT 1
            ];

            return new Map<String, Object>{
                'opportunity' => opp,
                'entific'     => entificList.isEmpty() ? null : entificList[0],
                'entity'      => entityList.isEmpty()  ? null : entityList[0]
            };
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve renew opportunity data: ' + e.getMessage());
        }
    }

    // ─── External ID ──────────────────────────────────────────────────────────────

    /**
     * @description Calls DMT_DealManagement_Handler to retrieve the external line Id
     *              used as DMT_Opp_Id__c on the renewed Opportunity.
     */
    private static String getOppIdExternal(String entific) {
        Map<String, Object> inputMap = new Map<String, Object>{
            'linOropp'              => 'OPP',
            'DMT_Client_Entific__c' => entific
        };
        Map<String, Object> wrapperMap = new Map<String, Object>{
            'input'   => inputMap,
            'output'  => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };
        DMT_DealManagement_Handler handler = new DMT_DealManagement_Handler();
        Map<String, Object> response = (Map<String, Object>) handler.call('getLineId', wrapperMap);
        String lineId = (String) response.get('lineId');
        System.debug(LoggingLevel.DEBUG, '### [getOppIdExternal] Calling handler with entific: ' + entific+ ' response line: '+ lineId);
        return lineId;
    }
}