/**********************************************************************************
* @author       Global Desktop
* @date         05/02/2020
* @description  Test class for DiscardAlertsCmpCtrl
**********************************************************************************/
@isTest
public class CompleteAlleSalesCmpCtrlTest {

    /**
     * Test method 1
    */
    @isTest
    public static void updateFormstest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Secondary_Sales_Id__c = UserInfo.getUserRoleId();
        assTemp.Status__c = 'Implement';
        insert assTemp;
        final Set<Id> setIds = new Set<Id>();
        setIds.add(assTemp.Id);
        final String serial = JSON.serialize(setIds);
        system.assert(CompleteAlleSalesCmpCtrl.updateForms(serial).isEmpty(), 'No se ha actualizado el estado.');
    }

    /**
     * Test method 2
    */
    @isTest
    public static void updateFormstest2() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Secondary_Sales_Id__c = UserInfo.getUserRoleId();
        assTemp.Asset_Class__c = 'Equity';
        assTemp.Status__c = 'Implement';
        insert assTemp;
        assTemp.Asset_Class__c = 'Equity';
        update assTemp;
        final Set<Id> setIds = new Set<Id>();
        setIds.add(assTemp.Id);
        final String serial = JSON.serialize(setIds);
        system.assert(CompleteAlleSalesCmpCtrl.updateForms(serial).isEmpty(), 'No se ha actualizado el estado.');
    }

    /**
     * Test method 2
    */
    @isTest
    public static void updateFormstestKo() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Secondary_Sales_Id__c = UserInfo.getUserRoleId();
        insert assTemp;
        final Set<Id> setIds = new Set<Id>();
        setIds.add(assTemp.Id);
        final String serial = JSON.serialize(setIds);
        system.assert(!(CompleteAlleSalesCmpCtrl.updateForms(serial)).isEmpty(), 'Se ha actualizado el estado.');
    }


    /**
     * Test method 3
    */
    @isTest
    public static void checkRolTest() {
        system.assert(!CompleteAlleSalesCmpCtrl.checkRole(), 'Pertenece al rol.');
    }
}