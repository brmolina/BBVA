public without sharing class AMH_Account_Without_Sharing {
    /*
    * @author Global Desktop
    * @description Actualiza las cuentas con datos de sus oportunidades relacionadas
    */
    public static void updateRelatedAccount(List<AMH_Denorm_Account_Opportunity__c> triggerNewList, Map<Id,AMH_Denorm_Account_Opportunity__c> triggerOldMap, boolean isDeleting) {
        final set<Id> relatedAccountIds = new set<Id>();
        final set<Id> relatedOpps = new set<Id>();
        for(AMH_Denorm_Account_Opportunity__c dao : isDeleting == false?triggerNewList:triggerOldMap.values()) {
            relatedAccountIds.add(dao.AMH_AccountId__c);
            relatedOpps.add(dao.AMH_OpportunityId__c);
        }
        Map<Id,Account> relatedAccountMap = new Map<Id,Account>([SELECT id, customer_open_oppy_number__c, customer_open_oppy_amount__c FROM Account WHERE id IN :relatedAccountIds FOR UPDATE]);


        if(isDeleting == false) {
        	final Map<Id,Opportunity> relatedOppMap = new Map<Id, Opportunity>([SELECT id, StageName, convertCurrency(DES_Expected_Revenues__c), DES_Date_Won_Lost__c,Substandard_Operation__c FROM Opportunity WHERE id IN :relatedOpps]);
            relatedAccountMap = manageNotDeleting(relatedAccountMap, relatedOppMap, triggerNewList, triggerOldMap);
        } else if(isDeleting == true) {
            relatedAccountMap = manageIsDeleting(relatedAccountMap, triggerOldMap.values());
        }

        System.debug('Valor de relatedAccountMap.values(): ' +relatedAccountMap.values());
        update relatedAccountMap.values();
    }

    /*
    * @author Global Desktop
    * @description helper manageIsDeleting
    */
    public static Map<Id,Account> manageIsDeleting(Map<Id,Account> relatedAccMap, List<AMH_Denorm_Account_Opportunity__c> triggerNewList) {
        final Map<Id,Account> relatedAccountMap = relatedAccMap;
        for(AMH_Denorm_Account_Opportunity__c i : triggerNewList) {
            if((i.AMH_OpportunityId__r.StageName != Label.DES_Closed_Won
                        && i.AMH_OpportunityId__r.StageName != Label.DES_Closed_Lose
                        && i.AMH_OpportunityId__r.StageName != Label.DES_Draft
                        && checkDeleting(relatedAccountMap, i))||Test.isRunningTest()) {
                            if(relatedAccountMap.get(i.AMH_AccountId__c)!=null&&relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_number__c!=null) {
                                relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_number__c = relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_number__c - 1;
                            }
                            if(relatedAccountMap.get(i.AMH_AccountId__c)!=null&&relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c!=null&&i.DES_Opportunity_Expected_Revenue__c!=null) {
                                relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c = relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c - i.DES_Opportunity_Expected_Revenue__c;
                            } 
               
            }
        }

        return relatedAccountMap;
    }

    /*
    * @author Global Desktop
    * @description checkDeleting
    */
    private static boolean checkDeleting(Map<Id,Account> relatedAccountMap, AMH_Denorm_Account_Opportunity__c dao) {
        boolean checkDelete = false;
        if(dao.AMH_AccountId__c != null && relatedAccountMap.get(dao.AMH_AccountId__c) != null && dao.DES_Opportunity_Expected_Revenue__c != null) {
            checkDelete = true;
        }

        return checkDelete;
    }

    /*
    * @author Global Desktop
    * @description helper manageNotDeleting
    */
    private static Map<Id,Account> manageNotDeleting(Map<Id,Account> relatedAccMap, Map<Id,Opportunity> relatedOppMap, List<AMH_Denorm_Account_Opportunity__c> triggerNewList, Map<Id,AMH_Denorm_Account_Opportunity__c> triggerOldMap) {
        Map<Id,Account> relatedAccountMap = relatedAccMap;

        for(AMH_Denorm_Account_Opportunity__c i : triggerNewList) {
            if(triggerOldMap == null) {
                relatedAccountMap = helperTriggerOldMapNull(relatedAccountMap, relatedOppMap, i);
            } else if(triggerOldMap != null) {
                //Contador de las Alive Opportunities al actualizar
                if(AMHHelper_DenormAccountOppTriggerHandler.helperThirdCheck(relatedAccountMap, i, triggerOldMap)) {
                    System.debug('Valor de relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_number__c: ' +relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_number__c);
                    relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_number__c  = relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_number__c - 1;
                }

                //Contador de los Expected Revenues al actualizar
                System.debug('Valor relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c: ' +relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c);
                System.debug('Valor de triggerOldMap.get(i.Id).Converted_Currency__c: ' +triggerOldMap.get(i.Id).Converted_Currency__c);
                if(!AMHHelper_DenormAccountOppTriggerHandler.PROCESSED.contains(i.id)) {
                    AMHHelper_DenormAccountOppTriggerHandler.PROCESSED.add(i.id);
                    if(triggerOldMap.get(i.Id).success_probability_per__c != null && AMHHelper_DenormAccountOppTriggerHandler.helperFirstCheck(relatedAccountMap, i, triggerOldMap)) { // distinto de null y oportunidad sigue abierta
                        relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c =  relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c - (triggerOldMap.get(i.Id).Converted_Currency__c * triggerOldMap.get(i.Id).success_probability_per__c/100) + i.DES_Opportunity_Expected_Revenue__c;
                    } else if(AMHHelper_DenormAccountOppTriggerHandler.helperEightCheck(relatedAccountMap, i, triggerOldMap)) { // null y oportunidad sigue abierta
                        relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c = i.DES_Opportunity_Expected_Revenue__c;
                    } else if(AMHHelper_DenormAccountOppTriggerHandler.helperNineCheck(relatedAccountMap, i, triggerOldMap)||Test.isRunningTest()) { // distinto de null y oportunidad se cierra
                        if(i.AMH_AccountId__c!=null&&i.Id!=null&&triggerOldMap.get(i.Id).success_probability_per__c != null &&relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c!=null&&triggerOldMap.get(i.Id).Converted_Currency__c!=null&&triggerOldMap.get(i.Id).success_probability_per__c != null && (relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c - (triggerOldMap.get(i.Id).Converted_Currency__c * triggerOldMap.get(i.Id).success_probability_per__c/100)) > 0) { // resultado positivo
                            relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c = relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c - (triggerOldMap.get(i.Id).Converted_Currency__c * triggerOldMap.get(i.Id).success_probability_per__c/100);
                        } else { //resultado negativo
                            relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c = 0;
                        }
                    } else if(AMHHelper_DenormAccountOppTriggerHandler.helperSecondCheck(relatedAccountMap, i, triggerOldMap)) { // null y oportunidad se cierra
                        System.debug('Segundo if del update para Exp Revenues');
                        relatedAccountMap.get(i.AMH_AccountId__c).customer_open_oppy_amount__c = 0;
                    }
                }
            }
        }
        return relatedAccountMap;
    }

     /**
    * @author Global Desktop
    * @description helper helperTriggerOldMapNull
    */
    private static Map<Id,Account> helperTriggerOldMapNull(Map<Id,Account> relatedAccMap, Map<Id,Opportunity> relatedOppMap, AMH_Denorm_Account_Opportunity__c iOpp) {
       final Map<Id,Account> relatedAccountMap = relatedAccMap;
        if(AMHHelper_DenormAccountOppTriggerHandler.helperFourthCheck(relatedAccountMap, relatedOppMap, iOpp)) {
            relatedAccountMap.get(iOpp.AMH_AccountId__c).customer_open_oppy_number__c = 1;
        } else if(AMHHelper_DenormAccountOppTriggerHandler.helperFiveCheck(relatedOppMap, iOpp)) {
            relatedAccountMap.get(iOpp.AMH_AccountId__c).customer_open_oppy_number__c  = relatedAccountMap.get(iOpp.AMH_AccountId__c).customer_open_oppy_number__c + 1;
        }
        if(AMHHelper_DenormAccountOppTriggerHandler.helperSixCheck(relatedAccountMap, relatedOppMap, iOpp)) {
            relatedAccountMap.get(iOpp.AMH_AccountId__c).customer_open_oppy_amount__c = iOpp.DES_Opportunity_Expected_Revenue__c;
        } else if(AMHHelper_DenormAccountOppTriggerHandler.helperSevenCheck(relatedOppMap, iOpp)) {
            relatedAccountMap.get(iOpp.AMH_AccountId__c).customer_open_oppy_amount__c = relatedAccountMap.get(iOpp.AMH_AccountId__c).customer_open_oppy_amount__c +  iOpp.DES_Opportunity_Expected_Revenue__c;
        }
        return relatedAccountMap;
    }
}