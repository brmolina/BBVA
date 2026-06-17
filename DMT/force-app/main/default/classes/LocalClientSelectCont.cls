/*
* Class controller for localClientSelect component
*/
@SuppressWarnings('sf:PreserveStackTrace')
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
      SELECT country_id__c, entity_id__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__r.g_customer_id__c = :clientCode AND country_id__c IN :countriesSet GROUP BY country_id__c, entity_id__c
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
      SELECT Id, participant_name__c, entity_id__c, unique_id__c, Cib_Client__r.gf_data_institution_type_name__c, Cib_Client__r.DES_ID_Fiscal__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__r.g_customer_id__c = :clientCode AND country_id__c = :countryCode ORDER BY Name desc
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
      final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{ clientCode }).get(clientCode);
      if(getSObjectName(clientCode).equalsIgnoreCase('Account') && !accWrapper.isProspect) {
          localClients =[SELECT g_residence_country_id__c, entity_id__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__c = :clientCode AND entity_id__c IN :entitySet GROUP BY g_residence_country_id__c, entity_id__c];
      } else if(getSObjectName(clientCode).equalsIgnoreCase('Local_Client__c')) {
          localClients =[SELECT g_residence_country_id__c, entity_id__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Id = :clientCode AND entity_id__c IN :entitySet GROUP BY g_residence_country_id__c, entity_id__c];
      }

    
    final List<WrapperClass> listWrapper = new List<WrapperClass>();
    if (!accWrapper.isProspect) {
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
    } else {
      listWrapper.add(new WrapperClass(accWrapper.country, accWrapper.country, null));
    }
    return JSON.serialize(listWrapper);
  }

  /*
  * Method to get local clients related to global client
  */
  @AuraEnabled
  public static String gtClients(String clientCode, String countryCode, String entityType) {
      String queryTo;
      final List<WrapperClass> listWrapper = new List<WrapperClass>();
      final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{ clientCode }).get(clientCode);
      if (!accWrapper.isProspect) {
      if (entityType == 'ifis') {
          List<String> entityAllowed = new List<String>{'0182', '0074', '0013','0011','0017','7714','0069'};
        final String mdm = [SELECT local_customer_id__c from Local_Client__c where Cib_Client__c = :clientCode  AND entity_id__c IN :entityAllowed LIMIT 1][0].local_customer_id__c;
        queryTo = 'SELECT Id, Alpha_code__c, participant_name__c, entity_id__c, unique_id__c, Cib_Client__r.gf_data_institution_type_name__c,gf_data_institution_type_name__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND local_customer_id__c = :mdm AND country_id__c = :countryCode ORDER BY Name DESC';   
        } else {
          queryTo = getQueryString(clientCode, countryCode);
      }

     final List<Local_Client__c> localClients = Database.query(queryTo);
      for(Local_Client__c lclient : localClients) {
        if (lclient.entity_id__c != null && Integer.valueOf(lclient.entity_id__c) < 8908) {
          listWrapper.add(new WrapperClass(lclient.participant_name__c + ' - ' + lclient.Alpha_code__c, lclient.Id, lclient.gf_data_institution_type_name__c));
        }
     }
    } else {
    listWrapper.add(new WrapperClass(accWrapper.name + ' - ' + accWrapper.name, accWrapper.accId, '0011'));
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
    String country;
      List<String> entityAllowed = new List<String>{'0182', '0074', '0013','0011','0017','7714','0069'};
      final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{ clientCode }).get(clientCode);
      if (accWrapper.isProspect) {
          country = accWrapper.country;
      } else {
          final List<Local_Client__c> listLc = [SELECT country_id__c from Local_Client__c where Cib_Client__c = :clientCode AND entity_id__c IN :entityAllowed LIMIT 1];
          if(!listLc.isEmpty()) {
              country = listLc[0].country_id__c;
          }
      }
        return country;
    }

    /**
    * Call the rating system service
    */
    @AuraEnabled
    public static Arc_Gen_RatingSystem_Service.ValidationResult callRatingSystem(Id clientId, String selectedFlow, String bookingCountry) {
        try {
            return Arc_Gen_RatingSystem_Service.callService(clientId, selectedFlow, bookingCountry);
        } catch (Exception e) {
            final AuraHandledException auraException = new AuraHandledException(e.getMessage());
            auraException.setMessage(e.getStackTraceString());
            throw auraException;
        }
    }

     /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to check explicit guarantee availability and CORE/NO_CORE id from service
    * -----------------------------------------------------------------------------------------------
    * @autor       isabel.ascaso.tech@bbva.com
    * @date        10/04/2026
    * @param       clientId
    * @return      ExpgAvailabilityWrapper with garantee explicit availability and CORE status id
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static ExpgAvailabilityWrapper checkExpgAvailability(String clientId) {
        try {
            final ExpgAvailabilityWrapper result = new ExpgAvailabilityWrapper();
            final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> { clientId }).get(clientId);
            if ((accWrapper.parentSubsidiary == 'SUBSIDIARY' || accWrapper.parentSubsidiary == 'SUBGROUP') && !accWrapper.isProspect) {
                final String response = getPSResponse(accWrapper.accNumber);
                result.isCoreRelation = isCoreRelation(response);
                result.isExpgAvailable = isExpgAvailable(response);
                result.isParent = false;
            } else if(!accWrapper.isProspect) {
                result.isCoreRelation = false;
                result.isExpgAvailable = false;
                result.isParent = true;
            }
            return result;
        } catch (Exception e) {
            System.debug('Error checking explicit guarantee availability: ' + e.getStackTraceString());
            System.debug('Error checking explicit guarantee availability: ' + e.getMessage());
            if (e instanceof AuraHandledException) {
                throw e;
            }
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError );
        }
    }


    /**
    * @description Call service to retrieve parent/subsidiary response.
    */
    private static String getPSResponse(String accNumber) {
        return (String) arce.Arc_Gen_GenericUtilities.callCallableService(
            'Arc_Gen_RetrievePS_Service',
            'getPSResponse',
            new Map<String, Object>{ 'accNumber' => accNumber }
        );
    }

    /**
    * @description Determine if relation id corresponds to CORE.
    */
    private static Boolean isCoreRelation(String response) {
        Boolean isCore = false;
        if (String.isNotBlank(response)) {
            final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
            final List<Object> relations = (List<Object>) responseMap.get('relations');
            if (relations != null && !relations.isEmpty()) {
                final Map<String, Object> firstRelation = (Map<String, Object>) relations[0];
                final Map<String, Object> relationPS = (Map<String, Object>) firstRelation.get('relationParentSubsidiary');
                isCore = relationPS != null && String.valueOf(relationPS.get('id')) == '1';
            }
        }
        return isCore;
    }

    /**
    * @description Determine explicit guarantee availability from service response.
    */
    private static Boolean isExpgAvailable(String response) {
        final arce__Overlay__c overlay = (arce__Overlay__c) arce.Arc_Gen_GenericUtilities.callCallableService(
            'Arc_Gen_RetrievePS_Service',
            'setQualitatives',
            new Map<String, Object>{
                'respStr' => response,
                'overlayObj' => new arce__Overlay__c()
            }
        );
        return overlay != null && overlay.arce__Arc_Gen_explicit_guarantee__c == '1';
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

  /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper class for guarantee explicit availability and CORE status id
    * -----------------------------------------------------------------------------------------------
    * @autor       isabel.ascaso.tech@bbva.com
    * @date        10/04/2026
    * @param       none
    * @return      none
    * -----------------------------------------------------------------------------------------------
    **/
    public class ExpgAvailabilityWrapper {
        @AuraEnabled
        /**
        * @description: Guarantee explicit availability
        */
        public Boolean isExpgAvailable { get; set; }
        /**
        * @description: CORE status id
        */
        @AuraEnabled
        public Boolean isCoreRelation { get; set; }
        /**
        * @description: isParent
        */
        @AuraEnabled
        public Boolean isParent { get; set; }
    }

}