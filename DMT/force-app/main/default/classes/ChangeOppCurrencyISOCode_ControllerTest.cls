@isTest
public class ChangeOppCurrencyISOCode_ControllerTest {
  public static Map<String, Opportunity> mapOpps = new Map<String, Opportunity>();

  /*
  *
  * @author Global Desktop  - DSL
  *
  */
	public static void dataNeeded() {
    mapOpps = new Map<String, Opportunity>();
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

		final String profileTest = [SELECT Id, Name FROM Profile WHERE Name = 'Desktop Integration' LIMIT 1].Id;
    final User userTest1 = utilTestClass.createUser(profileTest);
    userTest1.FirstName = 'usrName2 Test';
    insert userTest1;

    final User userTest2 = utilTestClass.createUser(profileTest,'NickAlias@t.com');
    userTest2.FirstName = 'usrName3 Test';
    insert userTest2;

    final Account accGroup = utilTestClass.createClient();
    accGroup.Name = 'Group Test 001';
    accGroup.DES_BBVA_Segmentation__c = 'B';
    accGroup.DES_Structure_Type__c = 'Group';
    accGroup.DES_Country_Client__c = 'ES';
		insert accGroup;

    final Opportunity opp = utilTestClass.createOpportunity(accGroup);
    insert opp;
    mapOpps.put('Opp1', opp);
	  Test.startTest();
    final Product2 prd = utilTestClass.createProduct('Product Test');
    insert prd;

    final PricebookEntry pbE = utilTestClass.createPricebookEntry(prd);
    insert pbE;

    final OpportunityLineItem oppli = utilTestClass.createOppLineItem(opp, prd, pbE);
    insert oppli;
    Test.stopTest();

	}

  /*
  *
  * @author Global Desktop  - DSL
  *
  */
  @isTest
  public static void gtOpportunityInfoTest() {
    dataNeeded();
    system.debug('MAPA: ' + mapOpps);
    final Opportunity oppReturned = ChangeOppCurrencyISOCode_Controller.gtOpportunityInfo(mapOpps.get('Opp1').Id);
    ChangeOppCurrencyISOCode_Controller.gtRelatedTemplate(oppReturned.Id);
    System.assertEquals(oppReturned.Id, mapOpps.get('Opp1').Id);

  }

    /*
    *
    *
    */
    @isTest
    public static void overrDeleteTemplate() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        Account acc = utilTestClass.createClient();
        insert acc;

        Opportunity opp = utilTestclass.createOpportunity(acc);
        insert opp;

        Product2 product1 = utilTestClass.createProduct(Label.DES_Project_Finance_Lending);
        insert product1;

        PricebookEntry pbEntryTest = utilTestClass.createPricebookEntry(product1);
        insert pbEntryTest;

        OpportunityLineItem oppLineItem = utilTestClass.createOppLineItem(opp, product1, pbEntryTest);
        oppLineItem.product_scope_type__c = 'CIB';
        oppLineItem.syndicated_loan_drawn_amount__c = 5;
        oppLineItem.bbva_prtcp_tranche_amount__c = 100000000;
        insert oppLineItem;

        DES_Template__c template = utilTestClass.createTemplate(opp, oppLineItem);
        template.RecordTypeId =  Schema.SObjectType.DES_Template__c.getRecordTypeInfosByDeveloperName().get('PF').getRecordTypeId();
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
        insert template;

        Test.startTest();
        DES_Template__c temp = ChangeOppCurrencyISOCode_Controller.gtRelatedTemplate(opp.Id);
        ChangeOppCurrencyISOCode_Controller.deleteTemplate(temp.Id);
        System.assertNotEquals(temp.Id, null);

        Test.stopTest();
    }


  /*
  *
  * @author Global Desktop  - DSL
  *
  */
  @isTest
  public static void chgOppCurrencyISOCodeTest_OK() {
    dataNeeded();
    final String strReturned = ChangeOppCurrencyISOCode_Controller.chgOppCurrencyISOCode(mapOpps.get('Opp1').Id, 'EUR');
    System.assertEquals(strReturned, 'The currency has been changed succesfully.');
  }

}