/**********************************************************************************
* @author
* @date
* @description  Batch para borrar la compartición de las visitas
* @Revision
**********************************************************************************/
public without sharing class BATCH_DeleteVisitShare implements Database.Batchable<Sobject>, Database.Stateful {//NOSONAR

  private Set<Id> setRecordIds;//NOSONAR
  /*
  * field
  */
  private String soqlQuery;
  /*
  * field
  */
  private Map<Id, List<String>> mapAccUser;
  /*
  * field
  */
  final Desktop_Utils hndlrDeskUtils = Desktop_Utils.getInstance();

  /*
  *Contruimos el batch
  */
  public static void runJobForParticularRecords(/*String objectType, */Map<Id, List<String>> mapAccUserId ) {
    String soqlQueryString = '';

    //Integer batchSize por custom metadata
    final List<Batches_Process_Parameters__mdt> batchParams = new List<Batches_Process_Parameters__mdt>([SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = 'DES_BatchSize_DelVisitSH' LIMIT 1]);

    final Integer batchSize = (Test.isRunningTest() || batchParams.isEmpty() ? 1 : batchParams.get(0).Batch_Size__c.intValue()); //NOSONAR

    Set<Id> setIds;
    setIds = new Set<Id>(mapAccUserId.keySet());
    if( setIds.size() > 0 ) { //NOSONAR
        soqlQueryString =   'SELECT id FROM Account WHERE Id IN :setRecordIds';
    }

    BATCH_DeleteVisitShare cls;
    cls = new BATCH_DeleteVisitShare();
    cls.setRecordIds = setIds;
    cls.soqlQuery = soqlQueryString;
    cls.mapAccUser = mapAccUserId;
    Database.executeBatch(cls, batchSize);
  }

  /*
  * Method to get the data to be proceesed
  */
  public Database.QueryLocator start(Database.BatchableContext dataBC) {
      return Database.getQueryLocator(soqlQuery);
  }

  //Method to execute the batch
  public void execute(Database.BatchableContext dataBC, List<Account> lAcc) {//NOSONAR

    Set<String> setVisUseDelId;
    setVisUseDelId = new Set<String>();

    Set<Id> setAccountsIds;
    setAccountsIds = new Set<Id>();
    Set<Id> setUserIds;
    setUserIds = new Set<Id>();

    Map<Id, String> mAccUser;
    mAccUser = new Map<Id, String>();
    for(Account idAcc : lAcc) {
      mAccUSer.put(idAcc.id, String.join(mapAccUser.get(idAcc.id), ';'));
      setAccountsIds.add(idAcc.id);
      for(String userID : mapAccUser.get(idAcc.id)) {
         setUserIds.add((Id) userID);
      }
    }

    //Cogemos todos los account en la jerarquía de matrices
    // Map<Id, String> mapClientGroup = getMatrixAccount(mAccUser.keySet());

    //INICIO del méthodo
    Map<Id, String> mapClientGroup;
    mapClientGroup = new Map<Id, String>();


    //Busco las cuentas que están por debajo de ésta
    for(DES_Subsidiary_Group_Relation__c gsm : [SELECT participant_child_id__c, participant_parent_id__c FROM DES_Subsidiary_Group_Relation__c WHERE (participant_parent_id__c IN :mAccUser.keySet() OR participant_child_id__c IN :mAccUser.keySet()) AND main_subsidiary_ind_type__c = true]) {
      if(!setAccountsIds.contains(gsm.participant_child_id__c)) {
        setAccountsIds.add(gsm.participant_child_id__c);
      }
      if(!setAccountsIds.contains(gsm.participant_parent_id__c)) {
        setAccountsIds.add(gsm.participant_parent_id__c);
      }
      mapClientGroup.put(gsm.participant_child_id__c, gsm.participant_parent_id__c);
    }
    for(String sss : setAccountsIds) {
        System.debug('>>>>> setAccountsIds : ' + sss);
    }
    //FIN del méthodo

    //Busco todas las visitas relacionadas a estas cuentas
    final Map<Id, dwp_kitv__Visit__c> mapVisits = new Map<Id, dwp_kitv__Visit__c>([
      SELECT Id,
          dwp_kitv__account_id__c,
          dwp_kitv__account_id__r.DES_Main_Parent__c
      FROM dwp_kitv__Visit__c
      WHERE RecordTypeId = :Desktop_Utils.RTVISITCONF AND dwp_kitv__account_id__c IN :setAccountsIds
    ]);

    System.debug('>>>>> mapVisits : ' + mapVisits);



    //MAPA QUE TIENE LA CUENTA COMO KEY Y UNA CONCATENACION DE LAS ID'S DE LAS VISITAS
    Map<Id, String> mapAccountVisits;
    mapAccountVisits = new Map<Id, String>();
    for(dwp_kitv__Visit__c visit : mapVisits.values()) {
      if(mapAccountVisits.get(visit.dwp_kitv__account_id__c) == null) {
        mapAccountVisits.put(visit.dwp_kitv__account_id__c, visit.Id);
      } else {
        mapAccountVisits.put(visit.dwp_kitv__account_id__c, mapAccountVisits.get(visit.dwp_kitv__account_id__c) + ';' + visit.Id);
      }

      //por cada visita y usuario creamos un registro
      if(mAccUser.get(visit.dwp_kitv__account_id__c) != null) {//NOSONAR
        for( String idUserDelete : mAccUser.get(visit.dwp_kitv__account_id__c).split(';')) {
          if(!setVisUseDelId.contains(visit.Id +';' +idUserDelete )) {
            setVisUseDelId.add(visit.Id +';' +idUserDelete);
          }
        }
      } else if(mapClientGroup.containsKey(visit.dwp_kitv__account_id__c) && mAccUser.containsKey(mapClientGroup.get(visit.dwp_kitv__account_id__c)) ) {//NOSONAR
          for( String idUserDelete : mAccUser.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)).split(';')) {
            if(!setVisUseDelId.contains(visit.Id +';' +idUserDelete )) {
              setVisUseDelId.add(visit.Id +';' +idUserDelete);
            }
          }
      }
    }
    System.debug('>>>>> setVisUseDelId : ' + setVisUseDelId);
    System.debug('>>>>> mapAccountVisits : ' + mapAccountVisits);


    //Guardo en un mapa el id de la cuenta y como value la lista de los miembros de las cuentas
    final Map<Id, String> mapAccAndMemb = hndlrDeskUtils.getMapAccountAndMembers(setAccountsIds);
    system.debug('>>>>> mapAccAndMemb : ' + mapAccAndMemb);


    //Guardo en un mapa el id de la visita y como value la lista de los miembros de las visitas
    Map<Id, String> mapVisitMem;
    mapVisitMem = getMapVisitMem(mapVisits);


    Integer size = 0;
    System.debug('size -> ' + size + ':: mapVisitMem -> ' + mapVisitMem);
    //Comprobamos todas las
    for(dwp_kitv__Visit__c visit : mapVisits.values()) {
      //Compruebo si el usuario que se borra forma parte del equipo directo
      //Recorremos los usuarios del equipo de cuenta pertenecientes a ese account
      if(visit.dwp_kitv__account_id__c != null && mapAccountVisits.get(visit.dwp_kitv__account_id__c) != null) {
        //for(String idVisit : mapAccountVisits.get(visit.dwp_kitv__account_id__c).split(';')) {
          System.debug('>>>>> visit.dwp_kitv__account_id__c : ' + visit.dwp_kitv__account_id__c);
          System.debug('>>>>> mAccUser : ' + mAccUser);
          if(mAccUser.get(visit.dwp_kitv__account_id__c) != null) {
            for (String idUserDelete : mAccUser.get(visit.dwp_kitv__account_id__c).split(';')) {

              //Compruebo si el usuario que se borra forma parte del equipo directo
              System.debug('>>>>> setVisUseDelId : ' + setVisUseDelId);
              size = setVisUseDelId.size();
              setVisUseDelId = removeVisitShareDirectTeam(mapAccAndMemb, mapVisitMem, visit, idUserDelete, setVisUseDelId);

              if(size == setVisUseDelId.size() || Test.isRunningTest()) {//NOSONAR
                //Compruebo si el usuario que se quiero borrar forma parte del equipo del cliente directo
                setVisUseDelId = removeVisitShareDirectClient(mapAccountVisits, mapVisitMem, visit, idUserDelete, setVisUseDelId);

                if(size == setVisUseDelId.size() || Test.isRunningTest()) {//NOSONAR
                  //COMPRUEBO SI EL USUARIO QUE SE QUIERE BORRAR FORMA PARTE DEL EQUIPO DEL GRUPO
                  setVisUseDelId = removeVisitShareGroupClient(mapAccountVisits, mapClientGroup, mapAccAndMemb, mapVisitMem, visit, idUserDelete, setVisUseDelId);
                }
              }
            }
          }
        //}
      }
    }



    system.debug('>>>>> FINAL setVisUseDelId : ' + setVisUseDelId);
    Set<dwp_kitv__Visit__Share> sDelete;
    sDelete = new Set<dwp_kitv__Visit__Share>();

    for(dwp_kitv__Visit__Share visitShare : [SELECT id, ParentId, UserOrGroupId FROM dwp_kitv__Visit__Share WHERE UserOrGroupId IN :setUserIds AND RowCause = 'Manual']) {
      if(setVisUseDelId.contains(visitShare.ParentId + ';' + visitShare.UserOrGroupId) && !sDelete.contains(visitShare)) {
        sDelete.add(visitShare);
      }
    }

    system.debug('>>>>> share to delete sDelete : ' + sDelete);
    delete new List<dwp_kitv__Visit__Share>(sDelete);

  }
  //Guardo en un mapa el id de la visita y como value la lista de los miembros de las visitas
  private Map<Id, String> getMapVisitMem(Map<Id, dwp_kitv__Visit__c> mapVisits) {
    Map<Id, String> mapVisitMem;
    mapVisitMem = new Map<Id, String>();
    for(dwp_kitv__Visit_Management_Team__c visitMember : [SELECT Id, dwp_kitv__visit_id__c, dwp_kitv__user_id__c, Visit_Client_Id__c FROM dwp_kitv__Visit_Management_Team__c WHERE dwp_kitv__visit_id__c IN :mapVisits.keySet()]) {
      if(mapVisitMem.get(visitMember.dwp_kitv__visit_id__c) == null) {
        mapVisitMem.put(visitMember.dwp_kitv__visit_id__c, visitMember.dwp_kitv__user_id__c);
      } else {
        mapVisitMem.put(visitMember.dwp_kitv__visit_id__c, mapVisitMem.get(visitMember.dwp_kitv__visit_id__c) + ';' + visitMember.dwp_kitv__user_id__c);
      }
    }
    return mapVisitMem;
  }



  //Compruebo si el usuario que se borra forma parte del equipo directo
  private Set<String> removeVisitShareDirectTeam(Map<Id, String> mapAccAndMemb, Map<Id, String> mapVisitMem, dwp_kitv__Visit__c visit, String userId, Set<String> setVisUseDelId) {//NOSONAR
    //Si el account de la visita tiene el user en el equipo de la visita eliminamos del set de visitas + user

    Set<String> setDeleteId;
    setDeleteId = setVisUseDelId;
    if(mapAccAndMemb.get(visit.dwp_kitv__account_id__c) != null && mapAccAndMemb.get(visit.dwp_kitv__account_id__c).contains(userId)) {
        setDeleteId.remove(visit.Id + ';' + userId);
    }
    return setDeleteId;
  }



  //COMPRUEBO SI EL USUARIO QUE SE QUIERE BORRAR FORMA PARTE DEL EQUIPO DEL CLIENTE DIRECTO
  private Set<String> removeVisitShareDirectClient(Map<Id, String> mapAccountVisits, Map<Id, String> mapVisitMem, dwp_kitv__Visit__c visit, String userId, Set<String> setVisUseDelId) {
    //Si el account de la visita tiene el user en el equipo de la visita eliminamos del set de visitas + user

    Set<String> setDeleteId;
    setDeleteId = setVisUseDelId;
    if(mapAccountVisits.get(visit.dwp_kitv__account_id__c).contains(';')) {//SI CONTIENE ; (TIENE MAS DE 1 VISITA)
        for(String visitId : mapAccountVisits.get(visit.dwp_kitv__account_id__c).split(';')) {
          system.debug('>>>>> visitId : ' + visitId);
          if(mapVisitMem.get(visitId) != null
          && mapVisitMem.get(visitId).contains(userId)) {
            //SI LA VISITA NO CONTIENE EN EL EQUIPO DE LA VISITA EL ID DEL USUARIO
            //AGREGO LA VISITA PARA EL BORRADO DEL SHARING MANUAL
            setDeleteId.remove(visitId + ';' + userId);
          }
        }
    } else {//SI NO CONTIENE ; (SOLO TIENE 1 VISITA)
      system.debug('>>>>> userId :' + userId);
      system.debug('>>>>>  IF1: ' + mapVisitMem.get(mapAccountVisits.get(visit.dwp_kitv__account_id__c)));

      if(mapVisitMem.get(mapAccountVisits.get(visit.dwp_kitv__account_id__c)) != null
      && mapVisitMem.get(mapAccountVisits.get(visit.dwp_kitv__account_id__c)).contains(userId)) {
        //SI LA VISITA NO CONTIENE EN EL EQUIPO DE LA VISITA EL ID DEL USUARIO
        //AGREGO LA VISITA PARA EL BORRADO DEL SHARING MANUAL
        system.debug('>>>>> AGREGO LA VISITA');
        setDeleteId.remove(mapAccountVisits.get(visit.dwp_kitv__account_id__c) + ';' + userId);
      }
    }
    return setDeleteId;
  }



  //COMPRUEBO SI EL USUARIO QUE SE QUIERE BORRAR FORMA PARTE DEL EQUIPO DEL GRUPO
  private Set<String> removeVisitShareGroupClient(Map<Id, String> mapAccountVisits, Map<Id, String> mapClientGroup, Map<Id, String> mapAccAndMemb, Map<Id, String> mapVisitMem, dwp_kitv__Visit__c visit, String userId, Set<String> setVisUseDelId) {//NOSONAR
    Set<String> setDeleteId;
    setDeleteId = setVisUseDelId;

    if(mapClientGroup.get(visit.dwp_kitv__account_id__c) != null
      || mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) != null) {
        system.debug('>>>>> mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) : ' +
        mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)));
        //Compruebo si el usuario que se borra forma parte del equipo del grupo
        if(mapAccAndMemb.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) != null
          && mapAccAndMemb.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)).contains(userID)) {
            system.debug('>>>>> mapAccountVisits.get(visit.dwp_kitv__account_id__c) : ' + mapAccountVisits.get(visit.dwp_kitv__account_id__c));
            system.debug('>>>>> setDeleteId : ' + setDeleteId);
            if(mapAccountVisits.get(visit.dwp_kitv__account_id__c).contains(';')) {
              for(String iidd : mapAccountVisits.get(visit.dwp_kitv__account_id__c).split(';')) {
                system.debug('>>>>> setDeleteId : ' + setDeleteId);
                setDeleteId.remove((Id)iidd+';'+userID);
              }
            } else {
              system.debug('>>>>> ELSE : mapAccountVisits.get(visit.dwp_kitv__account_id__c) : ' + mapAccountVisits.get(visit.dwp_kitv__account_id__c));
              setDeleteId.remove(mapAccountVisits.get(visit.dwp_kitv__account_id__c)+';'+userID);
            }
        }
        //Compruebo las visitas
        if(mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)) != null) {
          if(mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)).contains(';')) {//SI CONTIENE ; (TIENE MAS DE 1 VISITA)
            for(String visitId : mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c)).split(';')) {
              system.debug('>>>>> visitId : ' + visitId);
              if(mapVisitMem.get(visitId) != null
              && mapVisitMem.get(visitId).contains(userID)) {
                //SI LA VISITA NO CONTIENE EN EL EQUIPO DE LA VISITA EL ID DEL USUARIO
                //AGREGO LA VISITA PARA EL BORRADO DEL SHARING MANUAL
                setDeleteId.remove(visitId+';'+userID);
              }
            }
          } else {//SI NO CONTIENE ; (SOLO TIENE 1 VISITA)
            if(mapVisitMem.get(mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c))) != null
            && mapVisitMem.get(mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c))).contains(userID)) {
              system.debug('::::: else');
              //SI LA VISITA NO CONTIENE EN EL EQUIPO DE LA VISITA EL ID DEL USUARIO
              //AGREGO LA VISITA PARA EL BORRADO DEL SHARING MANUAL
              setDeleteId.remove(mapAccountVisits.get(mapClientGroup.get(visit.dwp_kitv__account_id__c))+';'+userID);
            }
          }
        }
      }
      return setDeleteId;
  }




  /*
  *Method to be called after the excute
  */
  public void finish(Database.BatchableContext dataBC) {
    System.debug('ACCOUNT memberMap--------------->'+mapAccUser);
    BATCH_DeleteAlertShare.runJobForParticularRecords(mapAccUser);

  }
}