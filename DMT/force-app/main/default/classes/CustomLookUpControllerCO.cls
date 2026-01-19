/**
* @author Global Desktop
* @description Lookup Custom para oferta comercial
*/
public with sharing class CustomLookUpControllerCO {

	/**
	* @author Global Desktop
	* @description SINGLETON PATTERN
	*/
  	private static CustomLookUpControllerCO instance;

  	/**
   	* @author Global Desktop
   	* @description getInstance
   	*/
  	public static CustomLookUpControllerCO getInstance() { //NOSONAR
    	if (instance == null) {
      		instance = new CustomLookUpControllerCO();
    	}
    	return instance;
  	}

    /*
    * Met0d0 para pasar sonar
    */
    private CustomLookUpControllerCO() {}

	/*
	* Met0d0 principal que construye la query
	*/
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String oppId) {
      final List <Id> lstIdFilt = new List <Id> ();
      system.debug(lstIdFilt);
      List < sObject > returnList;
      returnList  = new List < sObject > ();
      Set <Id> accIds;
      accIds = new Set<Id> ();

      final Opportunity currentOpp= [Select Id, AccountId from Opportunity where Id =:oppId];
      final String oppAccId = currentOpp.AccountId;
      accIds.add(oppAccId);
      DES_Subsidiary_Group_Relation__c groupParent = new DES_Subsidiary_Group_Relation__c();
      try {
      	 groupParent = [Select participant_child_id__c, participant_parent_id__c from DES_Subsidiary_Group_Relation__c where participant_child_id__c =:oppAccId LIMIT 1];
      } catch (Exception e) {
         system.debug('There is no parent for this Client');
      }

      if(groupParent != null) {
        accIds.add(groupParent.participant_parent_id__c);
      }

      final String searchKey = '%' +searchKeyWord + '%';
      // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5
      final String sQuery =  'select id, Name from coff__Commercial_Offer__c where Name LIKE: searchKey AND coff__participant_id__c IN :accIds order by createdDate DESC limit 5'; //NOSONAR
      final List < sObject > lstOfRecords = Database.query(sQuery);
      returnList.addAll(lstOfRecords);
      return returnList;
    }

  /*
  * Devuelve los resultados de la query dinamica
  */
  @AuraEnabled
  public static List <sObject> lookupResultValues(String searchKeyWord, String lookupObjct , String fromObject, String accountSelec) { //NOSONAR
	String fromObjectAux = fromObject;
    final String searchKey = searchKeyWord + '*';
    system.debug(searchKey);
    List<List<sObject>> lstOfRecordsSOSL = new List<List<sObject>> ();
    system.debug('>>>>>>>>< Objecttttt 1: ' + fromObject);
    if (accountSelec == '' || accountSelec == null ) {
      fromObjectAux = 'anotherObject';
    }
    system.debug('>>>>>>>>< Objecttttt 2: ' + fromObject);

    // El componente es invocado desde cliente.
    if(fromObjectAux == Label.Account) {
      lstOfRecordsSOSL = queryCliente(searchKeyWord, accountSelec, lookupObjct);
    } else if (fromObjectAux == Label.Opportunity_Name) {
      lstOfRecordsSOSL = queryOpp(searchKeyWord, accountSelec);
      // El componente es invocado desde la acción standard de creación
    } else {
      // El lookup es invocado para mostrar Clientes
      if (lookupObjct == Label.account_m) {
        lstOfRecordsSOSL = [FIND :searchKey IN NAME FIELDS RETURNING Account(Id, Name)];//NOSONAR
        // El lookup es invocado para mostrar oportunidades
      } else if(lookupObjct == Label.opportunity) {
        lstOfRecordsSOSL = queryOpp(searchKeyWord, accountSelec);
      }
    }

    return listFinal(lstOfRecordsSOSL, lookupObjct);
  }

  /**
  * Method que devuelve la lista final ya filtrada para lookupResultValues
  *
  **/
  @AuraEnabled
  public static List <sObject> listFinal(List<List<sObject>> lstOfRecordsSOSL, String lookupObjct) {
    final List <sObject> returnList = new List <sObject> ();
    List <sObject> lstFiltrada;
    lstFiltrada = new List <sObject>();
    final List <Id> lstIdFilt = new List <Id> ();
    system.debug(lstIdFilt);
    system.debug(lstFiltrada);
    if(lstOfRecordsSOSL != null) {
      for(List<SObject> lObject : lstOfRecordsSOSL) {
        for(SObject op : lObject) {
          lstIdFilt.add(String.valueof(op.get('Id')));
        }
      }
      if(lookupObjct == Label.opportunity) {
        lstFiltrada = [SELECT id, Name FROM Opportunity WHERE id =:lstIdFilt];
      } else if (lookupObjct == Label.account_m) {
        lstFiltrada = [SELECT id, Name FROM Account WHERE id =:lstIdFilt];
      }
      returnList.addAll(lstFiltrada);
    }
    return returnList;
  }

  /**
  * Method auxiliar para la invocacion del componente desde cliente.
  */
  @AuraEnabled
  public static List<List<sObject>> queryCliente(String searchKey, String accountSelec, String lookupObjct ) {
    final Account client = [Select DES_Client_Type__c from Account where Id =:accountSelec LIMIT 1];
    final Boolean isGroup = client.DES_Client_Type__c == Label.CIB_Group ? true : false;
    List<List<sObject>> lstOfRecordsSOSL = new List<List<sObject>> ();
    system.debug(isGroup);
    /// El lookup es invocado para mostrar oportunidades
    if(lookupObjct == Label.opportunity) {
      lstOfRecordsSOSL = queryOpp(searchKey, accountSelec);
    }
    return lstOfRecordsSOSL;
  }

  /**
  * Method auxiliar para la invocacion del componente desde oportunidad.
  */
  @AuraEnabled
  public static List<List<sObject>> queryOpp(String searchKey, String accountSelec) {
    List<List<sObject>> lstOfRecordsSOSL = new List<List<sObject>> ();
    final Account client = [Select DES_Client_Type__c from Account where Id =:accountSelec LIMIT 1];
    final Boolean isGroup = client.DES_Client_Type__c == Label.CIB_Group ? true : false;
    // El lookup es invocado para mostrar oportunidades
    if(isGroup) {
      final set<id> childs = childsClients(accountSelec);
      system.debug('SEARCHKEY ---> CHILDS: ' + searchKey + ' ------> ' + childs);
      lstOfRecordsSOSL = [FIND :searchKey IN NAME FIELDS RETURNING Opportunity(id, Name where AccountId IN :childs)];
    } else {
      lstOfRecordsSOSL = [FIND :searchKey IN NAME FIELDS RETURNING Opportunity(id, Name where AccountId = :accountSelec)];
    }
    return lstOfRecordsSOSL;
  }

  /*
  * Method para recuperar los id de los clientes hijos de un grupo
  * @Author: Global Desktop
  */
  public static Set<Id> childsClients(String idParent) {
    final List<DES_Subsidiary_Group_Relation__c> childs = [select id, participant_child_id__c, participant_parent_id__c  from DES_Subsidiary_Group_Relation__c where participant_parent_id__c =:idParent];

    Set<Id> childsIds;
    childsIds = new Set<Id> ();

    for(DES_Subsidiary_Group_Relation__c current : childs) {
      childsIds.add(current.participant_child_id__c);
    }

    return childsIds;
  }
}