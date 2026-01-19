/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_GeographyVisibilityConfig_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-05-08
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class HPG_GeographyVisibilityConfig_Ctrl_Test {
    @IsTest
    static void testInitialData() {
        HPG_Geography_Visibility_Configuration__c geographyVisibilityConfiguration = new HPG_Geography_Visibility_Configuration__c();
        geographyVisibilityConfiguration.Name = 'Spain';
        geographyVisibilityConfiguration.Geography__c = 'ESP';
        geographyVisibilityConfiguration.Risk_Anonymized__c = 'ES,AR';
        geographyVisibilityConfiguration.Risk_Compacted__c = 'ES,AR';
        geographyVisibilityConfiguration.No_Risk_Anonymized__c = 'ES,AR';
        geographyVisibilityConfiguration.No_Risk_Compacted__c = 'ES,AR';
        insert geographyVisibilityConfiguration;
        Test.startTest();
            Map<String, Object> retMap = HPG_GeographyVisibilityConfig_Ctrl.initialData();
            Boolean hideData = (Boolean)retMap.get('hideData');
            List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigurations = (List<HPG_Geography_Visibility_Configuration__c>)retMap.get('geographyVisibilityConfigurations');
            Boolean success = (Boolean)retMap.get('success');
            System.assertEquals(false, hideData, 'testInitialData - Not passed - hideData');
            System.assertEquals(1, geographyVisibilityConfigurations.size(), 'testInitialData - Not passed - geographyVisibilityConfigurations');
            System.assertEquals(true, success, 'testInitialData - Not passed - success');
        Test.stopTest();
    }
    @IsTest
    static void testAddGeographyOK() {
        List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigurationsAdd = new List<HPG_Geography_Visibility_Configuration__c>();
        String geographySelected = 'ESP';
        List<HPG_GeographyVisibilityConfig_Ctrl.PicklistValue_Wrapper> geographiesPicklist = HPG_GeographyVisibilityConfig_Ctrl.getPicklistData('HPG_Geography_Visibility_Configuration__c','Geography__c');
        Test.startTest();
            Map<String, Object> retMap = HPG_GeographyVisibilityConfig_Ctrl.addGeography(geographyVisibilityConfigurationsAdd, geographySelected, geographiesPicklist);
            Boolean success = (Boolean)retMap.get('success');
            geographyVisibilityConfigurationsAdd = (List<HPG_Geography_Visibility_Configuration__c>)retMap.get('geographyVisibilityConfigurationsAdd');
            System.assertEquals(true, success, 'testAddGeographyOK - Not passed - success');
            System.assertEquals(1, geographyVisibilityConfigurationsAdd.size(), 'testAddGeographyOK - Not passed - geographyVisibilityConfigurationsAdd size');
        Test.stopTest();
    }
    @IsTest
    static void testAddGeographyNOK() {
        List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigurationsAdd = new List<HPG_Geography_Visibility_Configuration__c>();
        String geographySelected = 'A';
        List<HPG_GeographyVisibilityConfig_Ctrl.PicklistValue_Wrapper> geographiesPicklist = HPG_GeographyVisibilityConfig_Ctrl.getPicklistData('HPG_Geography_Visibility_Configuration__c','Geography__c');
        Test.startTest();
            Map<String, Object> retMap = HPG_GeographyVisibilityConfig_Ctrl.addGeography(geographyVisibilityConfigurationsAdd, geographySelected, geographiesPicklist);
            Boolean success = (Boolean)retMap.get('success');
            System.assertEquals(false, success, 'testAddGeographyNOK - Not passed - success');
        Test.stopTest();
    }
    @IsTest
    static void testUpdateGeographies() {
        List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigurations = new List<HPG_Geography_Visibility_Configuration__c>();
        HPG_Geography_Visibility_Configuration__c geographyVisibilityConfiguration1 = new HPG_Geography_Visibility_Configuration__c();
        geographyVisibilityConfiguration1.Name = 'Spain';
        geographyVisibilityConfiguration1.Geography__c = 'ESP';
        geographyVisibilityConfiguration1.Risk_Anonymized__c = 'ES,AR';
        geographyVisibilityConfiguration1.Risk_Compacted__c = 'ES,AR';
        geographyVisibilityConfiguration1.No_Risk_Anonymized__c = 'ES,AR';
        geographyVisibilityConfiguration1.No_Risk_Compacted__c = 'ES,AR';
        insert geographyVisibilityConfiguration1;
        geographyVisibilityConfiguration1.Risk_Anonymized__c = 'ES';
        geographyVisibilityConfiguration1.Risk_Compacted__c = 'ES';
        geographyVisibilityConfiguration1.No_Risk_Anonymized__c = 'ES';
        geographyVisibilityConfiguration1.No_Risk_Compacted__c = 'ES';
        geographyVisibilityConfigurations.add(geographyVisibilityConfiguration1);
        HPG_Geography_Visibility_Configuration__c geographyVisibilityConfiguration2 = new HPG_Geography_Visibility_Configuration__c();
        geographyVisibilityConfiguration2.Name = 'Colombia';
        geographyVisibilityConfiguration2.Geography__c = 'COL';
        geographyVisibilityConfiguration2.Risk_Anonymized__c = 'CL,ES';
        geographyVisibilityConfiguration2.Risk_Compacted__c = 'CL,ES';
        geographyVisibilityConfiguration2.No_Risk_Anonymized__c = 'CL,ES';
        geographyVisibilityConfiguration2.No_Risk_Compacted__c = 'CL,ES';
        insert geographyVisibilityConfiguration2;
        geographyVisibilityConfiguration2.Risk_Anonymized__c = '';
        geographyVisibilityConfiguration2.Risk_Compacted__c = '';
        geographyVisibilityConfiguration2.No_Risk_Anonymized__c = '';
        geographyVisibilityConfiguration2.No_Risk_Compacted__c = '';
        geographyVisibilityConfigurations.add(geographyVisibilityConfiguration2);
        HPG_Geography_Visibility_Configuration__c geographyVisibilityConfiguration3 = new HPG_Geography_Visibility_Configuration__c();
        geographyVisibilityConfiguration3.Name = 'Mexico';
        geographyVisibilityConfiguration3.Geography__c = 'MEX';
        geographyVisibilityConfiguration3.Risk_Anonymized__c = 'MX,ES';
        geographyVisibilityConfiguration3.Risk_Compacted__c = 'MX,ES';
        geographyVisibilityConfiguration3.No_Risk_Anonymized__c = 'MX,ES';
        geographyVisibilityConfiguration3.No_Risk_Compacted__c = 'MX,ES';
        insert geographyVisibilityConfiguration3;
        geographyVisibilityConfiguration3.Risk_Anonymized__c = null;
        geographyVisibilityConfiguration3.Risk_Compacted__c = null;
        geographyVisibilityConfiguration3.No_Risk_Anonymized__c = 'MX';
        geographyVisibilityConfiguration3.No_Risk_Compacted__c = 'MX';
        geographyVisibilityConfigurations.add(geographyVisibilityConfiguration3);
        HPG_Geography_Visibility_Configuration__c geographyVisibilityConfiguration4 = new HPG_Geography_Visibility_Configuration__c();
        geographyVisibilityConfiguration4.Name = 'Italy';
        geographyVisibilityConfiguration4.Geography__c = 'ITA';
        geographyVisibilityConfiguration4.Risk_Anonymized__c = 'IT,ES';
        geographyVisibilityConfiguration4.Risk_Compacted__c = 'IT,ES';
        geographyVisibilityConfiguration4.No_Risk_Anonymized__c = 'IT,ES';
        geographyVisibilityConfiguration4.No_Risk_Compacted__c = 'IT,ES';
        insert geographyVisibilityConfiguration4;
        geographyVisibilityConfiguration4.Risk_Anonymized__c = 'IT';
        geographyVisibilityConfiguration4.Risk_Compacted__c = 'IT';
        geographyVisibilityConfiguration4.No_Risk_Anonymized__c = null;
        geographyVisibilityConfiguration4.No_Risk_Compacted__c = null;
        geographyVisibilityConfigurations.add(geographyVisibilityConfiguration4);
        List<HPG_Geography_Visibility_Configuration__c> geographyVisibilityConfigurationsAdd = new List<HPG_Geography_Visibility_Configuration__c>();
        HPG_Geography_Visibility_Configuration__c geographyVisibilityConfigurationAdd = new HPG_Geography_Visibility_Configuration__c();
        geographyVisibilityConfigurationAdd.Name = 'Argentina';
        geographyVisibilityConfigurationAdd.Geography__c = 'ARG';
        geographyVisibilityConfigurationAdd.Risk_Anonymized__c = 'AR,ES';
        geographyVisibilityConfigurationAdd.Risk_Compacted__c = 'AR,ES';
        geographyVisibilityConfigurationAdd.No_Risk_Anonymized__c = 'AR,ES';
        geographyVisibilityConfigurationAdd.No_Risk_Compacted__c = 'AR,ES';
        geographyVisibilityConfigurationsAdd.add(geographyVisibilityConfigurationAdd);
        Test.startTest();
            Map<String, Object> retMap = HPG_GeographyVisibilityConfig_Ctrl.updateGeographies(geographyVisibilityConfigurations, geographyVisibilityConfigurationsAdd);
            Boolean success = (Boolean)retMap.get('success');
            System.assertEquals(true, success, 'testUpdateGeographies - Not passed - success');
        Test.stopTest();
    }
}