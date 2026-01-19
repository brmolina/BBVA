/**
* ____________________________________________________________________________
* Controller class for DPMX_Container.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-07-20
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class DPMX_Container_Ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_Container_Ctrl() {

    }
    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData (String recordId) {
        Map<String, Object> retMap = new Map<String, Object>();
        DateTime today = DateTime.now();
        String consultDate = today.format('yyyy-MM-dd');
        DPMX_Dynamic_Pricing__c dynamicPricing =DPMX_Utils.dynamicPricingSelector(recordId);
        retMap.put('dynamicPricing', dynamicPricing);
        if(dynamicPricing.familia_AcquiererCategories_Id__c == '13'){
            retMap.put('isGs', true);
        }else {
            retMap.put('isGs', false);
        }
            try{
                DPMX_Formalize__c formalize = DPMX_Utils.formalizeDPMXSelector(recordId);
                retMap.put('deniedFormalizeCheck', formalize.deniedCheck__c);
                retMap.put('formalizeAcceptedCheck', formalize.formalizeAccepted__c);
                retMap.put('formalizeExist', true);
            } catch(Exception ex){
                retMap.put('formalizeExist', false);
            }
        
        
        String customerId = '';
        if(!dynamicPricing.isCustom__c){
            try{
                Local_Client__c localClient = DPMX_Utils.Local_ClientSelector(dynamicPricing.Company_Name__c);
                customerId = localClient.unique_id__c;
                retMap.put('succes', 'Cliente encontrado');
            } catch(Exception ex){
                retMap.put('error', 'Cliente no encontrado');
            }
        }else{
            retMap.put('succes', 'Cliente establecido');
            retMap.put('razonSocialLst', setListFamilies());
            retMap.put('razonSocialMp', setListFamiliesId());
        }
        retMap.put('customerId', customerId);

        return retMap;
    }

    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> CallComparativeCategories (String customerId, String acquirerCategoryId, String recordId, Boolean isGs) {
        Map<String, Object> retMap = new Map<String, Object>(); 
        Map<String,String> jsonInputMap = new Map<String,String>();
        jsonInputMap.put('customerId', customerId);
        jsonInputMap.put('acquirerCategoryId', acquirerCategoryId);

        HttpResponse response = DPMX_Utils.callWebService('DPMX_ComparativeCategories', jsonInputMap);
        switch on response.getStatusCode() {
            when 200 {
                String responseReplace;
                if(Test.isRunningTest()){
                    responseReplace = '{"data":{"id":"13","description":"Grandes_Superficies","businessInformations":[{"companyName":"Test","groupName":"TestGroup","rate":{"itemizeRates":[{"rateType":"CREDIT","itemizeRateUnit":{"unitType":"PERCENTAGE","value":11}},{"rateType":"DEBIT","itemizeRateUnit":{"unitType":"AMOUNT","amount":22,"currency":"MXN"}},{"rateType":"INTERNATIONAL","itemizeRateUnit":{"unitType":"PERCENTAGE","value":33}}]}},{"companyName":"SUBURBIA S DE RL DE CV","groupName":"LIVERPOOL","rate":{"itemizeRates":[{"rateType":"CREDIT","itemizeRateUnit":{"unitType":"PERCENTAGE","value":1.75}},{"rateType":"DEBIT","itemizeRateUnit":{"unitType":"AMOUNT","amount":1.01,"currency":"MXN"}},{"rateType":"INTERNATIONAL","itemizeRateUnit":{"unitType":"PERCENTAGE","value":1.75}}]}},{"companyName":"SANBORN HERMANOS SA DE CV","groupName":"GRUPO CARSO","rate":{"itemizeRates":[{"rateType":"CREDIT","itemizeRateUnit":{"unitType":"PERCENTAGE","value":1.6}},{"rateType":"DEBIT","itemizeRateUnit":{"unitType":"AMOUNT","amount":1.24,"currency":"MXN"}},{"rateType":"INTERNATIONAL","itemizeRateUnit":{"unitType":"PERCENTAGE","value":2.38}}]}},{"companyName":"RESTAURANTES TOKS SA DE CV","groupName":"GIGANTE","rate":{"itemizeRates":[{"rateType":"CREDIT","itemizeRateUnit":{"unitType":"PERCENTAGE","value":2.0}},{"rateType":"DEBIT","itemizeRateUnit":{"unitType":"AMOUNT","amount":2.0,"currency":"MXN"}},{"rateType":"INTERNATIONAL","itemizeRateUnit":{"unitType":"PERCENTAGE","value":2.46}}]}},{"companyName":"SANBORN HERMANOS SA DE CV","groupName":"GRUPO CARSO","rate":{"itemizeRates":[{"rateType":"CREDIT","itemizeRateUnit":{"unitType":"PERCENTAGE","value":1.61}},{"rateType":"DEBIT","itemizeRateUnit":{"unitType":"AMOUNT","amount":1.24,"currency":"MXN"}},{"rateType":"INTERNATIONAL","itemizeRateUnit":{"unitType":"PERCENTAGE","value":2.34}}]}}]}}';
                	responseReplace = responseReplace.replaceAll('"currency":','"currency_y":');
                    final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                	final DPMX_ComparativeCategories_Wrapper acquirerCategoriesWrapper = (DPMX_ComparativeCategories_Wrapper) Json.deserialize(JSON.serialize(responseMap.get('data')), DPMX_ComparativeCategories_Wrapper.class);
					retMap.put('acquirerCategoriesWrapper', acquirerCategoriesWrapper);				
                }else {
                    responseReplace = response.getBody().replaceAll('"currency":','"currency_y":');
                }
                final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                System.debug(responseMap);
                System.debug(responseMap.get('data'));
                final DPMX_ComparativeCategories_Wrapper acquirerCategoriesWrapper = (DPMX_ComparativeCategories_Wrapper) Json.deserialize(JSON.serialize(responseMap.get('data')), DPMX_ComparativeCategories_Wrapper.class);

                retMap.put('acquirerCategoriesWrapper',acquirerCategoriesWrapper);
        List<DPMX_Company_Comparison__c> companyComparisionLst = new List<DPMX_Company_Comparison__c>();
        List<DPMX_Company_Comparison__c> companyComparisionToInsertLst = new List<DPMX_Company_Comparison__c>();

        List<DPMX_Company_Comparison__c> companyComparisionexistenLst = [Select Name, companyName__c, Dynamic_Pricing__c, groupName__c, Company__c, Debit__c, Credit__c, International__c, CurrencyIsoCode, isVisible__c, isGs__c
                FROM DPMX_Company_Comparison__c WHERE Dynamic_Pricing__c =:recordId];
                boolean exist = false;
                System.debug(companyComparisionexistenLst);
            for(integer i=0; i!=acquirerCategoriesWrapper.businessInformations.size(); i++){
                DPMX_Company_Comparison__c companyComparision = new DPMX_Company_Comparison__c();
                companyComparision.companyName__c = acquirerCategoriesWrapper.businessInformations[i].companyName;
                companyComparision.groupName__c = acquirerCategoriesWrapper.businessInformations[i].groupName;
                companyComparision.Dynamic_Pricing__c = recordId;
                companyComparision.isVisible__c = false;
                for(integer z=0; z!=acquirerCategoriesWrapper.businessInformations[i].rate.itemizeRates.size(); z++){
                    System.debug(acquirerCategoriesWrapper.businessInformations[i].rate.itemizeRates[z].itemizeRateUnit.value);
                    if(acquirerCategoriesWrapper.businessInformations[i].rate.itemizeRates[z].rateType == 'CREDIT'){
                        companyComparision.Credit__c = acquirerCategoriesWrapper.businessInformations[i].rate.itemizeRates[z].itemizeRateUnit.value;
                    }else if(acquirerCategoriesWrapper.businessInformations[i].rate.itemizeRates[z].rateType == 'DEBIT'){
                        if(isGs){
                            companyComparision.Debit__c = acquirerCategoriesWrapper.businessInformations[i].rate.itemizeRates[z].itemizeRateUnit.amount;
                            companyComparision.isGs__c = isGs;
                        }else{
                            companyComparision.Debit__c = acquirerCategoriesWrapper.businessInformations[i].rate.itemizeRates[z].itemizeRateUnit.value;
                        }
                    }else if(acquirerCategoriesWrapper.businessInformations[i].rate.itemizeRates[z].rateType == 'INTERNATIONAL'){
                        companyComparision.International__c = acquirerCategoriesWrapper.businessInformations[i].rate.itemizeRates[z].itemizeRateUnit.value;
                    }
                }
                companyComparisionLst.add(companyComparision);
            }

            //Verificamos que no exita ya este objeto para evitar duplciados
            for(DPMX_Company_Comparison__c companyComparisionToInsert: companyComparisionLst){
                for(DPMX_Company_Comparison__c companyComparisionexisten: companyComparisionexistenLst)
                {
                    if(companyComparisionToInsert.companyName__c == companyComparisionexisten.companyName__c &&
                    companyComparisionToInsert.groupName__c == companyComparisionexisten.groupName__c &&
                    companyComparisionToInsert.Debit__c == companyComparisionexisten.Debit__c &&
                    companyComparisionToInsert.Credit__c == companyComparisionexisten.Credit__c &&
                    companyComparisionToInsert.International__c == companyComparisionexisten.International__c
                    ){
                        exist = true;
                        break;
                    }
                }
                if(!exist){
                    companyComparisionToInsertLst.add(companyComparisionToInsert);
                }else{
                    exist = false;
                }
            }
            
            System.debug(companyComparisionToInsertLst.size());
            if(companyComparisionToInsertLst.size() > 0){
                System.debug(companyComparisionToInsertLst.size());
                insert(companyComparisionToInsertLst);
            }

            retMap.put('companyComparisonList', companyComparisionexistenLst);
                System.debug('200');
                retMap.put('success', true);
            }
            when else {
                System.debug('400');
                retMap.put('success', false);
            }
        }
        return retMap;
    }

    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> callAcquirerActivitiesService (String recordId, String customerId, String familia) {
        Map<String, Object> retMap = new Map<String, Object>();     
        Map<String,String> jsonInputMap = new Map<String,String>();
        jsonInputMap.put('customerId', customerId);
        jsonInputMap.put('familia', familia);
        HttpResponse response = DPMX_Utils.callWebService('DPMX_AcquirerActivities', jsonInputMap);
        switch on response.getStatusCode() {
            when 200 {
                String responseReplace0;
                if(Test.isRunningTest()){
                    responseReplace0 = '{"data":[{"id":"98717946","businessInformation":{"companyName":"ECOSISTEMAS Y RECUBR IMIENTOS DE MEXICO S A DE CV","groupName":"GRUPO IMPAC","familyAcquirer":"Refacciones_y_ferreteria"},"discount":{"debit":{"itemizeType":{"unitType":"PERCENTAGE","value":1.75}},"percentage":{"credit":2.38,"international":2.38},"monetaryCeiling":{"amount":1.0E+15,"currency":"MXN"},"totalAmount":{"amount":6675.9,"currency":"MXN"}},"ratesResult":"NA","expenses":{"totalAmount":{"amount":-497.12,"currency":"MXN"},"mit":{"amount":0.0,"currency":"MXN"}},"yieldPercentage":12.43,"taxAcquirer":{"amount":6178.78,"currency":"MXN"},"transaction":{"debit":{"own":4.0,"thirdParty":26.0},"credit":{"own":2.0,"thirdParty":17.0},"international":0.0,"acquirerAffiliation":49.0},"billing":{"debit":{"own":{"amount":32058.88,"currency":"MXN"},"thirdParty":{"amount":100816.11,"currency":"MXN"}},"credit":{"own":{"amount":9611.52,"currency":"MXN"},"thirdParty":{"amount":173186.3,"currency":"MXN"}},"international":{"amount":0.0,"currency":"MXN"},"totalAmount":{"amount":315672.8,"currency":"MXN"}},"tickets":{"debit":{"own":{"amount":8014.72,"currency":"MXN"},"thirdParty":{"amount":3877.54,"currency":"MXN"}},"credit":{"own":{"amount":4805.76,"currency":"MXN"},"thirdParty":{"amount":10187.43,"currency":"MXN"}},"international":{"amount":0.0,"currency":"MXN"},"totalAmount":{"amount":6442.3,"currency":"MXN"}},"terminal":{"id":2},"percentage":{"debit":{"mixOwn":0.1,"mixExternal":0.32},"credit":{"mixOwn":0.03,"mixExternal":0.55},"mixInternational":0.0,"total":1.0},"devices":{"devicesNumber":2,"pinPads":{"pinPadsNumber":0}},"ecommerce":"Y","informationDate":"julio-2023","commission":{"billing":{"amount":0.0,"currency":"MXN"},"extraBilling":{"amount":0.0,"currency":"MXN"},"cellnet":{"amount":9.66,"currency":"MXN"},"opportunity":{"lowBilling":{"amount":0.0,"currency":"MXN"},"posExtra":{"amount":174.0,"currency":"MXN"},"cellnet":{"amount":0.0,"currency":"MXN"}}}}]}';
                	responseReplace0 = responseReplace0.replaceAll('"currency":','"currency_y":');
                }else {
            	    responseReplace0 = response.getBody().replaceAll('"currency":','"currency_y":');
                }
                final String responseReplace1 = responseReplace0.replaceAll('"number":','"number_y":');
                final String responseReplace2 = responseReplace1.replaceAll('"id":','"id_y":');
                final String responseReplace3 = responseReplace2.replaceAll('"expenses":\\{"totalAmount":\\{"amount":-','"expenses":\\{"totalAmount":\\{"amount":');
                final String responseReplace = responseReplace3.replaceAll('"transaction":','"transaction_y":');
                
                updateDPMXJSON(recordId, responseReplace, 'acqAct');
                final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                final List<DPMX_AcquirerActivities_Wrapper> acquirerActivitiesWrapperLst = (List<DPMX_AcquirerActivities_Wrapper>) Json.deserialize(JSON.serialize(responseMap.get('data')), List<DPMX_AcquirerActivities_Wrapper>.class);
                DPMX_AcquirerActivities_Wrapper acquirerActivitiesWrapper = acquirerActivitiesWrapperLst[0];
                //acquirerActivitiesWrapper.expenses.totalAmount.amount= acquirerActivitiesWrapper.expenses.totalAmount.amount*(-1);
                if (acquirerActivitiesWrapper.BusinessInformation.familyAcquirer == Label.DPMX_GS) {
                    acquirerActivitiesWrapper.isGS = true;
                }else {
                    acquirerActivitiesWrapper.isGS = false; 
                }
                // ecommerce conversion
                Set<String> SetEcommerce = new Set<String>{'Y', 'S'};
                if (SetEcommerce.contains(acquirerActivitiesWrapper.ecommerce)) {
                    acquirerActivitiesWrapper.ecommerceCheckbox = true;
                }else{
                    acquirerActivitiesWrapper.ecommerceCheckbox = false;
                }
                // Calculate Basis points gastos
                if (acquirerActivitiesWrapper.ecommerceCheckbox &&
                    (acquirerActivitiesWrapper.terminal.id_y == 0 || acquirerActivitiesWrapper.terminal.id_y == null) &&
                    (acquirerActivitiesWrapper.Devices.PinPads.pinPadsNumber == 0 || acquirerActivitiesWrapper.Devices.PinPads.pinPadsNumber == null) &&
                    (acquirerActivitiesWrapper.Devices.devicesNumber == 0 || acquirerActivitiesWrapper.Devices.devicesNumber == null)) {
                        acquirerActivitiesWrapper.basisPoints = '15';
                }else {
                    acquirerActivitiesWrapper.basisPoints = '26';
                }
                // ratesResultIcon
                switch on acquirerActivitiesWrapper.ratesResult {
                    when 'Break even' {
                        acquirerActivitiesWrapper.ratesResultIcon = 'action:close';
                    }
                    when 'Bueno', 'Óptimo' {
                        acquirerActivitiesWrapper.ratesResultIcon = 'action:approval';
                    }
                    when else {
                        acquirerActivitiesWrapper.ratesResultIcon = 'action:question_post_action';
                    }
                }
                //Calculate the thirdparty+own for debit/credit
                //transacciones
                acquirerActivitiesWrapper.transaction_y.debit.total = acquirerActivitiesWrapper.transaction_y.debit.own + acquirerActivitiesWrapper.transaction_y.debit.thirdParty;
                acquirerActivitiesWrapper.transaction_y.credit.total = acquirerActivitiesWrapper.transaction_y.credit.own + acquirerActivitiesWrapper.transaction_y.credit.thirdParty;

                //FacuraciónMensual
                acquirerActivitiesWrapper.billing.debit.total = acquirerActivitiesWrapper.billing.debit.own.amount + acquirerActivitiesWrapper.billing.debit.thirdParty.amount;
                acquirerActivitiesWrapper.billing.credit.total = acquirerActivitiesWrapper.billing.credit.own.amount + acquirerActivitiesWrapper.billing.credit.thirdParty.amount;

                //Ticket Promedio
                acquirerActivitiesWrapper.tickets.debit.total = acquirerActivitiesWrapper.tickets.debit.own.amount + acquirerActivitiesWrapper.tickets.debit.thirdParty.amount;
                acquirerActivitiesWrapper.tickets.credit.total = acquirerActivitiesWrapper.tickets.credit.own.amount + acquirerActivitiesWrapper.tickets.credit.thirdParty.amount;

                //% MIX - Aqui hay que poner a % los valores.
                integer perc = 100;
                acquirerActivitiesWrapper.percentage.debit.mixTotal = (acquirerActivitiesWrapper.percentage.debit.mixOwn + acquirerActivitiesWrapper.percentage.debit.mixExternal)* perc;
                acquirerActivitiesWrapper.percentage.credit.mixTotal = (acquirerActivitiesWrapper.percentage.credit.mixOwn + acquirerActivitiesWrapper.percentage.credit.mixExternal)* perc;
                acquirerActivitiesWrapper.percentage.mixInternational = acquirerActivitiesWrapper.percentage.mixInternational* perc;
                acquirerActivitiesWrapper.percentage.total = acquirerActivitiesWrapper.percentage.total* perc;

                retMap.put('acquirerActivitiesWrapper', acquirerActivitiesWrapper);
                retMap.put('success', true);
            }when else {
                //
                retMap.put('success', false);
            }
        }
        return retMap;
    }

    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> callAcquirerFeesService (String recordId, String customerId, String acquirerId, DPMX_AcquirerActivities_Wrapper acquirerActivitiesWrapper, Discount_Rates_Wrapper discountRates, Boolean checkbox) {
        Map<String, Object> retMap = new Map<String, Object>();
        Map<String,String> jsonInputMap = new Map<String,String>();
        Map<String, Object> responseMap = new Map<String, Object>();
        DPMX_AcquirerActivitiesFees_Wrapper acquirerFeesWrapperToSend = new DPMX_AcquirerActivitiesFees_Wrapper();
        List<DPMX_AcquirerActivitiesFees_Wrapper.ItemizeFees> brekEvenFees = new List<DPMX_AcquirerActivitiesFees_Wrapper.ItemizeFees>();
        Boolean checkBreakEvenBool = false;

        DPMX_Dynamic_Pricing__c dynamicPricing =DPMX_Utils.dynamicPricingSelector(recordId);
        System.debug(acquirerActivitiesWrapper);
        System.debug(discountRates);
        jsonInputMap.put('customerId', customerId);
        jsonInputMap.put('acquirerId', acquirerId);
        HttpResponse response = DPMX_Utils.callWebService('DPMX_AcquirerActivitiesFees', jsonInputMap);
        System.debug('--- '+response.getStatusCode());
        switch on response.getStatusCode() {
            when 200 {
                String responseReplace;
                if(Test.isRunningTest()){
					responseReplace = '{"data":{"id":"21","consultMonth":"julio-2023","description":"Refacciones_y_ferreteria","scenarios":[{"commissionType":"ninguna","scenarioType":"GOOD","fees":{"itemizeFees":[{"feeType":"DEBIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":2.15}},{"feeType":"CREDIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":2.68}},{"feeType":"INTERNATIONAL","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":3.0}}],"profitability":{"percentage":14.63,"amount":{"amount":7272.94,"currency":"MXN"}}}},{"commissionType":"ninguna","scenarioType":"GOOD","fees":{"itemizeFees":[{"feeType":"DEBIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":1.83}},{"feeType":"CREDIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":2.91}},{"feeType":"INTERNATIONAL","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":3.0}}],"profitability":{"percentage":14.63,"amount":{"amount":7272.94,"currency":"MXN"}}}},{"commissionType":"ninguna","scenarioType":"OPTIMAL","fees":{"itemizeFees":[{"feeType":"DEBIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":2.25}},{"feeType":"CREDIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":3.2}},{"feeType":"INTERNATIONAL","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":3.0}}],"profitability":{"percentage":16.8,"amount":{"amount":8351.7,"currency":"MXN"}}}},{"commissionType":"ninguna","scenarioType":"BREAK_EVEN","fees":{"itemizeFees":[{"feeType":"DEBIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":0.13}},{"feeType":"CREDIT","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":0.17}},{"feeType":"INTERNATIONAL","itemizeFeeUnit":{"unitType":"PERCENTAGE","value":3.0}}],"profitability":{"percentage":0.0,"amount":{"amount":0.0,"currency":"MXN"}}}}]}}';
                    responseReplace = responseReplace.replaceAll('"currency":','"currency_y":');
                }else {
            	    responseReplace = response.getBody().replaceAll('"currency":','"currency_y":');
                }
                responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                acquirerFeesWrapperToSend = (DPMX_AcquirerActivitiesFees_Wrapper) Json.deserialize(JSON.serialize(responseMap.get('data')), DPMX_AcquirerActivitiesFees_Wrapper.class);
                acquirerFeesWrapperToSend = calculatedBaiRentForFees(responseReplace, recordId, acquirerActivitiesWrapper, discountRates);
                for (integer i = 0; i < acquirerFeesWrapperToSend.scenarios.size(); i++) {
                    if (acquirerFeesWrapperToSend.scenarios[i].scenarioType == 'BREAK_EVEN') {
                        brekEvenFees = acquirerFeesWrapperToSend.scenarios[i].fees.itemizeFees;
                    }
                }
                checkBreakEvenBool = checkrateBreakEvenOutLimits(recordId, acquirerActivitiesWrapper, discountRates, brekEvenFees);
                if(checkBreakEvenBool){
                    System.debug('INSIDE');
                    responseReplace = response.getBody().replaceAll('"BREAK_EVEN"','"Minimo viable"');
                    responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                    acquirerFeesWrapperToSend = (DPMX_AcquirerActivitiesFees_Wrapper) Json.deserialize(JSON.serialize(responseMap.get('data')), DPMX_AcquirerActivitiesFees_Wrapper.class);
                    acquirerFeesWrapperToSend = calculatedBaiRentForFees(responseReplace, recordId, acquirerActivitiesWrapper, discountRates);
                    updatemessageBreakEven(recordId, checkBreakEvenBool);
                }
                updateDPMXJSON(recordId, responseReplace, 'acqFees');
                retMap.put('checkrateBreakEvenOutLimits', checkBreakEvenBool);
                retMap.put('acquirerFeesWrapper', acquirerFeesWrapperToSend);
                retMap.put('sendConditionLst', acquirerFeesWrapperToSend.scenarios);
                retMap.put('dynamicPricing', dynamicPricing);
                retMap.put('success', true);
                System.debug('200 - 1');
            }
            when else {
                System.debug('400 - 1');
                retMap.put('success', false);
            }
        }
        return retMap;
    }

    /**
    * @description Get data from services
    * @param recordId : Dynamic Pricing Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> callCorporateRateService (String recordId, String customerId, String acquirerId, DPMX_AcquirerActivities_Wrapper acquirerActivitiesWrapper) {
        DateTime today = DateTime.now();
        String consultDate = today.format('yyyy-MM-dd');
        Map<String, Object> retMap = new Map<String, Object>();
        Map<String, Object> retMapRentBai = new Map<String, Object>(); 
        Map<String,String> jsonInputMap = new Map<String,String>();
        jsonInputMap.put('customerId', customerId);
        jsonInputMap.put('acquirerId', acquirerId);
        
        HttpResponse response = DPMX_Utils.callWebService('DPMX_CorporateRates', jsonInputMap);
        switch on response.getStatusCode() {
            when 200 {
                String responseReplace0;
                if(Test.isRunningTest()){
					responseReplace0 = '{"data":[{"id":"DISCOUNT","lastUpdateDate":"2023-07-01","itemizeType":{"unitType":"PERCENTAGE","value":0.0},"credit":{"value":0.0},"international":{"value":1.6}},{"id":"INTERCHANGE","lastUpdateDate":"2023-07-01","itemizeType":{"unitType":"PERCENTAGE","value":2.25},"credit":{"value":3.2},"international":{"value":4.0}},{"id":"AVERAGE_DISCOUNT","lastUpdateDate":"2023-07-01","itemizeType":{"unitType":"PERCENTAGE","value":0.99},"credit":{"value":1.09},"international":{"value":2.39}}]}';
                    responseReplace0 = responseReplace0.replaceAll('"number":','"number_y":');
                }else {
                	responseReplace0 = response.getBody().replaceAll('"number":','"number_y":');
                }
                final String responseReplace = responseReplace0.replaceAll('"id":','"id_y":');
                updateDPMXJSON(recordId, responseReplace, 'corpRates');
                final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                final List<DPMX_CorporateRates_Wrapper> CorporateRatesWrapper = (List<DPMX_CorporateRates_Wrapper>) Json.deserialize(JSON.serialize(responseMap.get('data')), List<DPMX_CorporateRates_Wrapper>.class);

                Discount_Rates_Wrapper interchangeRates = new Discount_Rates_Wrapper();
                Discount_Rates_Wrapper discountRates = new Discount_Rates_Wrapper();
                List<Company_Info> companies = new List<Company_Info>();
                Double credit;
                Double international;
                Double debit;
                
                for (DPMX_CorporateRates_Wrapper CorporateRate: CorporateRatesWrapper) {

                credit = CorporateRate.credit.value;
                international = CorporateRate.international.value;
                if(CorporateRate.itemizeType.value == null){
                    debit = CorporateRate.itemizeType.amount;
                }else{
                    debit = CorporateRate.itemizeType.value;
                }

                    switch on CorporateRate.id_y {
                        when 'INTERCHANGE' {
                            interchangeRates.credit = credit;
                            interchangeRates.debit = debit;
                            interchangeRates.international = international;
                        }
                        when 'DISCOUNT' {
                            discountRates.credit = credit;
                            discountRates.debit = debit;
                            discountRates.international = international;
                        }
                        when 'AVERAGE_DISCOUNT' {
                            Company_Info familyAverage = new Company_Info();
                            familyAverage.id = '';
                            familyAverage.name = System.Label.DPMX_CompanyComparison_Row1;
                            familyAverage.credit = credit;
                            familyAverage.debit = debit;
                            familyAverage.international = international;
                            companies.add(familyAverage);
                        }
                    }
                }

                if(acquirerActivitiesWrapper != null){
                    if(acquirerActivitiesWrapper.isGS){
                        retMapRentBai = updateRates(recordId, acquirerActivitiesWrapper, interchangeRates, false, acquirerActivitiesWrapper.discount.percentage.credit, acquirerActivitiesWrapper.discount.debit.itemizeType.amount, acquirerActivitiesWrapper.discount.percentage.international, false, acquirerActivitiesWrapper.expenses.totalAmount.amount);
                    }else {
                        retMapRentBai = updateRates(recordId, acquirerActivitiesWrapper, interchangeRates, false, acquirerActivitiesWrapper.discount.percentage.credit, acquirerActivitiesWrapper.discount.debit.itemizeType.value, acquirerActivitiesWrapper.discount.percentage.international, false, acquirerActivitiesWrapper.expenses.totalAmount.amount);
                    }
                    acquirerActivitiesWrapper.yieldPercentage = (Decimal) retMapRentBai.get('profitability')+'';
                    acquirerActivitiesWrapper.taxAcquirer.amount = (Decimal) retMapRentBai.get('profitAmount');
                }
                retMap.put('acquirerActivitiesWrapper', acquirerActivitiesWrapper);
                retMap.put('interchangeRates', interchangeRates);
                retMap.put('discountRates', discountRates);
                retMap.put('discountWrapper', CorporateRatesWrapper);
                retMap.put('companies', companies);
                retMap.put('success', true);
            }
            when else {
                retMap.put('success', false);
            }
        }
        return retMap;
    }

    /**
    * @description ??????????????????????
    * @param recordId : Client Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> updateFields (Id recordId, string result, Decimal debit, boolean decimalBoolean, Decimal credit, boolean creditBoolean, Decimal international, boolean internationalBoolean, boolean isSimulated, Decimal rentaibilidad, Decimal bai) {
        Map<String, Object> retMap = new Map<String, Object>(); 
        DPMX_Dynamic_Pricing__c dynamicPricing = DPMX_Utils.dynamicPricingSelector(recordId);
        System.debug(decimalBoolean);
        System.debug(debit);
        System.debug(creditBoolean);
        System.debug(credit);
        System.debug(internationalBoolean);
        System.debug(international);
        System.debug(isSimulated);
        Boolean updateNeeds = false;
        if(isSimulated){
            if(decimalBoolean){
                dynamicPricing.CustomSimulatedDebit__c = debit;
                updateNeeds = true;
            }
            if(creditBoolean){
                dynamicPricing.CustomSimulatedCredit__c = credit;
                updateNeeds = true;
            }
            if(internationalBoolean){
                dynamicPricing.CustomSimulatedInternational__c = international;
                updateNeeds = true;
            }
            if(updateNeeds){
                dynamicPricing.resultTasaEditSim__c = result;
                dynamicPricing.CustomSimulatedRent__c = rentaibilidad;
                dynamicPricing.CustomSimulatedBai__c = bai;
            }
        }else {
            if(decimalBoolean){
                dynamicPricing.CustomAcquiredFeesDebit__c = debit;
                updateNeeds = true;
            }
            if(creditBoolean){
                dynamicPricing.CustomAcquiredFeesCredit__c = credit;
                updateNeeds = true;
            }
            if(internationalBoolean){
                dynamicPricing.CustomAcquiredFeesInternational__c = international;
                updateNeeds = true;
            }
            if(updateNeeds){
                dynamicPricing.resultTasaEdit__c = result;
            }
        }
        
        if(updateNeeds){
            if(!dynamicPricing.firstCheckTaxes__c){
               dynamicPricing.firstCheckTaxes__c = true; 
            }
            update dynamicPricing;
        }

        retMap.put('dynamicPricing', dynamicPricing);

        return retMap;
        
    }

    /**
    * @description ??????????????????????
    * @param recordId : Client Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static void updateCustomSimulation (Id recordId, Decimal credit, Decimal debit, Decimal international) {
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT CustomSimulatedCredit__c,
                                                        CustomSimulatedDebit__c,
                                                        CustomSimulatedInternational__c
                                                    FROM DPMX_Dynamic_Pricing__c
                                                    WHERE Id = :recordId];
        
        dynamicPricing.CustomSimulatedCredit__c = credit;
        dynamicPricing.CustomSimulatedDebit__c = debit;
        dynamicPricing.CustomSimulatedInternational__c = international;
        update dynamicPricing;
    }

    /**
    * @description ??????????????????????
    * @param recordId : Client Id
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> updateRates (String recordId, DPMX_AcquirerActivities_Wrapper acquirerActivitiesWrapper, Discount_Rates_Wrapper discountRates, Boolean checkbox, Decimal credit, Decimal debit, Decimal international, boolean isSimulated, Decimal totalAmountSimulated) {
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_Dynamic_Pricing__c dynamicPricing =DPMX_Utils.dynamicPricingSelector(recordId);
        //system.debug('acquirerActivitiesWrapper: '+acquirerActivitiesWrapper);
        //system.debug('discountRates: '+discountRates);

        decimal ingresoBrutoSer = 0;

        string rentabilidadSer = '0';

        final decimal percent = 100;
        final Decimal exchangeCap = 13.5;

        //INGRESO BRUTO (ingBrut) - Dos flujos para GS y para no GS
        Decimal Txndp = 0;
        Decimal Txnda = 0;
        Decimal cuotad = debit;

        Decimal faccp = 0;
        Decimal facca = 0;
        Decimal tasac = credit;

        Decimal facint = 0;
        Decimal tasaint = international;

        Decimal comisionBajaFact = 0;
        Decimal comisionRedCelular = 0;

        Decimal debitAmount = 0;
        Decimal monetaryCeiling = 0;
        Decimal debitAmountTP = 0;

        Decimal expensesTotalAmount = 0;
        Decimal expensesMitAmount = 0;

        Decimal IngresoBruto = 0;
        Decimal exchangeFees = 0;
        Decimal RentaTPVs = 0;

        Decimal rentabilidad = 0;

        boolean isGs = false;
        if(dynamicPricing.familia_AcquiererCategories_Id__c == '13'){
            isGs= true;
        }

        if(isSimulated){

            //En simulacion solo hay una tasa de debito, credio (no hay propio o ajeno), asi que solo se especficia una de las dos, la otra se deja en 0.
            Txnda = dynamicPricing.Sim_Transaction_Debit_Own__c;
            facca = dynamicPricing.Sim_Billing_Credit_Own_Amount__c;
            facint = dynamicPricing.Sim_Billing_International_Amount__c;

            if(dynamicPricing.Sim_Fees_Billing_Checkbox__c){
                comisionBajaFact = 416.44;
            }

            if(dynamicPricing.Sim_Fees_Cellnet_Checkbox__c){
                comisionRedCelular = 0.42;
            }

            System.debug(dynamicPricing.Sim_Fees_ExtraBilling_Checkbox__c);
            System.debug(dynamicPricing.Sim_Terminal_Id__c);
            if(dynamicPricing.Sim_Fees_ExtraBilling_Checkbox__c){
                if (dynamicPricing.Sim_Terminal_Id__c > 0) {
                    RentaTPVs = (dynamicPricing.Sim_Terminal_Id__c - 1) * 174;
                }
            }

            System.debug(RentaTPVs);

            debitAmount = dynamicPricing.Sim_Billing_Debit_Own_Amount__c;
            monetaryCeiling = 9999999;
            debitAmountTP = 0;

            if(totalAmountSimulated == null || totalAmountSimulated == 0){
                expensesTotalAmount = 0;
                expensesTotalAmount = expensesTotalAmount.abs();
            }else {
                expensesTotalAmount = totalAmountSimulated;
                expensesTotalAmount = expensesTotalAmount.abs();
            }
            
            //expensesMitAmount = acquirerActivitiesWrapper.expenses.mit.amount;

        }else {

            //ingresoBrutoSer = acquirerActivitiesWrapper.discount.totalAmount.amount;
            rentabilidadSer = acquirerActivitiesWrapper.yieldPercentage;

            //Flujo GS - (txnda + txndp)*cuotad + (facca + facp)*tasac + facint*tasaint

            Txndp = acquirerActivitiesWrapper.transaction_y.debit.own;
            Txnda = acquirerActivitiesWrapper.transaction_y.debit.thirdParty;
            System.debug('Txnda: '+Txnda);
            System.debug('Txndp: '+Txndp);
            system.debug('debit: '+debit);

            faccp = acquirerActivitiesWrapper.billing.credit.own.amount;
            facca = acquirerActivitiesWrapper.billing.credit.thirdParty.amount;
            System.debug('facca: '+facca);
            System.debug('faccp: '+faccp);
            system.debug('credit: '+credit);

            facint = acquirerActivitiesWrapper.billing.international.amount;
            System.debug('facint: '+facint);
            system.debug('international: '+international);

            comisionBajaFact = acquirerActivitiesWrapper.commission.billing.amount;
            comisionRedCelular = acquirerActivitiesWrapper.commission.cellnet.amount;
            
            debitAmount = acquirerActivitiesWrapper.billing.debit.own.amount;
            monetaryCeiling = acquirerActivitiesWrapper.discount.monetaryCeiling.amount;
            debitAmountTP = acquirerActivitiesWrapper.billing.debit.thirdParty.amount;
            
            expensesTotalAmount = acquirerActivitiesWrapper.expenses.totalAmount.amount;
            expensesTotalAmount = expensesTotalAmount.abs();
            
            expensesMitAmount = acquirerActivitiesWrapper.expenses.mit.amount;
            isGs = acquirerActivitiesWrapper.isGS;
        }
        
        if (isGs) {
            IngresoBruto = (Txnda * debit) + (Txndp * debit) + (facca*(credit/percent)) + (faccp*(credit/percent)) + (facint*(international/percent));
            exchangeFees = (Txnda * discountRates.debit) + (Txndp*discountRates.debit)  + (facca*(discountRates.credit/percent) + faccp*(discountRates.credit/percent)) + (facint * (discountRates.international/percent));
            System.debug('Txnda: '+Txnda);
            System.debug('Txndp: '+Txndp);
            system.debug('debit: '+debit);
            System.debug('facca: '+facca);
            System.debug('faccp: '+faccp);
            system.debug('credit: '+credit);
            System.debug('facint: '+facint);
            system.debug('international: '+international);
            system.debug('(Txnda * debit): '+(Txnda * debit));
            system.debug('(Txndp * debit): '+(Txndp * debit));
            system.debug('(facca*(credit/percent): '+(facca*(credit/percent)));
            system.debug('(faccp*(credit/percent): '+(faccp*(credit/percent)));
            system.debug('(facint*(international/percent): '+(facint*(international/percent)));
            system.debug('GS******IngresoBruto: '+IngresoBruto);
            System.debug('Txnda: '+Txnda);
            System.debug('Txndp: '+Txndp);
            System.debug('discountRates.debit: '+discountRates.debit);
            System.debug('facca: '+facca);
            System.debug('faccp: '+faccp);
            System.debug('discountRates.credit: '+discountRates.credit);
            System.debug('facint: '+facint);
            System.debug('discountRates.international: '+discountRates.international);
            system.debug('(Txnda * discountRates.debit): '+(Txnda * discountRates.debit));
            system.debug('(Txndp*discountRates.debit): '+(Txndp*discountRates.debit));
            system.debug('(facca*(discountRates.credit/percent): '+(facca*(discountRates.credit/percent)));
            system.debug('(faccp*(credit/percent): '+(faccp*(discountRates.credit/percent)));
            system.debug('(facint*(international/percent): '+(facint * (discountRates.international/percent)));
            system.debug('GS******exchangeFees: '+exchangeFees);
        }else {
            IngresoBruto = (facca + faccp) * (credit/percent) + facint * (international/percent);
            System.debug('facca: '+facca);
            System.debug('faccp: '+faccp);
            System.debug('debit: '+debit);
            System.debug('credit: '+credit);
            System.debug('facint: '+facint);
            System.debug('international: '+international);
            system.debug('No_GS_1******IngresoBruto: '+IngresoBruto);
            System.debug('Txnda: '+Txnda);
            System.debug('debitAmount: '+debitAmount);
            System.debug('debit: '+debit);
            System.debug('Txndp: '+Txndp);
            System.debug('monetaryCeiling: '+monetaryCeiling);
            if ((Txnda > 0) && ((debitAmount * (debit/percent)) / Txnda > monetaryCeiling)) {
                IngresoBruto = IngresoBruto + Txnda * monetaryCeiling;
            }else {
                IngresoBruto = IngresoBruto + debitAmount * (debit/percent);
            }
            System.debug('Txnda > 0'+(Txnda > 0));
            System.debug('((debitAmount * (debit/percent)) / Txnda > monetaryCeiling)'+((debitAmount * (debit/percent)) ));
            system.debug('No_GS_2******IngresoBruto: '+IngresoBruto);

            if ((Txndp > 0) && ((debitAmountTP * (debit/percent)) / Txndp > monetaryCeiling)) {
                IngresoBruto = IngresoBruto + Txndp * monetaryCeiling;
            }else {
                IngresoBruto = IngresoBruto + debitAmountTP * (debit/percent);
            }
            System.debug('Txndp > 0'+(Txnda > 0));
            System.debug('((debitAmountTP * (debit/percent)) / Txndp > monetaryCeiling)'+((debitAmountTP * (debit/percent)) ));
            system.debug('No_GS_3******IngresoBruto: '+IngresoBruto);

            if ((Txnda > 0) && ((debitAmount * (discountRates.debit/percent)) / Txnda > exchangeCap)) {
                exchangeFees = exchangeFees + Txnda * exchangeCap;
            }else {
                exchangeFees = exchangeFees + debitAmount * (discountRates.debit/percent);
            }
            System.debug('Txnda > 0'+(Txnda > 0));
            System.debug('((debitAmount * (discountRates.debit/percent)) / Txnda > exchangeCap))'+((debitAmount * (discountRates.debit/percent))  ));
            system.debug('No_GS_1******exchangeFees: '+exchangeFees);

            if ((Txndp > 0) && ((debitAmountTP * (discountRates.debit/percent))/Txndp > exchangeCap)) {
                exchangeFees = exchangeFees + Txndp * exchangeCap;
            }else {
                exchangeFees = exchangeFees + debitAmountTP * (discountRates.debit/percent);
            }
            System.debug('Txndp > 0'+(Txndp > 0));
            //System.debug('((debitAmountTP * (discountRates.debit/percent))/Txndp > exchangeCap)'+((debitAmountTP * (discountRates.debit/percent))/Txndp));
            system.debug('No_GS_2******exchangeFees: '+exchangeFees);
            exchangeFees = exchangeFees + ((facca + faccp) * (discountRates.credit))/percent + (facint * discountRates.international)/percent;
            System.debug('facca: '+facca);
            System.debug('faccp: '+faccp);
            System.debug('discountRates.credit: '+discountRates.credit);
            System.debug('facint: '+facint);
            System.debug('discountRates.international: '+discountRates.international);
            system.debug('No_GS_3******exchangeFees: '+exchangeFees);
        }
        exchangeFees = exchangeFees.abs();
        
        Decimal IngresoCliente = IngresoBruto + comisionBajaFact + comisionRedCelular + RentaTPVs;
        System.debug('IngresoBruto: '+IngresoBruto);
        System.debug('comisionBajaFact: '+comisionBajaFact);
        System.debug('comisionRedCelular: '+comisionRedCelular);
        System.debug('RentaTPVs: '+RentaTPVs);
        system.debug('******IngresoCliente: '+IngresoCliente);
        
        Decimal gastosCliente = 0;
        gastosCliente = exchangeFees + expensesTotalAmount + expensesMitAmount;
        
        System.debug('exchangeFees: '+exchangeFees);
        System.debug('expensesTotalAmount: '+expensesTotalAmount);
        System.debug('expensesMitAmount: '+expensesMitAmount);
        system.debug('******gastosCliente: '+gastosCliente);

        if(gastosCliente != 0){
            rentabilidad = (IngresoCliente/gastosCliente) - 1;
        }
        
        System.debug('IngresoCliente: '+IngresoCliente);
        System.debug('gastosCliente: '+gastosCliente);
        system.debug('******rentabilidad1: '+rentabilidad);

        if(rentabilidad < 0){
            rentabilidad = 0;
        }

        rentabilidad = rentabilidad*100;

        system.debug('******rentabilidad2: '+rentabilidad);

        rentabilidad = rentabilidad.setScale(2);
        
        retMap.put('profitability', rentabilidad);

        Decimal profitAmount = IngresoCliente - gastosCliente;
        profitAmount = profitAmount.setScale(2);
        system.debug('******profitAmount1: '+profitAmount);
        if(profitAmount < 0){
            profitAmount = 0;
        }
        System.debug('IngresoCliente: '+IngresoCliente);
        System.debug('gastosCliente: '+gastosCliente);
        system.debug('******profitAmount2: '+profitAmount);

        retMap.put('profitAmount', profitAmount);

        retMap.put('success', true);

        
        if (checkbox){
            dynamicPricing.CustomAcquiredFeesRent__c = rentabilidad;
            dynamicPricing.CustomAcquiredFeesBai__c = profitAmount;
        }
        update dynamicPricing;
        return retMap;
    }

    public class Discount_Rates_Wrapper {
        @AuraEnabled
        public Decimal credit {get; set;}
        @AuraEnabled
        public Decimal debit {get; set;}
        @AuraEnabled
        public Decimal international {get; set;}
    }
    public class Company_Info {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public Decimal credit {get; set;}
        @AuraEnabled
        public Decimal debit {get; set;}
        @AuraEnabled
        public Decimal international {get; set;}
    }

    /**
    * @description ??????????????????????
    * @param recordId : 
    * @return retMap ??????
    */
    public static List<String> setListFamilies () {
        List<String> razonSocialLst = new List<String>();
        razonSocialLst.add('AGENCIA DE VIAJES');
        razonSocialLst.add('AGREGADORES');
        razonSocialLst.add('ASEGURADORAS');
        razonSocialLst.add('BENEFICENCIA');
        razonSocialLst.add('COLEGIOS Y UNIVERSIDADES');
        razonSocialLst.add('COMIDA RÁPIDA');
        razonSocialLst.add('EDUCACIÓN BÁSICA');
        razonSocialLst.add('ESTACIONAMIENTO');
        razonSocialLst.add('ENTRETENIMIENTO');
        razonSocialLst.add('FARMACIAS');
        razonSocialLst.add('GASOLINERAS');
        razonSocialLst.add('GOBIERNO');
        razonSocialLst.add('GRANDES SUPERFICIES');
        razonSocialLst.add('GUARDERÍAS');
        razonSocialLst.add('HOSPITALES');
        razonSocialLst.add('HOTELES');
        razonSocialLst.add('MÉDICOS Y DENTISTAS');
        razonSocialLst.add('MISCELANEAS');
        razonSocialLst.add('OTROS');
        razonSocialLst.add('PEAJE');
        razonSocialLst.add('REFACCIONES Y FERRETERÍA');
        razonSocialLst.add('RENTA DE AUTOS');
        razonSocialLst.add('RESTAURANTES');
        razonSocialLst.add('SALONES DE BELLEZA');
        razonSocialLst.add('SUPERMERCADOS');
        razonSocialLst.add('TELECOMUNICACIONES');
        razonSocialLst.add('TRANSPORTE AÉREO');
        razonSocialLst.add('TRANSPORTE TERRESTRE DE PASAJEROS');
        razonSocialLst.add('VENTAS AL MENUDEO');
        return razonSocialLst;
    }

    /**
    * @description ??????????????????????
    * @param recordId : 
    * @return retMap ??????
    */
    public static Map<String, String> setListFamiliesId () {
        Map<String, String> razonSocialMp = new Map<String, String>();
        razonSocialMp.put('AGENCIA DE VIAJES','1');
        razonSocialMp.put('AGREGADORES','2');
        razonSocialMp.put('ASEGURADORAS','3');
        razonSocialMp.put('BENEFICENCIA','4');
        razonSocialMp.put('COLEGIOS Y UNIVERSIDADES','5');
        razonSocialMp.put('COMIDA RÁPIDA','6');
        razonSocialMp.put('EDUCACIÓN BÁSICA','7');
        razonSocialMp.put('ESTACIONAMIENTO','8');
        razonSocialMp.put('ENTRETENIMIENTO','9');
        razonSocialMp.put('FARMACIAS','10');
        razonSocialMp.put('GASOLINERAS','11');
        razonSocialMp.put('GOBIERNO','12');
        razonSocialMp.put('GRANDES SUPERFICIES','13');
        razonSocialMp.put('GUARDERÍAS','14');
        razonSocialMp.put('HOSPITALES','15');
        razonSocialMp.put('HOTELES','16');
        razonSocialMp.put('MÉDICOS Y DENTISTAS','17');
        razonSocialMp.put('MISCELANEAS','18');
        razonSocialMp.put('OTROS','19');
        razonSocialMp.put('PEAJE','20');
        razonSocialMp.put('REFACCIONES Y FERRETERÍA','21');
        razonSocialMp.put('RENTA DE AUTOS','22');
        razonSocialMp.put('RESTAURANTES','23');
        razonSocialMp.put('SALONES DE BELLEZA','24');
        razonSocialMp.put('SUPERMERCADOS','25');
        razonSocialMp.put('TELECOMUNICACIONES','26');
        razonSocialMp.put('TRANSPORTE AÉREO','27');
        razonSocialMp.put('TRANSPORTE TERRESTRE DE PASAJEROS','28');
        razonSocialMp.put('VENTAS AL MENUDEO','29');
        return razonSocialMp;
    }

    /**
    * @description retrieve Profitability Sheets related to the participant
    * @param dynamicPricingJSON : DPMX_Dynamic_Pricing__c data in JSON format
    * @return retMap
    */
    @AuraEnabled
    public static Map<String,Object> saveFamily (string recordId, String familia, String familiaId) {
        Map<String, Object> retMap = new Map<String, Object>();
        System.debug(recordId);
        System.debug(familia);
            System.debug(familiaId);
        DPMX_Dynamic_Pricing__c dynamicPricing = DPMX_Utils.dynamicPricingSelector(recordId);
            dynamicPricing.familia__c = familia;
            dynamicPricing.familia_AcquiererCategories_Id__c = familiaId;
            update dynamicPricing;
            retMap.put('dynamicPricingId', dynamicPricing.Id);
            retMap.put('success', true);
            return retMap;
    }

    /**
    * @description save JSON
    * @param dynamicPricingJSON : DPMX_Dynamic_Pricing__c data in JSON format
    * @return retMap
    */
    @AuraEnabled
    public static void updateDPMXJSON (string recordId, string serviceJSON, string service) {
        DPMX_Dynamic_Pricing__c dynamicPricing = DPMX_Utils.dynamicPricingSelector(recordId);
        System.debug(service);
        switch on service {
            when 'acqAct' {
                dynamicPricing.acquiererActy_JSON__c = serviceJSON;
            }
            when 'acqFees' {
                dynamicPricing.acquirerFees_JSON__c = serviceJSON;
            }
            when 'corpRates' {
                dynamicPricing.corporateRates_JSON__c = serviceJSON;
            }
            when 'validate' {
                dynamicPricing.validate_JSON__c = serviceJSON;
            }
        }
        
        update dynamicPricing;
    }

    /**
    * @description save JSON
    * @param dynamicPricingJSON : DPMX_Dynamic_Pricing__c data for send report
    * @return retMap
    */
    @AuraEnabled
    public static Map<String,Object> updateInfoToSendReport (string recordId, Boolean isLastMonthTab, Boolean isSimulationTab, string result, decimal debitLastMonth, decimal CreditLastMonth, decimal IntLastMonth, decimal rentLastMonth, decimal baiLastMonth, string resultSim, decimal debitSim, decimal creditSim, decimal interSim, decimal rentSim, decimal baiSim) {
        Map<String, Object> retMap = new Map<String, Object>();
        boolean isBreakEvenAccepted = false;
        boolean isBreakEvenSimAccepted = false;
        DPMX_Dynamic_Pricing__c dynamicPricing = DPMX_Utils.dynamicPricingSelector(recordId);

        dynamicPricing.isLastMonthTab__c = isLastMonthTab;
        dynamicPricing.isSimulationTab__c = isSimulationTab;

        dynamicPricing.resultLastMonth__c = result;
        dynamicPricing.debitLastMonth__c = debitLastMonth;
        dynamicPricing.CreditLastMonth__c = CreditLastMonth;
        dynamicPricing.IntLastMonth__c = IntLastMonth;
        dynamicPricing.baiLastMonth__c = baiLastMonth;
        dynamicPricing.RentabildiadLastMonth__c = rentLastMonth;

        dynamicPricing.resultSim__c = resultSim;
        dynamicPricing.debitSim__c = debitSim;
        dynamicPricing.creditSim__c = creditSim;
        dynamicPricing.interSim__c = interSim;
        dynamicPricing.baiSim__c = baiSim;
        dynamicPricing.RentabildiadSim__c = rentSim;
        
        update dynamicPricing;


        if(result != null  && (result == 'BREAK_EVEN' || result == 'Break even' || result == 'Minimo viable')){
            isBreakEvenAccepted = DPMX_Utils.returnAuthIsAccepted(recordId, debitLastMonth+'', CreditLastMonth+'', IntLastMonth+'');
        }
        if(resultSim != null  && (resultSim == 'BREAK_EVEN' || resultSim == 'Break even' || resultSim == 'Minimo viable')){
            isBreakEvenSimAccepted = DPMX_Utils.returnAuthIsAccepted(recordId, debitSim+'', creditSim+'', interSim+'');
        }

        retMap.put('isBreakEvenAccepted',isBreakEvenAccepted);
        retMap.put('isBreakEvenSimAccepted',isBreakEvenSimAccepted);

        return retMap;
        
    }

    /**
    * @description save JSON
    * @param dynamicPricingJSON : DPMX_Dynamic_Pricing__c data for send report
    * @return retMap
    */
    @AuraEnabled
    public static Map<String,Object> callstatusFee (string recordId, string folioId, string customerId, string familia) {
        Map<String, Object> retMap = new Map<String, Object>();        
        Map<String,String> jsonInputMap = new Map<String,String>();
        jsonInputMap.put('customerId', customerId);
        jsonInputMap.put('familia', familia);
        try{
            HttpResponse response = DPMX_Utils.callWebService('DPMX_StatusFee', jsonInputMap);
            System.debug(response);
            String responseReplace0;
            if(Test.isRunningTest()){
                responseReplace0 = '';
            }else {
                responseReplace0 = response.getBody().replaceAll('"currency":','"currency_y":');
            }
            String responseReplace = responseReplace0.replaceAll('"id":','"id_y":');
            final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
            final List<DPMX_StatusFee_Wrapper> statusFeeWrapperLst = (List<DPMX_StatusFee_Wrapper>) Json.deserialize(JSON.serialize(responseMap.get('data')), List<DPMX_StatusFee_Wrapper>.class);
            DPMX_StatusFee_Wrapper statusFeeWrapper = statusFeeWrapperLst[0];
            System.debug(statusFeeWrapper);
            retMap.put('success', 'Se ha actualizado la tasa');
            retMap.put('status', response.getStatusCode()+' - '+response.getStatus());
        }catch(Exception ex){
            retMap.put('error', 'json no creado');
        }
        return retMap;
    }

    /**
    * @description create fomrlize object
    * @param recordId : Dynamic Pricing Id
    * @return retMap
    */    
    @AuraEnabled
    public static Map<String,Object> callValidate(string recordId, DPMX_AcquirerActivities_Wrapper acquirerActivitiesWrapper, Discount_Rates_Wrapper discountRates, Boolean checkbox, string customerId){
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_Dynamic_Pricing__c dynamicPricing = DPMX_Utils.dynamicPricingSelector(recordId);
        Map<String,String> jsonInputMap = new Map<String,String>();
        DPMX_Validate_Wrapper validate = new DPMX_Validate_Wrapper();
        DPMX_Validate_Wrapper.Device device = new DPMX_Validate_Wrapper.Device();
        DPMX_Validate_Wrapper.PinPads pinPad = new DPMX_Validate_Wrapper.PinPads();
        List<DPMX_Validate_Wrapper.InvoicingAmounts> invAmountLst = new List<DPMX_Validate_Wrapper.InvoicingAmounts>();
        DPMX_Validate_Wrapper.InvoicingAmounts invAmount = new DPMX_Validate_Wrapper.InvoicingAmounts();
        DPMX_Validate_Wrapper.Amount amount = new DPMX_Validate_Wrapper.Amount();
        List<DPMX_Validate_Wrapper.SpecificAmounts> spAmountLst = new List<DPMX_Validate_Wrapper.SpecificAmounts>();
        DPMX_Validate_Wrapper.SpecificAmounts spAmount = new DPMX_Validate_Wrapper.SpecificAmounts();
        user us = DPMX_Utils.userSelector(UserInfo.getUserId());

        double debitInfoCliente = 0;
        double creditInfoCliente = 0;
        double internationalInfoCliente = 0;

        invAmount.id = 'THIRDPARTY_DEBIT';
        if(dynamicPricing.Sim_Transaction_Debit_Own__c != 0 && dynamicPricing.Sim_Transaction_Debit_Own__c != null){
            debitInfoCliente = (dynamicPricing.Sim_Transaction_Debit_Own__c/2).round(System.RoundingMode.HALF_UP);
        }
        invAmount.transactionsNumber = debitInfoCliente;
        amount.amount = (dynamicPricing.Sim_Billing_Debit_Own_Amount__c/2).round(System.RoundingMode.HALF_UP);
        amount.currency_y = 'MXN';
        invAmount.amount = amount;
        invAmountLst.add(invAmount);
        invAmount = new DPMX_Validate_Wrapper.InvoicingAmounts();
        invAmount.id = 'OWN_DEBIT';
        invAmount.transactionsNumber = debitInfoCliente;
        invAmount.amount = amount;
        invAmountLst.add(invAmount);

        amount = new DPMX_Validate_Wrapper.Amount();
        invAmount = new DPMX_Validate_Wrapper.InvoicingAmounts();
        invAmount.id = 'THIRDPARTY_CREDIT';
        if(dynamicPricing.Sim_Transaction_Credit_Own__c != 0 && dynamicPricing.Sim_Transaction_Credit_Own__c != null){
            creditInfoCliente = (dynamicPricing.Sim_Transaction_Credit_Own__c/2).round(System.RoundingMode.HALF_UP);
        }
        invAmount.transactionsNumber = creditInfoCliente;
        amount.amount = (dynamicPricing.Sim_Billing_Credit_Own_Amount__c/2).round(System.RoundingMode.HALF_UP);
        amount.currency_y = 'MXN';
        invAmount.amount = amount;
        invAmountLst.add(invAmount);
        invAmount = new DPMX_Validate_Wrapper.InvoicingAmounts();
        invAmount.id = 'OWN_CREDIT';
        invAmount.transactionsNumber = creditInfoCliente;
        invAmount.amount = amount;
        invAmountLst.add(invAmount);

        amount = new DPMX_Validate_Wrapper.Amount();
        invAmount = new DPMX_Validate_Wrapper.InvoicingAmounts();
        invAmount.id = 'INTERNATIONAL';
        if(dynamicPricing.Sim_Transaction_International__c != 0 && dynamicPricing.Sim_Transaction_International__c != null){
            internationalInfoCliente = dynamicPricing.Sim_Transaction_International__c;
        }
        invAmount.transactionsNumber = internationalInfoCliente;
        amount.amount = dynamicPricing.Sim_Billing_International_Amount__c;
        amount.currency_y = 'MXN';
        invAmount.amount = amount;
        invAmountLst.add(invAmount);

        if(dynamicPricing.pinPadsInfo_withoutPinPads__c != 0){
            pinPad.totalPinPads = dynamicPricing.pinPadsInfo_withoutPinPads__c;
        }else if(dynamicPricing.Sim_PinPadsInfo_PinPads__c != 0){
            pinPad.totalPinPads = dynamicPricing.Sim_PinPadsInfo_PinPads__c;
        }else {
            pinPad.totalPinPads = 0;
        }

        if(dynamicPricing.Sim_Fees_ExtraBilling_Checkbox__c){
            if (dynamicPricing.Sim_Terminal_Id__c > 0) {
                device.pointOfSales = dynamicPricing.Sim_Terminal_Id__c;
            } else {
                device.pointOfSales = 0;
            }
        }else {
            device.pointOfSales = 0;
        }
        
        device.pinPads = pinPad;


        amount = new DPMX_Validate_Wrapper.Amount();
        amount.amount = 0;
        amount.currency_y = 'MXN';
        spAmount.id = 'COMMISSIONS';
        spAmount.amount = amount;
        spAmountLst.add(spAmount);
        spAmount = new DPMX_Validate_Wrapper.SpecificAmounts();
        amount = new DPMX_Validate_Wrapper.Amount();
        amount.amount = 0;
        amount.currency_y = 'MXN';
        spAmount.id = 'DISCOUNT';
        spAmount.amount = amount;
        spAmountLst.add(spAmount);
        spAmount = new DPMX_Validate_Wrapper.SpecificAmounts();
        amount = new DPMX_Validate_Wrapper.Amount();
        //Ultimo mes de cliente
        amount.amount = 0;
        amount.currency_y = 'MXN';
        spAmount.id = 'ACTUALEXPENSES';
        spAmount.amount = amount;
        spAmountLst.add(spAmount);

        //Iscustom - isModel == 0
        validate.isModel = 0;
        //Familia
        validate.categoryId = dynamicPricing.familia_AcquiererCategories_Id__c;
        validate.specificAmounts = spAmountLst;
        validate.invoicingAmounts = invAmountLst;
        validate.device = device;

        String validateJson = JSON.serialize(validate);
        validateJson = validateJson.replace('currency_y', 'currency');
        jsonInputMap.put('customerId', us.ID_User__c);
        jsonInputMap.put('validateJson', validateJson);
        HttpResponse response = DPMX_Utils.callWebService('DPMX_Validate', jsonInputMap);
        String responseReplace = '';

        if(Test.isRunningTest()){
            responseReplace = '{ "categoryId": "8", "isModel": 1, "device": { "pointOfSales": 10, "pinPads": { "totalPinPads": 10 } }, "invoicingAmounts": [ { "id": "THIRDPARTY_DEBIT", "amount": { "amount": 10000, "currency": "MXN" }, "transactionsNumber": 500000 }, { "id": "OWN_DEBIT", "amount": { "amount": 10000, "currency": "MXN" }, "transactionsNumber": 500000 }, { "id": "THIRDPARTY_CREDIT", "amount": { "amount": 10000, "currency": "MXN" }, "transactionsNumber": 500000 }, { "id": "OWN_CREDIT", "amount": { "amount": 10000, "currency": "MXN" }, "transactionsNumber": 500000 }, { "id": "INTERNATIONAL", "amount": { "amount": 500, "currency": "MXN" }, "transactionsNumber": 2000000 } ], "specificAmounts": [ { "id": "COMMISSIONS", "amount": { "amount": 1500, "currency": "MXN" } }, { "id": "DISCOUNT", "amount": { "amount": 18, "currency": "MXN" } }, { "id": "ACTUALEXPENSES", "amount": { "amount": 1500, "currency": "MXN" } } ] }';
            responseReplace = responseReplace.replaceAll('"currency":','"currency_y":');
        }else {
            responseReplace = response.getBody().replaceAll('"currency":','"currency_y":');
        }

        System.debug(responseReplace);

        switch on response.getStatusCode() {
            when 200, 201 {
                responseReplace = response.getBody().replaceAll('"currency":','"currency_y":');
                updateDPMXJSON(recordId, responseReplace, 'validate');
                final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                DPMX_ValidateResponse_Wrapper validateResponseWrapper = (DPMX_ValidateResponse_Wrapper) Json.deserialize(JSON.serialize(responseMap.get('data')), DPMX_ValidateResponse_Wrapper.class);
                DPMX_ValidateResponse_Wrapper validateResponse = validateResponseWrapper;
                List<DPMX_ValidateResponse_Wrapper.itemizeRates> itemLst = new DPMX_ValidateResponse_Wrapper.itemizeRates[4];
                List<DPMX_ValidateResponse_Wrapper.itemizeRates> itemLstRst = new DPMX_ValidateResponse_Wrapper.itemizeRates[4];
                integer i = 0;
                integer z = 0;
                integer q = 0;
                integer orderIdProp = 0;
                integer orderIdItem = 0;
                boolean goodScenarioExist = false;
                boolean goodTwoScenarioExist = false;
                boolean optimalScenarioExist = false;
                dynamicPricing.gastoTotal__c = validateResponseWrapper.proposed[0].amount.amount;
                Map<String,Object> baiMAP = new Map<String,Object>();
                decimal debit = 0;
                decimal credit = 0;
                decimal international = 0;
                DPMX_ValidateResponse_Wrapper.Amount amountResponse = new DPMX_ValidateResponse_Wrapper.Amount();

                for(i = 0; i != validateResponseWrapper.proposed.size(); i++){
                    if(validateResponseWrapper.proposed[i].scenaryType == 'BREAK_EVEN'){
                        validateResponseWrapper.proposed[i].idOrder = 0;
                        validateResponse.proposed.set(0, validateResponseWrapper.proposed[i]);
                    }else if(validateResponseWrapper.proposed[i].scenaryType == 'GOOD'){
                        if(goodScenarioExist){
                            validateResponseWrapper.proposed[i].idOrder = 2;
                            validateResponse.proposed.set(2, validateResponseWrapper.proposed[i]);
                            goodTwoScenarioExist = true;
                        }else {
                            validateResponseWrapper.proposed[i].idOrder = 1;
                            validateResponse.proposed.set(1, validateResponseWrapper.proposed[i]);
                            goodScenarioExist = true;
                        }
                    }
                    for(z = 0; z != validateResponseWrapper.proposed[i].rate.itemizeRates.size(); z++){
                        if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'DEBIT_DISCOUNT'){
                            if(dynamicPricing.familia_AcquiererCategories_Id__c == '13'){
                                debit = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.amount;
                            }else{
                                debit = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            }
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'CREDIT_DISCOUNT'){
                            credit = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'INTERNATIONAL_DISCOUNT'){
                            international = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                        }
                        if(debit != null && debit != 0 && credit != null && credit != 0 && international != null && international != 0){
                            baiMAP = DPMX_Container_Ctrl.updateRates(recordId, acquirerActivitiesWrapper, discountRates, false, credit, debit, international, true, dynamicPricing.gastoTotal__c);
                            amountResponse.amount = (decimal) baiMAP.get('profitAmount');
                            amountResponse.currency_y = 'MXN';
                            validateResponseWrapper.proposed[i].amount = amountResponse;
                            System.debug((decimal) baiMAP.get('profitability'));
                            for(q = 0; q != validateResponseWrapper.proposed[i].rate.itemizeRates.size(); q++){
                                if(validateResponseWrapper.proposed[i].rate.itemizeRates[q].rateType == 'RETURN'){
                                    validateResponseWrapper.proposed[i].rate.itemizeRates[q].itemizeRatesUnit.percentage = (decimal) baiMAP.get('profitability');
                                }
                            }
                        }
                        if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'DEBIT_DISCOUNT'){
                            debit = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 0;
                            itemLst.set(0, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'CREDIT_DISCOUNT'){
                            credit = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 1;
                            itemLst.set(1, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'INTERNATIONAL_DISCOUNT'){
                            international = validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage;
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 2;
                            itemLst.set(2, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }else if(validateResponseWrapper.proposed[i].rate.itemizeRates[z].rateType == 'RETURN'){
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].idOrder = 3;
                            System.debug((decimal) baiMAP.get('profitability'));
                            validateResponseWrapper.proposed[i].rate.itemizeRates[z].itemizeRatesUnit.percentage = (decimal) baiMAP.get('profitability');
                            itemLst.set(3, validateResponseWrapper.proposed[i].rate.itemizeRates[z]);
                        }
                    }

                    validateResponse.proposed[i].rate.itemizeRates = itemLst;
                    itemLst = new DPMX_ValidateResponse_Wrapper.itemizeRates[4];
                    debit = 0;
                    credit = 0;
                    international = 0;
                    baiMAP.clear();
                    amountResponse = new DPMX_ValidateResponse_Wrapper.Amount();
                }

                for(i = 0; i != validateResponseWrapper.proposed.size(); i++){
                    if(validateResponseWrapper.proposed[i].scenaryType == 'OPTIMAL'){
                        if(optimalScenarioExist){
                            if(goodTwoScenarioExist){
                                validateResponseWrapper.proposed[i].idOrder = 4;
                                validateResponse.proposed.set(4, validateResponseWrapper.proposed[i]);
                            }else {
                                validateResponseWrapper.proposed[i].idOrder = 3;
                                validateResponse.proposed.set(3, validateResponseWrapper.proposed[i]);
                            }
                            
                        }else {
                            if(goodTwoScenarioExist){
                                validateResponseWrapper.proposed[i].idOrder = 3;
                                validateResponse.proposed.set(3, validateResponseWrapper.proposed[i]);
                            }else {
                                validateResponseWrapper.proposed[i].idOrder = 2;
                                validateResponse.proposed.set(2, validateResponseWrapper.proposed[i]);
                            }
                            optimalScenarioExist = true; 
                        }
                    }
                }
                update dynamicPricing;
                retMap.put('validateResponseWrapper', validateResponse);
                retMap.put('rates', validateResponse);
                retMap.put('dynamicPricing', dynamicPricing);
                retMap.put('validateResponse', true);
                retMap.put('success', true);
            }
            when else {
                retMap.put('validateResponse', false);
                retMap.put('success', false);
            }
        }

        return retMap;
    }

    /**
    * @description ??????????????????????
    * @param recordId : 
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> callGetStatusService (String recordId, String customerId, String acquirerId, integer pageKey) {
        Map<String, Object> retMap = new Map<String, Object>(); 
        Map<String,String> jsonInputMap = new Map<String,String>();
        System.debug('getStatus');
        jsonInputMap.put('acquirerId', acquirerId);
        DPMX_Dynamic_Pricing__c dynamicPricing =DPMX_Utils.dynamicPricingSelector(recordId);
        user us = DPMX_Utils.userSelector(dynamicPricing.LastModifiedById);
        

        DPMX_getStatusFee_Wrapper getStatus = new DPMX_getStatusFee_Wrapper();
        getStatus.customerId = customerId;
        //getStatus.userAuthorized = us.ID_User__c;
        getStatus.pageSize = 10;
        System.debug(pageKey);
        getStatus.paginationKey = pageKey;
        

        String getStatusJson = JSON.serialize(getStatus);
        jsonInputMap.put('GetStatusJson', getStatusJson);
        HttpResponse response = DPMX_Utils.callWebService('DPMX_GetStatus', jsonInputMap);

        System.debug('--- '+response.getStatusCode());
        System.debug(response);
        retMap.put('statusCode', response.getStatusCode());
        switch on response.getStatusCode() {
            when 200 {
                String responseReplace = '';
                if(Test.isRunningTest()){
					responseReplace = '{"data":[{"folio":"247242910","category":{"description":"Ventas_al_menudeo","businessInformation":{"companyName":"GLOBARCO SA DE CV","groupName":"JUMEX"}},"itemizeRates":[{"codeStatus":"PENDIENTE","rateType":"DESCUENTODEBITO","fee":{"unitType":"PERCENTAGE","percentage":1.4}},{"codeStatus":"PENDIENTE","rateType":"CREDITOINTERNACIONAL","fee":{"unitType":"PERCENTAGE","percentage":3.2}}],"businessPeople":{"businessAgent":{"id":"3"},"businessAuthorizes":{"id":"MB80078"}},"updateRates":{"startDate":"2024-07-24","expirationDate":"9999-12-31","modifyDate":"2024-07-24"}},{"folio":"247242909","category":{"description":"Ventas_al_menudeo","businessInformation":{"companyName":"GLOBARCO SA DE CV","groupName":"JUMEX"}},"itemizeRates":[{"codeStatus":"PENDIENTE","rateType":"DESCUENTODEBITO","fee":{"unitType":"PERCENTAGE","percentage":1.4}}],"businessPeople":{"businessAgent":{"id":"2"},"businessAuthorizes":{"id":"MB80078"}},"updateRates":{"startDate":"2024-07-24","expirationDate":"9999-12-31","modifyDate":"2024-07-24"}},{"folio":"247242901","category":{"description":"Ventas_al_menudeo","businessInformation":{"companyName":"GLOBARCO SA DE CV","groupName":"JUMEX"}},"itemizeRates":[{"codeStatus":"PENDIENTE","rateType":"DESCUENTODEBITO","fee":{"unitType":"PERCENTAGE","percentage":1.4}},{"codeStatus":"PENDIENTE","rateType":"CREDITONACIONAL","fee":{"unitType":"PERCENTAGE","percentage":2.0}},{"codeStatus":"PENDIENTE","rateType":"CREDITOINTERNACIONAL","fee":{"unitType":"PERCENTAGE","percentage":3.2}}],"businessPeople":{"businessAgent":{"id":"1"},"businessAuthorizes":{"id":"MB80078"}},"updateRates":{"startDate":"2024-07-24","expirationDate":"9999-12-31","modifyDate":"2024-07-24"}}],"pagination":{"links":{"first":"/stores/v2/acquirer-categories/29/requests-status-fee","last":"/stores/v2/acquirer-categories/29/requests-status-fee?paginationKey=1","previous":"/stores/v2/acquirer-categories/29/requests-status-fee?paginationKey=1&pageSize=10","next":"/stores/v2/acquirer-categories/29/requests-status-fee?paginationKey=1&pageSize=10"},"page":1,"totalPages":1,"totalElements":3,"pageSize":10}}';
                    responseReplace = responseReplace.replaceAll('"currency":','"currency_y":');
                }else {
                    responseReplace = response.getBody().replaceAll('"currency":','"currency_y":');
                }
                System.debug(responseReplace);
                final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                System.debug(responseMap.get('data'));
                DPMX_getStatusFeeResponse_Wrapper getStatusResponseWrapper = (DPMX_getStatusFeeResponse_Wrapper) Json.deserialize(JSON.serialize(responseMap), DPMX_getStatusFeeResponse_Wrapper.class);

                System.debug(getStatusResponseWrapper.pagination.totalElements);
                System.debug(getStatusResponseWrapper.pagination.totalPages);
                System.debug(getStatusResponseWrapper.pagination.pageSize);
                
                integer index = 0;
                List<DPMX_getStatusFeeResponse_Wrapper.data> getStatusResponseDataWrapperLst = getStatusResponseWrapper.data;

                List<DPMX_UpdtRatesxDynPric__c> permissionSetAssignmentLstbk = new List<DPMX_UpdtRatesxDynPric__c>();
                for(DPMX_getStatusFeeResponse_Wrapper.data  getStatusResponseDataWrapper : getStatusResponseDataWrapperLst){
                    System.debug(recordId+' - '+getStatusResponseDataWrapper.folio);
                    List<DPMX_UpdtRatesxDynPric__c> permissionSetAssignmentLst = DPMX_Utils.DPMX_UpdtRatesxAllDynPricSelector(getStatusResponseDataWrapper.folio);
                    System.debug(permissionSetAssignmentLst);
                    if(!permissionSetAssignmentLst.isEmpty()){
                        permissionSetAssignmentLstbk = permissionSetAssignmentLst;
                        dynamicPricing.folioGetStatus__c = getStatusResponseDataWrapper.folio;
                        getStatusResponseWrapper.data.get(index).updateRates.initDateFormalize = permissionSetAssignmentLst.get(0).CreatedDate.format('yyyy-MM-dd');
                        getStatusResponseWrapper.data.get(index).updateRates.startDate = permissionSetAssignmentLst.get(0).initDateFormalize__c;
                        getStatusResponseWrapper.data.get(index).updateRates.revisionDateFormalize = permissionSetAssignmentLst.get(0).revisionDateFormalize__c;
                    }else if(!permissionSetAssignmentLstbk.isEmpty()){
                        getStatusResponseWrapper.data.get(index).updateRates.initDateFormalize = permissionSetAssignmentLstbk.get(0).CreatedDate.format('yyyy-MM-dd');
                        getStatusResponseWrapper.data.get(index).updateRates.startDate = permissionSetAssignmentLstbk.get(0).initDateFormalize__c;
                        getStatusResponseWrapper.data.get(index).updateRates.revisionDateFormalize = permissionSetAssignmentLstbk.get(0).revisionDateFormalize__c;
                    }else if(dynamicPricing.folioGetStatus__c != null){
                        permissionSetAssignmentLst = DPMX_Utils.DPMX_UpdtRatesxAllDynPricSelector(dynamicPricing.folioGetStatus__c);
                        permissionSetAssignmentLstbk = permissionSetAssignmentLst;
                        getStatusResponseWrapper.data.get(index).updateRates.initDateFormalize = permissionSetAssignmentLstbk.get(0).CreatedDate.format('yyyy-MM-dd');
                        getStatusResponseWrapper.data.get(index).updateRates.startDate = permissionSetAssignmentLstbk.get(0).initDateFormalize__c;
                        getStatusResponseWrapper.data.get(index).updateRates.revisionDateFormalize = permissionSetAssignmentLstbk.get(0).revisionDateFormalize__c;
                        
                    }
                    index++;
                }

                update dynamicPricing;
                retMap.put('getStatus',getStatusResponseWrapper);

                retMap.put('success', true);
                System.debug('200');
            }
            when else {
                System.debug('400');
                retMap.put('success', false);
            }
        }
        return retMap;
    }

    /**
    * @description ??????????????????????
    * @param recordId : 
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> updatemessageBreakEven (String recordId, boolean isbreakEvenOutOfLimits) {
        Map<String, Object> retMap = new Map<String, Object>(); 
        DPMX_Dynamic_Pricing__c dynamicPricing = DPMX_Utils.dynamicPricingSelector(recordId);
        dynamicPricing.rateBreakEvenOutLimits__c = isbreakEvenOutOfLimits;
        update dynamicPricing;

        retMap.put('dpmx', dynamicPricing);

        return retMap;
    }

    /**
    * @description ??????????????????????
    * @param recordId : 
    * @return retMap ??????
    */
    public static DPMX_AcquirerActivitiesFees_Wrapper calculatedBaiRentForFees (String responseReplace, string recordId, DPMX_AcquirerActivities_Wrapper acquirerActivitiesWrapper, Discount_Rates_Wrapper discountRates) {
        Map<String, Object> retMapUpRa = new Map<String, Object>(); 
        decimal debit = 0;
        decimal credit = 0;
        decimal international = 0;

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
        DPMX_AcquirerActivitiesFees_Wrapper acquirerFeesWrapper = (DPMX_AcquirerActivitiesFees_Wrapper) Json.deserialize(JSON.serialize(responseMap.get('data')), DPMX_AcquirerActivitiesFees_Wrapper.class);
        DPMX_AcquirerActivitiesFees_Wrapper acquirerFeesWrapperToSend = (DPMX_AcquirerActivitiesFees_Wrapper) Json.deserialize(JSON.serialize(responseMap.get('data')), DPMX_AcquirerActivitiesFees_Wrapper.class);
        List<DPMX_AcquirerActivitiesFees_Wrapper.Scenario> AcqFeScenLst = new List<DPMX_AcquirerActivitiesFees_Wrapper.Scenario>();
        DPMX_AcquirerActivitiesFees_Wrapper.Scenario scn = new DPMX_AcquirerActivitiesFees_Wrapper.Scenario();

        for(DPMX_AcquirerActivitiesFees_Wrapper.Scenario scena : acquirerFeesWrapper.scenarios){
            scn = scena;
            for(DPMX_AcquirerActivitiesFees_Wrapper.ItemizeFees itemFees : scena.fees.itemizeFees){
                if(itemFees.feeType == 'DEBIT'){
                    if(acquirerActivitiesWrapper.isGS){
                        debit = itemFees.itemizeFeeUnit.amount;
                    }else{
                        debit = itemFees.itemizeFeeUnit.value;
                    }
                }else if(itemFees.feeType == 'CREDIT'){
                    credit = itemFees.itemizeFeeUnit.value;
                }else if(itemFees.feeType == 'INTERNATIONAL'){
                    international = itemFees.itemizeFeeUnit.value;
                }
            }
            retMapUpRa = DPMX_Container_Ctrl.updateRates(recordId, acquirerActivitiesWrapper, discountRates, false, credit, debit, international, false, acquirerActivitiesWrapper.expenses.totalAmount.amount);
            scn.fees.profitability.percentage = (Decimal) retMapUpRa.get('profitability');
            scn.fees.profitability.amount.amount = (Decimal) retMapUpRa.get('profitAmount');
            AcqFeScenLst.add(scn);
            scn = new DPMX_AcquirerActivitiesFees_Wrapper.Scenario();
        }
        
        acquirerFeesWrapperToSend.scenarios = AcqFeScenLst;
        
        return acquirerFeesWrapperToSend;
    }
    
    /**
    * @description ??????????????????????
    * @param recordId : 
    * @return retMap ??????
    */
    public static Boolean checkrateBreakEvenOutLimits (string recordId, DPMX_AcquirerActivities_Wrapper acquirerActivitiesWrapper, Discount_Rates_Wrapper discountRates, List<DPMX_AcquirerActivitiesFees_Wrapper.ItemizeFees> lstScenearios){
        Boolean isbreakEvenOutOfLimits = false;
        Decimal breakEvenDebit = 0;
        Decimal breakEvenCredit = 0;
        Decimal breakEvenInt = 0;

        for (integer x = 0; x < lstScenearios.size(); x++) {
            if (lstScenearios[x].feeType == 'DEBIT') {
                if (acquirerActivitiesWrapper.isGS) {
                    breakEvenDebit = lstScenearios[x].itemizeFeeUnit.amount;
                } else {
                breakEvenDebit = lstScenearios[x].itemizeFeeUnit.value;
                }
            } else if (lstScenearios[x].feeType == 'CREDIT') {
                breakEvenCredit = lstScenearios[x].itemizeFeeUnit.value;
            } else if (lstScenearios[x].feeType == 'INTERNATIONAL') {
                breakEvenInt = lstScenearios[x].itemizeFeeUnit.value;
            }
        }

        isbreakEvenOutOfLimits = discountRates.debit > breakEvenDebit.setScale(2);

        if (!isbreakEvenOutOfLimits) {
            isbreakEvenOutOfLimits = discountRates.credit > breakEvenCredit.setScale(2);
        }

        if (!isbreakEvenOutOfLimits) {
            isbreakEvenOutOfLimits = discountRates.international > breakEvenInt.setScale(2);
        }

        return isbreakEvenOutOfLimits;

    }
}