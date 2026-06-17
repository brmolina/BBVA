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
        // --- Existing General Fields ---
        public String name;
        public String bookingGeography;
        public String riskType;
        public Date initialDate;
        public Date maturityDate;
        public String comments;
        public String commitment;

        // --- NEW: General Fields ---
        public String useOfProceeds;

        // --- Existing Amortization Fields ---
        public String amortizationType;
        public String paymentFrequency;
        public String currencyIsoCode;
        public String amortizationScheduleCurrency;
        public List<DMT_Opportunity_Tenor__c> oppTenors = new List<DMT_Opportunity_Tenor__c>();

        // --- NEW: Amortization Fields ---
        public Boolean bullet;
        public Boolean balloon;
        public String TenorsCurrency;
        public Decimal dealAmountTenors;
        public Decimal gf_accrual_fees_bp;
        public Decimal extensionDurationFees;
        public Decimal newMoney;
        public Decimal oldMoney;
        public Decimal expectedFinalTake;
        public Decimal expectedDrawn;
        public Decimal dealAmount;
        public Decimal bbvaPrtcpTrancheAmount;
        public Decimal liquidityFee;
        public Decimal commitmentFees;
        public Decimal otherFees;
        public Decimal expectedFinalTakeBBVA;

        // --- Existing Funding Fields ---
        public Boolean socialBonus;
        public Boolean greenBonus;
        public Double fundingUndrawnBPS;
        public Double fundingDrawnBPS;
        public String fundingTerm;
        public String fundingCurve;

        public String rateType;
        public String pricingGrid;

        // --- NEW: Sustainability Fields ---
        public String sustainableDealAssessment;
        public String sustainableDealSubtype;
        public String sustainableDealValue;
        public String sustainableDealLabel;
        public String greenActivityFilter;
        public String sustainablePercentage;
        public String sustainabilityBonusEligible;

        // --- Existing Country Risk & Mitigant Fields ---
        public String country;
        public String countryRating;
        public List<DMT_Opportunity_Mitigant__c> oppMitigants = new List<DMT_Opportunity_Mitigant__c>();
        public String currencyMitigant;
    }
    public class LineDataWrapper {
        public String objectApiName;
        public String recordTypeId;

        public String statusLineOrOpp;
        public String closeLine;
        public String recordTypeName;
        public String lineName;
        public String recordLineId;

        public DMT_Line__c line = new DMT_Line__c();
        public Opportunity opportunity = new Opportunity();
        public Account clientAccount = new Account();
        public DMT_Opportunity_Client__c oppClient = new DMT_Opportunity_Client__c();
        public List<OpportunityProduct> oppProducts = new List<OpportunityProduct>();

        public List<DMT_X_Sell__c> xSellOpp = new List<DMT_X_Sell__c>();

        public List<Custom_Association_Client__c> customAssociationClientList = new List<Custom_Association_Client__c>();
        public List<DMT_Line__c> activeRelatedLines = new List<DMT_Line__c>();
        public List<DMT_TeamMember__c> participantList = new List<DMT_TeamMember__c>();
        public List<DMT_Risk_Line_Term__c> riskLineList = new List<DMT_Risk_Line_Term__c>();
        public List<DMT_Line_Product_Item__c> lineProductList = new List<DMT_Line_Product_Item__c>();
        public List<Map<String, Object>> featuresList = new List<Map<String, Object>>();
        public List<DMT_Case_Steps_Controller.WRAPPER_Step> steps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        public List<DMT_Case_Steps_Controller.WRAPPER_Step> allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        public List<Map<String, Object>> sanctionFeaturesList = new List<Map<String, Object>>();
        public List<DMT_Case_Steps_Controller.WRAPPER_Step> sanctionSteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        public List<DMT_Case_Steps_Controller.WRAPPER_Step> sanctionAllsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        // Sanction Line view: features/steps belonging to its child Opportunity (Opportunity.DMT_Sanction__c)
        public List<Map<String, Object>> sanctionOppFeaturesList = new List<Map<String, Object>>();
        public List<DMT_Case_Steps_Controller.WRAPPER_Step> sanctionOppSteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        public List<DMT_Case_Steps_Controller.WRAPPER_Step> sanctionOppAllsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        public String currencyIsoCode;

        public Map<Id, DMT_Currency_Provision__c> riskLineToCurrencyProvisionMap = new Map<Id, DMT_Currency_Provision__c>();
        public Map<Id, Map<String, String>> productLevelsByRiskLine = new Map<Id, Map<String, String>>();
        public Map<Id, List<DMT_Warranty__c>> riskLineToWarrantyListMap = new Map<Id, List<DMT_Warranty__c>>();
        public Map<Id, String> riskLineToTaxonomyC162Map = new Map<Id, String>();
        public Map<Id, String> riskLineToTaxonomyC164Map = new Map<Id, String>();
        public Map<Id, String> riskLineToTaxonomyH007Map = new Map<Id, String>();
        public Map<Id, String> riskLineToTaxonomyALATMap = new Map<Id, String>();
        public Map<String, String> taxonomyH007Map = new Map<String, String>(); // NEW: Exposes H007 to Renderers
        public Boolean isImg64;
        public List<ItemImgB64> itemImgBase64 = new List<ItemImgB64>();
        public List<Map<String, Object>> closedWonVersions = new List<Map<String, Object>>();

        public String oppEntity;
        public String oppEntific;
        public String oppBookingGeography;

        public String mainHolderCustomerId;
        public String ratingMonoHolder;
        public Boolean isSubsidiary = false;
        public Date currentRatingToolDate;

        // Key is constructed like LineId_groupPriorityId (string), so use String as key
        public Map<String, List<MainHolderProductsWrapper>> mainHolderProductsWrapperMap= new Map<String, List<MainHolderProductsWrapper>>();
        public List<DMT_Banking_Pool_Structure__c> bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();
        public Boolean forceException = false;

        public String oppAccountParentName;

        // Pre-loaded profitability data (populated in loadRelatedData for Opportunity type)
        public List<Map<String, Object>> profitabilityProductDetailsList = new List<Map<String, Object>>();
        public Map<String, Map<String, Object>> profitabilityNominalAmountsMap = new Map<String, Map<String, Object>>();
        public Map<String, Map<String, Object>> profitabilityNominalAmountsConvertedMap = new Map<String, Map<String, Object>>();
        public String clientGroupName = null;
    }

    public class MainHolderProductsWrapper {
        public String clientName;
        public String internalRatingShort;
        public Date currentRatingToolDate;
    }

    public class MonoHolderDataWrapper {
        public String ratingMonoHolder;
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

    public static MonoHolderDataWrapper getMonoHolderDataFromService(Id clientId, String customerId){
        MonoHolderDataWrapper result = new MonoHolderDataWrapper();
        result.ratingMonoHolder = '';
        // call DMT_HPG_Utils.lastDate() first to get the searchDate
        String searchDate = DMT_HPG_Utils.lastDate();
        DMT_HPG_GlobalPosition.Wrapper res = new DMT_HPG_GlobalPosition.Wrapper();
        res = DMT_HPG_MainTableCustomController.fetchClientDataFromService(clientId, '1', '5000', new List<String>{}, Date.valueOf(searchDate), 'Y/N', null);
        if(res.data != null && res.data.size() > 0) {
            for(DMT_HPG_GlobalPosition.Data data : res.data) {
                if(data.customerId == customerId) {
                    result.ratingMonoHolder = data.updSmsclInternalRatgType != null ? data.updSmsclInternalRatgType : '';
                    result.currentRatingToolDate = data.currentRatingToolDate;
                    break;
                }
            }
        }
        return result;
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

    public static List<String> getCustomerClientIds(List<Custom_Association_Client__c> customAssociationClientsList){
        List<String> aux = new List<String>();
        if(customAssociationClientsList!=null){
            for(Custom_Association_Client__c ca : customAssociationClientsList){
                aux.add(ca.g_customer_id__c);
            }
        }
        return aux;
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
        } else if (type == 'Line_Sanction'){
            recordTypeDeveloperName = 'Sanction';
        }
        if(String.isBlank(type)){
            throw new DMT_CustomException('view type is empty');
        }
        if (type == 'Line' || type == 'Line_Treasury' || type == 'Line_Sanction') {
            data.objectApiName = 'DMT_Line__c';
            data.line = DMT_View_Selector.getLineWithRelatedData(recordId, recordTypeDeveloperName);

            data.recordTypeId = data.line?.RecordTypeId;
            data.recordTypeName = data.line?.RecordType.DeveloperName;
            data.statusLineOrOpp = data.line?.Status__c;
            data.closeLine = data.line?.Closed__c;
            data.lineName = data.line?.Name;
            data.recordLineId = data.line?.Id;

            if (data.line.Custom_Association__c != null) {
                data.customAssociationClientList = getUpdatedCustomAssociationClientList(data.line.Client__c, data.line.Custom_Association__c);
                System.debug('data.customAssociationClientList: '+data.customAssociationClientList);
                data.mainHolderCustomerId = data.line.Custom_Association__r.g_customer_id__c;
                data.activeRelatedLines =  DMT_View_Selector.getRelatedTRSRLines(getCustomerClientIds(data.customAssociationClientList), data.line.Start_Date__c, data.line.End_Date__c, recordId);
                System.debug('Has custom Association');
                System.debug('activeRelatedLines: '+data.activeRelatedLines);
            }else if(data.line.Custom_Association__c == null && data.line.Client__r.g_customer_id__c != null){
                MonoHolderDataWrapper monoHolderData = getMonoHolderDataFromService(data.line.Client__c, data.line.Client__r.g_customer_id__c);
                data.ratingMonoHolder = monoHolderData.ratingMonoHolder;
                data.currentRatingToolDate = monoHolderData.currentRatingToolDate;
                System.debug('ratingMonoHolder: '+data.ratingMonoHolder);
                data.isSubsidiary = true;
                data.activeRelatedLines =  DMT_View_Selector.getRelatedTRSRLines(new List<String>{data.line.Client__r.g_customer_id__c}, data.line.Start_Date__c, data.line.End_Date__c, recordId);
                System.debug('activeRelatedLines: '+data.activeRelatedLines);
            }

            data.currencyIsoCode = data.line?.CurrencyIsoCode ?? '';
            if(data.line != null && !data.line.Line_Team_Members__r.isEmpty()){
                data.participantList.addAll(data.line.Line_Team_Members__r);
            }

            if(data.line != null && !data.line.Risk_Line_Terms__r.isEmpty()){
                data.riskLineList.addAll(data.line.Risk_Line_Terms__r);
            }

            populateRiskLineAuxiliaryMaps(data);
            data.featuresList = getFeatures(data.line.Id);system.debug('in features'+ data.featuresList);
            if (!data.featuresList.isEmpty()) {
                List<String> featureIds = new List<String>();
                for (Map<String, Object> feature : data.featuresList) {
                    String id = (String) feature.get('id');
                    if (id != null) {
                        featureIds.add(id);
                    }
                }
                // FIX: 1 bulk query for ALL features instead of N individual calls (saves ~40 SOQL)
                Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> allStepsMap = DMT_Case_Steps_Controller.getAllStepsFromFeaturesLine(featureIds, data.line.Line_Id__c);
                for (String fId : featureIds) {
                    if (allStepsMap.containsKey(fId) && !allStepsMap.get(fId).isEmpty()) {
                        data.allsteps.add(allStepsMap.get(fId)[0]);
                    }
                }
                data.steps = DMT_Case_Steps_Controller.getCurrentStepFromFeatures(featureIds, data.line.Line_Id__c);system.debug('in steps'+ data.steps);

            }

            // Sanction Line: load Approval Process features/steps from its child Opportunity (Opportunity.DMT_Sanction__c)
            if (data.line != null && !data.line.Opportunities__r.isEmpty()) {
                Opportunity childOpp = data.line.Opportunities__r[0];
                data.sanctionOppFeaturesList = getFeatures(childOpp.Id);
                if (!data.sanctionOppFeaturesList.isEmpty()) {
                    List<String> oppFeatureIds = new List<String>();
                    for (Map<String, Object> feature : data.sanctionOppFeaturesList) {
                        String id = (String) feature.get('id');
                        if (id != null) {
                            oppFeatureIds.add(id);
                        }
                    }
                    Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> oppAllStepsMap = DMT_Case_Steps_Controller.getAllStepsFromFeaturesOpp(oppFeatureIds, childOpp.DMT_Opp_Id__c);
                    for (String fId : oppFeatureIds) {
                        if (oppAllStepsMap.containsKey(fId) && !oppAllStepsMap.get(fId).isEmpty()) {
                            data.sanctionOppAllsteps.add(oppAllStepsMap.get(fId)[0]);
                        }
                    }
                    data.sanctionOppSteps = DMT_Case_Steps_Controller.getCurrentStepFromFeaturesOpp(oppFeatureIds, childOpp.DMT_Opp_Id__c);
                }
            }

                if (data.line?.Status__c == 'Closed' && data.line?.Closed__c == 'Won'){
                data.closedWonVersions = getCloseWonVersions(data.line.Line_Id__c);
                }

        } else if (type == 'Opportunity') {
            System.debug('recordTypeDeveloperName  '+ recordTypeDeveloperName);
            System.debug('recordId  '+ recordId);
            data.objectApiName = 'Opportunity';
            data.opportunity = DMT_View_Selector.getOpportunityWithRelatedData(recordId, recordTypeDeveloperName);
            data.oppAccountParentName = DMT_Utils.getComparisonAccountName(data.opportunity.AccountId);
            // Pre-fetch client group name once here to avoid SOQL-in-renderer (CIBGLOBALD-3485)
            if (data.opportunity.AccountId != null) {
                try {
                    Map<String, Object> groupData = DMT_HPG_Utils.getGroupFromClientAccount(data.opportunity.AccountId);
                    String groupName = groupData.get('groupName') != null ? (String)groupData.get('groupName') : '';
                    String accountName = data.opportunity.Account.Name != null ? data.opportunity.Account.Name : '';
                    data.clientGroupName = groupName + ' - ' + accountName;
                } catch (Exception e) {
                    System.debug('Error pre-fetching client group name: ' + e.getMessage());
                    data.clientGroupName = '';
                }
            }
            // START Populate general for send email 
            data.recordTypeName = (data.opportunity != null && data.opportunity.RecordType != null) ? data.opportunity.RecordType.DeveloperName: 'DMT_Opportunity';
            data.lineName = data.opportunity?.Name;
            data.recordLineId = (data.opportunity != null && data.opportunity.Id != null) ? String.valueOf(data.opportunity.Id) : null;
            data.statusLineOrOpp = data.opportunity?.StageName;
            Boolean oppIsWon = data.opportunity?.IsWon == true;
            Boolean oppIsClosed = data.opportunity?.IsClosed == true;
            data.closeLine = oppIsWon ? 'Won' : (oppIsClosed ? 'Closed' : 'Open');
            // END Populate general for send email 
            // Fetch Sanction Line AND its corresponding Features/Steps
            if(String.isNotBlank(data.opportunity.DMT_Sanction__c)){
                data.line = DMT_View_Selector.getLineWithRelatedData(data.opportunity.DMT_Sanction__c, 'Sanction');

                if(data.line != null && !data.line.Risk_Line_Terms__r.isEmpty()){
                    data.riskLineList.addAll(data.line.Risk_Line_Terms__r);
                }
                
                populateRiskLineAuxiliaryMaps(data);

                // Populate Sanction Features separately
                data.sanctionFeaturesList = getFeatures(data.line.Id);
                if (!data.sanctionFeaturesList.isEmpty()) {
                    List<String> sanctionFeatureIds = new List<String>();
                    for (Map<String, Object> feature : data.sanctionFeaturesList) {
                        String id = (String) feature.get('id');
                        if (id != null) {
                            sanctionFeatureIds.add(id);
                        }
                    }
                    // FIX: Bulk query for ALL sanction features
                    Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> sanctionStepsMap = DMT_Case_Steps_Controller.getAllStepsFromFeaturesLine(sanctionFeatureIds, data.line.Line_Id__c);
                    for (String fId : sanctionFeatureIds) {
                        if (sanctionStepsMap.containsKey(fId) && !sanctionStepsMap.get(fId).isEmpty()) {
                            data.sanctionAllsteps.add(sanctionStepsMap.get(fId)[0]);
                        }
                    }
                    data.sanctionSteps = DMT_Case_Steps_Controller.getCurrentStepFromFeatures(sanctionFeatureIds, data.line.Line_Id__c);
                }
            }
            data.recordTypeId = data.opportunity?.RecordTypeId;
            data.currencyIsoCode = data.opportunity.CurrencyIsoCode;
            if(!data.opportunity.getPopulatedFieldsAsMap().isEmpty()){
                if(!data.opportunity.X_sell__r.isEmpty()){
                    data.xSellOpp.addAll(data.opportunity.X_sell__r);
                }
                if (!data.opportunity.Banking_Pool_Structures__r.isEmpty()) {
                    data.bankingPoolStructures.addAll(data.opportunity.Banking_Pool_Structures__r);
                }
                if(!data.opportunity.Deal_Team_Members__r.isEmpty()){
                    data.participantList.addAll(data.opportunity.Deal_Team_Members__r);
                }
                if(!data.opportunity.DMT_MDE_Opportunities_Clients__r.isEmpty()){
                    //CLIENT AND APPROVAL PROCESS DATA
                    data.oppClient = (data.opportunity.DMT_MDE_Opportunities_Clients__r[0]);
                }
                if(data.opportunity.AccountId != null && data.opportunity.Account.g_customer_id__c != null){
                    System.debug('Fetching MonoHolderData for AccountId: ' + data.opportunity.AccountId + ' and CustomerId: ' + data.opportunity.Account.g_customer_id__c);
                    MonoHolderDataWrapper monoHolderData = getMonoHolderDataFromService(data.opportunity.AccountId, data.opportunity.Account.g_customer_id__c);
                    System.debug('MonoHolderData retrieved: CurrentRatingToolDate - ' + monoHolderData.currentRatingToolDate);
                    data.currentRatingToolDate = monoHolderData.currentRatingToolDate;
                }
                if(!data.opportunity.OpportunityLineItems.isEmpty()){
                    Set<String> oppLinesBranchIds = new Set<String>();
                    Set<String> oppLinesRiskTypes = new Set<String>();
                    Set<String> oppLinesCountryRisk = new Set<String>();
                    Set<String> oppLinesSustainValues = new Set<String>();
                    Set<String> xsellGeographies = new Set<String>(); // NEW: X-Sell Geographies

                    for(OpportunityLineItem oppItem : data.opportunity.OpportunityLineItems){
                        oppLinesBranchIds.add(oppItem.g_branch_id__c);
                        oppLinesRiskTypes.add(oppItem.DMT_Risk_Type__c);
                        oppLinesCountryRisk.add(oppItem.gf_country_risk__c);
                        if(String.isNotBlank(oppItem.DMT_sustainable_deal_value__c)) {
                            oppLinesSustainValues.add(oppItem.DMT_sustainable_deal_value__c);
                        }
                    }

                    if(!data.opportunity.X_sell__r.isEmpty()){
                        for(DMT_X_Sell__c xs : data.opportunity.X_sell__r) {
                            if(String.isNotBlank(xs.Booking_Geography__c)) {
                                xsellGeographies.add(xs.Booking_Geography__c);
                            }
                        }
                    }

                    List<DMT_Taxonomy_Values__c> taxonomyValuesList = [SELECT Name, DMT_Value__c, DMT_Name_EN__c, DMT_Catalog__c FROM DMT_Taxonomy_Values__c
                                                                        WHERE DMT_Catalog__c IN ('H007', 'B444', 'C245', 'H006', 'CD07', 'RBGR', 'RBSO', 'RBES')
                                                                        AND (
                                                                            DMT_Value__c IN : oppLinesBranchIds
                                                                            OR DMT_Value__c IN : oppLinesRiskTypes
                                                                            OR DMT_Value__c IN : oppLinesCountryRisk
                                                                            OR DMT_Value__c IN : oppLinesSustainValues
                                                                            OR DMT_Value__c IN : xsellGeographies
                                                                            OR DMT_Value__c = : data.opportunity.Entific__c
                                                                            OR DMT_Value__c = : data.opportunity.DMT_Entity__c
                                                                        ) ORDER BY DMT_Catalog__c,DMT_Name_EN__c];
                    Map<String, String> taxH007Map = new Map<String, String>();
                    Map<String, String> taxB444Map = new Map<String, String>(); 
                    Map<String, String> taxC245Map = new Map<String, String>();
                    Map<String, String> taxH006Map = new Map<String, String>();
                    Map<String, String> taxCD07Map = new Map<String, String>();
                    Map<String, String> taxSustainMap = new Map<String, String>();
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
                        if (tax.DMT_Value__c != null && (tax.DMT_Catalog__c == 'RBGR' || tax.DMT_Catalog__c == 'RBSO' || tax.DMT_Catalog__c == 'RBES')) {
                            taxSustainMap.put(tax.DMT_Value__c, tax.DMT_Name_EN__c);
                        }
                    }
                    data.taxonomyH007Map = taxH007Map; // NEW: Store map for renderers
                    data.oppEntific = taxCD07Map.containsKey(data.opportunity.Entific__c) ? taxCD07Map.get(data.opportunity.Entific__c) : '';
                    data.oppEntity = taxH006Map.containsKey(data.opportunity.DMT_Entity__c) ? taxH006Map.get(data.opportunity.DMT_Entity__c) : '';
                    String bookingGeo = data.opportunity.DMT_Entity__c +'-'+ data.opportunity.Entific__c;
                    System.debug('Constructed bookingGeo: ' + bookingGeo);
                    if (!String.isBlank(data.opportunity.DMT_branch_id_c__c) && taxH007Map.containsKey(data.opportunity.DMT_branch_id_c__c)) {
                        data.oppBookingGeography = taxH007Map.get(data.opportunity.DMT_branch_id_c__c);
                    } else if (!String.isBlank(bookingGeo) && taxH007Map.containsKey(bookingGeo)) {
                        data.oppBookingGeography = taxH007Map.get(bookingGeo);
                    } else {
                        data.oppBookingGeography = '';
                    }

                    for(OpportunityLineItem oppItem : data.opportunity.OpportunityLineItems){
                        OpportunityProduct oppProduct = new OpportunityProduct();

                        //General Info / Detail
                        oppProduct.name = !String.isBlank(oppItem.DMT_TXT_ProductNameOLI__c) ? oppItem.DMT_TXT_ProductNameOLI__c : oppItem.DES_Product_Name__c;
                        //oppProduct.bookingGeography = taxH007Map.containsKey(oppItem.g_branch_id__c) ? taxH007Map.get(oppItem.g_branch_id__c) : '';
                        oppProduct.riskType = taxB444Map.containsKey(oppItem.DMT_Risk_Type__c) ? taxB444Map.get(oppItem.DMT_Risk_Type__c) : '';
                        oppProduct.initialDate = oppItem.gf_initial_date__c;
                        oppProduct.maturityDate = oppItem.gf_maturity_date__c;
                        oppProduct.useOfProceeds = oppItem.loan_purpose_desc__c;
                        oppProduct.comments = oppItem.DMT_TXT_Comentarios__c;

                        //Amortization
                        oppProduct.amortizationType = oppItem.gf_amortization_type__c;
                        oppProduct.paymentFrequency = oppItem.gf_payment_frequency__c;
                        oppProduct.rateType = oppItem.DMT_RateType__c;
                        oppProduct.bullet = oppItem.DMT_bullet_amortization_indicator__c; 
                        oppProduct.balloon = oppItem.DMT_balloon_amortization_indicator__c; 
                        oppProduct.TenorsCurrency = oppProduct.TenorsCurrency = oppItem.g_currency_id__c;
                        oppProduct.dealAmountTenors = oppItem.DMT_Deal_Amount_Tenors__c;
                        oppProduct.gf_accrual_fees_bp = oppItem.gf_accrual_fees_bp__c;
                        oppProduct.extensionDurationFees = oppItem.DMT_Extension_Duration_Fees__c;
                        oppProduct.newMoney = oppItem.DMT_NewMoney_BBVA__c;
                        oppProduct.oldMoney = oppItem.DMT_OldMoney_BBVA__c;
                        oppProduct.expectedFinalTake = oppItem.syndicated_loan_drawn_amount__c;
                        oppProduct.expectedDrawn = oppItem.DMT_Expected_Drawn__c;
                        oppProduct.oppTenors.addAll(oppItem.Opportunity_Tenors__r);
                        oppProduct.pricingGrid = oppItem.DMT_PricingGrid_OR_StepUps__c;
                        oppProduct.dealAmount = oppItem.DMT_Deal_amount__c;
                        oppProduct.bbvaPrtcpTrancheAmount = oppItem.bbva_prtcp_tranche_amount__c;
                        oppProduct.liquidityFee = oppItem.DMT_Liquidity_Fee__c;
                        oppProduct.commitmentFees = oppItem.DES_Commitment_Fees__c;
                        oppProduct.otherFees = oppItem.DES_Other_Fees__c;
                        oppProduct.expectedFinalTakeBBVA = oppItem.syndicated_loan_drawn_amount__c;

                        //Funding / Cost of Funding
                        oppProduct.currencyIsoCode = oppItem.CurrencyIsoCode;
                        oppProduct.fundingCurve = oppItem.Funding_Curve__c;
                        oppProduct.fundingUndrawnBPS = oppItem.gf_funding_cost_fb__c;
                        oppProduct.fundingDrawnBPS = oppItem.gf_funding_cost_db__c;
                        oppProduct.fundingTerm = oppItem.Life_Funding_Type__c;

                        //Sustainability
                        oppProduct.sustainableDealAssessment = oppItem.DMT_sustainable_deal_assessment__c; 
                        oppProduct.sustainableDealSubtype = oppItem.DMT_Sustainable_Deal_Subtype__c; 
                        oppProduct.sustainableDealValue = oppItem.DMT_sustainable_deal_value__c; 
                        oppProduct.sustainableDealLabel = taxSustainMap.containsKey(oppItem.DMT_sustainable_deal_value__c) ? taxSustainMap.get(oppItem.DMT_sustainable_deal_value__c) : oppItem.DMT_sustainable_deal_value__c;
                        oppProduct.greenActivityFilter = oppItem.DMT_Sustainability_deal_value_criteria__c;
                        oppProduct.sustainablePercentage = oppItem.DMT_PER_Sustainability_Percentage__c != null ? (oppItem.DMT_PER_Sustainability_Percentage__c).toString() : ''; 
                        oppProduct.sustainabilityBonusEligible = oppItem.DMT_Sustainability_bonus_eligible__c;

                        //Country Risk
                        oppProduct.country = taxC245Map.containsKey(oppItem.gf_country_risk__c) ? taxC245Map.get(oppItem.gf_country_risk__c) : '';
                        oppProduct.countryRating = oppItem.gf_country_rating__c;

                        //Mitigants
                        oppProduct.currencyMitigant = !oppItem.Opportunity_Mitigants__r.isEmpty() ? oppItem.Opportunity_Mitigants__r[0].CurrencyIsoCode ?? oppitem.CurrencyIsoCode : oppItem.CurrencyIsoCode;

                        // SEPARATE MITIGANTS INTO COLLATERALS vs GUARANTORS
                        // TODO: Replace "RecordType.DeveloperName" with the actual field your org uses to separate them!
                        for(DMT_Opportunity_Mitigant__c mit : oppItem.Opportunity_Mitigants__r) {
                            // if(mit.RecordType.DeveloperName == 'Collateral') {
                            //     oppProduct.oppCollaterals.add(mit);
                            // } else if(mit.RecordType.DeveloperName == 'Guarantor') {
                            //     oppProduct.oppGuarantors.add(mit);
                            // } else {
                                // Fallback: If no record type matches, add to general list (or pick one)
                                oppProduct.oppMitigants.add(mit);
                            // }
                        }

                        data.oppProducts.add(oppProduct);
                    }
                }

                data.featuresList = getFeatures(data.opportunity.Id);
                if (!data.featuresList.isEmpty()) {
                    List<String> featureIds = new List<String>();
                    for (Map<String, Object> feature : data.featuresList) {
                        String id = (String) feature.get('id');
                        if (id != null) {
                            featureIds.add(id);
                        }
                    }
                    // FIX: Bulk query for ALL opportunity features
                    Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> allStepsMap = DMT_Case_Steps_Controller.getAllStepsFromFeaturesOpp(featureIds, data.opportunity.DMT_Opp_Id__c);
                    for (String fId : featureIds) {
                        if (allStepsMap.containsKey(fId) && !allStepsMap.get(fId).isEmpty()) {
                            data.allsteps.add(allStepsMap.get(fId)[0]);
                        }
                    }
                    data.steps = DMT_Case_Steps_Controller.getCurrentStepFromFeaturesOpp(featureIds, data.opportunity.DMT_Opp_Id__c);

                    // Pre-load profitability data so renderers can read from the wrapper without issuing queries
                    Set<String> profitabilityProductIdsSet = new Set<String>();
                    for (Map<String, Object> feat : data.featuresList) {
                        if (feat.containsKey('profitability')) {
                            Map<String, Object> profitability = (Map<String, Object>) feat.get('profitability');
                            if (profitability != null && profitability.containsKey('results')) {
                                for (Object resultObj : (List<Object>) profitability.get('results')) {
                                    Map<String, Object> row = (Map<String, Object>) resultObj;
                                    if (row.containsKey('productId') && row.get('productId') != null) {
                                        profitabilityProductIdsSet.add(String.valueOf(row.get('productId')));
                                    }
                                }
                            }
                        }
                    }
                    if (!profitabilityProductIdsSet.isEmpty()) {
                        List<String> profitabilityProductIdList = new List<String>(profitabilityProductIdsSet);
                        data.profitabilityProductDetailsList = DMT_Profitability_utils.getProductDetailsByIds(profitabilityProductIdList, data.opportunity.Id);
                        data.profitabilityNominalAmountsMap = DMT_Profitability_utils.getNominalAmountsByOpportunityLineItemIds(profitabilityProductIdList, data.opportunity.Id);
                        data.profitabilityNominalAmountsConvertedMap = DMT_Profitability_utils.convertNominalsToOppCurrency(data.profitabilityProductDetailsList, data.profitabilityNominalAmountsMap);
                    }
                }
            }
        }
        return data;
    }

    private static void populateRiskLineAuxiliaryMaps(LineDataWrapper data) {
        if (data.riskLineList == null || data.riskLineList.isEmpty()) return;

        Set<String> concatenatedValuesSet = new Set<String>();

        for (DMT_Risk_Line_Term__c risk : data.riskLineList) {
            if (!risk.DMT_Currency_Provisions__r.isEmpty()) {
                data.riskLineToCurrencyProvisionMap.put(risk.Id, risk.DMT_Currency_Provisions__r[0]);
            }
            if (!risk.DMT_Warranties__r.isEmpty()) {
                data.riskLineToWarrantyListMap.put(risk.Id, risk.DMT_Warranties__r);
            }
            if (data.line != null && data.line.Line_Id__c != null) {
                String concatenatedValue = data.line.Line_Id__c + '_' + risk.gf_group_priority_line_id__c;
                concatenatedValuesSet.add(concatenatedValue);
            }
        }

        // Build mainHolderProductsWrapperMap
        if(data.line != null && data.line.Custom_Associations__r != null && !data.line.Custom_Associations__r.isEmpty()){
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
                    for(Custom_Association_Client__c client : ca.Custom_Associations_Clients__r){
                        String clientName = client.Name;
                        String internalRatingShort = client.DMT_ClientRating__c;
                        Date currentRatingToolDate = client.DMT_Client_Rating_Date__c;

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

        if(data.line != null && data.line.Line_Products__r != null && !data.line.Line_Products__r.isEmpty()){
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
        Set<String> g_amortization_type = new Set<String>();
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
            if (!String.isEmpty(risk.g_amortization_type__c)) {
                g_amortization_type.add(risk.g_amortization_type__c);
            }
        }

        List<DMT_Taxonomy_Values__c> taxonomyValuesList = [SELECT Name, DMT_Value__c, DMT_Name_EN__c, DMT_Catalog__c FROM DMT_Taxonomy_Values__c
                                                        WHERE DMT_Catalog__c IN ('C162', 'C164','H007','ALAT')
                                                        AND (
                                                            DMT_Value__c IN : g_limit_sinds_ast_sctr_id
                                                            OR  DMT_Value__c IN : g_limit_sinds_ast_subsec_id
                                                            OR  DMT_Value__c IN : g_branch_id
                                                            OR  DMT_Value__c IN : g_amortization_type
                                                        )
                                                        ORDER BY DMT_Catalog__c,DMT_Name_EN__c];

        Map<String, String> tax162Map = new Map<String, String>();
        Map<String, String> tax164Map = new Map<String, String>();
        Map<String, String> taxH007Map = new Map<String, String>();
        Map<String, String> taxALATMap = new Map<String, String>();
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
            if (tax.DMT_Value__c != null && tax.DMT_Catalog__c == 'ALAT') {
                taxALATMap.put(tax.DMT_Value__c, tax.DMT_Name_EN__c);
            }
        }

        for (DMT_Risk_Line_Term__c risk : data.riskLineList) {
            String key = risk.g_limit_sinds_ast_sctr_id__c;
            if (!String.isEmpty(key) && tax162Map.containsKey(key)) {
                data.riskLineToTaxonomyC162Map.put(risk.Id, tax162Map.get(key));
            }
            String key2 = risk.g_limit_sinds_ast_subsec_id__c;
            if (!String.isEmpty(key2) && tax164Map.containsKey(key2)) {
                data.riskLineToTaxonomyC164Map.put(risk.Id, tax164Map.get(key2));
            }
            String key3 = risk.g_branch_id__c;
            if (!String.isEmpty(key3) && taxH007Map.containsKey(key3)) {
                data.riskLineToTaxonomyH007Map.put(risk.Id, taxH007Map.get(key3));
            }
            String key4 = risk.g_amortization_type__c;
            if (!String.isEmpty(key4) && taxALATMap.containsKey(key4)) {
                data.riskLineToTaxonomyALATMap.put(risk.Id, taxALATMap.get(key4));
            }
        }
    }

    public static List<Map<String, Object>> getCloseWonVersions(String opportunityId) {
        String payload = 'opportunityId='+opportunityId;

        String responseJson = DMT_SnapshotEvaluationVersions.getSnapshotEvaluationVersions(payload);
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(responseJson);

        Map<String, Object> data = (Map<String, Object>) responseData.get('data');
        List<Object> versions = (List<Object>) data.get('versions');
        

        // 4. Filtrar versiones
        List<Map<String, Object>> filteredVersions = new List<Map<String, Object>>();
        for (Object v : versions) {
            Map<String, Object> version = (Map<String, Object>) v;

            if('Closed-Won'.equals((String) version.get('categoryId'))){
                filteredVersions.add(version);
            }

        }

        return filteredVersions;
    }

    @AuraEnabled(cacheable=true)
    public static String getRecordId(String objectApiName, String recordTypeApiName){
        System.debug('getRecordId called with objectApiName: ' + objectApiName + ' and recordTypeApiName: ' + recordTypeApiName);
        
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

        // Declare the bind variable outside the if-block so it stays in scope for Database.query
        String clientTypeValue = 'Custom';

        // Apply DMT_Line__c specific filters
        if (objectApiName == 'DMT_Line__c') {
            soql += ' AND Name != null';
            
            // Bypass the Client_Type__c filter if it's a Sanction record
            if (recordTypeApiName != 'Sanction') {
                soql += ' AND Client_Type__c = :clientTypeValue';
            }
        }
        
        soql += ' ORDER BY CreatedDate DESC LIMIT 1';

        // Execute query safely
        List<SObject> records = Database.query(soql, AccessLevel.SYSTEM_MODE);

        // ALWAYS check if the list is empty before trying to access index [0]!
        if (records.isEmpty()) {
            return null;
        }

        Map<String, String> resultMap = new Map<String, String>();
        resultMap.put('Id', (String) records[0].get('Id'));
        resultMap.put('CurrencyIsoCode', (String) records[0].get('CurrencyIsoCode'));

        return JSON.serialize(resultMap);
    }

    public static String loadJSONFromSelectedItems(String lineId, String type, String items) {
            String rawResult = loadComponentsForView(lineId, type, items, '', null);
        return rawResult;
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
                    } else if (caseRecord[0].DMT_Line__r.RecordType.DeveloperName == 'Sanction') {
                        viewType = 'Line_Sanction';
                        approverViewId = approver[0].Approvers_View__c;
                        resultMap.put('recordTypeApiName','Sanction');
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
            resultMap.put('StatusLine', data.statusLineOrOpp);
            resultMap.put('CloseLine', data.closeLine);
            resultMap.put('RecordTypeName', data.recordTypeName);
            resultMap.put('lineName', data.lineName);
            resultMap.put('recordLineId', data.recordLineId);

            DMT_AsyncOrchestrator.flush();
            return JSON.serialize(resultMap);
        } catch (Exception e) {
            System.debug('Error on loadComponentsForView, ' + e.getLineNumber());
            System.debug('Error on loadComponentsForView, ' + e.getTypeName());
            System.debug('Error on loadComponentsForView, ' + e.getMessage());
            System.debug('Error on loadComponentsForView stacktrace, ' + e.getStackTraceString());

            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_ViewController', 'loadComponentsForView','DMT','' ));
            DMT_AsyncOrchestrator.flush();

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
            
            // 1. If it's a registered component, route to the Factory
            if (DMT_RendererFactory.hasRenderer(item.component)) {
                component = DMT_RendererFactory.getRenderer(item.component).renderPdfJson(data);
                if (component != null && !component.isEmpty()){
                    componentsList.add(component);
                }
                continue; // Skip the switch statement below
            }

            // 2. Otherwise, handle static formatting utilities
            switch on item.component {
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

    // Parametro para saber desde donde venimos y mostrar la linea solo en el html de la vista
    // Método para generar el HTML de cada componente
    @TestVisible
    private static String generateHtmlForComponent(String componentItem, String text, LineDataWrapper data) {

        // 1. If it's a registered component, route to the Factory
        if (DMT_RendererFactory.hasRenderer(componentItem)) {
            return DMT_RendererFactory.getRenderer(componentItem).renderHtml(data);
        }

        // 2. Otherwise, handle static formatting utilities
        switch on componentItem {
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

    @AuraEnabled
    public static Map<String, Object> getModalFilesData(String taskId) {
        Map<String, Object> result = new Map<String, Object>{
            'htmlData' => null,
            'jsonData' => null,
            'hasJSON' => false
        };

        try {
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink cdl : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :taskId]) {
                docIds.add(cdl.ContentDocumentId);
            }

            if (docIds.isEmpty()) return result;

            Set<Id> versionIds = new Set<Id>();
            for (ContentDocument doc : [SELECT LatestPublishedVersionId FROM ContentDocument WHERE Id IN :docIds]) {
                versionIds.add(doc.LatestPublishedVersionId);
            }

            for (ContentVersion cv : [SELECT VersionData, FileType FROM ContentVersion WHERE Id IN :versionIds AND (FileType = 'HTML' OR FileType = 'JSON')]) {
                if (cv.FileType == 'HTML') {
                    result.put('htmlData', cv.VersionData.toString());
                } else if (cv.FileType == 'JSON') {
                    result.put('jsonData', cv.VersionData.toString());
                    result.put('hasJSON', true);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    // =========================================================================
    // === NEW CORE DOCUMENTS & SNAPSHOT ORCHESTRATION METHODS               ===
    // =========================================================================

    /**
     * @description Fallback generator if the LWC cache is empty.
     * Returns the HTML and JSON payloads WITHOUT inserting anything into the database.
     */
    /* @AuraEnabled
    public static Map<String, String> getSnapshotPayloads(String caseId, String taskId, String itemsB64) {
        try {
            Map<String, Object> itemsToDisplay = (Map<String, Object>) JSON.deserializeUntyped(getItemsToDisplayExtended(caseId, 'Case', taskId));
            List<ItemWrapper> itemsList = (List<ItemWrapper>) JSON.deserialize((String) itemsToDisplay.get('items'), List<ItemWrapper>.class);
            String viewType = (String) itemsToDisplay.get('viewType');
            String recordId = (String) itemsToDisplay.get('recordId');

            Map<String, Object> rawResult = (Map<String, Object>) JSON.deserializeUntyped(loadComponentsForView(recordId, viewType, JSON.serialize(itemsList), '', itemsB64));

            Map<String, String> response = new Map<String, String>();
            response.put('HTML', (String) rawResult.get('HTML'));
            response.put('JSON', (String) rawResult.get('PDF'));
            return response;
        } catch (Exception e) {
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_ViewController','getSnapshotPayloads','DMT',''));
            throw new AuraHandledException('Error fetching snapshot payloads: ' + e.getMessage());
        }
    } */

    /**
     * @description Universal method to save the native ContentVersions (HTML and/or JSON).
     */
    @AuraEnabled
    public static void saveNativeSnapshots(String taskId, String htmlString, String jsonString, Blob fileBlob) {
        try {
            List<ContentVersion> cvsToInsert = new List<ContentVersion>();

            // 1. Prepare HTML if provided
            if (String.isNotBlank(htmlString)) {
                ContentVersion cvHtml = new ContentVersion();
                cvHtml.Title = 'Task completed HTML';
                cvHtml.PathOnClient = 'taskCompleted.html';
                cvHtml.VersionData = Blob.valueOf(htmlString);
                cvHtml.IsMajorVersion = true;
                cvHtml.Is_Template_PDF__c = false;
                cvsToInsert.add(cvHtml);
            }

            // 2. Prepare JSON if provided
            if (String.isNotBlank(jsonString)) {
                ContentVersion cvJson = new ContentVersion();
                cvJson.Title = 'Task completed JSON';
                cvJson.PathOnClient = 'taskCompleted.json';
                cvJson.VersionData = Blob.valueOf(jsonString);
                cvJson.IsMajorVersion = true;
                cvJson.Is_Template_PDF__c = true;
                cvsToInsert.add(cvJson);
            }
            // 3. Prepare PDF if provided
            if (fileBlob != null) {
                ContentVersion cvPdf = new ContentVersion();
                cvPdf.Title = 'Task completed PDF';
                cvPdf.PathOnClient = 'taskCompleted.pdf';
                cvPdf.VersionData = fileBlob;
                cvPdf.IsMajorVersion = true;
                cvPdf.Is_Template_PDF__c = true;
                cvsToInsert.add(cvPdf);
            }

            if (!cvsToInsert.isEmpty()) {
                Database.insert(cvsToInsert, AccessLevel.SYSTEM_MODE);

                // 4. Link them to the Task
                List<ContentDocumentLink> cdlsToInsert = new List<ContentDocumentLink>();
                Set<Id> cvIds = new Set<Id>();
                for (ContentVersion cv : cvsToInsert) cvIds.add(cv.Id);

                for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cvIds]) {
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cv.ContentDocumentId;
                    cdl.LinkedEntityId = taskId;
                    cdl.ShareType = 'V';
                    cdlsToInsert.add(cdl);
                }

                if (!cdlsToInsert.isEmpty()) {
                    Database.insert(cdlsToInsert, AccessLevel.SYSTEM_MODE);
                }
            }
        } catch (Exception e) {
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_ViewController','saveNativeSnapshots','DMT',''));
            throw new AuraHandledException('Error saving native snapshots: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String deleteNativeSnapshots(Id taskId) {
        try {
            // Find all files linked to this Task
            List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :taskId WITH SYSTEM_MODE];

            if (links.isEmpty()) {
                return 'No content documents to delete.';
            }

            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink link : links) {
                docIds.add(link.ContentDocumentId);
            }

            // Fetch the documents in System Mode
            List<ContentDocument> docsToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :docIds WITH SYSTEM_MODE];
            Integer deletedCount = docsToDelete.size();

            // Deleting the ContentDocument automatically deletes all associated ContentVersions.
            Database.delete(docsToDelete, true, AccessLevel.SYSTEM_MODE);

            return deletedCount + ' documents deleted.';

        } catch (Exception e) {
            throw new AuraHandledException('Error deleting native snapshots: ' + e.getMessage());
        }
    }
}