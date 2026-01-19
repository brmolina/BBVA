/**
* ____________________________________________________________________________
* Controller class for HPG_GeographyVisibilityConfig.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-07-24
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class HPG_GeographyVisibilityConfig_Ctrl {
    /**
    * @description Get initial data
    * @param - : No param
    * @return retMap initial data
    */
    @AuraEnabled
    public static Map<String,Object> initialData() {
        Map<String, Object> retMap = new Map<String, Object>();
        Boolean hideData = true;
        Boolean hideSelector = true;
        String geographySelected = '';
        Set<String> availableGeographies = new Set<String>();
        for (HPG_Visibility_Country__mdt geographyVisibilityConfiguration : [SELECT ISO3_Code__c FROM HPG_Visibility_Country__mdt]) {
            availableGeographies.add(geographyVisibilityConfiguration.ISO3_Code__c);
        }
        List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigurations = [SELECT Name, Geography__c, Risk_Anonymized__c, Risk_Compacted__c, No_Risk_Anonymized__c, No_Risk_Compacted__c FROM HPG_Geography_Visibility_Configuration__c ORDER BY Geography__c];
        List<String> geographies = new List<String>();
        for (HPG_Geography_Visibility_Configuration__c geographyVisibilityConfiguration : geographyVisibilityConfigurations) {
            geographies.add(geographyVisibilityConfiguration.Geography__c);
        }
        List<PicklistValue_Wrapper> geographiesPicklist = new List<PicklistValue_Wrapper>();
        for (PicklistValue_Wrapper picklistValueWrapper : getPicklistData('HPG_Geography_Visibility_Configuration__c','Geography__c')) {
            if (!geographies.contains(picklistValueWrapper.value) && picklistValueWrapper.value !='' && availableGeographies.contains(picklistValueWrapper.value)) {
                geographiesPicklist.add(picklistValueWrapper);
            }
        }
        if (geographiesPicklist.size() > 0) {
            hideSelector = false;
        }
        if (geographyVisibilityConfigurations.size() > 0) {
            hideData = false;
        }
        if (geographiesPicklist.size() > 0) {
            geographySelected = geographiesPicklist[0].value;
        }
        retMap.put('title', HPG_Geography_Visibility_Configuration__c.sObjectType.getDescribe().getLabel());
        retMap.put('hideData', hideData);
        retMap.put('hideSelector', hideSelector);
        retMap.put('geographyVisibilityConfigurations', geographyVisibilityConfigurations);
        retMap.put('geographiesPicklist', geographiesPicklist);
        retMap.put('geographySelected', geographySelected);
        retMap.put('success', true);
        return retMap;
    }
    /**
    * @description Add geography
    * @param geographyVisibilityConfigurationsAdd : geographies previously added
    * @param geographySelected : new geography added
    * @param geographiesPicklist : available geographies picklist
    * @return retMap geographies added data
    */
    @AuraEnabled
    public static Map<String,Object> addGeography(List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigurationsAdd, String geographySelected, List<PicklistValue_Wrapper> geographiesPicklist) {
        Map<String, Object> retMap = new Map<String, Object>();
        Boolean error = true;
        Boolean hideSelector = true;
        String geoSelected = '';

        HPG_Geography_Visibility_Configuration__c geographyVisibilityConfiguration = new HPG_Geography_Visibility_Configuration__c();
        List<PicklistValue_Wrapper> geographiesPicklistClone = geographiesPicklist.clone();
        for (PicklistValue_Wrapper picklistValueWrapper : geographiesPicklistClone) {
            if (picklistValueWrapper.value == geographySelected) {
                geographyVisibilityConfiguration.Name = picklistValueWrapper.label;
                geographyVisibilityConfiguration.Geography__c = picklistValueWrapper.value;
                geographyVisibilityConfiguration.Risk_Anonymized__c = '';
                geographyVisibilityConfiguration.Risk_Compacted__c = '';
                geographyVisibilityConfiguration.No_Risk_Anonymized__c = '';
                geographyVisibilityConfiguration.No_Risk_Compacted__c = '';
                geographyVisibilityConfigurationsAdd.add(geographyVisibilityConfiguration);
                geographiesPicklist.remove(geographiesPicklist.indexOf(picklistValueWrapper));
                error = false;
            }
        }
        if (geographiesPicklist.size() > 0) {
            hideSelector = false;
            geoSelected = geographiesPicklist[0].value;
        }
        if (error) {
            retMap.put('success', false);
        }else{
            retMap.put('geographyVisibilityConfigurationsAdd', geographyVisibilityConfigurationsAdd);
            retMap.put('geographiesPicklist', geographiesPicklist);
            retMap.put('hideSelector', hideSelector);
            retMap.put('geographySelected', geoSelected);
            retMap.put('success', true);
        }
        return retMap;
    }
    /**
    * @description Update geographies
    * @param geographyVisibilityConfigurations : geographies modified data
    * @param geographyVisibilityConfigurationsAdd : geographies added data
    * @return retMap success
    */
    @AuraEnabled
    public static Map<String,Object> updateGeographies(List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigurations, List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigurationsAdd) {
        Map<String, Object> retMap = new Map<String, Object>();
        List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigurationsUpsert = new List<HPG_Geography_Visibility_Configuration__c>();
        List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigurationsDelete = new List<HPG_Geography_Visibility_Configuration__c>();
        for (HPG_Geography_Visibility_Configuration__c geographyVisibilityConfiguration : geographyVisibilityConfigurations) {
            if ((geographyVisibilityConfiguration.Risk_Anonymized__c == '' || geographyVisibilityConfiguration.Risk_Anonymized__c == null) &&
                (geographyVisibilityConfiguration.Risk_Compacted__c == '' || geographyVisibilityConfiguration.Risk_Compacted__c == null) &&
                (geographyVisibilityConfiguration.No_Risk_Anonymized__c == '' || geographyVisibilityConfiguration.No_Risk_Anonymized__c == null) &&
                (geographyVisibilityConfiguration.No_Risk_Compacted__c == '' || geographyVisibilityConfiguration.No_Risk_Compacted__c == null)) {
                geographyVisibilityConfigurationsDelete.add(geographyVisibilityConfiguration);
            }else {
                if (geographyVisibilityConfiguration.Risk_Anonymized__c == null) {
                    geographyVisibilityConfiguration.Risk_Anonymized__c = '';
                }else {
                    geographyVisibilityConfiguration.Risk_Anonymized__c = geographyVisibilityConfiguration.Risk_Anonymized__c.toUppercase();
                }
                if (geographyVisibilityConfiguration.Risk_Compacted__c == null) {
                    geographyVisibilityConfiguration.Risk_Compacted__c = '';
                }else {
                    geographyVisibilityConfiguration.Risk_Compacted__c = geographyVisibilityConfiguration.Risk_Compacted__c.toUppercase();
                }
                if (geographyVisibilityConfiguration.No_Risk_Anonymized__c == null) {
                    geographyVisibilityConfiguration.No_Risk_Anonymized__c = '';
                }else {
                    geographyVisibilityConfiguration.No_Risk_Anonymized__c = geographyVisibilityConfiguration.No_Risk_Anonymized__c.toUppercase();
                }
                if (geographyVisibilityConfiguration.No_Risk_Compacted__c == null) {
                    geographyVisibilityConfiguration.No_Risk_Compacted__c = '';
                }else {
                    geographyVisibilityConfiguration.No_Risk_Compacted__c = geographyVisibilityConfiguration.No_Risk_Compacted__c.toUppercase();
                }
                geographyVisibilityConfigurationsUpsert.add(geographyVisibilityConfiguration);
            }
        }
        for (HPG_Geography_Visibility_Configuration__c geographyVisibilityConfiguration : geographyVisibilityConfigurationsAdd) {
            if ((geographyVisibilityConfiguration.Risk_Anonymized__c != '' && geographyVisibilityConfiguration.Risk_Anonymized__c != null) || (geographyVisibilityConfiguration.Risk_Compacted__c != '' && geographyVisibilityConfiguration.Risk_Compacted__c != null) || (geographyVisibilityConfiguration.No_Risk_Anonymized__c != '' && geographyVisibilityConfiguration.No_Risk_Anonymized__c != null) || (geographyVisibilityConfiguration.No_Risk_Compacted__c != '' && geographyVisibilityConfiguration.No_Risk_Compacted__c != null)) {
                geographyVisibilityConfiguration.Risk_Anonymized__c = geographyVisibilityConfiguration.Risk_Anonymized__c.toUppercase();
                geographyVisibilityConfiguration.Risk_Compacted__c = geographyVisibilityConfiguration.Risk_Compacted__c.toUppercase();
                geographyVisibilityConfiguration.No_Risk_Anonymized__c = geographyVisibilityConfiguration.No_Risk_Anonymized__c.toUppercase();
                geographyVisibilityConfiguration.No_Risk_Compacted__c = geographyVisibilityConfiguration.No_Risk_Compacted__c.toUppercase();
                geographyVisibilityConfigurationsUpsert.add(geographyVisibilityConfiguration);
            }
        }
        if (geographyVisibilityConfigurationsUpsert.size() > 0) {
            upsert geographyVisibilityConfigurationsUpsert;
        }
        if (geographyVisibilityConfigurationsDelete.size() > 0) {
            delete geographyVisibilityConfigurationsDelete;
        }
        retMap.put('success', true);
        return retMap;
    }
    /**
    * @description Returns picklist values
    * @param objectName : Object name
    * @param fieldName : Field name
    * @return retMap Picklist values
    */
    @AuraEnabled
    public static List<PicklistValue_Wrapper> getPicklistData(String objectName, String fieldName) {
        List<PicklistValue_Wrapper> picklistDataList = new List<PicklistValue_Wrapper>();
        List<Schema.PicklistEntry> picklistEntries = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues();
        PicklistValue_Wrapper picklistNone = new PicklistValue_Wrapper();
        picklistNone.label = '';
        picklistNone.value = '';
        picklistDataList.add(picklistNone);
        for (Schema.PicklistEntry picklistEntry : picklistEntries) {
            if (picklistEntry.isActive()) {
                PicklistValue_Wrapper picklistData = new PicklistValue_Wrapper();
                picklistData.label = picklistEntry.getLabel();
                picklistData.value = picklistEntry.getValue();
                picklistDataList.add(picklistData);
            }
        }
        return picklistDataList;
    }
    /**
    * @description Wrapper for picklist values
    */
	public class PicklistValue_Wrapper {
		@AuraEnabled
		public String label {get; set;}
		@AuraEnabled
		public String value {get; set;}
	}
}