@isTest
public class DES_IP_NotifyInsideFormDecisionsTest {

    /* Clase Util con methods auxiliares */
    private static DES_UtilTestClass util = new DES_UtilTestClass();

    @testSetup
    static void setup() {
        final String profile = util.createProfile();
        final User user1 = util.createUser(profile);
        insert user1;
        Inside_information_form__c form = new Inside_information_form__c();
        form.Name = 'test_email';
        insert form;
        Account accFilial = util.createClient();
        insert accFilial;
        Opportunity opp;
        opp = util.createOpportunity(accFilial);
        opp.DES_Booking_Geography__c = 'BE';
        opp.DES_Countries__c = 'BE';
        opp.CurrencyIsoCode = 'EUR';
        opp.DES_Booking_Geography__c = 'BE';
        opp.DES_Countries__c = 'BE';
        opp.CurrencyIsoCode = 'EUR';
        opp.StageName = Label.DES_Draft;
        insert opp;
        dwp_kitv__Visit__c visit = new dwp_kitv__Visit__c();
        visit.dwp_kitv__visit_duration_number__c = '15';
        visit.dwp_kitv__visit_start_date__c = Date.today();
        insert visit;
    }

    @isTest
    public static void testOppFormApproved() {
        User user1 = [SELECT Id FROM User WHERE FirstName = 'User Name Test'];
        GroupMember gm = new GroupMember();
        gm.UserOrGroupId = user1.Id;
        List<GroupMember> listMembers = new List<GroupMember>();
        listMembers.add(gm);

        Inside_information_form__c form = [SELECT Id,Name FROM Inside_information_form__c];

        Opportunity opp = [SELECT Id FROM Opportunity];

        Case relCase = new Case();
        relCase.opportunity_id__c = opp.Id;
        insert relCase;

        String decision = 'Approved';

        DES_IP_NotifyInsideFormDecisions.NotifyOppTeamFormDecision(listMembers, decision, form, relCase);
        System.assertEquals(1, listMembers.size());
    }

    @isTest
    public static void testOppFormRejected() {
        User user1 = [SELECT Id FROM User WHERE FirstName = 'User Name Test'];
        GroupMember gm = new GroupMember();
        gm.UserOrGroupId = user1.Id;
        List<GroupMember> listMembers = new List<GroupMember>();
        listMembers.add(gm);

        Inside_information_form__c form = [SELECT Id,Name FROM Inside_information_form__c];

        Opportunity opp = [SELECT Id FROM Opportunity];

        Case relCase = new Case();
        relCase.opportunity_id__c = opp.Id;
        insert relCase;

        String decision = 'Rejected';

        DES_IP_NotifyInsideFormDecisions.NotifyOppTeamFormDecision(listMembers, decision, form, relCase);
        System.assertEquals(1, listMembers.size());
    }

    @isTest
    public static void testVisitFormApproved() {
        User user1 = [SELECT Id FROM User WHERE FirstName = 'User Name Test'];
        GroupMember gm = new GroupMember();
        gm.UserOrGroupId = user1.Id;
        List<GroupMember> listMembers = new List<GroupMember>();
        listMembers.add(gm);

        Inside_information_form__c form = [SELECT Id,Name FROM Inside_information_form__c];

        dwp_kitv__Visit__c visit = [SELECT Id FROM dwp_kitv__Visit__c];

        Case relCase = new Case();
        relCase.visit_id__c = visit.Id;
        insert relCase;

        String decision = 'Approved';

        DES_IP_NotifyInsideFormDecisions.NotifyOppTeamFormDecision(listMembers, decision, form, relCase);
        System.assertEquals(1, listMembers.size());
    }

    @isTest
    public static void testVisitFormRejected() {
        User user1 = [SELECT Id FROM User WHERE FirstName = 'User Name Test'];
        GroupMember gm = new GroupMember();
        gm.UserOrGroupId = user1.Id;
        List<GroupMember> listMembers = new List<GroupMember>();
        listMembers.add(gm);

        Inside_information_form__c form = [SELECT Id,Name FROM Inside_information_form__c];

        dwp_kitv__Visit__c visit = [SELECT Id FROM dwp_kitv__Visit__c];

        Case relCase = new Case();
        relCase.visit_id__c = visit.Id;
        insert relCase;

        String decision = 'Rejected';

        DES_IP_NotifyInsideFormDecisions.NotifyOppTeamFormDecision(listMembers, decision, form, relCase);
        System.assertEquals(1, listMembers.size());
    }
}