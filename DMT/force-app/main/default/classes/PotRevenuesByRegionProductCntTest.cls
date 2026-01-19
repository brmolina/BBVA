@isTest
private class PotRevenuesByRegionProductCntTest
{
    @isTest
    static void PotRevenuesByRegionProductCnt()
    {
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

        Account acc1 = utilTestClass.createClient();
        insert acc1;

        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp1 = utilTestClass.createOpportunity(acc1);
        opp1.StageName = Label.DES_Proposal;
        oppList.add(opp1);
        Opportunity opp2 = utilTestClass.createOpportunity(acc1);
        opp2.StageName = Label.DES_Proposal;
        opp2.DES_Booking_Geography__c = 'BE';
        oppList.add(opp2);
        Opportunity opp3 = utilTestClass.createOpportunity(acc1);
        opp3.StageName = Label.DES_Proposal;
        opp3.DES_Booking_Geography__c = 'BE';
        oppList.add(opp3);
        insert oppList;

        Product2 prod1 =  utilTestClass.createProduct('Working Capital');
        insert prod1;
        Product2 prod2 =  utilTestClass.createProduct('Credit');
        prod2.Family = 'GM';
        insert prod2;
        
        Test.StartTest();
        
        PricebookEntry pricebook1 = utilTestClass.createPricebookEntry(prod1);
        insert pricebook1;
        PricebookEntry pricebook2 = utilTestClass.createPricebookEntry(prod2);
        insert pricebook2;

        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
        OpportunityLineItem oppLineIt1 = utilTestClass.createOppLineItem(opp1, prod1, pricebook1);
        oppLineIt1.pre_oppy_revenue_next_12m_amount__c = 5000;
        oppLineItemList.add(oppLineIt1);
        OpportunityLineItem oppLineIt2 = utilTestClass.createOppLineItem(opp2, prod1, pricebook1);
        oppLineIt2.pre_oppy_revenue_next_12m_amount__c = 5000;
        oppLineItemList.add(oppLineIt2);
        OpportunityLineItem oppLineIt3 = utilTestClass.createOppLineItem(opp3, prod1, pricebook1);
        oppLineIt3.pre_oppy_revenue_next_12m_amount__c = 5000;
        oppLineItemList.add(oppLineIt3);
        insert oppLineItemList;

        String resJsonGlobal = PotRevenuesByRegionProductCnt.getData(acc1.Id);
        PotRevenuesByRegionProductCnt.WrapperGlobalData resData = (PotRevenuesByRegionProductCnt.WrapperGlobalData)JSON.deserialize(resJsonGlobal, PotRevenuesByRegionProductCnt.WrapperGlobalData.class);

        System.assertEquals(5000, oppLineIt1.pre_oppy_revenue_next_12m_amount__c);

        String resOppProds = PotRevenuesByRegionProductCnt.getOppProducts(acc1.Id);

        Test.StopTest();

    }
}