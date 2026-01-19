/**************************************************************************************************************
Name:            DES_DenormAccountOppTriggerHandler
Description:     Handler class for DES_DenormAccountOpportunityTrigger Trigger
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            11/05/2018                         Class creation
0.2            27/06/2018      Accenture          Añadida funcionalidad en "setPotentialRevenueRollup" para añadir el valor de DES_Opportunity_Potential_Revenue_Rollup__c
                                                  Modificado method denOpportunityAfterDelete para que si se cambia el accountId de una opp, se ejecute restore() y no borre la oportunidad a posteriori
0.3            29/06/2018      Accenture          Modificado method denOpportunityAfterDelete para que:
                                                    - para que si se cambia el accountId de una Opp, se ejecute restore() y no borre la Opp a posteriori
                                                    - no se eliminen las Opps cuando se ejecuta el proceso Batch programado de la denormalización.  El proceso Batch debe ser programado por el ADMIN y tiene que tener en el CustomSettings marcada la opcion "IsAdmin", así cuando se borre la tabla
                                                  denormalizada pues NO se elimina el registro relacionado de la tabla Opp. Para que un Admin pueda borrar manualmente una Oppa desde el LAYOUT debe
                                                  quitarse los checks "IsAdmin", "CIB_skip_trigger__c" y "CIB_DES_skip_trigger_in_denorm__c", cuando termine debe volver a marcarse los check para que en la ejecución siguiente del Batch NO se eliminen todas las Opps
0.4            06/07/2018      Accenture          Añadida funcionalidad en "before insert" para añadir el valor de CurrencyIsoCode
**************************************************************************************************************/
public with sharing class DES_DenormAccountOppTriggerHandler {
    private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
    private static CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();

    /**
    * @description Este method se encarga de eliminar la Oppa que tiene relacionada la Denorm Account Opp
    */
    public static void denOpportunityAfterDelete(Map<Id,dwp_acmh__Denorm_Account_Opportunity__c> triggerOldMap) {


        //Si se ha disparado por que se ha efectuado un Update en la Opportunity, no se debe hacer delete de la Oportunidad
        if (userSettings.CIB_Is_Admin__c || byPass.CIB_skip_trigger__c || byPass.CIB_DES_skip_trigger_in_denorm__c || SER_TriggerHelper.get_MethodFired('OpportunityDenorm_restoreUpdate')) {
            System.debug(Logginglevel.INFO,'>>>>>>> DES_DenormAccountOppTriggerHandler: Skip denOpportunityAfterDelete');
        }
         //Sólo se ejecuta si el usuario NO es Administrador y NO tiene chequeado CIB_skip_trigger__c ni CIB_DES_skip_trigger_in_denorm__c y no viene de un OpportunityDenorm_restoreUpdate
        else{
            Set<Id> setIdsDOpps = getSetIdsDOpps(triggerOldMap);
            if(!setIdsDOpps.isEmpty()) {
                final List<Opportunity> listaOpps = getlistaOpps(setIdsDOpps);
                System.debug('>>>>> listaOpps: ' + listaOpps);
                delete listaOpps;
            }
        }//FIN IF ELSE
    }

     /*
     * denOpportunityAfterDelete: helper denOpportunityAfterDelete
     */
    private static Set<Id> getSetIdsDOpps(Map<Id,dwp_acmh__Denorm_Account_Opportunity__c> triggerOldMap) {
        final Set<Id> setIdsDOpps = new Set<Id>();
        //Recojo en un Set los id's de las Opp
        for(dwp_acmh__Denorm_Account_Opportunity__c dOpp : triggerOldMap.values()) {
            if(dOpp.dwp_acmh__OpportunityId__c != null && !setIdsDOpps.contains(dOpp.dwp_acmh__OpportunityId__c)) {
                setIdsDOpps.add(dOpp.dwp_acmh__OpportunityId__c);
            }
        }
        return setIdsDOpps;
    }

    /*
     * getlistaOpps: helper denOpportunityAfterDelete
    */
    private static List<Opportunity> getlistaOpps(Set<Id> setIdsDOpps) {
        final List<Opportunity> listaOpps = new List<Opportunity>();
        for(Id oppId : setIdsDOpps) {
            Opportunity oppAux = new Opportunity();
            oppAux.id = oppId;
            listaOpps.add(oppAux);
        }
        System.debug('>>>>> listaOpps: ' + listaOpps);
        return listaOpps;
    }

    /*
     * Copia el valor del campo DES_Opportunity_PotentialRevenue_Formula__c en el campo DES_Opportunity_Potential_Revenue_Rollup__c.
     * La razón de crear este nuevo campo y rellenarlo es que no se puede utilizar un campo formula para hacer RollUpSummary, por eso se copia a uno que no es formula.
     */
    public static void setPotentialRevenueRollup(List<dwp_acmh__Denorm_Account_Opportunity__c> triggerNewList) {
        set<id> oppIds = new Set<id>();
        map<id,Opportunity> oppMap = new map<id,Opportunity>();
        for (dwp_acmh__Denorm_Account_Opportunity__c dao : triggerNewList) {
            oppIds.add(dao.dwp_acmh__OpportunityId__c);
        }

        final List<Opportunity> oppList = [Select Id, pre_oppy_revenue_next_12m_amount__c, CurrencyIsoCode, DES_Expected_Probability__c, StageName From Opportunity Where Id in :oppIds];
        if (!oppList.isEmpty()) {
            for (Opportunity opp : oppList) {
                oppMap.put(opp.id,opp);
            }

            for (dwp_acmh__Denorm_Account_Opportunity__c dao : triggerNewList) {
                dao.DES_Opportunity_Potential_Revenue_Rollup__c = oppMap.get(dao.dwp_acmh__OpportunityId__c).pre_oppy_revenue_next_12m_amount__c;
                dao.success_probability_per__c = oppMap.get(dao.dwp_acmh__OpportunityId__c).DES_Expected_Probability__c;
                dao.DES_Opportunity_Stage_Rollup__c = oppMap.get(dao.dwp_acmh__OpportunityId__c).StageName;
                dao.CurrencyIsoCode = oppMap.get(dao.dwp_acmh__OpportunityId__c).CurrencyIsoCode;
            }
        }

    }

    /*
    * @author Global Desktop
    * @description Actualiza las cuentas con datos de sus oportunidades relacionadas
    */
    /*
    public static void updateRelatedAccount(List<dwp_acmh__Denorm_Account_Opportunity__c> triggerNewList, Map<Id,dwp_acmh__Denorm_Account_Opportunity__c> triggerOldMap, boolean isDeleting) {
        final set<Id> relatedAccountIds = new set<Id>();
        final set<Id> relatedOpps = new set<Id>();
        for(dwp_acmh__Denorm_Account_Opportunity__c dao : isDeleting == false?triggerNewList:triggerOldMap.values()) {
            relatedAccountIds.add(dao.dwp_acmh__AccountId__c);
            relatedOpps.add(dao.dwp_acmh__OpportunityId__c);
        }
        Map<Id,Account> relatedAccountMap = new Map<Id,Account>([SELECT id, customer_open_oppy_number__c, customer_open_oppy_amount__c FROM Account WHERE id IN :relatedAccountIds]);
        final Map<Id,Opportunity> relatedOppMap = new Map<Id, Opportunity>([SELECT id, StageName, DES_Expected_Revenues__c, DES_Date_Won_Lost__c FROM Opportunity WHERE id IN :relatedOpps]);


        if(isDeleting == false) {
            relatedAccountMap = manageNotDeleting(relatedAccountMap, relatedOppMap, triggerNewList, triggerOldMap);
        } else if(isDeleting == true) {
            relatedAccountMap = manageIsDeleting(relatedAccountMap, triggerOldMap.values(), relatedOppMap);
        }

        System.debug('Valor de relatedAccountMap.values(): ' +relatedAccountMap.values());
        update relatedAccountMap.values();
    }*/

    /*
    * @author Global Desktop
    * @description helper manageIsDeleting
    */
    /*
    private static Map<Id,Account> manageIsDeleting(Map<Id,Account> relatedAccMap, List<dwp_acmh__Denorm_Account_Opportunity__c> triggerNewList, Map<Id,Opportunity> relatedOppMap) {
        final Map<Id,Account> relatedAccountMap = relatedAccMap;
        for(dwp_acmh__Denorm_Account_Opportunity__c i : triggerNewList) {
            if(relatedOppMap.get(i.dwp_acmh__OpportunityId__c).StageName != Label.DES_Closed_Won
                        && relatedOppMap.get(i.dwp_acmh__OpportunityId__c).StageName != Label.DES_Closed_Lose
                        && relatedOppMap.get(i.dwp_acmh__OpportunityId__c).StageName != Label.DES_Draft
                        && relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_number__c != null
                        && relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_amount__c != null) {
                        system.debug('++ stageName ' + relatedOppMap.get(i.dwp_acmh__OpportunityId__c).StageName);
                        system.debug('++ relatedAccountMap.get(i.dwp_acmh__AccountId__c) ' + relatedAccountMap.get(i.dwp_acmh__AccountId__c));
                        system.debug('++ relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_number__c ' + relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_number__c);
                relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_number__c = relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_number__c - 1;
                relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_amount__c = relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_amount__c - i.DES_Opportunity_Expected_Revenue__c;
            }
        }

        return relatedAccountMap;
    }
    */

    /*
    * @author Global Desktop
    * @description helper manageNotDeleting
    */
    /*
    private static Map<Id,Account> manageNotDeleting(Map<Id,Account> relatedAccMap, Map<Id,Opportunity> relatedOppMap, List<dwp_acmh__Denorm_Account_Opportunity__c> triggerNewList, Map<Id,dwp_acmh__Denorm_Account_Opportunity__c> triggerOldMap) {
        Map<Id,Account> relatedAccountMap = relatedAccMap;

        for(dwp_acmh__Denorm_Account_Opportunity__c i : triggerNewList) {
            if(triggerOldMap == null) {
                relatedAccountMap = helperTriggerOldMapNull(relatedAccountMap, relatedOppMap, i);
            } else if(triggerOldMap != null) {
                //Contador de las Alive Opportunities al actualizar
                if(Helper_DenormAccountOppTriggerHandler.helperThirdCheck(relatedAccountMap, i, triggerOldMap)) {
                    System.debug('Valor de relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_number__c: ' +relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_number__c);
                    relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_number__c  = relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_number__c - 1;
                }

                //Contador de los Expected Revenues al actualizar
                System.debug('Valor relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_amount__c: ' +relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_amount__c);
                System.debug('Valor de triggerOldMap.get(i.Id).DES_Opportunity_Potential_Revenue_Rollup__c: ' +triggerOldMap.get(i.Id).DES_Opportunity_Potential_Revenue_Rollup__c);
                if(Helper_DenormAccountOppTriggerHandler.helperFirstCheck(relatedAccountMap, i, triggerOldMap)) {
                    system.debug('++ i.dwp_acmh__AccountId__c ' +i.dwp_acmh__AccountId__c);
                    system.debug('++ relatedAccountMap ' +relatedAccountMap);
                    system.debug('++ relatedAccountMap.get(i.dwp_acmh__AccountId__c) ' + relatedAccountMap.get(i.dwp_acmh__AccountId__c));
                    system.debug('++ triggerOldMap ' + triggerOldMap);
                    system.debug('++ triggerOldMap.get(i.Id) ' + triggerOldMap.get(i.Id));
                    system.debug('++ ');
                    system.debug('++ ');
                    system.debug('++ ');
                    relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_amount__c =  relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_amount__c - (triggerOldMap.get(i.Id).DES_Opportunity_Potential_Revenue_Rollup__c * triggerOldMap.get(i.Id).success_probability_per__c/100) + i.DES_Opportunity_Expected_Revenue__c;
                } else if(Helper_DenormAccountOppTriggerHandler.helperSecondCheck(relatedAccountMap, i, triggerOldMap)) {
                    System.debug('Segundo if del update para Exp Revenues');
                    relatedAccountMap.get(i.dwp_acmh__AccountId__c).customer_open_oppy_amount__c = i.DES_Opportunity_Expected_Revenue__c;
                }
            }
        }
        return relatedAccountMap;
    }
    */

    /**
    * @author Global Desktop
    * @description helper helperTriggerOldMapNull
    */
    /*
    private static Map<Id,Account> helperTriggerOldMapNull(Map<Id,Account> relatedAccMap, Map<Id,Opportunity> relatedOppMap, dwp_acmh__Denorm_Account_Opportunity__c iOpp) {
       final Map<Id,Account> relatedAccountMap = relatedAccMap;
        if(Helper_DenormAccountOppTriggerHandler.helperFourthCheck(relatedAccountMap, relatedOppMap, iOpp)) {
            relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_number__c = 1;
        } else if(Helper_DenormAccountOppTriggerHandler.helperFiveCheck(relatedOppMap, iOpp)) {
            relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_number__c  = relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_number__c + 1;
        }
        if(Helper_DenormAccountOppTriggerHandler.helperSixCheck(relatedAccountMap, relatedOppMap, iOpp)) {
            relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_amount__c = iOpp.DES_Opportunity_Expected_Revenue__c;
        } else if(Helper_DenormAccountOppTriggerHandler.helperSevenCheck(relatedOppMap, iOpp)) {
            relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_amount__c = relatedAccountMap.get(iOpp.dwp_acmh__AccountId__c).customer_open_oppy_amount__c +  iOpp.DES_Opportunity_Expected_Revenue__c;
        }
        return relatedAccountMap;
    }
    */
}