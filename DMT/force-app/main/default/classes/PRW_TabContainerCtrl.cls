/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_TabContainerCtrl
* @Author   Global Hub
* @Date     Created: 2021-07-22
* ------------------------------------------------------------------------------------------------
* @Description Controller class for PRW_TabContainer component
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-07-22 david.rodriguez.lucena.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
public with sharing class PRW_TabContainerCtrl {
  /**
  * SINGLETON PATTERN
  */
  private static PRW_TabContainerCtrl instance;

  /**
  * Constructor
  */
  private PRW_TabContainerCtrl() {
  }

  /**
  * getInstance
  */
  public static PRW_TabContainerCtrl gtInstance() {
    if(instance == null) {
      instance = new PRW_TabContainerCtrl();
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
  public static Account gtInfoAccount(String recordId) {
    Account acc = new Account();
    system.debug(acc);
    try {
      final List<Account> lstAccount = new List<Account>([
        SELECT id, Name, DES_Client_Type__c, SER_CClient__c
        FROM Account
        WHERE Id = :recordId
      ]);
      if(!lstAccount.isEmpty()) {
        acc = lstAccount.get(0);
      }
    } catch (Exception e) { //NOSONAR
        throw new AuraHandledException(e.getMessage()); //NOSONAR
    }
    system.debug(acc);
    return acc;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return an Account based on recordId
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-07-22
  * @param accId - Record Id of the account
  * @return cuco__profitability_sheet_participant__c - Current pricing condition book
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static cuco__profitability_sheet_participant__c gtProfSheet(String accId) {
    cuco__profitability_sheet_participant__c profSheet;
    system.debug(profSheet);
    try {
      final List<cuco__profitability_sheet_participant__c> lstProfSheet = new List<cuco__profitability_sheet_participant__c>([
        SELECT cuco__gf_profitability_sheet_id__r.id, cuco__gf_profitability_sheet_id__r.cuco__gf_profitability_sheet_id__c, cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_end_date__c, cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_start_date__c
        FROM cuco__profitability_sheet_participant__c
        WHERE cuco__participant_id__c = :accId
        AND cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_end_date__c > TODAY
      ]);
      if(!lstProfSheet.isEmpty()) {
        profSheet = lstProfSheet.get(0);
      }
    } catch (Exception e) { //NOSONAR
        throw new AuraHandledException(e.getMessage()); //NOSONAR
    }
    system.debug(profSheet);
    return profSheet;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return an Account based on recordId
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-12-01
  * @param profShId - SF Id of the CuCo
  * @return List<String> - List of names of participants
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static List<String> gtParticipants(String profShId) {
    final List<String> lstNames = new List<String>();
    try {
      final List<cuco__profitability_sheet_participant__c> lstProfSheet = new List<cuco__profitability_sheet_participant__c>([
        SELECT cuco__participant_id__r.name, cuco__participant_id__r.DES_ID_Fiscal__c, cuco__gf_profitability_sheet_id__r.id
        FROM cuco__profitability_sheet_participant__c
        WHERE cuco__gf_profitability_sheet_id__c = :profShId
        AND cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_end_date__c > TODAY
      ]);
      for(cuco__profitability_sheet_participant__c part : lstProfSheet) {
        lstNames.add(part.cuco__participant_id__r.name + '-' + part.cuco__participant_id__r.DES_ID_Fiscal__c);
      }
    } catch (Exception e) { //NOSONAR
        throw new AuraHandledException(e.getMessage()); //NOSONAR
    }
    lstNames.sort();
    return lstNames;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that call CuCo condition service
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-07-22
  * @param cucoId - Id of the CuCo
  * @return Map<String,Object> - Response from the server
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static Map<String,Object> gtCuCoConditions(String cucoSFId, String cucoId) {
    final cuco.ProfitabilitySheet_Selector selectorProfSheet = new cuco.ProfitabilitySheet_Selector(true);
    final List<cuco__profitability_sheet__c> profSheets = selectorProfSheet.selectById(new Set<Id>{cucoSFId});
    Map<String,Object> returnMap = new Map<String,Object>();
    final GetProposalWrapper gtCondWrap = new GetProposalWrapper(cucoId);
    try {
      final HttpResponse responseGtCond = callWs('getProposalConditionsNotebook', JSON.serialize(gtCondWrap));
      returnMap = gtCondResponse(responseGtCond, profSheets);
    } catch (Exception e) { //NOSONAR
        throw new AuraHandledException(e.getMessage()); //NOSONAR
    }
    return returnMap;
  }


  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that call CuCo condition service
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-09-08
  * @param serviceName - serviceName name of the metadata of Aso service
  * @param request - request
  * @return HttpResponse - Response from the server
  * --------------------------------------------------------------------------------------
  **/
  public static HttpResponse callWs(String serviceName, String request) {
    HttpResponse response;
    final iaso__GBL_integration_service__mdt serviceProp = iaso__GBL_integration_service__mdt.getInstance(serviceName);
    if (serviceProp.iaso__Retrieve_Mock_LTA__c) {
        response = cuco.Utils.getResponseMock(serviceName, null);
    } else {
        response = cuco.Utils.callWServices(serviceName, request);
    }
    return response;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that call CuCo condition service
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-09-08
  * @param serviceName - serviceName name of the metadata of Aso service
  * @param request - request
  * @return HttpResponse - Response from the server
  * --------------------------------------------------------------------------------------
  **/
  public static Map<String,Object> gtCondResponse(HttpResponse response, List<cuco__profitability_sheet__c> profSheets) {
    Map<String,Object> returnMap = new Map<String,Object>();
    switch on response.getStatusCode() {
      when 204 {
        returnMap.put('success', false);
        returnMap.put('errorMessage', Label.cuco.no_ps_details);
      }
      when 200 {
        final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        returnMap = stResponseOk(responseMap, response, profSheets);
      }
      when else {
        String error = null;
        final Map<String,Object> errorMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
        if (errorMap.containsKey('messages')) {
          final List<Object> messageMapList = (List <Object>) errorMap.get('messages');
          final Map<String,Object> messageMap = (Map<String,Object>) messageMapList[0];
          if (messageMap.containsKey('message')) {
            error = (String) messageMap.get('message');
          }
        }
        returnMap.put('success', false);
        returnMap.put('errorMessage', Label.cuco.error_ps_details + ' ' + error);
      }
    }
    return returnMap;
  }


  /**
  * --------------------------------------------------------------------------------------
  * @Description - Wrapper Class to call getProposalConditionsNotebook
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-09-08
  * --------------------------------------------------------------------------------------
  **/
  public class GetProposalWrapper {
    /**
    * @description Private constructor to avoid sonar err
    */
    public String profSheetCode {get;set;}

    /**
    * @description Private constructor to avoid sonar err
    */
    public String userId {get;set;}

    /**
    * @description constructor GetProposalConditionsNotebook_Helper
    * @param profSheetCode
    */
    public GetProposalWrapper(String profSheetCode) {
        final String userCode = [SELECT FederationIdentifier FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].FederationIdentifier;
        this.userId = userCode;
        this.profSheetCode = profSheetCode;
    }
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Wrapper Class to call listProposalNotebookConditions
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-09-08
  * --------------------------------------------------------------------------------------
  **/
  public class GetListProposalWrapper {
    /**
    * @description Private constructor to avoid sonar err
    */
    public String profSheetCode {get;set;}

    /**
    * @description Private constructor to avoid sonar err
    */
    public String userId {get;set;}

    /**
    * @description Private constructor to avoid sonar err
    */
    public Date conditionsDate {get;set;}

    /**
    * @description constructor ListProposalNotebookConditions_Helper
    * @param profSheetCode user code
    * @param conditionsDate date conditions
    */
    public GetListProposalWrapper (String profSheetCode, Date conditionsDate) {
      final String userCode = [SELECT FederationIdentifier FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].FederationIdentifier;
      this.userId = userCode;
      this.conditionsDate = conditionsDate;
      this.profSheetCode = profSheetCode;
    }
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return a Map  with Cuco Names and Ammount condition
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-09-10
  * @param cucoConditions - Conditions serialize
  * @return Account - Wrapper with the data of the
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static String gtCucoNamesAndAmount(String sConditions) {
    final List<ConditionsWrapper> lReturnWrp = new List<ConditionsWrapper>();
    try {
      if(sConditions != null) {
        final Map<String, Object> wrapper = (Map<String, Object>)JSON.deserializeUntyped(sConditions);
        lReturnWrp.addAll(getConditions(wrapper));
        lReturnWrp.addAll(getFlats(wrapper));
      }

    } catch (Exception e) { //NOSONAR
        throw new AuraHandledException(e.getMessage()); //NOSONAR
    }

    return JSON.serialize(lReturnWrp,true);
  }

  private static List<ConditionsWrapper> getConditions(Map<String, Object> wrapper) {
    final List<ConditionsWrapper> lReturnWrp = new List<ConditionsWrapper>();
    final Map<Id,  String> mIdCondAmnt = new Map<Id,  String>();
    String value;
    String canonicalId;
    canonicalId = 'canonicalId';
    //CONDITIONS
    for(Object condition : (List<Object>) wrapper.get('conditionsList')) {
      final Map<String, Object> conditionUntyped = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(condition));
      value = '0';
      for (Object att : (List<Object>) conditionUntyped.get('attributesList')) {
        final Map<String, Object> attUntyped = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(att));
        if (((String)attUntyped.get(canonicalId)).contains('.amount')) {
          value = (String)attUntyped.get('value');
        }
      }
      mIdCondAmnt.put((String)conditionUntyped.get('id'), value);
    }

    final Map<id,cuco__ps_catalog_condition__c> mConditionName = new Map<ID, cuco__ps_catalog_condition__c>(
      [SELECT id, Name, cuco__gf_psc_condition_id__c, cuco__gf_psc_family_id__r.name
      FROM cuco__ps_catalog_condition__c
      WHERE id IN :mIdCondAmnt.keySet()
      AND cuco__gf_psc_cond_avail_ind_type__c = true
      AND cuco__gf_psc_family_id__r.cuco__gf_psc_family_avail_ind_type__c = true
      AND gf_psc_cond_pricewise_ind_type__c = true
    ]);

    for (String idCond : mIdCondAmnt.keySet()) {
      if (mConditionName.containsKey(idCond) && Double.ValueOf(mIdCondAmnt.get(idCond)) != 0) {
        lReturnWrp.add(new ConditionsWrapper(mConditionName.get(idCond).cuco__gf_psc_condition_id__c, mConditionName.get(idCond).cuco__gf_psc_family_id__r.name + ' - ' + mConditionName.get(idCond).Name, mIdCondAmnt.get(idCond),null, true));
      }
    }
    final List<ConditionsWrapper> lReturnWrp2 = orderConditionList(lReturnWrp);
    return lReturnWrp2;
  }

  private static Map<String,Object> stResponseOk(Map<String, Object> responseMap, HttpResponse response, List<cuco__profitability_sheet__c> profSheets) {
    Map<String,Object> returnMap = new Map<String,Object>();

    if (responseMap.containsKey('data')) {
      final Map<String, Object> mapData = (Map<String, Object>) responseMap.get('data');
      Date psDate; //NOSONAR
      String psStatus = ''; //NOSONAR
      system.debug(psDate + ' ' + psStatus);
      if (mapData.containsKey('status')) {
        final Map<String, Object> mapStatus = (Map<String, Object>) mapData.get('status');
        final String val = (String)mapStatus.get('id');
        switch on val {
          when 'ACTIVE', 'PENDING' {
            psDate = Date.today();
            psStatus = (val == 'ACTIVE') ? 'Valid' : 'Pending Request';
          }
          when 'EXPIRED' {
            psDate = Date.valueOf((String)mapData.get('endDate'));
            psStatus = 'Expired';
          }
          when 'CANCELED' {
            psDate = Date.valueOf((String)mapData.get('conditionsStartDate'));
            psStatus = 'Canceled';
          }
        }
      }
      system.debug(psDate + ' ' + psStatus);
      returnMap = PRW_BackendIntegration.callListProposalNotebookConditions(profSheets[0], psDate, responseMap, psStatus);
    } else {
      returnMap.put('success', false);
      returnMap.put('errorMessage', Label.cuco.error_ps_details + ' ' + response.getBody());
    }
    return returnMap;
  }

  private static List<ConditionsWrapper> getFlats(Map<String, Object> wrapper) {
    final List<ConditionsWrapper> lReturnWrp = new List<ConditionsWrapper>();
    final Map<String,  List<String>> mFlatAmntQuan = new Map<String,  List<String>>();
    String value;
    String quantity;
    String nameId;
    String canonicalId;
    canonicalId = 'canonicalId';
    //FLATS
    final Map<String, Object> mWrapper = (Map<String, Object>) wrapper.get('flatRates');
    final List<Object> flatRatesDP = new List<Object>();
    if(wrapper.containsKey('flatRates') && mWrapper.containsKey('flatRatesDPList')) {
      flatRatesDP.addAll((List<Object>)mWrapper.get('flatRatesDPList'));
    }
    for(Object flat : flatRatesDP) {
      final Map<String, Object> flatAttListUnt = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(flat));
      value = '0';
      quantity = '0';
      nameId = '';

      for(Object flatAtt : (List<Object>) flatAttListUnt.get('dpAttributeList')) {
        final Map<String, Object> flatUntyped = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(flatAtt));
        if(((String) flatUntyped.get(canonicalId)).contains('.p.')) {
          value = (String)flatUntyped.get('value');
        } else if(((String) flatUntyped.get(canonicalId)).contains('.q.')) {
          quantity = (String)flatUntyped.get('value');
        }
        nameId = (String)flatUntyped.get(canonicalId);
      }
      mFlatAmntQuan.put(nameId, new List<String> {value, quantity});
    }

    final Map<String,Flat_product_model__mdt> mNameProdFlat = new Map<String, Flat_product_model__mdt>();
    for(Flat_product_model__mdt fProdModel : [SELECT Id, DeveloperName,  Label, Family_Name__c, Product_name__c, Id_product__c, Quantity_id__c, Price_id__c, Order__c, Family_order__c FROM Flat_product_model__mdt LIMIT 200]) {
      mNameProdFlat.put(fProdModel.Quantity_id__c, fProdModel);
      mNameProdFlat.put(fProdModel.Price_id__c, fProdModel);
    }

    for (String nameFlat : mFlatAmntQuan.keySet()) {
      if (mNameProdFlat.containsKey(nameFlat)) {
        lReturnWrp.add(new ConditionsWrapper(mNameProdFlat.get(nameFlat).Id_product__c, mNameProdFlat.get(nameFlat).Family_Name__c + ' - ' + mNameProdFlat.get(nameFlat).Product_name__c, mFlatAmntQuan.get(nameFlat).get(0), mFlatAmntQuan.get(nameFlat).get(1), false));
      }
    }
    final List<ConditionsWrapper> lReturnWrp2 =orderConditionList(lReturnWrp);
    return lReturnWrp2;
  }

  private static List<ConditionsWrapper> orderConditionList(List<ConditionsWrapper> conditionsMap){
    final List<ConditionsWrapper> lReturnWrp = new List<ConditionsWrapper>();
    List<String> orderList = new List<String>();
    Map<String,ConditionsWrapper> orderMap = new Map<String,ConditionsWrapper>();
    for(ConditionsWrapper cond : conditionsMap){
      orderMap.put(cond.Name,cond);
      orderList.add(cond.Name);
    }
    orderList.sort();
    for(String name : orderList){
      lReturnWrp.add(orderMap.get(name));
    }
    return lReturnWrp;
  }
  /**
  * --------------------------------------------------------------------------------------
  * @Description - Wrapper Class to set Conditions
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-09-08
  * --------------------------------------------------------------------------------------
  **/
  public class ConditionsWrapper {
    /**
    * @description Private constructor to avoid sonar err
    */
    public String idProd {get;set;}

    /**
    * @description Private constructor to avoid sonar err
    */
    public String name {get;set;}

    /**
    * @description Private constructor to avoid sonar err
    */
    public String price {get;set;}

    /**
    * @description Private constructor to avoid sonar err
    */
    public String quantity {get;set;}

    /**
    * @description Private constructor to avoid sonar err
    */
    public Boolean isSpecial {get;set;}

    /**
    * @description constructor ListProposalNotebookConditions_Helper
    * @param idProd condition code
    * @param name condition name
    * @param price condition price
    * @param quantity condition quantity
    * @param isSpecial true if special condition false for flat fee
    */
    public ConditionsWrapper (String idProd, String name, String price, String quantity, Boolean isSpecial) {
      this.name = name;
      this.price = price;
      this.quantity = quantity;
      this.idProd = idProd;
      this.isSpecial = isSpecial;
    }
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
      if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
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
      returnMap.put('success', false);
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
    if(responseCatalog.data[0].levels != null){
      for(PRW_Catalog_Service.Level responseLevels : responseCatalog.data[0].levels) {
          PRW_Catalog_Service.LevelDataWrap level = new PRW_Catalog_Service.LevelDataWrap();
          level.firstLevel = responseLevels.firstLevel == null ? null : responseLevels.firstLevel.id_y;
          level.secondLevel = responseLevels.secondLevel == null ? null : responseLevels.secondLevel.id_y;
          level.thirdLevel = responseLevels.thirdLevel == null ? null : responseLevels.thirdLevel.id_y;
          level.fourthLevel = responseLevels.fourthLevel == null ? null : responseLevels.fourthLevel.id_y;
          level.fifthLevel = responseLevels.fifthLevel == null ? null : responseLevels.fifthLevel.id_y;
          catalog.add(level);
      }
    }
    returnMap.put('catalog', JSON.serialize(catalog,true));
    return returnMap;
  }
}