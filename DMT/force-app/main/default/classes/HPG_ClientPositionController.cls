/**
* ────────────────────────────────────────────────────────────────────
* Client Position App Controller
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
public with sharing class HPG_ClientPositionController {
    static final String DMT_ACCESS_PERMISSION_SET = 'DMT_Access';
    /**
    * @description get tri data
    * @param clientId - : clientId
    * @return tri data string
    */
    @AuraEnabled
    public static String getTriData(String clientId) {
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
    * @description Get user permissions
    * @return retMap with user permissions
    */
    @AuraEnabled
    public static Map<String,Object> getUserPermissions() {
        Map<String, Object> retMap = new Map<String, Object>();
        retMap.put('isAdmin', HPG_Utils.userCanEdit());
        retMap.put('isDMTUser', HPG_Utils.userHasPermissionSet(DMT_ACCESS_PERMISSION_SET));
        return retMap;
    }
    /**
    * @description Get Customer Picklist
    * @param clientId - : clientId
    * @param countriesUser - : List of countries to filter
    * @param page - : page
    * @param pageSize - : pageSize
    * @return retMap initial data
    */
    @AuraEnabled
    public static Map<String,Object> fetchCustomerDataFromService(String clientId, List<String> countriesUser, String page, String pageSize) {
        Map<String, Object> retMap = new Map<String, Object>();
        List<HPG_Utils.PicklistValue_Wrapper> customerIdPicklist = new List<HPG_Utils.PicklistValue_Wrapper>();
        Map<String, Object> request = new Map<String, Object>();
        Map<String, Object> payload = new Map<String, Object>();
        List<String> countries = new List<String>();
        payload.put('groupId', clientId);
        if (countriesUser.size() == 0) {
            countries = getCountriesUser();
        }else {
            countries = countriesUser;
        }
        if (countries.size() > 0) {
            List<Map<String,Object>> countriesToSend = new List<Map<String,Object>>();
            for(String country : countries){
                if(!String.isBlank(countries[0])){
                    countriesToSend.add(new Map<String,Object>{'countryId' => country});
                }
            }
            payload.put('countries', countriesToSend);
        }
        payload.put('paginationKey', page);
        payload.put('pageSize', pageSize);
        payload.put('clientPositionsType', 'L');
        request.put('payload' , JSON.serialize(payload));
        HPG_GlobalPosition.Wrapper clients = HPG_GlobalPosition.getGlobalPosition(request);
        for (HPG_GlobalPosition.Data client : clients.data)  {
            customerIdPicklist.add(new HPG_Utils.PicklistValue_Wrapper(client.customerId + ' - ' + client.customerName, client.customerId));
        }
        if(customerIdPicklist.size() == 0) {
            retMap.put('errorMessage', 'This group has no subsidiaries');
            retMap.put('success', false);
        }else {
            retMap.put('customerIdPicklist', customerIdPicklist);
            retMap.put('page', clients.pagination.page);
            retMap.put('pageSize', clients.pagination.pageSize);
            retMap.put('totalPages', clients.pagination.totalPages);
            retMap.put('success', true);
        }
        retMap.put('countriesUser', countries);
        return retMap;
    }
    /**
    * @description Get Customer Picklist
    * @param - : no param
    * @return retMap initial data
    */
    @AuraEnabled
    public static List<String> getCountriesUser() {
        List<String> countriesUser = new List<String>();
        final Id userId = UserInfo.getUserId();
        User userInfo = [SELECT DES_Country__c, Profile.Name FROM User WHERE Id = :userId LIMIT 1];
        Boolean riskUser = UserInfo.Profile.Name == 'BBVA Desktop ARCE';
        List<String> geographiesToHide = new List<String>();
        if (!String.isBlank(userInfo.DES_Country__c)) {
            String userCountry = userInfo.DES_Country__c;
            List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigs = [SELECT Risk_Anonymized__c,
                                                                                                Risk_Compacted__c,
                                                                                                No_Risk_Anonymized__c,
                                                                                                No_Risk_Compacted__c
                                                                                        FROM HPG_Geography_Visibility_Configuration__c
                                                                                        WHERE Geography__c =: userCountry LIMIT 1];
            if (geographyVisibilityConfigs.size() > 0) {
                if (riskUser) {
                    if (!String.isBlank(geographyVisibilityConfigs[0].Risk_Anonymized__c)) {
                        geographiesToHide = geographyVisibilityConfigs[0].Risk_Anonymized__c.split(',');
                    }
                    if (!String.isBlank(geographyVisibilityConfigs[0].Risk_Compacted__c)) {
                        geographiesToHide = geographyVisibilityConfigs[0].Risk_Compacted__c.split(',');
                    }
                } else {
                    if (!String.isBlank(geographyVisibilityConfigs[0].No_Risk_Anonymized__c)) {
                        geographiesToHide = geographyVisibilityConfigs[0].No_Risk_Anonymized__c.split(',');
                    }
                    if (!String.isBlank(geographyVisibilityConfigs[0].No_Risk_Compacted__c)) {
                        geographiesToHide = geographyVisibilityConfigs[0].No_Risk_Compacted__c.split(',');
                    }
                }
            }
        }
        for (HPG_Visibility_Country__mdt geographyVisibilityConfiguration : [SELECT ISO2_Code__c FROM HPG_Visibility_Country__mdt]) {
            if (!geographiesToHide.contains(geographyVisibilityConfiguration.ISO2_Code__c)) {
                countriesUser.add(geographyVisibilityConfiguration.ISO2_Code__c);
            }
        }
        return countriesUser;
    }
    /**
    * @description Get Used Tables Dates
    * @param - : no param
    * @return retMap initial data
    */
    @AuraEnabled
    public static Map<String,Object> getUsedTablesDates() {
        Map<String, Object> retMap = new Map<String, Object>();
        List<HPG_Utils.PicklistValue_Wrapper> UsedTablesDatesPicklist = new List<HPG_Utils.PicklistValue_Wrapper>();
        Map<String, Object> request = new Map<String, Object>();
        request.put('tblMeEngineNameConcatenationDesc', 'GCE');
        String today = Datetime.now().format('yyyy-MM-dd');
        request.put('searchDate', today);
        request.put('pageSize', '300');
        request.put('paginationKey', '1');
        HPG_UsedTables.Wrapper usedTables = HPG_UsedTables.getUsedTables(request);
        for (HPG_UsedTables.DateRangeTable usedTable : usedTables.data[0].dateRangeTables)  {
            UsedTablesDatesPicklist.add(new HPG_Utils.PicklistValue_Wrapper(usedTable.tableDate, usedTable.tableDate));
        }
        UsedTablesDatesPicklist.sort();
        retMap.put('usedTablesDates', UsedTablesDatesPicklist);
        return retMap;
    }
}