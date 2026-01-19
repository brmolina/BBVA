@istest
public class Commitment_ctrl_Test {
    
    static Local_Client__c acctest;
    //static Opportunity olitest;
    static OpportunityLineItem_Local__c olitest;
    static Product2Local__c prodtest;
    static User quoteOwner;
    
    @testSetup
    static void setData() {
            
            acctest = TestFactory.createLocalClient();
            olitest = new OpportunityLineItem_Local__c(OwnerId=UserInfo.getUserId(),Name='testopp', Local_Client_id__c=acctest.Id,StageName__c='02',Amount__c=100 ,CloseDate__c=system.Date.today(),opportunity_status_type__c='02');
    		insert olitest;
            prodtest = TestFactory.createProduct();
            olitest = TestFactory.createOLI(olitest.Id, prodtest.Id);
    }

    @isTest
    static void test_method_one(){

        List<Product2Local__c> lstProd = [SELECT Id, Type_of_quote__c FROM Product2Local__c];
        lstProd[0].Type_of_quote__c = 'Tarifario';
        update lstProd;

        List<OpportunityLineItem_Local__c> lstOpp = [SELECT Id FROM OpportunityLineItem_Local__c];
        Map<String,Object> mapReturnInfoTable = Commitment_ctrl.getInfoTable(lstOpp[0].Id);
        System.assert(mapReturnInfoTable.containsKey('schemaSetup'));

        List<Object> lstData = new List<Object>();
        lstData.add('Prod');
        lstData.add('PEN');
        lstData.add(34);
        lstData.add(12);
        lstData.add(3);
        lstData.add(null);
        lstData.add(null);
        
    }
    
    @isTest
    static void test_requetQuotationApproval_Success(){
        
        
        setData();
		
		List<OpportunityLineItem_Local__c> oppLineItemTestList = [SELECT Id, price_quote_id__c
														FROM OpportunityLineItem_Local__c WHERE Id = :olitest.Id];
		
		if(!oppLineItemTestList.isEmpty()){
			oppLineItemTestList[0].price_quote_id__c = '1475650';
		}
		System.assertNotEquals(oppLineItemTestList, null,'Error');

		update oppLineItemTestList[0];
                
    }
    
    @isTest
    static void test_requetQuotationApproval_2_Success(){
        
        
        setData();
		
		List<OpportunityLineItem_Local__c> oppLineItemTestList = [SELECT Id, price_quote_id__c
														FROM OpportunityLineItem_Local__c WHERE Id = :olitest.Id];
		
		if(!oppLineItemTestList.isEmpty()){
			oppLineItemTestList[0].price_quote_id__c = '1475650';
		}
		
		update oppLineItemTestList[0];
        Commit_Inter_Garant__c osc = new Commit_Inter_Garant__c(opp_solution_commitment_amount__c = 34,
                                                                            opp_soln_comt_expiry_days_number__c = 23,
                                                                            Opportunity_Product_Local_id__c = olitest.Id,
                                                                            CurrencyIsoCode = 'PEN');    
        System.assertNotEquals(oppLineItemTestList, null,'Error');

    }
    
    @isTest
    static void test_requetQuotationApprovalDifferentUser_Success(){
        
        
        setData();
		
		List<OpportunityLineItem_Local__c> oppLineItemTestList = [SELECT Id, price_quote_id__c
														FROM OpportunityLineItem_Local__c WHERE Id = :olitest.Id];
		
		if(!oppLineItemTestList.isEmpty()){
			oppLineItemTestList[0].price_quote_id__c = '1475650';
		}
		
		update oppLineItemTestList[0];  
		System.assertNotEquals(oppLineItemTestList, null,'Error');
             
    }
    
    @isTest
    static void test_requetQuotationApproval_Error_1(){
        
        
        setData();
		
		List<OpportunityLineItem_Local__c> oppLineItemTestList = [SELECT Id, price_quote_id__c
														FROM OpportunityLineItem_Local__c WHERE Id = :olitest.Id];
		
		if(!oppLineItemTestList.isEmpty()){
			oppLineItemTestList[0].price_quote_id__c = '1475650';
		}
		
		update oppLineItemTestList[0];
		System.assertNotEquals(oppLineItemTestList, null,'Error');


    }
	
	@isTest
    static void test_requetQuotationApproval_Error_2(){
        
        
        setData();
		
		List<OpportunityLineItem_Local__c> oppLineItemTestList = [SELECT Id, price_quote_id__c
														FROM OpportunityLineItem_Local__c WHERE Id = :olitest.Id];
		
		if(!oppLineItemTestList.isEmpty()){
			oppLineItemTestList[0].price_quote_id__c = '1475650';
		}
		
		update oppLineItemTestList[0];
		System.assertNotEquals(oppLineItemTestList, null,'Error');

    }
    
    @isTest
    static void test_requetQuotationApprovalDifferentUser_Error_1(){
        
        
        setData();
		
		List<OpportunityLineItem_Local__c> oppLineItemTestList = [SELECT Id, price_quote_id__c
														FROM OpportunityLineItem_Local__c WHERE Id = :olitest.Id];
		
		if(!oppLineItemTestList.isEmpty()){
			oppLineItemTestList[0].price_quote_id__c = '1475650';
		}
		
		update oppLineItemTestList[0]; 
		System.assertNotEquals(oppLineItemTestList, null,'Error');
              
    }
    
    @isTest
    static void test_requetQuotationApprovalDifferentUser_Error_2(){
        
        
        setData();
		
		List<OpportunityLineItem_Local__c> oppLineItemTestList = [SELECT Id, price_quote_id__c
														FROM OpportunityLineItem_Local__c WHERE Id = :olitest.Id];
		
		if(!oppLineItemTestList.isEmpty()){
			oppLineItemTestList[0].price_quote_id__c = '1475650';

		}
		
		update oppLineItemTestList[0];
        System.assertNotEquals(oppLineItemTestList, null,'Error');

    }
}