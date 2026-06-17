global without sharing class GBL_DenormalizeOpportunitiesUtils {
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Set<AMH_Denorm_Account_Opportunity__c> setAccOpty = new Set<AMH_Denorm_Account_Opportunity__c>();

  // Campos static final inicializados en bloque static
  private static final Integer deleteBatchSize;
  private static final String leadToAccountField;
  private static final String optyToLeadField;

  // Bloque de inicialización estática
  static {
    Integer tempDeleteBatchSize = 0;
    String tempLeadToAccountField = null;
    String tempOptyToLeadField = null;

    List<AMH_GBL_Account_Multi_Hierarchy_denorm__mdt> lmdt = [
      SELECT
        AMH_Delete_Batch_Size__c,
        AMH_Lead_Lookup_Field_To_Account__c,
        AMH_Opportunity_Lookup_Field_To_Lead__c
      FROM AMH_GBL_Account_Multi_Hierarchy_denorm__mdt
      WHERE AMH_Active__c = TRUE
      LIMIT 1
    ];

    if (!lmdt.isEmpty()) {
      tempDeleteBatchSize = Integer.valueOf(lmdt[0].AMH_Delete_Batch_Size__c);
      tempLeadToAccountField = lmdt[0].AMH_Lead_Lookup_Field_To_Account__c;
      tempOptyToLeadField = lmdt[0].AMH_Opportunity_Lookup_Field_To_Lead__c;

      System.debug('deleteBatchSize: ' + tempDeleteBatchSize);
      System.debug('leadToAccountField: ' + tempLeadToAccountField);
      System.debug('optyToLeadField: ' + tempOptyToLeadField);
    }

    deleteBatchSize = tempDeleteBatchSize;
    leadToAccountField = tempLeadToAccountField;
    optyToLeadField = tempOptyToLeadField;
  }

  //--------------------------------------- PUBLIC METHODS ----------------------------------------
  global void clear() {
    if (deleteBatchSize != null && deleteBatchSize > 0) {
      Id batchInstanceId = Database.executeBatch(
        new GBL_DenormalizeOpportunitiesDelete(),
        deleteBatchSize
      );
    }
  }

  global void clear(String optyId) {
    List<AMH_Denorm_Account_Opportunity__c> pListAccOpty = [
      SELECT Id
      FROM AMH_Denorm_Account_Opportunity__c
      WHERE AMH_OpportunityId__c = :optyId
    ];

    if (!pListAccOpty.isEmpty()) {
      delete pListAccOpty;
    }
  }

  global void restore() {
    if (deleteBatchSize != null && deleteBatchSize > 0) {
      Id batchInstanceId = Database.executeBatch(
        new GBL_DenormalizeOpportunitiesDelete(true),
        deleteBatchSize
      );
    }
  }

  global void restore(String optyId) {
    this.clear(optyId);
    this.denormalize(optyId);
  }

  global void denormalize(String optyId) {
    List<Opportunity> opts = [
      SELECT Id, AccountId
      FROM Opportunity
      WHERE Id = :optyId
      LIMIT 1
    ];

    for (Opportunity opt : opts) {
      this.denormalize(opt);
    }
  }

  global Integer denormalize(Opportunity opt) {
    setAccOpty.clear();
    String optId = opt.Id;
    String accId;

    if (opt != null) {
      if (opt.AccountId != null) {
        System.debug('Account Opportunity');
        accId = opt.AccountId;
      } else {
        System.debug('Lead Opportunity');
        // Validar que los campos existen en el Schema antes de usarlos
        if (isValidOpportunityToLeadField() && isValidLeadToAccountField()) {
          accId = getAccountIdFromLead(optId);
        }
      }

      if (String.isNotBlank(accId)) {
        recursiveFxn(accId, optId);
      }
    }

    // Insertar relaciones en base de datos
    if (!setAccOpty.isEmpty()) {
      List<AMH_Denorm_Account_Opportunity__c> pListAccOpty = new List<AMH_Denorm_Account_Opportunity__c>();
      pListAccOpty.addAll(setAccOpty);
      insert pListAccOpty;
    }

    return setAccOpty.size();
  }

  //--------------------------------------- PRIVATE METHODS ---------------------------------------

  // Método seguro para obtener el Account Id desde Lead
  private String getAccountIdFromLead(String optId) {
    String accId = null;

    try {
      // Validar configuración
      if (!isValidOpportunityToLeadField() || !isValidLeadToAccountField()) {
        return null;
      }

      // Obtener el descriptor del campo de forma segura
      String optyToLeadRelField = optyToLeadField.replace('__c', '__r');

      // Usar Schema para validación adicional
      Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();

      String baseFieldName = optyToLeadField.toLowerCase();
      if (!fieldMap.containsKey(baseFieldName)) {
        System.debug('Field does not exist: ' + optyToLeadField);
        return null;
      }

      // Construir query con campos validados y escapados
      String safeRelField = String.escapeSingleQuotes(optyToLeadRelField);
      String safeLeadField = String.escapeSingleQuotes(leadToAccountField);

      String query =
        'SELECT Id, ' +
        safeRelField +
        '.' +
        safeLeadField +
        ' FROM Opportunity WHERE Id = :optId LIMIT 1';

      List<Opportunity> opportunities = Database.query(query);

      // Verificación segura contra null
      if (!opportunities.isEmpty()) {
        SObject leadRecord = opportunities[0].getSObject(optyToLeadRelField);
        if (leadRecord != null) {
          Object accountIdObj = leadRecord.get(leadToAccountField);
          if (accountIdObj != null) {
            accId = String.valueOf(accountIdObj);
          }
        }
      }
    } catch (Exception e) {
      System.debug('Error getting Account Id from Lead: ' + e.getMessage());
    }

    return accId;
  }

  // Validar que el campo Opportunity -> Lead existe
  private Boolean isValidOpportunityToLeadField() {
    if (String.isBlank(optyToLeadField)) {
      return false;
    }
    return Schema.SObjectType.Opportunity.fields.getMap()
      .containsKey(optyToLeadField.toLowerCase());
  }

  // Validar que el campo Lead -> Account existe
  private Boolean isValidLeadToAccountField() {
    if (String.isBlank(leadToAccountField)) {
      return false;
    }
    return Schema.SObjectType.Lead.fields.getMap()
      .containsKey(leadToAccountField.toLowerCase());
  }

  // Validar que el campo de relación es válido
  private Boolean isValidRelationshipField(String relationshipFieldName) {
    if (String.isBlank(relationshipFieldName)) {
      return false;
    }

    // Obtener el campo base (sin el __r)
    String baseFieldName = relationshipFieldName.replace('__r', '__c');

    // Verificar que existe en Opportunity
    return Schema.SObjectType.Opportunity.fields.getMap()
      .containsKey(baseFieldName.toLowerCase());
  }

  private void recursiveFxn(String accId, String optyId) {
    if (accId != null) {
      System.debug(
        'Add relationship for Opty: ' + optyId + ' and AccId: ' + accId
      );
      AMH_Denorm_Account_Opportunity__c accOpty = new AMH_Denorm_Account_Opportunity__c(
        AMH_AccountId__c = accId,
        AMH_OpportunityId__c = optyId
      );
      setAccOpty.add(accOpty);
    }

    // Recuperar los padres de la cuenta
    List<AMH_GBL_Account_Relationship__c> listAccRel = [
      SELECT Id, AMH_Parent_Account__c
      FROM AMH_GBL_Account_Relationship__c
      WHERE AMH_Child_Account__c = :accId
    ];

    // Iterar recursivamente para agregar la oportunidad a cada padre
    for (AMH_GBL_Account_Relationship__c accRel : listAccRel) {
      recursiveFxn(accRel.AMH_Parent_Account__c, optyId);
    }
  }

  // Constructor vacío - la inicialización se hace en el bloque static
  global GBL_DenormalizeOpportunitiesUtils() {
    // Inicialización de campos static se realiza en el bloque static
  }
}