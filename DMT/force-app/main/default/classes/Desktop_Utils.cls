/**
* @author GlobalDesktop
*/
public with sharing class Desktop_Utils { //NOSONAR

    /*SINGLETON PATTERN  **/
    private static Desktop_Utils instance;
    /*
     * @author Global Desktop
    **/
    public static final Id RTVISITCONF = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(Label.DES_RT_VISIT_Account_Confidential_Visit).getRecordTypeId();
    /*
     * @author Global Desktop
    **/
    public static final Id RTOPPCONF = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId();
    /*
     * @author Global Desktop
    **/
    public static final Id RTOPPCONFGM = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_SalesGM_Confidential_Opp).getRecordTypeId();
    /*
     * @author Global Desktop
    **/
    public static List <DES_BBVA_Management_team__c> listaDeDuplicados = new List <DES_BBVA_Management_team__c>(); //NOSONAR
    /*
     * @author Global Desktop
    **/
    public static List <String> listaDeDuplicadosBorrados = new List <String>(); //NOSONAR
    /*
     * @author Global Desktop
    **/
    public static Boolean existError = false; //NOSONAR
    /*
     * @author Global Desktop
    **/
	public static Map<String, String> mapCountryTemplateName = new Map<String, String>(); //NOSONAR
    /*Metdo1*/
	public static List<almd__Commercial_Alert__Share> alertShareToInsert= new List<almd__Commercial_Alert__Share>(); //NOSONAR
    /*Metdo2*/
	public static List<almd__Commercial_Alert__Share> alertShareToDelete = new List<almd__Commercial_Alert__Share>(); //NOSONAR
    /*Metdo3*/
	public static Set <String> invalidAlertsSet = new Set <String>(); //NOSONAR
    /*Metdo4*/
    public static List<ConnectApi.BatchInput> batchFeedItemInputs = new List<ConnectApi.BatchInput>(); //NOSONAR
    /*
     * @author Global Desktop
    **/
    public static final String ABREPAR = '{';
    /*
     * @author Global Desktop
    **/
    public static String profileName;
    /*
     * @author Global Desktop
    **/
    public static final String FINVSTSTS = '06';
    /*
     *
     *
     **/
    public static List<DES_Opportunity_Management_member__c> listMiembrosDuplicados = new List<DES_Opportunity_Management_member__c>();//NOSONAR

    private Desktop_Utils() {
        //this.logic = new ActivitiesUtils();
    }

    /*
     *
     * @author Global Desktop
     *
    **/
    public static Desktop_Utils getInstance() {//NOSONAR
        if (instance == null) {
            instance = new Desktop_Utils();
        }
        return instance;
    }

    /*
     *  @author Global Desktop  -   DSL
     *  @Description    Esta función devuelve los milisegundos desde la fecha '1-1-1970' hasta la fecha actual
     *                  Usar esta función para generar numeros random de campos únicos
     *
    **/
    public String getRandNumber() { //NOSONAR
        return String.valueof((Math.random()*100).round()) + System.now().getTime().format().replaceAll(',', '');
    }

    /*
     * Get profile Name
    */
    public String getProfileName() { //NOSONAR
        if(profileName == null) {
            profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].get(0).Name;
        }
        return profileName;
    }

    /*
     *
     * @author Global Desktop
     *
    **/
    public almd__Commercial_Alert__Share newManualSharingCommercialAlert(Id recordId, Id userOrGroupId, String accessType) { //NOSONAR
        //List<DES_Commercial_Alert__Share> listComAlertShare = new List<DES_Commercial_Alert__Share>();
        // Creo un registro del sharing object de commercial alert
        final almd__Commercial_Alert__Share comAlertShare  = new almd__Commercial_Alert__Share();
        // Vinculo el registro que quiero compartir
        comAlertShare.ParentId = recordId;
        // Vinculo el usuario/grupo con el que lo quiero compartir
        comAlertShare.UserOrGroupId = userOrGroupId;
        // Indico el nivel de acceso
        comAlertShare.AccessLevel = accessType;
        // Indico que es un share manual
        comAlertShare.RowCause = Schema.almd__Commercial_Alert__Share.RowCause.Manual;
        return comAlertShare;
        //listComAlertShare.add(comAlertShare);

    }

    /*
     *
     * @author Global Desktop
     *
    **/
    public dwp_kitv__Visit__Share newManualSharingVisit(Id recordId, Id userOrGroupId, String accessType) { //NOSONAR
        // Creo un registro del sharing object de commercial alert
        final dwp_kitv__Visit__Share visitShare  = new dwp_kitv__Visit__Share();
        // Vinculo el registro que quiero compartir
        visitShare.ParentId = recordId;
        // Vinculo el usuario/grupo con el que lo quiero compartir
        visitShare.UserOrGroupId = userOrGroupId;
        // Indico el nivel de acceso
        visitShare.AccessLevel = accessType;
        // Indico que es un share manual
        visitShare.RowCause = Schema.dwp_kitv__Visit__Share.RowCause.Manual;
        return visitShare;
        // IMPORTANTE: INSERTAR ASÍ: Database.SaveResult sr = Database.insert(visitShare,false);
    }


    /*
     *
     * @author Global Desktop
     * Funcion que devuelve un mapa con el Id de la cuenta como key y una concatenacion de los id's de los usuarios que forman parte del equipo de la cuenta
     * recibiendo como parámetro un set de las id's de las cuentas
    **/
    public Map<Id, String> getMapAccountAndMembers(Set<Id> setAccountIds) { //NOSONAR
        Map<Id, String> mapAccAndMembs;
        mapAccAndMembs = new Map<Id, String>();
        for(AccountTeamMember acctm : [SELECT Id, AccountId, UserId FROM AccountTeamMember WHERE AccountId IN :setAccountIds]) {
            if(mapAccAndMembs.get(acctm.AccountId) == null) {
            	mapAccAndMembs.put(acctm.AccountId, (String)acctm.UserId);
            } else {
            	mapAccAndMembs.put(acctm.AccountId, mapAccAndMembs.get(acctm.AccountId) + ';' + acctm.UserId);
            }
        }

        return mapAccAndMembs;
    }

    /*
     *
     * @author Global Desktop
     * Funcion que devuelve un mapa con el Id de la cuenta como key y una lista de DES_BBVA_Management_team__c pertenecientes al grupo
     * recibiendo como parámetro un set de las id's de las cuentas
    **/
    public Map<Id, List<DES_BBVA_Management_team__c>> getMapAccountAndMembersInfo(Set<Id> setAccountIds) { //NOSONAR
        System.debug('Set de Accounts ------> ' + setAccountIds);

        Map<Id, List<DES_BBVA_Management_team__c>> mapAccAndMembs;
        mapAccAndMembs = new Map<Id, List<DES_BBVA_Management_team__c>>();

        for(DES_BBVA_Management_team__c acctm : [SELECT Id, DES_Client__c, DES_User__c,DES_Member_Role__c,DES_Local_Banker_Country__c FROM DES_BBVA_Management_team__c WHERE DES_Client__c IN :setAccountIds]) {
            if(mapAccAndMembs.containsKey(acctm.DES_Client__c)) {
                final List<DES_BBVA_Management_team__c> membersInfo = mapAccAndMembs.get(acctm.DES_Client__c);
                membersInfo.add(acctm);
                mapAccAndMembs.put(acctm.DES_Client__c, membersInfo);
            } else {
                mapAccAndMembs.put(acctm.DES_Client__c, new List<DES_BBVA_Management_team__c> { acctm });
            }
        }

        return mapAccAndMembs;
    }

    /*
     *
     * @author Global Desktop
     * Funcion que devuelve un mapa con la relacion de cliente-grupo, en la key tiene el id del cliente y en el value tiene el id del grupo
    **/
    public Map<Id, Id> getMapClientGroup(Set<Id> setIdClients) { //NOSONAR
        final Map<Id, Id> mapClientGroups= new Map<Id, Id>();

        for(DES_Subsidiary_Group_Relation__c matrix : [SELECT Id, participant_parent_id__c, participant_child_id__c FROM DES_Subsidiary_Group_Relation__c WHERE participant_child_id__c IN :setIdClients AND main_subsidiary_ind_type__c = true]) {
            if(mapClientGroups.get(matrix.participant_child_id__c) == null) {
                mapClientGroups.put(matrix.participant_child_id__c, matrix.participant_parent_id__c);
            }
        }

        return mapClientGroups;
    }
    /*
     *
     * @author Global Desktop
     * Funcion que devuelve un mapa con la relacion de cliente-grupo, en la key tiene el id del cliente y en el value tiene el id del grupo
    **/
    public OpportunityShare newManualSharingOpportunity(Id recordId, Id userOrGroupId, String accessType) { //NOSONAR
        //List<DES_Commercial_Alert__Share> listComAlertShare = new List<DES_Commercial_Alert__Share>();
        // Creo un registro del sharing object de commercial alert
        final OpportunityShare oppShare  = new OpportunityShare();
        // Vinculo el registro que quiero compartir
        oppShare.OpportunityId = recordId;
        // Vinculo el usuario/grupo con el que lo quiero compartir
        oppShare.UserOrGroupId = userOrGroupId;
        // Indico el nivel de acceso
        oppShare.OpportunityAccessLevel = accessType;
        // Indico que es un share manual
        oppShare.RowCause = Schema.OpportunityShare.RowCause.Manual;
        return oppShare;
        //listComAlertShare.add(comAlertShare);

    }

     /*
     *
     * @author Global Desktop
     * Funcion que devuelve un registro de tipo dwp_kitv__Visit__Share
    **/
    public dwp_kitv__Visit__Share newManualSharingVisits(Id recordId, Id userOrGroupId, String accessType) { //NOSONAR

        // Creo un registro del sharing object de Visitas
        final dwp_kitv__Visit__Share visitShare  = new dwp_kitv__Visit__Share();
        // Vinculo el registro que quiero compartir
        visitShare.ParentId = recordId;
        // Vinculo el usuario/grupo con el que lo quiero compartir
        visitShare.UserOrGroupId = userOrGroupId;
        // Indico el nivel de acceso
        visitShare.AccessLevel = accessType;
        // Indico que es un share manual
        visitShare.RowCause = Schema.OpportunityShare.RowCause.Manual;

        return visitShare;

    }

    /*
     *
     * @author Global Desktop
     * Funcion que devuelve un mapa con la relacion de cliente-grupo, en la key tiene el id del cliente y en el value tiene el id del grupo
    **/
    public static void setMapCountryTemplateName() {
		if(mapCountryTemplateName.isEmpty()) {
			for(Opp_Countries__mdt countryRegMDT : [SELECT Id, Template_Name_Region__c,  MasterLabel, DeveloperName FROM Opp_Countries__mdt LIMIT 5000]) {
				mapCountryTemplateName.put(countryRegMDT.DeveloperName, countryRegMDT.Template_Name_Region__c);
			}
		}
		system.debug('>>>>> mapCountryRegion : ' + mapCountryTemplateName);
	}
    /*
     *
     * @author Global Desktop
     * Funcion que devuelve un mapa con la relacion de cliente-grupo, en la key tiene el id del cliente y en el value tiene el id del grupo
    **/
    public static String getDescribedObjects( List<String> lstSObjectType ) {

        // Globally desribe all the objects
        Map<String, SObjectType> globalDescribe = new Map<String, SObjectType>();
        globalDescribe = Schema.getGlobalDescribe();
        // Create a JSON string with object field labels and picklist values
        String allObjJSON = '{';

        // Iterate over the list of objects and describe each object
        for( String sObjectType : lstSObjectType ) {

            if(!allObjJSON.equalsIgnoreCase(ABREPAR)) {
            	allObjJSON += ', ';
            }

            allObjJSON += '"' + sObjectType + '": ';
            final DescribeSObjectResult describeResult = globalDescribe.get(sObjectType).getDescribe();
            Map<String, Schema.SObjectField> desribedFields = new Map<String, Schema.SObjectField>();
            desribedFields = describeResult.fields.getMap();
            String objJSON = '{';

            for( String fieldName :  desribedFields.keySet() ) {

                // Descirbe the field
                final Schema.SObjectField field = desribedFields.get( fieldName );
                final Schema.DescribeFieldResult fDesc = field.getDescribe();
                if( !objJSON.equalsIgnoreCase(ABREPAR) ) {
                    objJSON += ', ';
                }
                // Get the field label and append in the JSON string
                objJSON += '"' + fDesc.getName() + '": ' + '{ "label" : "' + fDesc.getLabel() + '"';
                String helpText;
                helpText = fDesc.getInlineHelpText();
                if(String.isNotEmpty(helpText)) {
                     objJSON +=  ', "helpText" : "' + helpText.replaceAll('[\n\r]', '') +'"';
                }


                // if it's a picklist field then also add the picklist options
                if( field.getDescribe().getType() == Schema.DisplayType.PICKLIST ) {

                    List <Schema.PicklistEntry> picklistValues = new List <Schema.PicklistEntry>();
                    picklistValues = field.getDescribe().getPickListValues();
                	List<String> pickListOptions = new List<String>();
                    pickListOptions = new List<String>();
                    pickListOptions.add('{ "label": "--None--", "value": null }');

                    for (Schema.PicklistEntry pe : picklistValues) {

                        pickListOptions.add('{ "label": "' + pe.getLabel() + '", "value": "' + pe.getValue() + '" }');

                    }

                    System.debug( '>>>> ' + fieldName + '>>>> ' + String.join(pickListOptions, ', ') );
                    objJSON += ', "picklistOptions": [' + String.join(pickListOptions, ', ') + ']';
                }
                objJSON += '}';
            }
            objJSON += '}';

            allObjJSON += objJSON;
        }

        // Close the object in the JSON String
        allObjJSON += '}';

        System.debug( ' JSON STRING : ' + allObjJSON );

        return allObjJSON;
    }
    /******************************************************************************************************************************************************
    *   @author: GlobalDesktop - APC
    *   @Method: addValueToSetStringified
    *   @Description:

    *   @Params: String initialValue - initial values of the String, example :multipicklist DES_Scope__c
    *   @Params: newValue - new value to be added in multipicklist (set< String>)
    *   @Params: concatValues -> values to concat the finalValue
    *   @Returns: String finalValue -> String with values concat with concatValues

    *   @Versions:
            v1 - 2019/01/24 - Initial version.
    ******************************************************************************************************************************************************/
    public static String addValueToSetStringified (String initialValue, String newValue, String concatValues) {
        System.debug('::::addValueToSetStringified init');
        System.debug('::::initialValue: ' + initialValue);
        System.debug('::::newValue: ' + newValue);
        System.debug('::::concatValues: ' + concatValues);
        if(newValue != null) {
            final List<String> lstNewValues = newValue.split(concatValues);
            final List<String> lstInitialValues = initialValue == null ? new List<String>() : initialValue.split(concatValues);
            for(String newValor : lstNewValues) {
                if(lstInitialValues.contains(newValor)) {
                    lstInitialValues.remove(lstInitialValues.indexOf(newValor));
                }
            }
            // if(lstInitialValues.contains(newValue)) {
            //     lstInitialValues.remove(lstInitialValues.indexOf(newValue));
            // }
            final String midValues = String.join(lstInitialValues, concatValues);
            final String finalValue = midValues == null ? newValue : newValue + concatValues + midValues;
            System.debug('::::finalValue: ' + finalValue);
            return finalValue;
        }
        return null;
    }
    /******************************************************************************************************************************************************
    *   @author: GlobalDesktop - APC
    *   @Method: addValueToSetStringified
    *   @Description:

    *   @Params: String initialValue - initial values of the String, example :multipicklist DES_Scope__c
    *   @Params: newValue - new value to be added in multipicklist (set< String>)
    *   @Params: concatValues -> values to concat the finalValue
    *   @Returns: String finalValue -> String with values concat with concatValues

    *   @Versions:
            v1 - 2019/01/24 - Initial version.
    ******************************************************************************************************************************************************/
    public static String checkDuplicateString (String initialValue, String concatValues) {
        System.debug('::::addValueToSetStringified init');
        System.debug('::::initialValue: ' + initialValue);
        System.debug('::::concatValues: ' + concatValues);
        if(initialValue != null) {
            final List<String> lstNewValues = initialValue.split(concatValues);
            final String finalValue;
            final Set<String> setValues = new Set<String>();
            for(String value : lstNewValues) {
                setValues.add(value);
            }
            finalValue = String.join(new List<String>(setValues), concatValues);
            return finalValue;
        }
        return null;
    }

    /**
     * Devuelve un mapa con las preguntas de compliance
     */
    public static Map<String, String> complianceQuestions() {
    	final Map<String, String> mQuestions = new Map<String, String>();
		for(Compliance_Form__mdt question : [SELECT DeveloperName, question__c from Compliance_Form__mdt LIMIT 100]) {
			mQuestions.put(question.DeveloperName, question.question__c);
		}
		system.debug('>>>>> mQuestions : ' + mQuestions);
		return mQuestions;

	}

    /**
     * Devuelve el codigo bbva del usuario que invoca el method
     */
    public static String bbvaUserCode() {
    	system.debug('entra bbvaUserCode usuario: ' + UserInfo.getUserId());

    	final List<User> users = new List<User>([SELECT FederationIdentifier FROM User WHERE Id=:UserInfo.getUserId()]);
    	return users.get(0).FederationIdentifier;
    }

     /**
     * Devuelve true si la oportunidad esta cerrada
     */
    public static Boolean isOppClosed(Id codOpp) {
		Boolean isClosed;
		for(Opportunity opp : [SELECT IsClosed from Opportunity where Id=:codOpp ]) {
			isClosed=  opp.IsClosed;
		}
		return isClosed;
	}

    /**
     * Devuelve true si la visita se ha finalizado
     */
    public static Boolean isVisitClosed(Id codVisit) {
		Boolean isClosed;
		for(dwp_kitv__Visit__c visit : [SELECT dwp_kitv__visit_status_type__c from dwp_kitv__Visit__c where Id=:codVisit ]) {
            if(visit.dwp_kitv__visit_status_type__c == FINVSTSTS ) {
               isClosed= true;
            } else {
               isClosed= false;
            }
		}
		return isClosed;
	}

     /**
     * Devuelve el endpoint de los servicios ip
     */
    public static String urlIPServices() {
		String endpoint;
		for(IP_Services__mdt url : [SELECT Endpoint__c from IP_Services__mdt where DeveloperName='url' ]) {
            endpoint = url.Endpoint__c;
		}
		return endpoint;
	}


  /**
   * Establece la lista de paises para que las oportunidades IP sean visibles por los compliances correspondientes
   * (campo oppy_participate_country_desc__c)
   *
   * @param oppsById
   */
  public List<Opportunity> setIPOpportunityCountries ( Map<Id, Opportunity> oppsById) { //NOSONAR

    final Map<Id, Set<String>> countriesByOppId = new Map<Id, Set<String>>();
    final Map<String, Id> oppsIdByOwnerId = new Map<String, Id>();

    // Filtrar las oportunidades privilegiadas del trigger
    final Id privOppRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Privileged Opportunity').getRecordTypeId();
    for ( Opportunity opp: oppsById.values() ) {
      if ( opp.RecordTypeId == privOppRT && opp.operation_privileged_user_name__c != null ) {
        countriesByOppId.put( opp.Id, null );
        oppsIdByOwnerId.put( opp.operation_privileged_user_name__c, opp.Id );
      }
    }

    if ( !countriesByOppId.isEmpty() ) {

      // Añadir el pais de los owner
      for ( User usr: [SELECT Id, DES_Country__c FROM User WHERE Id IN :oppsIdByOwnerId.keySet()] ) {
        countriesByOppId.put( oppsIdByOwnerId.get( usr.Id ), new Set<String> { usr.DES_Country__c } );
      }

      // Añadir el pais de los opportunity members
      Set<String> countries;
      for ( DES_Opportunity_Management_member__c teamMember: [
          SELECT Id, DES_Opportunity__c, DES_User__r.DES_Country__c
          FROM DES_Opportunity_Management_member__c
          WHERE DES_Opportunity__c IN :countriesByOppId.keySet()
      ] ) {

        countries = countriesByOppId.get( teamMember.DES_Opportunity__c );

        if ( countries.add( teamMember.DES_User__r.DES_Country__c ) ) {
          countriesByOppId.put( teamMember.DES_Opportunity__c, countries );
        }

      }

      // Establecer los paises a las oportunidades
      for ( Id oppId: countriesByOppId.keySet() ) {
        oppsById.get( oppId ).oppy_participate_country_desc__c = String.join( new List<String> (countriesByOppId.get( oppId )), ';' );
      }

    }

    return oppsById.values();

  }

  /**
   * Interfaz del mét0d0 setIPOpportunityCountries que toma un Set de Ids en vez de un Mapa.
   * Se trata de mantener desacoplado dicho mét0d0 de los atributos que deberían incluir las
   * oportunidades que se toman como argumento.
   *
   * @param oppsId
   */
  public void setIPOpportunityCountries ( Set<Id> oppsId ) { //NOSONAR

    update this.setIPOpportunityCountries( new Map<Id, Opportunity> ([
        SELECT Id, RecordTypeId, operation_privileged_user_name__c
        FROM Opportunity
        WHERE Id IN :oppsId])
    );

  }

  /**
   * Class to hold methods that are executed in an administrator context
   */
  public without sharing class adminMethods {

      /**
       *
       * @param recordId
       * @param userId
       *
       * @return an UserRecordAccess object with the details of the access over the record
       */
      public UserRecordAccess getUserRecordAccess ( Id recordId, Id userId ) { //NOSONAR

          UserRecordAccess ura = null;
          final List<UserRecordAccess> uras = [
              SELECT HasEditAccess, HasAllAccess, HasReadAccess, HasTransferAccess, HasDeleteAccess, RecordId
              FROM UserRecordAccess
              WHERE UserId = :userId
                AND RecordId = :recordId
          ];

          if(!uras.isEmpty()) {
              ura = new UserRecordAccess();
              ura = uras[0];
          }

          return ura;

      }

  }

    /**
     * Access to the adminMethods.getUserRecordAccess, to be executed without sharings
     *
     * @param recordId
     * @param userId
     *
     * @return
     */
    public static UserRecordAccess getUserRecordAccess ( Id recordId, Id userId ) {

      return new adminMethods().getUserRecordAccess( recordId, userId );

    }

    /**
    * Intenta realizar una operación de upsert (inserción o actualización) en una lista de SObjects con lógica de reintentos 
    * para manejar errores de tipo UNABLE_TO_LOCK_ROW.
    *
    * @param objList List<SObject> - La lista de SObjects a insertar o actualizar.
    * @param method String - La operación DML a realizar: 'insert' o 'update'.
    *
    * El método reintentará hasta 3 veces si ocurre un error UNABLE_TO_LOCK_ROW, esperando una cantidad creciente de tiempo entre reintentos.
    * Si ocurre cualquier otra excepción, o si se alcanza el número máximo de reintentos, el método registrará el error y saldrá.
    * Los éxitos parciales se reintentarán a menos que se alcance el número máximo de reintentos.
    *
    * Lanza una IllegalArgumentException si se proporciona un método no soportado.
    * Registra mensajes de error detallados para cada registro fallido.
    */

    public void upsertWithRetry ( List<SObject> objList, String method ) {
        Boolean success = false;
        Integer retries = 0;
        final Integer MAX_RETRIES = 3;

        while (!success && retries < MAX_RETRIES) {
            try {
                Database.SaveResult[] results = new Database.SaveResult[]{};
                switch on method {
                    when 'insert' {
                        results = Database.insert(objList, false);
                    }
                    when 'update' {
                        results = Database.update(objList, false);
                    }
                    when else {
                        throw new IllegalArgumentException('Método no soportado: ' + method);
                    }
                }
                
                
                Boolean hasErrors = false;
                for(Database.SaveResult result : results) {
                    if (!result.isSuccess()) {
                        hasErrors = true;
                        for (Database.Error err : result.getErrors()) {
                            System.debug('Error updating record: ' + err.getStatusCode() + ' - ' + err.getMessage());
                        }
                    }
                }
                
                if (!hasErrors || retries >= MAX_RETRIES - 1) {
                    success = true;
                } else {
                    throw new DmlException('Retrying after partial success');
                }
            } catch (Exception e) {
                if ((e instanceof DmlException && e.getMessage().contains('UNABLE_TO_LOCK_ROW')) && retries < MAX_RETRIES) {
                    retries++;
                    Integer waitTime = retries * 500;
                    System.debug('UNABLE_TO_LOCK_ROW error, retrying in ' + waitTime + 'ms. Attempt: ' + retries);
                    Long startTime = System.currentTimeMillis();
                    while (System.currentTimeMillis() - startTime < waitTime) { /* Sleep */ }
                } else {
                    System.debug('Error final en actualización: ' + e.getMessage());
                    success = true;
                }
            }
        }
    }

}