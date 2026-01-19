/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_CreateTask_Test
* @Author   ronald.pisco.contractor@bbva.com
* @Date     Created: 2021-20-04
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for Arc_Gen_CreateTask_Controller
* ------------------------------------------------------------------------------------------------
* |2021-20-04 ronald.pisco.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class Arc_Gen_CreateTask_Test {
  /**
  * @Description: String with external id of test group
  */
  static final string GROUP_ID = 'G000001';
  /**
  * @Description: String with external id of test subsidiary
  */
  static final string SUBSIDIARY_ID = 'C000001';
  /**
  * @Description: Id of desired recordType
  */
  static final Id RECORD_TYPE_ID = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ARCE Task').getRecordTypeId();
  /**
  * @Description: String with subject of task
  */
  static final string TASK_SUBJECT = 'Task ends soon';
  /**
  * @Description: String with value of picklist field type of task
  */
  static final string TASK_TYPE = 'Email';
  /**
  * @Description: String with value of field description of task
  */
  static final string TASK_DESCRIPTION = 'I need help with the task';
  /**
  * @Description: String with value of picklist field priority of task
  */
  static final string TASK_PRIORITY = 'Normal';
  /**
  * @Description: String with value of picklist field status of task
  */
  static final string TASK_STATUS = 'In Progress';
  /*
        @Description setup method
  */
  @testSetup static void setup() {
    final User userTest = Arc_UtilitysDataTest_tst.crearUsuario('UserTest',System.Label.Cls_arce_ProfileSystemAdministrator,'');
    userTest.ID_User__C = String.valueOf((Math.random()*100000));
    insert userTest;
    Arc_UtilitysDataTest_tst.setupAcccounts();
    final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
    final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
    final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
    insert newArce;
  }
  /*
        @Description test method
  */
  @isTest public static void retrieveDatatest() {
    Map<Integer, List<String>> mapPicklistvalues;
    Test.startTest();
    mapPicklistvalues = Arc_Gen_CreateTask_Controller.retrieveData();
    system.assertEquals(6, mapPicklistvalues.size(), 'the map is not the expected length');
    Test.stopTest();
  }
  /*
        @Description test method
  */
  @isTest public static void createTaskRecordtest() {
    final arce__Analysis__c arceRelated = [SELECT Id,Name FROM arce__Analysis__c LIMIT 1];
    final User owner = [SELECT Id FROM User LIMIT 1];
    final Task taskToInsert = new Task();
    taskToInsert.Subject = TASK_SUBJECT;
    taskToInsert.Type = TASK_TYPE;
    taskToInsert.ActivityDate = System.today();
    taskToInsert.Description = TASK_DESCRIPTION;
    taskToInsert.Priority = TASK_PRIORITY;
    taskToInsert.Status = TASK_STATUS;
    taskToInsert.RecordTypeId = RECORD_TYPE_ID;
    Test.startTest();
    Arc_Gen_CreateTask_Controller.createTaskRecord(taskToInsert, new List<Id>{owner.Id}, arceRelated.Id);
    final Task taskInserted = [SELECT Id FROM Task LIMIT 1];
    system.assert(!String.isEmpty(taskInserted.Id), 'the task is not inserted');
    Test.stopTest();
  }
}