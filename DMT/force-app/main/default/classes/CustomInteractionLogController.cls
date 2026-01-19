/*
*Author       JSS
*Date         2016/08/01
*Description  Controlador para la pagina SoftphoneCAServerCTI.page con el método para guardar las Tasks con la información de las llamadas
*Version      2019/01/31 Cuando se crea la Task se añaden los campos de Global Markets (Area, Business Line, Country)
*Version      2019/02/28 Cuando se crea la Task se añade un nuevo campo de Global Markets (Product) 
*/
public with sharing class CustomInteractionLogController {
    /**
    * @description  Task para insertar necesaria para mostrarlo en el formulario la visualforce
    */
	public Task callLog {get;set;}

    /**
    * @description  RelatedTo para relacionar con la Task necesaria para mostrarlo en picklist del formulario la visualforce
    */
    public String callLogRelatedTo {get;set;}
    // ---------------
    //Constructor
    // --------------- 
    /**
    * @author       JSS
    * @date         2016/08/01
    * @description  Constructor que recibe como parametro un CAServerCallContact.
                    Es necesario para utilizarlo en la pagina SoftphoneCAServerCTI ya que esta tiene como controlador principal la clase "CAServerCallContact"
    */    
    public CustomInteractionLogController (CAServerCallContact controller) {
        system.debug(Logginglevel.INFO,'>>>>>>> Constructor CustomInteractionLogController: ' + controller);
    }

    // ---------------  
    //public Methods
    // ---------------
        
   
    // ---------------  
    //private Methods
    // ---------------



    // ---------------  
    //Remote Action Methods
    // ---------------   

    /**
    * @author       JSS
    * @date         2016/08/01
    * @description  Crea las task(Call)
    * @Revision     
                    2019/01/31 Cuando se crea la Task se añaden los campos de Global Markets (Area, Business Line, Country) 
    */       
    @RemoteAction
    public static Task saveCallLog(String callLogComments, String callLogRelatedTo, String callLogType, String callLogObjectId, Integer callLogDuration, String callNumber) {  
        final User currentUserInfo = [Select Id, Name, ProfileId, UserRoleId, Asset_Class__c, Business_area_desc__c, Business_line_desc__c, coverage_country_name__c, solution_name_path_desc__c FROM User Where Id = :UserInfo.getUserId()];
        final Task newTask = new Task();
	        newTask.Subject = 'Call ' + Datetime.now().format('dd/MM/yyyy HH:mm');
	        newTask.Asset_Class__c = (currentUserInfo.Asset_Class__c != null ? currentUserInfo.Asset_Class__c.split(';')[0] : null);
	        //newTask.Call_Category__c = callLogCategory;
	        newTask.Call_Number__c = callNumber;
	        newTask.CallDurationInSeconds = callLogDuration;
	        newTask.CallObject = callLogObjectId;
	        newTask.CallDisposition = 'CTI Call - Successful';
	        newTask.CallType = callLogType;
            newTask.Call_Category__c = 'Answered';
	        newTask.Status = 'Completed';
	        newTask.Priority = 'Normal';
	        newTask.Type = 'Call';
	        newTask.Description = callLogComments;
	        if(callLogRelatedTo.startsWith('001')) {
	        	newTask.WhatId  = callLogRelatedTo;	
	        } else {
	        	newTask.WhoId  = callLogRelatedTo;
	        }	        
	        newTask.ActivityDate = date.today();	        
	        newTask.OwnerId  = currentUserInfo.Id;
            newTask.Business_area_desc__c = currentUserInfo.Business_area_desc__c;
            newTask.Business_line_desc__c = currentUserInfo.Business_line_desc__c;
            newTask.coverage_country_name__c = currentUserInfo.coverage_country_name__c;
            newTask.solution_name_path_desc__c = currentUserInfo.solution_name_path_desc__c;

            newTask.recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(Label.DES_RT_CTI_CALL_TASK).getRecordTypeId();    
        insert newTask;

        return newTask; 
    }
       

}