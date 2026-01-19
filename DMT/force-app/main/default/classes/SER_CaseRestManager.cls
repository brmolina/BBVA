/**
*    Author:        Julio L
*    Company:       Accenture
*    Description:   Web Service REST que se expone para crear un caso nuevo en Salesforce.
*
*    <Date>              <Author>                <Description>
*    2018-05-04          Julio L                 Creación de la clase
*    2018-11-26          Javier Touchard         V-2.0
*/
@RestResource(urlMapping='/Case/*')
global with sharing class SER_CaseRestManager {
  /* Constante 'Alerta'*/
  public static final string ALERT = 'Alert';
  /*Instancia única de la clase para implementar un patrón Singleton*/
  private static SER_CaseRestManager instance;
  /*Set para almacenar los valores de la picklist del campo Case.Origin*/
  private static final set<string> SETORIGEN = new Set<String>();
  static {
    // Se optienen los valores de la picklist del campo Origin
    Schema.DescribeFieldResult fieldOrigin;
    fieldOrigin = Case.Origin.getDescribe();
    List<Schema.PicklistEntry> lstOrigin;
    lstOrigin = fieldOrigin.getPicklistValues();
    for( Schema.PicklistEntry opt : lstOrigin) {
      SETORIGEN.add(opt.getValue());
    }
  }

  /*
  * @Description: Constructor privado.
  */
  private SER_CaseRestManager() {
    /*Instancio el Helper*/
    SER_CaseRest_HELPER.getSingleInstance();
  }

  /*
  * @Description: devuelve una instancia unica de esta clase. Patron Singleton.
  */
  public static SER_CaseRestManager createInstance() {
    // lazy load the record type - only initialize if it doesn't already exist
    if(instance == null) {
      instance = new SER_CaseRestManager();
    }
    return instance;
  }

  /*
  * @Description: Servicio REST para la creción de un caso.
  * @Params SData data: Wrapper que contiene la informacion necesaria para crear el caso.
  * @Return Result
  */
  @HttpPost
  global static Result createCase(SData data) {
    // Variables
    Result result;
    result = new Result();
    String strUserMail = '';

    try {
      // Info solo para informar el log de error
      strUserMail = ' [Name: ' + data.name + ' - Email: ' + data.email + ' - Phone: ' +
                    data.phone + ' - ProductReference: ' + data.productReference +
                    ' - UserCodeWS: ' + data.userCodeWS + ' - caseOrigin: ' + data.caseOrigin +
                    +' - descripcion: ' + data.description + ' - ContactPreference: ' +
                    data.contactPreference + ' - caseCreator: ' + data.caseCreator + ']';
      System.debug(strUserMail);

      //Compruebo si la alerta viene de Splunk
      Boolean isSplunk;
      isSplunk = data.userCodeWS.startsWithIgnoreCase(ALERT);

      // Se comprueba que los campos obligatorios estan informados
      String msgCheckData;
      msgCheckData = checkRequiredFields(data, isSplunk);
      System.debug('msgCheckData : ' + msgCheckData);

      // Se comprueba el tamaño de los campos informados.
      String msgCheckSizeData;
      if(isSplunk) {
        msgCheckSizeData = SER_CaseRest_HELPER.validateSplunkSizeFields(data);
      } else {
        msgCheckSizeData = checkValidateSizeFields(data);
      }
      System.debug('msgCheckSizeData : ' + msgCheckSizeData);

      if(String.isBlank(msgCheckData) && String.isBlank(msgCheckSizeData)) {
        manageCase(data, result, strUserMail);
      } else {
        // Si hay campos obligatorios que no estan informados
        result.statusCode = '3';
        if(!String.isBlank(msgCheckData)) {
          result.detail = msgCheckData;
        }

        // Si hay campos que se exceden de tamaño
        if(!String.isBlank(msgCheckSizeData)) {
          result.detail = result.detail + ' and ' + msgCheckSizeData;
        }

        // Insertamos un log si ha habido algun fallo
        CIB_LogUtils.create_Log(SER_Constant.MSG_ACCESS + data.caseOrigin, result.statusCode + SER_Constant.GUION + result.detail + SER_Constant.GUION + strUserMail);
      }
    } catch( Exception ex ) {
      result.statusCode = '2 ';
      result.detail = SER_Constant.MSG_FAIL + ' : ' + ex;

      // Insertamos un log si ha habido algun fallo
      CIB_LogUtils.create_Log(SER_Constant.MSG_ACCESS + data.caseOrigin, result.statusCode + SER_Constant.GUION + result.detail + SER_Constant.GUION + strUserMail);
    }

    return result;
  }

  /*
  * @Description: Valida los campos que son obligatorios para poder dar de alta el caso.
  *               Si esta OK devuelve una cadena vacía, si algún campo esta vacío devuelve
  *               el mensaje de error correspondiente.
  * @param data <tt>SData</tt> con el objeto Data a comprobar.
  * @return <tt>String</tt> con el mensaje de error o <tt>vacio</tt> si esta OK.
  */
  private static String checkRequiredFields(final SData data, Boolean isSplunk) {
    //Objecto retorno
    String toReturn = '';

    // description
    if(String.isBlank(data.description)) {
      toReturn += ' description ';
    }

    // name
    if(String.isBlank(data.name)) {
      toReturn += ' name ';
    }

    // email and phone
    if(String.isBlank(data.email) && String.isBlank(data.phone)) {
      toReturn += ' email ';
      toReturn += ' phone ';
    }

    // Se comprueba que el parametro caseOrigin no esta vacio y es un valor de la picklist Origin.
    if(String.isBlank(data.caseOrigin) || !SETORIGEN.contains(data.caseOrigin)) {
      toReturn += ' caseOrigin ';
    }

    toReturn += checkRequiredFields2(data, toReturn, isSplunk);

    return toReturn == '' ? null : SER_Constant.MSG_ERROR_FIELDS + ': ' + toReturn;
  }

  /*
  * @Description: Valida los campos que son obligatorios para poder dar de alta el caso.
  *               Si esta OK devuelve una cadena vacía, si algún campo esta vacío devuelve
  *               el mensaje de error correspondiente.
  * @param data <tt>SData</tt> con el objeto Data a comprobar.
  * @return <tt>String</tt> con el mensaje de error o <tt>vacio</tt> si esta OK.
  */
  private static String checkRequiredFields2(final SData data, String errors, Boolean isSplunk) {
    //Objecto retorno
    String toReturn = '';

    //Si caseOrigin es MAX_MISTRAL se saltan las validaciones de productReference y userCodeWS.
    Boolean process;
    process = !errors.contains(' caseOrigin ') && (data.caseOrigin!=Label.WS_MaxMistral || isSplunk);
    if(process) {
      // productReference
      if(String.isBlank(data.productReference)) {
        toReturn += ' productReference ';
      }

      // userCode
      if(String.isBlank(data.userCodeWS)) {
        toReturn += ' userCodeWS ';
      }
    }

    if(isSplunk) {
      if(String.isBlank(data.caseCreator)) {
        toReturn += ' fichero ';
      }
      if(String.isBlank(data.email)) {
        toReturn += ' idSplunk ';
      }
      if(String.isBlank(data.phone)) {
        toReturn += ' pais ';
      }
    }

    return toReturn;
  }

  /*
  * @Description: Valida los campos que son obligatorios para poder dar de alta el caso.
  *               Si esta OK devuelve una cadena vacía, si algún campo esta vacío devuelve
  *               el mensaje de error correspondiente.
  * @param data <tt>SData</tt> con el objeto Data a comprobar.
  * @return <tt>String</tt> con el mensaje de error o <tt>vacio</tt> si esta OK.
  */
  private static String checkRequiredFields3(SER_Transactional__c product) {
    //Objecto retorno
    String toReturn = '';

    if(String.isBlank(product.Id)) {
      toReturn += SER_Constant.PRODUCT;
    }

    if(String.isBlank(product.SER_Account__c)) {
      toReturn += SER_Constant.ACCOUNT;
    }

    return toReturn;
  }

  /*
  * @Description: Valida los tamaños de los campos obligatorios establecidos para poder dar de alta el caso.
  *               Si esta OK devuelve una cadena vacía, si algún campo es nulo devuelve
  *               el mensaje de error correspondiente.
  * @param data <tt>SData</tt> con el objeto Data a comprobar.
  * @return <tt>String</tt> con el mensaje de error o <tt>vacio</tt> si esta OK.
  */
  private static String checkValidateSizeFields(final SData data) {
    // Objecto retorno
    String toReturn = '';

    // description
    if(!String.isBlank(data.description) && data.description.length() > 31999) {
      toReturn += ' description ';
    }

    // phone
    if(!String.isBlank(data.phone) && data.phone.length() > 40) {
      toReturn += ' phone ';
    }

    // email
    if(!String.isBlank(data.email) && data.email.length() > 80) {
      toReturn += ' email ';
    }

    toReturn += checkValidateSizeFields2(data);

    return toReturn == '' ? null : SER_Constant.MSG_ERROR_SIZE + ': ' + toReturn;
  }

  /*
  * @Description: Valida los tamaños de los campos obligatorios establecidos para poder dar de alta el caso.
  *               Si esta OK devuelve una cadena vacía, si algún campo es nulo devuelve
  *               el mensaje de error correspondiente.
  * @param data <tt>SData</tt> con el objeto Data a comprobar.
  * @return <tt>String</tt> con el mensaje de error o <tt>vacio</tt> si esta OK.
  */
  private static String checkValidateSizeFields2(final SData data) {
    // Objecto retorno
    String toReturn = '';

    // Validacion del tamaño de los campos obligatorios

    // name
    if(!String.isBlank(data.name) && data.name.length() > 80) {
      toReturn += ' name ';
    }

    // productReference
    if(!String.isBlank(data.productReference) && data.productReference.length() > 80) {
      toReturn += ' productReference ';
    }

    // userCode
    if(!String.isBlank(data.userCodeWS) && data.userCodeWS.length() > 30) {
      toReturn += ' userCodeWS ';
    }

    // caseOrigin
    if(!String.isBlank(data.caseOrigin) && data.caseOrigin.length() > 40) {
      toReturn += ' caseOrigin ';
    }

    return toReturn;
  }

  /*
  * @Description: Retorna un objeto Transaccional con datos sobre la cuenta y el nombre del producto.
  * @param productReference <tt>String</tt> codigo del producto de referencia.
  * @return <tt>SER_Transactional__c</tt> objeto con los datos cuenta y producto.
  */
  private static SER_Transactional__c getAccount (final String productReference) {
    SER_Transactional__c product = new SER_Transactional__c();
    for(SER_Transactional__c stt : [select Id, SER_Account__c, SER_Product_Text__c
                                    from SER_Transactional__c
                                    where name = :productReference AND
                                                  SER_Product_Code__c = '1380' limit 1]) {
      product = stt;
    }

    System.debug('JLB WS - Account: ' + product.SER_Account__c);

    return product;
  }

  /*
  * @Description:  gestiona el caso.
  * @param SData data: Wrapper que contiene la informacion necesaria para crear el caso.
  * @return void
  */
  private static void manageCase(SData data, Result result, String strUserMail) {
    //Id del caso
    String caseId;
    //SSTT Product
    SER_Transactional__c product;
    // Mensaje de eror en caso de que el case origin sea Net cash o Boss y no tenga
    // product o account
    String msgCheckData2 = '';

    if(String.isNotBlank(data.productReference)) {
      // Se obtiene la cuenta y el producto asociado a la referencia del
      // producto que pasan por parametro(Net Cash y Boss)
      product = getAccount(data.productReference);
      //Valido que tenga product y account.
      msgCheckData2 = checkRequiredFields3(product);
    }

    if(msgCheckData2.equalsIgnoreCase('')) {
      // Se obtiene el contacto asociado al mail del usuario que pasan por parametro.
      //Contact contact = getContact(data, product.SER_Account__c);

      //Le damos valor a contactPreference
      SER_CaseRest_HELPER.fillContactPreference(data);

      // Generamos una plantilla en el campo Descripcion para no perder datos de Netcash.
      String strDesNetCash;
      strDesNetCash = SER_CaseRest_HELPER.fillDescription(data);

      // Si es correcto, se crea el objeto respuesta
      result.caseId = caseId;
      result.statusCode = '0';
      result.detail = SER_Constant.MSG_SUCCESS;
    } else {
      result.statusCode = '1';
      if(msgCheckData2.contains(SER_Constant.PRODUCT)) {
        result.detail = SER_Constant.MSG_ERROR_PRODUCT + data.productReference;
      } else if(msgCheckData2.contains(SER_Constant.ACCOUNT)) {
        result.detail = SER_Constant.MSG_ERROR_ACCOUNT +data.productReference;
      }

      // Insertamos un log si ha habido algun fallo
      CIB_LogUtils.create_Log(SER_Constant.MSG_ACCESS + data.caseOrigin, result.statusCode + SER_Constant.GUION + result.detail + SER_Constant.GUION + strUserMail);
    }
  }



  /**********************************************************
  ***********************   WRAPPER   ***********************
  **********************************************************/

  /*
  * @Description: Wrapper que recoge toda la información que entra al servicio.
  */
  global class SData {
    /*Clasificacion + Ref. producto. Campo calculado*/
    public String subject {get; set;}
    /*Descripcion*/
    public String description {get; set;}
    /*Telefono*/
    public String phone {get; set;}
    /*Mail*/
    public String email {get; set;}
    /*Nombre y apellidos*/
    public String name {get; set;}
    /*Referencia del producto*/
    public String productReference {get; set;}
    /*Codigo usuario Netcash, MaxMistral o Boss*/
    public String userCodeWS {get; set;}
    /*Caso origen. Campo constante*/
    public String caseOrigin {get; set;}
    /*Nombre del cliente*/
    public String clientName {get; set;}
    /*Producto*/
    public String product {get; set;}
    /*Forma preferida de contacto*/
    public String contactPreference {get; set;}
    /*Creador del caso*/
    public String caseCreator {get; set;}
  }

  /*
  * @Description: Wrapper que recoge toda la información que devuelve el servicio.
  */
  global class Result {
    /*Id del casocreado*/
    public String caseId {get; set;}
    /*Codigo de estado 0.- OK y 1.- FALLO*/
    public String statusCode {get; set;}
    /*Detalle del resultado*/
    public String detail {get; set;}
  }

}