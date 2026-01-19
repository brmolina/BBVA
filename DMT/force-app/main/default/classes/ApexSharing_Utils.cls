/**************************************************************************************************************
Name:            ApexSharing_Utils
Description:     Clase que contiene los métodos necesarios para la gestión del Apex Sharing
Test Class:

Version        Date            Author             Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            18/12/2018      VASS - DSL           Creación de las clases para el apex sharing de oportunidades,
                          visitas y alertas con el cliente directo y el grupo global
**************************************************************************************************************/
public with sharing class ApexSharing_Utils {
    private CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
    final Desktop_Utils handlerDesktopUtils = Desktop_Utils.getInstance();

    //Constructor
    private ApexSharing_Utils() {

    }

    //SINGLETON PATTERN
    private static ApexSharing_Utils instance;
    public static ApexSharing_Utils getInstance() {
        if (instance == null) instance = new ApexSharing_Utils();
        return instance;
    }



    /*
     *  Función que recoge los datos necesarios para el Apex Sharing
    **/
    public void createManualSharing(List<DES_BBVA_Management_team__c> triggerNew) {
    Set<Id> setUsersId = new Set<Id>();
    Set<Id> setAccountsIds = new Set<Id>();
    Map<Id, Id> mapIdMemberIdAcc = new Map<Id, Id>();
    for(DES_BBVA_Management_Team__c bbvaMT : triggerNew) {

      mapIdMemberIdAcc.put(bbvaMT.Id, bbvamt.DES_Client__c);

      if(!setUsersId.contains(bbvaMT.DES_User__c)) {
        setUsersId.add(bbvaMT.DES_User__c);
      }
      if(!setAccountsIds.contains(bbvaMT.DES_Client__c)) {
        setAccountsIds.add(bbvaMT.DES_Client__c);
      }
    }
    system.debug('>>>>> setAccountsIds : ' + setAccountsIds);
    if(!setAccountsIds.isEmpty()) {
      manualSharing(triggerNew, setAccountsIds, mapIdMemberIdAcc);
      //manualSharingCommAlerts(triggerNew, setAccountsIds, setUsersId);
      //manualSharingVisits(triggerNew, setAccountsIds, setUsersId);
    }
  }//FIN CreateManualSharing


    /*
     *  Función que
    **/
  private void manualSharing(List<DES_BBVA_Management_team__c> triggerNew, Set<Id> setAccountsIds, Map<Id, Id> mapIdMemberIdAcc) {
    system.debug('>>>>> mapIdMemberIdAcc : ' + mapIdMemberIdAcc);
    //Busco todos los id's de cuentas que tienen como padre alguno de los id's que están en el set
    Set<Id> setAllAccIds = new Set<Id>();
    setAllAccIds.addAll(mapIdMemberIdAcc.values());
    setAllAccIds.addAll(setAccountsIds);
    Map<Id, String> mapGroupClients = new Map<Id, String>();//Mapa que tiene el Id del grupo como key y concatenados los id's de los clientes que están por debajo de la jerarquía
    for(Id idAcc : setAccountsIds) {
      if(mapGroupClients.get(idAcc) == null) {
        mapGroupClients.put(idAcc, idAcc);
      }
    }
    //Busco los id's de todas las filiales y las agrego al set de todas las accounts
    for(DES_Subsidiary_Group_Relation__c matrix : [SELECT id, participant_child_id__c, participant_parent_id__c FROM DES_Subsidiary_Group_Relation__c WHERE participant_parent_id__c IN :setAccountsIds AND main_subsidiary_ind_type__c = true]) {
      if(!setAllAccIds.contains(matrix.participant_child_id__c)) {
        setAllAccIds.add(matrix.participant_child_id__c);
      }
      if(!setAllAccIds.contains(matrix.participant_parent_id__c)) {
        setAllAccIds.add(matrix.participant_parent_id__c);
      }
      if(mapGroupClients.get(matrix.participant_parent_id__c) != null) {
        mapGroupClients.put(matrix.participant_parent_id__c, mapGroupClients.get(matrix.participant_parent_id__c) + ';' + matrix.participant_parent_id__c + ';' + matrix.participant_child_id__c);
      }else{
        mapGroupClients.put(matrix.participant_parent_id__c, matrix.participant_parent_id__c + ';' + matrix.participant_child_id__c);
      }
    }


    //Busco todas las oportunidades vinculadas a estas cuentas
    Map<Id, String> mapAccOpp = getMapAccOpps(setAllAccIds);
    system.debug('>>>>> mapAccOpp : ' + mapAccOpp);

    //Map con el Id de la cuenta como Key y un string que concatena los id's de las commercial alerts
    Map<Id, String> mapAccAlerts = getMapAccAlerts(setAllAccIds);
    system.debug('>>>>> mapAccAlerts : ' + mapAccAlerts);
    /*DESCOMENTAR ESTO AL SUBIR ALERTAS
    */

    Map<Id, String> mapAccVisits = getMapAccVisits(setAllAccIds);
    system.debug('>>>>> mapAccVisits : ' + mapAccVisits);

    List<OpportunityShare> listOppShareInsert = new List<OpportunityShare>();//LISTA PARA INSERTAR MANUAL SHARING DE OPORTUNIDADES
    List<dwp_kitv__Visit__Share> listvisitSharing = new List<dwp_kitv__Visit__Share>();
    List<almd__Commercial_Alert__Share> listCommercialAlerts = new List<almd__Commercial_Alert__Share>();
    /*DESCOMENTAR ESTO AL SUBIR ALERTAS*/
    system.debug('>>>>> triggerNew : ' + triggerNew);
    system.debug('>>>>> mapGroupClients : ' + mapGroupClients);
    system.debug('>>>>> mapAccOpp : ' + mapAccOpp);
    //Recorro el triggerNew y le doy permisos para todas las oportunidades del grupo y de sus filiales hijas
    for(DES_BBVA_Management_team__c bbvamt : triggerNew) {
      if(!bbvamt.copy_record_approval_type__c) {
        //Accedo a las oportunidades del cliente directo
        //Accedo a todas las cuentas hijas
        if(mapGroupClients.get(bbvamt.DES_Client__c) != null
        && mapGroupClients.get(bbvamt.DES_Client__c).contains(';')) {
          system.debug('>>>>> mapGroupClients CONTAINS ;');
          List<String> listClients = mapGroupClients.get(bbvamt.DES_Client__c).split(';');
          for(String accId : listClients) {
            system.debug('>>>>> accId : ' + accId);
            system.debug('>>>>> mapAccOpp.get(accId) : ' + mapAccOpp.get(accId));
            system.debug('>>>>> mapAccVisits.get(accId) : ' + mapAccVisits.get(accId));
            listOppShareInsert = addToOppShareListMultiClients(listOppShareInsert, bbvamt, mapAccOpp, accId);
            listvisitSharing = addToVisitShareListMultiClients(listvisitSharing, bbvamt, mapAccVisits, accId);
            listCommercialAlerts = addToComAlertShareListMultiClients(listCommercialAlerts, bbvamt, mapAccAlerts, accId);
            /*DESCOMENTAR ESTO AL SUBIR ALERTAS*/
            system.debug('>>>>> listOppShareInsert : ' + listOppShareInsert);
          }
        } else if(mapGroupClients.get(bbvamt.DES_Client__c) != null) { //IF NOT CONTAINS ;
          system.debug('>>>>> mapGroupClients NOT CONTAINS ;');
          system.debug('>>>>> mapGroupClients.get(bbvamt.DES_Client__c) : ' + mapGroupClients.get(bbvamt.DES_Client__c));
          system.debug('>>>>> mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)) : ' + mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)));
          listOppShareInsert = addToOppShareListOneClient(listOppShareInsert, bbvamt, mapAccOpp, mapGroupClients);
          listvisitSharing = addToVisitShareListOneClient(listvisitSharing, bbvamt, mapAccVisits, mapGroupClients);
          listCommercialAlerts = addToAlertsShareListOneClient(listCommercialAlerts, bbvamt, mapAccAlerts, mapGroupClients);
          /*DESCOMENTAR ESTO AL SUBIR ALERTAS*/
          system.debug('>>>>> listOppShareInsert : ' + listOppShareInsert);
        }
      }

    }
    system.debug('>>>>> triggerNew : ' + triggerNew);
    system.debug('>>>>> mapGroupClients : ' + mapGroupClients);
    system.debug('>>>>> mapAccOpp : ' + mapAccOpp);
    system.debug(' >>>>> listOppShareInsert : ' + listOppShareInsert);
    system.debug(' >>>>> listvisitSharing : ' + listvisitSharing);
    //system.debug(' >>>>> listCommercialAlerts : ' + listCommercialAlerts);
    //List<Database.SaveResult> listSRComAlert = Database.insert(listComAlertSharing, false);
    insertApexSharings(listOppShareInsert, listvisitSharing, listCommercialAlerts );
    /*if(!listOppShareInsert.isEmpty()) {
      List<Database.SaveResult> listSROpps = Database.insert(listOppShareInsert, false);
    }
    if(!listvisitSharing.isEmpty()) {
      List<Database.SaveResult> listSRVisits = Database.insert(listvisitSharing, false);
    }
    if(!listCommercialAlerts.isEmpty()) {
      List<Database.SaveResult> listSRComAlerts = Database.insert(listCommercialAlerts, false);
    }*/
  }//FIN manualSharing

    private void insertApexSharings(List<OpportunityShare> listOppShareInsert, List<dwp_kitv__Visit__Share> listvisitSharing, List<almd__Commercial_Alert__Share> listCommercialAlerts) {
    if(!listOppShareInsert.isEmpty()) {
      List<Database.SaveResult> listSROpps = Database.insert(listOppShareInsert, false);
    }
    if(!listvisitSharing.isEmpty()) {
      List<Database.SaveResult> listSRVisits = Database.insert(listvisitSharing, false);
    }
    if(!listCommercialAlerts.isEmpty()) {
      List<Database.SaveResult> listSRComAlerts = Database.insert(listCommercialAlerts, false);
    }
    }


    private Map<Id, String> getMapAccOpps(Set<Id> setAllAccIds) {
    Map<Id, String> mapAccOpp = new Map<Id, String>();
    system.debug('>>>>> setAllAccIds : ' + setAllAccIds);
    //Concateno las cuentas y las oportunidades vinculadas a cada cuenta
    for(Opportunity opp : [SELECT Id, Name, AccountId FROM Opportunity WHERE AccountId IN :setAllAccIds AND StageName != :Label.DES_Draft]) {
      if(mapAccOpp.get(opp.AccountId) != null) {
        mapAccOpp.put(opp.AccountId, mapAccOpp.get(opp.AccountId) + ';' + opp.Id);
      }else{
        mapAccOpp.put(opp.AccountId, opp.Id);
      }
    }
    return mapAccOpp;
  }


  private Map<Id, String> getMapAccAlerts(Set<Id> setAccountsIds) {
    Map<Id, String> mapAccAlerts = new Map<Id, String>();
    for(almd__Commercial_Alert__c comAlert : [SELECT  Id, Name, almd__participant_id__c FROM almd__Commercial_Alert__c WHERE almd__participant_id__c IN :setAccountsIds]) {
      //system.debug('>>>>> comAlert : ' + comAlert);
      //system.debug('>>>>> mapAccAlerts.get(comAlert.participant_id__c) : ' + mapAccAlerts.get(comAlert.participant_id__c));
      //SI NO CONTIENE EL REGISTRO DE LA CUENTA
      if(mapAccAlerts.get(comAlert.almd__participant_id__c) == null) {
        mapAccAlerts.put(comAlert.almd__participant_id__c, comAlert.Id);
      }else{
        String alerts = mapAccAlerts.get(comAlert.almd__participant_id__c);
        alerts += ';' + comAlert.Id;
        mapAccAlerts.put(comAlert.almd__participant_id__c, alerts);
      }
    }
    return mapAccAlerts;
  }
  /*DESCOMENTAR ESTO AL SUBIR ALERTAS*/


  private Map<Id, String> getMapAccVisits(Set<Id> setAccountsIds) {
    //Map con el Id de la cuenta como Key y un string que concatena los id's de las VISITAS
    Map<Id, String> mapAccVisits = new Map<Id, String>();
    system.debug('>>>>> mapAccVisits : ' + mapAccVisits);
    for(dwp_kitv__Visit__c visit : [SELECT  Id, Name, dwp_kitv__account_id__c FROM dwp_kitv__Visit__c WHERE RecordTypeId = :Desktop_Utils.RTVISITCONF AND dwp_kitv__account_id__c IN :setAccountsIds]) {
      //system.debug('>>>>> visit : ' + visit);
      //system.debug('>>>>> mapAccVisits.get(visit.dwp_kitv__account_id__c) : ' + mapAccVisits.get(visit.dwp_kitv__account_id__c));
      //SI NO CONTIENE EL REGISTRO DE LA CUENTA
      if(mapAccVisits.get(visit.dwp_kitv__account_id__c) == null) {
        mapAccVisits.put(visit.dwp_kitv__account_id__c, visit.Id);
      }else{
        String visits = mapAccVisits.get(visit.dwp_kitv__account_id__c);
        visits += ';' + visit.Id;
        mapAccVisits.put(visit.dwp_kitv__account_id__c, visits);
      }
    }
    return mapAccVisits;
  }


    private List<OpportunityShare> addToOppShareListMultiClients(List<OpportunityShare> listOppShareInsert, DES_BBVA_Management_team__c bbvamt, Map<Id, String> mapAccOpp, String accId) {
    //List<OpportunityShare> listOppShareInsert = listOppShareInsert;
    if(mapAccOpp.get(accId) != null
    && mapAccOpp.get(accId).contains(';')) {
      system.debug('>>>>> mapAccOpp CONTAINS ;');
      List<String> listOpps = mapAccOpp.get(accId).split(';');
      for(String opp : listOpps) {
        //Creo el manual Sharing
        listOppShareInsert.add(handlerDesktopUtils.newManualSharingOpportunity(opp, bbvamt.DES_User__c, 'Edit'));
      }
    }else if(mapAccOpp.get(accId) != null) {//IF NOT CONTAINS ;
      system.debug('>>>>> mapAccOpp NOT CONTAINS ;');
      listOppShareInsert.add(handlerDesktopUtils.newManualSharingOpportunity(mapAccOpp.get(accId), bbvamt.DES_User__c, 'Edit'));
    }

    return listOppShareInsert;
  }//FIN addToOppShareListMultiClients

  private List<dwp_kitv__Visit__Share> addToVisitShareListMultiClients(List<dwp_kitv__Visit__Share> listvisitSharing, DES_BBVA_Management_team__c bbvamt, Map<Id, String> mapAccVisits, String accId) {
    //List<dwp_kitv__Visit__Share> listvisitSharing = new List<dwp_kitv__Visit__Share>();
    system.debug('>>>>> accId : ' + accId);
    if(mapAccVisits.get(accId) != null
    && mapAccVisits.get(accId).contains(';')) {
      system.debug('>>>>> mapAccVisits CONTAINS ;');
      system.debug('>>>>> mapAccVisits.get(accId) : ' + mapAccVisits.get(accId));
      for(String alertId : mapAccVisits.get(accId).split(';')) {
        listvisitSharing.add(handlerDesktopUtils.newManualSharingVisit(alertId, bbvaMT.DES_User__c, 'Edit'));
      }
    }else if(mapAccVisits.get(accId) != null) {//IF NOT CONTAINS ;
      system.debug('>>>>> mapAccVisits NOT CONTAINS ;');
      system.debug('>>>>> mapAccVisits.get(accId) : ' + mapAccVisits.get(accId));
      listvisitSharing.add(handlerDesktopUtils.newManualSharingVisit(mapAccVisits.get(accId), bbvaMT.DES_User__c, 'Edit'));
    }
    system.debug('>>>>> listvisitSharing : ' + listvisitSharing);
    return listvisitSharing;
    //List<Database.SaveResult> listSR = Database.insert(listvisitSharing, false);
  }//FIN addToOppShareListMultiClients


  private List<almd__Commercial_Alert__Share> addToComAlertShareListMultiClients(List<almd__Commercial_Alert__Share> listCommercialAlerts, DES_BBVA_Management_team__c bbvamt, Map<Id, String> mapAccAlerts, String accId) {
    //List<dwp_kitv__Visit__Share> listCommercialAlerts = new List<dwp_kitv__Visit__Share>();
    system.debug('>>>>> accId : ' + accId);
    if(mapAccAlerts.get(accId) != null
    && mapAccAlerts.get(accId).contains(';')) {
      system.debug('>>>>> mapAccAlerts CONTAINS ;');
      system.debug('>>>>> mapAccAlerts.get(accId) : ' + mapAccAlerts.get(accId));
      for(String alertId : mapAccAlerts.get(accId).split(';')) {
        listCommercialAlerts.add(handlerDesktopUtils.newManualSharingCommercialAlert(alertId, bbvaMT.DES_User__c, 'Edit'));
      }
    }else if(mapAccAlerts.get(accId) != null) {//IF NOT CONTAINS ;
      system.debug('>>>>> mapAccAlerts NOT CONTAINS ;');
      system.debug('>>>>> mapAccAlerts.get(accId) : ' + mapAccAlerts.get(accId));
      listCommercialAlerts.add(handlerDesktopUtils.newManualSharingCommercialAlert(mapAccAlerts.get(accId), bbvaMT.DES_User__c, 'Edit'));
    }
    system.debug('>>>>> listCommercialAlerts : ' + listCommercialAlerts);
    return listCommercialAlerts;
    //List<Database.SaveResult> listSR = Database.insert(listCommercialAlerts, false);
  }//FIN addToOppShareListMultiClients
  /*DESCOMENTAR ESTO AL SUBIR ALERTAS*/

  private List<OpportunityShare> addToOppShareListOneClient(List<OpportunityShare> listOppShareInsert, DES_BBVA_Management_team__c bbvamt, Map<Id, String> mapAccOpp, Map<Id, String> mapGroupClients) {
    //List<OpportunityShare> listOppShareInsert = listOppShareInsert;

    if(mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)) != null
    && mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)).contains(';')) {
      system.debug('>>>>> mapAccOpp CONTAINS ;');
      List<String> listOpps = mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)).split(';');
      for(String opp : listOpps) {
        //Creo el manual Sharing
        listOppShareInsert.add(handlerDesktopUtils.newManualSharingOpportunity(opp, bbvamt.DES_User__c, 'Edit'));
      }
    }else if(mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)) != null) {//IF NOT CONTAINS ;
      system.debug('>>>>> mapAccOpp NOT CONTAINS ;');
      listOppShareInsert.add(handlerDesktopUtils.newManualSharingOpportunity(mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)), bbvamt.DES_User__c, 'Edit'));
    }

    return listOppShareInsert;
  }//FIN addToOppShareListOneClient


  private List<almd__Commercial_Alert__Share> addToAlertsShareListOneClient(List<almd__Commercial_Alert__Share> listCommercialAlerts, DES_BBVA_Management_team__c bbvamt, Map<Id, String> mapAccAlerts, Map<Id, String> mapGroupClients) {
    //List<OpportunityShare> listCommercialAlerts = listCommercialAlerts;

    if(mapAccAlerts.get(mapGroupClients.get(bbvamt.DES_Client__c)) != null
    && mapAccAlerts.get(mapGroupClients.get(bbvamt.DES_Client__c)).contains(';')) {
      system.debug('>>>>> mapAccAlerts CONTAINS ;');
      List<String> listOpps = mapAccAlerts.get(mapGroupClients.get(bbvamt.DES_Client__c)).split(';');
      for(String opp : listOpps) {
        //Creo el manual Sharing
        listCommercialAlerts.add(handlerDesktopUtils.newManualSharingCommercialAlert(opp, bbvamt.DES_User__c, 'Edit'));
      }
    }else if(mapAccAlerts.get(mapGroupClients.get(bbvamt.DES_Client__c)) != null) {//IF NOT CONTAINS ;
      system.debug('>>>>> mapAccAlerts NOT CONTAINS ;');
      listCommercialAlerts.add(handlerDesktopUtils.newManualSharingCommercialAlert(mapAccAlerts.get(mapGroupClients.get(bbvamt.DES_Client__c)), bbvamt.DES_User__c, 'Edit'));
    }

    return listCommercialAlerts;
  }//FIN addToOppShareListOneClient
  /*DESCOMENTAR ESTO AL SUBIR ALERTAS*/
  private List<dwp_kitv__Visit__Share> addToVisitShareListOneClient(List<dwp_kitv__Visit__Share> listVisitShareInsert, DES_BBVA_Management_team__c bbvamt, Map<Id, String> mapAccVisits, Map<Id, String> mapGroupClients) {
    //List<OpportunityShare> listVisitShareInsert = listVisitshareInsert;

    if(mapAccVisits.get(mapGroupClients.get(bbvamt.DES_Client__c)) != null
    && mapAccVisits.get(mapGroupClients.get(bbvamt.DES_Client__c)).contains(';')) {
      system.debug('>>>>> mapAccVisits CONTAINS ;');
      List<String> listVisits = mapAccVisits.get(mapGroupClients.get(bbvamt.DES_Client__c)).split(';');
      for(String visit : listVisits) {
        //Creo el manual Sharing
        listVisitShareInsert.add(handlerDesktopUtils.newManualSharingVisit(visit, bbvamt.DES_User__c, 'Edit'));
      }
    }else if(mapAccVisits.get(mapGroupClients.get(bbvamt.DES_Client__c)) != null) {//IF NOT CONTAINS ;
      system.debug('>>>>> mapAccVisits NOT CONTAINS ;');
      listVisitShareInsert.add(handlerDesktopUtils.newManualSharingVisit(mapAccVisits.get(mapGroupClients.get(bbvamt.DES_Client__c)), bbvamt.DES_User__c, 'Edit'));
    }

    return listVisitShareInsert;
  }//FIN addToOppShareListOneClient



}//FIN ApexSharing_Utils