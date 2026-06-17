/*
 * @author Global Desktop
 * @Description: Batch que realiza el merge de propect y clients
 */
public with sharing class Batch_MergeProspects implements Database.Batchable<Sobject>, Database.Stateful {
  /*
  * private attribute query
  */
  private String query = ''; //NOSONAR
  /*
  * private attribute stringHierarchy
  */
  private Set<String> setAccIdHierarchyForContact = new Set<String>(); //NOSONAR
  /*
  * private attribute: The id of the account to be merged into the subsidiary prospect relationship is stored
  */
  private Map<String, String> idAccountMergeIdFiscal = new Map<String, String>();
  /*
  * private attribute: 
  */
  private Map<String, String> idSubsiProcpectGroupProspect = new Map<String, String>();
  /*
  * private attribute: Toolkits for delete in merge.
  */
  private List<cstk__Toolkit__c> toolkitDeletelist = new List<cstk__Toolkit__c>();
  /*
  * private attribute: List all objects toolkit for update merge.
  */
  private List<sObject> allRecordsToolkitUpdate = new List<sObject>();
  /*
  * private attribute fields
  */
  private String fields = ''; //NOSONAR
  /*
  * Exclude fields in dynamic query
  */
  private static final List<String> EXCLUDE_FIELDS = new List<String>{'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid', 'systemmodstamp', 'isdeleted'};
  /*
  * Select
  */
  private static final String STR_SELECT = 'SELECT ';

  /*
  * Constructor
  */
  public Batch_MergeProspects() {
    final List <Global_Desktop_SOQL_Config__mdt> soqlConfigs = new List <Global_Desktop_SOQL_Config__mdt>(
      [SELECT Id, DeveloperName, Prospect_Merge__c FROM Global_Desktop_SOQL_Config__mdt WHERE DeveloperName = 'Queries_Configurations']
    );
    this.fields = soqlConfigs.get(0).Prospect_Merge__c;
    this.query = 'SELECT Id, RecordTypeId, RecordType.DeveloperName, DES_Main_Parent__c, ' + this.fields + ' FROM Account WHERE Merge_Insert__c = true' + (Test.isRunningTest() ? ' LIMIT 1000' : '');
    System.debug('>>>>> Query: ' + query);
  }

  /*
  * @author Global Desktop
  * @Description: batchable method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    return Database.getQueryLocator(query);
  }

  /*
  * @author Global Desktop
  * @Description: batch que lanza las notificaciones de las alertas insertadas/modificadas con la configuración del usuario
  */
  public void execute(Database.BatchableContext bch, List<Account> clientsToMerge) {
    system.debug('++++ clientsToMerge -> ' + JSON.serialize(clientsToMerge));
    final Set<String> fiscalIds = new Set<String>();
    final Set<Id> clientsIds = new Set<Id>();
    final Map<String, Id> accountGroupsIds = new Map<String, Id>();
    this.toolkitDeletelist = new List<cstk__Toolkit__c>();
    this.allRecordsToolkitUpdate = new List<sObject>();
    for(Account acc : clientsToMerge) {
      if(!fiscalIds.contains(acc.DES_ID_Fiscal__c)) {
        idAccountMergeIdFiscal.put(acc.Id, acc.DES_ID_Fiscal__c);
        fiscalIds.add(acc.DES_ID_Fiscal__c);
      }
      if(!clientsIds.contains(acc.Id)) {
        clientsIds.add(acc.Id);
      }
      if(acc.RecordType.DeveloperName != 'Group' && !accountGroupsIds.values().contains(acc.DES_Main_Parent__c) && String.isNotBlank(acc.DES_Main_Parent__c)) {
        accountGroupsIds.put(acc.DES_ID_Fiscal__c, acc.DES_Main_Parent__c);
      }
      if(acc.RecordType.DeveloperName == 'Group' && !accountGroupsIds.values().contains(acc.Id) && String.isNotBlank(acc.Id)) {
        accountGroupsIds.put(acc.DES_ID_Fiscal__c, acc.Id);
      }
    }
    system.debug('++++ clientsIds -> ' + JSON.serialize(clientsIds));

    /* Get related objects to clients */
    final List <AMH_GBL_Account_Relationship__c> relationships = gtRelationship(clientsIds);
    final List <DES_BBVA_Management_team__c> members = gtMembers(clientsIds);

    /* Get prospect that will be converted */
    final String queryProspect = 'SELECT Id, participant_id__c, participant_id__r.RecordType.DeveloperName, RecordTypeId, ' + fields + ' FROM Account WHERE DES_ID_Fiscal__c IN :fiscalIds AND RecordType.DeveloperName = \'Prospect_Subsidiary\'';
    final List <Account> prospects = Database.query(queryProspect);
    final Map<String, Account> mapProspects = generateMapProspect(prospects);
    system.debug('++++ prospects -> ' + JSON.serialize(mapProspects));

    /* Generate list of prospect groups to delete */
    final Set <Id> groupsIds = generateSetGroups(prospects);
    system.debug('++++ groupsIds -> ' + JSON.serialize(groupsIds));

    final List<Account> prosNotConvert = new List<Account>([
      SELECT Id, DES_ID_Fiscal__c, participant_id__c FROM Account WHERE participant_id__c IN :groupsIds AND RecordType.DeveloperName = 'Prospect_Subsidiary' AND DES_ID_Fiscal__c NOT IN :mapProspects.keyset()
    ]);
    system.debug('++++ prosNotConvert -> ' + JSON.serialize(prosNotConvert));

    final List <Account> accsToDelete = generateListGroupDelete(groupsIds, prosNotConvert);
    system.debug('++++ accsToDelete -> ' + JSON.serialize(accsToDelete));

    /* Pass information from client to prospect by IdFiscal */
    final List<Account> clntMergdelete = new List<Account>();
    for(Account acc : clientsToMerge) {
      for(String field : fields.split(',')) {
        if(acc.get(field) != null && mapProspects != null && mapProspects.get(acc.DES_ID_Fiscal__c) != null) {
          mapProspects.get(acc.DES_ID_Fiscal__c).put(field, acc.get(field));
        }
      }
      if(mapProspects != null && mapProspects.get(acc.DES_ID_Fiscal__c) != null) {
        mapProspects.get(acc.DES_ID_Fiscal__c).RecordTypeId = acc.RecordTypeId;
        clntMergdelete.add(acc);
      }
      system.debug('++++ prospects2 -> ' + JSON.serialize(mapProspects));
    }

    updateRelationshipToolkit(groupsIds, accountGroupsIds, mapProspects);

    /* Change object related */
    insertRelationship(mapProspects, relationships, members);


    if(!this.allRecordsToolkitUpdate.isEmpty()) {
      update this.allRecordsToolkitUpdate;
    }

    /* Delete clients, groups and update prospect to client */
    if(!clntMergdelete.isEmpty()) {
      deleteProspectLocalClient(clntMergdelete);
      delete clntMergdelete;
    }
    if(!mapProspects.values().isEmpty()) {
      update mapProspects.values();
    }
    if(!accsToDelete.isEmpty()) {
      delete accsToDelete;
    }

    if(!this.toolkitDeletelist.isEmpty()) {
      delete this.toolkitDeletelist;
    }

    if(!prospects.isEmpty()) {
      denormalizeContacts(prospects);
    }

  }

  /*
  * Method borra los local client asociados a los propect
  */
  private void deleteProspectLocalClient(List <Account> prospects) {
    final Set<Id> accProspectIds = new Set<Id>();
    for(Account pros : prospects) {
      if(!accProspectIds.contains(pros.Id)) {
        accProspectIds.add(pros.Id);
      }
    }
    
    List<Local_Client__c> lstDeleteLocalClient=[select Id, Cib_Client__c  from Local_Client__c where Cib_Client__c in:accProspectIds ];
    if(!lstDeleteLocalClient.isEmpty()) {
       delete lstDeleteLocalClient; 
    }
    
  }
  /*
  * Method to generate map of prospect
  */
  private Set<Id> completeSetProspct(List <Account> prospects) {
    final Set<Id> accProspectIds = new Set<Id>();
    for(Account pros : prospects) {
      if(!accProspectIds.contains(pros.Id)) {
        accProspectIds.add(pros.Id);
      }
    }
    return accProspectIds;
  }
  /*
  * Method to generate map of prospect
  */
  private void denormalizeContacts(List <Account> prospects) {
    final Set<Id> accProspectIds = completeSetProspct(prospects);

    final List <Contact> contactsProsp = new List <Contact>([SELECT Id, AccountId, CurrencyIsoCode FROM Contact WHERE AccountId IN : accProspectIds]);

    final Map<String,AccountContactRelation> acrToInsert = new  Map<String,AccountContactRelation>();
    final Map<String,AccountContactRelation> acrExist = new  Map<String,AccountContactRelation>();
    final Set<Id> setContact = new Set<Id>();

    for(Contact con : contactsProsp) {
        if(!setContact.contains(con.Id)) {
            setContact.add(con.Id);
        }
    }

    final List<AccountContactRelation> accountRelations = [SELECT accountId, contactId from AccountContactRelation where contactId in :setContact];

    for(AccountContactRelation acr : accountRelations) {
      acrExist.put(acr.accountId + '_' + acr.contactId, acr);
    }

    system.debug('++ acrExist -> ' + JSON.serialize(acrExist));

    for (Contact contact: contactsProsp) {
      setAccIdHierarchyForContact.clear();
      recursiveFxn(contact.AccountId, contact.AccountId);
      system.debug('++ AccsIdHierarchy -> ' + contact.Id + ' ' + setAccIdHierarchyForContact);
      if (!setAccIdHierarchyForContact.isEmpty()) {
        for( String accId : setAccIdHierarchyForContact) {
          if(acrExist.get(accId + '_' + contact.Id) == null) {
            final AccountContactRelation accountContactRel = new AccountContactRelation(AccountId=accId, ContactId=contact.Id, CurrencyIsoCode=contact.CurrencyIsoCode, record_created_hierarchy_type__c = true);
            acrToInsert.put(accId + '_' + contact.Id,accountContactRel);
          }
        }
      }
    }

    if (!ACRtoInsert.isEmpty()) {
      System.debug('>>>>>>>>>> Lista de registros a insertar en AccountContactRelation: ' + ACRtoInsert);
      insert ACRtoInsert.values();
    }
  }

  /*
  * Method to add parents of hierarchy in a set
  */
  private void recursiveFxn(string accId, string accInicial) {
    if (accId != null && accId != accInicial) {
      setAccIdHierarchyForContact.add(accId);
    }
    //Retrieve the parents for the account passed
    final List<AMH_GBL_Account_Relationship__c> listAccRel = [SELECT Id, AMH_Parent_Account__c FROM AMH_GBL_Account_Relationship__c WHERE AMH_Child_Account__c = :accId];

    for (AMH_GBL_Account_Relationship__c accRel : listAccRel) {
      recursiveFxn(accRel.AMH_Parent_Account__c, accInicial);
    }
  }

  /*
  * Method to generate map of prospect
  */
  private Map<String, Account> generateMapProspect(List <Account> prospects) {
    final Map <String, Account> mapProspects = new Map <String, Account>();
    for(Account acc : prospects) {
      if(mapProspects.get(acc.DES_ID_Fiscal__c) == null) {
        mapProspects.put(acc.DES_ID_Fiscal__c, acc);
      }
    }
    return mapProspects;
  }

  /*
  * Method to generate set of groups Ids
  */
  private Set<Id> generateSetGroups(List <Account> prospects) {
    final Set <Id> groupsIds = new Set <Id>();
    for(Account acc : prospects) {
      if(!groupsIds.contains(acc.participant_id__c) && acc.participant_id__r.RecordType.DeveloperName == 'Prospect_Group') {
        idSubsiProcpectGroupProspect.put(acc.DES_ID_Fiscal__c, acc.participant_id__c);
        groupsIds.add(acc.participant_id__c);
      }
    }
    return groupsIds;
  }

  /*
  * Method to generate set of groups Ids
  */
  private List <Account> generateListGroupDelete(Set <Id> groupsIds, List<Account> prosNotConvert) {
    final List <Account> accsToDelete = new List <Account>();
    for(Id groupProspect : groupsIds) {
      Boolean contain = false;
      for(Account aux : prosNotConvert) {
        if (groupProspect == aux.participant_id__c) {
          contain = true;
        }
      }
      if(!contain) {
        final Account accAux = new Account(Id = groupProspect);
        accsToDelete.add(accAux);

      }
    }
    return accsToDelete;
  }

  /*
  * Method to insert relations and members
  */
  private void insertRelationship(Map <String, Account> mapProspects, List <AMH_GBL_Account_Relationship__c> relationships, List <DES_BBVA_Management_team__c> members) {
    system.debug('++++ relationships -> ' + JSON.serialize(relationships));
    system.debug('++++ members -> ' + JSON.serialize(members));
    final List <AMH_GBL_Account_Relationship__c> relationsToInsert = new List <AMH_GBL_Account_Relationship__c>();
    final List <DES_BBVA_Management_team__c> membersToInsert = new List <DES_BBVA_Management_team__c>();
    final List <AMH_GBL_Account_Relationship__c> relationsToDelete = new List <AMH_GBL_Account_Relationship__c>();
    final List <DES_BBVA_Management_team__c> membersToDelete = new List <DES_BBVA_Management_team__c>();
    for(String fiscal : mapProspects.keyset()) {
      for(AMH_GBL_Account_Relationship__c relation : relationships) {
        if(relation.AMH_Child_Account__r.DES_ID_Fiscal__c == fiscal) {
          final AMH_GBL_Account_Relationship__c auxNew = relation.clone(false, true);
          auxNew.AMH_Child_Account__c = mapProspects.get(fiscal).Id;
          relationsToInsert.add(auxNew);
          relationsToDelete.add(relation);
        }
        if(relation.AMH_Parent_Account__r.DES_ID_Fiscal__c == fiscal) {
          final AMH_GBL_Account_Relationship__c auxNew = relation.clone(false, true);
          auxNew.AMH_Parent_Account__c = mapProspects.get(fiscal).Id;
          relationsToInsert.add(auxNew);
          relationsToDelete.add(relation);
        }
      }
      for(DES_BBVA_Management_team__c member : members) {
        if(member.DES_Client__r.DES_ID_Fiscal__c == fiscal) {
          final DES_BBVA_Management_team__c auxNew = member.clone(false, true);
          auxNew.DES_Client__c = mapProspects.get(fiscal).Id;
          membersToInsert.add(auxNew);
          membersToDelete.add(member);
        }
      }
    }
    system.debug('++++ relationsToInsert -> ' + JSON.serialize(relationsToInsert));
    system.debug('++++ membersToInsert -> ' + JSON.serialize(membersToInsert));
    if(!membersToInsert.isEmpty()) {
      insert membersToInsert;
    }
    if(!relationsToInsert.isEmpty()) {
      insert relationsToInsert;
    }
    if(!relationsToDelete.isEmpty()) {
      delete relationsToDelete;
    }
    if(!membersToDelete.isEmpty()) {
      delete membersToDelete;
    }
  }

  /*
  * Method to query relationship of clients
  */
  private static List<AMH_GBL_Account_Relationship__c> gtRelationship(Set<Id> clientsIds) {
    //Lista con campos que no se tienen que copiar. PONER SIEMPRE EN MINUSCULAS
    String query1;
    query1 = STR_SELECT;
    final Schema.DescribeSObjectResult oppliDesc = AMH_GBL_Account_Relationship__c.sObjectType.getDescribe();
    for(String apiName : oppliDesc.fields.getMap().keySet()) {
      system.debug('>>>>> apiName : ' + apiName);
      if(!EXCLUDE_FIELDS.contains(apiName)) {
        if(query1 == STR_SELECT) {
          query1 += apiName;
        } else {
          query1 += ', ' + apiName;
        }
      }
    }
    query1 += ', AMH_Child_Account__r.DES_ID_Fiscal__c, AMH_Parent_Account__r.DES_ID_Fiscal__c FROM AMH_GBL_Account_Relationship__c WHERE AMH_Child_Account__c IN :clientsIds OR AMH_Parent_Account__c IN :clientsIds';
    system.debug('>>>>> query: ' + query1);
    return Database.query(query1);
  }
  /*
  * Method to query member of clients
  */
  private static List<DES_BBVA_Management_team__c> gtMembers(Set<Id> clientsIds) {
    //Lista con campos que no se tienen que copiar. PONER SIEMPRE EN MINUSCULAS
    String query1;
    query1 = STR_SELECT;
    final Schema.DescribeSObjectResult oppliDesc = DES_BBVA_Management_team__c.sObjectType.getDescribe();
    for(String apiName : oppliDesc.fields.getMap().keySet()) {
      system.debug('>>>>> apiName : ' + apiName);
      if(!EXCLUDE_FIELDS.contains(apiName)) {
        if(query1 == STR_SELECT) {
          query1 += apiName;
        } else {
          query1 += ', ' + apiName;
        }
      }
    }
    query1 += ', DES_Client__r.DES_ID_Fiscal__c FROM DES_BBVA_Management_team__c WHERE DES_Client__c IN :clientsIds';
    system.debug('>>>>> query1: ' + query1);
    return Database.query(query1);
  }

  private void updateRelationshipToolkit(Set<Id> prospectGroupsIds, Map<String, Id> accountGroupsIds, Map<String, Account> mapProspects){

    final Map<Id, cstk__Toolkit__c> idProspectToToolkit = new Map<Id, cstk__Toolkit__c>();
    final Map<Id, cstk__Toolkit__c> idAccountToToolkit = new Map<Id, cstk__Toolkit__c>();
    final Map<Id, Account> lProspects = new Map<Id, Account>([
      SELECT Id, Name, DES_ID_Fiscal__c, participant_id__c, customer_stock_exchange_name__c, gf_customer_prospect_id__c,
      participant_status_type__c, gf_stock_exchange_company_id__c, gf_cust_orig_prospect_ind_type__c, DES_Prospect_status__c
      FROM Account WHERE Id IN :prospectGroupsIds
    ]);

    final Map<Id, Account> clientsToMerge = new Map<Id, Account>([
      SELECT Id, Name, DES_ID_Fiscal__c, participant_id__c, customer_stock_exchange_name__c, gf_customer_prospect_id__c, DES_Contact__c,
      participant_status_type__c, gf_stock_exchange_company_id__c, gf_cust_orig_prospect_ind_type__c, DES_Group_Code__c, DES_Main_Parent__c
      FROM Account WHERE Id IN :accountGroupsIds.values()
    ]);

    final List<cstk__Toolkit__c> toolkitsProspects = new List<cstk__Toolkit__c>([
      SELECT Id, cstk__lei_id__c, cstk__toolkit_unique_id__c, cstk__account_id__c
      FROM cstk__Toolkit__c
      WHERE cstk__account_id__c IN :prospectGroupsIds
    ]);

    final List<cstk__Toolkit__c> toolkitsClientsToMerge = new List<cstk__Toolkit__c>([
      SELECT Id, cstk__lei_id__c, cstk__toolkit_unique_id__c, cstk__account_id__c
      FROM cstk__Toolkit__c
      WHERE cstk__account_id__c IN :accountGroupsIds.values()
    ]);

    for(cstk__Toolkit__c toolkit : toolkitsProspects) {
      idProspectToToolkit.put(toolkit.cstk__account_id__c, toolkit);
    }

    for(cstk__Toolkit__c toolkit : toolkitsClientsToMerge) {
      idAccountToToolkit.put(toolkit.cstk__account_id__c, toolkit);
    }

    for(Id prospectGroupId : prospectGroupsIds) {
      final Account prospect = lProspects.get(prospectGroupId);
      final Account clientToMerge = clientsToMerge.get(accountGroupsIds.get(prospect.DES_ID_Fiscal__c));

      final cstk__Toolkit__c toolkitProspect = idProspectToToolkit.get(prospectGroupId);
      final cstk__Toolkit__c toolkitClientToMerge = idAccountToToolkit.get(accountGroupsIds.get(prospect.DES_ID_Fiscal__c));

      if (toolkitProspect != null && toolkitClientToMerge == null) {
        updateToolkitRelationships(toolkitProspect, prospect, clientToMerge);
      } else if (toolkitProspect != null && toolkitClientToMerge != null) {
        this.toolkitDeletelist.add(toolkitProspect);
      }
    }
  }

  /*
  * Private method to update relationships from the Prospect Toolkit to the Customer Toolkit.
  */
  private void updateToolkitRelationships(cstk__Toolkit__c toolkitProspect, Account prospect, Account clientToMerge) {

    List<sObject> allRecordsUpdate = new List<sObject>();
    String toolUniqueOld = toolkitProspect.cstk__toolkit_unique_id__c;

    toolkitProspect.cstk__account_id__c = clientToMerge.Id;
    toolkitProspect.Name = clientToMerge.Name;
    if (!String.isBlank(clientToMerge.DES_Group_Code__c)) {
      toolkitProspect.cstk__toolkit_unique_id__c = clientToMerge.DES_Group_Code__c;
      toolkitProspect.cstk__has_parent_prospect__c = false;
    }else{
      clientToMerge.gf_customer_prospect_id__c = prospect.gf_customer_prospect_id__c;
      //allRecordsUpdate.add(clientToMerge);
    }
    allRecordsUpdate.add(toolkitProspect);

    if (!String.isBlank(clientToMerge.DES_Group_Code__c)) {
      final List<sObject> relatedRecords = new List<sObject>();
      final Id toolkitId = toolkitProspect.Id;
      final Map<String, Object> resMap = new CSTK_Client().getClientInfo(toolkitId);
      Set<Id> listIdSector = new Set<Id>();

      relatedRecords.addAll([
          SELECT Id, cstk__year__c, cstk__unique_id__c FROM cstk__General_Data__c WHERE cstk__toolkit_id__c = :toolkitId
      ]);
      relatedRecords.addAll([
          SELECT Id, cstk__year__c, cstk__category__c, cstk__source__c , cstk__Unique_id__c FROM cstk__Rating__c WHERE cstk__toolkit_id__c = :toolkitId
      ]);
      relatedRecords.addAll([
          SELECT Id, cstk__year__c, cstk__unique_id__c FROM cstk__Strategy__c WHERE cstk__toolkit_id__c = :toolkitId
      ]);
      relatedRecords.addAll([
          SELECT Id, cstk__year__c, cstk__unique_id__c FROM cstk__Emission_record__c WHERE cstk__toolkit_id__c = :toolkitId
      ]);
      relatedRecords.addAll([
          SELECT Id, cstk__year__c, cstk__unique_id__c FROM cstk__EmissionTarget__c WHERE cstk__toolkit_id__c = :toolkitId
      ]);
      relatedRecords.addAll([
          SELECT Id, cstk__year__c, cstk__gf_sustainability_subcatg_id__c, cstk__unique_id__c FROM cstk__Environmental_sales__c WHERE cstk__toolkit_id__c = :toolkitId
      ]);
      relatedRecords.addAll([
          SELECT Id, cstk__year__c, cstk__unique_id__c FROM cstk__Water_Biodiversity__c WHERE cstk__toolkit_id__c = :toolkitId
      ]);
      relatedRecords.addAll([
          SELECT Id, cstk__year__c, cstk__unique_id__c FROM cstk__tri__c WHERE cstk__toolkit_id__c = :toolkitId
      ]);
      relatedRecords.addAll([
          SELECT Id, cstk__year__c, cstk__unique_id__c FROM cstk__tri_autoparts__c WHERE cstk__toolkit_id__c = :toolkitId
      ]);
      relatedRecords.addAll([
          SELECT Id, cstk__year__c, cstk__unique_id__c FROM cstk__tri_generic__c WHERE cstk__Toolkit_id__c = :toolkitId
      ]);
      relatedRecords.addAll([
          SELECT Id, cstk__gf_tri_request_date_account_id_id__c FROM cstk__tri_multisector__c WHERE cstk__Toolkit_id__c = :toolkitId
      ]);

      String sector = (String) resMap.get('sector');
      List<String> sectorsList = String.isNotBlank(sector) ? sector.split(';') : new List<String>();

      for (String sect : sectorsList) {
        listIdSector.clear();
        switch on sect.toLowerCase('en') {
          when 'energy' {
            final List<cstk__Sector_Energy__c> listAllSectorEnergy = [SELECT Id, cstk__year__c, cstk__sector_energy_id__c FROM cstk__Sector_Energy__c WHERE cstk__toolkit_id__c = :toolkitId];
            for (cstk__Sector_Energy__c sectorEnergyCurrent : listAllSectorEnergy) {
              listIdSector.add(sectorEnergyCurrent.Id);
            }
            relatedRecords.addAll(listAllSectorEnergy);
            relatedRecords.addAll([
                SELECT Id, cstk__Unique_id__c, cstk__main_geo__c, cstk__origin__c, cstk__year__c FROM cstk__Top_5_geographies__c WHERE cstk__Sector_Energy__c IN :listIdSector
            ]);
          }
          when 'cement' {
            final List<cstk__Sector_Cement__c> listAllSectorCement = [SELECT Id, cstk__year__c, cstk__sector_cement_id__c FROM cstk__Sector_Cement__c WHERE cstk__toolkit_id__c = :toolkitId];
            for (cstk__Sector_Cement__c sectorCementCurrent : listAllSectorCement) {
              listIdSector.add(sectorCementCurrent.Id);
            }
            relatedRecords.addAll(listAllSectorCement);
            relatedRecords.addAll([
                SELECT Id, cstk__Unique_id__c, cstk__main_geo__c, cstk__origin__c, cstk__year__c FROM cstk__Top_5_geographies__c WHERE cstk__Sector_Cement__c IN :listIdSector
            ]);
          }
          when 'autoparts' {
            final List<cstk__Sector_Autoparts__c> listAllSectorAutoparts = [SELECT Id, cstk__year__c, cstk__sector_autoparts_id__c FROM cstk__Sector_Autoparts__c WHERE cstk__toolkit_id__c = :toolkitId];
            for (cstk__Sector_Autoparts__c sectorAutopartsCurrent : listAllSectorAutoparts) {
              listIdSector.add(sectorAutopartsCurrent.Id);
            }
            relatedRecords.addAll(listAllSectorAutoparts);
            relatedRecords.addAll([
                SELECT Id, cstk__Unique_id__c, cstk__main_geo__c, cstk__origin__c, cstk__year__c FROM cstk__Top_5_geographies__c WHERE cstk__Sector_Autoparts__c IN :listIdSector
            ]);
          }
          when 'auto' {
            final List<cstk__Sector_Auto__c> listAllSectorAuto = [SELECT Id, cstk__year__c, cstk__sector_auto_id__c FROM cstk__Sector_Auto__c WHERE cstk__toolkit_id__c = :toolkitId];
            for (cstk__Sector_Auto__c sectorAutoCurrent : listAllSectorAuto) {
              listIdSector.add(sectorAutoCurrent.Id);
            }
            relatedRecords.addAll(listAllSectorAuto);
            relatedRecords.addAll([
                SELECT Id, cstk__Unique_id__c, cstk__main_geo__c, cstk__origin__c, cstk__year__c FROM cstk__Top_5_geographies__c WHERE cstk__Sector_Auto__c IN :listIdSector
            ]);
          }
          when 'generic' {
            final List<cstk__Sector_Generic__c> listAllSectorGeneric = [SELECT Id, cstk__year__c, cstk__sector_generic_id__c FROM cstk__Sector_Generic__c WHERE cstk__toolkit_id__c = :toolkitId];
            for (cstk__Sector_Generic__c sectorGenericCurrent : listAllSectorGeneric) {
              listIdSector.add(sectorGenericCurrent.Id);
            }
            relatedRecords.addAll(listAllSectorGeneric);
            relatedRecords.addAll([
                SELECT Id, cstk__Unique_id__c, cstk__main_geo__c, cstk__origin__c, cstk__year__c FROM cstk__Top_5_geographies__c WHERE cstk__Sector_Generic__c IN :listIdSector
            ]);

            //Check if applies
            relatedRecords.addAll([
              SELECT Id, cstk__year__c, cstk__sector_aviation_id__c FROM cstk__Sector_Aviation__c WHERE cstk__toolkit_id__c = :toolkitId
            ]);
            relatedRecords.addAll([
              SELECT Id, cstk__year__c, cstk__sector_heavy_industry_id__c FROM cstk__Sector_Heavy_Industry__c WHERE cstk__toolkit_id__c = :toolkitId
            ]);
            relatedRecords.addAll([
              SELECT Id, cstk__year__c, cstk__sector_real_state_id__c FROM cstk__Sector_Real_State__c WHERE cstk__toolkit_id__c = :toolkitId
            ]);
            relatedRecords.addAll([
              SELECT Id, cstk__year__c, cstk__sector_shipping_id__c FROM cstk__Sector_Shipping__c WHERE cstk__toolkit_id__c = :toolkitId
            ]);
          }
          when 'steel' {
            final List<cstk__Sector_Steel__c> listAllSectorSteel = [SELECT Id, cstk__year__c, cstk__sector_steel_id__c FROM cstk__Sector_Steel__c WHERE cstk__toolkit_id__c = :toolkitId];
            for (cstk__Sector_Steel__c sectorSteelCurrent : listAllSectorSteel) {
              listIdSector.add(sectorSteelCurrent.Id);
            }
            relatedRecords.addAll(listAllSectorSteel);
            relatedRecords.addAll([
                SELECT Id, cstk__Unique_id__c, cstk__main_geo__c, cstk__origin__c, cstk__year__c FROM cstk__Top_5_geographies__c WHERE cstk__Sector_Steel__c IN :listIdSector
            ]);
          }
          when 'utilities' {
            final List<cstk__Sector_Utilities__c> listAllSectorUtilities = [SELECT Id, cstk__year__c, cstk__sector_utility_id__c FROM cstk__Sector_Utilities__c WHERE cstk__toolkit_id__c = :toolkitId];
            for (cstk__Sector_Utilities__c sectorUtilitiesCurrent : listAllSectorUtilities) {
              listIdSector.add(sectorUtilitiesCurrent.Id);
            }
            relatedRecords.addAll(listAllSectorUtilities);
            relatedRecords.addAll([
                SELECT Id, cstk__Unique_id__c, cstk__main_geo__c, cstk__origin__c, cstk__year__c FROM cstk__Top_5_geographies__c WHERE cstk__Sector_Utility__c IN :listIdSector
            ]);
          }
        }
      }

      for (sObject record : relatedRecords) {
        record = setFieldsObject(record, toolUniqueOld, toolkitProspect.cstk__toolkit_unique_id__c, toolkitProspect.cstk__account_id__c);
        allRecordsUpdate.add(record);
      }
    }

    this.allRecordsToolkitUpdate.addAll(allRecordsUpdate);
  }

  /*
  * Private method to set fields of objects related to toolkit.
  */
  private sObject setFieldsObject(sObject record, String prospectUnique, String toolUnique, String accountId) {
    final String sobjType = String.valueOf(record.getSObjectType());
    switch on sobjType {
      when 'cstk__Emission_record__c' {
        record.put('cstk__unique_id__c', setUniqueId((String) record.get('cstk__unique_id__c'), toolUnique));
      }
      when 'cstk__EmissionTarget__c' {
        record.put('cstk__unique_id__c', setUniqueId((String) record.get('cstk__unique_id__c'), toolUnique));
      }
      when 'cstk__Environmental_sales__c' {
        record.put('cstk__unique_id__c', setUniqueId((String) record.get('cstk__unique_id__c'), toolUnique));
      }
      when 'cstk__General_Data__c' {
        record.put('cstk__unique_id__c', setUniqueId((String) record.get('cstk__unique_id__c'), toolUnique));
      }
      when 'cstk__Rating__c' {
        record.put('cstk__Unique_id__c', setUniqueId((String) record.get('cstk__Unique_id__c'), toolUnique));
      }
      when 'cstk__Sector_Auto__c' {
        record.put('cstk__sector_auto_id__c', setUniqueId((String) record.get('cstk__sector_auto_id__c'), toolUnique));
      }
      when 'cstk__Sector_Autoparts__c' {
        record.put('cstk__sector_autoparts_id__c', setUniqueId((String) record.get('cstk__sector_autoparts_id__c'), toolUnique));
      }
      when 'cstk__Sector_Aviation__c' {
        record.put('cstk__sector_aviation_id__c', setUniqueId((String) record.get('cstk__sector_aviation_id__c'), toolUnique));
      }
      when 'cstk__Sector_Cement__c' {
        record.put('cstk__sector_cement_id__c', setUniqueId((String) record.get('cstk__sector_cement_id__c'), toolUnique));
      }
      when 'cstk__Sector_Energy__c' {
        record.put('cstk__sector_energy_id__c', setUniqueId((String) record.get('cstk__sector_energy_id__c'), toolUnique));
      }
      when 'cstk__Sector_Generic__c' {
        record.put('cstk__sector_generic_id__c', setUniqueId((String) record.get('cstk__sector_generic_id__c'), toolUnique));
      }
      when 'cstk__Sector_Heavy_Industry__c' {
        record.put('cstk__sector_heavy_industry_id__c', setUniqueId((String) record.get('cstk__sector_heavy_industry_id__c'), toolUnique));
      }
      when 'cstk__Sector_Real_State__c' {
        record.put('cstk__sector_real_state_id__c', setUniqueId((String) record.get('cstk__sector_real_state_id__c'), toolUnique));
      }
      when 'cstk__Sector_Shipping__c' {
        record.put('cstk__sector_shipping_id__c', setUniqueId((String) record.get('cstk__sector_shipping_id__c'), toolUnique));
      }
      when 'cstk__Sector_Steel__c' {
        record.put('cstk__sector_steel_id__c', setUniqueId((String) record.get('cstk__sector_steel_id__c'), toolUnique));
      }
      when 'cstk__Sector_Utilities__c' {
        record.put('cstk__sector_utility_id__c', setUniqueId((String) record.get('cstk__sector_utility_id__c'), toolUnique));
      }
      when 'cstk__Strategy__c' {
        record.put('cstk__unique_id__c', setUniqueId((String) record.get('cstk__unique_id__c'), toolUnique));
      }
      when 'cstk__Top_5_geographies__c' {
        record.put('cstk__Unique_id__c', setUniqueId((String) record.get('cstk__Unique_id__c'), toolUnique));
      }
      when 'cstk__tri__c' {
        record.put('cstk__toolkit_id__c', null);
        record.put('cstk__account__c', null);
      }
      when 'cstk__tri_autoparts__c' {
        record.put('cstk__toolkit_id__c', null);
        record.put('cstk__account__c', null);
      }
      when 'cstk__tri_generic__c' {
        record.put('cstk__Toolkit_id__c', null);
        record.put('cstk__account__c', null);
      }
      when 'cstk__tri_multisector__c' {
        record.put('cstk__toolkit_id__c', null);
        record.put('cstk__gf_account_code_id__c', null);
      }
      when 'cstk__Water_Biodiversity__c' {
        record.put('cstk__unique_id__c', setUniqueId((String) record.get('cstk__unique_id__c'), toolUnique));
      }
    }

    return record;
  }

  /*
  * Private method to update unique_id__c field of objects related to toolkit.
  */
  private static String setUniqueId(String uniqueIdOld, String replacement) {
    String uniqueIdCurrent = uniqueIdOld;
    if (uniqueIdOld.length() > 15 && String.isNotBlank(replacement)) {
      uniqueIdCurrent = uniqueIdOld.substring(0, uniqueIdOld.length() - 15) + replacement;
    }
    return uniqueIdCurrent;
  }

	/*
	* @author Global Desktop
	* @Description: finish batch method
	*/
	public void finish(Database.BatchableContext bch) {
		final Id batchInstanceId = Database.executeBatch(new Batch_DeleteProspectGroup(), 2000);
	}
}