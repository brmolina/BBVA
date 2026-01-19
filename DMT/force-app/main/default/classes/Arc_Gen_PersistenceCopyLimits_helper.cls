/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistenceCopyLimits_helper
* @Author   Juan Ignacio Hita Manso
* @Date     Created: 2020-10-28
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class with helper methods for PersistenceCopyLimits_service class
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-10-28 Juan Ignacio Hita Manso
*             Class creation.
* |2021-01-07 José Luis García Díaz
*             Fix sanction error in orphan customers.
* |2021-01-12 Juan Ignacio Hita Manso
*             Changes in mapping fields to params request
* |2021-01-15 Juan Ignacio Hita Manso
*             Add maturity date to json object request service
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_PersistenceCopyLimits_helper {

    /*------------------------------------------------------------------------------------------------------
    * @Description Builder Arc_Gen_PersistenceCopyLimits_helper
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2020-10-28
    * @param    null
    * @return   Arc_Gen_PersistenceCopyLimits_helper
    * @example  new Arc_Gen_PersistenceCopyLimits_helper()
    * */
    @TestVisible
    private Arc_Gen_PersistenceCopyLimits_helper() {}

    /*------------------------------------------------------------------------------------------------------
    * @Description Method that generate json body for uses in copy-limits service
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2020-10-28
    * @param    Map<String, arce__limits_exposures__c> lstAha
    * @param    Arc_Gen_User_Wrapper user
    * @param    Map<String, Object> data
    * @return   Map<String, Object>
    * @example  Map<String, Object> mapObj = copyLimitsJson(lstAha, user, data);
    * */
    public static Map<String, Object> copyLimitsJson(List<arce__Account_has_Analysis__c> lstAha, arce.Arc_Gen_User_Wrapper user, Map<String, Object> data) {
        final Map<String, arce__Account_has_Analysis__c> mapAha = new Map<String, arce__Account_has_Analysis__c>();
        String accGroupId = '';
        for(arce__Account_has_Analysis__c aha : lstAha) {
            mapAha.put(aha.arce__Customer__c, aha);
            if (aha.arce__group_asset_header_type__c == arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER) {
                accGroupId = aha.arce__Customer__c;
            }
        }
        final List<String> lstKeyAha = new List<String>(mapAha.keySet());
        if (accGroupId == '') {
            // If there is no group, it's an orphan customer. Pick the first ID.
            accGroupId = mapAha.get(lstKeyAha[0]).arce__Customer__c;
        }

        final Map<Id, arce.Arc_Gen_Account_Wrapper> accWrapMap = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<String> {accGroupId});
        final String sancDateCom = (String) data.get('sancdateCometee');
        Map<String, Object> mapObj = fillCommitteeStruc(user, sancDateCom, mapAha.get(accGroupId));
        fillBankStructure(mapObj, accWrapMap.get(accGroupId), user);
        mapObj.put('riskAssessments', fillRiskAssesment(lstAha));
        return mapObj;
    }

    /*------------------------------------------------------------------------------------------------------
    * @Description Method that fills risk assesment structure object
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2020-10-28
    * @param    List<arce__Account_has_Analysis__c> lstAha
    * @return   List<Map<String, Object>>
    * @example  List<Map<String, Object>> mapObj = fillRiskAssesment(accWrapMap);
    * */
    public static List<Map<String, Object>> fillRiskAssesment(List<arce__Account_has_Analysis__c> lstAha) {
        final List<Map<String, Object>> lstRiskAsses = new List<Map<String, Object>>();
        for(arce__Account_has_Analysis__c accAha : lstAha) {
            final Map<String, Object> mapObj = new Map<String, Object>();
            getIdStructure(mapObj, accAha.Name, '');
            lstRiskAsses.add(mapObj);
        }
        return lstRiskAsses;
    }

    /*------------------------------------------------------------------------------------------------------
    * @Description Method that fills bank structure object
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2020-10-28
    * @param    Map<String, Object> mapObj
    * @param    Arc_Gen_Account_Wrapper accWrap
    * @param    Arc_Gen_User_Wrapper user
    * @return   Map<String, Object> mapObj
    * @example  Map<String, Object> mapObj = fillBankStructure(mapObj, accWrap, user);
    * */
    public static void fillBankStructure(Map<String, Object> mapObj, arce.Arc_Gen_Account_Wrapper accWrap, arce.Arc_Gen_User_Wrapper user) {
        if (!String.isBlank(accWrap.bankId)) {
            final Map<String, Object> mapBankStructure = new Map<String, Object>();
            if (!String.isBlank(user.branchId)) {
                final Map<String, Object> mapBranch = new Map<String, Object>();
                getIdStructure(mapBranch, user.branchlevel, 'level');
                getIdStructure(mapBranch, user.branchId, '');
                mapBankStructure.put('branch', mapBranch);
            }
            getIdStructure(mapBankStructure, accWrap.bankId, '');
            mapObj.put('bank', mapBankStructure);
        }
    }

    /*------------------------------------------------------------------------------------------------------
    * @Description Method that fills committee object
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2021-01-12
    * @param    Arc_Gen_User_Wrapper user
    * @param    String sancdateCometee
    * @param    arce__Account_has_Analysis__c accAha
    * @return   Map<String, Object> mapObj
    * @example  Map<String, Object> mapObj = fillCommitteeStruc(user, sancdateCometee, accAha);
    * */
    public static Map<String, Object> fillCommitteeStruc(arce.Arc_Gen_User_Wrapper user, String sancdateCometee, arce__Account_has_Analysis__c accAha) {
        Map<String, Object> mapObj = new Map<String, Object>();
        final String idCommittee = arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Analysis__c', 'arce__bbva_committees_type__c', accAha.arce__Analysis__r.arce__bbva_committees_type__c);
        if (!String.isBlank(idCommittee)) {
            final Map<String, Object> mapCommitte = new Map<String, Object>();
            mapCommitte.put('expirationDate', sancdateCometee);
            getIdStructure(mapCommitte, idCommittee, '');
            mapObj.put('committee', mapCommitte);
        }
        return mapObj;
    }

    /*------------------------------------------------------------------------------------------------------
    * @Description Auxilar method for get id structure
    * -----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     2020-10-28
    * @param    Map<String, Object> mapObj
    * @param    String value
    * @param    String valueKey
    * @return   void
    * @example  Map<String, Object> mapObj = getIdStructure(mapObj, value, valueKey);
    * */
    public static void getIdStructure(Map<String, Object> mapObj, String value, String valueKey) {
        if (valueKey == '') {
            mapObj.put('id', value);
        } else {
            if (!String.isBlank(value)) {
                final Map<String, Object> mapObjId = new Map<String, Object> {
                    'id' => value
                };
                mapObj.put(valueKey, mapObjId);
            }
        }
    }
}