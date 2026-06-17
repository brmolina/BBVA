/**********************************************************************************
* @author       Accenture
* @date         12/01/2016
* @description  Trigger para objeto Event. No crear más triggers para Event, para ello usar la clase EventTriggerHandler y ActivitiesUtils.
* @Revision     
                2017/10/26 Se deja de utilizar customActivity (Activity__c) y se comentan las líneas de código que ya no aplican. En realidad el trigger de Event ya no hay que hacer nada, pero se deja comentado
                2018/05/11 Actualización con las llamadas al handler del kit de visitas
                2018/06/05 Actualización con las llamadas al handler del google calendar. Eliminación líneas comentadas que ya no aplican
                2018/07/04 Se añade comprobaciones en los metodos del trigger para que sólo se lancen llamadas a los metodos de KitVisitas y de GoogleCalendarSync si son eventos creados manualmente (de 1 en 1) y desde el componente de Kit Visitas
**********************************************************************************/
trigger Event on Event (before update, after insert, after update, after delete) {
    CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();    
    CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();    
    system.debug('>>>>>>>>>> entrando en Event trigger. Custom setting byPass trigger: ' + byPass.CIB_skip_trigger__c + '\r\n Custom setting is user desktop: ' + userSettings.CIB_Is_Desktop__c);    
    
    if(!byPass.CIB_skip_trigger__c /*&& userSettings.CIB_Is_Desktop__c*/)
    {       
        //Get Event_Handler from package gcal (Google Calendar Sync)
        gcal.GBL_EventHandler gcalHandler = new gcal.GBL_EventHandler();        

        //Get Event_Handler from package dwp_kitv (Kit Visit)
        dwp_kitv.Event_Handler eventHandler_visit = new dwp_kitv.Event_Handler();


        //ON BEFORE UPDATE
        if (Trigger.isBefore && Trigger.isUpdate){
            system.debug('>>>>>>>>>> ON BEFORE UPDATE');

            // esta comprobación se pone para que sólo se lancen los metodos de KitVisitas y de GoogleCalendarSync si son eventos
            // creados manualmente y desde el componente de Kit Visitas
            
            if (Trigger.new.size() == 1 && trigger.new.get(0).dwp_kitv__visit_id__c != null
                 && !SER_TriggerHelper.get_MethodFired('KitVisit_Event')) {      

                eventHandler_visit.eventBeforeUpdate(trigger.new, Trigger.oldMap);
                SER_TriggerHelper.set_MetodFired('KitVisit_Event', true);
            }
        }

        //ON AFTER UPDATE
        else if (Trigger.isAfter && Trigger.isUpdate){
            system.debug('>>>>>>>>>> ON AFTER UPDATE');
            // esta comprobación se pone para que sólo se lancen los metodos de KitVisitas y de GoogleCalendarSync si son eventos
            // creados manualmente y desde el componente de Kit Visitas
            if(Trigger.new.size() == 1 && trigger.new.get(0).dwp_kitv__visit_id__c != null){

                // handler de componente Visitas
                if (!SER_TriggerHelper.get_MethodFired('KitVisit_Event')) {             
                    eventHandler_visit.eventAfterUpdate(trigger.new, Trigger.oldMap);
                    SER_TriggerHelper.set_MetodFired('KitVisit_Event', true);
                }
                
                
                // handler de componente GoogleCalendarSync
                if (!SER_TriggerHelper.get_MethodFired('GoogleCalendarSync')) {                      
                    system.debug('>>>>>>>>>> ON AFTER UPDATE: Sincronizando Google Calendar');
                    gcalHandler.afterUpdate();
                    SER_TriggerHelper.set_MetodFired('GoogleCalendarSync', true);
                 } 
             }
        }
        
        //ON AFTER INSERT
        else if (Trigger.isAfter && Trigger.isInsert){
            // esta comprobación se pone para que sólo se lancen los metodos de KitVisitas y de GoogleCalendarSync si son eventos
            // creados manualmente y desde el componente de Kit Visitas              
            if(Trigger.new.size() == 1 && trigger.new.get(0).dwp_kitv__visit_id__c != null
                 && !SER_TriggerHelper.get_MethodFired('GoogleCalendarSync')){ 

                    system.debug('>>>>>>>>>> ON AFTER INSERT: Sincronizando Google Calendar');    
                    gcalHandler.afterInsert();
                    SER_TriggerHelper.set_MetodFired('GoogleCalendarSync', true);
                
             }            
        } 

        //ON AFTER DELETE
        else if (Trigger.isAfter && Trigger.isDelete){
            // esta comprobación se pone para que sólo se lancen los metodos de KitVisitas y de GoogleCalendarSync si son eventos
            // creados manualmente y desde el componente de Kit Visitas
            //if(Trigger.new.size() == 1 && trigger.new.get(0).dwp_kitv__visit_id__c != null) { -> se comenta para que en principio al eliminar se invoque siempre
                system.debug('>>>>>>>>>> ON AFTER DELETE: Sincronizando Google Calendar');    
                gcalHandler.afterDelete();
            //}
        }
        

    }        
        
}