public with sharing class GBL_DataTableMH_SrvrCtrl {
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //INNER CLASS
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  class ClsDataRecord {
    public Map<String, String> recordFields = new Map<String, String>();
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //PUBLIC AURA FUNCTIONS
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  @AuraEnabled
  public static String getColumns(Boolean useStandard) {
    String result;
    List<GBL_DataTableMH__mdt> lmdt = [
      SELECT
        Label,
        NamespacePrefix,
        FieldName__c,
        FieldType__c,
        Order__c,
        Active__c
      FROM GBL_DataTableMH__mdt
      WHERE
        Visible__c = TRUE
        AND Active__c = TRUE
        AND Standard_Field__c = :useStandard
      ORDER BY Order__c ASC
    ];
    result = generateJSONContent(lmdt);
    system.debug('getColumns(): ' + result);
    return result;
  }

  @AuraEnabled
  public static String fetchData(
    Boolean useStandard,
    String recordId,
    String vision,
    String[] types,
    String searchKey,
    String accountTypeField,
    Boolean returnTotal,
    String startFromRow
  ) {
    if (useStandard) {
      return getStandardData(
        recordId,
        types,
        searchKey,
        accountTypeField,
        returnTotal,
        startFromRow
      );
    } else {
      return getCustomData(
        recordId,
        vision,
        types,
        searchKey,
        returnTotal,
        startFromRow
      );
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //PRIVATE FUNCTIONS
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  @SuppressWarnings('sf:SOQLInjection')
  private static String getStandardData(
    String recordId,
    String[] types,
    String searchKey,
    String accountTypeField,
    Boolean returnTotal,
    String startFromRow
  ) {
    String result;
    Integer queryLimit = 30;

    if (returnTotal) {
      queryLimit = 2000;
    }

    String validatedAccountTypeField = null;
    if (String.isNotBlank(accountTypeField)) {
      Map<String, Schema.SObjectField> accountFieldsMap = Schema.SObjectType.Account.fields.getMap();
      if (accountFieldsMap.containsKey(accountTypeField.toLowerCase())) {
        validatedAccountTypeField = accountFieldsMap.get(accountTypeField.toLowerCase()).getDescribe().getName();
      }
    }

    Set<String> validatedFields = getValidatedMDTFields(true);

    String query = 'SELECT Id, Name, ParentId';
    
    for (String validatedField : validatedFields) {
      query += ', ' + validatedField;
    }
    
    if (validatedAccountTypeField != null) {
      query += ', ' + validatedAccountTypeField;
    }

    query += ' FROM Account WHERE ParentId = :recordId';

    if (validatedAccountTypeField != null && types != null && !types.isEmpty()) {
      query += ' AND ' + validatedAccountTypeField + ' IN :types';
    }

    query += ' LIMIT :queryLimit';


    List<Account> accounts = Database.query(query);

    // Filtrar por búsqueda EN MEMORIA (Name es campo cifrado)
    List<Account> filteredAccounts = new List<Account>();
    if (String.isNotBlank(searchKey)) {
      String lowerSearchKey = searchKey.toLowerCase();
      for (Account acc : accounts) {
        if (acc.Name != null && acc.Name.toLowerCase().contains(lowerSearchKey)) {
          filteredAccounts.add(acc);
        }
      }
    } else {
      filteredAccounts = accounts;
    }

    if (startFromRow != 'START' && !returnTotal && String.isNotBlank(startFromRow)) {
      List<Account> paginatedAccounts = new List<Account>();
      for (Account acc : filteredAccounts) {
        if (acc.Name != null && acc.Name > startFromRow) {
          paginatedAccounts.add(acc);
        }
      }
      filteredAccounts = paginatedAccounts;
    }

    if (!returnTotal) {
      filteredAccounts.sort();
    }

    if (returnTotal) {
      result = String.valueOf(filteredAccounts.size());
    } else {
      List<GBL_DataTableMH_SrvrCtrl.ClsDataRecord> dataRecords = new List<GBL_DataTableMH_SrvrCtrl.ClsDataRecord>();

      for (Account acc : filteredAccounts) {
        GBL_DataTableMH_SrvrCtrl.ClsDataRecord dataRecord = new GBL_DataTableMH_SrvrCtrl.ClsDataRecord();
        Map<String, Object> accountFields = acc.getPopulatedFieldsAsMap();

        dataRecord.recordFields.put('recordUrl', '/lightning/r/Account/' + acc.Id + '/view');
        dataRecord.recordFields.put('recordName', acc.Name);

        for (String fieldName : accountFields.keySet()) {
          dataRecord.recordFields.put(fieldName, String.valueOf(accountFields.get(fieldName)));
        }
        dataRecords.add(dataRecord);
      }

      result = generateJSONContent(dataRecords);
    }
    return result;
  }
  
  @SuppressWarnings('sf:SOQLInjection')
  private static String getCustomData(
    String recordId,
    String vision,
    String[] types,
    String searchKey,
    Boolean returnTotal,
    String startFromRow
  ) {
    String result;

    Set<String> validatedFields = getValidatedMDTFields(false);

    String query = 'SELECT Id, Name, AMH_ChildName__c, AMH_Child_Account__c, AMH_Child_Account__r.Name, AMH_Vision__c, AMH_Type__c';

    for (String validatedField : validatedFields) {
      query += ', ' + validatedField;
    }

    query += ' FROM AMH_GBL_Account_Relationship__c';
    query += ' WHERE AMH_Parent_Account__c = :recordId';
    query += ' AND AMH_Vision__c = :vision';

    if (types != null && !types.isEmpty()) {
      query += ' AND AMH_Type__c IN :types';
    }

    query += ' LIMIT 2000';


    List<AMH_GBL_Account_Relationship__c> accRelRecords = Database.query(query);

    if (!returnTotal) {
      accRelRecords.sort();
    }

    if (returnTotal) {
      result = String.valueOf(accRelRecords.size());
    } else {
      List<GBL_DataTableMH_SrvrCtrl.ClsDataRecord> dataRecords = new List<GBL_DataTableMH_SrvrCtrl.ClsDataRecord>();

      for (AMH_GBL_Account_Relationship__c accRel : accRelRecords) {
        if (accRel == null) {
          continue;
        }

        String nameValue = accRel.AMH_ChildName__c;
        if (String.isBlank(nameValue) && accRel.AMH_Child_Account__r != null) {
          nameValue = accRel.AMH_Child_Account__r.Name;
        }
        if (String.isBlank(nameValue)) {
          nameValue = 'N/A';
        }

        // Filtrar por búsqueda EN MEMORIA
        if (String.isNotBlank(searchKey) && !nameValue.toLowerCase().contains(searchKey.toLowerCase())) {
          continue;
        }

        GBL_DataTableMH_SrvrCtrl.ClsDataRecord dataRecord = new GBL_DataTableMH_SrvrCtrl.ClsDataRecord();
        Map<String, Object> accountFields = accRel.getPopulatedFieldsAsMap();

        dataRecord.recordFields.put('recordUrl', '/lightning/r/Account/' + accRel.AMH_Child_Account__c + '/view');
        dataRecord.recordFields.put('recordName', nameValue);
        dataRecord.recordFields.put('Name', nameValue);

        for (String fieldName : accountFields.keySet()) {
          dataRecord.recordFields.put(fieldName, String.valueOf(accountFields.get(fieldName)));
        }

        if (dataRecord.recordFields.get('recordName') != null) {
          dataRecords.add(dataRecord);
        }
      }

      result = generateJSONContent(dataRecords);
    }

    return result;
  }

  // SEGURIDAD: Validación centralizada de campos contra Schema
  private static Set<String> getValidatedMDTFields(Boolean useStandard) {
    Set<String> validatedFields = new Set<String>();
    
    List<GBL_DataTableMH__mdt> lmdt = [
      SELECT FieldName__c, Standard_Field__c
      FROM GBL_DataTableMH__mdt
      WHERE
        Visible__c = TRUE
        AND Active__c = TRUE
        AND Standard_Field__c = :useStandard
      ORDER BY Order__c ASC
    ];

    System.debug('getValidatedMDTFields(): ' + lmdt);

    // SEGURIDAD: Validar cada campo contra el schema del objeto correspondiente
    if (useStandard) {
      Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
      for (GBL_DataTableMH__mdt mdt : lmdt) {
        if (String.isNotBlank(mdt.FieldName__c) && accountFields.containsKey(mdt.FieldName__c.toLowerCase())) {
          // Usar el nombre exacto del campo del schema (esto NO es valor de usuario, es metadata del sistema)
          validatedFields.add(accountFields.get(mdt.FieldName__c.toLowerCase()).getDescribe().getName());
        }
      }
    } else {
      Map<String, Schema.SObjectField> relFields = Schema.SObjectType.AMH_GBL_Account_Relationship__c.fields.getMap();
      for (GBL_DataTableMH__mdt mdt : lmdt) {
        if (String.isNotBlank(mdt.FieldName__c) && relFields.containsKey(mdt.FieldName__c.toLowerCase())) {
          // Usar el nombre exacto del campo del schema (esto NO es valor de usuario, es metadata del sistema)
          validatedFields.add(relFields.get(mdt.FieldName__c.toLowerCase()).getDescribe().getName());
        }
      }
    }

    return validatedFields;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //JSON GENERATORS
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  private static String generateJSONContent(List<GBL_DataTableMH_SrvrCtrl.ClsDataRecord> dataRecords) {
    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartArray();

    for (GBL_DataTableMH_SrvrCtrl.ClsDataRecord dataRecord : dataRecords) {
      gen.writeObject(dataRecord.recordFields);
    }
    gen.writeEndArray();

    String pretty = gen.getAsString();
    return pretty;
  }

  private static String generateJSONContent(List<GBL_DataTableMH__mdt> lmdt) {
    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartArray();

    gen.writeStartObject();
    gen.writeObjectField('label', 'Name');
    gen.writeObjectField('fieldName', 'recordUrl');
    gen.writeObjectField('type', 'url');

    gen.writeFieldName('typeAttributes');
    gen.writeStartObject();
    gen.writeFieldName('label');
    gen.writeStartObject();
    gen.writeObjectField('fieldName', 'recordName');
    gen.writeEndObject();
    gen.writeEndObject();
    gen.writeEndObject();

    for (GBL_DataTableMH__mdt mdt : lmdt) {
      gen.writeStartObject();
      gen.writeObjectField('label', mdt.Label);
      gen.writeObjectField('fieldName', mdt.FieldName__c);
      gen.writeObjectField('type', mdt.FieldType__c);
      gen.writeEndObject();
    }
    gen.writeEndArray();

    String pretty = gen.getAsString();
    return pretty;
  }
}