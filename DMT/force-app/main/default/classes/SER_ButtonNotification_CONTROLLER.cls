/**
  * VASS Latam
  * @author            Victor Velandia victor.velandia@vass.es
  * Project:           BBVA Service
  * Description:       Clase Controller SER_ButtonNotification_CONTROLLER - SER_ButtonNotification para mostrar botones en Page Layout
  *
  *            No.     Date            Author                  Description
  *            -----   ----------      --------------------    ---------------
  * @version   1.0     2018-07-31      Victor Velandia (VV)    Clase Controller SER_ButtonNotification
  **************************************************************************************************************************************/
public with sharing class SER_ButtonNotification_CONTROLLER {

  /**
    * description: String Constant for Success Message Email Notification
    * @author Victor Velandia
    */
  private static final string STRENOTSUCCMESS    = System.label.SER_EmailNotificationSuccesMessage;
  /**
    * description: String Constant for Error Message Email Notification
    * @author Victor Velandia
    */
  private static final string STRENOTERRMESS             = System.label.SER_EmailNotificationErrorMessage;
  /**
    * description: String Constant for Error Message Catch
    * @author Victor Velandia
    */
  private static final string STRERRORMESSAGE    = System.label.SER_EmailNotificationErrorMessage;
  /**
    * description: Private Constructor
    * @author Juan Carlos Terrón Ruiz
    */
  private SER_ButtonNotification_CONTROLLER() {
  }

  /**
    * description: getCase
    * @author Victor Velandia
    */
  @AuraEnabled
  public static Case getCase( Id caseId ) {       //NOSONAR
    //make your own SOQL here from your desired object where you want to place your lightnign action
    Case sqlCase    =       new Case();
    sqlCase                 =       [Select Id, Status, SER_SendFirstContactEmail__c, SER_Send_email_close_master_case__c, SER_Outbound_Mailbox__c From Case Where Id = :caseId];
    return sqlCase;
  }

  /**
    * description: updateCallCaseEmailNotifications
    * @author Victor Velandia
    */
  @AuraEnabled
  public static AuraProcessingMessage updateCallCaseEmailNotifications( Case emailNotifiCase ) {       //NOSONAR
    //you can make your own update here.
    Savepoint svpoint;
    svpoint = Database.setSavepoint();
    //Initializing the wrapper message
    AuraProcessingMessage returnMessage;
    returnMessage = new AuraProcessingMessage();
    try {
      if( emailNotifiCase.Status == System.label.SER_Closed ) {
        emailNotifiCase.SER_Send_email_close_master_case__c = True;
        returnMessage.strSuccessMsg = STRENOTSUCCMESS;
      } else {
        returnMessage.blnIsSuccess = false;
        returnMessage.strErrorMsg = STRENOTERRMESS;
      }
    } catch( Exception ex ) {
      system.debug('Debug Exception Message'+ ex.getMessage());
      returnMessage.blnIsSuccess = false;
      returnMessage.strErrorMsg = STRERRORMESSAGE + ex.getMessage();
      //Adding the error message if an exception is occured
      //Rollback the transaction if an exception is occured
      Database.rollback( svpoint );
    }
    //Upsert del caso
    Upsert emailNotifiCase;
    //Return the error message
    return returnMessage;
  }

  /************************************************************
      Name:		AuraProcessingMessage
      Type:		Wrapper  Class
      Purpose:	Wrapper  Class to error and success message to
                          display in  lightning component SER_ButtonNotification
    ***********************************************************/
  public class AuraProcessingMessage {

    /**
      * description: boolean blnIsSuccess;
      * @author Victor Velandia
      */
    @AuraEnabled public boolean blnIsSuccess { get; set; }
    /**
      * description: string strErrorMsg
      * @author Victor Velandia
      */
    @AuraEnabled public string strErrorMsg { get; set; }
    /**
      * description: string strSuccessMsg
      * @author Victor Velandia
      */
    @AuraEnabled public string strSuccessMsg { get; set; }
    /**
      * description: AuraProcessingMessage
      * @author Victor Velandia
      */
    public AuraProcessingMessage() {
      this.blnIsSuccess               = true;
      this.strErrorMsg                = '';
      this.strSuccessMsg              = '';
    }
  }
}