public without sharing class DMT_ViewController {

    // Clase envoltorio para los ítems seleccionados (mover al principio)
    public class ItemWrapper {
        public String type { get; set; }
        public String component { get; set; }
        public Decimal orderDisplay { get; set; }
        public String textValue { get; set; }
        public ItemWrapper(){}
        public ItemWrapper(String type, String component,Decimal orderDisplay,String textValue) {
            this.type = type;
            this.component = component;
            this.orderDisplay = orderDisplay;
            this.textValue = textValue;
        }
    }
    public class ItemImgB64{
        public String imgB64 { get; set; }
    }

    public class OpportunityProduct {
        public String name;
        public String bookingGeography;
        public String riskType;
        public Date initialDate;
        public Date maturityDate;
        public String comments;
        public String amortizationType;
        public String paymentFrequency;
        public String currencyIsoCode;
        public String amortizationScheduleCurrency;
        public List<DMT_Opportunity_Tenor__c > oppTenors = new List<DMT_Opportunity_Tenor__c>();
        public Boolean socialBonus;
        public Boolean greenBonus;
        public Double fundingUndrawnBPS;
        public Double fundingDrawnBPS;
        public String fundingTerm;
        public String fundingCurve;
        public String country;
        public String countryRating;
        public List<DMT_Opportunity_Mitigant__c> oppMitigants = new List<DMT_Opportunity_Mitigant__c>();
        public String currencyMitigant;
    }

    public class LineDataWrapper {
        public String objectApiName;
        public String recordTypeId;
        public DMT_Line__c line = new DMT_Line__c();
        public Opportunity opportunity = new Opportunity();
        public Account clientAccount = new Account();
        public DMT_Opportunity_Client__c oppClient = new DMT_Opportunity_Client__c();
        public List<OpportunityProduct> oppProducts = new List<OpportunityProduct>();

        public List<DMT_X_Sell__c> xSellOpp = new List<DMT_X_Sell__c>();

        public List<Custom_Association_Client__c> customAssociationClientList = new List<Custom_Association_Client__c>();
        public List<DMT_TeamMember__c> participantList = new List<DMT_TeamMember__c>();
        public List<DMT_Risk_Line_Term__c> riskLineList = new List<DMT_Risk_Line_Term__c>();
        public List<DMT_Line_Product_Item__c> lineProductList = new List<DMT_Line_Product_Item__c>();
        public List<Map<String, Object>> featuresList = new List<Map<String, Object>>();
        public List<DMT_Case_Steps_Controller.WRAPPER_Step> steps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        public List<DMT_Case_Steps_Controller.WRAPPER_Step> allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        public String currencyIsoCode;

        public Map<Id, DMT_Currency_Provision__c> riskLineToCurrencyProvisionMap = new Map<Id, DMT_Currency_Provision__c>();
        public Map<Id, Map<String, String>> productLevelsByRiskLine = new Map<Id, Map<String, String>>();
        public Map<Id, List<DMT_Warranty__c>> riskLineToWarrantyListMap = new Map<Id, List<DMT_Warranty__c>>();
        public Map<Id, String> riskLineToTaxonomyC162Map = new Map<Id, String>();
        public Map<Id, String> riskLineToTaxonomyC164Map = new Map<Id, String>();
        public Map<Id, String> riskLineToTaxonomyH007Map = new Map<Id, String>();
        public Boolean isImg64;
        public List<ItemImgB64> itemImgBase64 = new List<ItemImgB64>();

        public String oppEntity;
        public String oppEntific;

        public String mainHolderCustomerId;
        public Boolean isNotMultiHolder = false;
        
    // Key is constructed like LineId_groupPriorityId (string), so use String as key
    public Map<String, List<MainHolderProductsWrapper>> mainHolderProductsWrapperMap= new Map<String, List<MainHolderProductsWrapper>>();
    }

    public class MainHolderProductsWrapper {
        public String clientName;
        public String internalRatingShort;
        public Date currentRatingToolDate;
    }

    public DMT_ViewController() {

    }
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getFeatures(String id) {
        List<Map<String, Object>> featuresList = new List<Map<String, Object>>();
        try {
            Passport__c passportRecord = [SELECT DMT_Passport_Save__c, DMT_Line__c FROM Passport__c WHERE Opportunity__c = :id OR DMT_Line__c = :id OR DMT_Line__r.Line_Id__c =:id OR Opportunity__r.DMT_Opp_Id__c = :id LIMIT 1];

            if (passportRecord.DMT_Passport_Save__c != null) {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(passportRecord.DMT_Passport_Save__c);
                if (data.containsKey('data')) {
                    Map<String, Object> dataMap = (Map<String, Object>) data.get('data');
                    if (dataMap.containsKey('features')) {
                        List<Object> rawFeatures = (List<Object>) dataMap.get('features');
                        for (Object featureObj : rawFeatures) {
                            featuresList.add((Map<String, Object>) featureObj);
                        }
                    }
                }
            }
        } catch (QueryException e) {
            System.debug('No se encontró un registro de Passport__c con el ID proporcionado: '+ id);
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_ViewController','getFeatures','DMT',''));
        }
        return featuresList;
    }

    @AuraEnabled(cacheable=true)
    public static String getFeaturesForJsonPdf(String lineId, String caseId) {
        String featuresJson = '';
        String baseQuery;
        Boolean isOpp = false;
        try {
            if(String.isNotBlank(caseId)){
                Case caseRecord = DMT_View_Selector.getCaseLineOpportunity((Id)caseId);
                if(caseRecord.DMT_LineOpportunity__c == 'O') {
                    lineId = caseRecord.opportunity_id__c;
                }
            }
            Map<String, Object> wrapper;
            isOpp = (String.isNotBlank(lineId) && ((Id)Id.valueOf(lineId)).getSObjectType().getDescribe().getName() == 'Opportunity') ? true : false;
            Schema.SObjectType objType = isOpp ? Opportunity.SObjectType : DMT_Line__c.SObjectType;
            Schema.DescribeSObjectResult d = objType.getDescribe();
            Map<String, Schema.SObjectField> f = d.fields.getMap();
            if (!d.isAccessible() || !f.get('CurrencyIsoCode').getDescribe().isAccessible() || !f.get('Id').getDescribe().isAccessible()) {
                throw new AuraHandledException('You do not have permission to access ' + (isOpp ? 'Opportunity' : 'DMT Line') + ' records.');
            }

            if(isOpp) {
                baseQuery = 'SELECT Id, CurrencyIsoCode FROM Opportunity WHERE';
                if (String.isNotBlank(caseId)) {
                    baseQuery += ' Id IN (SELECT opportunity_id__c FROM Case WHERE Id = :caseId)';
                }
                List<Opportunity> oppList = Database.query(baseQuery);
                if (oppList.isEmpty()) {
                    throw new AuraHandledException('no records found.');
                }
                List<Map<String, Object>> featuresList = getFeatures(oppList[0].Id);
                if (featuresList.isEmpty()) {
                    throw new AuraHandledException('no features found for ' + oppList[0].Id);
                }
                wrapper = new Map<String, Object>{
                    'currencyCode' => oppList[0].CurrencyIsoCode,
                    'features'     => featuresList
                };
            }else{
                baseQuery = 'SELECT Id, CurrencyIsoCode FROM DMT_Line__c WHERE';
                if (String.isNotBlank(caseId)) {
                    baseQuery += ' Id IN (SELECT DMT_Line__c FROM Case WHERE Id = :caseId)';
                } else if (String.isNotBlank(lineId)) {
                    baseQuery += ' Id = :lineId';
                } else {
                    throw new AuraHandledException('no caseId or lineId received');
                }
                List<DMT_Line__c> lineList = Database.query(baseQuery);
                if (lineList.isEmpty()) {
                    throw new AuraHandledException('no records found.');
                }
                List<Map<String, Object>> featuresList = getFeatures(lineList[0].Id);
                if (featuresList.isEmpty()) {
                    throw new AuraHandledException('no features found for ' + lineList[0].Id);
                }
                wrapper = new Map<String, Object>{
                    'currencyCode' => lineList[0].CurrencyIsoCode,
                    'features'     => featuresList
                };
            }
            featuresJson = JSON.serialize(wrapper);
            return featuresJson;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getFeaturesForJsonPdf: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_ViewController', 'getFeaturesForJsonPdf', 'DMT', ''));
            // Return error as JSON
            return JSON.serialize(new Map<String, String>{ 'error' => e.getMessage() + ' at line ' + e.getLineNumber() });
        }
    }

    public static List<Custom_Association_Client__c> getUpdatedCustomAssociationClientList(Id clientId, Id customAssociationId){

        // call DMT_HPG_Utils.lastDate() first to get the searchDate
        String searchDate = DMT_HPG_Utils.lastDate();

        DMT_HPG_GlobalPosition.Wrapper res = new DMT_HPG_GlobalPosition.Wrapper();
                                                                        //clientId, page, pageSize, countries, searchDate, clientPositionsType, customerId)
        res = DMT_HPG_MainTableCustomController.fetchClientDataFromService(clientId, '1', '5000', new List<String>{}, Date.valueOf(searchDate), 'Y/N', null);
        System.debug('getUpdatedCustomAssociationClientList res --> ' + JSON.serialize(res));

        Map<String, String> customerIdOperationMitigantDescMap = new Map<String, String>();
        Map<String, String> customerIdCustomerCounterpartiesCodesDescMap = new Map<String, String>();
        Map<String, String> customerIdCurrentRatingMap = new Map<String, String>();
        Map<String, Date> customerIdCurrentRatingToolDateMap = new Map<String, Date>();
        if(res.data != null && res.data.size() > 0) {
            for(DMT_HPG_GlobalPosition.Data data : res.data) {
                if(!customerIdOperationMitigantDescMap.containsKey(data.customerId)) {
                    customerIdOperationMitigantDescMap.put(data.customerId, data.operationMitigantDesc);
                }
                if(!customerIdCustomerCounterpartiesCodesDescMap.containsKey(data.customerId)) {
                    customerIdCustomerCounterpartiesCodesDescMap.put(data.customerId, data.customerCounterpartiesCodesDesc);

                }
                if(!customerIdCurrentRatingMap.containsKey(data.customerId)) {
                    customerIdCurrentRatingMap.put(data.customerId, data.updSmsclInternalRatgType);
                }
                if(!customerIdCurrentRatingToolDateMap.containsKey(data.customerId)) {
                    customerIdCurrentRatingToolDateMap.put(data.customerId, data.currentRatingToolDate);

                }
            }
        }

        List<Custom_Association_Client__c> customAssociationClientsList = DMT_View_Selector.getCustomAssociationClient(customAssociationId);

        for(Custom_Association_Client__c client : customAssociationClientsList){
            if(customerIdOperationMitigantDescMap.containsKey(client.Alpha_Code_Client__c) && client.DMT_ClientContracts__c != customerIdOperationMitigantDescMap.get(client.Alpha_Code_Client__c)) {
                client.DMT_ClientContracts__c = customerIdOperationMitigantDescMap.get(client.Alpha_Code_Client__c);
            }
            if(customerIdCustomerCounterpartiesCodesDescMap.containsKey(client.Alpha_Code_Client__c) && client.DMT_ClientStarCode__c != customerIdCustomerCounterpartiesCodesDescMap.get(client.Alpha_Code_Client__c)) {
                client.DMT_ClientStarCode__c = customerIdCustomerCounterpartiesCodesDescMap.get(client.Alpha_Code_Client__c);
            }
            if(customerIdCurrentRatingMap.containsKey(client.Alpha_Code_Client__c) && client.DMT_ClientRating__c != customerIdCurrentRatingMap.get(client.Alpha_Code_Client__c)) {
                client.DMT_ClientRating__c = customerIdCurrentRatingMap.get(client.Alpha_Code_Client__c);
            }
            if(customerIdCurrentRatingToolDateMap.containsKey(client.Alpha_Code_Client__c) && client.DMT_Client_Rating_Date__c != customerIdCurrentRatingToolDateMap.get(client.Alpha_Code_Client__c)) {
                client.DMT_Client_Rating_Date__c = customerIdCurrentRatingToolDateMap.get(client.Alpha_Code_Client__c);
            }
        }

        return customAssociationClientsList;
    }

    public static LineDataWrapper loadRelatedData(String recordId, String type) {
        System.debug('loadRelatedData called with recordId: ' + recordId + ' and type: ' + type);
        LineDataWrapper data = new LineDataWrapper();
        data.riskLineToCurrencyProvisionMap = new Map<Id, DMT_Currency_Provision__c>();
        String recordTypeDeveloperName;
        if(type == 'Line'){
            recordTypeDeveloperName = 'OtherProducts';
        } else if(type == 'Line_Treasury') {
            recordTypeDeveloperName = 'TreasurySettlement';
        } else if (type == 'Opportunity'){
            recordTypeDeveloperName = 'DMT_Opportunity';
        }
        try {
            if(String.isBlank(type)){
                throw new DMT_CustomException('view type is empty');
            }
            if (type == 'Line' || type == 'Line_Treasury') {
                data.objectApiName = 'DMT_Line__c';
                data.line = [
                    SELECT Id, Name, Booking_Geography__c, DMT_Oficina__c, g_limit_last_level_type__c, Start_Date__c, End_Date__c, Line_Term__c, CurrencyIsoCode, DvP_Amount__c, FD_Amount__c, Line_Id__c, DMT_RecordTypeName__c,
                        DMT_LastLevelId__c, Amount__c, Client__c, Client__r.Name, Custom_Association__c, Custom_Association__r.g_customer_id__c, Client_Type__c, Repos_Limit__c, Repos_Limit_6M__c, First_Breakclause__c,
                        First_Breakclause_Date__c, RecordType.DeveloperName, RecordTypeId, DMT_GlobalBanker__c, Breakclause_Frequency__c, Waiver__c, DMT_Operation__c,
                        DMT_RAROEC_RORC_Proposal__c, DMT_Nominal__c, DMT_Comments__c, DMT_Franchise_L12M__c, DMT_Client_Rating_Date__c, DMT_ClientStarCode__c, DMT_Approver__c,
                        DMT_Approver__r.Name, DMT_Client_Use__c, DMT_ApproverGlobalBanker__c, DMT_Booking_Unit_Risk_Analyst__c, DMT_Booking_Unit_Risk_Analyst__r.Name,
                        DMT_ApproverGlobalBanker__r.Name, DMT_Additional_Restrictions__c, DMT_Client_Entific__c,g_line_commitment_level_type__c,
                        // CHILD LINE TEAM MEMBER
                            (
                                SELECT Full_Name_User__c, AccessLevel__c FROM Line_Team_Members__r),
                        // CHILD RISK LINE TERMS (PRODUCTS)
                            (
                                SELECT Id, Name, DMT_Init_Term__c, DMT_End_Term__c, DMT_Amount__c, DMT_Risk_Type__c, CurrencyIsoCode,
                                DMT_Parent_Product_Name__c, gf_group_priority_line_id__c, DMT_LastLevelId__c, DMT_Product__r.Name,
                                g_bullet_ind_type__c, g_smscl_internal_ratg_type__c, g_branch_id__c, g_limit_sinds_ast_sctr_id__c, g_limit_sinds_ast_subsec_id__c,
                                gf_inscol_months_grace_number__c, gf_loan_value_per__c, g_notary_crtfn_ind_type__c, g_gtee_public_adm_ind_type__c,
                                gf_loan_eca_cntrb_per__c, gf_min_raroec_fcg_per__c, gf_min_raroec_wo_fcg_per__c, gf_min_rorc_fcg_per__c,
                                gf_min_rorc_wo_fcg_per__c, gf_revolvence_pd_days_number__c, g_multioperation_ind_type__c, DMT_Comments__c,
                                g_global_product_family_Id__c, g_global_product_subfamily_Id__c, g_global_product_category_Id__c, g_gbl_product_subcategory_Id__c,
                                DMT_Max_Date__c, DMT_Singular_Active__c, DMT_Singular_Operation__c, DMT_Product_Name__c, DMT_Term__c, DMT_Singular__c,
                                // CHILD CURRENCY PROVISIONS
                                    (
                                        SELECT g_currency_id__c, DMT_Risk_Line_Term__c FROM DMT_Currency_Provisions__r
                                    ),
                                // CHILD WARRANTIES
                                    (
                                        SELECT Id, Name, DMT_Risk_Line_Term__c FROM DMT_Warranties__r
                                    )
                                FROM Risk_Line_Terms__r
                            ),
                            // CHILD LINE PRODUCTS
                            (
                                SELECT Name, DMT_DerivativeRestriction__c, DMT_FDRestriction__c, DMT_DVPRestriction__c, Max_Tenor_WC__c
                                FROM Line_Products__r
                            ),
                            // CHILD Custom_Associations__r
                            (
                                SELECT Id, g_customer_id__c, Name, gf_customer_group_id__c, // ESCD25LIN00006408ES_01 (if ends with _xx (number)) means its related to a product (risk line term) that has DMT_Line__r.Line_Id__c concatenated (_) gf_group_priority_line_id__c
                                // child Custom_Associations_Clients__r
                                (
                                    SELECT Name, Alpha_Code_Client__c, DMT_ClientStarCode__c, DMT_ClientContracts__c, DMT_ClientRating__c, DMT_Client_Rating_Date__c
                                    FROM Custom_Associations_Clients__r
                                )
                                FROM Custom_Associations__r
                            )
                    FROM DMT_Line__c
                    WHERE Id = :recordId
                    OR (Line_Id__c =:recordId AND RecordType.DeveloperName = :recordTypeDeveloperName AND Name != null AND Client_Type__c = 'Custom')
                    ORDER BY CreatedDate DESC LIMIT 1
                ];

                data.recordTypeId = data.line?.RecordTypeId;

                if (data.line.Custom_Association__c != null) {
                    data.customAssociationClientList = getUpdatedCustomAssociationClientList(data.line.Client__c, data.line.Custom_Association__c);
                    data.mainHolderCustomerId = data.line.Custom_Association__r.g_customer_id__c;
                }else{
                    System.debug(' data.line.Client__c: '+data.line.Client__c);
                    data.customAssociationClientList = getUpdatedCustomAssociationClientList(data.line.Client__c, null);
                    System.debug('data.customAssociationClientList: '+data.customAssociationClientList);
                    data.isNotMultiHolder = true;
                }

                data.currencyIsoCode = data.line?.CurrencyIsoCode ?? '';
                if(data.line != null && !data.line.Line_Team_Members__r.isEmpty()){
                    data.participantList.addAll(data.line.Line_Team_Members__r);
                }

                if(data.line != null && !data.line.Risk_Line_Terms__r.isEmpty()){
                     data.riskLineList.addAll(data.line.Risk_Line_Terms__r);
                }

                Set<Id> riskLineIds = new Set<Id>();

                Set<String> concatenatedValuesSet = new Set<String>();

                for (DMT_Risk_Line_Term__c risk : data.riskLineList) {
                    if (!risk.DMT_Currency_Provisions__r.isEmpty()) {
                        data.riskLineToCurrencyProvisionMap.put(risk.Id, risk.DMT_Currency_Provisions__r[0]);
                    }
                    if (!risk.DMT_Warranties__r.isEmpty()) {
                        data.riskLineToWarrantyListMap.put(risk.Id, risk.DMT_Warranties__r);
                    }
                    String concatenatedValue = data.line.Line_Id__c + '_' + risk.gf_group_priority_line_id__c;
                    concatenatedValuesSet.add(concatenatedValue);
                }

                // Build mainHolderProductsWrapperMap using the parent Custom_Associations__c key (gf_customer_group_id__c)
                if(!data.line.Custom_Associations__r.isEmpty()){
                    // Prebuild a lookup map from Alpha_Code_Client__c -> updated Custom_Association_Client__c
                    Map<String, Custom_Association_Client__c> updatedClientByAlpha = new Map<String, Custom_Association_Client__c>();
                    if (data.customAssociationClientList != null && !data.customAssociationClientList.isEmpty()){
                        for (Custom_Association_Client__c uc : data.customAssociationClientList){
                            if (uc.Alpha_Code_Client__c != null) {
                                updatedClientByAlpha.put(uc.Alpha_Code_Client__c, uc);
                            }
                        }
                    }

                    for(Custom_Association__c ca : data.line.Custom_Associations__r){
                        if(concatenatedValuesSet.contains(ca.gf_customer_group_id__c)){
                            // for each child client, add a wrapper under the parent's gf_customer_group_id__c key
                            for(Custom_Association_Client__c client : ca.Custom_Associations_Clients__r){
                                // Start with original values
                                String clientName = client.Name;
                                String internalRatingShort = client.DMT_ClientRating__c;
                                Date currentRatingToolDate = client.DMT_Client_Rating_Date__c;

                                // If we have an updated entry, use it (O(1) lookup) — avoids a 3rd nested loop
                                if (client.Alpha_Code_Client__c != null && updatedClientByAlpha.containsKey(client.Alpha_Code_Client__c)){
                                    Custom_Association_Client__c updatedClient = updatedClientByAlpha.get(client.Alpha_Code_Client__c);
                                    internalRatingShort = updatedClient.DMT_ClientRating__c;
                                    currentRatingToolDate = updatedClient.DMT_Client_Rating_Date__c;
                                    clientName = updatedClient.Name != null ? updatedClient.Name : clientName;
                                }

                                MainHolderProductsWrapper mainHolder = new MainHolderProductsWrapper();
                                mainHolder.clientName = clientName;
                                mainHolder.internalRatingShort = internalRatingShort;
                                mainHolder.currentRatingToolDate = currentRatingToolDate;

                                String key = ca.gf_customer_group_id__c;
                                if(!data.mainHolderProductsWrapperMap.containsKey(key)){
                                    List<MainHolderProductsWrapper> tempList = new List<MainHolderProductsWrapper>();
                                    tempList.add(mainHolder);
                                    data.mainHolderProductsWrapperMap.put(key, tempList);
                                } else {
                                    data.mainHolderProductsWrapperMap.get(key).add(mainHolder);
                                }
                            }
                        }
                    }
                }

                if(data.line != null && !data.line.Line_Products__r.isEmpty()){
                    data.lineProductList.addAll(data.line.Line_Products__r);
                }

                Map<String, String> familyMap      = getProductNameMapByLevel('Family');
                Map<String, String> subfamilyMap   = getProductNameMapByLevel('Subfamily');
                Map<String, String> categoryMap    = getProductNameMapByLevel('Category');
                Map<String, String> subcategoryMap = getProductNameMapByLevel('Subcategory');

                for (DMT_Risk_Line_Term__c risk : data.riskLineList) {
                    Map<String, String> productLevels = new Map<String, String>();
                    productLevels.put('familyProduct',      familyMap.get(risk.g_global_product_family_Id__c));
                    productLevels.put('subfamilyProduct',   subfamilyMap.get(risk.g_global_product_subfamily_Id__c));
                    productLevels.put('categoryProduct',    categoryMap.get(risk.g_global_product_category_Id__c));
                    productLevels.put('subcategoryProduct', subcategoryMap.get(risk.g_gbl_product_subcategory_Id__c));
                    data.productLevelsByRiskLine.put(risk.Id, productLevels);
                }

                Set<String> g_limit_sinds_ast_sctr_id = new Set<String>();
                Set<String> g_limit_sinds_ast_subsec_id = new Set<String>();
                Set<String> g_branch_id = new Set<String>();
                for (DMT_Risk_Line_Term__c risk : data.riskLineList) {
                    if (!String.isEmpty(risk.g_limit_sinds_ast_sctr_id__c)) {
                        g_limit_sinds_ast_sctr_id.add(risk.g_limit_sinds_ast_sctr_id__c);
                    }
                    if (!String.isEmpty(risk.g_limit_sinds_ast_subsec_id__c)) {
                        g_limit_sinds_ast_subsec_id.add(risk.g_limit_sinds_ast_subsec_id__c);
                    }
                    if (!String.isEmpty(risk.g_branch_id__c)) {
                        g_branch_id.add(risk.g_branch_id__c);
                    }
                }

                List<DMT_Taxonomy_Values__c> taxonomyValuesList = [SELECT Name, DMT_Value__c, DMT_Name_EN__c, DMT_Catalog__c FROM DMT_Taxonomy_Values__c
                                                                        WHERE DMT_Catalog__c IN ('C162', 'C164','H007')
                                                                        AND (
                                                                                    DMT_Value__c IN : g_limit_sinds_ast_sctr_id
                                                                                OR  DMT_Value__c IN : g_limit_sinds_ast_subsec_id
                                                                                OR  DMT_Value__c IN : g_branch_id
                                                                            )
                                                                        ORDER BY DMT_Catalog__c,DMT_Name_EN__c];

                Map<String, String> tax162Map = new Map<String, String>();
                Map<String, String> tax164Map = new Map<String, String>(); // could be just one map, but its separated for better readability.
                Map<String, String> taxH007Map = new Map<String, String>();
                for (DMT_Taxonomy_Values__c tax : taxonomyValuesList) {
                    if (tax.DMT_Value__c != null && tax.DMT_Catalog__c == 'C162') {
                        tax162Map.put(tax.DMT_Value__c, tax.DMT_Name_EN__c);
                    }
                    if (tax.DMT_Value__c != null && tax.DMT_Catalog__c == 'C164') {
                        tax164Map.put(tax.DMT_Value__c, tax.DMT_Name_EN__c);
                    }
                    if (tax.DMT_Value__c != null && tax.DMT_Catalog__c == 'H007') {
                        taxH007Map.put(tax.DMT_Value__c, tax.DMT_Name_EN__c);
                    }
                }

                // Mapear cada riskLine a su taxonomía correspondiente
                for (DMT_Risk_Line_Term__c risk : data.riskLineList) {
                    String key = risk.g_limit_sinds_ast_sctr_id__c;
                    if (!String.isEmpty(key)) {
                        if (tax162Map.containsKey(key)) {
                            data.riskLineToTaxonomyC162Map.put(risk.Id, tax162Map.get(key));
                        }
                    }
                    String key2 = risk.g_limit_sinds_ast_subsec_id__c;
                    if (!String.isEmpty(key2)) {
                        if (tax164Map.containsKey(key2)) {
                            data.riskLineToTaxonomyC164Map.put(risk.Id, tax164Map.get(key2));
                        }
                    }
                    String key3 = risk.g_branch_id__c;
                    if (!String.isEmpty(key3)) {
                        if (taxH007Map.containsKey(key3)) {
                            data.riskLineToTaxonomyH007Map.put(risk.Id, taxH007Map.get(key3));
                        }
                    }
                }
                data.featuresList = getFeatures(data.line.Id);system.debug('in features'+ data.featuresList);
                if (!data.featuresList.isEmpty()) {
                    List<String> featureIds = new List<String>();
                    //Integer numFeature = 0;
                    for (Map<String, Object> feature : data.featuresList) {
                        String id = (String) feature.get('id');
                        if (id != null){
                            featureIds.add(id);
                            List<DMT_Case_Steps_Controller.WRAPPER_Step> allStepsList = DMT_Case_Steps_Controller.getStepsFromFeature(id, data.line.Line_Id__c);system.debug('in allStepsList'+ allStepsList);
                            if(!allStepsList.isEmpty()){
                                data.allsteps.add(allStepsList[0]);
                            }

                            //data.allsteps[numFeature].subitems.add(allStepsList);
                            //numFeature++;
                        }

                    }
                    data.steps = DMT_Case_Steps_Controller.getCurrentStepFromFeatures(featureIds, data.line.Line_Id__c);system.debug('in steps'+ data.steps);
                }
            } else if (type == 'Opportunity') {
                System.debug('recordTypeDeveloperName  '+ recordTypeDeveloperName);
                System.debug('recordId  '+ recordId);
                data.objectApiName = 'Opportunity';
                data.opportunity = DMT_View_Selector.getOpportunityWithRelatedData(recordId, recordTypeDeveloperName);
                data.recordTypeId = data.opportunity?.RecordTypeId;
                data.currencyIsoCode = data.opportunity.CurrencyIsoCode;
                if(!data.opportunity.getPopulatedFieldsAsMap().isEmpty()){
                    if(!data.opportunity.X_sell__r.isEmpty()){
                        data.xSellOpp.addAll(data.opportunity.X_sell__r);
                    }
                    if(!data.opportunity.Deal_Team_Members__r.isEmpty()){
                        data.participantList.addAll(data.opportunity.Deal_Team_Members__r);
                    }
                    if(!data.opportunity.DMT_MDE_Opportunities_Clients__r.isEmpty()){
                        //CLIENT AND APPROVAL PROCESS DATA
                        data.oppClient = (data.opportunity.DMT_MDE_Opportunities_Clients__r[0]);
                    }
                    if(!data.opportunity.OpportunityLineItems.isEmpty()){
                        Set<String> oppLinesBranchIds = new Set<String>();
                        Set<String> oppLinesRiskTypes = new Set<String>();
                        Set<String> oppLinesCountryRisk = new Set<String>();
                        for(OpportunityLineItem oppItem : data.opportunity.OpportunityLineItems){
                            oppLinesBranchIds.add(oppItem.g_branch_id__c);
                            oppLinesRiskTypes.add(oppItem.DMT_Risk_Type__c);
                            oppLinesCountryRisk.add(oppItem.gf_country_risk__c);

                        }
                        List<DMT_Taxonomy_Values__c> taxonomyValuesList = [SELECT Name, DMT_Value__c, DMT_Name_EN__c, DMT_Catalog__c FROM DMT_Taxonomy_Values__c
                                                                            WHERE DMT_Catalog__c IN ('H007', 'B444', 'C245', 'H006', 'CD07')
                                                                            AND (
                                                                                DMT_Value__c IN : oppLinesBranchIds
                                                                                OR DMT_Value__c IN : oppLinesRiskTypes
                                                                                OR DMT_Value__c IN : oppLinesCountryRisk
                                                                                OR DMT_Value__c = : data.opportunity.Entific__c
                                                                                OR DMT_Value__c = : data.opportunity.DMT_Entity__c
                                                                            ) ORDER BY DMT_Catalog__c,DMT_Name_EN__c];
                        Map<String, String> taxH007Map = new Map<String, String>();
                        Map<String, String> taxB444Map = new Map<String, String>(); // could be just one map, but its separated for better readability.
                        Map<String, String> taxC245Map = new Map<String, String>();
                        Map<String, String> taxH006Map = new Map<String, String>();
                        Map<String, String> taxCD07Map = new Map<String, String>();
                        for (DMT_Taxonomy_Values__c tax : taxonomyValuesList) {
                            if (tax.DMT_Value__c != null && tax.DMT_Catalog__c == 'H007') {
                                taxH007Map.put(tax.DMT_Value__c, tax.DMT_Name_EN__c);
                            }
                            if (tax.DMT_Value__c != null && tax.DMT_Catalog__c == 'B444') {
                                taxB444Map.put(tax.DMT_Value__c, tax.DMT_Name_EN__c);
                            }
                            if (tax.DMT_Value__c != null && tax.DMT_Catalog__c == 'C245') {
                                taxC245Map.put(tax.DMT_Value__c, tax.DMT_Name_EN__c);
                            }
                            if (tax.DMT_Value__c != null && tax.DMT_Catalog__c == 'H006') {
                                taxH006Map.put(tax.DMT_Value__c, tax.DMT_Name_EN__c);
                            }
                            if (tax.DMT_Value__c != null && tax.DMT_Catalog__c == 'CD07') {
                                taxCD07Map.put(tax.DMT_Value__c, tax.DMT_Name_EN__c);
                            }
                        }
                        data.oppEntific = taxCD07Map.containsKey(data.opportunity.Entific__c) ? taxCD07Map.get(data.opportunity.Entific__c) : '';
                        data.oppEntity = taxH006Map.containsKey(data.opportunity.DMT_Entity__c) ? taxH006Map.get(data.opportunity.DMT_Entity__c) : '';
                        for(OpportunityLineItem oppItem : data.opportunity.OpportunityLineItems){
                            OpportunityProduct oppProduct = new OpportunityProduct();
                            //Detail
                            oppProduct.name = !String.isBlank(oppItem.DMT_TXT_ProductNameOLI__c) ? oppItem.DMT_TXT_ProductNameOLI__c : oppItem.DES_Product_Name__c;
                            oppProduct.bookingGeography = taxH007Map.containsKey(oppItem.g_branch_id__c) ? taxH007Map.get(oppItem.g_branch_id__c) : '';
                            oppProduct.riskType = taxB444Map.containsKey(oppItem.DMT_Risk_Type__c) ? taxB444Map.get(oppItem.DMT_Risk_Type__c) : '';
                            oppProduct.initialDate = oppItem.gf_initial_date__c;
                            oppProduct.maturityDate = oppItem.gf_maturity_date__c;
                            oppProduct.comments = oppItem.DMT_TXA_Comentarios__c;

                            //Amortization
                            oppProduct.amortizationType = oppitem.gf_amortization_type__c;
                            oppProduct.paymentFrequency = oppItem.gf_payment_frequency__c;
                            oppProduct.amortizationScheduleCurrency = !oppItem.Opportunity_Tenors__r.isEmpty() ? oppItem.Opportunity_Tenors__r[0].CurrencyIsoCode ?? oppitem.CurrencyIsoCode : oppItem.CurrencyIsoCode;
                            oppProduct.oppTenors.addAll(oppItem.Opportunity_Tenors__r);

                            //Funding
                            oppProduct.currencyIsoCode = oppItem.CurrencyIsoCode;
                            oppProduct.socialBonus = oppItem.gf_social_bond__c;
                            oppProduct.greenBonus = oppItem.gf_green_bonus__c;
                            oppProduct.fundingUndrawnBPS = oppItem.gf_funding_cost_fb__c;
                            oppProduct.fundingDrawnBPS = oppItem.gf_funding_cost_db__c;
                            oppProduct.fundingTerm = oppItem.Life_Funding_Type__c;
                            oppProduct.fundingCurve = oppItem.Funding_Curve__c;

                            //Country Risk
                            oppProduct.country = taxC245Map.containsKey(oppItem.gf_country_risk__c) ? taxC245Map.get(oppItem.gf_country_risk__c) : '';
                            oppProduct.countryRating = oppItem.gf_country_rating__c;

                            //Mitigants
                            oppProduct.currencyMitigant = !oppItem.Opportunity_Mitigants__r.isEmpty() ? oppItem.Opportunity_Mitigants__r[0].CurrencyIsoCode ?? oppitem.CurrencyIsoCode : oppItem.CurrencyIsoCode;
                            oppProduct.oppMitigants.addAll(oppItem.Opportunity_Mitigants__r);

                            data.oppProducts.add(oppProduct);

                        }
                    }


                    data.featuresList = getFeatures(data.opportunity.Id);
                    if (!data.featuresList.isEmpty()) {
                        List<String> featureIds = new List<String>();
                        for (Map<String, Object> feature : data.featuresList) {
                            String id = (String) feature.get('id');
                            if (id != null) featureIds.add(id);
                        }
                        data.steps = DMT_Case_Steps_Controller.getCurrentStepFromFeaturesOpp(featureIds, data.opportunity.DMT_Opp_Id__c);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error on loadRelatedData, ' + e.getLineNumber());
            System.debug('Error on loadRelatedData, ' + e.getMessage());
         //   System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_ViewController','loadRelatedData','DMT',''));
            throw new DMT_CustomException('Error in loadRelatedData: ' + e.getMessage() + ' line number: '+ e.getLineNumber());
        }
        return data;
    }

    @AuraEnabled(cacheable=true)
    public static string getRecordId(String objectApiName, String recordTypeApiName){
        String lineIdField;
        if (objectApiName == 'DMT_Line__c') {
            lineIdField = 'Line_Id__c';
        } else if (objectApiName == 'Opportunity') {
            lineIdField = 'DMT_Opp_Id__c';
        } else {
            throw new AuraHandledException('Unsupported object: ' + objectApiName);
        }

        String soql = 'SELECT Id, CurrencyIsoCode, ' + lineIdField +
            ' FROM ' + objectApiName +
            ' WHERE ' + lineIdField + ' != null' +
            ' AND RecordType.DeveloperName = :recordTypeApiName';
            if(objectApiName == 'DMT_Line__c'){
                String clientTypeValue = 'Custom';
                soql += ' AND Name != null AND Client_Type__c = :clientTypeValue';
            }
            soql += ' ORDER BY CreatedDate DESC LIMIT 1';

        List<SObject> records = Database.query(String.escapeSingleQuotes(soql), AccessLevel.SYSTEM_MODE);

        Map<String, String> resultMap = new Map<String, String>();
            resultMap.put('Id', (String) records[0].get('Id'));
            resultMap.put('CurrencyIsoCode', (String) records[0].get('CurrencyIsoCode'));


        return records.isEmpty() ? null : JSON.serialize(resultMap);
    }

    public static String loadJSONFromSelectedItems(String lineId, String type, String items) {
        String viewType = 'PDF';
        Map<String, Object> rawResult = (Map<String, Object>) JSON.deserializeUntyped(loadComponentsForView(lineId, type, items, '', null));

        // Convert into Map<String, String>
        Map<String, String> resultMap = new Map<String, String>();
        for (String key : rawResult.keySet()) {
            resultMap.put(key, (String) rawResult.get(key));
        }

        return resultMap.get('PDF');
    }
    @AuraEnabled(cacheable=true)
    public static String getItemsToDisplay(String recordOrLineId, String objectApiName) {
        return getItemsToDisplayExtended(recordOrLineId, objectApiName, '');
    }

    @AuraEnabled(cacheable=true)
    public static String getItemsToDisplayExtended(String recordOrLineId, String objectApiName, String taskId){
        List<ItemWrapper> itemsList = new List<ItemWrapper>();
        String recordId = '';
        String viewType = '';

        Map<String, String> resultMap = new Map<String, String>();

        try {
            if(objectApiName == 'Opportunity'){
                for (DMT_Items__c item : [SELECT Id, Type_Item__c, DMT_Component_Item__c, DMT_order_display__c, DMT_Text__c FROM DMT_Items__c WHERE DMT_View__r.Profitability__c = true ORDER BY DMT_order_display__c ASC]) {
                        itemsList.add(new ItemWrapper(item.Type_Item__c, item.DMT_Component_Item__c,item.DMT_order_display__c,item.DMT_Text__c));
                    }
                    resultMap.put('recordId', recordOrLineId);
                    resultMap.put('recordTypeApiName', 'DMT_Opportunity');
                    viewType = 'Opportunity';

            } else if(objectApiName == 'Case'){
                String owmnerView;

                List<Case> caseRecord = DMT_View_Selector.getCaseApprover(recordOrLineId);
                if(String.isNotBlank(taskId)){
                  List<Task> taskRecord =  DMT_View_Selector.getTaskApprover(taskId, recordOrLineId);
                  owmnerView = taskRecord[0].OwnerId;

                }else{
                    owmnerView = caseRecord[0].OwnerId;
                }
                if(caseRecord[0].DMT_Line__c != null && caseRecord[0].DMT_LineOpportunity__c == 'L' ){
                    resultMap.put('recordId', caseRecord[0].DMT_Line__c);
                }else if(caseRecord[0].opportunity_id__c != null && caseRecord[0].DMT_LineOpportunity__c == 'O' ){
                    resultMap.put('recordId', caseRecord[0].opportunity_id__c);
                }else{
                    System.debug(LoggingLevel.ERROR, 'The record ID in DMT_ViewController was not found in the getItemsToDisplayExtended method.');
                }
                List<Group> groupRecord = DMT_View_Selector.getGroup(owmnerView );
                System.debug('groupRecord developerName, '+ groupRecord[0].DeveloperName);
                List<DMT_Approver__c> approver = DMT_View_Selector.getApprover(groupRecord[0].DeveloperName);

                Id approverViewId;
                //String rtName = caseRecord[0].DMT_Line__r.RecordType.DeveloperName;
                //resultMap.put('recordTypeApiName', rtName);
                if(caseRecord[0].DMT_LineOpportunity__c == 'L'){
                    if (caseRecord[0].DMT_Line__r.RecordType.DeveloperName == 'OtherProducts') {
                        viewType = 'Line';
                        approverViewId = approver[0].Approvers_View__c;
                        resultMap.put('recordTypeApiName','OtherProducts');
                    } else if (caseRecord[0].DMT_Line__r.RecordType.DeveloperName == 'TreasurySettlement') {
                        viewType = 'Line_Treasury';
                        approverViewId = approver[0].Approvers_View_Treasury__c;
                        resultMap.put('recordTypeApiName','TreasurySettlement');
                    }
                } else if(caseRecord[0].DMT_LineOpportunity__c == 'O') {
                    viewType = 'Opportunity';
                    resultMap.put('recordTypeApiName','DMT_Opportunity');
                    approverViewId = approver[0].Approvers_View_Opportunity__c;
                }
                if(approverViewId == null){
                    System.debug(LoggingLevel.ERROR, 'The approverViewId is null in DMT_ViewController in the getItemsToDisplayExtended method.');
                } else {
                    List<DMT_Items__c> dmtItemsList = new List<DMT_Items__c>();
                    dmtItemsList = [SELECT Id, Type_Item__c, DMT_Component_Item__c, DMT_order_display__c, DMT_Text__c FROM DMT_Items__c  WHERE DMT_View__c = :approverViewId ORDER BY DMT_order_display__c ASC];

                    if(!dmtItemsList.isEmpty() && dmtItemsList.size() > 0){
                        for (DMT_Items__c item : dmtItemsList) {
                            itemsList.add(new ItemWrapper(item.Type_Item__c, item.DMT_Component_Item__c,item.DMT_order_display__c,item.DMT_Text__c));
                        }
                    } else {
                        List<String> components = DMT_ItemController.getFilteredComponentItemOptions(viewType);

                        for (String component : components) {
                            ItemWrapper item = new ItemWrapper();
                            item.component = component;
                            itemsList.add(item);
                        }
                    }
                }

            }
            resultMap.put('viewType', viewType);
            resultMap.put('items', JSON.serialize(itemsList));
            return JSON.serialize(resultMap);
        } catch (Exception e) {
            System.debug('Error on getItemsToDisplay, ' + e.getLineNumber());
            System.debug('Error on getItemsToDisplay, ' + e.getMessage());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_ViewController','getItemsToDisplay','DMT',''));
            throw new AuraHandledException('Error retrieving items to display: ' + e.getMessage() + 'line number: ' + e.getLineNumber());
        }
    }

    @AuraEnabled(cacheable=false)
    public static string loadComponentsForView(String recordOrLineId, String viewType, String selectedItems, String productId, String itemsImg){
        System.debug('loadComponentsForView selectedItems: '+selectedItems);
        try{
            List<ItemWrapper> itemsList =(List<ItemWrapper>) JSON.deserialize(selectedItems, List<ItemWrapper>.class);
            String renderedHtmlData = '';
            String renderedPdfData = '';
            LineDataWrapper data = loadRelatedData(recordOrLineId, viewType);
            if(itemsImg != null && !String.isEmpty(itemsImg)){
                List<ItemImgB64> b64Img = (List<ItemImgB64> ) JSON.deserialize(itemsImg, List<ItemImgB64>.class);
                data.itemImgBase64 = b64Img;
            }

            data.isImg64 = !String.isEmpty(itemsImg);
            if(!data.opportunity.getPopulatedFieldsAsMap().isEmpty() && !data.opportunity.OpportunityLineItems.isEmpty() && !String.isBlank(productId)){
                for(Integer i = (data.opportunity.OpportunityLineItems.size()-1) ; i>= 0 ; i--){
                    OpportunityLineItem oli = data.opportunity.OpportunityLineItems[i];
                    if(oli.Id != productId){
                        data.opportunity.OpportunityLineItems.remove(i);
                    }
                }
            }
            for (ItemWrapper item : itemsList) {
                System.debug('Rendering html component: ' + item.component);
                renderedHtmlData += generateHtmlForComponent(item.component, item.textValue, data);
            }

            renderedPdfData = generatePdfJsonForComponent(itemsList, data);

            Map<String, String> resultMap = new Map<String, String>();
            resultMap.put('HTML', renderedHtmlData);
            resultMap.put('PDF', renderedPdfData);

            return JSON.serialize(resultMap);
        } catch (Exception e) {
            System.debug('Error on loadComponentsForView, ' + e.getLineNumber());
            System.debug('Error on loadComponentsForView, ' + e.getTypeName());
            System.debug('Error on loadComponentsForView, ' + e.getMessage());
            List<DMT_AsyncPayload> batchPayloads = new List<DMT_AsyncPayload>();
            batchPayloads.add(new DMT_LogExceptionPayload(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_ViewController','loadComponentsForView', 'DMT', ''));
            Database.executeBatch(new DMT_AsyncBatchJob(batchPayloads), 1);
            Map<String, String> resultMap = new Map<String, String>();
            resultMap.put('HTML', '');
            resultMap.put('PDF', '');
            resultMap.put('error', '<div class="error-message">An unexpected error has occurred. ' + e.getMessage() + '</div>');
            return JSON.serialize(resultMap);
         //   return '<div>An unexpected error has occurred. '+e.getMessage()+'</div>';
        }
    }

    private static String generatePdfJsonForComponent(List<ItemWrapper> itemsList, LineDataWrapper data){

        Map<String, Object> componentsCreate = new Map<String, Object>();
        Map<String, Object> component = new Map<String, Object>();
        List<Map<String, Object>> componentsList = new List<Map<String, Object>>();
         for (ItemWrapper item : itemsList) {
             System.debug('Generating PDF component: ' + item.component);
             switch on item.component {
                when 'Line Info', 'Client', 'Approval Process Data', 'Participants', 'Products', 'Passport', 'Limit', 'Limit Visual', 'Opportunity Info', 'Commercial Process Data', 'Approval Process', 'Validation Process', 'Transaction Overview', 'Economics' {
                    component = DMT_RendererFactory.getRenderer(item.component).renderPdfJson(data);
                    if(component != null && !component.isEmpty()){
                        componentsList.add(component);
                    }
                }
                when 'Page Break' {
                    Map<String, Object> pageBreakComponent = new Map<String, Object>{
                        'content' => new List<Object>{
                            new Map<String, Object>{
                                'type' => 'pageBreak',
                                'threshold' => 0
                            }
                        }
                    };
                    componentsList.add(pageBreakComponent);
                }
                when 'Line Break' {
                    Map<String, Object> lineBreakComponent = new Map<String, Object>{
                        'content' => new List<Object>{
                            new Map<String, Object>{
                                'type' => 'lineBreak'
                            }
                        }
                    };
                    componentsList.add(lineBreakComponent);
                }
                when 'Text 12px' {
                    List<Object> contentList = new List<Object>();
                    Map<String, Object> detailTitle = DMT_Create_Pdf_Controller.createTitle(item.textValue);
                    detailTitle.put('type', 'text');
                    Map<String, Object> style = (Map<String, Object>) detailTitle.get('style');
                    style.put('fontSize', 12);
                    style.put('textColor', '#004481');
                    contentList.add(detailTitle);
                    Map<String, Object> textComponent = new Map<String, Object>{
                        'content' => contentList
                    };
                    componentsList.add(textComponent);
                }
                when 'Text 18px' {
                    List<Object> contentList = new List<Object>();
                    Map<String, Object> detailTitle = DMT_Create_Pdf_Controller.createTitle(item.textValue);
                    detailTitle.put('type', 'text');
                    Map<String, Object> style = (Map<String, Object>) detailTitle.get('style');
                    style.put('fontSize', 18);
                    style.put('textColor', '#004481');
                    contentList.add(detailTitle);
                    Map<String, Object> textComponent = new Map<String, Object>{
                        'content' => contentList
                    };
                    componentsList.add(textComponent);
                }
                when 'Text 14px' {
                    List<Object> contentList = new List<Object>();
                    Map<String, Object> detailTitle = DMT_Create_Pdf_Controller.createTitle(item.textValue);
                    detailTitle.put('type', 'text');
                    Map<String, Object> style = (Map<String, Object>) detailTitle.get('style');
                    style.put('fontSize', 14);
                    style.put('textColor', '#004481');
                    contentList.add(detailTitle);
                    Map<String, Object> textComponent = new Map<String, Object>{
                        'content' => contentList
                    };
                    componentsList.add(textComponent);
                }
             }
         }
        // CONFIGURATION OF THE COMPONENT CUSTOM
        Map<String, Object> pdfStructure = new Map<String, Object>{
            'components' => componentsList,
            'styles' => new Map<String, Object>{
                'text' => new Map<String, Object>{'fontSize' => 12},
                'pageNumber' => new Map<String, Object>{'fontSize' => 8, 'fontStyle' => 'italic'},
                'date' => new Map<String, Object>{'fontSize' => 8, 'fontStyle' => 'italic'},
                'footer' => new Map<String, Object>{'fontSize' => 8},
                'subtitle' => new Map<String, Object>{'fontSize' => 12},
                'title' => new Map<String, Object>{'fontSize' => 12}
            },
            'showPageNumber' => true,
            'showLogo' => true,
            'showFooter' => true,
            'showHeader' => true,
            'margin' => new Map<String, Object>{'left' => 15, 'bottom' => 25, 'right' => 15, 'top' => 35},
            'format' => 'a4',
            'filename' => 'DMT VIEW.pdf'
        };
        return JSON.serialize(pdfStructure);
    }

   private static Map<String, Map<String, String>> allProductNameMaps;

    private static Map<String, String> getProductNameMapByLevel(String level) {
        if (allProductNameMaps == null) {
            allProductNameMaps = initializeProductNameMaps();
        }
        return allProductNameMaps.get(level);
    }

    private static Map<String, Map<String, String>> initializeProductNameMaps() {
        Map<String, Map<String, String>> maps = new Map<String, Map<String, String>>{
            'Family' => new Map<String, String>(),
            'Subfamily' => new Map<String, String>(),
            'Category' => new Map<String, String>(),
            'Subcategory' => new Map<String, String>()
        };

        List<Product2> products = [
            SELECT DMT_Classification_Level__c, DMT_Product_family__c, DMT_Product_Subfamily__c,
                DMT_Product_category__c, DMT_Product_Subcategory__c, Name
            FROM Product2
            WHERE DMT_Classification_Level__c IN :maps.keySet()
            AND Family = 'DMT Lines'
        ];

        for (Product2 p : products) {
            switch on p.DMT_Classification_Level__c {
                when 'Family' {
                    if (String.isNotBlank(p.DMT_Product_family__c)) {
                        maps.get('Family').put(p.DMT_Product_family__c, p.Name);
                    }
                }
                when 'Subfamily' {
                    if (String.isNotBlank(p.DMT_Product_Subfamily__c)) {
                        maps.get('Subfamily').put(p.DMT_Product_Subfamily__c, p.Name);
                    }
                }
                when 'Category' {
                    if (String.isNotBlank(p.DMT_Product_category__c)) {
                        maps.get('Category').put(p.DMT_Product_category__c, p.Name);
                    }
                }
                when 'Subcategory' {
                    if (String.isNotBlank(p.DMT_Product_Subcategory__c)) {
                        maps.get('Subcategory').put(p.DMT_Product_Subcategory__c, p.Name);
                    }
                }
            }
        }
        return maps;
    }

    // Parametro para saber desde donde venimos y mostrar la linea solo en el html de la vista
    // Método para generar el HTML de cada componente
    @TestVisible
    private static String generateHtmlForComponent(String componentItem, String text, LineDataWrapper data) {

        switch on componentItem {
            when 'Line Info', 'Client', 'Approval Process Data', 'Participants', 'Products', 'Passport', 'Limit', 'Limit Visual', 'Opportunity Info', 'Commercial Process Data', 'Approval Process', 'Validation Process', 'Transaction Overview', 'Economics' {
                return DMT_RendererFactory.getRenderer(componentItem).renderHtml(data);
            }
             when 'Page Break' {
                return '<div style="border-top: 2px dashed #004481; margin: 20px 0; page-break-after: always;"></div>';
            }
            when 'Line Break' {
                return '&nbsp;</br>';
            }
            when 'Text 12px' {
                return '<div style="font-size: 12px; color: #004481; margin-bottom: 10px;">'+DMT_FormattingUtils.checkNull(text)+'</div>';
            }
            when 'Text 18px' {
                return '<div style="font-size: 18px; color: #004481; margin-bottom: 10px;">'+DMT_FormattingUtils.checkNull(text)+'</div>';
            }
            when 'Text 14px' {
                return '<div style="font-size: 14px; color: #004481; margin-bottom: 10px;">'+DMT_FormattingUtils.checkNull(text)+'</div>';
            }
            when else {
                return '<div>'
                     + '<h1 style="color: #004481;">Contenido por defecto</h1>'
                     + '<p>Este es el contenido por defecto cuando no se encuentra una opción específica.</p>'
                     + '</div>';
            }
        }
    }

    @AuraEnabled
    public static String generateContentDocumentForView(String caseId, String taskId, String documentType, String itemsB64) {
        try {
            Blob contentDcBlob;
            String templateDocumentType = '';
            String extension;
            String contentTitle;

            if (documentType == 'PDF') {
                // keep PDF logic as-is
                contentDcBlob = EncodingUtil.base64Decode(itemsB64);
                contentTitle = 'Task completed PDF';
                extension = '.pdf';

                if (taskId != null) {
                    List<ContentDocumentLink> listCdl = [
                        SELECT ContentDocumentId, ContentDocument.FileType
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId = :taskId
                        AND ContentDocument.LatestPublishedVersion.Is_Template_PDF__c = true
                    ];
                    for (ContentDocumentLink cdl : listCdl) {
                        if (cdl.ContentDocument.FileType == 'PDF') {
                            System.debug('A PDF document related to this task already exists.');
                            return 'A PDF document related to this task already exists.';
                        }
                    }
                }
            } else {
                 // First normalize with getItemsToDisplay
                Map<String, Object> itemsToDisplay = (Map<String, Object>) JSON.deserializeUntyped(getItemsToDisplayExtended(caseId, 'Case', taskId));
                List<ItemWrapper> itemsList = (List<ItemWrapper>) JSON.deserialize((String) itemsToDisplay.get('items'), List<ItemWrapper>.class);
                String viewType = (String) itemsToDisplay.get('viewType');
                String recordId = (String) itemsToDisplay.get('recordId');
                // Call centralized renderer
                Map<String, Object> rawResult = (Map<String, Object>) JSON.deserializeUntyped(loadComponentsForView(recordId, viewType, JSON.serialize(itemsList), '', itemsB64));

                // Convert into Map<String, String>
                Map<String, String> resultMap = new Map<String, String>();
                for (String key : rawResult.keySet()) {
                    resultMap.put(key, (String) rawResult.get(key));
                }

           //     return resultMap.get('PDF');
           //     Map<String, String> resultMap = (Map<String, String>) JSON.deserializeUntyped(resultMapStr);

                templateDocumentType = documentType == 'HTML' ? resultMap.get('HTML') : resultMap.get('PDF');
                contentTitle = 'Task completed ' + documentType;
                extension = documentType == 'HTML' ? '.html' : '.json';
                contentDcBlob = Blob.valueOf(templateDocumentType);
            }

            // Insert ContentVersion
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = contentTitle;
            contentVersion.PathOnClient = 'taskCompleted' + extension;
            contentVersion.VersionData = contentDcBlob;
            contentVersion.IsMajorVersion = true;
            contentVersion.Is_Template_PDF__c = true;
            insert contentVersion;

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id = :contentVersion.Id
            ].ContentDocumentId;
            cdl.LinkedEntityId = taskId;
            cdl.ShareType = 'V';
            insert cdl;

            return 'Success document creation';
        } catch (Exception e) {
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_ViewController','generateContentDocumentForView','DMT',''));
            System.debug('Error creating document generateContentDocumentForView: ' + e.getMessage());
            System.debug('Error creating document generateContentDocumentForView line number: ' + e.getLineNumber());
            return 'Error creating document';
        }
    }

    @AuraEnabled
    public static String fileTypeDocument(String taskId){
        List<ContentDocumentLink> listCdl = new List<ContentDocumentLink>();
        listCdl = [SELECT ContentDocumentId, ContentDocument.FileType
                                            FROM ContentDocumentLink
                                            WHERE LinkedEntityId =:taskId
                                            AND ContentDocument.LatestPublishedVersion.Is_Template_PDF__c = true];

        Boolean isHTML = false;
        Boolean isPDF = false;
        Boolean isJSON = false;
        for(ContentDocumentLink cdl : listCdl){
            if(cdl.ContentDocument.FileType == 'HTML' || cdl.ContentDocument.FileType == 'text/html'){isHTML = true;}
            else if(cdl.ContentDocument.FileType == 'PDF' || cdl.ContentDocument.FileType == 'application/pdf'){isPDF = true;}
            else if(cdl.ContentDocument.FileType == 'JSON' || cdl.ContentDocument.FileType == 'application/json'){isJSON = true;}
        }
        if(isHTML) return 'HTML';
        if(isPDF) return 'PDF';
        if(isJSON) return 'JSON';

        return null;
    }

}