@isTest
/*
  Test class 2 for Email Service 
*/
public class EmailService_TEST2 {
    
    /*Email Addres Routing Rules*/
    public static final string EMAIL_ROUTING = 'cds@bbva.com';
    /*Constant aplicationpdf*/
    public static final string PDF = 'application/pdf';
    /*Constant filename*/
    public static final string FILENAME = 'filename';
    /* Constant Min size Attachment*/
    public static final integer SIZE = 3000;
    /*Constant plaintextbody*/
    public static final string PLAIN_TEXT = 'plaintextbody7';
    /*Constant subject*/
    public static final string SUBJECT = 'subject7';
    /*Constant Email*/
    public static final string FROM_EMAIL = 'fromaddress7@email.com';
    
    /*-------------------------------------------------------------------------------
    Description:   Method that executes the creation of an email with binary attachment.
    ---------------------------------------------------------------------------------*/ 
    public static Messaging.InboundEmail.BinaryAttachment binaryAtt() {
        final Messaging.InboundEmail.BinaryAttachment batt = new Messaging.InboundEmail.BinaryAttachment();
        batt.body = Blob.valueof('body');
        batt.filename = FILENAME;
        batt.headers = new List<Messaging.InboundEmail.Header>();
        final Messaging.InboundEmail.Header bacontenttype = new Messaging.InboundEmail.Header();
        final Messaging.InboundEmail.Header bacontentid = new Messaging.InboundEmail.Header();
        final Messaging.InboundEmail.Header baconttransfcod= new Messaging.InboundEmail.Header();
        batt.headers.add(bacontenttype);
        batt.headers.add(bacontentid);
        batt.headers.add(baconttransfcod);
        batt.mimetypesubtype = PDF;
        return batt;
    }
    /*-------------------------------------------------------------------------------
    Description:   Method that executes the creation of an email with text attachment.
    ---------------------------------------------------------------------------------*/ 
    public static Messaging.InboundEmail.TextAttachment textAtt() {
        final Messaging.InboundEmail.TextAttachment tta = new Messaging.InboundEmail.TextAttachment();
        tta.body = 'body';
        tta.charset = 'UTF-8';
        tta.bodyIsTruncated = true;
        tta.filename = FILENAME;
        tta.headers = new List<Messaging.InboundEmail.Header>();
        final Messaging.InboundEmail.Header tacontenttype = new Messaging.InboundEmail.Header();
        final Messaging.InboundEmail.Header tacontentid = new Messaging.InboundEmail.Header();
        final Messaging.InboundEmail.Header taconttransfcod = new Messaging.InboundEmail.Header();
        tta.headers.add(tacontenttype);
        tta.headers.add(tacontentid);
        tta.headers.add(taconttransfcod);
        tta.mimetypesubtype = PDF;
        return tta;
    }

    @isTest
    /*-------------------------------------------------------------------------------
    Description:   Method that executes the creation of email duplicity.
    ---------------------------------------------------------------------------------*/ 
    public static void fullFlowDuplicity() {
        EmailService_TestUtils.bypassall();
        final Messaging.InboundEmail email = new Messaging.InboundEmail();
        final Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'fromaddress8@email.com';
        envelope.toaddress = 'From8';
        final List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        final Messaging.InboundEmail.Header messageid = new Messaging.InboundEmail.Header();
        messageid.name = 'Message-ID8';
        messageid.value = 'messageid8';
        headers.add(messageid);
        email.fromAddress = 'fromaddress8@email.com';
        email.headers = headers;
        email.subject = 'Subject8';
        email.htmlBody = 'htmlbody8';
        email.plainTextBody = 'plaintextbody8';
        EmailService_TestUtils.loadEmailSettings();
        EmailService_TestUtils.loadFilters();
        final EmailService emailservicengine = new EmailService();  
        final Messaging.InboundEmailResult result = emailservicengine.handleInboundEmail(email,envelope);
        final Messaging.InboundEmailResult result2 = emailservicengine.handleInboundEmail(email,envelope);
        system.assertnotEquals(result,null);
        system.assertnotEquals(result2,null);
    }
    
    @isTest
    /*-------------------------------------------------------------------------------
    Description:   Method that executes the creation of email fake duplicity.
    ---------------------------------------------------------------------------------*/ 
    public static void fullFlowFakeDuplicity() {
        EmailService_TestUtils.bypassall();
        final Messaging.InboundEmail email = new Messaging.InboundEmail();
        final Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'fromaddress9@email.com';
        envelope.toaddress = 'From9';
        final List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        final Messaging.InboundEmail.Header messageid = new Messaging.InboundEmail.Header();
        messageid.name = 'Message-ID9';
        messageid.value = 'messageid9';
        headers.add(messageid);
        email.fromAddress = 'fromaddress9@email.com';
        email.headers = headers;
        email.subject = 'Subject9';
        email.htmlBody = 'htmlbody9';
        email.plainTextBody = 'plaintextbody9';
        EmailService_TestUtils.loadEmailSettings();
        EmailService_TestUtils.loadFilters();
        final EmailService emailservicengine = new EmailService(); 
        final Messaging.InboundEmailResult result = emailservicengine.handleInboundEmail(email,envelope);
        email.htmlBody = 'different htmlbody';
        email.plainTextBody = 'different plaintextbody';
        final Messaging.InboundEmailResult result2 = emailservicengine.handleInboundEmail(email,envelope);
        system.assertnotEquals(result,null);
        system.assertnotEquals(result2,null);
    }
}