/**********************************************************************************
* @author       Global Desktop
* @date         15/03/2019
* @description  Test de la case OpportunitiesInProgressByFamilyCont
* @Revision

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------
0.1            15/03/2019      Global Desktop    Testeo de la clase OpportunitiesInProgressByFamilyCont
**********************************************************************************/
@isTest
public class OpportunitiesInProgressByFamilyContTest{
  
  /**
  * @author Global Desktop
  * @description Test de la clase FamilyProductCards_Controller
  */
    @isTest
    public static void OpportunitiesInProgressByFamilyCont() {
      final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
      Boolean devuelveJSON = false;
       
       final id accountGroupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
          
      //Creacion grupo
    final Account accGroup = utilTestClass.createClient();
      accGroup.RecordTypeId = accountGroupRT;
      accGroup.DES_Structure_Type__c = 'Group';
      accGroup.DES_BBVA_Segmentation__c = 'C';
      accGroup.DES_Country_Client__c = 'ES';
    insert accGroup;
       
      final Account acc1 = utilTestClass.createClient();
      acc1.DES_Main_Parent__c = accGroup.Id;
      insert acc1;
      
      //Insertamos la relacion
      final AMH_GBL_Account_Relationship__c relatedAcc = new AMH_GBL_Account_Relationship__c();
      relatedAcc.AMH_Child_Account__c = acc1.Id;
      relatedAcc.AMH_Parent_Account__c = accGroup.Id;
      relatedAcc.AMH_Vision__c = 'Business';
      insert relatedAcc;
  
      final Opportunity opp1 = utilTestClass.createOpportunity(accGroup);
      opp1.StageName = Label.DES_Proposal;
      insert opp1;
     
      final Product2 prod1 =  utilTestClass.createProduct('Working Capital');
      insert prod1;
        
      final PricebookEntry pricebook1 = utilTestClass.createPricebookEntry(prod1);
      insert pricebook1;
        
      final OpportunityLineItem oppLineIt1 = utilTestClass.createOppLineItem(opp1, prod1, pricebook1);
      insert oppLineIt1;
        
      Test.StartTest();
      
      final String resRelOpps = OpportunitiesInProgressByFamilyCont.getRelatedOpportunities('2',accGroup.Id, 'GTB', 'Spain');
        final String oppsNoCountry = OpportunitiesInProgressByFamilyCont.getRelatedOpportunities('2',accGroup.Id, 'GTB', '');
        system.debug(oppsNoCountry);
      OpportunitiesInProgressByFamilyCont.getFieldLabels(accGroup.Id,'Spain');     
      List<OpportunitiesInProgressByFamilyCont.WrapperClass> reslistRelOpps;
      reslistRelOpps = (List<OpportunitiesInProgressByFamilyCont.WrapperClass>)JSON.deserialize(resRelOpps, List<OpportunitiesInProgressByFamilyCont.WrapperClass>.class);                
      if(reslistRelOpps != null) {
          devuelveJSON = true;
      }
      System.assertEquals(devuelveJSON, true);

      Test.StopTest();
    }
}