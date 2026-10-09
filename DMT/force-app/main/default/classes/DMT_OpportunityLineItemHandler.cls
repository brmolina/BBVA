public with sharing class DMT_OpportunityLineItemHandler implements Callable{

    // ========================================================================
    // STATIC CACHE (SOQL LIMITS OPTIMIZATION)
    // ========================================================================
    private static Map<Id, Opportunity> cachedDmtOpps;
    private static Id dmtOppRecordTypeId;

    public static Map<Id, Opportunity> getCachedDmtOpportunities(Set<Id> oppIds) {
        if (cachedDmtOpps == null) {
            cachedDmtOpps = new Map<Id, Opportunity>();
        }
        if (dmtOppRecordTypeId == null) {
            dmtOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(DMT_Constants.RT_OPP_DMT_NAME).getRecordTypeId();
        }

        Set<Id> idsToQuery = new Set<Id>();
        for (Id oppId : oppIds) {
            if (!cachedDmtOpps.containsKey(oppId)) {
                idsToQuery.add(oppId);
            }
        }

        if (!idsToQuery.isEmpty()) {
            // Query all fields needed by any method in this handler to guarantee 1 SOQL execution
            for (Opportunity opp : [
                SELECT Id, RecordTypeId, DMT_Notional_Amount_Changed__c, DMT_Opportunity_amount__c,
                       DMT_DATE_Initial_Date__c, DMT_DATE_Maturity_Date__c, 
                       DMT_Initial_Date_Changed__c, DMT_Maturity_Date_Changed__c, DMT_CurrencyText__c
                FROM Opportunity 
                WHERE Id IN :idsToQuery AND RecordTypeId = :dmtOppRecordTypeId
            ]) {
                cachedDmtOpps.put(opp.Id, opp);
            }
            
            // Mark non-DMT Opps with null so we don't query them again
            for (Id queriedId : idsToQuery) {
                if (!cachedDmtOpps.containsKey(queriedId)) {
                    cachedDmtOpps.put(queriedId, null);
                }
            }
        }

        Map<Id, Opportunity> result = new Map<Id, Opportunity>();
        for (Id oppId : oppIds) {
            if (cachedDmtOpps.get(oppId) != null) {
                result.put(oppId, cachedDmtOpps.get(oppId));
            }
        }
        return result;
    }

     public Object call(String action, Map<String, Object> args) {

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

        private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try {
            Map<String, Object> result;

            if(methodName == 'recalculatePriority') {
                String oppId=  String.valueOf(inputMap.get('oppId'));
                recalculatePriority(oppId);
            }
                
        } catch(exception e) {
            Boolean logged = false;
            logged = DES_Exception_Utils.logException(e,
                                                    'DES_Exception_Handler',
                                                    'invokeMethod',
                                                    'DMT',
                                                    '');
            outMap.put('error', true);
            outMap.put('errorMessage', e.getMessage());
        }
        return outMap;
    }


    public static void recalculatePriority(String opportunityId) {

        List<OpportunityLineItem> allLines = DMT_Opportunity_Selector.getAllOpportunityLineItems(opportunityId);

        Map<Id, List<OpportunityLineItem>> groupedByOpp = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : allLines) {
            if (!groupedByOpp.containsKey(oli.OpportunityId)) {
                groupedByOpp.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            groupedByOpp.get(oli.OpportunityId).add(oli);
        }

        List<OpportunityLineItem> updates = new List<OpportunityLineItem>();

        for (Id oppId : groupedByOpp.keySet()) {
            List<OpportunityLineItem> lineItems = groupedByOpp.get(oppId);
            Integer index = 1;

            for (OpportunityLineItem oli : lineItems) {

                // Conversión a formato '01', '02', ...
                String paddedValue = toPadded2(index);
                oli.gf_group_priority_opportunity_id__c = paddedValue;
                updates.add(oli);
                index++;
            }
        }

        if (!updates.isEmpty()) {
            try {
                update updates;
            } catch (DmlException e) {
                System.debug(' Error updating gf_group_priority_opportunity_id__c: ' + e.getMessage());
            }
        }
    }

    public static void handleAfterInsertOrUpdate(List<OpportunityLineItem> newRecords) {
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : newRecords) {
            if (oli.OpportunityId != null) {
                oppIds.add(oli.OpportunityId);
            }
        }

        OpportunityLineItem lastOppLineItem =
            DMT_Opportunity_Selector.getLastOppLineItem(oppIds);

        Integer currentMax;

        if (lastOppLineItem.gf_group_priority_opportunity_id__c != null) {
            try {
                currentMax = Integer.valueOf(lastOppLineItem.gf_group_priority_opportunity_id__c);
            } catch (Exception e) {
                currentMax = 0; 
            }
        } else {
            currentMax = 0;
        }

        Integer nextIndex = currentMax + 1;

            for (OpportunityLineItem oli2 : newRecords) {
                
                String paddedValue = toPadded2(nextIndex);
                oli2.gf_group_priority_opportunity_id__c = paddedValue;

            nextIndex++;
            }


        
    } 
    private static String toPadded2(Integer num) {
    if (num == null) return null;
    return (num < 10 ? '0' : '') + String.valueOf(num);
}


public static void calculateTenorYears(List<OpportunityLineItem> oliList) {
    
    for (OpportunityLineItem oli : oliList) {
        
        Date startDate = oli.gf_initial_date__c;
        Date endDate = oli.gf_maturity_date__c;

        if (startDate == null || endDate == null) {

            oli.DES_Tenor_years__c = null;

        }else{

            Integer diffDays = startDate.daysBetween(endDate);
            Decimal diffYears = Decimal.valueOf(diffDays) / 365;
            Integer roundedYears = (Integer)Math.round(diffYears);
            oli.DES_Tenor_years__c = roundedYears;

        }
    }
}

public static void syncDealAmountWithBbvaCommitment(List<OpportunityLineItem> oliList) {
    if (oliList == null || oliList.isEmpty()) {
        return;
    }

    for (OpportunityLineItem oli : oliList) {
        if (oli.DMT_Deal_amount__c != oli.bbva_prtcp_tranche_amount__c && oli.DMT_Deal_amount__c == null) {
            oli.DMT_Deal_amount__c = oli.bbva_prtcp_tranche_amount__c;
        }

        /*if (oli.DMT_Deal_amount__c != oli.bbva_prtcp_tranche_amount__c && oli.bbva_prtcp_tranche_amount__c == null) {
            oli.DMT_Deal_amount__c = null;
        }*/
    }
}

public static void syncNewMoneyAndFinalTakeWithBbvaCommitment(List<OpportunityLineItem> oliList) {
    if (oliList == null || oliList.isEmpty()) {
        return;
    }

    for (OpportunityLineItem oli : oliList) {
        if (oli.bbva_prtcp_tranche_amount__c == null) {
            continue;
        }

        if (oli.DMT_NewMoney_BBVA__c == null) {
            oli.DMT_NewMoney_BBVA__c = oli.bbva_prtcp_tranche_amount__c;
        }

        if (oli.syndicated_loan_drawn_amount__c == null) {
            oli.syndicated_loan_drawn_amount__c = oli.bbva_prtcp_tranche_amount__c;
        }
    }
}

/**
* @description Calculates the EUR counter-valuation of DMT_Deal_amount__c (using g_currency_id__c
* as the original currency) and stores it in DMT_Deal_Amount_EUR__c, so Opportunity Reports can show
* both the original amount/currency and its EUR equivalent without relying on the native
* CurrencyIsoCode/multicurrency conversion (which cannot differ from the parent Opportunity's currency).
* Called from before insert and before update; does not touch CurrencyIsoCode.
* @param oliList Trigger.new records
*/
public static void calculateDealAmountEur(List<OpportunityLineItem> oliList) {
    if (oliList == null || oliList.isEmpty()) {
        return;
    }

    for (OpportunityLineItem oli : oliList) {
        if (oli.DMT_Deal_amount__c == null || String.isBlank(oli.g_currency_id__c)) {
            oli.DMT_Deal_Amount_EUR__c = null;
            continue;
        }

        oli.DMT_Deal_Amount_EUR__c = DMT_Currency.convert(oli.DMT_Deal_amount__c, oli.g_currency_id__c, 'EUR');
    }
}


public static void calculateGreenSocialBonds(List<OpportunityLineItem> oliList, Map<Id, OpportunityLineItem> oldMap) {
    List<OpportunityLineItem> filteredList = new List<OpportunityLineItem>();
    Set<Id> oppIds = new Set<Id>();
    for (OpportunityLineItem oli : oliList) {
        Boolean hasChanged = oldMap == null;
        if (!hasChanged) {
            OpportunityLineItem oldOli = oldMap.get(oli.Id);
            if (oldOli == null ||
                oli.DMT_Sustainability_bonus_eligible__c != oldOli.DMT_Sustainability_bonus_eligible__c ||
                oli.DMT_Sustainable_Deal_Subtype__c != oldOli.DMT_Sustainable_Deal_Subtype__c ||
                oli.DMT_sustainable_deal_assessment__c != oldOli.DMT_sustainable_deal_assessment__c) {
                hasChanged = true;
            }
        }
        if (hasChanged) {
            filteredList.add(oli);
            if (oli.OpportunityId != null) {
                oppIds.add(oli.OpportunityId);
            }
        }
    }

    if (filteredList.isEmpty() || oppIds.isEmpty()) {
        return;
    }

    // Safely fetch from static cache to save SOQL limits
    Map<Id, Opportunity> filteredOpps = getCachedDmtOpportunities(oppIds);

    if( filteredOpps.isEmpty() ){
        return;
    }
    
    // Process only line items from DMT_Opportunity records, to set social or green bond
    for (OpportunityLineItem oli : filteredList) {
        if (filteredOpps.containsKey(oli.OpportunityId)) {

            oli.gf_green_bonus__c = false;
            oli.gf_social_bond__c = false;

            if (oli.DMT_Sustainability_bonus_eligible__c == 'Yes') {
                Boolean notNull = !String.isBlank(oli.DMT_Sustainable_Deal_Subtype__c);

                if( notNull && oli.DMT_Sustainable_Deal_Subtype__c == DMT_Constants.DMT_SUSTAINABLE_GREEN ){
                    oli.gf_green_bonus__c = true;
                }else if( notNull && oli.DMT_Sustainable_Deal_Subtype__c == DMT_Constants.DMT_SUSTAINABLE_SOCIAL ){
                    oli.gf_social_bond__c = true;
                }else if( notNull && oli.DMT_Sustainable_Deal_Subtype__c == DMT_Constants.DMT_SUSTAINABLE_GREEN_AND_SOCIAL || oli.DMT_sustainable_deal_assessment__c == DMT_Constants.DMT_SUSTAINABILITY_SSL || oli.DMT_sustainable_deal_assessment__c == DMT_Constants.DMT_SUSTAINABILITY_SSL_GREEN ){
                    oli.gf_green_bonus__c = true;
                    oli.gf_social_bond__c = true;
                }
            }
        }
    }
}

    // Helper method for Opportunity amount: use Deal Amount from OLI
    private static Decimal getDealAmountFromBbvaCommitment(OpportunityLineItem oli) {
        if (oli == null) {
            return 0;
        }

        return oli.DMT_Deal_amount__c != null
            ? oli.DMT_Deal_amount__c
            : 0;
    }

    private static Map<Id, Decimal> calculateOppAmountMap( Set<Id> oppIds,Map<Id, OpportunityLineItem> newRecords, Map<Id, OpportunityLineItem> oldRecords,List<OpportunityLineItem> allOliList,Map<Id, Opportunity> filteredOpps ) {
        Map<Id, Decimal> oppAmountMap = new Map<Id, Decimal>();

        // Inicializar en 0 para que el update se dispare aunque no queden productos
        for (Id oppId : oppIds) {
            oppAmountMap.put(oppId, 0);
        }

        for (OpportunityLineItem oli : allOliList) {
            Decimal amount = getDealAmountFromBbvaCommitment(oli);
            if (!oppAmountMap.containsKey(oli.OpportunityId)) {
                oppAmountMap.put(oli.OpportunityId, 0);
            }
                system.debug('*** SE VA A CONVERTIR con valores de trigger');
                system.debug('*** SE VA A CONVERTIR :' + amount + ' DE ESTA DIVISA: ' + oli.g_currency_id__c);
                system.debug('**** a ESTA DIVISA: ' + oli.Opportunity.DMT_CurrencyText__c);
                system.debug('**** TOTAL CAMBIO: ' + DMT_Currency.convert(amount,oli.g_currency_id__c, oli.Opportunity.DMT_CurrencyText__c));
                Decimal convertedAmount = DMT_Currency.convert(amount,oli.g_currency_id__c, oli.Opportunity.DMT_CurrencyText__c);

                if( convertedAmount == null ){
                   Map<Id, OpportunityLineItem> errorSource = newRecords != null ? newRecords : oldRecords;
                   OpportunityLineItem errorOli = errorSource != null ? errorSource.get(oli.Id) : null;
                   if (errorOli != null) {
                    errorOli.addError('Exchange rate not found for the currency pair: ' + oli.g_currency_id__c + ' to opportunity currency ' + oli.Opportunity.DMT_CurrencyText__c);
                }
                }else{
                    oppAmountMap.put(oli.OpportunityId, oppAmountMap.get(oli.OpportunityId) + convertedAmount);
                }
                
        }

        return oppAmountMap;
    }

    public static void calculateDmtOpportunityDealAmount(Map<Id,OpportunityLineItem> newRecords, Map<Id,OpportunityLineItem> oldRecords) {

        if (newRecords == null && oldRecords == null) {
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        Map<Id, OpportunityLineItem> mapOpliConditionById = new Map<Id, OpportunityLineItem>();
        Boolean isInsertContext = newRecords != null && !newRecords.isEmpty() && oldRecords == null;
        Boolean isUpdateContext = newRecords != null && !newRecords.isEmpty() && oldRecords != null;
        Boolean isDeleteContext = (newRecords == null && oldRecords != null && !oldRecords.isEmpty()) ? true : false;

        if (isInsertContext) {
            system.debug('*** SE VA A CONVERTIR - INSERT CONTEXT');
            for (OpportunityLineItem newOli : newRecords.values()) {
                Decimal newAmount = getDealAmountFromBbvaCommitment(newOli);
                Boolean hasDealAmount = newAmount != null && newAmount != 0;
                Boolean hasNotionalAmount = newOli.bbva_prtcp_tranche_amount__c != null && newOli.bbva_prtcp_tranche_amount__c != 0;

                if (newOli.OpportunityId != null && (hasDealAmount || hasNotionalAmount)) {
                    oppIds.add(newOli.OpportunityId);
                    mapOpliConditionById.put(newOli.Id, newOli);
                }
            }
        } else if (isUpdateContext) {
            system.debug('*** SE VA A CONVERTIR - UPDATE CONTEXT');
            for (OpportunityLineItem newOli : newRecords.values()) {
                OpportunityLineItem oldOli = oldRecords.get(newOli.Id);

                Decimal newAmount = getDealAmountFromBbvaCommitment(newOli);
                Decimal oldAmount = getDealAmountFromBbvaCommitment(oldOli);

                Boolean dealAmountChanged = newAmount != oldAmount;
                Boolean currencyChanged = newOli.g_currency_id__c != oldOli.g_currency_id__c;
                Boolean notionalChanged = newOli.bbva_prtcp_tranche_amount__c != oldOli.bbva_prtcp_tranche_amount__c;

                if (newOli.OpportunityId != null && (dealAmountChanged || currencyChanged || notionalChanged)) {
                    system.debug('*** Cambia amount');
                    oppIds.add(newOli.OpportunityId);
                    mapOpliConditionById.put(newOli.Id, newOli);
                }
            }
        } else if (isDeleteContext) {
            system.debug('*** SE VA A CONVERTIR - DELETE CONTEXT');
            for (OpportunityLineItem oldOli : oldRecords.values()) {
                if (oldOli.OpportunityId != null) {
                    oppIds.add(oldOli.OpportunityId);
                }
            }
        }

        if (oppIds.isEmpty()) {
            return;
        }

        // Safely fetch from static cache to save SOQL limits
        Map<Id, Opportunity> filteredOpps = getCachedDmtOpportunities(oppIds);

        if (filteredOpps.isEmpty()) {
            return;
        }

        Map<Id,OpportunityLineItem> allOliList = new Map<Id,OpportunityLineItem>([
            SELECT Id, OpportunityId, DMT_Deal_amount__c, bbva_prtcp_tranche_amount__c, Opportunity.DMT_CurrencyText__c, g_currency_id__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :filteredOpps.keySet()
        ]);

        if(!mapOpliConditionById.isEmpty()){
            for(Id opliId : allOliList.keySet()){
                if(mapOpliConditionById.containsKey(opliId)){
                    allOliList.get(opliId).DMT_Deal_amount__c = mapOpliConditionById.get(opliId).DMT_Deal_amount__c;
                    allOliList.get(opliId).bbva_prtcp_tranche_amount__c = mapOpliConditionById.get(opliId).bbva_prtcp_tranche_amount__c;
                    allOliList.get(opliId).g_currency_id__c = mapOpliConditionById.get(opliId).g_currency_id__c;
                }
            }
        }

        if(isDeleteContext){
            for(Id oldOliId : oldRecords.keySet()){
                    allOliList.remove(oldOliId);
            }
        }

         System.debug('*** Mapa SIN divisas convertidas: '+ allOliList);
        Map<Id, Decimal> oppAmountMap = calculateOppAmountMap(oppIds, newRecords,oldRecords, allOliList.values(), filteredOpps);
        Map<Id, Decimal> oppNotionalConvertedMap = new Map<Id, Decimal>();
        // Inicializar en 0 para que se actualice a 0 cuando no queden productos
        for (Id oppId : oppIds) {
            oppNotionalConvertedMap.put(oppId, 0);
        }
        for (OpportunityLineItem oli : allOliList.values()) {
            if (!oppNotionalConvertedMap.containsKey(oli.OpportunityId)) {
                oppNotionalConvertedMap.put(oli.OpportunityId, 0);
            }
            Decimal rawNotional = oli.bbva_prtcp_tranche_amount__c != null ? oli.bbva_prtcp_tranche_amount__c : 0;
            // Apply currency conversion to notional amount as well
            Decimal convertedNotional = DMT_Currency.convert(rawNotional, oli.g_currency_id__c, oli.Opportunity.DMT_CurrencyText__c);
            
            if (convertedNotional == null) {
                convertedNotional = rawNotional;
            }
            oppNotionalConvertedMap.put(oli.OpportunityId, oppNotionalConvertedMap.get(oli.OpportunityId) + convertedNotional);
        }
        System.debug('*** Mapa divisas convertidas: '+ oppAmountMap);

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Id oppId : oppAmountMap.keySet()) {
            Opportunity opp = new Opportunity(Id = oppId);

            // DMT_CUR_Notional_Amount__c must have currency conversion applied like DMT_Opportunity_amount__c
            opp.DMT_CUR_Notional_Amount__c = (oppNotionalConvertedMap.containsKey(oppId) ? oppNotionalConvertedMap.get(oppId) : 0).setScale(2, RoundingMode.HALF_UP);
            opp.DMT_Opportunity_amount__c = oppAmountMap.get(oppId).setScale(2, RoundingMode.HALF_UP);
            oppsToUpdate.add(opp);
        }

        if (!oppsToUpdate.isEmpty()) {
            try {
                update oppsToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating DMT_CUR_Notional_Amount__c: ' + e.getMessage());
            }
        }
    }

    public static void calculateRiskType(List<OpportunityLineItem> newList, Map<Id, OpportunityLineItem> oldMap) {
        System.debug(LoggingLevel.INFO, '=== CALCULATE RISK TYPE: START ===');
        if (newList == null || newList.isEmpty()) {
            System.debug(LoggingLevel.INFO, '--- ABORT: newList is empty or null.');
            return;
        }

        // ========================================================================
        // 1 & 2. FILTER & GROUP OLIs AND QUERY VALID OPPORTUNITIES
        // ========================================================================
        Map<Id, List<OpportunityLineItem>> unlockedOlisByOppId = getUnlockedOlisByOppId(newList, oldMap);
        if (unlockedOlisByOppId.isEmpty()) {
            System.debug(LoggingLevel.INFO, '--- ABORT: unlockedOlisByOppId is empty (All OLIs skipped).');
            return;
        }

        Map<Id, Opportunity> validOppMap = getCachedDmtOpportunities(unlockedOlisByOppId.keySet());
        if (validOppMap.isEmpty()) {
            System.debug(LoggingLevel.INFO, '--- ABORT: No parent Opportunities matched the DMT Record Type.');
            return;
        }

        // ========================================================================
        // 3. GATHER ELIGIBLE DATA AND GLOBAL PRODUCT TAXONOMY LOOKUPS
        // ========================================================================
        List<OpportunityLineItem> eligibleOlis = new List<OpportunityLineItem>();
        Set<Id> globalProductTaxonomyIds = new Set<Id>();
        for (OpportunityLineItem oli : newList) {
            if (oli.DMT_RiskTypeLocked__c || !validOppMap.containsKey(oli.OpportunityId)) {
                System.debug(LoggingLevel.INFO, '--- SKIP: OLI ' + oli.Id + ' is Locked or has no valid Opportunity.');
                continue;
            }

            if (oli.DMT_Global_Product__c != null) {
                globalProductTaxonomyIds.add(oli.DMT_Global_Product__c);
            }

            eligibleOlis.add(oli);
        }
        if (eligibleOlis.isEmpty()) {
            System.debug(LoggingLevel.INFO, '--- ABORT: eligibleOlis is empty.');
            return;
        }

        // ========================================================================
        // 4. QUERY THE TAXONOMY RECORD REFERENCED BY GLOBAL PRODUCT / GLOBAL MODEL
        // ========================================================================
        if (globalProductTaxonomyIds.isEmpty()) {
            System.debug(LoggingLevel.INFO, '--- ABORT: no Global Product taxonomy lookup is populated.');
            return;
        }

        Map<Id, DMT_Taxonomy_Values__c> taxonomyByGlobalProductId = new Map<Id, DMT_Taxonomy_Values__c>([
            SELECT Id, gf_catalog_atrb_val8_name__c
            FROM DMT_Taxonomy_Values__c
            WHERE Id IN :globalProductTaxonomyIds
            WITH SYSTEM_MODE
        ]);

        // ========================================================================
        // 5. IDENTIFY OLIs THAT REQUIRE A MITIGANT CHECK
        // ========================================================================
        Set<Id> oliIdsForMitigants = new Set<Id>();
        
        for (OpportunityLineItem oli : eligibleOlis) {
            DMT_Taxonomy_Values__c tax = taxonomyByGlobalProductId.get(oli.DMT_Global_Product__c);
            if (tax == null || String.isBlank(tax.gf_catalog_atrb_val8_name__c)) {
                continue;
            }

            // Only queue for Mitigant query if it is 'FIN', has an ID, and tenor is > 1 year
            if (tax.gf_catalog_atrb_val8_name__c.toUpperCase() == 'FIN' && oli.Id != null) {
                if (getTenorDays(oli) > 365) {
                    oliIdsForMitigants.add(oli.Id);
                }
            }
        }
        // ========================================================================
        // 6 & 7. CONDITIONAL MITIGANT QUERY & FINAL EVALUATION MATRIX
        // ========================================================================
        Map<Id, Integer> mitigantCountMap = getMitigantCountMap(oliIdsForMitigants);
        applyRiskTypeEvaluation(eligibleOlis, taxonomyByGlobalProductId, mitigantCountMap);
    }

    // ========================================================================
    // HELPER METHODS FOR CALCULATE RISK TYPE
    // ========================================================================
    private static Map<Id, List<OpportunityLineItem>> getUnlockedOlisByOppId(List<OpportunityLineItem> newList, Map<Id, OpportunityLineItem> oldMap) {
        Map<Id, List<OpportunityLineItem>> unlockedMap = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : newList) {
            OpportunityLineItem oldOli = (oldMap != null) ? oldMap.get(oli.Id) : null;
            
            // Added oldOli != null to prevent NPE during Before Insert
            if (oldOli != null && String.isNotBlank(oli.DMT_Risk_Type__c) && String.isNotBlank(oldOli.DMT_Risk_Type__c) && oli.DMT_Risk_Type__c != oldOli.DMT_Risk_Type__c) {
                oli.DMT_RiskTypeLocked__c = true;
                System.debug(LoggingLevel.INFO, '--- SKIP: OLI ' + oli.Id + ' is Locked due to manual override.');
                continue; 
            }
            if (oli.DMT_RiskTypeLocked__c || oli.OpportunityId == null) {
                System.debug(LoggingLevel.INFO, '--- SKIP: OLI ' + oli.Id + ' is Locked or has no OpportunityId.');
                continue; 
            }
            if (!unlockedMap.containsKey(oli.OpportunityId)) {
                unlockedMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            unlockedMap.get(oli.OpportunityId).add(oli);
        }
        return unlockedMap;
    }

    // HELPER 1: Centralize the days calculation to avoid duplicate code
    private static Integer getTenorDays(OpportunityLineItem oli) {
        if (oli.gf_initial_date__c != null && oli.gf_maturity_date__c != null) {
            return oli.gf_initial_date__c.daysBetween(oli.gf_maturity_date__c);
        }
        return 0;
    }

    // HELPER 2: Isolate the Mitigant SOQL query to drop complexity
    private static Map<Id, Integer> getMitigantCountMap(Set<Id> oliIdsForMitigants) {
        Map<Id, Integer> mitigantCountMap = new Map<Id, Integer>();
        if (!oliIdsForMitigants.isEmpty()) {
            for (AggregateResult ar : [
                SELECT DMT_Opportunity_Product__c oliId, COUNT(Id) cnt 
                FROM DMT_Opportunity_Mitigant__c 
                WHERE DMT_Opportunity_Product__c IN :oliIdsForMitigants WITH SYSTEM_MODE
                GROUP BY DMT_Opportunity_Product__c 
            ]) {
                Id oliId = (Id)ar.get('oliId');
                Integer count = (Integer)ar.get('cnt');
                mitigantCountMap.put(oliId, count);
            }
        } else {
            System.debug(LoggingLevel.INFO, '--- getMitigantCountMap skipped: no oliIdsForMitigants');
        }
        return mitigantCountMap;
    }

    // HELPER 3: Isolate the Evaluation Matrix to drastically reduce the main method's complexity score
    private static void applyRiskTypeEvaluation(List<OpportunityLineItem> eligibleOlis, Map<Id, DMT_Taxonomy_Values__c> taxonomyByGlobalProductId, Map<Id, Integer> mitigantCountMap) {
        for (OpportunityLineItem oli : eligibleOlis) {
            DMT_Taxonomy_Values__c tax = taxonomyByGlobalProductId.get(oli.DMT_Global_Product__c);
            if (tax == null || String.isBlank(tax.gf_catalog_atrb_val8_name__c)) {
                System.debug(LoggingLevel.INFO, '--- SKIP EVAL: no Global Product taxonomy or missing Attribute 8 for OLI ' + oli.Id);
                continue;
            }

            String newRiskType;
            if (tax.gf_catalog_atrb_val8_name__c.toUpperCase() == 'FIN') {
                Integer tenorDays = getTenorDays(oli);
                if (tenorDays <= 365) {
                    newRiskType = '20200'; // label 'S/T Financial Risk'
                } else {
                    Integer mitigants = mitigantCountMap.containsKey(oli.Id) ? mitigantCountMap.get(oli.Id) : 0;
                    if (mitigants == 0) {
                        newRiskType = '10100'; // label 'L/T Unsecured'
                    } else {
                        newRiskType = '10200'; // label 'L/T Financial Risk - Secured'
                    }
                }
            } else {
                newRiskType = tax.gf_catalog_atrb_val8_name__c;
            }
            System.debug(LoggingLevel.INFO, '--- Assigning DMT_Risk_Type__c for OLI ' + oli.Id + ' = ' + newRiskType + ' (previous=' + oli.DMT_Risk_Type__c + ')');
            oli.DMT_Risk_Type__c = newRiskType;
        }
        System.debug('--- applyRiskTypeEvaluation finished');
    }

    /**
     * Populates numeric/percent fields by parsing their corresponding String source fields.
     * Currently maps:
     *   DMT_TXT_Commitment_Fees__c (String) → DES_Commitment_Fees__c (Percent)
     * Add new field pairs to the FIELD_SYNC_MAP to extend behaviour.
     * Handles optional '%' suffix and comma/dot decimal separators.
     * Called from before insert and before update.
     *
     * @param oliList  Trigger.new records
     * @param oldMap   Trigger.oldMap (null on insert)
     */
    // Mapping: sourceTextField → targetDecimalField
    private static final Map<String, String> FIELD_SYNC_MAP = new Map<String, String>{
        'DMT_TXT_Commitment_Fees__c' => 'DES_Commitment_Fees__c',
        'DMT_TXT_Extension_Duration_Fees__c' => 'DMT_Extension_Duration_Fees__c',
        'DMT_TXT_Other_Fees_Accrual__c' => 'DES_Other_Fees__c'
    };

    public static void syncTextToDecimalFields(List<OpportunityLineItem> oliList, Map<Id, OpportunityLineItem> oldMap) {
        if (oliList == null || oliList.isEmpty()) {
            return;
        }

        Map<String, Schema.SObjectField> oliFieldMap = OpportunityLineItem.SObjectType.getDescribe().fields.getMap();

        for (OpportunityLineItem oli : oliList) {
            for (String sourceField : FIELD_SYNC_MAP.keySet()) {
                String targetField = FIELD_SYNC_MAP.get(sourceField);

                if (!oliFieldMap.containsKey(sourceField) || !oliFieldMap.containsKey(targetField)) {
                    System.debug(LoggingLevel.WARN,'syncTextToDecimalFields: invalid field mapping ' + sourceField + ' -> ' + targetField);
                    continue;
                }

                String newVal = (String) oli.get(sourceField);

                // On update, skip pair if the source field has not changed
                if (oldMap != null) {
                    OpportunityLineItem oldOli = oldMap.get(oli.Id);
                    if (oldOli != null && newVal == (String) oldOli.get(sourceField)) {
                        continue;
                    }
                }

                if (String.isBlank(newVal)) {
                    oli.put(targetField, null);
                    continue;
                }

                // Normalize: remove '%', replace common decimal separators with dots, trim whitespace
                String raw = newVal.trim().replace('%', '').replace(',', '.').replace('/', '.').trim();

                try {
                    Decimal parsedValue = Decimal.valueOf(raw);

                    // Validate the parsed value against the field's defined numeric range.
                    // If it exceeds the range, Salesforce would throw an uncontrolled system
                    // error. We intercept it here to show a clear, user-friendly message.
                    Schema.DescribeFieldResult fieldDescribe = oliFieldMap.get(targetField).getDescribe();
                    Integer fieldPrecision  = fieldDescribe.getPrecision();
                    Integer fieldScale      = fieldDescribe.getScale();
                    Integer integerDigits   = fieldPrecision - fieldScale;
                    Decimal maxAllowed      = Decimal.valueOf(10).pow(integerDigits) - Decimal.valueOf(10).pow(-fieldScale);

                    if (parsedValue > maxAllowed || parsedValue < -maxAllowed) {
                        String fieldLabel = fieldDescribe.getLabel();
                        oli.addError(
                            'The value entered for "' + fieldLabel + '" (' + parsedValue.toPlainString() + ') ' +
                            'exceeds the maximum allowed value. Please enter a number between ' +
                            (-maxAllowed).toPlainString() + ' and ' + maxAllowed.toPlainString() + '.'
                        );
                        continue;
                    }

                    oli.put(targetField, parsedValue);
                } catch (Exception e) {
                    // If the value cannot be parsed, leave the target field unchanged
                    System.debug(LoggingLevel.WARN,'syncTextToDecimalFields: could not parse ' + sourceField + ' value "' + newVal + '" for OLI Id=' + oli.Id + ' – ' + e.getMessage());
                }
            }
        }
    }

    public static void calculateOpportunityDatesFromLineItems(List<OpportunityLineItem> newRecords, Map<Id, OpportunityLineItem> oldMap) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : newRecords) {
            if (oli.OpportunityId != null) {
                OpportunityLineItem oldOli = oldMap != null ? oldMap.get(oli.Id) : null;
                // Add to set if it is an Insert, or if the specific date fields were altered
                if (oldOli == null || 
                    oli.gf_initial_date__c != oldOli.gf_initial_date__c || 
                    oli.gf_maturity_date__c != oldOli.gf_maturity_date__c) {
                    oppIds.add(oli.OpportunityId);
                }
            }
        }
        if (oppIds.isEmpty()) {
            return;
        }

        // Safely fetch from static cache to save SOQL limits
        Map<Id, Opportunity> oppMap = getCachedDmtOpportunities(oppIds);
        if (oppMap.isEmpty()) {
            return;
        }

        Map<Id, AggregateResult> aggregatedDatesByOppId = new Map<Id, AggregateResult>();
        for (AggregateResult ar : [
            SELECT OpportunityId oppId,
                   MIN(gf_initial_date__c) minInitial,
                   MAX(gf_maturity_date__c) maxMaturity
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppMap.keySet()
            GROUP BY OpportunityId
        ]) {
            aggregatedDatesByOppId.put((Id)ar.get('oppId'), ar);
        }
        if (aggregatedDatesByOppId.isEmpty()) {
            return;
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : oppMap.values()) {
            AggregateResult ar = aggregatedDatesByOppId.get(opp.Id);
            if (ar == null) {
                continue;
            }

            Date minInitial = (Date)ar.get('minInitial');
            Date maxMaturity = (Date)ar.get('maxMaturity');

            Boolean isInitialDateEditable = opp.DMT_Initial_Date_Changed__c != true;
            Boolean isMaturityDateEditable = opp.DMT_Maturity_Date_Changed__c != true;
            Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
            Boolean shouldUpdate = false;

            // Syncs the Opp date exactly to the Minimum OLI Date
            if (isInitialDateEditable && minInitial != null) {
                if (opp.DMT_DATE_Initial_Date__c != minInitial) {
                    oppToUpdate.DMT_DATE_Initial_Date__c = minInitial;
                    shouldUpdate = true;
                }
            }

            // Syncs the Opp date exactly to the Maximum OLI Date
            if (isMaturityDateEditable && maxMaturity != null) {
                if (opp.DMT_DATE_Maturity_Date__c != maxMaturity) {
                    oppToUpdate.DMT_DATE_Maturity_Date__c = maxMaturity;
                    shouldUpdate = true;
                }
            }

            if (shouldUpdate) {
                oppsToUpdate.add(oppToUpdate);
            }
        }

        if (!oppsToUpdate.isEmpty()) {
            try {
                // Explicitly declares System Mode to satisfy security scanners
                update as system oppsToUpdate;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'DMT_OpportunityLineItemHandler.calculateOpportunityDatesFromLineItems update failed: ' + e.getMessage());
            }
        }
    }
    /**
     * CIBGLOBALD-3748 Executed After Update. Dynamically verify that the opportunitiLineItems fields
     * meet the necessary requirements to be submitted to Clan.
     */
    private static final Set<String> FIELDS_TO_CHECK = new Set<String>{
        'CurrencyIsoCode',
        'DMT_Deal_Amount_Tenors__c',
        'ProductCode',
        'Name',
        'DMT_OldMoney_BBVA__c',
        'DMT_NewMoney_BBVA__c',
        'DMT_sustainable_deal_assessment__c',
        'DMT_PER_Sustainability_Percentage__c',
        'DMT_RateType__c',
        'gf_payment_frequency__c',
        'gf_amortization_type__c',
        'DMT_Sustainable_Deal_Subtype__c',
        'DMT_sustainable_deal_value__c'
    };
    /**
     * CIBGLOBALD-3748 Executed After Update. Dynamically verify that the opportunitiLineItems fields
     * meet the necessary requirements to be submitted to Clan.
     */
    public static void checkOpportunityLineItemChanges(List<OpportunityLineItem> newList, Map<Id, OpportunityLineItem> oldMap) {
        
        Set<Id> opportunityIds = new Set<Id>();
        for (OpportunityLineItem oli : newList) {
            OpportunityLineItem oldOli = oldMap.get(oli.Id);
            if (hasChangedFields(oli, oldOli) && oli.OpportunityId != null) {
                opportunityIds.add(oli.OpportunityId);
            }
        }

        if (!opportunityIds.isEmpty()) {
            Id dmtRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
                [
                    SELECT Id,
                        RecordTypeId,
                        StageName,
                        DMT_Product_Area__c
                    FROM Opportunity
                    WHERE Id IN :opportunityIds
                ]
            );
            for (Opportunity opp : oppMap.values()) {
                if (opp.RecordTypeId == dmtRecordTypeId
                    && opp.StageName == 'Ready to close'
                    && opp.DMT_Product_Area__c == 'IB&F') {

                    System.debug('checkOpportunityLineItemChanges opp: ' + opp.Id);

                    DMT_AsyncOrchestrator.enqueue(
                        new DMT_DynamicMapperPayload(
                            opp.Id,
                            'DMT_Opportunity_RTC_To_Clan',
                            opp.StageName
                        )
                    );
                    DMT_AsyncOrchestrator.flush();
                }
            }
        }
    }

    private static Boolean hasChangedFields(OpportunityLineItem newOli,OpportunityLineItem oldOli) {
        for (String fieldName : FIELDS_TO_CHECK) {
            if (newOli.get(fieldName) != oldOli.get(fieldName)) {
                return true;
            }
        }
        return false;
    }
}