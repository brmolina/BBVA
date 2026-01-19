/*---------------------------------------------------------------------------------------------
        Company:       BBVA
        Description:   Class to test SER_Lookup_CONTROLLER class.
----------------------------------------------------------------------------------------------*/
@isTest
public class SER_Lookup_CONTROLLER_TEST {

  /*-----------------------------------------------------------------------
          Description: createCase.
  ------------------------------------------------------------------------*/
  private static Case createCase() {
    Case newCase;
    newCase = new Case();
    newCase.SER_Classification__c = 'Incidencia';
    newCase.Subject = 'test subject';
    insert newCase;
    return newCase;
  }

  /*-----------------------------------------------------------------------
          Description: createGroup.
  ------------------------------------------------------------------------*/
  private static void createGroup() {
    account grupo;
    grupo = new account();
    grupo.DES_Group_Code__c = 'GroupCode';
    grupo.Name = 'Group Test';
    grupo.Group_BEI__c = 'Filial BEI,Group BEI';
    grupo.RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName('Account', 'Group');
    insert grupo;

    Account filial;
    filial = new Account();
    filial.Name = 'Filial Test';
    filial.DES_Main_Parent__c = grupo.Id;
    filial.gf_bei_Id__c = 'Group BEI';
    filial.SER_CClient__c = 'Codetest';
    insert filial;
  }

  /*-----------------------------------------------------------------------
          Description:   Method to test SER_Lookup_CONTROLLER.fetchRecords
  ------------------------------------------------------------------------*/
  @isTest
  static void fetchRecordsTEST() {
    Case caso;
    caso = createCase();
    Test.startTest();
      SER_Lookup_CONTROLLER.Request request;
      request = new SER_Lookup_CONTROLLER.Request();
      request.objectName = 'Case';
      request.filterField = 'Subject';
      request.value = caso.Id;
      SER_Lookup_CONTROLLER.Request request2;
      request2 = new SER_Lookup_CONTROLLER.Request();
      request2.objectName = 'Case';
      request2.filterField = 'Subject';
      request2.searchString = 'test subject';
      SER_Lookup_CONTROLLER.Response response;
      response = SER_Lookup_CONTROLLER.fetchRecords(request);
      response = SER_Lookup_CONTROLLER.fetchRecords(request2);
      System.assert (!response.recordsDataList.isEmpty(),'Error1');
    Test.stopTest();
  }

  /*-----------------------------------------------------------------------
          Description:   Method to test SER_Lookup_CONTROLLER.fetchRecords KO
  ------------------------------------------------------------------------*/
  @isTest
  static void fetchRecordsTEST2() {
    Case caso;
    caso = createCase();
    Test.startTest();
    try {
      SER_Lookup_CONTROLLER.Request request;
      request = new SER_Lookup_CONTROLLER.Request();
      request.objectName = 'Case';
      request.filterField = 'CaseNumber';
      request.value = caso.Id;
      SER_Lookup_CONTROLLER.fetchRecords(request);
    } catch(Exception exc) {
      System.assertEquals('System.AuraHandledException', exc.getTypeName(),'Error2');
    }
    Test.stopTest();
  }

  /*-----------------------------------------------------------------------
          Description:   Method to test SER_Lookup_CONTROLLER.fetchRecords OK
  ------------------------------------------------------------------------*/
  @isTest
  static void fetchRecordsTEST3() {
    createGroup();
    Test.startTest();
    SER_Lookup_CONTROLLER.Request request;
    request = new SER_Lookup_CONTROLLER.Request();
    request.objectName = 'Group';
    request.searchString = 'Group';
    request.queryFields = 'DES_Main_Parent__c';
    request.filterField = 'gf_bei_Id__c';
    SER_Lookup_CONTROLLER.Response response;
    response = SER_Lookup_CONTROLLER.fetchRecords(request);
    System.assert(response.rdListWFields != null, 'Error 3');
    Test.stopTest();
  }

  /*-----------------------------------------------------------------------
          Description:   Method to test SER_Lookup_CONTROLLER.fetchRecords. Local Reference OK
  ------------------------------------------------------------------------*/
  @isTest
  static void fetchRecordsTEST5() {
    Local_Reference__c localRefTest;
    localRefTest = new Local_Reference__c(External_Id_Ref__c = 'Testing-01', Name = 'Testing Es 01',
                                            solution_category_id__c = 'B2B', gf_bei_id__c = 'TEST01', gf_local_reference_country_id__c = 'ES');
    insert localRefTest;

    Test.startTest();
      SER_Lookup_CONTROLLER.Request request;
      request = new SER_Lookup_CONTROLLER.Request();
      request.objectName = 'Local_Reference__c';
      request.filterField = 'gf_bei_id__c';
      request.searchString = 'TEST';
      request.queryFields = 'gf_reference_id__c';
      SER_Lookup_CONTROLLER.Response response;
      response = SER_Lookup_CONTROLLER.fetchRecords(request);
      System.assert(response.rdListWFields.size() > 0 , 'Error 5');
    Test.stopTest();
  }

}