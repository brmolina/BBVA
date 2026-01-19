/**
------------------------------------------------------------------------------------------------
@Name     KPI_searchController
@Author   ivan.garces.contractor@bbva.com
@Date     Created: 2023-01-19
------------------------------------------------------------------------------------------------
@Description Controller class for KPI_search component
------------------------------------------------------------------------------------------------
@Changes
|2023-02-15 ivan.garces.contractor@bbva.com
            Class Creation
-----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods, PMD.ExcessiveParameterList, sf:NPathComplexity, PMD.ApexCRUDViolation, PMD.NcssTypeCount, PMD.EmptyStatementBlock, PMD.NcssMethodCount, PMD.AvoidDeeplyNestedIfStmts, PMD.StdCyclomaticComplexity, PMD.ApexSOQLInjection, PMD.FormalParameterNamingConventions, PMD.ExcessiveClassLength , PMD.ExcessivePublicCount, PMD.AvoidGlobalModifier, PMD.UnusedLocalVariable, PMD.ApexAssertionsShouldIncludeMessage, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
public with sharing class KPI_searchController {
    /**
    @description Method that returns a catalog (from a service call)
    @param catalogType KPI_TYPE, CRITERIA_NAME, BUSINESS_AREA, INDUSTRY_GROUP, INDUSTRY_ACTIVITY
    @return Map<String, Object> {success, options [{id, name}]}
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getKPICatalog(String catalogId, List<String> opSelected) {
        Map<string, Object> res = new Map<string, Object>{ 'success' => false };
        Map<String, Object> request = new Map<String, Object>{ 'catalogId' => catalogId };
        String serviceName = 'KPI_getCatalogIdRecords';
        if (catalogId == 'INDUSTRY_GROUP' && opSelected.size() > 0) {
            String firstGroup = opSelected[0];
            if (firstGroup.substring(0, 3) == 'a4f') {
                opSelected.set(0, getgroupCode(firstGroup));
            }
        }

        try {
            HttpResponse response = KPI_Utils.callService(serviceName, request);
            if (new List<Integer>{ 200, 201 }.contains(response.getStatusCode())) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                Map<String, Map<String, Object>> options = new Map<String, Map<String, Object>>();
                List<Map<String, Object>> selected = new List<Map<String, Object>>();

                List<Object> responseData = (List<Object>) responseMap.get('data');

                for (Object objData : responseData) {
                    Map<String, Object> data = (Map<String, Object>) objData;
                    Map<String, Object> option;

                    option = new Map<String, Object>{ 'value' => data.get('id'), 'label' => data.get('description') };
                    if (opSelected.contains((String) data.get('id'))) {
                        option.put('selected', true);
                        Map<String, Object> sel = new Map<String, Object>{ 'id' => data.get('id'), 'name' => data.get('description') };
                        selected.add(sel);
                    }

                    options.put((String) data.get('description'), option);
                }

                res.put('success', true);
                res.put('options', options.values());
                res.put('selected', selected);
            }
        } catch (Exception e) {
            res.put('errorMessage', e.getMessage());
        }

        return res;
    }

    /**
    @description Method that returns a catalog (from a service call)
    @param catalogType KPI_TYPE, CRITERIA_NAME, BUSINESS_AREA, INDUSTRY_GROUP, INDUSTRY_ACTIVITY
    @return Map<String, Object> {success, options [{id, name}]}
    */
    @AuraEnabled(cacheable=true)
    public static KPI_FinantialCustomers_Wrapper getClients(List<String> businessArea, List<String> sector, List<String> bookingCountry, List<String> KPICatalog, List<String> clients, List<String> product, List<String> groupsId, String toolkitId) {
        String queryString = '?';

        //Business Area
        for (String ba : businessArea) {
            queryString += 'businessArea=' + ba + '&';
        }

        //Sector
        for (String sec : sector) {
            queryString += 'industryGroup=' + sec + '&';
        }

        //KPI catalog
        for (String cat : KPICatalog) {
            queryString += 'kpiCatalog=' + cat + '&';
        }

        //Booking Country
        for (String bok : bookingCountry) {
            queryString += 'client.country.id=' + bok + '&';
        }

        //Group
        for (String groupIdElem : groupsId) {
            if (groupIdElem.startsWith('a4f')) {
                queryString += 'client.group.id=' + getgroupCode(groupIdElem) + '&';
            } else {
                queryString += 'client.group.id=' + groupIdElem + '&';
            }
        }

        //Client Code
        for (String clientElem : clients) {
            queryString += 'code=' + clientElem + '&';
        }

        queryString += 'contracts.sustainabilityFamily.id=RBES&contracts.sustainabilityFamily.id=CIBS&';
        queryString += 'pageSize=2000&';
        queryString += 'paginationKey=1&';
        Map<String, Object> request = new Map<String, Object>{ 'queryString' => queryString };
        return KPI_FinantialCustomers.getFinantialCustomers(request);
    }

    /**
    @description Method that returns a query with the group code
    @param clientsIds : toolkit Id to search
    @return String
    */
    public static String getgroupCode(String groupId) {
        system.debug([SELECT cstk__account_id__r.DES_Group_Code__c FROM cstk__Toolkit__c WHERE Id = :groupId][0].cstk__account_id__r.DES_Group_Code__c);
        return [SELECT cstk__account_id__r.DES_Group_Code__c FROM cstk__Toolkit__c WHERE Id = :groupId][0].cstk__account_id__r.DES_Group_Code__c;
    }

    /**
    @description Method that returns a query the name of the user permission set assigment for businessArea
    @return String
    */
    @AuraEnabled
    public static String getUserBAPermissionSet() {
        List<PermissionSet> permissionSetsAsigned = [SELECT Name FROM PermissionSet WHERE Id IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId())];
        String businesAreaPS;
        for (PermissionSet perm : permissionSetsAsigned) {
            if (perm.Name.contains('KPI_Business_Area'))
                businesAreaPS = perm.name;
        }
        switch on businesAreaPS {
            when 'KPI_Business_Area_GM' {
                return 'GLOBAL MARKETS';
            }
            when 'KPI_Business_Area_GTB' {
                return 'GLOBAL TRANSACTIONAL BANKING';
            }
            when else {
                return 'NoBAPermissionSet';
            }
        }
    }
    /**
    @description Method that returns a query the name of the user permission set assigment for businessArea
    @return String
    */
    @AuraEnabled
    public static List<Map<String, String>> getTransactionalBankers(List<String> groups) {
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get('User');
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> fields = objDescribeSobject.fields.getMap();
        Schema.DescribeFieldResult fieldResult;
        if (fields.get('DES_Country__c') != null) {
            fieldResult = fields.get('DES_Country__c').getDescribe();
        } else if (fields.get('cstk__DES_Country__c') != null) {
            fieldResult = fields.get('cstk__DES_Country__c').getDescribe();
        }
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Map<String, String>> listOfMapToReturn = new List<Map<String, String>>();

        Map<String, String> countryMap = new Map<String, String>();
        for (Schema.PicklistEntry pickListVal : ple) {
            countryMap.put(pickListVal.getValue(), pickListVal.getLabel());
        }
        Map<String, String> mapToRet = new Map<String, String>();
        for (DES_BBVA_Management_team__c transbanker : [SELECT id, DES_Member_Role__c, DES_Client__r.DES_Group_Code__c, DES_Client__c, DES_Client__r.Name, DES_User_Country__c, DES_User__c, DES_USER__r.Name, DES_USER__r.EMPLOYEE_DEPARTMENT_DESC__c FROM DES_BBVA_Management_team__c WHERE DES_Member_Role__c = 'Transaction Banker' AND DES_Client__r.DES_Group_Code__c IN :groups]) {
            if (transbanker.DES_USER__r.Name != null && transbanker.DES_Client__r.Name != null) {
                mapToRet = new Map<String, String>();
                mapToRet.put('groupCode', transbanker.DES_Client__r.DES_Group_Code__c);
                mapToRet.put('userName', transbanker.DES_USER__r.Name);
                mapToRet.put('country', countryMap.get(transbanker.DES_User_Country__c));
                mapToRet.put('countryCode', transbanker.DES_User_Country__c);
                listOfMapToReturn.add(mapToRet);
            }
        }
        listOfMapToReturn.add(mapToRet);
        return listOfMapToReturn;
    }
}