/*
* Test para probar el funcionamiento del componente que anade oportunidades al nbc
*/
@isTest
public with sharing class AddOppNBCVirtual_Controller_Test {

    /*
    *Variable para definir el stage de las oportunidades
    */
    static final String STAGE = 'Proposal';
    /*
    *Variable para definir la region del nbc
    */
    static final String REGION = 'LATAM';
    /*
    *Variable para introducir en el buscador
    */
    static final string SEARCHKEYWORD= 'Test';

    /*
    * Test que prueba el met0d0 del lookup de las oportunidades
    */
    @isTest
    public static void fetchLookUpValuesTest() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        List<Id> lstIdFilt = new List<Id>();//NOSONAR
        final NBC__c nbc = utilClass.createNBC();
        nbc.NBC_Region_type__c = REGION;
        nbc.RecordTypeId = Schema.SObjectType.NBC__c.getRecordTypeInfosByName().get('Virtual NBC').getRecordTypeId();
        insert nbc;
        final Account acc = utilClass.createClient();
        insert acc;
        final Opportunity opp = utilClass.createOpportunity(acc);
        opp.DES_NBC_Region__c = REGION;
        opp.Template_approved_type__c = true;
        opp.StageName = STAGE;
        opp.gf_oppy_virtual_cmtee_ind_type__c = true;
        insert opp;

        AddOppNBCVirtual_Controller.gtInstance();
        //Para poder usar SOSL en test.
        Test.setFixedSearchResults(new List<Id>{opp.id});

        final List<SObject> listOp = AddOppNBCVirtual_Controller.fetchLookUpValues(SEARCHKEYWORD, nbc.id);

        for(sObject op : listOp) {
            lstIdFilt.add(String.valueof(op.get('Id')));
        }

        final List<Opportunity> listTempl = new List<Opportunity>([SELECT Id, Name FROM Opportunity  WHERE Id = :lstIdFilt LIMIT 1]);

        system.assertEquals(opp.Name, listTempl.get(0).Name,'Error no se muestra la oportunidad en el lookup');
    }

    /*
    * Test que prueba el met0d0 saveOp
    */
    @isTest
    public static void saveOpTest() {

        final DES_UtilTestClass utilClass = new DES_UtilTestClass();

        final NBC__c nbc = utilClass.createNBC();
        nbc.NBC_Region_type__c = REGION;
        insert nbc;
        final Account acc = utilClass.createClient();
        insert acc;
        final Opportunity opp = utilClass.createOpportunity(acc);
        opp.DES_NBC_Region__c = REGION;
        opp.Template_approved_type__c = true;
        opp.StageName = STAGE;
        insert opp;

        AddOppNBCVirtual_Controller.saveOp(opp, nbc.id);

        system.assertEquals(opp.Committee_id__c, nbc.id, 'Error al insertar la oportunidad en el NBC');

    }

    /*
    * Test que prueba el catch del met0d0 saveOp
    */
     @isTest
    public static void saveOpTestKO() {

        final DES_UtilTestClass utilClass = new DES_UtilTestClass();

        final NBC__c nbc = utilClass.createNBC();
        nbc.NBC_Region_type__c = REGION;
        insert nbc;
        final Opportunity opp = new Opportunity();
        try {
        AddOppNBCVirtual_Controller.saveOp(opp, nbc.id);
        } catch(Exception e) {
            system.assert(e.getMessage().contains('exception'),'msg');
        }
    }

    /*
    * Test que prueba el met0d0 de listarOpp
    */
    @isTest
    public static void listarOppTest() {

        Boolean listado = false;
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();

        final NBC__c nbc = utilClass.createNBC();
        nbc.NBC_Region_type__c = REGION;
        insert nbc;
        final Account acc = utilClass.createClient();
        insert acc;
        final Opportunity opp = utilClass.createOpportunity(acc);
        opp.DES_NBC_Region__c = REGION;
        opp.Template_approved_type__c = true;
        opp.StageName = STAGE;
        opp.Committee_id__c = nbc.id;
        insert opp;

        final String opps = AddOppNBCVirtual_Controller.listarOpp(nbc.id);
        if(opps != null) {
            listado = true;
        }
        System.assert(listado,'Error al mostrar las oportunidades');
    }

    /*
    * Met0d0 para comporbar el correcto funcionamiento del met0d0 de elimiar oportunidad
    */
    @isTest
    public static void eliminarOppTest() {

        final DES_UtilTestClass utilClass = new DES_UtilTestClass();

        final NBC__c nbc = utilClass.createNBC();
        nbc.NBC_Region_type__c = REGION;
        insert nbc;
        final Account acc = utilClass.createClient();
        insert acc;
        final Opportunity opp = utilClass.createOpportunity(acc);
        opp.DES_NBC_Region__c = REGION;
        opp.Template_approved_type__c = true;
        opp.StageName = STAGE;
        opp.Committee_id__c = nbc.id;
        insert opp;

        final String opps = AddOppNBCVirtual_Controller.listarOpp(nbc.id);

        AddOppNBCVirtual_Controller.eliminarOpp(nbc.id, opps);
        final List<Opportunity> opElimin = [SELECT id, Committee_id__c  FROM Opportunity WHERE Committee_id__c = null LIMIT 1];

        System.assertEquals(opp.id, opElimin.get(0).Id, 'La opp no se ha eliminado correctamente');

    }

}