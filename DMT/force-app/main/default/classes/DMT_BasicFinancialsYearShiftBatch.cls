public without sharing class DMT_BasicFinancialsYearShiftBatch
    implements Database.Batchable<SObject> {

    private static final String ACCOUNT_OBJECT = 'Account';

    private static final String OPPORTUNITY_CLIENT_OBJECT =
        'DMT_Opportunity_Client__c';

    private static final Set<String> SUPPORTED_OBJECTS =
        new Set<String>{
            ACCOUNT_OBJECT,
            OPPORTUNITY_CLIENT_OBJECT
        };

    private static final List<String> FINANCIAL_METRICS =
        new List<String>{
            'Revenues',
            'EBITDA',
            'EBIT',
            'Net_Income',
            'Free_Cash_Flow',
            'Debt_EBITDA',
            'Net_Debt_EBITDA'
        };

    private static final List<String> BUSINESS_PLAN_METRICS =
        new List<String>{
            'Cash_Management',
            'Child_X_Sell',
            'Client_Resources',
            'Corp_Synd_Lending',
            'Credit_Equity',
            'DCM',
            'ECM_M_A',
            'FX_CCS',
            'GTF',
            'Rates',
            'Securities_Services',
            'Str_Trade_Finance',
            'Structured_Finance',
            'Working_Capital'
        };

    private final String objectApiName;
    private final Id recordId;

    public DMT_BasicFinancialsYearShiftBatch(
        String objectApiName
    ) {
        this(objectApiName, null);
    }

    /**
     * Permite limitar una ejecución manual a un único registro.
     */
    public DMT_BasicFinancialsYearShiftBatch(
        String objectApiName,
        Id recordId
    ) {
        if (!SUPPORTED_OBJECTS.contains(objectApiName)) {
            throw new IllegalArgumentException(
                'Unsupported object: ' + objectApiName
            );
        }

        if (
            recordId != null &&
            recordId.getSObjectType()
                .getDescribe()
                .getName() != objectApiName
        ) {
            throw new IllegalArgumentException(
                'The record does not belong to ' +
                objectApiName
            );
        }

        this.objectApiName = objectApiName;
        this.recordId = recordId;
    }

    public Database.QueryLocator start(
        Database.BatchableContext context
    ) {
        List<List<String>> shiftChains =
            buildShiftChains(objectApiName);

        Set<String> queriedFieldSet =
            new Set<String>{ 'Id' };

        for (List<String> chain : shiftChains) {
            queriedFieldSet.addAll(chain);
        }

        List<String> queriedFields =
            new List<String>(queriedFieldSet);

        queriedFields.sort();

        String query =
            'SELECT ' +
            String.join(queriedFields, ', ') +
            ' FROM ' +
            objectApiName;

        List<String> conditions = new List<String>();

        /*
         * Las oportunidades cerradas conservan
         * sus años y valores.
         */
        if (objectApiName == OPPORTUNITY_CLIENT_OBJECT) {
            conditions.add(
            'DMT_MDE_Opportunity__r.IsClosed = false'
        );
        }

        /*
         * Ejecución controlada para pruebas manuales.
         */
        if (recordId != null) {
            Id filterRecordId = recordId;
            conditions.add('Id = :filterRecordId');
        }

        if (!conditions.isEmpty()) {
            query +=
                ' WHERE ' +
                String.join(conditions, ' AND ');
        }

        return Database.getQueryLocator(query);
    }

    public void execute(
        Database.BatchableContext context,
        List<SObject> scope
    ) {
        for (SObject record : scope) {
            shiftAnnualValues(record);
        }

        if (!scope.isEmpty()) {
            Database.update(scope, false);
        }
    }

    public void finish(
        Database.BatchableContext context
    ) {
        // No action required.
    }

    /**
     * Desplaza todas las tablas anuales soportadas:
     * Basic Financials, Business Plan y Cross Sell.
     */
    @TestVisible
    private static void shiftAnnualValues(
        SObject record
    ) {
        String recordObjectApiName =
            record.getSObjectType()
                .getDescribe()
                .getName();

        List<List<String>> shiftChains =
            buildShiftChains(recordObjectApiName);

        for (List<String> chain : shiftChains) {
            shiftChain(record, chain);
        }
    }

    /**
     * Conservamos este método para no romper los tests
     * que ya lo utilizasen.
     */
    @TestVisible
    private static void shiftFinancials(
        SObject record
    ) {
        shiftAnnualValues(record);
    }

    /**
     * Lee primero todos los valores y después realiza
     * el desplazamiento para no perder información.
     */
    private static void shiftChain(
        SObject record,
        List<String> fields
    ) {
        List<Object> originalValues =
            new List<Object>();

        for (String fieldName : fields) {
            originalValues.add(record.get(fieldName));
        }

        for (
            Integer index = 0;
            index < fields.size() - 1;
            index++
        ) {
            record.put(
                fields[index],
                originalValues[index + 1]
            );
        }

        record.put(
            fields[fields.size() - 1],
            null
        );
    }

    /**
     * Construye únicamente cadenas cuyos campos existan
     * y sean editables en el objeto correspondiente.
     *
     * Esto permite soportar diferencias entre Account
     * y DMT_Opportunity_Client__c.
     */
    @TestVisible
    private static List<List<String>> buildShiftChains(
        String targetObjectApiName
    ) {
        Schema.SObjectType targetType =
            Schema.getGlobalDescribe().get(
                targetObjectApiName
            );

        if (targetType == null) {
            throw new IllegalArgumentException(
                'Unsupported object: ' +
                targetObjectApiName
            );
        }

        Map<String, Schema.SObjectField> describedFields =
            targetType.getDescribe()
                .fields
                .getMap();

        Map<String, String> actualFieldNamesByLowerCase =
            new Map<String, String>();

        for (String actualFieldName :
            describedFields.keySet()
        ) {
            actualFieldNamesByLowerCase.put(
                actualFieldName.toLowerCase(),
                actualFieldName
            );
        }

        List<List<String>> chains =
            new List<List<String>>();

        addBasicFinancialChains(
            chains,
            describedFields,
            actualFieldNamesByLowerCase
        );

        addBusinessPlanChains(
            chains,
            describedFields,
            actualFieldNamesByLowerCase
        );

        addCrossSellChains(
            chains,
            describedFields,
            actualFieldNamesByLowerCase
        );

        return chains;
    }

    private static void addBasicFinancialChains(
        List<List<String>> chains,
        Map<String, Schema.SObjectField> describedFields,
        Map<String, String> actualNames
    ) {
        for (String metric : FINANCIAL_METRICS) {
            addSupportedChain(
                chains,
                new List<String>{
                    metric + '_Last_Year_number__c',
                    metric + '_Current_Year_number__c',
                    metric + '_Next_Year_number__c',
                    metric + '_Next_Year_1_number__c',
                    metric + '_Next_Year_2_number__c'
                },
                describedFields,
                actualNames
            );
        }
    }

    private static void addBusinessPlanChains(
        List<List<String>> chains,
        Map<String, Schema.SObjectField> describedFields,
        Map<String, String> actualNames
    ) {
        for (String metric : BUSINESS_PLAN_METRICS) {
            addSupportedChain(
                chains,
                new List<String>{
                    'Past2_FY_' + metric + '_amount__c',
                    'Past_FY_' + metric + '_amount__c',
                    'Current_FY_' + metric + '_amount__c',
                    'Next_FY_' + metric + '_amount__c'
                },
                describedFields,
                actualNames
            );
        }
    }

    private static void addCrossSellChains(
        List<List<String>> chains,
        Map<String, Schema.SObjectField> describedFields,
        Map<String, String> actualNames
    ) {
        addSupportedChain(
            chains,
            new List<String>{
                'gf_kpi_trans_fees_2ya_amount__c',
                'gf_kpi_trans_fees_ly_amount__c',
                'gf_kpi_trans_fees_cyr_amount__c',
                'gf_kpi_trans_fees_nxy_amount__c'
            },
            describedFields,
            actualNames
        );

        addSupportedChain(
            chains,
            new List<String>{
                'gf_xb_cust_ope_revenue_2ya_per__c',
                'gf_xb_cust_ope_revenue_ly_per__c',
                'gf_xb_cust_ope_revenue_cyr_per__c',
                'gf_xb_cust_ope_revenue_nxy_per__c'
            },
            describedFields,
            actualNames
        );
    }

    /**
     * Los campos fórmula quedan descartados porque
     * DescribeFieldResult.isCalculated() devuelve true.
     */
    private static void addSupportedChain(
        List<List<String>> chains,
        List<String> requestedFields,
        Map<String, Schema.SObjectField> describedFields,
        Map<String, String> actualNames
    ) {
        List<String> resolvedFields =
            new List<String>();

        for (String requestedField : requestedFields) {
            String actualFieldName =
                actualNames.get(
                    requestedField.toLowerCase()
                );

            if (actualFieldName == null) {
                return;
            }

            Schema.DescribeFieldResult fieldDescription =
                describedFields.get(actualFieldName)
                    .getDescribe();

            if (fieldDescription.isCalculated()) {
                return;
            }
            resolvedFields.add(actualFieldName);
        }

        chains.add(resolvedFields);
    }
}