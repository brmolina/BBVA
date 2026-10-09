public with sharing class DMT_OppToSanctionUtils {

    public static List<Integer> cachedEndTermDayOptions;
    public static Map<String, String> cachedMaxTermLabels;

    @InvocableMethod(label='Create Risk Lines and Warranties')
    public static void createRiskLinesAndWarranties(List<OpportunityLineItemWrapper> wrappers) {
        System.debug(wrappers);
        // Listas para insertar
        List<DMT_Risk_Line_Term__c> riskLinesToInsert = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Warranty__c> warrantiesToInsert = new List<DMT_Warranty__c>();
        List<DMT_Currency_Provision__c> currencyToInsert = new List<DMT_Currency_Provision__c>();
        Map<Id,DMT_Risk_Line_Term__c> mapIdOppToRisk = new Map<Id,DMT_Risk_Line_Term__c>();
        List<String> listIdOppLineItems = new List<String>();
        List<String> listIdProducts = new List<String>();
        List<String> listIdOppLineItemsForUnderlyings = new List<String>();

        for (OpportunityLineItemWrapper wrapper : wrappers) {
            for(OpportunityLineItem oli: wrapper.listOli){
                listIdProducts.add(oli.Product2Id);
                listIdOppLineItemsForUnderlyings.add(oli.Id);
            }
        }
        Map<Id, List<DMT_Underlying__c>> mapOliToUnderlyings = DMT_Opportunity_Selector.getUnderlyingsByOliIds(listIdOppLineItemsForUnderlyings);
        Map<Id, List<DMT_Opportunity_Mitigant__c>> mapOliToMitigants = DMT_Opportunity_Selector.getMitigantsByOliIds(listIdOppLineItemsForUnderlyings);
        Map<Id,Product2> mapIdToProduct = DMT_Opportunity_Selector.getProduct2(listIdProducts);

        for (OpportunityLineItemWrapper wrapper : wrappers) {
            for(OpportunityLineItem oli: wrapper.listOli){

                // Crear un DMT_Risk_Line_Term__c por cada OpportunityLineItem
                DMT_Risk_Line_Term__c riskLine = new DMT_Risk_Line_Term__c();
                riskLine.DMT_Line__c = wrapper.idLine;
                riskLine.DMT_Product__c =  oli.Product2Id;
                riskLine.DMT_LastLevelId__c =  oli.DMT_Risk_Type__c;
                riskLine.DMT_Risk_Type__c =  oli.opportunity_risk_name__c;
                riskLine.DMT_Max_Date__c =  oli.gf_maturity_date__c;
                riskLine.g_global_product_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Global_Product_Id__c;
                riskLine.g_global_product_category_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_category__c;
                riskLine.g_global_product_family_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_family__c;
                riskLine.g_gbl_product_subcategory_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_Subcategory__c;
                riskLine.g_global_product_subfamily_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_Subfamily__c;
                riskLine.Name =  mapIdToProduct.get(oli.Product2Id).Name;
                riskLine.DMT_Comments__c = buildCommentsText(mapOliToUnderlyings.get(oli.Id),  oli.g_currency_id__c, oli.gf_country_risk__c, mapOliToMitigants.get(oli.Id));
                riskLine.DMT_Amount__c =  oli.bbva_prtcp_tranche_amount__c;
                riskLine.CurrencyIsoCode =  oli.g_currency_Id__c;
                riskLine.DMT_Init_Term__c =  '0';
                riskLine.DMT_End_Term__c = toMaxAllowedEndTermPicklistValue(oli.gf_initial_date__c, oli.gf_maturity_date__c);
                riskLine.g_branch_id__c =  oli.g_branch_id__c;
                riskLine.gf_group_priority_line_id__c =  oli.gf_group_priority_opportunity_id__c;
                riskLine.g_line_commitment_level_type__c =  oli.g_line_commitment_level_type__c;
                riskLine.g_multioperation_ind_type__c =  oli.g_multioperation_ind_type__c;
                riskLine.gf_payment_frequency__c = oli.gf_payment_frequency__c;
                riskLine.DMT_Line_Tenor__c = oli.DMT_Line_Tenor__c != null ? oli.DMT_Line_Tenor__c.toPlainString() : null;
                riskLine.DMT_Operation_Type__c = oli.DMT_Line_Oneoffdeal__c == 'One-off deal' ? 'OPP' : 'LIN';

                // Se añade traduccion para el campo de amortization Type
                if(oli.gf_amortization_type__c == 'Linear'){
                    riskLine.g_amortization_type__c = '03';
                }else if(oli.gf_amortization_type__c == 'Bullet'){
                    riskLine.g_amortization_type__c = '04';
                }else if(oli.gf_amortization_type__c == 'User-Defined'){
                    if(oli.DMT_balloon_amortization_indicator__c == true){
                        riskLine.g_amortization_type__c = '05';
                    }else if(oli.DMT_bullet_amortization_indicator__c == true){
                        riskLine.g_amortization_type__c = '04';
                    }else{
                        riskLine.g_amortization_type__c = '09';
                    }
                }

                // Agrega aquí los demás campos que necesites copiar o inicializar
                listIdOppLineItems.add(oli.Id);
                mapIdOppToRisk.put(oli.Id,riskLine);
                riskLinesToInsert.add(riskLine);
            }

        }

        if (!riskLinesToInsert.isEmpty()) {
            DMT_WithoutSharingDAO.insertRecords(riskLinesToInsert);
            List<OpportunityLineItem> opliListToUpdate = new List<OpportunityLineItem>();

            for(String opliId : listIdOppLineItems){
                OpportunityLineItem opliToUpdate = new OpportunityLineItem(Id = opliId, DMT_Associated_Line_Product__c = mapIdOppToRisk.get(opliId).Id);
                opliListToUpdate.add(opliToUpdate);
            }

            if(!opliListToUpdate.isEmpty()){
                DMT_WithoutSharingDAO.updateRecords(opliListToUpdate);
            }

            List<DMT_Opportunity_Mitigant__c> listMitigants = [SELECT Id,DMT_Opportunity_Product__c,Mitigant_Type__c, DMT_Opportunity_Product__r.ProductCode, DMT_Opportunity_Product__r.gf_group_priority_opportunity_id__c FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c IN :listIdOppLineItems];
            // Crear DMT_Warranty__c por cada Risk Line creado
            Map<String, String> guaranteeTypeMapCreate = buildGuaranteeTypeMap(listMitigants);
            for (DMT_Opportunity_Mitigant__c mitigant : listMitigants) {
                DMT_Warranty__c warranty = new DMT_Warranty__c();
                warranty.DMT_Risk_Line_Term__c = mapIdOppToRisk.get(mitigant.DMT_Opportunity_Product__c).Id;
                warranty.Name = mitigant.Mitigant_Type__c;
                warranty.gf_group_priority_line_id__c = mitigant.DMT_Opportunity_Product__r.gf_group_priority_opportunity_id__c ;
                warranty.g_limits_grid_guarantee_type__c = guaranteeTypeMapCreate.get(mitigant.Mitigant_Type__c);
                warranty.gf_origin_application_type__c = '04' ;
                warranty.g_entific_id__c = 'HO';
                // Agrega aquí los demás campos que necesites
                warrantiesToInsert.add(warranty);
            }

            if (!warrantiesToInsert.isEmpty()) {
                DMT_WithoutSharingDAO.insertRecords(warrantiesToInsert);
            }
            for(DMT_Risk_Line_Term__c rkl : riskLinesToInsert){
                DMT_Currency_Provision__c currencyprovision = new DMT_Currency_Provision__c();
                currencyprovision.DMT_Risk_Line_Term__c = rkl.Id;
                currencyprovision.Name = rkl.CurrencyIsoCode;
                currencyprovision.g_currency_id__c = rkl.CurrencyIsoCode;
                currencyprovision.gf_group_priority_line_id__c = rkl.gf_group_priority_line_id__c;
                currencyprovision.gf_origin_application_type__c = '04' ;
                currencyprovision.g_entific_id__c = 'HO';
                currencyToInsert.add(currencyprovision);
            }
            if(!currencyToInsert.isEmpty()){
                DMT_WithoutSharingDAO.insertRecords(currencyToInsert);
            }
        }
    }

    public static Map<String, String> getCachedMaxTermLabels() {
        if (cachedMaxTermLabels == null) {
            Schema.DescribeSObjectResult objectDescribe = DMT_Underlying__c.SObjectType.getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get('DMT_Max_Term__c').getDescribe();
            cachedMaxTermLabels = new Map<String, String>();
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                if (String.isNotBlank(entry.getValue())) {
                    cachedMaxTermLabels.put(entry.getValue(), entry.getLabel());
                }
            }
        }
        return cachedMaxTermLabels;
    }

    public static List<Integer> getCachedEndTermDayOptions() {
        // Se obtienen los valores de la picklist DMT_Risk_Line_Term__c.DMT_End_Term__c, se convierte a integer (días) y se ordena.
        if (cachedEndTermDayOptions == null) {
            Schema.DescribeSObjectResult objectDescribe = DMT_Risk_Line_Term__c.SObjectType.getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get('DMT_End_Term__c').getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
            List<Integer> dayOptions = new List<Integer>();

            for (Schema.PicklistEntry entry : picklistEntries) {
                String rawValue = entry.getValue();
                if (String.isBlank(rawValue)) continue;

                try {
                    dayOptions.add(Integer.valueOf(rawValue));
                } catch (Exception e) {
                    DES_Exception_Utils.logException(e, 'DMT_OppToSanctionUtils', 'getCachedEndTermDayOptions', 'DMT', '');
                }
            }
            dayOptions.sort();
            cachedEndTermDayOptions = dayOptions.isEmpty() ? new List<Integer>{0} : dayOptions;
        }
        return cachedEndTermDayOptions;
    }

    public static Integer lowerBound(List<Integer> sortedList, Integer target) {
        // Devuelve el indice del primer elemento >= target y si los elementos son menores que target, devuelve el tamaño de la lista
        Integer left = 0;
        Integer right = sortedList.size();

        while (left < right) {
            Integer mid = left + ((right - left) / 2);

            if (sortedList[mid] < target) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        return left;
    }

    public static String toMaxAllowedEndTermPicklistValue(Date startDate, Date endDate) {
        // Se devuelve el plazo mínimo superior de End Term
        // Se calculan los días entre la fecha inicial y fecha de vencimiento
        // y se selecciona el valor de picklist que sea >= a esa diferencia.
        if (startDate == null || endDate == null) return null;
    
        Integer dayDifference = startDate.daysBetween(endDate);
        List<Integer> endTermDayOptions = END_TERM_DAY_OPTIONS;
    
        if (endTermDayOptions == null || endTermDayOptions.isEmpty()) {
            return null;
        }
    
        Integer insertionIndex = lowerBound(endTermDayOptions, dayDifference);
    
        if (insertionIndex == 0) {
            return String.valueOf(endTermDayOptions[0]);
        }
    
        if (insertionIndex >= endTermDayOptions.size()) {
            return String.valueOf(endTermDayOptions[endTermDayOptions.size() - 1]);
        }
    
        return String.valueOf(endTermDayOptions[insertionIndex]);
    }
    
    @AuraEnabled(cacheable=false)
    public static void updateRiskLinesAndWarranties(String oppId, List<String> approversId, String typeFeature) {
        //Obtener featureType
        //List<Map<String,String>> featureTypes = DMT_Passport_Handler.getFeatureTypeByApproverType(approversId);
        //System.debug('Feature type obtained: ' + featureTypes);
        //String typeFeature = (featureTypes != null && !featureTypes.isEmpty()) ? featureTypes[0].get('featureType') : null;
        // Listas para insertar
        List<DMT_Risk_Line_Term__c> riskLinesToUpdate = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Warranty__c> warrantiesToUpdate = new List<DMT_Warranty__c>();
        List<DMT_Currency_Provision__c> currencyToUpdate = new List<DMT_Currency_Provision__c>();
        Map<Id,DMT_Risk_Line_Term__c> mapIdOppToRisk = new Map<Id,DMT_Risk_Line_Term__c>();
        List<String> listIdOppLineItems = new List<String>();
        List<String> listIdProducts = new List<String>();
        Map<Id,OpportunityLineItem> mapIdOPLToOppLinItem = new Map<Id,OpportunityLineItem>();

        
        List<Id> existingRiskLineIds = new List<Id>();
        List<Id> listIdOppLineItemsForUnderlyings = new List<Id>();
        Map<Id,DMT_Risk_Line_Term__c> mapIdOppLineItemToRiskLineTerm = new Map<Id,DMT_Risk_Line_Term__c>();
        for (OpportunityLineItem oli : DMT_Opportunity_Selector.getOpportunityLineItems(oppId)) {
            listIdProducts.add(oli.Product2Id);
            if (oli.DMT_Associated_Line_Product__c != null) {
                mapIdOppLineItemToRiskLineTerm.put(oli.Id, new DMT_Risk_Line_Term__c(Id = oli.DMT_Associated_Line_Product__c));
                existingRiskLineIds.add(oli.DMT_Associated_Line_Product__c);
                mapIdOPLToOppLinItem.put(oli.Id, oli);
            }
            listIdOppLineItemsForUnderlyings.add(oli.Id);
        }
        Map<Id, List<DMT_Underlying__c>> mapOliToUnderlyings = DMT_Opportunity_Selector.getUnderlyingsByOliIds(listIdOppLineItemsForUnderlyings);
        Map<Id, List<DMT_Opportunity_Mitigant__c>> mapOliToMitigants = DMT_Opportunity_Selector.getMitigantsByOliIds(listIdOppLineItemsForUnderlyings);
        List<DMT_PassportProfitabilityProcessor.ProductProfitability> productProf = DMT_PassportProfitabilityProcessor.getProductLevelProfitability(oppId);
        // Update Line
        DMT_Line__c line = new DMT_Line__c();
        line.Id = DMT_Opportunity_Selector.getLineByOpportunityId(oppId)?.Id;
        if (line != null) {
            Opportunity opp = DMT_Opportunity_Selector.getOpportunity(oppId);
            if(typeFeature == 'risk'){            
                line.Booking_Geography__c       = opp.Entific__c;
                line.CurrencyIsoCode            = opp.DMT_CurrencyText__c;
                line.DMT_ApproverGlobalBanker__c = opp.DMT_ApproverGlobalBanker__c;
                line.DMT_Approver__c            = opp.DMT_Approver__c;
                line.DMT_Booking_Unit_Risk_Analyst__c = opp.DMT_Booking_Unit_Risk_Analyst__c;
                line.DMT_Client_Entific__c      = opp.Entific__c;
                line.DMT_Entity__c              = opp.DMT_Entity__c;
                line.DMT_Opportunity__c         = opp.Id;
            }else{
                for (DMT_PassportProfitabilityProcessor.ProductProfitability prof : productProf) {
                    line.gf_min_raroec_wo_fcg_per__c = prof.raroec;
                    line.gf_min_rorc_wo_fcg_per__c   = prof.rorc;
                    break; // nivel de oportunidad: se usa el primer valor
                }
            }
            DMT_WithoutSharingDAO.updateRecord(line);
            
        }
        // Fin update line
        Map<Id,Product2> mapIdToProduct = DMT_Opportunity_Selector.getProduct2(listIdProducts);
        for(OpportunityLineItem oli: mapIdOPLToOppLinItem.values()){
            DMT_Risk_Line_Term__c riskLine = new DMT_Risk_Line_Term__c();
            if(typeFeature == 'risk'){            
                // Update un DMT_Risk_Line_Term__c por cada OpportunityLineItem
                riskLine.Id = mapIdOppLineItemToRiskLineTerm.get(oli.Id)?.Id;
                riskLine.DMT_Product__c =  oli.Product2Id;
                riskLine.DMT_LastLevelId__c =  oli.DMT_Risk_Type__c;
                riskLine.DMT_Risk_Type__c =  oli.opportunity_risk_name__c;
                riskLine.DMT_Max_Date__c =  oli.gf_maturity_date__c;
                riskLine.g_global_product_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Global_Product_Id__c;
                riskLine.g_global_product_category_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_category__c;
                riskLine.g_global_product_family_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_family__c;
                riskLine.g_gbl_product_subcategory_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_Subcategory__c;
                riskLine.g_global_product_subfamily_id__c =  mapIdToProduct.get(oli.Product2Id).DMT_Product_Subfamily__c;
                riskLine.Name =  mapIdToProduct.get(oli.Product2Id).Name;
                riskLine.DMT_Comments__c = buildCommentsText(mapOliToUnderlyings.get(oli.Id), oli.g_currency_id__c, oli.gf_country_risk__c, mapOliToMitigants.get(oli.Id));
                riskLine.DMT_Amount__c =  oli.bbva_prtcp_tranche_amount__c;
                riskLine.CurrencyIsoCode =  oli.g_currency_Id__c;
                riskLine.DMT_Init_Term__c =  '0';
                riskLine.DMT_End_Term__c = toMaxAllowedEndTermPicklistValue(oli.gf_initial_date__c, oli.gf_maturity_date__c);
                riskLine.g_branch_id__c =  oli.g_branch_id__c;
                riskLine.gf_group_priority_line_id__c =  oli.gf_group_priority_opportunity_id__c;
                riskLine.g_line_commitment_level_type__c =  oli.g_line_commitment_level_type__c;
                riskLine.g_multioperation_ind_type__c =  oli.g_multioperation_ind_type__c;
                riskLine.gf_payment_frequency__c = oli.gf_payment_frequency__c;
                riskLine.DMT_Line_Tenor__c = oli.DMT_Line_Tenor__c != null ? oli.DMT_Line_Tenor__c.toPlainString() : null;
                riskLine.DMT_Operation_Type__c = oli.DMT_Line_Oneoffdeal__c == 'One-off deal' ? 'OPP' : 'LIN';
                
            }else{
                continue;
            }
            
            // Se añade traduccion para el campo de amortization Type
            if(typeFeature == 'risk'){            
                if(oli.gf_amortization_type__c == 'Linear'){
                    riskLine.g_amortization_type__c = '03';
                }else if(oli.gf_amortization_type__c == 'Bullet'){
                    riskLine.g_amortization_type__c = '04';
                }else if(oli.gf_amortization_type__c == 'User-Defined'){
                    if(oli.DMT_balloon_amortization_indicator__c == true){
                        riskLine.g_amortization_type__c = '05';
                    }else if(oli.DMT_bullet_amortization_indicator__c == true){
                        riskLine.g_amortization_type__c = '04';
                    }else{
                        riskLine.g_amortization_type__c = '09';
                    }
                }
            }
            // Agrega aquí los demás campos que necesites copiar o inicializar
            listIdOppLineItems.add(oli.Id);
            mapIdOppToRisk.put(oli.Id,riskLine);
            riskLinesToUpdate.add(riskLine);
           
        }
        
        if (!riskLinesToUpdate.isEmpty()) {
            DMT_WithoutSharingDAO.updateRecords(riskLinesToUpdate);
            if(typeFeature == 'risk'){
   
                List<DMT_Opportunity_Mitigant__c> listMitigants = [SELECT Id,DMT_Opportunity_Product__c,Mitigant_Type__c, DMT_Opportunity_Product__r.ProductCode, DMT_Opportunity_Product__r.gf_group_priority_opportunity_id__c FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c IN :listIdOppLineItems];
                // Update DMT_Warranty__c por cada Risk Line creado
                //Traer query con los warranty creados ya TODO
                Map<String,DMT_Warranty__c> mapGroupPriorityToWarranty = new Map<String,DMT_Warranty__c>();
                for (DMT_Warranty__c w : DMT_Opportunity_Selector.getWarrantiesByRiskLineIds(existingRiskLineIds)) {
                    mapGroupPriorityToWarranty.put(w.gf_group_priority_line_id__c, w);
                }
                Map<String, String> guaranteeTypeMapUpdate = buildGuaranteeTypeMap(listMitigants);
                for (DMT_Opportunity_Mitigant__c mitigant : listMitigants) {
                    DMT_Warranty__c warranty = new DMT_Warranty__c();
                    warranty.Id = mapGroupPriorityToWarranty.get(mitigant.DMT_Opportunity_Product__r.gf_group_priority_opportunity_id__c)?.Id;
                    warranty.Name = mitigant.Mitigant_Type__c;
                    warranty.gf_group_priority_line_id__c = mitigant.DMT_Opportunity_Product__r.gf_group_priority_opportunity_id__c ;
                    warranty.g_limits_grid_guarantee_type__c = guaranteeTypeMapUpdate.get(mitigant.Mitigant_Type__c);
                    warranty.gf_origin_application_type__c = '04' ;
                    warranty.g_entific_id__c = 'HO';
                    // Agrega aquí los demás campos que necesites
                    warrantiesToUpdate.add(warranty);
                }
                
                if (!warrantiesToUpdate.isEmpty()) {
                    DMT_WithoutSharingDAO.updateRecords(warrantiesToUpdate);
                }
                Map<Id,DMT_Currency_Provision__c> mapIdRiskLineTermToCurrency = new Map<Id,DMT_Currency_Provision__c>();
                for (DMT_Currency_Provision__c cp : DMT_Opportunity_Selector.getCurrencyProvisionsByRiskLineIds(existingRiskLineIds)) {
                    mapIdRiskLineTermToCurrency.put(cp.DMT_Risk_Line_Term__c, cp);
                }
                for(DMT_Risk_Line_Term__c rkl : riskLinesToUpdate){
                    DMT_Currency_Provision__c currencyprovision = new DMT_Currency_Provision__c();
                    currencyprovision.Id = mapIdRiskLineTermToCurrency.get(rkl.Id)?.Id;
                    currencyprovision.Name = rkl.CurrencyIsoCode;
                    currencyprovision.g_currency_id__c = rkl.CurrencyIsoCode;
                    currencyprovision.gf_group_priority_line_id__c = rkl.gf_group_priority_line_id__c;
                    currencyprovision.gf_origin_application_type__c = '04' ;
                    currencyprovision.g_entific_id__c = 'HO';
                    currencyToUpdate.add(currencyprovision);
                }
                if(!currencyToUpdate.isEmpty()){
                    DMT_WithoutSharingDAO.updateRecords(currencyToUpdate);
                }
            }
        }
    }

    private static final String TRUNCATION_MARKER = ' (...)';
    private static final Integer MAX_LENGTH = 500;

    private static String buildCommentsText(List<DMT_Underlying__c> underlyings, String lineCurrency, String countryRisk, List<DMT_Opportunity_Mitigant__c> mitigants) {
        String text = '';
        Boolean truncated = false;

        // Sección Underlyings
        if (!truncated && underlyings != null && !underlyings.isEmpty()) {
            List<DMT_Underlying__c> restrictions  = new List<DMT_Underlying__c>();
            List<DMT_Underlying__c> profitability = new List<DMT_Underlying__c>();

            for (DMT_Underlying__c u : underlyings) {
                if (u.DMT_Underlying_Type__c == 'Profitability') {
                    profitability.add(u);
                } else {
                    restrictions.add(u);
                }
            }

            Boolean hasRestrictions  = !restrictions.isEmpty();
            Boolean hasProfitability = !profitability.isEmpty();

            // Underlying Restriction
            if (!truncated && hasRestrictions) {
                String block = 'Underlying Restriction:\n';
                Boolean anyLineAdded = false;

                Map<String, String> maxTermLabels = getCachedMaxTermLabels();
                for (DMT_Underlying__c u : restrictions) {
                    String termLabel = String.isNotBlank(u.DMT_Max_Term__c) ? (maxTermLabels.containsKey(u.DMT_Max_Term__c) ? maxTermLabels.get(u.DMT_Max_Term__c) : u.DMT_Max_Term__c) : '';
                    String line = '-' + (u.Name != null ? u.Name : '') + ': max amount ' +
                        (u.DMT_Max_Amount__c != null ? formatDecimal(u.DMT_Max_Amount__c) : '') +
                        (String.isNotBlank(lineCurrency) ? ' ' + lineCurrency : '') +
                        ' and max term ' + termLabel + '\n';

                    if ((text + block + line).length() <= MAX_LENGTH) {
                        block += line;
                        anyLineAdded = true;
                    } else {
                        truncated = true;
                        break;
                    }
                }

                if (anyLineAdded) text += block;
            }


            if (!truncated && (hasRestrictions || hasProfitability) && (text + '\n').length() <= MAX_LENGTH) {
                text += '\n';
            }
        }

        // Sección Guarantor / Collateral
        if (!truncated && mitigants != null && !mitigants.isEmpty()) {
            List<DMT_Opportunity_Mitigant__c> collaterals = new List<DMT_Opportunity_Mitigant__c>();
            List<DMT_Opportunity_Mitigant__c> guarantors   = new List<DMT_Opportunity_Mitigant__c>();

            for (DMT_Opportunity_Mitigant__c m : mitigants) {
                if (String.isBlank(m.DMT_Guarantor_Display__c)) {
                    collaterals.add(m);
                } else {
                    guarantors.add(m);
                }
            }

            Boolean hasGuarantors  = !guarantors.isEmpty();
            Boolean hasCollaterals = !collaterals.isEmpty();

            // Guarantor
            if (!truncated && hasGuarantors) {
                String block = 'Guarantor:\n';
                Boolean anyLineAdded = false;

                for (DMT_Opportunity_Mitigant__c m : guarantors) {
                    String line = '-';
                    if (m.Garantor_European_ECA__c == true) {
                        line += 'ECA ';
                    }

                    line += (String.isNotBlank(m.DMT_Guarantor_Display__c) ? m.DMT_Guarantor_Display__c : '');

                    if (m.Commercial_Percentage__c != null || m.Political_Percentage__c != null) {
                        line += ' Credit / CountryRisk Coverage:' +
                            (m.Commercial_Percentage__c != null ? formatDecimal(m.Commercial_Percentage__c) + '%' : '') +
                            ' / ' +
                            (m.Political_Percentage__c != null ? formatDecimal(m.Political_Percentage__c) + '%' : '');
                    }
                    if (m.End_Date__c != null) {
                        line += ' EndDate:' + formatDateShort(m.End_Date__c);
                    }
                    if (m.Internal_Rating__c != null || m.External_Rating__c != null) {
                        line += ' Internal / External Rating: ' +
                            (m.Internal_Rating__c != null ? m.Internal_Rating__c + (m.DMT_Scoring__c != null ? '(' + formatDecimal(m.DMT_Scoring__c) + ')' : '') : '') +
                            ' / ' +
                            (m.External_Rating__c != null ? m.External_Rating__c : '');
                    }
                    if (String.isNotBlank(m.SCRA__c)) {
                        line += ' SCRA:' + m.SCRA__c;
                    }
                    if (m.AVC_Check__c == true) {
                        line += ' AVC: Yes';
                    }
                    line += '\n';

                    if ((text + block + line).length() <= MAX_LENGTH) {
                        block += line;
                        anyLineAdded = true;
                    } else {
                        truncated = true;
                        break;
                    }
                }

                if (anyLineAdded) text += block;
            }

            // Collateral
            if (!truncated && hasCollaterals) {
                String block = 'Collateral :\n';
                Boolean anyLineAdded = false;

                for (DMT_Opportunity_Mitigant__c m : collaterals) {
                    String line = '-' + (m.Mitigant_Type__c != null ? m.Mitigant_Type__c : '');

                    if (m.Commercial_Percentage__c != null || m.Political_Percentage__c != null) {
                        line += ' Credit / CountryRisk Coverage:' +
                            (m.Commercial_Percentage__c != null ? formatDecimal(m.Commercial_Percentage__c) + '%' : '') +
                            ' / ' +
                            (m.Political_Percentage__c != null ? formatDecimal(m.Political_Percentage__c) + '%' : '');
                    }
                    if (m.End_Date__c != null) {
                        line += ' EndDate:' + formatDateShort(m.End_Date__c);
                    }
                    if (m.Internal_Rating__c != null || m.External_Rating__c != null) {
                        line += ' Internal / External Rating: ' +
                            (m.Internal_Rating__c != null ? m.Internal_Rating__c : '') +
                            ' / ' +
                            (m.External_Rating__c != null ? m.External_Rating__c : '');
                    }
                    line += '\n';

                    if ((text + block + line).length() <= MAX_LENGTH) {
                        block += line;
                        anyLineAdded = true;
                    } else {
                        truncated = true;
                        break;
                    }
                }

                if (anyLineAdded) text += block;
            }

            if (!truncated && (hasGuarantors || hasCollaterals) && (text + '\n').length() <= MAX_LENGTH) {
                text += '\n';
            }
        }

        // Sección Country Risk
        if (!truncated && String.isNotBlank(countryRisk)) {
            String block = 'Country risk: ' + countryRisk + '\n';
            if ((text + block).length() <= MAX_LENGTH) {
                text += block;
            } else {
                truncated = true;
            }
        }

        // Marcador de truncado
        if (truncated) {
            Integer maxBase = MAX_LENGTH - TRUNCATION_MARKER.length();
            if (text.length() > maxBase) {
                text = text.substring(0, maxBase);
            }
            text += TRUNCATION_MARKER;
        }

        return text;
    }

    private static Map<String, String> buildGuaranteeTypeMap(List<DMT_Opportunity_Mitigant__c> mitigants) {
        Set<String> mitigantNames = new Set<String>();
        for (DMT_Opportunity_Mitigant__c m : mitigants) {
            if (String.isNotBlank(m.Mitigant_Type__c)) {
                mitigantNames.add(m.Mitigant_Type__c);
            }
        }
        Map<String, String> nameToValue = new Map<String, String>();
        if (mitigantNames.isEmpty()) return nameToValue;
        for (DMT_Taxonomy_Values__c tax : [
            SELECT DMT_Name_EN__c, DMT_Value__c
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c = 'E895'
              AND DMT_Name_EN__c IN :mitigantNames
              AND DMT_Active__c = true
            WITH SYSTEM_MODE
            ORDER BY DMT_Value__c
        ]) {
            if (!nameToValue.containsKey(tax.DMT_Name_EN__c)) {
                nameToValue.put(tax.DMT_Name_EN__c, tax.DMT_Value__c);
            }
        }
        return nameToValue;
    }

    private static String formatDecimal(Decimal d) {
        if (d == null) return '';
        return String.valueOf(d.setScale(2));
    }

    private static String formatDateShort(Date d) {
        if (d == null) return '';
        List<String> months = new List<String>{
            'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
        };
        return String.valueOf(d.day()) + months[d.month() - 1] + String.valueOf(d.year());
    }

    // Wrapper para recibir OpportunityLineItem desde Flow
    public class OpportunityLineItemWrapper {
        @InvocableVariable(required=true)
        public List<OpportunityLineItem> listOli;
        @InvocableVariable(required=true)
        public String idLine;
    }
    
    public static final List<Integer> END_TERM_DAY_OPTIONS = new List<Integer>{
        0, 7, 15, 21, 31, 62, 92, 122, 153, 183, 214, 244, 275, 305, 336, 366,
        397, 424, 454, 484, 514, 545, 575, 605, 635, 666, 696, 726, 756, 787,
        817, 847, 877, 908, 938, 968, 998, 1029, 1059, 1089, 1119, 1150, 1180,
        1210, 1240, 1271, 1301, 1331, 1361, 1392, 1422, 1452, 1482, 1513, 1543,
        1573, 1603, 1634, 1664, 1694, 1724, 1755, 1785, 1815, 1918, 2009, 2100,
        2192, 2283, 2374, 2465, 2557, 2648, 2739, 2831, 2922, 3013, 3105, 3196,
        3287, 3379, 3470, 3561, 3653, 3835, 4018, 4200, 4383, 4566, 4748, 4931,
        5114, 5296, 5479, 5844, 6209, 6575, 6940, 7305, 7670, 8036, 8401, 8766,
        9131, 9497, 9862, 10227, 10592, 10958, 11323, 11688, 12053, 12419, 12784
    };

}