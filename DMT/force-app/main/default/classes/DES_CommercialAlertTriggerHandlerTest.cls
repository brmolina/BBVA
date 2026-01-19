@isTest
public class DES_CommercialAlertTriggerHandlerTest {

    /* Declarando variable */
    static Account acc, acc2;
    /* Declarando variable */
    static CIB_User_Org__c settings, settings1;
	/* Declarando variable */
    public static final String PRUEBADESC = 'Prueba';
    /* Declarando variable */
    public static final String PRIORITYHIGH = 'High';
    /* Declarando variable */
    public static final String BACKUP = 'backup';
    /* Declarando variable */
    private static final String IBFTYPE = 'Commercial Task IBF';

    @isTest(SeeAllData=true)
    /* Method 0 */
    public static void insertOneToOne() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);
        DES_BBVA_Management_Team__c accMember;
        accMember = createBBVAManagementTeamMember(user1, acc);
        final List<almd__Commercial_Alert__c> listCA = new List<almd__Commercial_Alert__c>();
        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        almd__Commercial_Alert__c comAl2;
        comAl2 = createAlert(user1, user2, acc, 1, IBFTYPE);
        comAl2.almd__owner_access_alert_id__c = 'pepe';
        comAl2.sf_no_db_authorizer_user_id__c = user1.FederationIdentifier;
        comAl2.sf_no_db_reject_user_id__c = user1.FederationIdentifier;
        comAl2.sf_no_db_user_id__c = user1.FederationIdentifier;
        comAl2.sf_no_db_monitor_manager_user_id__c = user1.FederationIdentifier;
        comAl2.sf_no_db_ori_manager_user_id__c = user1.FederationIdentifier;
        listCA.add(comAl1);
        listCA.add(comAl2);
        Test.startTest();
        try {
            insert listCA;
        } catch(Exception e) {    }
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 0, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 1 */
    public static void insertGroupByClient() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'Grouped By Client',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'Grouped By Client',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, 'Commercial Task GCC');
		final List<almd__Commercial_Alert__c> alertList = new List<almd__Commercial_Alert__c>();
        alertList.add(comAl1);

        Test.startTest();
        //insert comAl1;
        insert alertList;
    	final Set<Id> setIdsCuentas = CommercialAlertTriggerHandler.getSetIdCuentas(alertList);
        CommercialAlertTriggerHandler.getMapaAccounts(setIdsCuentas);
        final Map<Id, AccountTeamMember> mapEquiposCuenta = CommercialAlertTriggerHandler.getMapAccountMembers(setIdsCuentas);
        CommercialAlertTriggerHandler.setMapClientMembers(mapEquiposCuenta);
        final Map<String, Boolean> mapUserPriority = CommercialAlertTriggerHandler.userPriorityInfo(alertList);
        System.debug(mapUserPriority);

        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }


	@isTest(SeeAllData=true)
    /* Method 4 */
    public static void updateBanker() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        comAl1.almd__Transaction_type_desc__c = 'Cash Management';
        comAl1.almd__country_id__c = 'ES';

        Test.startTest();
        insert comAl1;
        comAl1.almd__User_id__c = user1.Id;
        update comAl1;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 5 */
    public static void bbvaTeam() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);
        DES_BBVA_Management_team__c bbvaTeam;
        bbvaTeam = createBBVAManagementTeamMember(user1, acc);
        System.debug(bbvaTeam);
        DES_BBVA_Management_team__c bbvaTeam2;
        bbvaTeam2 = createBBVAManagementTeamMember(user2, acc);
        System.debug(bbvaTeam2);
        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);

        Test.startTest();
        insert comAl1;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 6 */
    public static void bbvaTeamNotUser() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        DES_BBVA_Management_team__c bbvaTeam;
        bbvaTeam = createBBVAManagementTeamMember(user1, acc);
        System.debug(bbvaTeam);
        DES_BBVA_Management_team__c bbvaTeam2;
        bbvaTeam2 = createBBVAManagementTeamMember(user2, acc);
        System.debug(bbvaTeam2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = new almd__Commercial_Alert__c();
        comAl1.Name = 'Prueba Alerta1';
        comAl1.almd__owner_access_alert_id__c = user1.ID_User__c;
        comAl1.almd__commercial_alert_id__c = 'Id1';
        comAl1.almd__participant_id__c = acc.id;
        comAl1.almd__commercial_alert_start_date__c = system.today();
        comAl1.almd__commercial_alert_end_date__c = system.today();
        comAl1.almd__commercial_alert_record_type__c = IBFTYPE;
        comAl1.almd__commercial_alert_desc__c = PRUEBADESC;
        comAl1.almd__priority_alert_type__c = PRIORITYHIGH;
        comAl1.almd__data_source_name__c = 'Test';
        comAl1.almd__commercial_alert_task_type__c = BACKUP;
        Test.startTest();
        insert comAl1;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 7 */
    public static void wrongOwner() {
        Boolean message;
        message = false;
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);
        DES_BBVA_Management_team__c bbvaTeam;
        bbvaTeam = createBBVAManagementTeamMember(user1, acc);
        System.debug(bbvaTeam);
        DES_BBVA_Management_team__c bbvaTeam2;
        bbvaTeam2 = createBBVAManagementTeamMember(user2, acc);
        System.debug(bbvaTeam2);
        almd__Commercial_Alert__c comAl1;
        comAl1 = new almd__Commercial_Alert__c();
        comAl1.Name = 'Prueba Alerta1';
        comAl1.almd__owner_access_alert_id__c = 'pepe';
        comAl1.almd__commercial_alert_id__c = 'Id1';
        comAl1.almd__participant_id__c = acc.id;
        comAl1.almd__commercial_alert_start_date__c = system.today();
        comAl1.almd__commercial_alert_end_date__c = system.today();
        comAl1.almd__commercial_alert_record_type__c = IBFTYPE;
        comAl1.almd__commercial_alert_desc__c = PRUEBADESC;
        comAl1.almd__priority_alert_type__c = PRIORITYHIGH;
        comAl1.almd__data_source_name__c = 'Test';
        comAl1.almd__commercial_alert_task_type__c = BACKUP;

        Test.startTest();
        try {
            insert comAl1;
        } catch(Exception e) {
            message = true;
            system.debug(e.getMessage());
            system.assert(message, 'Correcto');
        }

        Test.stopTest();
    }


    @isTest(SeeAllData=true)
    /* Method 8 */
    public static void groupTwoClients() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        Account acc2;
        acc2 = createClient(groupRT, 'GC000012');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'Grouped By Client',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'Grouped By Client',2);
        DES_BBVA_Management_team__c bbvaTeam;
        bbvaTeam = createBBVAManagementTeamMember(user1, acc);
        System.debug(bbvaTeam);
        DES_BBVA_Management_team__c bbvaTeam2;
        bbvaTeam2 = createBBVAManagementTeamMember(user2, acc);
        System.debug(bbvaTeam2);
        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        almd__Commercial_Alert__c comAl2;
        comAl2 = createAlert(user1, user2, acc2, 2, IBFTYPE);
        almd__Commercial_Alert__c comAl3;
        comAl3 = createAlert(user1, user2, acc, 3, IBFTYPE);


        final List <almd__Commercial_Alert__c> listToInsert = new List<almd__Commercial_Alert__c>();
        listToInsert.add(comAl1);
        listToInsert.add(comAl2);
        listToInsert.add(comAl3);
        Test.startTest();
        insert listToInsert;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 3, insertedAlerts.size(),'Correcto' );

        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 9 */
    public static void notEditPermission() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'Grouped By Client',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'Grouped By Client',2);
        DES_BBVA_Management_team__c bbvaTeam;
        bbvaTeam = createBBVAManagementTeamMember(user1, acc);
        System.debug(bbvaTeam);
        DES_BBVA_Management_team__c bbvaTeam2;
        bbvaTeam2 = createBBVAManagementTeamMember(user2, acc);
        System.debug(bbvaTeam2);
        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user1, acc, 1, IBFTYPE);

        Test.startTest();
        insert comAl1;
        comAl1.almd__commercial_alert_desc__c = 'Prueba1';
        system.runAs(user2) {
            try {
                update comAl1;
            } catch(Exception e) {
                system.debug(e.getMessage());
                boolean contains = e.getMessage().contains('Insufficient Privileges: Commercial Alerts Task can only be modified by Task owner or');
                system.assert(contains,'Error');
            }
        }
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 10 */
    public static void notification() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1 = createAlert(user1, user2, acc, 1, 'Notification');

        Test.startTest();
        insert comAl1;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(), 'Correcto' );
        //List <FeedItem> feed = [Select Body from FeedItem ORDER BY CreatedDate desc LIMIT 1];
        //String expected = '@User Name Test2 User Last Name Test2 You have received a new notification Prueba Alerta1. Please, check it..';
        //String actual = feed[0].Body;
        //system.assertEquals(expected, actual);
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 11 */
    public static void updateUser() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, 'Commercial Task GTB');

        Test.startTest();
        insert comAl1;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(), 'Correcto' );
        comAl1.almd__owner_access_alert_id__c = user2.ID_User__c;
        comAl1.almd__User_id__c = user1.Id;
        system.runAs(user1) {
            update comAl1;
        }
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 12 */
    public static void oppWithoutAccept() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        insert comAl1;
        Test.startTest();
        system.runAs(user1) {
            try {
                Opportunity opp;
                opp = createOpportunity(acc, comAl1);
                insert opp;
            } catch(Exception e) {
                system.debug(e.getMessage());
            }
        }
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 13 */
    public static void oppWithoutAcceptUpdate() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        insert comAl1;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(), 'Correcto' );
        Opportunity opp;
        opp = createOpportunity(acc, null);
        insert opp;
        Test.startTest();
        system.runAs(user1) {
            try {
                opp.almd__commercial_alert_id__c = comAl1.Id;
                update opp;
            } catch(Exception e) {
                system.debug(e.getMessage());
            }
        }
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 14 */
    public static void oppPendingAlert() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        comAl1.almd__alert_stage_type__c = 'Pending Approval';
        comAl1.sf_no_db_authorizer_user_id__c = user1.FederationIdentifier;
        insert comAl1;
        Test.startTest();
        system.runAs(user1) {
            try {
                Opportunity opp;
                opp = createOpportunity(acc, comAl1);
                insert opp;
            } catch(Exception e) {
                system.debug(e.getMessage());
            }
        }
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto');
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 15 */
    public static void visitPendingAlert() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        comAl1.almd__alert_stage_type__c = 'Pending Approval';
        comAl1.sf_no_db_authorizer_user_id__c = user1.FederationIdentifier;
        insert comAl1;
        Test.startTest();
        system.runAs(user1) {
            try {
                dwp_kitv__Visit__c visit;
                visit = createVisit(acc, comAl1);
                insert visit;
            } catch(Exception e) {
                system.debug(e.getMessage());
            }
        }
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 16 */
    public static void visitPendingAlertUpdate() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        comAl1.almd__alert_stage_type__c = 'Pending Approval';
        comAl1.sf_no_db_authorizer_user_id__c = user1.FederationIdentifier;
        insert comAl1;
        dwp_kitv__Visit__c visit;
        visit = createVisit(acc, null);
        insert visit;
        Test.startTest();
        system.runAs(user1) {
            try {
                visit.almd__commercial_alert_id__c = comAl1.Id;
                update visit;
            } catch(Exception e) {
                system.debug(e.getMessage());
            }
        }
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 17 */
    public static void winAlertOpenOpp() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        comAl1.almd__client_process_accepted_type__c = true;
        comAl1.almd__execution_indicator_type__c = 'Test';
        Test.startTest();
        insert comAl1;
        comAl1.almd__alert_sub_stage_type__c = 'Won';
        system.runAs(user1) {
            try {
                Opportunity opp;
                opp = createOpportunity(acc, comAl1);
                insert opp;
                update comAl1;
            } catch(Exception e) {
                system.debug(e.getMessage());
            }
        }
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 18 */
    public static void winAlertLostOpp() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        comAl1.almd__client_process_accepted_type__c = true;
        comAl1.almd__execution_indicator_type__c = 'Test';
        Test.startTest();
        insert comAl1;
        comAl1.almd__alert_sub_stage_type__c = 'Won';
        system.runAs(user1) {
            try {
                Opportunity opp;
                opp = createOpportunity(acc, comAl1);
                opp.StageName = 'Closed Lost';
                insert opp;
                system.debug('>>>>>opp stage   ' + opp.StageName);
                update comAl1;
            } catch(Exception e) {
                system.debug(e.getMessage());
            }
        }
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto');
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 19 */
    public static void lostAlertOpenOpp() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        comAl1.almd__client_process_accepted_type__c = true;
        comAl1.almd__execution_indicator_type__c = 'Test';
        Test.startTest();
        insert comAl1;
        comAl1.almd__alert_sub_stage_type__c = 'Discarded';
        system.runAs(user1) {
            try {
                Opportunity opp;
                opp = createOpportunity(acc, comAl1);
                opp.StageName = 'Closed Won';
                insert opp;
                update comAl1;
            } catch(Exception e) {
                system.debug(e.getMessage());
            }
        }
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 20 */
    public static void winAlertVisitRequired() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        comAl1.almd__client_process_accepted_type__c = true;
        comAl1.almd__execution_indicator_type__c = 'Test';
        comAl1.almd__mandatory_visit_type__c = 'Yes';
        Test.startTest();
        insert comAl1;
        comAl1.almd__alert_stage_type__c = 'Closed';
        comAl1.almd__alert_sub_stage_type__c = 'Won';
        system.runAs(user1) {
            try {
                update comAl1;
            } catch(Exception e) {
                system.debug(e.getMessage());
            }
        }
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 21 */
    public static void winAlertOpenVisit() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        comAl1.almd__client_process_accepted_type__c = true;
        Test.startTest();
        insert comAl1;
        comAl1.almd__alert_stage_type__c = 'Closed';
        comAl1.almd__alert_sub_stage_type__c = 'Won';
        system.runAs(user1) {
            try {
                dwp_kitv__Visit__c visit;
                visit = createVisit(acc, comAl1);
                insert visit;
                update comAl1;
            } catch(Exception e) {
                system.debug(e.getMessage());
            }
        }
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto');
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 22 */
    public static void winAlertCloseVisit() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        almd__Commercial_Alert__c comAl1;
        comAl1 = createAlert(user1, user2, acc, 1, IBFTYPE);
        comAl1.almd__client_process_accepted_type__c = true;
        Test.startTest();
        insert comAl1;
        comAl1.almd__alert_stage_type__c = 'Closed';
        comAl1.almd__alert_sub_stage_type__c = 'Won';
        system.runAs(user1) {
            try {
                dwp_kitv__Visit__c visit;
                visit = createVisit(acc, comAl1);
                visit.dwp_kitv__visit_status_type__c = '05';
                insert visit;
                update comAl1;
            } catch(Exception e) {
                system.debug(e.getMessage());
            }
        }
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto' );
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 23 */
    public static void gbMatrix() {
        Id groupRT;
        groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Subsidiary').getRecordTypeId();
        Account acc;
        acc = createClient(groupRT, 'GC000011');
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, false, 'One to One',2);

        DES_Subsidiary_Group_Relation__c matrix;
        matrix = createMatrix(acc);
        insert matrix;

        almd__Commercial_Alert__c comAl1;
        comAl1 = new almd__Commercial_Alert__c();
        comAl1.Name = 'Prueba Alerta1';
        comAl1.almd__owner_access_alert_id__c = user1.ID_User__c;
        comAl1.almd__commercial_alert_id__c = 'Id1';
        comAl1.almd__participant_id__c = acc.id;
        comAl1.almd__commercial_alert_start_date__c = system.today();
        comAl1.almd__commercial_alert_end_date__c = system.today();
        comAl1.almd__commercial_alert_record_type__c = IBFTYPE;
        comAl1.almd__commercial_alert_desc__c = PRUEBADESC;
        comAl1.almd__priority_alert_type__c = PRIORITYHIGH;
        comAl1.almd__data_source_name__c = 'Test';
        comAl1.almd__commercial_alert_task_type__c = BACKUP;
        Test.startTest();
        insert comAl1;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto');
        Test.stopTest();
    }


    @isTest(SeeAllData=true)
    /* Method 23 */
    public static void alertsPS() {
        final Id subsidiaryRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Subsidiary').getRecordTypeId();
        final Id groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        final Account acc = createClient(groupRT, 'GC000011');
        final Account acc2 = createClient(subsidiaryRT, 'S000011');

        final String profileTest = createProfile();
        final User user1 = createUser(profileTest, true, true, true, 'One to One',1);
        final User user2 = createUser(profileTest, true, true, false, 'One to One',2);

        final DES_Subsidiary_Group_Relation__c matrix = createMatrix(acc2);
        matrix.participant_parent_id__c = acc.Id;
        insert matrix;


        final Product2 prod = new Product2();
        prod.Name = 'Client Resources';
        prod.isActive = true;
        prod.Family = 'GTB';
        insert prod;

        final Regional_Product_Specialist__c psMatrix = new Regional_Product_Specialist__c();
        psMatrix.DES_Country__c = 'CL';
        psMatrix.DES_Product__c = prod.Id;
        psMatrix.DES_Product_Specialist__c = user2.Id;
        insert psMatrix;

        final almd__Commercial_Alert__c comAl1 = createAlert(user1, user2, acc2, 10, 'Commercial Task GTB');
        comAl1.almd__owner_access_alert_id__c = null;
        comAl1.almd__country_id__c = 'CL';
        Test.startTest();
        insert comAl1;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto');
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    /* Method 23 */
    public static void gtbTransactionBanker() {
        final Id subsidiaryRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Subsidiary').getRecordTypeId();
        final Id groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        final Account acc = createClient(groupRT, 'GC000011');
        final Account acc2 = createClient(subsidiaryRT, 'S000011');

        final String profileTest = createProfile();
        final User user1 = createUser(profileTest, true, true, true, 'One to One',1);
        final User user2 = createUser(profileTest, true, true, false, 'One to One',2);

        final DES_Subsidiary_Group_Relation__c matrix = createMatrix(acc2);
        matrix.participant_parent_id__c = acc.Id;
        insert matrix;

        final DES_BBVA_Management_team__c bbvaMT = new DES_BBVA_Management_team__c();
        bbvaMT.DES_Client__c = acc.Id;
        bbvaMT.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
        bbvaMT.DES_Local_Banker_Country__c = 'AR';
        bbvaMT.DES_User__c = user2.Id;
        insert bbvaMT;

        final Product2 prod = new Product2();
        prod.Name = 'Client Resources';
        prod.isActive = true;
        prod.Family = 'GTB';
        insert prod;

        final almd__Commercial_Alert__c comAl1 = createAlert(user1, user2, acc2, 10, 'Commercial Task GTB');
        comAl1.almd__owner_access_alert_id__c = null;
        comAl1.almd__country_id__c = 'AR';
        Test.startTest();
        insert comAl1;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 1, insertedAlerts.size(),'Correcto');
        Test.stopTest();
    }

    @isTest
    /* Method 24 */
    public static void copyExtId() {
        final Id subsidiaryRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Subsidiary').getRecordTypeId();
        final Id groupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        final Account acc = createClient(groupRT, 'TestCClient1');
        final Account acc2 = createClient(subsidiaryRT, 'TestCClient2');


        final String profileTest = createProfile();
        final User user1 = createUser(profileTest, true, true, true, 'One to One',1);
        final User user2 = createUser(profileTest, true, true, false, 'One to One',2);

        final DES_Subsidiary_Group_Relation__c matrix = createMatrix(acc2);
        matrix.participant_parent_id__c = acc.Id;
        insert matrix;

        final DES_BBVA_Management_team__c bbvaMT = new DES_BBVA_Management_team__c();
        bbvaMT.DES_Client__c = acc.Id;
        bbvaMT.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
        bbvaMT.DES_Local_Banker_Country__c = 'AR';
        bbvaMT.DES_User__c = user2.Id;
        insert bbvaMT;

        final DES_BBVA_Management_team__c bbvaMT2 = new DES_BBVA_Management_team__c();
        bbvaMT2.DES_Client__c = acc.Id;
        bbvaMT2.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
        bbvaMT2.DES_Local_Banker_Country__c = 'IT';
        bbvaMT2.DES_User__c = user2.Id;
        insert bbvaMT2;

        final Product2 prod = new Product2();
        prod.Name = 'Client Resources';
        prod.isActive = true;
        prod.Family = 'GTB';
        insert prod;

        final almd__Commercial_Alert__c comAl1 = createAlert(user1, user2, acc2, 10, 'Commercial Task GTB');
        comAl1.almd__owner_access_alert_id__c = null;
        comAl1.almd__country_id__c = 'AR';
    	comAl1.participant_name__c = 'TestCClient2';

        Test.startTest();
        insert comAl1;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals(1, insertedAlerts.size(),'Correcto');
        Test.stopTest();
    }


    private static almd__Commercial_Alert__c createAlert(User user1, User user2, Account acc, Integer i, String rt) {
        almd__Commercial_Alert__c comAl1 = new almd__Commercial_Alert__c();
        comAl1.Name = 'Prueba Alerta'+i;
        comAl1.almd__owner_access_alert_id__c = user1.ID_User__c;
        comAl1.almd__User_id__c = user2.Id;
        comAl1.almd__commercial_alert_id__c = 'Id'+i;
        comAl1.almd__participant_id__c = acc.id;
        comAl1.almd__commercial_alert_start_date__c = system.today();
        comAl1.almd__commercial_alert_end_date__c = system.today();
        comAl1.almd__commercial_alert_record_type__c = rt;
        comAl1.almd__commercial_alert_desc__c = PRUEBADESC;
        comAl1.almd__priority_alert_type__c = PRIORITYHIGH;
        comAl1.almd__data_source_name__c = 'Test';
        comAl1.almd__commercial_alert_task_type__c = BACKUP;
        comAl1.almd__reject_authorizer_user_id__c = user2.Id;
        return comAl1;
    }
    //Nuevo cliente
    private static Account createClient(Id rt, String code) {
        Account acc;
        acc = new Account();
        acc.Name = 'Test Client';
        acc.Phone = '646171717';
        acc.DES_Revenue_Update_Engloba__c = '20180912';
        acc.RecordTypeId = rt;
        acc.DES_Group_Code__c = code;
        acc.SER_CClient__c = code;
        insert acc;
        return acc;
    }

    //Nuevo perfil
     private static String createProfile() {
        String profileTest;
        profileTest = userinfo.getProfileId();
        return profileTest;
    }


    //Nuevo usuario
    private static User createUser(String profileTest, boolean high, boolean medium, boolean low, String not_type, Integer i) {
        User userTest;
        userTest = new User();
        userTest.ProfileId = profileTest;
        userTest.FirstName = 'User Name Test'+i;
        userTest.LastName = 'User Last Name Test'+i;
        userTest.Alias = 'ATest';
        userTest.Email = 'useremail'+i+'@test.comm';
        userTest.ID_User__c = string.valueOf(system.now() - Math.abs(Math.random()*10));
        userTest.FederationIdentifier = userTest.ID_User__c;
        userTest.username= 'useremail'+String.valueof(DateTime.now().getTime())+'@test.comm';
        userTest.CommunityNickname = 'ComunityNickNameTest2'+i;
        userTest.EmailEncodingKey = 'UTF-8';
        userTest.Timezonesidkey='Europe/London';
        userTest.Localesidkey ='en_US';
        userTest.languagelocalekey='en_US';
        userTest.almd__notification_priority_high_type__c = high;
        userTest.almd__notification_priority_low_type__c = medium;
        userTest.almd__notification_priority_med_type__c = low;
        userTest.almd__alert_notification_type__c = not_type;
        userTest.DES_Disable_Chatter__c = false;
        userTest.IsActive = true;
        system.debug('>>>>>>createUser: ' + userTest);
        insert userTest;
        return userTest;
    }

    private static DES_BBVA_Management_team__c createBBVAManagementTeamMember(User userTest, Account acc) {
        DES_BBVA_Management_team__c bbvaTM;
        bbvaTM = new DES_BBVA_Management_team__c();
        bbvaTM.Name = 'User Test';
        bbvaTM.DES_User__c = userTest.Id;
        bbvaTM.DES_Client__c = acc.Id;
        insert bbvaTM;
        return bbvaTM;
    }

    private static CIB_User_Org__c createCustomSetting(User u) {
        CIB_User_Org__c userSettings;
        userSettings = new CIB_User_Org__c();
        userSettings.CIB_Is_Admin__c = false;
        //userSettings.SetupOwnerId = u.id;
        insert userSettings;
        return userSettings;
    }

    private static Opportunity createOpportunity(Account acc, almd__Commercial_Alert__c alert) {
        Opportunity opp;
        opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.DES_Description_rich__c = 'Oportunidad para clase de test';
        opp.DES_Countries__c = 'AR';
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today();
        opp.StageName = Label.DES_Draft;
        opp.Probability = 5;
        opp.Amount = 5;
        opp.CurrencyIsoCode = 'EUR';
        opp.DES_Cross_border__c = true;
        //opp.pre_oppy_revenue_next_12m_amount__c = 5;
        opp.DES_Expected_Probability__c = 5;
        opp.DES_Amount__c = 5;
        opp.DES_Booking_Geography__c = 'AR';
        if(alert != null) {
            opp.almd__commercial_alert_id__c = alert.Id;
        }

        opp.Pricebook2Id = Test.getStandardPricebookId();
        return opp;
    }


    private static dwp_kitv__Visit__c createVisit(Account acc, almd__Commercial_Alert__c alert) {
        dwp_kitv__Visit__c vis;
        vis = new dwp_kitv__Visit__c();
        vis.dwp_kitv__account_id__c= acc.Id;
        vis.Name = 'VISIT TEST';
        vis.dwp_kitv__visit_duration_number__c = '15';
        vis.dwp_kitv__visit_start_date__c = Date.today();
        if(alert != null) {
            vis.almd__commercial_alert_id__c = alert.Id;
        }
        return vis;
    }

    private static DES_Subsidiary_Group_Relation__c createMatrix(Account acc) {
        DES_Subsidiary_Group_Relation__c matrix;
        matrix = new DES_Subsidiary_Group_Relation__c();
        matrix.participant_child_id__c = acc.Id;
        matrix.main_subsidiary_ind_type__c = true;
        return matrix;
    }

     @isTest(SeeAllData=true)
    /*Method 25 */
    public static void executeBatch() {
        Account acc1;
        acc1 = createAccount();
        Account acc2;
        acc2 = createAccount();
        final List<Account> listAccs = new List<Account>();
        listAccs.add(acc1);
        listAccs.add(acc2);

        insert listAccs;

        final List<User> listUsers = new List<User>();
        String profileTest;
        profileTest = createProfile();
        User user1;
        user1 = createUser(profileTest, true, true, true, 'One to One',1);
        User user2;
        user2 = createUser(profileTest, true, true, true, 'One General',2);
        User user3;
        user3 = createUser(profileTest, true, true, true, 'Grouped By Client',3);
        listUsers.add(user1);
        listUsers.add(user2);
        listUsers.add(user3);
        system.debug('>>>>> listUsers : ' + listUsers);
        //insert listUsers;

        DES_BBVA_Management_team__c bbvaTeam;
        bbvaTeam = createBBVAManagementTeamMember(user3, acc1);

        List<almd__Commercial_Alert__c> listCommAlert = new List<almd__Commercial_Alert__c>();
        final almd__Commercial_Alert__c comAlert1 = createAlert(listUsers.get(0), listUsers.get(1), listAccs.get(0), 1, IBFTYPE);
        final almd__Commercial_Alert__c comAlert2 = createAlert(listUsers.get(1), listUsers.get(0), listAccs.get(1), 2, IBFTYPE);
        final almd__Commercial_Alert__c comAlert3 = createAlert(listUsers.get(0), listUsers.get(1), listAccs.get(0), 3, IBFTYPE);
        final almd__Commercial_Alert__c comAlert4 = createAlert(listUsers.get(1), listUsers.get(0), listAccs.get(1), 4, IBFTYPE);
        final almd__Commercial_Alert__c comAlert5 = createAlert(listUsers.get(1), listUsers.get(0), listAccs.get(1), 5, 'Notification');
        final almd__Commercial_Alert__c comAlert6 = createAlert(listUsers.get(1), listUsers.get(2), listAccs.get(1), 5, 'Notification');
        listCommAlert.add(comAlert1);
        listCommAlert.add(comAlert2);
        listCommAlert.add(comAlert3);
        listCommAlert.add(comAlert4);
        listCommAlert.add(comAlert5);
        system.debug('>>>>> listCommAlert : ' + listCommAlert);
        insert listCommAlert;
        final List<almd__Commercial_Alert__c> insertedAlerts = [SELECT Id FROM almd__Commercial_Alert__c WHERE Name LIKE '%Prueba Alerta%'];
        System.assertEquals( 5, insertedAlerts.size(),'Correcto' );
         final Id batchInstanceId1 = Database.executeBatch(new DES_Batch_Commercial_Alert_Notify(IBFTYPE), 1000);
         final Id batchInstanceId2 = Database.executeBatch(new DES_Batch_Commercial_Alert_Notify('Notification'), 1000);
         System.debug(batchInstanceId1);
        //System.abortJob(batchInstanceId);
    }//FIN EXECUTE BATCH

    public static Account createAccount() {
        Account acc;
        acc = new Account();
        acc.Name = 'Test Client';
        acc.Phone = '646171717';
        acc.DES_Revenue_Update_Engloba__c = '20180912';
        return acc;
    }
}