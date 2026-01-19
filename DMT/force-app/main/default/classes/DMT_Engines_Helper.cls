@JsonAccess(serializable='always' deserializable='always')
public class DMT_Engines_Helper {

    public static void setCorrectionLevels(DMT_IP_Wrapper limitAttr, DMT_Engines_Wrapper.Request requestAttr) {
        final List<String> invalidIdList = new List<String> {'-1000','{Session.element.groupId}','{Session.element.subGroupId}', '{Session.element.level3groupId}','{Session.element.clientId}'};
        String correctionId = '';

        requestAttr.customerId = String.valueOf(limitAttr.inputMap.get('CustomerId'));
        correctionId = invalidIdList.contains(requestAttr.customerId) ? null : requestAttr.customerId ;
        requestAttr.customerId = String.isNotBlank(requestAttr.customerId) ? correctionId: null;

        requestAttr.groupId = String.valueOf(limitAttr.inputMap.get('GroupId'));
        correctionId = invalidIdList.contains(requestAttr.groupId) ? null : requestAttr.groupId;
        requestAttr.groupId = String.isNotBlank(requestAttr.groupId) ?  correctionId : null;

        requestAttr.subGroupId = String.valueOf(limitAttr.inputMap.get('SubGroupId'));
        correctionId = invalidIdList.contains(requestAttr.subGroupId) ? null : requestAttr.subGroupId;
        requestAttr.subGroupId = String.isNotBlank(requestAttr.subGroupId) ? correctionId : null;

        requestAttr.level3groupId = String.valueOf(limitAttr.inputMap.get('Level3groupId'));

        correctionId = invalidIdList.contains(requestAttr.level3groupId) ? null : requestAttr.level3groupId;

        requestAttr.level3groupId = String.isNotBlank(requestAttr.level3groupId) ? correctionId : null;

        requestAttr.customerName = String.isNotBlank(requestAttr.customerId) ? String.valueOf(limitAttr.inputMap.get('CustomerName')) : null;

        requestAttr.groupName = String.isNotBlank(requestAttr.groupId) ? String.valueOf(limitAttr.inputMap.get('GroupName')) : null;

        requestAttr.subGroupName = String.isNotBlank(requestAttr.subGroupId) ? String.valueOf(limitAttr.inputMap.get('SubGroupName')) : null;

        requestAttr.level3groupName = String.isNotBlank(requestAttr.level3groupId) ? String.valueOf(limitAttr.inputMap.get('Level3groupName')) : null;
    }

    // Método para establecer los atributos de IP
    public static DMT_Engines_Wrapper.Request setIPAttributes(DMT_IP_Wrapper limitAttr) {
        final DMT_Engines_Wrapper.Request requestAttr = new DMT_Engines_Wrapper.Request();

        final String guaranteeInd = String.valueOf(limitAttr.inputMap.get('IPGarantias'));//garantias

        final Integer numPlazo = Integer.valueOf(String.valueOf(limitAttr.inputMap.get('IPOpportunityLineItemPlazo')));
        final String  strPlazo = (numPlazo >= 12 ? '1' : '0');

        requestAttr.accountId = String.valueOf(limitAttr.inputMap.get('IPAccountId'));

        requestAttr.isView = String.valueOf(limitAttr.inputMap.get('IPIsView'));
        requestAttr.isViewError = String.valueOf(limitAttr.inputMap.get('IsViewError'));

        requestAttr.productId = String.valueOf(limitAttr.inputMap.get('IPProductFamily'));
        requestAttr.clientType = String.valueOf(limitAttr.inputMap.get('ClientType'));

        requestAttr.clientTypeStructure = String.valueOf(limitAttr.inputMap.get('clientType'));

        requestAttr.termMajor = String.valueOf(limitAttr.inputMap.get('PlazoMetric'));//Mes 0 año 1
        requestAttr.termMajor = '1'.equals(requestAttr.termMajor) ? requestAttr.termMajor : strPlazo;

        requestAttr.guaranteeInd = 'true'.equals(guaranteeInd) ? '1' : '0';
        requestAttr.amountValue = Decimal.valueOf(String.valueOf(limitAttr.inputMap.get('IPOpportunityLineItemUnitPrice')));
        requestAttr.currencyId = String.valueOf(limitAttr.inputMap.get('Divisa'));

        setCorrectionLevels(limitAttr, requestAttr);

        return requestAttr;
    }

    public static Map<String, Object> setPayload(DMT_Engines_Wrapper.Request requestAttr) {
        Map<String, Object> payloadMap = new Map<String, Object>();

        payloadMap.put('productId', requestAttr?.productId);
        payloadMap.put('clientType', requestAttr?.clientType);
        payloadMap.put('termMajor', requestAttr?.termMajor);
        payloadMap.put('guaranteeInd', requestAttr?.guaranteeInd);
        payloadMap.put('amountValue', requestAttr?.amountValue);
        payloadMap.put('currencyId', requestAttr?.currencyId);
        payloadMap.put('aggregationLevel', requestAttr?.aggregationLevel);
        payloadMap.put('aggregationId', requestAttr?.aggregationId);

        return payloadMap;
    }

    public static List<DMT_Engines_Wrapper> callEngines(DMT_Engines_Wrapper.Request requestAttr) {

        List<DMT_Engines_Wrapper> wrapperList = new List<DMT_Engines_Wrapper>();
        DMT_Engines_Wrapper wrapperItem;
        Boolean requestNotNull = requestAttr != null;
        Boolean level3NotNull = requestNotNull && DMT_Vlocity_Helper.isNotEmpty(requestAttr.level3groupId);
        Boolean hassLevel3 = requestNotNull && DMT_Vlocity_Helper.isNotEmpty(requestAttr.level3groupName);

        Boolean groupIsSupragroup = false;
        try {
            Account acc = DMT_Client_Selector.getStructureTypeByGroupCode(requestAttr.groupId);
            groupIsSupragroup = acc.DES_Structure_Type__c == 'Supragroup';
        } catch (Exception e) {
           System.debug('Error retrieving client group, group does not exist in Salesforce? ' + e.getMessage());
        }


        if(requestAttr.clientTypeStructure == 'client') {
            requestAttr.aggregationLevel = 'Local customer';
            requestAttr.aggregationId = requestAttr?.customerId;
            wrapperItem = callSpecificEngine(requestAttr);
            wrapperItem.callEntityName = 'Client Limit: ' + requestAttr?.customerName;
            wrapperList.add(wrapperItem);
        }

        if((requestAttr.clientTypeStructure == 'client' && requestAttr.subGroupId != null)|| requestAttr.clientTypeStructure == 'subgroup'){
            requestAttr.aggregationLevel = 'Group';
            requestAttr.aggregationId = requestAttr?.subGroupId;
            wrapperItem = callSpecificEngine(requestAttr);
            wrapperItem.callEntityName = 'Subgroup Limit: ' + requestAttr?.subGroupName;
            wrapperList.add(wrapperItem);
        }

        if(requestAttr.clientTypeStructure == 'client' || requestAttr.clientTypeStructure == 'subgroup' || requestAttr.clientTypeStructure == 'group'){
            requestAttr.aggregationLevel = 'Group';
            requestAttr.aggregationId = requestAttr?.groupId;
            wrapperItem = callSpecificEngine(requestAttr);
            wrapperItem.callEntityName = 'Group Limit: ' + requestAttr?.groupName;
            wrapperList.add(wrapperItem);
        }

        if((requestAttr.clientTypeStructure == 'client' || requestAttr.clientTypeStructure == 'subgroup' || requestAttr.clientTypeStructure == 'group') && groupIsSupragroup){
            requestAttr.aggregationLevel = 'Group';
            requestAttr.aggregationId = requestAttr?.groupId;
            wrapperItem = callSpecificEngine(requestAttr);
            wrapperItem.callEntityName = 'Supragroup Limit ' + requestAttr?.groupName;
            wrapperList.add(wrapperItem);
        }

        DMT_Integration_GenericService.commitAllLogsViaBatch();

        return wrapperList;
    }

    public static List<DMT_Engines_Wrapper.ResponseItem> transformResponse(DMT_Engines_Wrapper.Request requestAttr,List<DMT_Engines_Wrapper> wrapperList) {

        Integer inc = 0;
        Integer isEvaluate;
        Integer notEvalueate;
        Boolean tieneRojo;
        Boolean tieneNaranja;
        String stateName;

        List<DMT_Engines_Wrapper.ResponseItem> responseList = new List<DMT_Engines_Wrapper.ResponseItem>();
        DMT_Engines_Wrapper.ResponseItem responseItem;

        Map<String,String> mapImg = new Map<String,String>();
        Map<String,String> mapImgDes = new Map<String,String>();

        mapImgDes.put('RED','Limit exceeded. Please, verify with risk analyst');
        mapImgDes.put('GREEN','Further limitations may apply to this trade. Please, verify with risk analyst');
        mapImgDes.put('ORANGE','ORANGE');

        for(Document contDocitem: [SELECT Id, Name  FROM Document WHERE Name IN ('Green','Orange','Red','White') WITH SECURITY_ENFORCED]){
            mapImg.put(contDocitem.Name,contDocitem.Id);
        }

        for (DMT_Engines_Wrapper wrapperItem:wrapperList){

            responseItem = new DMT_Engines_Wrapper.ResponseItem();
            responseItem.LastUpdate = Datetime.now().format('HH:mm:ss');
            responseItem.Amount = requestAttr.amountValue.toString();
            responseItem.FeatureId = 'F'+inc;
            responseItem.Name = wrapperItem.callEntityName;
            responseItem.Description = 'PF '+ responseItem.FeatureId;

            isEvaluate = 0;
            notEvalueate = 0;
            tieneRojo = false;
            tieneNaranja = false;
            stateName = 'White';

            DMT_Engines_Wrapper.ChartDataWrapper chartData = new DMT_Engines_Wrapper.ChartDataWrapper();
            chartData.originCurrency = requestAttr.currencyId;
            chartData.targetColor = 'red';
            chartData.targets = new List<Decimal>();
            chartData.labels = new List<String>();
            chartData.datasets = new List<DMT_Engines_Wrapper.Dataset>();
            chartData.limitLights = new List<String>();
            chartData.currencies = new List<String>();
            chartData.conditions = new List<String>();

            chartData.sections = new List<String>{'Drawn', 'Undrawn committed', 'Undrawn uncommitted', 'Pending authorized','New Opportunity'};

            List<Decimal> drawnList = new List<Decimal>();
            List<Decimal> unDrawnCommittedList = new List<Decimal>();
            List<Decimal> unDrawnUnCommittedList = new List<Decimal>();
            List<Decimal> pendingAuthorizedList = new List<Decimal>();
            List<Decimal> newOpportunityList = new List<Decimal>();

            List<String> stateNameList = new List<String>();
            List<string> currencyIdList =  new List<String>();

            Boolean limitApply;
            String conditionDesc = '';

            for (DMT_Engines_Wrapper.ConsumptionLimitItem consumptionItem:wrapperItem.data) {


                limitApply = true;

                if ('RED'.equals(consumptionItem.stateName)) {
                    tieneRojo = true;
                    isEvaluate+=1;
                } else if ('ORANGE'.equals(consumptionItem.stateName)) {
                    tieneNaranja = true;
                    isEvaluate+=1;
                } else if (String.isNotBlank(consumptionItem.stateName)){
                    isEvaluate+=1;
                } else if (consumptionItem.conditionDesc == 'No limits apply to this trade') {
                    notEvalueate+=1;
                    limitApply = false;
                    conditionDesc = consumptionItem.conditionDesc;
                }

                if(limitApply) {

                    String limitDesc = consumptionItem.limitDesc;
                    List<String> limitDescList = DMT_Utils.splitString(limitDesc,'#');
                    limitDesc = !limitDescList.isEmpty() ? limitDescList[0] + '#'  + limitDescList[2]: '';
                    chartData.labels.add(limitDesc);
                    chartData.targets.add(consumptionItem.amount.currentApprovedAmount);
                    chartData.conditions.add( mapImgDes.get(consumptionItem.stateName) + ' ' + consumptionItem.riskAnalystId);

                    drawnList.add(consumptionItem.amount.cmtContDisposedAmount + consumptionItem.amount.uncmtContDisposedAmount);
                    unDrawnCommittedList.add(consumptionItem.amount.cmtContNonDspsAmount);
                    unDrawnUnCommittedList.add(consumptionItem.amount.uncmtContNonDspsAmount);
                    pendingAuthorizedList.add(consumptionItem.amount.authorizedRiskAmount);
                    newOpportunityList.add(requestAttr.amountValue);

                    stateNameList.add(consumptionItem.stateName);
                    currencyIdList.add(consumptionItem.currencyId);
                }
            }

            if(!wrapperItem.data.isEmpty()) {
                Boolean notZero = (wrapperItem.data.size() - notEvalueate) != 0 ;
                responseItem.Comments = '';
                if (notZero){

                    chartData.datasets.add(new DMT_Engines_Wrapper.Dataset(drawnList , 'rgba(4, 50, 99, 1)', 'rgba(4, 50, 99, 1)','Drawn'));
                    chartData.datasets.add(new DMT_Engines_Wrapper.Dataset(unDrawnCommittedList, 'rgba(20, 100, 165, 1)', 'rgba(20, 100, 165, 1)','Undrawn committed'));
                    chartData.datasets.add(new DMT_Engines_Wrapper.Dataset(unDrawnUnCommittedList, 'rgba(36, 150, 234, 1)', 'rgba(36, 150, 234, 1)','Undrawn uncommitted'));
                    chartData.datasets.add(new DMT_Engines_Wrapper.Dataset(pendingAuthorizedList, 'rgba(45, 204, 205, 1)', 'rgba(45, 204, 205, 1)','Pending authorized'));
                    chartData.datasets.add(new DMT_Engines_Wrapper.Dataset(newOpportunityList, 'rgba(189, 189, 189, 1)', 'rgba(189, 189, 189, 1)','New Opportunity'));


                    chartData.limitLights.addAll(stateNameList);
                    chartData.currencies.addAll(currencyIdList);

                    responseItem.chartData = chartData;
                } else {
                    responseItem.Comments = conditionDesc;
                }

                if (tieneRojo) {
                    stateName ='Red';
                } else if (tieneNaranja) {
                    stateName ='Yellow';
                } else if (wrapperItem.data != null && !wrapperItem.data.isEmpty() && (wrapperItem.data.size() - notEvalueate) == isEvaluate && notZero){
                    stateName ='Green';
                }
                responseItem.Capability = stateName.toLowerCase();
                responseItem.Description +=' '+ stateName;
                responseItem.CapabilityV2 =   stateName.toLowerCase();
                responseList.add(responseItem);
            } else {
                responseItem.Comments = wrapperItem.errorMessage;
                responseItem.Capability = stateName.toLowerCase();
                responseItem.Description +=' '+ stateName;
                responseItem.CapabilityV2 = stateName.toLowerCase();
                responseList.add(responseItem);
            }

            inc+=1;
        }
        return responseList;
    }

    public static void getResponse(DMT_Engines_Wrapper.Request requestAttr,List<DMT_Engines_Wrapper> wrapperList, DMT_IP_Wrapper ipWrapper) {

        List<DMT_Engines_Wrapper.ResponseItem> responseList = transformResponse(requestAttr,wrapperList);
        String isViewErrorAttr = '';
        List<String> capabilityList  = new List<String>();
        List<String> errorList  = new List<String>();
        ipWrapper.outputMap.put('ACrecords',responseList);
        System.debug('***ACrecords --> ' + responseList);
        if(responseList != null && !responseList.isEmpty()){
            for(DMT_Engines_Wrapper.ResponseItem responseItem: responseList){
                if(!capabilityList.contains(responseItem.Capability)){
                    capabilityList.add(responseItem.Capability);
                }
                if(!errorList.contains(responseItem.Comments)){
                    errorList.add(responseItem.Comments);
                }
            }
            Boolean capabilityBool = capabilityList != null && !capabilityList.isEmpty() && capabilityList.size() == 1 && capabilityList[0] == 'White';
            Boolean errorBool = errorList != null && !errorList.isEmpty() && errorList.size() == 1;
            if(capabilityBool && errorBool){
                isViewErrorAttr = requestAttr.isViewError;
                ipWrapper.outputMap.put('IsView','false');
                ipWrapper.outputMap.put('IsViewError','true'.equals(isViewErrorAttr) ? 'true' : 'false');
                ipWrapper.outputMap.put('ErrorMessage', DMT_Utils.listToString(errorList, '. '));
            } else {
                ipWrapper.outputMap.put('IsView',requestAttr.isView);
                ipWrapper.outputMap.put('IsViewError','false');
                ipWrapper.outputMap.put('ErrorMessage','No error');
            }
        } else {
            isViewErrorAttr = requestAttr.isViewError;
            ipWrapper.outputMap.put('IsView','false');
            ipWrapper.outputMap.put('IsViewError','true'.equals(isViewErrorAttr) ? 'true' : 'false');
            for(DMT_Engines_Wrapper wrapperItem: wrapperList){
                if(!errorList.contains(wrapperItem.errorMessage)){
                    errorList.add(wrapperItem.errorMessage);
                }
            }
            ipWrapper.outputMap.put('ErrorMessage', DMT_Utils.listToString(errorList, '. '));
        }

        ipWrapper.outputMap.put('LastUpdate',Datetime.now().format('HH:mm:ss'));
        ipWrapper.outputMap.put('ACAccountId',requestAttr.accountId);
    }


    public static DMT_Engines_Wrapper callSpecificEngine(DMT_Engines_Wrapper.Request requestAttr) {
        List<DMT_Engines_Wrapper.ConsumptionLimitItem> consumptionItem = new List<DMT_Engines_Wrapper.ConsumptionLimitItem>();
        DMT_Engines_Wrapper wrapper = new DMT_Engines_Wrapper();
        Map<String, Object> payloadMap;
        final User userLogin = DMT_User_Selector.getLoginUser();
        final String federationId = userLogin.federationIdentifier;
        if(String.isNotBlank(requestAttr.aggregationId)){
            payloadMap = setPayload(requestAttr);
            wrapper = callEngine(payloadMap, federationId);//futuro
        }
        return wrapper;
    }

    // Método para obtener la posición global
    public static DMT_Engines_Wrapper callEngine(Map<String, Object> payloadMap, String federationId) {
        Map<String, Object> requestRest = DMT_Utils.setRequest(payloadMap, federationId);
        System.debug('***callEngines--DMT_Engines '+ requestRest);
        final HttpResponse response = DMT_HPG_Utils.callService_DMT('DMT_Engines', requestRest);//ATENCION
        DMT_Engines_Wrapper wrapper = new DMT_Engines_Wrapper();

        Map<String, String> errorMessages = new Map<String, String>();

        errorMessages.put('No limits apply to this trade', 'No limits apply to this trade');
        errorMessages.put('00000002#LAST LEVEL NO ENCONTRADO', 'Limit last level not found. Ask your system administrator');
        errorMessages.put('00000005#NIVEL DE AGREGACION NO VALIDO', 'Unexpected client hierarchy. Ask your system administrator');
        errorMessages.put('00000005#TIPO DE CAMBIO NO ENCONTRADO', 'Currency not found. Ask your system administrator');

        switch on response.getStatusCode() {
            when 200, 201 {
                wrapper = (DMT_Engines_Wrapper)System.JSON.deserialize(response.getBody(), DMT_Engines_Wrapper.class);
                wrapper.success = true;
                wrapper.errorMessage = '';
            }
            when 204 {
                wrapper.errorMessage = 'Limit last level not found. Ask your system administrator.';
                wrapper.success = false;
                wrapper.data = new List<DMT_Engines_Wrapper.ConsumptionLimitItem>();
            }
            when 400 {
                DMT_Engines_Wrapper.ErrorResponse errorResponse = (DMT_Engines_Wrapper.ErrorResponse) JSON.deserialize(response.getBody(), DMT_Engines_Wrapper.ErrorResponse.class);
                List<DMT_Engines_Wrapper.Message> errorRespMessage = errorResponse.messages;
                if(errorRespMessage.get(0).message.contains('00000002#LAST LEVEL NO ENCONTRADO')){
                    wrapper.errorMessage = 'Limit last level not found. Ask your system administrator';
                }
                wrapper.success = false;
                wrapper.data = new List<DMT_Engines_Wrapper.ConsumptionLimitItem>();
            }
            when else {
                wrapper.errorMessage = response.getStatus();
                wrapper.success = false;
                wrapper.data = new List<DMT_Engines_Wrapper.ConsumptionLimitItem>();
            }
        }

        return wrapper;
    }

    // Método para obtener la posición global
    public static DMT_Engines_Wrapper getEnginesMock() {
        final StaticResource staticR = [SELECT Id, Body FROM StaticResource WHERE Name = 'DMT_Engines_200' LIMIT 1];//ATENCION

        DMT_Engines_Wrapper wrapper = (DMT_Engines_Wrapper)System.JSON.deserialize( staticR.Body.toString(), DMT_Engines_Wrapper.class);
        return wrapper;
    }

    public static DMT_Engines_Wrapper.CurrencyResponse getCurrenciesD() {
        DMT_Engines_Wrapper.CurrencyResponse currencyR = new DMT_Engines_Wrapper.CurrencyResponse();
        List<DMT_Engines_Wrapper.PickItem> picklist = new List<DMT_Engines_Wrapper.PickItem>();
        Map<String,String> currencyMap = new Map<String,String>();
        final List<DMT_Taxonomy_Values__c> taxonomyList = [SELECT Id, DMT_Catalog__c, DMT_Key__c, DMT_Name__c, DMT_Value__c FROM DMT_Taxonomy_Values__c WHERE DMT_Catalog__c = 'C264' WITH SECURITY_ENFORCED];
        final Set<String> currenciesSet = new Set<String>();

        for(DMT_Taxonomy_Values__c taxonomyItem:taxonomyList){
            currenciesSet.add(taxonomyItem.DMT_Key__c != null ? taxonomyItem.DMT_Key__c : taxonomyItem.DMT_Value__c);
        }

        final List<CurrencyType> currencyTypeList = [SELECT Id, IsoCode, ConversionRate, IsCorporate, IsActive, LastModifiedDate  FROM CurrencyType WHERE IsActive = true AND IsoCode IN :currenciesSet WITH SECURITY_ENFORCED ORDER BY IsoCode ];
        for(CurrencyType currencyTypeItem: currencyTypeList){
            DMT_Engines_Wrapper.PickItem pickItem = new DMT_Engines_Wrapper.PickItem();
            pickItem.label = currencyTypeItem.IsoCode + ' ('+ (1/currencyTypeItem.ConversionRate).setScale(6, RoundingMode.HALF_UP)+ ' EUR)';
            pickItem.value = currencyTypeItem.IsoCode;
            picklist.add(pickItem);
            currencyMap.put(currencyTypeItem.IsoCode,currencyTypeItem.ConversionRate.toString());
        }

        currencyR.picklist = picklist;
        currencyR.currencyMap = currencyMap;
        return currencyR;
    }
}