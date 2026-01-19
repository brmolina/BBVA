/*
* Clase Test para verificar la clase CustomLookUpControllerCO
* @Author: Global Desktop
*/
@isTest
public with sharing class CustomLookUpControllerCO_Test {
    /*
    * Global variable to instantiate the utility class.
    */
    private final static DES_UtilTestClass UTILITIES = new DES_UtilTestClass();

    /*
    * Global variable to instantiate the Commercial Offer utility class.
    */
    private final static UtilTest_CommercialOffer COFF_UTILITIES = new UtilTest_CommercialOffer();

    /*
    *Variable
    */
    static final string COMMERCIAL = 'Commercial';

    /*
    *Variable
    */
    static final string OPPORTUNITY= 'opportunity';

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de fetchLookUpValues()
    */
    public static void verifyFetchLUp() {
        List<coff__Commercial_Offer__c> coffToInsert;
        coffToInsert = new List<coff__Commercial_Offer__c>();

        final Account acc = UTILITIES.createClient();
        insert acc;

        final Account parentAcc = UTILITIES.createClient();
        parentAcc.Name = 'Parent Acc';
        insert parentAcc;

        DES_Subsidiary_Group_Relation__c groupRel;
        groupRel = new DES_Subsidiary_Group_Relation__c();

        groupRel.participant_child_id__c = acc.Id;
        groupRel.participant_parent_id__c = parentAcc.Id;

        insert groupRel;

        final Opportunity opp = UTILITIES.createOpportunity(acc);
        insert opp;

        final coff__Commercial_Offer__c parentCoff = COFF_UTILITIES.createCommOff(parentAcc);
        coffToInsert.add(parentCoff);
        final coff__Commercial_Offer__c childCoff = COFF_UTILITIES.createCommOff(acc);
        childCoff.Name = 'Commercial Offer Test 2';
        coffToInsert.add(childCoff);

        insert coffToInsert;

        final Opportunity oppToUp = [Select id,coff__gf_commercial_offer_id__c from Opportunity where id = :opp.id];
        oppToUp.coff__gf_commercial_offer_id__c = childCoff.Id;
        update oppToUp;

        final List<sObject> result = CustomLookUpControllerCO.fetchLookUpValues('Commercial Offer', opp.Id);

        System.assert(!result.isEmpty(), 'There is no Commercial Offer to relate');

    }

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de childsClients()
    */
    public static void verifyChilds() {

        final Account acc = UTILITIES.createClient();
        insert acc;

        final Account parentAcc = UTILITIES.createClient();
        parentAcc.Name = 'Parent Acc';
        insert parentAcc;

        DES_Subsidiary_Group_Relation__c groupRel;
        groupRel = new DES_Subsidiary_Group_Relation__c();

        groupRel.participant_child_id__c = acc.Id;
        groupRel.participant_parent_id__c = parentAcc.Id;

        insert groupRel;

        final Set<Id> result = CustomLookUpControllerCO.childsClients(parentAcc.Id);

        System.assert(!result.isEmpty(), 'There is no child related');
    }

    /*
    *
    *Met0d0 auxiliar, retorna una lista de String [0] Child Account Id / [1] Parent Account Id
    */
    public static List<String> auxMet() {


        final Account acc = UTILITIES.createClient();
        acc.Name = 'Commercial Child Acc';
        insert acc;
        system.debug('CUENTA CHILD: -----> ' + acc.Id);

        final Account parentAcc = UTILITIES.createClient();
        parentAcc.Name = 'Commercial Parent Acc';
        parentAcc.DES_Structure_Type__c = 'Group';
        parentAcc.DES_BBVA_Segmentation__c = 'C';
        insert parentAcc;
        system.debug('CUENTA PARENT: -----> ' + parentAcc.Id);

        DES_Subsidiary_Group_Relation__c groupRel;
        groupRel = new DES_Subsidiary_Group_Relation__c();

        groupRel.participant_child_id__c = acc.Id;
        groupRel.participant_parent_id__c = parentAcc.Id;

        insert groupRel;

        Opportunity opp;
        opp = UTILITIES.createOpportunity(acc);
        opp.Name = 'Commercial Offer opp';
        insert opp;

        Opportunity opp2;
        opp2 = UTILITIES.createOpportunity(acc);
        opp2.Name = 'Commercial Offer opp two';
        insert opp2;

        Id [] searchRes= new Id[2];
        searchRes[0] = opp.Id;
        searchRes[1] = acc.Id;
        Test.setFixedSearchResults(searchRes);

        //final List<String> accList = new List<String>{acc.Id, parentAcc.Id};

        return new List<String>{acc.Id, parentAcc.Id};
    }

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de los lookup
    */
    public static void verifyLookup1() {
        final List<String> accs = auxMet();

        List<sObject> result1;
        result1 = new List<sObject>();

        List<sObject> result2;
        result2 = new List<sObject>();

        result1 = CustomLookUpControllerCO.lookupResultValues(COMMERCIAL, OPPORTUNITY, 'Account', accs[0]);
        result2 = CustomLookUpControllerCO.lookupResultValues(COMMERCIAL, OPPORTUNITY, 'Account', accs[1]);


        System.assert(!result1.isEmpty() && !result2.isEmpty(), 'There is no sObject to show from Account');
    }

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de los lookup
    */
    public static void verifyLookup2() {
        final List<String> accs = auxMet();

        List<sObject> result;
        result = new List<sObject>();

        result = CustomLookUpControllerCO.lookupResultValues(COMMERCIAL, OPPORTUNITY, 'Opportunity', accs[0]);

        System.assert(!result.isEmpty(), 'There is no sObject to show from Opportunity on the lookup of ' + accs[0]);
    }

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de los lookup
    */
    public static void verifyLookup3() {
        final List<String> accs = auxMet();

        List<sObject> result1;
        result1 = new List<sObject>();

        List<sObject> result2;
        result2 = new List<sObject>();

        result1 = CustomLookUpControllerCO.lookupResultValues(COMMERCIAL, OPPORTUNITY, 'Another',accs[0]);
        result2 = CustomLookUpControllerCO.lookupResultValues(COMMERCIAL, OPPORTUNITY, 'Another',accs[1]);


        System.assert(!result1.isEmpty() && !result2.isEmpty(), 'There is no sObject to show from Account');
    }

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de los lookup
    */
    public static void verifyLookup4() {
        final List<String> accs = auxMet();

        List<sObject> result;
        result = new List<sObject>();

        result = CustomLookUpControllerCO.lookupResultValues(COMMERCIAL, 'account', 'Another','');

        System.assert(!result.isEmpty(), 'There is no sObject to show from Opportunity on the lookup of ' + accs[0]);
    }

}