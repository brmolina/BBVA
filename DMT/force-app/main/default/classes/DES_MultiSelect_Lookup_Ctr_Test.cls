/**
 * Clase para los test de la clase DES_MultiSelect_Lookup_Ctr
 */
@isTest
public with sharing class DES_MultiSelect_Lookup_Ctr_Test {

    /*
    * Met0d0 de test para comprobar la funcionalidad de oppReadyToRelate.
    */
    @isTest
    static void oppReadyToRelateTest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final UtilTest_CommercialOffer utilCommOff = new UtilTest_CommercialOffer();
        final Account acc = utilTestClass.createClient();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Label.DES_RT_Subsidiary).getRecordTypeId();
		insert acc;
        final coff__Commercial_Offer__c cOffer = utilCommOff.createCommOff(acc);
        insert cOffer;
        final Opportunity opp = utilTestClass.createOpportunity(acc);
        List<Opportunity> lstOpp;
        lstOpp = new List<Opportunity>();
        lstOpp.add(opp);
        insert lstOpp;
        Test.startTest();
        DES_MultiSelect_Lookup_Ctr.oppReadyToRelate(cOffer.Id, lstOpp);
        final List<Opportunity> lstDev = [SELECT Id, coff__gf_commercial_offer_id__c FROM Opportunity WHERE coff__gf_commercial_offer_id__c =: cOffer.Id];
        Test.stopTest();
        System.assert(!lstDev.isEmpty(),'Error, no se han relacionado la oferta comercial y la oportunidad');
    }

    /*
    * Met0d0 de test para comprobar la funcionalidad de listarOpp.
    */
    @isTest
    static void listarOppTest() {
        Test.startTest();

        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final Account acc = utilTestClass.createClient();
        insert acc;
        final Opportunity opp = utilTestClass.createOpportunity(acc);
        List<Opportunity> lstOpp;
        lstOpp = new List<Opportunity>();
        lstOpp.add(opp);
        insert lstOpp;
        final String lista = DES_MultiSelect_Lookup_Ctr.listarOpp(lstOpp);
        system.debug('lista devuelta------------------->'+lista);
        System.assert(lista != null, 'Error, no se están listando las oportunidades.');

        Test.StopTest();
    }

    /*
    * Met0d0 de test para comprobar la funcionalidad de fetchLookUpValues.
    */
    @isTest
    static void fetchLookUpValuesTestSubsidiary() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final UtilTest_CommercialOffer utilCommOff = new UtilTest_CommercialOffer();
        final Account acc = utilTestClass.createClient();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Label.DES_RT_Subsidiary).getRecordTypeId();
		insert acc;
        final coff__Commercial_Offer__c cOffer = utilCommOff.createCommOff(acc);
        insert cOffer;
        final Opportunity opp = utilTestClass.createOpportunity(acc);
        final Opportunity opp2 = utilTestClass.createOpportunity(acc);
        List<Opportunity> lstOpp;
        lstOpp = new List<Opportunity>();
        lstOpp.add(opp);
        lstOpp.add(opp2);
        insert lstOpp;
        List<Opportunity> lstOpp2;
        lstOpp2 = new List<Opportunity>{opp2};

        Id [] searchRes= new Id[1];
        searchRes[0] = opp.Id;
        Test.setFixedSearchResults(searchRes);

        final List<Opportunity> lstDev = DES_MultiSelect_Lookup_Ctr.fetchLookUpValues(opp.Name, cOffer.Id, lstOpp2);
        System.assert(!lstDev.isEmpty(), 'Error, no se devuelven oportunidades');
    }
    /*
    * Met0d0 de test para comprobar la funcionalidad de fetchLookUpValues.
    */
    @isTest
    static void fetchLookUpValuesTestGroup() {

        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final UtilTest_CommercialOffer utilCommOff = new UtilTest_CommercialOffer();
        final Account acc = utilTestClass.createClient();
        acc.DES_Structure_Type__c = 'Group';
        acc.DES_BBVA_Segmentation__c = 'C';
        insert acc;
        final Account acc2 = utilTestClass.createClient();
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Label.DES_RT_Subsidiary).getRecordTypeId();
        insert acc2;
        final DES_Subsidiary_Group_Relation__c relation = utilTestClass.createSubsidiaryGroupRelation(acc, acc2);
        insert relation;
        final coff__Commercial_Offer__c cOffer = utilCommOff.createCommOff(acc);
        insert cOffer;
        final Opportunity opp = utilTestClass.createOpportunity(acc2);
        final Opportunity opp2 = utilTestClass.createOpportunity(acc2);
        List<Opportunity> lstOpp;
        lstOpp = new List<Opportunity>();
        lstOpp.add(opp);
        lstOpp.add(opp2);
        insert lstOpp;
        List<Opportunity> lstOpp2;
        lstOpp2 = new List<Opportunity>{opp2};
        Id [] searchRes= new Id[1];
        searchRes[0] = opp.Id;
        Test.setFixedSearchResults(searchRes);
        final List<Opportunity> lstDev = DES_MultiSelect_Lookup_Ctr.fetchLookUpValues(opp.Name, cOffer.Id, lstOpp2);
        System.assert(!lstDev.isEmpty(), 'Error, no se devuelven oportunidades');
    }
}