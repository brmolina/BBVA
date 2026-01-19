/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_RecordCompactCtrl
* @Author   Global Hub
* @Date     Created: 2021-07-22
* ------------------------------------------------------------------------------------------------
* @Description Controller for PRW_RecordCompactLayout
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-08-25 david.rodriguez.lucena.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:AvoidUsingTestIsRunningTest')
public with sharing class PRW_RecordCompactCtrl {
  /**
  * SINGLETON PATTERN
  */
  private static PRW_RecordCompactCtrl instance;

  /**
  * GLOBAL VARIABLE prodIDS
  */
  private static Set<String> prodIDS;

  /**
  * Constructor
  */
  private PRW_RecordCompactCtrl() {
  }

  /**
  * getInstance
  */
  public static PRW_RecordCompactCtrl gtInstance() {
    if(instance == null) {
      instance = new PRW_RecordCompactCtrl();
    }
    return instance;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return an Account based on recordId
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-07-22
  * @param recordId - Record Id of the account
  * @return Account - Wrapper with the data of the
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static Map<String,Object> calculatePrice(String clientCode, String data, String idCuaderno, Boolean isGroup) {
    Map<String,Object> returnMap = new Map<String,Object>();
    prodIDS = new Set<String>();
    final String request = prepareRequest(clientCode, data, idCuaderno, isGroup);
    final String userCode = [SELECT FederationIdentifier FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].FederationIdentifier;
    final Map<String,String> jsonInputMap = new Map<String,String>();
    jsonInputMap.put('JSONinput', request);
    jsonInputMap.put('userId', userCode);
    final HttpResponse mockTest = new HttpResponse();
    mockTest.setStatus('OK');
    mockTest.setStatusCode(201);
    mockTest.setBody(Label.PRW_MockResponse);
    try {
      final HttpResponse response = ( Test.isRunningTest() ? mockTest : iaso.GBL_Integration_GenericService.invoke('notebookPricing', jsonInputMap));  
      if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
        final String responseReplace = response.getBody().replaceAll('"id":','"id_y":');
        final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
        final PRW_Notebook_Service propResponse = (PRW_Notebook_Service) Json.deserialize(JSON.serialize(responseMap.get('data')), PRW_Notebook_Service.class);
        returnMap = completeProdResponse(clientCode, idCuaderno, propResponse);
        returnMap.put('success', true);
      } else if(response.getStatusCode() == 500 || response.getStatusCode() == 400) {
        final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        String responseSerialize = JSON.serialize(responseMap.get('messages'));
        final Map<String, Object> responseMap1 = (Map<String, Object>) JSON.deserializeUntyped(responseSerialize.substring(1, responseSerialize.length() -1));
        String response2 = (String)responseMap1.get('message');
        final List<String> listResponse = response2.split('#');
        returnMap.put('success', false);
        returnMap.put('errorMessage', Label.PRW_ErrorService + ' ' + listResponse.get(1));
      } else {
        returnMap.put('success', false);
        returnMap.put('errorMessage', Label.PRW_ErrorService);
      }
    } catch (Exception e) { //NOSONAR
      throw new AuraHandledException(e.getMessage()); //NOSONAR
    }
    return returnMap;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that prepare request to invoke service
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-07-22
  * @param clientCode - Id of the account
  * @param data - List of products to send into the request
  * @return String - Request to send
  * --------------------------------------------------------------------------------------
  **/
  public static String prepareRequest(String clientCode, String data, String idCuaderno, Boolean isGroup) {
    final PRW_Notebook_Service.petitionBy petitionBy = requestPetitionBy(clientCode, idCuaderno, isGroup);
    final List<PRW_Notebook_Service.Pricing> listPricing = requestPricing(data);
    final PRW_Notebook_Service request = new PRW_Notebook_Service();
    request.petitionBy = petitionBy;
    request.pricing = listPricing;
    return JSON.serialize(request,true).replaceAll('id_y','id');
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that prepare Pricing section request
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-08-25
  * @param data - products to be sended to service
  * @return List<PRW_Notebook_Service.Pricing> - List of pricing from wrapper
  * --------------------------------------------------------------------------------------
  **/
  private static List<PRW_Notebook_Service.Pricing> requestPricing(String data) {
    final List<PRW_Notebook_Service.Pricing> pricingList = new List<PRW_Notebook_Service.Pricing>();
    final List<Map<String,String>> listObject = (List<Map<String,String>>) JSON.deserialize(data, List<Map<String,String>>.class);
    for(Map<String,String> element : listObject) {
      final PRW_Notebook_Service.Pricing pricing = new PRW_Notebook_Service.Pricing();
      final List<PRW_Notebook_Service.Product> products = new List<PRW_Notebook_Service.Product>();
      final PRW_Notebook_Service.Product prod = new PRW_Notebook_Service.Product();
      prod.productConditionType = 'CASH_MANAGEMENT';
      prod.id_y = element.get('id_prod');
      prod.price = element.get('simulatedP') == null ? '0' : element.get('simulatedP');
      prod.volume = element.get('simulatedQ') == null ? '0' : element.get('simulatedQ');
      prodIDS.add(element.get('id_prod'));
      products.add(prod);
      pricing.details = new PRW_Notebook_Service.Details('SIMPLE',null); //Un único prod por pricing y SIMPLE
      pricing.products = products;
      pricingList.add(pricing);
    }
    return pricingList;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that prepare PetitionBy section request
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-08-25
  * @param data - products to be sended to service
  * @return List<PRW_Notebook_Service.Product> - List of products from wrapper
  * --------------------------------------------------------------------------------------
  **/
  private static PRW_Notebook_Service.petitionBy requestPetitionBy(String clientCode, String idCuaderno, Boolean isGroup) {
    final PRW_Notebook_Service.petitionBy petitionBy = new PRW_Notebook_Service.petitionBy();
    if(idCuaderno != null && idCuaderno != '' && isGroup) {
      petitionBy.petitionType = 'NOTEBOOK';
      petitionBy.id_y = idCuaderno;
    } else if(clientCode != null && clientCode != '') {
      petitionBy.petitionType = 'BUSINESS';
      petitionBy.id_y = clientCode;
    }
    return petitionBy;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that prepare PetitionBy section request
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-08-26
  * @param clientCode - Id of the account
  * @param propResponse - Wrapper with response
  * @return Map<String,Object> - List of products from response
  * --------------------------------------------------------------------------------------
  **/
  private static Map<String,Object> completeProdResponse(String clientCode, String idCuaderno, PRW_Notebook_Service propResponse) {
    final Map<String,Object> returnMap = new Map<String,Object>();
    final List<PRW_Notebook_Service.Product> listProducts = new List<PRW_Notebook_Service.Product>();
    if((propResponse.petitionBy.petitionType == 'BUSINESS' && clientCode == propResponse.petitionBy.id_y)
    || (propResponse.petitionBy.petitionType == 'NOTEBOOK' && idCuaderno == propResponse.petitionBy.id_y)) { //Comprueba que cliente respuesta = cliente request
      for(PRW_Notebook_Service.Pricing price : propResponse.pricing) {
        for(PRW_Notebook_Service.Product product : price.products) {
          if(prodIDS.contains(product.id_y)) { //Pasa al componente solo los productos que van en la request
            
            if(product.notifications != null){
              for(PRW_Notebook_Service.Notification notification : product.notifications){
                if(notification.description.contains(product.id_y)){
                  product.notificationDescription = notification.description != null ?   notification.description : null;
                  product.notificationCode = notification.code != null ?  notification.code : null;
                }
              }
              product.notifications.clear();
            }

            listProducts.add(product);
          }
        }
      }
    }
    returnMap.put('products', JSON.serialize(listProducts,true));
    return returnMap;
  }
}