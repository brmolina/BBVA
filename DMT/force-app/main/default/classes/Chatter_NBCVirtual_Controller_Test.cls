/*
* @author       Aitor Martin
* @date         22/11/2019
* @description  Clase para los test realizados en Chatter_NBCVirtual_Controller en relacion con en el componente Chatter_NBCVirtual
*/
@isTest
public with sharing class Chatter_NBCVirtual_Controller_Test {

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de gtChatterNBC del componente Chatter_NBCVirtual
    */
    public static void gtChatterNBCTest() {

        final DES_UtilTestClass utilClass = new DES_UtilTestClass();

        final Account acc = utilClass.createClient();
        insert acc;
        final Opportunity opp = utilClass.createOpportunity(acc);
        insert opp;
        Chatter_NBC_Virtual__c chatReg = new Chatter_NBC_Virtual__c();//NOSONAR
        chatReg.id_objeto__c = opp.Id;
        chatReg.tipo_objeto__c = 'Opportunity';
        insert chatReg;

        Chatter_NBCVirtual_Controller.gtInstance();

        final String chatId = Chatter_NBCVirtual_Controller.gtChatterNBC(opp.Id);
        final List <Chatter_NBC_Virtual__c> ChatterNBC = [SELECT id, id_objeto__c FROM Chatter_NBC_Virtual__c WHERE id = :chatId LIMIT 1];

        system.assertEquals(opp.id, ChatterNBC[0].id_objeto__c, 'Error al recuperar el campo id_objeto__c de Chatter_NBC_Virtual__c');

    }

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de gtChatterNBC del componente Chatter_NBCVirtual
    */
    public static void gtTipoRegistroTest() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();

        final Account acc = utilClass.createClient();
        insert acc;
        final Opportunity opp = utilClass.createOpportunity(acc);
        insert opp;
        final NBC__c nbc = utilClass.createNBC();
        insert nbc;
        final Boolean esNbc = Chatter_NBCVirtual_Controller.gtTipoRegistro(nbc.Id);
        final Boolean noNbc = Chatter_NBCVirtual_Controller.gtTipoRegistro(opp.Id);
        Boolean confirm = false;
        if(esNbc && !noNbc) {
            confirm = true;
        }
        system.assert(confirm, 'message');
    }

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de generarPostChatter del componente Chatter_NBCVirtual
    */
    public static void generarPostChatterTest() {
        final String texto = 'Texto prueba'; //NOSONAR
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String iden = acc.Id;
        Chatter_NBCVirtual_Controller.generarPostChatter(iden,texto);
        final List<FeedItem> accFeed = [SELECT Id, ParentId FROM FeedItem WHERE ParentId =: iden LIMIT 1];
        system.assert(!accFeed.isEmpty(), 'message');
    }
    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de gtChatterUp del componente Chatter_NBCVirtual
    */
	public static void gtChatterLonTest() {

        final String texto = 'Texto prueba'; //NOSONAR
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String iden = acc.Id;
        Chatter_NBCVirtual_Controller.generarPostChatter(iden,texto);
        system.assertEquals(0, Chatter_NBCVirtual_Controller.gtChatterUp(iden),'message');

    }

}