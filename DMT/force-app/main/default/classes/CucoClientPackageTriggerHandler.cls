/**
* ────────────────────────────────────────────────────────────────────
* Cuco Client Package Trigger Handler
*
* ────────────────────────────────────────────────────────────────────
* @author      Torcuato tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-08-27
* @modified
* @systemLayer Trigger
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class CucoClientPackageTriggerHandler {

    private static CucoClientPackageTriggerHandler instance;

    /*
    * return existing instance
    */
    public static CucoClientPackageTriggerHandler getInstance() {
        if (instance == null) {
            instance = new CucoClientPackageTriggerHandler();
        }
        return instance;
    }

    /*
    *  beforeInsert trigger handler
    */
    public void beforeInsert(List<cuco__client_package__c> triggerNew) {

        final Map<String, Id> packageIds = new Map<String, Id>();
        final String gipString = System.Label.GIPString;
        final List<cuco__ps_catalog_package__c> catalogPackages = [SELECT Id, cuco__gf_psc_package_id__c FROM cuco__ps_catalog_package__c LIMIT 50000];

        for (cuco__ps_catalog_package__c catalogPackage : catalogPackages) {
            packageIds.put(catalogPackage.cuco__gf_psc_package_id__c, catalogPackage.Id);
        }

        for (cuco__client_package__c clientPackage : triggerNew) {
            final String packageId = 'F' + clientPackage.cuco__gf_cust_package_id__c;
            checkDate(clientPackage);
            if (packageIds.containsKey(packageId)) {
                clientPackage.cuco__gf_psc_package_code_id__c = packageIds.get(packageId);
            } else if (packageIds.containsKey(gipString)) {
                clientPackage.cuco__gf_psc_package_code_id__c = packageIds.get(gipString);
            } else {
                clientPackage.addError(System.Label.cuco_package_does_not_exist + packageId);
            }
        }
    }

    public void checkDate(cuco__client_package__c clientPackage) {
        if (String.isBlank(string.ValueOf(clientPackage.cuco__gf_cust_pkg_ct_expiry_date__c)) || String.isEmpty(string.ValueOf(clientPackage.cuco__gf_cust_pkg_ct_expiry_date__c))){
            clientPackage.cuco__gf_cust_pkg_ct_expiry_date__c = date.valueOf(System.Label.DatePackage);
        }
    }

}