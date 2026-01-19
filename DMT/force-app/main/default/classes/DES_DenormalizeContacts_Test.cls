/***********************************************************************************************************************************************
Name:           DES_DenormalizeContacts_Test 
Description:    Clase test para las clases:
					- SER_Contact_TRIGGER.trigger
					- ContactTriggerHandler
					- DES_DenormalizeContactsExecute
					- DES_AggregateResultIterator
					- DES_AggregateResultIterator

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------------------
0.1            12/12/2018      Accenture         Class creation    
0.2            19/12/2018      Accenture         Cambios para arreglar problemas detectados por SONAR en la compilación al subir a Bitbucket
************************************************************************************************************************************************/
@isTest
public class DES_DenormalizeContacts_Test {
	@isTest
	public static void DES_TriggerHandlerContactTest() {

			//Datos necesarios
			Final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
			
				//Accounts		
			Final List<Account> listaCuentas = new List<Account>();			
			Final Account accGroup = utilTestClass.createClient();
					accGroup.DES_Structure_Type__c			=Label.DES_STR_TYPE_Subsidiary;
					accGroup.DES_BBVA_Segmentation__c		=Label.DES_Segmentation_B_BEC;
					accGroup.DES_Group_Code__c				='GroupCode';
					accGroup.RecordTypeId					=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
			
			listaCuentas.add(accGroup);			
			Final Account accSubsidiary = utilTestClass.createClient();
					accSubsidiary.DES_Structure_Type__c		=Label.DES_STR_TYPE_Supragroup;
					accSubsidiary.DES_BBVA_Segmentation__c	=Label.DES_Segmentation_B_BEC;
					accSubsidiary.SER_CClient__c			='CClient';
					accGroup.RecordTypeId 					=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Subsidiary').getRecordTypeId();
			
			listaCuentas.add(accSubsidiary);	
			insert listaCuentas;
			
				//Relacion entre accounts			
			Final dwp_acmh__GBL_Account_Relationship__c  relationAcc = new 	dwp_acmh__GBL_Account_Relationship__c (
																		dwp_acmh__Parent_Account__c	=accGroup.Id,
																		dwp_acmh__Child_Account__c	=accSubsidiary.Id,
																		CurrencyIsoCode				='EUR',
																		dwp_acmh__Type__c			='03 - Filial',
																		dwp_acmh__Vision__c 		='Negocio',
																		DES_Participacion__c 		=100
																		);
        	insert relationAcc;
																	
				//Contacts
			Final Contact contact = utilTestClass.createContact(accSubsidiary);
					contact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Desktop Contact').getRecordTypeId();				
						
            //Prueba del test
            Test.startTest();
				insert contact;
            Test.stopTest();
        
            //Assertions para verificar
            Final List<AccountContactRelation> listACR = [Select Id From AccountContactRelation Where ContactId = :contact.Id];
            System.assertEquals(listACR.size(),2);
	}
    
    
	@isTest
	public static void DES_BatchDenormContactTest() {

			//Datos necesarios
			Final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
			
			//Accounts		
			Final List<Account> listaCuentas = new List<Account>();
			
			Final Account accGroup = utilTestClass.createClient();
					accGroup.DES_Structure_Type__c			=Label.DES_STR_TYPE_Subsidiary;
					accGroup.DES_BBVA_Segmentation__c		=Label.DES_Segmentation_B_BEC;
					accGroup.DES_Group_Code__c				='GroupCode';
					accGroup.RecordTypeId					=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
					accGroup.DES_Structure_Type__c 			='Group';

			listaCuentas.add(accGroup);
			
			Final Account accSubsidiary = utilTestClass.createClient();
					accSubsidiary.DES_Structure_Type__c		=Label.DES_STR_TYPE_Supragroup;
					accSubsidiary.DES_BBVA_Segmentation__c	=Label.DES_Segmentation_B_BEC;
					accSubsidiary.SER_CClient__c			='CClient';
					accSubsidiary.RecordTypeId 				=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Subsidiary').getRecordTypeId();
					accSubsidiary.DES_Structure_Type__c 	='Subsidiary';
			
			listaCuentas.add(accSubsidiary);	

			insert listaCuentas;
			System.debug('>>>>>>>>>>>>>>>>> listaCuentas: ' + listaCuentas);
			
			//Relacion entre accounts			
			Final dwp_acmh__GBL_Account_Relationship__c  relationAcc = new 	dwp_acmh__GBL_Account_Relationship__c (
																		dwp_acmh__Parent_Account__c	=accGroup.Id,
																		dwp_acmh__Child_Account__c	=accSubsidiary.Id,
																		CurrencyIsoCode				='EUR',
																		dwp_acmh__Type__c			='03 - Filial',
																		dwp_acmh__Vision__c 		='Negocio',
																		DES_Participacion__c 		=100
																		);
        	insert relationAcc;
																	
			//Contacts
			Final Contact contact = utilTestClass.createContact(accSubsidiary);
					contact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Desktop Contact').getRecordTypeId();
					contact.CurrencyIsoCode = 'EUR';			
			insert contact;
			
				// Para testear el Batch -> eliminamos lo que haya creado el Trigger
        	Final List<AccountContactRelation> acrList = [Select Id, AccountId, ContactId, Roles, IsDirect, IsActive, StartDate, EndDate, CurrencyIsoCode, BKP_ACR_Backup_External_Id__c From AccountContactRelation Where IsDirect = false];			
			delete acrList;
			
            //Prueba del test
            Test.startTest();
            	Final Id batchInstanceId	= Database.executeBatch(new DES_DenormalizeContactsExecute(), 5);
            	System.debug('>>>>> Terminado test proceso batch: ' + batchInstanceId);
            Test.stopTest();
        
            //Assertions para verificar
            Final List<AccountContactRelation> listACR = [Select Id From AccountContactRelation Where ContactId = :contact.Id];
            System.assertEquals(listACR.size(),2);

	}    
}