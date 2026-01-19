/**********************************************************************************
* @author       Global Desktop
* @date         02/07/2019
* @description  Handler para el trigger para objeto Inside_information_form__c.
* @Revision
**********************************************************************************/
public with sharing class CompformContTriggerHandler {

  /*
	* @author Global Desktop
	* @Description Funcion que tiene la logica a realizar cuando se ejecute el Before Delete
	*/
    public static void logicBeforeDelete(Map<Id, Compliance_form_contact__c> triggerOldMap) {
        NotDeleteOwner(triggerOldMap);
        //checkDeleteIPFormMember(triggerOldMap);
    }

  /**
  * @Method NotDeleteOwner
  * */
  public static void NotDeleteOwner(Map<Id, Compliance_form_contact__c> triggerOldMap) {

    Set<Id> formsIds = new Set<Id>();
    for ( Compliance_form_contact__c cfc : triggerOldMap.values() ) {
      formsIds.add(cfc.Formulario__c);
    }

    Map<Id, Inside_information_form__c> linform = new Map<Id, Inside_information_form__c>([SELECT Id,OwnerId FROM Inside_information_form__c where Id = :formsIds]);
    //Se itera Compliance_form_contact__c para obtener los registros donde el owner de Compliance_form_contact__c y Inside_information_form__c sean el mismo usuario
    for (Compliance_form_contact__c cfc : triggerOldMap.values()) {
      if (cfc.user_id__c == linform.get(cfc.Formulario__c).OwnerId) {
        Trigger.oldMap.get(cfc.Id).addError('You cannot delete the Owner of the InsideForm.');
      }
    }
  }

  /*
    *   @author Global Desktop
    *   @Description Funcion que, si la oportunidad es IP, no deja borrar a los miembros de la oportunidad si ya ha iniciado sesión en algun momento
    *
    */
    /*private static void checkDeleteIPFormMember(Map<Id, Compliance_form_contact__c> triggerOldMap) {
        system.debug('>>>>> triggerOldMap: ' + triggerOldMap);
        Global_Desktop_Settings__c gdSettings = Global_Desktop_Settings__c.getInstance();
        if(gdSettings.URL_Lightning__c != null && gdSettings.URL_Lightning__c != '') {
            final Set<String> setFormsId = new Set<String>();
            final Set<String> setComplFormsURL = new Set<String>();
            final Set<Id> setUserId = new Set<Id>();
            //Mapa que tiene como key 'IDUSUARIO_IDOPORTUNIDAD' y como value un true si ha visitado la oportunidad y no tiene que permitir borrar al opp team member
            final Set<String> setUserFormEvent = new Set<String>();
            //Recorro el triggerNew para recuperar todos los Ids de las opps y los usuarios relacionados
            for(Compliance_form_contact__c formContact : triggerOldMap.values()) {
                if(!setComplFormsURL.contains(gdSettings.URL_Lightning__c + 'lightning/r/Opportunity/' + formContact.Id + '/view')) {
                    setComplFormsURL.add(gdSettings.URL_Lightning__c + 'lightning/r/Opportunity/' + formContact.Id + '/view');
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
                for(Compliance_form_contact__c formContact : triggerOldMap.values()) {
                    if(setUserFormEvent.contains(formContact.user_id__c + '_' + formContact.Formulario__c)) {
                        formContact.addError(Label.ERROR_IP_CANNOT_DELETE_FORM_MEMBER);
                    }
                }
            }

        }

        //etrk__EventTracker_Event__c
    }*/
}