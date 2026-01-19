@isTest
public class AJustePermisosTerritorioOpportBatchTest {

static testMethod void myUnitTest() {
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        
        Account testAcc = new Account(Name = 'TestAccount');
        insert testAcc;

        Pricebook2 p = new Pricebook2(Name = 'Testbook');
        insert p;

        Pricebook2 pb22 = new Pricebook2(Name='testDIE');
        insert pb22;
    
        Opportunity testOpportunity = new Opportunity(
            StageName='Draft Opp',
            CloseDate=Date.today(),
            AccountId = testAcc.Id,
            Name = 'Test Opportunity Triggers',
            Pricebook2Id=pb22.id
        );
        insert testOpportunity;


        

        Product2 pro2 = new Product2(Name='BXCD', isActive=true ,Family = 'Terminal');
        insert pro2;
        insert new PriceBookEntry(Product2Id=pro2.Id, Pricebook2Id=Test.getStandardPricebookId(), UnitPrice=0);
        PricebookEntry pbe2 =new PricebookEntry(UnitPrice=10000,Product2Id=pro2.Id,Pricebook2Id=pb22.id,
                                             isActive=true,UseStandardPrice = false);
        insert pbe2;

        OpportunityLineItem OPplineitem2 =utilTestClass.createOppLineItem(testOpportunity, pro2, pbe2);
            //new OpportunityLineItem (Quantity=1, OpportunityId=testOpportunity.Id,UnitPrice=0.01,PriceBookEntryId=pbe2.Id);
        insert OPplineitem2;        
    
        final Desktop_Utils handlerDsktpUtls = Desktop_Utils.getInstance();
   
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfileTest = testClass.createProfile();
        final User userTest = testClass.createUser(idProfileTest,'delopp1@oppven.com');
        insert userTest;
        final OpportunityShare oppsh = handlerDsktpUtls.newManualSharingOpportunity(testOpportunity.Id,testOpportunity.ownerid , 'Edit');
        oppsh.UserOrGroupId=userTest.id; 
       insert oppsh;

       Test.startTest();

        AJustePermisosTerritorioOpportBatch obj=new AJustePermisosTerritorioOpportBatch();
        String idbatch=database.executebatch(obj,10 );

        system.assertNotEquals(idbatch, null);
        Test.stopTest();


	}
      //final OpportunityShare oppsh = handlerDsktpUtls.newManualSharingOpportunity(opp.Id, [select id from user limit 1].Id, 'Edit');
      //insert oppsh;
      
        
        
        
      //AJustePermisosTerritorioOpportBatch obj=new AJustePermisosTerritorioOpportBatch();
      //String idbatch=database.executebatch(obj,10 );

        
}