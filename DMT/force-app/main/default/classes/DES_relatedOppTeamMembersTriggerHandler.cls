/***********************************************************************************************
Name:            DES_relatedOppTeamMembersTriggerHandler
Description:     Handler Class with custom methods for Opportunity.trigger
Test Class:      -

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            08/05/2018                        Class creation
2.0            19/06/2018      Accenture         Update -> Cambia la funcionalidad y ahora para 
                         añadir el OppTeam se añade la funcion recursiva que va 
                         añadiendo los AccTeam de toda la jerarquía superior 
                         (padres) de la Account de la Opportunity
3.0            12/07/2018      Accenture         Update -> Cambia la funcionalidad para añadir los miembros
                         'Transactional Banker'. Actualizado el scope a 'Global'
***********************************************************************************************/

public  with sharing class DES_relatedOppTeamMembersTriggerHandler {
    /*byPass*/
    final private CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();
    /*Group RecordType*/
    final private set<String> groupRecordtype = new set<String> { 'Group','Commercial Client'};
    /*util class*/
    final Desktop_Utils hDesktopUtils = Desktop_Utils.getInstance();

    /*SINGLETON PATTERN*/
    private static DES_relatedOppTeamMembersTriggerHandler instance;
    
    /*Constructor*/
    public static DES_relatedOppTeamMembersTriggerHandler getInstance() {
        if (instance == null) instance = new DES_relatedOppTeamMembersTriggerHandler();
        return instance;
    }

    /* ---------- PUBLIC METHODS ----------------*/

    /*
    *  este mét0d0 añade al usuario creador de la oportunidad como miembro del equipo de esta, con el check de owner marcado
    */
    public static void addOwnerOppMember(Map<Id,Opportunity> triggerNewMap) {
      List<DES_Opportunity_Management_member__c> lstOppMemb;
      lstOppMemb = new List<DES_Opportunity_Management_member__c>();

      for(Opportunity opp : triggerNewMap.values()) {
        final DES_Opportunity_Management_member__c member = new DES_Opportunity_Management_member__c(
        DES_Opportunity__c = opp.Id,
        DES_User__c = opp.OwnerId,
        DES_Owner__c = true,
        Name = opp.Owner.Name
        );
        lstOppMemb.add(member);
      }

      if(!lstOppMemb.isEmpty()) {
        try {
          insert lstOppMemb;
        } catch(Exception e) {
          for(DES_Opportunity_Management_member__c member : lstOppMemb) {
            triggerNewMap.get(member.DES_Opportunity__c).addError(Label.Error_Change_Owner_Opp);
          }
        }
      }
    }

    /*
    *  este mét0d0 añade al usuario creador de la oportunidad como miembro del equipo de esta, con el check de owner marcado
    */
    public void checkOwnerOppMember(Map<Id,Opportunity> triggerNewMap, Map<Id,Opportunity> triggerOldMap) { //NOSONAR
         OpportinityMember_cls.checkOwnerOppMember(triggerNewMap, triggerOldMap);
    }

    /*
    *  este mét0d0 está diseñado sólo para inserciones de Opp de una en una, no cargas masivas, 
    *  para que se traiga el AccTeam de la jerarquía cuando se da de alta una Opp
    */
    public void accHierarchyTeamCopyToOppTeam(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) { //NOSONAR
        List<Opportunity> listOpps = new List<Opportunity>();
        final List <DES_Opportunity_Management_member__c> lstOppTeamMbrsToIns = new List <DES_Opportunity_Management_member__c>(); //NOSONAR
        final Set<Id> setAccIds = new Set<Id>();
        final Set<String> setOppExc = obtainOppTeamExc(); //NOSONAR

        if (/*userSettings.CIB_Is_Desktop__c &&*/ !bypassSettings.CIB_DES_DataMigration__c) {
            // recorremos las oportunidades recibidas -> si el estado de triggerOld es Draft y el estado de triggerNew es Proposal, guardamos la oportunidad
            for(Opportunity i : triggerNewMap.values()) {
                if(!setAccIds.contains(i.AccountId)) {
                    setAccIds.add(i.AccountId);
                }
                if((triggerOldMap == null && i.StageName == Label.DES_Proposal)
                   || (triggerOldMap != null && triggerOldMap.get(i.Id).StageName == Label.DES_Draft && i.StageName == Label.DES_Proposal)) {
                    system.debug('>>>>>>>> accHierarchyTeamCopyToOppTeam: Entra ');
                       //Si es confidencial validamos si tiene algun producto que impida copiar el equipo
                    listOpps = oppToCopyTeam(listOpps, setOppExc, i);
                }
            }

            if ( !listOpps.isEmpty() ) {


              system.debug('>>>>>>>> 1. listaOportunidades: ' + listOpps);

              // Get all opportunity products of the opportunities
              // Set<Id> opportunitiesSet = new Set<Id>();
              final Set<Id> setOppWthPrdctGTB = new Set<Id>();
              final OpportunityLineItem[] oppProducts = [SELECT OpportunityId, DES_Product_Family__c, Product2Id, Opportunity.DES_Countries__c FROM OpportunityLineItem Where OpportunityId in :listOpps];
              for (OpportunityLineItem aux : oppProducts) {
                // me quedo con las oportunidades con opportunity products de familia GTB para la copia del TB
                if (aux.DES_Product_Family__c == Label.Product_Family_GTB //NOSONAR
                    && !setOppWthPrdctGTB.contains(aux.OpportunityId)) {
                      setOppWthPrdctGTB.add(aux.OpportunityId);
                }
              }

              //system.debug('>>>>>>>> 2. setOppWithProductGTB: ' + setOppWithProductGTB);

              /* Recupero el tipo de Account de la Opp, para luego las comparaciones con el Transactional Banker comparar si es Filial, Grupo */
              final Map<Id, Opportunity> mapAccountsOpp = new Map<Id, Opportunity>([SELECT Id, Account.DES_Country_Client__c, Account.RecordType.Name FROM Opportunity Where Id in :listOpps]);
              system.debug('>>>>> setAccIds : ' + setAccIds);
              final Map<Id, Id> mapClientGroup = hDesktopUtils.getMapClientGroup(setAccIds);
              //Llamo a la funcion que me devuelve t0dos los miembros del cliente directo y del grupo.
              //Mapa que contiene el id del cliente directo de la opp como key y una lista con los miembros del cliente directo y los miembros del grupo
              final Map<Id, List<DES_BBVA_Management_team__c>> mapAccCltTeamMbrs = getBBVATeamMembers(mapAccountsOpp, mapClientGroup, setAccIds);

              Boolean isGroup;
              // este mét0d0 está pensado sólo para inserciones de Opp de una en una, no cargas masivas, para que se traiga
              // el AccTeam de la jerarquía cuando se da de alta una Opp
              Set<DES_BBVA_Management_team__c> oppAccTeamMembers; // acumula t0d0s los team members, ya sean de la filial o del grupo
              for (Opportunity opp : listOpps) {
                //setAccIdHierarchyForOpp.clear();
                system.debug('>>>>>> opp : ' + opp);
                system.debug('>>>>> mapAccClientTeamMembers : ' + mapAccCltTeamMbrs);

                oppAccTeamMembers = new Set<DES_BBVA_Management_team__c>();

                if ( opp.AccountId != null ) { //NOSONAR

                  if (mapAccCltTeamMbrs.get( opp.AccountId ) != null ) {
                    oppAccTeamMembers.addAll(mapAccCltTeamMbrs.get( opp.AccountId ) );
                  }
                  if ( mapClientGroup.get( opp.AccountId ) != null && mapAccCltTeamMbrs.get( mapClientGroup.get( opp.AccountId ) ) != null ) {
                    oppAccTeamMembers.addAll(mapAccCltTeamMbrs.get( mapClientGroup.get( opp.AccountId ) ) );
                  }

                  System.debug( '@@oppAccTeamMembers' + oppAccTeamMembers );

                }


                if ( !oppAccTeamMembers.isEmpty() ) {

                  system.debug('>>> mapAccClientTeamMembers.get(opp.AccountId) : ' + mapAccCltTeamMbrs.get(opp.AccountId));
                  // por cada Oportunidad, recorro los DES_BBVA_Management_team__c traidos de la cuenta de la opp 
                  // y todas sus cuentas padres, y se añaden al equipo de la Opp.

                    for (DES_BBVA_Management_team__c auxClientTM : oppAccTeamMembers ) {
                      if (auxClientTM.DES_User__r.isActive) {
                        system.debug('>>>>> 4-2.auxClientTM: ' + auxClientTM);
                        DES_Opportunity_Management_member__c oppTM;
                        //SI EL MIEMBRO QUE SE VA A COPIAR ES PRODUCT SPECIALIST Y/O LOCAL BANKER Y/O REGIONAL BANKER TENGO QUE COMPROBAR SI EL PAÍS COINCIDE
                        if (auxClientTM.DES_Member_Role__c == Label.DES_Role_Product_Specialist //NOSONAR
                            || auxClientTM.DES_Member_Role__c == Label.DES_Role_Regional_Banker
                            || auxClientTM.DES_Member_Role__c == Label.DES_ROLE_LOCAL_BANKER) {
                          //Si opp.DES_Country__c contiene más de 1 país
                          if (!String.isBlank(opp.DES_Countries__c)) { //NOSONAR
                            for (String pais : opp.DES_Countries__c.split(';')) {
                              //Si coinciden el país y el producto, llamo a una funcion para crear un miembro de la Opp y 
                              //relleno el PS del opportunity product para que no se ejecute la matriz
                              if (pais == auxClientTM.DES_Local_Banker_Country__c) { //NOSONAR
                                oppTM = generarOppTeamMember(opp, auxClientTM);
                                if (auxClientTM.DES_Member_Role__c == Label.DES_Role_Product_Specialist) { //NOSONAR
                                  for (OpportunityLineItem auxOppProduct : oppProducts) {
                                    if (auxClientTM.DES_PS_Product__c != null && auxOppProduct.Product2Id == auxClientTM.DES_PS_Product__c) { //NOSONAR
                                      oppTM = generarOppTeamMember(opp, auxClientTM);
                                      auxOppProduct.DES_Product_Specialist__c = auxClientTM.DES_User__c;
                                    }
                                  }
                                }
                                //Paro la ejecución del FOR, ya que no necesito seguir recorriendo la lista de paises
                                break;
                              }
                            }
                          }

                          //SI EL MIEMBRO ES TRANSACTIONAL BANKER
                        } else if (auxClientTM.DES_Member_Role__c == Label.DES_Role_Transactional_Banker) {
//                                        if( (setOppWithProductGTB.contains(opp.Id) ) ||
//                                           (groupRecordtype.contains(mapAccountsOpp.get(opp.Id).Account.RecordType.Name) 
//                                           && opp.DES_Booking_Geography__c != null 
//                                           && opp.DES_Booking_Geography__c == auxClientTM.DES_Local_Banker_Country__c 
//                                           && auxClientTM.DES_Tipo_de_cobertura__c == 'SINGLE') ||
//                                           (subsidiaryRecordtype.contains(mapAccountsOpp.get(opp.Id).Account.RecordType.Name) 
//                                           && mapAccountsOpp.get(opp.Id).Account.DES_Country_Client__c != null 
//                                           && mapAccountsOpp.get(opp.Id).Account.DES_Country_Client__c == auxClientTM.DES_Local_Banker_Country__c 
//                                           && auxClientTM.DES_Tipo_de_cobertura__c == 'SINGLE') ) {
//                                           oppTM = generarOppTeamMember(opp, auxClientTM);
//                                        }
                          final Boolean hasGTBProduct = setOppWthPrdctGTB.contains(opp.Id);
                          final Boolean sameAccCountry = mapAccountsOpp.get(opp.Id).Account.DES_Country_Client__c == null ?
                              false :
                              mapAccountsOpp.get(opp.Id).Account.DES_Country_Client__c == auxClientTM.DES_Local_Banker_Country__c;
                          final Boolean sameOppBkngGeo = opp.DES_Booking_Geography__c == null ?
                              false :
                              opp.DES_Booking_Geography__c == auxClientTM.DES_Local_Banker_Country__c;
                          final Boolean isSingle = auxClientTM.DES_Tipo_de_cobertura__c == 'SINGLE';
                            
                          isGroup = groupRecordtype.contains(mapAccountsOpp.get(opp.Id).Account.RecordType.Name);
                          if (isGroup && hasGTBProduct && sameAccCountry
                              || isGroup && !hasGTBProduct && sameOppBkngGeo && isSingle
                              || !isGroup && hasGTBProduct && sameAccCountry
                              || !isGroup && !hasGTBProduct && sameAccCountry && isSingle
                              ) {
                            oppTM = generarOppTeamMember(opp, auxClientTM);
                          }

                        } else {//Si no es ninguno de los roles anteriores se copia sin validar nada
                          oppTM = generarOppTeamMember(opp, auxClientTM);
                        }
                        system.debug('>>>>> oppTM : ' + oppTM);
                        //system.debug('>>>>> 5. oppTM: ' + oppTM);
                        // auxOppTM.DES_PS_Product__c = auxClientTM.DES_PS_Product__c;
                        if (oppTM != null && !checkDuplicates(lstOppTeamMbrsToIns, oppTM)) { //NOSONAR
                          lstOppTeamMbrsToIns.add(oppTM);
                        }
                        system.debug('>>>>> listaOppTeamMembersToInsert : ' + lstOppTeamMbrsToIns);
                        //system.debug('>>>>> 6. listaOppTeamMembersToInsert: ' + listaOppTeamMembersToInsert);
                      }//FIN IF user is active
                    }
//                  }
                  system.debug('>>>>> mapClientGroup : ' + mapClientGroup);
                  system.debug('>>>>> mapClientGroup.get(opp.AccountId) : ' + mapClientGroup.get(opp.AccountId));
                  system.debug('>>>>>  mapAccClientTeamMembers.get(mapClientGroup.get(opp.AccountId)) : ' + mapAccCltTeamMbrs.get(mapClientGroup.get(opp.AccountId)));

                }//FIN IF !oppAccTeamMembers.isEmpty()
              }// FIN FOR
              system.debug('Valor de listaOppTeamMembersToInsert: ' + lstOppTeamMbrsToIns);
              try {
                insert lstOppTeamMbrsToIns;
              } catch (Exception e) {
                system.debug('>>>>> 7. Exception: ' + e);
              }
            }
        } // FIN  if (userSettings.CIB_Is_Desktop__c && !bypassSettings.CIB_DES_DataMigration__c)
    } // FIN Method

    private Map<Id, List<DES_BBVA_Management_team__c>> getBBVATeamMembers(Map<Id,Opportunity> mapAccountsOpp, Map<Id, Id> mapClientGroup, Set<Id> setAccIds) { //NOSONAR
       final Map<Id, List<DES_BBVA_Management_team__c>> mapAccClntTmMbrs = new Map<Id, List<DES_BBVA_Management_team__c>>();

       final Set<Id> setAllAccIds = new Set<Id>();
       setAllAccIds.addAll(setAccIds);

       if(!mapClientGroup.isEmpty()) {
            setAllAccIds.addAll(mapClientGroup.values());
       }
       for(DES_BBVA_Management_team__c bbvaMT : [SELECT  Id,
                                                        DES_User__c,
                                                        DES_User__r.isActive,
                                                        DES_User__r.Name,
                                                        DES_Client__c,
                                                        DES_Member_Role__c,
                                                        DES_Local_Banker_Country__c,
                                                        DES_Tipo_de_cobertura__c,
                                                        DES_Client__r.DES_Country_Client__c,
                                                        DES_Client__r.RecordType.Name,
                                                        DES_PS_Product_Family__c,
                                                        DES_PS_Product__c
                                                FROM DES_BBVA_Management_team__c
                                                WHERE DES_Client__c IN :setAllAccIds
                                                    AND copy_record_approval_type__c = false]) {

            List<DES_BBVA_Management_team__c> listBBVAMT = new List<DES_BBVA_Management_team__c>();
            if(mapAccClntTmMbrs.get(bbvaMT.DES_Client__c) != null) {
                listBBVAMT = mapAccClntTmMbrs.get(bbvaMT.DES_Client__c);
            }
            listBBVAMT.add(bbvaMT);
            mapAccClntTmMbrs.put(bbvaMT.DES_Client__c, listBBVAMT);

       }

       return mapAccClntTmMbrs;
    }


// --------------------------------- PRIVATE METHODS --------------------------------- //

    private DES_Opportunity_Management_member__c generarOppTeamMember(Opportunity auxOpp, DES_BBVA_Management_team__c auxClientTM) { //NOSONAR
        system.debug('>>>>> INPUT auxOpp : ' + auxOpp);
        system.debug('>>>>> INPUT auxClientTM : ' + auxClientTM);
        final DES_Opportunity_Management_member__c auxOppTM = new DES_Opportunity_Management_member__c();
        auxOppTM.DES_Opportunity__c = auxOpp.Id;
        auxOppTM.DES_User__c = auxClientTM.DES_User__c;
        auxOppTM.DES_Opportunity_member_role__c = auxClientTM.DES_Member_Role__c;
        auxOppTM.DES_PS_Product_Family__c = auxClientTM.DES_PS_Product_Family__c;
        auxOppTM.DES_PS_Product__c = auxClientTM.DES_PS_Product__c;
//        if (auxClientTM.DES_Member_Role__c == Label.DES_ROLE_GLOBAL_BANKER || auxClientTM.DES_Member_Role__c == Label.DES_ROLE_INDUSTRY_HEAD){ //NOSONAR
//            auxOppTM.DES_Scope__c = 'Global';
//        }else{
        auxOppTM.DES_Scope__c = auxClientTM.DES_Local_Banker_Country__c;
//        }
        system.debug('>>>>> auxOppTM RETURN : ' + auxOppTM);
        return auxOppTM;
    }


  //Recursive function to add the AccTeamMembers of the Account hierarchy for a given opportunity
  //starting from Opportunity.AccountId
    private Boolean checkDuplicates(List<DES_Opportunity_Management_member__c> currentList, DES_Opportunity_Management_member__c newBBVAManagement) {
        // recorro la lista incial (currentList) y la comparo con la lista recogida (listaBBVAMT). Si hay alguna 
        // pareja repetida el met0d0 devuelve FALSE y no se añade a currentList
        Boolean hayDuplicado = false;

        for(DES_Opportunity_Management_member__c oppBBVAmember : currentList) {
                if(oppBBVAmember.DES_Opportunity__c == newBBVAManagement.DES_Opportunity__c && oppBBVAmember.DES_User__c == newBBVAManagement.DES_User__c && oppBBVAmember.DES_Opportunity_member_role__c == newBBVAManagement.DES_Opportunity_member_role__c) {
                    // Global Banker, Industry Head y Risk Analyst
                    if (oppBBVAmember.DES_Opportunity_member_role__c == Label.DES_ROLE_SECONDARY_GB || oppBBVAmember.DES_Opportunity_member_role__c == Label.DES_ROLE_GLOBAL_BANKER || oppBBVAmember.DES_Opportunity_member_role__c == Label.DES_ROLE_INDUSTRY_HEAD || oppBBVAmember.DES_Opportunity_member_role__c == Label.DES_Role_Risk_Analyst) {
                        hayDuplicado = true;

                    // Local Banker y Transactional Banker
                    } else if (oppBBVAmember.DES_Scope__c == newBBVAManagement.DES_Scope__c
                               && (oppBBVAmember.DES_Opportunity_member_role__c == Label.DES_ROLE_LOCAL_BANKER || oppBBVAmember.DES_Opportunity_member_role__c == Label.DES_Role_Transactional_Banker || oppBBVAmember.DES_Opportunity_member_role__c == Label.DES_Role_Regional_Banker)) {
                      hayDuplicado = true;
                    // Product Specialist
                     } else if ( oppBBVAmember.DES_PS_Product__c == newBBVAManagement.DES_PS_Product__c
                                && oppBBVAmember.DES_Opportunity_member_role__c == Label.DES_Role_Product_Specialist) {
                    	hayDuplicado = true;
                     }
                }// FIN IF

        }// FIN FOR

        return hayDuplicado;
    } // FIN checkDuplicates()



// --------------------------------- OBSOLETE METHODS --------------------------------- //
    private static Set<String> obtainOppTeamExc() {
    final Set<String> values = new Set<String>();
    for(Opp_Team_exc__mdt oppExc : [SELECT Id, Label  from Opp_Team_exc__mdt LIMIT 100]) {
            values.add(oppExc.Label);
        }
    return values;
  }

    private static Boolean checkOppExc(Id oppid, Set<String> setOppExc) {
    Boolean noExcluido = true;
    final List<OpportunityLineItem> listaProdOppNew = new List<OpportunityLineItem>([
                                                                                    SELECT  Id,solution_classification_desc__c
                                                                                  FROM OpportunityLineItem
                                                                                  WHERE OpportunityId = :oppid and solution_classification_desc__c IN :setOppExc]);
    if(listaProdOppNew != null && !listaProdOppNew.isEmpty()) {
         noExcluido = false;
      }


    return noExcluido;
  }

  private  List<Opportunity> oppToCopyTeam(List<Opportunity> aOpps, Set<String> setOppExc, Opportunity opp) { //NOSONAR
    if((opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId() ||
      opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_SalesGM_Confidential_Opp).getRecordTypeId()) && checkOppExc(opp.Id, setOppExc)) {
        //Si no tiene productos que excluyan lo añadimos
              system.debug('>>>>>>>> accHierarchyTeamCopyToOppTeam: if ');

        aOpps.add(opp);


      //si no es confidencial lo añadimos
    } else if(opp.recordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId() &&
      opp.recordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_SalesGM_Confidential_Opp).getRecordTypeId() &&
      opp.recordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_opp).getRecordTypeId() &&
      opp.recordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_GM_opp).getRecordTypeId()) {
                system.debug('>>>>>>>> accHierarchyTeamCopyToOppTeam: else ');
        aOpps.add(opp);
    }

    return aOpps;
  }
}