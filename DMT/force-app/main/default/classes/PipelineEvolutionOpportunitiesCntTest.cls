@isTest
public class PipelineEvolutionOpportunitiesCntTest {
    @isTest
    public static void PipelineEvolutionOpportunitiesCnt1(){

        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

        Account acc1 = utilTestClass.createClient();
        insert acc1;

        List <Product2> prodList = new List <Product2>();
        Product2 prod1 = utilTestClass.createProduct('ProductGTB');
        prodList.add(prod1);
        Product2 prod2 = utilTestClass.createProduct('Credit');
        prod2.Family = 'GM';
        prodList.add(prod2);
        insert prodList;

        List <PricebookEntry> pricebookEntryList= new List <PricebookEntry>();
        PricebookEntry priceBookEntryProd1 = utilTestClass.createPricebookEntry(prod1);
        pricebookEntryList.add(priceBookEntryProd1);
        PricebookEntry priceBookEntryProd2 = utilTestClass.createPricebookEntry(prod2);
        pricebookEntryList.add(priceBookEntryProd2);
        insert pricebookEntryList;

        List <Opportunity> oppList = new List <Opportunity>();
        Opportunity opp1 = utilTestClass.createOpportunity(acc1);
        opp1.StageName = Label.DES_Proposal;
        opp1.CloseDate = Date.today().addMonths(1);//Opp1 Closed Date one month after today
        oppList.add(opp1);
        Opportunity opp2 = utilTestClass.createOpportunity(acc1);
        opp2.StageName = Label.DES_Proposal;
        opp2.CloseDate = Date.today().addMonths(2);//Opp2 Closed Date two months after today
        oppList.add(opp2);
        Opportunity opp3 = utilTestClass.createOpportunity(acc1);
        opp3.StageName = Label.DES_Proposal;
        opp3.CloseDate = Date.today();//Opp3 Closed Date today
        oppList.add(opp3);
        Opportunity opp4 = utilTestClass.createOpportunity(acc1);
        opp4.StageName = Label.DES_Proposal;
        opp4.CloseDate = Date.today();//Opp4 Closed Date today
        oppList.add(opp4);
        Opportunity opp5 = utilTestClass.createOpportunity(acc1);
        opp5.StageName = Label.DES_Proposal;
        opp5.CloseDate = Date.today().addMonths(1);//Opp5 Closed Date one month after today
        oppList.add(opp5);
        Opportunity opp6 = utilTestClass.createOpportunity(acc1);
        opp6.StageName = Label.DES_Proposal;
        opp6.CloseDate = Date.today().addMonths(-1);//Opp6 Closed Date one month before today
        oppList.add(opp6);
        Opportunity opp7 = utilTestClass.createOpportunity(acc1);
        opp7.StageName = Label.DES_Proposal;
        opp7.CloseDate = Date.today().addMonths(-1);//Opp7 Closed Date today one month before today
        oppList.add(opp7);

        insert oppList;

        Test.setCreatedDate(opp1.Id, Date.today().addMonths(-5));//Opp1 Created Date 5 months before today
        Test.setCreatedDate(opp2.Id, Date.today());//Opp2 Created Date Today
        Test.setCreatedDate(opp3.Id, Date.today().addMonths(-3));//Opp3 Created Date 3 months before today
        Test.setCreatedDate(opp4.Id, Date.today().addMonths(-1));//Opp4 Created Date 1 month before today
        Test.setCreatedDate(opp5.Id, Date.today().addMonths(-2));//Opp5 Created Date 2 months before today
        Test.setCreatedDate(opp6.Id, Date.today().addMonths(-4));//Opp6 Created Date 4 months before today
        Test.setCreatedDate(opp7.Id, Date.today().addMonths(-3));//Opp7 Created Date 3 months before today

        List <OpportunityLineItem> oppLineItemList = new List <OpportunityLineItem>();
        OpportunityLineItem oppLineIt11 = utilTestClass.createOppLineItem(opp1, prod1,priceBookEntryProd1);
        oppLineIt11.pre_oppy_revenue_next_12m_amount__c = 20;
        oppLineItemList.add(oppLineIt11);
        OpportunityLineItem oppLineIt12 = utilTestClass.createOppLineItem(opp1, prod2,priceBookEntryProd2);
        oppLineIt12.pre_oppy_revenue_next_12m_amount__c = 30;
        oppLineItemList.add(oppLineIt12);
        OpportunityLineItem oppLineIt21 = utilTestClass.createOppLineItem(opp2, prod1,priceBookEntryProd1);
        oppLineIt21.pre_oppy_revenue_next_12m_amount__c = 40;
        oppLineItemList.add(oppLineIt21);
        OpportunityLineItem oppLineIt32 = utilTestClass.createOppLineItem(opp3, prod2,priceBookEntryProd2);
        oppLineIt32.pre_oppy_revenue_next_12m_amount__c = 60;
        oppLineIt32.solution_name_path_desc__c = 'Bonds';
        oppLineItemList.add(oppLineIt32);
        OpportunityLineItem oppLineIt42 = utilTestClass.createOppLineItem(opp4, prod2,priceBookEntryProd2);
        oppLineIt42.pre_oppy_revenue_next_12m_amount__c = 10;
        oppLineIt42.solution_name_path_desc__c = 'Bonds';
        oppLineItemList.add(oppLineIt42);
        OpportunityLineItem oppLineIt51 = utilTestClass.createOppLineItem(opp5, prod1,priceBookEntryProd1);
        oppLineIt51.pre_oppy_revenue_next_12m_amount__c = 40;
        oppLineItemList.add(oppLineIt51);
        OpportunityLineItem oppLineIt62 = utilTestClass.createOppLineItem(opp6, prod2,priceBookEntryProd2);
        oppLineIt62.pre_oppy_revenue_next_12m_amount__c = 60;
        oppLineIt62.solution_name_path_desc__c = 'Bonds';
        oppLineItemList.add(oppLineIt62);
        OpportunityLineItem oppLineIt72 = utilTestClass.createOppLineItem(opp7, prod2,priceBookEntryProd2);
        oppLineIt72.pre_oppy_revenue_next_12m_amount__c = 10;
        oppLineIt72.solution_name_path_desc__c = 'Bonds';
        oppLineItemList.add(oppLineIt72);

        Test.StartTest();
		insert oppLineItemList;



        opp3.StageName = Label.DES_Ready_to_close;
        opp4.DES_Reasons_Lost__c = 'Pricing';
        opp4.DES_Description_reason_for_lost_deal__c = 'Pricing';
        opp4.StageName = Label.DES_Ready_to_close;
        opp6.StageName = Label.DES_Ready_to_close;
        opp7.DES_Reasons_Lost__c = 'Pricing';
        opp7.DES_Description_reason_for_lost_deal__c = 'Pricing';
        opp7.StageName = Label.DES_Ready_to_close;
        update oppList;

/*
        opp3.StageName = Label.DES_Closed_Won;
        opp3.opportunity_correct_ind_type__c =  true;
        opp4.StageName = Label.DES_Closed_Lose;
        opp4.opportunity_correct_ind_type__c = true;
        opp6.StageName = Label.DES_Closed_Won;
        opp6.opportunity_correct_ind_type__c = true;
        opp7.StageName = Label.DES_Closed_Lose;
        opp7.opportunity_correct_ind_type__c = true;
        update oppList;

        opp6.DES_Date_Won_Lost__c = opp6.CloseDate;
        opp7.DES_Date_Won_Lost__c = opp7.CloseDate;
        update oppList;
*/

        String resgetData = PipelineEvolutionOpportunitiesCnt.getData(acc1.Id);
        Map<String, Map<String, Double>> resmapMonth = (Map<String, Map<String, Double>>)JSON.deserialize(resgetData, Map<String, Map<String, Double>>.class);

        String resgetOppProducts = PipelineEvolutionOpportunitiesCnt.getOppProducts(acc1.Id);
        List<PipelineEvolutionOpportunitiesCnt.WrapperClass> ListOppProducts =  (List<PipelineEvolutionOpportunitiesCnt.WrapperClass>)JSON.deserialize(resgetOppProducts, List<PipelineEvolutionOpportunitiesCnt.WrapperClass>.class);

        String resUserInfo = PipelineEvolutionOpportunitiesCnt.getCurrentUserISOCode();
        System.assertEquals('EUR',resUserInfo);
        Test.StopTest();
    }

    @isTest
    public static void PipelineEvolutionOpportunitiesCnt3(){

        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

        Account acc1 = utilTestClass.createClient();
        insert acc1;

        List <Product2> prodList = new List <Product2>();
        Product2 prod1 = utilTestClass.createProduct('ProductGTB');
        prodList.add(prod1);
        Product2 prod2 = utilTestClass.createProduct('Credit');
        prod2.Family = 'GM';
        prodList.add(prod2);
        insert prodList;

        List <PricebookEntry> pricebookEntryList= new List <PricebookEntry>();
        PricebookEntry priceBookEntryProd1 = utilTestClass.createPricebookEntry(prod1);
        pricebookEntryList.add(priceBookEntryProd1);
        PricebookEntry priceBookEntryProd2 = utilTestClass.createPricebookEntry(prod2);
        pricebookEntryList.add(priceBookEntryProd2);
        insert pricebookEntryList;

        List <Opportunity> oppList = new List <Opportunity>();
        Opportunity opp1 = utilTestClass.createOpportunity(acc1);
        opp1.StageName = Label.DES_Proposal;
        opp1.CloseDate = Date.today().addMonths(1);//Opp1 Closed Date one month after today
        oppList.add(opp1);
        Opportunity opp2 = utilTestClass.createOpportunity(acc1);
        opp2.StageName = Label.DES_Proposal;
        opp2.CloseDate = Date.today().addMonths(2);//Opp2 Closed Date two months after today
        oppList.add(opp2);
        Opportunity opp3 = utilTestClass.createOpportunity(acc1);
        opp3.StageName = Label.DES_Proposal;
        opp3.CloseDate = Date.today();//Opp3 Closed Date today
        oppList.add(opp3);
        Opportunity opp4 = utilTestClass.createOpportunity(acc1);
        opp4.StageName = Label.DES_Proposal;
        opp4.CloseDate = Date.today();//Opp4 Closed Date today
        oppList.add(opp4);
        Opportunity opp5 = utilTestClass.createOpportunity(acc1);
        opp5.StageName = Label.DES_Proposal;
        opp5.CloseDate = Date.today().addMonths(1);//Opp5 Closed Date one month after today
        oppList.add(opp5);
        Opportunity opp6 = utilTestClass.createOpportunity(acc1);
        opp6.StageName = Label.DES_Proposal;
        opp6.CloseDate = Date.today().addMonths(-1);//Opp6 Closed Date one month before today
        oppList.add(opp6);
        Opportunity opp7 = utilTestClass.createOpportunity(acc1);
        opp7.StageName = Label.DES_Proposal;
        opp7.CloseDate = Date.today().addMonths(-1);//Opp7 Closed Date today one month before today
        oppList.add(opp7);
        opp3.StageName = Label.DES_Ready_to_close;
        opp4.DES_Reasons_Lost__c = 'Pricing';
        opp4.DES_Description_reason_for_lost_deal__c = 'Pricing';
        opp4.StageName = Label.DES_Ready_to_close;
        opp6.StageName = Label.DES_Ready_to_close;
        opp7.DES_Reasons_Lost__c = 'Pricing';
        opp7.DES_Description_reason_for_lost_deal__c = 'Pricing';
        opp7.StageName = Label.DES_Ready_to_close;
        opp3.StageName = Label.DES_Closed_Won;
        opp3.opportunity_correct_ind_type__c =  true;
        opp4.StageName = Label.DES_Closed_Lose;
        opp4.opportunity_correct_ind_type__c = true;
        opp6.StageName = Label.DES_Closed_Won;
        opp6.opportunity_correct_ind_type__c = true;
        opp7.StageName = Label.DES_Closed_Lose;
        opp7.opportunity_correct_ind_type__c = true;

        insert oppList;

        Test.setCreatedDate(opp1.Id, Date.today().addMonths(-5));//Opp1 Created Date 5 months before today
        Test.setCreatedDate(opp2.Id, Date.today());//Opp2 Created Date Today
        Test.setCreatedDate(opp3.Id, Date.today().addMonths(-3));//Opp3 Created Date 3 months before today
        Test.setCreatedDate(opp4.Id, Date.today().addMonths(-1));//Opp4 Created Date 1 month before today
        Test.setCreatedDate(opp5.Id, Date.today().addMonths(-2));//Opp5 Created Date 2 months before today
        Test.setCreatedDate(opp6.Id, Date.today().addMonths(-4));//Opp6 Created Date 4 months before today
        Test.setCreatedDate(opp7.Id, Date.today().addMonths(-3));//Opp7 Created Date 3 months before today

        List <OpportunityLineItem> oppLineItemList = new List <OpportunityLineItem>();
        OpportunityLineItem oppLineIt11 = utilTestClass.createOppLineItem(opp1, prod1,priceBookEntryProd1);
        oppLineIt11.pre_oppy_revenue_next_12m_amount__c = 20;
        oppLineItemList.add(oppLineIt11);
        OpportunityLineItem oppLineIt12 = utilTestClass.createOppLineItem(opp1, prod2,priceBookEntryProd2);
        oppLineIt12.pre_oppy_revenue_next_12m_amount__c = 30;
        oppLineItemList.add(oppLineIt12);
        OpportunityLineItem oppLineIt21 = utilTestClass.createOppLineItem(opp2, prod1,priceBookEntryProd1);
        oppLineIt21.pre_oppy_revenue_next_12m_amount__c = 40;
        oppLineItemList.add(oppLineIt21);
        OpportunityLineItem oppLineIt32 = utilTestClass.createOppLineItem(opp3, prod2,priceBookEntryProd2);
        oppLineIt32.pre_oppy_revenue_next_12m_amount__c = 60;
        oppLineIt32.solution_name_path_desc__c = 'Bonds';
        oppLineItemList.add(oppLineIt32);
        OpportunityLineItem oppLineIt42 = utilTestClass.createOppLineItem(opp4, prod2,priceBookEntryProd2);
        oppLineIt42.pre_oppy_revenue_next_12m_amount__c = 10;
        oppLineIt42.solution_name_path_desc__c = 'Bonds';
        oppLineItemList.add(oppLineIt42);
        OpportunityLineItem oppLineIt51 = utilTestClass.createOppLineItem(opp5, prod1,priceBookEntryProd1);
        oppLineIt51.pre_oppy_revenue_next_12m_amount__c = 40;
        oppLineItemList.add(oppLineIt51);
        OpportunityLineItem oppLineIt62 = utilTestClass.createOppLineItem(opp6, prod2,priceBookEntryProd2);
        oppLineIt62.pre_oppy_revenue_next_12m_amount__c = 60;
        oppLineIt62.solution_name_path_desc__c = 'Bonds';
        oppLineItemList.add(oppLineIt62);
        OpportunityLineItem oppLineIt72 = utilTestClass.createOppLineItem(opp7, prod2,priceBookEntryProd2);
        oppLineIt72.pre_oppy_revenue_next_12m_amount__c = 10;
        oppLineIt72.solution_name_path_desc__c = 'Bonds';
        oppLineItemList.add(oppLineIt72);

        Test.StartTest();
		insert oppLineItemList;




        opp6.DES_Date_Won_Lost__c = opp6.CloseDate;
        opp7.DES_Date_Won_Lost__c = opp7.CloseDate;
        update oppList;

        String resgetData = PipelineEvolutionOpportunitiesCnt.getData(acc1.Id);
        Map<String, Map<String, Double>> resmapMonth = (Map<String, Map<String, Double>>)JSON.deserialize(resgetData, Map<String, Map<String, Double>>.class);

        String resgetOppProducts = PipelineEvolutionOpportunitiesCnt.getOppProducts(acc1.Id);
        List<PipelineEvolutionOpportunitiesCnt.WrapperClass> ListOppProducts =  (List<PipelineEvolutionOpportunitiesCnt.WrapperClass>)JSON.deserialize(resgetOppProducts, List<PipelineEvolutionOpportunitiesCnt.WrapperClass>.class);

        String resUserInfo = PipelineEvolutionOpportunitiesCnt.getCurrentUserISOCode();
        System.assertEquals('EUR',resUserInfo);
        Test.StopTest();
    }

}