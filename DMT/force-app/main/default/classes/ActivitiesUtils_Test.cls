/***********************************************************************************************************************************
* @author       Accenture
* @date         01/03/2016
* @description  Clase de test para ActivitiesUtils_Test
* @Revision     Modificacion del metodo crearData y los testMethod para resolucion de errores
************************************************************************************************************************************/
@isTest
public class ActivitiesUtils_Test {
  /* account */
  public static  Account account;
  /* contact */
  public static  Contact contact;
  /* event */
  public static  Event event;
  /* caso */
  public static  Case caso;
  /*Constant Status Working*/
  final public static string STATUS_WRK = 'Working';
  /*Constant Priority Normal */
  final public static string PRIO_NORMAL = 'Normal';
  /*Constant 'Call' */
  final public static string CALL = 'Call';

  /*
      Method Creat Data
  */
  @testSetup public static void crearData() {
      CIB_User_Org__c csiUserOrgInstanc;
      csiUserOrgInstanc = new CIB_User_Org__c();
      csiUserOrgInstanc.CIB_Is_Sales__c = true;
      insert csiUserOrgInstanc;
  
      gcal__GBL_Google_Calendar_Sync_Environment__c csGcal;
      csGcal = new gcal__GBL_Google_Calendar_Sync_Environment__c();
      csGcal.Name = 'DEV';
      insert csGcal;
  
      account = UnitTestUtils.GetStandardAccount();
      insert account;
  
      User sampleFISalesUser;
      sampleFISalesUser = UnitTestUtils.GetFISalesUser();
      insert sampleFISalesUser;
  
      caso = new Case();
      insert caso;
  
      system.runAs(sampleFISalesUser) {
          contact = UnitTestUtils.GetContact(account.id);
          contact.Logical_Delete__c = False;
          contact.Asset_Class_Text__c = ConstantsUtils.EQ;
          contact.Email = 'test@example.com';
          contact.ownerId = sampleFISalesUser.Id;
          contact.RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName('Contact','SER_Service_Contact_Global_Markets');
      insert contact;}
  
      Event evento;
    evento = new Event(DurationInMinutes = 8,
          ActivityDateTime = Date.today(),
          WhatId = caso.Id,
          WhoId = contact.Id,
                      IsPublicEquity__c = false);
      insert evento;
  
      Task task1;
    task1 = new Task(OwnerId = sampleFISalesUser.Id,
          Status = 'Completed',
          Priority = PRIO_NORMAL,
          Subject = CALL,
          WhatId = account.Id,
          WhoId = contact.Id,
                          type = CALL,
                          IsPublicEquity__c = false);
      insert task1;
  
      Task task2;
    task2 = new Task(OwnerId = sampleFISalesUser.Id,
          Status = 'Completed',
          Priority = PRIO_NORMAL,
          Subject = CALL,
          WhoId = contact.Id,
                          type = CALL,
                          IsPublicEquity__c = false);
      insert task2;
  
      // Crear tipos de tarea requeridos
      DMT_Task_Type__c taskType1 = new DMT_Task_Type__c(Name = 'Risk Approval - Local', DMT_External_Id__c = 'RiskApprovalLocal');
      DMT_Task_Type__c taskType2 = new DMT_Task_Type__c(Name = 'Risk Analysis (local approval)', DMT_External_Id__c = 'RiskAnalysisLocal');
      insert new List<DMT_Task_Type__c>{ taskType1, taskType2 };
  
      // Crear línea relacionada con el caso
      DMT_Line__c testLine = new DMT_Line__c(
          Line_Id__c = 'LINE123',
          DMT_Global_Risk_Analyst_User__c = null,
          DMT_Global_Risk_Analyst__c = null,
          DMT_Local_Risk_Analyst__c = null
      );
      insert testLine;
  
      // Asociar el caso a la línea
      caso.DMT_Line__c = testLine.Id;
      update caso;
  
      // Crear línea consolidada relacionada
      /*DMT_Consolidated_Line__c testConsolidatedLine = new DMT_Consolidated_Line__c(
          line_id__c = 'LINE123',
          global_risk_analyst__c = null,
          global_risk_analyst_name__c = null,
          gf_group_line_id__c = 'LINE123',
          gf_group_priority_line_id__c = '1'
      );
      insert testConsolidatedLine;*/
  
      // Modificar una tarea existente para que cumpla con los criterios del método
      task1.WhatId = caso.Id;
      task1.DMT_Task_Type__c = taskType1.Id;
      update task1;
  }  

  /*---------------------------------------------------------------------------
          Description:   getRecord
  ----------------------------------------------------------------------------*/
  public static void getRecord() {
    account = [SELECT Id FROM Account LIMIT 1];
    caso = [SELECT Id FROM Case LIMIT 1];
    contact =  [SELECT Id, Logical_Delete__c, Asset_Class__c, Email FROM Contact LIMIT 1];
    event = [SELECT Id, DurationInMinutes, ActivityDateTime, WhatId, WhoId, IsPublicEquity__c FROM Event LIMIT 1];
  }

  /*----------------------------------------------------------------------------
          Description:   Method to test ActivitiesUtils.check_EmptyContactEmail
  -----------------------------------------------------------------------------*/
  @isTest
  public static void checkEmptyContactEmailTEST() {

    gcal__GBL_Google_Calendar_Sync_Environment__c csGcal;
    csGcal = new gcal__GBL_Google_Calendar_Sync_Environment__c();
    csGcal.Name = 'DEV';
    insert csGcal;

    account = UnitTestUtils.GetStandardAccount();
    account.Name = Label.SER_SernovaAccountNAME;
    insert account;

    caso = new Case();
    insert caso;

    getRecord();
    Map<Id, Contact> mapContact;
    mapContact = new Map<id, Contact>();
    mapContact.put(contact.Id, contact);
    Test.startTest();
    ActivitiesUtils.check_EmptyContactEmail(mapContact);
    System.assertEquals(ContactTriggerHandler.map_EmptyEmailContacts.get(contact.Id), null, 'Error');
    Test.stopTest();
  }

  /*---------------------------------------------------------------------------
          Description:   Method to test ActivitiesUtils.check_EmptyContactEmail
  ----------------------------------------------------------------------------*/
  @isTest
  public static void check_setTimeAccount_TEST() {

    account = UnitTestUtils.GetStandardAccount();
    account.Name = Label.SER_SernovaAccountNAME;
    insert account;
    caso = new Case();
    insert caso;

    getRecord();
    Map<Id, Contact> mapContact;
    mapContact = new Map<id, Contact>();
    mapContact.put(contact.Id, contact);
    Test.startTest();
    ActivitiesUtils.check_EmptyContactEmail(mapContact);
    System.assertEquals(ContactTriggerHandler.map_EmptyEmailContacts.get(contact.Id), null, 'Error2');
    Test.stopTest();
  }
    @isTest
    static void testUpdateLineFromTask() {
        // Obtener la tarea de prueba
        Task testTask = [SELECT Id, WhatId, Status, LastModifiedById, DMT_Task_Type__r.Name, DMT_Task_Type__c FROM Task LIMIT 1];

        // Ejecutar el método a probar
        Test.startTest();
        ActivitiesUtils.updateLineFromTask(new List<Task>{testTask});
        Test.stopTest();

        // Verificar que la línea se actualizó correctamente
        DMT_Line__c updatedLine = [SELECT Id, DMT_Global_Risk_Analyst_User__c, DMT_Global_Risk_Analyst__c, DMT_Local_Risk_Analyst__c FROM DMT_Line__c LIMIT 1];
        //System.assertEquals(testTask.LastModifiedById, updatedLine.DMT_Global_Risk_Analyst_User__c, 'El usuario de la línea debe haberse actualizado');
        System.assertNotEquals(null, updatedLine.DMT_Local_Risk_Analyst__c, 'El nombre del analista debe estar actualizado');
        // Verificar que la línea consolidada se actualizó correctamente
        /*DMT_Consolidated_Line__c updatedConsolidatedLine = [SELECT Id, global_risk_analyst__c, global_risk_analyst_name__c FROM DMT_Consolidated_Line__c LIMIT 1];
        System.assertEquals(testTask.LastModifiedById, updatedConsolidatedLine.global_risk_analyst__c, 'El usuario consolidado debe haberse actualizado');
        System.assertNotEquals(null, updatedConsolidatedLine.global_risk_analyst_name__c, 'El nombre del analista consolidado debe estar actualizado');*/
    }
}