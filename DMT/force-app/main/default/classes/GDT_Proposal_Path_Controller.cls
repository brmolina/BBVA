/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-27-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global with sharing class GDT_Proposal_Path_Controller {
    
    public class ComboboxOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public ComboboxOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ComboboxOption> getRegionAmbit() {
        Set<String> uniqueValues = new Set<String>(); 
        List<ComboboxOption> options = new List<ComboboxOption>();

        for (Arce_Proposal_Ambit_Hierarchy__mdt meta : [
            SELECT id, GDT_Region__c,  GDT_Taxonomy_ID__c 
			FROM Arce_Proposal_Ambit_Hierarchy__mdt 
        ]) {
            if (!uniqueValues.contains(meta.GDT_Region__c)) { 
                uniqueValues.add(meta.GDT_Region__c);
                options.add(new ComboboxOption(meta.GDT_Region__c, meta.GDT_Taxonomy_ID__c));
            }
        }
        System.debug('revisar ' + options);
        return options;
    }
    
    @AuraEnabled
    public static List<ComboboxOption> getLevelAmbit(String filterValue) {
        Set<String> uniqueValues = new Set<String>(); 
        List<ComboboxOption> options = new List<ComboboxOption>();

        for (Arce_Proposal_Ambit_Hierarchy__mdt meta : [
            SELECT id, GDT_Region__c, GDT_Level__c, GDT_Description__c, GDT_Taxonomy_ID__c 
			FROM Arce_Proposal_Ambit_Hierarchy__mdt 
			WHERE GDT_Taxonomy_ID__c =: filterValue
        ]) {
            if (!uniqueValues.contains(meta.GDT_Level__c)) { 
                uniqueValues.add(meta.GDT_Level__c);
                options.add(new ComboboxOption(meta.GDT_Level__c, meta.GDT_Level__c));
            }
        }
        return options;
    }
    
    @AuraEnabled
    public static List<ComboboxOption> getDescriptionAmbit(String filterValue1, String filterValue2) {
        Set<String> uniqueValues = new Set<String>(); 
        List<ComboboxOption> options = new List<ComboboxOption>();
		System.debug('revisar 2' + filterValue1 + ' ' + filterValue2);
        for (Arce_Proposal_Ambit_Hierarchy__mdt meta : [
            SELECT id, GDT_Region__c, GDT_Level__c, GDT_Description__c, GDT_Taxonomy_ID__c
			FROM Arce_Proposal_Ambit_Hierarchy__mdt 
			WHERE GDT_Taxonomy_ID__c =: filterValue2
            AND GDT_Level__c = :filterValue1
        ]) {
            if (!uniqueValues.contains(meta.GDT_Description__c)) { 
                uniqueValues.add(meta.GDT_Description__c);
                options.add(new ComboboxOption(meta.GDT_Description__c, meta.GDT_Description__c));
            }
        }
        System.debug('revisar ' + options);
        return options;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ComboboxOption> getTaxonomy() {
        Set<String> uniqueValues = new Set<String>(); 
        List<ComboboxOption> options = new List<ComboboxOption>();

        for (GDT_Proposal_Taxonomy__mdt meta : [
            SELECT id, ID__c, Value__c 
			FROM GDT_Proposal_Taxonomy__mdt 
        ]) {
            if (!uniqueValues.contains(meta.Value__c)) { 
                uniqueValues.add(meta.Value__c);
                options.add(new ComboboxOption(meta.Value__c, meta.ID__c));
            }
        }
        return options;
    }
    
    @AuraEnabled
    public static List<ComboboxOption> getGeographyCommittee() {
        Set<String> uniqueValues = new Set<String>(); 
        List<ComboboxOption> options = new List<ComboboxOption>();

        for (GDT_Committee_Geo__mdt meta : [
            SELECT id, GDT_Geography__c, GDT_Committee_Description__c, GDT_Committee__c 
			FROM GDT_Committee_Geo__mdt 
        ]) {
            if (!uniqueValues.contains(meta.GDT_Geography__c)) { 
                uniqueValues.add(meta.GDT_Geography__c);
                options.add(new ComboboxOption(meta.GDT_Geography__c, meta.GDT_Geography__c));
            }
        }
        return options;
    }
	
    @AuraEnabled
    public static List<ComboboxOption> getCommittee(String filterValue) {
        Set<String> uniqueValues = new Set<String>(); 
        List<ComboboxOption> options = new List<ComboboxOption>();

        for (GDT_Committee_Geo__mdt meta : [
            SELECT id, GDT_Geography__c, GDT_Committee_Description__c, GDT_Committee__c 
			FROM GDT_Committee_Geo__mdt 
			WHERE GDT_Geography__c =: filterValue
        ]) {
            if (!uniqueValues.contains(meta.GDT_Committee__c)) { 
                uniqueValues.add(meta.GDT_Committee__c);
                options.add(new ComboboxOption(meta.GDT_Committee_Description__c, meta.GDT_Committee__c));
            }
        }
        return options;
    }
    
    @AuraEnabled
    public static List<ComboboxOption> getCommitteeCombo(String filterValue) {
        System.debug('revisar last' + filterValue);
        Set<String> uniqueValues = new Set<String>(); 
        List<ComboboxOption> options = new List<ComboboxOption>();

        for (GDT_Committee_Geo__mdt meta : [
            SELECT id, GDT_Geography__c, GDT_Committee_Description__c, GDT_Committee__c 
			FROM GDT_Committee_Geo__mdt 
			WHERE GDT_Committee__c =: filterValue
        ]) {
            if (!uniqueValues.contains(meta.GDT_Committee__c)) { 
                uniqueValues.add(meta.GDT_Committee__c);
                options.add(new ComboboxOption(meta.GDT_Committee_Description__c, meta.GDT_Committee__c));
            }
        }
        System.debug('revisar last 2' + options);
        return options;
    }


}