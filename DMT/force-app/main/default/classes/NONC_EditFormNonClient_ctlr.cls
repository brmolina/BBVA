/**
* @author bbva.com developers
* @date 2019
*
* @group Global Desktop
*
* @description Controller class of the EditFormNonClient
**/
global without sharing class NONC_EditFormNonClient_ctlr {
  private static final String PROSPECT_SUBSIDIARY_PARENT_FIELD = 'DES_Main_Parent__c';
  private static final String PROSPECT_SUBSIDIARY_CUSTOMER_ID_FIELD = 'g_customer_id__c';

  /*
  * List of all accounts names
  */
  private static Map <id, String> sAllName;

  /**
  * @description Check if the field of custom setting exists in Account
  * @return A wrapper with the label and the API Name of the field of custom setting
  **/
  private static WrapperField getFieldValidation() {
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();

    if(nonClientCS.Additional_field_duplicate_validation__c != null && nonClientCS.Additional_field_duplicate_validation__c.trim().length() > 0) {
      try {
        Account objValidar = new Account();
        objValidar.get(nonClientCS.Additional_field_duplicate_validation__c);
        return new WrapperField(nonClientCS.Additional_field_duplicate_validation__c,NONC_EditFormNonClient_ctlr.getFieldLabel(nonClientCS.Additional_field_duplicate_validation__c),true);
      } catch(Exception exc) {
        return new WrapperField('','',false);
      }
    }
    return new WrapperField('','',false);
  }

  /**
  * @description Gets the label of a field
  * @return Label of a field
  **/
  private static String getFieldLabel(String fieldAPIName) {
    String type='Account';
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.SObjectType leadSchema = schemaMap.get(type);
    Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
    return fieldMap.get(fieldAPIName).getDescribe().getLabel();
  }

  /**
  * @description Searchs duplicate Non Clients
  * @return String with the result
  **/
  @AuraEnabled
  global static String validateNonClienteComponent(Account acc) {
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    Boolean bolCustomValidation = nonClientCS.Custom_validation_creation__c;
    String className = nonClientCS.ClassName_Validation__c;

    if(bolCustomValidation != null && bolCustomValidation) {
      Type typeCustomCLass = Type.forName(className);
      Object classCustomValidation = typeCustomCLass.newInstance();
      NONC_NonClient_interface_prospect infCustomValidation = (NONC_NonClient_interface_prospect) classCustomValidation;
      return infCustomValidation.validateNonCliente(acc);
    } else {
      return NONC_EditFormNonClient_ctlr.validateNonCliente(acc, nonClientCS);
    }
  }

  /**
  * @description Get Lookup field and
  * @return String with the result
  **/
  @AuraEnabled
  global static String getFieldLookup(String recordTypeID) {
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();

    String lookupField = '';
    String lookupCondition = '';

    if(String.valueof(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(nonClientCS.Non_Client_RecordType__c).getRecordTypeId()).contains(String.valueof(recordTypeID))) {
      lookupField = nonClientCS.Lookup_Field__c;
      lookupCondition = nonClientCS.Lookup_Condition__c;
    } else {
      lookupField = nonClientCS.Lookup_Field_Additional__c;
      lookupCondition = nonClientCS.Lookup_Condition_Additional__c;
    }


    LookupFieldWhere wrpLookup = new LookupFieldWhere();
    wrpLookup.lookupField = lookupField;
    wrpLookup.whereField = lookupCondition;
    wrpLookup.lookupFieldLabel = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().get(lookupField).getDescribe().getLabel();
    return JSON.serialize(wrpLookup);
  }


  /**
  * @description Searchs duplicate Non Clients
  * @return String with the result
  **/
  @AuraEnabled
  global static String createAccount(String accJSON) {
    return '';
  }


  /**
  * @description Gets the fields from fieldset
  * @return A wrapper with the attributes of each field
  **/
  @AuraEnabled
  global static String getFieldSetAccount() {
    return '';
  }


  /**
  * @description OLD save method Non Clients
  * @return String with the result
  **/
  @AuraEnabled
  global static String createNewAccount(String accJSON, Boolean isAdditional) {
    String result = '';
    return result;
  }

  /**
  * @description Save method for Non Clients Tab
  * @return String with the result
  **/
  @AuraEnabled
  global static String createNewAccountNew(String accJSON, Boolean isAdditional, String fieldAPIName, String lookupID) {

    String result = '';

    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    String accJSON1 = accJSON;
    Map<String, Object> accPayload;
    if(!Test.isRunningTest()) {
      accPayload = (Map<String, Object>) JSON.deserializeUntyped(accJSON1);

      String requestedRecordTypeId = accPayload.containsKey('RecordTypeId') ? String.valueOf(accPayload.get('RecordTypeId')) : '';
      if(String.isBlank(requestedRecordTypeId)) {
        accPayload.put('RecordTypeId',
          isAdditional
            ? Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(nonClientCS.Additional_Non_Client_RecordType__c).getRecordTypeId()
            : Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(nonClientCS.Non_Client_RecordType__c).getRecordTypeId()
        );
      }
      accJSON1 = JSON.serialize(accPayload);
    }
    Account acc = (Account) JSON.deserialize(accJSON1, Account.class);

    if(fieldAPIName != '' && lookupID != '') {
      acc.put(fieldAPIName, lookupID);
    }
    try {
      insert acc;
      result = acc.id;
    } catch (Exception exc) {
      result = exc.getMessage();
      return result;
    }

    Boolean subsidiaryRequested = isProspectSubsidiaryRequested(accPayload);
    Boolean shouldCreateSubsidiary = subsidiaryRequested && shouldCreateProspectSubsidiary(acc, nonClientCS);

    if(shouldCreateSubsidiary) {
      try {
        Account prospectSubsidiaryAcc = buildProspectSubsidiaryAccount(acc, nonClientCS);
        prospectSubsidiaryAcc.Name = accPayload.containsKey('DES_SubSidiaryName') ? (String)accPayload.get('DES_SubSidiaryName') : null;
        prospectSubsidiaryAcc.DES_Country_of_Management_OLD__c = accPayload.containsKey('DES_SubSidiaryCM') ? (String)accPayload.get('DES_SubSidiaryCM') : null;
        prospectSubsidiaryAcc.DES_ID_Fiscal__c = accPayload.containsKey('DES_SubSidiaryTaxId') ? (String)accPayload.get('DES_SubSidiaryTaxId') : null;
        insert prospectSubsidiaryAcc;

        // ACTUALIZAR EL GROUP CON LA ID DE LA SUBSIDIARY EN EL CAMPO MAIN PARENT
        acc.DES_Client_Matrix__c = prospectSubsidiaryAcc.Id;
        update acc;
      } catch (Exception exc) {
        String subsidiaryError = 'Prospect Subsidiary creation failed for Group ' + acc.Id + ': ' + exc.getMessage();
        return subsidiaryError;
      }
    }

    return result;
  }

  private static Boolean isProspectSubsidiaryRequested(Map<String, Object> accPayload) {
    if (accPayload == null) {
      return false;
    }

    Object subsidiaryName = accPayload.get('DES_SubSidiaryName');
    Object subsidiaryTaxId = accPayload.get('DES_SubSidiaryTaxId');

    return (subsidiaryName != null && String.isNotBlank(String.valueOf(subsidiaryName)))
        || (subsidiaryTaxId != null && String.isNotBlank(String.valueOf(subsidiaryTaxId)));
  }

  private static Boolean shouldCreateProspectSubsidiary(Account acc, Prospect_validation__c nonClientCS) {
    if(acc == null || acc.RecordTypeId == null) {
      return false;
    }

    Id groupRtId = resolveProspectGroupRecordTypeId(nonClientCS);
    Id subsidiaryRtId = resolveProspectSubsidiaryRecordTypeId(nonClientCS);

    if(groupRtId != null && acc.RecordTypeId == groupRtId) {
      return true;
    }

    // Fallback for orgs where Group/Subsidiary record type labels can be ambiguous:
    // if current RT is not the Subsidiary RT, allow subsidiary auto-creation.
    if(subsidiaryRtId != null && acc.RecordTypeId != subsidiaryRtId) {
      return true;
    }

    return false;
  }

  private static Account buildProspectSubsidiaryAccount(Account groupAcc, Prospect_validation__c nonClientCS) {
    Account subsidiaryAcc = new Account();
    System.debug('NONC_PS_DEBUG buildProspectSubsidiaryAccount START groupId=' + groupAcc.Id + ' groupName=' + groupAcc.Name);

    if(!Test.isRunningTest()) {
      Id subsidiaryRtId = resolveProspectSubsidiaryRecordTypeId(nonClientCS);
      if(subsidiaryRtId != null) {
        subsidiaryAcc.RecordTypeId = subsidiaryRtId;
      }
    }

    // Reuse the same relevant inputs shown in the Additional (Subsidiary) create form.
    copyIfPresent(groupAcc, subsidiaryAcc, 'CIB_Commercial_Prospect__c');
    copyIfPresent(groupAcc, subsidiaryAcc, 'DES_Country_Client__c');
    copyIfPresent(groupAcc, subsidiaryAcc, 'DES_Country_of_Management_OLD__c');
    copyIfPresent(groupAcc, subsidiaryAcc, 'customer_stock_exchange_name__c');
    copyIfPresent(groupAcc, subsidiaryAcc, 'DES_Activity__c');

    subsidiaryAcc.Name = groupAcc.Name;

    putIfFieldExists(subsidiaryAcc, 'participant_id__c', groupAcc.Id);
    putIfFieldExists(subsidiaryAcc, PROSPECT_SUBSIDIARY_PARENT_FIELD, groupAcc.Id);
    if(String.isBlank((String)subsidiaryAcc.get('CIB_Commercial_Prospect__c'))) {
      putIfFieldExists(subsidiaryAcc, 'CIB_Commercial_Prospect__c', 'CIB');
    }

    // Keep required country parity for subsidiary creation screen.
    if(String.isBlank((String)subsidiaryAcc.get('DES_Country_Client__c')) && String.isNotBlank((String)groupAcc.get('DES_Country_of_Management_OLD__c'))) {
      putIfFieldExists(subsidiaryAcc, 'DES_Country_Client__c', groupAcc.get('DES_Country_of_Management_OLD__c'));
    }

    // Ensure subsidiary goes through insert with a provisional customer id.
    // This avoids depending on trigger-side id generation for initial creation.
    if(String.isBlank((String)subsidiaryAcc.get(PROSPECT_SUBSIDIARY_CUSTOMER_ID_FIELD))) {
      String timestampValue = String.valueOf(DateTime.now().getTime());
      String numericSuffix = timestampValue.length() > 14 ? timestampValue.substring(timestampValue.length() - 14) : timestampValue.leftPad(14, '0');
      putIfFieldExists(subsidiaryAcc, PROSPECT_SUBSIDIARY_CUSTOMER_ID_FIELD, 'P' + numericSuffix);
    }

   /* Boolean leiNotAvailable = isTruthy(groupAcc.get('DES_Create_ProspectSubsidiary_LEINotAv__c'));
    if(!leiNotAvailable && String.isNotBlank((String)groupAcc.get('lei_id__c'))) {
      putIfFieldExists(subsidiaryAcc, 'lei_id__c', groupAcc.get('lei_id__c'));
    }

    System.debug('NONC_PS_DEBUG buildProspectSubsidiaryAccount END payload=' + JSON.serialize(subsidiaryAcc));
*/
    return subsidiaryAcc;
  }

  private static void copyIfPresent(Account sourceAcc, Account targetAcc, String fieldApiName) {
    Object sourceValue = sourceAcc.get(fieldApiName);
    if(sourceValue != null) {
      putIfFieldExists(targetAcc, fieldApiName, sourceValue);
    }
  }

  private static Boolean isTruthy(Object rawValue) {
    if(rawValue instanceof Boolean) {
      return (Boolean) rawValue;
    }

    if(rawValue instanceof String) {
      String normalizedValue = ((String)rawValue).trim().toLowerCase();
      return normalizedValue == 'true' || normalizedValue == 'on' || normalizedValue == '1' || normalizedValue == 'yes';
    }

    return rawValue != null && String.valueOf(rawValue).toLowerCase() == 'true';
  }

  private static void putIfFieldExists(Account targetAcc, String fieldApiName, Object value) {
    if(value == null) {
      return;
    }

    try {
      targetAcc.put(fieldApiName, value);
    } catch(Exception exc) {
      System.debug('Field not available on Account: ' + fieldApiName + ' - ' + exc.getMessage());
    }
  }

  private static Id getRecordTypeIdByDeveloperName(String developerName) {
    if(String.isBlank(developerName)) {
      return null;
    }

    Schema.RecordTypeInfo info = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(developerName);
    return info == null ? null : info.getRecordTypeId();
  }

  private static Id resolveProspectGroupRecordTypeId(Prospect_validation__c nonClientCS) {
    Id additionalRtId = getRecordTypeIdByDeveloperName(nonClientCS.Additional_Non_Client_RecordType__c);
    Id nonClientRtId = getRecordTypeIdByDeveloperName(nonClientCS.Non_Client_RecordType__c);

    if(String.isNotBlank(nonClientCS.Additional_Non_Client_RecordType__c) &&
       nonClientCS.Additional_Non_Client_RecordType__c.toLowerCase().contains('group')) {
      return additionalRtId;
    }

    if(String.isNotBlank(nonClientCS.Non_Client_RecordType__c) &&
       nonClientCS.Non_Client_RecordType__c.toLowerCase().contains('group')) {
      return nonClientRtId;
    }

    if(String.isNotBlank(nonClientCS.Additional_Non_Client_RecordType__c) &&
       nonClientCS.Additional_Non_Client_RecordType__c.toLowerCase().contains('subsidiary')) {
      return nonClientRtId;
    }

    if(String.isNotBlank(nonClientCS.Non_Client_RecordType__c) &&
       nonClientCS.Non_Client_RecordType__c.toLowerCase().contains('subsidiary')) {
      return additionalRtId;
    }

    return additionalRtId;
  }

  private static Id resolveProspectSubsidiaryRecordTypeId(Prospect_validation__c nonClientCS) {
    Id additionalRtId = getRecordTypeIdByDeveloperName(nonClientCS.Additional_Non_Client_RecordType__c);
    Id nonClientRtId = getRecordTypeIdByDeveloperName(nonClientCS.Non_Client_RecordType__c);

    if(String.isNotBlank(nonClientCS.Additional_Non_Client_RecordType__c) &&
       nonClientCS.Additional_Non_Client_RecordType__c.toLowerCase().contains('subsidiary')) {
      return additionalRtId;
    }

    if(String.isNotBlank(nonClientCS.Non_Client_RecordType__c) &&
       nonClientCS.Non_Client_RecordType__c.toLowerCase().contains('subsidiary')) {
      return nonClientRtId;
    }

    if(String.isNotBlank(nonClientCS.Additional_Non_Client_RecordType__c) &&
       nonClientCS.Additional_Non_Client_RecordType__c.toLowerCase().contains('group')) {
      return nonClientRtId;
    }

    if(String.isNotBlank(nonClientCS.Non_Client_RecordType__c) &&
       nonClientCS.Non_Client_RecordType__c.toLowerCase().contains('group')) {
      return additionalRtId;
    }

    return nonClientRtId;
  }

  /**
  * @description Save method for Non Clients Tab
  * @return String with the result
  **/
  @AuraEnabled
  public static Map<String, String> getCustomIdsJSON(){
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    Map<String, String> customIdsJSON = null;
    if(nonClientCS.server_response_custom_ids__c != null && nonClientCS.server_response_custom_ids__c != ''){
      customIdsJSON = (Map<String, String>) JSON.deserialize(nonClientCS.server_response_custom_ids__c,Map<String, String>.class);
    }
    return customIdsJSON;
  }

  @AuraEnabled
  public static Map<String, String> getProspectRecordTypeIds() {
    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    Map<String, String> recordTypeIds = new Map<String, String>();

    Id groupRtId = resolveProspectGroupRecordTypeId(nonClientCS);
    Id subsidiaryRtId = resolveProspectSubsidiaryRecordTypeId(nonClientCS);

    recordTypeIds.put('groupRecordTypeId', groupRtId == null ? '' : String.valueOf(groupRtId));
    recordTypeIds.put('subsidiaryRecordTypeId', subsidiaryRtId == null ? '' : String.valueOf(subsidiaryRtId));

    return recordTypeIds;
  }

  @AuraEnabled
  global static String validateProspectSubsidiaryCreation(String groupId) {
    if(String.isBlank(groupId)) {
      return 'Prospect Subsidiary validation failed: Group Id is empty.';
    }

    try {
      Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
      Id subsidiaryRtId = resolveProspectSubsidiaryRecordTypeId(nonClientCS);
      if(subsidiaryRtId == null) {
        return 'Prospect Subsidiary validation failed: Subsidiary Record Type is not configured.';
      }

      List<Account> subsidiaries = [
        SELECT Id
        FROM Account
        WHERE participant_id__c = :groupId
          AND RecordTypeId = :subsidiaryRtId
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];

      if(!subsidiaries.isEmpty()) {
        return subsidiaries[0].Id;
      }

      return 'Prospect Subsidiary was not created for Group ' + groupId + '.';
    } catch(Exception exc) {
      return 'Prospect Subsidiary validation failed for Group ' + groupId + ': ' + exc.getMessage();
    }
  }

  /**
  * @description Standard validations for non clients
  * @return String with the error of duplicate code
  **/
  @AuraEnabled
  global static String validateNonCliente(Account acc, Prospect_validation__c nonClientCS) {
    ResultValidation objRespuesta = new ResultValidation();
    objRespuesta.status = 'success';
    List<Account> lstCuenta = new List<Account>();

    if(nonClientCS.Unique_Id_field_name__c != null && nonClientCS.Unique_Id_field_name__c.trim().length() > 0) {
        String valueField=String.ValueOf(acc.get(nonClientCS.Unique_Id_field_name__c));
        if((valueField==null || valueField.trim().length() == 0) && nonClientCS.Required_Unique_ID__c == true) {
            objRespuesta.status = 'error';
            objRespuesta.message = system.Label.NClient_lbl_CompleteUnique.replace('&field&',NONC_EditFormNonClient_ctlr.getFieldLabel(nonClientCS.Unique_Id_field_name__c));
            return JSON.serialize(objRespuesta);
        } else if(valueField != null){
            String valfieldAccount = String.ValueOf(acc.get(nonClientCS.Unique_Id_field_name__c)).trim();
            String query = 'SELECT Id , ' + nonClientCS.Unique_Id_field_name__c + ' FROM Account WHERE ' + nonClientCS.Unique_Id_field_name__c + ' = :valfieldAccount';
            if(nonClientCS.Required_Unique_ID__c == false) {
                query = query + ' AND ' + nonClientCS.Unique_Id_field_name__c + ' <> null LIMIT 1';
            }
            String escapedQuery = String.escapeSingleQuotes(query);
            lstCuenta = Database.query(escapedQuery);
        }
    }
    if(lstCuenta.size() > 0) {
      objRespuesta.status = 'error';
      objRespuesta.message = system.Label.NClient_lbl_UniqueIDExist.replace('&field&',NONC_EditFormNonClient_ctlr.getFieldLabel(nonClientCS.Unique_Id_field_name__c));
    }
    return JSON.serialize(objRespuesta);
  }

  /**
  * @description Gets the fields from fieldset
  * @return A wrapper with the attributes of each field
  **/
  @AuraEnabled
  global static String getFieldSetFromAccount(Boolean isAdditional) {
    NonCLientWrapperClass wrpNonclient = new NonCLientWrapperClass();
    List<FieldSetMemberWrapperClass> wrapperList = new List<FieldSetMemberWrapperClass>();
    String objectName = 'Account';
    Schema.SObjectType sObj = Schema.getGlobalDescribe().get(objectName);
    WrapperField wprField = getFieldValidation();

    String idRecordType;
    String fieldAPINameValidationField = wprField.strField;
    Boolean isValidationFieldAdded = false;

    try {
      Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
      String fieldSetName = getFieldSetName(isAdditional);

      idRecordType = getIDRecordType(isAdditional, nonClientCS);

      for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(fieldSetName).getFields()) {

          FieldSetMemberWrapperClass wrapper = new FieldSetMemberWrapperClass();
          wrapper.isDBRequired = fieldMember.getDbRequired();
          wrapper.isRequired = fieldMember.getRequired();
          wrapper.fieldType = String.valueOf(fieldMember.getType());

          if(fieldAPINameValidationField != '' && fieldAPINameValidationField == fieldMember.getFieldPath()){
            wrapper.fieldLabel = wprField.strLabel;
            wrapper.fieldAPIName = wprField.strField;
            wrapper.isValidationField = true;
            isValidationFieldAdded = true;
          }else{
            wrapper.fieldLabel = fieldMember.getLabel();
            wrapper.fieldAPIName = fieldMember.getFieldPath();
            wrapper.isValidationField = false;
          }

          if(wrapper.fieldAPIName=='RecordTypeId') {
            wrapper.fieldValue = idRecordType;
          }
          if(wrapper.fieldType == 'BOOLEAN') {
            wrapper.fieldValue = null;
          }

          if(String.valueOf(fieldMember.getType()) == 'PICKLIST' ||
            String.valueOf(fieldMember.getType()) == 'MULTIPICKLIST') {
            wrapper.pickListValues = sObj.getDescribe().fields.getMap().get(fieldMember.getFieldPath()).getDescribe().getPicklistValues();
          }

          wrapperList.add(wrapper);
      }
    } catch(Exception exc) {
      system.debug('exc ' + exc);
    }

    if(wprField.bolValidationField!=null && wprField.bolValidationField && !isValidationFieldAdded) {
      FieldSetMemberWrapperClass wrapper = new FieldSetMemberWrapperClass();
      wrapper.fieldLabel = wprField.strLabel;
      wrapper.fieldAPIName = wprField.strField;
      wrapper.isValidationField = true;
      wrapperList.add(wrapper);
    }

    wrpNonclient.wrapperList = wrapperList;
    wrpNonclient.recordType = idRecordType;
    wrpNonclient.customIdsJSON = getCustomIdsJSON();

    return JSON.serialize(wrpNonclient);
  }

  private static String getFieldSetName(Boolean isAdditional) {
    return isAdditional?System.Label.NClientAdd_lbl_FielSet:System.Label.NClient_lbl_FielSet;
  }

  private static String getIDRecordType(Boolean isAdditional, Prospect_validation__c nonClientCS) {
    String idRecordType = null;
    if(!Test.isRunningTest() && isAdditional) {
      idRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(nonClientCS.Additional_Non_Client_RecordType__c).getRecordTypeId();
    } else if(!Test.isRunningTest()) {
      idRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(nonClientCS.Non_Client_RecordType__c).getRecordTypeId();
    }
    return idRecordType;
  }

  /**
  * @description Get the help text from custom setting
  * @return String with the help text
  **/
  @AuraEnabled
  global static String getHelpText() {

    Prospect_validation__c nonClientCS = Prospect_validation__c.getInstance();
    String resultData = nonClientCS.Form_Help_Text__c;

    return JSON.serialize(resultData);
  }

  /**
  * @description Gets the fields from the DES_Create_Prospect_Subsidiary FieldSet
  * @return A JSON array of FieldSetMemberWrapperClass with the attributes of each field
  **/
  @AuraEnabled
  global static String getFieldSetProspectSubsidiary() {
    List<FieldSetMemberWrapperClass> wrapperList = new List<FieldSetMemberWrapperClass>();
    String objectName = 'Account';
    String fieldSetName = 'DES_Create_Prospect_Subsidiary';
    Schema.SObjectType sObj = Schema.getGlobalDescribe().get(objectName);

    try {
      for (Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(fieldSetName).getFields()) {
        FieldSetMemberWrapperClass wrapper = new FieldSetMemberWrapperClass();
        wrapper.fieldLabel      = fieldMember.getLabel();
        wrapper.fieldAPIName    = fieldMember.getFieldPath();
        wrapper.isDBRequired    = fieldMember.getDbRequired();
        wrapper.isRequired      = fieldMember.getRequired();
        wrapper.fieldType       = String.valueOf(fieldMember.getType());
        wrapper.isValidationField = false;

        if (String.valueOf(fieldMember.getType()) == 'PICKLIST' ||
            String.valueOf(fieldMember.getType()) == 'MULTIPICKLIST') {
          wrapper.pickListValues = sObj.getDescribe().fields.getMap()
            .get(fieldMember.getFieldPath()).getDescribe().getPicklistValues();
        }

        wrapperList.add(wrapper);
      }
    } catch (Exception exc) {
      System.debug('getFieldSetProspectSubsidiary error: ' + exc);
    }


    return JSON.serialize(wrapperList);
  }

  private static FieldSetMemberWrapperClass buildProspectSubsidiaryFieldWrapper(Schema.SObjectType sObj, String fieldApiName, Boolean required) {
    FieldSetMemberWrapperClass wrapper = new FieldSetMemberWrapperClass();
    wrapper.fieldAPIName = fieldApiName;
    wrapper.fieldLabel = sObj.getDescribe().fields.getMap().containsKey(fieldApiName)
      ? sObj.getDescribe().fields.getMap().get(fieldApiName).getDescribe().getLabel()
      : fieldApiName;
    wrapper.isDBRequired = required;
    wrapper.isRequired = required;
    wrapper.isValidationField = false;
    wrapper.fieldType = sObj.getDescribe().fields.getMap().containsKey(fieldApiName)
      ? String.valueOf(sObj.getDescribe().fields.getMap().get(fieldApiName).getDescribe().getType())
      : 'STRING';

    if (sObj.getDescribe().fields.getMap().containsKey(fieldApiName) &&
        (String.valueOf(sObj.getDescribe().fields.getMap().get(fieldApiName).getDescribe().getType()) == 'PICKLIST' ||
         String.valueOf(sObj.getDescribe().fields.getMap().get(fieldApiName).getDescribe().getType()) == 'MULTIPICKLIST')) {
      wrapper.pickListValues = sObj.getDescribe().fields.getMap().get(fieldApiName).getDescribe().getPicklistValues();
    }

    return wrapper;
  }

  public class NonCLientWrapperClass {

    @AuraEnabled
    private String recordType { get; set; }
    @AuraEnabled
    private Map<String,String> customIdsJSON { get; set; }
    @AuraEnabled
    public List<FieldSetMemberWrapperClass> wrapperList { get; set; }

  }

  public class LookupFieldWhere {

    @AuraEnabled
    private String lookupField { get; set; }
    @AuraEnabled
    private String lookupFieldLabel { get; set; }
    @AuraEnabled
    public String whereField { get; set; }

  }

  public class FieldSetMemberWrapperClass {

    @AuraEnabled
    private Boolean isValidationField { get; set; }
    @AuraEnabled
    private Boolean isDBRequired { get; set; }
    @AuraEnabled
    private Boolean isRequired { get; set; }
    @AuraEnabled
    private String fieldType { get; set; }
    @AuraEnabled
    private String fieldLabel { get; set; }
    @AuraEnabled
    private String fieldAPIName { get; set; }
    @AuraEnabled
    public String fieldValue { get; set; }
    @AuraEnabled
    public List<Schema.PicklistEntry> pickListValues { get; set; }

  }

  public class ResultValidation {
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String message { get; set; }
  }

  public class WrapperField {
    private String strField;
    private String strLabel;
    private Boolean bolValidationField;

    public WrapperField () {
      System.debug('Empty constructor');
    }

    public WrapperField (String strField, String strLabel,Boolean bolValidationField) {
      this.strField = strField;
      this.strLabel = strLabel;
      this.bolValidationField = bolValidationField;
    }
  }
}