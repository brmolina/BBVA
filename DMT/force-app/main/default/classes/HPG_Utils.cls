/**
* ────────────────────────────────────────────────────────────────────
* Client Position Utils class.
* ────────────────────────────────────────────────────────────────────
* @author     torcuato.tejada.contractor@bbva.com
* @modifiedBy
* @version     1.0
* @created     2023-04-14
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class HPG_Utils {

    //static final String SUPRAGROUP_NAME = 'Supragroup';
    //static final String GROUP_NAME = 'Group';
    //static final String SHARED_GROUP_NAME = 'Shared Management Group';
    static final String ACCESS_GCE_STD = 'STD';
    static final String ACCESS_GCE_RISK = 'RISK';
    static final String TOTAL_CLIENTS = 'TOTAL CLIENTS';
    static final List<String> ADMIN_PROFILES = new List<String>{'System Administrator', 'Consultation IT'};

    private HPG_Utils() {}

    public static HttpResponse callService(String serviceName, Map<String, Object> request) {
        request.put('userId', getFederationIdentifier());
        final String requestStr = JSON.serialize(request);
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = getMock(serviceName);
        } else {
            response = iaso.GBL_Integration_GenericService.invoke(serviceName, requestStr);
        }
        return response;
    }

    public static HttpResponse getMock(String serviceName) {
        final HttpResponse response = new HttpResponse();
        final iaso__GBL_integration_service__mdt serviceDetails = [SELECT iaso__Mock_LTA__c , iaso__Http_Method__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName =:serviceName LIMIT 1];
        final String responseBody = (String)serviceDetails.get('iaso__Mock_LTA__c');
        final String requestMethod = (String)serviceDetails.get('iaso__Http_Method__c');
        response.setStatus('OK');
        if (serviceName == 'HPG_UpdateOverrideConsumption' || serviceName == 'HPG_CreateOverrideConsumption') {
            response.setStatusCode(204);
        }else {
            response.setStatusCode(requestMethod == 'GET' ? 200 : 201);
        }
        response.setBody(responseBody);
        return response;
    }

    public static String getFederationIdentifier() {
        final Id userId = UserInfo.getUserId();
        String res;
        User usr = [SELECT Access_GCE__c, FederationIdentifier FROM User WHERE Id = :userId LIMIT 1];
        if (usr.Access_GCE__c == ACCESS_GCE_STD || usr.Access_GCE__c == ACCESS_GCE_RISK) {
            res = usr.FederationIdentifier;
        } else {
            throw new HandledException('You have no access to this resource: missing Access_GCE');
        }
        return res;
    }

    // DEPRECATED
    //public static Map<String,Object> handleServiceError(Map<String,Object> responseBodyErrorMap){
    //    Map<String,Object> returnMap = new Map<String,Object>();
    //    String responseSerialize = JSON.serialize(responseBodyErrorMap.get('messages'));
    //    final Map<String, Object> responseMap1 = (Map<String, Object>) JSON.deserializeUntyped(responseSerialize.substring(1, responseSerialize.length() -1));
    //    final String response = (String)responseMap1.get('message');
    //    returnMap.put('success', false);
    //    returnMap.put('errorMessage', 'An error ocurred meanwhile calling the service, please try again later.' + ' ' + response);
    //    return returnMap;
    //}

    // DEPRECATED
    //public static String getGroupId(Id clientId) {
    //    final Map<String,Object> groups = getGroupFromClient(clientId);
    //    final String res = (String)groups.get('groupCode');
    //    return res;
    //}

    /** DEPRECATED
    * @description Get client data
    * @param recordId - : Account Id or Local_Client__c
    * @return retMap account data
    */
    //public static Account getClient(Id recordId) {
    //    final String objectName = recordId.getSObjectType().getDescribe().getName();
    //    Id clientId;
    //    switch on objectName {
    //        when 'Local_Client__c' {
    //            final Local_Client__c localC = [SELECT Cib_Client__c FROM Local_Client__c WHERE Id =:recordId][0];
    //            clientId = localC.Cib_Client__c;
    //        }
    //        when else {
    //            clientId = recordId;
    //        }
    //    }
    //    final Account acc = [SELECT Name, DES_Structure_Type__c, DES_Group_Code__c, DES_Main_Parent__c, DES_Main_Parent__r.Name, DES_Main_Parent__r.DES_Group_Code__c, DES_Main_Parent__r.DES_Structure_Type__c, DES_Main_Parent__r.DES_Main_Parent__r.Name, DES_Main_Parent__r.DES_Main_Parent__r.DES_Group_Code__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Structure_Type__c FROM Account WHERE Id =:clientId][0];
    //    return acc;
    //}

    /**
    * @description - DEPRECATED
    * - Get group information if the id is not from a group, get parent group by looking into amch (multihierarchy) with vision Riesgos or main parent if that is not available.
    * - Take into account if there is a supragroup
    *
    *   - If there is no supgragroup:
    *      group -> groupId
    *      subgroup -> subgroupId
    *      subsidiary -> customerId
    *
    *   - If there is supragroup:
    *      supgragroup -> groupId
    *      group -> subgroupId
    *      subgroup -> level3Id
    *      subsidiary -> customerId
    *
    * @param recordId - : Account Id or Local_Client__c Id
    * @return retMap account data
    */
    //public static Map<String,Object> getGroupFromClient(Id recordId) {
    //    final Map<String,Object> res = new Map<String,Object>();
    //    final String objectName = recordId.getSObjectType().getDescribe().getName();
    //    final List<String> groupList = new List<String>{SUPRAGROUP_NAME, GROUP_NAME};
    //    Id clientId;
    //    String alphaCode;
    //    switch on objectName {
    //        when 'Local_Client__c' {
    //            Local_Client__c localC = [SELECT Cib_Client__c, Alpha_code__c FROM Local_Client__c WHERE Id =:recordId][0];
    //            clientId = localC.Cib_Client__c;
    //            alphaCode = localC.Alpha_code__c;
    //        }
    //        when else {
    //            List<Local_Client__c> localClients = [SELECT Alpha_code__c FROM Local_Client__c WHERE Cib_Client__c =:recordId];
    //            clientId = recordId;
    //            if (localClients.size() > 0) {
    //                alphaCode = localClients[0].Alpha_code__c;
    //            }
    //        }
    //    }
    //    final Account acc = getClient(clientId);
    //    res.put('Id', clientId);
    //    res.put('IdType', acc.DES_Structure_Type__c);
    //    res.put('alphaCode', alphaCode);
    //    res.put('clientName', acc.Name);
    //    if (acc.DES_Structure_Type__c == SUPRAGROUP_NAME) {
    //        res.put('groupName', acc.Name);
    //        res.put('groupCode', acc.DES_Group_Code__c);
    //        res.put('groupId', clientId);
    //    } else if (acc.DES_Structure_Type__c == GROUP_NAME || acc.DES_Structure_Type__c == SHARED_GROUP_NAME) {
    //        if (getChildrenVisionRisk(clientId)) {
    //            final List<dwp_acmh__GBL_Account_Relationship__c> acmh = [SELECT Name, dwp_acmh__Parent_Account__c, dwp_acmh__Parent_Account__r.Name, dwp_acmh__Parent_Account__r.DES_Structure_Type__c, dwp_acmh__Parent_Account__r.DES_Group_Code__c, dwp_acmh__Parent_Account__r.DES_Main_Parent__c, dwp_acmh__Parent_Account__r.DES_Main_Parent__r.Name, dwp_acmh__Parent_Account__r.DES_Main_Parent__r.DES_Group_Code__c, dwp_acmh__Parent_Account__r.DES_Main_Parent__r.DES_Structure_Type__c, dwp_acmh__ChildName__c, DES_Participacion__c, DES_Type__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Vision__c = 'Riesgos' AND DES_Main_Parent__c = 'S' AND dwp_acmh__Child_Account__c =:clientId];
    //            if (acmh.size() > 0 && acmh[0].dwp_acmh__Parent_Account__r.DES_Structure_Type__c == SUPRAGROUP_NAME) {
    //                res.put('groupName', acmh[0].dwp_acmh__Parent_Account__r.Name);
    //                res.put('groupCode', acmh[0].dwp_acmh__Parent_Account__r.DES_Group_Code__c);
    //                res.put('groupId', acmh[0].dwp_acmh__Parent_Account__c);
    //                res.put('subGroupId', acc.Id);
    //                res.put('subGroupName', acc.Name);
    //            } else  {
    //                res.put('groupName', acc.Name);
    //                res.put('groupCode', acc.DES_Group_Code__c);
    //                res.put('groupId', clientId);
    //            }
    //        } else {
    //            if (acc.DES_Main_Parent__r.DES_Structure_Type__c == SUPRAGROUP_NAME) {
    //                res.put('groupName', acc.DES_Main_Parent__r.Name);
    //                res.put('groupCode', acc.DES_Main_Parent__r.DES_Group_Code__c);
    //                res.put('groupId', acc.DES_Main_Parent__c);
    //                res.put('subGroupId', acc.Id);
    //                res.put('subGroupName', acc.Name);
    //            } else {
    //                res.put('groupName', acc.Name);
    //                res.put('groupCode', acc.DES_Group_Code__c);
    //                res.put('groupId', clientId);
    //            }
    //        }
    //    } else {
    //        final List<dwp_acmh__GBL_Account_Relationship__c> acmh = [SELECT Name, dwp_acmh__Parent_Account__c, dwp_acmh__Parent_Account__r.Name, dwp_acmh__Parent_Account__r.DES_Structure_Type__c, dwp_acmh__Parent_Account__r.DES_Group_Code__c, dwp_acmh__Parent_Account__r.DES_Main_Parent__c, dwp_acmh__Parent_Account__r.DES_Main_Parent__r.Name, dwp_acmh__Parent_Account__r.DES_Main_Parent__r.DES_Group_Code__c, dwp_acmh__Parent_Account__r.DES_Main_Parent__r.DES_Structure_Type__c, dwp_acmh__ChildName__c, DES_Participacion__c, DES_Type__c from dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Vision__c = 'Riesgos' AND DES_Main_Parent__c = 'S' AND dwp_acmh__Child_Account__c =:clientId];
    //        if (acmh.size() > 0) {
    //            final Id groupId = acmh[0].dwp_acmh__Parent_Account__c;
    //            final List<dwp_acmh__GBL_Account_Relationship__c> supracmh = [SELECT Name, dwp_acmh__Parent_Account__c, dwp_acmh__Parent_Account__r.Name, dwp_acmh__Parent_Account__r.DES_Structure_Type__c, dwp_acmh__Parent_Account__r.DES_Group_Code__c, dwp_acmh__Parent_Account__r.DES_Main_Parent__c, dwp_acmh__Parent_Account__r.DES_Main_Parent__r.Name, dwp_acmh__Parent_Account__r.DES_Main_Parent__r.DES_Group_Code__c, dwp_acmh__Parent_Account__r.DES_Main_Parent__r.DES_Structure_Type__c, dwp_acmh__ChildName__c, DES_Participacion__c, DES_Type__c from dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Vision__c = 'Riesgos' AND DES_Main_Parent__c = 'S' AND dwp_acmh__Child_Account__c =:groupId];
    //            if (supracmh.size() > 0) {
    //                if (supracmh[0].dwp_acmh__Parent_Account__r.DES_Structure_Type__c == SUPRAGROUP_NAME) {
    //                    res.put('groupName', supracmh[0].dwp_acmh__Parent_Account__r.Name);
    //                    res.put('groupCode', supracmh[0].dwp_acmh__Parent_Account__r.DES_Group_Code__c);
    //                    res.put('groupId', supracmh[0].dwp_acmh__Parent_Account__c);
    //                    res.put('subGroupId', acmh[0].dwp_acmh__Parent_Account__c);
    //                    res.put('subGroupName',acmh[0].dwp_acmh__Parent_Account__r.Name);
    //                } else {
    //                    res.put('groupName', acmh[0].dwp_acmh__Parent_Account__r.Name);
    //                    res.put('groupCode', acmh[0].dwp_acmh__Parent_Account__r.DES_Group_Code__c);
    //                    res.put('groupId', acmh[0].dwp_acmh__Parent_Account__c);
    //                }
    //            } else {
    //                res.put('groupName', acmh[0].dwp_acmh__Parent_Account__r.Name);
    //                res.put('groupCode', acmh[0].dwp_acmh__Parent_Account__r.DES_Group_Code__c);
    //                res.put('groupId', groupId);
    //            }
    //        } else  {
    //            res.put('groupName', acc.DES_Main_Parent__r.Name);
    //            res.put('groupCode', acc.DES_Main_Parent__r.DES_Group_Code__c);
    //            res.put('groupId', acc.DES_Main_Parent__c);
    //        }
    //    }
    //    return res;
    //}

    // DEPRECATED
    //private static boolean getChildrenVisionRisk(Id accountId) {
    //    final List<dwp_acmh__GBL_Account_Relationship__c> acmh = [SELECT Id from dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Vision__c = 'Riesgos' AND  dwp_acmh__Parent_Account__c =:accountId LIMIT 1];
    //    return acmh.size() > 0;
    //}

    public static List<String> getCountriesToCompact(){
        final Id userId = UserInfo.getUserId();
        List<String> res = new List<String>();
        User userInfo = [Select Access_GCE__c, DES_Country__c, Profile.Name FROM User WHERE Id=:userId LIMIT 1];

        Boolean riskUser = UserInfo.Access_GCE__c == ACCESS_GCE_RISK;

        if (!String.isBlank(userInfo.DES_Country__c)) {
            String userCountry = userInfo.DES_Country__c;
            List<HPG_Geography_Visibility_Configuration__c> compacted = [SELECT Risk_Compacted__c, No_Risk_Compacted__c FROM HPG_Geography_Visibility_Configuration__c WHERE Geography__c =: userCountry LIMIT 1];
            if (compacted.size() > 0) {
                if (riskUser) {
                    if (!String.isBlank(compacted[0].Risk_Compacted__c)) {
                        res = compacted[0].Risk_Compacted__c.split(',');
                    }
                } else {
                    if (!String.isBlank(compacted[0].No_Risk_Compacted__c)) {
                        res = compacted[0].No_Risk_Compacted__c.split(',');
                    }
                }
            }
        }
        return res;
    }

    public static List<String> getCountries2Anonymize() {
        final Id userId = UserInfo.getUserId();
        List<String> res = new List<String>();
        User userInfo = [Select Access_GCE__c, DES_Country__c, Profile.Name FROM User WHERE Id=:userId LIMIT 1];
        Boolean riskUser = UserInfo.Access_GCE__c == ACCESS_GCE_RISK;
        if (String.isBlank(userInfo.DES_Country__c)) {
            res = new List<String>{'ES', 'MX', 'PE', 'CO', 'TR', 'AR', 'VN', 'VE'};
        } else {
            String userCountry = userInfo.DES_Country__c;
            List<HPG_Geography_Visibility_Configuration__c> anonym = [SELECT Risk_Anonymized__c, No_Risk_Anonymized__c FROM HPG_Geography_Visibility_Configuration__c WHERE Geography__c =: userCountry LIMIT 1];
            if (anonym.size() > 0) {
                if (riskUser) {
                    if (!String.isBlank(anonym[0].Risk_Anonymized__c)) {
                        res = anonym[0].Risk_Anonymized__c.split(',');
                    }
                } else {
                    if (!String.isBlank(anonym[0].No_Risk_Anonymized__c)) {
                        res = anonym[0].No_Risk_Anonymized__c.split(',');
                    }
                }
            }
        }
        return res;
    }

    public static Boolean userCanEdit() {
        final Id userId = UserInfo.getUserId();
        final User usr = [SELECT FederationIdentifier, Profile.Name FROM User WHERE Id = :userId LIMIT 1];
        final Map<String, HPG_VisibilityUsers__mdt> users = HPG_VisibilityUsers__mdt.getAll();
        return users.keyset().contains(usr.FederationIdentifier) || ADMIN_PROFILES.contains(usr.Profile.Name);
    }

    public static Boolean userHasPermissionSet(String permissionSetName) {
        final Id userId = UserInfo.getUserId();
        List<PermissionSetAssignment> psaList = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSet.Name = :permissionSetName LIMIT 1];
        return psaList.size() > 0;
    }

    public static HPG_Consumption.Wrapper anonymize(HPG_Consumption.Wrapper wrap) {
        List<String> countries2Anonymize = getCountries2Anonymize();
        for (HPG_Consumption.Data item : wrap.data) {
            if (countries2Anonymize.contains(item.countryId)  && !item.customerName.contains(TOTAL_CLIENTS)) {
                item.customerName = hash('MD5', item.customerName);
                item.taxpayerId = hash('MD5', item.taxpayerId);
            }
        }
        return wrap;
    }

    public static HPG_GlobalPosition.Wrapper anonymize(HPG_GlobalPosition.Wrapper wrap) {
        List<String> countries2Anonymize = getCountries2Anonymize();
        for (HPG_GlobalPosition.Data item : wrap.data) {
            if (countries2Anonymize.contains(item.countryId) && !item.customerName.contains(TOTAL_CLIENTS)) {
                item.customerName = hash('MD5', item.customerName);
                item.lei = hash('MD5', item.lei);
                item.taxpayerId = hash('MD5', item.taxpayerId);
            }
        }
        return wrap;
    }

    public static HPG_CapitalProvision.Wrapper anonymize(HPG_CapitalProvision.Wrapper wrap) {
        List<String> countries2Anonymize = getCountries2Anonymize();
        for (HPG_CapitalProvision.Data item : wrap.data) {
            if (countries2Anonymize.contains(item.countryId) && !item.customerName.contains(TOTAL_CLIENTS)) {
                item.customerName = hash('MD5', item.customerName);
                item.taxpayerId = hash('MD5', item.taxpayerId);
            }
        }
        return wrap;
    }

    public static HPG_ConnectedClients.Wrapper anonymize(HPG_ConnectedClients.Wrapper wrap) {
        List<String> countries2Anonymize = getCountries2Anonymize();
        for (HPG_ConnectedClients.Data item : wrap.data) {
            if (countries2Anonymize.contains(item.countryId) && !item.customerName.contains(TOTAL_CLIENTS)) {
                item.customerName = hash('MD5', item.customerName);
                item.taxpayerId = hash('MD5', item.taxpayerId);
            }
        }
        return wrap;
    }

    public static String hash(String algo, String input) {
        String res;
        if (!String.isBlank(input)) {
            res = input.replaceAll('[^\\s]','X');
        }
        return res;
    }

    public static String unNullValue(String value, String ko) {
        String res = value;
        if (String.isBlank(value)) {
            res = ko;
        }
        return res;
    }

    // DEPRECATED
    public static String lastDate() {
        Date currentDate = Date.newInstance(1975, 5, 5);
        Map<String, Object> request = new Map<String, Object>();
        request.put('tblMeEngineNameConcatenationDesc', 'GCE');
        HPG_UsedTables.Wrapper usedTables = HPG_UsedTables.getUsedTables(request);
        for (HPG_UsedTables.DateRangeTable dateRange : usedTables.data[0].dateRangeTables)  {
            Date compareTo = Date.valueOf(dateRange.tableDate);
            if (compareTo > currentDate) {
                currentDate = compareTo;
            }
        }
        return String.ValueOf(currentDate);
    }

    /**
    * @description Wrapper for picklist values
    */
    public class PicklistValue_Wrapper implements Comparable {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}
        public PicklistValue_Wrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
        public Integer compareTo(Object compareTo) {
            PicklistValue_Wrapper compareToPicklist = (PicklistValue_Wrapper)compareTo;
            return -value.compareTo(compareToPicklist.value);
        }
    }
}