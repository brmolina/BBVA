@isTest
public class RateOfSuccessChartCntTest {

    @isTest
    public static void RateOfSuccessChartCnt(){

        Date todayDate = System.today();

        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

        Account acc1 = utilTestClass.createClient();
        insert acc1;

        List <Product2> prodList = new List <Product2>();
        Product2 prod1 = utilTestClass.createProduct('Cash Management');
        prodList.add(prod1);
        Product2 prod2 = utilTestClass.createProduct('ProductIBF');
        prod2.Family = 'IBF';
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
        opp1.CloseDate = todayDate; //Opp1 Closed Date Today
        oppList.add(opp1);
        Opportunity opp2 = utilTestClass.createOpportunity(acc1);
        opp2.StageName = Label.DES_Proposal;
        opp2.CloseDate = todayDate.addMonths(-3);//Opp2 Closed 3 months after today
        oppList.add(opp2);
        Opportunity opp3 = utilTestClass.createOpportunity(acc1);
        opp3.StageName = Label.DES_Proposal;
        opp3.CloseDate = todayDate.addMonths(-6);//Opp3 Closed Date 6 months after today
        oppList.add(opp3);
        Opportunity opp4 = utilTestClass.createOpportunity(acc1);
        opp4.StageName = Label.DES_Proposal;
        opp4.CloseDate = todayDate.addMonths(-9);//Opp4 Closed Date 9 months after today
        oppList.add(opp4);
        insert oppList;
        Test.setCreatedDate(opp1.Id, todayDate.addMonths(-3));//Opp1 Created Date 3 months before today
        Test.setCreatedDate(opp2.Id, todayDate.addMonths(-6));//Opp2 Created Date 6 months before today
        Test.setCreatedDate(opp3.Id, todayDate.addMonths(-9));//Opp3 Created Date 9 months before today
        Test.setCreatedDate(opp4.Id, todayDate.addMonths(-12));//Opp4 Created Date 12 months before today
        
		Test.StartTest();
        List <OpportunityLineItem> oppLineItemList = new List <OpportunityLineItem>();
        OpportunityLineItem oppLineIt11 = utilTestClass.createOppLineItem(opp1, prod1,priceBookEntryProd1);
        oppLineIt11.subproduct_name__c = 'Electronic Channels';
        oppLineIt11.DES_Service__c = 'Collections - PoS';
        oppLineIt11.pre_oppy_revenue_next_12m_amount__c = 2000;
        oppLineIt11.DES_Annual_Fees__c = 2000;
        oppLineItemList.add(oppLineIt11);
        OpportunityLineItem oppLineIt12 = utilTestClass.createOppLineItem(opp1, prod2,priceBookEntryProd2);
        oppLineItemList.add(oppLineIt12);
        OpportunityLineItem oppLineIt21 = utilTestClass.createOppLineItem(opp2, prod1,priceBookEntryProd1);
        oppLineIt21.subproduct_name__c = 'Electronic Channels';
        oppLineIt21.DES_Service__c = 'Collections - PoS';
        oppLineIt21.pre_oppy_revenue_next_12m_amount__c = 2000;
        oppLineIt21.DES_Annual_Fees__c = 2000;
        oppLineItemList.add(oppLineIt21);
        OpportunityLineItem oppLineIt32 = utilTestClass.createOppLineItem(opp3, prod2,priceBookEntryProd2);
        oppLineItemList.add(oppLineIt32);
        OpportunityLineItem oppLineIt41 = utilTestClass.createOppLineItem(opp4, prod1,priceBookEntryProd1);
        oppLineIt41.subproduct_name__c = 'Electronic Channels';
        oppLineIt41.DES_Service__c = 'Collections - PoS';
        oppLineIt41.pre_oppy_revenue_next_12m_amount__c = 2000;
        oppLineIt41.DES_Annual_Fees__c = 2000;
        oppLineItemList.add(oppLineIt41);
        OpportunityLineItem oppLineIt42 = utilTestClass.createOppLineItem(opp4, prod2,priceBookEntryProd2);
        oppLineItemList.add(oppLineIt42);
        insert oppLineItemList;

        date d = System.today().addDays(-366);
		
        System.debug (':::::queries antes de Test.StartTest = '+ Limits.getQueries());//added to track queries
		
        oppList[0].StageName = Label.DES_Ready_to_close;
        update oppList;
		Test.StopTest();
        oppList[0].StageName = Label.DES_Closed_Won;
        oppList[0].opportunity_correct_ind_type__c = true;
        update oppList;
        

        System.debug ('oppLineItemList = ' + oppLineItemList);

        String resgetData = RateOfSuccessChartCnt.getData(acc1.Id);
        Map<String, Map<String, Double>> resmapStage = (Map<String, Map<String, Double>>)JSON.deserialize(resgetData, Map<String, Map<String, Double>>.class);
        System.debug('resmapStage = ' + resmapStage);
        //System.assertEquals(5.0, resmapStage.get('2018 Q1').get('GF'));
        //System.assertEquals(5.0, resmapStage.get('2018 Q2').get('GTB'));
        //System.assertEquals(5.0, resmapStage.get('2018 Q3').get('GF'));
        //System.assertEquals(5.0, resmapStage.get('2018 Q4').get('GTB'));

        String resgetOppProducts = RateOfSuccessChartCnt.getOppProducts(acc1.Id);
        List<RateOfSuccessChartCnt.WrapperClass> listOppProducts = (List<RateOfSuccessChartCnt.WrapperClass>)JSON.deserialize(resgetOppProducts, List<RateOfSuccessChartCnt.WrapperClass>.class);
        //System.assertEquals('5%', listOppProducts[0].expectedProbability);
        //System.assertEquals('5%', listOppProducts[1].expectedProbability);
        //System.assertEquals('GTB', listOppProducts[2].prodFam);
        //System.assertEquals('ProductGF', listOppProducts[3].prodName);
        //System.assertEquals('ProductGTB', listOppProducts[4].prodName);
        //System.assertEquals('5%', listOppProducts[5].expectedProbability);

        String resUserInfo = RateOfSuccessChartCnt.getCurrentUserISOCode();
        System.assertEquals('EUR',resUserInfo);

        System.debug (':::::queries dentro de Test.StartTest = ' + Limits.getQueries());//added to track queries

        
    }
}