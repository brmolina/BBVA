@isTest
public class PotRevenuesProductsPerRegionCntTest {
    @isTest
    public static void PotRevenuesProductsPerRegionCnt(){

          DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
          Boolean devuelveJSON = false;

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
          opp3.DES_Booking_Geography__c = 'Compass';
          oppList.add(opp3);
          Opportunity opp4 = utilTestClass.createOpportunity(acc1);
          opp4.StageName = Label.DES_Proposal;
          opp4.DES_Booking_Geography__c = 'HK';
          oppList.add(opp4);
          Opportunity opp5 = utilTestClass.createOpportunity(acc1);
          opp5.StageName = Label.DES_Proposal;
          opp5.DES_Booking_Geography__c = 'MX';
          oppList.add(opp5);
          Opportunity opp6 = utilTestClass.createOpportunity(acc1);
          opp6.StageName = Label.DES_Proposal;
          opp6.DES_Booking_Geography__c = 'ES';
          oppList.add(opp6);
          Opportunity opp7 = utilTestClass.createOpportunity(acc1);
          opp7.StageName = Label.DES_Proposal;
          opp7.DES_Booking_Geography__c = 'UY';
          oppList.add(opp7);
          insert oppList;

          Test.StartTest();

          Product2 prod1 =  utilTestClass.createProduct('Working Capital');
          insert prod1;

          PricebookEntry pricebook1 = utilTestClass.createPricebookEntry(prod1);
          insert pricebook1;

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
          OpportunityLineItem oppLineIt4 = utilTestClass.createOppLineItem(opp4, prod1, pricebook1);
          oppLineIt4.pre_oppy_revenue_next_12m_amount__c = 5000;
          oppLineItemList.add(oppLineIt4);
          OpportunityLineItem oppLineIt5 = utilTestClass.createOppLineItem(opp5, prod1, pricebook1);
          oppLineIt5.pre_oppy_revenue_next_12m_amount__c = 5000;
          oppLineItemList.add(oppLineIt5);
          OpportunityLineItem oppLineIt6 = utilTestClass.createOppLineItem(opp6, prod1, pricebook1);
          oppLineIt6.pre_oppy_revenue_next_12m_amount__c = 5000;
          oppLineItemList.add(oppLineIt6);
          OpportunityLineItem oppLineIt7 = utilTestClass.createOppLineItem(opp7, prod1, pricebook1);
          oppLineIt7.pre_oppy_revenue_next_12m_amount__c = 5000;
          oppLineItemList.add(oppLineIt7);
          insert oppLineItemList;

          String resRelOpps = PotRevenuesProductsPerRegionCnt.getData(acc1.Id, 'GTB');
          Map<String, Map<String, Double>> resMapStage = (Map<String, Map<String, Double>>)JSON.deserialize(resRelOpps, Map<String, Map<String, Double>>.class);

          String resOppProds = PotRevenuesProductsPerRegionCnt.getOppProducts(acc1.Id, 'GTB');
          List<PotRevenuesProductsPerRegionCnt.WrapperClass> resListOppProduct = (List<PotRevenuesProductsPerRegionCnt.WrapperClass>)JSON.deserialize(resOppProds, List<PotRevenuesProductsPerRegionCnt.WrapperClass>.class);
          if(resListOppProduct != null){
            devuelveJSON = true;
          }
          System.assertEquals(devuelveJSON, true);

          String resUser = PotRevenuesProductsPerRegionCnt.getCurrentUserISOCode();


          Test.StopTest();

    }


}