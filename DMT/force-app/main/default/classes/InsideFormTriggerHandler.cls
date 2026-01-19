/**********************************************************************************
* @author       Global Desktop
* @date         02/07/2019
* @description  Handler para el trigger para objeto Inside_information_form__c. 
* @Revision
**********************************************************************************/
public with sharing class InsideFormTriggerHandler {
	
    /**
     * @Method changeContactsRT 
     * */
    public static void changeContactsRT(Map<Id,Inside_information_form__c> triggerNewMap) {
        List<Inside_information_form__c> listPending = new List<Inside_information_form__c>();
        List<Inside_information_form__c> listRejected = new List<Inside_information_form__c>();
        for (Inside_information_form__c form : triggerNewMap.values()) {
            if (form.status_type__c == 'Pending') {
            	listPending.add(form);
            } else if (form.status_type__c == 'Rejected') {
                listRejected.add(form);
            }
        }
        List<Compliance_form_contact__c> listContactReadOnlyQuery = [Select Id, RecordTypeId from Compliance_form_contact__c where Formulario__c  in :listPending];
        List<Compliance_form_contact__c> listContactWriteQuery =  [Select Id, RecordTypeId from Compliance_form_contact__c where Formulario__c  in :listRejected];
        List<Compliance_form_contact__c> listContactReadOnly = new List<Compliance_form_contact__c>();
        List<Compliance_form_contact__c> listContactWrite =  new List<Compliance_form_contact__c>();
		System.debug('>>>>>>> listContactReadOnlyQuery' + listContactReadOnlyQuery.size());
        System.debug('>>>>>>> listContactWriteQuery' + listContactWriteQuery.size());

        
        if (!listContactReadOnlyQuery.isEmpty()) {
            for(Compliance_form_contact__c contactRead: listContactReadOnlyQuery) {
                if(contactRead.RecordTypeId == Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Form).getRecordTypeId()) {
                    contactRead.RecordTypeId = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Read_Form).getRecordTypeId();  
                    listContactReadOnly.add(contactRead);
                } else if ( contactRead.RecordTypeId == Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_BBVA_Contact_Form).getRecordTypeId() ) {
                    contactRead.RecordTypeId = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_BBVA_Contact_Read_Form).getRecordTypeId();       
                    listContactReadOnly.add(contactRead);
                }
        	}  
        }

        if (!listContactWriteQuery.isEmpty()) {
            for(Compliance_form_contact__c contactWrite: listContactWriteQuery) {
                if(contactWrite.RecordTypeId == Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Read_Form).getRecordTypeId()) {
                    contactWrite.RecordTypeId = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Form).getRecordTypeId();  
                    listContactWrite.add(contactWrite);
                } else if ( contactWrite.RecordTypeId == Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_BBVA_Contact_Read_Form).getRecordTypeId() ) {
                    contactWrite.RecordTypeId = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_BBVA_Contact_Form).getRecordTypeId();       
                    listContactWrite.add(contactWrite);
                }
        	}
        }
        
        
        if (!listContactReadOnly.isEmpty()) {
            update listContactReadOnly;
        }
        
        if (!listContactWrite.isEmpty()) {
        	update listContactWrite;  
        }
    }
    
    /**
     * @Method InsertOwner 
     * */
     public static void InsertOwner(Map<Id,Inside_information_form__c> triggerNewMap) {
        Id UserId = UserInfo.GetUserId();
		List <User> u=  [SELECT Id,Name,UserRole.Name FROM User WHERE Id = :UserId];
          for(User users : u){
        Compliance_form_contact__c ComForCon = new Compliance_form_contact__c(
        	Formulario__c=triggerNewMap.values().Id,
        	user_id__c= users.Id, 
        	person_name__c=users.Name,
       		role_name__c=users.UserRole.Name,
        	operation_user_assign_date__c=System.now()
        );
        insert ComForCon;
          }
	}
}