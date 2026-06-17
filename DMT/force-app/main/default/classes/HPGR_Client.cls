/*-------------------------------------------------------------------------------------------
* @Name     HPGR_Client
* @Author   torcuato.tejada.tech@bbva.com
*           cosme.alcazar.tech@bbva.com
* @Date     Created: 2024-07-18
* -------------------------------------------------------------------------------------------
* @Description  Client_Itf implementation class
* -------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class HPGR_Client implements hpgr.Client_Itf {

    static final String EXTERNAL_APP_ICON = 'hpgr__External_App_Icon';
    static final String EXTERNAL_APP_URL = '/lightning/cmp/c__dMT_page_Deal_Manament?c__recordAcc=';

    /**
    * @description get client code used to call 'group-positions' service
    * @param recordId : Id of the client
    * @return client code
    */
    global Map<String, Object> getRecordCode(Id recordId) {
        Map<String, Object> retMap = new Map<String, Object>();
        final String objectName = recordId.getSObjectType().getDescribe().getName();
        switch on objectName {
            when 'Local_Client__c' {
                retMap = getLocalClient(recordId);
            }
            when 'Account' {
                retMap = getAccount(recordId);
                // if there is no local_client, obtain the client parent group
                if (!(Boolean)retMap.get('success')) {
                    retMap = getParentGroupFromId(recordId);
                }
            }
            when else {
                retMap.put('errorMessage', Label.hpgr.Error_Get_Data);
                retMap.put('success', false);
            }
        }
        return retMap;
    }

    /**
    * @description get group data
    * @param groupCode : group code obtained in 'group-positions' service
    * @param recordCode : Salesforce recordId
    * @return group data
    */
    global Map<String, Object> getGroupData(String groupCode, String recordCode) {
        Id groupId;
        String groupName = '';
        final Map<String,Object> retMap = new Map<String, Object>();
        List<Account> accountList = [SELECT Id, Name FROM Account WHERE DES_Group_Code__c =:groupCode];
        if (accountList.size() > 0) {
            retMap.put('groupId', accountList[0].Id);
            retMap.put('groupName', accountList[0].Name);
            retMap.put('groupCode', groupCode);
            retMap.put('success', true);
        } else {
            List<Local_Client__c> localClientList = [SELECT Cib_Client__c, Cib_Client__r.Name FROM Local_Client__c WHERE Alpha_code__c =:recordCode];
            if (localClientList.size() > 0) {
                retMap.put('groupId', localClientList[0].Cib_Client__c);
                retMap.put('groupName', localClientList[0].Cib_Client__r.Name);
                retMap.put('groupCode', groupCode);
                retMap.put('success', true);
            } else {
                retMap.put('errorMessage', Label.hpgr.Error_Get_Data);
                retMap.put('success', false);
            }
        }
        return retMap;
    }

    /**
    * @description get client additional info
    * @param clientId : Id of the client
    * @return additional info
    */
    global String getAdditionalInfo(Id clientId) {
        List<cstk__General_Data__c> generalData = [SELECT cstk__cta__c, cstk__cca__c, cstk__tri__c
                                                    FROM cstk__General_Data__c
                                                    WHERE cstk__toolkit_id__r.cstk__account_id__c = :clientId AND cstk__year__c = '0000'];
        String ccaScore = 'N/A';
        String ctaScore = 'N/A';
        String triScore = 'N/A';
        if (generalData.size() > 0) {
            if (generalData[0].cstk__cca__c != null) {
                ccaScore = String.valueOf(generalData[0].cstk__cca__c.setScale(1));
            }
            if (generalData[0].cstk__cta__c != null) {
                ctaScore = String.valueOf(generalData[0].cstk__cta__c.setScale(1));
            }
            if (generalData[0].cstk__tri__c != null) {
                triScore = String.valueOf(Integer.valueOf(generalData[0].cstk__tri__c));
            }
        }
        String triData = ' - TRI ' + triScore +' - CCA ' + ccaScore + ' - CTA ' + ctaScore;
        return triData;
    }

    /**
    * @description get external app info
    * @param - : no param
    * @return external app info
    */
    global Map<String, Object> getExternalAppInfo(String groupId) {
        Map<String,Object> retMap = new Map<String, Object>();
        retMap.put('externalAppIcon', EXTERNAL_APP_ICON);
        retMap.put('externalAppName', Label.GoToDMTLines);
        retMap.put('externalAppUrl', EXTERNAL_APP_URL + groupId);
        return retMap;
    }

    /**
    * @description get parent group by looking into amch (multihierarchy) with vision Riesgos, fallback to main parent.
    * @param clientId: Account Id
    * @return String groupcode
    */
    private static Map<String,Object> getParentGroupFromId(Id clientId) {
        Map<String,Object> res = new Map<String, Object>{'recordCode' => '', 'errorMessage' => Label.hpgr.Error_Get_Data, 'success' => false};
        final List<AMH_GBL_Account_Relationship__c> acmh = [SELECT AMH_Parent_Account__r.DES_Group_Code__c FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND DES_Main_Parent__c = 'S' AND AMH_Child_Account__c =:clientId];
        if (acmh.size() > 0 && !String.isBlank(acmh[0].AMH_Parent_Account__r.DES_Group_Code__c)) {
            res.put('recordCode', acmh[0].AMH_Parent_Account__r.DES_Group_Code__c);
            res.put('errorMessage', '');
            res.put('success', true);
        } else {
            final String groupCode = [SELECT DES_Main_Parent__r.DES_Group_Code__c FROM Account WHERE Id =:clientId].DES_Main_Parent__r.DES_Group_Code__c;
            if (!String.isBlank(groupCode)) {
                res.put('recordCode', groupCode);
                res.put('errorMessage', '');
                res.put('success', true);
            }
        }
        return res;
    }

    /**
    * @description get parent group by looking into amch (multihierarchy) with vision Riesgos, fallback to main parent.
    * @param clientId: Account Id
    * @return String groupcode
    */
    private Map<String, Object> getLocalClient(Id recordId) {
        final Map<String,Object> res = new Map<String, Object>{'recordCode' => '', 'errorMessage' => Label.hpgr.Error_Get_Data, 'success' => false};
        final List<Local_Client__c> localClientList = [SELECT Alpha_code__c FROM Local_Client__c WHERE Id =:recordId];
        if (localClientList.size() > 0 && localClientList[0].Alpha_code__c != '' && localClientList[0].Alpha_code__c != null) {
            res.put('recordCode', localClientList[0].Alpha_code__c);
            res.put('errorMessage', '');
            res.put('success', true);
        }
        return res;
    }

    /**
    * @description get parent group by looking into amch (multihierarchy) with vision Riesgos, fallback to main parent.
    * @param clientId: Account Id
    * @return String groupcode
    */
    private Map<String, Object> getAccount(Id recordId) {
        final Map<String,Object> res = new Map<String, Object>{'recordCode' => '', 'errorMessage' => Label.hpgr.Error_Get_Data, 'success' => false};
        final List<Account> accountList = [SELECT Id, DES_Group_Code__c FROM Account WHERE Id =:recordId];
        if (accountList.size() > 0 && accountList[0].DES_Group_Code__c != '' && accountList[0].DES_Group_Code__c != null) {
            res.put('recordCode', accountList[0].DES_Group_Code__c);
            res.put('errorMessage', '');
            res.put('success', true);
        } else {
            List<Local_Client__c> localClientList = [SELECT Alpha_code__c FROM Local_Client__c WHERE Cib_Client__c =:recordId];
            if (localClientList.size() > 0 && localClientList[0].Alpha_code__c != '' && localClientList[0].Alpha_code__c != null) {
                res.put('recordCode', localClientList[0].Alpha_code__c);
                res.put('errorMessage', '');
                res.put('success', true);
            }
        }
        return res;
    }
}