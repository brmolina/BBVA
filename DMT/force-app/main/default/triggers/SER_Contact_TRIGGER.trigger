/**********************************************************************************
* @author       Accenture
* @date         01/03/2016
* @description  Trigger para objeto Contact. No crear más triggers para Contact, para ello usar la clase ContactTriggerHandler y ActivitiesUtils.
* @Revision
                2017/10/26 Se deja de utilizar customActivity (Activity__c) y se comentan las líneas de código que ya no aplican
**********************************************************************************/
//**trigger SER_Contact_TRIGGER on Contact (before insert, after insert, after delete) {
trigger SER_Contact_TRIGGER on Contact (before insert, after insert, before update, after update) {

    System.debug('JCT - Entering Contact.trigger on Contact');
    final ContactTriggerHandler handler = ContactTriggerHandler.getInstance();

    /*Get TriggerHandler*/
    CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
    //ajuste validacion NPS
    if (Trigger.isUpdate && Trigger.isBefore) {
           handler.uncheckValidationNPS(Trigger.new, Trigger.old);
    }
    if(!byPass.CIB_skip_trigger__c) {

        //ON AFTER INSERT
        if(Trigger.isAfter &&Trigger.isInsert) {
                System.debug('JCT - Entering Contact.trigger on Contact - EVENT : AFTER INSERT');
                handler.onAfterInsert(Trigger.newMap);

        //ON BEFORE INSERT
        } else if(Trigger.isBefore && Trigger.isInsert) {
                System.debug('JCT - Entering Contact.trigger on Contact - EVENT : BEFORE INSERT');
                System.debug('JCT - Lista de Contactos para INSERT : '+Trigger.new);
                handler.onBeforeInsert(Trigger.newMap);
        //ON BEFORE UPDATE
        } else if (Trigger.isUpdate && Trigger.isBefore) {
            handler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        //ON AFTER DELETE
        } else if (Trigger.isUpdate && Trigger.isAfter) {
            handler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);

        }
    }

}