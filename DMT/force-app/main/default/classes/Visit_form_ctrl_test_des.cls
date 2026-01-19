/**
*
* @author Global Desktop
*/
@isTest
public class Visit_form_ctrl_test_des {
    /**
     * @author Global Desktop
     */
    static Boolean objVisit;
    /**
     * @author Global Desktop
     */
    static Boolean objTopic;
    /**
     * @author Global Desktop
     */
    static Boolean showdisclosure;
    /**
     * @author Global Desktop
     */
    static User defaultUser;
    /**
     * @author Global Desktop
     */
    static Account defaultAcc;
    /**
     * @author Global Desktop
     */
    static Opportunity defaultOpp;
    /**
     * @author Global Desktop
     */
    static Lead defaultLead;

    /**
     * @author Global Desktop
     */
    static Map<String, Schema.SObjectType> globalDesc;
    /**
     * @author Global Desktop
     */
    static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    /**
     * @author Global Desktop
     */
    static Schema.SObjectType sobjtopic;
    /**
     * @author Global Desktop
     */
    static Schema.SObjectType sobjcs;
    /**
     * @author Global Desktop
     */
    static Schema.SObjectType sobjvisit;
    /**
     * @author Global Desktop
     */
    public static final String NAME_TEST = 'Test';

    static void setData() {
        Test.startTest();
        showdisclosure = Visit_form_ctrl_des.isShowDisclosure();

        final String profile = utilTestClass.createProfile();
        defaultUser = utilTestClass.createUser(profile);
        insert defaultUser;

        defaultAcc = dwp_kitv.Kit_Visit_TestFactory.createAccount();
        insert defaultAcc;

        defaultOpp = dwp_kitv.Kit_Visit_TestFactory.createOpportunity();
        insert defaultOpp;

        defaultLead = dwp_kitv.Kit_Visit_TestFactory.createLead();
        insert defaultLead;

        globalDesc = Schema.getGlobalDescribe();
        objVisit = dwp_kitv.Visit_Aux.checkObject('dwp_kitv__Visit__c');
        objTopic = dwp_kitv.Visit_Aux.checkObject('dwp_kitv__Visit_Topic__c');
        sobjvisit = globalDesc.get('dwp_kitv__Visit__c');
        sobjtopic = globalDesc.get('dwp_kitv__Visit_Topic__c');
        sobjcs = globalDesc.get('dwp_kitv__Lead_Opportunity_Field_cs__c');
        Test.stopTest();
    }
    @isTest
    static void setEndVisitTestOK() {
        setData();

        String visitInfo;
        String visitInfo2;
        String visitInfo3;
        // SObject getcustom;
        final sObject kitvisit = sobjvisit.newSObject();
        final dateTime today = System.Now();
        // Date todaydate = System.today();
        System.runAs(defaultUser) {
            dwp_kitv.Kit_Visit_TestFactory.objectNameToCheck = 'dwp_kitv__Visit__c';
            final sObject visitRecord = dwp_kitv.Kit_Visit_TestFactory.createVisit();
            insert visitRecord;

            final sObject topic = sobjtopic.newSObject();
            topic.put('dwp_kitv__visit_id__c',visitRecord.Id);
            topic.put('dwp_kitv__topic_desc__c', NAME_TEST);
            topic.put('dwp_kitv__opportunity_id__c',defaultOpp.Id);
            insert topic;
            String rtName;
            rtName = Visit_form_ctrl_des.recordTypeName(defaultOpp.Id);
            System.debug(rtName);
            // String accInfo = Visit_form_ctrl_des.getAccId(defaultOpp.Id);
            // String leadINfo = Visit_form_ctrl_des.getLeadId(defaultOpp.Id);
            visitInfo = Visit_form_ctrl_des.newVisit('nameTest', defaultOpp.Id,'60', today, 'locationTest','testasdsad', '', '', '');
            System.assertNotEquals(visitInfo,null);

            // List < String > selectedOp = Visit_form_ctrl_des.getselectOptions(kitvisit, 'dwp_kitv__visit_purpose_type__c');

            final dwp_kitv__Lead_Opportunity_Field_cs__c csopp = new dwp_kitv__Lead_Opportunity_Field_cs__c();
            csopp.dwp_kitv__LeadId__c = 'DES_Prospect__c';
            insert csopp;


            final Account acc = utilTestClass.createClient();
            insert acc;

            final Lead prospect = new Lead();
            prospect.Company = NAME_TEST;
            prospect.LastName = NAME_TEST;
            prospect.DES_Fiscal_Number__c = NAME_TEST;
            prospect.Email = 'test@test.com';
            prospect.Status = 'Open';
            insert prospect;


            final List <Opportunity> opps = new List <Opportunity>();
            final Opportunity opp = utilTestClass.createOpportunity(acc);
            opps.add(opp);
            final Opportunity opp2 = utilTestClass.createOpportunity(acc);
            opp2.DES_Prospect__c = prospect.id;
            // opp2.AccountId = null; //NOSONAR
            opps.add(opp2);
            insert opps;
            system.debug('antes start -> ' + Limits.getQueries());
            //Test.startTest();


            visitInfo2 = Visit_form_ctrl_des.newVisit('nameTest', opps.get(0).Id,'60', today, 'locationTest',
                                                  'testasdsad', '', '', '');
            System.assertNotEquals(visitInfo2,null);

            visitInfo3 = Visit_form_ctrl_des.newVisit(NAME_TEST, opps.get(1).Id,'60', today, 'locationTest',
                                                  'testasdsad', '', '', '');
            final SObject obj = Schema.getGlobalDescribe().get('dwp_kitv__Visit__c').newSObject();
            Visit_form_ctrl_des.getselectOptions(obj, 'dwp_kitv__visit_duration_number__c', 'false');
            System.assertNotEquals(visitInfo3,null);
            system.debug('antes stop -> ' + Limits.getQueries());
            //Test.stopTest();
        }
    }
}