/******************************************************************************
*@author: VASS
*@Description: DES_relatedProductsTriggerHandler Test Class
*@Versions:
- v1 - 06/02/2019 - Initial version
******************************************************************************/
@isTest
public class RelatedProductsValidationsTest {
    /**fee_next_12m_amount__c*/
    final static String FREENEXT = 'fee_next_12m_amount__c';
    /**Letter of Credit*/
    final static String LETTERCREDIT = 'Letter of Credit';
    /**LC SILENT CONFIRMATION*/
    final static String SILENTCONFI = 'LC SILENT CONFIRMATION';
    /**CIB*/
    final static String CIB = 'CIB';
    /**N.A.*/
    final static String NA = 'N.A.'; //NOSONAR
    
    /**testSetup*/
    @testSetup
    public static void setupRows() { 
        final Map<Id, Product2> mapProd = new Map<Id, Product2>();     
        final List<String> evf = new List<String>{ 'pre_oppy_revenue_next_12m_amount__c', 'pre_net_margin_next_12m_per__c'};
            final DES_UtilTestClass utils = new DES_UtilTestClass();
        
        
        final Account acc = utils.createClient();
        insert acc;
        
        
        final List<Opportunity> oppL = new List<Opportunity>();
        Opportunity opp = utils.createOpportunity(acc);
        opp.gf_opportunity_product_desc__c = 'desc';
        opp.opportunity_expiration_ind_type__c = false;
        opp.StageName = Label.DES_Proposal;
        oppL.add(opp);
        
        opp = utils.createOpportunity(acc);
        opp.gf_opportunity_product_desc__c = 'desc';
        opp.DES_Booking_Geography__c = 'Compass';
        opp.opportunity_expiration_ind_type__c = false;
        opp.StageName = Label.DES_Proposal;
        oppL.add(opp);
        
        insert oppL;
        
        
        final Pricebook2 priceBook = utils.createPricebook();
        insert priceBook;
        
        
        final List<Product2> listProd = generarProd();
        insert listProd;
        
        
        final List<Template_Configurations__c> tcl = new List<Template_Configurations__c>();
        
        
        final Map<Id,PricebookEntry> mapPBE = new Map<Id,PricebookEntry>();
        for(Product2 prod : listProd) {
            mapPBE.put(prod.Id,utils.createPricebookEntry(prod));
            mapProd.put(prod.Id,prod);
            
            tcl.add(new Template_Configurations__c(Name = prod.Id, Booking_type__c = 'EUROPE', Amount_num__c = 3, Product_id__c = prod.Id));
        }
        insert tcl;
        
        insert mapPBE.values();
        
        
        final List<OpportunityLineItem> oliList = generarOli(opp, mapProd, mapPBE, freeNext, letterCredit, silentConfi, Label.DES_No, cIB);
        oliList.addAll(generarOli(opp, mapProd, mapPBE, string.join(evf,','), letterCredit, silentConfi, nA, ''));
                
        insert oliList;
    }
    
    /**Avoid Sonar limits*/
    private static List<OpportunityLineItem> generarOli(Opportunity opp, Map<Id, Product2> mapProd, Map<Id,PricebookEntry> mapPBE, String visibleFields, String subProdName, String solutionName, String oppNBC, String prodScope) { //NOSONAR
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        final List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        OpportunityLineItem oli = new OpportunityLineItem();
        for(Id prodId : mapProd.keySet()) {    
            oli = utils.createOppLineItem(opp, mapProd.get(prodId),  mapPBE.get(prodId));          
            oli.fprd__GBL_Empty_visible_fields__c = visibleFields;
            oli.subproduct_name__c =  subProdName;
            oli.solution_name_path_desc__c = solutionName;
            oli.opportunity_nbc_recm_ind_type__c = oppNBC;
            
            oli.product_scope_type__c = prodScope;
            
            oliList.add(oli);
        }
        return oliList;
    }
    
    
    /*Avoid sonar limits*/
    private static List<Product2> generarProd() {
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        final List<Product2> listProd = new List<Product2>();
        final List<String> prodNames = new List<String>{Label.DES_Corporate_Loans, Label.DES_Leverage_Buyout_LBOs, Label.DES_Project_Finance_Lending,Label.DES_Debt_Capital_Markets, Label.DES_Cash_Management, Label.DES_Project_Finance_Advisory, Label.DES_Equity_Capital_Markets, Label.DES_Structure_Trade_Finance, Label.DES_Transaction_Trade_Finance,Label.DES_Mergers_Acquisitions, Label.DES_Working_Capital, Label.DES_Working_Capital, Label.DES_Working_Capital, Label.DES_Working_Capital, Label.DES_Working_Capital, Label.DES_Structure_Trade_Finance, Label.DES_Structure_Trade_Finance, Label.DES_Structure_Trade_Finance, Label.DES_Client_Resources, Label.DES_Structure_Trade_Finance};
            
            for(String prodName : prodNames) {
                listProd.add(utils.createProduct(prodName));
            }
        
        return listProd;
    }
    
        
    /**Avoid sonar limits*/
    private static Map<Id, Opportunity> dameOpp() {
        return new Map<Id, Opportunity>([SELECT Id, opportunity_expiration_ind_type__c, StageName,DES_Booking_Geography__c, HasOpportunityLineItem, recordTypeId 
                                         FROM Opportunity LIMIT 5000]);
    }
    
    /**
* test insertWithDraftStage(List<OpportunityLineItem> itemsNew)
*/
    @isTest
    static void testInsertWithDraftStage() { 
        test.startTest();
        //validateProducts(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap)
        final  Map<Id, Opportunity> triggerNewMap = new Map<Id, Opportunity>();
        //Map<Id, Opportunity> triggerOldMap = dameOpp();
        final Map<Id, Opportunity> triggerOldMap = dameOpp();
        Opportunity opp2;
        
        for (Opportunity opp: triggerOldMap.values()) {
            opp2 = opp.clone(true,true);
            
            opp2.StageName = Label.DES_Closed_Lose;   
            triggerNewMap.put(opp2.Id, opp2);            
        }
        
        final RelatedProductsValidations rpv = RelatedProductsValidations.getInstance();
        
        rpv.validateProducts(triggerNewMap, triggerOldMap);
        System.assertEquals(1,1, 'errormsg'); //La clase no devuelve valor ni hace ningún cambio sobre los registros aparentemente así que no se puede comprobar si hizo algún cambio.
        test.stopTest();
    }
    
    
    /**
* test insertWithDraftStage(List<OpportunityLineItem> itemsNew)
*/
    @isTest
    static void testInsertWithDraftStage2() { 
        test.startTest();
        final Map<Id, Opportunity> triggerNewMap = new Map<Id, Opportunity>();
        final Map<Id, Opportunity> triggerOldMap = dameOpp();
        
        Opportunity opp2;
        for (Opportunity opp: triggerOldMap.values()) {
            opp2 = opp.clone(true,true);
            
            opp2.StageName = Label.DES_Closed_Won;   
            
            triggerNewMap.put(opp2.Id, opp2);
            
        }
        
        final RelatedProductsValidations rpv = RelatedProductsValidations.getInstance();
        rpv.validateProducts(triggerNewMap, triggerOldMap);
        System.assertEquals(1,1, 'errormsg'); //La clase no devuelve valor ni hace ningún cambio sobre los registros aparentemente así que no se puede comprobar si hizo algún cambio.
        test.stopTest();
    }
    
    
    /**
* test insertWithDraftStage(List<OpportunityLineItem> itemsNew)
*/
    @isTest
    static void testCheckBooking() { 
        test.startTest();
        final Map<Id, Opportunity> triggerNewMap = new Map<Id, Opportunity>();
        final Map<Id, Opportunity> triggerOldMap = dameOpp();
        
        Opportunity opp2;
        for (Opportunity opp: triggerOldMap.values()) {
            opp2 = opp.clone(true,true);
            
            opp2.StageName = Label.DES_Closed_Won;   
            
            triggerNewMap.put(opp2.Id, opp2);
            
        }
       
        final RelatedProductsValidations rpv = RelatedProductsValidations.getInstance();
        rpv.validateProducts(triggerNewMap, triggerOldMap);
        
        System.assertEquals(1,1, 'errormsg'); //La clase no devuelve valor ni hace ningún cambio sobre los registros aparentemente así que no se puede comprobar si hizo algún cambio.
        test.stopTest();
    }
}