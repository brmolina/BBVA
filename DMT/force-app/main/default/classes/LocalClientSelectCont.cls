/*
* Class controller for localClientSelect component
*/
public with sharing class LocalClientSelectCont {

  /**
  * SINGLETON PATTERN
  */
  private static LocalClientSelectCont instance;

  /**
  * Constructor
  */
  private LocalClientSelectCont() {
  }

  /**
  * getInstance
  */
  public static LocalClientSelectCont gtInstance() {
    if(instance == null) {
      instance = new LocalClientSelectCont();
    }
    return instance;
  }

  /*
  * Method to get countries of local clients related to global client. Cacheable porque se llama con wire
  */
  @AuraEnabled(cacheable=true)
  public static String gtLocalCountries(String clientCode) {
      System.debug('::::: ClientCode ---> ' + clientCode);
    /* Pendiente de modificar el country por el país de residencia cuando nos lo aprovisionen */
    final Set<String> countriesSet = new Set<String>{'ES','MX','CO','PE','AR','PY','CH'};
    final List<AggregateResult> localClients = new List<AggregateResult>([
      SELECT country_id__c, entity_id__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__r.SER_CClient__c = :clientCode AND country_id__c IN :countriesSet GROUP BY country_id__c, entity_id__c
    ]);

    final Schema.DescribeFieldResult fieldResult = Account.DES_Country_Client__c.getDescribe();
    final List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
    final Map<String,String> mapValueLabel = new Map<String,String>();
    for( Schema.PicklistEntry v : values) {
      mapValueLabel.put(v.getValue(),v.getLabel());
    }

    final List<WrapperClass> listWrapper = new List<WrapperClass>();
    for (AggregateResult gsm : localClients) {
      String labelCountry;
      switch on String.valueOf(gsm.get('country_id__c')) {
        when 'ES' {
          labelCountry = 'ES (BBVA SA)';
        }
        when 'MX' {
          labelCountry = 'MX (Bancomer)';
        }
        when 'CO' {
          labelCountry = 'CO (BBVA Colombia)';
        }
        when 'PE' {
          labelCountry = 'PE (BBVA Perú)';
        }
        when 'AR' {
          labelCountry = 'AR (BBVA Argentina)';
        }
        when 'PY' {
          labelCountry = 'PY (BBVA Paraguay)';
        }
        when 'CH' {
          labelCountry = 'CH (Forum Chile)';
        }
        when else {
          labelCountry = mapValueLabel.get(String.valueOf(gsm.get('country_id__c')));
        }
      }
      if (gsm.get('entity_id__c') != null && Integer.valueOf(gsm.get('entity_id__c')) < 9000) {
        listWrapper.add(new WrapperClass(labelCountry, String.valueOf(gsm.get('country_id__c')), null));
      }
    }
    return JSON.serialize(listWrapper);
  }



  /*
  * Method to get local clients related to global client
  */
  @AuraEnabled
  public static String gtLocalClients(String clientCode, String countryCode) {
    final List<Local_Client__c> localClients = new List<Local_Client__c>([
      SELECT Id, participant_name__c, entity_id__c, unique_id__c, Cib_Client__r.gf_data_institution_type_name__c, Cib_Client__r.DES_ID_Fiscal__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__r.SER_CClient__c = :clientCode AND country_id__c = :countryCode ORDER BY Name desc
    ]);


    final List<WrapperClass> listWrapper = new List<WrapperClass>();
    for(Local_Client__c lclient : localClients) {
      if (lclient.entity_id__c != null && Integer.valueOf(lclient.entity_id__c) < 8908) {
        listWrapper.add(new WrapperClass(
          lclient.unique_id__c + ' - ' + lclient.participant_name__c + ' - ' + lclient.Cib_Client__r.DES_ID_Fiscal__c,
          lclient.Id, lclient.Cib_Client__r.gf_data_institution_type_name__c
        ));
      }
    }

    return JSON.serialize(listWrapper);
  }

        /*
  * Method to get countries of local clients related to global client. Cacheable porque se llama con wire
  */
  @AuraEnabled(cacheable=true)
  public static String gtCountries(String clientCode) {
    final Set<String> entitySet = new Set<String>{'0182','0074','0013','0011','0017','7714','0069'};
    List<AggregateResult> localClients = new List<AggregateResult>();
      if(getSObjectName(clientCode).equalsIgnoreCase('Account')) {
          localClients =[SELECT g_residence_country_id__c, entity_id__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__c = :clientCode AND entity_id__c IN :entitySet GROUP BY g_residence_country_id__c, entity_id__c];
      } else if(getSObjectName(clientCode).equalsIgnoreCase('Local_Client__c')) {
          localClients =[SELECT g_residence_country_id__c, entity_id__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Id = :clientCode AND entity_id__c IN :entitySet GROUP BY g_residence_country_id__c, entity_id__c];
      }

    
    final List<WrapperClass> listWrapper = new List<WrapperClass>();
    for (AggregateResult gsm : localClients) {
      String labelCountry;
      switch on String.valueOf(gsm.get('entity_id__c')) {
        when '0182' {
          labelCountry = 'ES (BBVA SA)';
        }
        when '0074' {
          labelCountry = 'MX (Bancomer)';
        }
        when '0013' {
          labelCountry = 'CO (BBVA Colombia)';
        }
        when '0011' {
          labelCountry = 'PE (BBVA Perú)';
        }
        when '0017' {
          labelCountry = 'AR (BBVA Argentina)';
        }
        when '7714' {
          labelCountry = 'PY (BBVA Paraguay)';
        }
        when '0069' {
          labelCountry = 'CH (Forum Chile)';
        }
      }
      if (gsm.get('entity_id__c') != null && Integer.valueOf(gsm.get('entity_id__c')) < 9000) {
        listWrapper.add(new WrapperClass(labelCountry, labelCountry.left(2), null));
      }
    }
    return JSON.serialize(listWrapper);
  }

  /*
  * Method to get local clients related to global client
  */
  @AuraEnabled
  public static String gtClients(String clientCode, String countryCode, String entityType) {
      String queryTo;
      if (entityType == 'ifis') {
          List<String> entityAllowed = new List<String>{'0182', '0074', '0013','0011','0017','7714','0069'};
        final String mdm = [SELECT local_customer_id__c from Local_Client__c where Cib_Client__c = :clientCode  AND entity_id__c IN :entityAllowed LIMIT 1][0].local_customer_id__c;
        queryTo = 'SELECT Id, Alpha_code__c, participant_name__c, entity_id__c, unique_id__c,  gf_data_institution_type_name__c, Cib_Client__r.DES_ID_Fiscal__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND local_customer_id__c = :mdm AND country_id__c = :countryCode ORDER BY Name DESC';     
        } else {
          queryTo = getQueryString(clientCode, countryCode);
      }

    final List<Local_Client__c> localClients = Database.query(queryTo);

    final List<WrapperClass> listWrapper = new List<WrapperClass>();
    for(Local_Client__c lclient : localClients) {
      if (lclient.entity_id__c != null && Integer.valueOf(lclient.entity_id__c) < 8908) {
        listWrapper.add(new WrapperClass(
          lclient.participant_name__c + ' - ' + lclient.Alpha_code__c + ' - ' + lclient.Cib_Client__r.DES_ID_Fiscal__c,
          lclient.Id, lclient.gf_data_institution_type_name__c
        ));
      }
    }

    return JSON.serialize(listWrapper);
  }

  /*
  * Method that returns sobject name by Id
  */
  @AuraEnabled
  public static String getSObjectName(String clientCode) {
    Id clientId = (Id) clientCode;
    return (String) clientId.getSObjectType().getDescribe().getName();
  }

  /*
  * Method that returns sobject name by Id
  */
  @AuraEnabled
  public static String getQueryString(String clientCode, String countryCode) { 
    String queryTo;
    final String objectName = getSObjectName(clientCode);
    if(getSObjectName(clientCode).equalsIgnoreCase('Account')) {
      queryTo = 'SELECT Id, Cib_Client__r.DES_ID_Fiscal__c, Alpha_code__c, participant_name__c, entity_id__c, unique_id__c, Cib_Client__r.gf_data_institution_type_name__c, gf_data_institution_type_name__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__c = :clientCode AND country_id__c = :countryCode ORDER BY Name DESC';
    } else if(getSObjectName(clientCode).equalsIgnoreCase('Local_Client__c')) {
      queryTo = 'SELECT Id, Cib_Client__r.DES_ID_Fiscal__c, Alpha_code__c, participant_name__c, entity_id__c, unique_id__c, Cib_Client__r.gf_data_institution_type_name__c, gf_data_institution_type_name__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Id = :clientCode AND country_id__c = :countryCode ORDER BY Name DESC';
    }
    return queryTo;
  }

  /*
  * Method to get local clients related to global client
  */
  @AuraEnabled
  public static String mainCntry(String clientCode) {
      List<String> entityAllowed = new List<String>{'0182', '0074', '0013','0011','0017','7714','0069'};
      return [SELECT id, country_id__c from Local_Client__c where Cib_Client__c = :clientCode AND entity_id__c IN :entityAllowed LIMIT 1][0].country_id__c;
  }

  /*
  * @author Global Desktop
  * @description construye la lista wrapper que devuelve la informacion al componente lightning
  */
  public class WrapperClass {

    //Nombre de la matrix
    private String localName; //NOSONAR

    //URL de la matriz
    private String localId; //NOSONAR

     /**
    * Bank entity
    */
    private String bankEntity; //NOSONAR

    /**
    * @author Global Desktop
    * @description Construye la clase wrapper
    */

    public WrapperClass(String nameIn, String idIn, String bankEntityIn) {
      this.localName = nameIn;
      this.localId = idIn;
      this.bankEntity = bankEntityIn;
    }
  }

}