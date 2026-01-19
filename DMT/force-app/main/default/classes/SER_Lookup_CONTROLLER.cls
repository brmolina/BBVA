/**********************************************************************************
* @author     BBVA
* @date     26-12-2019
* @description  Controlador del componente SER_Lookup.cmp.

**********************************************************************************/
public with sharing class SER_Lookup_CONTROLLER {
  /*Constante 'Account' */
  public final static string ACCOUNT = 'Account';
  /*Constante 'Local_Reference__c' */
  public final static string LOCAL_REFERENCE = 'Local_Reference__c';

  /*---------------------------------------------------------------------------------------
      Company:       BBVA
      Description:   private constructor.
  ---------------------------------------------------------------------------------------*/
  private SER_Lookup_CONTROLLER() {
  }


  /*---------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   forma una query con los parámetros de entrada y devuelve una lista de objetos.

    IN:        Request request.
    OUT:       List<RecordsData>.
  ---------------------------------------------------------------------------------------*/
  @AuraEnabled
  public static Response fetchRecords(Request request) {
    try {
      Response response;
      response = new Response();
      //Lista que se devuelve cuando no hay QueryFields.
      List<RecordsData> recordsDataList;
      recordsDataList = new List<RecordsData>();
      //Lista de Listas que se devuelve cuando hay QueryFields.
      List<List<RecordsData>> rdListWFields;
      rdListWFields = new List<List<RecordsData>>();
      //Lista de las filiales.
      Set<Id> filialesIds;
      filialesIds = new Set<Id>();
      //Indica si el objeto es un Grupo
      Boolean isGroup;
      isGroup = String.isNotBlank(request.objectName) && request.objectName.trim().equalsIgnoreCase('Group');
      //Query
      String query;
      query = String.escapeSingleQuotes(createQuery(request, isGroup));

      trimSearchString(request);

      if(String.isNotBlank(request.value)) {
        query += ' WHERE Id =\'' + String.escapeSingleQuotes(request.value.trim()) + '\'';
      } else if(String.isNotBlank(request.filterField)) {
        query += ' WHERE ' + String.escapeSingleQuotes(request.filterField.trim()) +
            ' LIKE ' + '\'%' + String.escapeSingleQuotes(request.searchString.trim()) + '%\'';
      }

      query += ' LIMIT 20';

      for(SObject sOb : Database.query(query)) {
        if(isGroup) {
          Account filial;
          filial = new Account();
          filial = (Account)sOb;
          if(filial.DES_Main_Parent__c != null) {
            filialesIds.add(filial.DES_Main_Parent__c);
          }
        } else {
          trateRecords(request, recordsDataList, rdListWFields, sOb, isGroup);
        }
      }

      if(filialesIds.isEmpty() == false) {
        for(Account grupo : [SELECT Id, Name, DES_Group_Code__c, Group_BEI__c FROM Account WHERE Id IN :filialesIds LIMIT 20]) {
          Request request2;
          request2 = new Request();
          request2.objectName = 'Group';
          request2.queryFields = 'DES_Group_Code__c,Group_BEI__c';
          trateRecords(request2, recordsDataList, rdListWFields, grupo, isGroup);
        }
      }

      response.rdListWFields = rdListWFields;
      response.recordsDataList = recordsDataList;

      return response;
    } catch (Exception err) {
      throw new AuraHandledException(Label.SER_Error_Server + ' ' + err);
    }
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   Recuerta el string de busqueda si vienen BEIs concatenados.

    IN:            Request request.
    OUT:           Void.
  ---------------------------------------------------------------------------------------*/
  private static Void trimSearchString(Request request) {
    Boolean trimSString;
    trimSString = String.isNotBlank(request.searchString) && request.searchString.contains(',');
    if(trimSString) {
      request.searchString = request.searchString.substringAfterLast(', ');
    }
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   Crea la query sin los filtros.

    IN:            Request request.
    IN:            Boolean isGroup
    OUT:           String.
  ---------------------------------------------------------------------------------------*/
  private static String createQuery(Request request, Boolean isGroup) {
    String query;
    query = 'SELECT Id ' + (String.isNotBlank(request.filterField) ? (' ,' + String.escapeSingleQuotes(request.filterField.trim())) : '');

    if(request.objectName.equalsIgnoreCase('Case') == false) {
      query +=  ', Name ';
    }

    if(String.isNotBlank(request.queryFields)) {
      query += ', ' + String.escapeSingleQuotes(request.queryFields.trim());
    }

    if(isGroup) {
      query += ' FROM Account';
    } else if (String.isNotBlank(request.objectName)) {
      query += ' FROM ' +  String.escapeSingleQuotes(request.objectName.trim());
    }

    return query;
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   va a tartar los registros obtenidos con la query.

    IN:        Request request.
    IN:        List<List<RecordsData>> rdListWFields.
    IN:        List<List<RecordsData>> rdListWFields.
    IN:        SObject s.
    IN:        Boolean isGroup
    OUT:       void.
  ---------------------------------------------------------------------------------------*/
  private static void trateRecords(Request request, List<RecordsData> recordsDataList, List<List<RecordsData>> rdListWFields, SObject soBJ, Boolean isGroup) {
    if(String.isNotBlank(request.queryFields)) {
      List<RecordsData> fieldsDataList;
      fieldsDataList = new List<RecordsData>();
      fieldsDataList.add(new RecordsData((String)soBJ.get('Name'), (String)soBJ.get('id')));
      fieldsDataList.add(new RecordsData('Name', (String)soBJ.get('Name')));
      if(String.isNotBlank(request.filterField)) {
        fieldsDataList.add(new RecordsData(getLabel(request.objectName, request.filterField), (String)soBJ.get(request.filterField)));
      }

      for(String field : request.queryFields.split(',')) {
        if(String.isNotBlank((String)soBJ.get(field))) {
          fieldsDataList.add(new RecordsData(getLabel(isGroup ? 'Account' : request.objectName, field),(String)soBJ.get(field)));
        }
      }
      rdListWFields.add(fieldsDataList);
    } else {
      recordsDataList.add(new RecordsData((String)soBJ.get(request.filterField), (String)soBJ.get('id')));
    }
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   forma una query con los parámetros de entrada y devuelve una lista de objetos.

    IN:        String searchString
    IN:        String value
    OUT:       String field label
  ---------------------------------------------------------------------------------------*/
  private static String getLabel(String objectType, String field) {
    String fieldName = '';
    if(objectType == ACCOUNT) {
      fieldName = Schema.SObjectType.Account.fields.getMap().get(field).getDescribe().getLabel();
    } else if(objectType == LOCAL_REFERENCE) {
      fieldName = Schema.SObjectType.Local_Reference__c.fields.getMap().get(field).getDescribe().getLabel();
    }
    return fieldName;
  }


  /**************************************************************************************
  *******************                   WRAPPER                     *********************
  **************************************************************************************/

  /*--------------------------------------------------------------------------------------
      Company:        BBVA
      Description:    Clase interna .
  --------------------------------------------------------------------------------------*/
  public class Request {
    /* objectName */
    @AuraEnabled
    public String objectName {get; set;}
    /* filterField */
    @AuraEnabled
    public String filterField {get; set;}
    /* searchString */
    @AuraEnabled
    public String searchString {get; set;}
    /* value */
    @AuraEnabled
    public String value {get; set;}
    /* queryFields */
    @AuraEnabled
    public String queryFields {get; set;}
  }

  /*--------------------------------------------------------------------------------------
      Company:        BBVA
      Description:    Clase interna .
  --------------------------------------------------------------------------------------*/
  public class Response {
    /* recordsDataList */
    @AuraEnabled
    public List<RecordsData> recordsDataList {get; set;}
    /* recordsDataList */
    @AuraEnabled
    public List<List<RecordsData>> rdListWFields {get; set;}
  }

  /*--------------------------------------------------------------------------------------
      Company:        BBVA
      Description:    Clase interna .
  --------------------------------------------------------------------------------------*/
  public class RecordsData {
    /* label */
    @AuraEnabled
    public String label {get; set;}
    /* value */
    @AuraEnabled
    public String value {get; set;}

    /*---------------------------------------------------------------------------------------
        Company:       BBVA
        Description:   constructor.
    ---------------------------------------------------------------------------------------*/
    public RecordsData(String label, String value) {
      this.label = label;
      this.value = value;
    }
  }
}