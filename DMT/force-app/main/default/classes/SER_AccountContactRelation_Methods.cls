/**********************************************************************************
* @author       Accenture
* @date         01/07/2017
* @description  Handler para el trigger SER_AccountContactRelation_TRIGGER.
* @Revision
    2018/08/06 Se modifica esta clase para arreglar un problema con las cargas
    masivas de migracion de datos del proyecto DESKTOP que provocaba que se
    sobrepasaba un límite de Salesforce
**********************************************************************************/
public with sharing class SER_AccountContactRelation_Methods {
  /**Business Case Type GTB*/
  public static final String INSERTEVENT = 'insert';
  /**Business Case Type GTB*/
  public static final String DELETEEVENT = 'delete';

  private SER_AccountContactRelation_Methods() {}


  /*------------------------------------------------------
    Author:        Accenture
    Description:   manageRelatedContactClientNumber

    History:
    <Date>          <Author>                <Description>
    01/07/2017      Accenture               Initial version
  --------------------------------------------------------*/
  public static void manageRelatedContactClientNumber(Map<Id,AccountContactRelation> tgrMap, String event) {
    final Set<Id> setContactId = new Set<Id>();
    for(AccountContactRelation itemACR : tgrMap.valueS()) {
      final boolean blContactId = itemACR.ContactId!=null && !setContactId.contains(itemACR.ContactId);
      if(blContactId) {
        setContactId.add(itemACR.ContactId);
      }
    }
    if(!setContactId.isEmpty()) {
      Map<Id,Integer> mapContClieRSNum; //map_Contact_ClientRelationshipsNumber
      mapContClieRSNum = new Map<Id,Integer>();
      if(event.equalsIgnoreCase(INSERTEVENT)) {
        isInsert(mapContClieRSNum,setContactId);
      } else if(event.equalsIgnoreCase(DELETEEVENT)) {
        isDelete(mapContClieRSNum,tgrMap);
      }
      if(!mapContClieRSNum.isEmpty()) {
        List<Contact> listContaToUpd;
        listContaToUpd = new List<Contact>();
        for(Id itemCTID : mapContClieRSNum.keyset()) {
          listContaToUpd.add(new Contact(Id = itemCTID, SER_Related_Accounts__c = mapContClieRSNum.get(itemCTID)));
        }
        if(!listContaToUpd.isEmpty()) {
            update listContaToUpd;
        }
      }
    }
  }
  private static void isInsert(Map<Id,Integer> mapContClieRSNum, Set<Id> setContactId) {
    for(AccountContactRelation itemACR : [select Id, ContactId from AccountContactRelation where ContactId in :setContactId]) {
      if(mapContClieRSNum.containskey(itemACR.ContactId)) {
        mapContClieRSNum.put(itemACR.ContactId, mapContClieRSNum.get(itemACR.ContactId)+1);
      } else {
        mapContClieRSNum.put(itemACR.ContactId, 1);
      }
    }
  }
  private static void isDelete(Map<Id,Integer> mapContClieRSNum, Map<Id,AccountContactRelation> tgrMap) {
    for(AccountContactRelation itemACR : [select Id, ContactId, Contact.SER_Related_Accounts__c from AccountContactRelation where Id IN : tgrMap.KeySet()]) {
          if(mapContClieRSNum.containskey(itemACR.ContactId)) {
            mapContClieRSNum.put(itemACR.ContactId, mapContClieRSNum.get(itemACR.ContactId) - 1);
          } else {
            mapContClieRSNum.put(itemACR.ContactId, Integer.valueOf(itemACR.Contact.SER_Related_Accounts__c) - 1);
          }
        }
  }
  /****************************************************************************************************
  *   @author: GlobalDesktop - APC
  *   @Method: updateContactScope
  *   @Description: calls to Desktop_Utils.manageContactScope to populate contact.scope

  *   @Params: newList< AccountContactRelation > - after insert (not update or delete, business reasons)
  *   @Versions:
        v1 - 2019/01/23 - Initial version
  ********************************************************************************************************/
  public static void updateContactScope(List<AccountContactRelation> lstACR) {
    if(!lstACR.isEmpty()) {
      ContactScopeManagement.manageContactScope(lstACR);
    }
  }
}