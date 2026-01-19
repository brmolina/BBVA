/**********************************************************************************
* @author  		VASS     
* @date         
* @description  Batch que genera todos los Apex Sharing para el equipo de cuenta de los objetos de oportunidad, el kit de visitas y las commercial alerts
* @Revision     
**********************************************************************************/
public without sharing class Batch_CreateAllApexSharing implements Database.Batchable<Sobject>, Database.Stateful {
    final ApexSharing_Utils apexSharingUtils = ApexSharing_Utils.getInstance();
    private String pQuery = 'SELECT Id, Name, RecordTypeId, DES_Client__c, DES_BBVA_Internal_Code__c, DES_BBVA_User_Code__c, DES_Clave_Externa__c, DES_Clon_de__c, DES_First_Name__c, DES_Last_Name__c, DES_Local_Banker_Country__c, DES_Member_Role__c, DES_PS_Product_Family__c, DES_PS_Product__c, DES_Provisioning_Method__c, DES_Registro_actualizado__c, copy_record_approval_type__c, DES_User_Country__c, DES_User__c, DES_User_email__c, DES_User_email_text__c, DES_User_phone__c, DES_phone__c, DES_Tipo_de_cobertura__c, approbation_process_status__c, login_access_type__c, member_employee_dept_desc__c  FROM DES_BBVA_Management_team__c ' + (Test.isRunningTest()?' LIMIT 1':'');
    
    public Batch_CreateAllApexSharing(){
        system.debug('>>>>> pQuery : ' + pQuery);
    }
    
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(pQuery);
    }
    
    
    public void execute(Database.BatchableContext bc,List<DES_BBVA_Management_team__c> scope){
    	
    	system.debug('>>>>> scope : ' + scope);
    	apexSharingUtils.createManualSharing(scope);
    	
    }//FIN execute

    public void finish(Database.BatchableContext bc){    }
    
}