/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: FilteredLookUpController
*   @Description:


*   @Versions:
        v1 - 2019/02/XX - Initial version
******************************************************************************************************************************************************/
public with sharing class FilteredLookUpController {

  /**
   * SINGLETON PATTERN
   */
  private static FilteredLookUpController instance;

  /**
   * Constructor
   */
  private FilteredLookUpController() {
  }

  /**
   * getInstance
   */
  public static FilteredLookUpController gtInstance() {
    if (instance == null) {
      instance = new FilteredLookUpController();
    }
    return instance;
  }


  /**
   * fetchLookUpValuesEmail
   */
  @AuraEnabled
  public static List <sObject> fetchLookUpValuesEmail(String searchKeyWord, String objectName) {
    try {
      System.debug('::::::fetchLookUpValuesEmail con filtro init:');
      final String lazyKeyword = searchKeyWord.replaceAll(' ', '%');
      final String searchKey = '%' + lazyKeyword + '%';
      String filterContractor;
      filterContractor = '%.contractor@%';
      String filterBecas;
      filterBecas = '%.becas@%';
      final List <sObject> returnList = new List <sObject> ();
      // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5
      String sQuery;
      if(objectName == Label.DES_User) {
        sQuery =  Label.DES_SelectIdName + ' ' + objectName +
                 +' WHERE isActive = true AND Name LIKE :searchKey AND (NOT Username  LIKE :filterContractor) AND (NOT Username  LIKE :filterBecas) ' +
                 +Label.DES_OrderCreatedDate + ' '
                 + Label.DES_Limit5
        ;
      } else {
        sQuery =  Label.DES_SelectIdName + ' ' + objectName +
                 +' WHERE Name = :searchKeyWord ' +
                 +Label.DES_OrderCreatedDate + ' '
                 + Label.DES_Limit5
        ;
      }
      system.debug('searchKey1' + searchKey);
      system.debug('filterContractor1' + filterContractor);
      system.debug('filterBecas1' + filterBecas);
      final List <sObject> lstOfRecords = Database.query(String.escapeSingleQuotes(sQuery));
      returnList.addAll(lstOfRecords);
      return returnList;
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /**
   * fetchLookUpValuesFamily
   */
  @AuraEnabled
  public static List <sObject> fetchLookUpValuesFamily(String searchKeyWord, String objectName, String strFilter) {
    try {
      System.debug('::::::fetchLookUpValuesFamily init:');
      final String lazyKeyword = searchKeyWord.replaceAll(' ', '%');
      final String searchKey = '%' + lazyKeyword + '%';
      final List <sObject> returnList = new List <sObject> ();
      // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5
      String sQuery;
      if(objectName == Label.DES_Product2 && !String.isBlank(strFilter)) {
        sQuery =  Label.DES_SelectIdName + ' ' + objectName
                 + ' WHERE Name LIKE :searchKey AND (Family = :strFilter) '
                 + Label.DES_OrderCreatedDate + ' '
                 + Label.DES_Limit5
        ;
      } else {
        sQuery =  Label.DES_SelectIdName + ' ' + objectName +
                 +' WHERE Name LIKE :searchKey '
                 + Label.DES_OrderCreatedDate + ' '
                 + Label.DES_Limit5
        ;
      }

      system.debug('searchKey2' + searchKey);
      final List <sObject> lstOfRecords = Database.query(String.escapeSingleQuotes(sQuery));
      returnList.addAll(lstOfRecords);
      return returnList;
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /**
   * fetchLookUpValuesFamily
   */
   @AuraEnabled
    public static List <sObject> fetchLookUpValuesDisclosure(String searchKeyWord, String objectName, String strFilter) {
        try {
            System.debug('::::::fetchLookUpValuesDisclosure init:');
            final List <sObject> returnList = new List <sObject> ();
            // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5
            String sQuery;
            if(objectName == Label.Opportunity_Name && !String.isBlank(strFilter)) {
                sQuery = Label.DES_SelectIdName + ' ' + objectName
                    + ' WHERE Name = :searchKeyWord AND (disclosure_info_type__c = :strFilter) '
                    + Label.DES_OrderCreatedDate + ' '
                    + Label.DES_Limit5
                    ;
            } else {
                sQuery =  Label.DES_SelectIdName + ' ' + objectName +
                    + ' WHERE Name = :searchKeyWord '
                    + Label.DES_OrderCreatedDate + ' '
                    + Label.DES_Limit5
                    ;
            }

            system.debug('searchKeyWord3' + searchKeyWord);
            final List <sObject> lstOfRecords = Database.query(String.escapeSingleQuotes(sQuery));
            returnList.addAll(lstOfRecords);
            return returnList;
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_Error + e);
        }
    }

  /**
   * fetchLookUpValuesFamily
   */
  @AuraEnabled
  public static sObject getLookupValue(String objectName, String objectRecordId) {
    try {
      System.debug('Valor de objectRecordId: ' +objectRecordId);

      SObject returnObject;
      if(objectName == Label.DES_Contact) {
        final String sQuery = 'SELECT id, Name, Owner.Name, OwnerId, AccountId FROM ' + objectName +
                              +' WHERE Id = :objectRecordId LIMIT 1';
        returnObject = Database.query(String.escapeSingleQuotes(sQuery));

      } else {

        final User userInfo = [SELECT Name, Id
                               FROM User
                               WHERE id = :UserInfo.getUserId() AND (NOT Email LIKE '%contractor@%') AND (NOT Email LIKE '%becas@%') LIMIT 1];

        returnObject = userInfo;
      }


      System.debug('Valor de returnObject: ' + returnObject);
      return returnObject;
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }

  }

  /**
   * getRelatedAccount
   */
  @AuraEnabled
  public static sObject getRelatedAccount(String objectName, String objectRecordId) {
    try {
      SObject returnObject;
      String sQuery;
      System.debug(':ct ' + objectName + ' - ' + objectRecordId);
      if(objectName == Label.DES_Contact) {
                /** Contact relatedCon = [SELECT id, Name, AccountId, Account.Name FROM Contact WHERE id = :objectRecordId LIMIT 1]; */
                // returnObject = relatedCon;
        sQuery = 'SELECT id, Name, AccountId, Account.Name FROM Contact WHERE id = :objectRecordId LIMIT 1';
        returnObject = Database.query(String.escapeSingleQuotes(sQuery));
      } else {
                /** Account relatedAcc = [SELECT Id, Name FROM Account WHERE id = :objectRecordId LIMIT 1]; */
                // returnObject = relatedAcc;
        sQuery = 'SELECT Id, Name FROM Account WHERE id = :objectRecordId LIMIT 1';
        returnObject = Database.query(String.escapeSingleQuotes(sQuery));
      }
      return returnObject;
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

}