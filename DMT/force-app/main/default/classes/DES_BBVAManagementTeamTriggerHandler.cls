/**
Name:            DES_BBVAManagementTeamTriggerHandler
  Description:     Handler Class to manage the trigger on object DES_BBVA_Management_team__c
  Test Class:
  Version        Date            Author            Summary of changes
  --------------------------------------------------------------------------------------------------------------
  0.1            01/04/2018      DSL          Creación de la clase
  0.2            29/05/2018      JSS          Añadido method "updateBankerAccount" para actualizar el campo Banker de la Account
  0.3            05/06/2018      JSS          Se comenta el method "updateBankerAccount" para actualizar el campo Banker de la Account
  (porque se hace al final en el Process Builder)
  0.5            05/06/2018      JSS          Añadida funcionalidad  Se comenta el method "updateBankerAccount" para actualizar el campo Banker
  de la Account (porque se hace al final en el Process Builder)
  0.6            13/07/2018      JSS          Update -> Creación method setCountry_GB_IH para actualizar el country a 'Global' cuando se trata
  de los 'Industry Head' y 'Global Banker'
  0.7            26/07/2018      JSS          Update -> se cambia la etiqueta "with sharing" por "without sharing" para solucionar el error que
  daba ya que los usuarios no tienen permisos de borrado en el objeto estandar AccountTeam
  Update -> En el borrado se hace la comprobación de no eliminar un BBVAMember en el objeto accountTeam
  estandar cuando en el objeto custom respectivo existe añadido varias veces el mismo miembro pero con diferentes roles
  0.8            18/10/2018      JSS          Update -> se cambia el method deleteAccountTeamMember para que no de error si se eliminan
  masivamente via Dataloader los miembros de accountteam
  0.9            08/01/2019      EQS          Update -> Añadimos ByPass para que el Admin pueda saltarse el trigger al hacer cargas de datos.
  0.91           28/05/2020      EQS          Update -> Añadimos filtro en getMapAccOpps y getMapAccVisits para evitar mapear opps de clientes Venezolanos.
   */
public without sharing class DES_BBVAManagementTeamTriggerHandler {

  /* method 0 */
  private static DES_BBVAManagementTeamTriggerHandler instance;
  //public static List<AccountTeamMember> listAccTeamMemberInsert = new List<AccountTeamMember>();
  //LOGIC
  /* method 1 */
  private static CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
  /* method 2 */
  final CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
  /* method 3 */
  final Desktop_Utils hndlrDeskUtils = Desktop_Utils.getInstance();

  /* Edit Var*/
  private final static String EDITVAR = 'Edit';

  /* Error añadir usuario inactivo*/
  private final static String ERRINACT = 'YOU CANNOT ADD AN INACTIVE USER OR BEC USERS';

  /* Usuario integracion*/
  private final static String DESKINTEG = 'Desktop Integration';

  /* Global banker */
  private final static String GBANKER = Label.DES_ROLE_GLOBAL_BANKER;

  /*string para guardar el perfil del current user*/
  final static String PROFILECURRENT = [SELECT Name FROM Profile WHERE Id = :userInfo.getProfileId() LIMIT 1].Name;

  //Constructor
  private DES_BBVAManagementTeamTriggerHandler() {

  }

  /* SINGLETON PATTERN */
  public static DES_BBVAManagementTeamTriggerHandler getInstance() { //NOSONAR
    if (instance == null) {
      instance = new DES_BBVAManagementTeamTriggerHandler();
    }
    return instance;
  }

  /////////////////////TEST "Upsert Global banker"//////////////////////////////

  /**
   * En la carga de BBVA_Management_team en las cuentas de grupos, es necesario eliminar los miembros con role Global
   * Banker o Industry Head cuyo usuario sea distinto para una misma cuenta, antes de insertar el nuevo registro
   * Sólo se ejecuta en integraciones
   *
   * @param triggerNew
   */
  public static void deleteTeamMembersBeforeInsert ( List<DES_BBVA_Management_team__c> triggerNew ) {

    // SOLO PARA INTEGRACIONES
    if ( byPass.CIB_DES_DataMigration__c ) {
      auxdeleteMemb(triggerNew);
    }
  }

  /**
   * Method auxiliar para el method deleteTeamMembersBeforeInsert
   *
   * @param triggerNew
   */
  private static void auxdeleteMemb (List<DES_BBVA_Management_team__c> triggerNew) {
    final List<DES_BBVA_Management_team__c> teamMembsToDelete = new List<DES_BBVA_Management_team__c>();
    // lista de ID_User indexados por concatenación Group Code||Team Role
    final Map<String, String> idUsrByGrpCAndRol = new Map<String, String>(); // ID_UserByGroupCodeAndRole

    // Solo los global banker e Industry Head pueden ser únicos
    final Set<String> uniqueMemberRoles = new Set<String>{ Label.DES_ROLE_GLOBAL_BANKER, Label.DES_ROLE_INDUSTRY_HEAD };
    // Almacena los codigos de grupo de los team members son aprovisionados
    final Set<String> groupCodes = new Set<String>(); //NOSONAR

    for ( DES_BBVA_Management_team__c triggerTM : triggerNew ) {

      if ( uniqueMemberRoles.contains( triggerTM.DES_Member_Role__c ) ) {

        //// DES_Clave_Externa : <GROUP_CODE>-<ID_USER>-<COUNTRY>-<TEAM_ROLE> ///////
        final List<String> externalKeyFields =
          triggerTM.DES_Clave_Externa__c == null ? null : triggerTM.DES_Clave_Externa__c.split( '-' );
        if (auxdelMembComplx2(externalKeyFields)) {
          idUsrByGrpCAndRol.put( externalKeyFields[0] + '||' + externalKeyFields[3], externalKeyFields[1] );
          groupCodes.add( externalKeyFields[0] );

        }

      }

    }

    // Get current Team Members to compare...
    if ( !idUsrByGrpCAndRol.isEmpty() ) {

      for ( DES_BBVA_Management_team__c currentTeamMember : [ SELECT DES_Client__r.DES_Group_Code__c, DES_User__r.ID_User__c, //NOSONAR
                                                                     DES_Member_Role__c, DES_Clave_Externa__c
                                                                FROM DES_BBVA_Management_team__c
                                                                WHERE DES_Member_Role__c IN :uniqueMemberRoles
                                                                AND DES_Clave_Externa__c <> null
                                                                AND DES_Client__r.DES_Group_Code__c IN :groupCodes ] ) {

        final String newTMIDUser = idUsrByGrpCAndRol.get( currentTeamMember.DES_Client__r.DES_Group_Code__c + '||' + currentTeamMember.DES_Member_Role__c );

        if (auxdelMembComplex(currentTeamMember, newTMIDUser)) {
          teamMembsToDelete.add( currentTeamMember );
        }

      }

      if ( !teamMembsToDelete.isEmpty() ) {
        delete teamMembsToDelete;
      }

    }
    system.debug('teamMembsToDelete ' + teamMembsToDelete);
  }

  /**
   * Method auxiliar para el method auxdeleteMemb
   *
   * @param triggerNew
   */
  private static boolean auxdelMembComplex(DES_BBVA_Management_team__c currentTeamMember, String newTMIDUser) {
    boolean result;
    result = false;
    if(newTMIDUser != null && newTMIDUser != currentTeamMember.DES_User__r.ID_User__c) {
      result = true;
    }
    return result;
  }

  /**
   * Method auxiliar para el method auxdeleteMemb
   *
   * @param triggerNew
   */
  private static boolean auxdelMembComplx2(List<String> externalKeyFields) {
    boolean result;
    result = false;
    if(externalKeyFields != null && externalKeyFields.size() > 3) {
      result = true;
    }
    return result;
  }


  //////////////////////////////////////////////////////////////////////////////


  /* method que actualiza el country a 'Global' cuando se trata de los 'Industry Head' y 'Global Banker' */
  public static void fillCountryGBIH(List<DES_BBVA_Management_team__c> triggerNew) {
    for(DES_BBVA_Management_team__c bbvaMT : triggerNew) {
      if (bbvaMT.DES_Member_Role__c == Label.DES_ROLE_GLOBAL_BANKER || bbvaMT.DES_Member_Role__c == Label.DES_ROLE_INDUSTRY_HEAD) {
        bbvaMT.DES_Local_Banker_Country__c = 'Global';
      }
    }
  }//FIN fillCountryGBIH

  /* method 3 */
  public static void checkInactiveUsers(List<DES_BBVA_Management_team__c> triggerNew) {
    final Set<Id> setIdsUsers = new Set<Id>();
    for(DES_BBVA_Management_team__c bbvaMT : triggerNew) {
      if(!setIdsUsers.contains(bbvaMT.DES_User__c)) {
        setIdsUsers.add(bbvaMT.DES_User__c);
      }
    }
    final Map<Id, User> mapInactiveUsers = new Map<Id, User>([
    SELECT 	Id,
        isActive,
        Profile.Name
    FROM User
    WHERE Id IN :setIdsUsers
    AND (isActive = false OR  Profile.Name = 'BBVA Desktop ARCE')
  ]);
    for(DES_BBVA_Management_team__c bbvaMT : triggerNew) {
      if(mapInactiveUsers.keySet().contains(bbvaMT.DES_User__c)) {
        bbvaMT.addError(ERRINACT);
      }
    }
  }//FIN checkInactiveUsers

  /* method 4 */
  public void createManualSharing(List<DES_BBVA_Management_team__c> triggerNew, Boolean execute) {
    if((PROFILECURRENT != Label.DES_ADMIN_PROFILE && PROFILECURRENT != Label.DES_INTEGRATION_PROFILE) || execute || Test.isRunningTest()) { //NOSONAR
      Set<Id> setUsersId;
      setUsersId = new Set<Id>();
      Set<Id> setAccountsIds;
      setAccountsIds = new Set<Id>();
      Map<Id, Id> mapIdMemberIdAcc;
      mapIdMemberIdAcc = new Map<Id, Id>();
      for(DES_BBVA_Management_Team__c bbvaMT : triggerNew) {

        mapIdMemberIdAcc.put(bbvaMT.Id, bbvamt.DES_Client__c);

        if(!setUsersId.contains(bbvaMT.DES_User__c)) {
          setUsersId.add(bbvaMT.DES_User__c);
        }
        if(!setAccountsIds.contains(bbvaMT.DES_Client__c)) {
          setAccountsIds.add(bbvaMT.DES_Client__c);
        }
      }

      system.debug('setAccountsIds : ' + setAccountsIds);
      if(!setAccountsIds.isEmpty()) {
        manualSharing(triggerNew, setAccountsIds, mapIdMemberIdAcc);
        // manualSharingCommAlerts(triggerNew, setAccountsIds/*, setUsersId*/); /*Descomentar en subida de alertas*/
        //manualSharingVisits(triggerNew, setAccountsIds, setUsersId);
      }
    }
  }//FIN CreateManualSharing

  private void manualSharing(List<DES_BBVA_Management_team__c> triggerNew, Set<Id> setAccountsIds, Map<Id, Id> mapIdMemberIdAcc) {
    system.debug('mapIdMemberIdAcc : ' + mapIdMemberIdAcc);
    /*Busco all los id's de cuentas que tienen como padre alguno de los id's que están en el set */
    Set<Id> setAllAccIds;
    setAllAccIds = new Set<Id>();
    setAllAccIds.addAll(mapIdMemberIdAcc.values());
    setAllAccIds.addAll(setAccountsIds);
    Map<Id, String> mapGroupClients;
    mapGroupClients = new Map<Id, String>();//Mapa que tiene el Id del grupo como key y concatenados los id's de los clientes que están por debajo de la jerarquía
    for(Id idAcc : setAccountsIds) {
      if(mapGroupClients.get(idAcc) == null) {
        mapGroupClients.put(idAcc, idAcc);
      }
    }
    //Busco los id's de todas las filiales y las agrego al set de todas las accounts
    fillGroupClient(setAccountsIds, setAllAccIds, mapGroupClients);

    //Busco todas las oportunidades vinculadas a estas cuentas
    Map<Id, String> mapAccOpp = getMapAccOpps(setAllAccIds);

    Map<Id, String> mapAccVisits = getMapAccVisits(setAllAccIds);

    List<OpportunityShare> listOppShIns = fillListOppShare(triggerNew, mapGroupClients, mapAccOpp);
    List<Database.SaveResult> listSROpps = new List<Database.SaveResult>();
    System.debug(listOppShIns);
    if(!listOppShIns.isEmpty()) {
      System.debug('size:'+listOppShIns.size());
      if(listOppShIns.size()<=10000) {//ajuste temporal para corregir un error
        listSROpps = Database.insert(listOppShIns, false);
      } else {
        //insertShareOpp(listOppShIns);
        ID jobID = System.enqueueJob(new insertShareOpportunity(listOppShIns));

      }

      //liberamos memoria
      listOppShIns = new List<OpportunityShare>();
      listSROpps   = new List<Database.SaveResult>();
      mapAccOpp    = new Map<Id, String>();
    }

    List<dwp_kitv__Visit__Share> listvisitSharing = fillListVisShare(triggerNew, mapGroupClients, mapAccVisits);

    List<Database.SaveResult> listSRVisits = new List<Database.SaveResult>();

    if(!listvisitSharing.isEmpty()) {

      if(listvisitSharing.size()<=10000) {//ajuste temporal para corregir un error
        listSRVisits = Database.insert(listvisitSharing, false);
        system.debug('listSRVisits ' + listSRVisits);
      } else {
        //insertShVisit(listvisitSharing);
        ID jobID = System.enqueueJob(new insertShareVisit(listvisitSharing));
      }
      //liberamos memoria
      listvisitSharing = new List<dwp_kitv__Visit__Share>();
      listSRVisits   = new List<Database.SaveResult>();
      mapAccVisits    = new Map<Id, String>();
    }
  }

  /*  public void insertShareOpp(List<OpportunityShare> listOppShIns) {
    Integer limitDML=9999;
    List<OpportunityShare> listOppShInsInsert=new List<OpportunityShare>();
    List<OpportunityShare> listOppShInsRes=new List<OpportunityShare>();
    for (Integer i=0;i< listOppShIns.size();i++) {
      if(i<limitDML) {
        listOppShInsInsert.add(listOppShIns[i]);
      } else {
        listOppShInsRes.add(listOppShIns[i]);
      }
    }
    List<Database.SaveResult> listSR = Database.insert(listOppShInsInsert, false);
    if(listOppShInsRes.size()>0) {
      ID jobID = System.enqueueJob(new insertShareOpportunity(listOppShInsRes));
    }
  }

  public void insertShVisit(List<dwp_kitv__Visit__Share> listvisitSharing) {
    Integer limitDML=9999;
    List<dwp_kitv__Visit__Share> listvisitSharingInsert=new List<dwp_kitv__Visit__Share>();
    List<dwp_kitv__Visit__Share> listvisitSharingRes=new List<dwp_kitv__Visit__Share>();
    for (Integer i=0;i< listvisitSharing.size();i++) {
      if(i<limitDML) {
        listvisitSharingInsert.add(listvisitSharing[i]);
      } else {
        listvisitSharingRes.add(listvisitSharing[i]);
      }
    }
    List<Database.SaveResult> listSR = Database.insert(listvisitSharingInsert, false);
    if(listvisitSharingRes.size()>0) {
      ID jobID = System.enqueueJob(new insertShareVisit(listvisitSharingRes));
    }
  } */
  private static void fillGroupClient(Set<Id> setAccountsIds, Set<Id> setAllAccIds, Map<Id, String> mapGroupClients) {
    for(DES_Subsidiary_Group_Relation__c matrix : [
      SELECT Id, participant_child_id__c, participant_parent_id__c
      FROM DES_Subsidiary_Group_Relation__c
      WHERE participant_parent_id__c IN :setAccountsIds AND main_subsidiary_ind_type__c = true
  ]) {
      if(!setAllAccIds.contains(matrix.participant_child_id__c)) {
        setAllAccIds.add(matrix.participant_child_id__c);
      }
      if(!setAllAccIds.contains(matrix.participant_parent_id__c)) {
        setAllAccIds.add(matrix.participant_parent_id__c);
      }
      if(mapGroupClients.get(matrix.participant_parent_id__c) == null) {
        mapGroupClients.put(matrix.participant_parent_id__c, matrix.participant_parent_id__c + ';' + matrix.participant_child_id__c);
      } else {
        mapGroupClients.put(matrix.participant_parent_id__c, mapGroupClients.get(matrix.participant_parent_id__c) + ';' + matrix.participant_parent_id__c + ';' +
          matrix.participant_child_id__c);
      }
    }
  }

  private List<OpportunityShare> fillListOppShare(List<DES_BBVA_Management_team__c> triggerNew, Map<Id, String> mapGroupClients, Map<Id, String> mapAccOpp) {
    List<OpportunityShare> listOppShIns = new List<OpportunityShare>();
    for(DES_BBVA_Management_team__c bbvamt : triggerNew) {
      if(!bbvamt.copy_record_approval_type__c) {
        if(mapGroupClients.get(bbvamt.DES_Client__c) != null
        && mapGroupClients.get(bbvamt.DES_Client__c).contains(';')) {
          final List<String> listClients = mapGroupClients.get(bbvamt.DES_Client__c).split(';');
          for(String accId : listClients) {
            listOppShIns = addToOppShareListMultiClients(listOppShIns, bbvamt, mapAccOpp, accId);
          }
        } else if(mapGroupClients.get(bbvamt.DES_Client__c) != null) { //IF NOT CONTAINS ;
          listOppShIns = addToOppShareListOneClient(listOppShIns, bbvamt, mapAccOpp, mapGroupClients);
        }
      }
    }
    return listOppShIns;
  }

  private List<dwp_kitv__Visit__Share> fillListVisShare(List<DES_BBVA_Management_team__c> triggerNew, Map<Id, String> mapGroupClients, Map<Id, String> mapAccVisits) {
    List<dwp_kitv__Visit__Share> listvisitSharing = new List<dwp_kitv__Visit__Share>();
    for(DES_BBVA_Management_team__c bbvamt : triggerNew) {
      if(!bbvamt.copy_record_approval_type__c) {
        if(mapGroupClients.get(bbvamt.DES_Client__c) != null
        && mapGroupClients.get(bbvamt.DES_Client__c).contains(';')) {
          final List<String> listClients = mapGroupClients.get(bbvamt.DES_Client__c).split(';');
          for(String accId : listClients) {
            listvisitSharing = addToVisitShareListMultiClients(listvisitSharing, bbvamt, mapAccVisits, accId);
          }
        } else if(mapGroupClients.get(bbvamt.DES_Client__c) != null) { //IF NOT CONTAINS ;
          listvisitSharing = addToVisitShareListOneClient(listvisitSharing, bbvamt, mapAccVisits, mapGroupClients);
        }
      }
    }
    return listvisitSharing;
  }

  private List<OpportunityShare> addToOppShareListMultiClients(List<OpportunityShare> listOppShIns, DES_BBVA_Management_team__c bbvamt,
  Map<Id, String> mapAccOpp, String accId) {
    if(mapAccOpp.get(accId) != null
    && mapAccOpp.get(accId).contains(';')) {
      system.debug('>>>>> mapAccOpp CONTAINS ;');
      final List<String> listOpps = mapAccOpp.get(accId).split(';');
      for(String opp : listOpps) {
        //Creo el manual Sharing
        listOppShIns.add(hndlrDeskUtils.newManualSharingOpportunity(opp, bbvamt.DES_User__c, EDITVAR));
      }
    } else if(mapAccOpp.get(accId) != null) {//IF NOT CONTAINS ;
      system.debug('>>>>> mapAccOpp NOT CONTAINS ;');
      listOppShIns.add(hndlrDeskUtils.newManualSharingOpportunity(mapAccOpp.get(accId), bbvamt.DES_User__c, EDITVAR));
    }

    return listOppShIns;
  }//FIN addToOppShareListMultiClients

  private List<dwp_kitv__Visit__Share> addToVisitShareListMultiClients(List<dwp_kitv__Visit__Share> listvisitSharing, DES_BBVA_Management_team__c bbvamt, Map<Id, String> mapAccVisits, String accId) {
    //List<dwp_kitv__Visit__Share> listvisitSharing = new List<dwp_kitv__Visit__Share>();
    system.debug('>>>>> accId : ' + accId);
    if(mapAccVisits.get(accId) != null
    && mapAccVisits.get(accId).contains(';')) {
      system.debug('>>>>> mapAccVisits CONTAINS ;');
      system.debug('>>>>> mapAccVisits.get(accId) : ' + mapAccVisits.get(accId));
      for(String alertId : mapAccVisits.get(accId).split(';')) {
        listvisitSharing.add(hndlrDeskUtils.newManualSharingVisit(alertId, bbvaMT.DES_User__c, EDITVAR));
      }
    } else if(mapAccVisits.get(accId) != null) {//IF NOT CONTAINS ;
      system.debug('>>>>> mapAccVisits NOT CONTAINS ;');
      system.debug('>>>>> mapAccVisits.get(accId) : ' + mapAccVisits.get(accId));
      listvisitSharing.add(hndlrDeskUtils.newManualSharingVisit(mapAccVisits.get(accId), bbvaMT.DES_User__c, EDITVAR));
    }
    system.debug('>>>>> listvisitSharing : ' + listvisitSharing);
    return listvisitSharing;
    //List<Database.SaveResult> listSR = Database.insert(listvisitSharing, false);
  }//FIN addToOppShareListMultiClients



  private List<OpportunityShare> addToOppShareListOneClient(List<OpportunityShare> listOppShare, DES_BBVA_Management_team__c bbvamt, Map<Id, String> mapAccOpp, Map<Id, String> mapGroupClients) {
    //List<OpportunityShare> listOppShare = listOppShare;

    if(mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)) != null
    && mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)).contains(';')) {
      system.debug('>>>>> mapAccOpp CONTAINS ;');
      final List<String> listOpps = mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)).split(';');
      for(String opp : listOpps) {
        //Creo el manual Sharing
        listOppShare.add(hndlrDeskUtils.newManualSharingOpportunity(opp, bbvamt.DES_User__c, EDITVAR));
      }
    } else if(mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)) != null) {//IF NOT CONTAINS ;
      system.debug('>>>>> mapAccOpp NOT CONTAINS ;');
      listOppShare.add(hndlrDeskUtils.newManualSharingOpportunity(mapAccOpp.get(mapGroupClients.get(bbvamt.DES_Client__c)), bbvamt.DES_User__c, EDITVAR));
    }

    return listOppShare;
  }//FIN addToOppShareListOneClient


  private List<dwp_kitv__Visit__Share> addToVisitShareListOneClient(List<dwp_kitv__Visit__Share> listVisitShare, DES_BBVA_Management_team__c bbvamt, Map<Id, String> mapAccVisits, Map<Id, String> mapGroupClients) {
    //List<OpportunityShare> listVisitShare = listVisitShare;

    if(mapAccVisits.get(mapGroupClients.get(bbvamt.DES_Client__c)) != null
    && mapAccVisits.get(mapGroupClients.get(bbvamt.DES_Client__c)).contains(';')) {
      system.debug('>>>>> mapAccVisits CONTAINS ;');
      final List<String> listVisits = mapAccVisits.get(mapGroupClients.get(bbvamt.DES_Client__c)).split(';');
      for(String visit : listVisits) {
        //Creo el manual Sharing
        listVisitShare.add(hndlrDeskUtils.newManualSharingVisit(visit, bbvamt.DES_User__c, EDITVAR));
      }
    } else if(mapAccVisits.get(mapGroupClients.get(bbvamt.DES_Client__c)) != null) {//IF NOT CONTAINS ;
      system.debug('>>>>> mapAccVisits NOT CONTAINS ;');
      listVisitShare.add(hndlrDeskUtils.newManualSharingVisit(mapAccVisits.get(mapGroupClients.get(bbvamt.DES_Client__c)), bbvamt.DES_User__c, EDITVAR));
    }

    return listVisitShare;
  }//FIN addToOppShareListOneClient

  private static Map<Id, String> getMapAccOpps(Set<Id> setAllAccIds) {
    Map<Id, String> mapAccOpp;
    mapAccOpp = new Map<Id, String>();
    final String ven = 'VE'; //NOSONAR
    system.debug('>>>>> setAllAccIds : ' + setAllAccIds);
    //Concateno las cuentas y las oportunidades vinculadas a cada cuenta que no sea Venezolana.
    for(Opportunity opp : [SELECT Id, Name, AccountId,Account.DES_Country_Client__c FROM Opportunity WHERE AccountId IN :setAllAccIds AND StageName != :Label.DES_Draft AND disclosure_info_type__c != :Label.DES_OP_Inside]) { //NOSONAR
      if(mapAccOpp.get(opp.AccountId) == null && opp.Account.DES_Country_Client__c != ven) {
        mapAccOpp.put(opp.AccountId, opp.Id);
      } else if(opp.Account.DES_Country_Client__c != ven) {
        mapAccOpp.put(opp.AccountId, mapAccOpp.get(opp.AccountId) + ';' + opp.Id);
      }
    }
    return mapAccOpp;
  }

  private static Map<Id, String> getMapAccVisits(Set<Id> setAccountsIds) {
    //Map con el Id de la cuenta como Key y un string que concatena los id's de las commercial alerts
    Map<Id, String> mapAccVisits;
    mapAccVisits = new Map<Id, String>();
    final String ven = 'VE'; //NOSONAR
    system.debug('>>>>> mapAccVisits : ' + mapAccVisits);
    for(dwp_kitv__Visit__c visit : [SELECT 	Id, Name, dwp_kitv__account_id__c,dwp_kitv__account_id__r.DES_Country_Client__c FROM dwp_kitv__Visit__c WHERE RecordTypeId = :Desktop_Utils.RTVISITCONF AND dwp_kitv__account_id__c IN :setAccountsIds]) {
      //system.debug('>>>>> visit : ' + visit);
      //system.debug('>>>>> mapAccVisits.get(visit.dwp_kitv__account_id__c) : ' + mapAccVisits.get(visit.dwp_kitv__account_id__c));
      //SI NO CONTIENE EL REGISTRO DE LA CUENTA
      if(mapAccVisits.get(visit.dwp_kitv__account_id__c) == null && visit.dwp_kitv__account_id__r.DES_Country_Client__c != ven) {
        mapAccVisits.put(visit.dwp_kitv__account_id__c, visit.Id);
      } else if(visit.dwp_kitv__account_id__r.DES_Country_Client__c != ven) {
        String visits = mapAccVisits.get(visit.dwp_kitv__account_id__c);
        visits += ';' + visit.Id;
        mapAccVisits.put(visit.dwp_kitv__account_id__c, visits);
      }
    }
    return mapAccVisits;
  }

  /* Descomentar en la subida de Alertas*/
  /*
  private void manualSharingCommAlerts(List<DES_BBVA_Management_team__c> triggerNew, Set<Id> setAccountsIds, Set<Id> setUsersId) {
    Map<Id, String> mapAccAlerts = new Map<Id, String>();
    mapAccAlerts = getMapAccAlerts(setAccountsIds);
    system.debug('>>>>> mapAccAlerts : ' + mapAccAlerts);


    if(!mapAccAlerts.isEmpty()) {
      List<almd__Commercial_Alert__Share> listComAlrt;
      listComAlrt = new List<almd__Commercial_Alert__Share>();
      for(DES_BBVA_Management_team__c bbvaMT : triggerNew) {
        if(mapAccAlerts.get(bbvaMT.DES_Client__c).contains(';')) {
          for(String alertId : mapAccAlerts.get(bbvaMT.DES_Client__c).split(';')) {
            listComAlrt.add(hndlrDeskUtils.newManualSharingCommercialAlert(alertId, bbvaMT.DES_User__c, EDITVAR));
          }
        } else {
          listComAlrt.add(hndlrDeskUtils.newManualSharingCommercialAlert(mapAccAlerts.get(bbvaMT.DES_Client__c), bbvaMT.DES_User__c, EDITVAR));
        }

      }

      system.debug('>>>>> listComAlrt : ' + listComAlrt);
      List<Database.SaveResult> listSR = Database.insert(listComAlrt, false); //NOSONAR
      system.debug(listSR);
    }
  } */ //FIN manualSharingCommAlerts

  /*
  private void manualSharingVisits(List<DES_BBVA_Management_team__c> triggerNew, Set<Id> setAccountsIds, Set<Id> setUsersId) {
    //Map con el Id de la cuenta como Key y un string que concatena los id's de las commercial alerts
    Map<Id, String> mapAccVisits = new Map<Id, String>();
    system.debug('>>>>> mapAccVisits : ' + mapAccVisits);
    for(dwp_kitv__Visit__c visit : [SELECT 	Id, Name, dwp_kitv__account_id__c FROM dwp_kitv__Visit__c
                                WHERE RecordTypeId = :Desktop_Utils.rtVisitConfidential
                                AND dwp_kitv__account_id__c IN :setAccountsIds]) {
      //system.debug('>>>>> visit : ' + visit);
      //system.debug('>>>>> mapAccVisits.get(visit.dwp_kitv__account_id__c) : ' + mapAccVisits.get(visit.dwp_kitv__account_id__c));
      //SI NO CONTIENE EL REGISTRO DE LA CUENTA
      if(mapAccVisits.get(visit.dwp_kitv__account_id__c) == null) {
        mapAccVisits.put(visit.dwp_kitv__account_id__c, visit.Id);
      } else {
        String visits = mapAccVisits.get(visit.dwp_kitv__account_id__c);
        visits += ';' + visit.Id;
        mapAccVisits.put(visit.dwp_kitv__account_id__c, visits);
      }
    }

    if(!mapAccVisits.isEmpty()) {
      List<dwp_kitv__Visit__Share> listvisitSharing = new List<dwp_kitv__Visit__Share>();
      for(DES_BBVA_Management_team__c bbvaMT : triggerNew) {
        if(mapAccVisits.get(bbvaMT.DES_Client__c) != null
        && mapAccVisits.get(bbvaMT.DES_Client__c).contains(';')) {
          for(String alertId : mapAccVisits.get(bbvaMT.DES_Client__c).split(';')) {
            listvisitSharing.add(handlerDesktopUtils.newManualSharingVisit(alertId, bbvaMT.DES_User__c, EDITVAR));
          }
        } else if(mapAccVisits.get(bbvaMT.DES_Client__c) != null) {
          listvisitSharing.add(handlerDesktopUtils.newManualSharingVisit(mapAccVisits.get(bbvaMT.DES_Client__c), bbvaMT.DES_User__c, EDITVAR));
        }

      }

      system.debug('>>>>> listvisitSharing : ' + listvisitSharing);
      List<Database.SaveResult> listSR = Database.insert(listvisitSharing, false);
    }

  }//FIN manualSharingvisits
   */
  public static List <DES_BBVA_Management_team__c> checkDuplicates(List<DES_BBVA_Management_team__c> triggerNew) {
    // meto en una lista las cuentas de los BBVA management team que lanzan el trigger
    Set<Id> listaCuentas;
    listaCuentas = new Set<Id>();
    List <DES_BBVA_Management_team__c> listaDeDuplicados;
    listaDeDuplicados = new List <DES_BBVA_Management_team__c>();
    List<String> duplicadosList;
    duplicadosList = new List<String>();
    //if (userSettings.CIB_Is_Desktop__c) {

      //List<Account> listaCuentas = new List<Account>();
      for(DES_BBVA_Management_team__c aux : triggerNew) {
        listaCuentas.add(aux.DES_Client__c);
      }
      // recojo tdos los BBVA management team cuya cuenta esté en el set inicial
      final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>([
                      SELECT  Id, DES_User__c, DES_Client__c, DES_Member_Role__c, DES_Local_Banker_Country__c, DES_PS_Product__c
                      FROM DES_BBVA_Management_team__c
                      WHERE DES_Client__c IN :listaCuentas
          ]);

      // recorro la lista incial (triggerNew) y la comparo con la lista recogida (listaBBVAMT). Si hay alguna pareja repetida se muestra mensaje de error
      //Set<Id> setCuentasError = new Set<Id>(); Quitado porq no se usa segun sonar
      Boolean hayDuplicado = false;

      Map<String, DES_BBVA_Management_team__c> mapStrBBVAMT;
      mapStrBBVAMT = new Map<String, DES_BBVA_Management_team__c>();
      for(DES_BBVA_Management_team__c bbvaMT : listaBBVAMT) {
        String key = '';
        if(bbvaMT.DES_Member_Role__c == Label.DES_ROLE_GLOBAL_BANKER || bbvaMT.DES_Member_Role__c == Label.DES_ROLE_SECONDARY_GB || bbvaMT.DES_Member_Role__c == Label.DES_ROLE_INDUSTRY_HEAD) {
          key = bbvaMT.DES_Client__c + '_' + bbvaMT.DES_Member_Role__c;
        } else {
          key = bbvaMT.DES_Client__c + '_' + bbvaMT.DES_User__c + '_' + bbvaMT.DES_Member_Role__c + '_';
        }

        //Si es Product Specialist, local banker o transactional banker
        if(bbvaMT.DES_Member_Role__c == Label.DES_ROLE_LOCAL_BANKER || bbvaMT.DES_Member_Role__c == Label.DES_Role_Transactional_Banker
        || bbvaMT.DES_Member_Role__c == Label.DES_Role_Regional_Banker || bbvaMT.DES_Member_Role__c == Label.DES_Role_Product_Specialist) {
          key += bbvaMT.DES_Local_Banker_Country__c;//Concateno tambien el país en el control de duplicados
          if(bbvaMT.DES_Member_Role__c == Label.DES_Role_Product_Specialist) {//Si es product Specialist
            //Concateno tambien el producto
            key += bbvaMT.DES_PS_Product__c;
          }
        }

        mapStrBBVAMT.put(key, bbvaMT);
      }
      system.debug('>>>>> mapStrBBVAMT : ' + mapStrBBVAMT);

      for(DES_BBVA_Management_team__c i : triggerNew) {
        String keyDup;
        if(i.DES_Member_Role__c == Label.DES_ROLE_GLOBAL_BANKER || i.DES_Member_Role__c == Label.DES_ROLE_SECONDARY_GB || i.DES_Member_Role__c == Label.DES_ROLE_INDUSTRY_HEAD) {
          keyDup = i.DES_Client__c + '_' + i.DES_Member_Role__c;
        } else {
          keyDup = i.DES_Client__c + '_' + i.DES_User__c + '_' + i.DES_Member_Role__c + '_';
        }

        if(i.DES_Member_Role__c == Label.DES_ROLE_LOCAL_BANKER || i.DES_Member_Role__c == Label.DES_Role_Transactional_Banker
        || i.DES_Member_Role__c == Label.DES_Role_Regional_Banker || i.DES_Member_Role__c == Label.DES_Role_Product_Specialist) {
          keyDup += i.DES_Local_Banker_Country__c;
          if(i.DES_Member_Role__c == Label.DES_Role_Product_Specialist) {//Si es product Specialist
            //Concateno tambien el producto
            keyDup += i.DES_PS_Product__c;
          }
        }
        if(mapStrBBVAMT.get(keyDup) != null) {
          hayDuplicado = true;
          i.DES_Clave_Externa__c = String.valueOf(Integer.valueof(Math.random() * 100000));
          listaDeDuplicados.add(i);
          duplicadosList.add(i.DES_Clave_Externa__c);
        }
        /*if(i.DES_Client__c == j.DES_Client__c && i.DES_User__c == j.DES_User__c && i.DES_Member_Role__c == j.DES_Member_Role__c) {

          // Global Banker, Industry Head y Risk Analyst
          if (i.DES_Member_Role__c=='Global Banker' || i.DES_Member_Role__c=='Industry Head' || i.DES_Member_Role__c=='Risk Analyst') {
            //  i.addError(label.DES_Duplicate_BBVA_Team_Member);
            hayDuplicado = true;
            listaDeDuplicados.add(i);

            // Local Banker y Transactional Banker
          } else if (i.DES_Local_Banker_Country__c == j.DES_Local_Banker_Country__c
          && (i.DES_Member_Role__c==Label.DES_ROLE_LOCAL_BANKER || i.DES_Member_Role__c==Label.DES_Role_Transactional_Banker)) {
            hayDuplicado = true;
            listaDeDuplicados.add(i);
          }
          // Product Specialist
          else if ( />*i.DES_PS_Product__c == j.DES_PS_Product__c
          &&*>/  i.DES_Member_Role__c=='Product Specialist') {
            hayDuplicado = true;
            listaDeDuplicados.add(i);
          }
        }*/
      }
      // Si la inserción es manual salta el mensaje. Si la inserción es masiva sólo salta si se inserta 1 registro
      system.debug('>>>>> hayDuplicado: ' + hayDuplicado);
      system.debug('>>>>> triggerNewSize: ' + triggerNew.size());
      if(triggerNew.size() == 1 && hayDuplicado == true && Userinfo.getName() != 'User Integrator') {
        triggerNew.get(0).addError(label.DES_Duplicate_BBVA_Team_Member);
      }
    //} FIN SI ES USUARIO DESKTOP
    Desktop_Utils.listaDeDuplicadosBorrados = duplicadosList;
    return listaDeDuplicados;
  } // FIN checkDuplicates()

  /* Method 6 */
  public static void deleteAccountTeamMember(List<DES_BBVA_Management_team__c > listTriggerOld) {
    //system.debug('>>>>> Entrando a method deleteAccountTeamMember. Lista listTriggerOld: ' + listTriggerOld);
    // Sólo si el usuario es de Desktop CIB
    //if (userSettings.CIB_Is_Desktop__c) {

      set<id> accountIds;
      accountIds = new set<id>();
      set<id> userIds;
      userIds = new set<id>();
      for(DES_BBVA_Management_team__c i : listTriggerOld) {
        if(!accountIds.contains(i.DES_Client__c)) {
          accountIds.add(i.DES_Client__c);
        }
        if(!userIds.contains(i.DES_User__c)) {
          userIds.add(i.DES_User__c);
        }
      }

      // recuperamos el numero de veces que aparece un usuario como miembro en cada cliente, y lo metemos en un mapa
      final AggregateResult[] grpMemOld = [SELECT DES_Client__c,DES_User__c, Count(Id)Member_count FROM DES_BBVA_Management_team__c Where DES_Client__c in :accountIds Group by DES_Client__c,DES_User__c];
      map<String,Integer> mapCountMC;
      mapCountMC = new map<String,Integer>();
      for (AggregateResult memberCount : grpMemOld) {
        mapCountMC.put((String) memberCount.get('DES_Client__c') + '_' + memberCount.get('DES_User__c'),(Integer) memberCount.get('Member_count'));
      }

      //recuperamos los usuarios que están como miembros del objeto estandar AccountTeamMember
      //(si no habido error deberían ser los mismos que los del objeto custom), y lo metemos en un mapa
      final list<AccountTeamMember> accTeamMemberList = [SELECT id, AccountId, UserId FROM AccountTeamMember WHERE AccountId IN:accountIds AND UserId IN:userIds];
      system.debug('Valor de accTeamMemberList: ' +accTeamMemberList);
      Map<String,AccountTeamMember> atmMap;
      atmMap = new Map<String, AccountTeamMember>();
      for (AccountTeamMember atm : accTeamMemberList) {
        atmMap.put(atm.AccountId + '_' + atm.UserId, atm);
      }
      //system.debug('>>>>>>>>>>>> Valor de mapCountMC: ' + mapCountMC);
      //system.debug('>>>>>>>>>>>> Valor de atmMap: ' + atmMap);

      // creacion de la lista con los id's de los miembros del objeto estandar que habrá que eliminar a posteriori
      set<AccountTeamMember> membersToDelete;
      membersToDelete = new set<AccountTeamMember>();
      //Recorremos la lista que viene del trigger de miembros del objeto custom, y se rellena la lista de id's membersToDelete del objeto estandar
      for(DES_BBVA_Management_team__c bbvaMember : listTriggerOld) {
        // si un usuario NO sigue apareciendo en el mapa (si sigue apareciendo es que estaba  más de 1 vez como miembro de un Cliente)
        //y si ese miembro está tambien en el objeto estandar, se añade en la lista para eliminar en el objeto estandar
        if (!mapCountMC.containsKey(bbvaMember.DES_Client__c + '_' + bbvaMember.DES_User__c) && atmMap.containsKey(bbvaMember.DES_Client__c + '_' + bbvaMember.DES_User__c) ) {
          membersToDelete.add(atmMap.get(bbvaMember.DES_Client__c + '_' + bbvaMember.DES_User__c));
        }
      }

      if (!membersToDelete.isEmpty()) {
        //system.debug('>>>>>>>>> Valor de membersToDelete: ' + membersTodelete);
        delete new List<AccountTeamMember>(membersToDelete);
      }
    // }//FIN SI ES USUARIO DESKTOP
  }//FIN deleteAccountTeamMember

  /*method 7 */
  public void setUserFields(List<DES_BBVA_Management_team__c> triggerNew, Map<Id, DES_BBVA_Management_team__c> triggerOldMap) {//NOSONAR
    Set<Id> setUserIds;
    setUserIds = new Set<Id>();
    for(DES_BBVA_Management_team__c bbvaMT : triggerNew) {
      if (bbvaMT.DES_Local_Banker_Country__c == 'GL') {
        bbvaMT.DES_Local_Banker_Country__c = 'Global';
      }
      if(!setUserIds.contains(bbvaMT.DES_User__c)) {
        setUserIds.add(bbvaMT.DES_User__c);
      }
    }
    /*  CAMPOS A RELLENAR:
     *  DES_User_email_text__c
     *  DES_phone__c
     *  Name
     *
     **/
    system.debug('>>>>> setUserIds : ' + setUserIds);
    final Map<Id, User> mapUsers = new Map<Id, User>([
              SELECT  Id,
                      Email,
                      Phone,
                      FirstName,
                      LastName,
                      Name
              FROM User
              WHERE Id IN :setUserIds
      ]);

    system.debug('>>>>> mapUsers : ' + mapUsers);
    for(DES_BBVA_Management_team__c bbvaMT : triggerNew) {
      bbvaMT.Name = mapUsers.get(bbvaMT.DES_User__c).Name;
      bbvaMT.DES_phone__c = mapUsers.get(bbvaMT.DES_User__c).Phone;
      bbvaMT.DES_User_email_text__c = mapUsers.get(bbvaMT.DES_User__c).Email;
      system.debug('>>>>>  Trigger.isUpdate : ' + Trigger.isUpdate);
      system.debug('>>>>>  triggerOldMap : ' + triggerOldMap);
      system.debug('>>>>>  bbvaMT.copy_record_approval_type__c : ' + bbvaMT.copy_record_approval_type__c);
      //system.debug('>>>>>  triggerOldMap.get(bbvaMT.Id).copy_record_approval_type__c : ' + triggerOldMap.get(bbvaMT.Id).copy_record_approval_type__c);
      system.debug('>>>>>  userSettings.CIB_Is_Admin__c : ' +userSettings.CIB_Is_Admin__c);
      //system.debug('>>>>>  byPass.CIB_skip_trigger__c : ' +byPass.CIB_skip_trigger__c);


      if(Trigger.isUpdate &&
        triggerOldMap != null
        && bbvaMT.copy_record_approval_type__c == triggerOldMap.get(bbvaMT.Id).copy_record_approval_type__c
      && !(userSettings.CIB_Is_Admin__c && byPass.CIB_skip_trigger__c) && Userinfo.getName() != 'User Integrator') {
        bbvaMT.addError(Label.DES_ERROR_EDIT_BBVA_TEAM_MEMBERS);
      }
    }

  }

  /*method 8 */
  public static void fillAccountField(Map<Id, DES_BBVA_Management_team__c> triggerNewMap) {
    final Id profileId = userInfo.getProfileId();
    final String profileName = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1].Name;
    system.debug('>>>>> profileName : ' + profileName);
    system.debug('>>>>> profileId : ' + profileId);
    if(profileName == DESKINTEG) {
      Set<Id> setAccountsIds;
      setAccountsIds = new Set<Id>();
      for(DES_BBVA_Management_Team__c bbvaMT : triggerNewMap.values()) {
        if(bbvaMT.DES_Member_Role__c == GBANKER && !setAccountsIds.contains(bbvaMT.DES_Client__c)) {
          setAccountsIds.add(bbvaMT.DES_Client__c);
        }
      }
      if(!setAccountsIds.isEmpty()) {
        final Map<Id, Account> mapAccounts = new Map<Id, Account>([
          SELECT 	Id,
              Name,
              DES_Global_Banker_Ref__c,
              DES_Global_banker__c
          FROM Account
          WHERE Id IN :setAccountsIds
        ]);

        for(DES_BBVA_Management_Team__c bbvaMT : triggerNewMap.values()) {
          if(bbvaMT.DES_Member_Role__c == GBANKER && !Desktop_Utils.listaDeDuplicadosBorrados.contains(bbvaMT.DES_Clave_Externa__c)) {
            mapAccounts.get(bbvaMT.DES_Client__c).DES_Global_Banker_Ref__c = bbvaMT.Id;
            mapAccounts.get(bbvaMT.DES_Client__c).DES_Global_banker__c = bbvaMT.DES_User__c;
          }
        }

        system.debug('>mapAccounts.values() : ' + mapAccounts.values());
        update mapAccounts.values();
      }

    }//FIN SI ES USUARIO DE INTEGRACION
  }

  /*method 9 */
  public static void insertAccountTeam(List<DES_BBVA_Management_team__c> triggerNew, Map<Id, DES_BBVA_Management_team__c> triggerOldMap) {
    List<AccountTeamMember> listAccTM;
    listAccTM = new List<AccountTeamMember>();
    for(DES_BBVA_Management_team__c bbvaMT : triggerNew) {
      if((!bbvaMT.copy_record_approval_type__c && triggerOldMap == null)
      || (triggerOldMap != null && triggerOldMap.get(bbvaMT.Id).copy_record_approval_type__c && !bbvaMT.copy_record_approval_type__c)) {//SOLO REPLICO EL ACCOUNT TEAM SI SE HA APROBADO (CHECK DE PENDING APPROVAL DESMARCADO)
        AccountTeamMember accTM;
        accTM = new AccountTeamMember();
        accTM.AccountId = bbvaMT.DES_Client__c;
        accTM.TeamMemberRole = bbvaMT.DES_Member_Role__c;
        accTM.UserId = bbvaMT.DES_User__c;
        accTM.AccountAccessLevel = EDITVAR;
        listAccTM.add(accTM);
      }
    }

    system.debug('>>>>> listAccTM : ' + listAccTM);
    insert listAccTM;
  }
  /* Descomentar en la subida de Alertas*/
  /*public void deleteComAlertManualSharing(List<DES_BBVA_Management_Team__c> triggerOld) {
    Set<Id> setAccountsIds = new Set<Id>();
    Set<Id> setComAlertsIds = new Set<Id>();
    Set<Id> setUsersIds = new Set<Id>();
    for(DES_BBVA_Management_Team__c bbvaMT : triggerOld) {
      if(!setAccountsIds.contains(bbvaMT.DES_Client__c)) {
        setAccountsIds.add(bbvaMT.DES_Client__c);
      }
      if(!setUsersIds.contains(bbvaMT.DES_User__c)) {
        setUsersIds.add(bbvaMT.DES_User__c);
      }
    }

    for(almd__Commercial_Alert__c comAlert : [SELECT Id, almd__User_id__c, almd__closed_won_authorizer_user_id__c,
                                          almd__reject_authorizer_user_id__c FROM almd__Commercial_Alert__c WHERE almd__participant_id__c IN :setAccountsIds]) {
      if(!setComAlertsIds.contains(comAlert.Id)) {
        setComAlertsIds.add(comAlert.Id);
      }
      if(setUsersIds.contains(comAlert.almd__User_id__c)) {
        setUsersIds.remove(comAlert.almd__User_id__c);
      }
      if(setUsersIds.contains(comAlert.almd__closed_won_authorizer_user_id__c)) {
        setUsersIds.remove(comAlert.almd__closed_won_authorizer_user_id__c);
      }
      if(setUsersIds.contains(comAlert.almd__reject_authorizer_user_id__c)) {
        setUsersIds.remove(comAlert.almd__reject_authorizer_user_id__c);
      }
    }
    List<almd__Commercial_Alert__Share> listaComAlertCompartidas = new List<almd__Commercial_Alert__Share>([
    SELECT Id
    FROM almd__Commercial_Alert__Share
    WHERE UserOrGroupId IN :setUsersIds
      AND ParentId IN :setComAlertsIds
      AND RowCause = 'Manual'
  ]);

    system.debug('>>>>> listaComAlertCompartidas : ' + listaComAlertCompartidas);
    delete listaComAlertCompartidas;


  }//FIN deleteComAlertManualSharing
   */

  //esta funcion no está preparada para realizarse de forma masiva. es una funcionalidad que aplica al borrado manual (1 en 1),
  //si se quieren borrar varios de golpe se tendrá que lanzar un batch que borre tods los miembros, tods los manual sharing y los vuelva a crear

  /*method 10*/
  public void deleteVisitManualSharing(List<DES_BBVA_Management_Team__c> triggerOld) {
    //Mapa que contiene el Id de la visita y un boolean indicando si se tiene que borrar o si no se tiene que borrar
    //Map<Id, Boolean> mapDeleteVisit = new Map<Id, Boolean>(); Se comento para sonar
    Set<Id> setAccountsIds;
    setAccountsIds = new Set<Id>();
    //Set<Id> setVisitsIds = new Set<Id>();
    Set<Id> setVisitsDeleteId;
    setVisitsDeleteId = new Set<Id>();
    //Guardo las cuentas que relacionadas al miembro que se quiere borrar
    for(DES_BBVA_Management_Team__c bbvaMT : triggerOld) {
      if(!setAccountsIds.contains(bbvaMT.DES_Client__c)) {
        setAccountsIds.add(bbvaMT.DES_Client__c);
      }
    }

    //MAPA QUE TENGA EL ID DEL CLIENTE Y EL ID DEL GRUPO
    Map<Id, String> mapClientGroup;
    mapClientGroup = new Map<Id, String>();
    //Busco las cuentas que están por debajo de ésta
    for(DES_Subsidiary_Group_Relation__c gsm : [SELECT participant_child_id__c, participant_parent_id__c FROM DES_Subsidiary_Group_Relation__c WHERE (participant_parent_id__c IN :setAccountsIds OR participant_child_id__c IN :setAccountsIds) AND main_subsidiary_ind_type__c = true]) {
      if(!setAccountsIds.contains(gsm.participant_child_id__c)) {
        setAccountsIds.add(gsm.participant_child_id__c);
      }
      if(!setAccountsIds.contains(gsm.participant_parent_id__c)) {
        setAccountsIds.add(gsm.participant_parent_id__c);
      }
      mapClientGroup.put(gsm.participant_child_id__c, gsm.participant_parent_id__c);
    }
    //Busco todas las visitas relacionadas a estas cuentas
    final Map<Id, dwp_kitv__Visit__c> mapVisits = new Map<Id, dwp_kitv__Visit__c>([
    SELECT Id,
        dwp_kitv__account_id__c
    FROM dwp_kitv__Visit__c
    WHERE dwp_kitv__account_id__c IN :setAccountsIds
  ]);

    system.debug('>>>>> mapVisits : ' + mapVisits);

    //MAPA QUE TIENE LA CUENTA COMO KEY Y UNA CONCATENACION DE LAS ID'S DE LAS VISITAS
    Map<Id, String> mapAccountVisits;
    mapAccountVisits = new Map<Id, String>();
    for(dwp_kitv__Visit__c visit : mapVisits.values()) {
      if(mapAccountVisits.get(visit.dwp_kitv__account_id__c) == null) {
        mapAccountVisits.put(visit.dwp_kitv__account_id__c, visit.Id);
      } else {
        mapAccountVisits.put(visit.dwp_kitv__account_id__c, mapAccountVisits.get(visit.dwp_kitv__account_id__c) + ';' + visit.Id);
      }
      if(!setVisitsDeleteId.contains(visit.Id)) {
        setVisitsDeleteId.add(visit.Id);
      }

    }
    system.debug('>>>>> mapAccountVisits : ' + mapAccountVisits);
    //Guardo en un mapa el id de la cuenta y como value la lista de los miembros de las cuentas
    final Map<Id, String> mapAccAndMemb = hndlrDeskUtils.getMapAccountAndMembers(setAccountsIds);
    //Guardo en un mapa el id de la visita y como value la lista de los miembros de las visitas
    Map<Id, String> mapVisitMem = new Map<Id, String>();
    for(dwp_kitv__Visit_Management_Team__c visitMember : [SELECT Id, dwp_kitv__visit_id__c, dwp_kitv__user_id__c, Visit_Client_Id__c FROM dwp_kitv__Visit_Management_Team__c WHERE dwp_kitv__visit_id__c IN :mapVisits.keySet()]) {
      if(mapVisitMem.get(visitMember.dwp_kitv__visit_id__c) == null) {
        mapVisitMem.put(visitMember.dwp_kitv__visit_id__c, visitMember.dwp_kitv__user_id__c);
      } else {
        mapVisitMem.put(visitMember.dwp_kitv__visit_id__c, mapVisitMem.get(visitMember.dwp_kitv__visit_id__c) + ';' + visitMember.dwp_kitv__user_id__c);
      }
    }


    system.debug('>>>>> mapAccAndMemb : ' + mapAccAndMemb);
    for(dwp_kitv__Visit__c visit : mapVisits.values()) {

      system.debug('>>>>> mapAccountVisits.get(visit.dwp_kitv__account_id__c) : ' + mapAccountVisits.get(visit.dwp_kitv__account_id__c));
      system.debug('>>>>> mapAccAndMemb.get(visit.dwp_kitv__account_id__c) : ' + mapAccAndMemb.get(visit.dwp_kitv__account_id__c));
      //Compruebo si el usuario que se borra forma parte del equipo directo
      if(mapAccAndMemb.get(visit.dwp_kitv__account_id__c) != null
      && mapAccAndMemb.get(visit.dwp_kitv__account_id__c).contains(triggerOld.get(0).DES_User__c)) {
        setVisitsDeleteId.remove(visit.Id);
      }
      //COMPRUEBO SI EL USUARIO QUE SE QUIERE BORRAR FORMA PARTE DEL EQUIPO DEL CLIENTE DIRECTO
      if(mapAccountVisits.get(visit.dwp_kitv__account_id__c).contains(';')) {//SI CONTIENE ; (TIENE MAS DE 1 VISITA)
        for(String visitId : mapAccountVisits.get(visit.dwp_kitv__account_id__c).split(';')) {
          system.debug('>>>>> visitId : ' + visitId);
          if(mapVisitMem.get(visitId) != null
          && mapVisitMem.get(visitId).contains(triggerOld.get(0).DES_User__c)) {
            //SI LA VISITA NO CONTIENE EN EL EQUIPO DE LA VISITA EL ID DEL USUARIO
            //AGREGO LA VISITA PARA EL BORRADO DEL SHARING MANUAL
            setVisitsDeleteId.remove(visitId);
          }
        }
      } else {//SI NO CONTIENE ; (SOLO TIENE 1 VISITA)
        system.debug('>>>>> triggerOld.get(0) :' + triggerOld.get(0));
        //system.debug('>>>>> mapVisitMem.get(mapAccountVisits.get(visit.dwp_kitv__account_id__c)).contains(triggerOld.get(0).DES_User__c) : '
        //+ mapVisitMem.get(mapAccountVisits.get(visit.dwp_kitv__account_id__c)).contains(triggerOld.get(0).DES_User__c));
        system.debug('>>>>>  IF1: ' + mapVisitMem.get(mapAccountVisits.get(visit.dwp_kitv__account_id__c)));
        //system.debug('>>>>>  OR IF1: ' +
        //!mapVisitMem.get(mapAccountVisits.get(visit.dwp_kitv__account_id__c)).contains(triggerOld.get(0).DES_User__c));
        if(mapVisitMem.get(mapAccountVisits.get(visit.dwp_kitv__account_id__c)) != null
        && mapVisitMem.get(mapAccountVisits.get(visit.dwp_kitv__account_id__c)).contains(triggerOld.get(0).DES_User__c)) {
          //SI LA VISITA NO CONTIENE EN EL EQUIPO DE LA VISITA EL ID DEL USUARIO
          //AGREGO LA VISITA PARA EL BORRADO DEL SHARING MANUAL
          system.debug('>>>>> AGREGO LA VISITA');
          setVisitsDeleteId.remove(mapAccountVisits.get(visit.dwp_kitv__account_id__c));
        }
      }

      system.debug('>>>>> mapClientGroup : ' + mapClientGroup);
      system.debug('>>>>> mapAccountVisits : ' + mapAccountVisits);

      //system.debug('>>>>> mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) : ' +
      //mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)));
      //COMPRUEBO SI EL USUARIO QUE SE QUIERE BORRAR FORMA PARTE DEL EQUIPO DEL GRUPO
      system.debug('>>>>> mapClientGroup.get(visit.dwp_kitv__account_id__c) : ' + mapClientGroup.get(visit.dwp_kitv__account_id__c));
      system.debug('>>>>> mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) : ' +
        mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)));
      if(mapClientGroup.get(visit.dwp_kitv__account_id__c) != null
      || mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) != null) {
        system.debug('>>>>> mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) : ' +
          mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)));
        //Compruebo si el usuario que se borra forma parte del equipo del grupo
        if(mapAccAndMemb.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) != null
        && mapAccAndMemb.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)).contains(triggerOld.get(0).DES_User__c)) {
          system.debug('>>>>> mapAccountVisits.get(visit.dwp_kitv__account_id__c) : ' + mapAccountVisits.get(visit.dwp_kitv__account_id__c));
          system.debug('>>>>> setVisitsDeleteId : ' + setVisitsDeleteId);
          if(mapAccountVisits.get(visit.dwp_kitv__account_id__c).contains(';')) {
            for(String iidd : mapAccountVisits.get(visit.dwp_kitv__account_id__c).split(';')) {
              system.debug('>>>>> setVisitsDeleteId : ' + setVisitsDeleteId);
              setVisitsDeleteId.remove((Id)iidd);
            }
          } else {
            system.debug('>>>>> ELSE : mapAccountVisits.get(visit.dwp_kitv__account_id__c) : ' + mapAccountVisits.get(visit.dwp_kitv__account_id__c));
            setVisitsDeleteId.remove(mapAccountVisits.get(visit.dwp_kitv__account_id__c));
          }
        }
        //Compruebo las visitas
        if(mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) != null) {
          if(mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)).contains(';')) {//SI CONTIENE ; (TIENE MAS DE 1 VISITA)
            for(String visitId : mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)).split(';')) {
              system.debug('>>>>> visitId : ' + visitId);
              if(mapVisitMem.get(visitId) != null
              && mapVisitMem.get(visitId).contains(triggerOld.get(0).DES_User__c)) {
                //SI LA VISITA NO CONTIENE EN EL EQUIPO DE LA VISITA EL ID DEL USUARIO
                //AGREGO LA VISITA PARA EL BORRADO DEL SHARING MANUAL
                setVisitsDeleteId.remove(visitId);
              }
            }
          } else {//SI NO CONTIENE ; (SOLO TIENE 1 VISITA)
            if(mapVisitMem.get(mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c))) != null
            && mapVisitMem.get(mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c))).contains(triggerOld.get(0).DES_User__c)) {
              system.debug('::::: else');
              //SI LA VISITA NO CONTIENE EN EL EQUIPO DE LA VISITA EL ID DEL USUARIO
              //AGREGO LA VISITA PARA EL BORRADO DEL SHARING MANUAL
              setVisitsDeleteId.remove(mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)));
            }
          }
        }

      }
    }

    system.debug('>>>>> setVisitsDeleteId : ' + setVisitsDeleteId);
    List<dwp_kitv__Visit__Share> listShareToDelete = new List<dwp_kitv__Visit__Share>([
    SELECT Id
    FROM dwp_kitv__Visit__Share
    WHERE ParentId IN :setVisitsDeleteId
    AND UserOrGroupId = :triggerOld.get(0).DES_User__c
    AND RowCause = 'Manual'
  ]);

    system.debug('>>>>> listShareToDelete : ' + listShareToDelete);
    /*if(!listShareToDelete.isEmpty()) {
      triggerOld.get(0).addError('A : ' + setVisitsDeleteId);
    }*/
    delete listShareToDelete;
    //triggerOld.get(0).addError('A : ' + setVisitsDeleteId);


  }//FIN deleteVisitManualSharing


  //ESTE method NO ESTÁ PREPARADO PARA MASIVO, ESTÁ PREPARADO PARA EL BORRADO MANUAL 1 A 1
  /* Method 11*/
  public void deleteOppsManualSharing(List<DES_BBVA_Management_Team__c> triggerOld) {
    Set<Id> setAccountsIds;
    setAccountsIds = new Set<Id>();
    Set<Id> setOppsDeleteId;
    setOppsDeleteId = new Set<Id>();
    //Guardo las cuentas que relacionadas al miembro que se quiere borrar
    for(DES_BBVA_Management_Team__c bbvaMT : triggerOld) {
      if(!setAccountsIds.contains(bbvaMT.DES_Client__c)) {
        setAccountsIds.add(bbvaMT.DES_Client__c);
      }
    }

    //MAPA QUE TENGA EL ID DEL CLIENTE Y EL ID DEL GRUPO
    final Map<Id, String> mapClientGroup = new Map<Id, String>();
    //Busco las cuentas que están por debajo de ésta
    for(DES_Subsidiary_Group_Relation__c gsm : [SELECT participant_child_id__c, participant_parent_id__c FROM DES_Subsidiary_Group_Relation__c WHERE (participant_parent_id__c IN :setAccountsIds OR participant_child_id__c IN :setAccountsIds) AND main_subsidiary_ind_type__c = true]) {
      if(!setAccountsIds.contains(gsm.participant_child_id__c)) {
        setAccountsIds.add(gsm.participant_child_id__c);
      }
      if(!setAccountsIds.contains(gsm.participant_parent_id__c)) {
        setAccountsIds.add(gsm.participant_parent_id__c);
      }
      mapClientGroup.put(gsm.participant_child_id__c, gsm.participant_parent_id__c);
    }
    //Busco todas las Opportunidades relacionadas a estas cuentas
    final Map<Id, Opportunity> mapOpps = new Map<Id, Opportunity>([
    SELECT Id,
        AccountId
    FROM Opportunity
    WHERE AccountId IN :setAccountsIds
  ]);

    system.debug('>>>>> mapOpps : ' + mapOpps);

    //MAPA QUE TIENE LA CUENTA COMO KEY Y UNA CONCATENACION DE LAS ID'S DE LAS Opportunidades
    final Map<Id, String> mapAccountOpps = new Map<Id, String>();

    auxDeleteOppSh1(mapOpps, mapAccountOpps, setOppsDeleteId);

    system.debug('>>>>> mapAccountOpps : ' + mapAccountOpps);
    //Guardo en un mapa el id de la cuenta y como value la lista de los miembros de las cuentas
    final Map<Id, String> mapAccAndMemb = hndlrDeskUtils.getMapAccountAndMembers(setAccountsIds);

    system.debug('>>>>> mapAccAndMemb : ' + mapAccAndMemb);
    for(Opportunity opp : mapOpps.values()) {

      system.debug('>>>>> mapAccountOpps.get(opp.AccountId) : ' + mapAccountOpps.get(opp.AccountId));
      system.debug('>>>>> mapAccAndMemb.get(opp.AccountId) : ' + mapAccAndMemb.get(opp.AccountId));

      //Compruebo si el usuario que se borra forma parte del equipo directo
      if(mapAccAndMemb.get(opp.AccountId) != null
      && mapAccAndMemb.get(opp.AccountId).contains(triggerOld.get(0).DES_User__c)) {
        setOppsDeleteId.remove(opp.Id);
      }

      system.debug('>>>>> mapClientGroup : ' + mapClientGroup);
      system.debug('>>>>> mapAccountOpps : ' + mapAccountOpps);

      //COMPRUEBO SI EL USUARIO QUE SE QUIERE BORRAR FORMA PARTE DEL EQUIPO DEL GRUPO
      system.debug('>>>>> mapClientGroup.get(opp.AccountId) : ' + mapClientGroup.get(opp.AccountId));
      system.debug('>>>>> mapAccountOpps.get(mapClientGroup.get(opp.AccountId)) : ' +
        mapAccountOpps.get(mapClientGroup.get(opp.AccountId)));

      auxDeleteOppSh(opp, mapClientGroup, mapAccountOpps, mapAccAndMemb, setOppsDeleteId, triggerOld);
    }

    system.debug('>>>>> setOppsDeleteId : ' + setOppsDeleteId);
    final List<OpportunityShare> listShareToDelete = new List<OpportunityShare>([
    SELECT Id
    FROM OpportunityShare
    WHERE OpportunityId IN :setOppsDeleteId
    AND UserOrGroupId = :triggerOld.get(0).DES_User__c
    AND RowCause = 'Manual'
  ]);

    system.debug('>>>>> listShareToDelete : ' + listShareToDelete);
    delete listShareToDelete;

  }//FIN deleteOppsManualSharing



  /*
   * Method Aux for delete OppShare
   */
  private static void auxDeleteOppSh(Opportunity opp, Map<Id, String> mapClientGroup, Map<Id, String> mapAccountOpps,
  Map<Id, String> mapAccAndMemb, Set<Id> setOppsDeleteId, List<DES_BBVA_Management_Team__c> triggerOld) {
    if(mapClientGroup.get(opp.AccountId) != null
    || mapAccountOpps.get(mapClientGroup.get(opp.AccountId)) != null) {
      system.debug('>>>>> mapAccountOpps.get(mapClientGroup.get(opp.AccountId)) : ' +
        mapAccountOpps.get(mapClientGroup.get(opp.AccountId)));
      //Compruebo si el usuario que se borra forma parte del equipo del grupo
      if(mapAccAndMemb.get(mapClientGroup.get(opp.AccountId)) != null
      && mapAccAndMemb.get(mapClientGroup.get(opp.AccountId)).contains(triggerOld.get(0).DES_User__c)) {
        system.debug('>>>>> mapAccountOpps.get(opp.AccountId) : ' + mapAccountOpps.get(opp.AccountId));
        system.debug('>>>>> setOppsDeleteId : ' + setOppsDeleteId);
        if(mapAccountOpps.get(opp.AccountId).contains(';')) {
          for(String iidd : mapAccountOpps.get(opp.AccountId).split(';')) {
            system.debug('>>>>> setOppsDeleteId : ' + setOppsDeleteId);
            setOppsDeleteId.remove((Id)iidd);
          }
        } else {
          system.debug('>>>>> ELSE : mapAccountOpps.get(opp.AccountId) : ' + mapAccountOpps.get(opp.AccountId));
          setOppsDeleteId.remove(mapAccountOpps.get(opp.AccountId));
        }
      }
    }
  }

  /*
   * Method Aux for delete OppShare
   */
  private static void auxDeleteOppSh1(Map<Id, Opportunity> mapOpps, Map<Id, String> mapAccountOpps, Set<Id> setOppsDeleteId) {
    for(Opportunity opp : mapOpps.values()) {
      if(mapAccountOpps.get(opp.AccountId) == null) {
        mapAccountOpps.put(opp.AccountId, opp.Id);
      } else {
        mapAccountOpps.put(opp.AccountId, mapAccountOpps.get(opp.AccountId) + ';' + opp.Id);
      }
      if(!setOppsDeleteId.contains(opp.Id)) {
        setOppsDeleteId.add(opp.Id);
      }
    }
  }

  /**
   * Future method to insert manual sharing of alerts
   */
  @future
  public static void insertCommAlertManualSharingFuture(String newListJSON) {
    final List<DES_BBVA_Management_Team__c> newList = (List<DES_BBVA_Management_Team__c>) JSON.deserialize(newListJSON, List<DES_BBVA_Management_Team__c>.class);
    final List<DES_BBVA_Management_Team__c> listBBVAMT = [SELECT Id,
                                                          DES_Client__c,
                                                          DES_User__c
                                                        FROM DES_BBVA_Management_Team__c
                                                        WHERE Id IN :newList
                                                          AND copy_record_approval_type__c = false];
    final List<altm__Commercial_Alert__Share> commAlertShare = insertCommAlertManualSharing(listBBVAMT);
    if(!commAlertShare.isEmpty()) {
      insert commAlertShare;
    }
  }

  /**
   * Future method to delete manual sharing of alerts
   */
  @future
  public static void deleteCommAlertManualSharingFuture(String oldListJSON) {
    final List<DES_BBVA_Management_Team__c> oldList = (List<DES_BBVA_Management_Team__c>) JSON.deserialize(oldListJSON, List<DES_BBVA_Management_Team__c>.class);
    final List<altm__Commercial_Alert__Share> commAlertShare = deleteCommAlertManualSharing(oldList);
    if(!commAlertShare.isEmpty()) {
      delete commAlertShare;
    }
  }

  /**
   * @author Global Desktop
   * @Description insertCommAlertManualSharing
   */
  public static List<altm__Commercial_Alert__Share> insertCommAlertManualSharing(List<DES_BBVA_Management_Team__c> newList) {
    final Map<Id, List<DES_BBVA_Management_Team__c>> mapAccBBVAMT = new Map<Id, List<DES_BBVA_Management_Team__c>>();

    for(DES_BBVA_Management_Team__c iBBVAMT : newList) {
      if(mapAccBBVAMT.containsKey(iBBVAMT.DES_Client__c)) {
        final List<DES_BBVA_Management_Team__c> listAux = mapAccBBVAMT.get(iBBVAMT.DES_Client__c);
        listAux.add(iBBVAMT);
        mapAccBBVAMT.put(iBBVAMT.DES_Client__c, listAux);
      } else {
        mapAccBBVAMT.put(iBBVAMT.DES_Client__c, new List<DES_BBVA_Management_Team__c> {iBBVAMT});
      }
    }

    System.debug('::::::::::mapAccBBVAMT.keySet(): ' + mapAccBBVAMT.keySet());
    System.debug('::::::::::mapAccBBVAMT: ' + mapAccBBVAMT);
    final Map<Id, Id> mapClientGroup = getMapClientGroup(mapAccBBVAMT.keySet());
    final Map<String, Id> mapBusinessGroup = getMapBusinessGroup(mapAccBBVAMT.keySet());
    final Map<Id, altm__Commercial_Alert__c> mapIdAlert = new Map<Id, altm__Commercial_Alert__c>([SELECT Id,
                                                                                                  altm__participant_id__c,
                                                                                                  altm__User_id__c,
                                                                                                  business_group_id__c,
                                                                                                  OwnerId
                                                                                                FROM altm__Commercial_Alert__c
                                                                                                WHERE altm__participant_id__c IN :mapClientGroup.keySet()
                                                                                                  OR business_group_id__c IN :mapBusinessGroup.keySet()]);

    final Map<Id, List<altm__Commercial_Alert__c>> mapBBVAMTAlert = insertCommAlertManualSharingAux(mapIdAlert, mapAccBBVAMT, mapClientGroup, mapBusinessGroup);

    final List<altm__Commercial_Alert__Share> commAlertShare = new List<altm__Commercial_Alert__Share>();
    Set<String> setUserids;
    setUserids  = new Set<String>();

    for(User objUser : [select id from user where id in:mapBBVAMTAlert.keySet() and isActive=true]) {

      setUserids.add(objUser.id);
    }
    for(Id iUser : setUserids) {
      for(altm__Commercial_Alert__c iCommercialAlert : mapBBVAMTAlert.get(iUser)) {
        if(mapAccBBVAMT.get(iCommercialAlert.altm__participant_id__c) != null) { //NOSONAR
          commAlertShare.add(Commercial_Alert_Helper.newBBVAManualSharingCommAlert(iCommercialAlert.Id, iUser));
        } else if(mapAccBBVAMT.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c)) != null
        || mapAccBBVAMT.get(mapBusinessGroup.get(iCommercialAlert.business_group_id__c)) != null) {
          commAlertShare.add(Commercial_Alert_Helper.newBBVAGroupManualSharingCommAlert(iCommercialAlert.Id, iUser));
        }
      }
    }

    return commAlertShare;
  }

  /**
   * @author Global Desktop
   * @Description insertCommAlertManualSharingAux
   */
  public static Map<Id, List<altm__Commercial_Alert__c>> insertCommAlertManualSharingAux(final Map<Id, altm__Commercial_Alert__c> mapIdAlert, final Map<Id, List<DES_BBVA_Management_Team__c>> mapAccBBVAMT, final Map<Id, Id> mapClientGroup, final Map<String, Id> mapBusinessGroup) { //NOSONAR
    Map<Id, List<altm__Commercial_Alert__c>> mapBBVAMTAlert = new Map<Id, List<altm__Commercial_Alert__c>>();
    for(altm__Commercial_Alert__c iCommercialAlert : mapIdAlert.values()) {
      if(mapAccBBVAMT.get(iCommercialAlert.altm__participant_id__c) != null) { //NOSONAR
        for(DES_BBVA_Management_Team__c iBBVAMT : mapAccBBVAMT.get(iCommercialAlert.altm__participant_id__c)) {
          mapBBVAMTAlert = getMapUserCommercialAlert(mapBBVAMTAlert, iBBVAMT, iCommercialAlert);
        }
      } else if(mapAccBBVAMT.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c)) != null
      && iCommercialAlert.business_group_id__c == null) {
        for(DES_BBVA_Management_Team__c iBBVAMT : mapAccBBVAMT.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c))) {
          mapBBVAMTAlert = getMapUserCommercialAlert(mapBBVAMTAlert, iBBVAMT, iCommercialAlert);
        }
      } else if(mapAccBBVAMT.get(mapBusinessGroup.get(iCommercialAlert.business_group_id__c)) != null
      && iCommercialAlert.business_group_id__c != null) {
        for(DES_BBVA_Management_Team__c iBBVAMT : mapAccBBVAMT.get(mapBusinessGroup.get(iCommercialAlert.business_group_id__c))) {
          mapBBVAMTAlert = getMapUserCommercialAlert(mapBBVAMTAlert, iBBVAMT, iCommercialAlert);
        }
      }
    }

    return mapBBVAMTAlert;
  }

  /**
   * @author Global Desktop
   * @Description deleteAlertsManualSharing
   */
  public static List<altm__Commercial_Alert__Share> deleteCommAlertManualSharing(List<DES_BBVA_Management_Team__c> oldList) {
    final Map<Id, List<DES_BBVA_Management_Team__c>> mapAccBBVAMT = new Map<Id, List<DES_BBVA_Management_Team__c>>();

    System.debug('::::::::::oldList.size():' + oldList.size());
    for(DES_BBVA_Management_Team__c iBBVAMT : oldList) {
      if(mapAccBBVAMT.containsKey(iBBVAMT.DES_Client__c)) {
        final List<DES_BBVA_Management_Team__c> listAux = mapAccBBVAMT.get(iBBVAMT.DES_Client__c);
        listAux.add(iBBVAMT);
        mapAccBBVAMT.put(iBBVAMT.DES_Client__c, listAux);
      } else {
        mapAccBBVAMT.put(iBBVAMT.DES_Client__c, new List<DES_BBVA_Management_Team__c> {iBBVAMT});
      }
    }

    final Set<Id> setUserIdNoDelete = new Set<Id>(); //NOSONAR
    for(DES_BBVA_Management_Team__c iBBVAMT : [SELECT Id,
                                              DES_Client__c,
                                              DES_User__c
                                            FROM DES_BBVA_Management_team__c
                                            WHERE DES_Client__c IN :mapAccBBVAMT.keySet()]) {
      for(DES_BBVA_Management_Team__c iBBVAMTAux : mapAccBBVAMT.get(iBBVAMT.DES_Client__c)) {
        if(iBBVAMT.DES_User__c == iBBVAMTAux.DES_User__c) {
          setUserIdNoDelete.add(iBBVAMT.DES_User__c);
        }
      }
    }

    System.debug('::::::::::mapAccBBVAMT.keySet(): ' + mapAccBBVAMT.keySet());
    final Map<Id, Id> mapClientGroup = getMapClientGroup(mapAccBBVAMT.keySet());
    final Map<String, Id> mapBusinessGroup = getMapBusinessGroup(mapAccBBVAMT.keySet());
    final Map<Id, altm__Commercial_Alert__c> mapIdAlert = new Map<Id, altm__Commercial_Alert__c>([SELECT Id,
                                                                                                  altm__participant_id__c,
                                                                                                  altm__User_id__c,
                                                                                                  business_group_id__c,
                                                                                                  OwnerId
                                                                                                FROM altm__Commercial_Alert__c
                                                                                                WHERE altm__participant_id__c IN :mapClientGroup.keySet()
                                                                                                  OR business_group_id__c IN :mapBusinessGroup.keySet()]);

    final Map<Id, List<altm__Commercial_Alert__c>> mapBBVAMTAlert = deleteCommAlertManualSharingAux(mapIdAlert, mapAccBBVAMT, mapClientGroup, mapBusinessGroup, setUserIdNoDelete);

    return deleteCommAlertManualSharingGetShare(mapBBVAMTAlert, mapAccBBVAMT, mapClientGroup, mapBusinessGroup);
  }

  /**
   * @author Global Desktop
   * @Description deleteCommAlertManualSharingAux
   */
  public static Map<Id, List<altm__Commercial_Alert__c>> deleteCommAlertManualSharingAux(final Map<Id, altm__Commercial_Alert__c> mapIdAlert, final Map<Id, List<DES_BBVA_Management_Team__c>> mapAccBBVAMT, final Map<Id, Id> mapClientGroup, final Map<String, Id> mapBusinessGroup, final Set<Id> setUserIdNoDelete) { //NOSONAR
    Map<Id, List<altm__Commercial_Alert__c>> mapBBVAMTAlert = new Map<Id, List<altm__Commercial_Alert__c>>(); //NOSONAR
    for(altm__Commercial_Alert__c iCommercialAlert : mapIdAlert.values()) {
      if(mapAccBBVAMT.get(iCommercialAlert.altm__participant_id__c) != null) { //NOSONAR
        for(DES_BBVA_Management_Team__c iBBVAMT : mapAccBBVAMT.get(iCommercialAlert.altm__participant_id__c)) {
          if(!setUserIdNoDelete.contains(iBBVAMT.DES_User__c)) {
            mapBBVAMTAlert = getMapUserCommercialAlert(mapBBVAMTAlert, iBBVAMT, iCommercialAlert);
          }
        }
      } else if(mapAccBBVAMT.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c)) != null
      && iCommercialAlert.business_group_id__c == null) {
        for(DES_BBVA_Management_Team__c iBBVAMT : mapAccBBVAMT.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c))) {
          if(!setUserIdNoDelete.contains(iBBVAMT.DES_User__c)) {
            mapBBVAMTAlert = getMapUserCommercialAlert(mapBBVAMTAlert, iBBVAMT, iCommercialAlert);
          }
        }
      } else if(mapAccBBVAMT.get(mapBusinessGroup.get(iCommercialAlert.business_group_id__c)) != null
      && iCommercialAlert.business_group_id__c != null) {
        for(DES_BBVA_Management_Team__c iBBVAMT : mapAccBBVAMT.get(mapBusinessGroup.get(iCommercialAlert.business_group_id__c))) {
          if(!setUserIdNoDelete.contains(iBBVAMT.DES_User__c)) {
            mapBBVAMTAlert = getMapUserCommercialAlert(mapBBVAMTAlert, iBBVAMT, iCommercialAlert);
          }
        }
      }
    }

    return mapBBVAMTAlert;
  }

  /**
   * @author Global Desktop
   * @Description deleteAlertsManualSharing
   */
  public static List<altm__Commercial_Alert__Share> deleteCommAlertManualSharingGetShare(final Map<Id, List<altm__Commercial_Alert__c>> mapBBVAMTAlert, final Map<Id, List<DES_BBVA_Management_Team__c>> mapAccBBVAMT, final Map<Id, Id> mapClientGroup, final Map<String, Id> mapBusinessGroup) {
    final List<altm__Commercial_Alert__Share> commAlertShare = new List<altm__Commercial_Alert__Share>();

    commAlertShare.addAll(deleteCommAlertManualSharingGetShareParticipant(mapBBVAMTAlert, mapAccBBVAMT, mapClientGroup, mapBusinessGroup));
    commAlertShare.addAll(deleteCommAlertManualSharingGetShareGroup(mapBBVAMTAlert, mapAccBBVAMT, mapClientGroup, mapBusinessGroup));

    return commAlertShare;
  }

  /**
   * @author Global Desktop
   * @Description deleteCommAlertManualSharingGetShareParticipant
   */
  public static List<altm__Commercial_Alert__Share> deleteCommAlertManualSharingGetShareParticipant(final Map<Id, List<altm__Commercial_Alert__c>> mapBBVAMTAlert, final Map<Id, List<DES_BBVA_Management_Team__c>> mapAccBBVAMT, final Map<Id, Id> mapClientGroup, final Map<String, Id> mapBusinessGroup) {
    final List<altm__Commercial_Alert__Share> commAlertShare = new List<altm__Commercial_Alert__Share>();
    for(altm__Commercial_Alert__Share iCommAlertShare : [SELECT Id,
                                                        UserOrGroupId,
                                                        ParentId
                                                      FROM altm__Commercial_Alert__Share
                                                      WHERE UserOrGroupId IN :mapBBVAMTAlert.keySet()
                                                        AND RowCause = :Schema.altm__Commercial_Alert__Share.RowCause.Participant_member__c]) {
      for(altm__Commercial_Alert__c iCommercialAlert : mapBBVAMTAlert.get(iCommAlertShare.UserOrGroupId)) {
        if(iCommercialAlert.Id == iCommAlertShare.ParentId
          && !commAlertShare.contains(iCommAlertShare)
        && mapAccBBVAMT.get(iCommercialAlert.altm__participant_id__c) != null) {
          commAlertShare.add(iCommAlertShare);
        }
      }
    }

    return commAlertShare;
  }

  /**
   * @author Global Desktop
   * @Description deleteAlertsManualSharing
   */
  public static List<altm__Commercial_Alert__Share> deleteCommAlertManualSharingGetShareGroup(final Map<Id, List<altm__Commercial_Alert__c>> mapBBVAMTAlert, final Map<Id, List<DES_BBVA_Management_Team__c>> mapAccBBVAMT, final Map<Id, Id> mapClientGroup, final Map<String, Id> mapBusinessGroup) {
    final List<altm__Commercial_Alert__Share> commAlertShare = new List<altm__Commercial_Alert__Share>();
    for(altm__Commercial_Alert__Share iCommAlertShare : [SELECT Id,
                                                        UserOrGroupId,
                                                        ParentId
                                                      FROM altm__Commercial_Alert__Share
                                                      WHERE UserOrGroupId IN :mapBBVAMTAlert.keySet()
                                                        AND RowCause = :Schema.altm__Commercial_Alert__Share.RowCause.Group_member__c]) {
      for(altm__Commercial_Alert__c iCommercialAlert : mapBBVAMTAlert.get(iCommAlertShare.UserOrGroupId)) {
        if(iCommercialAlert.Id == iCommAlertShare.ParentId
          && !commAlertShare.contains(iCommAlertShare)
          && (mapAccBBVAMT.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c)) != null
        || mapAccBBVAMT.get(mapBusinessGroup.get(iCommercialAlert.business_group_id__c)) != null)) {
          commAlertShare.add(iCommAlertShare);
        }
      }
    }

    return commAlertShare;
  }

  /**
   * @author Global Desktop
   * @Description getMapUserCommercialAlert
   */
  public static Map<Id, List<altm__Commercial_Alert__c>> getMapUserCommercialAlert(final Map<Id, List<altm__Commercial_Alert__c>> mapBBVAMTAlert, DES_BBVA_Management_Team__c iBBVAMT, altm__Commercial_Alert__c iCommercialAlert) {
    if(mapBBVAMTAlert.containsKey(iBBVAMT.DES_User__c)) {
      final List<altm__Commercial_Alert__c> listAux = mapBBVAMTAlert.get(iBBVAMT.DES_User__c);
      listAux.add(iCommercialAlert);
      mapBBVAMTAlert.put(iBBVAMT.DES_User__c, listAux);
    } else {
      mapBBVAMTAlert.put(iBBVAMT.DES_User__c, new List<altm__Commercial_Alert__c> {iCommercialAlert});
    }

    return mapBBVAMTAlert;
  }

  /**
   * @author Global Desktop
   * @Description updateCommAlertManualSharing
   */
  public static void updateCommAlertManualSharing(Map<Id, DES_BBVA_Management_Team__c> newMap, Map<Id, DES_BBVA_Management_Team__c> oldMap) { //NOSONAR
    final List<DES_BBVA_Management_Team__c> listBBVAMT = new List<DES_BBVA_Management_Team__c>();
    for(DES_BBVA_Management_Team__c iBBVAMT : newMap.values()) {
      if(newMap.get(iBBVAMT.Id).copy_record_approval_type__c != oldMap.get(iBBVAMT.Id).copy_record_approval_type__c
      && newMap.get(iBBVAMT.Id).copy_record_approval_type__c == false) {
        listBBVAMT.add(iBBVAMT);
      }
    }

    final List<altm__Commercial_Alert__Share> commAlertShare = insertCommAlertManualSharing(listBBVAMT);
    if(!commAlertShare.isEmpty()) {
      insert commAlertShare;
    }
  }

  /**
   * @author Global Desktop
   * @Description getMapClientGroup
   */
  public static Map<Id, Id> getMapClientGroup(Set<Id> setAccountId) { //NOSONAR
    final Map<Id, Id> mapClientGroup = new Map<Id, Id>();

    for(DES_Subsidiary_Group_Relation__c iGroupRelation : [SELECT Id,
                                                          participant_child_id__c,
                                                          participant_parent_id__c
                                                        FROM DES_Subsidiary_Group_Relation__c
                                                        WHERE (participant_child_id__c IN :setAccountId
                                                          OR participant_parent_id__c IN :setAccountId)
                                                          AND main_subsidiary_ind_type__c = true]) {
      if(mapClientGroup.get(iGroupRelation.participant_child_id__c) == null) {
        mapClientGroup.put(iGroupRelation.participant_child_id__c, iGroupRelation.participant_parent_id__c);
      }
    }

    return mapClientGroup;
  }

  /**
   * @author Global Desktop
   * @Description getMapClientGroup
   */
  public static Map<String, Id> getMapBusinessGroup(Set<Id> setAccountId) { //NOSONAR
    final Map<String, Id> mapBusinessGroup = new Map<String, Id>();

    for(Account iAccount : [SELECT Id,
                            DES_Group_Code__c,
                            g_customer_id__c
                          FROM Account
                          WHERE Id IN :setAccountId]) {
      if(iAccount.DES_Group_Code__c != null
      && mapBusinessGroup.get(iAccount.DES_Group_Code__c) == null) {
        mapBusinessGroup.put(iAccount.DES_Group_Code__c, iAccount.Id);
      }
    }

    return mapBusinessGroup;
  }

  /*********************************************************************************************************
   * @name            insertFilialCoverTeamMember
   * @author          Capgemini
   * @created         24/10/2024
   * @description     Metodo que crea los CoverTeamMembers de las filiales en función de su rol, region y pais
   * @param           List<DES_BBVA_Management_team__c> triggerNew
   * @return          N/A
   **********************************************************************************************************/
  public static void insertFilialCoverTeamMember(List<DES_BBVA_Management_team__c> triggerNew) {
    List<DES_BBVA_Management_team__c> coverTeamMembersToInsert = new List<DES_BBVA_Management_team__c>();
    Set<Id> setAccIds = new Set<Id>();
    Set<String> coverTeamMembersRoles = new Set<String>();
    Set<String> regionCTM = new Set<String>();
    Map<String,Map<String,List<DES_BBVA_Management_team__c>>> coverTeamMembersByRoleByTerritory = new Map<String,Map<String,List<DES_BBVA_Management_team__c>>>();
    List<Account> listAcc = new List<Account>();
    Map<String,List<Account>> filialesByTerritory = new Map<String,List<Account>>();
    for(DES_BBVA_Management_team__c bbvaMT : triggerNew) {
      setAccIds.add(bbvaMT.DES_Client__c);
      coverTeamMembersRoles.add(bbvaMT.DES_Member_Role__c);
      regionCTM.add(bbvaMT.DES_User_Country__c);
      if(bbvaMT.DES_Member_Role__c != null){
        Map<String,List<DES_BBVA_Management_team__c>> coverTeamMemberByTerritory = coverTeamMembersByRoleByTerritory.get(bbvaMT.DES_Member_Role__c);
        if(coverTeamMemberByTerritory == null){
          List<DES_BBVA_Management_team__c> coverTeamMember = new List<DES_BBVA_Management_team__c>();
          coverTeamMember.add(bbvaMT);
          coverTeamMemberByTerritory = new Map<String,List<DES_BBVA_Management_team__c>>();
          coverTeamMemberByTerritory.put(bbvaMT.DES_User_Country__c,coverTeamMember);
          coverTeamMembersByRoleByTerritory.put(bbvaMT.DES_Member_Role__c,coverTeamMemberByTerritory);
        }
        else{
          List<DES_BBVA_Management_team__c> coverTeamMembersList = coverTeamMemberByTerritory.get(bbvaMT.DES_User_Country__c);
          if(coverTeamMembersList == null){
            List<DES_BBVA_Management_team__c> coverTeamMember = new List<DES_BBVA_Management_team__c>();
            coverTeamMember.add(bbvaMT);
            coverTeamMemberByTerritory.put(bbvaMT.DES_User_Country__c,coverTeamMember);
            coverTeamMembersByRoleByTerritory.put(bbvaMT.DES_Member_Role__c,coverTeamMemberByTerritory);
          }
          else{
            coverTeamMembersList.add(bbvaMT);
          }
        }
      }
    }
    List<String> regionesAsList = new List<String>(regionCTM);
    List<String> rolesAsList = new List<String>(coverTeamMembersRoles);
    String rolesAsString = String.join(rolesAsList, ',');
    String regionesAsString = String.join(regionesAsList, ',');
    List<DES_BBVA_territories__c> coverTeamMembersTerritories = ([SELECT Id, Paises__c, Regiones__c, Rol_Member__c FROM DES_BBVA_territories__c WHERE Regiones__c INCLUDES (:regionesAsString) AND Rol_Member__c INCLUDES (:rolesAsString)]);
    listAcc = [SELECT Id, DES_Country_Client__c, DES_Group__c, DES_Main_Parent__c FROM Account WHERE DES_Main_Parent__c IN: setAccIds];
    for(Account filial : listAcc){
      List<Account> filialesList = filialesByTerritory.get(filial.DES_Country_Client__c);
      if(filialesList == null){
        filialesList = new List<Account>();
        filialesList.add(filial);
        filialesByTerritory.put(filial.DES_Country_Client__c,filialesList);
      }
      else{
        filialesList.add(filial);
      }
    }
    for(DES_BBVA_territories__c territory : coverTeamMembersTerritories){
      Map<Id,List<Account>> filialesByGroup = new Map<Id,List<Account>>();
      List<DES_BBVA_Management_team__c> coverTemaMembersList= new List<DES_BBVA_Management_team__c>();
      if(territory.Paises__c != null){
        for(String pais : territory.Paises__c.split(';')){
          List<Account> filialesList = filialesByTerritory.get(pais);
          if(filialesList != null){
            for(Account filial : filialesList){
              List<Account> filiales = filialesByGroup.get(filial.DES_Main_Parent__c);
              if(filiales == null){
                filiales = new List<Account>();
                filiales.add(filial);
                filialesByGroup.put(filial.DES_Main_Parent__c,filiales);
              }
              else{
                filiales.add(filial);
              }
            }
          }
        }
      }
      for(String role : territory.Rol_Member__c.split(';')){
        Map<String,List<DES_BBVA_Management_team__c>> cTMByTerritory = coverTeamMembersByRoleByTerritory.get(role);
        if(cTMByTerritory != null && territory.Regiones__c != null){
          for(String region : territory.Regiones__c.split(';')){
            List<DES_BBVA_Management_team__c> cTMList = cTMByTerritory.get(region);
            if(cTMList != null){
              coverTemaMembersList.addAll(cTMByTerritory.get(region));
            }
          }
        }
      }
      for(DES_BBVA_Management_team__c coverTeamMember : coverTemaMembersList){
        List<Account> filialesList = filialesByGroup.get(coverTeamMember.DES_Client__c);
        if(filialesList != null){
          for(Account filial : filialesList){
            coverTeamMembersToInsert.add(new DES_BBVA_Management_Team__c(DES_Client__c = filial.id, DES_User__c = coverTeamMember.DES_User__c, DES_Member_Role__c = coverTeamMember.DES_Member_Role__c));
          }
        }
      }
    }
    System.debug('>>>>> coverTeamMembersToInsert : ' + coverTeamMembersToInsert);
    if(!coverTeamMembersToInsert.isEmpty()){
      insert coverTeamMembersToInsert;
    }
  }

  /*********************************************************************************************************
   * @name            deleteFilialCoverTeamMember
   * @author          Capgemini
   * @created         06/11/2024
   * @description     Metodo que borra los CoverTeamMembers de las filiales al borrar los CoverTeamMembers en la cuenta Padre
   * @param           List<DES_BBVA_Management_team__c > listTriggerOld
   * @return          N/A
   **********************************************************************************************************/
  public static void deleteFilialCoverTeamMember(List<DES_BBVA_Management_team__c > listTriggerOld) {
    List<DES_BBVA_Management_team__c> coverTeamMembersToDelete = new List<DES_BBVA_Management_team__c>();
    Set<Id> setAccIds = new Set<Id>();
    Map<String,List<DES_BBVA_Management_team__c>> coverTeamMembersByParentAccount = new Map<String,List<DES_BBVA_Management_team__c>>();
    List<Account> listAcc = new List<Account>();
    Map<String,Account> filiales = new Map<String,Account>();
    Set<Id> setFilialesIds = new Set<Id>();
    List<DES_BBVA_Management_team__c> coverTeamMembersFiliales = new List<DES_BBVA_Management_team__c> ();
    for(DES_BBVA_Management_team__c bbvaMT : listTriggerOld) {
      if(bbvaMT.DES_Client__c != null){
        setAccIds.add(bbvaMT.DES_Client__c);
        List<DES_BBVA_Management_team__c> coverTeamMember = coverTeamMembersByParentAccount.get(bbvaMT.DES_Client__c);
        if(coverTeamMember == null){
          coverTeamMember = new List<DES_BBVA_Management_team__c>();
          coverTeamMember.add(bbvaMT);
          coverTeamMembersByParentAccount.put(bbvaMT.DES_Client__c, coverTeamMember);
        }
        else{
          coverTeamMembersByParentAccount.get(bbvaMT.DES_Client__c).add(bbvaMT);
        }
      }
    }
    listAcc = [SELECT Id, DES_Country_Client__c, DES_Group__c, DES_Main_Parent__c FROM Account WHERE DES_Main_Parent__c IN: setAccIds];
    for(Account acc : listAcc) {
      setFilialesIds.add(acc.Id);
      filiales.put(acc.Id, acc);
    }
    coverTeamMembersFiliales = [SELECT Id, DES_Client__c, DES_User__c, DES_Member_Role__c FROM DES_BBVA_Management_team__c WHERE DES_Client__c IN :setFilialesIds];
    for(DES_BBVA_Management_team__c cTM : coverTeamMembersFiliales) {
      Account filial = filiales.get(cTM.DES_Client__c);
      List<DES_BBVA_Management_team__c> coverTeamMember = coverTeamMembersByParentAccount.get(filial.DES_Main_Parent__c);
      if(!coverTeamMember.isEmpty() && coverTeamMember != null){
        for(DES_BBVA_Management_team__c cTMParent : coverTeamMember) {
          if(cTMParent.DES_User__c == cTM.DES_User__c && cTMParent.DES_Member_Role__c == cTM.DES_Member_Role__c){
            coverTeamMembersToDelete.add(cTM);
          }
        }
      }
    }
    System.debug('>>>>> coverTeamMembersToDelete : ' + coverTeamMembersToDelete);
    if(!coverTeamMembersToDelete.isEmpty()){
      delete coverTeamMembersToDelete;
    }
  }

  /* -------------------------------------------------------------------------------------------------------------- */
  /* --------------------------------------------- METDOS OBSOLETOS ---------------------------------------------- */
  /* -------------------------------------------------------------------------------------------------------------- */


  /*public void insertBBVAMTChildAccount(List<DES_BBVA_Management_team__c> triggerNew) {
    system.debug('>>>>> DENTRO FUNCION insertBBVATChldAccount - triggerNew: ' + triggerNew);
    if (userSettings.CIB_Is_Desktop__c) {
      //1º  Guardo en un set las cuentas relacionadas a los registros insertados
      Set<Id> setIdsCuentasPadre = new Set<Id>();
      for(DES_BBVA_Management_team__c bbvaMT : triggerNew) {
        if(!setIdsCuentasPadre.contains(bbvaMT.DES_Client__c)) {
          setIdsCuentasPadre.add(bbvaMT.DES_Client__c);
        }
      }
      //system.debug('>>>>> setIdsCuentasPadre : ' + setIdsCuentasPadre);
      //2º  Recojo todas las cuentas hijas que tengan como MainParent la cuenta del TeamMember eliminado.
      /-*List<Account> listaCuentasHijas = new List<Account>([
                SELECT  Id,
                    DES_Main_Parent__c,
                    DES_Country_Client__c
                FROM Account
                WHERE DES_Main_Parent__c IN :setIdsCuentasPadre
    ]);
      system.debug('>>>>> listaCuentasHijas: ' + listaCuentasHijas);
       *-/
      //Guardo en un mapa la lista de las cuentas hijas de cada cuenta padre
      Map<Id, List<Account>> mapaCuentasHijasPorPadre = new Map<Id,List<Account>>();//Este mapa como key tiene el
      id de la uent padre y como value una lista con las cuentas hijas
      //for(Account acc : listaCuentasHijas) {
        for(Account acc : [SELECT Id,DES_Main_Parent__c,DES_Country_Client__c FROM Account WHERE DES_Main_Parent__c IN :setIdsCuentasPadre]) {
          List<Account> listaCueH = new List<Account>();
          //Si ya existe un listado de cuentas que son hijas
          if(mapaCuentasHijasPorPadre.get(acc.DES_Main_Parent__c) != null) {
            //Agrego todas las cuentas al listado
            listaCueH = mapaCuentasHijasPorPadre.get(acc.DES_Main_Parent__c);
          }
          //Agrego esta cuenta al listado
          listaCueH.add(acc);

          //Actualizo el mapa con dicha cuenta
          mapaCuentasHijasPorPadre.put(acc.DES_Main_Parent__c, listaCueH);
        }
        system.debug('>>>>> mapaCuentasHijasPorPadre: ' + mapaCuentasHijasPorPadre);
        if(!mapaCuentasHijasPorPadre.isEmpty()) {
          List<DES_BBVA_Management_team__c> listaBBVAMTInsertar = new List<DES_BBVA_Management_team__c>();
          //3º  Recorro TriggerNew y para cada uno de sus registros, lo clono tantas veces como cuentas hijas tengan las cuentas relacionadas
          for(DES_BBVA_Management_team__c bbvamt : triggerNew) {
            system.debug('>>>>> triggerNew: ' + triggerNew);
            if(mapaCuentasHijasPorPadre.get(bbvamt.DES_Client__c) != null) {
              for(Account accH : mapaCuentasHijasPorPadre.get(bbvamt.DES_Client__c)) {
                system.debug('>>>>> Client Country : ' + accH.DES_Country_Client__c);
                system.debug('>>>>> Rol: ' + bbvamt.DES_Member_Role__c + ' Country : ' + bbvamt.DES_Local_Banker_Country__c);
                //Si es del rol Transaccional Banker y el país de destino es distinto
                if((bbvamt.DES_Member_Role__c == Label.DES_Role_Transactional_Banker
                  || bbvamt.DES_Member_Role__c == Label.DES_ROLE_LOCAL_BANKER)
                && accH.DES_Country_Client__c != bbvamt.DES_Local_Banker_Country__c) {
                  system.debug('>>>>> TRANSACTIONAL CON OTRO PAIS');
                  continue;//Que salte a la siguiente iteración
                }
                //Si es del rol es Local Banker
                /-*if(bbvamt.DES_Member_Role__c == Label.DES_ROLE_LOCAL_BANKER) {
                  system.debug('>>>>> INSERTADO LOCAL BANKER');
                  continue;//Que salte a la siguiente iteración
                }*-/
                DES_BBVA_Management_team__c bbvaMTClonado = bbvamt.clone(false, true);
                bbvaMTClonado.DES_Client__c = accH.Id;
                if(bbvamt.DES_Clon_de__c != null) {
                  bbvaMTClonado.DES_Clon_de__c = bbvamt.DES_Clon_de__c;
                } else {
                  bbvaMTClonado.DES_Clon_de__c = bbvamt.Id;
                }
                //bbvaMTClonado.DES_Clon_de__c = bbvamt.Id;
                bbvaMTClonado.DES_Clave_Externa__c = null;
                listaBBVAMTInsertar.add(bbvaMTClonado);
              }
            }
          }

          if (!listaBBVAMTInsertar.isEmpty()) {
            system.debug('>>>> listaBBVAMTInsertar : ' + listaBBVAMTInsertar);
            insert listaBBVAMTInsertar;
          }
        }
      }//FIN SI ES USUARIO DESKTOP
      system.debug('>>>>> FIN FUNCION insertBBVATChldAccount');
    }//FIN insertBBVAMTChildAccount
     */


    /*
     *  LA ACTUALIZACION NO ESTÁ PREPARADA PARA MASIVO, YA QUE NO SE VA A REALIZAR ESTA ACCION EN MASIVO
     *
     */
    /*public void updateBBVAMTChildAccount(Map<Id, DES_BBVA_Management_team__c> triggerNewMap, Map<Id, DES_BBVA_Management_team__c> triggerOldMap) {
      if (userSettings.CIB_Is_Desktop__c) {

        //1º RECOJO ALL LOS BBVA TEAM MEMBERS QUE TENGN COMO PADRE ALGUNO DE OS ACTUALIZADOS
        Set<Id> setIdsBBVMTActualizados = new Set<Id>();
        for(DES_BBVA_Management_team__c bbvaMT : triggerOldMap.values()) {
          if(bbvaMT.Name != triggerNewMap.get(bbvaMT.Id).Name
            || bbvaMT.DES_User__c != triggerNewMap.get(bbvaMT.Id).DES_User__c
            || bbvaMT.DES_Member_Role__c != triggerNewMap.get(bbvaMT.Id).DES_Member_Role__c
            || bbvaMT.DES_Local_Banker_Country__c != triggerNewMap.get(bbvaMT.Id).DES_Local_Banker_Country__c
            || bbvaMT.DES_Client__c != triggerNewMap.get(bbvaMT.Id).DES_Client__c
            || bbvaMT.DES_User_email_text__c != triggerNewMap.get(bbvaMT.Id).DES_User_email_text__c
            || bbvaMT.DES_phone__c != triggerNewMap.get(bbvaMT.Id).DES_phone__c
            || bbvaMT.DES_Tipo_de_cobertura__c != triggerNewMap.get(bbvaMT.Id).DES_Tipo_de_cobertura__c
          || bbvaMT.DES_Clave_Externa__c != triggerNewMap.get(bbvaMT.Id).DES_Clave_Externa__c) {
            if(!setIdsBBVMTActualizados.contains(bbvaMT.Id)) {
              setIdsBBVMTActualizados.add(bbvaMT.Id);
            }
          }
        }

        if(!setIdsBBVMTActualizados.isEmpty()) {
          List<DES_BBVA_Management_team__c> listaBBVAMTHijos = new List<DES_BBVA_Management_team__c>([
                      SELECT  Id,
                              Name,
                              DES_User__c,
                              DES_Member_Role__c,
                              DES_Local_Banker_Country__c,
                              DES_Client__c,
                              DES_User_email_text__c,
                              DES_phone__c,
                              DES_Tipo_de_cobertura__c,
                              DES_Clon_de__c
                      FROM DES_BBVA_Management_team__c
                      WHERE DES_Clon_de__c IN :setIdsBBVMTActualizados
            ]);

          List<DES_BBVA_Management_team__c> listaBBVMTActualizar = new List<DES_BBVA_Management_team__c>();
          //2º RECORRO LOS HIJOS Y LOS ACTULIZO CUANDO SEAN DEL PADRE QUE CORRESPONDE A CADA UNO
          for(DES_BBVA_Management_team__c bbvaMTH : listaBBVAMTHijos) {
            if(triggerNewMap.get(bbvaMTH.DES_Clon_de__c) != null) {
              bbvaMTH.Name = triggerNewMap.get(bbvaMTH.DES_Clon_de__c).Name;
              bbvaMTH.DES_User__c = triggerNewMap.get(bbvaMTH.DES_Clon_de__c).DES_User__c;
              bbvaMTH.DES_Member_Role__c = triggerNewMap.get(bbvaMTH.DES_Clon_de__c).DES_Member_Role__c;
              bbvaMTH.DES_Local_Banker_Country__c = triggerNewMap.get(bbvaMTH.DES_Clon_de__c).DES_Local_Banker_Country__c;
              //bbvaMTH.DES_Client__c = triggerNewMap.get(bbvaMTH.DES_Clon_de__c).DES_Client__c;
              bbvaMTH.DES_User_email_text__c = triggerNewMap.get(bbvaMTH.DES_Clon_de__c).DES_User_email_text__c;
              bbvaMTH.DES_phone__c = triggerNewMap.get(bbvaMTH.DES_Clon_de__c).DES_phone__c;
              bbvaMTH.DES_Tipo_de_cobertura__c = triggerNewMap.get(bbvaMTH.DES_Clon_de__c).DES_Tipo_de_cobertura__c;
              bbvaMTH.DES_Clave_Externa__c = null;
              listaBBVMTActualizar.add(bbvaMTH);
            }
          }

          if (!listaBBVMTActualizar.isEmpty()) {
            system.debug('>>>>> listaBBVMTActualizar : ' + listaBBVMTActualizar);
            update listaBBVMTActualizar;
          }
        }
      }//fin si es usuario desktop
    }//fin updateBBVAMTChildAccount
     */
    /*public void deleteBBVAMTChildAccount(List<DES_BBVA_Management_team__c> triggerOld) {
      if (userSettings.CIB_Is_Desktop__c) {
        //1. Guardo los Ids de las cuentas que estaban relacionadas con los OppManagementMembers
        Set<Id> setIdsCuentasPadre = new Set<Id>();
        Set<Id> setIdsUsers = new Set<Id>();
        for(DES_BBVA_Management_team__c bbvaMT : triggerOld) {
          //if(bbvaMT.DES_Member_Role__c == 'Global Banker' || bbvaMT.DES_Member_Role__c == 'Industry Head') {

            if(!setIdsCuentasPadre.contains(bbvaMT.DES_Client__c)) {
              setIdsCuentasPadre.add(bbvaMT.DES_Client__c);
            }
            if(!setIdsUsers.contains(bbvaMT.DES_User__c)) {
              setIdsUsers.add(bbvaMT.DES_User__c);
            }

          //}

        }
        system.debug('>>>>> setIdsCuentasPadre : ' + setIdsCuentasPadre);
        //2. Recojo todas las cuentas hijas que tengan como MainParent la cuenta del TeamMember eliminado.
        Map<Id, Account> mapaCuentasHijas = new Map<Id, Account>([
                                  SELECT Id
                                  FROM Account
                                  WHERE DES_Main_Parent__c IN :setIdsCuentasPadre
          ]);

        system.debug('>>>>> mapaCuentasHijas : ' + mapaCuentasHijas);

        List<DES_BBVA_Management_team__c> listaBBVAMTBorrar = new List<DES_BBVA_Management_team__c >([
                                      SELECT Id
                                      FROM DES_BBVA_Management_team__c
                                      WHERE DES_User__c IN :setIdsUsers
                                          AND DES_Client__c IN :mapaCuentasHijas.keySet()
                                          //AND (DES_Member_Role__c = 'Global Banker' OR DES_Member_Role__c = 'Industry Head')
          ]);

        if (!listaBBVAMTBorrar.isEmpty()) {
          system.debug('>>>>> listaBBVAMTBorrar : ' + listaBBVAMTBorrar);
          delete listaBBVAMTBorrar;
        }
      }//fin si es usuario desktop
    }//FIN deleteBBVAMTChildAccount
     */

    /*
     * Sólo se implementa el method de insert, de momento no se hace nada si se elimina/actualiza el registro de DES_BBVA_Management_team__c
     *//*
    public void updateBankerAccount(List<DES_BBVA_Management_team__c> triggerNew) {
      //list<Account> accountsToUpdate = new list<Account>();
      map<Id,Account> accountsMapToUpdate = new map<Id,Account>();

      if (userSettings.CIB_Is_Desktop__c) {

        for(DES_BBVA_Management_team__c bbvaMT : triggerNew) {
          if(!accountsMapToUpdate.containsKey(bbvaMT.DES_Client__c) && bbvaMT.DES_Member_Role__c == Label.DES_ROLE_LOCAL_BANKER) {
            Account accountAux = new Account(id=bbvaMT.DES_Client__c,DES_Banker_MultiHierarchy__c=bbvaMT.DES_First_Name__c + ' ' + bbvaMT.DES_Last_Name__c);
            accountsMapToUpdate.put(bbvaMT.DES_Client__c,accountAux);
          }
        }
      }


      if (!accountsMapToUpdate.isEmpty()) {
        system.debug('>>>>>>> Lista de Accounts a actualizar: ' + accountsMapToUpdate.values());
        update accountsMapToUpdate.values();
      }

    }*/

  }