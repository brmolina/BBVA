@isTest
/*
  Test class for Email Service 
*/
public class EmailService_TEST {
    
    /*Email Address Routing Rules*/
    public static final string EMAIL_ROUTING = 'cds@bbva.com';
    /*Constant Email From Address*/
    public static final string FROM_ADD = 'fromaddress@email.com';
    @isTest
    /*-------------------------------------------------------------------------------
    Description:   Method that executes the creation of an email without an address.
    ---------------------------------------------------------------------------------*/ 
    public static void fullFlowNoAddresses() {
        EmailService_TestUtils.bypassall();
        final Messaging.InboundEmail email = new Messaging.InboundEmail();
        final Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = FROM_ADD;
        envelope.toaddress = 'From';
        final List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        final Messaging.InboundEmail.Header messageid = new Messaging.InboundEmail.Header();
        messageid.name = 'Message-ID';
        messageid.value = 'messageid';
        email.fromAddress = FROM_ADD;
        email.headers = headers;
        email.subject = 'no filter';
        email.htmlBody = 'htmlbody';
        email.plainTextBody = 'plaintextbody';
        EmailService_TestUtils.loadEmailSettings();
        EmailService_TestUtils.loadFilters();
        final EmailService emailservicengine = new EmailService();     
        final Messaging.InboundEmailResult result = emailservicengine.handleInboundEmail(email,envelope);
        system.assertnotEquals(result,null);
    }
    @isTest
    /*-------------------------------------------------------------------------------
    Description:   Method that executes the creation of an email without filter.
    ---------------------------------------------------------------------------------*/ 
    public static void fullFlowSingleToAddressNoFilters() {
        EmailService_TestUtils.bypassall();
        final Messaging.InboundEmail email = new Messaging.InboundEmail();
        final Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'fromaddress2@email.com';
        envelope.toaddress = 'From2';
        final List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        final Messaging.InboundEmail.Header messageid = new Messaging.InboundEmail.Header();
        messageid.name = 'Message-ID2';
        messageid.value = 'messageid2';
        headers.add(messageid);
        email.fromAddress = 'fromaddress2@email.com';
        email.headers = headers;
        email.subject = 'no filter2';
        email.htmlBody = 'htmlbody2';
        email.plainTextBody = 'plaintextbody2';
        email.toAddresses = new List<String>{EMAIL_ROUTING};
        EmailService_TestUtils.loadEmailSettings();
        EmailService_TestUtils.loadFilters();
        final EmailService emailservicengine = new EmailService();
        final Messaging.InboundEmailResult result = emailservicengine.handleInboundEmail(email,envelope);
        system.assertnotEquals(result,null);
    }
    @isTest
    /*-------------------------------------------------------------------------------
    Description:   Method that executes the creation of an email with cc address.
    ---------------------------------------------------------------------------------*/ 
    public static void fullFlowSingleccAddressNoFilters() {
        EmailService_TestUtils.bypassall();
        final Messaging.InboundEmail email = new Messaging.InboundEmail();
        final Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'fromaddress3@email.com';
        envelope.toaddress = 'From3';
        final List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        final Messaging.InboundEmail.Header messageid = new Messaging.InboundEmail.Header();
        messageid.name = 'Message-ID3';
        messageid.value = 'messageid3';
        headers.add(messageid);
        email.fromAddress = 'fromaddress3@email.com';
        email.headers = headers;
        email.subject = 'no filter3';
        email.htmlBody = 'htmlbody3';
        email.plainTextBody = 'plaintextbody3';
        email.ccAddresses = new List<String>{EMAIL_ROUTING};
        EmailService_TestUtils.loadEmailSettings();
        EmailService_TestUtils.loadFilters();
        final EmailService emailservicengine = new EmailService();  
        final Messaging.InboundEmailResult result = emailservicengine.handleInboundEmail(email,envelope);
        system.assertnotEquals(result,null);
    }
    @isTest
    /*-------------------------------------------------------------------------------
    Description:   Method that executes the creation of an email with two to address.
    ---------------------------------------------------------------------------------*/ 
    public static void fullFlowDoubleToAddressNoFilters() {
        EmailService_TestUtils.bypassall();
        final Messaging.InboundEmail email = new Messaging.InboundEmail();
        final Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'fromaddress4@email.com';
        envelope.toaddress = 'From4';
        final List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        final Messaging.InboundEmail.Header messageid = new Messaging.InboundEmail.Header();
        messageid.name = 'Message-ID4';
        messageid.value = 'messageid4';
        headers.add(messageid);
        email.fromAddress = 'fromaddress4@email.com';
        email.headers = headers;
        email.subject = 'no filter4';
        email.htmlBody = 'htmlbody4';
        email.plainTextBody = 'plaintextbody4';
        email.toAddresses = new List<String>{EMAIL_ROUTING,Label.SER_CustomerServiceMailbox};
        EmailService_TestUtils.loadEmailSettings();
        EmailService_TestUtils.loadFilters();
        final EmailService emailservicengine = new EmailService();    
        final Messaging.InboundEmailResult result = emailservicengine.handleInboundEmail(email,envelope);
        system.assertnotEquals(result,null);
    }
    @isTest
    /*-------------------------------------------------------------------------------
    Description:   Method that executes the creation of an email with two cc address.
    ---------------------------------------------------------------------------------*/ 
    public static void fullFlowDoubleccAddressNoFilters() {
        EmailService_TestUtils.bypassall();
        final Messaging.InboundEmail email = new Messaging.InboundEmail();
        final Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'fromaddress5@email.com';
        envelope.toaddress = 'From5';
        final List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        final Messaging.InboundEmail.Header messageid = new Messaging.InboundEmail.Header();
        messageid.name = 'Message-ID5';
        messageid.value = 'messageid5';
        headers.add(messageid);
        email.fromAddress = 'fromaddress5@email.com';
        email.headers = headers;
        email.subject = 'no filter5';
        email.htmlBody = 'htmlbody5';
        email.plainTextBody = 'plaintextbody5';
        email.ccAddresses = new List<String>{EMAIL_ROUTING,Label.SER_CustomerServiceMailbox};
        EmailService_TestUtils.loadEmailSettings();
        EmailService_TestUtils.loadFilters();
        final EmailService emailservicengine = new EmailService();   
        final Messaging.InboundEmailResult result = emailservicengine.handleInboundEmail(email,envelope);
        system.assertnotEquals(result,null);
    }
    @isTest
    /*-------------------------------------------------------------------------------
    Description:   Method that executes the creation of an email with a filter.
    ---------------------------------------------------------------------------------*/ 
    public static void fullFlowSingleAddressUniqueFilter() {
        EmailService_TestUtils.bypassall();
        final Messaging.InboundEmail email = new Messaging.InboundEmail();
        final Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'fromaddress6@email.com';
        envelope.toaddress = 'From6';
        final List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        final Messaging.InboundEmail.Header messageid = new Messaging.InboundEmail.Header();
        messageid.name = 'Message-ID6';
        messageid.value = 'messageid6';
        headers.add(messageid);
        email.fromAddress = 'fromaddress6@email.com';
        email.headers = headers;
        email.subject = 'Subject6';
        email.htmlBody = 'htmlbody6';
        email.plainTextBody = 'plaintextbody6';
        EmailService_TestUtils.loadEmailSettings();
        EmailService_TestUtils.loadFilters();
        final EmailService emailservicengine = new EmailService();   
        final Messaging.InboundEmailResult result = emailservicengine.handleInboundEmail(email,envelope);
        system.assertnotEquals(result,null);

    }
    
}