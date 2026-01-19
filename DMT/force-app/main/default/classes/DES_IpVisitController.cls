/**
* @author GlobalDesktop
*/
public with sharing
class DES_IpVisitController {

  /**
   * SINGLETON PATTERN
   */
  private static DES_IpVisitController instanceVisit;

  /*
	 *
	 *
	 */
	private static final Id IDPROFCOMP = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop Compliance' LIMIT 1].Id;

  /*
	 *
	 *
	 */
	private static final Id IDPROFSP = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop SP' LIMIT 1].Id;


  /**
   * Constructor
   */
  private DES_IpVisitController() {
  }

  /**
   * getInstance
   */
  public static DES_IpVisitController instance() {
    if (instanceVisit == null) {
      instanceVisit = new DES_IpVisitController();
    }
    return instanceVisit;
  }

   /**
   * Devuelve true o false si el usuario que realiza la consulta es owner de la oportunidad que se pasa por parametro.
   */
  @AuraEnabled
  public static Boolean isOwner(id visitId) {
      try {
        final List<dwp_kitv__Visit__c> lVisit = [SELECT Id, visit_privileged_user_name__c FROM dwp_kitv__Visit__c WHERE Id=:visitId AND visit_privileged_user_name__c=:UserInfo.getUserId()];
        system.debug('isOwner: ' + lVisit.size());
        return !lVisit.isEmpty();
      } catch(Exception e) {
        throw new AuraHandledException(Label.DES_IP_ERROR + e);
      }
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
    public static boolean isVisible(Id visitId) {
     try {
       boolean visible = false;
       final List <dwp_kitv__Visit__c> visits = new List <dwp_kitv__Visit__c>([
           SELECT id, visit_privileged_user_name__c
           FROM dwp_kitv__Visit__c
           WHERE id = :visitId
       ]);
       final dwp_kitv__Visit__c visit = visits.get(0);
       final List <dwp_kitv__Visit_Management_Team__c> visitMembers = new List<dwp_kitv__Visit_Management_Team__c>([
           SELECT id, dwp_kitv__user_id__c, dwp_kitv__visit_id__c  FROM dwp_kitv__Visit_Management_Team__c
           WHERE dwp_kitv__visit_id__c = : visitId
       ]);
        for (dwp_kitv__Visit_Management_Team__c member : visitMembers) {
          if (member.dwp_kitv__user_id__c == UserInfo.getUserId()) {
            visible = true;
          }
        }
        if(visit.visit_privileged_user_name__c == UserInfo.getUserId()) {
          visible = true;
        }
        if(UserInfo.getProfileId() == IDPROFCOMP || UserInfo.getProfileId() == IDPROFSP) {
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
      return Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }
/**
 * Obtiene los miembros de la visita
 */
  @AuraEnabled
  public static String visitMembers(Id visitId) {
   try {
     final List <dwp_kitv__Visit_Management_Team__c> visitMembers = new List<dwp_kitv__Visit_Management_Team__c>([
         SELECT id,  DES_Member_Role__c, dwp_kitv__user_id__r.Name, dwp_kitv__contact_email_desc__c, dwp_kitv__contact_phone_desc__c
         FROM dwp_kitv__Visit_Management_Team__c
         WHERE dwp_kitv__visit_id__c  = :visitId
     ]);
     return JSON.serialize(visitMembers);
   } catch(Exception e) {
     throw new AuraHandledException(Label.DES_IP_ERROR + e);
   }
  }
  /**
 * Obtiene los topics de la visita
 */
  @AuraEnabled
  public static String visitTopics(Id visitId) {
   try {
     final List <dwp_kitv__Visit_Topic__c> visitMembers = new List<dwp_kitv__Visit_Topic__c>([
         SELECT Id, dwp_kitv__visit_done_type__c, dwp_kitv__opportunity_id__c, dwp_kitv__opportunity_id__r.Name, dwp_kitv__topic_desc__c
         FROM dwp_kitv__Visit_Topic__c
         WHERE dwp_kitv__visit_id__c  = :visitId
     ]);
     return JSON.serialize(visitMembers);
   } catch(Exception e) {
     throw new AuraHandledException(Label.DES_IP_ERROR + e);
   }
  }
/**
 * Obtiene los contactos de la visita
 */
  @AuraEnabled
  public static String visitContact(Id visitId) {
   try {
     final List <dwp_kitv__Visit_Contact__c > visitContact = new List<dwp_kitv__Visit_Contact__c >([
         SELECT Id, dwp_kitv__contact_id__r.Name, dwp_kitv__contact_id__c, dwp_kitv__contact_phone_desc__c, dwp_kitv__contact_email_desc__c, dwp_kitv__contact_called_type__c
         FROM dwp_kitv__Visit_Contact__c
         WHERE dwp_kitv__visit_id__c  = :visitId
     ]);
     return JSON.serialize(visitContact);
   } catch(Exception e) {
     throw new AuraHandledException(Label.DES_IP_ERROR + e);
   }
  }

  /**
  * Elimina el miembro de la visita indicado
  */
 @AuraEnabled
   public static void delRecord(Id codTeamMember, Id visitId) {
   	system.debug('Valor de codTeamMember: ' +codTeamMember);
   	system.debug('Valor de visitId: ' +visitId);
    try {
        if (codTeamMember != null) {
	      /*final dwp_kitv__Visit_Management_Team__c member = new dwp_kitv__Visit_Management_Team__c (Id = codTeamMember);
	      delete member;*/
	      final List<dwp_kitv__Visit_Management_Team__c> members = new List<dwp_kitv__Visit_Management_Team__c>([
	      		SELECT Id, dwp_kitv__user_id__c
		      	FROM dwp_kitv__Visit_Management_Team__c
		      	WHERE Id = :codTeamMember
      		]);
	      final List <Group> groupList = new List<Group>([
               SELECT Id
               FROM Group
               WHERE Name = :visitId
   		  ]);
   		  final List <Inside_information_form__c> formList = new List<Inside_information_form__c>([
               SELECT Id
               FROM Inside_information_form__c
               WHERE visit_id__c = :visitId
           ]);
           final List <Compliance_form_contact__c> comConList = new List<Compliance_form_contact__c>([
               SELECT Id
               FROM Compliance_form_contact__c
               WHERE Formulario__c = :formList[0].Id
               and user_id__c = :members[0].dwp_kitv__user_id__c
           ]);

           delete members[0];
            DES_IP_groupMember.deleteMember(groupList[0].Id, members[0].dwp_kitv__user_id__c);
           	if (comConList != null && !comConList.isEmpty()) {
            	 delete comConList;
            }


        }
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
   }
  /**
  * Elimina el topic de la visita indicado
  */
 @AuraEnabled
   public static void delVisitTopic(Id codVisitTopic) {
    try {
        if (codVisitTopic != null) {
          final dwp_kitv__Visit_Topic__c topic = new dwp_kitv__Visit_Topic__c (Id = codVisitTopic);
          delete topic;
        }
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
   }
     /**
  * Elimina el contacto de la visita indicado
  */
 @AuraEnabled
   public static void delContactRecord(Id codTeamMember) {
    try {
        if (codTeamMember != null) {
          final dwp_kitv__Visit_Contact__c member = new dwp_kitv__Visit_Contact__c (Id = codTeamMember);
          delete member;
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
   public static Boolean checkEventTracker(Id visitId, Id codTeamMember) {
      Boolean isInEventTracker;
      final List <dwp_kitv__Visit_Management_Team__c> members = new List<dwp_kitv__Visit_Management_Team__c>([
        SELECT Id, dwp_kitv__user_id__c, dwp_kitv__visit_id__c
        FROM dwp_kitv__Visit_Management_Team__c
        WHERE Id = :codTeamMember
      ]);

      final List <Compliance_form_contact__c> membersForm = new List<Compliance_form_contact__c>([
        SELECT Id, user_id__c, Formulario__c, Formulario__r.opportunity_id__c, Formulario__r.visit_id__c
        FROM Compliance_form_contact__c
        WHERE user_id__c = :members.get(0).dwp_kitv__user_id__c
            AND Formulario__c IN (SELECT Id FROM Inside_information_form__c WHERE visit_id__c = :members.get(0).dwp_kitv__visit_id__c)]);

      try {
        isInEventTracker = DES_IpFormContactController.checkDeleteIPFormMember(membersForm);
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
    // private static Boolean checkDeleteIPVisitMember(List<dwp_kitv__Visit_Management_Team__c> listVisit) {
		// 	Boolean isInEventTracker;
    //   isInEventTracker = false;
    //   system.debug('>>>>> listVisit: ' + listVisit);
		// 	Global_Desktop_Settings__c gdSettings = Global_Desktop_Settings__c.getInstance();
		// 	if(gdSettings.URL_Lightning__c != null && gdSettings.URL_Lightning__c != '') {
		// 		final Set<String> setVisitsId = new Set<String>();
		// 		final Set<String> setVisitsURL = new Set<String>();
		// 		final Set<Id> setUserId = new Set<Id>();
		// 		final Set<String> setUserVisitEvent = new Set<String>();
		// 		//Recorro el triggerNew para recuperar todos los Ids de las opps y los usuarios relacionados
		// 		for(dwp_kitv__Visit_Management_Team__c visitTeam : listVisit) {
		// 			if(!setVisitsId.contains(visitTeam.dwp_kitv__visit_id__c)) {
		// 				setVisitsId.add(visitTeam.dwp_kitv__visit_id__c);
		// 			}
		// 			if(!setUserId.contains(visitTeam.dwp_kitv__user_id__c)) {
		// 				setUserId.add(visitTeam.dwp_kitv__user_id__c);
		// 			}
		// 		}

		// 		//Construyo las URLS de las Opps relacionadas que sean inside information
		// 		for(dwp_kitv__Visit__c visit : [SELECT Id, disclosure_info_type__c FROM dwp_kitv__Visit__c WHERE disclosure_info_type__c = :Label.DES_OP_Inside AND Id IN :setVisitsId]) {
		// 				if(!setVisitsURL.contains(gdSettings.URL_Lightning__c + 'lightning/r/dwp_kitv__Visit__c/' + visit.Id + '/view')) {
		// 						setVisitsURL.add(gdSettings.URL_Lightning__c + 'lightning/r/dwp_kitv__Visit__c/' + visit.Id + '/view');
		// 				}
		// 		}
		// 		system.debug('>>>>> setUserId: ' + setUserId);
		// 		system.debug('>>>>> setVisitsURL: ' + setVisitsURL);
		// 		system.debug('>>>>> query: ' + [SELECT Name, etrk__Account_Name__c, etrk__Body__c, etrk__CreationDate__c, etrk__Event_Name__c, etrk__Event_Text__c,
		// 																																etrk__Location__c, etrk__Raw_Location__c, etrk__Section__c, etrk__SessionId__c, etrk__Type__c, etrk__User__c
		// 																												FROM etrk__EventTracker_Event__c
		// 																												WHERE etrk__User__c IN :setUserId AND etrk__Location__c IN :setVisitsURL]);
		// 		if(!setVisitsURL.isEmpty()) {
		// 			//Recorro los eventtracker para ver si el usuario ha visitado la oportunidad que quiere comprobar
		// 			for(etrk__EventTracker_Event__c eventTracker : [SELECT Name, etrk__Account_Name__c, etrk__Body__c, etrk__CreationDate__c, etrk__Event_Name__c, etrk__Event_Text__c,
		// 																															etrk__Location__c, etrk__Raw_Location__c, etrk__Section__c, etrk__SessionId__c, etrk__Type__c, etrk__User__c
		// 																											FROM etrk__EventTracker_Event__c
		// 																											WHERE etrk__User__c IN :setUserId AND etrk__Location__c IN :setVisitsURL]) {
		// 				system.debug('>>>>> eventTracker: ' + eventTracker);
		// 				String visitId = eventTracker.etrk__Location__c.substringBeforeLast('/'); //NOSONAR
		// 				visitId = visitId.substringAfterLast('/');
		// 				if(!setUserVisitEvent.contains(eventTracker.etrk__User__c + '_' + visitId)) {
		// 					setUserVisitEvent.add(eventTracker.etrk__User__c + '_' + visitId);
		// 				}
		// 			}
		// 			for(dwp_kitv__Visit_Management_Team__c visitTeam : listVisit) {
		// 				if(setUserVisitEvent.contains(visitTeam.dwp_kitv__user_id__c + '_' + visitTeam.dwp_kitv__visit_id__c)) {
		// 					isInEventTracker = true;
		// 				}
		// 			}
		// 		}

		// 	}
    //   return isInEventTracker;
    // }



}