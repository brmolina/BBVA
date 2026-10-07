/*
* @author       Accenture
* @date         01/03/2016
* @description  Manejador del trigger para el objeto Opportunity. No implementar logica aquí, para ello utilizar ActivitiesUtils reupload
* @Revision
*/
/*
Version   Date            Author          Summary of changes
----------------------------------------------------------------------------------
0.2       2017/10/26      Accenture       Se deja de utilizar customActivity (Activity__c) y se comentan las líneas de código que ya no aplican
0.3       15/06/2018      Accenture       Se añade en el mét0d0 onAfterInsert y una comprobación para evitar que haga un bucle infinito
                                          cuando la Opp pertenece a un Lead (Prospect) en lugar de a una Account
0.4       19/06/2018      Accenture       modificado para que no denormalize las Opp Draft
0.5       27/06/2018      Accenture       modificado met0d0 onAfterUpdate para que si se cambia el accountId de una opp, se ejecute
                                          restore() y no borre la oportunidad a posteriori la clase DES_DenormAccountOppTriggerHandler
0.6       01/07/2018      Accenture       modificado met0d0 onAfterUpdate para que no de error al realizar restore() de una Opp
                                          de un Lead(Prospect) que no pertenece a Grupo (campo DES_Group__c)
0.7       2018/12/14      Accenture       Añadido mét0d0 "checkDeletePermission" con la lógica para evento before delete
0.8       2018/12/17      VASS            Si se modifica el campo del NBC asociado, se copian t0d0s los ficheros que tenga el
                                          template asociado a la opp al nbc vinculado.
0.9      22/03/2019      Accenture      Modificado el cálculo de cross border
1.0      03/09/2019      Accenture      Renombrado de métodos onAfterInsert/onAfterUpdate por los nombres más descriptivos
                                          denormOnAfterInsert/denormOnAfterUpdate respectivamente.
                                          Modificada la lógica de changeDraftToProp para que cambie el recordtype en las opp expiradas.
1.1      19/09/2019      Accenture      Se saca del metodo denormOnAfterUpdate la llamada al método moveFilesToNBC para que sea independiente.
1.2      27/09/2019      Accenture      Se elimina metodo innecesario "toggleScheduleNotification".
1.3      13/11/2019      Vass          Se añade el met0d0 updateTemplate.
1.4     20/11/2019      Vass          Se añade el met0d0 crearChatter.
1.5     21/04/2020      Vass          Se añade condicional en setManualPermissions que verifica si la opp es de cliente Venezolano (MAXMIX4-3425) y solo comparte a TB y GB del Grupo.
1.6      17/05/2020      JSS              Se añaden métodos con lógica para las oportunidades de la funcionalidad PRICING
**********************************************************************************/
public with sharing class OpportunityTriggerHandler {
    //LOGIC
        //private final ActivitiesUtils logic;
    /*Declarando variable*/
    private Integer timesExecuted = 0;
    /*Declarando variable*/
    private final CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
    /*Declarando variable*/
    private final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();
    /*Declarando variable*/
    private static List<Opportunity> lstOppUpdDrftPrp = new List<Opportunity>();
    /*Declarando variable*/
    private static Id oppIdWithSimilar;//Id de la oportunidad modificada a Proposal manualmente y con oportunidades similares.
    /*Declarando variable*/
    final Desktop_Utils handlerDsktpUtls = Desktop_Utils.getInstance();

    private OpportunityTriggerHandler() {
    }

    private static String getProfileName() {
    return TriggerCacheManager.getInstance().getCurrentUserProfileName();
}

    //SINGLETON PATTERN
    private static OpportunityTriggerHandler instance;
    public static OpportunityTriggerHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new OpportunityTriggerHandler();
        }
        return instance;
    }
    /*
     *  Method that is responsible for, if the NBC Comittee field has been modified, link the template files to the NBC
    **/
    public void moveFilesToNBC(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) {
      //Mapa que tendrá como key el id de la opp y como value el id del NBC asociado
      final Map<Id, Id> mapOppNBC = new Map<Id, Id>();
      for(Opportunity opp : triggerNewMap.values()) {
        if(opp.Committee_id__c != null
        && opp.Committee_id__c != triggerOldMap.get(opp.Id).Committee_id__c) {
          mapOppNBC.put(opp.Id, opp.Committee_id__c);
        }
      }

      if(!mapOppNBC.isEmpty()) {
        //Obtengo el mapa con los templates relacionados a cada opp
        final Map<Id, Id> mapTemplateOpp = getRelatedTemplates(mapOppNBC.keySet());
        if(!mapTemplateOpp.isEmpty()) {
          //I get the list of all associated documents
          final List<ContentDocumentLink> lstCntntDcLnk = getContentDocsLinks(mapTemplateOpp.keySet());
          final List<ContentDocumentLink> lstCnDcLnkToInsrt = new List<ContentDocumentLink>();
          //Recorro la lista de los documentos asociados, clono cada contentdocumentlink y los asocio al NBC correspondiente
          for(ContentDocumentLink cdl : lstCntntDcLnk) {
            final ContentDocumentLink cdl2 = cdl.clone(false, true);
            cdl2.LinkedEntityId = mapOppNBC.get(mapTemplateOpp.get(cdl.LinkedEntityId));
            lstCnDcLnkToInsrt.add(cdl2);
          }

          system.debug('>>>>> lstCnDcLnkToInsrt : ' + lstCnDcLnkToInsrt);
          if(!lstCnDcLnkToInsrt.isEmpty()) {
            try {
              insert lstCnDcLnkToInsrt;
            } catch(Exception e) {
              system.debug('>>>>> EXCEPTION : ' + e);
            }
          }
        }
      }
    }//FIN moveFilesToNBC


    /*
     *  Función que recoge los templates relacionados a cada oportunidad
    **/
    private Map<Id, Id> getRelatedTemplates(Set<Id> setOpps) { //NOSONAR
     final Map<Id, Id> mapTemplOpp = new Map<Id, Id>();
      for(DES_Template__c templ : [SELECT Id, opportunity_id__c FROM DES_Template__c WHERE opportunity_id__c IN :setOpps]) {
        mapTemplOpp.put(templ.Id, templ.opportunity_id__c);
      }
      return mapTemplOpp;
    } //FIN getRelatedTemplates

    /*
     *  Funcion que devuelve los documentos relacionados a los templates solo si tienen el campo 'Copy_to_NBC__c' a true
    **/
    private List<ContentDocumentLink> getContentDocsLinks(Set<Id> setTemplIds) { //NOSONAR
      return new List<ContentDocumentLink>([SELECT Id, LinkedEntityId, ContentDocumentId, ShareType, ContentDocument.LatestPublishedVersion.Copy_to_NBC__c
                                          FROM ContentDocumentLink WHERE LinkedEntityId IN :setTemplIds
                                          AND ContentDocument.LatestPublishedVersion.Copy_to_NBC__c = true]);
    }

    //EVENT HANDLER
/**
 * Event handler denormOnAfterInsert para lanzar la denormalización y las alertas comerciales
*/
   public void denormOnAfterInsert(final List<Opportunity> newList) {


        List <almd__Commercial_Alert__c> alertsToUpdate = new List <almd__Commercial_Alert__c>();
        final Set <Id> idAlertas = new Set<Id>();

        system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Opportunity (after create): ' + newList);

        if (/*userSettings.CIB_Is_Desktop__c  &&*/ !bypassSettings.CIB_DES_DataMigration__c) {
            system.debug(Logginglevel.INFO,'>>>>>>> Desktop User. Inserting records to a DenormalizeOpportunities custom object...');
            final GBL_DenormalizeOpportunitiesUtils doUtil = new GBL_DenormalizeOpportunitiesUtils(); //NOSONAR
            for (Opportunity opp : newList) {
                if (/*opp.AccountId != null  &&*/ opp.StageName != Label.DES_Draft) {
                    doUtil.denormalize(String.valueOf(opp.Id));
                }
                if(opp.almd__commercial_alert_id__c != null) {
                    idAlertas.add(opp.almd__commercial_alert_id__c);
                }
            }

        }
       if(!idAlertas.isEmpty()) {
           alertsToUpdate = [Select id from almd__Commercial_Alert__c where id in :idAlertas];
       }
       if(!alertsToUpdate.isEmpty()) {
           try {
               update alertsToUpdate;
           } catch(DMLException e) {
               system.debug('Valor de e: ' +e);
               newList.get(0).addError(label.DES_USER_CANNOT_EDIT_TASK_COMMERCIAL_ALERT);
           }
       }

       timesExecuted ++;
    }

    /**
   * @author Global Desktop
   */
  private Set<Id> getDirectClientIds(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) {
      Set<Id> setIdDirectClient = new Set<Id>();
      Boolean noExcluido = true;

      for(Opportunity opp : triggerNewMap.values()) {
        //Revisamos si la oportunidad es confidencial y tiene productos que impiden que se comparta con el euqipo de cobertura
        noExcluido = true;
        if(opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId() ||
           opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_SalesGM_Confidential_Opp).getRecordTypeId()) {
           final Set<String> setOppExc = obtainOppExc();
           noExcluido = checkOppExc(opp.Id,setOppExc);
        } else if(opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_opp).getRecordTypeId() ||
                  opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_GM_opp).getRecordTypeId()) {
           noExcluido = false;
        }
        setIdDirectClient = obtainAccounts(opp, triggerOldMap, noExcluido, setIdDirectClient );
      }
      return setIdDirectClient;
    }

    /**
   * @author Global Desktop
   */
    public void setManualPermissions(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) {
      //Set<Id> setIdOpp = new Set<Id>(); Unused local variable
      Set<Id> setIdDirectClient = new Set<Id>();
      Map<Id, Id> mapClientsGroups = new Map<Id, Id>();
      final Set<Id> setAllAccounts = new Set<Id>();
      Map<Id, String> mapAccAndMmbrs = new Map<Id, String>();
      Map<Id, List<DES_BBVA_Management_team__c>> mapAccAndMmbrsInfo = new Map<Id, List<DES_BBVA_Management_team__c>>();
      final List<OpportunityShare> lstMnlShrOpps = new List<OpportunityShare>();

      setIdDirectClient = getDirectClientIds(triggerNewMap, triggerOldMap);
      system.debug('>>>>> setIdDirectClient : ' + setIdDirectClient);

      mapClientsGroups = handlerDsktpUtls.getMapClientGroup(setIdDirectClient);
      system.debug('>>>>> mapClientsGroups : ' + mapClientsGroups);

      setAllAccounts.addAll(setIdDirectClient);
      setAllAccounts.addAll(mapClientsGroups.values());
      system.debug('>>>>> setAllAccounts : ' + setAllAccounts);

      mapAccAndMmbrs = handlerDsktpUtls.getMapAccountAndMembers(setAllAccounts);
      system.debug('>>>>> mapAccAndMmbrs : ' + mapAccAndMmbrs);
      system.debug('>>>>> lstOppUpdDrftPrp : ' + lstOppUpdDrftPrp);

      mapAccAndMmbrsInfo = handlerDsktpUtls.getMapAccountAndMembersInfo(setAllAccounts);
      system.debug('>>>>> mapAccAndMmbrsInfo : ' + mapAccAndMmbrsInfo);

      if(!lstOppUpdDrftPrp.isEmpty()){
          for(Opportunity opp : [SELECT AccountId, Account.DES_Country_Client__c FROM Opportunity Where Id IN: lstOppUpdDrftPrp]) {
            system.debug('>>>>> mapAccAndMmbrs.get(opp.AccountId) : ' + mapAccAndMmbrs.get(opp.AccountId));
            system.debug('>>>>> mapAccAndMmbrs.get(mapClientsGroups.get(opp.AccountId)) : ' + mapAccAndMmbrs.get(mapClientsGroups.get(opp.AccountId)));
            system.debug('>>>>> mapClientsGroups.get(opp.AccountId) : ' + mapClientsGroups.get(opp.AccountId));
            system.debug('>>>>> Country Client: ' + opp.Account.DES_Country_Client__c);
            //Doy permisos para el equipo de la cuenta directa

            if(opp.Account.DES_Country_Client__c != 'VE') {

              if(mapAccAndMmbrs.get(opp.AccountId) != null) {
                if(mapAccAndMmbrs.get(opp.AccountId).contains(';')) {
                  for(String userId : mapAccAndMmbrs.get(opp.AccountId).split(';')) {
                    lstMnlShrOpps.add(handlerDsktpUtls.newManualSharingOpportunity(opp.Id, userId, 'Edit'));
                  }
                } else {
                  lstMnlShrOpps.add(handlerDsktpUtls.newManualSharingOpportunity(opp.Id, mapAccAndMmbrs.get(opp.AccountId), 'Edit'));
                }
              }

              if(mapClientsGroups.get(opp.AccountId) != null
              && mapAccAndMmbrs.get(mapClientsGroups.get(opp.AccountId)) != null) {
                if(mapAccAndMmbrs.get(mapClientsGroups.get(opp.AccountId)).contains(';')) {
                  for(String userId : mapAccAndMmbrs.get(mapClientsGroups.get(opp.AccountId)).split(';')) {
                    lstMnlShrOpps.add(handlerDsktpUtls.newManualSharingOpportunity(opp.Id, userId, 'Edit'));
                  }
                } else {
                  system.debug('>>>>> DENTRO DEL ELSE BUENO');
                  lstMnlShrOpps.add(handlerDsktpUtls.newManualSharingOpportunity(opp.Id, mapAccAndMmbrs.get(mapClientsGroups.get(opp.AccountId)), 'Edit'));
                }
              }

            } else {
              System.debug('>>>>> Es oportunidad de Cliente venezolano');
              System.debug('>>>>> la validacion es ------> ' + mapAccAndMmbrsInfo.get(mapClientsGroups.get(opp.AccountId)));
              if(mapAccAndMmbrsInfo.get(mapClientsGroups.get(opp.AccountId)) != null) {
                for(DES_BBVA_Management_team__c team : mapAccAndMmbrsInfo.get(mapClientsGroups.get(opp.AccountId))) {
                  if(team.DES_Local_Banker_Country__c == 'VE' && team.DES_Member_Role__c == Label.DES_Role_Transactional_Banker) {
                    System.debug('>>>>> Se agrego el TB');
                    lstMnlShrOpps.add(handlerDsktpUtls.newManualSharingOpportunity(opp.Id, team.DES_User__c, 'Edit'));
                  } else if(team.DES_Member_Role__c == Label.DES_ROLE_GLOBAL_BANKER) {
                    System.debug('>>>>> Se agrego el GB');
                    lstMnlShrOpps.add(handlerDsktpUtls.newManualSharingOpportunity(opp.Id, team.DES_User__c, 'Edit'));
                  }
                }
              }
            }
          }
      }

      system.debug('>>>>> lstMnlShrOpps : ' + lstMnlShrOpps);
      final List<Database.SaveResult> listSR = Database.insert(lstMnlShrOpps,false);
      system.debug('>>>>> listSR buena : ' + listSR);
    }
    /**
   * Event handler before insert
   */
  public void beforeInsert(List<Opportunity> triggerNew) {
    completeRegion(triggerNew);
    Map<Id, SObject> newMap = new Map<Id, SObject>();
    for(Opportunity opp : triggerNew){
      newMap.put(opp.Id, (SObject)opp);
    }
    Utilities.checkIsMexico(newMap);
  }
  public void beforeUpdate(List<Opportunity> triggerNew) {
    completeRegion(triggerNew);
    Map<Id, SObject> newMap = new Map<Id, SObject>();
    for(Opportunity opp : triggerNew){
      newMap.put(opp.Id, (SObject)opp);
    }
    Utilities.checkIsMexico(newMap);
  }

 public void completeRegion(List<Opportunity> triggerNew) {
    // Usar caché en lugar de query
    Map<String, String> countryRegion = TriggerCacheManager.getInstance().getCountryToRegionMap();

    for (Opportunity o : triggerNew) {
        String region = countryRegion.get(o.DES_Booking_Geography__c);
        if (region != null) {
            o.region_name__c = region;
        }
    }
}


   /*   Event handler denormOnAfterUpdate para lanzar la denormalización en caso de ser necesario tras una modificación de la Opportunidad  */
    public void denormOnAfterUpdate (final List<Opportunity> newList, final Map<Id,Opportunity> oldMap, final Map<Id,Opportunity> triggerNewMap) {
      setManualPermissions(triggerNewMap, oldMap);
        system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Opportunity (after update): ' + newList);
        if (/*userSettings.CIB_Is_Desktop__c &&*/ !bypassSettings.CIB_DES_DataMigration__c && !System.isBatch()) {
            system.debug(Logginglevel.INFO,'>>>>>>> Desktop User. Updating records to a DenormalizeOpportunities custom object...');
//            final GBL_DenormalizeOpportunitiesUtils doUtil = new GBL_DenormalizeOpportunitiesUtils();

            final set<id> oppId = new set<id>();
            for (Opportunity opp : newList) {
                oppId.add(opp.Id);
            }
            final List<Opportunity> listOpp_OK = [Select Id, Substandard_Operation__c From Opportunity Where (id in :oppId) AND (StageName != :Label.DES_Draft) AND ((AccountId != null) OR (DES_Prospect__c != null AND DES_Prospect__r.DES_Group__c != null))];

            set<id> oppId_OK = new set<id>();
            for (Opportunity op : listOpp_OK) {
                oppId_OK.add(op.Id);
            }

            for (Opportunity opp : newList) {
                if ( (oppId_OK.contains(opp.Id)) && ((opp.AccountId != oldMap.get(opp.Id).AccountId /*&& opp.StageName != Label.DES_Draft*/) || (oldMap.get(opp.Id).StageName == Label.DES_Draft && opp.StageName != Label.DES_Draft))) {
                        system.debug('>>>>>>> llamando a dernomalización (future method): '+ opp.Name);
                        auxDenorm(opp.Id); //NOSONAR
                }
            }
        }
        timesExecuted ++;
    }
    /**
  * Aux future method to denorm
  */
    @future
    private static void auxDenorm(Id oppId) {
        final GBL_DenormalizeOpportunitiesUtils doUtil = new GBL_DenormalizeOpportunitiesUtils();
        SER_TriggerHelper.set_MetodFired('OpportunityDenorm_restoreUpdate', true);
        doUtil.restore(String.valueOf(oppId));
    }

    /**
   * Función que rellena el recordtype de la opp
   */
   public static void setOppRecordType(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) {
        for(Opportunity opp : triggerNewMap.values()) {
            if(changeDraftToProp(opp, triggerOldMap.get(opp.Id))) {
                system.debug(Logginglevel.INFO,'>>>>>>> setOppRecordType -> cambiando el recordtype de Draf a Business.');
                opp.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Business_Opportunity).getRecordTypeId();
            }
        }
    }

    private static Boolean changeDraftToProp(Opportunity oppNew, Opportunity oppOld) {
        return oppNew.StageName != Label.DES_Draft && oppOld.StageName == Label.DES_Draft
            && oppNew.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Draft_Opportunity).getRecordTypeId()
            && oppOld.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Draft_Opportunity).getRecordTypeId();
    }

    public static void checkIfSimilarOpp(List<Opportunity> triggerNew, Map<Id, Opportunity> triggerOldMap) {
        if(triggerNew.size() == 1 && !triggerNew.get(0).DES_Confirm_Duplicate_Message__c) {

            List<Opportunity> lstOppsSimilar = new List<Opportunity>();
             if (changeDraftToProp(triggerNew.get(0), triggerOldMap.get(triggerNew.get(0).Id))) {
                lstOppsSimilar = searchSimilarOpp(triggerNew.get(0));
            }
            system.debug('>>>>> listaOppsSimilares: ' + lstOppsSimilar);
            if(lstOppsSimilar != null && !lstOppsSimilar.isEmpty()) {
              String nmbrsOppsSimilar = '';
              Integer num = 0;
                system.debug('>>>>> listaOppsSimilares : ' + lstOppsSimilar);
                for(Opportunity oppSimilar : lstOppsSimilar) {
                    if(num < lstOppsSimilar.size()-1) {
                        nmbrsOppsSimilar += oppSimilar.Name + ', ';
                    } else {
                        nmbrsOppsSimilar += oppSimilar.Name + '.';
                    }
                    num++;
                }
                system.debug('>>>>> nombresOppsSimilares : ' + nmbrsOppsSimilar);
                for(Opportunity opp : triggerNew) {

                    if(opp.Id == oppIdWithSimilar) {
                        opp.addError(Label.CheckDuplicateOpp+ ' ' + nmbrsOppsSimilar);
                    }
                }
            }

        }

    }
    //List<Opportunity> listOppSimilar = new List<Opportunity>();
    private static List<Opportunity> searchSimilarOpp(Opportunity opp) {

        Map<Id, Opportunity> mapOppsSim = new Map<Id, Opportunity>();
        if(opp.AccountId != null) { //NOSONAR
            mapOppsSim = new Map<Id, Opportunity>([
                        SELECT  Id, //NOSONAR
                                AccountId,
                                DES_Prospect__c,
                                DES_Booking_Geography__c,
                                DES_Countries__c,
                                CurrencyIsoCode
                        FROM Opportunity
                        WHERE   AccountId = :opp.AccountId
                                AND DES_Booking_Geography__c = :opp.DES_Booking_Geography__c
                                AND DES_Countries__c = :opp.DES_Countries__c
                                AND CurrencyIsoCode = :opp.CurrencyIsoCode
                                AND StageName != :Label.DES_Draft
                                AND Id != :opp.Id


            ]);
        } else if(opp.DES_Prospect__c != null) {
            mapOppsSim = new Map<Id, Opportunity>([
                        SELECT  Id, //NOSONAR
                                AccountId,
                                DES_Prospect__c,
                                DES_Booking_Geography__c,
                                DES_Countries__c,
                                CurrencyIsoCode
                        FROM Opportunity
                        WHERE   DES_Prospect__c = :opp.DES_Prospect__c
                                AND DES_Booking_Geography__c = :opp.DES_Booking_Geography__c
                                AND DES_Countries__c = :opp.DES_Countries__c
                                AND CurrencyIsoCode = :opp.CurrencyIsoCode
                                AND StageName != :Label.DES_Draft
                                AND Id != :opp.Id


            ]);
        }

        system.debug('>>>>> mapOppsSim : ' + mapOppsSim);
        List<Opportunity> listOpp = new List<Opportunity>();
        if(!mapOppsSim.isEmpty()) {
            final List<OpportunityLineItem> lstPrdctsOppNew = new List<OpportunityLineItem>([
                        SELECT  Id,
                                Name,
                                Product2Id
                        FROM OpportunityLineItem
                        WHERE OpportunityId = :opp.Id
                        ORDER BY OpportunityId
            ]);
            system.debug('>>>>> listaProductsOppNew:' + lstPrdctsOppNew);
            String productsNewOpp = '';
            for(OpportunityLineItem opli : lstPrdctsOppNew) {
                productsNewOpp +=  opli.Product2Id + ',';
            }

            final List<OpportunityLineItem> lstPrdctsOppSim = new List<OpportunityLineItem>([
                        SELECT  Id,
                                Name,
                                Product2Id,
                                OpportunityId
                        FROM OpportunityLineItem
                        WHERE   OpportunityId IN :mapOppsSim.keySet()
                        ORDER BY OpportunityId
            ]);

            system.debug('>>>>> listaProductsOppsSim: ' + lstPrdctsOppSim);
            String productsSimOpp = '';
            Id previousOppId;
            final Set<Id> setIdOppsProdEqu;
            setIdOppsProdEqu = new Set<Id>();
            for(OpportunityLineItem opliSim : lstPrdctsOppSim) {
              if(previousOppId == null) {
                previousOppId = opliSim.OpportunityId;
              }
              system.debug('>>>>> previousOppId : ' + previousOppId);
              system.debug('>>>>> opliSim.OpportunityId : ' + opliSim.OpportunityId);
              if(opliSim.OpportunityId == previousOppId) {
                  productsSimOpp +=  opliSim.Product2Id + ',';
              } else {
                  productsSimOpp =  opliSim.Product2Id + ',';
              }
              system.debug('>>>>> productsNewOpp: ' + productsNewOpp + ' -- productsSimOpp: ' + productsSimOpp);
              if(productsNewOpp == productsSimOpp) {
                  setIdOppsProdEqu.add(opliSim.OpportunityId);
              }
              system.debug('>>>>> productsNewOpp : ' + productsNewOpp);

              previousOppId = opliSim.OpportunityId;
            }
            system.debug('>>>>> QUERY AA : ' + new List<Opportunity>([SELECT Id, Name FROM Opportunity WHERE Id IN :setIdOppsProdEqu]));
            if(!setIdOppsProdEqu.isEmpty()) {
              oppIdWithSimilar = opp.Id;
              listOpp = [SELECT Id, Name FROM Opportunity WHERE Id IN :setIdOppsProdEqu];
            }
        }
        return listOpp;
    }

    /*
    * @author Global Desktop
    * @Description Calcula el cross border de las oportunidades
    */
    public void calculateCrossBorder(List<Opportunity> inputOppList, Map<Id, Opportunity> oldMapValues) {
      Set<Id> accountIds = new Set<Id>();
      Set<Id> oppIds = new Set<Id>();

      for (Opportunity opportunity : inputOppList) {
          if (opportunity.AccountId != null) {
              accountIds.add(opportunity.AccountId);
              oppIds.add(opportunity.Id);
          }
      }

      if (accountIds.isEmpty()) {
          return;
      }

      // Obtener relaciones matriz-filial
      Map<Id, DES_Subsidiary_Group_Relation__c> matrixRelationMap = new Map<Id, DES_Subsidiary_Group_Relation__c>();
      for (DES_Subsidiary_Group_Relation__c matrix : [
          SELECT participant_parent_id__c, participant_child_id__c
          FROM DES_Subsidiary_Group_Relation__c
          WHERE participant_child_id__c IN :accountIds
          AND main_subsidiary_ind_type__c = true
      ]) {
          matrixRelationMap.put(matrix.participant_child_id__c, matrix);
          if (!accountIds.contains(matrix.participant_parent_id__c)) {
              accountIds.add(matrix.participant_parent_id__c);
          }
      }

      // Obtener cuentas
      Map<Id, Account> totalAccountsMap = new Map<Id, Account>([
          SELECT Id, RecordType.DeveloperName, DES_Tier__c, DES_Country_of_Management__c,
                DES_Country_Client__c, DES_Segment__c, DES_Entity_Hierarchy__c,
                DES_Client_Matrix__c, DES_Client_Matrix__r.DES_Country_Client__c
          FROM Account
          WHERE Id IN :accountIds
      ]);

      // Obtener productos de oportunidades
      List<OpportunityLineItem> oppProductList = [
          SELECT Id, OpportunityId, DES_Product_Family__c, solution_classification_desc__c, oppy_target_country_name__c
          FROM OpportunityLineItem
          WHERE OpportunityId IN :oppIds
      ];

      // USAR CACHÉ para países - AQUÍ ESTÁ LA OPTIMIZACIÓN PRINCIPAL
      TriggerCacheManager cache = TriggerCacheManager.getInstance();
      Set<String> setCountrySpecial = cache.getSpecialCountries();
      Set<String> setCountryEuropa = cache.getEuropeCountries();
      Set<String> setCountryAsia = cache.getAsiaCountries();

      for (Opportunity opp : inputOppList) {
          opp.DES_Cross_border__c = false;

          if (opp.AccountId == null) {
              continue;
          }

          if (matrixRelationMap.get(opp.AccountId) == null) {
              // No es filial
              String geografiaOrigen = getGeografiaOrigen(
                  totalAccountsMap.get(opp.AccountId),
                  false,
                  totalAccountsMap,
                  opp
              );
              getGeografiaDestinoGrupo(
                  oppProductList,
                  opp,
                  geografiaOrigen,
                  setCountryEuropa,
                  setCountryAsia
              );
          } else {
              // Es filial
              String geografiaOrigen = getGeografiaOrigen(
                  totalAccountsMap.get(matrixRelationMap.get(opp.AccountId).participant_child_id__c),
                  true,
                  totalAccountsMap,
                  opp
              );
              String geografiaDestino = totalAccountsMap.get(opp.AccountId).DES_Country_Client__c;

              if (setCountrySpecial.contains(geografiaDestino)) {
                  opp.DES_Cross_border__c = false;
              } else {
                  checkGOequalsGD(
                      geografiaOrigen,
                      geografiaDestino,
                      opp,
                      setCountryEuropa,
                      setCountryAsia
                  );
              }
          }
      }
  }


  /*
  * @author Global Desktop
  * @Description Calcula la geografia de origen para cross border
  */
    private static String getGeografiaOrigen(Account accToEvaluate, boolean isSubsidiary, Map<Id,Account> totalAccountsMap, Opportunity opp) {
      if (accToEvaluate == null) {
              return null;
          }

          String geografiaOrigen = null;
          String tier = accToEvaluate.DES_Tier__c;
          String segment = accToEvaluate.DES_Segment__c;

          if (tier == '00000020' || tier == '00000021' || tier == '00000022' || tier == '00000024') {
              if (segment == '00005' || segment == '00003') {
                  geografiaOrigen = accToEvaluate.DES_Country_of_Management__c;
              } else if (segment == '00001' || segment == '00002' || segment == '00006' || segment == '00004') {
                  geografiaOrigen = accToEvaluate.DES_Country_Client__c;
              }
          } else if (tier == '00000010' || tier == '00000025' || tier == '00000023' || tier == '00000000') {
              if (isSubsidiary) {
                  Account oppAccount = totalAccountsMap.get(opp.AccountId);
                  geografiaOrigen = oppAccount != null ? oppAccount.DES_Country_Client__c : null;
              } else {
                  Account oppAccount = totalAccountsMap.get(opp.AccountId);
                  geografiaOrigen = (oppAccount != null && oppAccount.DES_Client_Matrix__r != null)
                      ? oppAccount.DES_Client_Matrix__r.DES_Country_Client__c
                      : null;
              }
          }

          return geografiaOrigen;
      }


	/*
	* @author Global Desktop
	* @Description Calcula la geografia de destino para cross border de filiales
	*/
    private static String getGeografiaDestino(map<Id, Account> allAccountsMap, String accIdRelatedOpp) {
        return allAccountsMap.get(accIdRelatedOpp).DES_Country_Client__c;
    }

	/*
	* @author Global Desktop
	* @Description Calcula la geografia de destino para cross border de no filiales
	*/
    private static void getGeografiaDestinoGrupo(list<OpportunityLineItem> allProductsList, Opportunity opp, String geografiaOrigen, Set<String> europeCountries,Set<String> asiaCountries) {
        List<OpportunityLineItem> productOfOpp = new List<OpportunityLineItem>();
        for (OpportunityLineItem oppProduct : allProductsList) {
            if (oppProduct.OpportunityId == opp.Id) {
                productOfOpp.add(oppProduct);
            }
        }

        if (productOfOpp.isEmpty()) {
            opp.DES_Cross_border__c = false;
            return;
        }

        opp.DES_Cross_border__c = false;

        for (OpportunityLineItem oppItem : productOfOpp) {
            if (opp.DES_Cross_border__c) {
                break;
            }

            String family = oppItem.DES_Product_Family__c;
            String classification = oppItem.solution_classification_desc__c;

            if ((family == 'GTB' && classification == 'Client Resources') ||
                family == 'IBF' ||
                family == 'GM' ||
                classification == 'Equity Capital Markets') {

                checkGOequalsGD(
                    geografiaOrigen,
                    opp.DES_Booking_Geography__c,
                    opp,
                    europeCountries,
                    asiaCountries
                );
            } else if (classification == Label.DES_Product_Name_Mergers_Acquisitions) {
                checkGOequalsGD(
                    geografiaOrigen,
                    oppItem.oppy_target_country_name__c,
                    opp,
                    europeCountries,
                    asiaCountries
                );
            } else {
                opp.DES_Cross_border__c = false;
            }
        }
    }

    /*
    * @author Global Desktop
    * @Description Comprueba si la geografía de origen es igual a la de destino
    */
    public static void checkGOequalsGD(String geografiaOrigen, String geografiaDestino, Opportunity opp, Set<String> europeCountries, Set<String> asiaCountries) {
       if ((europeCountries.contains(geografiaOrigen) && europeCountries.contains(geografiaDestino)) ||
            (asiaCountries.contains(geografiaOrigen) && asiaCountries.contains(geografiaDestino))) {
            opp.DES_Cross_border__c = false;
          } else if (geografiaOrigen == geografiaDestino) {
              opp.DES_Cross_border__c = false;
          } else {
              opp.DES_Cross_border__c = true;
          }
      }


    /*
    * @author Global Desktop
    * @Description Asigna recordtype a la opp
    */
     public void confidentialRecordType(List<Opportunity> triggerNew) { //NOSONAR
      for(Opportunity opp : triggerNew) {

        if((opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Draft_Opportunity).getRecordTypeId()
        || opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Business_Opportunity).getRecordTypeId()
        || opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_opp).getRecordTypeId() )
        && opp.disclosure_info_type__c == Label.DES_OP_CONFIDENTIAL) {
          opp.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId();
            system.debug(Logginglevel.INFO,'>>>>>>> confidentialRecordType_1 -> cambiando el recordtype a ' + Label.DES_RT_ACC_Confidential_Opportunity);
        } else if((opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Draft_Opportunity).getRecordTypeId()
          || opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Business_Opportunity).getRecordTypeId()
          || opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId() )
          && opp.disclosure_info_type__c == Label.DES_OP_Inside) {
            opp.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_opp).getRecordTypeId();
            system.debug(Logginglevel.INFO,'>>>>>>> confidentialRecordType_2 -> cambiando el recordtype a ' + Label.DES_RT_Inside_opp);
        } else if(opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_SalesGM_Opportunity).getRecordTypeId() && opp.disclosure_info_type__c == Label.DES_OP_CONFIDENTIAL) {
          opp.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_SalesGM_Confidential_Opp).getRecordTypeId();
           system.debug(Logginglevel.INFO,'>>>>>>> confidentialRecordType_3 -> cambiando el recordtype a ' + Label.DES_RT_ACC_SalesGM_Confidential_Opp);
        } else if(opp.StageName == Label.DES_OPP_stage_draft &&
          ((opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId() && opp.disclosure_info_type__c != Label.DES_OP_CONFIDENTIAL ) ||
          (opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_opp).getRecordTypeId() && opp.disclosure_info_type__c != Label.DES_OP_Inside))) {
            opp.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Business_Opportunity).getRecordTypeId();
            system.debug(Logginglevel.INFO,'>>>>>>> confidentialRecordType_4 -> cambiando el recordtype a ' + Label.DES_RT_ACC_Business_Opportunity);
        } else if(opp.StageName != Label.DES_OPP_stage_draft &&
          ((opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId() && opp.disclosure_info_type__c != Label.DES_OP_CONFIDENTIAL ) ||
          (opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_opp).getRecordTypeId() && opp.disclosure_info_type__c != Label.DES_OP_Inside))) {
            opp.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Business_Opportunity).getRecordTypeId();
            system.debug(Logginglevel.INFO,'>>>>>>> confidentialRecordType_5 -> cambiando el recordtype a ' + Label.DES_RT_ACC_Business_Opportunity);
        } else if((opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_SalesGM_Confidential_Opp).getRecordTypeId() && opp.disclosure_info_type__c != Label.DES_OP_CONFIDENTIAL) ||
          (opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_GM_opp).getRecordTypeId() && opp.disclosure_info_type__c != Label.DES_OP_Inside)) {
            opp.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_SalesGM_Opportunity).getRecordTypeId();
            system.debug(Logginglevel.INFO,'>>>>>>> confidentialRecordType_6 -> cambiando el recordtype a ' + Label.DES_RT_ACC_SalesGM_Opportunity);
        } else if(opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_SalesGM_Opportunity).getRecordTypeId() && opp.disclosure_info_type__c == Label.DES_OP_Inside) {
            opp.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_GM_opp).getRecordTypeId();
             system.debug(Logginglevel.INFO,'>>>>>>> confidentialRecordType_7 -> cambiando el recordtype a ' + Label.DES_RT_Inside_GM_opp);
        }
      }
     }

    /*public static void showSimilarOppsFound(List<Opportunity> triggerNew, Map<Id, Opportunity> triggerOldMap) {
       //A ESTA FUNCION SE LE LLAMA DESDE EL AFTER, UNA VEZ SE HA MODIFICADO LA OPORTUNIDAD
        if(triggerNew.size() == 1) {
            system.debug('>>>>> triggerNew.get(0).Id : ' + triggerNew.get(0).Id);
            system.debug('>>>>> oppIdWithSimilar : ' + oppIdWithSimilar);
            //system.debug('>>>>> triggerNew.get(0).DES_SimilarOppsMessage__c : ' + triggerNew.get(0).DES_SimilarOppsMessage__c);
            //system.debug('>>>>> triggerOldMap.get(oppIdWithSimilar).DES_SimilarOppsMessage__c : '
            //  + triggerOldMap.get(oppIdWithSimilar).DES_SimilarOppsMessage__c);
            if(triggerNew.get(0).Id == oppIdWithSimilar && !triggerNew.get(0).DES_Confirm_Duplicate_Message__c)
                triggerNew.get(0).addError('You have Similar Opportunities');
        }
    }

  public void onAfterDelete(final List<Opportunity> oldList) {
        system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger Opportunity (after delete)');
        if (userSettings.CIB_Is_Desktop__c  && !bypassSettings.CIB_DES_DataMigration__c) {
            system.debug(Logginglevel.INFO,'>>>>>>> Desktop User. Deleting records of a DenormalizeOpportunities custom object...');

            AMHI.GBL_DenormalizeOpportunitiesUtils doUtil = new AMHI.GBL_DenormalizeOpportunitiesUtils();
            for (Opportunity opp : oldList) {
                doUtil.clear(String.valueOf(opp.Id));

            }

        }
        timesExecuted ++;
    }

  ComentadasCampañasAlertasParaSubidaPosterior
    public void closeAccountCampaign(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) {

      System.debug('entro en closeAccountCampaign');
      Set<Id> accCampaignToCloseSet = new Set<Id>();
      Set<Id> accCampaignToPendingApprovalSet = new Set<Id>();
      // ids de campañas en un set
      Set<Id> accCampaignAllSet = new Set<Id>();
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
      for(Opportunity opp : triggerNewMap.values()) {
        accCampaignAllSet.add(opp.participant_campaign_id__c);
      }
      // query en mapa
      map<Id,Account_Campaign__c> accCampaignAllMap = new map<Id,Account_Campaign__c>([
          SELECT id, campaign_authorizer_user_id__c FROM Account_Campaign__c
              WHERE id IN: accCampaignAllSet
            ]);

      for(Opportunity opp : triggerNewMap.values()) {
        // Si el new tiene el estado DES_Closed_Won y el old no
        if(opp.StageName == Label.DES_Closed_Won && triggerOldMap.get(opp.Id).StageName == Label.DES_Ready_to_close) {
          System.debug('el nuevo es won y el viejo es ready to close');
          // miro si participant_campaign_id__c está relleno
          if(opp.participant_campaign_id__c != null) {
            System.debug('opp.participant_campaign_id__c != null');
            // miro si campaign_authorizer_user_id__c está relleno
            if(accCampaignAllMap.get(opp.participant_campaign_id__c).campaign_authorizer_user_id__c == null) {
              System.debug('account campaign: ' + opp.participant_campaign_id__c);
              System.debug('estado de la account Campaign: ' + opp.participant_campaign_id__r.Campaign_status_approval_type__c);
              accCampaignToCloseSet.add(opp.participant_campaign_id__c);
              //opp.participant_campaign_id__r.Campaign_status_approval_type__c = 'Closed';
              //opp.participant_campaign_id__r.sub_status_type__c = 'Won';
            } else {
              accCampaignToPendingApprovalSet.add(opp.participant_campaign_id__c);
              //opp.participant_campaign_id__r.Campaign_status_approval_type__c = 'Pending Approval';
              // lanzo el approval process
                //Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(opp.participant_campaign_id__c);
                req.setProcessDefinitionNameOrId('Account_Campaign_Approval_Process_Won');
                //Approval.ProcessResult result =  Approval.process(req);
            }
          }
        }
        }
        System.debug('accCampaignToCloseSet: ' + accCampaignToCloseSet);
        System.debug('accCampaignToPendingApprovalSet: ' + accCampaignToPendingApprovalSet);

        // obtengo las account campaign a las que les tengo que actualizar el estado
        List<Account_Campaign__c> accCampaignToCloseList = new List<Account_Campaign__c>(
          [SELECT id, Campaign_status_approval_type__c, sub_status_type__c
                FROM Account_Campaign__c
                      WHERE id IN: accCampaignToCloseSet]
      );
      List<Account_Campaign__c> accCampaignToPendingApprovalList = new List<Account_Campaign__c>(
          [SELECT id, Campaign_status_approval_type__c, sub_status_type__c
                FROM Account_Campaign__c
                      WHERE id IN: accCampaignToPendingApprovalSet]
      );
      System.debug('accCampaignToCloseList: ' + accCampaignToCloseList);
        System.debug('accCampaignToPendingApprovalList: ' + accCampaignToPendingApprovalList);
        for(Account_Campaign__c accCampCloseAux : accCampaignToCloseList) {
          accCampCloseAux.Campaign_status_approval_type__c = 'Closed';
          accCampCloseAux.sub_status_type__c = 'Won';
        }
      for(Account_Campaign__c accCampPendingApprovalAux : accCampaignToPendingApprovalList) {
          accCampPendingApprovalAux.Campaign_status_approval_type__c = 'Pending Approval';
        }
      update accCampaignToCloseList;
      update accCampaignToPendingApprovalList;
        if(req.getObjectId()!=null) {
      Approval.ProcessResult result = Approval.process(req);
        }
        System.debug('req: '+ req.getObjectId());
    }//FIN closeAccountCampaign

    ComentadasCampañasAlertasParaSubidaPosterior    */

  /******************************************************************************
  *@author: GlobalDesktop
  *@Method: needTemplate
  *@Description: Show an error when users move to Approval if the opportunity does not have an approved template.
  *@Params: list<Opportunity> trigger.new, map<id,Opportunity> oldmap - before update
  *@Returns: void
  *@Versions:
    v1 - 23/01/2019 - Initial version
  ******************************************************************************/
    public void needTemplate(list<Opportunity> inputList, map<id, Opportunity> oldValuesList) {

        Set<id> oppIds;
        oppIds = new Set<id>();
        for(Opportunity  opp : inputList) {
            oppIds.add(opp.Id);
        }
        ComponentNBC_Controller.setMapCountryRegion();
        ComponentNBC_Controller.getTemplateConfigurationsList();

        final Map <Id, Opportunity> mOpps = new Map<Id, Opportunity>( [SELECT id, (SELECT id, solution_classification_desc__c, bbva_prtcp_tranche_amount__c, deal_total_amount__c, Converted_Currency__c, product_scope_type__c FROM OpportunityLineItems), (SELECT id, Template_approved_type__c FROM Templates__r), Substandard_Operation__c FROM Opportunity WHERE Id IN :oppIds]);
        system.debug('mOpps : ' + mOpps);
        for(Opportunity opp : inputList) {
          if(isNotIPOpp(opp) && opp.StageName == LABEL.DES_Approvals
            && oldValuesList.get(opp.id).StageName!= opp.StageName && oldValuesList.get(opp.id).StageName!= null) {

            for(OpportunityLineItem oppLine : mOpps.get(opp.id).OpportunityLineItems) {
              opp = needTemplateValidation(mOpps, opp, oppLine);
            }
          }
        }

    }

    private Opportunity needTemplateValidation( Map <ID, Opportunity> mOpps, Opportunity opp, OpportunityLineItem oppLine) {
      final Opportunity oppValidate = opp;
      if(isProductTemplate(oppLine) && (ComponentNBC_Controller.getTemplateId(oppLine.solution_classification_desc__c,ComponentNBC_Controller.mapCountryRegion.get(opp.DES_Booking_Geography__c), oppLine.Converted_Currency__c,
                                                                                oppLine.product_scope_type__c,opp.Substandard_Operation__c) != null //NOSONAR
      && (mOpps.get(opp.id).Templates__r.size() == 0 || !mOpps.get(opp.id).Templates__r[0].Template_approved_type__c))) { //NOSONAR
        system.debug(Logginglevel.INFO,'>>>>>>> Entrando needTemplate error' +  oppLine.solution_classification_desc__c);
        oppValidate.addError(LABEL.DES_Need_Template);

        }
      return oppvalidate;
    }

    private Boolean isNotIPOpp(Opportunity opp) { //NOSONAR
      Boolean check = false;
      if(opp.recordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_GM_opp).getRecordTypeId() &&
          opp.recordTypeId != Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_opp).getRecordTypeId()) {
        check = true;
      }
      return check;
    }

    private Boolean isProductTemplate(OpportunityLineItem oppLine) { //NOSONAR
      Boolean check = false;
      if(LABEL.DES_Corporate_Loans == oppLine.solution_classification_desc__c || LABEL.DES_Leverage_Buyout_LBOs == oppLine.solution_classification_desc__c ||
                LABEL.DES_Structure_Trade_Finance == oppLine.solution_classification_desc__c || LABEL.DES_Transaction_Trade_Finance == oppLine.solution_classification_desc__c ||
                LABEL.DES_Project_Finance_Lending == oppLine.solution_classification_desc__c || LABEL.DES_Working_Capital == oppLine.solution_classification_desc__c) {
    		check = true;
    	}

    	return check;
    }

    public void checkDeletePermission(final List<Opportunity> oldList) {
      // Usar caché para profile name
      String profileName = TriggerCacheManager.getInstance().getCurrentUserProfileName();

      List<PermissionSetAssignment> psaList = [
          SELECT Id, AssigneeId
          FROM PermissionSetAssignment
          WHERE AssigneeId = :UserInfo.getUserId()
          AND PermissionSet.Name = 'Champions_Locales'
      ];

      Set<Id> userIds = new Set<Id>();
      for (PermissionSetAssignment psa : psaList) {
          userIds.add(psa.AssigneeId);
      }

      if (profileName == Label.DES_ADMIN_PROFILE) {
          userIds.add(UserInfo.getUserId());
      }

      for (Opportunity opp : oldList) {
          if (checkIfRTisIP(opp) && !opp.remove_record_type__c &&
              !(userSettings.CIB_Is_Admin__c || bypassSettings.CIB_DES_Delete_Opp_Permission__c)) {
              opp.addError(Label.DES_IP_DELETE_OPP);
          } else if (opp.StageName != Label.DES_OPP_stage_draft &&
                    !(userSettings.CIB_Is_Admin__c || bypassSettings.CIB_DES_Delete_Opp_Permission__c)) {
              if (userIds.isEmpty()) {
                  opp.addError(Label.DES_USER_CANNOT_DELETE_OPP);
              }
          }
      }
  }


    /**
    *
    *
    *
    */
    private Boolean checkIfRTisIP(Opportunity opp) { //NOSONAR
       return opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_opp).getRecordTypeId()
       || opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_GM_opp).getRecordTypeId();
    }

    /*
  *
  *  @author Global Desktop  - DSL
  *  @Description  - Method que se encarga de actualizar la expected probability de una oportunidad
  *                  al cambiar el subestado
  *
  **/

  public static void updateProbability(List<Opportunity> triggerNew, Map<Id, Opportunity> triggerOldMap) {
      // Usar caché para verificar si está habilitado
      TriggerCacheManager cache = TriggerCacheManager.getInstance();

      if (!cache.isAutoExpectedProbabilityEnabled()) {
          return;
      }

      // Usar caché para obtener el mapa de probabilidades
      Map<String, Decimal> mapStgExpProb = cache.getStageToExpectedProbabilityMap();

      if (mapStgExpProb.isEmpty()) {
          return;
      }

      for (Opportunity opp : triggerNew) {
          if (triggerOldMap == null || opp.StageName != triggerOldMap.get(opp.Id).StageName) {
              Decimal expectedProb = mapStgExpProb.get(opp.StageName.toUpperCase());
              if (expectedProb != null) {
                  opp.DES_Expected_Probability__c = expectedProb;
              }
          }
      }
}

  //FIN UPDATE PROBABILITY

  /*
   *  @author Global Desktop  - DSL
   *  @Description    - Función que se encarga de devolver un mapa con el par <'Stage','ExpectedProb'>, sacando esta información
   *                    del objeto 'Opportunity_Expected_Probability__mdt'
   *
  **/
  private static Map<String, Decimal> gtExpecProbMTD() {
    Map<String, Decimal> mapStgExpProb;
    mapStgExpProb = new Map<String, Decimal>();
    for(Opportunity_Expected_Probability__mdt oppExpProb : [SELECT Id, Opportunity_Stage_Name__c, Expected_Probability__c
                                                            FROM Opportunity_Expected_Probability__mdt LIMIT 5000]) {
      mapStgExpProb.put(oppExpProb.Opportunity_Stage_Name__c.toUpperCase(), oppExpProb.Expected_Probability__c);
    }
    return mapStgExpProb;
  }

  /*
   *  @author Global Desktop  - DSL
   *  @Description  - Devuelvo true si está habilitada la opción de Expected Probability dinámica
   *
  **/
  private static Boolean checkExpecProb() {
    final Global_Desktop_Settings__c gdSettings = Global_Desktop_Settings__c.getInstance();
    system.debug('>>>>> gdSettings : ' + gdSettings);
    system.debug('>>>>> gdSettings.Opportunity_Auto_Expected_Probability__c : ' + gdSettings.Opportunity_Auto_Expected_Probability__c);
    return gdSettings.Opportunity_Auto_Expected_Probability__c;
  }

  /**
   * Si el usuario no checkea que ha confiramdo la oportunidad, no podrá cerrarla
   *
   * @param triggerNewMap
   * @param triggerOldMap
   */
  public static void checkConfirmData(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) {

    for (Id oppId : triggerNewMap.keySet()) {

      final Boolean toCloseWon = (triggerNewMap.get( oppId ).StageName == Label.DES_Closed_Won
               || triggerNewMap.get( oppId ).StageName == Label.DES_Closed_Lose);
      final Boolean isNotConfirm = triggerNewMap.get( oppId ).opportunity_correct_ind_type__c == false;

      if ( toCloseWon && isNotConfirm && triggerOldMap.get(oppId).StageName != triggerNewMap.get(oppId).StageName) {
        triggerNewMap.get( oppId ).addError( Label.DES_ERROR_OPP_CONFIRM_DATA );
      }

    }
  }

	private static Set<String> obtainOppExc() {
		final Set<String> values = new Set<String>();
		for(Opp_excluded__mdt oppExc : [SELECT Id, Label from Opp_excluded__mdt LIMIT 100]) {
            values.add(oppExc.Label);
        }
    return values;
  }

  private static Boolean checkOppExc(Id oppid, Set<String> setOppExc) { //NOSONAR
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

  private Set<Id> obtainAccounts(Opportunity opp, Map<Id, Opportunity> triggerOldMap, Boolean noExcluido, Set<Id> setIdDC) {
    Set<Id> setIdDirectClient = setIdDC;
    //Si antes era DRAFT y ahora es PROPOSAL y no tiene productos excluidos
        setIdDirectClient = checkDraftProposal(opp, triggerOldMap, noExcluido, setIdDirectClient);
      //Si tiene productos excluidos al cerrar la oportunidad se comparte con le euqipo de cobertura
        setIdDirectClient = checkClose(opp, triggerOldMap, noExcluido, setIdDirectClient);
    return setIdDirectClient;
  }

  private Set<Id> checkAccountExists(Opportunity opp,  Set<Id> setIdDirectClient) { //NOSONAR
    if(!setIdDirectClient.contains(opp.AccountId)) {
              setIdDirectClient.add(opp.AccountId);
      }
      System.debug('>>>>>>>> Opp añadida al lstOppUpdDrftPrp' + opp);
      lstOppUpdDrftPrp.add(opp);
    return setIdDirectClient;
  }

  private Set<Id> checkDraftProposal(Opportunity opp, Map<Id, Opportunity> triggerOldMap, Boolean noExcluido, Set<Id> setIdDC) {
    Set<Id> setIdDirectClient = setIdDC;
    if(noExcluido && ((triggerOldMap == null && opp.StageName == Label.DES_Proposal)
           || (opp.StageName == Label.DES_Proposal && triggerOldMap.get(opp.Id).StageName == Label.DES_Draft))) {
            //Se asigna permisos a los miembros del cliente directo y del grupo de la matriz
            //Asigno permisos a los miembros del cliente directo
            setIdDirectClient = checkAccountExists(opp,setIdDirectClient);
           //Si tiene productos excluidos al cerrar la oportunidad se comparte con le euqipo de cobertura
        }
        return setIdDirectClient;
  }

  private Set<Id> checkClose(Opportunity opp, Map<Id, Opportunity> triggerOldMap, Boolean noExcluido, Set<Id> setIdDC) {
    Set<Id> setIdDirectClient = setIdDC;
    if(!noExcluido && (triggerOldMap == null || triggerOldMap.get(opp.Id).StageName == Label.DES_Ready_to_close)
         && (opp.StageName == Label.DES_Closed_Lose   || opp.StageName == Label.DES_Closed_Won)) {
            //Se asigna permisos a los miembros del cliente directo y del grupo de la matriz
            //Asigno permisos a los miembros del cliente directo
            setIdDirectClient = checkAccountExists(opp,setIdDirectClient);
           //Si tiene productos excluidos al cerrar la oportunidad se comparte con le euqipo de cobertura
        }
        return setIdDirectClient;
  }

  /******************************************************************************
  * @Author:      David Rodriguez
  * @Method:      completeNBCFinallyBook
  * @Return:
  * @Paramerers:  triggerNew lista de opps
  * @Description: completa el campo NBC Finally Booking en funcion de Booking y portfolio
  ***********************************************************************************/
    public static void completeNBCFinallyBook(List <Opportunity> triggerNew, Map<Id, Opportunity> mapOld) {
      final List<String> emeaCountries = new List<String>{'PT', 'ID', 'ES', 'IN', 'GB', 'TW', 'JP', 'BE', 'SG', 'FR', 'IT', 'DE','HK'}; //NOSONAR
      for(Opportunity opp : triggerNew) {
        if(mapOld == null || opp.DES_Booking_Geography__c != mapOld.get(opp.Id).DES_Booking_Geography__c || opp.gf_opportunity_nbc_name__c != mapOld.get(opp.Id).gf_opportunity_nbc_name__c) {
          if(emeaCountries.contains(opp.DES_Booking_Geography__c)) {
            opp.DES_NBC_Region__c = 'EMEA';
          } else if(checkLatam(opp)) {
            opp.DES_NBC_Region__c = 'LATAM';
          } else if (checkUsa(opp)) {
            opp.DES_NBC_Region__c = 'USA';
          }
        }
      }
    }

    /*
    * Aux Method
    */
    private static Boolean checkUsa(Opportunity opp) {
        boolean usa;
        usa = false;
        if (opp.DES_Booking_Geography__c == 'Compass' || (opp.DES_Booking_Geography__c == 'NY' && (opp.gf_opportunity_nbc_name__c == 'USA' || opp.gf_opportunity_nbc_name__c == null))) {
            usa = true;
        }
        return usa;
    }

    /*
    * Aux Method
    */
    private static Boolean checkLatam(Opportunity opp) {
        final List<String> latamCountries = new List<String>{'UY', 'AR', 'PE', 'MX', 'VE', 'CO', 'CL'}; //NOSONAR
        boolean latam;
        latam = false;
        if (latamCountries.contains(opp.DES_Booking_Geography__c) || (opp.DES_Booking_Geography__c == 'NY' && opp.gf_opportunity_nbc_name__c == 'LATAM')) {
            latam = true;
        }
        return latam;
    }


  /******************************************************************************
  * @Author:      David Rodriguez
  * @Method:      completeBookTemplate
  * @Return:
  * @Paramerers:  triggerNew lista de opps
  * @Description: completa el campo Booking del template si cambia el booking geography
  ***********************************************************************************/
    public static void completeBookTemplate(List <Opportunity> triggerNew, Map<Id, Opportunity> mapOld) {
      final Set<Id> oppsIds = new Set<Id>();
      final List <DES_Template__c> templUpdate = new List <DES_Template__c>();

      for(Opportunity opp : triggerNew) {
        if(opp.DES_Booking_Geography__c != mapOld.get(opp.Id).DES_Booking_Geography__c) {
          oppsIds.add(opp.Id);
        }
      }

      for(DES_Template__c templ : [SELECT Id, Booking_label__c, opportunity_id__r.DES_Booking_Geography__c from DES_Template__c WHERE opportunity_id__c IN :oppsIds]) {
        templ.Booking_label__c = Util_PickList.getLabelFromAPI('Opportunity', 'DES_Booking_Geography__c').get(templ.opportunity_id__r.DES_Booking_Geography__c);
        templUpdate.add(templ);
      }

      if(!templUpdate.isEmpty()) {
        update templUpdate;
      }
    }

  /******************************************************************************
  * @Author:      Aitor Martin
  * @Method:      updateTemplate
  * @Return:
  * @Paramerers:  triggerNew lista de opps
  * @Description: cambia el valor del comite nbc en el template asociado a la
  *               Oportunidad cuando el comite de la oportunidad cambia
  ***********************************************************************************/

    public static void updateTemplate(List <Opportunity> triggerNew, Map<Id, Opportunity> mapOld) {

      final Set<Id> lstId = new Set<Id>();
      for(Opportunity opp : triggerNew) {
        if(opp.Committee_id__c != mapOld.get(opp.Id).Committee_id__c) {
          lstId.add(opp.Id);
        }
        System.debug('lstId Opp cambiadas----------------------------------------> '+lstId);
      }
      if(!lstId.isEmpty()) {
        final List <DES_Template__c> lstTemp = [SELECT Id, Name, gf_oppy_virtual_cmtee_id__c, opportunity_id__c FROM DES_Template__c WHERE opportunity_id__c IN :lstId];
        final List <Opportunity> lstOpp = [SELECT Id, Name, Committee_id__c FROM Opportunity WHERE Id = :lstId];
        if(!lstTemp.isEmpty() && !lstOpp.isEmpty()) {
          for(Opportunity opp : lstOpp) {
            for(DES_Template__c temp :lstTemp ) {
              if(opp.Id == temp.opportunity_id__c) {
                temp.gf_oppy_virtual_cmtee_id__c = opp.Committee_id__c;
              }
            }
          }
          System.debug('lstTemp Templates cambiados----------------------------------------> '+lstTemp);
          update lstTemp;
        }
      }
    }

  /******************************************************************************
  * @Author:      Aitor Martin
  * @Method:      crearChatter
  * @Return:
  * @Paramerers:  triggerNew lista de opps mapOld lista de opps antigua
  * @Description: Crea un objeto del tipo Chatter_NBC_Virtual__c cuando
  *               se asocia una Oportunidad a un NBC
  ***********************************************************************************/
    public static void crearChatter(List <Opportunity> triggerNew, Map<Id, Opportunity> mapOld) {
      final Set<Id> lstId = new Set<Id>();
      final Set<Id> lstIdnoNull = new Set<Id>();
      for(Opportunity opp : triggerNew) {
        if(opp.gf_oppy_virtual_cmtee_ind_type__c) {
          if(opp.Committee_id__c != mapOld.get(opp.Id).Committee_id__c) { //NOSONAR
            if(mapOld.get(opp.Id).Committee_id__c == null) { //NOSONAR
              lstId.add(opp.Id);
            } else {
              lstIdnoNull.add(opp.Id);
            }
          }
        }
      }
      System.debug('lstId Opp cambiadas---------------------------------------->'+lstId);
      System.debug('lstId Opp cambiadas---------------------------------------->'+lstIdnoNull);
      crearChatterHelper(lstId, lstIdnoNull);
    }
    /******************************************************************************
    * @Author:      Aitor Martin
    * @Method:      crearChatterHelper
    * @Return:
    * @Paramerers:  lstId lista de ids que antes no tenian Committee_id__c lstIdnoNull
    *               lista de ids que antes tenian Committee_id__c
    * @Description: Crea un objeto del tipo Chatter_NBC_Virtual__c cuando
    *               se asocia una Oportunidad a un NBC
    ***********************************************************************************/
    public static void crearChatterHelper(Set<Id> lstId, Set<Id> lstIdnoNull) {
      if(!lstId.isEmpty()) {
        final List<Chatter_NBC_Virtual__c> lstChat = new List<Chatter_NBC_Virtual__c>();
        for(Id id : lstId) {
          Chatter_NBC_Virtual__c chat = new Chatter_NBC_Virtual__c();//NOSONAR
          chat.id_objeto__c = id;
          chat.tipo_objeto__c = Label.Opportunity_Name;
          lstChat.add(chat);
        }
        System.debug('lstChat Chatters creados----------------------------------------> '+lstChat);
        if(!lstChat.isEmpty()) {
          insert lstChat;
        }
      }
      if(!lstIdnoNull.isEmpty()) {
        final List<Chatter_NBC_Virtual__c> lsChatNonull = [SELECT Id, id_objeto__c FROM Chatter_NBC_Virtual__c WHERE id_objeto__c = :lstIdnoNull];
        final List<Opportunity> lstOpp = [SELECT Id, Name, Committee_id__c FROM Opportunity WHERE Id = :lstIdnoNull];
        final List<Chatter_NBC_Virtual__c> lstChatUp = new List<Chatter_NBC_Virtual__c>();
        delete lsChatNonull;
        for(Opportunity opp : lstOpp) {
          if(opp.Committee_id__c != null) {
            Chatter_NBC_Virtual__c chatUp = new Chatter_NBC_Virtual__c(); //NOSONAR
            chatUp.id_objeto__c = opp.id;
            chatUp.tipo_objeto__c = Label.Opportunity_Name;
            lstChatUp.add(chatUp);
          }
        }
        if(!lstChatUp.isEmpty()) {
          insert lstChatUp;
        }
      }
    }

/******************************************************************************
  * @Author:      Alejandro del Rio Martin
  * @Method:      Crear NBC_Commitee_Member__c
  * @Return:
  * @Paramerers:  triggerNew lista de opps mapOld lista de opps antigua
  * @Description: Crea un objeto del tipo NBC_Commitee_Member__c cuando
  *               se asocia una Oportunidad a un NBC
  ***********************************************************************************/
    public static void crearNbcMembers(List <Opportunity> triggerNew, Map<Id, Opportunity> mapOld) {
      final List<GroupMember> Groupmembers = [SELECT Id, GroupId, UserOrGroupId from GroupMember where Group.DeveloperName ='Virtual_NBC_Commitee_Team'];//NOSONAR
      final List<NBC_Commitee_Member__c> nbcMembers = new List<NBC_Commitee_Member__c>();
      final Set<Id> goToIsNoNull = new Set<Id>();
      for(Opportunity opp : triggerNew) {
        if(opp.gf_oppy_virtual_cmtee_ind_type__c==true) {
          System.debug('@@@opp.gf_oppy_virtual_cmtee_ind_type__c'+ opp.gf_oppy_virtual_cmtee_ind_type__c);
          if(opp.Committee_id__c != mapOld.get(opp.Id).Committee_id__c) {//NOSONAR
            System.debug('@@@opp.Committee_id__c'+ opp.Committee_id__c);
            System.debug('@@@mapOld.get(opp.Id).Committee_id__c'+ mapOld.get(opp.Id).Committee_id__c);
            if(mapOld.get(opp.Id).Committee_id__c != null) {//NOSONAR
              goToIsNoNull.add(opp.id);
            }
            for(GroupMember members :Groupmembers) {
              final NBC_Commitee_Member__c nbcMember = new NBC_Commitee_Member__c();//NOSONAR
              nbcMember.opportunity_id__c =opp.id;
              nbcMember.gf_oppy_virtual_cmtee_id__c = opp.Committee_id__c;
              nbcMember.gf_oppy_virtual_cmtee_user_id__c = members.UserOrGroupId;
              nbcMembers.add(nbcMember);
            }
          }
        }
      }
      if(!goToIsNoNull.isEmpty()){
         final List<NBC_Commitee_Member__c> lsNonull = [SELECT Id FROM NBC_Commitee_Member__c WHERE opportunity_id__c IN :goToIsNoNull ];//NOSONAR
         if(!lsNonull.isEmpty()){
             delete lsNonull;//NOSONAR
         }
      }

      if(!nbcMembers.isEmpty()) {
        insert nbcMembers;
      }
    }


   /**
      * @author       JSS
      * @description  metodo con la lógica para evitar que se eliminen oportunidades con la funcionalidad de Pricing que ya se ha enviado a Workflow
      */
      public void checkLogicForDeletingPricingOpportunity(List <Opportunity> triggerOld) {
        System.debug('>>>>>>>>>> OpportunityTriggerHandler. Entrando en el método checkLogicForDeletingPricingOpportunity, triggerlist: ' + triggerOld.toString());
        final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
        for (Opportunity opp : triggerOld) {
          if (!pricingLogic.pricingOpportunityCanBeDeleted(opp)) {
            System.debug('>>>>>>>>>> Añadimos error a la opportunity: ' + opp.Name);
              opp.addError(label.PRC_CANNOT_DELETE_PRICING_OPPORTUNITY);
          }

        }

    }     

    /**
     * @description Compares the StageName of DMT Opportunities and logs snapshot version.
     * @param newOpps List of new Opportunity records from Trigger.new
     * @param oldOppMap Map of old Opportunity records from Trigger.oldMap
     */
    public void createOppVersionSnapshot(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
      
      // User Context
      String userId = UserInfo.getUserId();
      List<User> users = [SELECT ID_User__c FROM User WHERE Id = :userId LIMIT 1];
      String dmtUserId = !users.isEmpty() ? users[0].ID_User__c : '';

      for (Opportunity opp : newOpps) {
          Opportunity oldOpp = oldOppMap.get(opp.Id);

          if (oldOpp != null && opp.StageName != oldOpp.StageName) {
              // Build the standard Request
              DMT_SnapshotEvaluationVersions.PostRequestWrapperClass req = new DMT_SnapshotEvaluationVersions.PostRequestWrapperClass();
              req.user = dmtUserId;
              req.opportunityId = opp.DMT_Opp_Id__c;
              req.categoryId = oldOpp.StageName + '-' + opp.StageName;
              req.versionDescription = '';

              // Add directly as a SnapshotPayload (Interface implementation)
              DMT_AsyncOrchestrator.enqueue(new DMT_SnapshotPayload(req, opp.Id, 'Opportunity'));
          }
      }
  }
    /**
     * @description Called in AFTER UPDATE trigger.
     * Monitors StageName changes to trigger Passport refresh.
     */
    public void updatePassport_OppStatusChanged(List<Opportunity> newOpps, Map<Id, Opportunity> oldMapOpps) {

        Id oppRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity')?.getRecordTypeId();

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newOpps) {
            if (opp.RecordTypeId == oppRTId) {
                oppIds.add(opp.Id);
            }
        }

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMapOpps.get(opp.Id);

            Boolean statusChanged = opp.StageName != oldOpp.StageName;
            Boolean passesIntegrity = opp.RecordTypeId == oppRTId;

            if (statusChanged && passesIntegrity) {
                DMT_AsyncOrchestrator.enqueue(new DMT_PassportPayload(opp.Id, opp.AccountId, 'DMTO_EvaluationOpportunity'));
            }
        }
    }

 }