/**
* ____________________________________________________________________________
* Controller class for hpg_main_table lightning web component
* ____________________________________________________________________________
* @author      torcuato.tejada.contractor@bbva.com
* @modifiedBy
* @version     1.0
* @created     2023-09-08
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class DMT_HPG_MainTableCustomController {

    @AuraEnabled
    public static DMT_HPG_GlobalPosition.Wrapper fetchClientDataFromService(Id clientId, String page, String pageSize, List<String> countries, Date searchDate, String clientPositionsType, String customerId) {
        DMT_HPG_GlobalPosition.Wrapper clients = new DMT_HPG_GlobalPosition.Wrapper();
        Map<String, Object> request = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        List<String> countriesToCompact = DMT_HPG_Utils.getCountriesToCompact();
        if (countries != null && countries.size() > 0 ) {
            List<Map<String,Object>> countriesToSend = new List<Map<String,Object>>();
            for(String country : countries){
                if(String.isNotBlank(countries[0])){
                    countriesToSend.add(new Map<String,Object>{'countryId' => country});
                }
            }
            if(!countriesToSend.isEmpty()){
                payload.put('countries', countriesToSend);
            }
        }
        if (countriesToCompact != null && countriesToCompact.size() > 0 ) {
            List<Map<String,Object>> countriesTotal = new List<Map<String,Object>>();
            for (String country : countriesToCompact){
                countriesTotal.add(new Map<String,Object>{'countryId' => country});
            }
            payload.put('countriesTotal', countriesTotal);
        }
        if(clientId != null && String.isNotBlank(String.valueOf(clientId))){
            payload.put('groupId', DMT_HPG_Utils.getGroupId(clientId));
        }
        else if(String.isNotBlank(customerId)){
            String customerIdPayLoad = DMT_HPG_Utils.getAlphaCode(customerId);

            if(customerIdPayLoad == null){
                System.debug('ABS TEST customerId');
                List<Account> acc = [SELECT Id,DES_Group_Code__c FROM Account WHERE Id =:customerId WITH SECURITY_ENFORCED];
                if(!acc.isEmpty() && acc[0].DES_Group_Code__c =='GXXXXXXXXXXXXXX' ){
                    customerIdPayLoad =  'ES0182XXXXXXXXX' ;
                }
            }
            payload.put('customerId', customerIdPayLoad);
        }

        payload.put('clientDataOption', 'D');
        payload.put('paginationKey', page);
        payload.put('pageSize', pageSize);
        payload.put('searchDate', searchDate);
        payload.put('clientPositionsType', (clientPositionsType == 'Y') ? 'Y' : '');
        request.put('payload' , JSON.serialize(payload));
        System.debug('Request Test: ' + request);
        clients = DMT_HPG_GlobalPosition.getGlobalPosition(request);
        System.debug('Response Test: ' + clients);
        // Transform ratingGenerationDate
        if (clients != null && clients.data != null) {
            for (DMT_HPG_GlobalPosition.Data data : clients.data) {
                if (data.ratingGenerationDate != null) {
                    Datetime ratingGenerationDateTime = (DateTime)JSON.deserialize('"' + data.ratingGenerationDate + '"', DateTime.class);
                    Date ratingGenerationDate = date.newinstance(ratingGenerationDateTime.year(), ratingGenerationDateTime.month(), ratingGenerationDateTime.day());
                    data.ratingGenerationDate = String.valueOf(ratingGenerationDate);
                }
                data.sectorAA = DMT_HPG_Utils.unNullValue(data.assetAllocationSectorType, '') + '/' + DMT_HPG_Utils.unNullValue(data.assetAllcSectorDesc, '');
                data.subSectorAA = DMT_HPG_Utils.unNullValue(data.assetAllocationSubSecType, '') + '/' + DMT_HPG_Utils.unNullValue(data.aaSubSectorDesc, '');
                data.activityAA  = DMT_HPG_Utils.unNullValue(data.assetAllocationActvyType, '') + '/' + DMT_HPG_Utils.unNullValue(data.aaActivityDesc, '');
                //data.priority = 'Jimmy';
            }
        }
        return clients;
    }

    @AuraEnabled
    public static DMT_HPG_Consumption.Wrapper fetchConsumptionDataFromService(String clientId, String clientPositionsType, String page, Date searchDate, String pageSize, List<String> countries) {
        Map<String, Object> request = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        List<String> countriesToCompact = DMT_HPG_Utils.getCountriesToCompact();
        if (countries.size() > 0) {
            List<Map<String,Object>> countriesToSend = new List<Map<String,Object>>();
            for(String country : countries){
                if(!String.isBlank(countries[0])){
                    countriesToSend.add(new Map<String,Object>{'countryId' => country});
                }
            }
            payload.put('countries', countriesToSend);
        }
        if (countriesToCompact.size() > 0) {
            List<Map<String,Object>> countriesTotal = new List<Map<String,Object>>();
            for (String country : countriesToCompact){
                countriesTotal.add(new Map<String,Object>{'countryId' => country});
            }
            payload.put('countriesTotal', countriesTotal);
        }
        payload.put('groupId', DMT_HPG_Utils.getGroupId(clientId));
        payload.put('clientPositionsType', 'Y');
        payload.put('paginationKey', page);
        payload.put('pageSize', pageSize);
        payload.put('searchDate', searchDate);
        //try to avoid caching
        Datetime dt = Datetime.now();
        Long timestamp = dt.getTime();
        payload.put('timestamp', timestamp);
        request.put('jsonInputTemplate', JSON.serialize(payload));
        DMT_HPG_Consumption.Wrapper consumption = DMT_HPG_Consumption.getConsumption(request);
        return consumption;
    }

    @AuraEnabled
    public static DMT_HPG_ConnectedClients.Wrapper fetchConnectedClientsFromService(String clientId, String page, Date searchDate, String pageSize, List<String> countries) {

        Map<String, Object> request = new Map<String, Object>();
        String queryString;
        // accept both accountId or group code
        if (clientId.startsWith('001')) {
            queryString= 'groupId=' + DMT_HPG_Utils.getGroupId(clientId);
        } else {
            queryString= 'groupId=' + clientId;
        }
        queryString += '&pageSize=' + pageSize;
        queryString += '&paginationKey=' + page;
        queryString += '&searchDate=' + String.valueOf(searchDate).substring(0, 10);
        if (countries.size() > 0) {
            for (String country : countries) {
                if (!String.isBlank(country)) {
                    queryString += '&countries=' + country;
                }
            }
        }
        List<String> countriesToCompact = DMT_HPG_Utils.getCountriesToCompact();
        if (countriesToCompact.size() > 0) {
            List<Map<String,Object>> countriesTotal = new List<Map<String,Object>>();
            for (String country : countriesToCompact){
                queryString += '&countriesTotal=' + country;
            }
        }
        request.put('queryString' , queryString);
        DMT_HPG_ConnectedClients.Wrapper connected = DMT_HPG_ConnectedClients.getConnectedClients(request);
        // hardcode subgroup to -1000 as is never returned in this service.
        for (DMT_HPG_ConnectedClients.Data data : connected.data) {
            data.subGroupName = 'toplevelclients';
            data.subGroupId = '-1000';
        }
        return connected;
    }

    @AuraEnabled
    public static String getClientId(String clientId) {
        String res;
        List<Account> acc = [SELECT Name, DES_Structure_Type__c, DES_Group_Code__c  FROM Account WHERE Id =:clientId WITH SECURITY_ENFORCED];
        if (acc.size() > 0 && acc[0].DES_Structure_Type__c == 'Group' || acc[0].DES_Structure_Type__c == 'Supragroup') {
            res = acc[0].DES_Group_Code__c;
        } else {
            List<Local_Client__c> local = [SELECT Id, Alpha_code__c, Is_Parent__c, Cib_Client__c, Cib_Client__r.DES_Main_Parent__c from Local_Client__c where Cib_Client__c  =:clientId WITH SECURITY_ENFORCED];
            if (local.size() > 0) {
                res = local[0].Alpha_code__c;
            }
        }
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static string getRecordCode(String clientId) {
        return DMT_HPG_Utils.getRecordCode(clientId);
    }

    @AuraEnabled
    public static DMT_HPG_CapitalProvision.Wrapper fetchCaProvisionDataFromService(Id clientId, String page, String pageSize, List<String> countries, Date searchDate, String clientPositionsType) {
        Map<String, Object> request = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        List<String> countriesToCompact = DMT_HPG_Utils.getCountriesToCompact();
        if (countries.size() > 0) {
            List<Map<String,Object>> countriesToSend = new List<Map<String,Object>>();
            for(String country : countries){
                if(!String.isBlank(countries[0])){
                    countriesToSend.add(new Map<String,Object>{'countryId' => country});
                }
            }
            payload.put('countries', countriesToSend);
        }
        if (countriesToCompact.size() > 0) {
            List<Map<String,Object>> countriesTotal = new List<Map<String,Object>>();
            for (String country : countriesToCompact){
                countriesTotal.add(new Map<String,Object>{'countryId' => country});
            }
            payload.put('countriesTotal', countriesTotal);
        }
        payload.put('groupId', DMT_HPG_Utils.getGroupId(clientId));
        payload.put('paginationKey', page);
        payload.put('pageSize', pageSize);
        payload.put('searchDate', searchDate);
        payload.put('clientPositionsType',  (clientPositionsType == 'Y') ? 'Y' : '');
        request.put('payload' , JSON.serialize(payload));
        DMT_HPG_CapitalProvision.Wrapper capitalProvision = DMT_HPG_CapitalProvision.getCapitalProvision(request);
        return capitalProvision;
    }

    @AuraEnabled
    public static DMT_HPG_UsedTables.Wrapper fetchUsedTablesDataFromService(Date searchDate, String pageSize, String page) {
        Map<String, Object> request = new Map<String, Object>();
        String paginationKey = '1';
        if (page != null) {
            paginationKey = page;
        }
        request.put('tblMeEngineNameConcatenationDesc', 'GCE');
        request.put('searchDate', searchDate);
        request.put('pageSize', pageSize);
        request.put('paginationKey', paginationKey);
        DMT_HPG_UsedTables.Wrapper usedTables = DMT_HPG_UsedTables.getUsedTables(request);
        return usedTables;
    }

    @AuraEnabled
    public static String userIsAdmin() {
       return String.valueOf(DMT_HPG_Utils.userCanEdit());
    }

    @AuraEnabled
    public static List<String> getAllGroups() {
       return new List<String>();
    }

    @AuraEnabled(cacheable = true)
    public static Object fetchInitialData(String selectedTab, Id clientId, List<String> lCountries, String searchDate, String clientPositionsType, String page, String pageSize, String customerId) {
        Object res;
        final Date dateFrom = Date.valueOf(searchDate);
        final List<String> countries = new List<String>();
        switch on selectedTab {
            when 'consumption' {
                res = new DMT_HPG_Consumption.Wrapper();
                res = fetchConsumptionDataFromService(clientId, clientPositionsType, page, dateFrom, pageSize, countries);
           }
            when 'capitalProvision'{
                res = new DMT_HPG_GlobalPosition.Wrapper();
                res = fetchClientDataFromService(clientId, page, pageSize, countries, dateFrom, clientPositionsType, customerId);
            }
            when 'connectedClients'{
                res = new DMT_HPG_GlobalPosition.Wrapper();
                res = fetchClientDataFromService(clientId, page, pageSize, countries, dateFrom, clientPositionsType, customerId);
            }
            when 'dataReport' {
                res = new DMT_HPG_GlobalPosition.Wrapper();
                res = fetchClientDataFromService(clientId, page, pageSize, countries, dateFrom, clientPositionsType, customerId);
            }
            when 'passport' {
                res = new DMT_HPG_GlobalPosition.Wrapper();
                res = fetchClientDataFromService(clientId, page, pageSize, countries, dateFrom, clientPositionsType, customerId);
            }
            when else {
                res = new DMT_HPG_GlobalPosition.Wrapper();
                res = fetchClientDataFromService(clientId, page, pageSize, countries, dateFrom, clientPositionsType, customerId);
            }
        }
        return res;
    }

    @AuraEnabled
    public static Object fetchData(String selectedTab, Id clientId, List<String> lCountries, String searchDate, String clientPositionsType, String page, String pageSize, String customerId) {
        Object res = fetchInitialData(selectedTab, clientId, lCountries, searchDate, clientPositionsType, page, pageSize, customerId);
        return res;
    }

    @AuraEnabled
    public static Id getAccountIdFromRecordId(Id recordId) {
        if (recordId == null) {
            return null;
        }

        String sobjectType = recordId.getSObjectType().getDescribe().getName();

        if (sobjectType == 'Account') {
            return recordId;
        } else if (sobjectType == 'Opportunity') {
            Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :recordId];
            return opp.AccountId;
        } else if (sobjectType == 'DMT_Line__c') {
            // Assuming the object type is "Line" and it has a lookup field to Account
            DMT_Line__c line = [SELECT Client__c FROM DMT_Line__c WHERE Id = :recordId];
            return line.Client__c;
        }

        return null;
    }

}