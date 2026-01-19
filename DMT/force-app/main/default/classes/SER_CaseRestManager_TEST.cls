/**
*    Company:       BBVA
*    Description:   Clase de Tedst de SER_TestUtils_2 (initData(), createProduct(), createSData()),
*       SER_CaseRestManager y SER_CaseRest_HELPER.
*/
@isTest
public with sharing class SER_CaseRestManager_TEST {
  /* Constante 'BOSS'*/
  public static final string BOSS= 'BOSS';

  /*
  * @Description: Net Cash con SSTT Product y Account - OK.
  * @return Void
  */
  public static testMethod void  createCaseTEST() {

    SER_TestUtils_2.getSingleInstance();
    SER_TestUtils_2.initData();

    Test.startTest();

    SER_CaseRestManager.SData data;
    data = SER_TestUtils_2.createSData();

    SER_CaseRestManager.Result resultado;
    resultado = SER_CaseRestManager.createCase(data);

    System.assertEquals(resultado.detail, SER_Constant.MSG_SUCCESS, 'Error');

    Test.stopTest();
  }

  /*
  * @Description: Net Cash con SSTT Product sin Account - KO
  */
  public static testMethod void  createCaseTEST2() {

    SER_TestUtils_2.getSingleInstance();
    SER_TestUtils_2.createProduct();

    Test.startTest();

    SER_CaseRestManager.SData data;
    data = SER_TestUtils_2.createSData();

    SER_CaseRestManager.Result resultado;
    resultado = SER_CaseRestManager.createCase(data);

    System.assertEquals(resultado.detail, SER_Constant.MSG_ERROR_ACCOUNT + SER_Constant.REFERENCE, 'Error');

    Test.stopTest();
  }

  /*
  * @Description: Net Cash Con reference de sstt product que no existe - KO.
  * @return Void
  */
  public static testMethod void  createCaseTEST3() {

    Test.startTest();

    SER_TestUtils_2.getSingleInstance();

    SER_CaseRestManager.SData data;
    data = SER_TestUtils_2.createSData();

    SER_CaseRestManager.Result resultado;
    resultado = SER_CaseRestManager.createCase(data);

    System.assertEquals(resultado.detail, SER_Constant.MSG_ERROR_PRODUCT+ SER_Constant.REFERENCE, 'Error');

    Test.stopTest();
  }

  /*
  * @Description: BOSS con tlf sin email - OK.
  * @return Void
  */
  public static testMethod void  createCaseTEST4() {

    SER_TestUtils_2.getSingleInstance();
    SER_TestUtils_2.initData();

    Test.startTest();

    SER_CaseRestManager.SData data;
    data = SER_TestUtils_2.createSData();
    data.email = '';
    data.phone = '111111111';
    data.caseOrigin = BOSS;

    SER_CaseRestManager.Result resultado;
    resultado = SER_CaseRestManager.createCase(data);

    System.assertEquals(resultado.detail, SER_Constant.MSG_SUCCESS, 'Error1');

    Test.stopTest();
  }

  /*
  * @Description: Max Mistral con Case Creator - OK.
  * @return Void
  */
  public static testMethod void  createCaseTEST5() {

    SER_TestUtils_2.getSingleInstance();
    SER_TestUtils_2.initData();

    Test.startTest();

    SER_CaseRestManager.SData data;
    data = SER_TestUtils_2.createSData();
    data.phone = '111111111';
    data.contactPreference = 'PHONE';
    data.caseOrigin = BOSS;
    data.caseCreator = 'Pedro';
    data.clientName = 'Jose';
    data.product = 'product';

    SER_CaseRestManager.Result resultado;
    resultado = SER_CaseRestManager.createCase(data);

    System.assertEquals(resultado.detail, SER_Constant.MSG_SUCCESS, 'Error2');

    Test.stopTest();
  }

  /*
  * @Description: Net Cash sin referencia - KO.
  * @return Void
  */
  public static testMethod void  withProductNullTEST() {

    Test.startTest();

    SER_CaseRestManager.SData data;
    data = new SER_CaseRestManager.SData();
    data.name = 'Ramón Cuellar';
    data.email = '';
    data.phone = '915254060';
    data.productReference = '';
    data.userCodeWS = 'User_0002';
    data.description = 'Description...';
    data.caseOrigin = BOSS;

    SER_CaseRestManager.Result resultado;
    resultado = SER_CaseRestManager.createCase(data);

    System.assertEquals(resultado.detail, SER_Constant.MSG_ERROR_FIELDS + ': ' + ' productReference ', 'Error3');

    Test.stopTest();
  }

  /*
  * @Description: campos muy largos - KO.
  * @return Void
  */
  public static testMethod void  checkFieldsTEST() {

    SER_CaseRestManager.createInstance();

    Test.startTest();

    SER_CaseRestManager.SData data;
    data = new SER_CaseRestManager.SData();
    data.name = '123456789012345678901234567890123456789012345678901234567890123456789012345678901';
    data.email = '123456789012345678901234567890123456789012345678901234567890123456789012345678901';
    data.phone = '12345678901234567890123456789012345678901';
    data.productReference = '123456789012345678901234567890123456789012345678901234567890123456789012345678901';
    data.userCodeWS = '1234567890123456789012345678901';
    data.description = '';
    data.caseOrigin = '12345678901234567890123456789012345678901';

    SER_CaseRestManager.Result resultado;
    resultado = SER_CaseRestManager.createCase(data);

    System.assert (resultado.detail.contains(' phone '), 'Error4');

    Test.stopTest();
  }

  /*
  * @Description: campos vacios - KO.
  * @return Void
  */
  public static testMethod void  voidValuesTEST() {

    SER_CaseRestManager.createInstance();

    Test.startTest();

    SER_CaseRestManager.SData data;
    data = new SER_CaseRestManager.SData();
    data.name = '';
    data.email = '';
    data.phone = '';
    data.productReference = '';
    data.userCodeWS = '';
    data.description = '';
    data.caseOrigin = '';

    SER_CaseRestManager.Result resultado;
    resultado = SER_CaseRestManager.createCase(data);

    System.assert (resultado.detail.contains(' phone '), 'Error5');

    Test.stopTest();
  }

  /*
  * @Description: Splunk - KO.
  * @return Void
  */
  public static testMethod void  createCaseplunkTEST2() {

    Test.startTest();

    SER_CaseRestManager.SData data;
    data = new SER_CaseRestManager.SData();
    data.phone = 'España';
    data.email = SER_Constant.TOOLONGCOMMENT;
    data.caseOrigin = BOSS;
    data.productReference = 'H2H';
    data.name = SER_Constant.TOOLONGCOMMENT;
    data.userCodeWS = SER_Constant.TOOLONGCOMMENT;
    data.description = 'Cuerpo del correo';
    data.caseCreator = 'TL.MTRE100......';

    SER_CaseRestManager.Result resultado;
    resultado = SER_CaseRestManager.createCase(data);

    System.assert (resultado.detail.contains(' name '), 'Error7');

    Test.stopTest();
  }


}