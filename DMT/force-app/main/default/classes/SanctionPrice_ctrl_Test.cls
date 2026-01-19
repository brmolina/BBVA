@istest
public class SanctionPrice_ctrl_Test {
    @testSetup
    static void setData() {
        Local_Client__c acc = TestFactory.createLocalClient();
        OpportunityLineItem_Local__c opp = TestFactory.createOpportunity(acc.Id, UserInfo.getUserId());
        Product2Local__c prod = TestFactory.createProduct();
        OpportunityLineItem_Local__c oli = TestFactory.createOLI(opp.Id, prod.Id);
    }

    @isTest
    static void test_method_one(){
        List<Local_Client__c> lstAccount = [SELECT Id,Cib_Client__c FROM Local_Client__c];
        lstAccount[0].segment_desc__c = 'SUPERIOR';
        update lstAccount;

        List<Product2Local__c> lstProd = [SELECT Id, Type_of_quote__c FROM Product2Local__c];
        lstProd[0].Type_of_quote__c = 'Tarifario';
        update lstProd;
        List<OpportunityLineItem_Local__c> lstOpp = [SELECT Id FROM OpportunityLineItem_Local__c];
        Map<String,Object> mapReturnInfo3 = SanctionPrice_ctrl.getInfoWithoutDefaultValues(lstOpp[0].Id);

        System.assertEquals(true, (Boolean)mapReturnInfo3.get('hasOLI'));    
        
    }
    @isTest
    static void test_method_two(){
        Test.startTest();
        List<Local_Client__c> lstAccount = [SELECT Id,Cib_Client__c FROM Local_Client__c];
        lstAccount[0].segment_desc__c = 'SUPERIOR';
        update lstAccount;

        List<Product2Local__c> lstProd = [SELECT Id, Type_of_quote__c FROM Product2Local__c];
        lstProd[0].Type_of_quote__c = 'Web';
        update lstProd;
        List<OpportunityLineItem_Local__c> lstOpp = [SELECT Id FROM OpportunityLineItem_Local__c];
        Map<String,Object> mapReturnInfo4 = SanctionPrice_ctrl.getInfoWithoutDefaultValues(lstOpp[0].Id);
        System.assertEquals(true, (Boolean)mapReturnInfo4.get('hasOLI')); 
        Test.stopTest();
        }
}