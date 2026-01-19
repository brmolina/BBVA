/*
    @Author : Juan Carlos Terrón ruiz
    @Class : Clase de test para el controllador apex SER_EmailThreadPDF_CTRL
*/
@isTest
public class SER_EmailThreadPDF_CTRL_TEST {

  /*
    @Value/Usage : Valor del subject del email
  */
  public static final String TESTSUBJECT = 'test';
  /*
    @Value/Usage : Valor del cuerpo html del email
  */
  public static final String TESTHTMLBODY = 'htmlbody';
  /*
    @Value/Usage : Valor del cuerpo de texto del email
  */
  public static final String TESTTEXTBODY = 'textbody';
  /*
    @Value/Usage : Dirección de salida del email
  */
  public static final String FROMADD = 'fromaddress@email.com';
  /*
    @Value/Usage : Direcciones en copia
  */
  public static final String CCADD = 'ccaddress@email.com';
  /*
    @Value/Usage : Destinatarios
  */
  public static final String TOADD = 'toaddress@email.com';
  /*
    @Value/Usage : Direcciones en copia oculta
  */
  public static final String BCCADD = 'bccaddress@email.com';
  /*
    @Author : Juan Carlos Terrón ruiz
    @Method : Testeo de la casuística más comun, hay emails y todos tienen el cuerpo relleno
  */
  @isTest
  public static void test() {
    Test.startTest();
    final Case testcase = new case ();
                          testcase.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('GM User').getRecordTypeId();
                          final EmailMessage email = new EmailMessage();
                          testcase.SER_Business_Case_Type__c = 'GM';
                          testcase.subject = SER_EmailThreadPDF_CTRL_TEST.TESTSUBJECT;
                          email.Incoming = true;
                          email.subject = SER_EmailThreadPDF_CTRL_TEST.TESTSUBJECT;
                          email.htmlbody = SER_EmailThreadPDF_CTRL_TEST.TESTHTMLBODY;
                          email.textbody = SER_EmailThreadPDF_CTRL_TEST.TESTTEXTBODY;
                          email.threadidentifier = 'threadidentifier';
                          email.fromaddress = SER_EmailThreadPDF_CTRL_TEST.FROMADD;
                          email.toaddress = SER_EmailThreadPDF_CTRL_TEST.TOADD;
                          email.ccaddress = SER_EmailThreadPDF_CTRL_TEST.CCADD;
                          email.bccaddress = SER_EmailThreadPDF_CTRL_TEST.BCCADD;
                          insert testcase;
                          final ApexPages.StandardController stdController = new ApexPages.StandardController(testcase);
                          final SER_EmailThreadPDF_CTRL vccall = new SER_EmailThreadPDF_CTRL();
                          final SER_EmailThreadPDF_CTRL nvccall = new SER_EmailThreadPDF_CTRL(stdController);
                          email.ParentId = testcase.Id;
                          insert email;
                          final SER_EmailThreadPDF_CTRL nonvoidemaillist = new SER_EmailThreadPDF_CTRL(stdController);//NOSONAR
                          final EmailMessage emailnullhbody = new EmailMessage();
                          emailnullhbody.Incoming = true;
                          emailnullhbody.subject = SER_EmailThreadPDF_CTRL_TEST.TESTSUBJECT;
                          emailnullhbody.textbody = SER_EmailThreadPDF_CTRL_TEST.TESTTEXTBODY;
                          emailnullhbody.threadidentifier = 'threadidentifier';
                          emailnullhbody.fromaddress = SER_EmailThreadPDF_CTRL_TEST.FROMADD;
                          emailnullhbody.toaddress = SER_EmailThreadPDF_CTRL_TEST.TOADD;
                          emailnullhbody.ccaddress = SER_EmailThreadPDF_CTRL_TEST.CCADD;
                          emailnullhbody.bccaddress = SER_EmailThreadPDF_CTRL_TEST.BCCADD;
                          emailnullhbody.ParentId = testcase.Id;
                          insert emailnullhbody;
                          SER_EmailThreadPDF_CTRL nullhbody = new SER_EmailThreadPDF_CTRL(stdController);//NOSONAR
                          final Boolean assert = nullhbody !=null && vccall != null && nvccall != null && nonvoidemaillist != null;
                          system.assert (assert,'all tests were good');
                          test.stopTest();
  }
  /*
    @Author : Juan Carlos Terrón ruiz
    @Method : Testeo de la casuística menos comun, no hay emails y si hay algunos tienen el cuerpo vacío
  */
  @istest
  public static void test2() {
    Test.startTest();
    final Case testcase = new case ();
                          testcase.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('GM User').getRecordTypeId();
                          final EmailMessage email = new EmailMessage();
                          testcase.SER_Business_Case_Type__c = 'GM';
                          testcase.subject = SER_EmailThreadPDF_CTRL_TEST.TESTSUBJECT;
                          email.Incoming = true;
                          email.subject = SER_EmailThreadPDF_CTRL_TEST.TESTSUBJECT;
                          email.htmlbody = SER_EmailThreadPDF_CTRL_TEST.TESTHTMLBODY;
                          email.textbody = SER_EmailThreadPDF_CTRL_TEST.TESTTEXTBODY;
                          email.threadidentifier = 'threadidentifier';
                          email.fromaddress = SER_EmailThreadPDF_CTRL_TEST.FROMADD;
                          email.toaddress = SER_EmailThreadPDF_CTRL_TEST.TOADD;
                          email.ccaddress = SER_EmailThreadPDF_CTRL_TEST.CCADD;
                          email.bccaddress = SER_EmailThreadPDF_CTRL_TEST.BCCADD;
                          insert testcase;
                          final ApexPages.StandardController stdController = new ApexPages.StandardController(testcase);
                          final SER_EmailThreadPDF_CTRL vcc = new SER_EmailThreadPDF_CTRL();
                          final SER_EmailThreadPDF_CTRL nvcc = new SER_EmailThreadPDF_CTRL(stdController);
                          final Boolean assert = vcc != null && nvcc != null;
                          system.assert (assert,'assert right');
                          test.stopTest();
  }
}