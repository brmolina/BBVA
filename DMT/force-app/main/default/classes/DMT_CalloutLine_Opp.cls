public with sharing class DMT_CalloutLine_Opp implements Callable {

    public Object call(String action, Map<String, Object> args) {
        final Map<String, Object> input   = (Map<String, Object>) args.get('input');
        final Map<String, Object> output  = (Map<String, Object>) args.get('output');
        final Map<String, Object> options = (Map<String, Object>) args.get('options');

        return invokeMethod(action, input, output, options);
    }

    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {

        try {
            if (methodName == 'getLines') {
               final String customerId = (String) inputMap.get('customerId');

                final String requestStr = 'customerId=' + customerId;

                Map<String, Object> request = new Map<String, Object>();
                request.put('jsonInput', requestStr);

                HttpResponse response = DMT_HPG_Utils.callService('DMT_GetLines', request);

                if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {

                    Map<String, Object> serviceResult =(Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                    if (serviceResult.containsKey('data')) {
                        outMap.put('lines', serviceResult.get('data'));
                    } else {
                        outMap.put('errorMessage', 'El servicio no devolvió la propiedad data.');
                    }

                } else {
                    outMap.put('errorMessage', 'Error calling line service:' + response.getBody());
                }
            } else if (methodName == 'getProducts') {

                final String lineId = (String) inputMap.get('lineId');

                String requestStr = lineId;

                Map<String, Object> request = new Map<String, Object>();
                request.put('jsonInput', requestStr);

                HttpResponse response = DMT_HPG_Utils.callService('DMT_GetProducts_Line', request);

                if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {

                    Map<String, Object> serviceResult =
                        (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                    if (serviceResult.containsKey('data')) {
                        Map<String, Object> dataBlock = (Map<String, Object>) serviceResult.get('data');
                        if (dataBlock.containsKey('productsList')) {
                            outMap.put('products', dataBlock.get('productsList'));
                        } else {
                            outMap.put('products', new List<Object>());
                        }
                    } else {
                        outMap.put('error', true);
                        outMap.put('errorMessage', 'The product service did not return data.');
                    }
                } else {
                    outMap.put('error', true);
                    outMap.put(
                        'errorMessage',
                        'Error en servicio productos: ' + response.getBody()
                    );
                }
            } else {

                outMap.put('error', true);
                outMap.put('errorMessage', 'Método no soportado: ' + methodName);
            }
        } catch (Exception e) {
            outMap.put('error', true);
            outMap.put('errorMessage', e.getMessage() + ' ' + e.getStackTraceString());
        }
        return outMap;
    }

    @AuraEnabled(cacheable=true)
    public static List<Data> getLinesFromService(String customerId) {

        Map<String, Object> args = new Map<String, Object>{
            'input'   => new Map<String, Object>{ 'customerId' => customerId },
            'output'  => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Map<String, Object> resultMap = (Map<String, Object>) new DMT_CalloutLine_Opp().call('getLines', args);

        List<Data> lines = new List<Data>();

        if (resultMap.containsKey('lines')) {

            List<Object> rawLines = (List<Object>) resultMap.get('lines');

            for (Object raw : rawLines) {

                Map<String, Object> row = (Map<String, Object>) raw;

                Data d = new Data(
                    (String) row.get('lineId'),
                    (String) row.get('lineName'),
                    (String) row.get('lastLevelId'),
                    (String.valueOf(row.get('amount')) == 'null') ? null : Decimal.valueOf(String.valueOf(row.get('amount'))),
                    (String) row.get('currencyId')
                );

                lines.add(d);
            }
        }

        Set<String> externalIds = new Set<String>();
        for (Data d : lines) {
            if (d.lineId != null) externalIds.add(d.lineId);
        }

        if (!externalIds.isEmpty()) {
            Map<String, DMT_Line__c> lineRecords = new Map<String, DMT_Line__c>();
            for (DMT_Line__c l : [
                SELECT Id, DMT_RecordTypeName__c, Line_Id__c
                FROM DMT_Line__c
                WHERE Line_Id__c IN :externalIds
            ]) {
                lineRecords.put(l.Line_Id__c, l);
            }

            for (Data d : lines) {
                if (lineRecords.containsKey(d.lineId)) {
                    d.recordTypeName = lineRecords.get(d.lineId).DMT_RecordTypeName__c;
                    d.lineExternalId = lineRecords.get(d.lineId).Line_Id__c;
                } else {
                    d.recordTypeName = 'Mock RecordType';
                }
            }
        }

        return lines;
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductData> getProductsFromService(String lineId) {

        Map<String, Object> args = new Map<String, Object>{
            'input'   => new Map<String, Object>{ 'lineId' => lineId },
            'output'  => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Map<String, Object> resultMap =
            (Map<String, Object>) new DMT_CalloutLine_Opp().call('getProducts', args);

        List<ProductData> products = new List<ProductData>();

        if (resultMap.containsKey('products')) {

            List<Object> rawList = (List<Object>) resultMap.get('products');

            for (Object raw : rawList) {
                Map<String, Object> row = (Map<String, Object>) raw;

                ProductData p = new ProductData(
                    (String) row.get('productName'),
                    (String) row.get('lastLevelId'),
                    (String.valueOf(row.get('amount')) == 'null') ? null : Decimal.valueOf(String.valueOf(row.get('amount'))),
                    (String) row.get('currencyId'),
                    (String) row.get('priorityId')
                );

                products.add(p);
            }
        }

        return products;
    }

    public class GetLinesWrapper {
        public List<Data> data { get; set; }
    }

    public class ProductData {
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public String lastLevelId { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public String currencyId { get; set; }
        @AuraEnabled public String priorityId { get; set; }

        public ProductData(String productName, String lastLevelId, Decimal amount, String currencyId, String priorityId) {
            this.productName = productName;
            this.lastLevelId = lastLevelId;
            this.amount = amount;
            this.currencyId = currencyId;
            this.priorityId = priorityId;
        }
    }

    public class Data {
        @AuraEnabled public String lineId { get; set; }
        @AuraEnabled public String lineName { get; set; }
        @AuraEnabled public String lastLevelId { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public String currencyId { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
        @AuraEnabled public String lineExternalId { get; set; }

        public Data(String lineId, String lineName, String lastLevelId, Decimal amount, String currencyId) {
            this.lineId = lineId;
            this.lineName = lineName;
            this.lastLevelId = lastLevelId;
            this.amount = amount;
            this.currencyId = currencyId;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<DMT_Risk_Line_Term__c> getRiskLineTerms(String lineExternalId) {
        if (lineExternalId == null) {
            throw new AuraHandledException('The lineExternalId parameter cannot be null.');
        }

        return [
            SELECT Id, gf_group_priority_line_id__c, DMT_Line__r.Line_Id__c, DMT_Line__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__r.Line_Id__c = :lineExternalId
        ];
    }

    @AuraEnabled
    public static List<OpportunityLineItem> getOpportunityLineItems(Id oppId) {
        return [
            SELECT Id, OpportunityId, Product2Id, Product2.Name, DMT_Associated_Line_Product__c, DMT_Associated_Line_Product__r.DMT_Product__r.Name, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :oppId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Id getLineSFId(String lineExternalId) {
        if (lineExternalId == null) {
            throw new AuraHandledException('The lineExternalId parameter cannot be null.');
        }

        DMT_Line__c line = [
            SELECT Id 
            FROM DMT_Line__c 
            WHERE Line_Id__c = :lineExternalId
            LIMIT 1
        ];

        return line.Id;
    }
}