/**
*
* @author Global Desktop
*/
@isTest
private class DES_VisitTopic_TriggerHandler_TEST {
    /*
     * @author Global Desktop
    **/
    public static final String RT_DVLPRNM_GROUP = 'Group';
    /*
     * @author Global Desktop
    **/
    public static final String RT_DVLPRNM_SBSDRY = 'Subsidiary';

    /**
    *
    * @author Global Desktop
    */
	@isTest //NOSONAR
	public static void testMethodOne() {
		//Data needed
		final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
		final String profileTest = utilTestClass.createProfile();
        final User user1 = utilTestClass.createUser(profileTest);
        insert user1;

        
		System.runAs(user1) {
            /*ComentadaParaSubidaProxima*/

            final Id rtGroupAcc = Schema.SObjectType.Account.getRecordTypeInfosByName().get(RT_DVLPRNM_GROUP).getRecordTypeId();
            final Account acc1 = utilTestClass.createClient();
            acc1.RecordTypeId = rtGroupAcc;
            acc1.DES_Group_Code__c = 'GC000011';
            insert acc1;
            
            final almd__Commercial_Alert__c comAl1 = utilTestClass.createAlert(user1, user1, acc1, 1,'Commercial Task IBF');

	        comAl1.almd__alert_stage_type__c = 'In progress';
	        comAl1.almd__alert_sub_stage_type__c = 'Visit in progress';
	        comAl1.almd__client_process_accepted_type__c = true;
	        insert comAl1;

            /*ComentadaParaSubidaProxima*/

	        //Test
	   	        final Opportunity opp1 = utilTestClass.createOpportunity(acc1);
                /*ComentadaParaSubidaProxima*/
		        opp1.almd__commercial_alert_id__c = comAl1.id;
               /*ComentadaParaSubidaProxima*/
	    	    insert opp1;

	    		Test.startTest();
	        		final dwp_kitv__Visit__c vis1 = utilTestClass.createVisit(acc1, null);
	                insert vis1;

	               	final list<dwp_kitv__Visit_Topic__c> visTopics =new list<dwp_kitv__Visit_Topic__c>();
                    final dwp_kitv__Visit_Topic__c visTopic  =   utilTestClass.createVisitTopic(vis1,opp1);
            		visTopics.add(visTopic);
	        		insert visTopics;
					final DES_VisitTopic_TriggerHandler test1 = new DES_VisitTopic_TriggerHandler();
            		test1.visitAfterInsert(visTopics);

                    final dwp_kitv__Visit_Topic__c testAssert = [SELECT id, dwp_kitv__visit_id__c FROM dwp_kitv__Visit_Topic__c WHERE id = :visTopic.id];
                    System.assertEquals(testAssert.dwp_kitv__visit_id__c, vis1.id);

				Test.stopTest();

				//Verify the expressions are the same
	        	//System.assertEquals(opp1.commercial_alert_id__c, vis1.commercial_alert_id__c);

    	}

	}

    /**
    *
    * @author Global Desktop
    */
    @isTest
	public static void visitConfidentialTest() {
		//Data needed
		DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final id accountGroupRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get(RT_DVLPRNM_GROUP).getRecordTypeId();
        final id accountFilialRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get(RT_DVLPRNM_SBSDRY).getRecordTypeId();
        
        // list<Account> accList = new list<Account>();
        final Account accGroup = utilTestClass.createClient();
        accGroup.RecordTypeId = accountGroupRT;
        accGroup.DES_Structure_Type__c = 'Group';
        accGroup.DES_BBVA_Segmentation__c = 'C';
        insert accGroup;

        final List<dwp_kitv__Visit__c> aVisit = new List<dwp_kitv__Visit__c>();
        dwp_kitv__Visit__c visit1 = utilTestClass.createVisit(accGroup, null);
	    visit1.RecordTypeId = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_VISIT_Account_Visit).getRecordTypeId();
        visit1.disclosure_info_type__c = Label.DES_OP_CONFIDENTIAL;
        aVisit.add(visit1);
        final dwp_kitv__Visit__c visit2 = utilTestClass.createVisit(accGroup, null);
	    visit2.RecordTypeId = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_VISIT_Account_Confidential_Visit).getRecordTypeId() ;
        aVisit.add(visit2);
        insert aVisit;

        visit1 = [SELECT id, RecordType.Name FROM dwp_kitv__Visit__c WHERE id = :visit1.ID];
        System.assertEquals(visit1.RecordType.Name, Label.DES_RT_VISIT_Account_Confidential_Visit);
    }

    /**
    *
    * @author Global Desktop
    */
    @isTest
    public static void oppTopicsNBCTest() {
    	final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    	final Account acc = utilTestClass.createClient();
        acc.DES_BBVA_Segmentation__c = Label.DES_Segmentation_NBC;
        acc.DES_Structure_Type__c = 'Group';
    	insert acc;

        final List <Account> accounts = [Select id, RecordType.DeveloperName, DES_BBVA_Segmentation__c from Account LIMIT 5000];
        system.debug('>>>>accountsTest -> '+accounts);

    	final NBC__c nbc = utilTestClass.createNBC();
    	insert nbc;

    	final Opportunity opp = utilTestClass.createOpportunity(acc);
    	opp.Committee_id__c = nbc.id;
    	opp.Template_approved_type__c = true;
    	insert opp;

    	final dwp_kitv__Visit__c visit = utilTestClass.createVisit(acc, opp);
    	visit.Committee_id__c = nbc.id;
    	Test.startTest();
    	insert visit;
        system.debug('>>> Visit -> ' + visit);
        final dwp_kitv__Visit_Topic__c visitTopic = [SELECT id, dwp_kitv__opportunity_id__c, dwp_kitv__visit_id__c from dwp_kitv__Visit_Topic__c where dwp_kitv__visit_id__c = :visit.Id LIMIT 1];
        system.assertEquals(visitTopic.dwp_kitv__opportunity_id__c, opp.id);
        Test.stopTest();
    }

    /**
    *
    * @author Global Desktop
    */
    @isTest
    public static void membersNBCTest() {
    	final List <NBC__c> nbcs = new List<NBC__c>();
    	final List <Opportunity> opps = new List<Opportunity>();
    	final List <dwp_kitv__Visit__c> visits = new List<dwp_kitv__Visit__c>();
    	final List <NBC_Member__c> members = new List <NBC_Member__c>();
    	final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

		final String profileTest = utilTestClass.createProfile();
        final User user1 = utilTestClass.createUser(profileTest);
        insert user1;

        system.runAs(new User(Id=UserInfo.getUserId())){
            final Account acc = utilTestClass.createClient();
            insert acc;
            final Contact con = utilTestClass.createContact(acc);
            insert con;

            final NBC__c nbc = utilTestClass.createNBC();
            nbc.NBC_Region_type__c = Label.NBC_REGION_EMEA;
            nbcs.add(nbc);
            final NBC__c nbc1 = utilTestClass.createNBC();
            nbc1.NBC_Region_type__c = Label.NBC_REGION_LATAM;
            nbcs.add(nbc1);
            final NBC__c nbc2 = utilTestClass.createNBC();
            nbc2.NBC_Region_type__c = Label.NBC_REGION_USA;
            nbcs.add(nbc2);
            insert nbcs;

            final Opportunity opp = utilTestClass.createOpportunity(acc);
            opp.Committee_id__c = nbc.id;
            opp.Template_approved_type__c = true;
            opps.add(opp);
            final Opportunity opp1 = utilTestClass.createOpportunity(acc);
            opp1.Committee_id__c = nbc1.id;
            opp1.Template_approved_type__c = true;
            opps.add(opp1);
            final Opportunity opp2 = utilTestClass.createOpportunity(acc);
            opp2.Committee_id__c = nbc2.id;
            opp2.Template_approved_type__c = true;
            opps.add(opp2);
            insert opps;

            utilTestClass.createCustomSettingByPass();

            final ContentVersion contentVersion = new ContentVersion(
              Title = 'Penguins',
              PathOnClient = 'Penguins.jpg',
              VersionData = Blob.valueOf('Test Content'),
              IsMajorVersion = true,
              Copy_to_NBC__c = true

            );
            insert contentVersion;
            final List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 5000];


            final ContentDocumentLink content = new ContentDocumentLink();
            content.LinkedEntityId = nbc.id;
            content.ContentDocumentId  = documents[0].id;
            content.ShareType = 'V';
            insert content;

            final dwp_kitv__Visit__c visit = utilTestClass.createVisit(acc, opp);
            visit.Committee_id__c = nbc.id;
            visits.add(visit);
            final dwp_kitv__Visit__c visit1 = utilTestClass.createVisit(acc, opp);
            visit1.Committee_id__c = nbc1.id;
            visits.add(visit1);
            final dwp_kitv__Visit__c visit2 = utilTestClass.createVisit(acc, opp);
            visit2.Committee_id__c = nbc2.id;
            visits.add(visit2);

            final NBC_Member__c member = utilTestClass.createNBCMember(user1, null);
            members.add(member);
            final NBC_Member__c member1 = utilTestClass.createNBCMember(null, con);
            members.add(member1);
            insert members;

            Test.startTest();
            insert visits;
            final List <NBC_Member__c> membersEMEA = new List <NBC_Member__c>([SELECT id, BBVA_participant__c, Other_BBVA_participant__c, region_emea__c, region_latam__c, region_usa__c from NBC_Member__c where region_emea__c = true]);
            system.assert(membersEMEA.get(0).region_emea__c, 'msg');
            Test.stopTest();
        }

    }

    /*
    * @author Global Desktop
    * @Description manualSharingVisitMembers
    */
    @isTest
    public static void checkDeletePermissionTest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final Account acc = utilTestClass.createClient();
        final dwp_kitv__Visit__c visit1 = utilTestClass.createVisit(acc, null);
        visit1.RecordTypeId = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_Inside_Visit).getRecordTypeId();
        visit1.disclosure_info_type__c = Label.DES_OP_Inside;
        insert visit1;
        try {
            delete visit1;
        } catch (Exception e) {
            system.assertNotEquals(null, visit1.Id, 'Not deleted');
        }
    }

}