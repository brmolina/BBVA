/*
*   @author: GlobalDesktop - APC
*   @Method: OpportunitiesPieCnt
*   @Description: Class used to print Risk Availability Charts related to Consumo_de_linea object filtered by several params

*   @Versions:
        v1 - 2019/04/26 - Initial version
*/
public with sharing class RiskAvailabilityCnt {


     /*
    *   @author: GlobalDesktop - APC
    *   @Method: getData
    *   @Description:

    *   @Versions:
            v1 - 2019/04/26 - Initial version
    */
     @AuraEnabled
    public static String getData(String clientId, String typeAmount) {
        try {
            // Map<String, Map<String, Double>> mapValues = new Map<String, Map<String, Double>>();
            Map<String, Map<String, Double>> mapTenors = new Map<String, Map<String, Double>>();
            // Map<String, Double> mapValues = new Map<String, Double>();

            Final List<Consumo_de_Linea__c> lstConsumos = getQuerySelector(clientId, typeAmount);
            System.debug('::::::lstConsumos to table: ' + JSON.serialize(lstConsumos));


            if(!lstConsumos.isEmpty()) {
                System.debug('::::lstConsumos:: ' + JSON.serialize(lstConsumos));

                mapTenors = populateValues(lstConsumos, typeAmount);


            }


            // WrapperGlobalData wrapperGlobal = new WrapperGlobalData(mapColors, mapData);
            // System.debug(':::respuesta:: ' + JSON.serialize(wrapperGlobal));

            // Final String RESPONSE = JSON.serialize(wrapperGlobal);
            // return RESPONSE;

            System.debug(':::return:: ' + JSON.serialize(mapTenors));
            return JSON.serialize(mapTenors);
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }

    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getTypeAmount
    *   @Description: Populating map of values depending on the typeAmout required. Rows(2) keys {CONSUMED,LIMIT}

    *   @Input: List<Consumo_de_Linea__c> lstConsumos, String typeAmount
    *   @Output: Map<String, Double> mapValues
    *   @Versions:
            v1 - 2019/04/29 - Initial version
    */
    private static Map<String, Map<String, Double>>  populateValues(List<Consumo_de_Linea__c> lstConsumos, String typeAmount) {
        Final Map<String, Map<String, Double>> mapTenors = new Map<String, Map<String, Double>>();
        Final String CONSUMED = 'CONSUMED';
        Final String LIMITE = 'LIMIT';

        for(Consumo_de_Linea__c consumo : lstConsumos) {
            Final Map<String, Double> mapValues = new Map<String, Double>();
            switch on typeAmount {
                when 'Credit' {
                    mapValues.put(CONSUMED, consumo.credit_drawn_amount__c);
                    mapValues.put(LIMITE, consumo.credit_limit_amount__c - consumo.credit_drawn_amount__c);
                }
                when 'Derivatives' {
                    mapValues.put(CONSUMED, consumo.derivatives_drawn_amount__c);
                    mapValues.put(LIMITE, consumo.derivatives_limit_amount__c - consumo.derivatives_drawn_amount__c);
                }
                when 'Deposits' {
                    mapValues.put(CONSUMED, consumo.deposits_drawn_amount__c);
                    mapValues.put(LIMITE, consumo.deposits_limit_amount__c - consumo.deposits_drawn_amount__c);
                }
                when 'Repos' {
                    mapValues.put(CONSUMED, consumo.repos_drawn_amount__c);
                    mapValues.put(LIMITE, consumo.repos_limit_amount__c - consumo.repos_drawn_amount__c);
                }
                when 'Settlement' {
                    mapValues.put(CONSUMED, consumo.settlement_drawn_amount__c);
                    mapValues.put(LIMITE, consumo.settlement_limit_amount__c - consumo.settlement_drawn_amount__c);
                }
                when else {//DVP
                    mapValues.put(CONSUMED, consumo.delivery_vs_pay_drawn_amount__c);
                    mapValues.put(LIMITE, consumo.delivery_vs_pay_limit_amount__c - consumo.delivery_vs_pay_drawn_amount__c);
                }
            }
            mapTenors.put(consumo.tenor_desc__c, mapValues);
        }
        return mapTenors;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getQuerySelector
    *   @Description:

    *   @Versions:
            v1 - 2019/04/26 - Initial version
    */
    private static List<Consumo_de_Linea__c> getQuerySelector(String clientId, String typeAmount) {
        String querySelect;
        List<Consumo_de_Linea__c> lstConsumos = new List<Consumo_de_Linea__c>();

        Final String amountsSelector = getTypeAmount(String.escapeSingleQuotes(typeAmount));
        querySelect = 'SELECT Id, participant_id__c, business_group_id__c, tenor_desc__c, operation_date__c ' + String.escapeSingleQuotes(amountsSelector);
        querySelect += ' FROM Consumo_de_Linea__c';

        String queryWhere;
        Final Account client = getAccountSelector(clientId);
        if(client != null && client.DES_Structure_Type__c != null) {
            // Final String typeAcc = getTypeAcc(client.DES_Structure_Type__c);

            queryWhere = ' WHERE participant_id__c =: clientId';
            queryWhere += ' ORDER BY operation_date__c DESC LIMIT 9';

            Final String query = querySelect + queryWhere;
            System.debug(':::::dynamic query::: ' + query);
            lstConsumos = Database.query(query);
        }
        return lstConsumos;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getAccountSelector
    *   @Description:

    *   @Versions:
            v1 - 2019/04/26 - Initial version
    */
    private static Account getAccountSelector(String clientId) {
        Account accountSelected = new Account();
        if (Schema.sObjectType.Account.fields.DES_Structure_Type__c.isAccessible()) {
            accountSelected = [SELECT Id, DES_Structure_Type__c FROM Account Where Id = :clientId LIMIT 1];
        }

        return accountSelected;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getTypeAmount
    *   @Description: fulfilling fields to be used in query. It depends on the attribute "typeAmount" sent to the component

    *   @Input: typeAmount{'Credit','Derivatives','Deposits', 'Repos', 'Settlement', 'DVP'}, the last one is the default value
    *   @Output: getTypeAmount => String to be added to the query clause
    *   @Versions:
            v1 - 2019/04/26 - Initial version
    */
    private static String getTypeAmount(String typeAmount) {
        System.debug('::::typeAmount ' + typeAmount);
        String amountSelector;
        amountSelector = ',';

        switch on typeAmount {
            when 'Credit' {
                amountSelector += ' convertCurrency(credit_drawn_amount__c), convertCurrency(credit_limit_amount__c)';
            }
            when 'Derivatives' {
                amountSelector += ' convertCurrency(derivatives_drawn_amount__c), convertCurrency(derivatives_limit_amount__c)';
            }
            when 'Deposits' {
                amountSelector += ' convertCurrency(deposits_drawn_amount__c), convertCurrency(deposits_limit_amount__c)';
            }
             when 'Repos' {
                amountSelector += ' convertCurrency(repos_drawn_amount__c), convertCurrency(repos_limit_amount__c)';
            }
             when 'Settlement' {
                amountSelector += ' convertCurrency(settlement_drawn_amount__c), convertCurrency(settlement_limit_amount__c)';
            }
            when else {//DVP
                amountSelector += ' convertCurrency(delivery_vs_pay_drawn_amount__c), convertCurrency(delivery_vs_pay_limit_amount__c)';
            }
        }
        return amountSelector;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getTypeAcc
    *   @Description: fulfilling fields to be used in query based on Account.DES_Structure_Type__c

    *   @Input: typeAmount{'Group','Subsidiary') - the last one is the default value
    *   @Output: getTypeAcc => String to be added to the where clause
    *   @Versions:
            v1 - 2019/04/26 - Initial version
    */
    // private static String getTypeAcc(String structureType) {
        // Final String typeAccount = structureType == 'Group' ? ' business_group_id__c' : ' participant_id__c';
        // typeAccount = '';

        // switch on structureType {
        //     when 'Group' {
        //         typeAccount += ' business_group_id__c';
        //     }
        //     when else {//Subsidiary
        //         typeAccount += ' participant_id__c';
        //     }
        // }
        //return typeAccount;
    // }
}