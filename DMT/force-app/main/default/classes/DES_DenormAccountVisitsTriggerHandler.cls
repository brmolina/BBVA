/**************************************************************************************************************
Name:            DES_DenormAccountVisitsTriggerHandler
Description:     Handler class for DES_DenormAccountVisitsTrigger Trigger
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            11/05/2018      			          Class creation
0.2            29/06/2018      Accenture          Modificado metodo denVisitAfterDelete para que:
													- para que si se cambia el accountId de una Visit, se ejecute restore() y no borre la Visit a posteriori
													- no se eliminen las Visitas cuando se ejecuta el proceso Batch programado de la denormalización.	El proceso Batch debe ser programado por el ADMIN y tiene que tener en el CustomSettings marcada la opcion "IsAdmin", así cuando se borre la tabla
												  denormalizada pues NO se elimina el registro relacionado de la tabla VISIT. Para que un Admin pueda borrar manualmente una Visita desde el LAYOUT debe
												  quitarse los checks "IsAdmin", "CIB_skip_trigger__c" y "CIB_DES_skip_trigger_in_denorm__c", cuando termine debe volver a marcarse los check para que en la ejecución siguiente del Batch NO se eliminen todas las visitas
**************************************************************************************************************/
public with sharing class DES_DenormAccountVisitsTriggerHandler {
    private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
    private static CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();



	/*
	* Method to update account
	*/
    public static void updateTotalVisit(Map<Id,DES_Denorm_AccountVisits__c> triggerOldMap) {
		Set<Id> setIdsAccount;
		setIdsAccount = new Set<Id>();
		//Recojo en un Set los id's de los account
		for(DES_Denorm_AccountVisits__c dVis : triggerOldMap.values()) {
			if(dVis.DES_Client__c != null && !setIdsAccount.contains(dVis.DES_Client__c)) {
				setIdsAccount.add(dVis.DES_Client__c);
			}
		}

		TotalAccountVisit.denVisitAfterDenormDelete(setIdsAccount);
	}
    /*
     *  Este método se encarga de eliminar la visita que tiene relacionada la Denorm Account Visit
     *
     *
    **/
    public static void denVisitAfterDelete(Map<Id,DES_Denorm_AccountVisits__c> triggerOldMap) {

        if (userSettings.CIB_Is_Admin__c || byPass.CIB_skip_trigger__c || byPass.CIB_DES_skip_trigger_in_denorm__c || SER_TriggerHelper.get_MethodFired('VisitDenorm_restoreUpdate')) {
       		//system.debug(Logginglevel.INFO,'>>>>>>> DES_DenormAccountVisitsTriggerHandler: Skip denVisitAfterDelete');
       	}
         //Sólo se ejecuta si el usuario NO es Administrador y NO tiene chequeado CIB_skip_trigger__c ni CIB_DES_skip_trigger_in_denorm__c y no viene de VisitDenorm_restoreUpdate
       	else {
	        Set<Id> setIdsVisits = new Set<Id>();
	        Set<Id> setIdsAccount;
			setIdsAccount = new Set<Id>();
	        //Recojo en un Set los id's de las visitas
	        for(DES_Denorm_AccountVisits__c dVis : triggerOldMap.values()) {
	            if(dVis.DES_Visit_new__c != null && !setIdsVisits.contains(dVis.DES_Visit_new__c)) {
	                setIdsVisits.add(dVis.DES_Visit_new__c);
	            }
	            if(dVis.DES_Client__c != null && !setIdsAccount.contains(dVis.DES_Client__c)) {
	                setIdsAccount.add(dVis.DES_Client__c);
	            }
	        }

	        if(!setIdsVisits.isEmpty()) {
	        	/* Hago una query para recuperar las visitas que están relacionadas
	            List<dwp_kitv__Visit__c> listaVisitas = new List<dwp_kitv__Visit__c>([SELECT Id FROM dwp_kitv__Visit__c WHERE Id IN :setIdsVisits]);
	            */
	            List<dwp_kitv__Visit__c> listaVisitas = new List<dwp_kitv__Visit__c>();
				for(Id visitId : setIdsVisits) {
					dwp_kitv__Visit__c aux = new dwp_kitv__Visit__c();
					aux.id = visitId;
					listaVisitas.add(aux);
				}

	            system.debug('>>>>> listaVisitas: ' + listaVisitas);
	            delete listaVisitas;
	        }

			TotalAccountVisit.denVisitAfterDenormDelete(setIdsAccount);
	   }//FIN IF ELSE
    }
}