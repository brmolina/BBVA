/*
* Clase Test para verificar la clase Commercial_Offer_Cr_re
* @Author: Global Desktop
*/
@isTest
public with sharing class Commercial_Offer_CrRe_Controller_Test {

    /*
    * global variable to instantiate the utility class.
    */
    private final static DES_UtilTestClass UTILITIES = new DES_UtilTestClass();

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de getinitAcount
    */
    public static void verifyInitAcc() {

        final Account acc = UTILITIES.createClient();
        insert acc;

        Commercial_Offer_CrRe_Controller.pickListValuesIn();

        final Account getAcc = Commercial_Offer_CrRe_Controller.getinitAcount(acc.Id);

        System.assert(getAcc != null, 'There is no Account');
    }

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de getinitOpp
    */
    public static void verifyInitOpp() {

        final Account acc = UTILITIES.createClient();
        insert acc;

        final Opportunity opp = UTILITIES.createOpportunity(acc);
        insert opp;

        final List<sObject> getAccAndOpp = Commercial_Offer_CrRe_Controller.getinitOpp(opp.Id);

        System.assert(!getAccAndOpp.isEmpty(), 'There is no Account or Opp');
    }

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de saveCommOff
    */
    public static void verifySavedCommOff() {

        final Account acc = UTILITIES.createClient();
        insert acc;

        final Opportunity opp = UTILITIES.createOpportunity(acc);
        insert opp;

        coff__Commercial_Offer__c commOffTest;
        commOffTest = new coff__Commercial_Offer__c();
        commOffTest.Name = 'Example Comm Off';
        commOffTest.coff__gf_commercial_offer_desc__c = 'Example Example';
        commOffTest.CurrencyIsoCode = 'USD';

        final coff__Commercial_Offer__c getCommOff = Commercial_Offer_CrRe_Controller.saveCommOff(commOffTest,acc.Id,opp.Id);

        System.assert(getCommOff != null, 'The Commercial offer was not created correctly');
    }

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de relateCo
    */
    public static void verifyCOrelated() {

        final Account acc = UTILITIES.createClient();
        insert acc;

        final Opportunity opp = UTILITIES.createOpportunity(acc);
        insert opp;

        coff__Commercial_Offer__c commOffTest;
        commOffTest = new coff__Commercial_Offer__c();
        commOffTest.Name = 'Example Comm Off';
        commOffTest.coff__gf_commercial_offer_desc__c = 'Example Example';
        commOffTest.CurrencyIsoCode = 'USD';

        final coff__Commercial_Offer__c getCommOff = Commercial_Offer_CrRe_Controller.saveCommOff(commOffTest,acc.Id,null);

        Commercial_Offer_CrRe_Controller.relateCo(getCommOff.Id,opp.Id);

        final Boolean anchorOpp = [Select gf_comm_offer_moppy_ind_type__c from Opportunity where id = :opp.id].gf_comm_offer_moppy_ind_type__c;

        System.assert(anchorOpp, 'The Opportunity was not related correctly');
    }
}