/*
*Name:            DES_Visit_TriggerHandler
*Description:     Class with VisitTrigger custom methods
*Test Class:      -
*
*Version        Date            Author            Summary of changes
*--------------------------------------------------------------------------------------------------------------------------------
*0.1            08/05/2018      Accenture         Class creation
*0.2            10/05/2018      Accenture         Update -> se añade actualización en la tabla Denorm de la fecha VisitStartDate
*0.3            15/06/2018      Accenture         Update -> Se añade en el method visitAfterInsert y visitAfterUpdate una comprobación
            para evitar que haga un bucle infinito cuando la visita pertenece a un Lead (Prospect) en lugar de a una Account
*0.4            21/06/2018      Accenture         Update -> Se quita la comprobación para Visitas de Account/Lead porque
            finalmente este arreglo se ha hecho en la clase DES_DenormalizeVisitsUtils
*0.5            29/06/2018      Accenture         Update -> modificado method visitAfterUpdate para que si se cambia el accountId de una Visit,
             se ejecute restore() y no borre la Visit a posteriori la clase DES_DenormAccountVisitsTriggerHandler
*0.6            01/02/2019      Accenture         Update -> se añade el method setVisitGMFields para rellenar los valores
            de los nuevos campos de GM
*0.7            2019/02/28      Cuando se crea la Task se añade un nuevo campo de Global Markets (Product)
*0.8            28/04/2020      VASS             Se añade los methods checkAccessByClientCountry y fillMapVisitIdGroup confidencialidad VENEZUELA.
*0.9.           27/05/25        CIB.              Se añade method checkOwnerDelete para validar que solo el owner borre visitas
*/
public with sharing class DES_Visit_TriggerHandler { //NOSONAR
  //private Integer timesExecuted = 0;

  /*
  * clase auxiliar desktop utils
  */
  final Desktop_Utils desUtils = Desktop_Utils.getInstance();
  //final private CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();

  /**
  * @description bypass custom setting
  */
  final private CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();

  /**
  * @description  Set con los id's de las visitas
  */
  private static Set<Id> setIdVisits = new Set<Id>();

  /**
  * @description  Set con los id's de los clientes relacionados a las visitas
  */
  private static Set<Id> setIdClients = new Set<Id>();

  /**
  * @description Mapa que relaciona Id Visita -> Id GrupoCliente a la que pertenece, para rellenarse se debe llamar al met0d0
  * fillMapVisitIdGroup(triggerNew,setIdClients) donde setIdClients es un set de los clientes padres de las visitas.
  */
  private static Map<Id, Id> mapCltGrpVst = new Map<Id, Id>();

  /**
  * @description  mapa de las cuentas relacionadas con las visitas
  */
  private static Map<Id, Account> mapAccounts = new Map<Id, Account>();

  //private Map<Id, dwp_kitv__Visit_Management_Team__c> mapVisitUsersMembers = new Map<Id, dwp_kitv__Visit_Management_Team__c>();

  /**
  * @description  mapa de las cuentas grupo
  */
  private static Map<Id, Id> mapClientGroup = new Map<Id, Id>();

  /*
  * Global list for method set members
  */
  private static final List<dwp_kitv__Visit_Management_Team__c> PARTICIPANTS = new List<dwp_kitv__Visit_Management_Team__c>();
  /*
  * Global list for method set members
  */
  private static final List<dwp_kitv__Visit_Contact__c> OTHERPARTICIPANTS = new List<dwp_kitv__Visit_Contact__c>();

    // ---------------
    //private Methods
    // ---------------

  /*
  * @author Global Desktop
  * @Description fillIdVisits
  */
  private static void fillIdVisits(dwp_kitv__Visit__c visit) {
    if(!setIdVisits.contains(visit.Id)) {
      setIdVisits.add(visit.Id);
    }
  }

  /*
  * @author Global Desktop
  * @Description fillClientVisits
  */
  private static void fillClientVisits(dwp_kitv__Visit__c visit) {
    if(!setIdClients.contains(visit.dwp_kitv__account_id__c)) {
      setIdClients.add(visit.dwp_kitv__account_id__c);
    }
  }


  /*
  * @author Global Desktop
  * @Description retrieveRelatedClients
  */
  private static void retrieveRelatedClients() {
    mapAccounts = new Map<Id, Account>([
      SELECT  Id,
          Name
      FROM  Account
      WHERE   Id IN :setIdClients
    ]);
  }



  /*
  * @author Global Desktop
  * @Description retrieveRelatedAccountMembers
  */
  private Map<Id, String> retrieveRelatedAccountMembers() {
    system.debug('>>>>> mapAccounts : ' + mapAccounts);
    mapClientGroup = desUtils.getMapClientGroup(mapAccounts.keySet());
    final Set<Id> setAccountsIds = new Set<Id>();
    setAccountsIds.addAll(mapAccounts.keySet());
    system.debug('>>>>> setAccountsIds : ' + setAccountsIds);
    setAccountsIds.addAll(mapClientGroup.values());
    system.debug('>>>>> setAccountsIds : ' + setAccountsIds);
    final Map<Id, String> mapAccMem = new Map<Id, String>();
    for(AccountTeamMember actm : [SELECT UserId, AccountId FROM AccountTeamMember WHERE AccountId IN :setAccountsIds]) {
      if(mapAccMem.get(actm.AccountId) == null) {
        mapAccMem.put(actm.AccountId, (String) actm.UserId);
      } else {
        String membersIds = mapAccMem.get(actm.AccountId);
        membersIds += ';' + actm.UserId;
        mapAccMem.put(actm.AccountId, membersIds);
      }
    }
    system.debug('>>>>> mapAccMem : ' + mapAccMem);
    return mapAccMem;
  }

  /*
  * @author Global Desktop
  * @Description Check Private visits cuando el cliente es venezolano
  */
  public static void privateVisit(List<dwp_kitv__Visit__c> triggerNew) {
    Set<Id> idsAccount;
    idsAccount = new Set<Id>();

    final String ven = 'VE';//NOSONAR

    for(dwp_kitv__Visit__c vst : triggerNew) {
      idsAccount.add(vst.dwp_kitv__account_id__c);
    }

    final List<Account> accs = [Select Id, DES_Country_Client__c from Account where Id IN :idsAccount];
    for(dwp_kitv__Visit__c currentVst : triggerNew) {
      for(Account currentAcc : accs) {
        if(currentAcc.Id == currentVst.dwp_kitv__account_id__c && currentAcc.DES_Country_Client__c == ven) {
          currentVst.Private_Visit__c = true;
        }
      }
    }
  }


  /*
  * @author Global Desktop
  * @Description Add manual sharing for GB and TB from Venezuela
  * @Dependencies DES_Subsidiary_Group_Relation__c
  */
  public static void checkAccessByClientCountry(List<dwp_kitv__Visit__c> triggerNew) {
    final List<String> literals = new List<String>{'VE', Label.DES_ROLE_GLOBAL_BANKER, Label.DES_Role_Transactional_Banker};
    final Desktop_Utils utilsHandler = Desktop_Utils.getInstance();
    Map<Id, List<DES_BBVA_Management_team__c>> mapAccMemInf = new Map<Id, List<DES_BBVA_Management_team__c>>();
    final List<dwp_kitv__Visit__Share> lstMnlShrVisits = new List<dwp_kitv__Visit__Share>();

    for(dwp_kitv__Visit__c fillIds : triggerNew) {
      fillClientVisits(fillIds);
    }
    system.debug('>>>>>> setIdClients' + setIdClients);

    fillMapVisitIdGroup(triggerNew,setIdClients);
    system.debug('>>>>>> mapCltGrpVst' + mapCltGrpVst);

    final Set<Id> clntGrpVists = new Set<Id>(mapCltGrpVst.values());
    mapAccMemInf = utilsHandler.getMapAccountAndMembersInfo(clntGrpVists);
    system.debug('>>>>>> mapAccMemInf' + mapAccMemInf);

    for(dwp_kitv__Visit__c visit : triggerNew) {
      if(visit.dwp_kitv__country_name__c == literals[0]) {
        System.debug('>>>>> Es Visita de Cliente venezolano');
        System.debug('>>>>> la validacion es ------> ' + mapAccMemInf.get(mapCltGrpVst.get(visit.Id)));
        if(mapAccMemInf.get(mapCltGrpVst.get(visit.Id)) != null) {
          for(DES_BBVA_Management_team__c team : mapAccMemInf.get(mapCltGrpVst.get(visit.Id))) {
            if(team.DES_Local_Banker_Country__c == literals[0] && team.DES_Member_Role__c == literals[2]) {
              System.debug('>>>>> Se agrego el TB');
              lstMnlShrVisits.add(utilsHandler.newManualSharingVisits(visit.Id, team.DES_User__c, 'Edit'));
            } else if(team.DES_Member_Role__c == literals[1]) {
              System.debug('>>>>> Se agrego el GB');
              lstMnlShrVisits.add(utilsHandler.newManualSharingVisits(visit.Id, team.DES_User__c, 'Edit'));
            }
          }
        }
      }
    }

    system.debug('>>>>> lstMnlShrVisits: ' + lstMnlShrVisits);
    final List<Database.SaveResult> listSR = Database.insert(lstMnlShrVisits,false);
    system.debug('>>>>> Result insert Databse: ' + listSR);

  }

  /*
  * @author Global Desktop
  * @Description fill mapCltGrpVst variable.
  */
  public static void fillMapVisitIdGroup(List<dwp_kitv__Visit__c> newVisits, Set<Id> idClients) {
    final List <DES_Subsidiary_Group_Relation__c> clientRelations = [SELECT Id, participant_parent_id__c, participant_child_id__c from DES_Subsidiary_Group_Relation__c where participant_child_id__c IN :idClients];
    for(dwp_kitv__Visit__c currentVisit : newVisits) {
      for(DES_Subsidiary_Group_Relation__c currentRelation : clientRelations) {
        if(currentRelation.participant_child_id__c == currentVisit.dwp_kitv__account_id__c) {
          mapCltGrpVst.put(currentVisit.Id,currentRelation.participant_parent_id__c);
        }
      }
    }
  }

  //private void getVisitBBVAMembers() {
  //  mapVisitUsersMembers = new Map<Id, dwp_kitv__Visit_Management_Team__c>([
  //    SELECT  Id,
  //        dwp_kitv__user_id__c
  //    FROM  dwp_kitv__Visit_Management_Team__c
  //    WHERE  dwp_kitv__visit_id__c IN :setIdVisits
  //  ]);
  //  for(dwp_kitv__Visit_Management_Team__c visitMember : mapVisitUsersMembers) {
  //  }
  //}


  /*
  * @author Global Desktop
  * @Description manualSharingVisitMembers
  */
  private void manualSharingVisitMembers() {
    final List<dwp_kitv__Visit__Share> listVisitSharing = new List<dwp_kitv__Visit__Share>();
    for(dwp_kitv__Visit_Management_Team__c visitTM : [SELECT dwp_kitv__visit_id__c, dwp_kitv__user_id__c FROM dwp_kitv__Visit_Management_Team__c WHERE dwp_kitv__visit_id__c IN :setIdVisits]) {
      listVisitSharing.add(desUtils.newManualSharingVisit(visitTM.dwp_kitv__visit_id__c, visitTM.dwp_kitv__user_id__c, Label.LABS_SF_Edit));
    }
    List<Database.SaveResult> listSR = Database.insert(listVisitSharing,false); //NOSONAR
  }


    // ---------------
    //public Methods
    // ---------------


  /*
  * @author Global Desktop
  * @Description
  */
  public void visitAfterInsert(List<dwp_kitv__Visit__c> news) {

    copyTemplateFiles(news);

    /*  ComentadasCampañasAlertasParaSubidaPosterior*/
    //Actualizo la commercial alert
    /*ComentadasCampañasAlertasParaSubidaPosterior  */

    /*  ComentadasCampañasAlertasParaSubidaPosterior
    // Si la visita está relacionada con una campaña (accountCampaign), se añaden miembros al equipo de la visita
    isAccountCampaignRelatedOnInsert( news );
    ComentadasCampañasAlertasParaSubidaPosterior  */

     if (/*userSettings.CIB_Is_Desktop__c &&*/ !bypassSettings.CIB_DES_DataMigration__c) {
      system.debug(Logginglevel.INFO,'>>>>>>> Desktop User. Inserting records to a DenormalizeVisits custom object...');
      final DES_DenormalizeVisitsUtils doUtil = new DES_DenormalizeVisitsUtils();
      for (dwp_kitv__Visit__c vis : news) {
        //if (vis.dwp_kitv__account_id__c != null) {
          system.debug(Logginglevel.INFO,'>>>>>>> Desktop User. Inserting records to a DenormalizeVisits custom object. Denormalize Visit: ' + vis.Id);
          doUtil.denormalize(String.valueOf(vis.Id));
        //}
        //Relleno el set que tiene las Id's de las visitas
        if(setIdVisits.isEmpty()) {
          fillIdVisits(vis);
        }
      }
    } 
    createSharingVisitAccMembers(news, retrieveRelatedAccountMembers(), mapClientGroup);
    //timesExecuted ++;
  }//FIN AFTER INSERT



  /*
  * @author Global Desktop
  * @Description Función que, al crear la visita, en caso de tener un nbc asociado, copia los files del nbc y los pone en la visita
  */
  private static void copyTemplateFiles(List<dwp_kitv__Visit__c> triggerNew) {
    //Recojo los id's de los NBC's, tendra como key el id del comite y como value el id de la visita
    final Map<Id, Id> mapNBCVisit = new Map<Id, Id>();

    for(dwp_kitv__Visit__c visit : triggerNew) {
      if(visit.Committee_id__c != null) {
        mapNBCVisit.put(visit.Committee_id__c, visit.Id);
      }
    }
    final Set<Id> setNBCIds = mapNBCVisit.keySet();
    if(!setNBCIds.isEmpty()) {
      final List<ContentDocumentLink> listCdlToInsert = new List<ContentDocumentLink>();
      for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId, ShareType FROM ContentDocumentLink WHERE LinkedEntityId IN :setNBCIds]) {
        final ContentDocumentLink cdl2 = cdl.clone(false, true);
        cdl2.LinkedEntityId = mapNBCVisit.get(cdl.LinkedEntityId);
        listCdlToInsert.add(cdl2);
      }
      system.debug('>>>>> listCdlToInsert : ' + listCdlToInsert);
      if(!listCdlToInsert.isEmpty()) {
        try {
          insert listCdlToInsert;
        } catch(Exception e) {
          system.debug('>>>>> EXCEPTION : ' + e);
        }
      }

    }

  }


  /*
  * @author Global Desktop
  * @Description updateStatusNBC
  */
  public static void updateStatusNBC(List<dwp_kitv__Visit__c> triggerNew) {
    final Set<Id> nbcId = new Set<Id>();
    for(dwp_kitv__Visit__c visit : triggerNew) {
      if(visit.Committee_id__c != null) {
        nbcId.add(visit.Committee_id__c);
      }
    }

    final Map<Id,NBC__c> nbcMap = new Map<Id,NBC__c>([SELECT Id, Visit_Status__c from NBC__c where Id IN :nbcId]);

    for(NBC__c nbc : nbcMap.values()) {
      nbc.Visit_Status__c = Label.DES_Visit_NBC_Status;
    }

    update nbcMap.values();
  }


  /*
  * @author Global Desktop
  * @Description oppsTopicsNBC
  */
  public static void oppsTopicsNBC(List<dwp_kitv__Visit__c> triggerNew) {
    final Set<Id> nbcId = new Set<Id>();
    for(dwp_kitv__Visit__c visit : triggerNew) {
      if(visit.Committee_id__c != null) {
        nbcId.add(visit.Committee_id__c);
      }
    }

    final Map<Id,Opportunity> nbcOpps = new Map<Id,Opportunity>([SELECT Id, Committee_id__c, Name, Account.Name from Opportunity where Committee_id__c IN :nbcId]);
    final List <dwp_kitv__Visit_Topic__c> topicsToInsert = new List<dwp_kitv__Visit_Topic__c>();

    for(dwp_kitv__Visit__c visit : triggerNew) {
      for(Opportunity opp : nbcOpps.values()) {
        if(visit.Committee_id__c == opp.Committee_id__c) {
          final  dwp_kitv__Visit_Topic__c topic = new dwp_kitv__Visit_Topic__c();
          topic.dwp_kitv__visit_id__c = visit.id;
          topic.dwp_kitv__topic_desc__c = opp.Name + ' - ' + opp.Account.Name;
          topic.dwp_kitv__opportunity_id__c = opp.id;
          topicsToInsert.add(topic);
        }
      }
    }
    if(!topicsToInsert.isEmpty()) {
      insert topicsToInsert;
    }
  }


  /*
  * @author Global Desktop
  * @Description fillClientNBCVisit
  */
  public static void fillClientNBCVisit(List<dwp_kitv__Visit__c> triggerNew) {
    final String rtype = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_CLIENT_NBC).getRecordTypeId();
    final List <Account> accounts = [Select id from Account where RecordTypeId = :rtype LIMIT 1];
        system.debug('>>>rtClase -> ' + rtype);
        system.debug('>>>accounts -> ' + accounts);
    for(dwp_kitv__Visit__c visit : triggerNew) {
      if(visit.Committee_id__c != null && !accounts.isEmpty()) {
        visit.dwp_kitv__account_id__c = accounts.get(0).id;
      }
    }
  }

/*
  * @author Global Desktop
  * @Description futuremethod for fillMembers
  */
  @future
  private static void futureFillMembers(String listNew) {
    final List<dwp_kitv__Visit__c> triggerNew = (List<dwp_kitv__Visit__c>)JSON.deserialize(listNew, List<dwp_kitv__Visit__c>.class);
    final Set<Id> nbcId = new Set<Id>();

    final List <NBC_Member__c> membersEMEA = new List <NBC_Member__c>([SELECT id, BBVA_participant__c, Other_BBVA_participant__c, region_emea__c, region_latam__c, region_usa__c from NBC_Member__c where region_emea__c = true]);
    final List <NBC_Member__c> membersLATAM = new List <NBC_Member__c>([SELECT id, BBVA_participant__c, Other_BBVA_participant__c, region_emea__c, region_latam__c, region_usa__c from NBC_Member__c where region_latam__c = true]);
    final List <NBC_Member__c> membersUSA = new List <NBC_Member__c>([SELECT id, BBVA_participant__c, Other_BBVA_participant__c, region_emea__c, region_latam__c, region_usa__c from NBC_Member__c where region_usa__c = true]);
	  system.debug('membersEMEA -> ' + membersEMEA);
	  system.debug('membersLATAM -> ' + membersLATAM);
	  system.debug('membersUSA -> ' + membersUSA);

    for(dwp_kitv__Visit__c visit : triggerNew) {
      if(visit.Committee_id__c != null) {
        nbcId.add(visit.Committee_id__c);
      }
    }

    final Map <Id, NBC__c> nbcs = new Map <Id, NBC__c>([SELECT id, NBC_Region_type__c from NBC__c where id IN : nbcId]);

    for(dwp_kitv__Visit__c visit : triggerNew) {

    if(visit.disclosure_info_type__c != Label.DES_OP_CONFIDENTIAL && !nbcs.isEmpty()) {

      membersNBCAux(nbcs, visit, membersEMEA, Label.NBC_REGION_EMEA);
      membersNBCAux(nbcs, visit, membersLATAM, Label.NBC_REGION_LATAM);
      membersNBCAux(nbcs, visit, membersUSA, Label.NBC_REGION_USA);
    }

  }

    if(!PARTICIPANTS.isEmpty()) {
      insert PARTICIPANTS;
    }
    if(!OTHERPARTICIPANTS.isEmpty()) {
      insert OTHERPARTICIPANTS;
    }
  }
  /*
  * @author Global Desktop
  * @Description fillMembers
  */
  public static void fillMembers(List<dwp_kitv__Visit__c> triggerNew) {
    futureFillMembers(JSON.serialize(triggerNew));
  }

  /*
  * Aux method for members NBC
  */
  private static void membersNBCAux(Map <Id, NBC__c> nbcs, dwp_kitv__Visit__c visit, List <NBC_Member__c> members, String region) {
    if(nbcs.get(visit.Committee_id__c) != null && nbcs.get(visit.Committee_id__c).NBC_Region_type__c == region && !members.isEmpty()) {
        for(NBC_Member__c member : members) {
          if(member.BBVA_participant__c != null && member.BBVA_participant__c != visit.OwnerId) { //NOSONAR
            dwp_kitv__Visit_Management_Team__c bbvamember;
            bbvamember = new dwp_kitv__Visit_Management_Team__c();
            bbvamember.dwp_kitv__user_id__c = member.BBVA_participant__c;
            bbvamember.dwp_kitv__visit_id__c = visit.id;
            PARTICIPANTS.add(bbvamember);
          } else if(member.Other_BBVA_participant__c != null) {
            dwp_kitv__Visit_Contact__c otherbbvamember;
            otherbbvamember = new dwp_kitv__Visit_Contact__c();
            otherbbvamember.dwp_kitv__contact_id__c = member.Other_BBVA_participant__c;
            otherbbvamember.dwp_kitv__visit_id__c = visit.id;
            OTHERPARTICIPANTS.add(otherbbvamember);
          }
        }
      }
  }

  /**
   * Si una nueva visita está relacionada con una campaña (accountCampaign), se añadirán el Owner y Banker PS al
   * equipo de la visita
   *
   * @param triggerNew
   */
   /*  ComentadasCampañasAlertasParaSubidaPosterior
  private void isAccountCampaignRelatedOnInsert( List<dwp_kitv__Visit__c> triggerNew ) {

    Map<Id, dwp_kitv__Visit__c> visitsByAccountCampaignId = new Map<Id, dwp_kitv__Visit__c>();
    for ( dwp_kitv__Visit__c visit : triggerNew ) {

      if ( visit.participant_campaign_id__c != null ) {
        visitsByAccountCampaignId.put( visit.participant_campaign_id__c, visit );
      }

    }

    if ( ! visitsByAccountCampaignId.isEmpty() ) {
      //obtener los miembros de equipo a insertar de las campañas
      Map<dwp_kitv__Visit__c, Set<Id>> teamMembersToAddByVisit = getMembersFromAccountCampaigns( visitsByAccountCampaignId );

      if ( !teamMembersToAddByVisit.isEmpty() ) {
        DES_Visit_Helper.createTeamMembers( teamMembersToAddByVisit, false );
      }
    }

  }
  ComentadasCampañasAlertasParaSubidaPosterior  */

  /**
   * Si una visita existente se ha vinculado a una campaña (AccountCampaign), se añadirán el Owner y Banker PS al
   * equipo de la visita
   *
   * @param newMap
   * @param oldMap
   */

   /*ComentadasCampañasAlertasParaSubidaPosterior
  private void isAccountCampaignRelatedOnUpdate ( Map<Id, dwp_kitv__Visit__c> newMap, Map<Id, dwp_kitv__Visit__c> oldMap ) {

    Map<Id, dwp_kitv__Visit__c> visitsByAccountCampaignId = new Map<Id, dwp_kitv__Visit__c>();
    for ( Id visitId : newMap.keySet() ) {

      Id oldAccountCampaignId = oldMap.get( visitId ).participant_campaign_id__c;
      Id newAccountCampaignId = newMap.get( visitId ).participant_campaign_id__c;
      Boolean isAccountCampaignIdChanged = oldAccountCampaignId != newAccountCampaignId;

      // Si la visita se ha vinculado a una campaña ( existe una Validation Rule que no dejará que se cambie de campaña, aún así... )
      if ( oldAccountCampaignId == null && isAccountCampaignIdChanged ) {
        visitsByAccountCampaignId.put( newAccountCampaignId, newMap.get( visitId ) );
      }
    }

    if ( !visitsByAccountCampaignId.isEmpty() ) {
      // obtener los miembros de equipo a insertar de las campañas
      Map<dwp_kitv__Visit__c, Set<Id>> teamMembersToAddByVisit = getMembersFromAccountCampaigns( visitsByAccountCampaignId );

      if ( !teamMembersToAddByVisit.isEmpty() ) {
        DES_Visit_Helper.createTeamMembers( teamMembersToAddByVisit, true );
      }
    }

  }
  ComentadasCampañasAlertasParaSubidaPosterior */

  /**
   * Obtiene los Qwners y BankerPS de las account Campaign que deberán añadirse a los equipos de las visitas
   *
   * @param visitsByAccountCampaignId
   *
   * @return
   */

   /*    ComentadasCampañasAlertasParaSubidaPosterior
  private Map<dwp_kitv__Visit__c, Set<Id>> getMembersFromAccountCampaigns ( Map<Id, dwp_kitv__Visit__c> visitsByAccountCampaignId ) {

    // obtener los miembros de equipo a insertar de las campañas
    Map<dwp_kitv__Visit__c, Set<Id>> teamMembersToAddByVisit = new Map<dwp_kitv__Visit__c, Set<Id>>();
    Set<Id> teamMembersToAdd;
    for ( Account_Campaign__c ac : [ SELECT Id, OwnerId, User_id__c, participant_id__r.DES_Global_banker__c
                     FROM Account_Campaign__c
                     WHERE Id IN :visitsByAccountCampaignId.keySet()] ) {

      teamMembersToAdd = new Set<Id> { ac.OwnerId, ac.User_id__c };
      teamMembersToAdd.remove( null );
      // El equipo de la visita no puede incluir al global banker
//      teamMembersToAdd.removeAll( new Set<Id> { ac.participant_id__r.DES_Global_banker__c, null } );

      if ( !teamMembersToAdd.isEmpty() ) {
        teamMembersToAddByVisit.put( visitsByAccountCampaignId.get( ac.Id ), teamMembersToAdd);
      }

    }

    return teamMembersToAddByVisit;

  }
  ComentadasCampañasAlertasParaSubidaPosterior    */

  /*
	* @author Global Desktop
	* @Description checkNullError
	*/
  public static void checkNullError(List<dwp_kitv__Visit__c> triggerNew) {
    for(dwp_kitv__Visit__c visit : triggerNew) {
      if(visit.dwp_kitv__solution_name_path_desc__c != null && visit.dwp_kitv__solution_name_path_desc__c.contains(';null')) {
        visit.dwp_kitv__solution_name_path_desc__c = visit.dwp_kitv__solution_name_path_desc__c.replace(';null','');
      }
    }
  }

  /*
  * @author Global Desktop
  * @Description confidentialRecordType
  */
    public static void confidentialRecordType(List<dwp_kitv__Visit__c> triggerNew) {
       for(dwp_kitv__Visit__c visit : triggerNew) {
         // Si es confidencial se pone el record type de confidencial
         if(toConfidential(visit)) {
           visit.recordTypeId = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_VISIT_Account_Confidential_Visit).getRecordTypeId();
         } else if(toPublic(visit)) {
           visit.recordTypeId = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_VISIT_Account_Visit).getRecordTypeId();
         } else if(toInside(visit)) {
           visit.recordTypeId = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_Inside_Visit).getRecordTypeId();
         }
       }
     }

  /*
  * @author Global Desktop
  * @Description auxMethod confidential
  */
  private static boolean toConfidential(dwp_kitv__Visit__c visit) {
  	boolean confidential;
  	confidential = false;
  	if((visit.RecordTypeId == Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_VISIT_Account_Visit).getRecordTypeId()
		|| visit.RecordTypeId == Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_Inside_Visit).getRecordTypeId())
		&& visit.disclosure_info_type__c == Label.DES_OP_CONFIDENTIAL) {
		confidential = true;
	}
  	return confidential;
  }

  /*
  * @author Global Desktop
  * @Description auxMethod public
  */
  private static boolean toPublic(dwp_kitv__Visit__c visit) {
  	boolean notapplicable;
  	notapplicable = false;
  	if((visit.RecordTypeId == Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_VISIT_Account_Confidential_Visit).getRecordTypeId()
		|| visit.RecordTypeId == Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_Inside_Visit).getRecordTypeId())
		&& visit.disclosure_info_type__c == Label.DES_OP_NOT_APPLICABLE) {
		notapplicable = true;
	}
  	return notapplicable;
  }

  /*
  * @author Global Desktop
  * @Description auxMethod inside
  */
  private static boolean toInside(dwp_kitv__Visit__c visit) {
  	boolean inside;
  	inside = false;
  	if((visit.RecordTypeId == Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_VISIT_Account_Confidential_Visit).getRecordTypeId()
		|| visit.RecordTypeId == Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_VISIT_Account_Visit).getRecordTypeId())
		&& visit.disclosure_info_type__c == Label.DES_OP_Inside) {
		inside = true;
	}
  	return inside;
  }

  /*
  * @author Global Desktop
  * @Description createSharingVisitAccMembers
  */
  public void createSharingVisitAccMembers(List<dwp_kitv__Visit__c> triggerNew, Map<Id, String> mapAccMem, Map<Id, Id> mapClientGroup) {
    system.debug('>>>>> mapAccMem : ' + mapAccMem);
    system.debug('>>>>> mapClientGroup : ' + mapClientGroup);
    List<dwp_kitv__Visit__Share> listVisitSharing;
    listVisitSharing = new List<dwp_kitv__Visit__Share>();
    for(dwp_kitv__Visit__c visit : triggerNew) {
      if(visit.disclosure_info_type__c == Label.DES_OP_CONFIDENTIAL) {

        system.debug('>>>>> visit : ' + visit);
        system.debug('>>>>> mapAccMem.get(visit.dwp_kitv__account_id__c) : ' + mapAccMem.get(visit.dwp_kitv__account_id__c));
        //EQUIPO DEL CLIENTE DIRECTO
        listVisitSharing = fillDirectClient(mapAccMem,visit,listVisitSharing);

        system.debug('>>>>> mapClientGroup.get(visit.dwp_kitv__account_id__c) : ' + mapClientGroup.get(visit.dwp_kitv__account_id__c));
        //EQUIPO DEL GRUPO SI EXISTE
        listVisitSharing = fillGroupTeam(mapClientGroup,mapAccMem,visit,listVisitSharing);
      }
      system.debug('>>>>> listVisitSharing : ' + listVisitSharing);
      List<Database.SaveResult> listSR = Database.insert(listVisitSharing,false); //NOSONAR
    }
  }

  /*
  * @author Global Desktop
  * @Description fillDirectClient
  */
  private List<dwp_kitv__Visit__Share> fillDirectClient(Map<Id, String> mapAccMem, dwp_kitv__Visit__c visit, List<dwp_kitv__Visit__Share> listVisitSharing) {
    if(mapAccMem.get(visit.dwp_kitv__account_id__c) != null
    && mapAccMem.get(visit.dwp_kitv__account_id__c).contains(';')) {
      for(String userId : mapAccMem.get(visit.dwp_kitv__account_id__c).split(';')) {
        listVisitSharing.add(desUtils.newManualSharingVisit(visit.Id, userId, Label.LABS_SF_Edit));
      }
    } else {
      listVisitSharing.add(desUtils.newManualSharingVisit(visit.Id, mapAccMem.get(visit.dwp_kitv__account_id__c), Label.LABS_SF_Edit));
    }

    return listVisitSharing;
  }

  /*
  * @author Global Desktop
  * @Description fillGroupTeam
  */
  private List<dwp_kitv__Visit__Share> fillGroupTeam(Map<Id, Id> mapClientGroup, Map<Id, String> mapAccMem, dwp_kitv__Visit__c visit, List<dwp_kitv__Visit__Share> listVisitSharing) {
    if(mapClientGroup.get(visit.dwp_kitv__account_id__c) != null) {
      system.debug('>>>>> mapAccMem.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) : ' + mapAccMem.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)));
      if(mapAccMem.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) != null
      && mapAccMem.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)).contains(';')) {
        for(String userId : mapAccMem.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)).split(';')) {
          listVisitSharing.add(desUtils.newManualSharingVisit(visit.Id, userId, Label.LABS_SF_Edit));
        }
      } else {
        listVisitSharing.add(desUtils.newManualSharingVisit(visit.Id, mapAccMem.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)), Label.LABS_SF_Edit));
      }
    }

    return listVisitSharing;
  }


  /*
  * @author Global Desktop
  * @Description visitBeforeUpdate
  */
  public static void visitBeforeUpdate(List<dwp_kitv__Visit__c> triggerNew, List<dwp_kitv__Visit__c> triggerOld) {

    /*  ComentadasCampañasAlertasParaSubidaPosterior
    // Controlar si el usuario tiene permiso para vincular la visita a una campaña
    canBeRelatedToAccountCampaign( triggerNew, triggerOld );*/

    /*ComentadasCampañasAlertasParaSubidaPosterior*/
    dwp_kitv.Visit_Helper.updInvolves(triggerNew, triggerOld);
    dwp_kitv.Visit_Helper.completeRegion(triggerNew);
    //completeRegion(triggerNew);
  }

  /*
  * @author Global Desktop
  * @Description visitBeforeInsert
  */
  public static void visitBeforeInsert(List<dwp_kitv__Visit__c> triggerNew) {

    /*  ComentadasCampañasAlertasParaSubidaPosterior
    // Controlar si puede crear una visita relacionada con una campaña.
    canBeRelatedToAccountCampaign( triggerNew, null );*/

    /*ComentadasCampañasAlertasParaSubidaPosterior  */

    //completeRegion(triggerNew);
    autoCompleteCountry(triggerNew);
    //Relleno el set con el Id de las cuentas relacionadas
    for(dwp_kitv__Visit__c visit : triggerNew) {
      fillClientVisits(visit);
    }
    retrieveRelatedClients();

  }

  /*
  * @author Global Desktop
  * @Description checkVisitInbound
  */
  public static void checkVisitInbound(List<dwp_kitv__Visit__c> triggerNew) {
    final Map<Id, List<dwp_kitv__Visit__c>> mapAccVisit = new Map<Id, List<dwp_kitv__Visit__c>>();
    for(dwp_kitv__Visit__c iVisit : triggerNew) {
      if(mapAccVisit.containsKey(iVisit.dwp_kitv__account_id__c)) {
        final List<dwp_kitv__Visit__c> listVisit = mapAccVisit.get(iVisit.dwp_kitv__account_id__c);
        listVisit.add(iVisit);
        mapAccVisit.put(iVisit.dwp_kitv__account_id__c, listVisit);
      } else {
        mapAccVisit.put(iVisit.dwp_kitv__account_id__c, new List<dwp_kitv__Visit__c>{iVisit});
      }
    }

    for(Account iAccount : [SELECT Id,
                              DES_Country_Client__c,
                              group_management_country_id__c
                            FROM Account
                            WHERE Id IN :mapAccVisit.keySet()]) {
      if(iAccount.DES_Country_Client__c != iAccount.group_management_country_id__c) {
        for(dwp_kitv__Visit__c iVisit : mapAccVisit.get(iAccount.Id)) {
          iVisit.visit_type__c = 'Inbound';
        }
      }
    }
  }

	/*
  	* @author Global Desktop
  	* @Description method que completa el pais de la visita con el pais del cliente asociado en caso de que no venga informado
  	*/
	private static void autoCompleteCountry(List<dwp_kitv__Visit__c> triggerNew) {
		final List<String> countryValues = retrievePickListVisitValues();
		set<Id> accountsId;
    accountsId = new set<Id>();
		for(dwp_kitv__Visit__c vis : triggerNew) {
			accountsId.add(vis.dwp_kitv__account_id__c);
		}
		final Map<Id,Account> accList = new Map<Id,Account>([SELECT id, DES_Country_Client__c FROM Account WHERE Id IN :accountsId]);
		for(dwp_kitv__Visit__c vis2 : triggerNew) {
			if(vis2.dwp_kitv__account_id__c != null && vis2.dwp_kitv__country_name__c == null && countryValues.contains(accList.get(vis2.dwp_kitv__account_id__c).DES_Country_Client__c)) {
			vis2.dwp_kitv__country_name__c = accList.get(vis2.dwp_kitv__account_id__c).DES_Country_Client__c;
			}
		}
	}

	/*
  	* @author Global Desktop
  	* @Description Devuelve el nombre API de los valores de la picklist de pais del objeto visita.
  	*/
	private static List<String> retrievePickListVisitValues() {
    List<String> pckValues;
    pckValues= new List<String>();
		final Schema.DescribeFieldResult fieldResult = dwp_kitv__Visit__c.dwp_kitv__country_name__c.getDescribe();
		final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple) {
			pckValues.add(pickListVal.getValue());
		}
		return pckValues;
    }

  /**
   * Comprueba si una visita puede relacionarse a una Account Campaign
   *
   * @param triggerNew
   * @param triggerOld
   */
   /* ComentadasCampañasAlertasParaSubidaPosterior
  private void canBeRelatedToAccountCampaign( List<dwp_kitv__Visit__c> triggerNew, List<dwp_kitv__Visit__c> triggerOld ) {

        Boolean isInsert = triggerOld == null;
    if ( triggerNew.size() == 1 ) {

      dwp_kitv__Visit__c visitNew = triggerNew[0];
      dwp_kitv__Visit__c visitOld = triggerOld != null ?  triggerOld[0] : null;


      if ( visitNew.participant_campaign_id__c != null ) {

        // Si la visita no estaba anteriormente relacionada con una campaña
        if ( isInsert || visitOld.participant_campaign_id__c == null ) {

          Account_Campaign__c accountCampaign = [
              SELECT Id, OwnerId, User_id__c, participant_id__c, Campaign_status_approval_type__c
              FROM Account_Campaign__c
              WHERE Id = :visitNew.participant_campaign_id__c
          ];

          // Si la campaña está cerrada
          if ( accountCampaign.Campaign_status_approval_type__c == Label.DES_CLOSED ) {
            visitNew.addError('Sorry, you can not relate the visit to a closed Account Campaign.');
          // Si el usuario no tiene relación con la campaña
          } else if ( !AccountCampaignHelper.canEdit( accountCampaign ) ) {
            visitNew.addError('Sorry, you are not allowed to relate this visit to this campaign');
          }

        }

      }

    }

  }
  ComentadasCampañasAlertasParaSubidaPosterior  */


  /*
  * @author Global Desktop
  * @Description completeRegion
  */
  /*private static void completeRegion(List<dwp_kitv__Visit__c> triggerNew) {
    final List<Opp_Countries__mdt> regionCountry = [SELECT Label, DeveloperName, Opp_Region__c FROM Opp_Countries__mdt LIMIT 1000];
      map<String, String> countryRegion;
      countryRegion = new map<String, String>();
      for(Opp_Countries__mdt i : regionCountry) {
        countryRegion.put(i.DeveloperName, i.Opp_Region__c);
      }
      for(dwp_kitv__Visit__c v : triggerNew) {
        final String region = countryRegion.get(v.dwp_kitv__country_name__c);
        if(region != null) {
              v.region_name__c = region;
          }
      }
  }*/


  /*
  * @author Global Desktop
  * @Description visitAfterUpdate
  */
  public void visitAfterUpdate(Map<Id,dwp_kitv__Visit__c> mapNews, Map<Id,dwp_kitv__Visit__c> mapOlds, List<dwp_kitv__Visit__c> news) {
    Map<Id, dwp_kitv__Visit__c> mapVisitSharingRecalculate = new Map<Id, dwp_kitv__Visit__c>(); //NOSONAR
    system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Visit (after update)');

    /*    ComentadasCampañasAlertasParaSubidaPosterior
    // Si la visita se ha vinculado a una campaña (Account Campaign)
    isAccountCampaignRelatedOnUpdate( mapNews, mapOlds );
    ComentadasCampañasAlertasParaSubidaPosterior  */

    if (/*userSettings.CIB_Is_Desktop__c &&*/ !bypassSettings.CIB_DES_DataMigration__c) {
      Set<Id> setOldAccountsIds;
      system.debug(Logginglevel.INFO,'>>>>>>> Desktop User. Updating records to a DenormalizeVisits custom object...');
      DES_DenormalizeVisitsUtils doUtil;
      for (dwp_kitv__Visit__c vis : news) {
        fillClientVisits(vis);
        if (vis.dwp_kitv__account_id__c != mapOlds.get(vis.Id).dwp_kitv__account_id__c) { //NOSONAR
          doUtil = new DES_DenormalizeVisitsUtils();
          system.debug(Logginglevel.INFO,'>>>>>>> Desktop User. Updating records to a DenormalizeVisits custom object. Updating Visit AccountId: ' + vis.Id);
          SER_TriggerHelper.set_MetodFired('VisitDenorm_restoreUpdate', true);
          doUtil.restore(String.valueOf(vis.Id));
          //GUARDO LOS Id's de las cuentas antiguas
          setOldAccountsIds = new Set<Id>();
          if(!setOldAccountsIds.contains(mapOlds.get(vis.Id).dwp_kitv__account_id__c)) {
            setOldAccountsIds.add(mapOlds.get(vis.Id).dwp_kitv__account_id__c);
          }
          //Guardo la visita en una lista para recalcular las sharing settings de la visita
          mapVisitSharingRecalculate.put(vis.Id, vis);
        } else if (/*vis.dwp_kitv__account_id__c != null && */vis.dwp_kitv__visit_start_date__c != mapOlds.get(vis.Id).dwp_kitv__visit_start_date__c) {
          doUtil = new DES_DenormalizeVisitsUtils();
          system.debug(Logginglevel.INFO,'>>>>>>> Desktop User. Updating records to a DenormalizeVisits custom object. Updating Visit StartDate ' + vis.Id);
          doUtil.updateVisitStartDate(String.valueOf(vis.Id),vis.dwp_kitv__visit_start_date__c);
        }

        if(setIdVisits.isEmpty()) {
          fillIdVisits(vis);
        }
      }//FIN FOR
      retrieveRelatedClients();
      system.debug('>>>>> setOldAccountsIds :' + setOldAccountsIds);

      //Busco los sharing que están vinculados a las visitas que han cambiado de cliente
      final List<dwp_kitv__Visit__Share> listVisitSharing = new List<dwp_kitv__Visit__Share>([
        SELECT Id
        FROM dwp_kitv__Visit__Share
        WHERE RowCause = 'Manual'
        AND ParentId IN :mapVisitSharingRecalculate.keySet()
      ]);

      system.debug('>>>>> listVisitSharing :' + listVisitSharing);
      //delete listVisitSharing;
      Database.delete(listVisitSharing,false); //NOSONAR
      
      retrieveRelatedClients();
      //Vuelvo a dar manual Sharing a los miembros de las cuentas
      createSharingVisitAccMembers(mapVisitSharingRecalculate.values(), retrieveRelatedAccountMembers(), mapClientGroup);

      //Doy manual Sharing a los miembros de la visita
      manualSharingVisitMembers();
    }
    //timesExecuted ++;



  }//Fin afterUpdate


  /*
  * @author Global Desktop
  * @Description method que copia el valor de los campos de GM del usuario a los campos GM de la visita
  */
  public static void fillVisitGMFields(List<dwp_kitv__Visit__c> triggerNew) {
    final set<ID> userList = new set<ID>();
    for(dwp_kitv__Visit__c visit : triggerNew) {
      userList.add(visit.OwnerId);
    }
    final Map<ID,User> userMap = new Map<ID,User>([Select Id, Business_area_desc__c, Business_line_desc__c, coverage_country_name__c, solution_name_path_desc__c FROM User Where Id IN :userList]);
    for(dwp_kitv__Visit__c visit : triggerNew) {
      visit.Business_area_desc__c = userMap.get(visit.OwnerId).Business_area_desc__c;
      visit.Business_line_desc__c = userMap.get(visit.OwnerId).Business_line_desc__c;
      visit.coverage_country_name__c = userMap.get(visit.OwnerId).coverage_country_name__c;
      visit.solution_category_desc__c = userMap.get(visit.OwnerId).solution_name_path_desc__c;
    }

  }//Fin setVisitGMFields

  /*
  * @author Global Desktop
  * @Description manualSharingVisitMembers
  */
    public static void checkDeletePermission(List<dwp_kitv__Visit__c> triggerOld) {
        for (dwp_kitv__Visit__c visit : triggerOld) {
            if (visit.RecordTypeId == Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_Inside_Visit).getRecordTypeId() && !visit.remove_record_type__c) {
                visit.addError(Label.DES_IP_DELETE_VISIT);
            }
        }
    }

  /*
  * @author Global Desktop
  * @Description updateIPVisitCountry
  */
  /*public static void updateIPVisitCountry(List <dwp_kitv__Visit__c> triggerNew) {
        // FILTRAR POR RECORD TYPE ?
      //Variable que guarda los países de las visitas que tengo que borrar
        Map<Id, String> visitCountriesMap;
        visitCountriesMap = new Map<Id, String>();
        //Variable que guarda las oportuniades de los miembros que borro
        Set<Id> visitIdSet;
        visitIdSet = new Set<Id>();
        Set<Id> setUsersId;
        setUsersId = new Set<Id>();

        //Cojo los ids de los usuarios de los miembros de la visita y las oportunidades
        for(dwp_kitv__Visit__c visitAux : triggerNew) {
            if(!visitIdSet.contains(visitAux.Id)) {
                visitIdSet.add(visitAux.Id);
            }
            if(!setUsersId.contains(visitAux.OwnerId)) {
                setUsersId.add(visitAux.OwnerId);
            }
        }

        //Recojo los miembros de oportunidad de las visitas
        final List<dwp_kitv__Visit_Management_Team__c> visitTMList = new List<dwp_kitv__Visit_Management_Team__c>([
            SELECT Id, dwp_kitv__user_id__c, dwp_kitv__visit_id__c from dwp_kitv__Visit_Management_Team__c WHERE dwp_kitv__visit_id__c IN :visitIdSet]);

        //Meto en el set de ids de usuarios a los miembros de visita
        if(!visitTMList.isEmpty()) {
          for(dwp_kitv__Visit_Management_Team__c visitTMAux : visitTMList) {
            if(!setUsersId.contains(visitTMAux.dwp_kitv__user_id__c)) {
                setUsersId.add(visitTMAux.dwp_kitv__user_id__c);
            }
          }
        }

        //Recojo los usuarios de Salesforce para coger su país
        final Map<Id, User> mapUsers = new Map<Id, User>([SELECT Id, DES_Country__c FROM User WHERE Id IN :setUsersId]);

        //Construyo un mapa con los ids de las visitas y sus países - miembros de visita
        if(!visitTMList.isEmpty()) {
          for(dwp_kitv__Visit_Management_Team__c visitMember : visitTMList) {
              //Si ya tengo la visita, meto el país del miembro de la op
              if(visitCountriesMap.get(visitMember.dwp_kitv__visit_id__c) == null) {
                  //Meto nueva visita
                  visitCountriesMap.put(visitMember.dwp_kitv__visit_id__c, mapUsers.get(visitMember.dwp_kitv__user_id__c).DES_Country__c + ';');
              } else {
                String concat = visitCountriesMap.get(visitMember.dwp_kitv__visit_id__c);
                concat +=  mapUsers.get(visitMember.dwp_kitv__user_id__c).DES_Country__c + ';' ;
                visitCountriesMap.put(visitMember.dwp_kitv__visit_id__c, concat);
              }
          }
        }
        //Añado al mapa los ids de las visitas y sus países - owners
        for(dwp_kitv__Visit__c visitAux : triggerNew) {
            //Si ya tengo la visita, meto el país del miembro de la visita
            if(visitCountriesMap.get(visitAux.Id) == null) {
                //Meto nueva oportunidad
                visitCountriesMap.put(visitAux.Id, mapUsers.get(visitAux.OwnerId).DES_Country__c + ';');
            } else {
              String concat = visitCountriesMap.get(visitAux.Id);
              concat +=  mapUsers.get(visitAux.OwnerId).DES_Country__c + ';' ;
              visitCountriesMap.put(visitAux.Id, concat);
            }
        }

        //Pongo el país en las visitas
        for(dwp_kitv__Visit__c visit : triggerNew) {
            visit.visit_participate_country_desc__c = visitCountriesMap.get(visit.Id);
            System.debug('visit.visit_participate_country_desc__c: ' + visitCountriesMap.get(visit.Id));
        }

    }///FIN updateIPVisitCountry*/


    /*
  * @author Global Desktop
  * @Description Method que obtiene los id de los clientes de las visitas denormalizadas asociadas a la visita a borrar
  */
  public void idsRelatedAccounts(List<dwp_kitv__Visit__c> triggerOld) {
      final Map<Id, Integer> accountNumber = new Map<Id, Integer>();

      final Set<Id> visitsId = new Set<Id>();
      for (dwp_kitv__Visit__c visit : triggerOld) {
        if(!visitsId.contains(visit.Id)) {
          visitsId.add(visit.Id);
        }
      }

      final List<DES_Denorm_AccountVisits__c> mapDenormVisit = new List<DES_Denorm_AccountVisits__c>([
        SELECT Id, DES_Start_Date__c, DES_Client__c, DES_Visit_new__c
        FROM DES_Denorm_AccountVisits__c
        WHERE DES_Visit_new__c IN :visitsId
      ]);

      for (DES_Denorm_AccountVisits__c denorm : mapDenormVisit) {
        if(accountNumber.get(denorm.DES_Client__c) == null) {
          accountNumber.put(denorm.DES_Client__c, 1);
        } else {
          accountNumber.put(denorm.DES_Client__c, accountNumber.get(denorm.DES_Client__c) + 1);
        }
      }


      TotalAccountVisit.denVisitAfterAccountDelete(accountNumber);


  }

  /*
  * @author Global Desktop
  * @Description Met0d0 que añade al owner de la visita a los attendees
  */
  public static void ownerToTeamMgmt(List<dwp_kitv__Visit__c> newVisit) {
    //Map to set information of the custom setting records(account and lead custom settings)
    final Map<String, sObject> customSettingConf = VisitCustomSetting();
    Map<Id, dwp_kitv__Visit__c> ownersMap = new Map<Id, dwp_kitv__Visit__c>();    //NOSONAR

    final Id recordTypeIdAcc = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get('AccountVisit').getRecordTypeId();
    final Id recordTypeIdLead = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get('LeadVisit').getRecordTypeId();

    if(recordTypeIdAcc != null || recordTypeIdLead != null) {
      for(dwp_kitv__Visit__c visit : newVisit) {
        sObject cSSelected = customSettingConf.get('Account');
        if(visit.RecordTypeId == recordTypeIdLead) {
          cSSelected = customSettingConf.get('Lead');
        }
        if(cSSelected.get('dwp_kitv__User_Team_Member__c') == true && cSSelected.get('dwp_kitv__create_Owner_in_Team_management__c') == true) {
          //createTeamMgmt (visit.Id, visit.OwnerId);
          ownersMap.put(visit.Id, visit);
        }
      }
      createTeamMgmt(ownersMap);
    }
    System.debug(customSettingConf);
    System.debug(ownersMap);
  }

  /**
  * @description Method to set Account and Lead custom settings records
  * @return recordCustomSettings Map<String, sObject>
  **/
  private static Map<String, sObject> visitCustomSetting() {
    Map<String, sObject> recordCS = new Map<String, sObject>();         //NOSONAR
    recordCS.put('Account', dwp_kitv__Visit_validations_acc_cs__c.getValues(UserInfo.getProfileId()) == null ? dwp_kitv__Visit_validations_acc_cs__c.getOrgDefaults() : dwp_kitv__Visit_validations_acc_cs__c.getValues(UserInfo.getProfileId()));
    recordCS.put('Lead', dwp_kitv__Visit_validations_lead_cs__c.getValues(UserInfo.getProfileId()) == null ? dwp_kitv__Visit_validations_lead_cs__c.getOrgDefaults() : dwp_kitv__Visit_validations_lead_cs__c.getValues(UserInfo.getProfileId()));
    return recordCS;
  }

  /*
  * @author Global Desktop
  * @Description Met0d0 que crea el Management Team
  */
  private static void createTeamMgmt (Map<Id, dwp_kitv__Visit__c> visitMap) {
    List<dwp_kitv__Visit_Management_Team__c> newTeamMgmts = new List<dwp_kitv__Visit_Management_Team__c>();     //NOSONAR
    final Map<Id, User> ownerMap = getOwners(visitMap.values());
    for(Id visitId : visitMap.keySet()) {
      dwp_kitv__Visit_Management_Team__c teamMang = new dwp_kitv__Visit_Management_Team__c();     //NOSONAR
      teamMang.dwp_kitv__visit_id__c =visitId;
      teamMang.dwp_kitv__user_id__c = visitMap.get(visitId).OwnerId;
      teamMang.dwp_kitv__Owner_Visit__c = true;
      teamMang.dwp_kitv__gf_sf_external_cust_mail_desc__c = String.valueOf(ownerMap.get(visitMap.get(visitId).OwnerId).Email);
      teamMang.dwp_kitv__gf_sf_external_customer_id__c = String.valueOf(ownerMap.get(visitMap.get(visitId).OwnerId).FederationIdentifier);
      teamMang.dwp_kitv__gf_sf_external_customer_name__c = String.valueOf(ownerMap.get(visitMap.get(visitId).OwnerId).Name);
      newTeamMgmts.add(teamMang);
    }
    insert newTeamMgmts;
  }

  /*
  * @author Global Desktop
  * @Description Met0d0 que crea el mapa de owners
  */
  private static Map<Id, User> getOwners(List<dwp_kitv__Visit__c> visitList) {
    Set<Id> ownerIds = new Set<Id>();           //NOSONAR
    for(dwp_kitv__Visit__c visit : visitList) {
      ownerIds.add(visit.OwnerId);
    }
    return new Map<Id, User> ([SELECT Id, Email, FederationIdentifier, Name FROM User WHERE Id IN :ownerIds]);
  }

  /*
  * @author Global Desktop
  * @Description Method to get profile name from the current user
  */
  public static String gtProfileName() {
    return [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].get(0).Name;
  }
   /* 
	  * @Description Method que valida que solo el propietario de la visita pueda borrar la visita  
	  * @Author Pedro Antonio Lozano Rios pedroantonio.lozano@bbva.com
	  * @Date 27-05-25
	  * @Params List<dwp_kitv__Visit__c> triggerOld lista de visitas
	  * @return null
	  */ 
	    public static void checkOwnerDelete(List<dwp_kitv__Visit__c> triggerOld) {
      Final Id currentUserId = UserInfo.getUserId();
      Final User currentUser = [Select id,Name from User where id =:UserInfo.getUserId()];
      Final Set <String> profiPerm = new Set<string> {'System Administrator','Administrador del Sistema'};   
		  Final  String visitRcdType = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get('AccountVisit').getRecordTypeId();
		  for (dwp_kitv__Visit__c lstvisit : triggerOld) {
			  if (lstvisit.OwnerId != currentUserId && !profiPerm.contains(currentUser.Name)   && lstvisit.RecordTypeId == visitRcdType) {
				  lstvisit.addError('Only the owner of this record can delete this visit .');
			  }
		  }
	  }
}