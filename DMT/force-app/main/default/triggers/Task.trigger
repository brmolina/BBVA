/**********************************************************************************
* @author		Accenture
* @date			12/01/2016
* @description	Trigger para objeto Task. No crear más triggers para Task, para ello usar la clase TaskTriggerHandler y ActivitiesUtils.
* @Revision
                2017/10/26 Se deja de utilizar customActivity (Activity__c) y se comentan las líneas de código que ya no aplican
**********************************************************************************/
trigger Task on Task (before insert, after insert, after delete, after update, before update) {
    CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();

    if(!byPass.CIB_skip_trigger__c) {
        //Get TriggerHandler
        final TaskTriggerHandler handler = TaskTriggerHandler.getInstance();

        //ON AFTER INSERT
        if (Trigger.isInsert && Trigger.isAfter) {
            handler.onAfterInsert(Trigger.new);
        }

        //ON AFTER UPDATE
        if (Trigger.isUpdate && Trigger.isAfter) {
            handler.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
        }

        //ON BEFORE UPDATE
        else if (Trigger.isUpdate && Trigger.isBefore) {
            handler.onBeforeUpdate (Trigger.new, Trigger.oldMap);
        }

    	// //ON BEFORE INSERT
        // //Se comenta esta parte porque no se dispara el 'trigger before insert' ni para Task ni para Events
        // else if (Trigger.isInsert && Trigger.isBefore){
    	//     handler.onBeforeInsert(Trigger.new);
         // }
    }

    if (Trigger.isInsert && Trigger.isAfter)
    {
        DTM_Task_Helper.processTask(Trigger.new, 'CREATE');
    }

    if (Trigger.isUpdate && Trigger.isAfter)
    {
        DTM_Task_Helper.processTask(Trigger.new, 'MODIFY');
        if (byPass.CIB_skip_trigger__c) {
            List<Task> dmtTasks = DES_RecordType_Utils.filter((List<SObject>) Trigger.new, 'Task', 'DMT_Step_Approval');
            if (!dmtTasks.isEmpty()) {
                ActivitiesUtils.updateLineFromTask(dmtTasks);
            }
        }
    }
    
}