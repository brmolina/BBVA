/**
* ____________________________________________________________________________
* Controller class for HPG Lightning Web Components
* ____________________________________________________________________________
* @author      ivan.garces.contractor@bbva.com
* @modifiedBy
* @version     1.0
* @created     2023-05-29
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class HPG_SecondaryTablesController {
    @AuraEnabled(cacheable = true)
    public static HPG_ConsumptionSummary.Wrapper getConsumptionSummary(String clientType, String clientId, String page, String pageSize, Date searchDate, String countryTotal, String timestamp) {
        HPG_ConsumptionSummary.Wrapper clients;
        try {
            Map<String, Object> request = new Map<String, Object>();
            String queryString;
            switch on clientType{
                when 'group'{
                    queryString = '?groupId=' + clientId;
                }
                when 'subgroup'{
                    queryString = '?subGroupId=' + clientId;
                }
                when 'level3group'{
                    queryString = '?level3groupId=' + clientId;
                }
                when else {
                    queryString = '?customerId=' + clientId;
                }
            }
            queryString += '&pageSize=' + pageSize;
            queryString += '&paginationKey=' + page;
            queryString += '&searchDate=' + String.valueOf(searchDate).substring(0, 10);
            queryString += '&timestamp=' +  timestamp;
            request.put('queryString' , queryString);
            clients = HPG_ConsumptionSummary.getConsumptionSummary(request);
        } catch (Exception e) { //NOSONAR
           System.debug(e.getMessage());//NOSONAR
           throw new AuraHandledException(e.getMessage());//NOSONAR
        }
        return clients;
    }
    @AuraEnabled(cacheable = true)
    public static HPG_ConsumptionDetail.Wrapper getConsumptionDetail(String clientType, String clientId, String page, String pageSize, List<String> countries, Date searchDate, String filter, String timestamp) {
        Map<String, Object> request = new Map<String, Object>();
        String queryString;
        switch on clientType{
            when 'group'{
                queryString = 'groupId=' + clientId;
            }
            when 'subgroup'{
                queryString = 'subGroupId=' + clientId;
            }
            when 'level3group'{
                queryString = 'level3groupId=' + clientId;
            }
            when else {
                queryString = 'customerId=' + clientId;
            }
        }
        queryString += '&paginationKey=' + page;
        queryString += '&pageSize=' + pageSize;
        queryString += '&searchDate=' + String.valueOf(searchDate).substring(0, 10);
        if (!String.isEmpty(filter)) {
            queryString += '&classConsumptions=' + filter;
        }
        for (String country : countries) {
            if (!String.isBlank(country)) {
                queryString += '&countries=' + country;
            }
        }
        queryString += '&timestamp=' + timestamp;
        request.put('queryString' , queryString);
        HPG_ConsumptionDetail.Wrapper detail = HPG_ConsumptionDetail.getConsumptionDetail(request);
        return detail;
    }
    @AuraEnabled(cacheable = true)
    public static HPG_ConsumptionDetail.Wrapper validateOverrideConsumption(HPG_ConsumptionDetail.Wrapper data, String clientId) {
        Map<String, Object> request = new Map<String, Object>();
        String queryString;
        queryString = 'paginationKey=1';
        queryString += '&pageSize=5000';
        queryString += '&groupId=' + clientId;
        request.put('queryString' , queryString);
        HPG_OverrideConsumption.Wrapper overrideConsumptionWrapper = HPG_OverrideConsumption.callOverrideConsumption('HPG_GetOverrideConsumption', request);
        Set<String> overrideConsumptionKeys = new Set<String>();
        Map<String,String> overrideConsumptionMap = new Map<String,String>();
        for (HPG_OverrideConsumption.Data overrideConsumption : overrideConsumptionWrapper.data) {
            overrideConsumptionKeys.add(overrideConsumption.customerId + overrideConsumption.internalContractCodeDesc);
            overrideConsumptionMap.put(overrideConsumption.customerId + overrideConsumption.internalContractCodeDesc, overrideConsumption.overrideComments);
        }
        for (HPG_ConsumptionDetail.DetailConsumption consumptionDetail : data.data[0].detailConsumptions) {
            if (consumptionDetail.currentExpirationDate < consumptionDetail.cutoffDate) {
                consumptionDetail.consumptionExpired = true;
                consumptionDetail.overrideAction = 'EXPIRED';
                    consumptionDetail.overrideIcon = 'utility:expired';
                    consumptionDetail.overrideTitle = 'Expired Operation';
            } else {
                consumptionDetail.consumptionExpired = false;
                if (overrideConsumptionKeys.contains(data.data[0].customerId + consumptionDetail.internalContractCodeDesc)) {
                    consumptionDetail.overrideAction = 'EDIT';
                    consumptionDetail.overrideIcon = 'utility:edit';
                    consumptionDetail.overrideTitle = 'Edit Override';
                    consumptionDetail.overrideComments = overrideConsumptionMap.get(data.data[0].customerId + consumptionDetail.internalContractCodeDesc);
                } else {
                    consumptionDetail.overrideAction = 'CONTRACT';
                    consumptionDetail.overrideIcon = 'utility:add';
                    consumptionDetail.overrideTitle = 'Add Override';
                }
            }
        }
        return data;
    }
    @AuraEnabled(cacheable = true)
    public static HPG_CapitalProvisionDetail.Wrapper getDetailCapitalProvision(String clientType, String clientId, String page, String pageSize, List<String> countries, Date searchDate) {
        Map<String, Object> request = new Map<String, Object>();
        String queryString;
        switch on clientType{
            when 'group'{
                queryString = 'groupId=' + clientId;
            }
            when 'subgroup'{
                queryString = 'subGroupId=' + clientId;
            }
            when 'level3group'{
                queryString = 'level3groupId=' + clientId;
            }
            when else {
                queryString = 'customerId=' + clientId;
            }
        }
        queryString += '&paginationKey=' + page;
        queryString += '&pageSize=' + pageSize;
        queryString += '&searchDate=' + String.valueOf(searchDate).substring(0, 10);
        for (String country : countries) {
            if (!String.isBlank(country)) {
                queryString += '&countries=' + country;
            }
        }
        request.put('queryString' , queryString);
        HPG_CapitalProvisionDetail.Wrapper detail = HPG_CapitalProvisionDetail.getDetailCapitalProvision(request);
        return detail;
    }
    @AuraEnabled(cacheable = true)
    public static HPG_IssuerRisk.Wrapper getIssuerRisk(String clientType, String clientId, String page, String pageSize, List<String> countries, Date searchDate) {
        Map<String, Object> request = new Map<String, Object>();
        String queryString;
        switch on clientType{
            when 'group'{
                queryString = 'groupId=' + clientId;
            }
            when 'subgroup'{
                queryString = 'subGroupId=' + clientId;
            }
            when 'level3group'{
                 queryString = 'level3groupId=' + clientId;
            }
            when else {
                 queryString = 'customerId=' + clientId;
            }
        }
        queryString += '&paginationKey=' + page;
        queryString += '&pageSize=' + pageSize;
        queryString += '&searchDate=' + String.valueOf(searchDate).substring(0, 10);
        for (String country : countries) {
            if (!String.isBlank(country)) {
                queryString += '&countries=' + country;
            }
        }
        request.put('queryString' , queryString);
        HPG_IssuerRisk.Wrapper risk = HPG_IssuerRisk.getIssuerRisk(request);
        return risk;
    }
    @AuraEnabled(cacheable = true)
    public static HPG_Derivatives.Wrapper getDerivativesData(String clientType, String clientId, String page, String pageSize, List<String> countries, Date searchDate, Boolean grouped) {
        Map<String, Object> request = new Map<String, Object>();
        Map<String, Object> jsonInputTemplate = new Map<String, Object>();
        switch on clientType{
            when 'group'{
                jsonInputTemplate.put('groupId', clientId);
            }
            when 'subgroup'{
                jsonInputTemplate.put('subGroupId', clientId);
            }
            when 'level3group'{
		 jsonInputTemplate.put('level3groupId', clientId);
            }
            when else {
                jsonInputTemplate.put('customerId', clientId);
            }
        }
        jsonInputTemplate.put('paginationKey', page);
        jsonInputTemplate.put('pageSize', pageSize);
        jsonInputTemplate.put('searchDate', searchDate);
        jsonInputTemplate.put('groupedDataIndicator', (grouped) ? 'Y' : 'N');
        if (countries.size() > 0) {
            List<Map<String,Object>> countriesToSend = new List<Map<String,Object>>();
            for(String country : countries){
                if(!String.isBlank(countries[0])){
                    countriesToSend.add(new Map<String,Object>{'countryId' => country});
                }
            }
            jsonInputTemplate.put('countries', countriesToSend);
        }
        request.put('jsonInputTemplate' , JSON.serialize(jsonInputTemplate));
        HPG_Derivatives.Wrapper clients = HPG_Derivatives.getDerivativesData(request);
        return clients;
    }

    @AuraEnabled(cacheable = true)
    public static HPG_CurrentLimits.Wrapper getCurrentLimits(String clientId, String clientType, Date searchDate) {
        HPG_CurrentLimits.Wrapper limits;
        try {
            Map<String, Object> request = new Map<String, Object>();
            String queryString;
            switch on clientType{
                when 'group'{
                    queryString = 'groupId=' + clientId;
                }
                when else {
                    queryString = 'customerId=' + clientId;
                }
            }
            queryString += '&searchDate=' + String.valueOf(searchDate).substring(0, 10);
            //queryString += '&timestamp=' +  timestamp;
            request.put('queryString' , queryString);
            limits = HPG_CurrentLimits.getCurrentLimits(request);
        } catch (Exception e) { //NOSONAR
           System.debug(e.getMessage());//NOSONAR
           throw new AuraHandledException(e.getMessage());//NOSONAR
        }
        return limits;
    }

    @AuraEnabled(cacheable = true)
    public static HPG_ContractGuarantees.Wrapper getContractGuarantees(String contractId, Date searchDate, String page, String pageSize) {
        HPG_ContractGuarantees.Wrapper guarantees;
        try {
            Map<String, Object> request = new Map<String, Object>();
            String queryString = 'internalContractCodeDesc=' + contractId + '&searchDate=' + String.valueOf(searchDate).substring(0, 10);
            queryString += '&page=' + page + '&pageSize=' + pageSize;
            //queryString += '&timestamp=' +  timestamp;
            request.put('queryString' , queryString);
            guarantees = HPG_ContractGuarantees.getContractGuarantees(request);
        } catch (Exception e) { //NOSONAR
           System.debug(e.getMessage());//NOSONAR
           throw new AuraHandledException(e.getMessage());//NOSONAR
        }
        return guarantees;
    }

    @AuraEnabled(cacheable = true)
    public static HPG_Currency.Wrapper getCurrencies(String baseCurrency) {
        HPG_Currency.Wrapper currencies = HPG_Currency.getCurrencies(baseCurrency);
        return currencies;
    }
}