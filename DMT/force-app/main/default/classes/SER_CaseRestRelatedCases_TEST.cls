/*-----------------------------------------------------------------------------------------------------------
    Author:        Julio L
    Company:       Accenture
    Description:   Clase de prueba para probar el Web Service que se expone para
                    que lo invoque Max Mistral y así pueda consultar los casos relacionados
                    dado el Cclient.

    <Date>              <Author>                <Description>
    2018-04-16          Julio L                 Creación de la clase de TEST
-------------------------------------------------------------------------------------------------------------*/

@isTest
private class SER_CaseRestRelatedCases_TEST {

  private static void initData(Datetime createdDate,String productName) {
    String idRT = '';
    for(RecordType rt: [select id, name from RecordType where name = 'SER Service Account' limit 1]) {
      idRT = rt.id;
    }

    // Se crea una cuenta
    Account acc;
    acc = new Account(Name='TestAccount Max Mistral JLB', ser_cclient__c='987654',
                      OwnerId = UserInfo.getUserId(),
                      RecordtypeId=idRT,
                      DES_BBVA_Segmentation__c = 'NBC');
    insert acc;

    // Se crea un contacto
    Contact contacto;
    contacto = new Contact( FirstName='Julian',
                            LastName = 'Liarte',
                            Email_ExternalID__c = 'jlb@sonprueba.com',
                            Phone = '915287001',
                            AccountId = acc.Id,
                            RecordTypeId = SER_RecordTypeUtils.getRecordTypeByName('Contact','SER_Service_Contact_Global_Markets')
      );
    insert contacto;

    // Se crea un caso asociado a la cuenta y al contacto
    Case caso;
    caso = new Case(Subject = 'Tema del caso',
                    Status  = 'New',
                    Priority = 'Low',
                    SER_Classification__c = 'Incidencia',
                    SER_Product__c = 'Consorcio',
                    CreatedDate = createdDate,
                    OwnerId = UserInfo.getUserId(),
                    AccountId = acc.Id,
                    ContactId = contacto.Id,
                    ClosedDate = Datetime.now().addDays(-1));
    insert caso;

    // Se crea un producto SSTT asociado a una cuenta
    SER_Transactional__c producto;
    producto = new SER_Transactional__c();
    producto.Name = productName;
    producto.SER_Account__c = acc.Id;
    producto.SER_Product_Text__c = 'NET CASH PRUEBA';

    insert producto;
  }

  @isTest static void byIdClientCasesRelatedTEST() {

    initData(Datetime.now().addDays(-2),'888999');

    RestRequest req;
    req = new RestRequest();
    RestResponse res;
    res = new RestResponse();

    req.requestURI = '/services/apexrest/CasesRelated/queryCases';
    req.httpMethod = 'GET';
    req.params.put('idClient', '987654');
    RestContext.request = req;
    RestContext.response = res;

    test.startTest();
    SER_CaseRestRelatedCases.getInstance();
    // ws Response
    SER_CaseRestRelatedCases.Result resultado;
    resultado = SER_CaseRestRelatedCases.queryCases();
    system.assertEquals(resultado.statusCode,'0','Error1');
    test.stopTest();

    system.debug(Logginglevel.INFO,'JLB - BYIDCLIENT > wsResponse: ' + resultado);
  }

  @isTest static void byProductReferenceCasesRelatedTEST() {

    initData(Datetime.now(),'777880');

    RestRequest req;
    req = new RestRequest();
    RestResponse res;
    res = new RestResponse();

    req.requestURI = '/services/apexrest/CasesRelated/queryCases';
    req.httpMethod = 'GET';
    req.params.put('productReference', '777880');
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    SER_CaseRestRelatedCases.Result respuesta;
    respuesta = SER_CaseRestRelatedCases.queryCases();
    System.debug('JLB - BYProduct - respuesta: '+respuesta);
    system.assertEquals(respuesta.statusCode,'0','Error2');
    Test.stopTest();
  }

  @isTest static void testCampoNoInformado() {
    RestRequest req;
    req = new RestRequest();
    RestResponse res;
    res = new RestResponse();

    req.params.put('idClient', '');
    req.params.put('productReference', '');
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    SER_CaseRestRelatedCases.Result respuesta;
    respuesta = SER_CaseRestRelatedCases.queryCases();
    System.debug('JLB - Campos no informados - respuesta: '+respuesta);
    system.assertEquals(respuesta.statusCode,'3','Error3');
    Test.stopTest();
  }

  @isTest static void testCamposInformados() {
    RestRequest req;
    req = new RestRequest();
    RestResponse res;
    res = new RestResponse();

    req.params.put('idClient', '1234wer');
    req.params.put('productReference', 'xcvg3451');
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    SER_CaseRestRelatedCases.Result respuesta;
    respuesta = SER_CaseRestRelatedCases.queryCases();
    System.debug('JLB - Campos no informados - respuesta: '+respuesta);
    system.assertEquals(respuesta.statusCode,'4','Error4');
    Test.stopTest();
  }
}