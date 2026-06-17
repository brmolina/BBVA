/************************************************************************
 * @name:                NONC_New_NonClient_ctlr
 * @author                              bbva.com developers
 * @date:               2019
 * @version:             1.0
 * @group:                      Global Desktop
 * @description:         Controller of New_NonClient component
 ***************************************************************************/
global with sharing class NONC_New_NonClient_ctlr{
  /**********************************************************************************************************
   * @name            getFieldValidation
   * @author          Global Desktop
   * @created         2019
   * @description     Check if the additional field of the custom setting exists and its type is text.
   * @return          String - Error if does not exist or is not text.
   **********************************************************************************************************/
  @AuraEnabled
  global static String getFieldValidation(){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    if (nonClientCS.Additional_field_duplicate_validation__c != null && nonClientCS.Additional_field_duplicate_validation__c.trim().length() > 0){
      try{
        Account objValidar = new Account();
        objValidar.get(nonClientCS.Additional_field_duplicate_validation__c);
        if (String.ValueOf(Schema.SObjectType.Account.fields.getMap().get(nonClientCS.Additional_field_duplicate_validation__c).getDescribe().getType()) != 'STRING'){
          throw new AuraHandledException('The Validation field must be TEXT in .');//NOSONAR
        }
        return JSON.serialize(new WrapperField(nonClientCS.Additional_field_duplicate_validation__c, NONC_New_NonClient_ctlr.getFieldLabel(nonClientCS.Additional_field_duplicate_validation__c)));//NOSONAR
      } catch (Exception exc){
        //NOSONAR
        throw new AuraHandledException(system.Label.NClient_lbl_NotExistCustomField.replace('&Field&', nonClientCS.Additional_field_duplicate_validation__c)); //NOSONAR
      }
    }
    return '';//NOSONAR
  }

  /**********************************************************************************************************
   * @name            getChecksGooglePlaces
   * @author          Global Desktop
   * @created         2019
   * @description     Checks for the google places functionality.
   * @return          String - JSON with checks.
   **********************************************************************************************************/
  @AuraEnabled
  global static String getChecksGooglePlaces(){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();

    Map<String, Object> checksGoogle = new Map<String, Object>();

    Boolean addressPredictive = nonClientCS.Address_Predictive__c;
    Boolean showGoogleMap = nonClientCS.show_Google_Map__c;

    checksGoogle.put('addressPredictive', addressPredictive);
    checksGoogle.put('showGoogleMap', showGoogleMap);

    return JSON.serialize(checksGoogle);
  }

  /**********************************************************************************************************
   * @name            getAccountFieldSetValues
   * @author          Global Desktop
   * @created         2019
   * @description     Get fieldset values for Account.
   * @param           String fieldSetName - Name of the fieldset.
   * @param           String objectName - Name of the object.
   * @return          String - JSON with fieldset values.
   **********************************************************************************************************/
  @AuraEnabled
  global static String getAccountFieldSetValues(String fieldSetName, String objectName){
    //NOSONAR
    Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
    Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(objectName);
    Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();

    Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

    List<Schema.FieldSetMember> fieldSetMemberList = fieldSetObj.getFields();
    Map<String, List<Object>> fieldsApiNames = new Map<String, List<Object>>();
    List<Object> billingAddressFieldsObject = new List<Object>();
    List<Object> shippingAddressFieldsObject = new List<Object>();
    List<Object> simpleFieldsObject = new List<Object>();

    for (Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){

      if (fieldSetMemberObj.getFieldPath().contains('Billing')){
        billingAddressFieldsObject.add(fieldSetMemberObj);
      } else if (fieldSetMemberObj.getFieldPath().contains('Shipping')){
        shippingAddressFieldsObject.add(fieldSetMemberObj);
      } else{
        simpleFieldsObject.add(fieldSetMemberObj);
      }
    }

    fieldsApiNames.put('billingFields', billingAddressFieldsObject);
    fieldsApiNames.put('shippingFields', shippingAddressFieldsObject);
    fieldsApiNames.put('simpleFields', simpleFieldsObject);

    String jsonserialize = JSON.serialize(fieldsApiNames);
    System.debug('jsonserialize' + jsonserialize);
    return jsonserialize;
  }

  /**********************************************************************************************************
   * @name            getFieldCountry
   * @author          Global Desktop
   * @created         2019
   * @description     Check if the country field of the custom setting exists and its type is text.
   * @return          String - Error if does not exist or is not text.
   **********************************************************************************************************/
  @AuraEnabled
  global static String getFieldCountry(){
    Prospect_validation__c nonClientCountryCS = Prospect_validation__c.getInstance();
    if (nonClientCountryCS.Country_field__c != null && nonClientCountryCS.Country_field__c.trim().length() > 0){
      try{
        Account objValidar = new Account();
        objValidar.get(nonClientCountryCS.Country_field__c);
        if (String.ValueOf(Schema.SObjectType.Account.fields.getMap().get(nonClientCountryCS.Country_field__c).getDescribe().getType()) != 'STRING' && String.ValueOf(Schema.SObjectType.Account.fields.getMap().get(nonClientCountryCS.Country_field__c).getDescribe().getType()) != 'PICKLIST'){
          throw new AuraHandledException('The Country field must be TEXT in .');
        }
        return JSON.serialize(new WrapperField(nonClientCountryCS.Country_field__c, NONC_New_NonClient_ctlr.getFieldLabel(nonClientCountryCS.Country_field__c)));//NOSONAR
      } catch (Exception exc){
        //NOSONAR
        throw new AuraHandledException(system.Label.NClient_lbl_NotExistCustomField.replace('&Field&', nonClientCountryCS.Country_field__c)); //NOSONAR
      }
    }
    return '';//NOSONAR
  }

  /**********************************************************************************************************
   * @name            getFieldType
   * @author          Global Desktop
   * @created         2019
   * @description     Check if the type field of the custom setting exists and its type is text.
   * @return          String - Error if does not exist or is not text.
   **********************************************************************************************************/
  @AuraEnabled
  global static String getFieldType(){
    Prospect_validation__c nonClientTypeCS = Prospect_validation__c.getInstance();
    if (nonClientTypeCS.Type_field__c != null && nonClientTypeCS.Type_field__c.trim().length() > 0){
      try{
        Account objValidar = new Account();
        objValidar.get(nonClientTypeCS.Type_field__c);
        if (String.ValueOf(Schema.SObjectType.Account.fields.getMap().get(nonClientTypeCS.Type_field__c).getDescribe().getType()) != 'STRING' && String.ValueOf(Schema.SObjectType.Account.fields.getMap().get(nonClientTypeCS.Type_field__c).getDescribe().getType()) != 'PICKLIST'){
          throw new AuraHandledException('The Type field must be TEXT in .');
        }
        return JSON.serialize(new WrapperField(nonClientTypeCS.Type_field__c, NONC_New_NonClient_ctlr.getFieldLabel(nonClientTypeCS.Type_field__c)));
      } catch (Exception exc){
        throw new AuraHandledException(system.Label.NClient_lbl_NotExistCustomField.replace('&Field&', nonClientTypeCS.Type_field__c)); //NOSONAR
      }
    }
    return '';
  }

  /**********************************************************************************************************
   * @name            getFieldInformation
   * @author          Global Desktop
   * @created         2019
   * @description     Check if the Information field of the custom setting exists and its type is text.
   * @return          String - Error if does not exist or is not text.
   **********************************************************************************************************/
  @AuraEnabled
  global static String getFieldInformation(){
    Prospect_validation__c nonClientTypeCS = Prospect_validation__c.getInstance();
    if (nonClientTypeCS.Information_fields__c != null && nonClientTypeCS.Information_fields__c.trim().length() > 0){
      try{
        Account objValidar = new Account();
        objValidar.get(nonClientTypeCS.Information_fields__c);
        if (String.ValueOf(Schema.SObjectType.Account.fields.getMap().get(nonClientTypeCS.Information_fields__c).getDescribe().getType()) != 'STRING' && String.ValueOf(Schema.SObjectType.Account.fields.getMap().get(nonClientTypeCS.Information_fields__c).getDescribe().getType()) != 'PICKLIST'){
          throw new AuraHandledException('The Type field must be TEXT in .');
        }
        return JSON.serialize(new WrapperField(nonClientTypeCS.Information_fields__c, NONC_New_NonClient_ctlr.getFieldLabel(nonClientTypeCS.Information_fields__c)));
      } catch (Exception exc){
        throw new AuraHandledException(system.Label.NClient_lbl_NotExistCustomField.replace('&Field&', nonClientTypeCS.Information_fields__c)); //NOSONAR
      }
    }
    return '';
  }

  /**********************************************************************************************************
   * @name            getFieldUniqueId
   * @author          Global Desktop
   * @created         2019
   * @description     Check if the unique id field of the custom setting exists and its type is text.
   * @return          String - Error if does not exist or is not text.
   **********************************************************************************************************/
  @AuraEnabled
  global static String getFieldUniqueId(){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    if (nonClientCS.Unique_Id_field_name__c != null && nonClientCS.Unique_Id_field_name__c.trim().length() > 0){
      try{
        Account objValidar = new Account();
        objValidar.get(nonClientCS.Unique_Id_field_name__c);
        if (String.ValueOf(Schema.SObjectType.Account.fields.getMap().get(nonClientCS.Unique_Id_field_name__c).getDescribe().getType()) != 'STRING'){
          throw new AuraHandledException('Unique Id field must be text type.');
        }
        return JSON.serialize(new WrapperField(nonClientCS.Unique_Id_field_name__c, NONC_New_NonClient_ctlr.getFieldLabel(nonClientCS.Unique_Id_field_name__c)));
      } catch (Exception exc){
        throw new AuraHandledException(system.Label.NClient_lbl_NotExistCustomField.replace('&Field&', nonClientCS.Unique_Id_field_name__c)); //NOSONAR
      }
    }
    return '';
  }

  /**********************************************************************************************************
   * @name            validateRecType
   * @author          Global Desktop
   * @created         2019
   * @description     Check if the record type exists in Account.
   * @return          String - Error if does not exist.
   **********************************************************************************************************/
  @AuraEnabled
  global static String validateRecType(){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    if (nonClientCS.Non_Client_RecordType__c != null && nonClientCS.Non_Client_RecordType__c.trim().length() > 0){
      try{
        if (Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(nonClientCS.Non_Client_RecordType__c) == null){
          throw new AuraHandledException('Not exists a Record Type in account with the name specified in custom setting.');
        }
        return JSON.serialize(new WrapperField(nonClientCS.Unique_Id_field_name__c, NONC_New_NonClient_ctlr.getFieldLabel(nonClientCS.Unique_Id_field_name__c)));
      } catch (Exception exc){
        throw new AuraHandledException(system.Label.NClient_lbl_NotExistsRT); //NOSONAR
      }
    }
    return '';
  }

  /**********************************************************************************************************
   * @name            validateAddRecType
   * @author          Global Desktop
   * @created         2019
   * @description     Check if the additional record type exists in Account.
   * @return          String - Error if does not exist.
   **********************************************************************************************************/
  @AuraEnabled
  global static String validateAddRecType(){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    if (nonClientCS.Additional_Non_Client_RecordType__c != null && nonClientCS.Additional_Non_Client_RecordType__c.trim().length() > 0){
      try{
        if (Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(nonClientCS.Additional_Non_Client_RecordType__c) == null){
          throw new AuraHandledException('Not exists an Additional Record Type in account with the name specified in custom setting.');
        }
        return JSON.serialize(new WrapperField(nonClientCS.Unique_Id_field_name__c, NONC_New_NonClient_ctlr.getFieldLabel(nonClientCS.Unique_Id_field_name__c)));
      } catch (Exception exc){
        throw new AuraHandledException(system.Label.NClient_lbl_NotExistsRT); //NOSONAR
      }
    }
    return '';
  }

  /**********************************************************************************************************
   * @name            getAllNamesSOSLComponent
   * @author          Global Desktop
   * @created         2019
   * @description     Check if exists a custom class in the custom setting, and validate duplicate non clients.
   * @param           String searchName
   * @param           String strFielValidation
   * @param           String strFielLabel
   * @param           String isOnDesktop
   * @return          String - Wrapper with duplicate Non Clients.
   **********************************************************************************************************/
  @AuraEnabled
  global static String getAllNamesSOSLComponent(String searchName, String strFielValidation, String strFielLabel, String isOnDesktop){
    return getAllNamesSOSLComponent(searchName, strFielValidation, strFielLabel, isOnDesktop, '');
  }

  /**********************************************************************************************************
   * @name            getAllNamesSOSLComponent (overload)
   * @author          Global Desktop
   * @created         2019
   * @description     Overloaded method for custom fields.
   * @param           String searchName
   * @param           String strFielValidation
   * @param           String strFielLabel
   * @param           String isOnDesktop
   * @param           String fields
   * @return          String - Wrapper with duplicate Non Clients.
   **********************************************************************************************************/
  @AuraEnabled@SuppressWarnings('PMD.ExcessiveParameterList')
  global static String getAllNamesSOSLComponent(String searchName, String strFielValidation, String strFielLabel, String isOnDesktop, String fields){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    if (nonClientCS.Non_Client_RecordType__c == null || nonClientCS.Non_Client_RecordType__c.trim().length() == 0 || nonClientCS.Non_Client_RecordType__c.trim().length() == 1){
      throw new AuraHandledException(system.Label.NClient_lbl_NotExistRecordtype);
    }
    if ((nonClientCS.Custom_duplicate_validation__c || nonClientCS.Custom_validation_creation__c) && (nonClientCS.ClassName_Validation__c == null || nonClientCS.ClassName_Validation__c.trim().length() == 0)){
      throw new AuraHandledException(system.Label.NClient_lbl_NotExistCustomClass);
    }
    Boolean bolCustomValidation = nonClientCS.Custom_duplicate_validation__c;
    String className = nonClientCS.ClassName_Validation__c;
    Boolean bolCreateValidation = nonClientCS.Custom_validation_creation__c;
    String idRecordType = null;
    if (!Test.isRunningTest() && Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(nonClientCS.Non_Client_RecordType__c) != null){
      idRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(nonClientCS.Non_Client_RecordType__c).getRecordTypeId();
    }
    if ((bolCreateValidation || bolCustomValidation) && className.trim().length() > 0){
      try{
        Type typeCustomCLass = Type.forName(className);
        Object classCustomValidation = typeCustomCLass.newInstance();
        NONC_NonClient_interface_prospect infCustomValidation = (NONC_NonClient_interface_prospect)classCustomValidation;
      } catch (Exception exc){
        throw new AuraHandledException(system.Label.NClient_lbl_CustomClassNotWork); //NOSONAR
      }
    }

    if (bolCustomValidation != null && bolCustomValidation){
      Type typeCustomCLass = Type.forName(className);
      Object classCustomValidation = typeCustomCLass.newInstance();
      NONC_NonClient_interface_prospect infCustomValidation = (NONC_NonClient_interface_prospect)classCustomValidation;
      return infCustomValidation.checkDuplicateNonClients(searchName, nonClientCS.Additional_field_duplicate_validation__c, strFielValidation);
    }

    return NONC_New_NonClient_ctlr.getAllNamesSOSL(searchName, strFielValidation, nonClientCS, isOnDesktop, fields);
  }

  /**********************************************************************************************************
   * @name            validateDuplicateCode
   * @author          bbva.com developers
   * @created         2019
   * @description     Check if exists any account with duplicate value in the field of custom setting.
   * @param           String strFielValidation
   * @param           Prospect_validation__c nonClientCS
   * @return          List<WrapperAccount> - Wrapper with duplicate Non Clients.
   **********************************************************************************************************/
  public static List<WrapperAccount> validateDuplicateCode(String strFielValidation, Prospect_validation__c nonClientCS){
    List<WrapperAccount> lWrapper = new List<WrapperAccount>();
    String country = '';
    if (nonClientCS.Country_field__c != null && nonClientCS.Country_field__c != ''){
      if(Schema.DisplayType.PICKLIST == Schema.SObjectType.Account.fields.getMap().get(nonClientCS.Country_field__c).getDescribe().getType()){
          country = 'toLabel(' + nonClientCS.Country_field__c + '), ';
        }else {
          country = nonClientCS.Country_field__c + ', ';
        }
    }
    String fieldType = '';
    if (nonClientCS.Type_field__c != null && nonClientCS.Type_field__c != ''){
      fieldType = nonClientCS.Type_field__c + ', ';
    }
    if (strFielValidation != null && strFielValidation.trim().length() > 0){
      // Validar campos
      Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
      List<String> fieldsToCheck = new List<String>();
      if (!String.isBlank(nonClientCS.Additional_field_duplicate_validation__c))
        fieldsToCheck.add(nonClientCS.Additional_field_duplicate_validation__c);
      if (!String.isBlank(nonClientCS.Country_field__c))
        fieldsToCheck.add(nonClientCS.Country_field__c);
      if (!String.isBlank(nonClientCS.Type_field__c))
        fieldsToCheck.add(nonClientCS.Type_field__c);
      if (!String.isBlank(nonClientCS.Information_fields__c))
        fieldsToCheck.add(nonClientCS.Information_fields__c);
      for (String field : fieldsToCheck){
        if (!accountFields.containsKey(field)){
          throw new AuraHandledException('Campo no válido para Account: ' + field);
        }
      }
      // Escapar valor
      String safeValue = String.escapeSingleQuotes(strFielValidation);
      String stringQuery = 'SELECT id, toLabel(Industry), lei_id__c, CIF_local__c,' + fieldType + 'Name, ' + country + 'OwnerId, Owner.Name, ' + nonClientCS.Additional_field_duplicate_validation__c + (String.isBlank(nonClientCS.Information_fields__c) ? '' : ', ' + nonClientCS.Information_fields__c) + 
                           ' FROM Account WHERE ' + nonClientCS.Additional_field_duplicate_validation__c + ' = \'' + safeValue + '\'';
      List<sObject> lstAccount = (List<sObject>)Database.query(stringQuery);
      for (Integer i = 0; i < lstAccount.size(); i++){
        lWrapper.add(new WrapperAccount(String.valueof(lstAccount[i].get('id')) + '//%//' + String.valueof(lstAccount[i].get('OwnerId')) + '//%//' + String.valueof(lstAccount[i].get('Name')) + '//%//' + ((Account) lstAccount[i]).Owner.Name, nonClientCS.Type_field__c == null || nonClientCS.Type_field__c == '' ? '' : String.valueof(lstAccount[i].get(nonClientCS.Type_field__c)), nonClientCS.Country_field__c == null || nonClientCS.Country_field__c == '' ? '' : String.valueof(lstAccount[i].get(nonClientCS.Country_field__c)), nonClientCS.Information_fields__c == null || nonClientCS.Information_fields__c == '' ? '' : String.valueof(lstAccount[i].get(nonClientCS.Information_fields__c)), String.ValueOf(lstAccount[i].get(nonClientCS.Additional_field_duplicate_validation__c)), String.valueOf(lstAccount[i].get('Industry')), String.valueOf(lstAccount[i].get('lei_id__c')), String.valueOf(lstAccount[i].get('CIF_local__c'))));
      }
    }
    return lWrapper;
  }

  /**********************************************************************************************************
   * @name            getAllNamesSOSL
   * @author          bbva.com developers
   * @created         2019
   * @description     Check if exists any account with duplicate value in the field of custom setting using SOSL.
   * @param           String searchName
   * @param           String strFielValidation
   * @param           Prospect_validation__c nonClientCS
   * @param           String isOnDesktop
   * @return          String - Wrapper with duplicate Non Clients.
   **********************************************************************************************************/
  @AuraEnabled
  global static String getAllNamesSOSL(String searchName, String strFielValidation, Prospect_validation__c nonClientCS, String isOnDesktop){
    return getAllNamesSOSL(searchName, strFielValidation, nonClientCS, isOnDesktop, '');
  }

  /**********************************************************************************************************
   * @name            getAllNamesSOSL
   * @author          Global Desktop
   * @created         2019
   * @description     Check if exists any account with duplicate value in the field of custom setting using SOSL.
   * @param           String searchName
   * @param           String strFielValidation
   * @param           Prospect_validation__c nonClientCS
   * @param           String isOnDesktop
   * @param           String fields
   * @return          String - Wrapper with duplicate Non Clients.
   **********************************************************************************************************/
  @AuraEnabled@SuppressWarnings('PMD.ExcessiveParameterList')
  global static String getAllNamesSOSL(String searchName, String strFielValidation, Prospect_validation__c nonClientCS, String isOnDesktop, String fields){
    nonClientCS = Prospect_validation__c.getInstance();

    try{
      Set<String> sAccId = new Set<String>();
      List<WrapperAccount> lWrapper = new List<WrapperAccount>();
      String name = searchName != null ? searchName.replace('.', '').replace('-', ' ').toLowerCase() : '';
      String searchTerms = '';

      // Validar campo de búsqueda para duplicados
      if (strFielValidation != null && strFielValidation.length() > 0){
        lWrapper = NONC_New_NonClient_ctlr.validateDuplicateCode(strFielValidation, nonClientCS);
        if (lWrapper.size() > 0){
          return JSON.serialize(lWrapper);
        }
      }

      // Construir términos de búsqueda seguros (escapando entrada de usuario)
      for (String search : name.split(' ')){
        if (!String.isEmpty(search)){
          String safeToken = escapeForSoslSingleQuotedTerm(search);
          if (!String.isEmpty(safeToken)){
            if (!String.isEmpty(searchTerms)){
              searchTerms += ' OR ';
            }
            searchTerms += safeToken;
          }
        }
      }

      searchTerms = '\'' + searchTerms + '\'';

      // Validar campos a devolver en la SOSL
      String fieldsRet = getQueryFields(nonClientCS, isOnDesktop);
      Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
      for (String field : fieldsRet.replace('Account(', '').replace(')', '').split(',')){
        String trimmed = field.trim();
        if (trimmed != '' && !trimmed.startsWith('Owner.') && !trimmed.startsWith('toLabel(') && !trimmed.equalsIgnoreCase('Id')){
          if (!accountFields.containsKey(trimmed)){
            throw new AuraHandledException('Campo no válido en la consulta: ' + trimmed);
          }
        }
      }

      List<List<SObject>> searchList = new List<List<SObject>>();
      String searchquery = 'FIND ' + searchTerms + ' IN NAME FIELDS RETURNING ' + fieldsRet;
      searchList = search.query(searchquery);

      if (fields != ''){
        lWrapper.addAll(getSimilarAccountFieldsPercentage(fields, nonClientCS));
      }
      return JSON.serialize(lWrapper);
    } catch (Exception exc){
      System.debug('Exception : ' + exc);
      throw new AuraHandledException(Label.Error + exc);
    }
  }

  private static String nameToQuery(String name){
    String searchTerms = '';
    for (String search : name.split(' ')){
      if (!String.isEmpty(search)){
        String safeToken = escapeForSoslSingleQuotedTerm(search);
        if (!String.isEmpty(safeToken)){
          if (!String.isEmpty(searchTerms)){
            searchTerms += ' OR ';
          }
          searchTerms += '(\'' + safeToken + '\')';
        }
      }
    }
    return searchTerms;
  }

  private static String getQueryFields(Prospect_validation__c nonClientCS, String isOnDesktop){
    String fieldsRet = '';
    String countryField = '';
    String typeField = '';
    String informationField = '';
    Boolean desktop = isOnDesktop == 'DESKTOP' ? true : false;
    if (nonClientCS.Country_field__c != null && nonClientCS.Country_field__c.trim().length() > 0){
      if(Schema.DisplayType.PICKLIST == Schema.SObjectType.Account.fields.getMap().get(nonClientCS.Country_field__c).getDescribe().getType()){
        countryField = 'toLabel(' + nonClientCS.Country_field__c + '), ';
      }else {
        countryField = nonClientCS.Country_field__c + ', ';
      }
    }
    if (nonClientCS.Type_field__c != null && nonClientCS.Type_field__c.trim().length() > 0){
      typeField = nonClientCS.Type_field__c + ', ';
    }
    if (nonClientCS.Information_fields__c != null && nonClientCS.Information_fields__c.trim().length() > 0){
      informationField = nonClientCS.Information_fields__c + ', ';
    }
    fieldsRet = 'Account(id, Name, toLabel(Industry), lei_id__c, CIF_local__c, ' + typeField + ' OwnerId, ' + countryField + informationField + ' Owner.Alias, Owner.Name ' + (sObjectType.Account.fields.Name.isEncrypted() ? ') ' : ' ORDER BY Name) ') + (desktop ? 'LIMIT 2000' : 'LIMIT 5');
    return fieldsRet;
  }

  /**********************************************************************************************************
   * @name            getSimilarAccountName
   * @author          bbva.com developers
   * @created         2019
   * @description     Checks if exist a duplicate non client (only if duplicate check from custom setting is unchecked).
   * @param           String searchName
   * @param           String strFielValidation
   * @return          String - Wrapper with duplicate non clients.
   **********************************************************************************************************/
  @AuraEnabled
  global static String getSimilarAccountName(String searchName, String strFielValidation){
    try{
      String resultNames = '';
      // Validar campo opcional
      if (!String.isBlank(strFielValidation)){
        Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
        if (!accountFields.containsKey(strFielValidation)){
          throw new AuraHandledException('Campo no válido para Account');
        }
      }
      // Validar texto a buscar
      if (String.isBlank(searchName) || searchName.trim().length() <= 1){
        return resultNames;
      }
      // Escapar el término de búsqueda para SOSL
      String searchTerm = '*' + String.escapeSingleQuotes(searchName.trim()) + '*';
      List<List<SObject>> searchList = [FIND : searchTerm IN NAME FIELDS RETURNING Account(Name, Type, OwnerId, Owner.Name LIMIT 2000)];
      // Procesar resultados
      if (searchList != null){
        for (List<SObject> groupResults : searchList){
          for (SObject rec : groupResults){
            resultNames += String.valueOf(rec.get('Name')) + '<br/>';
          }
        }
      }
      return resultNames;
    } catch (Exception exc){
      System.debug('Exception : ' + exc);
      throw new AuraHandledException(Label.Error + exc);
    }
  }

  /**********************************************************************************************************
   * @name            getFieldLabel
   * @author          Global Desktop
   * @created         2019
   * @description     Get the label of a field from its API Name.
   * @param           String fieldAPIName
   * @return          String - The label of the field.
   **********************************************************************************************************/
  public static String getFieldLabel(String fieldAPIName){
    String type = 'Account';
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.SObjectType leadSchema = schemaMap.get(type);
    Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
    return fieldMap.get(fieldAPIName).getDescribe().getLabel();
  }

  /**********************************************************************************************************
   * @name            ONB_getAllNamesSOSL
   * @author          bbva.com developers
   * @created         2019
   * @description     Get all names for onboarding process using SOQL.
   * @param           String searchName
   * @param           String searchLEI
   * @param           String isOnDesktop
   * @return          String - Wrapper with duplicate Non Clients.
   **********************************************************************************************************/
  @AuraEnabled@SuppressWarnings('PMD.ExcessiveParameterList')
  global static String ONB_getAllNamesSOSL(String searchName, String searchLEI, String isOnDesktop){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    try{
      List<ONB_WrapperAccount> wrpAcc = new List<ONB_WrapperAccount>();
      List<Account> accountList = new List<Account>();
      String name = String.isBlank(searchName) ? '' : String.escapeSingleQuotes(searchName.trim());
      String lei = String.isBlank(searchLEI) ? '' : String.escapeSingleQuotes(searchLEI.trim());
      String searchTerms = '';
      Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
      if (!accountFields.containsKey('Name') || !accountFields.containsKey('lei_id__c')){
        throw new AuraHandledException('Campos requeridos no existen en Account');
      }
      if (name != '' && lei != ''){
        searchTerms = ' WHERE Name = \'' + name + '\' AND lei_id__c = \'' + lei + '\'';
      } else if (name == ''){
        searchTerms = ' WHERE lei_id__c = \'' + lei + '\'';
      } else{
        searchTerms = ' WHERE Name = \'' + name + '\'';
      }
      String queryToExc = 'SELECT Id, Name, lei_id__c, DES_Client_Type__c FROM Account ' + searchTerms;
      accountList = (List<Account>)Database.query(queryToExc);
      for (Account acc : accountList){
        wrpAcc.add(new ONB_WrapperAccount(acc.Id, acc.Name, acc.lei_id__c, acc.DES_Client_Type__c));
      }
      return JSON.serialize(wrpAcc);
    } catch (Exception exc){
      System.debug('Exception : ' + exc);
      throw new AuraHandledException(Label.Error + exc);
    }
  }

  /**********************************************************************************************************
   * @name            ONB_createNewOnboarding
   * @author          bbva.com developers
   * @created         2019
   * @description     Create new onboarding record.
   * @param           String searchName
   * @param           String searchLEI
   * @param           String isOnDesktop
   * @return          String - Wrapper with duplicate Non Clients.
   **********************************************************************************************************/
  @AuraEnabled@SuppressWarnings('PMD.ExcessiveParameterList')
  global static String ONB_createNewOnboarding(String searchName, String searchLEI, String isOnDesktop){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    try{
      List<ONB_WrapperAccount> wrpAcc = new List<ONB_WrapperAccount>();
      List<Account> accountList = new List<Account>();
      String name = String.isBlank(searchName) ? '' : String.escapeSingleQuotes(searchName.trim());
      String lei = String.isBlank(searchLEI) ? '' : String.escapeSingleQuotes(searchLEI.trim());
      String searchTerms = '';
      Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
      if (!accountFields.containsKey('Name') || !accountFields.containsKey('lei_id__c')){
        throw new AuraHandledException('Campos requeridos no existen en Account');
      }
      if (name != '' && lei != ''){
        searchTerms = ' WHERE Name = \'' + name + '\' AND lei_id__c = \'' + lei + '\'';
      } else if (name == ''){
        searchTerms = ' WHERE lei_id__c = \'' + lei + '\'';
      } else{
        searchTerms = ' WHERE Name = \'' + name + '\'';
      }
      String queryToExc = 'SELECT Id, Name, lei_id__c, DES_Client_Type__c FROM Account ' + searchTerms;
      accountList = (List<Account>)Database.query(queryToExc);
      for (Account acc : accountList){
        wrpAcc.add(new ONB_WrapperAccount(acc.Id, acc.Name, acc.lei_id__c, acc.DES_Client_Type__c));
      }
      return JSON.serialize(wrpAcc);
    } catch (Exception exc){
      System.debug('Exception : ' + exc);
      throw new AuraHandledException(Label.Error + exc);
    }
  }

  /**********************************************************************************************************
   * @name            ONB_WrapperAccount
   * @author          Global Desktop
   * @created         2019
   * @description     Wrapper for onboarding account info.
   **********************************************************************************************************/
  public class ONB_WrapperAccount{
    private String clientName;
    private String clientLink;
    private String LEI;
    private String clientType;

    public ONB_WrapperAccount(){
      System.debug('Empty constructor');
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public ONB_WrapperAccount(String clientId, String clientName, String LEI, String clientType){
      this.clientLink = '/lightning/r/Account/' + clientId + '/view';
      this.clientName = clientName;
      this.LEI = LEI;
      this.clientType = clientType;
    }

  }

  /**********************************************************************************************************
   * @name            WrapperField
   * @author          Global Desktop
   * @created         2019
   * @description     Wrapper with the label and the API Name of the additional field.
   **********************************************************************************************************/
 public class WrapperField{
    private String strField;
    private String strLabel;

    public WrapperField(){
      System.debug('Empty constructor');
    }

    public WrapperField(String strField, String strLabel){
      this.strField = strField;
      this.strLabel = strLabel;
    }

  }

  /**********************************************************************************************************
   * @name            WrapperAccount
   * @author          Global Desktop
   * @created         2019
   * @description     Wrapper with the duplicate accounts.
   **********************************************************************************************************/
  public class WrapperAccount{
    private String ownerName;
    private String ownerLink;
    private String clientName;
    private String clientLink;
    private String clientType;
    private String country;
    private User owner;
    private String code;
    private String information;
    private String Industry;
    private String lei;
    private String cif;

    public WrapperAccount(){
      System.debug('Empty constructor');
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public WrapperAccount(String clientOwnerIDName, String clientType, String country, String information, String code, String industry, String lei, String cif){
      this.clientLink = '/lightning/r/Account/' + clientOwnerIDName.split('//%//').get(0) + '/view';
      this.ownerLink = '/lightning/r/User/' + clientOwnerIDName.split('//%//').get(1) + '/view';
      this.clientName = clientOwnerIDName.split('//%//').get(2);
      this.ownerName = clientOwnerIDName.split('//%//').get(3);
      this.clientType = clientType;
      this.country = country;
      this.code = code;
      this.information = information;
      this.Industry = industry;
      this.lei = lei;
      this.cif = cif;
    }

  }

  /**********************************************************************************************************
   * @name            getSimilarAccountFieldsPercentage
   * @author          bbva.com developers
   * @created         2019
   * @description     Get similar accounts by fields percentage.
   * @param           String fields
   * @param           Prospect_validation__c nonClientCS
   * @return          List<WrapperAccount>
   **********************************************************************************************************/
  private static List<WrapperAccount> getSimilarAccountFieldsPercentage(String fields, Prospect_validation__c nonClientCS){
    List<WrapperAccount> lWrapper = new List<WrapperAccount>();
    String uniqueId = nonClientCS.Unique_Id_field_name__c;
    String fieldsQuery = hasFieldsToQuery(nonClientCS);
    Map<String, String> jsondeserialize = (Map<String, String>)JSON.deserialize(fields, Map<String, String>.class);
    // Validar que los campos existen en Account
    Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
    for (String key : jsondeserialize.keySet()){
      if (!accountFields.containsKey(key)){
        throw new AuraHandledException('Campo no válido: ' + key);
      }
    }
    for (String field : fieldsQuery.split(',')){
      String trimmed = field.trim();
      String fieldToValidate = trimmed;
      if (trimmed.startsWithIgnoreCase('toLabel(')) {
          fieldToValidate = trimmed.substringBetween('toLabel(', ')').trim();
      }
      if (!String.isBlank(fieldToValidate) && !accountFields.containsKey(fieldToValidate)){
        throw new AuraHandledException('Campo no válido en la consulta: ' + fieldToValidate);
      }
    }
    if (!String.isBlank(uniqueId) && !accountFields.containsKey(uniqueId)){
      throw new AuraHandledException('Campo identificador no válido: ' + uniqueId);
    }
    List<Account> acc = new List<Account>();
    if (fields.indexOf(uniqueId) != -1 && jsondeserialize.get(uniqueId) != null && jsondeserialize.get(uniqueId) != ''){
      String searchNif = String.escapeSingleQuotes(jsondeserialize.get(uniqueId));
      String searchTerms = '\'' + searchNif + '\'';
      String queryToExc = 'SELECT id, Owner.id, Owner.Name, ' + fieldsQuery + 
                         ' FROM Account WHERE ' + uniqueId + '=' + searchTerms;
      acc = (List<Account>)Database.query(queryToExc);
      lWrapper = getWrapperAccountsPercentage(acc, nonClientCS);
    }
    Integer size = acc.size();
    if (size == 0){
      String fieldsToFind = fieldsToFind(jsondeserialize);
      String searchName = jsondeserialize.get('Name');
      Integer filterMaxNumber = (nonClientCS.DUP_Filter_Query_Max__c != null) ? nonClientCS.DUP_Filter_Query_Max__c.intValue() : 0;
      String queryToExc = 'FIND {' + fieldsToFind + '} IN ALL FIELDS RETURNING Account(Id,OwnerId,Owner.Name,' + fieldsQuery + (sObjectType.Account.fields.Name.isEncrypted() ? ')' : ' ORDER BY Name) LIMIT ' + validateDUPFilterQueryMax(filterMaxNumber));
      List<List<SObject>> searchList = (List<List<SObject>>)search.query(queryToExc);
      if (searchName != null && searchName.length() > 1){
        lWrapper = createWrapperList(searchList, jsondeserialize, nonClientCS);
      }
    }
    return lWrapper;
  }

  /**********************************************************************************************************
   * @name            fieldsToFind
   * @author          Global Desktop
   * @created         2019
   * @description     Build search string for SOSL.
   * @param           Map<String, String> jsondeserialize
   * @return          String
   **********************************************************************************************************/
  private static String fieldsToFind(Map<String, String> jsondeserialize){
    String fieldsToFind = '';
    Integer loopCounter = 1;
    Boolean firstAddressFiled = true;
    for (String fieldName : jsondeserialize.keySet()){
      String rawValue = jsondeserialize.get(fieldName);
      String safeValue = escapeForSoslDoubleQuotedTerm(rawValue);

      Boolean fieldsAddressType = (fieldName.contains('Billing') || fieldName.contains('Shipping')) ? true : false;
      if (fieldsAddressType){
        if (firstAddressFiled){
          fieldsToFind += '(\"' + safeValue + '\" and ';
          firstAddressFiled = false;
        } else if (!firstAddressFiled){
          if (jsondeserialize.keySet().size() != loopCounter){
            fieldsToFind += '\"' + safeValue + '\" and ';
          } else{
            fieldsToFind += '\"' + safeValue + '\")';
          }
        }
      } else{
        if (jsondeserialize.keySet().size() != loopCounter){
          fieldsToFind += '\"' + safeValue + '\" or ';
        } else{
          fieldsToFind += '\"' + safeValue + '\"';
        }
      }
      loopCounter++;
    }
    return fieldsToFind;
  }

  /**********************************************************************************************************
   * @name            validateDUPFilterQueryMax
   * @author          Global Desktop
   * @created         2019
   * @description     Validate max number for DUP filter query.
   * @param           Integer dupFilterQueryMax
   * @return          Integer
   **********************************************************************************************************/
  private static Integer validateDUPFilterQueryMax(Integer dupFilterQueryMax){
    Integer maxNumber = 1000;
    if (dupFilterQueryMax > 0 && dupFilterQueryMax <= 2000){
      maxNumber = dupFilterQueryMax;
    } else if (dupFilterQueryMax > 2000){
      maxNumber = 2000;
    }

    return maxNumber;
  }

  /**********************************************************************************************************
   * @name            getWrapperAccountsPercentage
   * @author          Global Desktop
   * @created         2019
   * @description     Get wrapper accounts by percentage.
   * @param           List<Account> acc
   * @param           Prospect_validation__c nonClientCS
   * @return          List<WrapperAccount>
   **********************************************************************************************************/
  private static List<WrapperAccount> getWrapperAccountsPercentage(List<Account> acc, Prospect_validation__c nonClientCS){
    List<WrapperAccount> lWrapper = new List<WrapperAccount>();

    if (acc != null){
      for (SObject objToCompare : acc){
        lWrapper.add(new WrapperAccount(String.valueof(objToCompare.get('Id')) + '//%//' + String.valueof(objToCompare.get('OwnerId')) + '//%//' + String.valueof(objToCompare.get('Name')) + '//%//' + ((Account) objToCompare).Owner.Name, nonClientCS.Type_field__c == null || nonClientCS.Type_field__c == '' ? '' : String.valueof(objToCompare.get(nonClientCS.Type_field__c)), nonClientCS.Country_field__c == null || nonClientCS.Country_field__c == '' ? '' : String.valueof(objToCompare.get(nonClientCS.Country_field__c)), nonClientCS.Information_fields__c == null || nonClientCS.Information_fields__c == '' ? '' : String.valueof(objToCompare.get(nonClientCS.Information_fields__c)), '', String.valueOf(objToCompare.get('Industry')), String.valueOf(objToCompare.get('lei_id__c')), String.valueOf(objToCompare.get('CIF_local__c'))));
      }
    }

    return lWrapper;
  }

  /**********************************************************************************************************
   * @name            createWrapperList
   * @author          Global Desktop
   * @created         2019
   * @description     Create wrapper list from search results.
   * @param           List<List<SObject>> searchList
   * @param           Map<String,String> jsondeserialize
   * @param           Prospect_validation__c nonClientCS
   * @return          List<WrapperAccount>
   **********************************************************************************************************/
  private static List<WrapperAccount> createWrapperList(List<List<SObject>> searchList, Map<String, String> jsondeserialize, Prospect_validation__c nonClientCS){
    List<WrapperAccount> lWrapper = new List<WrapperAccount>();

    double percentage = nonClientCS.Percent_to_match__c;
    Integer minFieldsToBlock = Integer.valueOf(nonClientCS.Min_Fields_to_block__c);
    for (List<SObject> compareList : searchList){
      for (SObject objToCompare : compareList){
        Integer matchingFields = 0;
        for (String key : jsondeserialize.keyset()){
          Map<String, Schema.SObjectField> m;
          m = Schema.SObjectType.Account.fields.getMap();

          Schema.SObjectField field = m.get(key);
          Schema.DisplayType fldType = field.getDescribe().getType();

          if (hasSObjectField(key, objToCompare) && objToCompare.get(key) != null && jsondeserialize.get(key) != null){
            matchingFields = compareByType(String.valueOf(objToCompare.get(key)), jsondeserialize.get(key), String.valueOf(fldType), percentage, matchingFields);
          }
          if (matchingFields >= minFieldsToBlock){
            lWrapper.add(new WrapperAccount(String.valueof(objToCompare.get('Id')) + '//%//' + String.valueof(objToCompare.get('OwnerId')) + '//%//' + String.valueof(objToCompare.get('Name')) + '//%//' + ((Account) objToCompare).Owner.Name, nonClientCS.Type_field__c == null || nonClientCS.Type_field__c == '' ? '' : String.valueof(objToCompare.get(nonClientCS.Type_field__c)), nonClientCS.Country_field__c == null || nonClientCS.Country_field__c == '' ? '' : String.valueof(objToCompare.get(nonClientCS.Country_field__c)), nonClientCS.Information_fields__c == null || nonClientCS.Information_fields__c == '' ? '' : String.valueof(objToCompare.get(nonClientCS.Information_fields__c)), '', String.valueOf(objToCompare.get('Industry')), String.valueOf(objToCompare.get('lei_id__c')), String.valueOf(objToCompare.get('CIF_local__c'))));
            break;
          }
        }
      }
    }
    return lWrapper;
  }

  /**********************************************************************************************************
   * @name            hasFieldsToQuery
   * @author          Global Desktop
   * @created         2019
   * @description     Get fields to query from fieldset and custom setting.
   * @param           Prospect_validation__c nonClientCS
   * @return          String
   **********************************************************************************************************/
  public static String hasFieldsToQuery(Prospect_validation__c nonClientCS){

    Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
    Schema.SObjectType sObjectTypeObj = globalDescribeMap.get('Account');

    Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();

    Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get('NONC_DuplicateSearchFieldSet');

    List<Schema.FieldSetMember> fieldSetMemberList = fieldSetObj.getFields();

    String[] tmp1 = New String[]{  };

    for (Schema.FieldSetMember c : fieldSetMemberList){
      tmp1.add(c.getFieldPath());
    }

    if (nonClientCS.Type_field__c != null && nonClientCS.Type_field__c != ''){
      tmp1.add(nonClientCS.Type_field__c);
    }
    if (nonClientCS.Country_field__c != null && nonClientCS.Country_field__c != ''){
      if(Schema.DisplayType.PICKLIST == Schema.SObjectType.Account.fields.getMap().get(nonClientCS.Country_field__c).getDescribe().getType()){
        tmp1.add('toLabel(' + nonClientCS.Country_field__c + ')');
      }else {
        tmp1.add(nonClientCS.Country_field__c);
      }
    }
    if (nonClientCS.Information_fields__c != null && nonClientCS.Information_fields__c != ''){
      tmp1.add(nonClientCS.Information_fields__c);
    }
    tmp1.add('toLabel(Industry)');
    tmp1.add('lei_id__c');
    tmp1.add('CIF_local__c');

    return string.join(tmp1, ',');
  }

  /**********************************************************************************************************
   * @name            hasSObjectField
   * @author          Global Desktop
   * @created         2019
   * @description     Check if SObject has a field.
   * @param           String fieldName
   * @param           SObject so
   * @return          Boolean
   **********************************************************************************************************/
  public static boolean hasSObjectField(String fieldName, SObject so){
    return so.getSobjectType().getDescribe().fields.getMap().keySet().contains(fieldName.toLowerCase());//NOSONAR
  }

  @SuppressWarnings('PMD.ExcessiveParameterList')
  public static Integer compareByType(String str1, String str2, String type, Double percentage, Integer matchingFields){
    //NOSONAR
    /*
     switch on type {
     when 'STRING' {
     if(NONC_MatchMaker.coincidentString(str1,str2,percentage)){
     matchingFields = matchingFields + 1;//NOSONAR
     }
     }
     when 'PHONE' {
     str1 = str1.replaceAll('[^a-zA-Z0-9\\s+]', '');//NOSONAR
     str2 = str2.replaceAll('[^a-zA-Z0-9\\s+]', '');//NOSONAR
     if(NONC_MatchMaker.coincidentNumber(Long.valueOf(str1),Long.valueOf(str2))){
     matchingFields = matchingFields + 1;//NOSONAR
     }
     }
     when 'URL' {
     if(NONC_MatchMaker.coincidentString(str1,str2,percentage)){
     matchingFields = matchingFields + 1;//NOSONAR
     }
     }
     when 'TEXTAREA' {
     if(NONC_MatchMaker.coincidentString(str1,str2,percentage)){
     matchingFields = matchingFields + 1;//NOSONAR
     }
     }
     when 'INTEGER' {
     if(NONC_MatchMaker.coincidentNumber(Long.valueOf(str1),Long.valueOf(str2))){
     matchingFields = matchingFields + 1;//NOSONAR
     }
     }
     }*/

    return matchingFields;
  }

  /**********************************************************************************************************
   * @name            isDisabledtrue
   * @author          Global Desktop
   * @created         2019
   * @description     Check if the process is disabled.
   * @return          Boolean
   **********************************************************************************************************/
  @AuraEnabled
  public static Boolean isDisabledtrue(){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    Boolean isdisabled = nonClientCS.isDisable__c;
    return isdisabled;
  }

  /**********************************************************************************************************
   * @name            disableforce
   * @author          bbva.com developers
   * @created         2019
   * @description     Check if force disable is required.
   * @param           String fields
   * @return          Boolean
   **********************************************************************************************************/
  @AuraEnabled
  public static Boolean disableforce(String fields){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    String uniqueId = nonClientCS.Unique_Id_field_name__c;
    Boolean forceDisable = false;
    Map<String, String> jsondeserialize = (Map<String, String>)JSON.deserialize(fields, Map<String, String>.class);
    // Validar que el campo identificador existe en Account
    Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
    if (!String.isBlank(uniqueId) && !accountFields.containsKey(uniqueId)){
      throw new AuraHandledException('Campo identificador no válido: ' + uniqueId);
    }
    List<Account> acc = new List<Account>();
    if (fields.indexOf(uniqueId) != -1 && jsondeserialize.get(uniqueId) != null && jsondeserialize.get(uniqueId) != ''){
      String searchNif = String.escapeSingleQuotes(jsondeserialize.get(uniqueId));
      String searchTerms = '\'' + searchNif + '\'';
      String queryToExc = 'SELECT id FROM Account WHERE ' + uniqueId + '=' + searchTerms;
      acc = (List<Account>)Database.query(queryToExc);
      Integer size = acc.size();
      forceDisable = (size > 0);
    }
    return forceDisable;
  }

  /**********************************************************************************************************
   * @name            ResultValidation
   * @author          Global Desktop
   * @created         2019
   * @description     Wrapper for validation result.
   **********************************************************************************************************/
  public class ResultValidation{
    @AuraEnabled
    public String status{ get; set; }

    @AuraEnabled
    public String message{ get; set; }

  }

  private static String escapeForSoslSingleQuotedTerm(String value){
    if (String.isBlank(value)){
      return '';
    }
    String safe = value.trim();
    safe = safe.replace('\\', '\\\\');
    safe = String.escapeSingleQuotes(safe);
    safe = safe.replace('{', '\\{').replace('}', '\\}');
    return safe;
  }

  private static String escapeForSoslDoubleQuotedTerm(String value){
    if (String.isBlank(value)){
      return '';
    }
    String safe = value.trim();
    safe = safe.replace('\\', '\\\\');
    safe = safe.replace('"', '\\"');
    safe = safe.replace('{', '\\{').replace('}', '\\}');
    safe = safe.replace('&', '\\&');
    return safe;
  }


}