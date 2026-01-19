/**********************************************************************************
* @author       Global Desktop
* @date         12/01/2021
* @description  Handler del trigger de LocalClient
**********************************************************************************/
public with sharing class LocalClientHandler {

  /**
  * SINGLETON PATTERN
  */
  private static LocalClientHandler instance;

  /**
  * Constructor
  */
  private LocalClientHandler() {
  }

  /**
  * getInstance
  */
  public static LocalClientHandler gtInstance() {
    if(instance == null) {
      instance = new LocalClientHandler();
    }
    return instance;
  }

  /**
  * @author Global Desktop
  * @Description Llevar el participant_name que viene informado al campo Name
  */
  public static void informName(List<Local_Client__c> triggerNew, Map<Id, Local_Client__c> oldMap) {
    for(Local_Client__c lclient : triggerNew) {
      if((oldMap == null && lclient.participant_name__c != null) ||
      (oldMap != null && lclient.participant_name__c != null && oldMap.get(lclient.Id).Name != lclient.participant_name__c)) {
        lclient.Name = lclient.participant_name__c;
      }
    }
  }


  /**
  * @author Global Desktop
  * @Description Genera el codigo Alpha para Arce
  */
  public static void insertAlphaCode(List<Local_Client__c> triggerNew) {
    for(Local_Client__c lclient : triggerNew) {
      System.debug('>>>>>>> insertAlphaCode' + lclient);
      if (lclient.country_id__c != null && lclient.unique_id__c != null) {
        lclient.Alpha_code__c = createAlphaCode(lclient.country_id__c, lclient.unique_id__c);
      }
    }
  }

  /**
  * @description
  * @author Global Desktop | 02-25-2021
  * @param country
  * @param countryGlobal
  * @param cclient
  * @param soloEntity
  * @return String
  **/
  private static String createAlphaCode(String country,  String  cclient) {
    String alphaCode = '';
    System.debug('>>>>>>> createAlphaCode country:' + country + ' cclient:' +  cclient);
    alphaCode=country;

    switch on country {
        when 'ES' {
            alphaCode+='0182';
        }
        when 'MX' {
            alphaCode+='0074';
        }
        when 'CO' {
            alphaCode+='0013';
        }
        when 'PE' {
            alphaCode+='0011';
        }
        when 'AR' {
            alphaCode+='0017';
        }
        when 'PY' {
            alphaCode+='7714';
        }
        when 'CH ' {
            alphaCode+='0069';
        }
        when 'BR' {
            alphaCode+='9120';
        }
    }

        alphaCode+=cclient.leftPad(9,'0');

    return alphaCode;
  }


}