/*
 *	@author		Global Desktop
 *	@Description		Clase batch para la comparticon de los territorios
 *
 *
**/
@SuppressWarnings('sf:UseSingleton')
public without sharing class DES_HandlerTerritoryBatch {

    /**
     * Devuelve una lista de objetos con los territorios correspondientes para ser utilizado en un batch
     **/
    public static List<sObject> shareWithTerritoryListBatch (List<sObject> objectos) {
			List<sObject> objList;
			objList = new List<sObject>();

			System.debug('>>>>> Entrando shareWithTerritoryListBatch');
			for (sObject objecto : objectos) {
				objList.addAll(DES_HandlerTerritory.shareWithTerritory(objecto, objecto));
			}


			return objList;
    }


    /**
     * Comparte una oportunidad con los territorios a partir de sus productos
     **/
    public static List<sObject> shareOpportunityBatch (List<OpportunityLineItem> objectos) {
			Map<Id,Id> idsOpp;
			idsOpp = new Map<Id,Id>();
			Map<Id,Opportunity> lineItemOpp;
			lineItemOpp = new Map<Id,Opportunity>();
			List<sObject> inserts;
			inserts = new List<sObject>();
			for (OpportunityLineItem objecto : objectos) {
				idsOpp.put(objecto.Id,objecto.OpportunityId);
			}
			final Map<ID,Opportunity> opps = new Map<ID, Opportunity>([SELECT Id, DES_Booking_Geography__c, disclosure_info_type__c, Account.DES_Segment__c FROM Opportunity WHERE Id IN :idsOpp.values() ]);

			for (OpportunityLineItem objecto : objectos) {
				OpportunityLineItem obj;
				obj = objecto.clone();
				obj.Opportunity = opps.get(obj.OpportunityId);
				inserts.addAll(DES_HandlerTerritory.shareWithTerritory(obj, opps.get(obj.OpportunityId)));
			}
			system.debug('::::: lineItemOpp: ' + lineItemOpp);
			return inserts;
    }

    /**
     * Comparte nbc con sus territorios
     **/
    public static List<sObject> shareNBCBatch(List<Opportunity> triggerNew) { //NOSONAR
        //Mapa que tendrá como key el id de la opSet<E> como value el id del NBC asociado
    	final List<sObject> inserts = new List<sObject>();
			final Set<ID> mapDeleteNBC = new Set<Id>();
				final Map<Id, Id> mapOppNBC = new Map<Id, Id>();

				for(Opportunity opp : triggerNew) {
					if(opp.Committee_id__c != null) {
						mapOppNBC.put(opp.Id, opp.Committee_id__c);
						mapDeleteNBC.add(opp.Committee_id__c);
					}
				}

				if (!mapDeleteNBC.isEmpty()) {
					final List<NBC__Share> sharesBorrar = [select id from NBC__Share where UserOrGroupId in (select id from Group where Type = 'Territory') and RowCause = 'Manual' and ParentId in :mapDeleteNBC];
					delete sharesBorrar;
				}

				if(!mapOppNBC.isEmpty()) {
					final Map<Id,NBC__c> nbcs = new Map<Id,NBC__c>([Select Id from NBC__c where id in :mapOppNBC.values()]);
					final Map<Id,List<Id>> listaOpp = new Map<Id,List<Id>>();

					final List<Opportunity> opptnys = [Select Id, Committee_id__c from Opportunity Where Committee_id__c in :nbcs.keySet()];
					System.debug('>>>> Opportunities opptnys ' + opptnys.size());

					for(Opportunity oppty : opptnys) {
						if(oppty.Committee_id__c != null) {
							if(listaOpp.containsKey(oppty.Committee_id__c)) {
								List<Id> oppsNbc;
								oppsNbc = listaOpp.get(oppty.Committee_id__c);
								oppsNbc.add(oppty.Id);
								listaOpp.put(oppty.Committee_id__c,oppsNbc );
							} else {
								List<Id> oppsNbc;
								oppsNbc = new List<Id>();
								oppsNbc.add(oppty.Id);
								listaOpp.put(oppty.Committee_id__c,oppsNbc );
							}
						}
					}

					System.debug('>>>> Opportunities listaOpp ' + opptnys.size());

					for (NBC__c nbc : nbcs.values()) {
						if(listaOpp.containsKey(nbc.Id)) {
										System.debug('>>>> Entra ');
							inserts.addAll(DES_HandlerTerritory.createShareNBC(nbc,listaOpp.get(nbc.Id)));
						}
					}

				}

    	return inserts;
    }
}