/**
* ____________________________________________________________________________
* Controller class for HPG_GlobalClientsExposure_Ct.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-11-15
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class HPG_GlobalClientsExposure_Ctrl {
    /**
    * @description Get Initial data
    * @param recordId - : recordId
    * @param recordCode - : recordCode
    * @return retMap initial data
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData(Id recordId, String recordCode) {
        Map<String, Object> retMap = new Map<String, Object>();
        String errorMessage = '';
        Id groupId;
        String groupName = '';
        String groupCode = '';
        if (recordCode == '') {
            final String objectName = recordId.getSObjectType().getDescribe().getName();
            switch on objectName {
                when 'Local_Client__c' {
                    List<Local_Client__c> localClientList = [SELECT Alpha_code__c FROM Local_Client__c WHERE Id =:recordId];
                    if (localClientList.size() > 0 && localClientList[0].Alpha_code__c != '' && localClientList[0].Alpha_code__c != null) {
                        recordCode = localClientList[0].Alpha_code__c;
                    } else {
                        errorMessage = Label.HPG_Error_Get_Data;
                    }
                }
                when 'Account' {
                    List<Account> accountList = [SELECT Id, DES_Group_Code__c FROM Account WHERE Id =:recordId];
                    if (accountList.size() > 0 && accountList[0].DES_Group_Code__c != '' && accountList[0].DES_Group_Code__c != null) {
                        recordCode = accountList[0].DES_Group_Code__c;
                    } else {
                        List<Local_Client__c> localClientList = [SELECT Alpha_code__c FROM Local_Client__c WHERE Cib_Client__c =:recordId];
                        if (localClientList.size() > 0 && localClientList[0].Alpha_code__c != '' && localClientList[0].Alpha_code__c != null) {
                            recordCode = localClientList[0].Alpha_code__c;
                        } else {
                            errorMessage = Label.HPG_Error_Get_Data;
                        }
                    }
                }
                when else {
                    errorMessage = Label.HPG_Error_Get_Data;
                }
            }
        }
        if (recordCode != '' || errorMessage == '') {
            Map<String, Object> request = new Map<String, Object>();
            String queryString;
            queryString = 'clientIdentifier=' + recordCode;
            request.put('queryString' , queryString);
            HPG_GroupPositions.Wrapper groupPositions = HPG_GroupPositions.getGroupPositions(request);
            if (!groupPositions.success || groupPositions.data.groupId == '' || groupPositions.data.groupId == null) {
                if(!groupPositions.success) {
                    retMap.put('errorMessage', Label.HPG_Error_Get_Data);
                }else {
                    retMap.put('errorMessage', Label.HPG_Error_No_Data_From_Service);
                }
                retMap.put('success', false);
            } else {
                groupCode = groupPositions.data.groupId;
                List<Account> accountList = [SELECT Id, Name FROM Account WHERE DES_Group_Code__c =:groupCode];
                if (accountList.size() > 0) {
                    groupId = accountList[0].Id;
                    groupName = accountList[0].Name;
                } else {
                    List<Local_Client__c> localClientList = [SELECT Cib_Client__c, Cib_Client__r.Name FROM Local_Client__c WHERE Alpha_code__c =:recordCode];
                    if (localClientList.size() > 0) {
                        groupId = localClientList[0].Cib_Client__c;
                        groupName = localClientList[0].Cib_Client__r.Name;
                    } else {
                        retMap.put('errorMessage', Label.HPG_Error_Get_Data);
                        retMap.put('success', false);
                    }
                }
                if (groupId != null && groupName != '') {
                    retMap.put('recordCode', recordCode);
                    retMap.put('groupName', groupName);
                    retMap.put('groupId', groupId);
                    retMap.put('groupCode', groupCode);
                    retMap.put('success', true);
                } else {
                    retMap.put('errorMessage', Label.HPG_Error_Get_Data);
                    retMap.put('success', false);
                }
            }
        } else {
            if (errorMessage == '') {
                retMap.put('errorMessage', Label.HPG_Error_Get_Data);
            } else {
                retMap.put('errorMessage', errorMessage);
            }
            retMap.put('success', false);
        }
        return retMap;
    }
}