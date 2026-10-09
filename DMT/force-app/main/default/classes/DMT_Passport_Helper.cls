public with sharing class DMT_Passport_Helper {

    private static Map<String, Object> mapGroupsCache = new Map<String, Object>();
    private static String recordCode = '';
    private static String mitigantClientCode = null;
    FINAL PRIVATE STATIC STRING APPROVERTYPE = 'Risk';
    private static final Map<String, String> RATE_TYPE_MAPPING = new Map<String, String>{
        'Fijo' => 'FIXED',
        'Variable' => 'FLOATING'
    };

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

        if (dmtLine.RecordType.DeveloperName == 'OtherProducts' || dmtLine.RecordType.DeveloperName == 'Sanction') {
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
        if ( dmtLine.RecordType.DeveloperName != 'Sanction') {
        body.features = new List<DMT_Wrapper_Passport_Abs.Feature> { calculateFeatureGenCons(recordId, clientsGroup) };
        }
        body.documentsloads = buildDocumentLoads(dmtLine.CoreDocsTaxonomyValues__c);
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
        body.documentsloads = buildDocumentLoads(dmtLine.CoreDocsTaxonomyValues__c);

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
        body.templateType = dmtLine.DMT_line_template_type__c;
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
            mapGroupsCache = DMT_HPG_Utils.getGroupFromClientAccount(dmtLine.Client__c);
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
        analyst.approverBankerId = opp.DMT_ApproverGlobalBanker__r.DMT_Approver_Code__c;
        analyst.businessUnitRiskAnalyst = opp.DMT_Booking_Unit_Risk_Analyst__r.DMT_Approver_Code__c;
        analyst.fpRiskAnalyst = opp.DMT_Approver__r.DMT_Approver_Code__c;
        return analyst;
    }

    // Construcción de los detalles del analista
    private static DMT_Wrapper_Passport_Abs.Analyst buildAnalystDetails(DMT_Line__c dmtLine) {
        DMT_Wrapper_Passport_Abs.Analyst analyst = new DMT_Wrapper_Passport_Abs.Analyst();
        analyst.approverBankerId = dmtLine.DMT_ApproverGlobalBanker__r.DMT_Approver_Code__c;
        analyst.businessUnitRiskAnalyst = dmtLine.DMT_Booking_Unit_Risk_Analyst__r.DMT_Approver_Code__c;
        analyst.fpRiskAnalyst = dmtLine.DMT_Approver__r.DMT_Approver_Code__c;
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
        line.minRaroEcWoFgPerct = dmtLine.gf_min_raroec_wo_fcg_per__c;
        line.minRorWocFcgPerc = dmtLine.gf_min_rorc_wo_fcg_per__c;

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
            dvp.productParent = '01';
            dvp.parentId = dmtLine.DMT_Parent_Line__r.Line_Id__c;
            dvp.amountParent = dmtLine.DMT_Parent_Line__r.DvP_Amount__c;
            dvp.currencyParentId = dmtLine.DMT_Parent_Line__r.CurrencyIsoCode;
            dvp.endDateParent = dmtLine.DMT_Parent_Line__r.End_Date__c;
            parentConsums.add(dvp);

            DMT_Wrapper_Passport_Abs.ParentConsum fd = new DMT_Wrapper_Passport_Abs.ParentConsum();
            fd.productParent = '02';
            fd.parentId = dmtLine.DMT_Parent_Line__r.Line_Id__c;
            fd.amountParent = dmtLine.DMT_Parent_Line__r.FD_Amount__c;
            fd.currencyParentId = dmtLine.DMT_Parent_Line__r.CurrencyIsoCode;
            fd.endDateParent = dmtLine.DMT_Parent_Line__r.End_Date__c;
            parentConsums.add(fd);

            for(DMT_Risk_Line_Term__c r : DMT_Passport_Selector.getRiskLineTerm(dmtLine.DMT_Parent_Line__r.Line_Id__c)){
                endTerm = !String.isEmpty(r.DMT_End_Term__c) && endTerm < Integer.valueOf(r.DMT_End_Term__c) ? Integer.valueOf(r.DMT_End_Term__c) : endTerm;
            }

            DMT_Wrapper_Passport_Abs.ParentConsum der = new DMT_Wrapper_Passport_Abs.ParentConsum();
            der.productParent = '03';
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
        System.debug('log::handleOpportunityPayload');
        Account acc = DMT_Passport_Selector.getAccountWithRelatedListsFromOppId(recordId);
        Opportunity oppty = acc.Opportunities[0];

        Id rtIdDmtOpportunity = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId();

        DMT_Opportunity_Client__c oppClient;
        Account validationAccount = acc; // default → single holder

        if (oppty.DMT_MDE_Opportunities_Clients__r != null &&
            !oppty.DMT_MDE_Opportunities_Clients__r.isEmpty()) {

        // MULTIHOLDER
            if (oppty.Custom_Associations__r != null &&
                !oppty.Custom_Associations__r.isEmpty()) {

                String mainHolderCustomerId =
                    oppty.Custom_Associations__r[0].g_customer_id__c;

                for (DMT_Opportunity_Client__c clientRec :
                    oppty.DMT_MDE_Opportunities_Clients__r) {

                    if (clientRec.Alpha_Code_Client__c == mainHolderCustomerId) {
                        oppClient = clientRec;
                        break;
                    }
                }

            // Account main holder
                Account mainHolderAccount =
                DMT_Passport_Selector.getAccountFromCustomerId(mainHolderCustomerId);

                if (mainHolderAccount != null) {
                    validationAccount = mainHolderAccount;
                }

            } else {
                // Caso SINGLE HOLDER
            oppClient = oppty.DMT_MDE_Opportunities_Clients__r[0];
            }
        }

    if (oppClient != null && String.isNotBlank(oppClient.Alpha_Code_Client__c)) {
        recordCode = oppClient.Alpha_Code_Client__c;
    } else {
        recordCode = validationAccount.g_customer_id__c;
    }

    if (mapGroupsCache.isEmpty()) {
        mapGroupsCache = DMT_HPG_Utils.getGroupFromClientAccount(acc.Id);
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
        payloadMap.status = oppty.StageName;
        payloadMap.initDate = oppty.DMT_DATE_Initial_Date__c;
        payloadMap.endDate = oppty.DMT_DATE_Maturity_Date__c;
        payloadMap.currencyId = oppty.DMT_CurrencyText__c;

        DMT_PassportOpportunity_Wrapper.RequestBody body = new DMT_PassportOpportunity_Wrapper.RequestBody();
        body.client = buildOpportunityClientDetails(oppty,validationAccount, oppClient);
        body.opportunity = buildOpportunityDetails(oppty,oppClient);
        body.products= buildOpportunityProducts(oppty);
        body.analysts = buildOppAnalystDetails(oppty);
        body.templateType = oppty.RecordTypeId == rtIdDmtOpportunity ? 'TO' : null;
        for(DMT_PassportOpportunity_Wrapper.Product prdct : body.products){
            if(prdct.geographyBranch !=null){
                payloadMap.geographyBranch = prdct.geographyBranch;
                break;
            }
        }
        if(oppty.DMT_Sanction__c != null){
            body.opportunity.opportunitySanctions = buildOpportunitySanctions(oppty);
            System.debug('log::opportunitySanctions => ' + JSON.serialize(body.opportunity.opportunitySanctions));
        }
        body.features = new List<DMT_Wrapper_Passport_Abs.Feature> { calculateFeatureGenConsOpp(oppty,validationAccount, oppClient, clientsGroup) };

        body.optionalFeatures = calculateOptionalFeaturesOpp(oppty);
        body.documentsloads = buildDocumentLoads(oppty.CoreDocsTaxonomyValues__c);

        payloadMap.body = JSON.serialize(body,true);
        return JSON.serialize(payloadMap);
    }


    // Construcción de los detalles del cliente para oportunidades
    private static DMT_Wrapper_Passport_Abs.Client buildOpportunityClientDetails(Opportunity oppty,Account acc, DMT_Opportunity_Client__c oppClient) {
        DMT_Wrapper_Passport_Abs.Client client = new DMT_Wrapper_Passport_Abs.Client();
        client.customerId = recordCode;
        client.customerName = acc.Name;
        client.clientType = 'CORP';//acc.DES_Client_Type__c;
        client.shortRating = oppClient.External_Rating__c;
        client.sectorTypeId = oppClient.DMT_Sector__c;
        client.subsectorTypeId = oppClient.DMT_Subsector__c;
        client.activityTypeId = oppClient.DMT_Activity__c;
        client.thresholdType = oppty.DMT_Threshold_Type__c;
        client.scoring = oppClient.DMT_Scoring__c;
        client.industry = oppClient.DMT_Industry__c;
        client.camn = oppClient.DMT_CAMN__c;
        client.leveragedlending = oppClient.DMT_Leveraged_Lending__c;
        client.moodysExternalRating = oppClient.DMT_External_Rating_Moodys__c;
        client.spExternalRating = oppClient.DMT_External_Rating_SP__c;
        client.fitchExternalRating = oppClient.DMT_External_Rating_Fitch__c;
        client.sectorHead = oppClient.DMT_Sector_Head__c;
        client.guarantorNameFiscalId = oppClient.DMT_Guarantor_Name_Fiscal_ID__c;

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



        DMT_PassportOpportunity_Wrapper.Opportunity opp = new DMT_PassportOpportunity_Wrapper.Opportunity();
        opp.counterpart =oppClient.Counterpart__c;
        opp.avc=oppClient.AVC_Check__c;
        opp.europeanBank=oppClient.European_Bank_Check__c;
        opp.clientRating=oppClient.g_upd_lmscl_internal_ratg_type__c;
        opp.externalClientRating=oppClient.External_Rating__c;
        opp.clientBDI = oppClient.DMT_Client_Net_Incomes__c;
        opp.clientRWA = oppClient.DMT_Client_RWA__c;
        opp.scra=oppClient.SCRA__c;
        opp.currencyId = oppty.DMT_CurrencyText__c;
        opp.underwriting = oppty.underwriting_agreement_type__c;
        opp.opportunityAmount = oppty.DMT_CUR_Notional_Amount__c;
        opp.opportunityAmountEUR = DMT_Currency.convert(oppty.DMT_CUR_Notional_Amount__c, oppty.DMT_CurrencyText__c, 'EUR') != null? DMT_Currency.convert(oppty.DMT_CUR_Notional_Amount__c, oppty.DMT_CurrencyText__c, 'EUR').setScale(2) : null;
        opp.businessApprovedDate = oppty.DMT_Bussiness_Approved_Date__c;
        opp.tenor = oppty.DMT_Tenor__c;
        opp.productArea = oppty.DMT_Product_Area__c;
        opp.capitalAction = oppty.DMT_Capital_Action__c;
        opp.contingentCommitments = oppty.DMT_ContingentCommitments__c;
        opp.confidential = oppty.DMT_Confidential__c;
        opp.bookingGeography = oppty.DMT_branch_id_c__c;
        opp.bookingEFAN = oppty.DMT_Booking_EFAN__c;
        opp.sppiFileUploaded = oppty.DMT_SPPI_File_Uploaded__c;
        opp.sppiStatus = oppty.DMT_SPPI_Status__c;
        opp.sppiUser = oppty.DMT_SPPI_User__c;
        opp.financialSponsors = oppty.DMT_Financial_Sponsors__c;
        opp.structuredGTB    = oppty.DMT_Structured_GTB__c;
        opp.defenseDueDiligence = oppty.DMT_Defense_Due_Diligence__c;
        opp.credentials      = oppty.DMT_Credentials__c;
        opp.sustainableDeal    = oppClient.DMT_Sustainable_Deal__c;

        opp.opportunityAmountDealTotal = oppty.DMT_Opportunity_amount__c;
        opp.xsellCostToIncome = oppClient.DMT_Xsell_Cost_to_Income__c;

        if(oppClient.Group_Sales_Check__c==true){
            opp.groupSales = 1;
        }else{
            opp.groupSales = 0;
        }

        opp.xsells = buildBusinessPlanXsells(oppty.Id, oppty.DMT_CurrencyText__c);
        system.debug('funciona correctamente ->' +  opp.opportunityAmountEUR);
        system.debug('funciona correctamente ->' +  opp.opportunityAmount);
        return opp;

    }

    private static List<DMT_PassportOpportunity_Wrapper.Xsells> buildBusinessPlanXsells(Id opportunityId, String fallbackCurrency) {
        List<DMT_PassportOpportunity_Wrapper.Xsells> xsells = new List<DMT_PassportOpportunity_Wrapper.Xsells>();

        if (opportunityId == null) {
            return xsells;
        }

        List<DMT_Opportunity_Business_Plan__c> bpRecords = DMT_Passport_Selector.getGlobalBusinessPlansByOpportunity(opportunityId);

        for (DMT_Opportunity_Business_Plan__c bp : bpRecords) {
            Integer year = Integer.valueOf(bp.DMT_Year__c);
            String currencyId = String.isNotBlank(bp.DMT_Currency__c) ? bp.DMT_Currency__c : fallbackCurrency;
            addBusinessPlanXsellIfValid(xsells, year, bp.Current_FY_Total_X_Sell_amount__c, currencyId);
        }

        return xsells;
    }

    private static void addBusinessPlanXsellIfValid(List<DMT_PassportOpportunity_Wrapper.Xsells> xsells, Integer year, Decimal amount, String currencyId) {
        if (amount != null && amount != 0 && String.isNotBlank(currencyId)) {
            xsells.add(buildBusinessPlanXsell(year, amount, currencyId));
        }
    }

    private static DMT_PassportOpportunity_Wrapper.Xsells buildBusinessPlanXsell(Integer year, Decimal amount, String currencyId) {
        DMT_PassportOpportunity_Wrapper.Xsells xs = new DMT_PassportOpportunity_Wrapper.Xsells();
        xs.year = year;
        xs.amount = amount;
        xs.currencyId = currencyId;
        return xs;
    }

    private static List<DMT_PassportOpportunity_Wrapper.Product> buildOpportunityProducts(Opportunity oppty) {
        List<OpportunityLineItem> oppLineItems = oppty.OpportunityLineItems;
        Map<Id, List<DMT_Opportunity_Mitigant__c>> mitigantsMap = buildMitigantsMap(oppLineItems);
        Map<String, String> tax895Map = buildTaxonomyMap(mitigantsMap);
        Map<Id, List<DMT_Opportunity_Tenor__c>> amortizationPayMap = buildAmortizationMap(oppLineItems);
        Map<Id, List<DMT_Underlying__c>> underlyingsMap = buildUnderlyingsMap(oppLineItems);
        Map<String, String> groupCountryRiskMap = buildGroupCountryRiskMap(oppLineItems);
        Map<String, String> underlyingTaxonomyMap = buildUnderlyingTaxonomyMap(underlyingsMap);

        List<DMT_PassportOpportunity_Wrapper.Product> products = new List<DMT_PassportOpportunity_Wrapper.Product>();
        for (OpportunityLineItem opplitem : oppLineItems) {
            products.add(buildProduct(opplitem, mitigantsMap, underlyingsMap, tax895Map, amortizationPayMap, groupCountryRiskMap, oppty, underlyingTaxonomyMap));
        }

        return products;
    }

    private static Map<String, String> buildUnderlyingTaxonomyMap(Map<Id, List<DMT_Underlying__c>> underlyingsMap) {
        Set<String> underlyingNames = new Set<String>();
        for (List<DMT_Underlying__c> uls : underlyingsMap.values()) {
            for (DMT_Underlying__c ul : uls) {
                if (String.isNotBlank(ul.Name)) {
                    underlyingNames.add(ul.Name);
                }
            }
        }
        Map<String, String> nameToTaxValueMap = new Map<String, String>();
        for (DMT_Taxonomy_Values__c tv : DMT_Passport_Selector.getUnderlyingTaxonomyByNames(underlyingNames)) {
            if (!nameToTaxValueMap.containsKey(tv.DMT_Name_EN__c)) {
                nameToTaxValueMap.put(tv.DMT_Name_EN__c, tv.gf_catalog_atrb_val1_name_c__c);
            }
        }
        return nameToTaxValueMap;
    }

    private static Map<String, String> buildGroupCountryRiskMap(List<OpportunityLineItem> oppLineItems) {
        Map<String, String> groupCountryRiskMap = new Map<String, String>();
        Set<String> countryRiskValues = new Set<String>();

        for (OpportunityLineItem opplitem : oppLineItems) {
            if (String.isNotBlank(opplitem.gf_country_risk__c)) {
                countryRiskValues.add(opplitem.gf_country_risk__c);
            }
        }

        if (countryRiskValues.isEmpty()) {
            return groupCountryRiskMap;
        }

        List<DMT_Taxonomy_Relationship__c> relationships = DMT_Passport_Selector.getCountryRiskRelationships(countryRiskValues);
        Map<String, String> finalValueByInitialValue = new Map<String, String>();
        Set<String> finalCatalogValues = new Set<String>();

        for (DMT_Taxonomy_Relationship__c relation : relationships) {
            if (String.isNotBlank(relation.DMT_Value_Catalog_Initial__c) && String.isNotBlank(relation.DMT_Value_Catalog_Final__c)) {
                if (!finalValueByInitialValue.containsKey(relation.DMT_Value_Catalog_Initial__c)) {
                    finalValueByInitialValue.put(relation.DMT_Value_Catalog_Initial__c, relation.DMT_Value_Catalog_Final__c);
                }
                finalCatalogValues.add(relation.DMT_Value_Catalog_Final__c);
            }
        }

        if (finalCatalogValues.isEmpty()) {
            return groupCountryRiskMap;
        }

        List<DMT_Taxonomy_Values__c> taxonomyValues = DMT_Passport_Selector.getTaxonomyValuesByCatalogAndValues('I076', finalCatalogValues);
        Map<String, String> nameByValue = new Map<String, String>();

        for (DMT_Taxonomy_Values__c taxonomyValue : taxonomyValues) {
            if (String.isNotBlank(taxonomyValue.DMT_Value__c) && String.isNotBlank(taxonomyValue.DMT_Name_EN__c)) {
                nameByValue.put(taxonomyValue.DMT_Value__c, taxonomyValue.DMT_Name_EN__c);
            }
        }

        for (String countryRiskValue : finalValueByInitialValue.keySet()) {
            String finalCatalogValue = finalValueByInitialValue.get(countryRiskValue);
            groupCountryRiskMap.put(countryRiskValue, nameByValue.get(finalCatalogValue));
        }

        return groupCountryRiskMap;
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

    private static Map<Id, List<DMT_Underlying__c>> buildUnderlyingsMap(List<OpportunityLineItem> oppLineItems) {
        List<DMT_Underlying__c> underlyings = new List<DMT_Underlying__c>();
        for (OpportunityLineItem oli : oppLineItems) {
            if (oli.Underlyings__r != null && !oli.Underlyings__r.isEmpty()) {
                underlyings.addAll(oli.Underlyings__r);
            }
        }

        Map<Id, List<DMT_Underlying__c>> underlyingsMap = new Map<Id, List<DMT_Underlying__c>>();
        for (DMT_Underlying__c underlying : underlyings) {
            if (underlyingsMap.containsKey(underlying.DMT_Opportunity_Product__c)) {
                underlyingsMap.get(underlying.DMT_Opportunity_Product__c).add(underlying);
            } else {
                underlyingsMap.put(underlying.DMT_Opportunity_Product__c, new List<DMT_Underlying__c>{underlying});
            }
        }

        return underlyingsMap;
    }

    private static DMT_PassportOpportunity_Wrapper.Product buildProduct(OpportunityLineItem opplitem, Map<Id, List<DMT_Opportunity_Mitigant__c>> mitigantsMap, Map<Id, List<DMT_Underlying__c>> underlyingsMap, Map<String, String> tax895Map, Map<Id, List<DMT_Opportunity_Tenor__c>> amortizationPayMap, Map<String, String> groupCountryRiskMap, Opportunity oppty, Map<String, String> underlyingTaxonomyMap) {
        DMT_PassportOpportunity_Wrapper.Product product = new DMT_PassportOpportunity_Wrapper.Product();
        product.name = opplitem.DMT_TXT_ProductNameOLI__c;
        product.geographyBranch = opplitem.g_branch_id__c;
        product.initDate = opplitem.gf_initial_date__c;
        product.endDate = opplitem.gf_maturity_date__c;
        product.currencyId = opplitem.g_currency_id__c;
        product.productId = opplitem.gf_group_priority_opportunity_id__c;
        product.useOfProceeds = opplitem.loan_purpose_desc__c;
        product.TXTComentarios = opplitem.DMT_TXT_Comentarios__c;
        product.lastLevelId = opplitem.DMT_Risk_Type__c;
        product.businessArea = oppty.DMT_Product_Area__c;
        product.committedLine = opplitem.g_line_commitment_level_type__c;
        product.prco = opplitem.ProductCode;
        product.intermediateDate = opplitem.gf_intermediate_date__c;
        product.countryRisk = opplitem.gf_country_risk__c;
        product.groupCountryRisk = groupCountryRiskMap.get(opplitem.gf_country_risk__c);
        product.crr2 = String.valueOf(opplitem.gf_crr2_essential_public_services__c);
        product.countryRating = opplitem.gf_country_rating__c;
        product.tenorAmount = opplitem.bbva_prtcp_tranche_amount__c;
        product.committedUncommitted = opplitem.DMT_Line_LC_LNC__c;
        product.lineOneOffDeal = opplitem.DMT_Line_Oneoffdeal__c;

        product.funding = buildFunding(opplitem);
        product.mitigants = buildMitigants(opplitem.Id, mitigantsMap, tax895Map);
        product.amortization = buildAmortization(opplitem, amortizationPayMap.get(opplitem.Id));
        product.amortization.underlyings = buildUnderlyings(opplitem.Id, underlyingsMap, underlyingTaxonomyMap);
        product.liquidityFee = opplitem.DMT_Liquidity_Fee__c;
        product.dealAmount = opplitem.DMT_Deal_amount__c;
        product.roleType = opplitem.entity_role_type__c;
        product.subLimit = opplitem.DMT_Sub_Limit__c;

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
        funding.sustainableDeal = opplitem.DMT_sustainable_deal_assessment__c;
        funding.sustainableDealSubcategory = opplitem.DMT_Sustainable_Deal_Subtype__c;
        funding.sustainableDealLabel = opplitem.DMT_sustainable_deal_value__c;
        funding.sustainableDelegatedFilter = opplitem.DMT_Sustainability_deal_value_criteria__c;
        funding.sustainabilityPercentage = opplitem.DMT_PER_Sustainability_Percentage__c;
        funding.sustainabilityBonus = opplitem.DMT_Sustainability_bonus_eligible__c;
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
                mitigant.mitigantCounterpart = String.isBlank(mt.Counterpart__c) ? 'Corporates' : mt.Counterpart__c;
                mitigant.mitigantRating = mt.Internal_Rating__c;
                mitigant.ratingExternal = mt.External_Rating__c;
                mitigant.mitigantScra = mt.SCRA__c;
                mitigant.mitigantLiquidationPeriod = mt.Liquidation_Period__c;
                mitigant.mitigantEndDate = mt.End_Date__c;
                mitigant.mitigantCurrency = mt.DMT_Currency__c;
                mitigant.commercialRisk = mt.Commercial_Percentage__c;
                mitigant.politicalRisk = mt.Political_Percentage__c;
                //mitigant.eca = mt.Garantor_European_ECA__c; //CIBGLOBALD-3497
                mitigant.mitigantCountry = mt.DMT_Country_Guarantor__c;
                mitigant.customerId = mitigantClientCode; //CIBGLOBALD-2027
                mitigant.scoring = mt.DMT_Scoring__c;
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
        amortization.rateType = RATE_TYPE_MAPPING.containsKey(opplitem.DMT_RateType__c) ? RATE_TYPE_MAPPING.get(opplitem.DMT_RateType__c) : opplitem.DMT_RateType__c;
        amortization.payments = new List<DMT_PassportOpportunity_Wrapper.AmortizationPayments>();
        amortization.newMoney = opplitem.DMT_NewMoney_BBVA__c;
        amortization.oldmoney = opplitem.DMT_OldMoney_BBVA__c;
        amortization.expectedFinalTake = opplitem.syndicated_loan_drawn_amount__c;
        amortization.pricinggridOrstepUp = opplitem.DMT_PricingGrid_OR_StepUps__c;
        amortization.extensionDurationFees = opplitem.DMT_Extension_Duration_Fees__c;
        amortization.expectedDrawn = opplitem.DMT_Expected_Drawn__c;
        amortization.bullet = opplitem.DMT_bullet_amortization_indicator__c;
        amortization.balloon = opplitem.DMT_balloon_amortization_indicator__c;

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

    private static Map<String, Map<String, String>> termPicklistLabelsCache = new Map<String, Map<String, String>>();

    private static Map<String, String> getTermPicklistLabels(String fieldApiName) {
        if (!termPicklistLabelsCache.containsKey(fieldApiName)) {
            Map<String, String> labels = new Map<String, String>();
            Schema.DescribeFieldResult fieldDescribe = DMT_Underlying__c.SObjectType.getDescribe().fields.getMap().get(fieldApiName).getDescribe();
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                if (String.isNotBlank(entry.getValue())) {
                    labels.put(entry.getValue(), entry.getLabel());
                }
            }
            termPicklistLabelsCache.put(fieldApiName, labels);
        }
        return termPicklistLabelsCache.get(fieldApiName);
    }

    private static Date calculateUnderlyingEndDate(Date referenceDate, String termValue, String fieldApiName) {
        if (referenceDate == null) {
            return null;
        }
        if (String.isBlank(termValue)) {
            return referenceDate;
        }

        String label = getTermPicklistLabels(fieldApiName).get(termValue);
        if (String.isBlank(label)) {
            return referenceDate.addDays(Integer.valueOf(termValue));
        }

        Matcher m = Pattern.compile('^([0-9]+(?:,[0-9]+)?)\\s*(week|month|year)').matcher(label.toLowerCase().trim());
        if (!m.find()) {
            return referenceDate.addDays(Integer.valueOf(termValue));
        }

        Decimal quantity = Decimal.valueOf(m.group(1).replace(',', '.'));
        String unit = m.group(2);

        if (unit == 'week') {
            return referenceDate.addDays((quantity * 7).intValue());
        }
        if (unit == 'year') {
            Boolean isWholeYears = Math.mod((quantity * 100).intValue(), 100) == 0;
            return isWholeYears ? referenceDate.addYears(quantity.intValue()) : referenceDate.addMonths((quantity * 12).intValue());
        }
        return referenceDate.addMonths(quantity.intValue());
    }

    private static List<DMT_PassportOpportunity_Wrapper.Underlying> buildUnderlyings(Id productId, Map<Id, List<DMT_Underlying__c>> underlyingsMap, Map<String, String> underlyingTaxonomyMap) {
        List<DMT_PassportOpportunity_Wrapper.Underlying> underlyings = new List<DMT_PassportOpportunity_Wrapper.Underlying>();
        if (underlyingsMap.get(productId) != null) {
            for (DMT_Underlying__c ul : underlyingsMap.get(productId)) {
                DMT_PassportOpportunity_Wrapper.Underlying underlying = new DMT_PassportOpportunity_Wrapper.Underlying();
                // New fields
                underlying.underlyingId = ul.Id;
                underlying.underlyingPrco = underlyingTaxonomyMap.get(ul.Name);
                underlying.underlyingInitDate = ul.CreatedDate.date();
                // Calculate endDate and term based on underlyingType
                String termFieldApiName = ul.DMT_Underlying_Type__c == 'Restriction' ? 'DMT_Max_Term__c' : 'DMT_Term__c';
                String termValue = ul.DMT_Underlying_Type__c == 'Restriction' ? ul.DMT_Max_Term__c : ul.DMT_Term__c;
                underlying.term = termValue;
                underlying.underlyingEndDate = calculateUnderlyingEndDate(ul.CreatedDate.date(), termValue, termFieldApiName);
                // Existing fields
                underlying.amortizationType = ul.DMT_Amortization_Type__c;
                underlying.currencyId = ul.DMT_Currency__c;
                underlying.nominalDrawn = ul.DMT_Drawn_Reference_Amount__c;
                underlying.spreadDrawn = ul.DMT_Drawn_Speed__c;
                underlying.interestPaymentFrequency = ul.DMT_Interest_Payment_Frequency__c;
                underlying.maxAmount = ul.DMT_Max_Amount__c;
                underlying.maxTerm = ul.DMT_Max_Term__c;
                underlying.otherRestrictions = ul.DMT_Other_restrictions__c;
                underlying.underlyingType = ul.DMT_Underlying_Type__c;
                underlying.nominalUndrawn = ul.DMT_Undrawn_Reference_Amount__c;
                underlying.spreadUndrawn = ul.DMT_Undrawn_Spread__c;
                underlying.fees = ul.DMT_Upfront_Fees__c;
                underlying.upfrontFeesAmount = ul.DMT_Upfront_Fees_amount__c;
                underlyings.add(underlying);
            }
        }
        return underlyings;
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
                    pl.productId = oli.Id;
                    productsLineList.add(pl);
                }
            }
        }

        oppSanctions.productsLine = productsLineList;
        oppSanctions.businessApprovedDateStartDate = oppty.DMT_Sanction__r.DMT_Bussiness_Approved_Date__c;
        oppSanctions.businessApprovedDateEndDate = oppty.DMT_Sanction__r.DMT_Business_Approved_End_Date__c;
        oppSanctions.riskStartDate = oppty.DMT_Sanction__r.Start_Date__c;
        oppSanctions.riskEndDate = oppty.DMT_Sanction__r.End_Date__c;
        oppSanctions.newApproval = (oppty.DMT_Sanction__r.DMT_Opportunity__c == oppty.Id);

        return new List<DMT_PassportOpportunity_Wrapper.OpportunitySanctions>{ oppSanctions };
    }

    // Métodos auxiliares
    private static String userId(String recordId) {
        if (recordId != null && objectNameById(recordId) == User.getSObjectType().getDescribe().getName()) {
            User u = [SELECT Id, FederationIdentifier FROM User WHERE Id = :recordId WITH USER_MODE];
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
            if (validation.state == DMT_Constants.FEATURE_GC_STATE_YELLOW) {
                featureBody.stateName = DMT_Constants.FEATURE_GC_STATE_YELLOW;
            }
            else if (validation.state == DMT_Constants.FEATURE_GC_STATE_RED) {
                featureBody.stateName = DMT_Constants.FEATURE_GC_STATE_RED;
                break;
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

    public static DMT_Wrapper_Passport_Abs.Feature calculateFeatureGenConsOpp(Opportunity opp,Account validationAccount,DMT_Opportunity_Client__c oppClient, String clientsGroup) {
        DMT_Wrapper_Passport_Abs.Feature featureBody = new DMT_Wrapper_Passport_Abs.Feature();
        featureBody.id = '200';
        featureBody.name = DMT_Constants.FEATURE_GC_NAME;
        featureBody.passportSanction = DMT_Constants.FEATURE_GC_PASSPORTSANCTION;
        featureBody.active = DMT_Constants.FEATURE_GC_ACTIVE;
        featureBody.motorDesc = DMT_Constants.FEATURE_GC_MOTORDESC;
        featureBody.stateName = DMT_Constants.FEATURE_GC_STATE_GREEN;
        //featureBody.validations = new List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations>();
        featureBody.validations = DMT_OppFeatureGenCons_Calc.checkValidations(opp, validationAccount,oppClient, clientsGroup);

         for (DMT_Wrapper_Passport_Abs.FeatureGenConsiderations validation : featureBody.validations) {
            if (validation.state != DMT_Constants.FEATURE_GC_STATE_GREEN) {
                featureBody.stateName = DMT_Constants.FEATURE_GC_STATE_YELLOW;
            }
        }

        return featureBody;
    }

    public static List<DMT_Wrapper_Passport_Abs.OptionalFeatures> calculateOptionalFeaturesOpp(Opportunity oppty) {
        List<DMT_Selected_Features__c> selectedFeatures = DMT_Passport_Selector.getSelectedFeaturesOPP(oppty.Id);

        List<DMT_Wrapper_Passport_Abs.OptionalFeatures> optionalFeaturesList = new List<DMT_Wrapper_Passport_Abs.OptionalFeatures>();
        for (DMT_Selected_Features__c feature : selectedFeatures) {
            DMT_Wrapper_Passport_Abs.OptionalFeatures optionalFeature = new DMT_Wrapper_Passport_Abs.OptionalFeatures();
            optionalFeature.id = feature.Feature__r.gf_code_value_id__c;
            optionalFeaturesList.add(optionalFeature);
        }
        return optionalFeaturesList;
    }

    //CIBGLOBALD-1195 parameter is added to the method
    public static Case createCase(DMT_Line__c line, Opportunity opp, Id aproverId,String featureId, String featureName,List<Map<String, Object>> taskList, String comment, String passportSanction) {

        Case newCase = new Case();
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(DMT_Constants.CASE_RT_APPROVAL).getRecordTypeId();
        //DMT_Passport_Selector.getRecordTypeId('Approval','Case');
        newCase.OwnerId = aproverId;
        newCase.Status = 'Pending';
        //CIBGLOBALD-1453 create case Opportunidad
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

        // Renovación: solo si la línea/opp tiene padre (es renovación), asignar el ParentId del Case correspondiente
        Boolean isLineRenewal = line != null && line.DMT_Parent_Line__c != null;
        Boolean isOppRenewal  = opp  != null && opp.DMT_Parent_Opportunity__c != null;
        if (String.isNotBlank(featureId) && (isLineRenewal || isOppRenewal)) {
            System.debug('###RENEWAL### createCase - featureId=' + featureId + ' line=' + (line != null ? line.Id : null) + ' opp=' + (opp != null ? opp.Id : null));
            Id parentId = isLineRenewal ? line.DMT_Parent_Line__c : opp.DMT_Parent_Opportunity__c;
            System.debug('###RENEWAL### parentId=' + parentId);
            List<Case> parentCase = DMT_Passport_Selector.getCaseByLineFeature(parentId, featureId);
            System.debug('###RENEWAL### parentCase size=' + parentCase.size());
            if (!parentCase.isEmpty()) {
                newCase.ParentId = parentCase[0].Id;
                System.debug('###RENEWAL### ParentId assigned=' + newCase.ParentId);
            }
        }

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

        HttpResponse response;
        String serviceName;

        if(objectName == Opportunity.getSObjectType().getDescribe().getName() ){
            serviceName='DMTO_EvaluationOpportunity';

        } else if(objectName == DMT_Line__c.getSObjectType().getDescribe().getName()){
            serviceName='DMTO_EvaluationLine';
        }
        response = DMT_HPG_Utils.callService(serviceName, requestMap);

        if( (response.getStatusCode() == 200 || response.getStatusCode() == 201) ) {
            if(objectName == Opportunity.getSObjectType().getDescribe().getName() ){
                Opportunity oppToUpdate = new Opportunity();
                oppToUpdate.Id = passport.Opportunity__c;
                oppToUpdate.DMT_Requested_Passport__c = true;

                update oppToUpdate;
            }

                String bodyResponse = response.getBody();

                bodyResponse = bodyResponse.replaceAll('@date', Datetime.now().format('yyyy-MM-dd HH:mm:ss'));

                // Enrich every feature's validation message (when it lists multiple missing fields
                // separated by commas) with a "fieldsRequired" map grouped by UI tab, so the front-end
                // can highlight the missing fields in YELLOW.
                bodyResponse = enrichMissingFields(bodyResponse);

                outMap.put('payload', bodyResponse);
                // 2. Return the state of the flag
                outMap.put('isObsolete', false);

                passport.DMT_Is_Obsoleted_Passport_Save__c = false;
                passport.DMT_Passport_Save__c = bodyResponse;

                update passport;
                //callPassportClosedWon(passport.DMT_Line__c);

                // New logic for non-mandatory proposal/passport features
                cancelNonMandatoryProposalWorkflows(passport, bodyResponse, objectName);

                // Update rentability fields on Opportunity and OpportunityLineItems
                if (objectName == Opportunity.getSObjectType().getDescribe().getName() && passport.Opportunity__c != null) {
                    DMT_PassportProfitabilityProcessor.updateProfitabilityFields(passport.Opportunity__c, bodyResponse);
                }
        } else {
            outMap.put('payload', null);
            outMap.put('isObsolete', true);
            outMap.put('result', false);
            outMap.put('message', Label.OpportunityServiceError);
        }
    }

    // Feature names whose validations are eligible for fieldsRequired enrichment. Not every feature
    // encodes its missing fields the same way (comma-separated field paths), so enrichment is
    // opt-in per feature name. Add new feature names here as they adopt the same message format.
    private static final Set<String> FIELDS_REQUIRED_ELIGIBLE_FEATURES = new Set<String>{
        'Profitability Engine'
    };

    /**
     * @description Enrichment applied to the raw Passport evaluation service JSON response, restricted
     * to the features listed in FIELDS_REQUIRED_ELIGIBLE_FEATURES (currently "Profitability Engine"),
     * since other features may not follow the same comma-separated field-path message format.
     * For each eligible feature it inspects every validation's "message" and passes it as-is to
     * DMT_FieldsRequiredParser.parse(). The result (possibly an empty map, if no field in the
     * message resolves to an active DMT_FieldsRequiredPassport__mdt record) always overwrites the
     * feature's "fieldsRequired" key, so a stale value from a previous enrichment run never
     * survives. The original "message" is left untouched.
     * If the JSON cannot be parsed, or the expected structure ("data.features") is not present, the
     * original body is returned unchanged.
     * @param jsonBody raw JSON response from the passport evaluation service
     * @return String enriched JSON (or the original jsonBody on any parsing issue)
     */
    public static String enrichMissingFields(String jsonBody) {
        if (String.isBlank(jsonBody)) {
            return jsonBody;
        }

        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            Map<String, Object> dataMap = root != null ? (Map<String, Object>) root.get('data') : null;

            if (dataMap == null || !dataMap.containsKey('features')) {
                return jsonBody;
            }

            List<Object> rawFeatures = (List<Object>) dataMap.get('features');
            if (rawFeatures == null) {
                return jsonBody;
            }

            for (Object featureObj : rawFeatures) {
                if (!(featureObj instanceof Map<String, Object>)) {
                    continue;
                }

                Map<String, Object> featureMap = (Map<String, Object>) featureObj;
                String featureName = (String) featureMap.get('name');

                if (!FIELDS_REQUIRED_ELIGIBLE_FEATURES.contains(featureName)) {
                    continue;
                }

                List<Object> rawValidations = (List<Object>) featureMap.get('validations');
                if (rawValidations == null) {
                    continue;
                }

                for (Object validationObj : rawValidations) {
                    if (!(validationObj instanceof Map<String, Object>)) {
                        continue;
                    }

                    Map<String, Object> validationMap = (Map<String, Object>) validationObj;
                    String message = (String) validationMap.get('message');

                    Map<String, Object> fieldsRequired = DMT_FieldsRequiredParser.parse(message);

                    // Always overwrite (even with an empty map) so a stale "fieldsRequired" value
                    // from a previous enrichment run never survives when the current message no
                    // longer resolves to any active DMT_FieldsRequiredPassport__mdt record.
                    featureMap.put('fieldsRequired', fieldsRequired);
                }
            }

            return JSON.serialize(root);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'DMT_Passport_Helper.enrichMissingFields error: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            return jsonBody;
        }
    }

    /**
     * @description
        * Cancela el workflow (Tasks + Cases) de features de tipo proposal (passport) cuando la Opportunity está en estado 'Ready to close'
        * y la feature llega congelada desde Passport (indicatorId = 'Y').
     *
     * Lógica:
     * - Solo se aplica para el passport de Opportunity
        * - Se identifican las features en las que passportSanction = 'passport' e indicatorId = 'Y'
     * - Para esas features se buscan Cases activos (Status != 'Finished') y Tasks activas asociadas a ellos. Primero se cancelan las Tasks (Status = 'Cancelled') y después se finalizan los Cases (Status = 'Finished')
     */
    public static void cancelNonMandatoryProposalWorkflows(Passport__c passport, String bodyResponse, String objectName) {

        try {
            // Solo se ejecuta si es Opportunity
            if (objectName != Opportunity.getSObjectType().getDescribe().getName()) {
                return;
            }

            // Se valida que hay Passport y Opportunity
            if (passport == null || passport.Opportunity__c == null) {
                return;
            }

            // Se obtiene el estado actual de la Opportunity
            Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :passport.Opportunity__c LIMIT 1];

            // La lógica solo aplica cuando el estado es 'Ready to close'
            Boolean isReadyToClose = opp.StageName == 'Ready to close';

            if (!isReadyToClose) {
                return;
            }

            // Se valida que el JSON exista
            if (String.isBlank(bodyResponse)) {
                return;
            }

            // Se parsea la respuesta del servicio
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(bodyResponse);
            if (root == null || !root.containsKey('data')) {
                return;
            }

            Map<String, Object> dataMap = (Map<String, Object>) root.get('data');
            if (dataMap == null || !dataMap.containsKey('features')) {
                return;
            }

            List<Object> rawFeatures = (List<Object>) dataMap.get('features');
            if (rawFeatures == null || rawFeatures.isEmpty()) {
                return;
            }

            Set<String> frozenProposalFeatureIds = new Set<String>();

            for (Object featureObj : rawFeatures) {
                if (!(featureObj instanceof Map<String, Object>)) {
                    continue;
                }

                Map<String, Object> featureMap = (Map<String, Object>) featureObj;

                String sanction = (String) featureMap.get('passportSanction');
                sanction = sanction != null ? sanction.trim().toLowerCase() : null;
                Object featureIdObj = featureMap.get('id');

                String indicatorId = (String) featureMap.get('indicatorId');
                indicatorId = indicatorId != null ? indicatorId.trim().toUpperCase() : null;
                Boolean isFrozenFeature = indicatorId == 'Y';

                // Solo interesan las features congeladas de passport o approval
                Boolean isCancellableSanction = sanction == 'passport' || sanction == 'approval';
                if (featureIdObj != null && isCancellableSanction && isFrozenFeature) {
                    frozenProposalFeatureIds.add(String.valueOf(featureIdObj));
                }
            }

            // Se valida que existan features de tipo proposal congeladas
            if (frozenProposalFeatureIds.isEmpty()) {
                return;
            }

            // Se obtienen Cases activos de esas features
            List<Case> activeCases = DMT_Passport_Selector.getActiveProposalCasesByOpportunityAndFeatureIds(passport.Opportunity__c, frozenProposalFeatureIds);

            if (activeCases.isEmpty()) {
                return;
            }

            Set<Id> caseIds = new Set<Id>();
            for (Case activeCase : activeCases) {
                caseIds.add(activeCase.Id);
            }

            // Se obtienen Tasks activas de esos Cases
            List<Task> activeTasks = DMT_Passport_Selector.getActiveTasksByCaseIds(caseIds);

            // Se cancelan Tasks
            if (!activeTasks.isEmpty()) {
                for (Task activeTask : activeTasks) {
                    activeTask.Status = 'Cancelled';
                }
                update activeTasks;
            }

            // Se finalizan Cases
            for (Case activeCase : activeCases) {
                activeCase.Status = 'Finished';
            }
            update activeCases;

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            DES_Exception_Utils.logException(e,'DMT_Passport_Helper', 'cancelNonMandatoryProposalWorkflows', 'DMT', '');
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
        }
        return JSON.serialize(payload);
    }

    public static void callConsumptionLimitService(Map<String, Object> requestMap, Map<String, Object> outMap) {
        HttpResponse response;
        String serviceName='DMT_PUT_OpportunityConsumptionLimit';
        response = DMT_HPG_Utils.callService(serviceName, requestMap);
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

    // --- Helper method to parse CoreDocs Taxonomies ---
    public static List<DMT_Wrapper_Passport_Abs.DocumentLoad> buildDocumentLoads(String taxonomyValues) {
        List<DMT_Wrapper_Passport_Abs.DocumentLoad> docs = new List<DMT_Wrapper_Passport_Abs.DocumentLoad>();
        if (String.isNotBlank(taxonomyValues)) {
            for (String val : taxonomyValues.split(',')) {
                if (String.isNotBlank(val)) {
                    DMT_Wrapper_Passport_Abs.DocumentLoad doc = new DMT_Wrapper_Passport_Abs.DocumentLoad();
                    doc.itemType = val.trim();
                    docs.add(doc);
                }
            }
        }
        return docs.isEmpty() ? null : docs;
    }

    public static Map<String, Object> resolveMainHolderAccountId(Id oppId) {
        Map<String, Object> result = new Map<String, Object>();
        Id accountId;
        String clientType;

        Custom_Association_Opportunity__c assoc = DMT_Passport_Selector.getMainHolderAssociation(oppId);
        if (assoc != null && String.isNotBlank(assoc.g_customer_id__c)) {
            Account mainHolder = DMT_Passport_Selector.getAccountFromCustomerId(assoc.g_customer_id__c);
            if (mainHolder != null) {
                accountId = mainHolder.Id;
                clientType = mainHolder.DES_Client_Type__c;
            } else {
                accountId = assoc.Opportunity__r.AccountId;
            }
        } else {
            accountId = DMT_Passport_Selector.getOpportunityAccountId(oppId);
        }

        if (clientType == null && accountId != null) {
            Account acc = DMT_Passport_Selector.getAccountById(accountId);
            clientType = acc != null ? acc.DES_Client_Type__c : null;
        }

        result.put('AccountId', accountId);
        result.put('ClientType', clientType);
        return result;
    }
}