/**
*
* @author Global Desktop
*/
@isTest
public with sharing class IpOppClosedCtllTest {
    /**
     * @author Global Desktop
     */
    private static DES_UtilTestClass util = new DES_UtilTestClass();
    /**
     * oppIPRecordTypeId
     */
    private static Id oppIPRecordTypeId {
        get {
            if (oppIPRecordTypeId == null) {
                oppIPRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Privileged Opportunity').getRecordTypeId();
            }
            return oppIPRecordTypeId;
        }
        set;
    }
    
  /**
   * Test that an IP Opportunity created by a normal user is visible by the user
   */
  @IsTest
  static void ipOppClosed () {
	 	final Account acc = util.createClient();
        insert acc;
      	final Opportunity opp = util.createOpportunity( acc );
      	opp.Name = 'Operacion tierra';
      	opp.disclosure_info_type__c = Label.DES_OP_Inside;
      	opp.RecordTypeId = oppIPRecordTypeId;
      	opp.StageName = Label.DES_Closed_Lose;
      	insert opp;
      	final String response = IpOppClosedCtll.relateOpportunities('5');

      	System.assertNotEquals(null, response);

  }

  /**
   * Test that an IP Opportunity created by a normal user is visible by the user
   */
  @IsTest
  static void ipOppInProgress () {
	 	final Account acc = util.createClient();
        insert acc;
      	final Opportunity opp = util.createOpportunity( acc );
      	opp.Name = 'Operacion tierra';
      	opp.disclosure_info_type__c = Label.DES_OP_Inside;
      	opp.RecordTypeId = oppIPRecordTypeId;
      	opp.StageName = Label.DES_Draft;
      	insert opp;
      	final String response = IpOppInProgressCtll.relateOpportunities('5');

      	System.assertNotEquals(null, response);

  }
  
  @IsTest
  static void visitRelatedOpp () {
		final Account acc = util.createClient();
        insert acc;
      	final Opportunity opp = util.createOpportunity( acc );
      	opp.Name = 'Operacion tierra';
      	opp.disclosure_info_type__c = Label.DES_OP_Inside;
      	opp.RecordTypeId = oppIPRecordTypeId;
      	opp.StageName = Label.DES_Draft;
      	insert opp;
      	final dwp_kitv__Visit__c visit = util.createVisit(acc,opp);
     	insert visit;
        final dwp_kitv__Visit_Topic__c topic = util.createVisitTopic(visit,opp);
      	insert topic;
      
      	final String response = OppIpRelatedToVisitNonIpCtll.relateOpportunities('5');

      	System.assertNotEquals(null, response);

  }

}