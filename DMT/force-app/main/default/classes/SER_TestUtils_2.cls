/*
*    Company:       BBVA
*    Description:  Clase auxiliar para las clases de Test.
*/
public with sharing class SER_TestUtils_2 {

  /*Instancia única de la clase para implementar un patrón Singleton*/
  private static SER_TestUtils_2 instance;

  /**Constante 'ANS Banca de Empresas'*/
  public static final String ANSBE = 'ANS Banca de Empresas';

  /**Constante 'REMEDY12345'*/
  public static final String REMEDY12345 = 'REMEDY12345';

  /*
  * @Description: Constructor privado.
  */
  private SER_TestUtils_2() {
  }

  /*
  * @Description: devuelve una instancia unica de esta clase. Patron Singleton.
  */
  public static SER_TestUtils_2 getSingleInstance() {
    // lazy load the record type - only initialize if it doesn't already exist
    if(instance == null) {
      instance = new SER_TestUtils_2();
    }
    return instance;
  }

  /*
  * @Description: se crean los datos necesarios para los Test.
  * @return Void
  */
  public static Void initData() {
    Account account;
    account = UnitTestUtils.GetStandardAccount();
    insert account;

    SER_Transactional__c trans;
    trans = new SER_Transactional__c(name=SER_Constant.REFERENCE, SER_Account__c=account.Id, SER_Product_Text__c='BBVA NET C@SH',SER_Product_Code__c = '1380');
    insert trans;
  }

  /*
  * @Description: se crea un SSTT Product.
  * @return Void
  */
  public static Void createProduct() {
    SER_Transactional__c trans;
    trans = new SER_Transactional__c(name=SER_Constant.REFERENCE, SER_Product_Text__c='BBVA NET C@SH',SER_Product_Code__c = '1380');
    insert trans;
  }

  /*
  * @Description: se crea un registro de SER_CaseRestManager.SData.
  * @return Void
  */
  public static SER_CaseRestManager.SData createSData() {

    SER_CaseRestManager.createInstance();

    SER_CaseRestManager.SData data;
    data = new SER_CaseRestManager.SData();
    data.name = 'Ramón Ferrán Pérez';
    data.email = 'ramon@pruebas.fn';
    data.phone = '';
    data.productReference = SER_Constant.REFERENCE;
    data.userCodeWS = 'User_0003';
    data.description = 'Es la descripción de....3';
    data.caseOrigin = 'BOSS';
    return data;
  }

  /*
  * @Description: se crean los custom settings SER_RemedyGroupAssignment__c necesarios para Remedy.
  * @return Void
  */
  public static Void initRemedyCS() {
    /*SER_RemedyGroupAssignment__c cs01;
    cs01 = new SER_RemedyGroupAssignment__c (Name = 'ANS SSTT', SER_Id__c = 'SGP000000009770',SER_Name__c = 'ANS SSTT');
    SER_RemedyGroupAssignment__c cs02;
    cs02 = new SER_RemedyGroupAssignment__c (Name = 'ANS Banca de Empresas', SER_Id__c = 'SGP000000007012',SER_Name__c = 'ANS Banca de Empresas');
    insert cs01; insert cs02;*/
  }

  /*
  * @Description: se inician los parametros para la pagina visualforce Page.SER_CallRemedyWebService.
  * @Param Id newCaseId
  * @return Void
  */
  public static Void initCallRemedyWSPage(Id newCaseId) {
    /*PageReference callRemedyWSPage;
    callRemedyWSPage = Page.SER_CallRemedyWebService;
    test.setCurrentPage(callRemedyWSPage);
    System.currentPageReference().getParameters().put('caid', newCaseId);
    System.currentPageReference().getParameters().put('usid', 'XE99999');
    System.currentPageReference().getParameters().put('tabid', 'TAB-id');*/
  }

  /*
  * @Description: inserta un CaseComment.
  * @Param Id newCaseId
  * @return Void
  */
  public static Void insertCaseComent(Id newCaseId) {
    CaseComment caseComment;
    caseComment = new CaseComment();
    caseComment.ParentId = newCaseId;
    caseComment.CommentBody = 'Comment number #1';
    insert caseComment;
  }

  /*
  * @Description: inserta un Attachment.
  * @Param Id newCaseId
  * @return Void
  */
  public static Void insertAttachment(Id newCaseId) {
    Attachment attach;
    attach = new Attachment();
    attach.parentId = newCaseId;
    attach.Name = 'Unit Test Attachment';
    Blob bodyBlob;
    bodyBlob = Blob.valueOf('Unit Test Attachment Body');
    attach.body = bodyBlob;
    attach.Description = 'file description';
    attach.ContentType = 'txt';
    insert attach;
  }

  /*
  * @Description: inserta un file(Content Document).
  * @Param Id newCaseId
  * @return Void
  */
  public static Void insertRelatedFile(Id newCaseId) {
    final ContentVersion contentVersion = new ContentVersion(
      Title = 'Penguins',
      PathOnClient = 'Penguins.jpg',
      VersionData = Blob.valueOf('Test Content'),
      IsMajorVersion = true
      );
    insert contentVersion;
    final List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument limit 1];

    //create ContentDocumentLink  record
    final ContentDocumentLink cdl = New ContentDocumentLink();
    cdl.LinkedEntityId = newCaseId;
    cdl.ContentDocumentId = documents[0].Id;
    cdl.shareType = 'V';
    insert cdl;
  }

  /*
  * @Description: set up mock response.
  * @Param Id newCaseId
  * @return Void
  */
  public static Void setUpMockResponse() {
    SER_ASOMockResponse_TEST fakeResponse;
    fakeResponse = new SER_ASOMockResponse_TEST(200, 'OK','{"id":"INC00000001"}',null );
    Test.setMock(HttpCalloutMock.class, fakeResponse);
  }

}