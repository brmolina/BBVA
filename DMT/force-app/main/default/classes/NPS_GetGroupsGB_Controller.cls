/**
 *
 * @author Global Desktop
 */
public with sharing class NPS_GetGroupsGB_Controller {
  /**
   * @author Global Desktop
   */
  public String varUserId {get; set;}
  /**
   * @author Global Desktop
   */
  public String varWave {get; set;}
  /**
   * @author Global Desktop
   */
  public String varInit {
    get;
    set {
      getListNPSClients();
    }
  }
  /**
   * @author Global Desktop
   */
  public Map<String, String> listClient {get; set;}

  /**
   *   @author Global Desktop
   *   @method getListNPSClients
   */
  public void getListNPSClients() {
    this.listClient = new Map<String, String>();
    System.debug('::::::::::controller');
    final List<NPS_Wave__c> listNPSWave = [SELECT Id, //NOSONAR
                                            gf_nps_sv_cust_oper_cntry_desc__c
                                          FROM NPS_Wave__c
                                          WHERE Id = :this.varWave
                                            AND gf_nps_sv_cust_oper_cntry_desc__c != null];

    final Map<Id, Account> mapAccounts = new Map<Id, Account>();
    final Map<Id, Account> mapAccountsGroup = new Map<Id, Account>();
    System.debug('::::::::::npsNotification');
    for(Account iAccount : [SELECT Id,
                              Name,
                              DES_Country_Client__c,
                              DES_Global_banker__c,
                              RecordTypeId,
                              RecordType.DeveloperName,
                              (SELECT Id,
                                OwnerId,
                                AccountId,
                                Owner.Email
                              FROM Contacts),
                              (SELECT Id,
                                DES_User__c,
                                DES_Member_Role__c
                              FROM BBVA_Client_teams__r
                              WHERE (DES_Member_Role__c =: Label.DES_ROLE_GLOBAL_BANKER
                                OR DES_Member_Role__c =: Label.DES_Role_Transactional_Banker))
                            FROM Account
                            WHERE survey_nps_contact_type__c = true]) {
      mapAccounts.put(iAccount.Id, iAccount);
      if(iAccount.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_STR_TYPE_Group).getRecordTypeId()
        || iAccount.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_NAME_COMMERCIAL_CLIENT).getRecordTypeId()
        || iAccount.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_BEC_Manually_Group).getRecordTypeId()) {
        mapAccountsGroup.put(iAccount.Id, iAccount);
      }
    }

    System.debug('::::::::::npsAux');
    npsNotificationAux(listNPSWave, mapAccounts, mapAccountsGroup);
  }

  /**
   *   @author Global Desktop
   *   @method npsNotificationAux
   */
  public void npsNotificationAux(List<NPS_Wave__c> listNPSWave, Map<Id, Account> mapAccounts, Map<Id, Account> mapAccountsGroup) {
    final Map<Id, List<Id>> mapGroupSub = NPS_Wave_Helper_Aux.getGroupRelation(mapAccounts, mapAccountsGroup); //NOSONAR

    final Map<Id, Account> listClientName = new Map<Id, Account>();
    for(NPS_Wave__c iNPSWave : listNPSWave) {
      for(Id iAccountId : mapAccounts.keySet()) {
        if(iNPSWave.gf_nps_sv_cust_oper_cntry_desc__c.containsIgnoreCase(mapAccounts.get(iAccountId).DES_Country_Client__c) == true
          && mapAccounts.get(iAccountId).Contacts.isEmpty()
          && mapAccountsGroup.containsKey(iAccountId)) {
          final Boolean filialHasContact = NPS_Wave_Helper_Aux.filialHasContactFunc(mapAccounts, mapGroupSub, iAccountId);
          final Id userIdAux = NPS_Wave_Helper_Aux.getUserId(mapAccountsGroup, iAccountId);
          if(filialHasContact == false
            && !listClientName.containsKey(mapAccountsGroup.get(iAccountId).Id)
            && userIdAux == varUserId) {
            System.debug('::::::::::addlistclientname');
            listClientName.put(mapAccountsGroup.get(iAccountId).Id, mapAccountsGroup.get(iAccountId));
          }
        }
      }
    }
    System.debug('::::::::::listClientName: ' + listClientName);
    getListClientURL(listClientName);
  }

  /**
   *   @author Global Desktop
   *   @method npsNotificationAux
   */
  public void getListClientURL(Map<Id, Account> listClientName) {
    if(!listClientName.isEmpty()) {
      for(Id accountId: listClientName.keySet()) {
        final String url = System.URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Account/' + accountId + '/view';
        this.listClient.put(url, listClientName.get(accountId).Name);
      }
    }
  }
}