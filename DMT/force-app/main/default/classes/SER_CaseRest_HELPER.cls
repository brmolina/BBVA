/*
*    Company:       BBVA
*    Description:   Clase auxiliar de SER_CaseRestManager.
*/
public with sharing class SER_CaseRest_HELPER {

  /*Instancia única de la clase para implementar un patrón Singleton*/
  private static SER_CaseRest_HELPER instance;

  /*
  * @Description: Constructor privado.
  */
  private SER_CaseRest_HELPER() {
  }

  /*
  * @Description: devuelve una instancia unica de esta clase. Patron Singleton.
  */
  public static SER_CaseRest_HELPER getSingleInstance() {
    // lazy load the record type - only initialize if it doesn't already exist
    if(instance == null) {
      instance = new SER_CaseRest_HELPER();
    }
    return instance;
  }

  /*
  * @Description: se crea el Subject del caso .
  * @param SData data: Wrapper que contiene la informacion necesaria para crear el caso.
  * @return String
  */
  public static String createSubject(SER_CaseRestManager.SData data) {
    String stringToReturn;
    if(String.isNotBlank(data.productReference)) {
      stringToReturn = 'Consulta ' + data.productReference;
    } else if(data.description.length() <= SER_Constant.LENGTH40) {
      stringToReturn = data.description;
    } else {
      stringToReturn = (data.description).substring(0, 40) + '...';
    }
    return stringToReturn;
  }

  /*
  * @Description: se rellena el campo contact preference.
  * @param SData data: Wrapper que contiene la informacion necesaria para crear el caso.
  * @return SData
  */
  public static SER_CaseRestManager.SData fillContactPreference(SER_CaseRestManager.SData data) {
    if(String.isBlank(data.phone)) {
      data.contactPreference = 'EMAIL';
      data.phone = '';
    } else if(String.isBlank(data.email)) {
      data.contactPreference = 'PHONE';
      data.email = '';
    }
    return data;
  }

  /*
  * @Description: se rellena el campo description.
  * @param SData data: Wrapper que contiene la informacion necesaria para crear el caso.
  * @return String
  */
  public static String fillDescription(SER_CaseRestManager.SData data) {
    String strDesNetCash =  'Name: ' + data.name + ';' + SER_Constant.SALTO_DE_LINEA +
                            'ContactPreference: ' + data.contactPreference + ';' + SER_Constant.SALTO_DE_LINEA +
                            'Phone: ' + data.phone + ';' + SER_Constant.SALTO_DE_LINEA +
                            'Email: ' + data.email + ';';

    if(!String.isBlank(data.productReference)) {
      strDesNetCash += SER_Constant.SALTO_DE_LINEA + 'ProductReference: ' + data.productReference + ';';
    }

    strDesNetCash = fillDescriptionUser(data,strDesNetCash);

    if(data.caseOrigin == Label.WS_MaxMistral && !String.isBlank(data.clientName)) {
      strDesNetCash += SER_Constant.SALTO_DE_LINEA + 'ClientName: ' + data.clientName + ';';
    }

    if(data.caseOrigin == Label.WS_MaxMistral && !String.isBlank(data.caseCreator)) {
      strDesNetCash += SER_Constant.SALTO_DE_LINEA + 'CaseCreator: ' + data.caseCreator + ';';
    }

    if(!String.isBlank(data.product)) {
      strDesNetCash += SER_Constant.SALTO_DE_LINEA + 'product: ' + data.product + ';';
    }

    strDesNetCash += SER_Constant.SALTO_DE_LINEA + data.description + ';';

    return strDesNetCash;
  }

  /*
  * @Description: dependiendo de el origen nos va a poner en la descripcion 'UserCodeWS' o 'NetCash User'.
  * @param SData data: Wrapper que contiene la informacion necesaria para crear el caso.
  * @param string strDesNetCash
  * @return String
  */
  public static String fillDescriptionUser(SER_CaseRestManager.SData data, string strDesNetCash) {

    String stringToReturn;
    stringToReturn = strDesNetCash;

    if(!String.isBlank(data.userCodeWS) && data.caseOrigin != Label.WS_WebForm) {
      stringToReturn += SER_Constant.SALTO_DE_LINEA + 'UserCodeWS: ' + data.userCodeWS + ';';
    }

    if(!String.isBlank(data.userCodeWS) && data.caseOrigin == Label.WS_WebForm) {
      stringToReturn += '\n\r' + 'NetCash User: ' + data.userCodeWS + ';';
    }
    return stringToReturn;
  }

  /*
  * @Description: Se rellena el caseId, si el case origin es Max Mistral se devuelve el Id del caso
  *               y si es Net Cash o Boss se devuelve el case number.
  * @param SData data: Wrapper que contiene la informacion necesaria para crear el caso.
  * @param Id caseId: Id del caso para poder obtener el case number si procede.
  * @return SData
  */
  public static String fillCaseId(SER_CaseRestManager.SData data, Id caseSId) {
    String caseId = '';
    if(data.caseOrigin == Label.WS_MaxMistral) {
      caseId = caseSId;
    } else {
      Case caseWS;
      caseWS = [SELECT CaseNumber FROM Case WHERE Id =: caseSId];
      if(caseWS != null) {
        caseId = caseWS.CaseNumber;
      }
    }
    return caseId;
  }

  /*
  * @Description: Valida los tamaños de los campos obligatorios establecidos para poder dar de alta el caso.
  *               Si esta OK devuelve una cadena vacía, si algún campo es nulo devuelve
  *               el mensaje de error correspondiente.
  * @param data <tt>SData</tt> con el objeto Data a comprobar.
  * @return <tt>String</tt> con el mensaje de error o <tt>vacio</tt> si esta OK.
  */
  public static String validateSplunkSizeFields(SER_CaseRestManager.SData data) {
    // Objecto retorno
    String toReturn = '';

    // Description
    Boolean description;
    description = !String.isBlank(data.description) && data.description.length() > 31999;
    if(description) {
      toReturn += ' description ';
    }

    // Email - ID Splunk
    Boolean email;
    email = !String.isBlank(data.email) && data.email.length() > 249;
    if(email) {
      toReturn += ' ID Splunk ';
    }

    // UserCodeWS - Subject
    Boolean userCode;
    userCode = !String.isBlank(data.userCodeWS) && data.userCodeWS.length() > 254;
    if(userCode) {
      toReturn += ' Subject ';
    }

    // Name - Nombre fichero
    Boolean fichero;
    fichero = !String.isBlank(data.caseCreator) && data.caseCreator.length() > 254;
    if(fichero) {
      toReturn += ' Nombre fichero ';
    }

    return toReturn == '' ? null : SER_Constant.MSG_ERROR_SIZE + ': ' + toReturn;
  }

  /*
  * @Description: rellena el mapa countryMap con el pais como clave y su codigo
  *               ISO como valor.
  * @return Map<String, String>.
  */
  private static Map<String, String> fillCountryMap() {
    Map<String, String> countryMap;
    countryMap = new Map<String, String>();
    countryMap.put('Perú', 'PE');
    countryMap.put('Argentina', 'AR');
    countryMap.put('Chile', 'CL');
    countryMap.put('Colombia', 'CO');
    countryMap.put('Venezuela', 'VE');
    countryMap.put('Mexico', 'MX');
    countryMap.put('Uruguay', 'UY');
    countryMap.put('Paraguay', 'PY');
    countryMap.put('España', 'ES');
    countryMap.put('Portugal', 'PT');
    countryMap.put('Turquía', 'TR');
    countryMap.put('Estados Unidos', 'US');
    countryMap.put('Francia', 'FR');
    countryMap.put('Reino Unido', 'UK');
    return countryMap;
  }

}