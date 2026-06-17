/**-------------------------------------------------------------------------------------------
* @Name     DMT_RiskPositionLine_Helper
* @Author   Javier Portilla <javieralberto.portilla.contractor@bbva.com>
* @Date     Created: 2025-09-02
* --------------------------------------------------------------------------------------------
* @Description Clase que arma el JSON para el envio de risk position y se comunica con el servicio
* de IASO para enviar la data.
* --------------------------------------------------------------------------------------------
*/
public with sharing class DMT_RiskPositionLine_Helper {

    /**
     * Builds the DMTO_RiskPositionLine request JSONs in BULK.
     * Returns a Map where the key is the Line Id and the value is the list of payloads.
     */
    public static Map<Id, LinePayloadContext> buildPayloadsBulk(List<Id> inputIds, String payloadVersion) {
        Map<Id, LinePayloadContext> resultPayloads = new Map<Id, LinePayloadContext>();

        if (inputIds == null || inputIds.isEmpty()) return resultPayloads;

        // --- SAFETY NET ---
        // Verify the object type using the first ID in the list
        Id firstId = inputIds[0];
        String objectName = objectNameById(firstId);
        
        if (String.isBlank(objectName)) return resultPayloads;

        // Resolve child IDs to DMT_Line__c IDs if necessary
        List<Id> listLineId = (objectName != 'DMT_Line__c') ? getLineIds(objectName, new Set<Id>(inputIds)) : inputIds;

        if (listLineId.isEmpty()) return resultPayloads;
        // ------------------

        // Retrieve the multiOp map using the bulkified list of IDs
        Map<String, String> multiOpMap = getMultiOp(new Set<Id>(listLineId));

        // Retrieve line info in bulk
        List<DMT_Line__c> lineInfo = getLineInfo(listLineId);

        if (lineInfo.isEmpty()) return resultPayloads;

        // ===== BULK DATA LOAD =====
        Set<Id> lineIds = new Map<Id, DMT_Line__c>(lineInfo).keySet();

        // Get Custom Associations
        Map<String, List<Custom_Association__c>> assocByLine = getCustomAssocByLines(lineIds);

        // Get Custom Assoc Client
        Set<Id> assocIds = new Set<Id>();
        for (List<Custom_Association__c> lst : assocByLine.values()) {
            for (Custom_Association__c a : lst) assocIds.add(a.Id);
        }
        Map<Id, List<Custom_Association_Client__c>> assocCliByAssoc = getCustomAssocClientsByAssoc(assocIds);

        // Get Risk Line terms
        Map<Id, List<DMT_Risk_Line_Term__c>> termsByLine = getRiskLineTermsByLines(lineIds);

        // Provisions / Warranties per term
        Set<Id> termIds = new Set<Id>();
        for (List<DMT_Risk_Line_Term__c> lst : termsByLine.values()) {
            for (DMT_Risk_Line_Term__c t : lst) termIds.add(t.Id);
        }

        // Get currency provisions
        Map<Id, List<DMT_Currency_Provision__c>> currByTerm = getCurrencyProvisionsByTerms(termIds);
        
        // Get Warranties
        Map<Id, List<DMT_Warranty__c>> wntByTerm = getWarrantiesByTerms(termIds);

        // Build payloads for each line
        for (DMT_Line__c ln : lineInfo) {

            // JSON Root
            Root root = new Root();
            root.products = new List<Product>();

            root.opportunityId         = ln.Line_Id__c;
            root.status                = ln.g_line_status_type__c == 'TD' ? 'TD' : ln.DMT_line_status_type__c;
            root.templateType          = ln.DMT_line_template_type__c;
            root.initDate              = formatDateToString(ln.Start_date__c);
            root.endDate               = formatDateToString(ln.End_Date__c);
            root.entificId             = ln.Booking_Geography__c;
            root.entityId              = ln.DMT_Entity__c;
            root.name                  = ln.Name;
            root.commitmentLevelType  = ln.g_line_commitment_level_type__c;  
            root.updateDate           = ln.LastModifiedDate?.format('yyyy-MM-dd hh:mm:ss');
            root.originApplicationType = ln.gf_origin_application_type__c;

            // ---- Client
            root.client = new Client();
            
            if(ln.Client_Type__c == 'Customer'){
                root.client.customerId = ln.Client_Code__c;
                root.client.groupId = ln.Client__r?.DES_Main_Parent__r?.DES_Group_Code__c;
                root.client.groupName = ln.Client__r?.Parent_Account_Name__c;
            } else {
                root.client.groupId = ln.Client__r?.DES_group_Code__c;
                root.client.groupName = ln.Client__r?.Name;
            }

            if(assocByLine.containsKey(ln.Line_id__c)){
                for(Custom_Association__c cusAssoc : assocByLine.get(ln.Line_id__c)){
                    if(cusAssoc.gf_customer_group_id__c == ln.Line_Id__c){
                        // Add multiholder
                        root.client.multiholder = new Multiholder();
                        root.client.multiholder.customerId = cusAssoc.g_customer_id__c;
                        root.client.multiholder.id        = cusAssoc.gf_customer_group_id__c;
                        root.client.multiholder.groupId   = cusAssoc.g_group_id__c;
                        root.client.multiholder.groupName = ln.Client__r?.Name;

                        // customers[] Multiholder
                        if(assocCliByAssoc.containsKey(cusAssoc.Id)){
                            root.client.multiholder.customers = new List<Customer>();
                            for(Custom_Association_Client__c cusAssocCli : assocCliByAssoc.get(cusAssoc.Id)) {
                                if (cusAssocCli.Alpha_Code_Client__c != null){
                                    Customer c = new Customer();
                                    c.id = cusAssocCli.Alpha_Code_Client__c;
                                    root.client.multiholder.customers.add(c);
                                }
                            }
                        }
                    }
                }
            }

            List<DMT_Risk_Line_Term__c> listGetRiskLineTerm = termsByLine.get(ln.Id);

            // ---- Products
            if(ln.Product__c == 'Treasury Line'){
                root.products = new List<Product>();
                if(ln.FD_Amount__c != null){
                    Product p = new Product();
                    p.id                         = DMT_Constants.GROUP_PRIORITY_FD;
                    p.amountLimitIndType         = 'Y';
                    p.amount                     = String.valueOf(ln.FD_Amount__c);
                    p.currencyId                 = ln.CurrencyIsoCode;
                    p.corporateUserId            = ln.DMT_ID_User__c;//Permisos
                    p.comments                   = ln.DMT_Comments__c;
                    p.breakClauseNumber          = ln.First_Breakclause__c;
                    p.breakClauseDate            = formatDateToString(ln.First_Breakclause_Date__c);
                    p.lastLevelId                = DMT_Constants.RSK_LVL_SETTLEMENT_FD;
                    p.isdaWaiverIndType          = booleanToYN(ln.Waiver__c);
                    p.prevRenewalId              = ln.DMT_Parent_Line__c != null ? ln.DMT_Parent_Code_Form__c : '';
                    p.prevRenewalPriorityId        = ln.DMT_Parent_Line__c != null ? '01' : '';
                    p.breakClauseDaysNumber      = ln.Breakclause_Frequency__c;

                    root.products.add(p);
                }
                if(ln.DvP_Amount__c != null){
                    Product p = new Product();
                    p.id                         = DMT_Constants.GROUP_PRIORITY_DVP;
                    p.amountLimitIndType         = 'Y';
                    p.amount                     = String.valueOf(ln.DvP_Amount__c);
                    p.currencyId                 = ln.CurrencyIsoCode;
                    p.corporateUserId            = ln.DMT_ID_User__c;//Permisos
                    p.comments                   = ln.DMT_Comments__c;
                    p.breakClauseNumber          = ln.First_Breakclause__c;
                    p.breakClauseDate            = formatDateToString(ln.First_Breakclause_Date__c);
                    p.lastLevelId                = DMT_Constants.RSK_LVL_SETTLEMENT_DVP;
                    p.isdaWaiverIndType          = booleanToYN(ln.Waiver__c);
                    p.prevRenewalId              = ln.DMT_Parent_Line__c != null ? ln.DMT_Parent_Code_Form__c : '';
                    p.prevRenewalPriorityId        = ln.DMT_Parent_Line__c != null ? '02' : '';
                    p.breakClauseDaysNumber      = ln.Breakclause_Frequency__c;

                    root.products.add(p);
                }
                
                if(listGetRiskLineTerm != null && !listGetRiskLineTerm.isEmpty()){
                    
                    Product pInit = new Product();
                    pInit.id                         = '00';
                    pInit.amountLimitIndType         = 'Y';
                    pInit.amount                     = ln.Amount__c == null ? '' : String.valueOf(ln.Amount__c);
                    pInit.currencyId                 = ln.CurrencyIsoCode;
                    pInit.corporateUserId                = ln.DMT_ID_User__c;//Permisos
                    pInit.comments                   = ln.DMT_Comments__c;
                    pInit.breakClauseNumber          = ln.First_Breakclause__c;
                    pInit.breakClauseDate            = formatDateToString(ln.First_Breakclause_Date__c);
                    pInit.lastLevelId                = ln.DMT_LastLevelId__c;
                    pInit.isdaWaiverIndType          = booleanToYN(ln.Waiver__c);
                    pInit.prevRenewalId              = ln.DMT_Parent_Line__c != null ? ln.DMT_Parent_Code_Form__c : '';
                    pInit.breakClauseDaysNumber      = ln.Breakclause_Frequency__c;

                    root.products.add(pInit);

                    Map<String, Integer> countersByRiskType = new Map<String, Integer>{
                        'Derivatives' => 1,
                        'Depos'       => 1,
                        'Equities'    => 1
                    };

                    Map<String, String> prefixesByRiskType = new Map<String, String>{
                        'Derivatives' => DMT_Constants.GROUP_PRIORITY_TERM,
                        'Depos'       => DMT_Constants.GROUP_PRIORITY_TERM_DEPOS,
                        'Equities'    => DMT_Constants.GROUP_PRIORITY_TERM_EQUITIES
                    };

                    for (DMT_Risk_Line_Term__c riskLineTerm : listGetRiskLineTerm) {

                        String riskType = riskLineTerm.DMT_Risk_Type__c;

                        if (!countersByRiskType.containsKey(riskType)) {
                            continue;
                        }

                        Integer currentCounter = countersByRiskType.get(riskType);
                        String productIdPrefix = prefixesByRiskType.get(riskType);

                        Product p = new Product();

                        p.id = productIdPrefix + 'o' + String.valueOf('0' + currentCounter).right(2);

                        countersByRiskType.put(riskType, currentCounter + 1);

                        p.familyId                   = riskLineTerm.g_global_product_family_id__c;
                        p.subfamilyId                = riskLineTerm.g_global_product_subfamily_id__c;
                        p.categoryId                 = riskLineTerm.g_global_product_category_id__c;
                        p.subcategoryId              = riskLineTerm.g_gbl_product_subcategory_id__c;
                        p.globalId                   = riskLineTerm.g_global_product_id__c;
                        p.initTermDaysNumber         = riskLineTerm.DMT_Init_Term__c;
                        p.endTermDaysNumber          = riskLineTerm.DMT_End_Term__c;
                        p.amountLimitIndType         = 'Y';
                        p.amount                     = decimalToStringZeroFormat(riskLineTerm.DMT_Amount__c);
                        p.currencyId                 = riskLineTerm.CurrencyIsoCode;
                        p.corporateUserId            = riskLineTerm.DMT_Line__r.DMT_ID_User__c;
                        p.comments                   = riskLineTerm.DMT_Comments__c;
                        p.breakClauseNumber          = riskLineTerm.DMT_Line__r.First_Breakclause__c;
                        p.breakClauseDate            = formatDateToString(riskLineTerm.DMT_Line__r.First_Breakclause_Date__c);
                        p.lastLevelId                = DMT_Constants.RSK_LVL_TREASURY;
                        p.isdaWaiverIndType          = booleanToYN(riskLineTerm.DMT_Line__r.Waiver__c);
                        p.prevRenewalId              = ln.DMT_Parent_Line__c != null ? ln.DMT_Parent_Code_Form__c : '';
                        p.prevRenewalPriorityId      = ln.DMT_Parent_Line__c != null ? '03' : '';
                        p.breakClauseDaysNumber      = riskLineTerm.DMT_Line__r.Breakclause_Frequency__c;
                        p.multiOperationIndType      = multiOpMap.get(ln.Line_Id__c);
                        if (riskType == 'Equities') {
                            p.expertCriteriaRiskType     = 'WWRX';                    
                        }

                        root.products.add(p);
                    }
                }
            }else{

                    root.products = new List<Product>();
                    Product pInit = new Product();
                    pInit.id                         = '00';
                    pInit.amountLimitIndType         = 'Y';
                    pInit.amount                     = ln.Amount__c == null ? '' : String.valueOf(ln.Amount__c);
                    pInit.currencyId                 = ln.CurrencyIsoCode;
                    pInit.corporateUserId            = ln.DMT_ID_User__c;//Permisos
                    pInit.comments                   = ln.DMT_Comments__c;
                    pInit.breakClauseNumber          = ln.First_Breakclause__c;
                    pInit.breakClauseDate            = formatDateToString(ln.First_Breakclause_Date__c);
                    pInit.minRaroEcWoFgPercentage    = decimalToStringZeroFormat(ln.gf_min_raroec_wo_fcg_per__c);
                    pInit.minRorWocFcgPercentage     = decimalToStringZeroFormat(ln.gf_min_rorc_wo_fcg_per__c);
                    pInit.lastLevelId                = ln.DMT_LastLevelId__c;
                    pInit.isdaWaiverIndType          = booleanToYN(ln.Waiver__c);
                    pInit.prevRenewalId              = ln.DMT_Parent_Line__c != null ? ln.DMT_Parent_Code_Form__c + '_00' : '';
                    pInit.breakClauseDaysNumber      = ln.Breakclause_Frequency__c;

                    root.products.add(pInit);

                if(listGetRiskLineTerm != null && !listGetRiskLineTerm.isEmpty()){
                    
                    Integer fallbackCounter = 1;
                    for(DMT_Risk_Line_Term__c riskLineTerm : listGetRiskLineTerm){
                        String rawCommitment = riskLineTerm.g_line_commitment_level_type__c;
                        String processedCommitment;
                        if (String.isBlank(rawCommitment)) {
                            processedCommitment = '';
                        } else if (rawCommitment.equalsIgnoreCase('PENDING FORMALIZATION')) {
                            processedCommitment = 'PNG';
                        } else {
                            processedCommitment = rawCommitment.left(3);
                        }

                        Product p = new Product();
                        // Fallback to '99' or a counter if the priority ID is missing
                        p.id                         = String.isNotBlank(riskLineTerm.gf_group_priority_line_id__c) ? riskLineTerm.gf_group_priority_line_id__c : '99_' + fallbackCounter;
                        p.familyId                   = riskLineTerm.g_global_product_family_id__c;
                        fallbackCounter++;
                        p.subfamilyId                = riskLineTerm.g_global_product_subfamily_id__c;
                        p.categoryId                 = riskLineTerm.g_global_product_category_id__c;
                        p.subcategoryId              = riskLineTerm.g_gbl_product_subcategory_id__c;
                        p.globalId                   = riskLineTerm.g_global_product_id__c;
                        p.guaranteeIndType           = riskLineTerm.g_line_cond_guarantee_ind_type__c;
                        p.bulletIndType              = riskLineTerm.g_bullet_ind_type__c;
                        p.internalRatingType         = riskLineTerm.g_smscl_internal_ratg_type__c;
                        p.initTermDaysNumber         = riskLineTerm.DMT_Init_Term__c;
                        p.endTermDaysNumber          = riskLineTerm.DMT_End_Term__c;
                        p.limitSindsAstSctrId        = riskLineTerm.g_limit_sinds_ast_sctr_id__c;
                        p.limitSindsAstSubsecId      = riskLineTerm.g_limit_sinds_ast_subsec_id__c;
                        p.expertCriteriaRiskType     = riskLineTerm.g_expert_criteria_risk_type__c;
                        p.amountLimitIndType         = 'Y';
                        p.amount                     = decimalToStringZeroFormat(riskLineTerm.DMT_Amount__c);
                        p.currencyId                 = riskLineTerm.CurrencyIsoCode;
                        p.corporateUserId            = riskLineTerm.DMT_Line__r.DMT_ID_User__c;//Permisos
                        p.comments                   = riskLineTerm.DMT_Comments__c;
                        p.breakClauseNumber          = riskLineTerm.DMT_Line__r.First_Breakclause__c;
                        p.breakClauseDate            = formatDateToString(riskLineTerm.DMT_Line__r.First_Breakclause_Date__c);
                        p.lastLevelId                = riskLineTerm.DMT_LastLevelId__c;
                        p.monthsGraceNumber          = decimalToStringZeroFormat(riskLineTerm.gf_inscol_months_grace_number__c);
                        p.loanValuePercentage        = decimalToStringZeroFormat(riskLineTerm.gf_loan_value_per__c);
                        p.notaryCrtfnIndType         = booleanToYN(riskLineTerm.g_notary_crtfn_ind_type__c);
                        p.gteePublicAdmIndType       = booleanToYN(riskLineTerm.g_gtee_public_adm_ind_type__c);
                        p.loanEcaContribPercentage   = decimalToStringZeroFormat(riskLineTerm.gf_loan_eca_cntrb_per__c);
                        p.minRaroEcFgPercentage      = decimalToStringZeroFormat(riskLineTerm.gf_min_raroec_fcg_per__c);
                        p.minRaroEcWoFgPercentage    = decimalToStringZeroFormat(riskLineTerm.gf_min_raroec_wo_fcg_per__c);
                        p.minRorcFcgPercentage       = decimalToStringZeroFormat(riskLineTerm.gf_min_rorc_fcg_per__c);
                        p.minRorWocFcgPercentage     = decimalToStringZeroFormat(riskLineTerm.gf_min_rorc_wo_fcg_per__c);
                        p.isdaWaiverIndType          = booleanToYN(riskLineTerm.DMT_Line__r.Waiver__c);
                        p.prevRenewalId              = riskLineTerm.DMT_Parent_Product__c != null ? ln.DMT_Parent_Code_Form__c : '';
                        p.prevRenewalPriorityId      = riskLineTerm.DMT_Parent_Product__c != null ? riskLineTerm.DMT_Parent_Product__r?.gf_group_priority_line_id__c : '';
                        p.breakClauseDaysNumber      = riskLineTerm.DMT_Line__r.Breakclause_Frequency__c;
                        p.multiOperationIndType      = multiOpMap.get(ln.Line_Id__c);
                        p.booking                    = riskLineTerm.g_branch_id__c;
                        p.commitmentLevelType = processedCommitment;

                        String prodMultiId = ln.Line_Id__c + '_' + riskLineTerm.gf_group_priority_line_id__c;
                        if(assocByLine.containsKey(prodMultiId)){
                            for(Custom_Association__c cusAssoc : assocByLine.get(prodMultiId)){
                                if(cusAssoc.gf_customer_group_id__c == prodMultiId && assocCliByAssoc.containsKey(cusAssoc.Id)){
                                    // Add multiholder
                                    p.multiholder = new Multiholder();
                                    p.multiholder.customerId = cusAssoc.g_customer_id__c;
                                    p.multiholder.id        = cusAssoc.gf_customer_group_id__c;
                                    p.multiholder.groupId   = cusAssoc.g_group_id__c;
                                    p.multiholder.groupName = ln.Client__r?.Name;

                                    // customers[] Multiholder
                                    if(assocCliByAssoc.containsKey(cusAssoc.Id)){
                                        p.multiholder.customers = new List<Customer>();
                                        for(Custom_Association_Client__c cusAssocCli : assocCliByAssoc.get(cusAssoc.Id)) {
                                            if (cusAssocCli.Alpha_Code_Client__c != null){
                                                Customer c = new Customer();
                                                c.id = cusAssocCli.Alpha_Code_Client__c;
                                                p.multiholder.customers.add(c);
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }

                        // currencies[]
                        List<DMT_Currency_Provision__c> listCurrencyProv = currByTerm.get(riskLineTerm.Id);
                        if(listCurrencyProv != null && !listCurrencyProv.isEmpty()){
                        p.currencies = new List<CurrencyItem>();
                            for(DMT_Currency_Provision__c currProv : listCurrencyProv){
                                if (currProv.g_currency_id__c != null){
                                    CurrencyItem cur = new CurrencyItem();
                                    cur.id = currProv.g_currency_id__c;
                                    p.currencies.add(cur);
                                }
                            }
                        }

                        // guarantees[] (Deduplicated)
                        if (wntByTerm.containsKey(riskLineTerm.Id)) {
                            p.guarantees = new List<GuaranteeItem>();
                            Set<String> uniqueGuaranteeTypes = new Set<String>();
                            
                            for(DMT_Warranty__c guarantee : wntByTerm.get(riskLineTerm.Id)){
                                String gType = guarantee.g_limits_grid_guarantee_type__c;
                                // Only add it to the payload if we haven't seen this type before
                                if (!uniqueGuaranteeTypes.contains(gType)) {
                                    GuaranteeItem g = new GuaranteeItem();
                                    g.guaranteeIndType = gType;
                                    p.guarantees.add(g);
                                    uniqueGuaranteeTypes.add(gType);
                                }
                            }
                        }

                    root.products.add(p);
                    }//end risk line terms
                }//end validation products
            }

            // Configuration for IASO payload
            Map<String, String> requestMap = new Map<String, String> {'payload' => JSON.serialize(root, true)};

            // Initialize Context Wrapper, add payload, and put in map
            LinePayloadContext ctx = new LinePayloadContext(ln);
            ctx.payloads.add(JSON.serialize(requestMap, true));
            
            resultPayloads.put(ln.Id, ctx);
        }

        return resultPayloads;
    }

    /**
    * Ejecuta la(s) llamada(s) al servicio IASO para cada payload recibido.
    * Retorna un mapa con el resumen y el detalle por payload.
    *
    * out = {
    *   'result'      => Boolean   // true si TODAS las llamadas fueron exitosas
    *   'message'     => String    // resumen
    *   'statusCode'  => Integer   // sin significado único con múltiples llamadas; se deja el último
    *   'processed'   => Integer   // cantidad de payloads procesados
    *   'succeeded'   => Integer   // cantidad con 200/201
    *   'failed'      => Integer   // cantidad con error
    *   'results'     => List<Map> // detalle por payload: index, statusCode, result, message, request
    *   'warning'     => String    // (opcional) aviso si superó límites
    * }
    */
    
    public static Map<String, Object> send(List<String> listPayloads) {
        
        Map<String,Object> out = new Map<String,Object>{
            'result'     => false,
            'message'    => 'Sin payloads que procesar',
            'statusCode' => 0,
            'processed'  => 0,
            'succeeded'  => 0,
            'failed'     => 0,
            'results'    => new List<Map<String, Object>>()
        };

        if (listPayloads == null || listPayloads.isEmpty()) {
            System.debug('>>> SEND METHOD: No payloads received.');
            return out;
        }

        // Gobernor limit: máximo 100 callouts por transacción
        Integer maxCallouts = 100;
        Integer toProcess   = Math.min(maxCallouts, listPayloads.size());
    
        if (listPayloads.size() > maxCallouts) {
            out.put('warning', 'Se recibieron ' + listPayloads.size() +
                    ' payloads pero solo se pueden procesar 100 por transacción. ' +
                    'Se procesarán los primeros 100.');
        }

        // Lee metadata del servicio una sola vez
        String serviceName = 'DMTO_RiskPositionLine';
        System.debug('>>> SEND METHOD: Retrieving metadata for service: ' + serviceName);

        iaso__GBL_integration_service__mdt svc = [SELECT iaso__Mock_LTA__c, iaso__Http_Method__c, iaso__Retrieve_Mock_LTA__c
                                                  FROM iaso__GBL_integration_service__mdt
                                                  WHERE DeveloperName = :serviceName
                                                  LIMIT 1];

        Integer succeeded = 0;
        Integer failed = 0;
        Integer lastStatus = 0;

        for (Integer i = 0; i < toProcess; i++) {
            System.debug('\n======================================================');
            System.debug('>>> SEND METHOD: Processing Payload Index [' + i + ']');
            
            String requestStr = listPayloads[i];

            Map<String,Object> perItem = new Map<String,Object>{
                'index'      => i,
                'request'    => requestStr,
                'result'     => false,
                'statusCode' => 0,
                'message'    => null
            };

            if (String.isBlank(requestStr)) {
                System.debug('>>> SEND METHOD: Payload is empty!');
                perItem.put('message', 'Payload vacio en posición ' + i);
                failed++;
                ((List<Map<String,Object>>)out.get('results')).add(perItem);
                continue;
            }

            try {
                HttpResponse response;
                
                System.debug('>>> SEND METHOD: RAW JSON REQUEST BODY BEING SENT:');
                System.debug(requestStr);
                System.debug('------------------------------------------------------');

                if (Test.isRunningTest() || svc.iaso__Retrieve_Mock_LTA__c) {
                    System.debug('>>> SEND METHOD: Invoking MOCK service.');
                    response = DMT_HPG_Utils.getMock(serviceName);
                } else {
                    // Real callout
                    System.debug('>>> SEND METHOD: Invoking REAL service: ' + serviceName);
                    response = iaso.GBL_Integration_GenericService.invoke(serviceName, requestStr);
                }

                Integer code = (response != null) ? response.getStatusCode() : 0;
                String body = (response != null) ? response.getBody() : 'NULL BODY';
                
                System.debug('>>> SEND METHOD: HTTP STATUS CODE: ' + code);
                System.debug('>>> SEND METHOD: HTTP RESPONSE BODY:');
                System.debug(body);

                lastStatus = code;
                perItem.put('statusCode', code);

                if (code == 200 || code == 201) {
                    perItem.put('result', true);
                    perItem.put('message', body);
                    succeeded++;
                    System.debug('>>> SEND METHOD: Callout SUCCESS.');
                } else {
                    perItem.put('message', 'Error en servicio: ' + code + ' - ' + safeTrunc(body));
                    failed++;
                    System.debug('>>> SEND METHOD: Callout FAILED.');
                }

            } catch (Exception ex) {
                System.debug('>>> SEND METHOD: EXCEPTION CAUGHT: ' + ex.getMessage());
                System.debug('>>> SEND METHOD: STACKTRACE: ' + ex.getStackTraceString());
                perItem.put('message', 'Excepción en integración: ' + safeTrunc(ex.getMessage()));
                failed++;
            }

            ((List<Map<String,Object>>)out.get('results')).add(perItem);
            System.debug('======================================================\n');
        }

        Integer processed = toProcess;
        out.put('processed', processed);
        out.put('succeeded', succeeded);
        out.put('failed', failed);
        out.put('statusCode', lastStatus);

        // Resultado global: true solo si TODAS fueron OK
        Boolean allOk = (processed > 0 && failed == 0);
        out.put('result', allOk);

        if (processed == 0) {
            out.put('message', 'No se proceso ningun payload');
        } else if (allOk) {
            out.put('message', 'Todos los payloads procesados correctamente (' + processed + ').');
        } else {
            out.put('message', 'Procesados: ' + processed + '. OK: ' + succeeded + ', Fallidos: ' + failed + '.');
        }

        System.debug('>>> SEND METHOD: Final Output Summary Map: ' + JSON.serialize(out));
        return out;
    }

    // ======= MODELOS =======
    public class Root {
        public String opportunityId;
        public String status;
        public String templateType;
        public String initDate;     // ISO yyyy-MM-dd
        public String endDate;      // ISO yyyy-MM-dd
        public String entificId;
        public String entityId;
        public String branchId;
        public String name;
        public String originApplicationType;
        public String commitmentLevelType;
        public String updateDate;
        public Client client;
        public List<Product> products;
    }
    public class Client {
        public String customerId;
        public String groupId;
        public String groupName;
        public Multiholder multiholder;
        public String goldenCustomerId;
    }
    public class Multiholder {
        public String id;
        public String groupId;
        public String groupName;
        public String customerId;
        public List<Customer> customers;
    }
    public class Customer { public String id; }

    public class Product {
        public String  id;
        public String  familyId;
        public String  subfamilyId;
        public String  categoryId;
        public String  subcategoryId;
        public String  globalId;
        public String  guaranteeIndType;
        public String  bulletIndType;
        public String  internalRatingType;
        public String  initTermDaysNumber;
        public String  endTermDaysNumber;
        public String  limitSindsAstSctrId;
        public String  limitSindsAstSubsecId;
        public String  expertCriteriaRiskType;
        public String  amountLimitIndType;
        public String  amount;
        public String  currencyId;
        public String  corporateUserId;
        public String  comments;
        public String  breakClauseNumber;
        public String  breakClauseDate;   // ISO
        public String  clearingHouseType;
        public String  classificationType;
        public String  lastLevelId;
        public String monthsGraceNumber;
        public String loanValuePercentage;
        public String  notaryCrtfnIndType;
        public String  gteePublicAdmIndType;
        public String  loanEcaContribPercentage;
        public String  minRaroEcFgPercentage;
        public String minRaroEcWoFgPercentage;
        public String minRorcFcgPercentage;
        public String minRorWocFcgPercentage;
        public String  isdaWaiverIndType;
        public String  prevRenewalId;
        public String  revolvencePdDaysNumber;
        public String  breakClauseDaysNumber;
        public String  multiOperationIndType;
        public String  booking;
        public Multiholder multiholder;
        public List<CurrencyItem> currencies;
        public List<GuaranteeItem> guarantees;
        public String prevRenewalPriorityId;
        public String commitmentLevelType;
    }

    public class CurrencyItem { public String id; }
    public class GuaranteeItem { public String guaranteeIndType; }

    public static String objectNameById(Id recordId) {
        try { return recordId.getSObjectType().getDescribe().getName(); }
        catch (Exception e) { return null; }
    }

    public static Map<String, String> getMultiOp(Set<Id> recordIds) {
        Map<String, String> multiOpMap = new Map<String, String> ();
        Set<String> lineIds = new Set<String>();
        List<DMT_Line__c> rows = [SELECT Id, Line_Id__c 
                                      FROM DMT_Line__c 
                                      WHERE Id IN :recordIds];

            for (DMT_Line__c row : rows) {
                lineIds.add(row.Line_Id__c);
            }
            for(DMT_Consolidated_Line__c row : [SELECT Line_Id__c, g_multioperation_ind_type__c FROM DMT_Consolidated_Line__c WHERE Line_Id__c IN :lineIds]){
                if (String.isNotBlank(row.Line_Id__c)){
                    multiOpMap.put(row.Line_Id__c, row.g_multioperation_ind_type__c);
                }
            }
        return multiOpMap;
    }

    public static List<Id> getLineIds(String objectApi, Set<Id> recordIds) {

        if (String.isBlank(objectApi) || recordIds.isEmpty()) {
            return new List<Id>();
        }

        List<Id> lineIds = new List<Id>();

        if (objectApi == 'DMT_Line__c') {

            List<DMT_Line__c> rows = [SELECT Id 
                                      FROM DMT_Line__c 
                                      WHERE Id IN :recordIds];

            for (DMT_Line__c row : rows) {
                lineIds.add(row.Id);
            }

        } else if (objectApi == 'DMT_Consolidated_Line__c') {
            Set<String> dmtIds = new Set<String>();
            for(DMT_Consolidated_Line__c row : [SELECT Line_Id__c FROM DMT_Consolidated_Line__c WHERE Id IN :recordIds]){
                if (String.isNotBlank(row.Line_Id__c)){
                    dmtIds.add(row.Line_Id__c);
                }
            }

            if (!dmtIds.isEmpty()) {
                for (DMT_Line__c line : [SELECT Id FROM DMT_Line__c WHERE Line_Id__c IN :dmtIds]) {
                lineIds.add(line.Id);
                }
            }
        } else if (objectApi == 'Custom_Association__c') {
            
            for(Custom_Association__c row : [SELECT DMT_Line__c FROM Custom_Association__c WHERE Id IN :recordIds]){
                if (row.DMT_Line__c != null){
                    lineIds.add(row.DMT_Line__c);
                }
            }

        } else if (objectApi == 'Custom_Association_Client__c') {

            List<Custom_Association_Client__c> rows = [SELECT Custom_Association__r.DMT_Line__c FROM Custom_Association_Client__c WHERE Id IN :recordIds];

            for (Custom_Association_Client__c row : rows) {
                if (row.Custom_Association__r != null && row.Custom_Association__r.DMT_Line__c != null) {
                    lineIds.add(row.Custom_Association__r.DMT_Line__c);
                }
            }

        } else if (objectApi == 'DMT_Warranty__c') {
        
            List<DMT_Warranty__c> rows = [SELECT DMT_Risk_Line_Term__r.DMT_Line__c FROM DMT_Warranty__c  WHERE Id IN :recordIds];

            for (DMT_Warranty__c row : rows) {
                if (row.DMT_Risk_Line_Term__r != null && row.DMT_Risk_Line_Term__r.DMT_Line__c != null) {
                    lineIds.add(row.DMT_Risk_Line_Term__r.DMT_Line__c);
                }
            }

        } else if (objectApi == 'DMT_Currency_Provision__c') {
            
            List<DMT_Currency_Provision__c> rows = [SELECT DMT_Risk_Line_Term__r.DMT_Line__c FROM DMT_Currency_Provision__c WHERE Id IN :recordIds];

            for (DMT_Currency_Provision__c row : rows) {
                if (row.DMT_Risk_Line_Term__r != null && row.DMT_Risk_Line_Term__r.DMT_Line__c != null) {
                    lineIds.add(row.DMT_Risk_Line_Term__r.DMT_Line__c);
                }
            }
        }

        return lineIds;
    }


    public static List<DMT_Line__c> getLineInfo(List<Id> lineIds) {
        
        if (lineIds == null || lineIds.isEmpty()) {
            return new List<DMT_Line__c>();
        }

        List<DMT_Line__c> lines = [
            SELECT Id, Line_Id__c, DMT_line_status_type__c, Client_Type__c, RecordType.DeveloperName,
                   DMT_line_template_type__c, Start_date__c, End_Date__c,
                   Booking_Geography__c, DMT_Entity__c, gf_origin_application_type__c,
                   Client_Code__c, Client__r.DES_Main_Parent__r.DES_Group_Code__c,
                   Client__r.DES_group_Code__c, Client__r.Parent_Account_Name__c,
                   Client__r.Name, DvP_Amount__c, FD_Amount__c, DMT_Comments__c,DMT_Parent_Line__c, Product__c,
                   First_Breakclause__c, First_Breakclause_Date__c,CurrencyIsoCode,
                   Breakclause_Frequency__c, Waiver__c, DMT_Total_Amount__c, Amount__c, DMT_LastLevelId__c,Name, DMT_Parent_Code_Form__c,
                   g_line_commitment_level_type__c, LastModifiedDate, DMT_ID_User__c, g_line_status_type__c, Closed__c, Status__c, gf_min_raroec_wo_fcg_per__c, gf_min_rorc_wo_fcg_per__c,
                   DMT_Status_Completed__c
            FROM DMT_Line__c
            WHERE Id IN :lineIds
            AND Line_Id__c != null AND Line_Id__c != ''
            AND DMT_line_status_type__c != null
            AND DMT_line_template_type__c != null
            AND Start_date__c != null
            AND End_Date__c != null
            AND (Status__c != 'Draft' AND Status__c !='Proposal')
            AND Booking_Geography__c != null AND Booking_Geography__c != ''
            AND Id IN (SELECT DMT_Line__c FROM DMT_Risk_Line_Term__c)
            ];
        return lines;
    }

    // Carga todas las Custom_Association__c
    @TestVisible
    private static Map<String, List<Custom_Association__c>> getCustomAssocByLines(Set<Id> lineIds) {
    
        Map<String, List<Custom_Association__c>> byLine = new Map<String, List<Custom_Association__c>>();
        if (lineIds.isEmpty()) return byLine;

        for (Custom_Association__c ca : [
            SELECT Id, DMT_Line__c, gf_customer_group_id__c, g_group_id__c, g_customer_id__c 
            FROM Custom_Association__c
            WHERE DMT_Line__c IN :lineIds
            AND gf_customer_group_id__c != null AND gf_customer_group_id__c != ''
            AND g_group_id__c != null AND g_group_id__c != ''
        ]) {
            if (!byLine.containsKey(ca.gf_customer_group_id__c)) byLine.put(ca.gf_customer_group_id__c, new List<Custom_Association__c>());
            byLine.get(ca.gf_customer_group_id__c).add(ca);
        }
        return byLine;
    }

    // Carga todos los Custom_Association_Client__c
    @TestVisible
    private static Map<Id, List<Custom_Association_Client__c>> getCustomAssocClientsByAssoc(Set<Id> assocIds) {
        
        Map<Id, List<Custom_Association_Client__c>> byAssoc = new Map<Id, List<Custom_Association_Client__c>>();
        if (assocIds.isEmpty()) return byAssoc;

        for (Custom_Association_Client__c cli : [
            SELECT Id, Custom_Association__c, Alpha_Code_Client__c
            FROM Custom_Association_Client__c
            WHERE Custom_Association__c IN :assocIds
            AND Alpha_Code_Client__c != null AND Alpha_Code_Client__c != ''
        ]) {
            if (!byAssoc.containsKey(cli.Custom_Association__c)) byAssoc.put(cli.Custom_Association__c, new List<Custom_Association_Client__c>());
            byAssoc.get(cli.Custom_Association__c).add(cli);
        }
        return byAssoc;
    }

    // Carga todos los Risk Line Terms por línea (incluye los campos que luego usas al construir el JSON)
    @TestVisible
    private static Map<Id, List<DMT_Risk_Line_Term__c>> getRiskLineTermsByLines(Set<Id> lineIds) {
    
        Map<Id, List<DMT_Risk_Line_Term__c>> byLine = new Map<Id, List<DMT_Risk_Line_Term__c>>();
        if (lineIds.isEmpty()) return byLine;

        for (DMT_Risk_Line_Term__c t : [
            SELECT Id,
                   gf_group_priority_line_id__c,
                   g_global_product_family_id__c, g_global_product_subfamily_id__c,
                   g_global_product_category_id__c, g_gbl_product_subcategory_id__c,
                   g_global_product_id__c, g_line_cond_guarantee_ind_type__c,
                   g_bullet_ind_type__c, g_smscl_internal_ratg_type__c,
                   DMT_Init_Term__c, DMT_End_Term__c,
                   g_limit_sinds_ast_sctr_id__c, g_limit_sinds_ast_subsec_id__c,
                   g_expert_criteria_risk_type__c,
                   DMT_Amount__c, CurrencyIsoCode, DMT_Comments__c, DMT_LastLevelId__c,
                   gf_inscol_months_grace_number__c, gf_loan_value_per__c,
                   g_notary_crtfn_ind_type__c, g_gtee_public_adm_ind_type__c,
                   gf_loan_eca_cntrb_per__c, gf_min_raroec_fcg_per__c,
                   gf_min_raroec_wo_fcg_per__c, gf_min_rorc_fcg_per__c, gf_min_rorc_wo_fcg_per__c,
                   g_multioperation_ind_type__c,
                   DMT_Parent_Product__r.gf_group_priority_line_id__c,
                   DMT_Line__r.First_Breakclause__c, DMT_Line__r.First_Breakclause_Date__c,
                   DMT_Line__r.Waiver__c, DMT_Line__r.Breakclause_Frequency__c,
                   DMT_Line__c, g_branch_id__c, DMT_Line__r.DMT_ID_User__c, g_line_commitment_level_type__c, DMT_Risk_Type__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c IN :lineIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!byLine.containsKey(t.DMT_Line__c))
            byLine.put(t.DMT_Line__c, new List<DMT_Risk_Line_Term__c>());
            byLine.get(t.DMT_Line__c).add(t);
        }
        return byLine;
    }

    // Carga todas las DMT_Currency_Provision__c
    @TestVisible
    private static Map<Id, List<DMT_Currency_Provision__c>> getCurrencyProvisionsByTerms(Set<Id> termIds) {
        Map<Id, List<DMT_Currency_Provision__c>> byTerm = new Map<Id, List<DMT_Currency_Provision__c>>();
        if (termIds.isEmpty()) return byTerm;

        for (DMT_Currency_Provision__c cp : [
            SELECT Id, DMT_Risk_Line_Term__c, g_currency_id__c
            FROM DMT_Currency_Provision__c
            WHERE DMT_Risk_Line_Term__c IN :termIds
            AND g_currency_id__c != null AND g_currency_id__c != ''
        ]) {
            if (!byTerm.containsKey(cp.DMT_Risk_Line_Term__c)) byTerm.put(cp.DMT_Risk_Line_Term__c, new List<DMT_Currency_Provision__c>());
            byTerm.get(cp.DMT_Risk_Line_Term__c).add(cp);
        }
        return byTerm;
    }

    // Carga todas lasDMT_Warranty__c
    @TestVisible
    private static Map<Id, List<DMT_Warranty__c>> getWarrantiesByTerms(Set<Id> termIds) {
        Map<Id, List<DMT_Warranty__c>> byTermMap = new Map<Id, List<DMT_Warranty__c>>();
        if (termIds.isEmpty()) return byTermMap;

        for (DMT_Warranty__c w : [SELECT DMT_Risk_Line_Term__c, g_limits_grid_guarantee_type__c FROM DMT_Warranty__c WHERE DMT_Risk_Line_Term__c IN :termIds AND g_limits_grid_guarantee_type__c != null AND g_limits_grid_guarantee_type__c != '']){
            Id key = w.DMT_Risk_Line_Term__c;
            if (!byTermMap.containsKey(key)) {
                byTermMap.put(key, new List<DMT_Warranty__c>());
            }
            byTermMap.get(key).add(w);
        }
        return byTermMap;
    }

    @TestVisible
    private static String safeTrunc(String s) {
        if (s == null) return null;
        return s.length() > 4000 ? s.substring(0,4000) : s;
    }

    public static String formatDateToString(Date inputDate) {
        if (inputDate == null) {
            return null;
        }
        Datetime dt = Datetime.newInstance(inputDate, Time.newInstance(0, 0, 0, 0));
        return dt.format('yyyy-MM-dd');
    }

    public static String booleanToYN(Boolean value) {
        return value == true ? 'Y' : 'N';
    }

    public static String decimalToStringZeroFormat(Decimal value) {
        if (value == null) {
            return '0'; // Devuelve "0" si es nulo
        }
        return String.valueOf(value);
    }

    // ======= CONTEXT WRAPPER =======
    public class LinePayloadContext {
        public DMT_Line__c lineRecord;
        public List<String> payloads;
        
        public LinePayloadContext(DMT_Line__c lineRecord) {
            this.lineRecord = lineRecord;
            this.payloads = new List<String>();
        }
    }

}