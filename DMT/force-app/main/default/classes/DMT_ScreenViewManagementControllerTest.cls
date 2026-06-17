/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private without sharing class DMT_ScreenViewManagementControllerTest {
    @testSetup
    static void makeData() {
        // Create an Approvers View
        DMT_ApproversView__c view = new DMT_ApproversView__c(
            Name = 'Test View',
            DMT_DeveloperName__c = 'Test_View_Dev',
            DMT_Type__c = 'Line_Treasury'
        );
        insert view;

        // Create some DMT_Items__c related to the view
        List<DMT_Items__c> items = new List<DMT_Items__c>();
        for (Integer i = 1; i <= 3; i++) {
            items.add(new DMT_Items__c(
                DMT_View__c = view.Id,
                DMT_order_display__c = i,
                Type_Item__c = 'Component',
                DMT_Component_Item__c = 'Line Info',
                DMT_Text__c = ''
            ));
        }
        insert items;
    }

    @isTest
    static void testGetApproversViews() {
        Test.startTest();
        String resultJson = DMT_ScreenViewManagementController.getApproversViews();
        Test.stopTest();

        List<DMT_ApproversView__c> result = (List<DMT_ApproversView__c>) JSON.deserialize(resultJson, List<DMT_ApproversView__c>.class);
        Assert.isTrue(result.size() > 0, 'Expected at least one ApproversView returned');
        Assert.isNotNull(result[0].Name, 'Expected Name to be present');
    }

    @isTest
    static void testGetItemsForView() {
        Id viewId = [SELECT Id FROM DMT_ApproversView__c LIMIT 1].Id;

        Test.startTest();
        String resultJson = DMT_ScreenViewManagementController.getItemsForView(viewId);
        Test.stopTest();

        List<DMT_Items__c> result = (List<DMT_Items__c>) JSON.deserialize(resultJson, List<DMT_Items__c>.class);
        Assert.AreEqual(3, result.size(), 'Expected 3 items related to the view');
    }

    @isTest
    static void testGetDMTTypePicklistOptions() {
        Test.startTest();
        String resultJson = DMT_ScreenViewManagementController.getDMTTypePicklistOptions();
        Test.stopTest();

        List<Object> result = (List<Object>) JSON.deserializeUntyped(resultJson);
        Assert.isTrue(result.size() > 0, 'Expected picklist options to be returned');
        Map<String, Object> firstEntry = (Map<String, Object>) result[0];
        Assert.isTrue(firstEntry.containsKey('label'), 'Expected label key in picklist option');
        Assert.isTrue(firstEntry.containsKey('value'), 'Expected value key in picklist option');
    }

    @isTest
    static void testUpsertApproversViewWithItems_InsertNew() {
        // 1. Prepare Items List
        List<Map<String, Object>> mockItems = new List<Map<String, Object>>();
        for (Integer i = 1; i <= 2; i++) {
            mockItems.add(new Map<String, Object>{
                'orderDisplay' => i,
                'type' => 'Component',
                'component' => 'Line Info',
                'textValue' => ''
            });
        }

        String viewName = 'New View Name';

        // 2. Create the Single Payload Map
        Map<String, Object> payload = new Map<String, Object>{
            'recordId' => null,
            'viewName' => viewName,
            'viewType' => 'Line_Treasury',
            'isVersionView' => true,
            'displayInOpportunity' => true,
            'items' => mockItems
        };

        Test.startTest();
        DMT_ScreenViewManagementController.upsertApproversViewWithItems(JSON.serialize(payload));
        Test.stopTest();

        // Single Assert: Validate the most critical outcome (Record creation with correct Name)
        DMT_ApproversView__c insertedView = [SELECT Name FROM DMT_ApproversView__c WHERE Name = :viewName LIMIT 1];
        Assert.areEqual(viewName, insertedView.Name, 'The view should be created with the correct name');
    }

    @isTest
    static void testUpsertApproversViewWithItems_UpdateExisting() {
        DMT_ApproversView__c existingView = [SELECT Id, Name FROM DMT_ApproversView__c LIMIT 1];

        List<Map<String, Object>> newItems = new List<Map<String, Object>>();
        newItems.add(new Map<String, Object>{
            'orderDisplay' => 1,
            'type' => 'Component',
            'component' => 'Line Info',
            'textValue' => ''
        });

        String newViewName = 'Updated Name';

        Map<String, Object> payload = new Map<String, Object>{
            'recordId' => existingView.Id,
            'viewName' => newViewName,
            'viewType' => 'Line_Treasury',
            'isVersionView' => true,
            'displayInOpportunity' => true,
            'items' => newItems
        };

        Test.startTest();
        DMT_ScreenViewManagementController.upsertApproversViewWithItems(JSON.serialize(payload));
        Test.stopTest();

        // Single Assert: Validate the most critical outcome (Record update persisted)
        DMT_ApproversView__c updatedView = [SELECT Name FROM DMT_ApproversView__c WHERE Id = :existingView.Id];
        Assert.areEqual(newViewName, updatedView.Name, 'The existing view name should be updated');
    }

    @isTest
    static void testUpsertApproversViewWithItems_UpdateExisting_withError() {
        DMT_ApproversView__c existingView = [SELECT Id, Name FROM DMT_ApproversView__c LIMIT 1];
        Boolean exceptionThrown = false;

        List<Map<String, Object>> newItems = new List<Map<String, Object>>();
        newItems.add(new Map<String, Object>{
            'orderDisplay' => 1,
            'type' => 'Component_wrongName',
            'component' => 'Line Info',
            'textValue' => ''
        });

        Map<String, Object> payload = new Map<String, Object>{
            'recordId' => existingView.Id,
            'viewName' => 'Updated Name',
            'viewType' => 'Line_Treasury',
            'isVersionView' => true,
            'displayInOpportunity' => true,
            'items' => newItems
        };

        Test.startTest();
        try {
            DMT_ScreenViewManagementController.upsertApproversViewWithItems(JSON.serialize(payload));
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Single Assert: Validate that an exception occurred
        Assert.isTrue(exceptionThrown, 'An exception should have been thrown due to invalid data');
    }
}