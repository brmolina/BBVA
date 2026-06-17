/*-------------------------------------------------------------------------------
Author:        Juan Carlos Terr�n
Company:       Accenture
Description:   Method that generates Case for Email Service

History:
<Author>                  <Date>                <Change Description>
Juan Carlos Terr�n                              Initial version.
Adrian Salinas (NFQ)     04/02/2026          Uso de Email_Service_Config__mdt para eliminacion de hardcode.
---------------------------------------------------------------------------------*/
public with sharing class EmailService_CaseEngine {
  /* Methods Get/Set Case */
  public Case newCase {get;set;}
  /* Methods Get/Set Email */
  public InboundEmailWrapper currentEmail {get;set;}
  /* Methods Get/Set Custom Setting Outbond Mailbox */
  public SER_EmailDefaultValues_Assignment__c setting {get;set;}
  /* Business case type GM */
  public static final String GM_BUSINESS = 'GM';
  /* Constant integer 1 */
  public static final integer UNO = 1;
  /* Constant limit length*/  
  public static final integer MAXLENGTH = 30000;
  /*Classification query*/
  public static final String CLASSIF_QUERY = 'Query';
  /* Metadata Config */
  private Email_Service_Config__mdt config;
  

/*-------------------------------------------------------------------------------
Author:        Juan Carlos Terr�n
Company:       Accenture
Description:   Method Case Engine
    IN: currentEmail
    OUT: -
History:
<Author>                  <Date>                <Change Description>
Juan Carlos Terr�n                              Initial version.
---------------------------------------------------------------------------------*/
  public EmailService_CaseEngine(InboundEmailWrapper currentEmail) {
    this.newCase = new Case();
    this.currentEmail = currentEmail;
    this.setting = new SER_EmailDefaultValues_Assignment__c();
    this.config = EmailServiceUtils.getConfig();
  }
/*-------------------------------------------------------------------------------
Author:        Juan Carlos Terr�n
Company:       Accenture
Description:   Method Create Case
---------------------------------------------------------------------------------*/
  public Id createCase() {
    Id result;
    try {
			final Id rtId = this.getRecordTypeId();
			this.newCase.subject = currentEmail.email.subject;
      system.debug('EmailService_CaseEngine - Create Case - Subect :  '+this.newCase.subject);//NOSONAR
      this.newCase.SuppliedEmail = currentemail.Sender;
      system.debug('EmailService_CaseEngine - Create Case - SuppliedEmail :  '+this.newCase.SuppliedEmail);//NOSONAR
			//this.newCase.SER_EmailToCaseCode__c = currentEmail.reference;
      //system.debug('EmailService_CaseEngine - Create Case - SER_EmailToCaseCode__c:  '+this.newCase.SER_EmailToCaseCode__c);//NOSONAR
			this.newCase.SER_MailingGroup__c = setting.SER_MailingGroup__c;
      system.debug('EmailService_CaseEngine - Create Case - SER_MailingGroup__c :  '+this.newCase.SER_MailingGroup__c);//NOSONAR
			this.newCase.SER_Outbound_Mailbox__c = setting.SER_OutboundMailbox__c;
      system.debug('EmailService_CaseEngine - Create Case - SER_Outbound_Mailbox__c :  '+this.newCase.SER_Outbound_Mailbox__c);//NOSONAR
			final Group cola = [select Id, Name from Group where Developername = :setting.SER_Queue__c limit 1][0];
			this.newCase.OwnerId = cola.Id;
      system.debug('EmailService_CaseEngine - Create Case - OwnerId:  '+this.newCase.OwnerId);//NOSONAR
      this.newcase.Origin = setting.SER_Origin__c;
      this.newCase.SER_Skip_validations__c = true;
      system.debug('EmailService_CaseEngine - Create Case - Origin :  '+this.newcase.Origin);//NOSONAR
			//this.newCase.Origin = 'Email';
			this.newCase.SER_Business_Case_Type__c = this.setting.SER_BusinessType__c;
      system.debug('EmailService_CaseEngine - Create Case - SER_Business_Case_Type__c :  '+this.newCase.SER_Business_Case_Type__c);//NOSONAR
      //this.newCase.SER_Classification__c = 'Queries';
      this.newCase.SER_Classification__c = this.config.Default_Classification__c;
      system.debug('EmailService_CaseEngine - Create Case - SER_Classification__c :  '+this.newCase.SER_Classification__c);//NOSONAR
      if(currentEmail.textBody!=null) { this.cutShortDescription(this.newCase, currentEmail.textBody.stripHtmlTags());}
          
      this.newCase.RecordTypeId = rtId;
      this.getContact();

			insert this.newCase;
			result =  this.newCase.Id;
		} catch (Exception error) {
			system.debug('Create Case Error: '+error.getMessage());//NOSONAR
      system.debug('Create Case Error Stack Trace '+error.getStackTraceString());//NOSONAR
		}
    return result;
  }

    /*
* Author: Miriam Simon
* Company: UST
* Description:  Method to cut short description field.
*/
    private void cutShortDescription (Case caseShortDes, String description) {
        
        system.debug('EmailService_CaseEngine - Create Case - description sin html length:  '+description.length());//NOSONAR
        if (description.length() > MAXLENGTH) {
            final String endEmailLabel = Label.SER_EndBodyEmailSTE; //(Too long description , to see the rest of the content go to email)
            caseShortDes.Description = description.substring(0, MAXLENGTH-endEmailLabel.length()-2) + ' ' + endEmailLabel;
        } else {
            caseShortDes.Description = description;
        }
        system.debug('EmailService_CaseEngine - Create Case - description :  '+caseShortDes.Description);//NOSONAR
    }

/*-------------------------------------------------------------------------------
Author:        Juan Carlos Terr�n
Company:       Accenture
Description:   Method get RecordTyeId
---------------------------------------------------------------------------------*/
  private Id getRecordTypeId() {
      // return Schema.SObjectType.Case.getRecordTypeInfosByName().get('GM User').getRecordTypeId();
      return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(this.config.Case_RT_DevName__c).getRecordTypeId();
      
  }
  private void getContact() {
    final String emailsender = this.currentEmail.Sender;
    system.debug('EmailService_CaseEngine - Get Contact - Email Sender :  '+emailsender);//NOSONAR
    final List<Contact> contacts = new List<Contact>();
    for(Contact cnt : [select Id from Contact where Email_ExternalID__c = :emailsender]) {
      contacts.add(cnt);
    }
    if(contacts.isempty()) {
    System.debug('New Contact');//NOSONAR
    } else if(contacts.size() == UNO) {
      this.newCase.contactId = contacts[0].Id;
      system.debug('EmailService_CaseEngine - Get Contact - Contact Id :  '+this.newCase.contactId);//NOSONAR
    }
  }
}