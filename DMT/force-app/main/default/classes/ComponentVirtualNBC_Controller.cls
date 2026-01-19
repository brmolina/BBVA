/*
    *
    * Clase para el virtual NBC
    *
    */

public with sharing class ComponentVirtualNBC_Controller {
    /**
    * SINGLETON PATTERN
    */
    private static ComponentVirtualNBC_Controller instance;

    /**
    * getInstance
    */
    public static ComponentVirtualNBC_Controller gtInstance() {//NOSONAR
        if (instance == null) {
        instance = new ComponentVirtualNBC_Controller();
        }
        return instance;
    }

    /*
    * Constructor para sonar
    */
    private ComponentVirtualNBC_Controller() {}

    /*
    *
    * Method para recoger el valor del campor opportunity_nbc_comments_desc__c
    * @author Aitor Martin
    */
    @AuraEnabled
    public static DES_Template__c valorNBC(Id recordId) {
        try {
            final List<DES_Template__c> listTempl = new List<DES_Template__c>([SELECT Id, opportunity_nbc_comments_desc__c, opportunity_id__r.gf_oppy_virtual_cmtee_ind_type__c FROM DES_Template__c  WHERE Id = :recordId LIMIT 1]);
            return listTempl.get(0);
        } catch(Exception e) {
            system.debug('Error al recoger la query del Template id: '+recordId);
            throw new AuraHandledException(Label.DES_Error+e);
        }
    }

    /*
    *
    * Method para  rellenar el campo opportunity_nbc_comments_desc__c
    * @author Aitor Martin
    */
    @AuraEnabled
    public static String escriboDescp(Id recordId, String des) {
        String mensaje;
        try {
            final List<DES_Template__c> listTempl = new List<DES_Template__c>([SELECT Id, opportunity_nbc_comments_desc__c FROM DES_Template__c  WHERE Id = :recordId LIMIT 1]);
            if(des != null && listTempl != null) {
                listTempl.get(0).opportunity_nbc_comments_desc__c = des;
                update listTempl.get(0);
                mensaje = 'Success';
            }
        } catch(Exception e) {
            system.debug('Fallo a la hora de actualizar el campo descripcion NBCVIRTUAL');
            system.debug('recordId: '+recordId +' campo descripción: '+ des);
            system.debug(e.getMessage());
            if(e.getMessage().contains('STRING_TOO_LONG')) {
            	mensaje = 'Max length of NBC Opportunity Summary is 3000';
            } else if(e.getMessage().contains('ENTITY_IS_LOCKED')) {
                mensaje = 'Template is blocked ';
            } else if(e.getMessage().contains('insufficient access rights')) {
                mensaje = 'Insufficient access rights on this object';
            } else if(e.getMessage().contains('Cannot edit the template when has been approve')) {
                mensaje = 'Success';
            } else {
                mensaje = e.getMessage();
            }
        }
        return mensaje;
    }
}