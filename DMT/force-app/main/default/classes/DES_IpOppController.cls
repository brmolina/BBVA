/**
*
*
* @author Global Desktop
*/

public with sharing
class DES_IpOppController { //NOSONAR

  /**
   * SINGLETON PATTERN
   */
  private static DES_IpOppController instance;

  /**
   * Lista paises
   */
  private static List<Map<String, String>> lista = new List<Map<String, String>>();
	/*
	 *
	 *
	 */
	private static final Id IDPROFCOMP = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop Compliance' LIMIT 1].Id;

  /**
   * Constructor
   */
  private DES_IpOppController() {
  }

  /**
   * getInstance
   */
  public static DES_IpOppController getInstance() {//NOSONAR
    if (instance == null) {
      instance = new DES_IpOppController();
    }
    return instance;
  }

  /**
   * Devuelve true o false si el usuario que realiza la consulta es owner de la oportunidad que se pasa por parametro.
   */
  @AuraEnabled
  public static Boolean isOwner(id optyId) {
      try {
        final List<Opportunity> lOpty = [SELECT Id, operation_privileged_user_name__c FROM Opportunity WHERE Id=:optyId AND operation_privileged_user_name__c=:UserInfo.getUserId()];
        system.debug('isOwner: ' + lOpty.size());
        return !lOpty.isEmpty();
      } catch(Exception e) {
        throw new AuraHandledException(Label.DES_IP_ERROR + e);
      }
  }

  /**
   * Devuelve el codigo bbva del usuario que invoca el method
   */
  @AuraEnabled
  public static String bbvaUserCode() {//NOSONAR
      // String user;
      system.debug('entra bbvaUserCode usuario: ' + UserInfo.getUserId());
      try {
        // user = Desktop_Utils.bbvaUserCode();
        return Desktop_Utils.bbvaUserCode();
      } catch (Exception e) {
        throw new AuraHandledException(Label.DES_IP_ERROR + e);
      }
      // return user;
  }

  /**
   * Devuelve una lista con oportunidades por id
   */
    @AuraEnabled
    public static Opportunity getOpportunityById(id optyId ) {//NOSONAR
        try {
            final List <Opportunity> lstOfOpportunity = [select id, Name FROM Opportunity WHERE Id=:optyId ];
            Opportunity opp;
            opp = new Opportunity();
            if(!lstOfOpportunity.isEmpty()) {
                opp = lstOfOpportunity.get(0);
            }
            return opp;
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }
    }

  /**
   * method for update records after inline editing
   */
  @AuraEnabled
  public static Opportunity saveOpportunity(Opportunity opp) {
    try {
      update opp;
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
    return opp;
  }

  /**
   *  method for fetch picklist values dynamic
   */
  @AuraEnabled
  public static String getCountries() {//NOSONAR
    Map<String, String> valores;
    try {
      if(lista.isEmpty()) {
          for(Opp_Countries__mdt countryRegMDT : [SELECT Id,  MasterLabel, DeveloperName FROM Opp_Countries__mdt order by MasterLabel LIMIT 1000]) {
              valores = new Map<String,String>();
              valores.put('label', countryRegMDT.MasterLabel);
              valores.put('value', countryRegMDT.DeveloperName);
              lista.add(valores);

          }
      }
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
    return JSON.serialize(lista);
  }

  /**
   * Devuelve fields de un objeto
   */
  @AuraEnabled
  public static String getObjectType(String objeto) {//NOSONAR
    try {
      // Passing the sObject name in the method, it could be multiple objects too
      return Desktop_Utils.getDescribedObjects( new List<String>{objeto} );
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }

  /**
   * Devuelve el record type para las picklist
   */
  @AuraEnabled
    public static String getRecordTypeId(String rtName) {//NOSONAR
     try {
       return Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
     } catch(Exception e) {
       throw new AuraHandledException(Label.DES_IP_ERROR + e);
     }
    }

   /**
   * Borra un miembro de la oportunidad
   */
  @AuraEnabled
    public static void delRecord(Id codTeamMember, Id oppId) {
     try {
         if (codTeamMember != null) {
            final List <DES_Opportunity_Management_member__c> members = new List<DES_Opportunity_Management_member__c>([
	               SELECT Id, DES_User__c
	               FROM DES_Opportunity_Management_member__c
	               WHERE Id = :codTeamMember
               ]);
            final List <Group> groupList = new List<Group>([
	               SELECT Id
	               FROM Group
	               WHERE Name = :oppId
               ]);
            final List <Inside_information_form__c> formList = new List<Inside_information_form__c>([
	               SELECT Id
	               FROM Inside_information_form__c
	               WHERE opportunity_id__c = :oppId
               ]);
             final List <Compliance_form_contact__c> cmplncCntctLst = new List<Compliance_form_contact__c>([
	               SELECT Id
	               FROM Compliance_form_contact__c
	               WHERE Formulario__c = :formList[0].Id
                   and user_id__c = :members[0].DES_User__c
               ]);

            delete members[0];
            DES_IP_groupMember.deleteMember(groupList[0].Id, members[0].DES_User__c);
           	if (cmplncCntctLst != null && !cmplncCntctLst.isEmpty()) {
            	 delete cmplncCntctLst;
            }

         }
     } catch(Exception e) {
    	 system.debug('delRecord: ' + e);
       throw new AuraHandledException(Label.DES_IP_ERROR + e);
     }
    }

   /**
   * Devuelve los miembros de la opp
   */
  @AuraEnabled
    public static String oppMembers(Id oppId) {
     try {
       final List <DES_Opportunity_Management_member__c> oppMembers = new List<DES_Opportunity_Management_member__c>([
           SELECT id, DES_User__c, DES_User__r.Name, DES_Phone__c, DES_Email__c,  DES_Opportunity_member_role__c
           FROM DES_Opportunity_Management_member__c
           WHERE DES_Opportunity__c = : oppId
       ]);
       return JSON.serialize(oppMembers);
     } catch(Exception e) {
       throw new AuraHandledException(Label.DES_IP_ERROR + e);
     }
    }

   /**
   * Devuelve los miembros de la opp
   */
  @AuraEnabled
    public static boolean isVisible(Id oppId) {
     try {
     	boolean visible = false;

	       	final List <Opportunity> opps = new List <Opportunity>([
	           SELECT id, operation_privileged_user_name__c
	           FROM Opportunity
	           WHERE id = :oppId
	       	]);
	       	final Opportunity opp = opps.get(0);
	       	final List <DES_Opportunity_Management_member__c> oppMembers = new List<DES_Opportunity_Management_member__c>([
	           SELECT id, DES_User__c, DES_User__r.Name, DES_Phone__c, DES_Email__c,  DES_Opportunity_member_role__c
	           FROM DES_Opportunity_Management_member__c
	           WHERE DES_Opportunity__c = : oppId
	       	]);
	       	for (DES_Opportunity_Management_member__c member : oppMembers) {
	           if (member.DES_User__c == UserInfo.getUserId()) {
	               visible = true;
	           }
	       	}
	       	if(opp.operation_privileged_user_name__c == UserInfo.getUserId()) {
	           visible = true;
	       	}
          if(UserInfo.getProfileId() == IDPROFCOMP || FeatureManagement.checkPermission('NBCAdmin')) {
            visible = true;
          }
       return visible;


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
            final String userId = UserInfo.getUserId();
            final String sessionId = UserInfo.getSessionId();
            final Map<String,String> jsonMap = new Map<String,String>();
            jsonMap.put('userId',userId);
            jsonMap.put('sessionId',sessionId);
            return JSON.serialize(jsonMap);
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }
    }

    /*
    *   @author Global Desktop
    *   @Description Funcion que, si la oportunidad es IP, no deja borrar a los miembros de la oportunidad si ya ha iniciado sesión en algun momento
    *
    */
    // private static Boolean checkDeleteIPOppMember(list<DES_Opportunity_Management_member__c> listOppTm) {
    //     Boolean isInEventTracker;
    //     isInEventTracker = false;
    //     system.debug('>>>>> listOppTm: ' + listOppTm);
    //     Global_Desktop_Settings__c gdSettings = Global_Desktop_Settings__c.getInstance();
    //     if(gdSettings.URL_Lightning__c != null && gdSettings.URL_Lightning__c != '') {
    //         final Set<String> setOppsId = new Set<String>();
    //         final Set<String> setOppsURL = new Set<String>();
    //         final Set<Id> setUserId = new Set<Id>();
    //         //Mapa que tiene como key 'IDUSUARIO_IDOPORTUNIDAD' y como value un true si ha visitado la oportunidad y no tiene que permitir borrar al opp team member
    //         final Set<String> setUserOppEvent = new Set<String>();
    //         //Recorro el triggerNew para recuperar todos los Ids de las opps y los usuarios relacionados
    //         for(DES_Opportunity_Management_member__c oppManag : listOppTm) {
    //             if(!setOppsId.contains(oppManag.DES_Opportunity__c)) {
    //                 setOppsId.add(oppManag.DES_Opportunity__c);
    //             }
    //             if(!setUserId.contains(oppManag.DES_User__c)) {
    //                 setUserId.add(oppManag.DES_User__c);
    //             }
    //         }

    //         //Construyo las URLS de las Opps relacionadas que sean inside information
    //         for(Opportunity opp : [SELECT Id, disclosure_info_type__c FROM Opportunity WHERE disclosure_info_type__c = :Label.DES_OP_Inside AND Id IN :setOppsId]) {
    //             if(!setOppsURL.contains(gdSettings.URL_Lightning__c + 'lightning/r/Opportunity/' + opp.Id + '/view')) {
    //                 setOppsURL.add(gdSettings.URL_Lightning__c + 'lightning/r/Opportunity/' + opp.Id + '/view');
    //             }
    //         }
    //         system.debug('>>>>> setUserId: ' + setUserId);
    //         system.debug('>>>>> setOppsURL: ' + setOppsURL);
    //         system.debug('>>>>> query: ' + [SELECT Name, etrk__Account_Name__c, etrk__Body__c, etrk__CreationDate__c, etrk__Event_Name__c, etrk__Event_Text__c,
    //                                                                     etrk__Location__c, etrk__Raw_Location__c, etrk__Section__c, etrk__SessionId__c, etrk__Type__c, etrk__User__c
    //                                                             FROM etrk__EventTracker_Event__c
    //                                                             WHERE etrk__User__c IN :setUserId AND etrk__Location__c IN :setOppsURL]);
    //         if(!setOppsURL.isEmpty()) {
    //             //Recorro los eventtracker para ver si el usuario ha visitado la oportunidad que quiere comprobar
    //             for(etrk__EventTracker_Event__c eventTracker : [SELECT Name, etrk__Account_Name__c, etrk__Body__c, etrk__CreationDate__c, etrk__Event_Name__c, etrk__Event_Text__c,
    //                                                                     etrk__Location__c, etrk__Raw_Location__c, etrk__Section__c, etrk__SessionId__c, etrk__Type__c, etrk__User__c
    //                                                             FROM etrk__EventTracker_Event__c
    //                                                             WHERE etrk__User__c IN :setUserId AND etrk__Location__c IN :setOppsURL]) {
    //                 system.debug('>>>>> eventTracker: ' + eventTracker);
    //                 String oppId = eventTracker.etrk__Location__c.substringBeforeLast('/'); //NOSONAR
    //                 oppId = oppId.substringAfterLast('/');
    //                 if(!setUserOppEvent.contains(eventTracker.etrk__User__c + '_' + oppId)) {
    //                     setUserOppEvent.add(eventTracker.etrk__User__c + '_' + oppId);
    //                 }
    //             }
    //             for(DES_Opportunity_Management_member__c oppManag : listOppTm) {
    //                 if(setUserOppEvent.contains(oppManag.DES_User__c + '_' + oppManag.DES_Opportunity__c)) {
    //                     isInEventTracker = true;
    //                 }
    //             }
    //         }

    //     }

    //     return isInEventTracker;
    // }
    /**
   * Devuelve los topics de la opp
   */
  @AuraEnabled
    public static String oppTopics(Id oppId) {
     try {
       final List <dwp_kitv__Visit_Topic__c> oppTopics = new List<dwp_kitv__Visit_Topic__c>([
           SELECT id, dwp_kitv__visit_id__r.Name, dwp_kitv__visit_id__c, dwp_kitv__most_recent_visits__c
           FROM dwp_kitv__Visit_Topic__c
           WHERE dwp_kitv__opportunity_id__c = : oppId
       ]);
       return JSON.serialize(oppTopics);
     } catch(Exception e) {
       throw new AuraHandledException(Label.DES_IP_ERROR + e);
     }
    }

  /**
   *
   */
  @AuraEnabled
    public static Boolean isOppClosed(Id oppId) {
      try {
        return (Desktop_Utils.isOppClosed(oppId));
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
      final List <DES_Opportunity_Management_member__c> members = new List<DES_Opportunity_Management_member__c>([
        SELECT Id, DES_User__c, DES_Opportunity__c
        FROM DES_Opportunity_Management_member__c
        WHERE Id = :codTeamMember
      ]);
      final List <Compliance_form_contact__c> membersForm = new List<Compliance_form_contact__c>([
        SELECT Id, user_id__c, Formulario__c, Formulario__r.opportunity_id__c, Formulario__r.visit_id__c
        FROM Compliance_form_contact__c
        WHERE user_id__c = :members.get(0).DES_User__c
            AND Formulario__c IN (SELECT Id FROM Inside_information_form__c WHERE opportunity_id__c = :members.get(0).DES_Opportunity__c)]);

      try {
        isInEventTracker = DES_IpFormContactController.checkDeleteIPFormMember(membersForm);
        system.debug('>>>>> isInEventTracker: ' + isInEventTracker);
        return (isInEventTracker);
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
   * Devuelve los topics de la opp
   */
  @AuraEnabled
    public static String oppForms2(Id oppId, Boolean valObject) {
     try {
         String retValue;
         if(valObject == true) {
             final List <Inside_information_form__c> oppForms = new List<Inside_information_form__c>([
                 SELECT id, Name
                 FROM Inside_information_form__c
                 WHERE Opportunity_id__r.Id = : oppId
             ]);
             retValue = JSON.serialize(oppForms);
         } else {
             final List <Inside_information_form__c> oppForms = new List<Inside_information_form__c>([
                 SELECT id, Name
                 FROM Inside_information_form__c
                 WHERE visit_id__r.Id = : oppId
             ]);
             retValue = JSON.serialize(oppForms);
         }
         return retValue;
     } catch(Exception e) {
         throw new AuraHandledException(Label.DES_IP_ERROR + e);
     }
    }
    /**
     * Devuelve una lista de Inside_information_form__c
     */
    @AuraEnabled
    public static String oppForms(Id oppId) {
     try {

     		final List <Inside_information_form__c> oppForms = new List<Inside_information_form__c>([
	           SELECT id, Name
	           FROM Inside_information_form__c
	           WHERE Opportunity_id__r.Id = : oppId
	       	]);
	       	return JSON.serialize(oppForms);
     } catch(Exception e) {
       throw new AuraHandledException(Label.DES_IP_ERROR + e);
     }
    }
}