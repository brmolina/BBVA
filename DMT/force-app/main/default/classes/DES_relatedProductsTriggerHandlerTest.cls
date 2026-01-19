/******************************************************************************
*@author: VASS
*@Description: DES_relatedProductsTriggerHandler Test Class
*@Versions:
- v1 - 06/02/2019 - Initial version
******************************************************************************/
@isTest
public class DES_relatedProductsTriggerHandlerTest {
    /**@author: VASS*/
    @testSetup
    public static void setupRows() { 
        
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        
        final List<fprd__GBL_Product_version__c> lpv = new List<fprd__GBL_Product_version__c>();
        fprd__GBL_Product_version__c prodver = new fprd__GBL_Product_version__c();
        prodver.fprd__Version_number__c = 1;
        lpv.add(prodver);
        
        prodver = new fprd__GBL_Product_version__c();
        prodver.fprd__Version_number__c = 2;
        lpv.add(prodver);
        
        insert lpv;
        
        final Account acc = utils.createClient();
        insert acc;
        
       final List<String> productNames = new List<String>{Label.DES_Working_Capital, Label.DES_Working_Capital, Label.DES_Working_Capital, Label.DES_Corporate_Loans, 
            Label.DES_Leverage_Buyout_LBOs, Label.DES_Project_Finance_Lending, Label.DES_Project_Finance_Advisory, Label.DES_Debt_Capital_Markets, 
            Label.DES_Securities_Services, Label.DES_Cash_Management, Label.DES_Transaction_Trade_Finance, Label.DES_Transaction_Trade_Finance, 
            Label.DES_Transaction_Trade_Finance, Label.DES_Transaction_Trade_Finance, Label.DES_Structure_Trade_Finance,Label.DES_Structure_Trade_Finance, Label.DES_Structure_Trade_Finance, 
            Label.DES_Structure_Trade_Finance, Label.DES_Client_Resources };
               final Map<Id, Product2> mapProd = new Map<Id, Product2>();
        final List<Product2> listProd = new List<Product2>();
        for(String prodName : productNames) {
            listProd.add(utils.createProduct(prodName));
        }
       
        
        insert listProd;
        
        final Pricebook2 priceBook = utils.createPricebook();
        insert priceBook;
        
        final Map<Id,PricebookEntry> mapPBE = new Map<Id,PricebookEntry>();
        for(Product2 prod : listProd) {
            mapPBE.put(prod.Id,utils.createPricebookEntry(prod));
            mapProd.put(prod.Id,prod);
        }
        insert mapPBE.values();
        
        final Opportunity opp = utils.createOpportunity(acc);
        opp.gf_opportunity_product_desc__c = 'desc';
        insert opp;
        
        
        final List<OpportunityLineItem> oliList = generarOli(opp, mapProd, mapPBE, lpv);
        insert oliList;
    }
    
    private static List<OpportunityLineItem> generarOli(Opportunity opp, Map<Id, Product2> mapProd, Map<Id,PricebookEntry> mapPBE, List<fprd__GBL_Product_version__c> lpv) {
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        final List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        OpportunityLineItem oli = new OpportunityLineItem();
        for(Id prodId : mapProd.keySet()) {    
            oli = utils.createOppLineItem(opp, mapProd.get(prodId),  mapPBE.get(prodId));
            oli.DES_Funding_Transfer_Price__c = 10;
            oli.avg_balance_annual_amount__c = 100;
            oli.fprd__GBL_Product_version__c = lpv.get(1).Id;
            oli.syndicated_loan_drawn_amount__c = 1;
            oli.DES_Risk_Fee_Next_12_Months__c = 1;
            oli.solution_name_path_desc__c = 'ECA Guarantee';
            oli.opening_fee_per__c=1;
            oli.unit_price_with_tax_amount__c = 1;
            oli.opportunity_sold_prdt_number__c = 1;
            oli.deferred_fee_per__c = 1; 
            oli.opening_fee_amount__c = 1; 
            oli.loan_tenor_month_desc__c = 1;
            oli.DES_Price_Percent__c = 1;
            oli.DES_Volume_in_Amounts__c = 1; 
            
            oliList.add(oli);
        }
        
        oliList.get(0).fprd__GBL_Product_version__c = lpv.get(0).Id;//fprd__Version_number__c = 1/DES_Working_Capital
        oliList.get(0).subproduct_name__c = Label.DES_Prod_Guarantees_SBLCs;
        
        oliList.get(1).fprd__GBL_Product_version__c = null; //NOSONAR
        
        oliList.get(8).subproduct_name__c = Label.DES_Prod_Letter_of_Credit;
        oliList.get(8).solution_name_path_desc__c = 'Import LC with Beneficiary Financing';
        
        oliList.get(9).subproduct_name__c = Label.DES_Prod_Trade_Loans;
        
        oliList.get(10).subproduct_name__c = Label.DES_Prod_Guarantees_SBLCs;
        
        oliList.get(11).subproduct_name__c = Label.DES_Prod_Letter_of_Credit;
        oliList.get(11).solution_name_path_desc__c = 'LC Silent Confirmation';
        
        oliList.get(12).subproduct_name__c= Label.DES_Prod_Letter_of_Credit; 
        oliList.get(12).solution_name_path_desc__c =  'LC Confirmation and Discount';
        
        oliList.get(13).subproduct_name__c= Label.DES_Prod_Trade_Loans; 
        oliList.get(13).solution_name_path_desc__c =  'FIEM';
        
        oliList.get(14).subproduct_name__c= Label.DES_Prod_Trade_Loans; 
        oliList.get(14).solution_name_path_desc__c =  'TB_GUARANTEES';
        
        oliList.get(15).subproduct_name__c = Label.DES_Prod_Trade_Loans; 
        oliList.get(15).solution_name_path_desc__c =  '';
        
        
        oliList.get(16).DES_Price_Percent__c = 1;
        oliList.get(16).DES_Volume_in_Amounts__c = 1;
        
        return oliList;
    }
    
    private static Boolean checkDeleted(Set<Id> idOpp) {
        Boolean output = true;
        Set<String> listaNombres;
        String resultado;
        final List<Opportunity> lstOpp = [SELECT id, Name, gf_opportunity_product_desc__c , (SELECT id, Name, OpportunityId, Product2.Name FROM OpportunityLineItems) FROM Opportunity WHERE id = :idOpp LIMIT 5000];
        for(Opportunity opp : lstOpp) {
            listaNombres = new Set<String>();
            for(OpportunityLineItem oppLine : opp.OpportunityLineItems) {
                listaNombres.add(oppLine.Product2.Name);
            }
            resultado = String.join(new List<String>(listaNombres),',');
            if(opp.gf_opportunity_product_desc__c  != resultado) {
                System.debug('_1_' + opp.gf_opportunity_product_desc__c);
                System.debug('_2_' + resultado);
                
                output = false;
                break;
            } 
        }
        return output;
        
    }
    
    private static Map<Id, OpportunityLineItem> dameOLI () {
        return new Map<Id, OpportunityLineItem>([SELECT Id, multi_tranche_type__c,opening_fee_per__c, deferred_fee_per__c, DES_Funding_Transfer_Price__c,avg_balance_annual_amount__c,
                                                 fprd__GBL_Product_version__c, solution_classification_desc__c, 
                                                 syndicated_loan_drawn_amount__c, DES_Risk_Fee_Next_12_Months__c, solution_name_path_desc__c, subproduct_name__c,
                                                 opening_fee_amount__c, loan_tenor_month_desc__c, DES_Price_Percent__c, DES_Volume_in_Amounts__c,
                                                 unit_price_with_tax_amount__c,opportunity_sold_prdt_number__c, user_profile_id__c,  
                                                 Opportunity.gf_opportunity_product_desc__c, Product2.Name 
                                                 FROM OpportunityLineItem  
                                                 LIMIT 5000]);
    }
      
    private static  Map<Id, Opportunity> dameOpp () {
        return new Map<Id,Opportunity> ([SELECT Id, gf_opportunity_product_desc__c FROM Opportunity LIMIT 5000]);
    }

    
    /**
* test fillDeferredFees(OpportunityLineItem olli)
es user_profile_id__c 'BBVA Desktop GTB Business Development' O 'BBVA Desktop GTB Standard'

*/
    @isTest
    static void testFillDeferredFees1() {
        test.startTest();
        //   User user1,user2;
        
        final Map<Id, OpportunityLineItem> olli = dameOLI();
        OpportunityLineItem oli = olli.values().get(0);
        //system.runAs(user1) { //('BBVA Desktop GTB Business Development');
        oli.deferred_fee_per__c = null; //NOSONAR
        oli = DES_relatedProductsTriggerHandler.fillDeferredFees(oli);
        System.assert(oli.user_profile_id__c == ('BBVA Desktop GTB Business Development') 
                      || oli.user_profile_id__c == ('BBVA Desktop GTB Standard') 
                      ? oli.deferred_fee_per__c == 100 
                      : oli.deferred_fee_per__c == 50 
                      ,'para este usuario su deferred_fee_per__c ha de ser 100');
        //}
        
        test.stopTest();
    }
    
    /**
* test fillDeferredFees(OpportunityLineItem olli)
no es user_profile_id__c 'BBVA Desktop GTB Business Development' ni 'BBVA Desktop GTB Standard'
*/
    @isTest
    static void testFillDeferredFees2() {
        test.startTest();
        
        final Map<Id, OpportunityLineItem> olli = dameOLI();
        OpportunityLineItem oli = olli.values().get(0);
        oli.deferred_fee_per__c = null; //NOSONAR
     
        
        //       system.runAs(user2) {
        oli = DES_relatedProductsTriggerHandler.fillDeferredFees(oli);
        System.assert(oli.user_profile_id__c == ('BBVA Desktop GTB Business Development') 
                      || oli.user_profile_id__c == ('BBVA Desktop GTB Standard') 
                      ? oli.deferred_fee_per__c == 100 
                      : oli.deferred_fee_per__c == 50 
                      ,'para este usuario su deferred_fee_per__c ha de ser 50');
        //     }
        
        test.stopTest();
    }

    
    /**
* test fillOppProductsHelper(List<OpportunityLineItem> lstOppLine,List<Opportunity> lstOppUpd, List<Opportunity> lstOpp);
*/
    @isTest
    static void testFillOppProductsHelper() {
        test.startTest();
        final Map<Id, OpportunityLineItem> olli = dameOLI();
        // OpportunityLineItem oli = olli.values().get(0);
        final Map<Id, Opportunity> oppMap = dameOpp();
        final List<Opportunity> lstOppUpd = oppMap.values();
        final List<Opportunity> lstOpp = oppMap.values();
        system.debug('handlertest  ' + olli.values().get(0).Opportunity.gf_opportunity_product_desc__c);
        olli.values().get(0).Opportunity.gf_opportunity_product_desc__c = 'desc';
        DES_relatedProductsTriggerHandler.fillOppProductsHelper(olli.values(), lstOppUpd, lstOpp);
        System.assert(!checkDeleted(oppMap.keySet()), 'gf_opportunity_product_desc__c no tiene sus oppLine.Product2.Name separadas por comas');
        test.stopTest();
    }
    
      /**test DES_relatedProductsTriggerHandler.deleteOppPrducts(List<OpportunityLineItem>)
*/
    @isTest
    static void testDeleteOppPrducts() {
        test.startTest();
        final Map<Id, OpportunityLineItem> olli = dameOLI();
        DES_relatedProductsTriggerHandler.deleteOppPrducts(olli.values());
        
        final Set<Id> idOpp = new Set<Id>();
        for(OpportunityLineItem oppLine : olli.values()) {
            idOpp.add(oppLine.OpportunityId);
        }
        System.assert(checkDeleted(idOpp), 'gf_opportunity_product_desc__c no tiene sus oppLine.Product2.Name separadas por comas');
        test.stopTest();
    }
}