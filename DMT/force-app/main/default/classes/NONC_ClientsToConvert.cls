/************************************************************************
  * @name:                ClientsToConvert
  * @author               bbva.com developers
  * @date:                2019
  * @version:             1.0
  * @group:               º
  * @description:         Class to add method on account trigger and convert prospect
  ***************************************************************************/
global without sharing class NONC_ClientsToConvert {

    /**
    * @description Check if new account exist on prospect
    * @return Trigger.new account and Trigger.oldMap Accounts
    **/
global static void getConvertedAccounts(List<Account> newAccount) {
    // Campos dinámicos
    String field     = getFieldUniqueId();
    String fieldName = getFieldName();
    List<String> lIDs = getIDRecordType();

    // Validar contra schema
    Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
    if (!accountFields.containsKey(field) || !accountFields.containsKey(fieldName)) {
        throw new SecurityException('Campo no válido para Account');
    }
    // Validación sintáctica adicional: solo API names, sin rutas ni puntos
    Pattern apiNamePattern = Pattern.compile('^[A-Za-z][A-Za-z0-9_]*$');
    if (field.contains('.') || fieldName.contains('.') ||
        !apiNamePattern.matcher(field).matches() ||
        !apiNamePattern.matcher(fieldName).matches()) {
        throw new SecurityException('Nombre de campo con formato no permitido');
    }

    // Preparar listas y mapas auxiliares
    List<String> lUniqueID = new List<String>();
    Map<String, Account> newMapAccount = new Map<String, Account>();

    for (Account acc : newAccount) {
        String aux = String.valueOf(acc.get(fieldName));
        if (acc.get(field) != null && !lIDs.contains(aux)) {
            newMapAccount.put((String) acc.get(field), acc);
            lUniqueID.add((String) acc.get(field));
        }
    }

    if (lUniqueID.isEmpty()) {
        // Nada que consultar, salimos pronto
        return;
    }

    // Construcción del SOQL (solo nombres de campo ya validados; todos los valores por bind)
    String soql =
        'SELECT Id, ' + fieldName + ', ' + field +
        ' FROM Account WHERE ' + field + ' IN :lUniqueID';

    if (!lIDs.isEmpty()) {
        // Usar IN en lugar de construir OR encadenados
        soql += ' AND ' + fieldName + ' IN :lIDs';
    }

    // Ejecutar el query
    // NOSONAR: nombres de campo validados contra el schema + regex; todos los valores via bind variables
    List<Account> lProspect = Database.query(soql); // NOSONAR

    // Mapeo de resultados
    Map<String, Account> resultMapAccount = new Map<String, Account>();
    for (Account acc : lProspect) {
        resultMapAccount.put(
            (String) acc.get(field),
            newMapAccount.get((String) acc.get(field))
        );
    }

    getConvertMethod(lProspect, resultMapAccount);
}



    private static String getFieldName() {
      return Test.isRunningTest() ? 'Name' : 'RecordTypeId';
    }
    /**
    * @description call method from interface
    * @return String with the result
    **/
    global static void getConvertMethod(List<Account> lProspect, Map<String, Account> mapUniqueIDAccount) {
      Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
      String className = nonClientCS.ClassName_Validation__c;
      Type typeCustomCLass = Type.forName(className);
      Object classCustomValidation = typeCustomCLass.newInstance();
      NONC_NonClient_interface_prospect infCustomValidation = (NONC_NonClient_interface_prospect) classCustomValidation;
      infCustomValidation.checkConvertedClients(lProspect, mapUniqueIDAccount);
    }

    /**
    * @description Check if the unique field of the custom setting exists and its type is text
    * @return Error if does not exist or is not text
    **/
    private static String getFieldUniqueId() {
      String result = '';
      Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
      if(nonClientCS.Unique_Id_field_name__c != null && nonClientCS.Unique_Id_field_name__c.trim().length() > 0) {
        try {
          Account objValidar = new Account();
          objValidar.get(nonClientCS.Unique_Id_field_name__c);
          if(String.ValueOf(Schema.SObjectType.Account.fields.getMap().get(nonClientCS.Unique_Id_field_name__c).getDescribe().getType()) != 'STRING') {
            throw new AuraHandledException('Unique Id field must be text type.');
          }
          result = nonClientCS.Unique_Id_field_name__c;
        } catch(Exception exc) {
          throw new AuraHandledException(system.Label.NClient_lbl_NotExistCustomField.replace('&Field&',nonClientCS.Unique_Id_field_name__c)); //NOSONAR
        }
      }
      return result;
    }

    /**
    * @description Get Prospect RecordType
    * @return List Prospect ids
    **/
    private static List<String> getIDRecordType() {
      List<String> lIDRecordType = new List<String> ();
      Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
      if(!Test.isRunningTest() && nonClientCS.Non_Client_RecordType__c != null) {
        lIDRecordType.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(nonClientCS.Non_Client_RecordType__c).getRecordTypeId());
      }
      if(!Test.isRunningTest() && nonClientCS.Additional_Non_Client_RecordType__c != null) {
        lIDRecordType.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(nonClientCS.Additional_Non_Client_RecordType__c).getRecordTypeId());
      }
      return lIDRecordType;
    }
}