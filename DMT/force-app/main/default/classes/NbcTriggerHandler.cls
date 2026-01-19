/*
* @author       Alejandro del Rio Martin
* @date         21/01/2020
* @description  Clase para los test realizados en NBCTriggerHandler
*/
public with sharing class NbcTriggerHandler {
    //LOGIC
    //private final ActivitiesUtils logic;
    /*Declarando variable*/

    /*Declarando variable*/
    final Desktop_Utils handlerDsktpUtls = Desktop_Utils.getInstance();
    /*string para guardar el perfil del current user*/
	final static String PROFILENAME = [SELECT Name FROM Profile WHERE Id = :userInfo.getProfileId() LIMIT 1].Name;

    //SINGLETON PATTERN
    private static NbcTriggerHandler instance;
    /*
    *
    *Constructor
    */
	 private NbcTriggerHandler() {
    }

    public static NbcTriggerHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new NbcTriggerHandler();
        }
        return instance;
    }
    /*
    *
    *Met0d0 borra el chatter de nbc antes de borrar el nbc
    */
    public void deleteChatter(final List<NBC__c> oldList) { //NOSONAR
        system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Opportunity (before delete)');
        for (NBC__c nbc : oldList) {
            final List<Opportunity> Oppo = [SELECT Id from Opportunity where Committee_id__c =: nbc.Id limit 1];//NOSONAR
            if(!Oppo.isEmpty()){
			    final List<Chatter_NBC_Virtual__c> ChatterVirtual = [SELECT Id from Chatter_NBC_Virtual__c where id_objeto__c =: Oppo[0].Id];//NOSONAR
        	    system.debug('Chatter a borrar :' +nbc.Id);
                if(!ChatterVirtual.isEmpty()){
                    delete ChatterVirtual;//NOSONAR
                }
            }
        }
    }
}