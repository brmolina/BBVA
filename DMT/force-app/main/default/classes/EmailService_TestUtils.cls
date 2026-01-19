global with sharing class EmailService_TestUtils { //NOSONAR

  /*Email Addres Routing Rules*/
  public static final string EMAIL_ROUTING = 'cds@bbva.com';
  /*-------------------------------------------------------------------------------
    Description:   Method to skip all validation and process.
  ---------------------------------------------------------------------------------*/ 
  public static void bypassall() {
    final CIB_ByPass__c bypassinstance = new CIB_ByPAss__c();
    bypassinstance.CIB_migration__c = false;
    bypassinstance.CIB_skip_assert__c = true;
    bypassinstance.CIB_skip_trigger__c = true;
    bypassinstance.CIB_skip_validationrule__c = true;
    bypassinstance.CIB_skip_workflow__c = true;
    bypassinstance.CIB_stop_job__c = false;
    bypassinstance.CIB_DES_DataMigration__c = false;
    bypassinstance.CIB_DES_skip_trigger_in_denorm__c = false;
    bypassinstance.CIB_DES_Delete_Opp_Permission__c = false;
    bypassinstance.SetupOwnerId = UserInfo.getUserId();
    insert bypassinstance;
  }

  /*-------------------------------------------------------------------------------
    Description:   Method that loads Custom Setting RoutingRule for GM.
  ---------------------------------------------------------------------------------*/ 
  public static void loadFilters() {
    final EmailServiceRoutingRule__c filter = new EmailServiceRoutingRule__c();
    filter.name = 'FilterName';
    filter.subject__c = 'Subject';
    filter.FromAddress__c = 'fromaddress@email.com';
    filter.Mailbox__c = EMAIL_ROUTING;
    filter.BusinessType__c = 'GM';
    insert filter;
  }

  /*-------------------------------------------------------------------------------
    Description:   Method that loads the mailbox settings for GM.
  ---------------------------------------------------------------------------------*/ 
  public static void loadEmailSettings() {
    final SER_EmailDefaultValues_Assignment__c emailsetting = new SER_EmailDefaultValues_Assignment__c();
    emailsetting.Name = 'emailsetting';
    emailsetting.SER_BusinessType__c = 'GM';
    emailsetting.SER_FromAddres__c = EMAIL_ROUTING;
    emailsetting.SER_MailingGroup__c = 'ALL FI & RV & Derivatives';
    emailsetting.SER_OutboundFromAddress__c = EMAIL_ROUTING;
    emailsetting.SER_OutboundMailbox__c = 'Email CDS';
    emailsetting.SER_Queue__c = 'SER_Settlement_CDS';
    final SER_EmailDefaultValues_Assignment__c defaultgmsetting = new SER_EmailDefaultValues_Assignment__c();
    defaultgmsetting.Name = 'defaultgmsetting';
    defaultgmsetting.SER_BusinessType__c = 'GM';
    defaultgmsetting.SER_FromAddres__c = Label.SER_CustomerServiceMailbox;
    defaultgmsetting.SER_MailingGroup__c = 'Customer & Claim Support';
    defaultgmsetting.SER_OutboundFromAddress__c = Label.SER_CustomerServiceMailbox;
    defaultgmsetting.SER_OutboundMailbox__c = 'Email Customer Support GM';
    defaultgmsetting.SER_Queue__c = 'SER_Customer_Support';

    insert emailsetting;
    insert defaultgmsetting;
  }

}