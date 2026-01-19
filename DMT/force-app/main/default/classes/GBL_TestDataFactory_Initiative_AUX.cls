/************************************************************************
 * @name:                GBL_TestDataFactory_Initiative_AUX
 * @author               bbva.com developers
 * @date:                2019
 * @version:             1.0
 * @group:               Global Desktop
 * @description:         Test class GBL_TestDataFactory_Initiative_AUX
 ***************************************************************************/
@isTest
public class GBL_TestDataFactory_Initiative_AUX {

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
  public static void test1() {
    Boolean prueba;
    prueba = true;
    system.assert (prueba, 'msg');
  }

  /**
  * @author Global Desktop
  * @description crea un Campaign
  */
  public static Campaign newCampaign(Integer typex) {
    Campaign camp;
    camp = new Campaign();

    if(typex == ONE) {
      camp.Status = system.Label.Draft_Status;
      camp.Name = 'camp1';
      camp.cond__priority_campaign_type__c = HIGH;
      camp.tier_desc__c = CIBPLATINUM;
      camp.segment_desc__c = CORPORATE;
      final Id recType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get(INITIATIVE).getRecordTypeId();
      camp.RecordTypeId = recType;
      camp.StartDate = system.today();
      camp.EndDate = system.today().addDays(7);
      camp.country_name__c = ESPANA;
      camp.solution_name_path_desc__c = '';
      camp.description= DESCR;

    } else if(typex == TWO || typex == THREE) {
      camp.Status = ENDED;
      camp.Name = CAMPA2;
      camp.tier_desc__c = CIBPLATINUM;
      camp.segment_desc__c = CORPORATE;
      camp.country_name__c = ESPANA;
      camp.cond__priority_campaign_type__c=HIGH;
      final Id recType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get(INITIATIVE).getRecordTypeId();
      camp.RecordTypeId = recType;
      camp.StartDate = system.today();
      camp.EndDate = system.today().addDays(7);
      camp.solution_name_path_desc__c = '';
      camp.description = DESCR;

    } else {
      camp.Status = DRAFT;
      camp.Name = 'camp885';
      camp.tier_desc__c = 'CIB-Gold';
      camp.segment_desc__c = 'Corporate;Others';
      final Id recType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get(INITIATIVE).getRecordTypeId();
      camp.RecordTypeId = recType;
      camp.StartDate = system.today();
      camp.EndDate = system.today().addDays(7);
      camp.country_name__c = ESPANA;
      camp.cond__priority_campaign_type__c=HIGH;
      camp.description = DESCR;
    }

    insert camp;
    return camp;
  }

  /**
   * @author Global Desktop
   */
  public static cond__Account_Campaign__c getAccountCampain(Campaign camp, Account acc, Boolean bolInsert) {
    cond__Account_Campaign__c objRelatedAccount = new cond__Account_Campaign__c();

    objRelatedAccount.cond__Campaign_status_approval_type__c = DRAFT;
    objRelatedAccount.cond__campaign_id__c = camp.Id;
    objRelatedAccount.cond__participant_id__c = acc.Id;
    objRelatedAccount.cond__data_source_name__c = INITIATIVE;
    objRelatedAccount.cond__priority_campaign_type__c = HIGH;
    objRelatedAccount.cond__solution_category_name__c = INITIATIVE;
    objRelatedAccount.cond__campaign_desc__c = INITIATIVE;
    objRelatedAccount.cond__campaign_name__c = INITIATIVE;
    objRelatedAccount.cond__solution_category_type__c = INITIATIVE;

    if(bolInsert) {
      insert objRelatedAccount;
    }
    return objRelatedAccount;
  }

  private static Account createAcc() {
    final Account acc = new Account();
    acc.Name = ACC2;

    insert acc;
    return acc;
  }

  private static cond__Account_Campaign__c createAccCamp(Campaign camp2, Account acc) {
    final cond__Account_Campaign__c comAction2 = new cond__Account_Campaign__c();
    comAction2 = GBL_TestDataFactory_Initiative_AUX.getAccountCampain(camp2,acc,false);
    comAction2.cond__Campaign_status_approval_type__c = 'Status';
    comAction2.cond__campaign_id__c = camp2.Id;

    insert comAction2;
    return comAction2;
  }

  /**
   * @author Global Desktop
   */
  public static List<cond__Account_Campaign__c> newCondCampRet(Integer numberx, Integer typex) {
    List<cond__Account_Campaign__c> lstGroup;
    lstGroup = new List<cond__Account_Campaign__c>();

    if (typex == ONE) {

      Campaign camp2;
      camp2 = GBL_TestDataFactory_Initiative_AUX.newCampaign(typex);

      final Account acc = createAcc();

      User objUser;
      objUser = GBL_TestDataFactory_Initiative.getUser(true);
      // GBL_TestDataFactory_Initiative_AUX.getAccountCampain(camp2,acc,true);
      GBL_TestDataFactory_Initiative.getTeamInitiative(camp2, objUser, true);

      camp2.Status = PENDING;
      update camp2;

      final cond__Account_Campaign__c comAction2 = createAccCamp(camp2, acc);
      lstGroup.add(comAction2);
    }

    if (typex == TWO) {

      for(Integer i = 0; i < numberx; i++) {
        Campaign camp2;
        camp2 = GBL_TestDataFactory_Initiative_AUX.newCampaign(typex);

        final Account acc = createAcc();
        final cond__Account_Campaign__c comAction2 = createAccCamp(camp2, acc);
        lstGroup.add(comAction2);
      }
    }

    if (typex == THREE) {

      Campaign camp2;
      camp2 = GBL_TestDataFactory_Initiative_AUX.newCampaign(typex);

      final Account acc = createAcc();
      final cond__Account_Campaign__c comAction2 = createAccCamp(camp2, acc);
      lstGroup.add(comAction2);

      User objUser;
      objUser = GBL_TestDataFactory_Initiative.getUser(true);
      GBL_TestDataFactory_Initiative.getTeamInitiative(camp2, objUser, true);

      camp2.Status = PENDING;
      update camp2;
    }
    return lstGroup;
  }

  /**
   * @author Global Desktop
   */
  public static dwp_kitv__Visit__c createVisit(Account acc) {
    final dwp_kitv__Visit__c visit = new dwp_kitv__Visit__c();
    visit.dwp_kitv__account_id__c = acc.Id;
    visit.Name = 'Test Visit';

    insert visit;
    return visit;
  }

  /**
   * @author Global Desktop
   */
  public static pith__Pitch__c createPitch(Account acc) {
    final pith__Pitch__c pitch = new pith__Pitch__c ();
    pitch.pith__participant_id__c = acc.Id;
    pitch.Name = 'Test Pitch';

    insert pitch;
    return pitch;
  }
}