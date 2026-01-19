/*
 * @author GlobalDesktop
 * @description Clase test de las clases InitiativeNotificationBatch y InitiativeNotificationScheduler
 */
@isTest
public class InitiativeNotificationScheduler_Test {
  /*
  * Fecha en la que el test programa la ejecución
  */
  static final String CRON_EXP = '0 0 0 15 3 ? 2032';

  /*
   * Variable string
   */
  static final String MEDIUM = 'Medium';

  /*
   * Variable string
   */
  static final String DRAFT = 'Draft';

  /*
   * Variable string
   */
  static final String TST = 'Test';

  /*
  * Met0d0 que crea los registros necesarios para cubrir las clases
  */

  private static List<Campaign> createInitt() {
    final Campaign initiative1 = new Campaign(
      Name = 'TestInitiative1',
      cond__priority_campaign_type__c = MEDIUM,
      Status = DRAFT,
      StartDate = Date.today(),
      EndDate = Date.today().addDays(15),
      Description = TST,
      Opportunity_goal__c = 1,
      Pitch_goal__c = 1,
      Visit_goal__c = 1,
      RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId()
    );
    final Campaign initiative2 = new Campaign(
      Name = 'TestInitiative2',
      cond__priority_campaign_type__c = MEDIUM,
      Status = DRAFT,
      StartDate = Date.today(),
      EndDate = Date.today().addDays(1),
      Description = TST,
      Opportunity_goal__c = 1,
      Pitch_goal__c = 1,
      Visit_goal__c = 1,
      RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId()
    );
    final Campaign initiative3 = new Campaign(
      Name = 'TestInitiative3',
      cond__priority_campaign_type__c = MEDIUM,
      Status = DRAFT,
      StartDate = Date.today(),
      EndDate = Date.today().addDays(1),
      Description = TST,
      Opportunity_goal__c = 1,
      Pitch_goal__c = 1,
      Visit_goal__c = 1,
      RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId()
    );
    final Campaign initiative4 = new Campaign(
      Name = 'TestInitiative4',
      cond__priority_campaign_type__c = MEDIUM,
      Status = DRAFT,
      StartDate = Date.today(),
      EndDate = Date.today().addDays(15),
      Description = TST,
      Opportunity_goal__c = 1,
      Pitch_goal__c = 1,
      Visit_goal__c = 1,
      RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId()
    );
    final Campaign initiative5 = new Campaign(
      Name = 'TestInitiative5',
      cond__priority_campaign_type__c = MEDIUM,
      Status = DRAFT,
      StartDate = Date.valueOf('2020-01-01'),
      EndDate = Date.valueOf('2020-01-05'),
      Description = TST,
      Opportunity_goal__c = 1,
      Pitch_goal__c = 1,
      Visit_goal__c = 1,
      RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId()
    );
    final List<Campaign> initiatives = new List<Campaign> {initiative1, initiative2, initiative3,initiative4, initiative5};
    System.debug(initiatives);

    return initiatives;
  }

  private static List<cond__Account_Campaign__c> createInittHija(Account client, List<Campaign> initiatives) {
    final cond__Account_Campaign__c inttHija1 = new cond__Account_Campaign__c(
      cond__participant_id__c = client.Id,
      cond__campaign_id__c = initiatives[1].Id,
      cond__campaign_desc__c = TST,
      cond__priority_campaign_type__c = MEDIUM,
      cond__Campaign_status_approval_type__c = DRAFT
    );
    final cond__Account_Campaign__c inttHija2 = new cond__Account_Campaign__c(
      cond__participant_id__c = client.Id,
      cond__campaign_id__c = initiatives[3].Id,
      cond__campaign_desc__c = TST,
      cond__priority_campaign_type__c = MEDIUM,
      cond__Campaign_status_approval_type__c = DRAFT
    );
    final cond__Account_Campaign__c inttHija3 = new cond__Account_Campaign__c(
      cond__participant_id__c = client.Id,
      cond__campaign_id__c = initiatives[4].Id,
      cond__campaign_desc__c = TST,
      cond__priority_campaign_type__c = MEDIUM,
      cond__Campaign_status_approval_type__c = DRAFT
    );
    final List<cond__Account_Campaign__c> inttHijas = new List<cond__Account_Campaign__c> {inttHija1, inttHija2, inttHija3};
    System.debug(inttHijas);

    return inttHijas;
  }

  private static List<intt__Team_initiative__c> createMember(List<Campaign> initiatives, User user, List<cond__Account_Campaign__c> inttHija) {
    intt__Team_initiative__c member1;
      member1 = new intt__Team_initiative__c(
      intt__campaign_id__c = initiatives[0].Id,
      intt__manager_team_id__c = user.Id
    );
    intt__Team_initiative__c member2;
      member2 = new intt__Team_initiative__c(
      intt__gf_group_campaign_id__c = inttHija[0].Id,
      intt__manager_team_id__c = user.Id
    );
    intt__Team_initiative__c member3;
      member3 = new intt__Team_initiative__c(
      intt__campaign_id__c = initiatives[2].Id,
      intt__manager_team_id__c = user.Id
    );
    intt__Team_initiative__c member4;
      member4 = new intt__Team_initiative__c(
      intt__campaign_id__c = initiatives[2].Id,
      intt__manager_team_id__c = user.Id
    );
    intt__Team_initiative__c member5;
      member5 = new intt__Team_initiative__c(
      intt__gf_group_campaign_id__c = inttHija[1].Id,
      intt__manager_team_id__c = user.Id
    );
    intt__Team_initiative__c member6;
      member6 = new intt__Team_initiative__c(
      intt__gf_group_campaign_id__c = inttHija[1].Id,
      intt__manager_team_id__c = user.Id
    );
    intt__Team_initiative__c member7;
      member7 = new intt__Team_initiative__c(
      intt__campaign_id__c = initiatives[4].Id,
      intt__manager_team_id__c = user.Id
    );
    final List<intt__Team_initiative__c> members = new List<intt__Team_initiative__c> {member1, member2, member3, member4, member5, member6, member7};
    System.debug(members);

    return members;
  }

  @testSetup static void testSetup() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

    final User user = utilTestClass.createUser(utilTestClass.createProfile(), 'usertest1@bbvatest.com');
    insert user;

    final Account client = utilTestClass.createClient();
    insert client;

    final List<Campaign> initiatives = createInitt();
    insert initiatives;

    final List<cond__Account_Campaign__c> inttHijas = createInittHija(client, initiatives);
    insert inttHijas;

    final List<intt__Team_initiative__c> members = createMember(initiatives, user, inttHijas);
    insert members;
  }

  /*
  * Met0d0 que programa la ejecución del batch
  */
  @isTest static void testScheduleBatch() {

    Test.startTest();

    System.schedule('TestInitiativeNotification', CRON_EXP, new InitiativeNotificationScheduler());

    Test.stopTest();

    final Campaign initiative = [SELECT Id, Name FROM Campaign WHERE Name = 'TestInitiative1' LIMIT 1];
    System.assertEquals('TestInitiative1', initiative.Name, 'El batch ha fallado');
  }
  /*
  * Met0d0 que prueba el batch
  */
  @isTest static void testBatch() {
    Test.startTest();

    final String query = 'SELECT Id, intt__manager_team_id__c, intt__manager_team_id__r.Email, ' +
      'intt__campaign_id__c, intt__gf_group_campaign_id__c, ' +
      'intt__campaign_id__r.Id, intt__campaign_id__r.Name, intt__campaign_id__r.EndDate, ' +
      'intt__gf_group_campaign_id__r.cond__campaign_id__c, ' +
      'intt__gf_group_campaign_id__r.cond__campaign_id__r.Id, intt__gf_group_campaign_id__r.cond__campaign_id__r.Name, ' +
      'intt__gf_group_campaign_id__r.cond__campaign_id__r.EndDate ' +
      'FROM intt__Team_initiative__c ' +
      'WHERE (intt__campaign_id__r.EndDate = :expiration1 ' +
      'OR intt__gf_group_campaign_id__r.cond__campaign_id__r.EndDate = :expiration1 ' +
      'OR intt__campaign_id__r.EndDate = :expiration2 ' +
      'OR intt__gf_group_campaign_id__r.cond__campaign_id__r.EndDate = :expiration2)';

    final Id batchJobId = Database.executeBatch(new InitiativeNotificationBatch(query));
    System.debug(batchJobId);

    Test.stopTest();

    final Campaign initiative = [SELECT Id, Status FROM Campaign WHERE Name = 'TestInitiative5' LIMIT 1];
    System.assertEquals('Ended', initiative.Status, 'El batch no ha ejecutado el final');
  }
}