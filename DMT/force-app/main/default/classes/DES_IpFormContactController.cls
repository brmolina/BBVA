/**
* @author GlobalDesktop
*/
public with sharing
class DES_IpFormContactController { //NOSONAR

  /**
   * SINGLETON PATTERN
   */
  private static DES_IpFormContactController instncFormCntct;


  /**
   * getInstance
   */
  public static DES_IpFormContactController instance() {
    if (instncFormCntct == null) {
      instncFormCntct = new DES_IpFormContactController();
    }
    return instncFormCntct;
  }

  /**
   * Devuelve el codigo bbva del usuario que invoca el method
   */
  @AuraEnabled
  public static String bbvaUserCode() {
      try {
        return Desktop_Utils.bbvaUserCode();
      } catch (Exception e) {
        throw new AuraHandledException(Label.DES_IP_ERROR + e);
      }
  }

  /**
   * Devuelve fields de un objeto
   */
  @AuraEnabled
  public static String getObjectType(String objeto) {
    try {
      // Passing the sObject name in the method, it could be multiple objects too
      return Desktop_Utils.getDescribedObjects( new List<String>{objeto} );
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }

  /**
   * Devuelve true/false si es owner o miembro de la visita
   */
  @AuraEnabled
    public static boolean isVisible(Id form) {
     try {
       boolean visible = false;
       final List <Inside_information_form__c> forms = new List <Inside_information_form__c>([
           SELECT id, opportunity_id__r.OwnerId
           FROM Inside_information_form__c
           WHERE id = :form ]);

       if (!forms.isEmpty() && forms.get(0).opportunity_id__r.OwnerId == UserInfo.getUserId()) {
           visible = true;
      }


       return visible;
     } catch(Exception e) {
       throw new AuraHandledException(Label.DES_IP_ERROR + e);
     }
    }

  /**
   * Devuelve el record type para las picklist
   */
  @AuraEnabled
  public static String getRecordTypeId(String rtName) {
    try {
      return Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }
/**
 * Obtiene los miembros de la visita
 */
  @AuraEnabled
  public static String formMembers(Id formId) {
   try {
     final String recordTypeId = getRecordTypeId(Label.DES_RT_BBVA_Contact_Form);
     final String recordTypeReadId = getRecordTypeId(Label.DES_RT_BBVA_Contact_Read_Form);
     final List<String> recTypes = new List<String>();
     recTypes.add(recordTypeId);
     recTypes.add(recordTypeReadId);

     final List <Compliance_form_contact__c> formMembers = new List<Compliance_form_contact__c>([
         SELECT id,  person_name__c, employee_department_name__c, operation_user_assign_date__c, role_name__c, CreatedDate
         FROM Compliance_form_contact__c
         WHERE Formulario__r.Id  = :formId
         and RecordTypeId in :recTypes
         ORDER BY CreatedDate DESC
     ]);
     return JSON.serialize(formMembers);
   } catch(Exception e) {
     throw new AuraHandledException(Label.DES_IP_ERROR + e);
   }
  }
/**
 * Obtiene los miembros de la visita
 */
  @AuraEnabled
  public static String formExtMembers(Id formId) {
   try {
     final String recordTypeId = getRecordTypeId(Label.DES_RT_External_Contact_Form);
     final String recordTypeReadId = getRecordTypeId(Label.DES_RT_External_Contact_Read_Form);
     final List<String> recTypes = new List<String>();
     recTypes.add(recordTypeId);
     recTypes.add(recordTypeReadId);

     final List <Compliance_form_contact__c> formMembers = new List<Compliance_form_contact__c>([
         SELECT id,  person_name__c, employee_department_name__c, operation_user_assign_date__c, role_name__c,
         participant_name__c
         FROM Compliance_form_contact__c
         WHERE Formulario__r.Id  = :formId
         and RecordTypeId in :recTypes
     ]);
     return JSON.serialize(formMembers);
   } catch(Exception e) {
     throw new AuraHandledException(Label.DES_IP_ERROR + e);
   }
  }

  /**
  * Elimina el miembro de la visita indicado
  */
 @AuraEnabled
   public static void delContactRecord(Id codTeamMember, Id formId) {
    try {
    	system.debug('Valor de codTeamMember (antes del if): ' +codTeamMember);
        if (codTeamMember != null) {
            /*final Compliance_form_contact__c member = new Compliance_form_contact__c (Id = codTeamMember);
            delete member;*/
            system.debug('Valor de codTeamMember: ' +codTeamMember);
            final List<Compliance_form_contact__c> memberList = new List<Compliance_form_contact__c>([
                                    SELECT Id, user_id__c
                                    FROM Compliance_form_contact__c
                                    WHERE Id = :codTeamMember
                                    LIMIT 1]);
            final List<Inside_information_form__c> form = [SELECT Id, visit_id__c, opportunity_id__c
                                    FROM Inside_information_form__c
          												WHERE Id = :formId
          												LIMIT 1];

            if(form[0].visit_id__c == null) {
                final List<Opportunity> relOpp = [SELECT Id
                                    FROM Opportunity
                                    WHERE Id = :form[0].opportunity_id__c
                                    LIMIT 1];
                final List<DES_Opportunity_Management_member__c> oppManagList = [SELECT Id
                                                  FROM DES_Opportunity_Management_member__c
                                                  WHERE DES_Opportunity__c = :relOpp[0].Id
                                                  AND DES_User__c = :memberList[0].user_id__c];
                final List <Group> groupList = new List<Group>([
                                                SELECT Id
                                                FROM Group
                                                WHERE Name = :relOpp[0].Id
                                                ]);
                system.debug('Valor de relOpp[0].Id: ' +relOpp[0].Id);

                //delete memberList[0];
                system.debug('Valor de memberList[0]: ' +memberList[0]);
                system.debug('Valor de memberList[0].user_id__c: ' +memberList[0].user_id__c);
                DES_IP_groupMember.deleteMember(groupList[0].Id, memberList[0].user_id__c);
                if (oppManagList != null && !oppManagList.isEmpty()) {
                    delete oppManagList;
                }
                delete memberList[0];
            } else {
                final List<dwp_kitv__Visit__c> relVisit = [SELECT Id
                                    FROM dwp_kitv__Visit__c
                                    WHERE Id = :form[0].visit_id__c
                                    LIMIT 1];
                final List<dwp_kitv__Visit_Management_Team__c> relManagement = [SELECT Id
                                              FROM dwp_kitv__Visit_Management_Team__c
                                              WHERE dwp_kitv__visit_id__c = :relVisit[0].Id
                                              AND dwp_kitv__user_id__c = :memberList[0].user_id__c];
                final List <Group> groupList = new List<Group>([
                                            SELECT Id
                                            FROM Group
                                            WHERE Name = :relVisit[0].Id
                                            ]);

                //delete memberList[0];
                DES_IP_groupMember.deleteMember(groupList[0].Id, memberList[0].user_id__c);
                if (relManagement != null && !relManagement.isEmpty()) {
                    delete relManagement;
                }
                delete memberList[0];
            }
        }
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
   }
    /**
    * Devuelve el id de la sesion
    */
    @AuraEnabled
    public static String sessionId() {
      try {
          final String userId1 = UserInfo.getUserId();
          final String sessionId1 = UserInfo.getSessionId();
          final Map<String,String> jsonMap1 = new Map<String,String>();
          jsonMap1.put('userId',userId1);
          jsonMap1.put('sessionId',sessionId1);
          return JSON.serialize(jsonMap1);
      } catch (Exception e) {
          throw new AuraHandledException(Label.DES_IP_ERROR + e);
      }
    }

    /**
  * Elimina el topic de la visita indicado
  */
 	@AuraEnabled
   public static Boolean isVisitClosed(Id codVisit) {
    try {
        return Desktop_Utils.isVisitClosed(codVisit);
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
   }

       /**
   * Devuelve el endpoint de los servicios
   */
  	@AuraEnabled
    public static String urlIpServices() {
     try {
      	return Desktop_Utils.urlIPServices();
     } catch(Exception e) {
       throw new AuraHandledException(Label.DES_IP_ERROR + e);
     }

    }

   /**
   *
   */
   @AuraEnabled
   public static Boolean checkEventTracker(Id oppId, Id codTeamMember) {
      Boolean isInEventTracker;
      final List <Compliance_form_contact__c> members = new List<Compliance_form_contact__c>([
        SELECT Id, user_id__c, Formulario__c, Formulario__r.opportunity_id__c, Formulario__r.visit_id__c
        FROM Compliance_form_contact__c
        WHERE Id = :codTeamMember
      ]);
      try {
        isInEventTracker = checkDeleteIPFormMember(members);
        system.debug('>>>>> isInEventTracker: ' + isInEventTracker);
        return (isInEventTracker);
      } catch(Exception e) {
        throw new AuraHandledException(Label.DES_IP_ERROR + e);
     }

    }

    /*
    *   @author Global Desktop
    *   @Description Funcion que, si la oportunidad es IP, no deja borrar a los miembros de la oportunidad si ya ha iniciado sesión en algun momento
    *
    */
    public static Boolean checkDeleteIPFormMember(List<Compliance_form_contact__c> listForm) {
        Boolean isInEventTracker;
        isInEventTracker = false;
        system.debug('>>>>> listForm: ' + listForm);
        Global_Desktop_Settings__c gdSettings = Global_Desktop_Settings__c.getInstance();
        if(gdSettings.URL_Lightning__c != null && gdSettings.URL_Lightning__c != '') {
            final Set<String> setFormsId = new Set<String>();
            final Set<String> setComplFormsURL = new Set<String>();
            final Set<Id> setUserId = new Set<Id>();
            //Mapa que tiene como key 'IDUSUARIO_IDOPORTUNIDAD' y como value un true si ha visitado la oportunidad y no tiene que permitir borrar al opp team member
            final Set<String> setUserFormEvent = new Set<String>();
            //Recorro el triggerNew para recuperar todos los Ids de las opps y los usuarios relacionados
            for(Compliance_form_contact__c formContact : listForm) {
                if(!setComplFormsURL.contains(gdSettings.URL_Lightning__c + 'lightning/r/Inside_information_form__c/' + formContact.Formulario__c + '/view')) {
                    setComplFormsURL.add(gdSettings.URL_Lightning__c + 'lightning/r/Inside_information_form__c/' + formContact.Formulario__c + '/view');
                    if(formContact.Formulario__r.opportunity_id__c != null) {
                      setComplFormsURL.add(gdSettings.URL_Lightning__c + 'lightning/r/Opportunity/' + formContact.Formulario__r.opportunity_id__c + '/view');
                    } else {
                      setComplFormsURL.add(gdSettings.URL_Lightning__c + 'lightning/r/dwp_kitv__Visit__c/' + formContact.Formulario__r.visit_id__c + '/view');
                    }
                }
                if(!setUserId.contains(formContact.user_id__c)) {
                    setUserId.add(formContact.user_id__c);
                }
            }
            system.debug('>>>>> setUserId: ' + setUserId);
            system.debug('>>>>> setComplFormsURL: ' + setComplFormsURL);
            system.debug('>>>>> query: ' + [SELECT Name, etrk__Account_Name__c, etrk__Body__c, etrk__CreationDate__c, etrk__Event_Name__c, etrk__Event_Text__c,
                                                                        etrk__Location__c, etrk__Raw_Location__c, etrk__Section__c, etrk__SessionId__c, etrk__Type__c, etrk__User__c
                                                                FROM etrk__EventTracker_Event__c
                                                                WHERE etrk__User__c IN :setUserId AND etrk__Location__c IN :setComplFormsURL]);
            if(!setComplFormsURL.isEmpty()) {
                //Recorro los eventtracker para ver si el usuario ha visitado la oportunidad que quiere comprobar
                for(etrk__EventTracker_Event__c eventTracker : [SELECT Name, etrk__Account_Name__c, etrk__Body__c, etrk__CreationDate__c, etrk__Event_Name__c, etrk__Event_Text__c,
                                                                        etrk__Location__c, etrk__Raw_Location__c, etrk__Section__c, etrk__SessionId__c, etrk__Type__c, etrk__User__c
                                                                FROM etrk__EventTracker_Event__c
                                                                WHERE etrk__User__c IN :setUserId AND etrk__Location__c IN :setComplFormsURL]) {
                    system.debug('>>>>> eventTracker: ' + eventTracker);
                    String complFormId = eventTracker.etrk__Location__c.substringBeforeLast('/'); //NOSONAR
                    complFormId = complFormId.substringAfterLast('/');
                    if(!setUserFormEvent.contains(eventTracker.etrk__User__c + '_' + complFormId)) {
                        setUserFormEvent.add(eventTracker.etrk__User__c + '_' + complFormId);
                    }
                }
                for(Compliance_form_contact__c formContact : listForm) {
                    if(setUserFormEvent.contains(formContact.user_id__c + '_' + formContact.Formulario__c)
                    || (formContact.Formulario__r.opportunity_id__c != null && setUserFormEvent.contains(formContact.user_id__c + '_' + formContact.Formulario__r.opportunity_id__c))
                    || (formContact.Formulario__r.visit_id__c != null && setUserFormEvent.contains(formContact.user_id__c + '_' + formContact.Formulario__r.visit_id__c))) {
                        //formContact.addError(Label.ERROR_IP_CANNOT_DELETE_FORM_MEMBER);
                        isInEventTracker = true;
                    }
                }
            }

        }
        return isInEventTracker;
        //etrk__EventTracker_Event__c
    }

}