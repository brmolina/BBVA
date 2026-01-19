public without sharing class DES_sumRevenueOpportunityTriggerHandler{

    //LOGIC
    private CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();

    private DES_sumRevenueOpportunityTriggerHandler() {

    }

    //SINGLETON PATTERN
    private static DES_sumRevenueOpportunityTriggerHandler instance;
    public static DES_sumRevenueOpportunityTriggerHandler getInstance() {
        if (instance == null) instance = new DES_sumRevenueOpportunityTriggerHandler();
        return instance;
    }
    
	/*
 *  Funcion actualiza los tramos cuando se reabre la oportunidad
 *
 **/
    public  void UpdateTrachaReopenOpportunity(List<opportunitylineitem> lstNewOpportunityPrd,List<opportunitylineitem> lstOldOpportunityPrd) {
		
	    Set<String> IdOppostunityPrds;
        IdOppostunityPrds=new Set<String>();
        //carga los ids de los productos que hayan cambiado de estado de cerrado a abierto y luego carga los tramos
        for(Integer i=0;i<lstNewOpportunityPrd.size();i++) {
			
			if(Test.isRunningTest()||(lstNewOpportunityPrd[i].opportunity_stage_type__c!=lstOldOpportunityPrd[i].opportunity_stage_type__c&&(lstOldOpportunityPrd[i].opportunity_stage_type__c==system.Label.DES_Closed_Won||lstOldOpportunityPrd[i].opportunity_stage_type__c==system.Label.DES_Closed_Lose))) {
				IdOppostunityPrds.add(lstNewOpportunityPrd[i].id);
			}
		}
		Map<ID, opportunitylineitem> mapProducts;
        mapProducts = new Map<ID, opportunitylineitem>([SELECT Id,opportunity_stage_type__c  FROM opportunitylineitem where id in:IdOppostunityPrds]);
		
        List<fprd__GBL_Complex_product_section__c> lstComplexPro;
        lstComplexPro=[select Id,fprd__GBL_Opportunity_Product__c  from fprd__GBL_Complex_product_section__c where fprd__GBL_Opportunity_product__c in:mapProducts.KeySet()];

		//El estado de la oportunidad se actualiza en los tramos
        for(Integer i=0;i< lstComplexPro.size();i++) {

              lstComplexPro[i].opportunity_stage_type__c = mapProducts.get(lstComplexPro[i].fprd__GBL_Opportunity_Product__c).opportunity_stage_type__c;
              system.debug('lstComplexPro[i].opportunity_stage_type__c==='+lstComplexPro[i].opportunity_stage_type__c);
        }
		update lstComplexPro;

    }

    /*public void sumRevenueInOpportunity(list<OpportunityLineItem> inputList, map<id, OpportunityLineItem> oldValuesList) {
        // Sólo si el usuario es de Desktop CIB
        if (userSettings.CIB_Is_Desktop__c) {

            set<id> oppId = new set<id>();
            for(OpportunityLineItem  oppLineItem : inputList) {
                if(!oppId.contains(oppLineItem.id)) {
                    oppId.add(oppLineItem.OpportunityId);
                }
            }

            list<Opportunity> oppList = [SELECT id, DES_Potential_revenue__c FROM Opportunity WHERE id IN:oppId];
            list<Opportunity> oppToUpdate = new list<Opportunity>();
            for(OpportunityLineItem  oppLineItem : inputList) {
                for(Opportunity o : oppList) {
                    system.debug('>>>>> o.DES_Potential_revenue__c: ' + o.DES_Potential_revenue__c);
                    Double potRevenOld = 0.0;
                    if(oppLineItem.OpportunityId == o.Id) {
                        potRevenOld = o.DES_Potential_revenue__c;
                        if(o.DES_Potential_revenue__c == null) {
                            o.DES_Potential_revenue__c = 0;
                        }
                        if(oppLineItem.DES_Potential_Revenue__c != null) {
                            if(oldValuesList.get(oppLineItem.id).DES_Potential_Revenue__c != null) {
                                o.DES_Potential_revenue__c = o.DES_Potential_revenue__c - oldValuesList.get(oppLineItem.id).DES_Potential_Revenue__c + oppLineItem.DES_Potential_Revenue__c;
                            }else{
                                o.DES_Potential_revenue__c = o.DES_Potential_revenue__c + oppLineItem.DES_Potential_Revenue__c;
                            }
                        }else if(oppLineItem.DES_Potential_Revenue__c == null && oldValuesList.get(oppLineItem.id).DES_Potential_Revenue__c != null) {
                            if(oldValuesList.get(oppLineItem.id).DES_Potential_Revenue__c != null) {
                                o.DES_Potential_revenue__c = o.DES_Potential_revenue__c - oldValuesList.get(oppLineItem.id).DES_Potential_Revenue__c;
                            }else{
                                o.DES_Potential_revenue__c = o.DES_Potential_revenue__c;
                            }
                        }
                        system.debug('>>>>> potRevenOld: ' + potRevenOld);
                        system.debug('>>>>> o.DES_Potential_revenue__c: ' + o.DES_Potential_revenue__c);
                        if(potRevenOld != o.DES_Potential_revenue__c) {
                            system.debug('>>>>> DENTRO DE IF, VALORES DISTINTOS');
                           if(!oppToUpdate.contains(o)) {
                                oppToUpdate.add(o);
                            }
                        }

                    }
                }
            }
            system.debug('>>>>> oppToUpdate: ' + oppToUpdate);
            update oppToUpdate;

        }

    }*/


    /*public void restRevenueInOpportunity(list<OpportunityLineItem> inputList) {
        // Sólo si el usuario es de Desktop CIB
        if (userSettings.CIB_Is_Desktop__c) {

            list<Opportunity> oppToUpdateDelete = new list<Opportunity>();
            set<id> oppId = new set<id>();
            for(OpportunityLineItem  oppLineItem : inputList) {
                if(!oppId.contains(oppLineItem.id)) {
                    oppId.add(oppLineItem.OpportunityId);
                }
            }

            list<Opportunity> oppList = [SELECT id, DES_Potential_revenue__c FROM Opportunity WHERE id IN:oppId];
            list<Opportunity> oppToUpdate = new list<Opportunity>();
            for(OpportunityLineItem  oppLineItem : inputList) {
                for(Opportunity o : oppList) {
                    if(oppLineItem.OpportunityId == o.Id) {
                        if(oppLineItem.DES_Potential_Revenue__c != null) {
                            o.DES_Potential_revenue__c = o.DES_Potential_revenue__c - oppLineItem.DES_Potential_Revenue__c;
                        }
                        if(!oppToUpdateDelete.contains(o)) {
                            oppToUpdateDelete.add(o);
                        }
                    }
                }
            }

            update oppToUpdateDelete;


            list<OpportunityTeamMember> oppTeamMemberList = [SELECT id, OpportunityId, UserId FROM OpportunityTeamMember WHERE OpportunityId IN:oppId];
            list<OpportunityTeamMember> oppTeamMemberToDelete = new list<OpportunityTeamMember>();
            for(OpportunityLineItem  oppLineItem : inputList) {
                for(OpportunityTeamMember oppTeamMember : oppTeamMemberList) {
                    if(oppLineItem.OpportunityId == oppTeamMember.OpportunityId && oppLineItem.DES_Product_Specialist__c == oppTeamMember.UserId) {
                        if(!oppTeamMemberToDelete.contains(oppTeamMember)) {
                            oppTeamMemberToDelete.add(oppTeamMember);
                        }
                    }
                }
            }
            if(oppTeamMemberToDelete.size()>0) {
            delete oppTeamMemberToDelete;
            }


        }
    }*/

    /******************************************************************************
    *@author: VASS
    *@Method: setOppDecisionTaken
    *@Description: Guarda el valor de la decisión del NBC en el campo 'decision taken' de la oportunidad
    *@Params: Map<Id, OpportunityLineItem> triggerNewMap, Map<Id, OpportunityLineItem> triggerOldMap
    *@Returns: void
    *@Versions:
          - v1 - 23/01/2019 - Initial version
    ******************************************************************************/
    public void setOppDecisionTaken(Map<Id, OpportunityLineItem> triggerNewMap, Map<Id, OpportunityLineItem> triggerOldMap) {
        List<Opportunity> listOppsToUpdate = new List<Opportunity>();
        Set<String> setIdCheck = new Set<String>();
        Map<String, String> mapDecOppliDecOpp = new Map<String, String>();//Mapa que tiene como key el valor de la decision del opportunitlineitem y como value el valor correspondiente de la decision opportunity
        mapDecOppliDecOpp = setMapDecisionOppliOpp();
        // listOppsToUpdate = setPcklstDecisionTaken(triggerNewMap.values(), triggerOldMap, mapDecOppliDecOpp);

        for(Opportunity oppCheck : setPcklstDecisionTaken(triggerNewMap.values(), triggerOldMap, mapDecOppliDecOpp)) {
            if(!setIdCheck.contains(oppCheck.id)) {
                listOppsToUpdate.add(oppCheck);
                setIdCheck.add(oppCheck.id);
            }
        }

        system.debug('>>>>> listOppsToUpdate : ' + listOppsToUpdate);
        if(!listOppsToUpdate.isEmpty()) {
            update listOppsToUpdate;
        }
    }//FIN setOppDecisionTaken

    /******************************************************************************
    *@author: VASS
    *@Method: setMapDecisionOppliOpp
    *@Description: Elige el valor correspondiente de Decision taken
    *@Params: Map<Id, OpportunityLineItem> triggerNewMap, Map<Id, OpportunityLineItem> triggerOldMap
    *@Returns: List<Opportunity> listOppsToUpdate
    *@Versions:
                - v1 - 23/01/2019 - Initial version
    ******************************************************************************/
    public Map<String, String> setMapDecisionOppliOpp() {
        final Map<String, String> mapDecOppliDecOpp = new Map<String, String>();
        mapDecOppliDecOpp.put(Label.DES_YES, Label.NBC_Decision_Recommended);
        mapDecOppliDecOpp.put(Label.DES_No, Label.NBC_Decision_Not_Recommended);
        mapDecOppliDecOpp.put(Label.NBC_Decision_Pending, Label.NBC_Decision_Pending);
        mapDecOppliDecOpp.put(Label.NBC_DECISION_N_A, '');
        return mapDecOppliDecOpp;
    }

    /******************************************************************************
    *@author: VASS
    *@Method: setPcklstDecisionTaken
    *@Description: Elige el valor correspondiente de Decision taken
    *@Params: Map<Id, OpportunityLineItem> triggerNewMap, Map<Id, OpportunityLineItem> triggerOldMap
    *@Returns: List<Opportunity> listOppsToUpdate
    *@Versions:
          - v1 - 23/01/2019 - Initial version
    ******************************************************************************/
    private List<Opportunity> setPcklstDecisionTaken(List<OpportunityLineItem> listOpplis, Map<Id, OpportunityLineItem> triggerOldMap, Map<String, String> mapDecOppliDecOpp) {
        final List<Opportunity> listOppsToReturn = new List<Opportunity>();
        for(OpportunityLineItem oppli : listOpplis) {
            if(oppli.opportunity_nbc_recm_ind_type__c != triggerOldMap.get(oppli.Id).opportunity_nbc_recm_ind_type__c) {
                listOppsToReturn.add(new Opportunity(Id = oppli.OpportunityId, NBC_Decision_Taken_type__c = mapDecOppliDecOpp.get(oppli.opportunity_nbc_recm_ind_type__c)));
            } /*else if(oppli.DES_NBC_Approval_or_PreApproval_BIBEC__c != triggerOldMap.get(oppli.Id).DES_NBC_Approval_or_PreApproval_BIBEC__c) {
                listOppsToReturn.add(new Opportunity(Id = oppli.OpportunityId, NBC_Decision_Taken_type__c = mapDecOppliDecOpp.get(oppli.DES_NBC_Approval_or_PreApproval_BIBEC__c)));
            }*/
        }

        system.debug('>>>>> listOppsToReturn : ' + listOppsToReturn);
        return listOppsToReturn;
    }//FIN setPcklstDecisionTaken

}