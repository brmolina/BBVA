/**
 * @description       :
 * @author            : David Rodríguez
 * @group             :
 * @last modified on  : 05-05-2021
 * @last modified by  : David Rodríguez
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   04-20-2021   David Rodríguez   Initial Version
**/
@SuppressWarnings('sf:AvoidLiteralsInIfCondition')
public without sharing class MergeProspectFlow {
  /**
  * SINGLETON PATTERN
  */
  private static MergeProspectFlow instance;

  /**
  * Constructor
  */
  private MergeProspectFlow() {
  }

  /**
  * getInstance
  */
  public static MergeProspectFlow gtInstance() {
    if(instance == null) {
      instance = new MergeProspectFlow();
    }
    return instance;
  }

  /*
  * Proceso de merge
  */
  @InvocableMethod(label='MergeProcess' description='Process to merge')
  public static void mergeProcess(List<WrapperMerge> mgList) {
    system.debug('** Entrada -> ' + JSON.serialize(mgList[0]));

    final List<Account> prospect = new List<Account>([
      SELECT Id, Name, DES_ID_Fiscal__c, participant_id__c, customer_stock_exchange_name__c, gf_customer_prospect_id__c,
      participant_status_type__c, gf_stock_exchange_company_id__c, gf_cust_orig_prospect_ind_type__c, DES_Prospect_status__c
      FROM Account WHERE Id = :mgList[0].idProspect
    ]);

    final List<Account> clientToMerge = new List<Account>([
      SELECT Id, Name, DES_ID_Fiscal__c, participant_id__c, customer_stock_exchange_name__c, gf_customer_prospect_id__c, DES_Contact__c,
      participant_status_type__c, gf_stock_exchange_company_id__c, gf_cust_orig_prospect_ind_type__c, DES_Group_Code__c, DES_Main_Parent__c, g_customer_id__c
      FROM Account WHERE Id = :mgList[0].idClient
    ]);

    final List<Opportunity> oppsProspect = new List<Opportunity>([
      SELECT Id, Name, AccountId
      FROM Opportunity
      WHERE AccountId = :mgList[0].idProspect
    ]);

    final List<dwp_kitv__Visit__c> visitsProspect = new List<dwp_kitv__Visit__c>([
      SELECT Id, Name, dwp_kitv__account_id__c
      FROM dwp_kitv__Visit__c
      WHERE dwp_kitv__account_id__c = :mgList[0].idProspect
    ]);

    final List<Contact> contactsProspect = new List<Contact>([
      SELECT Id, Name, AccountId
      FROM Contact
      WHERE AccountId = :mgList[0].idProspect
    ]);

    final List<cstk__Toolkit__c> toolkitsProspect = new List<cstk__Toolkit__c>([
      SELECT Id, cstk__lei_id__c, cstk__toolkit_unique_id__c
      FROM cstk__Toolkit__c
      WHERE cstk__account_id__c = :mgList[0].idProspect
    ]);

    final List<cstk__Toolkit__c> toolkitsClientToMerge = new List<cstk__Toolkit__c>([
      SELECT Id, cstk__lei_id__c, cstk__toolkit_unique_id__c
      FROM cstk__Toolkit__c
      WHERE cstk__account_id__c = :mgList[0].idClient
    ]);

    final List<Contact> contactsToUpdate = addToList(contactsProspect, mgList[0].idClient, 'AccountId');
    final List<Opportunity> oppsToUpdate = addToList(oppsProspect, mgList[0].idClient, 'AccountId');
    final List<dwp_kitv__Visit__c> visitsToUpdate = addToList(visitsProspect, mgList[0].idClient, 'dwp_kitv__account_id__c');

    if (!toolkitsProspect.isEmpty() && toolkitsClientToMerge.isEmpty()) {
      updateToolkitRelationships(toolkitsProspect.get(0), prospect.get(0), clientToMerge.get(0));
    } else if (!toolkitsProspect.isEmpty() && !toolkitsClientToMerge.isEmpty()) {
      delete toolkitsProspect;
    }

    migrateFields(clientToMerge.get(0), prospect.get(0));
    updateList(contactsToUpdate);
    updateList(oppsToUpdate);
    updateList(visitsToUpdate);

    if(mgList[0].arceList != null && mgList[0].hasNoArce) {
      final List<arce__Account_has_Analysis__c> arceProspect = updateAHA(mgList.get(0), true);

      final Set<Id> arceIds = new Set<Id>();
      for(arce__Account_has_Analysis__c aHa : arceProspect) {
        arceIds.add(aHa.arce__Analysis__c);
      }
      updateAnalysis(arceIds, true, clientToMerge.get(0), mgList.get(0));

    } else if (mgList[0].arceList != null && !mgList[0].hasNoArce) {
      final List<arce__Account_has_Analysis__c> arceProspect = updateAHA(mgList.get(0), false);

      final Set<Id> arceIds = new Set<Id>();
      final List<arce__Account_has_Analysis__c> aHaToUpdate = new List<arce__Account_has_Analysis__c>();
      for(arce__Account_has_Analysis__c aHa : arceProspect) {
        arceIds.add(aHa.arce__Analysis__c);
        if(aHa.arce__Analysis__r.arce__Stage__c == '3') {
          aHa.arce__CustomAccountID__c = mgList[0].idLocalClient;
          aHa.DES_Local_Client__c = mgList[0].idLocalClient;
          aHa.arce__Customer__c = mgList[0].idClient;
          aHa.arce__group_risk_detail_part_name__c = mgList[0].lClientName;
          aHa.arce__participant_name__c = mgList[0].lClientName;
          aHaToUpdate.add(aHa);
        }
      }

      updateList(aHaToUpdate);

      updateAnalysis(arceIds, false, clientToMerge.get(0), mgList.get(0));
    }
    updateCustomAssociationsForMerge(mgList[0].idProspect, clientToMerge.get(0));

    //final DES_Arc_ProspectController.WrapperService wrap = new DES_Arc_ProspectController.WrapperService(prospect.get(0), mgList[0].lClientAlpha, false);
    //System.enqueueJob(new MergeProspectConvertQueueable(JSON.serialize(wrap)));
    System.debug('** Antes de llamar al DMT_ProspectCallService -> ' + JSON.serialize(mgList[0]));
    DMT_ProspectCallService.callMergeProspectService(clientToMerge.get(0).g_customer_id__c, prospect.get(0).gf_customer_prospect_id__c, clientToMerge.get(0).DES_Group_Code__c);
    deleteGroupsPros(prospect.get(0).participant_id__c, mgList[0].idProspect, clientToMerge.get(0));    
  }

  /*
  * Private method to add record to List
  */
  public static void callWSConvert(String wrapJson) {
    final DES_Arc_ProspectController.WrapperService wrap = (DES_Arc_ProspectController.WrapperService) JSON.deserialize(wrapJson, DES_Arc_ProspectController.WrapperService.class);
    if(wrap.pros.DES_Prospect_status__c == Label.Prospect_created) {
      DES_Arc_ProspectController.callConvertProspect(wrap.pros.Name, wrap.pros.DES_ID_Fiscal__c, wrap.pros.gf_customer_prospect_id__c, wrap.alphacode);
    } else if (DES_Arc_ProspectController.callCreateProspect(wrap.pros, wrap.toUpdate)) {
      DES_Arc_ProspectController.callConvertProspect(wrap.pros.Name, wrap.pros.DES_ID_Fiscal__c, wrap.pros.gf_customer_prospect_id__c, wrap.alphacode);
    }
  }

  /*private class MergeProspectConvertQueueable implements Queueable, Database.AllowsCallouts {
    private final String wrapJson;

    public MergeProspectConvertQueueable(String wrapJson) {
      this.wrapJson = wrapJson;
    }

    public void execute(QueueableContext context) {
      callWSConvert(wrapJson);
    }
  }*/

  /*
  * Private method to add record to List
  */
  private static List<SObject> addToList(List<SObject> sourceList, String clientId, String field) {
    final List<SObject> listToReturn = new List<SObject>();
    for(SObject obj : sourceList) {
      obj.put(field, clientId);
      listToReturn.add(obj);
    }
    return listToReturn;
  }

  /*
  * Private method to update List
  */
  private static void updateList(List<SObject> sourceList) {
    if(!sourceList.isEmpty()) {
      update sourceList;
    }
  }

  /*
  * Private method to update relationships from the Prospect Toolkit to the Customer Toolkit.
  */
  @TestVisible
  private static void updateToolkitRelationships(cstk__Toolkit__c toolkitProspect, Account prospect, Account clientToMerge) {

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

    updateList(allRecordsUpdate);
  }

  /*
  * Private method to set fields of objects related to toolkit.
  */
  private static sObject setFieldsObject(sObject record, String prospectUnique, String toolUnique, String accountId) {
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
  * Private method to migrate fields from Prospect to account
  */
  private static void migrateFields(Account acc, Account prospect) {
    acc.customer_stock_exchange_name__c = prospect.customer_stock_exchange_name__c;
    acc.participant_status_type__c = prospect.participant_status_type__c;
    acc.gf_stock_exchange_company_id__c = prospect.gf_stock_exchange_company_id__c;
    acc.gf_cust_orig_was_prospect_ind_type__c = true;
    update acc;
  }

  /**
  * Private method to delete prospect group
  */
  private static void deleteGroupsPros(String groupId, String idProspect, Account clientToMerge) {
    final List <Account> accsToDelete = new List <Account>();
    final List<Account> prosNotConvert = new List<Account>([
      SELECT Id, DES_ID_Fiscal__c, participant_id__c FROM Account WHERE participant_id__c = :groupId AND participant_id__r.RecordType.DeveloperName = 'Prospect_Group' AND RecordType.DeveloperName = 'Prospect_Subsidiary'
    ]);

    final List<Local_Client__c > localClient = new List<Local_Client__c >([
      SELECT Id FROM Local_Client__c  WHERE Cib_Client__c = :idProspect
    ]);

    if(!localClient.isEmpty()) {
      delete localClient;
    }

    if(prosNotConvert.size() == 1) {
      //Comprobamos si el prospect group tiene toolkit
      Integer prospectGroupHasToolkit = [SELECT COUNT() FROM cstk__Toolkit__c WHERE cstk__account_id__c = :groupId];
      
      if (prospectGroupHasToolkit > 0) {
        //En caso de tener toolkit, se comprueba si el grupo del cliente con el que se va a mergear tiene toolkit 
        Integer finalGroupHasToolkit = [SELECT COUNT() From cstk__Toolkit__c WHERE cstk__account_id__c = :clientToMerge.DES_Main_Parent__c];
        cstk__Toolkit__c toolkitProspect = [SELECT Id, cstk__toolkit_unique_id__c FROM cstk__Toolkit__c WHERE cstk__account_id__c = :groupId];
        if (finalGroupHasToolkit > 0) {
          //En caso de que el grupo final tenga toolkit, se elimina el toolkit del prospect group
          delete toolkitProspect;
        } else {
          //En caso de que el grupo final no tenga toolkit, se actualiza el toolkit del prospect group al grupo final
          Account prospectToMerge = [SELECT ID, gf_customer_prospect_id__c, DES_Group_Code__c from Account WHERE ID = : idProspect LIMIT 1];
          Account toolkitGroupAccount = [SELECT ID, Name, DES_Group_Code__c, gf_customer_prospect_id__c FROM Account WHERE ID = : clientToMerge.DES_Main_Parent__c LIMIT 1];
          updateToolkitRelationships(toolkitProspect, prospectToMerge, toolkitGroupAccount);
        }
      }  
      final Account accAux = new Account(Id = groupId);
      accsToDelete.add(accAux);
    }
    final Account accAux1 = new Account(Id = idProspect);
    accsToDelete.add(accAux1);
    delete accsToDelete;
  }

  /*
  * Private method update AccountHasAnalysis
  */
  private static List<arce__Account_has_Analysis__c> updateAHA(WrapperMerge mgList, Boolean hasNoArce) {
    final Set<Id> aHaIds = new Set<Id>();
      for(arce__Account_has_Analysis__c arce : mgList.arceList) {
        aHaIds.add(arce.Id);
      }

      final List<arce__Account_has_Analysis__c> arceProspect = new List<arce__Account_has_Analysis__c>([
        SELECT Id, DES_Local_Client__c, arce__Customer__c, arce__Analysis__c, arce__Analysis__r.arce__Stage__c
        FROM arce__Account_has_Analysis__c WHERE Id IN :aHaIds
      ]);

      if(hasNoArce) {
        final List<arce__Account_has_Analysis__c> arcesToUpdate = new List<arce__Account_has_Analysis__c>();
        for(arce__Account_has_Analysis__c arce : arceProspect) {
          arce.DES_Local_Client__c = mgList.idLocalClient;
          arce.arce__CustomAccountID__c = mgList.idLocalClient;
          arce.arce__Customer__c = mgList.idClient;
          arce.arce__group_risk_detail_part_name__c = mgList.lClientName;
          arce.arce__participant_name__c = mgList.lClientName;
          arcesToUpdate.add(arce);
        }
        updateList(arcesToUpdate);
      }

      return arceProspect;
  }

  /*
  * Private method to update Analysis
  */
  private static void updateAnalysis(Set<Id> arceIds, Boolean hasNoArce, Account clientToMerge, WrapperMerge mgList) {
    final List<arce__Analysis__c> analysisPros = new List<arce__Analysis__c >([
      SELECT Id, Name, arce__Stage__c
      FROM arce__Analysis__c WHERE Id IN :arceIds
    ]);

    final List<arce__Analysis__c> analysisToUpdate = new List<arce__Analysis__c>();
    final List<arce__Analysis__c> arceDelete = new List<arce__Analysis__c>();

    for(arce__Analysis__c analysis : analysisPros) {
      if(hasNoArce || (!hasNoArce && analysis.arce__Stage__c == '3')) {
        final List<String> nameSplit = analysis.Name.split('-');
        analysis.Name = analysis.Name.replace(nameSplit[1], ' ' + mgList.lClientName + ' ');
        analysis.arce__Group__c = clientToMerge.Id;
        analysisToUpdate.add(analysis);
      } else {
        arceDelete.add(analysis);
      } 
    }
    updateList(analysisToUpdate);
    if(!arceDelete.isEmpty()) {
      delete arceDelete;
    }
  }

  /**
  * @description Actualiza Custom_Association__c y Custom_Association_Client__c del Prospect con datos del cliente final en lineas
  * Actualiza Custom_Association_Opportunity__c y DMT_Opportunity_Client__c del Prospect con datos del cliente final en oportunidades
  * @param prospectId Id del prospect
  * @param clientToMerge Account del cliente final
  */
  private static void updateCustomAssociationsForMerge(Id prospectId, Account clientToMerge) {
    // 1. Reasignar primero las lineas que apuntan directamente al prospect.
    final List<DMT_Line__c> linesToUpdate = [
      SELECT Id, Client__c, Custom_Association__c
      FROM DMT_Line__c
      WHERE Client__c = :prospectId
    ];

    final Set<Id> customAssociationIds = new Set<Id>();
    for (DMT_Line__c line : linesToUpdate) {
      line.Client__c = clientToMerge.Id;
      if (line.Custom_Association__c != null) {
        customAssociationIds.add(line.Custom_Association__c);
      }
    }

    // 2. Obtener el g_customer_id__c del Prospect
    final List<Account> prospectAccounts = [
      SELECT Id, g_customer_id__c
      FROM Account
      WHERE Id = :prospectId
      LIMIT 1
    ];

    if (prospectAccounts.isEmpty()) {
      System.debug('log::Prospect not found');
      return;
    }

    final String prospectCustomerId = prospectAccounts[0].g_customer_id__c;

    if (String.isBlank(prospectCustomerId)) {
      System.debug('log::Prospect g_customer_id__c is blank, fallback to line associations');
    }

    // 3. Consultar Local_Client__c del clientToMerge
    final List<Local_Client__c> localClientList = [
      SELECT Id, Alpha_code__c 
      FROM Local_Client__c 
      WHERE Cib_Client__c = :clientToMerge.Id 
      LIMIT 1
    ];
    final Local_Client__c localClient = !localClientList.isEmpty() ? localClientList[0] : null;

    // 4. Obtener groupStructure y determinar el código del grupo
    final Map<String, Object> groupStructure = DMT_HPG_Utils.buildClientGroupStructure(clientToMerge.Id);

    String groupCode = null;
    if (groupStructure.get('supragroupId') != null) {
      groupCode = (String) groupStructure.get('supragroupId');
    } else if (groupStructure.get('groupCode') != null) {
      groupCode = (String) groupStructure.get('groupCode');
    }

    // 5. Extraer g_entific_id__c del clientToMerge
    final String entificId = String.isNotBlank(clientToMerge.g_customer_id__c) && clientToMerge.g_customer_id__c.length() >= 2 ? clientToMerge.g_customer_id__c.substring(0, 2) : null;

    // 6. Buscar el Account del Group usando el código determinado
    Id groupAccountId = null;
    if (String.isNotBlank(groupCode)) {
      final List<Account> groupAccounts = [
        SELECT Id 
        FROM Account 
        WHERE DES_Group_Code__c = :groupCode 
        LIMIT 1
      ];
      if (!groupAccounts.isEmpty()) {
        groupAccountId = groupAccounts[0].Id;
      }
    }

    // 7. Consultar y actualizar Custom_Association__c (Líneas)
    List<Custom_Association__c> customAssociationsLine = new List<Custom_Association__c>();
    if (String.isNotBlank(prospectCustomerId)) {
      customAssociationsLine = [
        SELECT Id, Group__c, g_customer_id__c, g_group_id__c
        FROM Custom_Association__c
        WHERE g_customer_id__c = :prospectCustomerId
          AND DMT_Line__c != null
      ];
    } else if (!customAssociationIds.isEmpty()) {
      customAssociationsLine = [
        SELECT Id, Group__c, g_customer_id__c, g_group_id__c
        FROM Custom_Association__c
        WHERE Id IN :customAssociationIds
      ];
    }
    
    for (Custom_Association__c ca : customAssociationsLine) {
      ca.Group__c = groupAccountId;
      ca.g_customer_id__c = clientToMerge.g_customer_id__c;
      ca.g_group_id__c = groupCode;
    }

    // 8. Consultar y actualizar Custom_Association_Opportunity__c (Oportunidades)
    List<Custom_Association_Opportunity__c> customAssociationsOpp = new List<Custom_Association_Opportunity__c>();
    if (String.isNotBlank(prospectCustomerId)) {
      customAssociationsOpp = [
        SELECT Id, Group__c, g_customer_id__c, g_group_id__c
        FROM Custom_Association_Opportunity__c
        WHERE g_customer_id__c = :prospectCustomerId
          AND Opportunity__c != null
      ];
    }
    
    for (Custom_Association_Opportunity__c cao : customAssociationsOpp) {
      cao.Group__c = groupAccountId;
      cao.g_customer_id__c = clientToMerge.g_customer_id__c;
      cao.g_group_id__c = groupCode;
    }

    // 9. Consultar y actualizar Custom_Association_Client__c (Lineas)
    List<Custom_Association_Client__c> customAssociationClients = new List<Custom_Association_Client__c>();
    if (String.isNotBlank(prospectCustomerId)) {
      customAssociationClients = [
        SELECT Id, Name, Alpha_Code_Client__c, Local_Client_Child__c, g_customer_id__c, g_entific_id__c
        FROM Custom_Association_Client__c
        WHERE g_customer_id__c = :prospectCustomerId
      ];
    } else if (!customAssociationIds.isEmpty()) {
      customAssociationClients = [
        SELECT Id, Name, Alpha_Code_Client__c, Local_Client_Child__c, g_customer_id__c, g_entific_id__c
        FROM Custom_Association_Client__c
        WHERE Custom_Association__c IN :customAssociationIds
      ];
    }
    
    for (Custom_Association_Client__c cac : customAssociationClients) {
      if (localClient != null) {
        cac.Alpha_Code_Client__c = localClient.Alpha_code__c;
        cac.Local_Client_Child__c = localClient.Id;
      }
      cac.g_customer_id__c = clientToMerge.g_customer_id__c;
      cac.g_entific_id__c = entificId;
      cac.Name = clientToMerge.Name;
    }

    // 10. Consultar y actualizar DMT_Opportunity_Client__c (Oportunidades)
    List<DMT_Opportunity_Client__c> opportunityClients = new List<DMT_Opportunity_Client__c>();
    if (String.isNotBlank(prospectCustomerId)) {
      opportunityClients = [
        SELECT Id, Alpha_Code_Client__c
        FROM DMT_Opportunity_Client__c
        WHERE Alpha_Code_Client__c = :prospectCustomerId
      ];
    }
    
    for (DMT_Opportunity_Client__c oc : opportunityClients) {
      if (localClient != null) {
        oc.Alpha_Code_Client__c = localClient.Alpha_code__c;
      }
    }

    updateList(linesToUpdate);
    updateList(customAssociationsLine);
    updateList(customAssociationsOpp);
    updateList(customAssociationClients);
    updateList(opportunityClients);
  }

  /*
  * Entrada del method invocable addMemberGroup
  */
  public class WrapperMerge {
    /*
    * Id del prospect
    */
    @InvocableVariable(label='Id del prospect' required=false)
    public String idProspect; //NOSONAR

    /**
    * Id del cliente al que se va a mergear
    */
    @InvocableVariable(label='Id del cliente' required=false)
    public String idClient; //NOSONAR

    /**
    * Id del localClient
    */
    @InvocableVariable(label='Id del cliente local' required=false)
    public String idLocalClient; //NOSONAR

    /**
    * Lista de Arces
    */
    @InvocableVariable(label='Lista de Arce' required=false)
    public List<arce__Account_has_Analysis__c> arceList; //NOSONAR

    /**
    * Lista de Arces
    */
    @InvocableVariable(label='Tiene ARCE' required=false)
    public Boolean hasNoArce; //NOSONAR

    /**
    * Nombre local client
    */
    @InvocableVariable(label='Local Client Name' required=false)
    public String lClientName; //NOSONAR

    /**
    * Nombre local client
    */
    @InvocableVariable(label='Local Client Alpha' required=false)
    public String lClientAlpha; //NOSONAR
  }

}