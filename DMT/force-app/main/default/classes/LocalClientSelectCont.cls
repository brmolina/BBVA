/*
* Class controller for localClientSelect component
*/
@SuppressWarnings('sf:PreserveStackTrace')
public with sharing class LocalClientSelectCont {
  /** Constant for IFIS institution types metadata developer name */
  static final String IFIS_INSTITUTION_TYPES = 'IFIS_InstitutionTypes';
  /** Constant for IFIS RTC ALT institution type */
  static final String IFIS_RTC_ALT = 'IFIS-RTC-ALT';
  /** Constant for IFIS INV institution type */
  static final String IFIS_INV = 'IFIS-INV';

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

    // El picker de prospects devuelve el Id del Account.
    // Reutilizamos la lógica existente de gtCountries, que ya gestiona prospects.
    if (String.isNotBlank(clientCode)
        && (clientCode.length() == 15 || clientCode.length() == 18)
        && clientCode.startsWith('001')) {
      return gtCountries(clientCode);
    }

    /* Pendiente de modificar el country por el país de residencia cuando nos lo aprovisionen */
    final Set<String> countriesSet = new Set<String>{'ES','MX','CO','PE','AR','PY','CH'};
    final List<AggregateResult> localClients = new List<AggregateResult>([
      SELECT country_id__c, entity_id__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__r.g_customer_id__c = :clientCode AND country_id__c IN :countriesSet WITH SYSTEM_MODE GROUP BY country_id__c, entity_id__c
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
    // El picker de prospects devuelve el Id del Account.
    // Reutilizamos la lógica existente de gtClients, que ya gestiona prospects.
    if (String.isNotBlank(clientCode)
        && (clientCode.length() == 15 || clientCode.length() == 18)
        && clientCode.startsWith('001')) {
      return gtClients(clientCode, countryCode, null);
    }

    final List<Local_Client__c> localClients = new List<Local_Client__c>([
      SELECT Id, participant_name__c, entity_id__c, unique_id__c, Cib_Client__r.gf_data_institution_type_name__c, Cib_Client__r.DES_ID_Fiscal__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__r.g_customer_id__c = :clientCode AND country_id__c = :countryCode WITH SYSTEM_MODE ORDER BY Name desc
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
          localClients =[SELECT g_residence_country_id__c, entity_id__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__c = :clientCode AND entity_id__c IN :entitySet WITH SYSTEM_MODE GROUP BY g_residence_country_id__c, entity_id__c];
      } else if(getSObjectName(clientCode).equalsIgnoreCase('Local_Client__c')) {
          localClients =[SELECT g_residence_country_id__c, entity_id__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Id = :clientCode AND entity_id__c IN :entitySet WITH SYSTEM_MODE GROUP BY g_residence_country_id__c, entity_id__c];
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
        final String mdm = [SELECT local_customer_id__c from Local_Client__c where gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__c = :clientCode  AND entity_id__c IN :entityAllowed WITH SYSTEM_MODE LIMIT 1][0].local_customer_id__c;
        queryTo = 'SELECT Id, Alpha_code__c, participant_name__c, entity_id__c, unique_id__c, Cib_Client__r.gf_data_institution_type_name__c,gf_data_institution_type_name__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND local_customer_id__c = :mdm AND country_id__c = :countryCode WITH SYSTEM_MODE ORDER BY Name DESC';
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
      queryTo = 'SELECT Id, Cib_Client__r.DES_ID_Fiscal__c, Alpha_code__c, participant_name__c, entity_id__c, unique_id__c, Cib_Client__r.gf_data_institution_type_name__c, gf_data_institution_type_name__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Cib_Client__c = :clientCode AND country_id__c = :countryCode WITH SYSTEM_MODE ORDER BY Name DESC';
    } else if(getSObjectName(clientCode).equalsIgnoreCase('Local_Client__c')) {
      queryTo = 'SELECT Id, Cib_Client__r.DES_ID_Fiscal__c, Alpha_code__c, participant_name__c, entity_id__c, unique_id__c, Cib_Client__r.gf_data_institution_type_name__c, gf_data_institution_type_name__c FROM Local_Client__c WHERE gf_prtcpt_act_status_ind_type__c = true AND Id = :clientCode AND country_id__c = :countryCode WITH SYSTEM_MODE ORDER BY Name DESC';
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
          final List<Local_Client__c> listLc = [SELECT country_id__c from Local_Client__c where Cib_Client__c = :clientCode AND entity_id__c IN :entityAllowed WITH SYSTEM_MODE LIMIT 1 ];
          if(!listLc.isEmpty()) {
              country = listLc[0].country_id__c;
          }
      }
        return country;
    }

    /**
    * @description Call the rating system service.
    * @param clientId The Id of the account to evaluate.
    * @param selectedFlow The flow type (corporates/ifis).
    * @param bookingCountry The booking country code.
    * @param relationParentSubsidiaryId The parent subsidiary relation id.
    * @return ValidationResult with the rating system evaluation outcome.
    * @throws AuraHandledException if the service call fails.
    */
    @AuraEnabled
    public static Arc_Gen_RatingSystem_Service.ValidationResult callRatingSystem(Id clientId, String selectedFlow, String bookingCountry, String relationParentSubsidiaryId) {
        try {
            return Arc_Gen_RatingSystem_Service.callService(clientId, selectedFlow, bookingCountry, relationParentSubsidiaryId);
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
          final String ifisInstitutionType = getIfisInstitutionType(accWrapper.bankEntity);
          result.parentSubsidiary = accWrapper.parentSubsidiary;

          if ((accWrapper.parentSubsidiary == 'SUBSIDIARY' || accWrapper.parentSubsidiary == 'SUBGROUP')
              && !accWrapper.isProspect
              && ifisInstitutionType != IFIS_RTC_ALT
              && ifisInstitutionType != IFIS_INV) {
              final String response = getPSResponse(accWrapper.accNumber);
              result.relationParentSubsidiaryId = getRelationParentSubsidiaryId(response);
              if (result.relationParentSubsidiaryId == null) {
                  throw new AuraHandledException(System.Label.Arc_Gen_NoRelationIdPS);
              }
              result.isCoreRelation = '1'.equals(result.relationParentSubsidiaryId);
              result.isExpgAvailable = isExpgAvailable(response);
              result.isParent = false;
          } else if (!accWrapper.isProspect && (ifisInstitutionType == IFIS_RTC_ALT || ifisInstitutionType == IFIS_INV)) {
              result.isParent = accWrapper.parentSubsidiary == 'GROUP';
              result.relationParentSubsidiaryId = result.isParent ? '0' : null;
          } else if(!accWrapper.isProspect) {
                result.isCoreRelation = false;
                result.isExpgAvailable = false;
                result.isParent = true;
                result.relationParentSubsidiaryId = '0';
            }
          return result;
      } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, 'Error checking explicit guarantee availability: ' + e.getMessage());
          if (e instanceof AuraHandledException) {
              throw e;
          }
          throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError );
      }
  }

  /**
  * @description Call service to retrieve parent/subsidiary response.
  */
  @TestVisible
  private static String getPSResponse(String accNumber) {
      return (String) arce.Arc_Gen_GenericUtilities.callCallableService(
          'Arc_Gen_RetrievePS_Service',
          'getPSResponse',
          new Map<String, Object>{ 'accNumber' => accNumber }
      );
  }

  /**
  * @description Extract the relation parent subsidiary id from service response.
  */
  @TestVisible
  private static String getRelationParentSubsidiaryId(String response) {
      final Map<String, Object> relationPS = getRelationPSMap(response);
      return relationPS != null ? String.valueOf(relationPS.get('id')) : null;
  }

  /**
  * @description Parse the relationParentSubsidiary map from the first relation in the PS response.
  */
  private static Map<String, Object> getRelationPSMap(String response) {
      if (hasValidJsonResponse(response)) {
          final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
          final List<Object> relations = (List<Object>) responseMap.get('relations');
          if (relations != null && !relations.isEmpty()) {
              final Map<String, Object> firstRelation = (Map<String, Object>) relations[0];
              return (Map<String, Object>) firstRelation.get('relationParentSubsidiary');
          }
      }
      return null;
  }

  /**
  * @description Determine explicit guarantee availability from service response.
  */
  @TestVisible
  private static Boolean isExpgAvailable(String response) {
      Boolean isAvailable = false;

      if (hasValidJsonResponse(response)) {
        final arce__Overlay__c overlay = (arce__Overlay__c) arce.Arc_Gen_GenericUtilities.callCallableService(
          'Arc_Gen_RetrievePS_Service',
          'setQualitatives',
          new Map<String, Object>{
            'respStr' => response,
            'overlayObj' => new arce__Overlay__c()
          }
        );
        isAvailable = overlay != null && overlay.arce__Arc_Gen_explicit_guarantee__c == '1';
      }

      return isAvailable;
  }

  /**
  * @description Validates if a service response is valid JSON by attempting to deserialize it.
  */
  @TestVisible
  private static Boolean hasValidJsonResponse(String response) {
    Boolean isValid = false;

    if (String.isNotBlank(response)) {
      try {
        JSON.deserializeUntyped(response);
        isValid = true;
      } catch (JSONException e) {
        isValid = false;
      }
    }

    return isValid;
  }

  /**
  * @description Returns IFIS institution type key where bank entity is configured.
  */
  @TestVisible
  private static String getIfisInstitutionType(String bankEntity) {
      String institutionType;

      if (String.isNotBlank(bankEntity)) {
          try {
              final Map<String, arce__Service_persistence__mdt> configsByName = Arc_Gen_Persistence_Utils.getConfigurationInfo(
                  new List<String>{ IFIS_INSTITUTION_TYPES }
              );
              final arce__Service_persistence__mdt servicePersis = configsByName.get(IFIS_INSTITUTION_TYPES);

              if (servicePersis != null && String.isNotBlank(servicePersis.arce__JSON_input__c)) {
                  final Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(servicePersis.arce__JSON_input__c);
                  institutionType = findIfisInstitutionType(jsonMap, bankEntity);
              }
          } catch (Exception e) {
              System.debug(LoggingLevel.ERROR, 'Error retrieving IFIS institution type: ' + e.getMessage());
              throw new AuraHandledException(e.getMessage());
          }
      }

      return institutionType;
  }

  /**
  * @description Finds IFIS institution type key from metadata JSON map.
  */
  @TestVisible
  private static String findIfisInstitutionType(Map<String, Object> jsonMap, String bankEntity) {
      String institutionType;
      if (jsonMap != null) {
          for (String key : jsonMap.keySet()) {
              final List<Object> values = (List<Object>) jsonMap.get(key);
              if (values != null && values.contains(bankEntity)) {
                  institutionType = key;
                  break;
              }
          }
      }
      return institutionType;
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
      /** @description Guarantee explicit availability */
      @AuraEnabled
      public Boolean isExpgAvailable { get; set; }
      /** @description CORE status id */
      @AuraEnabled
      public Boolean isCoreRelation { get; set; }
      /** @description Whether the account is a parent group */
      @AuraEnabled
      public Boolean isParent { get; set; }
      /** @description Parent subsidiary type from account wrapper (GROUP/SUBSIDIARY/SUBGROUP) */
      @AuraEnabled
      public String parentSubsidiary { get; set; }
      /** @description Relation parent subsidiary id for rating system service */
      @AuraEnabled
      public String relationParentSubsidiaryId { get; set; }
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