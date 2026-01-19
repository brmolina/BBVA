@istest
public class FieldForm_ctrl_Test {

    @testSetup
    static void setData() {
        
        Local_Client__c acc = TestFactory.createLocalClient();
        OpportunityLineItem_Local__c opp = TestFactory.createOpportunity(acc.Id, UserInfo.getUserId());
        Product2Local__c prod = TestFactory.createProduct();
        OpportunityLineItem_Local__c oli = TestFactory.createOLI(opp.Id, prod.Id);
    }

    @isTest
    static void test_method_one(){
        List<OpportunityLineItem_Local__c> lstOLI = [SELECT Id FROM OpportunityLineItem_Local__c];
        Map<String,Object> getData = FieldForm_ctrl.getInfo(lstOLI[0].Id,'COTIZA Beta_Proposal');
        System.assertEquals(true, (Boolean)getData.get('isOk'));
        Map<String,Object> getDataError = FieldForm_ctrl.getInfo('skdfjowe23','COTIZA Beta_Proposal');
        System.assertEquals(false, (Boolean)getDataError.get('isOk'));

    }
}