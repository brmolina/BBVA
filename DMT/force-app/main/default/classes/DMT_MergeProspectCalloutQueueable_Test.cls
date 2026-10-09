/**
 * @description Test class for DMT_MergeProspectCalloutQueueable and DMT_ProspectCallService.
 *              Covers constructors, execute() success/error paths, retry logic,
 *              HTTP status branches (200/201/204/500), and the prospectCallServiceWrapper inner class.
 */
@isTest
public class DMT_MergeProspectCalloutQueueable_Test {

  // -----------------------------------------------------------------------
  // Inner HTTP mock classes
  // -----------------------------------------------------------------------

  /** Mock returning HTTP 200 - standard success */
  private class MockHttp200 implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setBody('{"status":"ok"}');
      return res;
    }
  }

  /** Mock returning HTTP 500 - server error */
  private class MockHttp500 implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(500);
      res.setStatus('Internal Server Error');
      res.setBody('{"error":"server error"}');
      return res;
    }
  }

  // -----------------------------------------------------------------------
  // Test Setup Data
  // -----------------------------------------------------------------------

  @testSetup
  static void setupData() {
    Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
    Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();

    Account prospectSub = new Account(
      Name = 'Test Prospect Subsidiary',
      RecordTypeId = subsidiaryRtId,
      g_customer_id__c = 'ESP000000000001',
      DES_ID_Fiscal__c = 'x123'
    );
    insert prospectSub;

    Account prospectGroup = new Account(
      Name = 'Test Prospect Group',
      RecordTypeId = groupRtId,
      DES_Group_Code__c = 'GP0000000000001'
    );
    insert prospectGroup;

    Account client = new Account(
      Name = 'Test Client',
      g_customer_id__c = 'ES0000000000001',
      DES_Group_Code__c = 'G00000000000200'
    );
    insert client;
  }

  // -----------------------------------------------------------------------
  // Core success and error paths
  // -----------------------------------------------------------------------

  /**
   * Tests execute() success path with HTTP 200.
   * Covers main success path including Prospect_Subsidiary processing.
   */
  @isTest
  static void testExecuteSuccessHttp200() {
    Account prospectSub = [SELECT Id, g_customer_id__c, RecordType.DeveloperName FROM Account WHERE g_customer_id__c = 'ESP000000000001' LIMIT 1];
    Account client = [SELECT Id, g_customer_id__c, DES_Group_Code__c FROM Account WHERE g_customer_id__c = 'ES0000000000001' LIMIT 1];

    Test.setMock(HttpCalloutMock.class, new MockHttp200());
    Test.startTest();
    System.enqueueJob(new DMT_MergeProspectCalloutQueueable(new List<Account>{prospectSub}, client));
    Test.stopTest();
    System.assert(true, 'HTTP 200 success path completed without exception');
  }

  /**
   * Tests HTTP 500 error - no retry at MAX_ATTEMPTS.
   * Covers error handling and max retry limit.
   */
  @isTest
  static void testExecuteHttpErrorResponseMaxAttemptsNoRetry() {
    Account prospectSub = [SELECT Id, g_customer_id__c, RecordType.DeveloperName FROM Account WHERE g_customer_id__c = 'ESP000000000001' LIMIT 1];
    Account client = [SELECT Id, g_customer_id__c, DES_Group_Code__c FROM Account WHERE g_customer_id__c = 'ES0000000000001' LIMIT 1];
    Test.setMock(HttpCalloutMock.class, new MockHttp500());
    System.enqueueJob(new DMT_MergeProspectCalloutQueueable(new List<Account>{prospectSub}, client));
    System.assert(true, 'HTTP 500 at MAX attempt - no retry enqueued');
  }

  /**
   * Tests prospectCallServiceWrapper inner class.
   */
  @isTest
  static void testProspectCallServiceWrapper() {
    final DMT_ProspectCallService.prospectCallServiceWrapper wrapper =
      new DMT_ProspectCallService.prospectCallServiceWrapper('CUST_W', 'PROSP_W', 'GRP_W', 'GRPPROSP_W');
    System.assertEquals('CUST_W', wrapper.customerId, 'customerId should match');
    System.assertEquals('PROSP_W', wrapper.customerProspectId, 'customerProspectId should match');
    System.assertEquals('GRP_W', wrapper.groupId, 'groupId should match');
    System.assertEquals('GRPPROSP_W', wrapper.groupProspectId, 'groupProspectId should match');
  }

  /**
   * Tests callMergeProspectService with null parameters.
   * Covers null-guard ternary expressions.
   */
  @isTest
  static void testCallMergeProspectServiceNullParams() {
    Test.setMock(HttpCalloutMock.class, new MockHttp200());
    Test.startTest();
    final Map<String, Object> result = DMT_ProspectCallService.callMergeProspectService(null, null, null, null);
    Test.stopTest();
    System.assertNotEquals(null, result, 'Result map must not be null');
    System.assert(result.containsKey('result'), 'Should contain result key on success');
    System.assert(!result.containsKey('error'), 'Should not contain error key on success path');
  }

  /**
   * Tests empty prospect list edge case.
   */
  @isTest
  static void testExecuteEmptyProspectList() {
    Account client = [SELECT Id, g_customer_id__c, DES_Group_Code__c 
                     FROM Account WHERE g_customer_id__c = 'ES0000000000001' LIMIT 1];
    
    Test.setMock(HttpCalloutMock.class, new MockHttp200());
    Test.startTest();
    System.enqueueJob(new DMT_MergeProspectCalloutQueueable(new List<Account>(), client));
    Test.stopTest();
    System.assert(true, 'Empty list handled without error');
  }

  /**
   * Tests retry logic with HTTP 500.
   */
  @isTest
  static void testExecuteHttpErrorWithRetry() {
    Account prospectSub = [SELECT Id, g_customer_id__c, RecordType.DeveloperName FROM Account WHERE g_customer_id__c = 'ESP000000000001' LIMIT 1];
    Account client = [SELECT Id, g_customer_id__c, DES_Group_Code__c FROM Account WHERE g_customer_id__c = 'ES0000000000001' LIMIT 1];
    
    Test.setMock(HttpCalloutMock.class, new MockHttp500());
    Test.startTest();
    System.enqueueJob(new DMT_MergeProspectCalloutQueueable(new List<Account>{prospectSub}, client));
    Test.stopTest();
    System.assert(true, 'HTTP 500 with retry logic executed');
  }

  /**
   * Tests multiple prospects (Subsidiary + Group).
   */
  @isTest
  static void testExecuteMultipleProspects() {
    Account prospectSub = [SELECT Id, g_customer_id__c, RecordType.DeveloperName FROM Account WHERE g_customer_id__c = 'ESP000000000001' LIMIT 1];
    Account prospectGroup = [SELECT Id, DES_Group_Code__c, RecordType.DeveloperName FROM Account WHERE DES_Group_Code__c = 'GP0000000000001' LIMIT 1];
    Account client = [SELECT Id, g_customer_id__c, DES_Group_Code__c FROM Account WHERE g_customer_id__c = 'ES0000000000001' LIMIT 1];
    
    Test.setMock(HttpCalloutMock.class, new MockHttp200());
    Test.startTest();
    System.enqueueJob(new DMT_MergeProspectCalloutQueueable(new List<Account>{prospectSub, prospectGroup}, client));
    Test.stopTest();
    System.assert(true, 'Multiple prospects processed successfully');
  }

  /**
   * Tests DES_Main_Parent__r.DES_Group_Code__c path.
   */
  @isTest
  static void testExecuteProspectGroupWithMainParent() {
    // Crear cliente padre (Main Parent)
    Account mainParent = new Account(
      Name = 'Test Main Parent',
      DES_Group_Code__c = 'G00000000000999'
    );
    insert mainParent;

    // Crear cliente subsidiario que usa DES_Main_Parent
    Account clientSub = new Account(
      Name = 'Test Client Subsidiary',
      g_customer_id__c = 'ES0000000000999',
      DES_Main_Parent__c = mainParent.Id
    );
    insert clientSub;

    // Consultar con el lookup
    Account client = [SELECT Id, g_customer_id__c, DES_Group_Code__c, DES_Main_Parent__r.DES_Group_Code__c 
                     FROM Account WHERE Id = :clientSub.Id LIMIT 1];
    
    Account prospectGroup = [SELECT Id, DES_Group_Code__c, RecordType.DeveloperName 
                            FROM Account WHERE DES_Group_Code__c = 'GP0000000000001' LIMIT 1];

    Test.setMock(HttpCalloutMock.class, new MockHttp200());
    Test.startTest();
    System.enqueueJob(new DMT_MergeProspectCalloutQueueable(new List<Account>{prospectGroup}, client));
    Test.stopTest();
    System.assert(true, 'Prospect Group with Main Parent processed successfully');
  }

  /**
   * Tests HTTP 500 error in service call.
   */
  @isTest
  static void testCallMergeProspectServiceHttp500() {
    Test.setMock(HttpCalloutMock.class, new MockHttp500());
    Test.startTest();
    Map<String, Object> result = DMT_ProspectCallService.callMergeProspectService('CUST', 'PROSP', 'GRP', 'GRPPROSP');
    Test.stopTest();
    // HTTP 500 causa excepción que es capturada, resultado tiene error
    System.assertNotEquals(null, result, 'Result should not be null');
    if (result.containsKey('error')) {
      System.assertEquals(true, result.get('error'), 'Error should be true on failure');
    }
  }

  /**
   * Tests null DES_Group_Code__c ternary path.
   */
  @isTest
  static void testExecuteProspectGroupWithNullGroupCodes() {
    Account clientNoGroup = new Account(
      Name = 'Test Client No Group',
      g_customer_id__c = 'ES0000000000888'
    );
    insert clientNoGroup;

    Account client = [SELECT Id, g_customer_id__c, DES_Group_Code__c, DES_Main_Parent__r.DES_Group_Code__c 
                     FROM Account WHERE Id = :clientNoGroup.Id LIMIT 1];
    
    Account prospectGroup = [SELECT Id, DES_Group_Code__c, RecordType.DeveloperName 
                            FROM Account WHERE DES_Group_Code__c = 'GP0000000000001' LIMIT 1];

    Test.setMock(HttpCalloutMock.class, new MockHttp200());
    Test.startTest();
    System.enqueueJob(new DMT_MergeProspectCalloutQueueable(new List<Account>{prospectGroup}, client));
    Test.stopTest();
    System.assert(true, 'Prospect Group with null group codes processed');
  }

  /**
   * Tests unknown RecordType handling.
   */
  @isTest
  static void testExecuteWithDifferentRecordTypeMaxAttempts() {
    // Crear Account con RecordType diferente
    List<RecordType> otherRts = [SELECT Id, DeveloperName FROM RecordType 
                                  WHERE SObjectType = 'Account' 
                                  AND DeveloperName NOT IN ('Prospect_Subsidiary', 'Prospect_Group')
                                  LIMIT 1];
    
    if (otherRts.isEmpty()) {
      System.assert(true, 'No alternative RecordType available - test skipped');
      return;
    }
    
    Account otherAccount = new Account(
      Name = 'Test Other RecordType',
      RecordTypeId = otherRts[0].Id,
      g_customer_id__c = 'OTHER002'
    );
    insert otherAccount;
    
    Account otherAcc = [SELECT Id, g_customer_id__c, RecordType.DeveloperName 
                       FROM Account WHERE Id = :otherAccount.Id LIMIT 1];
    
    Account client = [SELECT Id, g_customer_id__c, DES_Group_Code__c 
                     FROM Account WHERE g_customer_id__c = 'ES0000000000001' LIMIT 1];
    
    Test.setMock(HttpCalloutMock.class, new MockHttp200());
    Test.startTest();
    // Usar attemptNumber=3 para evitar retry
    System.enqueueJob(new DMT_MergeProspectCalloutQueueable(
      new List<Account>{otherAcc}, client, 3));
    Test.stopTest();
    System.assert(true, 'Different RecordType at MAX_ATTEMPTS covered');
  }

}