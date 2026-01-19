/**
* ____________________________________________________________________________
* Controller class for HPG_MainTableCustom.cmp aura Component
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
public with sharing class HPG_MainTableCustomController {
    @AuraEnabled
    public static HPG_GlobalPosition.Wrapper fetchClientDataFromService(String groupCode, String page, String pageSize, List<String> countries, Date searchDate, String clientPositionsType) {
        Map<String, Object> request = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        List<String> countriesToCompact = HPG_Utils.getCountriesToCompact();
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
        payload.put('groupId', groupCode);
        payload.put('paginationKey', page);
        payload.put('pageSize', pageSize);
        payload.put('searchDate', searchDate);
        payload.put('clientPositionsType', (clientPositionsType == 'Y') ? 'Y' : '');
        request.put('payload' , JSON.serialize(payload));
        HPG_GlobalPosition.Wrapper clients = HPG_GlobalPosition.getGlobalPosition(request);
        // Transform ratingGenerationDate
        for (HPG_GlobalPosition.Data data : clients.data) {
            if (data.ratingGenerationDate != null) {
                Datetime ratingGenerationDateTime = (DateTime)JSON.deserialize('"' + data.ratingGenerationDate + '"', DateTime.class);
                Date ratingGenerationDate = date.newinstance(ratingGenerationDateTime.year(), ratingGenerationDateTime.month(), ratingGenerationDateTime.day());
                data.ratingGenerationDate = String.valueOf(ratingGenerationDate);
            }
            data.sectorAA = HPG_Utils.unNullValue(data.assetAllocationSectorType, '') + '/' + HPG_Utils.unNullValue(data.assetAllcSectorDesc, '');
            data.subSectorAA = HPG_Utils.unNullValue(data.assetAllocationSubSecType, '') + '/' + HPG_Utils.unNullValue(data.aaSubSectorDesc, '');
            data.activityAA  = HPG_Utils.unNullValue(data.assetAllocationActvyType, '') + '/' + HPG_Utils.unNullValue(data.aaActivityDesc, '');
        }
        return clients;
    }

    @AuraEnabled
    public static HPG_Consumption.Wrapper fetchConsumptionDataFromService(String groupCode, String clientPositionsType, String page, Date searchDate, String pageSize, List<String> countries) {
        Map<String, Object> request = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        List<String> countriesToCompact = HPG_Utils.getCountriesToCompact();
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
        payload.put('groupId', groupCode);
        payload.put('clientPositionsType', 'Y');
        payload.put('paginationKey', page);
        payload.put('pageSize', pageSize);
        payload.put('searchDate', searchDate);
        //try to avoid caching
        Datetime dt = Datetime.now();
        Long timestamp = dt.getTime();
        payload.put('timestamp', timestamp);
        request.put('jsonInputTemplate', JSON.serialize(payload));
        HPG_Consumption.Wrapper consumption = HPG_Consumption.getConsumption(request);
        return consumption;
    }

    @AuraEnabled
    public static HPG_ConnectedClients.Wrapper fetchConnectedClientsFromService(String groupCode, String page, Date searchDate, String pageSize, List<String> countries) {
        Map<String, Object> request = new Map<String, Object>();
        String queryString;
        // accept both accountId or group code
        //if (clientId.startsWith('001')) {
        //    queryString= 'groupId=' + HPG_Utils.getGroupId(clientId);
        //} else {
        //    queryString= 'groupId=' + clientId;
        //}
        queryString = 'groupId=' + groupCode;
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
        List<String> countriesToCompact = HPG_Utils.getCountriesToCompact();
        if (countriesToCompact.size() > 0) {
            List<Map<String,Object>> countriesTotal = new List<Map<String,Object>>();
            for (String country : countriesToCompact){
                queryString += '&countriesTotal=' + country;
            }
        }
        request.put('queryString' , queryString);
        HPG_ConnectedClients.Wrapper connected = HPG_ConnectedClients.getConnectedClients(request);
        // hardcode subgroup to -1000 as is never returned in this service.
        for (HPG_ConnectedClients.Data data : connected.data) {
            data.subGroupName = 'toplevelclients';
            data.subGroupId = '-1000';
        }
        return connected;
    }

    @AuraEnabled
    public static String getClientId(String clientId) {
        String res;
        List<Account> acc = [SELECT Name, DES_Structure_Type__c, DES_Group_Code__c  FROM Account WHERE Id =:clientId];
        if (acc.size() > 0 && acc[0].DES_Structure_Type__c == 'Group' || acc[0].DES_Structure_Type__c == 'Supragroup') {
            res = acc[0].DES_Group_Code__c;
        } else {
            List<Local_Client__c> local = [SELECT Id, Alpha_code__c, Is_Parent__c, Cib_Client__c, Cib_Client__r.DES_Main_Parent__c from Local_Client__c where Cib_Client__c  =:clientId];
            if (local.size() > 0) {
                res = local[0].Alpha_code__c;
            }
        }
        return res;
    }

    @AuraEnabled
    public static HPG_CapitalProvision.Wrapper fetchCaProvisionDataFromService(String groupCode, String page, String pageSize, List<String> countries, Date searchDate, String clientPositionsType) {
        Map<String, Object> request = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        List<String> countriesToCompact = HPG_Utils.getCountriesToCompact();
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
        payload.put('groupId', groupCode);
        payload.put('paginationKey', page);
        payload.put('pageSize', pageSize);
        payload.put('searchDate', searchDate);
        payload.put('clientPositionsType',  (clientPositionsType == 'Y') ? 'Y' : '');
        request.put('payload' , JSON.serialize(payload));
        HPG_CapitalProvision.Wrapper capitalProvision = HPG_CapitalProvision.getCapitalProvision(request);
        return capitalProvision;
    }

    @AuraEnabled
    public static HPG_UsedTables.Wrapper fetchUsedTablesDataFromService(Date searchDate, String pageSize, String page) {
        Map<String, Object> request = new Map<String, Object>();
        String paginationKey = '1';
        if (page != null) {
            paginationKey = page;
        }
        request.put('tblMeEngineNameConcatenationDesc', 'GCE');
        request.put('searchDate', searchDate);
        request.put('pageSize', pageSize);
        request.put('paginationKey', paginationKey);
        HPG_UsedTables.Wrapper usedTables = HPG_UsedTables.getUsedTables(request);
        return usedTables;
    }

    @AuraEnabled
    public static HPG_OverrideConsumption.Wrapper fetchOverrideConsumptionDataFromService(String groupCode, String page, String pageSize) {
        Map<String, Object> request = new Map<String, Object>();
        String queryString;
        queryString = 'paginationKey=' + page;
        queryString += '&pageSize=' + pageSize;
        queryString += '&groupId=' + groupCode;
        request.put('queryString' , queryString);
        HPG_OverrideConsumption.Wrapper overrideConsumption = HPG_OverrideConsumption.callOverrideConsumption('HPG_GetOverrideConsumption', request);
        return overrideConsumption;
    }

    @AuraEnabled
    public static String userIsAdmin() {
       return String.valueOf(HPG_Utils.userCanEdit());
    }

    @AuraEnabled
    public static List<String> getAllGroups() {
       return new List<String>();
    }

    @AuraEnabled(cacheable = true)
    public static Object fetchInitialData(String selectedTab, String groupCode, List<String> lCountries, String searchDate, String clientPositionsType, String page, String pageSize) {
        Object res;
        final Date dateFrom = Date.valueOf(searchDate);
        final List<String> countries = new List<String>();
        switch on selectedTab {
            when 'consumption' {
                res = new HPG_Consumption.Wrapper();
                res = fetchConsumptionDataFromService(groupCode, clientPositionsType, page, dateFrom, pageSize, countries);
           }
            when 'capitalProvision'{
                res = new HPG_GlobalPosition.Wrapper();
                res = fetchClientDataFromService(groupCode, page, pageSize, countries, dateFrom, clientPositionsType);
            }
            when 'connectedClients'{
                res = new HPG_GlobalPosition.Wrapper();
                res = fetchClientDataFromService(groupCode, page, pageSize, countries, dateFrom, clientPositionsType);
            }
            when 'dataReport' {
                res = new HPG_GlobalPosition.Wrapper();
                res = fetchClientDataFromService(groupCode, page, pageSize, countries, dateFrom, clientPositionsType);
            }
            when else {
                res = new HPG_GlobalPosition.Wrapper();
                res = fetchClientDataFromService(groupCode, page, pageSize, countries, dateFrom, clientPositionsType);
            }
        }
        return res;
    }

    @AuraEnabled
    public static Object fetchData(String selectedTab, String groupCode, List<String> lCountries, String searchDate, String clientPositionsType, String page, String pageSize) {
        Object res = fetchInitialData(selectedTab, groupCode, lCountries, searchDate, clientPositionsType, page, pageSize);
        return res;
    }
}