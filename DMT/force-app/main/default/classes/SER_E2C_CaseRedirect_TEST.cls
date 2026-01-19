/*@Author:Juan Carlos Terrón Ruiz
  @Class: Clase de test para probar específicamente los métodos de la clase SER_E2C_CaseRedirect
*/
@isTest
public class SER_E2C_CaseRedirect_TEST {
  /*CSETTING Name*/
  public static final String EMAILMAFF = 'Email Middle Affirmations';
  /*CSETTING Address*/
  public static final String MAFFADD = 'middle.affirmations@grupobbva.com';
  /*Assertion Message*/
  public static final String ASSERTMSG = 'Assertion Failed';
  /*Default Address*/
  public static final String DFLTEMAIL = 'default@email.com';
  /*From Email*/
  public static final String FROMEMAIL = 'fromemail@email.com';
  /*Mailing Group*/
  public static final String CCSUPPORT = 'customer & claim support';
  /*Cola*/
  public static final String SERQUEUE = 'SER_QUEUE';
  /*Email Setting*/
  public static final String EMAILSETTING = 'email setting';
  /*@Author : Juan Carlos Terrón Ruiz
  @Método : Método para testear el método de excepciones definidas.
  */
  @IsTest
  public static void definedExceptions() {
    Test.startTest();//Inicio el test
    final SER_EmailDefaultValues_Assignment__c maff = new SER_EmailDefaultValues_Assignment__c();//Creo el registro de custom setting que aplica a middle affirmations
    maff.Name = SER_E2C_CaseRedirect_TEST.EMAILMAFF;//Añado el nombre
    maff.SER_Queue__c = '	SER_Middle_Affirmations';//Añado la cola
    maff.SER_MailingGroup__c = SER_E2C_CaseRedirect_TEST.EMAILMAFF;//Añado el mailing group
    maff.SER_OutboundMailbox__c = 'Documentation & Validations';//Añado el email outbox
    maff.SER_FromAddres__c = SER_E2C_CaseRedirect_TEST.MAFFADD;//Añado el campo fromaddress
    maff.SER_OutboundFromAddress__c = 'middle.affirmations@grupobbva.com-outbound';//Añado el campo outbound fromaddress
    insert maff;//Inserto el registro de custom setting
    final EmailMessage email = new EmailMessage();//Creo el registro de email message
    email.fromaddress = 'from@email.com';//Añado el campo From
    email.toaddress = SER_E2C_CaseRedirect_TEST.MAFFADD;//Añado el campo toaddress
    final Map<Id,EmailMessage> mapEmails = new Map<Id,EmailMessage>();
    final SER_E2C_CaseRedirect router = new SER_E2C_CaseRedirect(mapEmails);//Creo la instancia de la clase a testear
    final Boolean assert = router.definedExceptions(email);//LLamo al método de la clase a y genero el booleano para hacer el assert
    System.assert (assert,SER_E2C_CaseRedirect_TEST.ASSERTMSG);//Hago el assert
    email.toaddress = 'X'; //Cambio el toaddress para testear otra casuística
    email.ccaddress = 'middle.affirmations@grupobbva.com-outbound'; //Cambio el ccaddress para testear otra casuística
    router.mapCSAddress.remove(SER_E2C_CaseRedirect_TEST.MAFFADD);
    router.definedExceptions(email);
    Test.stopTest();//Finalizo el test
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : Método para testear el método que calcula las direcciones definidas de un email
  */
  @isTest
  public static void getDefinedAddresses() {
    Test.startTest();//Inicio el test
    final SER_EmailDefaultValues_Assignment__c csetting = new SER_EmailDefaultValues_Assignment__c();//Creo el registro de custom setting
    csetting.Name = SER_E2C_CaseRedirect_TEST.EMAILSETTING;//Añado el nombre
    csetting.SER_Queue__c = SER_E2C_CaseRedirect_TEST.SERQUEUE;//Añado la cola
    csetting.SER_MailingGroup__c = SER_E2C_CaseRedirect_TEST.CCSUPPORT;//Añado el mailing group
    csetting.SER_OutboundMailbox__c = SER_E2C_CaseRedirect_TEST.CCSUPPORT;//Añado el email outbox
    csetting.SER_FromAddres__c = SER_E2C_CaseRedirect_TEST.FROMEMAIL;//Añado el campo From address
    csetting.SER_OutboundFromAddress__c = SER_E2C_CaseRedirect_TEST.FROMEMAIL;//Añado el outbound from address
    insert csetting;//inserto custom setting
    final List<String> addresses = new List<String>(); //Creo la lista parámetro del método a testear
    addresses.add(SER_E2C_CaseRedirect_TEST.FROMEMAIL);
    List<String> assert;
    assert= SER_E2C_CaseRedirect.getDefinedAddresses(addresses);
    System.assert (!assert.isEmpty(),SER_E2C_CaseRedirect_TEST.ASSERTMSG);
    final List<String> addresses2 = new List<String>();
    SER_E2C_CaseRedirect.getDefinedAddresses(addresses2);
    Test.stopTest();//finalizo el test
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : método para testear la asignación de valores a los campos del caso.
  */
  @isTest
  public static void setCaseFields() {
    Test.startTest();//Inicio el test
    final SER_EmailDefaultValues_Assignment__c csetting = new SER_EmailDefaultValues_Assignment__c();//Creo el registro de custom setting
    csetting.Name = SER_E2C_CaseRedirect_TEST.EMAILSETTING;//Añado el nombre
    csetting.SER_Queue__c = SER_E2C_CaseRedirect_TEST.SERQUEUE;//Añado la cola
    csetting.SER_MailingGroup__c = SER_E2C_CaseRedirect_TEST.CCSUPPORT;//Añado el mailing group
    csetting.SER_OutboundMailbox__c = SER_E2C_CaseRedirect_TEST.CCSUPPORT;//Añado el email outbox
    csetting.SER_FromAddres__c = SER_E2C_CaseRedirect_TEST.FROMEMAIL;//Añado el campo From address
    csetting.SER_OutboundFromAddress__c = SER_E2C_CaseRedirect_TEST.FROMEMAIL;//Añado el outbound from address
    insert csetting;//inserto custom setting
    final Map<Id,EmailMessage> mapEmails = new Map<Id,EmailMessage>();
    final SER_E2C_CaseRedirect router = new SER_E2C_CaseRedirect(mapEmails);//Creo la instancia de la clase a testear
    final Case gtbcase = new Case(origin='Email GTB');
    insert gtbcase;
    final Case gmcase = new Case();
    insert gmcase;
    final Case gmcase2 = new Case();
    insert gmcase2;
    router.mapIdAddress.put(gtbcase.Id,SER_E2C_CaseRedirect_TEST.FROMEMAIL);
    router.mapIdAddress.put(gmcase.Id,'fromemailgm@email.com');
    router.mapIdAddress.put(gmcase.Id,SER_E2C_CaseRedirect_TEST.FROMEMAIL);
    final Group cola = new Group(Name = SER_E2C_CaseRedirect_TEST.SERQUEUE);
    insert cola;
    router.mapQueues.put(SER_E2C_CaseRedirect_TEST.SERQUEUE,cola.id);
    router.mapCasesToUpdate.put(gtbcase.id,gtbcase);
    router.mapCasesToUpdate.put(gmcase2.id,gmcase2);
    router.setCaseFields(gtbcase);
    final Boolean assert1 = gtbcase.SER_MailingGroup__c == null;
    System.assert (!assert1,SER_E2C_CaseRedirect_TEST.ASSERTMSG);
    router.setCaseFields(gmcase);
    router.setCaseFields(gmcase2);
    test.stopTest();
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : método para testear el procesamiento de las direcciones en copia.
  */
  @isTest
  public static void processCCAddresses() {
    Test.startTest();//Inicio el test
    final SER_EmailDefaultValues_Assignment__c csetting = new SER_EmailDefaultValues_Assignment__c();//Creo el registro de custom setting
    csetting.Name = SER_E2C_CaseRedirect_TEST.EMAILSETTING;//Añado el nombre
    csetting.SER_Queue__c = SER_E2C_CaseRedirect_TEST.SERQUEUE;//Añado la cola
    csetting.SER_MailingGroup__c = SER_E2C_CaseRedirect_TEST.CCSUPPORT;//Añado el mailing group
    csetting.SER_OutboundMailbox__c = SER_E2C_CaseRedirect_TEST.CCSUPPORT;//Añado el email outbox
    csetting.SER_FromAddres__c = SER_E2C_CaseRedirect_TEST.FROMEMAIL;//Añado el campo From address
    csetting.SER_OutboundFromAddress__c = SER_E2C_CaseRedirect_TEST.FROMEMAIL;//Añado el outbound from address
    insert csetting;//inserto custom setting
    final Map<Id,EmailMessage> mapEmails = new Map<Id,EmailMessage>();
    final SER_E2C_CaseRedirect router = new SER_E2C_CaseRedirect(mapEmails);//Creo la instancia de la clase a testear
    final EmailMessage email = new EmailMessage();
    email.ccaddress = SER_E2C_CaseRedirect_TEST.FROMEMAIL;
    final Boolean assert1 = router.processCCAddresses(SER_E2C_CaseRedirect_TEST.DFLTEMAIL,email);
    System.assert (!assert1,SER_E2C_CaseRedirect_TEST.ASSERTMSG);
    email.ccaddress = 'notdefined@email.com';
    router.processCCAddresses(SER_E2C_CaseRedirect_TEST.DFLTEMAIL,email);
    email.ccaddress = 'fromemail@email.com;fromemail@email.com';
    router.processCCAddresses(SER_E2C_CaseRedirect_TEST.DFLTEMAIL,email);
    Test.stopTest();
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : método para testear el procesamiento de las direcciones en to.
  */
  @isTest
  public static void processAddresses() {
    Test.startTest();//Inicio el test
    final SER_EmailDefaultValues_Assignment__c csetting = new SER_EmailDefaultValues_Assignment__c();//Creo el registro de custom setting
    csetting.Name = SER_E2C_CaseRedirect_TEST.EMAILSETTING;//Añado el nombre
    csetting.SER_Queue__c = SER_E2C_CaseRedirect_TEST.SERQUEUE;//Añado la cola
    csetting.SER_MailingGroup__c = SER_E2C_CaseRedirect_TEST.CCSUPPORT;//Añado el mailing group
    csetting.SER_OutboundMailbox__c = SER_E2C_CaseRedirect_TEST.CCSUPPORT;//Añado el email outbox
    csetting.SER_FromAddres__c = SER_E2C_CaseRedirect_TEST.FROMEMAIL;//Añado el campo From address
    csetting.SER_OutboundFromAddress__c = SER_E2C_CaseRedirect_TEST.FROMEMAIL;//Añado el outbound from address
    insert csetting;//inserto custom setting
    final SER_EmailDefaultValues_Assignment__c maff = new SER_EmailDefaultValues_Assignment__c();//Creo el registro de custom setting que aplica a middle affirmations
    maff.Name = SER_E2C_CaseRedirect_TEST.EMAILMAFF;//Añado el nombre
    maff.SER_Queue__c = '	SER_Middle_Affirmations';//Añado la cola
    maff.SER_MailingGroup__c = SER_E2C_CaseRedirect_TEST.EMAILMAFF;//Añado el mailing group
    maff.SER_OutboundMailbox__c = 'Documentation & Validations';//Añado el email outbox
    maff.SER_FromAddres__c = SER_E2C_CaseRedirect_TEST.MAFFADD;//Añado el campo fromaddress
    maff.SER_OutboundFromAddress__c = 'middle.affirmations@grupobbva.com-outbound';//Añado el campo outbound fromaddress
    insert maff;//Inserto el registro de custom setting
    final Map<Id,EmailMessage> mapEmails = new Map<Id,EmailMessage>();
    final SER_E2C_CaseRedirect router = new SER_E2C_CaseRedirect(mapEmails);//Creo la instancia de la clase a testear
    final EmailMessage email = new EmailMessage();
    email.toaddress = SER_E2C_CaseRedirect_TEST.FROMEMAIL;
    final Boolean assert1 = router.processAddresses(SER_E2C_CaseRedirect_TEST.DFLTEMAIL,email);
    System.assert (!assert1,SER_E2C_CaseRedirect_TEST.ASSERTMSG);
    email.toaddress = 'notdefined@email.com';
    router.processAddresses(SER_E2C_CaseRedirect_TEST.DFLTEMAIL,email);
    email.toaddress = 'fromemail@email.com;fromemail@email.com';
    router.processAddresses(SER_E2C_CaseRedirect_TEST.DFLTEMAIL,email);
    email.toaddress = SER_E2C_CaseRedirect_TEST.MAFFADD;
    router.processAddresses(SER_E2C_CaseRedirect_TEST.DFLTEMAIL,email);
    email.toaddress = '';
    email.ccaddress = SER_E2C_CaseRedirect_TEST.FROMEMAIL;
    router.processAddresses(SER_E2C_CaseRedirect_TEST.DFLTEMAIL,email);
    email.toaddress = '';
    email.ccaddress = '';
    router.processAddresses(SER_E2C_CaseRedirect_TEST.DFLTEMAIL,email);
    Test.stopTest();
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : Método de test para el método fillUpdateMap
  */
  @isTest
  public static void fillUpdateMap() {
    Test.startTest();
    final Map<Id,EmailMessage> mapEmails = new Map<Id,EmailMessage>();
    final SER_E2C_CaseRedirect router = new SER_E2C_CaseRedirect(mapEmails);//Creo la instancia de la clase a testear
    final Case newcase = new Case();
    insert newcase;
    final EmailMessage email = new EmailMessage(ParentId = newcase.Id);
    router.fillUpdateMap(null,email);
    final Boolean assert1 = router.mapCasesToUpdate.get(newcase.Id).SER_ReassignedToCustomerSupport__c == true;
    System.assert (assert1,SER_E2C_CaseRedirect_TEST.ASSERTMSG);
    router.fillUpdateMap(true,email);
    router.fillUpdateMap(false,email);
    Test.stopTest();
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : Método de test para el método fillUpdateMap
  */
  @isTest
  public static void getDefaultMailbox() {
    Test.startTest();
    final Map<Id,EmailMessage> mapEmails = new Map<Id,EmailMessage>();
    final SER_E2C_CaseRedirect router = new SER_E2C_CaseRedirect(mapEmails);//Creo la instancia de la clase a testear
    final Case newcase = new Case();
    insert newcase;
    String result;
    router.mapCases.put(newcase.Id,new Case(SER_Business_Case_Type__c = 'GNC'));
    result = router.getDefaultMailbox(newcase.Id);
    router.mapCases.put(newcase.Id,new Case(SER_Business_Case_Type__c = ''));
    result = router.getDefaultMailbox(newcase.Id);
    router.mapCases = new Map<Id,Case>();
    result = router.getDefaultMailbox(newcase.Id);
    router.mapCases.put(newcase.Id,new Case(SER_Business_Case_Type__c = 'GM'));
    result = router.getDefaultMailbox(newcase.Id);
    final Boolean assert1 = String.isNotBlank(result);
    System.assert (assert1,SER_E2C_CaseRedirect_TEST.ASSERTMSG);
    Test.stopTest();
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : Método de test para el método fillUpdateMap
  */
  @isTest
  public static void getQueues() {
    Test.startTest();
    final Map<Id,EmailMessage> mapEmails = new Map<Id,EmailMessage>();
    final SER_E2C_CaseRedirect router = new SER_E2C_CaseRedirect(mapEmails);//Creo la instancia de la clase a testear
    final Case newcase = new Case();
    insert newcase;
    final Group cola = new Group(Name = SER_E2C_CaseRedirect_TEST.SERQUEUE);
    insert cola;
    router.getQueues();
    final Boolean assert1 = router.mapQueues.isEmpty();
    System.assert (assert1,SER_E2C_CaseRedirect_TEST.ASSERTMSG);
    router.mapQueues.put(cola.Name,cola.Id);
    router.getQueues();
    Test.stopTest();
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : Método de test para el método fillUpdateMap
  */
  @isTest
  public static void processCases() {
    Test.startTest();
    final Case newcase = new Case();
    insert newcase;
    SER_Case_TriggerHelper.map_EmailToCase.put(newcase.Id,newcase);
    final EmailMessage email = new EmailMessage(ParentId = newcase.Id);
    email.toaddress = SER_E2C_CaseRedirect_TEST.FROMEMAIL;
    final Map<Id,EmailMessage> mapEmails = new Map<Id,EmailMessage> {};
    mapEmails.put(email.Id,email);
    final SER_E2C_CaseRedirect router = new SER_E2C_CaseRedirect(mapEmails);//Creo la instancia de la clase a testear
    final Group cola = new Group(Name = SER_E2C_CaseRedirect_TEST.SERQUEUE);
    insert cola;
    final SER_EmailDefaultValues_Assignment__c csetting = new SER_EmailDefaultValues_Assignment__c();//Creo el registro de custom setting
    csetting.Name = SER_E2C_CaseRedirect_TEST.EMAILSETTING;//Añado el nombre
    csetting.SER_Queue__c = SER_E2C_CaseRedirect_TEST.SERQUEUE;//Añado la cola
    csetting.SER_MailingGroup__c = SER_E2C_CaseRedirect_TEST.CCSUPPORT;//Añado el mailing group
    csetting.SER_OutboundMailbox__c = SER_E2C_CaseRedirect_TEST.CCSUPPORT;//Añado el email outbox
    csetting.SER_FromAddres__c = SER_E2C_CaseRedirect_TEST.FROMEMAIL;//Añado el campo From address
    csetting.SER_OutboundFromAddress__c = SER_E2C_CaseRedirect_TEST.FROMEMAIL;//Añado el outbound from address
    insert csetting;//inserto custom setting
    final Map<Id,Case> result  = router.processCases();
    final Boolean assert = result.isEmpty();
    System.assert (assert,SER_E2C_CaseRedirect_TEST.ASSERTMSG);
    Test.stopTest();
  }
}