/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Bureau_Main_Banks_Per_service
* @Author   Manuel Hugo Castillo Chavarria
* @Date     Created: 01/11/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages save for Banking Relationship
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-11-01 Manuel Hugo Castillo Chavarria manuelhugo.castillo.contractor@bbva.com
*             Class creation.
* |2020-11-12 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-02-25 juanmanuel.perez.ortiz.contractor@bbva.com
*             Modified field reference arce__stage_collective_type__c -> arce__stage_collective_ind_type__c
* |2021-05-24 juanignacio.hita.contractor@bbva.com
*             Added check for get permission of various type of object
* |2021-09-01 juanignacio.hita.contractor@bbva.com
*             Skip call to allocation package if running in tests
* |2022-06-06 juanignacio.hita.contractor@bbva.com
*             Add checkChangesQualQuestion validation
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton, sf:TooManyMethods,PMD.AvoidGlobalModifier,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PDM.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.CyclomaticComplexity,PMD.UnusedLocalVariable,sf:DUDataflowAnomalyAnalysis')
global class Arc_Gen_Bureau_Main_Banks_Per_service implements dyfr.Save_Interface {
    /**
    * @Description: String with value "Group"
    */
    static final string S_GROUP = 'GROUP';
    /**
    * @Description: String with value "Client"
    */
    static final string CLIENT = 'SUBSIDIARY';
    /**
    * @Description: String with value "comments"
    */
    static final string S_COMMENTS = 'comments';
    /**
    * @Description: String with value "amount"
    */
    static final string S_AMOUNT = 'amount';
    /**
    * @Description: String with value "currency"
    */
    static final string S_CURRENCY = 'currency';
    /**
    * @Description: String with value "description"
    */
    static final string S_DESCRIPTION = 'description';
    /**
    * @Description: String with value "participantType"
    */
    static final String S_PART_TYPE = 'participantType';
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for invoking the classes to save the banking relationship information
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param listObject - List of the account has analisys object
    * @return String with the execution message
    * @example save (listObject)
    * -----------------------------------------------------------------------------------------------
    **/
    public static String save(List<sObject> listObject) {
        Boolean hasPermission = Arc_Gen_TabSet_service.hasPermissionToEdit(listObject);
        String retValue;
        if (hasPermission) {
            String accHasId;
            for(sObject obj : listObject) {
              final String idAnalisis = obj.get('Id').toString();
              if (Id.valueOf(idAnalisis).getSobjectType() == arce__Account_has_Analysis__c.SObjectType) {
                  accHasId = idAnalisis;
                  break;
              }
            }
            final arce__Account_has_Analysis__c ahaData = Arc_Gen_Persistence_Utils.getAhaFromSobject(listObject);
            final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaData.Id})[0];
            Arc_Gen_FieldConfig_Data.checkChangesQualQuestion(ahaData, accHasAnalysis, String.valueOf(Arc_Gen_Bureau_Main_Banks_Per_service.class.getName()));
            if (Arc_Gen_Auto_ExpTable_Service_Helper.hasManualTablePerm(accHasId)) {
                retValue = JSON.serialize(new arce.Arc_Gen_wrpSave(true,'',listObject));
            } else {
                Map<String, Object> bureauMBMap = new Map<String, Object>();
                final Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccount = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<String>{accHasAnalysis.arce__Customer__c});
                final String participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient(mapAccount.get(accHasAnalysis.arce__Customer__c).accNumber);
                bureauMBMap = bureauMBInfoJSON(ahaData, accHasAnalysis,participantId,mapAccount);
                final boolean bankingRInfo = Arc_Gen_OraclePers_service.bankingRelationshipWS(participantId, accHasAnalysis.Name, bureauMBMap);
                retValue = JSON.serialize(new arce.Arc_Gen_wrpSave(bankingRInfo,'',listObject));
            }
        } else {
            retValue = JSON.serialize(new arce.Arc_Gen_wrpSave(false, Label.Arc_Gen_Generic_NotAllowed, listObject));
        }
        return retValue;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates JSON for bureau & main banks WS
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @param arce__Account_has_Analysis__c - prevAha - Object from query
    * @param Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccount - Account wrapper related to aha
    * @return Map<String, Object> with WS structure for bureau & main banks WS
    * @example bureauMBInfoJSON (ahaData, prevAha, participantId, mapAccount)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> bureauMBInfoJSON (arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, String participantId,Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccount) {
        Map<String, Object> finalWSMap = new Map<String, Object>();
        final Map<String, Object> riskPosition = addRiskPosition(ahaData, prevAha, participantId, mapAccount);
        final Map<String, Object> bankingPool = addBankingPool(ahaData, prevAha, participantId, mapAccount);
        finalWSMap = Arc_Gen_Persistence_Utils.addifFilled(finalWSMap,'riskPosition',riskPosition);
        finalWSMap.put('bankingPool', bankingPool);
        return finalWSMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating risk position Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @param arce__Account_has_Analysis__c - prevAha - Object from query
    * @param Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccount - Account wrapper related to aha
    * @return Map<String, Object> with WS structure for bureau & main banks WS
    * @example addRiskPosition(ahaData, prevAha, participantId, mapAccount)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addRiskPosition(arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, String participantId, Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccount) {
        final Map<String, Object> riskPositionMap =  new Map<String, Object>();
        List<Map<String, Object>> listBankingEGP =  new List<Map<String, Object>>();
        riskPositionMap.put('hasSummaryComments', Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get('arce__risk_position_summary_type__c')));
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__risk_position_summary_desc__c'))) {
            //riskPositionMap.put(S_COMMENTS, ahaData.get('arce__risk_position_summary_desc__c'));
            String valueStr = (String) ahaData.get('arce__risk_position_summary_desc__c');
            valueStr = valueStr.length() > 1000 ? valueStr.substring(0,999) : valueStr;
            riskPositionMap.put(S_COMMENTS, valueStr);
        }
        listBankingEGP = addBankingEGP(ahaData, prevAha, participantId, mapAccount);
        riskPositionMap.put('bankingEconomicGroupParticipants',listBankingEGP);
        return riskPositionMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Banking Economic Group Participants
    *                Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @param arce__Account_has_Analysis__c - prevAha - Object from query
    * @param Map<Id,arce.Arc_Gen_Account_Wrapper> mapAccount - Account wrapper related to aha
    * @return List<Map<String, Object>> with WS structure for bureau & main banks WS
    * @example addBankingEGP (ahaData, prevAha, participantId, mapAccount)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<Map<String, Object>> addBankingEGP (arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, String participantId, Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccount) {
        List<Map<String, Object>> listBankingEGP = new List<Map<String, Object>>();
        final Map<Id,Arc_Gen_Product_Wrapper> products = Arc_Gen_Product_Locator.getProductsActive();
        List<String> listIdsRP = new List<String>();
        for(arce__risk_position_summary__c riskItem : Arc_Gen_Risk_Position_summary_Data.getPositionSummaryData(new List<Id>{ahaData.Id})) {
            listIdsRP.add(riskItem.arce__account_Id__c);
        }
        Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccRP = new Map<Id, arce.Arc_Gen_Account_Wrapper>();
        if(!listIdsRP.isEmpty()){
            mapAccRP = arce.Arc_Gen_Account_Locator.getAccountInfoById(listIdsRP);
        }

        final String groupClient = arce.Arc_gen_Util.getFilialSubsidiaryByAha(new List<String>{(String) ahaData.Id});
        for(arce__risk_position_summary__c riskItem : Arc_Gen_Risk_Position_summary_Data.getPositionSummaryData(new List<Id>{ahaData.Id})) {
            if(prevAha.arce__Customer__c != riskItem.arce__account_Id__c) { //whether it is the total row
                Map<String, Object> bankingEGPMap = new Map<String, Object>();
                bankingEGPMap.put('id',(Object)arce.Arc_Gen_CallEncryptService.getEncryptedClient(mapAccRP.get(riskItem.arce__account_Id__c).accNumber));
                if(groupClient == null) {
                    bankingEGPMap.put(S_PART_TYPE,(Object)mapAccount.get(prevAha.arce__Customer__c).participantType);
                } else {
                    bankingEGPMap.put(S_PART_TYPE, groupClient);
                }
                bankingEGPMap.put('fullName',(Object)'999999');
                if(arce.Arc_Gen_ValidateInfo_utils.isFilled(riskItem.arce__banrel_comments_desc__c)) {
                    bankingEGPMap.put(S_COMMENTS,(Object)riskItem.arce__banrel_comments_desc__c);
                }
                bankingEGPMap.put('riskAmount',addRiskAmount(ahaData, riskItem));
                listBankingEGP.add(bankingEGPMap);
            }
            if(riskItem.arce__Product_id__c != null) {
                Map<String, Object> bankingEGPMap = new Map<String, Object>();
                bankingEGPMap.put('id',(Object)arce.Arc_Gen_CallEncryptService.getEncryptedClient(products.get(riskItem.arce__Product_id__c).externalId));
                if(groupClient == null) {
                    bankingEGPMap.put(S_PART_TYPE,(Object)mapAccount.get(prevAha.arce__Customer__c).participantType);
                } else {
                    bankingEGPMap.put(S_PART_TYPE, groupClient);
                }
                bankingEGPMap.put('fullName',(Object) products.get(riskItem.arce__Product_id__c).productName);
                if(arce.Arc_Gen_ValidateInfo_utils.isFilled(riskItem.arce__banrel_comments_desc__c)) {
                    bankingEGPMap.put(S_COMMENTS,(Object)riskItem.arce__banrel_comments_desc__c);
                }
                bankingEGPMap.put('riskAmount',addRiskAmount(ahaData, riskItem));
                listBankingEGP.add(bankingEGPMap);
            }
        }
        return listBankingEGP;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Risk Amount Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @param arce__risk_position_summary__c riskItem - Account wrapper related to aha
    * @return List<Map<String,Object>> with WS structure for Risk Amount
    * @example addRiskAmount(ahaData, riskItem)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<Map<String, Object>> addRiskAmount(arce__Account_has_Analysis__c ahaData, arce__risk_position_summary__c riskItem) {
        List<Map<String, Object>> listRiskAmount = new List<Map<String, Object>>();
        Map<String, Object> mapRsikAmount = new Map<String, Object>();
        mapRsikAmount.put('id',(Object)'CURRENT_LIMIT');
        //mapRsikAmount.put(S_AMOUNT,(Object)riskItem.arce__banrel_current_limit_name__c == null ? 0.0 : riskItem.arce__banrel_current_limit_name__c);
        mapRsikAmount.put(S_AMOUNT,(Object)getAmount(riskItem.arce__banrel_current_limit_name__c));
        mapRsikAmount.put(S_CURRENCY,(Object)riskItem.CurrencyIsoCode);
        listRiskAmount.add(mapRsikAmount);
        mapRsikAmount = new Map<String, Object>();
        mapRsikAmount.put('id',(Object)'COMMITED');
        //mapRsikAmount.put(S_AMOUNT,(Object)riskItem.arce__banrel_commitment_name__c == null ? 0.0 : riskItem.arce__banrel_commitment_name__c);
        mapRsikAmount.put(S_AMOUNT,(Object)getAmount(riskItem.arce__banrel_commitment_name__c));
        mapRsikAmount.put(S_CURRENCY,(Object)riskItem.CurrencyIsoCode);
        listRiskAmount.add(mapRsikAmount);
        mapRsikAmount = new Map<String, Object>();
        mapRsikAmount.put('id',(Object)'UNCOMMITED');
        //mapRsikAmount.put(S_AMOUNT,(Object)riskItem.arce__banrel_uncommitment_name__c == null ? 0.0 : riskItem.arce__banrel_uncommitment_name__c);
        mapRsikAmount.put(S_AMOUNT,(Object)getAmount(riskItem.arce__banrel_uncommitment_name__c));
        mapRsikAmount.put(S_CURRENCY,(Object)riskItem.CurrencyIsoCode);
        listRiskAmount.add(mapRsikAmount);
        mapRsikAmount = new Map<String, Object>();
        mapRsikAmount.put('id',(Object)'OUTSTANDING');
        //mapRsikAmount.put(S_AMOUNT,(Object)riskItem.arce__banrel_outstanding_name__c == null ? 0.0 : riskItem.arce__banrel_outstanding_name__c);
        mapRsikAmount.put(S_AMOUNT,(Object)getAmount(riskItem.arce__banrel_outstanding_name__c));
        mapRsikAmount.put(S_CURRENCY,(Object)riskItem.CurrencyIsoCode);
        listRiskAmount.add(mapRsikAmount);
        return listRiskAmount;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that returns a decimal value
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param Decimal - amount - value of decimal
    * @return Decimal value
    * @example getAmount(amount)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Decimal getAmount(Decimal amount) {
        return (amount == null ? 0.0 : amount);
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Banking pool Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @param arce__Account_has_Analysis__c - prevAha - Object from query
    * @param String participantId - encrypted account id
    * @param Map<Id,arce.Arc_Gen_Account_Wrapper> mapAccount - Account wrapper related to aha
    * @return Map<String, Object> with WS structure for Banking pool
    * @example addBankingPool(ahaData, prevAha, participantId, mapAccount)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addBankingPool(arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, String participantId, Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccount) {
        Map<String, Object> bankingPoolMap =  new Map<String, Object>();
        final Map<String, Object> financialSMap = addFinancialSystem(ahaData, prevAha, participantId, mapAccount);
        final Map<string, Object> bankingDetailMap = addBankingDetail(ahaData, prevAha, participantId, mapAccount);
        bankingPoolMap.put('financialSystem',financialSMap);
        bankingPoolMap.put('bankingDetail',bankingDetailMap);
        return bankingPoolMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Financial System Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @param arce__Account_has_Analysis__c - prevAha - Object from query
    * @param String participantId - encrypted account id
    * @param Map<Id,arce.Arc_Gen_Account_Wrapper> mapAccount - Account wrapper related to aha
    * @return Map<String, Object> with WS structure for Banking pool
    * @example addFinancialSystem(ahaData, prevAha, participantId, mapAccount)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addFinancialSystem(arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, String participantId, Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccount) {
        Map<String, Object> financialSMap = new Map<String, Object>();
        Map<String, Object> paymentDelayMap = new Map<String, Object>();
        final Map<String, Object> alert = addAlert(ahaData);
        paymentDelayMap.put('hasDelay',false);
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__cust_delay_payment_desc__c'))) {
            paymentDelayMap.put(S_COMMENTS, ahaData.get('arce__cust_delay_payment_desc__c'));
        }
        financialSMap.put('paymentDelay',paymentDelayMap);
        if(mapAccount.get(prevAha.arce__Customer__c).participantType == CLIENT && arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(alert)) {
            financialSMap.put('alert',alert);
        }
        return financialSMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Alert Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @return Map<String, Object> with WS structure for Alert
    * @example addAlert(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addAlert(arce__Account_has_Analysis__c ahaData) {
        final Map<String, Object> alertMap = new Map<String, Object>();
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__bureau_warning_prevention_desc__c'))) {
            alertMap.put('preventionDescription', ahaData.get('arce__bureau_warning_prevention_desc__c'));
        }
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__bureau_warn_prvnt_owner_desc__c'))) {
            alertMap.put('warningOwnerDescription', ahaData.get('arce__bureau_warn_prvnt_owner_desc__c'));
        }
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__bureau_warn_prvnt_action_desc__c'))) {
            alertMap.put('measure', ahaData.get('arce__bureau_warn_prvnt_action_desc__c'));
        }
        return alertMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Banking Detail Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @param arce__Account_has_Analysis__c - prevAha - Object from query
    * @param String participantId - encrypted account id
    * @param Map<Id,arce.Arc_Gen_Account_Wrapper> mapAccount - Account wrapper related to aha
    * @return Map<String, Object> with WS structure for Banking pool
    * @example addBankingDetail(ahaData, prevAha, participantId, mapAccount)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addBankingDetail(arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, String participantId, Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccount) {
        Map<String, Object> bankingDetailMap = new Map<String, Object>();
        final List<Map<String, Object>> otherBanksMap = addOtherBanks(ahaData);
        Map<String, Object> otherProdsMap = new Map<String, Object>();
        final Map<String, Object> econoCapitalMap = addEconomicCapitalMap(ahaData, prevAha);
        Map<String, Object> stageOperaMap = new Map<String, Object>();
        final Map<String, Object> capitalProvMap = addCapitalProvMap(ahaData);
        bankingDetailMap = Arc_Gen_Persistence_Utils.addifFilledList(bankingDetailMap,'otherBanks',otherBanksMap);
        otherProdsMap.put('hasOtherProducts',Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get('arce__other_contracted_product_type__c')));
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__other_contracted_product_desc__c'))) {
            otherProdsMap.put(S_DESCRIPTION,(Object)ahaData.get('arce__other_contracted_product_desc__c'));
        }
        bankingDetailMap.put('otherProducts',otherProdsMap);
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)prevAha.get('arce__number_entity_type__c'))) {
            bankingDetailMap.put('banksNumberRange',(Object)prevAha.get('arce__number_entity_type__c'));
        }
        bankingDetailMap.put('otherOperations',addOtherOperationsMap(ahaData));
        bankingDetailMap = Arc_Gen_Persistence_Utils.addifFilled(bankingDetailMap,'economicCapital',econoCapitalMap);
        bankingDetailMap = addLocalClassification(bankingDetailMap, ahaData, prevAha, mapAccount);
        stageOperaMap.put('hasStageOperations',Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get('arce__stage_collective_ind_type__c')));
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__stage_collective_desc__c'))) {
            stageOperaMap.put(S_DESCRIPTION,(Object)ahaData.get('arce__stage_collective_desc__c'));
        }
        bankingDetailMap.put('stageOperations',stageOperaMap);
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__customer_product_usage_desc__c'))) {
            bankingDetailMap.put('transactionalityDescription',(Object)ahaData.get('arce__customer_product_usage_desc__c'));
        }
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__banking_pool_desc__c'))) {
            bankingDetailMap.put('debtDescription',(Object)ahaData.get('arce__banking_pool_desc__c'));
        }
        bankingDetailMap = Arc_Gen_Persistence_Utils.addifFilled(bankingDetailMap,'capitalProvision',capitalProvMap);
        bankingDetailMap = addCovenant(bankingDetailMap, ahaData);
        return bankingDetailMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Covenant Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @param Map<String,Object> - bankingDetailMap - Map that contains info banking detail
    * @return Map<String,Object> with WS structure for Banking pool
    * @example addCovenant(bankingDetailMap,ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addCovenant(Map<String, Object> bankingDetailMap,arce__Account_has_Analysis__c ahaData) {
        Map<String, Object> convenantMap = new Map<String, Object>();
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__fin_covenants_breach_type__c'))) {
            convenantMap.put('hasCovenantBreaches',Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get('arce__fin_covenants_breach_type__c')));
        }
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__fin_covenants_breach_desc__c'))) {
            convenantMap.put('breachesComments',(Object)ahaData.get('arce__fin_covenants_breach_desc__c'));
        }
        if(arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(convenantMap)) {
            bankingDetailMap.put('covenant',convenantMap);
        }
        return bankingDetailMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Other Banks Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @return List<Map<String,Object>> with WS structure for Other Banks
    * @example addOtherBanks(ahaData) {
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<Map<String,Object>> addOtherBanks(arce__Account_has_Analysis__c ahaData) {
        final List<Map<String,Object>> listMainBanks = new List<Map<String,Object>>();
        Integer count = 1;
        for(arce__main_banks__c mainBItem : Arc_Gen_MainBanks_Data.getMainBanks(ahaData.Id)) {
            Map<String, Object> mapMainBank = new Map<String, Object>();
            mapMainBank.put('id',(Object)String.valueOf(count).length() == 1 ? '000' + count : String.valueOf(count).length() == 2 ? '00' + count : String.valueOf(count).length() == 3 ? '0' + count : String.valueOf(count));
            mapMainBank.put('name',(Object)mainBItem.arce__entity_name__c);
            mapMainBank.put('percentage',(Object)mainBItem.arce__entity_quota_share_per__c);
            listMainBanks.add(mapMainBank);
            count++;
        }
        return listMainBanks;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Other Operations Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @return Map<String,Object> with WS structure for Other Operations
    * @example addOtherOperationsMap(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addOtherOperationsMap(arce__Account_has_Analysis__c ahaData) {
        Map<String, Object> otherOperaMap = new Map<String, Object>();
        otherOperaMap.put('hasOtherOperations',Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get('arce__other_operation_type__c')));
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__other_operation_desc__c'))) {
            otherOperaMap.put(S_DESCRIPTION,(Object)ahaData.get('arce__other_operation_desc__c'));
        }
        return otherOperaMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Economic Capital Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @param arce__Account_has_Analysis__c - prevAha - Object from query
    * @return Map<String,Object> with WS structure for Economic Capital
    * @example addEconomicCapitalMap(ahaData,prevAha)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addEconomicCapitalMap(arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha) {
        Map<String, Object> econoCapitalMap = new Map<String, Object>();
        if(arce.Arc_Gen_ValidateInfo_utils.isFilled(ahaData.get('arce__rar_profitability_per__c') == null ? null : String.valueOf(ahaData.get('arce__rar_profitability_per__c')))) {
            econoCapitalMap.put(S_AMOUNT,(Object)ahaData.get('arce__rar_profitability_per__c'));
            econoCapitalMap.put(S_CURRENCY,UserInfo.getDefaultCurrency());
        }
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)prevAha.get('arce__rar_profitability_desc__c'))) {
            econoCapitalMap.put(S_DESCRIPTION,(Object)ahaData.get('arce__rar_profitability_desc__c'));
        }
        return econoCapitalMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Capital Provision Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @return Map<String,Object> with WS structure for Capital Provision
    * @example addCapitalProvMap(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addCapitalProvMap(arce__Account_has_Analysis__c ahaData) {
        Map<String, Object> capitalProvMap = new Map<String, Object>();
        if(arce.Arc_Gen_ValidateInfo_utils.isFilled(ahaData.get('arce__capital_provision_per__c') == null ? null :String.valueOf(ahaData.get('arce__capital_provision_per__c')))) {
            capitalProvMap.put('percentage',(Object)ahaData.get('arce__capital_provision_per__c'));
        }
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__capital_provision_desc__c'))) {
            capitalProvMap.put(S_COMMENTS,(Object)ahaData.get('arce__capital_provision_desc__c'));
        }
        return capitalProvMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for generating Capital Provision Object
    * -----------------------------------------------------------------------------------------------
    * @Author  Manuel Hugo Castillo Chavarria
    * @Date     Created: 01/11/2020
    * @param arce__Account_has_Analysis__c - ahaData - Object from dynamic form
    * @return Map<String,Object> with WS structure for Capital Provision
    * @example addCapitalProvMap(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addLocalClassification(Map<String, Object> bankingDetailMap, arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccount) {
        if(mapAccount.get(prevAha.arce__Customer__c).participantType == CLIENT && arce.Arc_Gen_ValidateInfo_utils.isFilled(ahaData.get('arce__hats_risk_qualification_number__c') == null ? null : String.valueOf(prevAha.get('arce__hats_risk_qualification_number__c')))) {
                bankingDetailMap.put('localClassification',(Object)prevAha.get('arce__hats_risk_qualification_number__c'));
        }
        return bankingDetailMap;
    }
}