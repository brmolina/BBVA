/**********************************************************************************
* @author       Global Desktop
* @date         16/01/2020
* @description  Helper del handler de cond__Account_Campaign__c
**********************************************************************************/
public with sharing class Account_Campaign_Helper {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Account_Campaign_Helper instance;
  
  /*Variable global*/
  private static final Integer MAXSIZE = 79;

  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Account_Campaign_Helper getInstance() { //NOSONAR
    if (instance == null) {
      instance = new Account_Campaign_Helper();
    }
    return instance;
  }

  /**
  * @author Global Desktop
  * @Description newTeamInitiative
  */
  public static void setNameAccountCampaing(final List<cond__Account_Campaign__c> newList) { //NOSONAR
    final Set<String> setIdClientes=new Set<String>();
    String name='';
    final List<Campaign> lstCampaign=[select id,name from Campaign where id=:newList[0].cond__campaign_id__c];

    //if(lstCampaign.size() > 0) {
    if(!lstCampaign.isEmpty()) {
      name = lstCampaign[0].name;
    }

    for(Integer i = 0; i < newList.size(); i ++) {
      setIdClientes.add(newList[i].cond__participant_id__c);
    }

    final Map<ID, Account> accountMap = new Map<ID, Account>([SELECT Id, Name FROM Account where id in: setIdClientes]);

    String strNameAC='';
    for(integer i = 0; i < newList.size(); i ++) {
      final Account acc = accountMap.get(newList[i].cond__participant_id__c);

      strNameAC = name + '-' + acc.name;
      if(strNameAC.length() > MAXSIZE) {
        strNameAC=strNameAC.substring(0,79);
      }

      newList[i].name = strNameAC;
    }

  }

  /**
  * @author Global Desktop
  * @description Empty Constructor
  */
  private Account_Campaign_Helper() {
    System.debug('Constructor empty');
  }

  /**
  * @author Global Desktop
  * @Description assignClientIDFiltered
  */
  public static void assignClientIDFiltered(final List<cond__Account_Campaign__c> newList) {
    for(cond__Account_Campaign__c iAccountCampaign : newList) {
      if(iAccountCampaign.Client_ID_Filtered__c != null) {
        iAccountCampaign.cond__participant_id__c = iAccountCampaign.Client_ID_Filtered__c;
      }
    }
  }

  /**
   * @author Global Desktop
   * @Description newTeamInitiative
   */
  public static void newTeamInitiative(final List<cond__Account_Campaign__c> newList) {
    final GBL_TeamInitiative iController = new GBL_TeamInitiative();
    final List<intt__Team_initiative__c> listTI = iController.clientInitiativeTeamFilterLocal(newList);
    insert listTI;
  }

  /**
   * @author Global Desktop
   * @Description checkDiscartedStatus
   */
  public static void checkDiscartedStatus(final List<cond__Account_Campaign__c> newList) {
    final Map<Id, intt__Team_initiative__c> mapAccCampTeam = new Map<Id, intt__Team_initiative__c>();
    Boolean bolErrorTeam = false;
    Boolean bolIsOnwer = false;

    for(intt__Team_initiative__c iTeamInitiative : [SELECT Id, intt__gf_group_campaign_id__c, intt__manager_team_id__c
                                                    FROM intt__Team_initiative__c
                                                    WHERE intt__gf_group_campaign_id__c IN :newList]) {
      if(UserInfo.getUserId() == iTeamInitiative.intt__manager_team_id__c) {
        mapAccCampTeam.put(iTeamInitiative.intt__gf_group_campaign_id__c, iTeamInitiative);
      }
    }

    final List<cond__Account_Campaign__c> iAccountCampaign = [SELECT Id, cond__campaign_id__r.ownerid, cond__campaign_id__c FROM cond__Account_Campaign__c WHERE id IN :newList];

    for(Integer i = 0; i < iAccountCampaign.size(); i ++) {
      if(mapAccCampTeam.isEmpty() || !mapAccCampTeam.containsKey(iAccountCampaign[i].Id)) {
        bolErrorTeam = true;
      }
      if(iAccountCampaign[i].cond__campaign_id__r.ownerid==UserInfo.getUserId()) {
        bolIsOnwer = true;
      }

      //valida si el usuario no esta en el equipo y no es owner
      if(bolErrorTeam == true && bolIsOnwer == false) {
        newList[i].addError(Label.Discarted_error);
      }
    }
  }
}