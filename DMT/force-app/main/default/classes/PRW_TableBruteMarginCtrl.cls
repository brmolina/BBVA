/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_TableBruteMarginCtrl
* @Author   Global Hub
* @Date     Created: 2022-04-27
* ------------------------------------------------------------------------------------------------
* @Description Controller class for PRW_TableBruteMargin component
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2022-01-19 ivan.garces.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
public with sharing class PRW_TableBruteMarginCtrl {
  private static PRW_TableBruteMarginCtrl instance; 

/**
  * GLOBAL VARIABLE YTD
  */
  private final static String CM = 'CM';
  /**
  * GLOBAL VARIABLE YTD
  */
  private final  static String WC = 'WC';
  /**
  * GLOBAL VARIABLE YTD
  */
  private final static String GTF = 'GTF';

  /**
  * GLOBAL VARIABLE YTD
  */
  private final static String YTD = 'YEAR_TO_DATE';

  /**
  * GLOBAL VARIABLE L12M
  */
  private final static String L12M = 'LAST_TWELVE_MONTHS';

  /**
  * GLOBAL VARIABLE ACCM
  */
  private final static String ACCM = 'ACCUMULATED_PERIOD';
  /**
  * GLOBAL VARIABLE ACCM
  */
  private final static String requestPublication = 'D';
  /**
  * GLOBAL VARIABLE ACCM
  */
  private final static String requestVision = 'M';
  /**
  * Constructor
  */
  private PRW_TableBruteMarginCtrl() {

}

/**
* getInstance
*/

public static PRW_TableBruteMarginCtrl gtInstance() {
  if(instance == null) {
    instance = new PRW_TableBruteMarginCtrl();
  }
  return instance;
}

/**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return the participants of a CuCo based on the cuco id
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2022-04-25
  * @param idCuaderno - CuCo Id
  * @return List<cuco__profitability_sheet_participant__c> - List of participants
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static List<cuco__profitability_sheet_participant__c> gtParticipants(String idCuaderno) {
    try {
      final List<cuco__profitability_sheet_participant__c> lstProfSheet = new List<cuco__profitability_sheet_participant__c>([
        SELECT cuco__participant_id__r.SER_CClient__c
        FROM cuco__profitability_sheet_participant__c
        WHERE cuco__gf_profitability_sheet_id__r.cuco__gf_profitability_sheet_id__c = :idCuaderno
        AND cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_end_date__c > TODAY
      ]);
      System.debug('Returning Participants! ' + lstProfSheet);
      return lstProfSheet;
    } catch (Exception e) { //NOSONAR
        throw new AuraHandledException(e.getMessage()); //NOSONAR
    }
  }
  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return an Account based on recordId
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2022-04-25
  * @param laccountsId - CClients from participants of the Cuco
  * @param profSheetStart - Start date of the Cuco
  * @param profSheetEnd - End date of the Cuco
  * @return Account - Wrapper with the data of the
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static Map<String,Object> gtDataMargin(String laccountsId, Date profSheetStart, Date profSheetEnd) {
    Map<String,Object> returnMap = new Map<String,Object>();
    System.debug('laccountsId : ' + laccountsId);
    final String request = prepareRequest(laccountsId, profSheetStart, profSheetEnd);
    final String userCode = [SELECT FederationIdentifier FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].FederationIdentifier;
    final Map<String,String> jsonInputMap = new Map<String,String>();
    jsonInputMap.put('JSONinput', request);
    jsonInputMap.put('userId', userCode);
    final HttpResponse mockTest = new HttpResponse();
    mockTest.setStatus('OK');
    mockTest.setStatusCode(201);
    mockTest.setBody(Label.PRW_MockResponseMargin);
    try {
      final HttpResponse response = ( Test.isRunningTest() ? mockTest : iaso.GBL_Integration_GenericService.invoke('generateMarginReport', jsonInputMap));
      if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
        String responseReplace = response.getBody().replaceAll('"id":','"id_y":');
        responseReplace = responseReplace.replaceAll('"transaction":','"transaction_y":');
        final PRW_Margin_Service.Data propResponse = (PRW_Margin_Service.Data) Json.deserialize(responseReplace, PRW_Margin_Service.Data.class);
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
  * @Description - Method that prepare request to invoke service
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2022-01-19
  * @param laccountsId - CClients from participants of the Cuco
  * @param profSheetStart - Start date of the Cuco
  * @param profSheetEnd - End date of the Cuco
  * @return String - Request to send
  * --------------------------------------------------------------------------------------
  **/
  public static String prepareRequest(String laccountsId, Date profSheetStart, Date profSheetEnd) {
    System.debug('laccountsId : ' + laccountsId);
    final PRW_Margin_Service.Request req = new PRW_Margin_Service.Request();
    final PRW_Margin_Service.PetitionBy petitionBy = requestPetitionBy(laccountsId);
    req.petitionBy = petitionBy;
    req.startDate = profSheetStart;
    req.endDate = System.today().addMonths(-1);
    req.vision = requestVision;
    req.publication = requestPublication;
    final List<PRW_Margin_Service.GroupBy> listaGroup = new List<PRW_Margin_Service.GroupBy>();
    final PRW_Margin_Service.GroupBy group1 = new PRW_Margin_Service.GroupBy('FIFTH_LEVEL_PRODUCT');
    final PRW_Margin_Service.GroupBy group2 = new PRW_Margin_Service.GroupBy('PRODUCT_FAMILY');
    listaGroup.add(group1);
    listaGroup.add(group2);
    req.groupBy = listaGroup;
    return JSON.serialize(req,true).replaceAll('id_y','id');
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that prepare PetitionBy section request
  * --------------------------------------------------------------------------------------
  * @Author   Ivan Garc�s
  * @Date     Created: 2022-04-22
  * @param laccountsId - Clients who requerst information
  * @return PRW_Margin_Service.PetitionBy - Applicants to get information from
  * --------------------------------------------------------------------------------------
  **/
  private static PRW_Margin_Service.PetitionBy requestPetitionBy(String laccountsId) {
      final PRW_Margin_Service.PetitionBy petitionBy = new PRW_Margin_Service.PetitionBy();
      petitionBy.petitionType = 'CUSTOMER';
      final List<String> laccountIds = laccountsId.split('-');
      petitionBy.id_y = laccountIds;
      return petitionBy;
  }
  
  
  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that prepare PetitionBy section request
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2022-02-02
  * @param clientCode - Id of the account
  * @param propResponse - Wrapper with response
  * @return Map<String,Object> - List of products from response
  * --------------------------------------------------------------------------------------
  **/
  private static Map<String,Object> completeProdResponse(PRW_Margin_Service.Data propResponse) {
    final Map<String,Object> returnMap = new Map<String,Object>();
    final List<PRW_Margin_Service.TableDataWrap> tabledata = new List<PRW_Margin_Service.TableDataWrap>();
    //Esta line para inicializar max date
    Date maximumDate =  Date.newInstance(2000,1,1);
    for(PRW_Margin_Service.Response resp : propResponse.data) {
      final PRW_Margin_Service.TableDataWrap row = new PRW_Margin_Service.TableDataWrap();
      //Esta line para asignar el max date si es mayor que el que ya tengo
      if(resp.maximumDateInformation > maximumDate){
        maximumDate = resp.maximumDateInformation;
      }
      for(PRW_Margin_Service.AcumulativeBlocks acum : resp.acumulativeBlocks) {
        final PRW_Margin_Service.Datavalue dataYtd = acum.dataValue;
        if(acum.frequency == YTD) {
          row.revenuesYTD = dataYtd.value;
          row.percentYoY_YTD = dataYtd.variation;
        } else if(acum.frequency == L12M) {
          row.revenuesL12M = dataYtd.value;
          row.percentYoYL12M = dataYtd.variation;
        } else if(acum.frequency == ACCM) {
          row.revenues = dataYtd.value;
        }
        if(dataYtd.valueLastPeriod != null){
          row.valueLastPeriod = dataYtd.valueLastPeriod;
        }
      }  
      if(resp.channels != null && !resp.channels.isEmpty()) {
        row.channel = resp.channels.get(0).id_y;
      }
      if(resp.product != null && resp.product.classification != null) {
        row.product = resp.product.classification.fifthLevel.id_y;
      }  
      if(resp.product != null && resp.product.classification.secondLevel != null) {
        if(resp.product.classification.secondLevel.id_y == GTF || resp.product.classification.secondLevel.id_y == WC || resp.product.classification.secondLevel.id_y == CM) {
          row.subFamily = resp.product.classification.secondLevel.id_y;
        }
      }
      if(row.subFamily != null){
        tabledata.add(row);
      }
      
    }
    final List<PRW_Margin_Service.TableDataWrap> tabledataOrdered = new List<PRW_Margin_Service.TableDataWrap>();
    List<String> orderList = new List<String>();
    Map<String,PRW_Margin_Service.TableDataWrap> orderMap = new Map<String,PRW_Margin_Service.TableDataWrap>();
    for(PRW_Margin_Service.TableDataWrap cond : tabledata){
      orderMap.put(cond.product,cond);
      orderList.add(cond.product);
    }
    orderList.sort();
    for(String name : orderList){
      tabledataOrdered.add(orderMap.get(name));
    }

    returnMap.put('tableData', JSON.serialize(tabledataOrdered,true));
    //Esta devolver en el mapa el maximum date
    returnMap.put('maximumDate', maximumDate);
    return returnMap;
  }
  }