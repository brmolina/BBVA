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
    this.fields = soqlConfigs.get(0).Prospect_Merge__c + ',DES_Main_Parent__c';
    this.query = 'SELECT Id, RecordTypeId, ' + this.fields + ' FROM Account WHERE Merge_Insert__c = true' + (Test.isRunningTest() ? ' LIMIT 1000' : '');
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
    for(Account acc : clientsToMerge) {
      if(!fiscalIds.contains(acc.DES_ID_Fiscal__c)) {
        fiscalIds.add(acc.DES_ID_Fiscal__c);
      }
      if(!clientsIds.contains(acc.Id)) {
        clientsIds.add(acc.Id);
      }
    }
    system.debug('++++ clientsIds -> ' + JSON.serialize(clientsIds));

    /* Get related objects to clients */
    final List <dwp_acmh__GBL_Account_Relationship__c> relationships = gtRelationship(clientsIds);
    final List <DES_BBVA_Management_team__c> members = gtMembers(clientsIds);

    /* Get prospect that will be converted */
    final String queryProspect = 'SELECT Id, participant_id__c, participant_id__r.RecordType.DeveloperName, RecordTypeId, ' + fields + ' FROM Account WHERE DES_ID_Fiscal__c IN :fiscalIds AND RecordType.DeveloperName = \'Prospect_Subsidiary\'';
    final List <Account> prospects = Database.query(queryProspect);
    final Map <String, Account> mapProspects = generateMapProspect(prospects);
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

    /* Change object related */
    insertRelationship(mapProspects, relationships, members);

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

    system.debug('++ acrToInsert -> ' + JSON.serialize(acrToInsert));

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
    final List<dwp_acmh__GBL_Account_Relationship__c> listAccRel = [SELECT Id, dwp_acmh__Parent_Account__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Child_Account__c = :accId];

    for (dwp_acmh__GBL_Account_Relationship__c accRel : listAccRel) {
      recursiveFxn(accRel.dwp_acmh__Parent_Account__c, accInicial);
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
  private void insertRelationship(Map <String, Account> mapProspects, List <dwp_acmh__GBL_Account_Relationship__c> relationships, List <DES_BBVA_Management_team__c> members) {
    system.debug('++++ relationships -> ' + JSON.serialize(relationships));
    system.debug('++++ members -> ' + JSON.serialize(members));
    final List <dwp_acmh__GBL_Account_Relationship__c> relationsToInsert = new List <dwp_acmh__GBL_Account_Relationship__c>();
    final List <DES_BBVA_Management_team__c> membersToInsert = new List <DES_BBVA_Management_team__c>();
    final List <dwp_acmh__GBL_Account_Relationship__c> relationsToDelete = new List <dwp_acmh__GBL_Account_Relationship__c>();
    final List <DES_BBVA_Management_team__c> membersToDelete = new List <DES_BBVA_Management_team__c>();
    for(String fiscal : mapProspects.keyset()) {
      for(dwp_acmh__GBL_Account_Relationship__c relation : relationships) {
        if(relation.dwp_acmh__Child_Account__r.DES_ID_Fiscal__c == fiscal) {
          final dwp_acmh__GBL_Account_Relationship__c auxNew = relation.clone(false, true);
          auxNew.dwp_acmh__Child_Account__c = mapProspects.get(fiscal).Id;
          relationsToInsert.add(auxNew);
          relationsToDelete.add(relation);
        }
        if(relation.dwp_acmh__Parent_Account__r.DES_ID_Fiscal__c == fiscal) {
          final dwp_acmh__GBL_Account_Relationship__c auxNew = relation.clone(false, true);
          auxNew.dwp_acmh__Parent_Account__c = mapProspects.get(fiscal).Id;
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
  private static List<dwp_acmh__GBL_Account_Relationship__c> gtRelationship(Set<Id> clientsIds) {
    //Lista con campos que no se tienen que copiar. PONER SIEMPRE EN MINUSCULAS
    String query1;
    query1 = STR_SELECT;
    final Schema.DescribeSObjectResult oppliDesc = dwp_acmh__GBL_Account_Relationship__c.sObjectType.getDescribe();
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
    query1 += ', dwp_acmh__Child_Account__r.DES_ID_Fiscal__c, dwp_acmh__Parent_Account__r.DES_ID_Fiscal__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Child_Account__c IN :clientsIds OR dwp_acmh__Parent_Account__c IN :clientsIds';
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

	/*
	* @author Global Desktop
	* @Description: finish batch method
	*/
	public void finish(Database.BatchableContext bch) {
		final Id batchInstanceId = Database.executeBatch(new Batch_DeleteProspectGroup(), 2000);
	}
}