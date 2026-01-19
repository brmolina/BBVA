/**
 * @description       :
 * @author            : David Rodríguez
 * @group             :
 * @last modified on  : 05-05-2021
 * @last modified by  : David Rodríguez
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   04-14-2021   David Rodríguez   Initial Version
**/
public with sharing class MergeSelectAccountCnt {
  /**
  * SINGLETON PATTERN
  */
  private static MergeSelectAccountCnt instance;


  /**
  * Constructor
  */
  private MergeSelectAccountCnt() {
  }

  /**
  * getInstance
  */
  public static MergeSelectAccountCnt gtInstance() {
    if(instance == null) {
      instance = new MergeSelectAccountCnt();
    }
    return instance;
  }

  @AuraEnabled
  public static List <SObject> fetchLookUpValues(String searchKeyWord, String objectName, String fieldsToGet, String filter, String fieldToOrder) { //NOSONAR
    final List <sObject> returnList = new List <sObject> ();
    final String fieldsRet = getQueryFields(objectName, fieldsToGet, filter, fieldToOrder);

    List<List<SObject> > searchList = new List<List<SObject> >();
    try {
      String searchquery = 'FIND \'' + String.escapeSingleQuotes(searchKeyWord) + '\' IN NAME FIELDS RETURNING ' + fieldsRet;
      system.debug('** Query -->' + searchquery);

      searchList = search.query(searchquery);

      for(List<SObject> lObject : searchList) {
        system.debug(JSON.serialize(lObject));
        returnList.addAll(lObject);
      }
      return returnList;
    } catch (Exception e) {
      throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage()); //NOSONAR
    }
  }

  /*
    * Method to get data for report
    */
    @AuraEnabled
    public static String getData(String clientId, String country) {
      try {
        final List<Local_Client__c> lclients = new List<Local_Client__c>([
          SELECT Id, unique_id__c, Name, entity_id__c, g_residence_country_id__c, Alpha_code__c
          FROM Local_Client__c
          WHERE Cib_Client__c = :clientId
          AND g_residence_country_id__c = :country
          order by Name asc
        ]);

        final Schema.DescribeFieldResult fieldResult = Account.DES_Country_Client__c.getDescribe();
        final List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        final Map<String,String> mapValueLabel = new Map<String,String>();
        final List<WrapperTable> listWrapper = new List<WrapperTable>();
        for(Schema.PicklistEntry val : values) {
          mapValueLabel.put(val.getValue(), val.getLabel());
        }
        for(Local_Client__c lclient : lclients) {
          listWrapper.add(new WrapperTable(lclient.Id, lclient.Name, lclient.unique_id__c, mapValueLabel.get(lclient.g_residence_country_id__c), lclient.entity_id__c, lclient.Alpha_code__c));
        }
        system.debug('>>>>>listWrapper : ' + listWrapper);
        return JSON.serialize(listWrapper);
      } catch(Exception e) {
        throw new AuraHandledException(Label.DES_Error + e);
      }
    }

  private static String getQueryFields(String objectName, String fieldsToGet, String filter, String fieldToOrder) {
    String fieldsRet = '';
    String filterToApply = ' WHERE ' + filter;
    system.debug('**encrypted - ' + fieldToOrder);
    Boolean encrypted = false;
		if(fieldToOrder != null) {
      encrypted = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldToOrder)?.getDescribe().isEncrypted();
		}
    system.debug('**encrypted - ' + encrypted);
    fieldsRet = objectName + '('+ fieldsToGet + (!(filter == null || filter == '') ? filterToApply : '') + (encrypted || fieldToOrder == null ? ' LIMIT 100)' : ' ORDER BY ' + fieldToOrder + ' LIMIT 100)');
    system.debug('**fieldsRet - ' + fieldsRet);
    return fieldsRet;
  }

  /*
  * Wrapper to set data for report
  */
  public class WrapperTable {
    /*
    * Attributes for lName
    */
    private String lId; //NOSONAR
    /*
    * Attributes for lName
    */
    private String lName; //NOSONAR
    /*
    * Attributes for clientCode
    */
    private String clientCode; //NOSONAR
    /*
    * Attributes for country
    */
    private String country; //NOSONAR
    /*
    * Attributes for entity
    */
    private String entity; //NOSONAR
    /*
    * Attributes for entity
    */
    private String alpha; //NOSONAR
    /*
    * Constructor for Wrapper
    */
    public WrapperTable (String lId, String lName, String clientCode, String country, String entity, String alpha) {
      this.lId = lId;
      this.lName = lName;
      this.clientCode = clientCode;
      this.country = country;
      this.entity = entity;
      this.alpha = alpha;
    }
  }
}