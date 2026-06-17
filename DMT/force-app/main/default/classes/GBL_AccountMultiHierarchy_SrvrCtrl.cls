public with sharing class GBL_AccountMultiHierarchy_SrvrCtrl {
  private GBL_HierarchyNode pMyHierarchy;
  private static String pHierarchyType;
  private static List<GBL_HierarchyNode> pParents = new List<GBL_HierarchyNode>();

  //*********************************************************************************************************************************************************
  //CUSTOM METADATA RETRIEVAL FUNCTIONS
  //*********************************************************************************************************************************************************
  @AuraEnabled
  //Returns a list with the Account hierarchy types to show in the hierarchy tree
  public static String getOptions() {
    String result;

    List<GBL_Account_Multi_Hierarchy_Relationship__mdt> relTypes = [
      SELECT
        Label,
        value__c,
        Selected__c,
        Color_Code__c,
        Active__c,
        Custom_Relationship__c
      FROM GBL_Account_Multi_Hierarchy_Relationship__mdt
      WHERE Active__c = TRUE
      ORDER BY value__c ASC
    ];
    result = generateJSONContent(relTypes);
    //system.debug('getOptions(): ' + result);
    return result;
  }

  @AuraEnabled
  //Returns a list with the visions defined
  public static String getVisions() {
    String result;

    List<GBL_Account_Multi_Hierarchy_Vision__mdt> visions = [
      SELECT Label, Name__c, Active__c, Order__c
      FROM GBL_Account_Multi_Hierarchy_Vision__mdt
      WHERE Active__c = TRUE
      ORDER BY Order__c ASC
    ];
    result = generateJSONContent(visions);
    system.debug('getVisions(): ' + result);
    return result;
  }
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //FETCHCHILDDATA()
  //Returns the data from the account childs for the following scenarios:
  //  · Initial Load where the structure needs to be RootNode + Child Nodes
  //  · When a node is clicked only Child Nodes need to be returned
  //  · From Subsidiary Related List where Childs need to be filtered by SearchKey
  // It is also used as a single interface either when recovering standard or custom hierarchy data
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  @AuraEnabled
  public static String fetchChildData(
    Boolean useStandard,
    Boolean addRoot,
    String recordId,
    String scope,
    String[] types,
    String searchKey,
    String leadLookupField,
    String accountTypeField
  ) {
    if (useStandard) {
      return getStandardChildData(
        addRoot,
        recordId,
        scope,
        types,
        searchKey,
        leadLookupField,
        accountTypeField
      );
    } else {
      return getCustomChildData(
        addRoot,
        recordId,
        scope,
        types,
        searchKey,
        leadLookupField
      );
    }
  }

  private static String getStandardChildData(
    Boolean addRoot,
    String recordId,
    String scope,
    String[] types,
    String searchKey,
    String leadLookupField,
    String accountTypeField
  ) {
    String result;
    List<GBL_HierarchyNode> childs = new List<GBL_HierarchyNode>();

    // Validate accountTypeField exists
    Boolean isAccountTypeFieldValid = false;
    if (String.isNotBlank(accountTypeField)) {
      Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();
      isAccountTypeFieldValid = fieldMap.containsKey(
        accountTypeField.toLowerCase()
      );
    }

    // Ejecutar query SIN LIKE ni ORDER BY (Name es campo cifrado)
    List<Account> accounts;

    if (isAccountTypeFieldValid) {
      accounts = queryAccountsWithTypeField(recordId, types, accountTypeField);
    } else {
      accounts = queryAccountsWithoutTypeField(recordId);
    }

    // Filtrar por búsqueda EN MEMORIA (no en SOQL)
    List<Account> filteredAccounts = new List<Account>();
    if (String.isNotBlank(searchKey) && !addRoot) {
      String lowerSearchKey = searchKey.toLowerCase();
      for (Account acc : accounts) {
        if (
          acc.Name != null && acc.Name.toLowerCase().contains(lowerSearchKey)
        ) {
          filteredAccounts.add(acc);
        }
      }
    } else {
      filteredAccounts = accounts;
    }

    // Ordenar EN MEMORIA (no en SOQL) - Name es campo cifrado
    filteredAccounts.sort();

    // Build Childs List
    for (Account accRel : filteredAccounts) {
      GBL_HierarchyNode pMyNode = new GBL_HierarchyNode();
      pMyNode.label = accRel.Name;

      if (isAccountTypeFieldValid) {
        Object typeValue = accRel.get(accountTypeField);
        if (typeValue != null) {
          pMyNode.type = String.valueOf(typeValue);
        }
      }

      pMyNode.objectName = 'account';
      pMyNode.objectId = accRel.Id;
      pMyNode.name = accRel.Id;
      pMyNode.vision = 'standard';
      pMyNode.recordId = accRel.Id;
      childs.add(pMyNode);
    }

    // Add related Leads if needed
    if (types != null && !types.isEmpty()) {
      String typeString = String.join(types, ',').toLowerCase();
      if (
        typeString.contains('lead') &&
        String.isNotBlank(leadLookupField) &&
        Schema.SObjectType.Lead.fields.getMap()
          .containsKey(leadLookupField.toLowerCase())
      ) {
        childs.addAll(relatedLeads(recordId, leadLookupField));
      }
    }

    // Serialize the object structure to JSON
    if (addRoot) {
      GBL_HierarchyNode pRootNode = createNode(recordId, 'standard');
      if (pRootNode != null) {
        pRootNode.children.addAll(childs);
        result = generateJSONContent2(pRootNode);
      } else {
        result = generateJSONContent(childs);
      }
    } else {
      result = generateJSONContent(childs);
    }

    return result;
  }

  // Query SIN LIKE ni ORDER BY - Name es campo cifrado
  private static List<Account> queryAccountsWithoutTypeField(String recordId) {
    return [
      SELECT Id, Name, ParentId
      FROM Account
      WHERE ParentId = :recordId
      LIMIT 1000
    ];
  }

  // Query con accountTypeField SIN usar Name en WHERE/ORDER BY
  private static List<Account> queryAccountsWithTypeField(
    String recordId,
    String[] types,
    String accountTypeField
  ) {
    // Validar que el campo existe antes de usarlo
    if (
      String.isBlank(accountTypeField) ||
      !Schema.SObjectType.Account.fields.getMap()
        .containsKey(accountTypeField.toLowerCase())
    ) {
      return new List<Account>();
    }

    // Escapar el nombre del campo
    String safeFieldName = String.escapeSingleQuotes(accountTypeField);

    String queryString = 'SELECT Id, Name, ParentId, ' + safeFieldName;
    queryString += ' FROM Account';
    queryString += ' WHERE ParentId = :recordId';

    if (types != null && !types.isEmpty()) {
      queryString += ' AND ' + safeFieldName + ' IN :types';
    }

    queryString += ' LIMIT 1000';

    System.debug(LoggingLevel.DEBUG, 'Query: ' + queryString);
    return Database.query(queryString);
  }
  private static String getCustomChildData(
    Boolean addRoot,
    String recordId,
    String scope,
    String[] types,
    String searchKey,
    String leadLookupField
  ) {
    String result;
    List<GBL_HierarchyNode> childs = new List<GBL_HierarchyNode>();

    // Construir query con bind variables
    String query = 'SELECT Id, Name, AMH_Child_Account__c, AMH_Child_Account__r.Name, AMH_Type__c, AMH_Vision__c ';
    query += 'FROM AMH_GBL_Account_Relationship__c ';
    query += 'WHERE AMH_Parent_Account__c = :recordId ';
    query += 'AND AMH_Vision__c = :scope ';

    // Agregar filtro de tipos si existe
    if (types != null && !types.isEmpty()) {
      query += 'AND AMH_Type__c IN :types ';
    }

    // NO usar LIKE con Name (campo cifrado) - filtrar en memoria
    // query += 'ORDER BY Name, Type__c ASC';  // Comentado porque Name es cifrado

    System.debug(LoggingLevel.DEBUG, 'Custom Child Query: ' + query);

    // Ejecutar query con bind variables
    List<AMH_GBL_Account_Relationship__c> rels = Database.query(query);

    // Filtrar por búsqueda EN MEMORIA (Name puede ser cifrado)
    List<AMH_GBL_Account_Relationship__c> filteredRels = new List<AMH_GBL_Account_Relationship__c>();

    if (String.isNotBlank(searchKey) && !addRoot) {
      String lowerSearchKey = searchKey.toLowerCase();
      for (AMH_GBL_Account_Relationship__c rel : rels) {
        if (
          rel.AMH_Child_Account__r.Name != null &&
          rel.AMH_Child_Account__r.Name.toLowerCase().contains(lowerSearchKey)
        ) {
          filteredRels.add(rel);
        }
      }
    } else {
      filteredRels = rels;
    }

    // Construir nodos
    for (AMH_GBL_Account_Relationship__c accRel : filteredRels) {
      GBL_HierarchyNode pMyNode = new GBL_HierarchyNode();
      pMyNode.label = accRel.AMH_Child_Account__r.Name;
      pMyNode.type = accRel.AMH_Type__c;
      pMyNode.objectName = 'account';
      pMyNode.objectId = accRel.AMH_Child_Account__c;
      pMyNode.name = accRel.AMH_Child_Account__c;
      pMyNode.vision = accRel.AMH_Vision__c;
      pMyNode.recordId = accRel.Id;
      childs.add(pMyNode);
    }

    // Añadir leads si procede
    if (types != null && !types.isEmpty()) {
      String typeString = String.join(types, ',').toLowerCase();
      if (
        typeString.contains('lead') &&
        String.isNotBlank(leadLookupField) &&
        Schema.SObjectType.Lead.fields.getMap()
          .containsKey(leadLookupField.toLowerCase())
      ) {
        childs.addAll(relatedLeads(recordId, leadLookupField));
      }
    }

    // Devolver JSON
    if (addRoot) {
      GBL_HierarchyNode pRootNode = createNode(recordId, scope);
      if (pRootNode != null) {
        pRootNode.children.addAll(childs);
        result = generateJSONContent2(pRootNode);
      } else {
        result = generateJSONContent(childs);
      }
    } else {
      result = generateJSONContent(childs);
    }

    return result;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //FETCHPARENTS() - Returns a JSON structure with the parent records of the recordId passed as a parameter
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  @AuraEnabled
  //Manages the creation of the hierarchyNode structure from Node to Top-Parents
  public static String fetchParentData(
    Boolean useStandard,
    String recordId,
    String vision,
    String accountTypeField
  ) {
    String result;

    //Create the record as the begining node of the hierarchy
    GBL_HierarchyNode pFirstNode = createNode(recordId, vision);

    //Fill up the parents hierarchy for the recordId
    if (pFirstNode != null) {
      if (useStandard) {
        getStandardParentData(recordId, pFirstNode, accountTypeField);
      } else {
        getCustomParentData(pFirstNode);
      }
    }

    //finally, serialize the object structure to a JSON so it can be passed to the client-side controller
    result = generateJSONContent2(pFirstNode);
    system.debug('fetchParentData result: ' + result);
    return result;
  }

  //constructs the structure of nodes from Top Parent to first-level parent using Account Standard Hierarchy
  private static void getStandardParentData(
    String recordId,
    GBL_HierarchyNode node,
    String accountTypeField
  ) {
    Boolean isAccountTypeFieldValid = false;

    if (String.isNotBlank(accountTypeField)) {
      Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();
      isAccountTypeFieldValid = fieldMap.containsKey(
        accountTypeField.toLowerCase()
      );
    }

    // Query SIN ORDER BY (Name es cifrado)
    List<Account> accounts;

    if (isAccountTypeFieldValid) {
      String safeFieldName = String.escapeSingleQuotes(accountTypeField);

      String queryString = 'SELECT Id, Name, ParentId, ' + safeFieldName;
      queryString += ' FROM Account WHERE Id = :recordId LIMIT 1';
      accounts = Database.query(queryString);
    } else {
      accounts = [
        SELECT Id, Name, ParentId
        FROM Account
        WHERE Id = :recordId
        LIMIT 1
      ];
    }

    for (Account accRel : accounts) {
      GBL_HierarchyNode pMyNode = new GBL_HierarchyNode();
      pMyNode.label = accRel.Name;

      if (isAccountTypeFieldValid) {
        Object typeValue = accRel.get(accountTypeField);
        if (typeValue != null) {
          pMyNode.type = String.valueOf(typeValue);
        }
      }

      pMyNode.objectName = 'account';
      pMyNode.objectId = accRel.Id;
      pMyNode.name = accRel.Id;
      pMyNode.vision = 'standard';
      pMyNode.recordId = accRel.Id;

      if (accRel.ParentId != null) {
        getStandardParentData(accRel.ParentId, pMyNode, accountTypeField);
      }

      node.children.add(pMyNode);
    }
  }

  //constructs the structure of nodes from Top Parent to first-level parent using Account custom Multi Hierarchy
  private static void getCustomParentData(GBL_HierarchyNode node) {
    String nodeObjectId = node.objectId;
    String nodeVision = node.vision;

    List<AMH_GBL_Account_Relationship__c> lParents = [
      SELECT
        Id,
        Name,
        AMH_Parent_Account__c,
        AMH_Parent_Account__r.Name,
        AMH_Parent_Account__r.Id,
        AMH_Type__c,
        AMH_Vision__c
      FROM AMH_GBL_Account_Relationship__c
      WHERE AMH_Child_Account__c = :nodeObjectId AND AMH_Vision__c = :nodeVision
    ];

    for (AMH_GBL_Account_Relationship__c accRel : lParents) {
      GBL_HierarchyNode pMyNode = new GBL_HierarchyNode();

      //create a node for the parent
      pMyNode.label = accRel.AMH_Parent_Account__r.Name;
      pMyNode.type = accRel.AMH_Type__c;
      pMyNode.objectName = 'account';
      pMyNode.objectId = accRel.AMH_Parent_Account__c;
      pMyNode.name = accRel.AMH_Parent_Account__c;
      pMyNode.vision = accRel.AMH_Vision__c;
      pMyNode.recordId = accRel.Id;

      //Add node as a child to the input hierarchy
      node.children.add(pMyNode);

      //Let's check if there are more parents so they can be added
      getCustomParentData(pMyNode); //get all parents from the current node

      system.debug('Adding to: ' + node.label + ' children: ' + pMyNode.label);
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //Other common functions
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //Returns a GBL_HierarchyNode structure from recordId
  private static GBL_HierarchyNode createNode(String recordId, String vision) {
    //First, locate the main account which will be the root node in the hierarchy structure
    List<Account> myAcc = [
      SELECT Id, Name
      FROM Account
      WHERE Id = :recordId
      LIMIT 1
    ];
    if (!myAcc.isEmpty()) {
      //Create node structure
      GBL_HierarchyNode pMyNode = new GBL_HierarchyNode();
      pMyNode.label = myAcc[0].Name;
      pMyNode.type = 'root';
      pMyNode.objectName = 'account';
      pMyNode.objectId = myAcc[0].Id;
      pMyNode.name = myAcc[0].Id;
      pMyNode.vision = vision;

      return pMyNode;
    }
    return null;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // QUERIES FOR RELATED ENTITIES
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  private static List<GBL_HierarchyNode> relatedLeads(
    String recordId,
    String leadLookupFieldName
  ) {
    List<GBL_HierarchyNode> leads = new List<GBL_HierarchyNode>();

    // Validate field exists in Lead object
    if (String.isBlank(leadLookupFieldName)) {
      return leads;
    }

    // Validar contra el Schema
    Map<String, Schema.SObjectField> leadFields = Schema.SObjectType.Lead.fields.getMap();
    if (!leadFields.containsKey(leadLookupFieldName.toLowerCase())) {
      return leads;
    }

    // Escapar el nombre del campo
    String safeFieldName = String.escapeSingleQuotes(leadLookupFieldName);

    // Build query with validated and escaped field name
    String queryString = 'SELECT Id, Name, Status, ' + safeFieldName;
    queryString += ' FROM Lead';
    queryString += ' WHERE ' + safeFieldName + ' = :recordId';
    queryString += ' LIMIT 1000';

    try {
      for (Lead lead : Database.query(queryString)) {
        GBL_HierarchyNode pMyNode = new GBL_HierarchyNode();
        pMyNode.label = lead.Name;
        pMyNode.extendedInfo = lead.Status;
        pMyNode.type = 'Lead';
        pMyNode.objectName = 'Lead';
        pMyNode.objectId = lead.Id;
        pMyNode.name = lead.Id;
        leads.add(pMyNode);
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Error querying leads: ' + e.getMessage()
      );
    }

    return leads;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //JSON GENERATORS
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  private static String generateJSONContent(List<GBL_HierarchyNode> nodes) {
    // Create a JSONGenerator object based on a List of Hierarchy custom objects

    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartArray();
    for (GBL_HierarchyNode node : nodes) {
      //gen.writeStartArray();
      gen.writeObject(node);
      //gen.writeEndArray();
    }
    gen.writeEndArray();

    String pretty = gen.getAsString();
    return pretty;
  }

  private static String generateJSONContent2(GBL_HierarchyNode myHierarchy) {
    // Create a JSONGenerator object based on a Hierarchy custom object.

    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeObject(myHierarchy);

    //system.debug(gen.getAsString());
    String pretty = gen.getAsString();
    return pretty;
  }

  private static String generateJSONContent(
    List<GBL_Account_Multi_Hierarchy_Relationship__mdt> relTypes
  ) {
    // Create a JSONGenerator object based on a GBL_Account_Multi_Hierarchy_Relationship__mdt custom object.
    Map<Integer, String> d3SchemaColorsToHex = new Map<Integer, String>{
      0 => '#1f77b4',
      1 => '#aec7e8',
      2 => '#f17d30',
      3 => '#f7ba77',
      4 => '#4ca02e',
      5 => '#98e089',
      6 => '#d73e2a',
      7 => '#f29695',
      8 => '#9466bd',
      9 => '#c6b0d6',
      10 => '#8b554a',
      11 => '#c49c94',
      12 => '#e476c2',
      13 => '#f4b6d2',
      14 => '#7f7f7f',
      15 => '#c7c7c7',
      16 => '#bcbe24',
      17 => '#dbdb8d',
      18 => '#4fbfcf',
      19 => '#9ddae5'
    };
    system.debug('relTypes: ' + relTypes);
    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartArray();
    for (GBL_Account_Multi_Hierarchy_Relationship__mdt relType : relTypes) {
      if (relType.Active__c == true) {
        Integer intColorCode = Integer.valueOf(relType.Color_Code__c);
        String hexColorCode = d3SchemaColorsToHex.get(intColorCode);
        system.debug('INT: ' + intColorCode + ' / HEX: ' + hexColorCode);

        gen.writeStartObject();
        gen.writeObjectField('label', relType.Label);
        gen.writeObjectField('value', relType.value__c);
        gen.writeObjectField('selected', relType.Selected__c);
        gen.writeObjectField('color', hexColorCode);
        gen.writeObjectField('colorCodeD3', intColorCode);
        gen.writeObjectField(
          'customRelationship',
          relType.Custom_Relationship__c
        );
        gen.writeEndObject();
      }
    }
    gen.writeEndArray();

    String pretty = gen.getAsString();
    return pretty;
  }

  private static String generateJSONContent(
    List<GBL_Account_Multi_Hierarchy_Vision__mdt> visions
  ) {
    // Create a JSONGenerator object based on a GBL_Account_Multi_Hierarchy_Relationship__mdt custom object.

    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartArray();
    for (GBL_Account_Multi_Hierarchy_Vision__mdt vision : visions) {
      gen.writeStartObject();
      gen.writeObjectField('value', vision.Name__c);
      gen.writeObjectField('label', vision.Label);
      gen.writeEndObject();
    }
    gen.writeEndArray();

    String pretty = gen.getAsString();
    return pretty;
  }
}