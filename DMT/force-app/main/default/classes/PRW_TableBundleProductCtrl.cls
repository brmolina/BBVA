/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_TableBundleProductCtrl
* @Author   Global Hub
* @Date     Created: 2022-06-08
* ------------------------------------------------------------------------------------------------
* @Description Controller class for PRW_FourthTabContent component
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2022-01-19 ivan.garc.contrator@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
public with sharing class PRW_TableBundleProductCtrl {
  
  /**
  * SINGLETON PATTERN
  */
  private static PRW_TableBundleProductCtrl instance;
  /**
  * Constructor
  */
  private PRW_TableBundleProductCtrl() {
  }

  /**
  * getInstance
  */
  public static PRW_TableBundleProductCtrl gtInstance() {
    if(instance == null) {
      instance = new PRW_TableBundleProductCtrl();
    }
    return instance;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return data from a web service 
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2022-01-19
  * @param idCuaderno - Record Id to do the request
  * @param type - Type of access to the service
  * @return Bundle Objects Map - Wrapper with the data of the web service call
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static Map<String,Object> gtDataBundles(String idServicio, String clientType) {
    Map<String,Object> returnMap = new Map<String,Object>();
    final String request = '?petitionBy.petitionType=' + clientType + '&petitionBy.id=' + idServicio;
    final Map<String,String> jsonInputMap = new Map<String,String>();
    jsonInputMap.put('queryParameters', request);
    final HttpResponse mockTest = new HttpResponse();
    mockTest.setStatus('OK');
    mockTest.setStatusCode(201);
    mockTest.setBody(Label.PRW_MockResponseBundles);
    try {
      final HttpResponse response = ( Test.isRunningTest() ? mockTest : iaso.GBL_Integration_GenericService.invoke('bundleProducts', jsonInputMap));
      if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
        String responseReplace = response.getBody().replaceAll('"id":','"id_y":');
        responseReplace = responseReplace.replaceAll('"currency":','"currency_y":');
        final PRW_Bundles_Service.Data propResponse = (PRW_Bundles_Service.Data) Json.deserialize(responseReplace, PRW_Bundles_Service.Data.class);
        returnMap = completeProdResponse(propResponse);
        returnMap.put('success', true);
      } else if(response.getStatusCode() == 500 || response.getStatusCode() == 400) {
        final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        String responseSerialize = JSON.serialize(responseMap.get('messages'));
        final Map<String, Object> responseMap1 = (Map<String, Object>) JSON.deserializeUntyped(responseSerialize.substring(1, responseSerialize.length() -1));
        final String response2 = (String)responseMap1.get('message');
        returnMap.put('success', false);
        returnMap.put('errorMessage', Label.PRW_ErrorService + ' ' + response2);
      } else {
        returnMap.put('success', false);
        returnMap.put('errorMessage', Label.PRW_ErrorService);
      }
    } catch (Exception e) { //NOSONAR
      throw new AuraHandledException(e.getMessage()); //NOSONAR
    }
    system.debug(JSON.serialize(returnMap));
    system.debug(returnMap);
    return returnMap;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that prepare the response for returning into component
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2022-02-02
  * @param clientCode - Id of the account
  * @param propResponse - Wrapper with response
  * @return Map<String,Object> - List of products from response
  * --------------------------------------------------------------------------------------
  **/
  private static Map<String,Object> completeProdResponse(PRW_Bundles_Service.Data propResponse) {
    final Map<String,Object> returnMap = new Map<String,Object>();
    final List<PRW_Bundles_Service.BundleDataWrap> bundleList = new List<PRW_Bundles_Service.BundleDataWrap>();
    Integer iteration = 0;
    for(PRW_Bundles_Service.Response resp : propResponse.data) {
      iteration ++;
      
        final PRW_Bundles_Service.BundleDataWrap bundleRow = new PRW_Bundles_Service.BundleDataWrap();
        final List<PRW_Bundles_Service.TableBundleProdDataWrap> tableBundledata = new List<PRW_Bundles_Service.TableBundleProdDataWrap>();
        final List<PRW_Bundles_Service.TableBundleProdDataWrap> tabledataOrdered = new List<PRW_Bundles_Service.TableBundleProdDataWrap>();
        final List<PRW_Bundles_Service.TableNBPDataWrap> tableNBPdata = new List<PRW_Bundles_Service.TableNBPDataWrap>();
        bundleRow.description = resp.description;
        bundleRow.bundleName = resp.id_y;
        bundleRow.currency_y = resp.price.currency_y;
        bundleRow.bundlePrice = resp.price.amount;
        bundleRow.isBestOption = resp.optimalProductPack == null || resp.optimalProductPack.id_y == null ? false: true;
        if(resp.products!= null ){
          for(PRW_Bundles_Service.Products prod : resp.products) {
            final PRW_Bundles_Service.TableBundleProdDataWrap bundle = new PRW_Bundles_Service.TableBundleProdDataWrap();  
            bundle.bundleProd = prod.description;
            bundle.order = prod.order;
            bundle.qntity = prod.optimalVolume;
            tableBundledata.add(bundle);
          }
          
          List<String> orderList = new List<String>();
          Map<String,PRW_Bundles_Service.TableBundleProdDataWrap> orderMap = new Map<String,PRW_Bundles_Service.TableBundleProdDataWrap>();
          for(PRW_Bundles_Service.TableBundleProdDataWrap cond : tableBundledata){
            
            orderMap.put(cond.bundleProd,cond);

            
            orderList.add(cond.bundleProd);
          }
          orderList.sort();
          for(String name : orderList){
            tabledataOrdered.add(orderMap.get(name));
          }

        }  

        if(resp.participants != null){
          List<String> nombresCif = new List<String>();
          List<String> idsCIF = new List<String>();
          for( PRW_Bundles_Service.Participant participant : resp.participants){
            idsCIF.add(participant.id_y);
          }
          
          for(Account acc : [SELECT Id, g_customer_id__c , Name FROM Account WHERE g_customer_id__c IN  : idsCIF]){
            nombresCif.add(acc.g_customer_id__c + ' - ' + acc.Name);
          }
          bundleRow.cifNames = nombresCif;
          bundleRow.cifs = resp.participants.size();
         }


        // if(resp.nextBestProducts!= null){
        //   for(PRW_Bundles_Service.NextBestProducts nbProd : resp.nextBestProducts) {
        //     final PRW_Bundles_Service.TableNBPDataWrap nbProdBund = new PRW_Bundles_Service.TableNBPDataWrap();  
        //     nbProdBund.nextBestProd = nbProd.description;
        //     nbProdBund.order = nbProd.order;
        //     nbProdBund.qntity = nbProd.optimalVolume;
        //     nbProdBund.price = nbProd.optimalPrice.amount;
        //     nbProdBund.currency_y = nbProd.optimalPrice.currency_y;
        //     tableNBPdata.add(nbProdBund);
        //   }
        // }
        bundleRow.nextBestProd = tableNBPdata;
        bundleRow.bundleProd = tabledataOrdered;
        //if(iteration == 1){
          //bundleRow.isBestOption = true;
        //}
        bundleList.add(bundleRow);
        
    }

    Map<Integer,PRW_Bundles_Service.BundleDataWrap> mapaparaordenar = new map<Integer,PRW_Bundles_Service.BundleDataWrap>();
    PRW_Bundles_Service.BundleDataWrap bundleBestOption;
    List<PRW_Bundles_Service.BundleDataWrap> listToReturn = new List<PRW_Bundles_Service.BundleDataWrap>();
    List<Integer> numerosBundleName = new List<Integer>();

    Integer bundleNumber = 0;

    for(PRW_Bundles_Service.BundleDataWrap bundleElement : bundleList){
      if(!bundleElement.isBestOption){
        bundleNumber = Integer.valueOf(bundleElement.bundleName);
        numerosBundleName.add(bundleNumber);
        mapaparaordenar.put( bundleNumber, bundleElement);
      }else{
         bundleBestOption = bundleElement;
      }
    }

    numerosBundleName.sort();

    for(Integer ind : numerosBundleName){

      listToReturn.add(mapaparaordenar.get(ind));

    }
    if(bundleBestOption!=null){
      listToReturn.add(0 ,bundleBestOption);
    }

    returnMap.put('bundles', JSON.serialize(listToReturn,true));
    return returnMap;

  }
   /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return data from a web service 
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2022-01-19
  * @param idCuaderno - Record Id to do the request
  * @param type - Type of access to the service
  * @return Bundle Objects Map - Wrapper with the data of the web service call
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static Map<String,Object> gtCatalog() {
    Map<String,Object> returnMap = new Map<String,Object>();
    final Map<String,String> jsonInputMap = new Map<String,String>();
    final HttpResponse mockTest = new HttpResponse();
    final String queryParameter = '?catalog=B289&relatedCatalog=B293';
    jsonInputMap.put('queryParameter' , queryParameter);
    mockTest.setStatus('OK');
    mockTest.setStatusCode(201);
    mockTest.setBody(Label.PRW_MockResponseCatalog);
    try {
      final HttpResponse response = ( Test.isRunningTest() ? mockTest : iaso.GBL_Integration_GenericService.invoke('getProductCatalog',jsonInputMap));
      if (response.getStatusCode() == 200 || response.getStatusCode() == 201 ) {
        String responseReplace = response.getBody().replaceAll('"id":','"id_y":');
        final PRW_Catalog_Service.Data propResponse = (PRW_Catalog_Service.Data) Json.deserialize(responseReplace ,PRW_Catalog_Service.Data.class);
        returnMap = parseCatalog(propResponse);
        returnMap.put('success', true);
      } else if(response.getStatusCode() == 500 || response.getStatusCode() == 400) {
        final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        String responseSerialize = JSON.serialize(responseMap.get('messages'));
        final Map<String, Object> responseMap1 = (Map<String, Object>) JSON.deserializeUntyped(responseSerialize.substring(1, responseSerialize.length() -1));
        final String response2 = (String)responseMap1.get('message');
        returnMap.put('success', false);
        returnMap.put('errorMessage', Label.PRW_ErrorService + ' ' + response2);
      } else {
        returnMap.put('success', false);
        returnMap.put('errorMessage', Label.PRW_ErrorService);
      }
    } catch (Exception e) { //NOSONAR
      returnMap.put('success', false); //NOSONAR
      returnMap.put('errorMessage', Label.PRW_ErrorService); //NOSONAR
    }
    return returnMap;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that prepare PetitionBy section request
  * --------------------------------------------------------------------------------------
  * @Author   ivan.garces.contractor@bbva.com
  * @Date     Created: 2021-08-26
  * @param responseCatalog - JSON with the data 
  * @return Map<String,Object> - List of products from response
  * --------------------------------------------------------------------------------------
  **/
  private static Map<String,Object> parseCatalog(PRW_Catalog_Service.Data responseCatalog) {
    final Map<String,Object> returnMap = new Map<String,Object>();
    final List<PRW_Catalog_Service.LevelDataWrap> catalog = new List<PRW_Catalog_Service.LevelDataWrap>();
      for(PRW_Catalog_Service.Level responseLevels : responseCatalog.data[0].levels) {
          PRW_Catalog_Service.LevelDataWrap level = new PRW_Catalog_Service.LevelDataWrap();
          level.firstLevel = responseLevels.firstLevel == null ? null : responseLevels.firstLevel.id_y;
          level.secondLevel = responseLevels.secondLevel == null ? null : responseLevels.secondLevel.id_y;
          level.thirdLevel = responseLevels.thirdLevel == null ? null : responseLevels.thirdLevel.id_y;
          level.fourthLevel = responseLevels.fourthLevel == null ? null : responseLevels.fourthLevel.id_y;
          level.fifthLevel = responseLevels.fifthLevel == null ? null : responseLevels.fifthLevel.id_y;
          catalog.add(level);
      }
    returnMap.put('catalog', JSON.serialize(catalog,true));
    return returnMap;
  }
}