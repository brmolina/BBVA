/*
*   @author: GlobalDesktop
*   @Name: CommOfferRelatedRevenuesCntTest
*   @Description: Testeo de la clase CommOfferRelatedRevenuesCnt
*/
@isTest
public class CommOfferRelatedRevenuesCntTest {

    /*Met0d0 1*/
    @IsTest
    static void getOppsTest() {
        
        //Instancia de clases
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final UtilTest_CommercialOffer utilCommOff = new UtilTest_CommercialOffer();
        //Creación de filial
        final Account acc = utilTestClass.createClient();
    	acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Label.DES_RT_Subsidiary).getRecordTypeId();
		insert acc;
        //Creación de oferta comercial
        final coff__Commercial_Offer__c cOffer = utilCommOff.createCommOff(acc);
        insert cOffer;
        //Creación de oportunidad
        final Opportunity opp = utilTestClass.createOpportunity(acc);
        opp.coff__gf_commercial_offer_id__c = cOffer.Id;
        insert opp;
        
        Test.startTest();        
        CommOfferRelatedRevenuesCnt.getData(cOffer.Id,'Expected');
        CommOfferRelatedRevenuesCnt.getData(cOffer.Id,'Potential');
        CommOfferRelatedRevenuesCnt.getDataTable(cOffer.Id);
		system.assertNotEquals(opp, null, 'not null');
        Test.stopTest();
    }
    
}