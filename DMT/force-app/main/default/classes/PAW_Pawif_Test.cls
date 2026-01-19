/**-------------------------------------------------------------------------------------------
* @Name     PAWIF Test Class
* @Date     Created: 2024-11-25
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for pawif service
* ------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class PAW_Pawif_Test {

    @isTest
    public static void testWrapper() {
        PAW_Pawif.Wrapper wrapper = new PAW_Pawif.Wrapper();
        wrapper.success = true;
        wrapper.errorMessage = 'test';
        PAW_Pawif.Data data = new PAW_Pawif.Data();
        data.opportunityId = 'test';
        data.urlOpportunity = 'test';
        data.urlSimulation = 'test';
        data.simulationStatus = 'test';
        wrapper.data = data;
        System.assert(wrapper.success, 'Error Testing PAWIF Wrapper');
    }

    @isTest(SeeAllData=true)
    public static void setPawifInformation_NBCStatusApproved_Test() {

        final DES_UtilTestClass utils = new DES_UtilTestClass();
        test.startTest();

        //USER
        final String profileTest = utils.createProfile();
        final User user1 = utils.createUser(profileTest, 'test@test.com');
        user1.FederationIdentifier = '123456';
        insert user1;
        assignPermissionSet(user1.Id, 'Commercial_Activity_Edit');

        System.runAs(user1) {
            final Account accFilial = utils.createClient();
            insert accFilial;

            final Product2 prod1 = utils.createProduct(Label.DES_Mergers_Acquisitions);
            insert prod1;

            final PricebookEntry pBookEntry1 = utils.createPricebookEntry(prod1);
            insert pBookEntry1;

            Opportunity opp;
            opp = utils.createOpportunity(accFilial);
            opp.DES_Booking_Geography__c = 'BE';
            opp.DES_Countries__c = 'BE';
            opp.CurrencyIsoCode = 'EUR';
            opp.StageName = 'Proposal';
            opp.PAW_simulation_url__c = 'http://www.example.com';
            opp.PAW_simulation_Id__c = '123456';
            insert opp;

            List<OpportunityLineItem> oppLineItemList;
            oppLineItemList = new List<OpportunityLineItem>();

            OpportunityLineItem oppLineItem2;
            oppLineItem2 = utils.createOppLineItem(opp, prod1, pBookEntry1);
            oppLineItem2.DES_Booking_System__c = 'booking system';
            oppLineItem2.DES_Booking_ID__c = 'booking id';
            utils.updateOppLineItem(oppLineItem2, user1);
            oppLineItemList.add(oppLineItem2);
            insert oppLineItem2;

            try{
                opp.NBC_Decision_Taken_type__c = 'Recommended';
                update opp;
            } catch (Exception e) {
                System.debug('excepcion');
            }

            List<sObject> lSObject = new List<sObject>();
            lSObject.add(opp);
            List<Boolean> result = PAW_PawifHelper.setPawifInformationOpportunity(lSObject);
            System.assert(result[0], 'Error Testing PAWIF Update NBC Status Approved');
        }
        test.stopTest();
    }

    @isTest(SeeAllData=true)
    public static void setPawifInformation_NBCStatusRejected_Test() {

        final DES_UtilTestClass utils = new DES_UtilTestClass();
        test.startTest();

        //USER
        final String profileTest = utils.createProfile();
        final User user1 = utils.createUser(profileTest, 'test@test.com');
        user1.FederationIdentifier = '123456';
        insert user1;
        assignPermissionSet(user1.Id, 'Commercial_Activity_Edit');

        System.runAs(user1) {
            final Account accFilial = utils.createClient();
            insert accFilial;

            final Product2 prod1 = utils.createProduct(Label.DES_Mergers_Acquisitions);
            insert prod1;

            final PricebookEntry pBookEntry1 = utils.createPricebookEntry(prod1);
            insert pBookEntry1;

            Opportunity opp;
            opp = utils.createOpportunity(accFilial);
            opp.DES_Booking_Geography__c = 'BE';
            opp.DES_Countries__c = 'BE';
            opp.CurrencyIsoCode = 'EUR';
            opp.StageName = 'Proposal';
            opp.PAW_simulation_url__c = 'http://www.example.com';
            opp.PAW_simulation_Id__c = '123456';
            insert opp;

            List<OpportunityLineItem> oppLineItemList;
            oppLineItemList = new List<OpportunityLineItem>();

            OpportunityLineItem oppLineItem2;
            oppLineItem2 = utils.createOppLineItem(opp, prod1, pBookEntry1);
            oppLineItem2.DES_Booking_System__c = 'booking system';
            oppLineItem2.DES_Booking_ID__c = 'booking id';
            utils.updateOppLineItem(oppLineItem2, user1);
            oppLineItemList.add(oppLineItem2);
            insert oppLineItem2;

            try {
                opp.NBC_Decision_Taken_type__c = 'Not Recommended';
                update opp;
            } catch (Exception e) {
                System.debug('excepcion');
            }

            List<sObject> lSObject = new List<sObject>();
            lSObject.add(opp);
            List<Boolean> result = PAW_PawifHelper.setPawifInformationOpportunity(lSObject);
            System.assert(result[0], 'Error Testing PAWIF Update NBC Status Rejected');
        }
        test.stopTest();
    }

    @isTest(SeeAllData=true)
    public static void setPawifInformation_OppClosedWon_Test() {

        final DES_UtilTestClass utils = new DES_UtilTestClass();
        test.startTest();

        //USER
        final String profileTest = utils.createProfile();
        final User user1 = utils.createUser(profileTest, 'test@test.com');
        user1.FederationIdentifier = '123456';
        insert user1;
        assignPermissionSet(user1.Id, 'Commercial_Activity_Edit');

        System.runAs(user1) {
            final Account accFilial = utils.createClient();
            insert accFilial;

            final Product2 prod1 = utils.createProduct(Label.DES_Mergers_Acquisitions);
            insert prod1;

            final PricebookEntry pBookEntry1 = utils.createPricebookEntry(prod1);
            insert pBookEntry1;

            Opportunity opp;
            opp = utils.createOpportunity(accFilial);
            opp.DES_Booking_Geography__c = 'BE';
            opp.DES_Countries__c = 'BE';
            opp.CurrencyIsoCode = 'EUR';
            opp.StageName = Label.DES_Ready_to_close;
            opp.PAW_simulation_url__c = 'http://www.example.com';
            opp.PAW_simulation_Id__c = '123456';
            insert opp;

            List<OpportunityLineItem> oppLineItemList;
            oppLineItemList = new List<OpportunityLineItem>();

            OpportunityLineItem oppLineItem2;
            oppLineItem2 = utils.createOppLineItem(opp, prod1, pBookEntry1);
            oppLineItem2.DES_Booking_System__c = 'booking system';
            oppLineItem2.DES_Booking_ID__c = 'booking id';
            utils.updateOppLineItem(oppLineItem2, user1);
            oppLineItemList.add(oppLineItem2);
            insert oppLineItem2;

            try{
                opp.StageName = Label.DES_Closed_Won;
                update opp;
            } catch (Exception e) {
                System.debug('excepcion');
            }

            List<sObject> lSObject = new List<sObject>();
            lSObject.add(opp);
            List<Boolean> result = PAW_PawifHelper.setPawifInformationOpportunity(lSObject);

            System.assert(result[0], 'Error Testing PAWIF Update Opp Closed Won');
        }
        test.stopTest();
    }

    @isTest(SeeAllData=true)
    public static void setPawifInformation_OppClosedLost_Test() {

        final DES_UtilTestClass utils = new DES_UtilTestClass();
        test.startTest();

        //USER
        final String profileTest = utils.createProfile();
        final User user1 = utils.createUser(profileTest, 'test@test.com');
        user1.FederationIdentifier = '123456';
        insert user1;
        assignPermissionSet(user1.Id, 'Commercial_Activity_Edit');

        System.runAs(user1) {
            final Account accFilial = utils.createClient();
            insert accFilial;

            final Product2 prod1 = utils.createProduct(Label.DES_Mergers_Acquisitions);
            insert prod1;

            final PricebookEntry pBookEntry1 = utils.createPricebookEntry(prod1);
            insert pBookEntry1;

            Opportunity opp;
            opp = utils.createOpportunity(accFilial);
            opp.DES_Booking_Geography__c = 'BE';
            opp.DES_Countries__c = 'BE';
            opp.CurrencyIsoCode = 'EUR';
            opp.StageName = Label.DES_Ready_to_close;
            opp.PAW_simulation_url__c = 'http://www.example.com';
            opp.PAW_simulation_Id__c = '123456';
            insert opp;

            List<OpportunityLineItem> oppLineItemList;
            oppLineItemList = new List<OpportunityLineItem>();

            OpportunityLineItem oppLineItem2;
            oppLineItem2 = utils.createOppLineItem(opp, prod1, pBookEntry1);
            oppLineItem2.DES_Booking_System__c = 'booking system';
            oppLineItem2.DES_Booking_ID__c = 'booking id';
            utils.updateOppLineItem(oppLineItem2, user1);
            oppLineItemList.add(oppLineItem2);
            insert oppLineItem2;

            try {
                opp.StageName = Label.DES_Closed_Lose;
                update opp;
            } catch (Exception e) {
                System.debug('excepcion');
            }

            List<sObject> lSObject = new List<sOBject>();
            lSObject.add(opp);
            List<Boolean> result = PAW_PawifHelper.setPawifInformationOpportunity(lSObject);
            System.assert(result[0], 'Error Testing PAWIF Update Opp Closed Lost');
        }
        test.stopTest();
    }

    private static void assignPermissionSet(Id userId, String psName) {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name =: psName limit 1];
        insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);
    }

}