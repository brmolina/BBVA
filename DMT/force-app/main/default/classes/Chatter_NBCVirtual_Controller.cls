/*
* Clae para controlar el componente de chatter del NBC Virtual
* @author Aitor Martin
*/
public with sharing class Chatter_NBCVirtual_Controller {
    /**
    * SINGLETON PATTERN
    */
    private static Chatter_NBCVirtual_Controller instance;

    /**
    * getInstance
    */
    public static Chatter_NBCVirtual_Controller gtInstance() {//NOSONAR
        if (instance == null) {
        instance = new Chatter_NBCVirtual_Controller();
        }
        return instance;
    }

    /*
    * Met0d0 para pasar sonar
    */
    private Chatter_NBCVirtual_Controller() {}

    /*
    * Met0d0 para el recoger el objeto Chatter_NBC_Virtual__c asociado al registro
    */
    @AuraEnabled
    public static String gtChatterNBC(Id iden) {
        try {
            final List <Chatter_NBC_Virtual__c> ChatterNBC = [SELECT id, id_objeto__c FROM Chatter_NBC_Virtual__c WHERE id_objeto__c = :iden LIMIT 1];
            System.debug('ChatterNBC ------------------------------------------------------->'+ChatterNBC);
            return ChatterNBC[0].id;
        } catch (Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /*
    * Met0d0 para el lookup de las oportunidades
    */
    @AuraEnabled
    public static Boolean gtTipoRegistro(Id iden) {
        try {
            final List <NBC__c	> lstNBC = [SELECT id FROM NBC__c WHERE id =: iden];
            System.debug('lstNBC ------------------------------------------> '+lstNBC);
            Boolean esNbc = true;
            if(lstNBC.isEmpty()) {
                esNbc = false;
            }
            System.debug('esNBC ------------------------------------------->' +esNbc);
            return esNbc;
        } catch (Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

    /*
    * Met0d0 para generar el post en tablet
    */
    @AuraEnabled
    public static void generarPostChatter(String iden, String post) {
        try {
        FeedItem feed;
        feed = new FeedItem();
		feed.ParentId =  iden;
		feed.Body = post;
        feed.IsRichText = true;
		insert feed;
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }
    /*
    * Met0d0 recoge la candidad de comentarios que se han puesto en un chat
    */
	@AuraEnabled
    public static Integer gtChatterUp(Id iden) {
       final List <Chatter_NBC_Virtual__Feed> lstNBC= [Select id,Body,ParentId from Chatter_NBC_Virtual__Feed WHERE ParentId=:iden];
        return lstNBC.size();
    }
    

}