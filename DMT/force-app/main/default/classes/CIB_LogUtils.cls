/**
* Project:           BBVA
* Description:       Clase Controller CIB_LogUtils
*
*            No.     Date            Author                  Description
*            -----   ----------      --------------------    ---------------
* @version   1.1     2020-03-23      Cintia Carmona 	     Ajuste Clase Sonar
******************************************************************************/
public with sharing class CIB_LogUtils {

 /**
 * description: CIB_LogUtils
 */
  	private CIB_LogUtils(){
    // Constructor
    }

  /**
  * description: create_Log
  */
	public static void create_Log(Exception error, String subject) {
		final CIB_Log__c log = new CIB_Log__c();

		log.CIB_Subject__c = subject;
		log.CIB_Type__c = error.getTypeName();
		log.CIB_ErrorMessage__c = error.getMessage();

		insert log;
	}

  /**
  * description: create_Log
  */
	public static void create_Log(String subject, String errMsg) {
		final CIB_Log__c log = new CIB_Log__c();

		log.CIB_Subject__c = subject;
		log.CIB_ErrorMessage__c = errMsg;

		insert log;
	}

  /**
  * description: create_RemedyLog
  */
	public static void create_RemedyLog(String subject, String recordId, String remedyUser) {
		final CIB_Log__c log = new CIB_Log__c();

		log.CIB_Subject__c = subject;
		log.CIB_RecordId__c = recordId;
		log.Remedy_User__c = remedyUser;

		insert log;
	}

  /**
  * description: create_RemedyErrorLog
  */
	public static void create_RemedyErrorLog(String subject, String recordId, String remedyUser, String errMsg) {
		final CIB_Log__c log = new CIB_Log__c();

		log.CIB_Subject__c = subject;
		log.CIB_RecordId__c = recordId;
		log.Remedy_User__c = remedyUser;
		log.CIB_ErrorMessage__c = errMsg;

		insert log;
	}	
}