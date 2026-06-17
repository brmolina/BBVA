/************************************************************************
 * @name:                GBL_TestDataFactory_Initiative
 * @author               bbva.com developers
 * @date:                2019
 * @version:             1.0
 * @group:               Global Desktop
 * @description:         Test class GBL_TestDataFactory_Initiative
 ***************************************************************************/
@istest
public class GBL_TestDataFactory_Initiative{
  /*
   * Variable string cuenta
   */
  static final String ACC2 = 'Acc2';
  /*
   * Variable string cuenta
   */
  static final String VISITA = 'Visit';
  /*
   * Variable string cuenta
   */
  static final String PITCHS = 'Pitch';
  /*
   * Variable string cuenta
   */
  static final String DESCR = 'des';
  /*
   * Variable string
   */
  static final String ENDED = 'Ended';
  /*
   * Variable string
   */
  static final String HIGH = 'High';
  /*
   * Variable string
   */
  static final String CAMPA2 = 'Camp2';
  /*
   * Variable string
   */
  static final String CIBPLATINUM = 'CIB-Platinum';
  /*
   * Variable string
   */
  static final String CORPORATE = 'Corporate';
  /*
   * Variable string
   */
  static final String INITIATIVE = 'Initiative';
  /*
   * Variable string
   */
  static final String ESPANA = 'ESPAÑA';
  /*
   * Variable string
   */
  static final String PENDING = 'Pending';
  /*
   * Variable string
   */
  static final String DRAFT = 'Draft';
  /*
   * Variable int uno
   */
  private static final Integer ONE = 1;
  /*
   * Variable int dos
   */
  private static final Integer TWO = 2;
  /*
   * Variable int dos
   */
  private static final Integer THREE = 3;
  /**
   * Met0d0 para permitir que la clase sea de test, no tener en cuenta.
   */
  @isTest
  public static void test1(){
    Boolean prueba;
    prueba = true;
    system.assert(prueba, 'msg');
  }

  /**
   * @author Global Desktop
   * @description crea DES_Booking__c
   */
  public static void newDb(String country){
    final Account acc = createAcc();

    DES_Booking__c desBook;
    desBook = new DES_Booking__c();
    desBook.DES_Client__c = acc.Id;
    desBook.DES_Country__c = country;
    insert desBook;
  }

  /**
   * @author Global Desktop
   * @description crea una cuenta en función del typex
   */
  public static void newAccount(Integer numberx, Integer typex){
    if (typex == ONE){
      List<Account> accts;
      accts = new List<Account>();
      for (Integer i = 0; i < numberx; i++){
        Account acc;
        acc = new Account(
          Name = 'TestAccount' + i
        );
        accts.add(acc);
      }
      insert accts;
    } else if (typex == TWO){
      Account acc3;
      acc3 = new Account();
      acc3.Name = 'Acc3';
      acc3.DES_Segment__c = '00004'; // Others
      insert acc3;
    }
  }

  /**
   * @author Global Desktop
   * @description crea un cond__Account_Campaign__c
   */
  public static void newCondCamp(Integer numberx, Integer typex){
    if (typex == ONE){
      final User objUser = GBL_TestDataFactory_Initiative.getUser(true);
      system.debug(objUser);

      final Account acc = createAcc();
      system.debug(acc);
    } else if (typex == TWO){
      final Id recType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Initiative').getRecordTypeId();
      system.debug(recType);

      final Account acc = createAcc();

      Campaign camp2;
      camp2 = GBL_TestDataFactory_Initiative_AUX.newCampaign(typex);
      cond__Account_Campaign__c comAction2;
      comAction2 = GBL_TestDataFactory_Initiative_AUX.getAccountCampain(camp2, acc, false);
    } else if (typex == THREE){
      User objUser;
      objUser = GBL_TestDataFactory_Initiative.getUser(true);

      final Account acc = createAcc();

      DES_BBVA_Management_team__c maTeam;
      maTeam = new DES_BBVA_Management_team__c();
      maTeam.DES_User__c = objUser.Id;
      maTeam.DES_Client__c = acc.Id;
      maTeam.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
      insert maTeam;

      Campaign camp2;
      camp2 = GBL_TestDataFactory_Initiative_AUX.newCampaign(typex);

      cond__Account_Campaign__c comAction2;
      comAction2 = GBL_TestDataFactory_Initiative_AUX.getAccountCampain(camp2, acc, false);
      comAction2.cond__Campaign_status_approval_type__c = DRAFT;
      comAction2.cond__Participant_id__c = acc.Id;
      update comAction2;
      comAction2.cond__Campaign_status_approval_type__c = 'Discarded';
      update comAction2;
    }
  }

  /**
   * @author Global Desktop
   */
  public static void newOpportunityGroup(Integer numberx, String condStatus){
    List<intt__Opportunity_Group__c> lstOpportunity;
    lstOpportunity = new List<intt__Opportunity_Group__c>();
    intt__Opportunity_Group__c opp;
    opp = new intt__Opportunity_Group__c();
    cond__Account_Campaign__c cond;
    cond = new cond__Account_Campaign__c();
    List<cond__Account_Campaign__c> listCond;
    listCond = GBL_TestDataFactory_Initiative_AUX.newCondCampRet(1, 3);
    cond = listCond.get(0);
    cond.cond__Campaign_status_approval_type__c = condStatus;
    update cond;
    for (Integer i = 0; i < numberx; i++){
      opp.intt__participant_id__c = cond.Id;
      lstOpportunity.add(opp);
    }
    insert lstOpportunity;
  }

  private static Account createAcc(){
    final Account acc = new Account();
    acc.Name = ACC2;

    insert acc;
    return acc;
  }

  /**
   * @author Global Desktop
   */
  public static void handlerTestVisitPitch(String typeTest, String objectss){
    if (typeTest == PENDING || typeTest == 'Duplicated'){
      final Account acc = createAcc();
      System.debug(acc);
      final Campaign camp1 = GBL_TestDataFactory_Initiative_AUX.newCampaign(0);

      User objUser;
      objUser = GBL_TestDataFactory_Initiative.getUser(true);
      GBL_TestDataFactory_Initiative.getTeamInitiative(camp1, objUser, true);

      if (objectss == VISITA){
        final dwp_kitv__Visit__c visit = GBL_TestDataFactory_Initiative_AUX.createVisit(acc);
        System.debug(visit);
      } else if (objectss == PITCHS){
        final pith__Pitch__c pitch = GBL_TestDataFactory_Initiative_AUX.createPitch(acc);
        system.debug(pitch);
      }

      camp1.Status = PENDING;
      update camp1;
    } else if (typeTest == 'Delete' || typeTest == 'New'){
      final Account acc = createAcc();
      final Campaign camp1 = GBL_TestDataFactory_Initiative_AUX.newCampaign(0);

      User objUser;
      objUser = GBL_TestDataFactory_Initiative.getUser(true);
      GBL_TestDataFactory_Initiative_AUX.getAccountCampain(camp1, acc, true);
      GBL_TestDataFactory_Initiative.getTeamInitiative(camp1, objUser, true);

      camp1.Status = PENDING;
      update camp1;

      cond__Account_Campaign__c comAction;
      comAction = GBL_TestDataFactory_Initiative_AUX.getAccountCampain(camp1, acc, false);
      comAction.cond__Campaign_status_approval_type__c = DRAFT;
      comAction.cond__campaign_id__c = camp1.Id;
      comAction.cond__participant_id__c = acc.Id;
      // insert comAction;

      if (objectss == VISITA){
        final dwp_kitv__Visit__c visit = GBL_TestDataFactory_Initiative_AUX.createVisit(acc);
        System.debug(visit);
      } else if (objectss == PITCHS){
        final pith__Pitch__c pitch = GBL_TestDataFactory_Initiative_AUX.createPitch(acc);
        System.debug(pitch);
      }
    }
  }

  /**
   * @author Global Desktop
   */
  public static user getUser(boolean bolInsert){
    User user;
    user = new User(
      ProfileId = [SELECT Id
                   FROM Profile
                   WHERE Name = 'System Administrator'].Id, 
      LastName = 'last', 
      Email = 'puser000@amamama.com', 
      Username = 'puser000@amamama.com' + System.currentTimeMillis(), 
      CompanyName = 'TEST', 
      Title = 'title', 
      Alias = 'alias', 
      TimeZoneSidKey = 'America/Los_Angeles', 
      EmailEncodingKey = 'UTF-8', 
      LanguageLocaleKey = 'en_US', 
      LocaleSidKey = 'en_US', 
      ID_User__c = String.valueOf(Datetime.now())
    );

    if (bolInsert){
      insert user;
    }

    return user;
  }

  /**
   * @author Global Desktop
   */
  public static user getStandardUser(boolean bolInsert){
    User user;
    user = new User(
      ProfileId = [SELECT Id
                   FROM Profile
                   WHERE Name = 'BBVA Standard User'].Id, 
      LastName = 'standardlast', 
      Email = 'stduser000@amamama.com', 
      Username = 'stduser000@amamama.com' + System.currentTimeMillis(), 
      CompanyName = 'TEST', 
      Title = 'title', 
      Alias = 'stdalias', 
      TimeZoneSidKey = 'America/Los_Angeles', 
      EmailEncodingKey = 'UTF-8', 
      LanguageLocaleKey = 'en_US', 
      LocaleSidKey = 'en_US', 
      ID_User__c = String.valueOf(Datetime.now())
    );

    if (bolInsert){
      insert user;
    }

    return user;
  }

  /**
   * @author Global Desktop
   */
  public static intt__Team_initiative__c getTeamInitiative(Campaign camp, User user, boolean bolInsert){
    intt__Team_initiative__c team;
    team = new intt__Team_initiative__c();
    team.intt__campaign_id__c = camp.Id;
    team.intt__manager_team_id__c = user.Id;

    if (bolInsert){
      insert team;
    }
    return team;
  }

}