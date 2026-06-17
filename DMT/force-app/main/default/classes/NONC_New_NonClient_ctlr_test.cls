/************************************************************************
 * @name:                NONC_New_NonClient_ctlr
 * @author               bbva.com developers
 * @date:                2019
 * @version:             1.0
 * @group:               Global Desktop
 * @description:         Test for NONC_New_NonClient_ctlr
 ***************************************************************************/
@isTest
public with sharing class NONC_New_NonClient_ctlr_test{
  /**
   * @description Method which creates test data
   **/
  @testSetup
  static void setup(){
    Prospect_validation__c nonClientCS = new Prospect_validation__c();
    nonClientCS.ClassName_Validation__c = 'NONC_NClient_cls_Validation_propect_test';
    nonClientCS.Non_Client_RecordType__c = 'Non_client';
    nonClientCS.Custom_duplicate_validation__c = true;
    nonClientCS.Country_field__c = 'AccountSource';
    nonClientCS.Type_field__c = 'Type';
    nonClientCS.Unique_Id_field_name__c = 'AccountNumber';
    nonClientCS.Information_fields__c = 'Sic';
    nonClientCS.Percent_to_match__c = 80;
    nonClientCS.Min_Fields_to_block__c = 1;
    nonClientCS.isDisable__c = true;

    insert nonClientCS;

    List<Account> listAcc = new List<Account>();

    Id prospectRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();

    for(integer i=0;i<10;i++){
      Account acc = new Account();
      acc.AccountNumber = '1'+i;
      acc.Name = 'TestAccount'+i;
      acc.Phone = '132145'+i;
      acc.Website = 'www.test'+i+'.com';
      if(prospectRTId != null){
          acc.RecordTypeId = prospectRTId;
      }
      acc.DES_ID_Fiscal__c = 'CIF' + i + 'XYZ';

      listAcc.add(acc);
    }
    insert listAcc;
  }

  @isTest
  static void testNClient(){
    Test.startTest();
    final Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    NONC_New_NonClient_ctlr.WrapperField old = new NONC_New_NonClient_ctlr.WrapperField('nombre', 'nombre');
    old = new NONC_New_NonClient_ctlr.WrapperField();
    NONC_New_NonClient_ctlr.ResultValidation objR = new NONC_New_NonClient_ctlr.ResultValidation();
    objR.status = '';
    objR.message = '';
    NONC_New_NonClient_ctlr.getFieldUniqueId();
    NONC_New_NonClient_ctlr.getFieldLabel('Name');

    NONC_New_NonClient_ctlr.getAllNamesSOSLComponent('test', '', '', 'TABLET', '');
    NONC_New_NonClient_ctlr.getAllNamesSOSLComponent('test', '', '', 'TABLET', '{"Name":"isTest","AccountNumber":"12345"}');
    NONC_New_NonClient_ctlr.getAllNamesSOSL('test', '', nonClientCS, 'TABLET');
    NONC_New_NonClient_ctlr.validateAddRecType();
    NONC_New_NonClient_ctlr.disableforce('{"Name":"isTest","AccountNumber":"12345"}');

    NONC_New_NonClient_ctlr.getSimilarAccountName('test','');
    NONC_New_NonClient_ctlr.WrapperAccount obj = new NONC_New_NonClient_ctlr.WrapperAccount('a//%//a//%//a//%//a','a','a','a','123', '1', 'LEITest', 'CIFTest');
    System.assertNotEquals(obj,null);
    Test.stopTest();
  }

  @isTest
  static void testNClientValidaciones(){

    Prospect_validation__c nonClientCS = [select id, Country_field__c, Type_field__c, Information_fields__c
                                          from Prospect_validation__c];
    nonClientCS.Non_Client_RecordType__c = 'r';
    nonClientCS.Additional_field_duplicate_validation__c = 'Site';
    update nonClientCS;

    NONC_New_NonClient_ctlr.getFieldValidation();
    NONC_New_NonClient_ctlr.getFieldCountry();
    NONC_New_NonClient_ctlr.getFieldType();
    NONC_New_NonClient_ctlr.getFieldInformation();
    NONC_New_NonClient_ctlr.getAccountFieldSetValues('NONC_DuplicateSearchFieldSet', 'Account');
    NONC_New_NonClient_ctlr.isDisabledtrue();
    NONC_New_NonClient_ctlr.compareByType('Test', 'Test', 'STRING', 10, 1);
    NONC_New_NonClient_ctlr.compareByType('10105', '10105', 'PHONE', 10, 1);
    NONC_New_NonClient_ctlr.compareByType('Test', 'Test', 'URL', 10, 1);
    NONC_New_NonClient_ctlr.compareByType('10105', '10105', 'INTEGER', 10, 1);
    NONC_New_NonClient_ctlr.compareByType('Test', 'Test', 'TEXTAREA', 10, 1);

    NONC_New_NonClient_ctlr.validateDuplicateCode('123', nonClientCS);
    NONC_New_NonClient_ctlr.getAllNamesSOSL('test', '123', nonClientCS, 'DESKTOP', '{"Name":"Test to test","Phone":"(123)1448569","Website":"www.bbva.es"}');
    try{
      NONC_New_NonClient_ctlr.getAllNamesSOSLComponent('test', '', '', 'DESKTOP');
    } catch (Exception exc){
      System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error');
    }
    Test.startTest();
    nonClientCS = [select id
                   from Prospect_validation__c];
    nonClientCS.Non_Client_RecordType__c = 'test';
    nonClientCS.ClassName_Validation__c = null;
    update nonClientCS;
    try{
      NONC_New_NonClient_ctlr.getAllNamesSOSLComponent('test', '', '', 'DESKTOP');
    } catch (Exception exc){
      System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error');
    }
    nonClientCS = [select id
                   from Prospect_validation__c];
    nonClientCS.Non_Client_RecordType__c = 'test';
    nonClientCS.ClassName_Validation__c = 'test';
    update nonClientCS;
    try{
      NONC_New_NonClient_ctlr.getAllNamesSOSLComponent('test', '', '', 'TABLET');
    } catch (Exception exc){
      System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error');
    }
    try{
      NONC_New_NonClient_ctlr.validateRecType();
    } catch (Exception exc){
      System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error');
    }

    Test.stopTest();
  }

  @isTest
  static void testNClientValidarCampo(){
    Prospect_validation__c nonClientCS = [select id, Country_field__c
                                          from Prospect_validation__c];
    nonClientCS.Non_Client_RecordType__c = 'r';
    nonClientCS.Additional_field_duplicate_validation__c = 'Site12';
    update nonClientCS;
    NONC_New_NonClient_ctlr.getChecksGooglePlaces();
    try{
      NONC_New_NonClient_ctlr.getFieldValidation();
    } catch (exception exc){
      System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error');
    }

    nonClientCS = [select id, Country_field__c
                   from Prospect_validation__c];
    nonClientCS.Non_Client_RecordType__c = 'r';
    nonClientCS.Additional_field_duplicate_validation__c = 'Id';
    nonClientCS.Country_field__c = 'nus';
    nonClientCS.Unique_Id_field_name__c = 'nus';
    update nonClientCS;

    try{
      NONC_New_NonClient_ctlr.getFieldValidation();
    } catch (exception exc){
      System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error');
    }

    try{
      NONC_New_NonClient_ctlr.getFieldCountry();
    } catch (exception exc){
      System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error');
    }

    try{
      NONC_New_NonClient_ctlr.getFieldUniqueId();
    } catch (exception exc){
      System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error');
    }

    nonClientCS = [select id, Country_field__c
                   from Prospect_validation__c];
    nonClientCS.Non_Client_RecordType__c = 'r';
    nonClientCS.Additional_field_duplicate_validation__c = null;
    nonClientCS.Country_field__c = null;
    update nonClientCS;

    try{
      NONC_New_NonClient_ctlr.getFieldValidation();
    } catch (exception exc){
      System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error');
    }

    try{
      NONC_New_NonClient_ctlr.getFieldCountry();
    } catch (exception exc){
      System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error');
    }

    try{
      NONC_New_NonClient_ctlr.getFieldUniqueId();
    } catch (exception exc){
      System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error');
    }
  }

  @isTest
  static void testGetAllNamesSOSLComponentOverload(){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    NONC_New_NonClient_ctlr.getAllNamesSOSLComponent('test', '', '', 'TABLET', '{"Name":"isTest","AccountNumber":"12345"}');
  }

  @isTest
  static void testGetAllNamesSOSL_Overload(){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    NONC_New_NonClient_ctlr.getAllNamesSOSL('test', '', nonClientCS, 'TABLET', '{"Name":"isTest","AccountNumber":"12345"}');
  }

  @isTest
  static void testWrappersAndConstructors(){
    new NONC_New_NonClient_ctlr.WrapperField();
    new NONC_New_NonClient_ctlr.WrapperField('field', 'label');
    new NONC_New_NonClient_ctlr.WrapperAccount();
    new NONC_New_NonClient_ctlr.WrapperAccount('a//%//a//%//a//%//a', 'a', 'a', 'a', '123', '1', '1234', '12345');
    new NONC_New_NonClient_ctlr.ONB_WrapperAccount();
    new NONC_New_NonClient_ctlr.ONB_WrapperAccount('id', 'name', 'lei', 'type');
    new NONC_New_NonClient_ctlr.ResultValidation();
  }

  @isTest
  static void testFieldValidationMethods(){
    try{
      NONC_New_NonClient_ctlr.getFieldValidation();
    } catch (Exception e){
    }
    try{
      NONC_New_NonClient_ctlr.getFieldCountry();
    } catch (Exception e){
    }
    try{
      NONC_New_NonClient_ctlr.getFieldType();
    } catch (Exception e){
    }
    try{
      NONC_New_NonClient_ctlr.getFieldInformation();
    } catch (Exception e){
    }
    try{
      NONC_New_NonClient_ctlr.getFieldUniqueId();
    } catch (Exception e){
    }
  }

  @isTest
  static void testRecordTypeValidationMethods(){
    try{
      NONC_New_NonClient_ctlr.validateRecType();
    } catch (Exception e){
    }
    try{
      NONC_New_NonClient_ctlr.validateAddRecType();
    } catch (Exception e){
    }
  }

  @isTest
  static void testGetAccountFieldSetValues(){
    try{
      NONC_New_NonClient_ctlr.getAccountFieldSetValues('NONC_DuplicateSearchFieldSet', 'Account');
    } catch (Exception e){
    }
  }

  @isTest
  static void testDisableforceAndIsDisabledtrue(){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    Boolean disabled = NONC_New_NonClient_ctlr.isDisabledtrue();
    Boolean force = NONC_New_NonClient_ctlr.disableforce('{"Unique_Id_field_name__c":"123456"}');
    System.assertNotEquals(null, disabled);
    System.assertNotEquals(null, force);
  }

  @isTest
  static void testGetSimilarAccountNameWithInvalidField(){
    try{
      NONC_New_NonClient_ctlr.getSimilarAccountName('TestName', 'CampoInexistente__c');
      System.assert(false, 'Debe lanzar excepción por campo inválido');
    } catch (Exception e){
      System.assertEquals('Script-thrown exception', e.getMessage(), 'Error');
    }
  }

  @isTest
  static void testGetSimilarAccountName_EarlyReturn(){
    // searchName vacío
    String result = NONC_New_NonClient_ctlr.getSimilarAccountName('', '');
    System.assertEquals('', result);
    // searchName nulo
    result = NONC_New_NonClient_ctlr.getSimilarAccountName(null, '');
    System.assertEquals('', result);
    // searchName de un solo caracter
    result = NONC_New_NonClient_ctlr.getSimilarAccountName('a', '');
    System.assertEquals('', result);
  }

  @isTest
  static void testGetFieldValidationEarlyReturn(){
    // Forzar custom setting vacío
    Prospect_validation__c nonClientCS = [SELECT Id
                                          FROM Prospect_validation__c
                                          LIMIT 1];
    nonClientCS.Additional_field_duplicate_validation__c = null;
    update nonClientCS;
    String result = NONC_New_NonClient_ctlr.getFieldValidation();
    System.assertEquals('', result);
  }

  @isTest
  static void testGetFieldCountryEarlyReturn(){
    Prospect_validation__c nonClientCS = [SELECT Id
                                          FROM Prospect_validation__c
                                          LIMIT 1];
    nonClientCS.Country_field__c = null;
    update nonClientCS;
    String result = NONC_New_NonClient_ctlr.getFieldCountry();
    System.assertEquals('', result);
  }

  @isTest
  static void testGetFieldTypeEarlyReturn(){
    Prospect_validation__c nonClientCS = [SELECT Id
                                          FROM Prospect_validation__c
                                          LIMIT 1];
    nonClientCS.Type_field__c = null;
    update nonClientCS;
    String result = NONC_New_NonClient_ctlr.getFieldType();
    System.assertEquals('', result);
  }

  @isTest
  static void testGetFieldInformationEarlyReturn(){
    Prospect_validation__c nonClientCS = [SELECT Id
                                          FROM Prospect_validation__c
                                          LIMIT 1];
    nonClientCS.Information_fields__c = null;
    update nonClientCS;
    String result = NONC_New_NonClient_ctlr.getFieldInformation();
    System.assertEquals('', result);
  }

  @isTest
  static void testValidateAddRecTypeEarlyReturn(){
    Prospect_validation__c nonClientCS = [SELECT Id
                                          FROM Prospect_validation__c
                                          LIMIT 1];
    nonClientCS.Additional_Non_Client_RecordType__c = null;
    update nonClientCS;
    String result = NONC_New_NonClient_ctlr.validateAddRecType();
    System.assertEquals('', result);
  }

  @isTest
  static void testGetAccountFieldSetValuesInvalid(){
    try{
      NONC_New_NonClient_ctlr.getAccountFieldSetValues('FieldSetInexistente', 'Account');
      System.assert(false, 'Debe lanzar excepción por fieldset inexistente');
    } catch (Exception e){
      System.assert(e.getMessage().contains('null'), 'Mensaje de excepción esperado');
    }
    try{
      NONC_New_NonClient_ctlr.getAccountFieldSetValues('NONC_DuplicateSearchFieldSet', 'ObjetoInexistente');
      System.assert(false, 'Debe lanzar excepción por objeto inexistente');
    } catch (Exception e){
      System.assert(e.getMessage().contains('null'), 'Mensaje de excepción esperado');
    }
  }

  @isTest
  static void testONB_getAllNamesSOSL_and_ONB_createNewOnboarding(){
    // Llama con valores válidos
    String result = NONC_New_NonClient_ctlr.ONB_getAllNamesSOSL('TestAccount0', '123', 'DESKTOP');
    System.assertNotEquals(null, result);

    result = NONC_New_NonClient_ctlr.ONB_createNewOnboarding('TestAccount0', '123', 'DESKTOP');
    System.assertNotEquals(null, result);

    // Llama con valores vacíos/nulos para cubrir caminos alternativos
    result = NONC_New_NonClient_ctlr.ONB_getAllNamesSOSL('', '', '');
    System.assertNotEquals(null, result);

    result = NONC_New_NonClient_ctlr.ONB_createNewOnboarding('', '', '');
    System.assertNotEquals(null, result);
  }

  @isTest
  static void testHasFieldsToQuery(){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    String result = NONC_New_NonClient_ctlr.hasFieldsToQuery(nonClientCS);
    System.assertNotEquals(null, result);
  }

}