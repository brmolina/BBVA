/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_CreateTask_Controller
* @Author   ronald.pisco.contractor@bbva.com
* @Date     Created: 2021-04-19
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description this class is the controller for the Arc_Gen_CreateTask_CMP component.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-04-19 ronald.pisco.contractor@bbva.com
*              Class creation.
* ------------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_CreateTask_Controller {
/**
  * @Description: api name of object Task
*/
  static final string TASK_API_NAME = 'Task';
/**
* ----------------------------------------------------------------------------------------------------
* @Description Void Constructor to avoid warning in sonar qube
* ----------------------------------------------------------------------------------------------------
* @author  ronald.pisco.contractor@bbva.com
* @date     2021-04-23
* @param void
* @return void
* @example Arc_Gen_CreateTask_Controller service = new Arc_Gen_CreateTask_Controller()
* ----------------------------------------------------------------------------------------------------
**/
  @TestVisible
  private Arc_Gen_CreateTask_Controller() {

  }
/**
*-------------------------------------------------------------------------------
* @description retrieveData gets the all picklist values for use in custom form.
*--------------------------------------------------------------------------------
* @author  ronald.pisco.contractor@bbva.com
* @date     2021-04-19
* @return Map<Integer, List<String>> picklist values
**/
  @AuraEnabled
  public static Map<Integer, List<String>> retrieveData () {
    final Map<Integer, List<String>> allData = new Map<Integer, List<String>>();
    final Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ARCE Task').getRecordTypeId();
    allData.put(0, new List<String>{recordTypeId});
    allData.put(1, arce.Arc_Gen_GenericUtilities.getMapPicklistValuesLabels(TASK_API_NAME, 'Subject').values());
    allData.put(2, arce.Arc_Gen_GenericUtilities.getMapPicklistValuesLabels(TASK_API_NAME, 'Type').values());
    allData.put(3, arce.Arc_Gen_GenericUtilities.getMapPicklistValuesLabels(TASK_API_NAME, 'Priority').values());
    allData.put(4, arce.Arc_Gen_GenericUtilities.getMapPicklistValuesLabels(TASK_API_NAME, 'Status').values());
    allData.put(5, getFieldLabels(TASK_API_NAME, new List<String>{'Subject', 'Type', 'ActivityDate', 'Description', 'Priority', 'Status'}));
    return allData;
  }
/**
*-------------------------------------------------------------------------------
* @description createTaskRecord insert the task record fill in the custom form.
*--------------------------------------------------------------------------------
* @author  ronald.pisco.contractor@bbva.com
* @date     2021-04-19
* @param taskForInsert type of collection.
* @param  ownerIds List of Ids of the user assigned to task.
* @param  relatedTo Id of the ARCE record related to task
* @return Map<Integer, List<String>> picklist values
**/
  @AuraEnabled
  public static void createTaskRecord (Task taskForInsert, List<Id> ownerIds, Id relatedTo) {
    final List<Task> taskListToInsert = new List<Task>();
    if(!ownerIds.isEmpty()) {
      for(Id singleOwnerId : ownerIds) {
        taskListToInsert.add(new Task(OwnerId = singleOwnerId, Subject =  taskForInsert.Subject, Type = taskForInsert.Type, ActivityDate = taskForInsert.ActivityDate,
        Description = taskForInsert.Description, Priority = taskForInsert.Priority, Status = taskForInsert.Status, WhatId = relatedTo, RecordTypeId = taskForInsert.RecordTypeId));
      }
    }
    insert taskListToInsert;
  }
/**
*-------------------------------------------------------------------------------
* @description getFieldLabels gets the field labels of the picklist fields.
*--------------------------------------------------------------------------------
* @author  ronald.pisco.contractor@bbva.com
* @date     2021-04-19
* @param objectName String with the api name of the object.
* @param  apiNameList List of strings with the api name of the picklist fields.
* @return Map<Integer, List<String>> picklist values
**/
  @AuraEnabled
  public static List<String> getFieldLabels(String objectName, List<String> apiNameList) {
    final List<String> fieldLabelList = new List<String>();
    final Map<String,Schema.SObjectType> allObj = Schema.getGlobalDescribe();
    final Map<String,Schema.SObjectField> allFields = allObj.get(objectName).getDescribe().fields.getMap();
    for(String field : apiNameList) {
      fieldLabelList.add(allFields.get(field).getDescribe().getLabel());
    }
    return fieldLabelList;
  }
}