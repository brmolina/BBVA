/******************************************************************************************************************************************************************
Name:            DES_Visit_TriggerHandler
Description:     Class with VisitTopicTrigger custom methods
Test Class:      -

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
1            24/08/2018      Accenture         Class creation
2			 08/11/2018		 Accenture			Añadida funcionalidad para actualizar las visitas relacionadas con AccountCampaign
*******************************************************************************************************************************************************************/
public with sharing class DES_VisitTopic_TriggerHandler {
	private Integer timesExecuted = 0;
  	private CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
  	private CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();

	public DES_VisitTopic_TriggerHandler() {

	}


	public void visitAfterInsert(List<dwp_kitv__Visit_Topic__c> newList){
            set<Id> oppIds = new set<Id>();
	        map<Id,Opportunity> oppCAMap= new map<Id,Opportunity>();
	        map<Id,dwp_kitv__Visit__c> visitToUpdate = new map<Id,dwp_kitv__Visit__c>();
	        //set<Account_Campaign__c> accountCampaignToUpdate = new set<Account_Campaign__c> ();

            for(dwp_kitv__Visit_Topic__c vt : newList){
                if (vt.dwp_kitv__opportunity_id__c != null){ // Sólo para los topic relacionados con una oportunidad
                    oppIds.add(vt.dwp_kitv__opportunity_id__c);
                }
            }

            if(!oppIds.isEmpty()){
                List<Opportunity> oppList = new List<Opportunity>([SELECT id, almd__commercial_alert_id__c/*, participant_campaign_id__c*/ From Opportunity WHERE Id IN:oppIds And (almd__commercial_alert_id__c != null /*OR participant_campaign_id__c != null*/) ]);

                if(!oppList.isEmpty()){
	                for (Opportunity opp : oppList){
	                    oppCAMap.put(opp.Id,opp);
	                }

	                // se recorre la lista de Topics de nuevo y se rellena el mapa con las Visits a actualizar
	                for(dwp_kitv__Visit_Topic__c vt : newList){
	                	dwp_kitv__Visit__c visitAux;
	                	if (vt.dwp_kitv__opportunity_id__c != null && oppCAMap.containsKey(vt.dwp_kitv__opportunity_id__c)) {
	                		//Paranoid mode: en caso de que haya varias repetidas visitas a actualizar (porque había varias opp apuntando a la misma CommercialAlert y las han metido en varias visitas en varios topicVisit) se machacan los valores al ser un map y se guarda el último que llega
	                		visitAux = new dwp_kitv__Visit__c(id=vt.dwp_kitv__visit_id__c,almd__commercial_alert_id__c=oppCAMap.get(vt.dwp_kitv__opportunity_id__c).almd__commercial_alert_id__c/*,participant_campaign_id__c=oppCAMap.get(vt.dwp_kitv__opportunity_id__c).participant_campaign_id__c*/);
	                		visitToUpdate.put(vt.dwp_kitv__visit_id__c,visitAux);

	                	}
	                }//FIN For

	                if(!visitToUpdate.isEmpty()){
	                	update visitToUpdate.values();
	                }

                }// FIN !oppList.isEmpty

        	}// FIN !oppIds.isEmpty

	timesExecuted ++;
	}//FIN AFTER INSERT
}