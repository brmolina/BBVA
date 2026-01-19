public with sharing class DMT_Passport_Helper {

    private static Map<String, Object> mapGroupsCache = new Map<String, Object>();
    private static String accountRecordCode = '';
    private static String mitigantClientCode = null;
    FINAL PRIVATE STATIC STRING APPROVERTYPE = 'Risk';

    // Método principal para establecer el payload
    public static String setPayloadPassport(String recordId, String clientsGroup) {
        if (recordId == null) {
            return '';
        }

        String objectName = objectNameById(recordId);

        if (objectName == DMT_Line__c.getSObjectType().getDescribe().getName()) {
            return handleLinePayload(recordId, clientsGroup);
        } else if (objectName == Opportunity.getSObjectType().getDescribe().getName()) {
            return handleOpportunityPayload(recordId,clientsGroup);
        }

        return '';
    }

    // Manejo del payload para líneas
    private static String handleLinePayload(String recordId, String clientsGroup) {
        DMT_Line__c dmtLine = DMT_Passport_Selector.getLine(recordId);

        if (dmtLine.RecordType.DeveloperName == 'OtherProducts') {
            return buildOtherProductsPayload(dmtLine, clientsGroup, recordId);
        } else {
            return buildStandardLinePayload(dmtLine, clientsGroup, recordId);
        }
    }

    // Construcción del payload para líneas de tipo "OtherProducts"
    private static String buildOtherProductsPayload(DMT_Line__c dmtLine, String clientsGroup, String recordId) {
        DMT_Wrapper_Passport_Abs.Request payloadMap = initializePayload(dmtLine);
        DMT_PassportOtherProducts_Wrapper.RequestBody body = (DMT_PassportOtherProducts_Wrapper.RequestBody) JSON.deserialize(initializeRequestBody(dmtLine), DMT_PassportOtherProducts_Wrapper.RequestBody.class);

        body.line = buildLineForOtherProducts(dmtLine);
        body.products = buildProductsForOtherProducts(dmtLine);
        body.features = new List<DMT_Wrapper_Passport_Abs.Feature> { calculateFeatureGenCons(recordId, clientsGroup) };
        body.optionalFeatures = calculateOptionalFeatures(dmtLine);

        payloadMap.body = JSON.serialize(body);
        return JSON.serialize(payloadMap);
    }

    // Construcción del payload estándar para líneas
    private static String buildStandardLinePayload(DMT_Line__c dmtLine, String clientsGroup, String recordId) {
        DMT_Wrapper_Passport_Abs.Request payloadMap = initializePayload(dmtLine);
        DMT_Passport_Wrapper.RequestBody body = (DMT_Passport_Wrapper.RequestBody) JSON.deserialize(initializeRequestBody(dmtLine), DMT_Passport_Wrapper.RequestBody.class);

        body.client.products = new List<DMT_Passport_Wrapper.Product> { buildStandardProducts(dmtLine) };
        body.client.indRenovada = dmtLine.DMT_Parent_Line__r.Line_Id__c != null;
        body.client.parentConsums = parentConsumsStandard(dmtLine);
        if(clientsGroup != ''){
            body.features = new List<DMT_Wrapper_Passport_Abs.Feature> { calculateFeatureGenCons(recordId, clientsGroup) };
            body.optionalFeatures = calculateOptionalFeatures(dmtLine);
        }

        payloadMap.body = JSON.serialize(body);
        return JSON.serialize(payloadMap);
    }

    // Inicialización del payload base
    private static DMT_Wrapper_Passport_Abs.Request initializePayload(DMT_Line__c dmtLine) {
        DMT_Wrapper_Passport_Abs.Request payloadMap = new DMT_Wrapper_Passport_Abs.Request();
        payloadMap.opportunityId = dmtLine.Line_Id__c;
        payloadMap.version = '001';
        payloadMap.auditDate = Datetime.now();
        payloadMap.entific = dmtLine.DMT_Client_Entific__c;
        payloadMap.booking = dmtLine.Booking_Geography__c;
        payloadMap.lineDesc = dmtLine.Line_Details__c;
        payloadMap.user = userId(dmtLine.OwnerId);
        payloadMap.status = dmtLine.DMT_Status_Completed__c.toUpperCase();
        payloadMap.initDate = dmtLine.Start_Date__c;
        payloadMap.endDate = dmtLine.End_Date__c;
        payloadMap.currencyId = dmtLine.CurrencyIsoCode;
        return payloadMap;
    }

    // Inicialización del cuerpo del payload
    private static String initializeRequestBody(DMT_Line__c dmtLine) {
        DMT_Wrapper_Passport_Abs.RequestBody body = new DMT_Wrapper_Passport_Abs.RequestBody();
        body.client = buildClientDetails(dmtLine);
        body.analysts = buildAnalystDetails(dmtLine);
        return JSON.serialize(body);
    }

    // Construcción de los detalles del cliente
    private static DMT_Wrapper_Passport_Abs.Client buildClientDetails(DMT_Line__c dmtLine) {
        DMT_Wrapper_Passport_Abs.Client client = new DMT_Wrapper_Passport_Abs.Client();
        client.customerId = dmtLine.Client_Type__c == 'Customer' ? dmtLine.Client_Code__c : null;
        client.customerName = dmtLine.Client__r.Name;
        client.clientType = 'CORP';
        client.taxpayer = dmtLine.Client__r.DES_Tax_Identification_Number__c;

        if (dmtLine.RecordType.DeveloperName == 'TreasurySettlement') {
            client.extension = DMT_LineFeatureGenCons_Calc.validationRenovation(dmtLine.Id, dmtLine.DMT_Parent_Line__c);
        } else if (dmtLine.RecordType.DeveloperName == 'OtherProducts') {
            client.extension = DMT_LineFeatureGenCons_Calc.validationRenovationOtherLines(dmtLine.Id, dmtLine.DMT_Parent_Line__c);
        }

        if (dmtLine.Custom_Association__c != null) {
            client.customAssociationId = dmtLine.Line_Id__c;
            client.customAssociationName = dmtLine.Custom_Association__r.Name;
        }

        if(mapGroupsCache.isEmpty()){
            mapGroupsCache = DMT_HPG_Utils.getGroupFromClient(dmtLine.Client__c);
        }
        if (mapGroupsCache.containsKey('groupCode')) {
            client.groupId = (String) mapGroupsCache.get('groupCode');
        }
        if (mapGroupsCache.containsKey('groupName')) {
            client.groupName = (String) mapGroupsCache.get('groupName');
        }
        if (mapGroupsCache.containsKey('subgroupId')) {
            client.subgroupId = (String) mapGroupsCache.get('subgroupId');
        }
        if (mapGroupsCache.containsKey('supragroupId')) {
            client.supragroupId = (String) mapGroupsCache.get('supragroupId');
        }

        return client;
    }

    // Construcción de los detalles del analista
    private static DMT_PassportOpportunity_Wrapper.Analyst buildOppAnalystDetails(Opportunity opp) {
        DMT_PassportOpportunity_Wrapper.Analyst analyst = new DMT_PassportOpportunity_Wrapper.Analyst();
        analyst.approverBankerId = opp.DMT_ApproverGlobalBanker__r.DMT_External_Id__c;
        analyst.businessUnitRiskAnalyst = opp.DMT_Booking_Unit_Risk_Analyst__r.DMT_External_Id__c;
        analyst.fpRiskAnalyst = opp.DMT_Approver__r.DMT_External_Id__c;
        return analyst;
    }

    // Construcción de los detalles del analista
    private static DMT_Wrapper_Passport_Abs.Analyst buildAnalystDetails(DMT_Line__c dmtLine) {
        DMT_Wrapper_Passport_Abs.Analyst analyst = new DMT_Wrapper_Passport_Abs.Analyst();
        analyst.approverBankerId = dmtLine.DMT_ApproverGlobalBanker__r.DMT_External_Id__c;
        analyst.businessUnitRiskAnalyst = dmtLine.DMT_Booking_Unit_Risk_Analyst__r.DMT_External_Id__c;
        analyst.fpRiskAnalyst = dmtLine.DMT_Approver__r.DMT_External_Id__c;
        return analyst;
    }

    // Construcción de productos para líneas de tipo "OtherProducts"
    private static List<DMT_PassportOtherProducts_Wrapper.Product> buildProductsForOtherProducts(DMT_Line__c dmtLine) {
        List<DMT_PassportOtherProducts_Wrapper.Product> products = new List<DMT_PassportOtherProducts_Wrapper.Product>();
        List<DMT_Risk_Line_Term__c> riskTerms = DMT_Passport_Selector.getRiskLineTermWhithoutRiskType(dmtLine.Id);

        for (DMT_Risk_Line_Term__c rlt : riskTerms) {
            DMT_PassportOtherProducts_Wrapper.Product product = new DMT_PassportOtherProducts_Wrapper.Product();
            product.productName = rlt.DMT_Product__r.Name;
            product.amount = rlt.DMT_Amount__c;
            product.initTerm = rlt.DMT_Init_Term__c;
            product.endTerm = rlt.DMT_End_Term__c;
            product.currencyId = rlt.CurrencyIsoCode;
            product.family = rlt.DMT_Product__r.DMT_Product_family__c;
            product.subfamily = rlt.DMT_Product__r.DMT_Product_Subfamily__c;
            product.category = rlt.DMT_Product__r.DMT_Product_category__c;
            product.subcategory = rlt.DMT_Product__r.DMT_Product_Subcategory__c;
            product.productCode = rlt.DMT_Product__r.ProductCode;
            product.endDate = rlt.DMT_End_Term__c != null ? dmtLine.Start_Date__c.addDays(Integer.valueOf(rlt.DMT_End_Term__c)) : dmtLine.Start_Date__c;
            product.initDate = rlt.DMT_Init_Term__c != null ? dmtLine.Start_Date__c.addDays(Integer.valueOf(rlt.DMT_Init_Term__c)) : dmtLine.Start_Date__c;
            product.lastLevelId = rlt.DMT_LastLevelId__c;
            product.globalProductId = rlt.g_global_product_id__c;
            product.productId = rlt.gf_group_priority_line_id__c;
            product.globalProductSubcategoryId = rlt.g_gbl_product_subcategory_id__c;
            product.globalProductCategoryId = rlt.g_global_product_category_id__c;
            product.globalProductSubfamilyId = rlt.g_global_product_subfamily_id__c;
            product.globalProductFamilyId = rlt.g_global_product_family_id__c;
            product.bulletIndicatorType = rlt.g_bullet_ind_type__c;
            product.assetAllocationSectLimit = rlt.g_limit_sinds_ast_sctr_id__c;
            product.assetAllocationSubSectLimit = rlt.g_limit_sinds_ast_subsec_id__c;
            product.branchLimitation = rlt.g_branch_id__c;
            product.monthsGracePeriod = rlt.gf_inscol_months_grace_number__c;
            product.loanValuePerct = rlt.gf_loan_value_per__c;
            product.notaryFormIndType = rlt.g_notary_crtfn_ind_type__c;
            product.publicAdmIndType = rlt.g_gtee_public_adm_ind_type__c;
            product.loanEcaContribPerct = rlt.gf_loan_eca_cntrb_per__c;
            product.minRaroEcFgPerct = rlt.gf_min_raroec_fcg_per__c;
            product.minRaroEcWoFgPerct = rlt.gf_min_raroec_wo_fcg_per__c;
            product.minRorcFcgPerct = rlt.gf_min_rorc_fcg_per__c;
            product.minRorWocFcgPerc = rlt.gf_min_rorc_wo_fcg_per__c;
            product.revolvencePdDaysNumber = rlt.gf_revolvence_pd_days_number__c;
            product.multiOperationIndType = rlt.g_multioperation_ind_type__c;
            product.comments = rlt.DMT_Comments__c;
            product.indRenovada = rlt.DMT_Parent_Product__c != null;
            product.parentConsums = product.indRenovada ? new List<DMT_Wrapper_Passport_Abs.ParentConsum>() : null;

            if(product.indRenovada){
                List<DMT_Wrapper_Passport_Abs.ParentConsum> parentList = new List<DMT_Wrapper_Passport_Abs.ParentConsum> ();
                DMT_Wrapper_Passport_Abs.ParentConsum parentProd = new DMT_Wrapper_Passport_Abs.ParentConsum();
                parentProd.productParent = rlt.DMT_Parent_Product__r.gf_group_priority_line_id__c;
                parentProd.parentId = dmtLine.DMT_Parent_Line__r.Line_Id__c;
                parentProd.amountParent = rlt.DMT_Parent_Product__r.DMT_Amount__c;
                parentProd.currencyParentId = rlt.DMT_Parent_Product__r.CurrencyIsoCode;
                parentProd.endDateParent = dmtLine.DMT_Parent_Line__r.Start_Date__c.addDays(rlt.DMT_Parent_Product__r.DMT_End_Term__c != null ? Integer.valueOf(rlt.DMT_Parent_Product__r.DMT_End_Term__c) : 0);
                parentList.add(parentProd);
                product.parentConsums = parentList;
            }

            product.currencyProvision = new List<DMT_PassportOtherProducts_Wrapper.Provisions>();

            for(DMT_Currency_Provision__c cp : rlt.DMT_Currency_Provisions__r){
                DMT_PassportOtherProducts_Wrapper.Provisions currencyProvision = new DMT_PassportOtherProducts_Wrapper.Provisions();
                currencyProvision.currencyId = cp.g_currency_id__c;
                product.currencyProvision.add(currencyProvision);
            }

            product.warranty = new List<DMT_PassportOtherProducts_Wrapper.Warranty>();

            for(DMT_Warranty__c wr : rlt.DMT_Warranties__r){
                DMT_PassportOtherProducts_Wrapper.Warranty warranty = new DMT_PassportOtherProducts_Wrapper.Warranty();
                warranty.warrantyId = wr.g_limits_grid_guarantee_type__c;
                product.warranty.add(warranty);
            }

            products.add(product);
        }

        return products;
    }

    private static DMT_PassportOtherProducts_Wrapper.Line buildLineForOtherProducts(DMT_Line__c dmtLine){
        DMT_PassportOtherProducts_Wrapper.Line line = new DMT_PassportOtherProducts_Wrapper.Line();

        line.amount = dmtLine.Amount__c;
        line.lastLevelId = dmtLine.DMT_LastLevelId__c;

        return line;
    }

    // Construcción de productos estándar
    private static DMT_Passport_Wrapper.Product buildStandardProducts(DMT_Line__c dmtLine) {
        DMT_Passport_Wrapper.Product product = new DMT_Passport_Wrapper.Product();
        product.amount = dmtLine.DMT_Total_Amount__c;
        product.initDate = dmtLine.Start_Date__c;
        product.endDate = dmtLine.End_Date__c;
        product.currencyId = dmtLine.CurrencyIsoCode;

        product.settlement = new DMT_Passport_Wrapper.Settlement();
        product.settlement.dvpAmount = dmtLine.DvP_Amount__c;
        product.settlement.fdAmount = dmtLine.FD_Amount__c;

        product.treasury = new DMT_Passport_Wrapper.Treasury();
        product.treasury.derivativesAmount = dmtLine.DMT_DerivativesAmount__c;

        return product;
    }

    private static List<DMT_Wrapper_Passport_Abs.ParentConsum> parentConsumsStandard(DMT_Line__c dmtLine){
        List<DMT_Wrapper_Passport_Abs.ParentConsum> parentConsums;
        Integer endTerm = 0;

        if(dmtLine.DMT_Parent_Line__r.Line_Id__c != null){
            parentConsums = new List<DMT_Wrapper_Passport_Abs.ParentConsum>();

            DMT_Wrapper_Passport_Abs.ParentConsum dvp = new DMT_Wrapper_Passport_Abs.ParentConsum();
            dvp.productParent = 'DVP';
            dvp.parentId = dmtLine.DMT_Parent_Line__r.Line_Id__c;
            dvp.amountParent = dmtLine.DMT_Parent_Line__r.DvP_Amount__c;
            dvp.currencyParentId = dmtLine.DMT_Parent_Line__r.CurrencyIsoCode;
            dvp.endDateParent = dmtLine.DMT_Parent_Line__r.End_Date__c;
            parentConsums.add(dvp);

            DMT_Wrapper_Passport_Abs.ParentConsum fd = new DMT_Wrapper_Passport_Abs.ParentConsum();
            fd.productParent = 'FD';
            fd.parentId = dmtLine.DMT_Parent_Line__r.Line_Id__c;
            fd.amountParent = dmtLine.DMT_Parent_Line__r.FD_Amount__c;
            fd.currencyParentId = dmtLine.DMT_Parent_Line__r.CurrencyIsoCode;
            fd.endDateParent = dmtLine.DMT_Parent_Line__r.End_Date__c;
            parentConsums.add(fd);

            for(DMT_Risk_Line_Term__c r : DMT_Passport_Selector.getRiskLineTerm(dmtLine.DMT_Parent_Line__r.Line_Id__c)){
                endTerm = !String.isEmpty(r.DMT_End_Term__c) && endTerm < Integer.valueOf(r.DMT_End_Term__c) ? Integer.valueOf(r.DMT_End_Term__c) : endTerm;
            }

            DMT_Wrapper_Passport_Abs.ParentConsum der = new DMT_Wrapper_Passport_Abs.ParentConsum();
            der.productParent = 'Derivatives';
            der.parentId = dmtLine.DMT_Parent_Line__r.Line_Id__c;
            der.amountParent = dmtLine.DMT_Parent_Line__r.DMT_DerivativesAmount__c;
            der.currencyParentId = dmtLine.DMT_Parent_Line__r.CurrencyIsoCode;
            der.endDateParent = dmtLine.DMT_Parent_Line__r.Start_Date__c?.addDays(endTerm);
            parentConsums.add(der);
        }

        return parentConsums;
    }

    // Building payload for Opportunity
    private static String handleOpportunityPayload(String recordId, String clientsGroup) {
        Account acc = DMT_Passport_Selector.getAccountWithRelatedListsFromOppId(recordId);
        String recordCode = '';
        if(String.isNotBlank(acc.DES_Group_Code__c)){
            recordCode = acc.DES_Group_Code__c;
        } else {
            recordCode = acc.Local_Clients__r[0].Alpha_code__c;
        }

        if(!acc.Local_Clients__r.isEmpty()){
            mitigantClientCode = acc.Local_Clients__r[0].Alpha_code__c;
        }

        if(String.isBlank(accountRecordCode)){
            accountRecordCode = recordCode;
        }
        Opportunity oppty = acc.Opportunities[0];
        DMT_Opportunity_Client__c oppClient;
        if (oppty.DMT_MDE_Opportunities_Clients__r != null && !oppty.DMT_MDE_Opportunities_Clients__r.isEmpty()) {
            oppClient = oppty.DMT_MDE_Opportunities_Clients__r[0];
        }

        // Load group data once, reuse everywhere
        if(mapGroupsCache.isEmpty()){
            mapGroupsCache = DMT_HPG_Utils.getGroupFromClientAccount(accountRecordCode);
        }

        DMT_PassportOpportunity_Wrapper.Request payloadMap = new DMT_PassportOpportunity_Wrapper.Request();
        payloadMap.opportunityId = oppty.DMT_Opp_Id__c;
        payloadMap.version = String.valueOf(oppty.DMT_NUM_Version__c);
        payloadMap.auditDate = Datetime.now();
        payloadMap.entific = oppty.Entific__c;
        payloadMap.booking = oppty.Entific__c;
        payloadMap.entity = oppty.DMT_Entity__c;
        payloadMap.lineDesc = oppty.Name;
        payloadMap.user = userId(oppty.OwnerId);
        payloadMap.status = oppty.StageName.toUpperCase();
        payloadMap.initDate = oppty.DMT_DATE_Initial_Date__c;
        payloadMap.endDate = oppty.DMT_DATE_Maturity_Date__c;
        payloadMap.currencyId = payloadMap.currencyId = String.isNotBlank(oppty.DMT_Currency__c) ? oppty.DMT_Currency__c.toUpperCase() : oppty.CurrencyIsoCode;

        DMT_PassportOpportunity_Wrapper.RequestBody body = new DMT_PassportOpportunity_Wrapper.RequestBody();
        body.client = buildOpportunityClientDetails(oppty, oppClient);
        body.opportunity = buildOpportunityDetails(oppty,oppClient);
        body.products= buildOpportunityProducts(oppty);
        body.analysts = buildOppAnalystDetails(oppty);
        for(DMT_PassportOpportunity_Wrapper.Product prdct : body.products){
            if(prdct.geographyBranch !=null){
                payloadMap.geographyBranch = prdct.geographyBranch;
                break;
            }
        }
        if(oppty.DMT_Sanction__c != null){
         body.opportunity.opportunitySanctions = buildOpportunitySanctions(oppty);
        }
        body.features = new List<DMT_Wrapper_Passport_Abs.Feature> { calculateFeatureGenConsOpp(oppty, clientsGroup) };

        body.optionalFeatures = calculateOptionalFeaturesOpp(oppty);


        payloadMap.body = JSON.serialize(body);
        System.debug('ABS PAYLOAD -- '+JSON.serialize(payloadMap) );

        return JSON.serialize(payloadMap);

        // --- BEGIN: FORCE NULL FIELDS IN BODY JSON ---

        // Convert wrapper into a Map because JSON.serialize() includes nulls for Maps
        /* Map<String, Object> bodyMap = new Map<String, Object>{
            'client'           => body.client,
            'opportunity'      => body.opportunity,
            'products'         => body.products,
            'features'         => body.features,
            'optionalFeatures' => body.optionalFeatures
        };

        // Serialize with nulls included
        String bodyJsonString = JSON.serialize(bodyMap, true);

        // Integration expects "body" as a string (escaped JSON)
        payloadMap.body = bodyJsonString;

        // --- END ---

        System.debug('ABS PAYLOAD -- ' + JSON.serialize(payloadMap, true));

        // Return final payload containing body as a JSON string
        return JSON.serialize(payloadMap, true); */

    }


    // Construcción de los detalles del cliente para oportunidades
    private static DMT_Wrapper_Passport_Abs.Client buildOpportunityClientDetails(Opportunity oppty, DMT_Opportunity_Client__c oppClient) {
        DMT_Wrapper_Passport_Abs.Client client = new DMT_Wrapper_Passport_Abs.Client();
        client.customerId = oppty.Account.g_customer_id__c; // testing 'ES01TESTNEOCLIE'
        client.customerName = oppty.Account.Name;
        client.clientType = 'CORP';//oppty.Account.DES_Client_Type__c;
        client.shortRating = oppClient.External_Rating__c;

        if (mapGroupsCache.containsKey('groupCode')) {
            client.groupId = (String) mapGroupsCache.get('groupCode');
        }
        if (mapGroupsCache.containsKey('groupName')) {
            client.groupName = (String) mapGroupsCache.get('groupName');
        }
        if (mapGroupsCache.containsKey('subgroupId')) {
            client.subgroupId = (String) mapGroupsCache.get('subgroupId');
        }
        if (mapGroupsCache.containsKey('supragroupId')) {
            client.supragroupId = (String) mapGroupsCache.get('supragroupId');
        }

        return client;
    }

    private static DMT_PassportOpportunity_Wrapper.Opportunity buildOpportunityDetails(Opportunity oppty,DMT_Opportunity_Client__c oppClient) {

        List<DMT_X_Sell__c> xSells = oppty.X_sell__r;

        DMT_PassportOpportunity_Wrapper.Opportunity opp = new DMT_PassportOpportunity_Wrapper.Opportunity();
        opp.counterpart =oppClient.Counterpart__c;
        opp.avc=oppClient.AVC_Check__c;
        opp.europeanBank=oppClient.European_Bank_Check__c;
        opp.clientRating=oppClient.g_upd_lmscl_internal_ratg_type__c;
        opp.externalClientRating=oppClient.External_Rating__c;
        opp.scra=oppClient.SCRA__c;
        opp.currencyId = oppty.DMT_CurrencyText__c;
        opp.clientSector = oppClient.DMT_Sector__c != null ? oppClient.DMT_Sector__c.left(5) : null;opp.clientSector = oppClient.DMT_Sector__c;
        opp.thresholdGroupType=oppty.DMT_Threshold_Type__c;
        if(oppClient.Group_Sales_Check__c==true){
            opp.groupSales = 1;
        }else{
            opp.groupSales=0;
        }

        opp.xsells = new List<DMT_PassportOpportunity_Wrapper.Xsells>();

        for(DMT_X_Sell__c xsell : xSells){
            DMT_PassportOpportunity_Wrapper.Xsells xs = new DMT_PassportOpportunity_Wrapper.Xsells();
            xs.year = xsell.g_year__c !=null ? Integer.valueOf(xsell.g_year__c.year()) : null;
            xs.amount = xsell.g_notional_amount__c;
            xs.currencyId = xsell.DMT_Currency__c;

            opp.xsells.add(xs);
        }

        return opp;

    }

    private static List<DMT_PassportOpportunity_Wrapper.Product> buildOpportunityProducts(Opportunity oppty) {
        List<OpportunityLineItem> oppLineItems = oppty.OpportunityLineItems;
        Map<Id, List<DMT_Opportunity_Mitigant__c>> mitigantsMap = buildMitigantsMap(oppLineItems);
        Map<String, String> tax895Map = buildTaxonomyMap(mitigantsMap);
        Map<Id, List<DMT_Opportunity_Tenor__c>> amortizationPayMap = buildAmortizationMap(oppLineItems);

        List<DMT_PassportOpportunity_Wrapper.Product> products = new List<DMT_PassportOpportunity_Wrapper.Product>();
        for (OpportunityLineItem opplitem : oppLineItems) {
            products.add(buildProduct(opplitem, mitigantsMap, tax895Map, amortizationPayMap));
        }

        return products;
    }

    private static Map<Id, List<DMT_Opportunity_Mitigant__c>> buildMitigantsMap(List<OpportunityLineItem> oppLineItems) {
        List<DMT_Opportunity_Mitigant__c> mitigants = new List<DMT_Opportunity_Mitigant__c>();
        for (OpportunityLineItem oli : oppLineItems) {
            if (oli.Opportunity_Mitigants__r != null && !oli.Opportunity_Mitigants__r.isEmpty()) {
                mitigants.addAll(oli.Opportunity_Mitigants__r);
            }
        }

        Map<Id, List<DMT_Opportunity_Mitigant__c>> mitigantsMap = new Map<Id, List<DMT_Opportunity_Mitigant__c>>();
        Set<String> mitigantTypes = new Set<String>();
        for (DMT_Opportunity_Mitigant__c mitigant : mitigants) {
            mitigantTypes.add(mitigant.Mitigant_Type__c);
            if (mitigantsMap.containsKey(mitigant.DMT_Opportunity_Product__c)) {
                mitigantsMap.get(mitigant.DMT_Opportunity_Product__c).add(mitigant);
            } else {
                mitigantsMap.put(mitigant.DMT_Opportunity_Product__c, new List<DMT_Opportunity_Mitigant__c>{mitigant});
            }
        }

        return mitigantsMap;
    }

    private static Map<String, String> buildTaxonomyMap(Map<Id, List<DMT_Opportunity_Mitigant__c>> mitigantsMap) {
        Set<String> mitigantTypes = new Set<String>();
        for (List<DMT_Opportunity_Mitigant__c> mitigantList : mitigantsMap.values()) {
            for (DMT_Opportunity_Mitigant__c mitigant : mitigantList) {
                mitigantTypes.add(mitigant.Mitigant_Type__c);
            }
        }

        List<DMT_Taxonomy_Values__c> taxonomyValuesList = DMT_Passport_Selector.getTaxonomyValuesByCatalogsAndNames(new List<String>{'E895'}, new List<String>(mitigantTypes));

        Map<String, String> tax895Map = new Map<String, String>();
        for (DMT_Taxonomy_Values__c tax : taxonomyValuesList) {
            if (tax.DMT_Name_EN__c != null && tax.DMT_Value__c != null) {
                tax895Map.put(tax.DMT_Name_EN__c, tax.DMT_Value__c);
            }
        }

        return tax895Map;
    }

    private static Map<Id, List<DMT_Opportunity_Tenor__c>> buildAmortizationMap(List<OpportunityLineItem> oppLineItems) {
        List<DMT_Opportunity_Tenor__c> amortizationPayments = new List<DMT_Opportunity_Tenor__c>();
        for (OpportunityLineItem oli : oppLineItems) {
            if (oli.Opportunity_Tenors__r != null && !oli.Opportunity_Tenors__r.isEmpty()) {
                amortizationPayments.addAll(oli.Opportunity_Tenors__r);
            }
        }

        Map<Id, List<DMT_Opportunity_Tenor__c>> amortizationPayMap = new Map<Id, List<DMT_Opportunity_Tenor__c>>();
        for (DMT_Opportunity_Tenor__c opTenor : amortizationPayments) {
            if (amortizationPayMap.containsKey(opTenor.DMT_Opportunity_Product__c)) {
                amortizationPayMap.get(opTenor.DMT_Opportunity_Product__c).add(opTenor);
            } else {
                amortizationPayMap.put(opTenor.DMT_Opportunity_Product__c, new List<DMT_Opportunity_Tenor__c>{opTenor});
            }
        }

        return amortizationPayMap;
    }

    private static DMT_PassportOpportunity_Wrapper.Product buildProduct(OpportunityLineItem opplitem, Map<Id, List<DMT_Opportunity_Mitigant__c>> mitigantsMap, Map<String, String> tax895Map, Map<Id, List<DMT_Opportunity_Tenor__c>> amortizationPayMap) {
        DMT_PassportOpportunity_Wrapper.Product product = new DMT_PassportOpportunity_Wrapper.Product();
        product.geographyBranch = opplitem.g_branch_id__c;
        product.initDate = opplitem.gf_initial_date__c;
        product.endDate = opplitem.gf_maturity_date__c;
        product.currencyId = opplitem.g_currency_id__c;
        product.productId = opplitem.Id;
        product.lastLevelId = opplitem.DMT_Risk_Type__c;
        product.businessArea = 'IB&F';
        product.prco = opplitem.ProductCode;
        product.intermediateDate = opplitem.gf_intermediate_date__c;
        product.countryRisk = opplitem.gf_country_risk__c;
        product.crr2 = String.valueOf(opplitem.gf_crr2_essential_public_services__c);
        product.countryRating = opplitem.gf_country_rating__c;

        product.funding = buildFunding(opplitem);
        product.mitigants = buildMitigants(opplitem.Id, mitigantsMap, tax895Map);
        product.amortization = buildAmortization(opplitem, amortizationPayMap.get(opplitem.Id));

        System.debug(LoggingLevel.INFO, 'PRODUCTO OPP-- ' + JSON.serialize(product));
        return product;
    }

    private static DMT_PassportOpportunity_Wrapper.Funding buildFunding(OpportunityLineItem opplitem) {
        DMT_PassportOpportunity_Wrapper.Funding funding = new DMT_PassportOpportunity_Wrapper.Funding();
        funding.fundingType = opplitem.Funding_Curve__c;
        funding.fundingTerm = opplitem.Life_Funding_Type__c;
        funding.dbFunding = opplitem.gf_funding_cost_db__c;
        funding.fbFunding = opplitem.gf_funding_cost_fb__c;
        funding.greenBond = opplitem.gf_green_bonus__c;
        funding.socialBond = opplitem.gf_social_bond__c;
        return funding;
    }

    private static List<DMT_PassportOpportunity_Wrapper.Mitigant> buildMitigants(Id productId, Map<Id, List<DMT_Opportunity_Mitigant__c>> mitigantsMap, Map<String, String> tax895Map) {
        List<DMT_PassportOpportunity_Wrapper.Mitigant> mitigants = new List<DMT_PassportOpportunity_Wrapper.Mitigant>();
        if (mitigantsMap.get(productId) != null) {
            for (DMT_Opportunity_Mitigant__c mt : mitigantsMap.get(productId)) {
                DMT_PassportOpportunity_Wrapper.Mitigant mitigant = new DMT_PassportOpportunity_Wrapper.Mitigant();
                mitigant.avc = mt.AVC_Check__c;
                mitigant.europeanBank = mt.European_Bank_Check__c;
                mitigant.mitigantId = mt.Id;
                mitigant.mitigantType = tax895Map.get(mt.Mitigant_Type__c);
                mitigant.mitigantCounterpart = mt.Counterpart__c;
                mitigant.mitigantRating = mt.Internal_Rating__c;
                mitigant.ratingExternal = mt.External_Rating__c;
                mitigant.mitigantScra = mt.SCRA__c;
                mitigant.mitigantLiquidationPeriod = mt.Liquidation_Period__c;
                mitigant.mitigantEndDate = mt.End_Date__c;
                mitigant.mitigantCurrency = mt.CurrencyIsoCode;
                mitigant.commercialRisk = mt.Commercial_Percentage__c;
                mitigant.politicalRisk = mt.Political_Percentage__c;
                mitigant.eca = mt.Garantor_European_ECA__c;
                mitigant.mitigantCountry = mt.DMT_Country_Guarantor__c;
                mitigant.customerId = mitigantClientCode; //CIBGLOBALD-2027
                if (mapGroupsCache.containsKey('groupCode')) {
                    mitigant.groupId = (String) mapGroupsCache.get('groupCode'); //CIBGLOBALD-2027
                }
                if (mapGroupsCache.containsKey('subgroupId')) {
                    mitigant.subgroupId = (String) mapGroupsCache.get('subgroupId'); //CIBGLOBALD-2027
                }
                if (mapGroupsCache.containsKey('supragroupId')) {
                    mitigant.supragroupId = (String) mapGroupsCache.get('supragroupId'); //CIBGLOBALD-2027
                }
                mitigants.add(mitigant);
            }
        }
        return mitigants;
    }

    private static DMT_PassportOpportunity_Wrapper.Amortization buildAmortization(OpportunityLineItem opplitem, List<DMT_Opportunity_Tenor__c> amortizationPayments) {
        DMT_PassportOpportunity_Wrapper.Amortization amortization = new DMT_PassportOpportunity_Wrapper.Amortization();
        amortization.amortizationType = opplitem.gf_amortization_type__c;
        amortization.paymentFrequency = opplitem.gf_payment_frequency__c;
        amortization.feesPeriodic = opplitem.gf_accrual_fees_bp__c != null ? opplitem.gf_accrual_fees_bp__c : 0;
        //periodic
        amortization.payments = new List<DMT_PassportOpportunity_Wrapper.AmortizationPayments>();

        if (amortizationPayments != null) {
            for (DMT_Opportunity_Tenor__c amortizationPayment : amortizationPayments) {
                DMT_PassportOpportunity_Wrapper.AmortizationPayments prdAmortizationPayment = new DMT_PassportOpportunity_Wrapper.AmortizationPayments();
                prdAmortizationPayment.paymentDate = amortizationPayment.gf_tenor_date__c;
                prdAmortizationPayment.nominalAmount = amortizationPayment.gj_nominal_amount_db__c != null ? amortizationPayment.gj_nominal_amount_db__c : 0;
                prdAmortizationPayment.nominalFb = amortizationPayment.gf_nominal_amount_fb__c != null ? amortizationPayment.gf_nominal_amount_fb__c : 0;
                prdAmortizationPayment.spreadAmount = amortizationPayment.gf_spread_db__c != null ? amortizationPayment.gf_spread_db__c : 0;
                prdAmortizationPayment.spreadFbAmount = amortizationPayment.gf_spread_fb__c != null ? amortizationPayment.gf_spread_fb__c : 0;
                prdAmortizationPayment.feesOther = amortizationPayment.gf_accrual_fees_bp__c != null ? amortizationPayment.gf_accrual_fees_bp__c : 0;
                prdAmortizationPayment.feesUpfront = amortizationPayment.gf_non_accrual_fees_bp__c != null ? amortizationPayment.gf_non_accrual_fees_bp__c : 0;
                prdAmortizationPayment.financeType = 'Standard' /*opplitem.gf_financing_type__c*/;

                amortization.payments.add(prdAmortizationPayment);
            }
        }

        return amortization;
    }

    public static List<DMT_PassportOpportunity_Wrapper.OpportunitySanctions> buildOpportunitySanctions(Opportunity oppty) {
        DMT_PassportOpportunity_Wrapper.OpportunitySanctions oppSanctions = new DMT_PassportOpportunity_Wrapper.OpportunitySanctions();
        oppSanctions.lineCode = oppty.DMT_Sanction__r.Line_Id__c;

        List<DMT_PassportOpportunity_Wrapper.ProductsLine> productsLineList = new List<DMT_PassportOpportunity_Wrapper.ProductsLine>();

        if (oppty.OpportunityLineItems != null && !oppty.OpportunityLineItems.isEmpty()) {
            for (OpportunityLineItem oli : oppty.OpportunityLineItems) {
                if (oli.DMT_Associated_Line_Product__r != null) {
                    DMT_PassportOpportunity_Wrapper.ProductsLine pl = new DMT_PassportOpportunity_Wrapper.ProductsLine();
                    pl.productApproval = oli.DMT_Associated_Line_Product__r.gf_group_priority_line_id__c;
                    pl.productOpportunity = oli.gf_group_priority_opportunity_id__c;
                    productsLineList.add(pl);
                }
            }
        }

        oppSanctions.productsLine = productsLineList;

        return new List<DMT_PassportOpportunity_Wrapper.OpportunitySanctions>{ oppSanctions };
    }

    // Métodos auxiliares
    private static String userId(String recordId) {
        if (recordId != null && objectNameById(recordId) == User.getSObjectType().getDescribe().getName()) {
            User u = [SELECT Id, FederationIdentifier FROM User WHERE Id = :recordId WITH SECURITY_ENFORCED];
            return u.FederationIdentifier.left(8);
        }
        return null;
    }

    public static String objectNameById(String recordId) {
        Id recId = Id.valueOf(recordId);
        return recId.getSObjectType().getDescribe().getName();
    }

    public static DMT_Wrapper_Passport_Abs.Feature calculateFeatureGenCons(String recordId, String clientsGroup) {
        DMT_Wrapper_Passport_Abs.Feature featureBody = new DMT_Wrapper_Passport_Abs.Feature();
        featureBody.id = DMT_Constants.FEATURE_GC_ID;
        featureBody.name = DMT_Constants.FEATURE_GC_NAME;
        featureBody.passportSanction = DMT_Constants.FEATURE_GC_PASSPORTSANCTION;
        featureBody.active = DMT_Constants.FEATURE_GC_ACTIVE;
        featureBody.motorDesc = DMT_Constants.FEATURE_GC_MOTORDESC;
        featureBody.stateName = DMT_Constants.FEATURE_GC_STATE_GREEN;
        featureBody.validations = DMT_LineFeatureGenCons_Calc.checkValidations(recordId, clientsGroup);

        for (DMT_Wrapper_Passport_Abs.FeatureGenConsiderations validation : featureBody.validations) {
            if (validation.state != DMT_Constants.FEATURE_GC_STATE_GREEN) {
                featureBody.stateName = DMT_Constants.FEATURE_GC_STATE_RED;
            }
        }

        return featureBody;
    }

    public static List<DMT_Wrapper_Passport_Abs.OptionalFeatures> calculateOptionalFeatures(DMT_Line__c dmtLine) {
        List<DMT_Selected_Features__c> selectedFeatures = DMT_Passport_Selector.getSelectedFeatures(dmtLine.Id);
        List<DMT_Wrapper_Passport_Abs.OptionalFeatures> optionalFeaturesList = new List<DMT_Wrapper_Passport_Abs.OptionalFeatures>();

        for (DMT_Selected_Features__c feature : selectedFeatures) {
            DMT_Wrapper_Passport_Abs.OptionalFeatures optionalFeature = new DMT_Wrapper_Passport_Abs.OptionalFeatures();
            optionalFeature.id = feature.Feature__r.gf_code_value_id__c;
            optionalFeaturesList.add(optionalFeature);
        }

        return optionalFeaturesList;
    }

    public static DMT_Wrapper_Passport_Abs.Feature calculateFeatureGenConsOpp(Opportunity opp, String clientsGroup) {
        DMT_Wrapper_Passport_Abs.Feature featureBody = new DMT_Wrapper_Passport_Abs.Feature();
        featureBody.id = '200';
        featureBody.name = DMT_Constants.FEATURE_GC_NAME;
        featureBody.passportSanction = DMT_Constants.FEATURE_GC_PASSPORTSANCTION;
        featureBody.active = DMT_Constants.FEATURE_GC_ACTIVE;
        featureBody.motorDesc = DMT_Constants.FEATURE_GC_MOTORDESC;
        featureBody.stateName = DMT_Constants.FEATURE_GC_STATE_GREEN;
        //featureBody.validations = new List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations>();
        featureBody.validations = DMT_OppFeatureGenCons_Calc.checkValidations(opp, clientsGroup);

         for (DMT_Wrapper_Passport_Abs.FeatureGenConsiderations validation : featureBody.validations) {
            if (validation.state != DMT_Constants.FEATURE_GC_STATE_GREEN) {
                featureBody.stateName = DMT_Constants.FEATURE_GC_STATE_RED;
            }
        }


        return featureBody;
    }

    public static List<DMT_Wrapper_Passport_Abs.OptionalFeatures> calculateOptionalFeaturesOpp(Opportunity oppty) {
        List<DMT_Selected_Features__c> selectedFeatures = DMT_Passport_Selector.getSelectedFeaturesOPP(oppty.Id);
        System.debug('DMT_Passport_Helper calculateOptionalFeaturesOpp selectedFeatures: ' + selectedFeatures);
        List<DMT_Wrapper_Passport_Abs.OptionalFeatures> optionalFeaturesList = new List<DMT_Wrapper_Passport_Abs.OptionalFeatures>();

        for (DMT_Selected_Features__c feature : selectedFeatures) {
            DMT_Wrapper_Passport_Abs.OptionalFeatures optionalFeature = new DMT_Wrapper_Passport_Abs.OptionalFeatures();
            optionalFeature.id = feature.Feature__r.gf_code_value_id__c;
            optionalFeaturesList.add(optionalFeature);
        }
        System.debug('DMT_Passport_Helper calculateOptionalFeaturesOpp optionalFeaturesList: ' + optionalFeaturesList);
        return optionalFeaturesList;
    }

    //CIBGLOBALD-1195 parameter is added to the method
    public static Case createCase(DMT_Line__c line, Opportunity opp, Id aproverId,String featureId, String featureName,List<Map<String, Object>> taskList, String comment, String passportSanction) {

        Case newCase = new Case();
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(DMT_Constants.CASE_RT_APPROVAL).getRecordTypeId();
        //DMT_Passport_Selector.getRecordTypeId('Approval','Case');
        newCase.OwnerId = aproverId;
        newCase.Status = 'Pending';
        if(line != null){
            newCase.DMT_Line__c = line.Id;
            newCase.AccountId = line.Client__c;
        }
        if(opp != null){
            newCase.opportunity_id__c = opp.Id;
            newCase.AccountId = opp.AccountId;
        }
        newCase.DMT_Feature_Id__c = featureId;
        newCase.DMT_Related_feature_name__c = featureName;
        newCase.DMT_Closing_Tasks__c = JSON.serialize(taskList);
        //CIBGLOBALD-1195 parameter is added to the method
        newCase.Description = comment;
        //CIBGLOBALD-1444 parameter is added to the method
        newCase.DMT_Passport_Sanction__c = passportSanction;

        insert newCase;

        return newCase;

    }

    public static Task  createTask(Id caseId,Id aproverId, DMT_Task_Type__c taskType) {

        Task newTask = new Task();
        newTask.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(DMT_Constants.TASK_RT_APPROVAL_STEP).getRecordTypeId();
        //DMT_Passport_Selector.getRecordTypeId('DMT_Step_Approval','Task');
        newTask.Status = DMT_Constants.PENDING;
        newTask.OwnerId = aproverId;
        newTask.DMT_Task_Type__c = taskType.Id;
        newTask.Subject = taskType.Name;
        newTask.whatId = caseId;

        DMT_WithoutSharingDAO.insertRecord(newTask);

        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(newTask.Id,false);

        return newTask;
    }

    public static void callPassportService(Passport__c passport,Map<String, Object> requestMap, Map<String, Object> outMap ,String objectName) {

        System.debug('ABS REQUEST - '+ JSON.serialize(requestMap));
        HttpResponse response;
        String serviceName;

        if(objectName == Opportunity.getSObjectType().getDescribe().getName() ){
            serviceName='DMTO_EvaluationOpportunity';

        } else if(objectName == DMT_Line__c.getSObjectType().getDescribe().getName()){
            serviceName='DMTO_EvaluationLine';
        }
        response = DMT_HPG_Utils.callService_DMT(serviceName, requestMap);

        if( (response.getStatusCode() == 200 || response.getStatusCode() == 201) ) {
            if(objectName == Opportunity.getSObjectType().getDescribe().getName() ){
                Opportunity oppToUpdate = new Opportunity();
                oppToUpdate.Id = passport.Opportunity__c;
                oppToUpdate.DMT_Requested_Passport__c = hasProfitabilityResultsFromJson(response.getBody());

                update oppToUpdate;
            }

                String bodyResponse = response.getBody();

                bodyResponse = bodyResponse.replaceAll('@date', Datetime.now().format('yyyy-MM-dd HH:mm:ss'));

                passport.DMT_Is_Obsoleted_Passport_Save__c = false;
                passport.DMT_Passport_Save__c = bodyResponse;
                System.debug('callPassport body response: ' + bodyResponse);

                update passport;
                System.debug('fuera');
                //callPassportClosedWon(passport.DMT_Line__c);

        } else {
            outMap.put('result', false);
            outMap.put('message', Label.OpportunityServiceError);
        }
    }


    public static String setPayloadMin(String recordId) {
        DMT_Line__c dmtLine = DMT_Passport_Selector.getLine(recordId);
        DMT_PasppportMin_Wrapper.Request payload = new DMT_PasppportMin_Wrapper.Request();

        payload.opportunityId = dmtLine.Line_Id__c;
        payload.status = dmtLine.DMT_Status_Completed__c.toUpperCase();
        if(dmtLine.RecordType.DeveloperName == 'TreasurySettlement'){
            List<DMT_PasppportMin_Wrapper.Product> products = new List<DMT_PasppportMin_Wrapper.Product>();
            DMT_PasppportMin_Wrapper.Product productFD = new DMT_PasppportMin_Wrapper.Product();
            productFD.amount = dmtLine.FD_Amount__c;
            productFD.currencyId = dmtLine.CurrencyIsoCode;
            productFD.groupPriorityLineId = '01';
            productFD.parentConsums = dmtLine.DMT_Parent_Line__c != null ? new List<DMT_PasppportMin_Wrapper.ParentConsum>() : null;

            if(dmtLine.DMT_Parent_Line__c != null){
                DMT_PasppportMin_Wrapper.ParentConsum parentFD = new DMT_PasppportMin_Wrapper.ParentConsum();
                parentFD.productParent = '01';
                parentFD.parentId = dmtLine.DMT_Parent_Line__r.Line_Id__c;
                parentFD.amount = dmtLine.DMT_Parent_Line__r.FD_Amount__c;
                parentFD.currencyId = dmtLine.DMT_Parent_Line__r.CurrencyIsoCode;
                parentFD.endDateParent = dmtLine.DMT_Parent_Line__r.End_Date__c;

                productFD.parentConsums.add(parentFD);
            }
            products.add(productFD);

            DMT_PasppportMin_Wrapper.Product productDVP = new DMT_PasppportMin_Wrapper.Product();
            productDVP.amount = dmtLine.DvP_Amount__c;
            productDVP.currencyId = dmtLine.CurrencyIsoCode;
            productDVP.groupPriorityLineId = '02';
            productDVP.parentConsums = dmtLine.DMT_Parent_Line__c != null ? new List<DMT_PasppportMin_Wrapper.ParentConsum>() : null;

            if(dmtLine.DMT_Parent_Line__c != null){
                DMT_PasppportMin_Wrapper.ParentConsum parentDVP = new DMT_PasppportMin_Wrapper.ParentConsum();
                parentDVP.productParent = '02';
                parentDVP.parentId = dmtLine.DMT_Parent_Line__r.Line_Id__c;
                parentDVP.amount = dmtLine.DMT_Parent_Line__r.DvP_Amount__c;
                parentDVP.currencyId = dmtLine.DMT_Parent_Line__r.CurrencyIsoCode;
                parentDVP.endDateParent = dmtLine.DMT_Parent_Line__r.End_Date__c;

                productDVP.parentConsums.add(parentDVP);
            }
            products.add(productDVP);

            DMT_PasppportMin_Wrapper.Product productDeri = new DMT_PasppportMin_Wrapper.Product();
            productDeri.amount = dmtLine.DMT_DerivativesAmount__c;
            productDeri.currencyId = dmtLine.CurrencyIsoCode;
            productDeri.groupPriorityLineId = '03';
            productDeri.parentConsums = dmtLine.DMT_Parent_Line__c != null ? new List<DMT_PasppportMin_Wrapper.ParentConsum>() : null;

            if(dmtLine.DMT_Parent_Line__c != null){
                DMT_PasppportMin_Wrapper.ParentConsum parentDeri = new DMT_PasppportMin_Wrapper.ParentConsum();
                parentDeri.productParent = '03';
                parentDeri.parentId = dmtLine.DMT_Parent_Line__r.Line_Id__c;
                parentDeri.amount = dmtLine.DMT_Parent_Line__r.DMT_DerivativesAmount__c;
                parentDeri.currencyId = dmtLine.DMT_Parent_Line__r.CurrencyIsoCode;
                parentDeri.endDateParent = dmtLine.DMT_Parent_Line__r.End_Date__c;

                productDeri.parentConsums.add(parentDeri);
            }
            products.add(productDeri);

            payload.products = products;
            system.debug('json'+ payload);
        }else{

        List<DMT_PasppportMin_Wrapper.Product> products = new List<DMT_PasppportMin_Wrapper.Product>();
        List<DMT_Risk_Line_Term__c> riskTerms = DMT_Passport_Selector.getRiskLineTermWhithoutRiskType(dmtLine.Id);

        DMT_PasppportMin_Wrapper.Product productInfo = new DMT_PasppportMin_Wrapper.Product();
            productInfo.amount = dmtLine.Amount__c;
            productInfo.currencyId = dmtLine.CurrencyIsoCode;
            productInfo.groupPriorityLineId = '00';
            productInfo.parentConsums = dmtLine.DMT_Parent_Line__c != null ? new List<DMT_PasppportMin_Wrapper.ParentConsum>() : null;

            if(dmtLine.DMT_Parent_Line__c != null){
                DMT_PasppportMin_Wrapper.ParentConsum parentInfo = new DMT_PasppportMin_Wrapper.ParentConsum();
                parentInfo.productParent = '00';
                parentInfo.parentId = dmtLine.DMT_Parent_Line__r.Line_Id__c;
                parentInfo.amount = dmtLine.Amount__c;
                parentInfo.currencyId = dmtLine.CurrencyIsoCode;
                parentInfo.endDateParent = dmtLine.DMT_Parent_Line__r.End_Date__c;

                productInfo.parentConsums.add(parentInfo);
            }

            products.add(productInfo);

        for (DMT_Risk_Line_Term__c rlt : riskTerms) {
            DMT_PasppportMin_Wrapper.Product product = new DMT_PasppportMin_Wrapper.Product();
            product.amount = rlt.DMT_Amount__c;
            product.currencyId = rlt.CurrencyIsoCode;
            product.groupPriorityLineId = rlt.gf_group_priority_line_id__c;
            product.parentConsums = rlt.DMT_Parent_Product__c != null ? new List<DMT_PasppportMin_Wrapper.ParentConsum>() : null;

            if(rlt.DMT_Parent_Product__c != null){
                DMT_PasppportMin_Wrapper.ParentConsum parent = new DMT_PasppportMin_Wrapper.ParentConsum();
                parent.productParent = rlt.DMT_Parent_Product__r.gf_group_priority_line_id__c;
                parent.parentId = dmtLine.DMT_Parent_Line__r.Line_Id__c;
                parent.amount = rlt.DMT_Parent_Product__r.DMT_Amount__c;
                parent.currencyId = rlt.DMT_Parent_Product__r.CurrencyIsoCode;
                parent.endDateParent = dmtLine.DMT_Parent_Line__r.Start_Date__c.addDays(rlt.DMT_Parent_Product__r.DMT_End_Term__c != null ? Integer.valueOf(rlt.DMT_Parent_Product__r.DMT_End_Term__c) : 0);

                product.parentConsums.add(parent);
            }

            products.add(product);
        }

        payload.products = products;
        system.debug('json'+ payload);
        }
        return JSON.serialize(payload);
    }

    public static void callConsumptionLimitService(Map<String, Object> requestMap, Map<String, Object> outMap) {
        HttpResponse response;
        String serviceName='DMT_PUT_OpportunityConsumptionLimit';
        response = DMT_HPG_Utils.callService_DMT(serviceName, requestMap);
        system.debug('response '+ response.getStatusCode());
        if( !(response.getStatusCode() == 200 || response.getStatusCode() == 201) ) {
            outMap.put('result', false);
            outMap.put('message', Label.OpportunityServiceError);
        }
    }

    /**
    * @description This method validate if the opportunity is ready to be sent to passport
    * @author BBVA DMT | 07-10-2025
    * @param oppId
    * @return Map<String, Object> succes = false its error validation, retur message to show
    **/
    public static Map<String,Object> validateOppBeforePassport(Id oppId) {
            final Map<String,Object> returnMap = new Map<String,Object>();
            final List<String> errorMessages = new List<String>();
            Map<Id,List<DMT_Opportunity_Tenor__c>> tenorMapByOplId;
            final List<OpportunityLineItem> listOppLineItems = DMT_Passport_Selector.getOpportunityLineItems(oppId);
            if (listOppLineItems.isEmpty()) {
                errorMessages.add(System.Label.DMT_PassportValidationMsg_NoProduct);
            } else {
                Map<Id,OpportunityLineItem> opliById = new Map<Id,OpportunityLineItem>();
                opliById.putAll(listOppLineItems);
                final List<DMT_Opportunity_Tenor__c> amortPaymts  = DMT_Passport_Selector.getAmortizationPayments(opliById.keySet());
                if(!amortPaymts .isEmpty()) {
                    tenorMapByOplId = new Map<Id,List<DMT_Opportunity_Tenor__c>>();
                    for(DMT_Opportunity_Tenor__c opTenor : amortPaymts) {
                        if(tenorMapByOplId.containsKey(opTenor.DMT_Opportunity_Product__c)) {
                            tenorMapByOplId.get(opTenor.DMT_Opportunity_Product__c).add(opTenor);
                        } else {
                            final List<DMT_Opportunity_Tenor__c> opTenorList = new List<DMT_Opportunity_Tenor__c>();
                            opTenorList.add(opTenor);
                            tenorMapByOplId.put(opTenor.DMT_Opportunity_Product__c,opTenorList);
                        }
                    }
                }

                for(OpportunityLineItem opli : listOppLineItems) {
                    if(opli.DMT_Risk_Type__c == null || opli.g_branch_id__c == null && (errorMessages.isEmpty() && !errorMessages.contains(System.Label.DMT_PassportValidationMsg_NoRiskTypeBookingGeography)) ) {
                            errorMessages.add(System.Label.DMT_PassportValidationMsg_NoRiskTypeBookingGeography );
                        }


                    Boolean hasValidTenor = false;
                    if(tenorMapByOplId?.get(opli.Id) != null) {
                        for(DMT_Opportunity_Tenor__c tenorFromOpli : tenorMapByOplId.get(opli.Id)) {
                            if((tenorFromOpli.gj_nominal_amount_db__c != null && tenorFromOpli.gj_nominal_amount_db__c > 0) || (tenorFromOpli.gf_nominal_amount_fb__c != null && tenorFromOpli.gf_nominal_amount_fb__c > 0)) {
                                hasValidTenor = true;
                                break;
                            }
                        }
                    }
                    if(!hasValidTenor && !errorMessages.contains(System.Label.DMT_PassportValidationMsg_TenorsAmount)) {
                            errorMessages.add(System.Label.DMT_PassportValidationMsg_TenorsAmount);
                    }
                }
            }//End else opli empty
            if (errorMessages.isEmpty()) {
                returnMap.put('success', true);
                returnMap.put('message', new List<String>());
            } else {
                returnMap.put('success', false);
                returnMap.put('message', errorMessages);
            }

            return returnMap;

    }
    public static String createSanctionFromOpp(String oppId, String approverId){
        DMT_Approver__c approver = DMT_Passport_Selector.getApprover(approverId);

        if(approver != null && approver.DMT_ApproverType__r.Name == APPROVERTYPE){
            Map<String,Object> params = new Map<String,Object>();
            params.put('recordId',oppId);
            Flow.Interview.DMT_CreateLineFROMOppFeature createSantionFlow = new Flow.Interview.DMT_CreateLineFROMOppFeature(params);
            createSantionFlow.start();
            String lineId = (String) createSantionFlow.getVariableValue('lineId');
            return lineId;
        }
        return null;
    }

    /* public static Boolean hasProfitabilityResults(String oppId) {
        Passport__c passport = DMT_Passport_Selector.passportByIdOpportunity(oppId);
        if (passport == null){
             return false;
        }

        String jsonStr = passport.DMT_Passport_Save__c;
        DMT_PassportLineWrapper wrapperedPassport =  DMT_PassportLineWrapper.parseLinePassport(jsonStr);
        if (wrapperedPassport == null || wrapperedPassport.data == null || wrapperedPassport.data.features == null) {
            return false;
        }

        for (DMT_PassportLineWrapper.Feature f : wrapperedPassport.data.features) {
            if (f.profitability != null &&
                f.profitability.results != null &&
                !f.profitability.results.isEmpty()) {
                return true;
            }
        }
        return false;
    } */
    
    public static Boolean hasProfitabilityResults(String oppId) {
        Passport__c passport = DMT_Passport_Selector.passportByIdOpportunity(oppId);
        if (passport == null) {
            return false;
        }
        return hasProfitabilityResultsFromJson(passport.DMT_Passport_Save__c);
    }

    public static Boolean hasProfitabilityResultsFromJson(String jsonStr) {
        if (String.isBlank(jsonStr)) {
            return false;
        }
        DMT_PassportLineWrapper wrapperedPassport = DMT_PassportLineWrapper.parseLinePassport(jsonStr);
        return hasProfitabilityResultsFromWrapper(wrapperedPassport);
    }
   
    private static Boolean hasProfitabilityResultsFromWrapper(DMT_PassportLineWrapper wrapperedPassport) {
        if (wrapperedPassport == null || wrapperedPassport.data == null || wrapperedPassport.data.features == null) {
            return false;
        }
        for (DMT_PassportLineWrapper.Feature f : wrapperedPassport.data.features) {
            if (f.profitability != null && f.profitability.results != null && !f.profitability.results.isEmpty()) {
                return true;
            }
        }
        return false;
    }
}