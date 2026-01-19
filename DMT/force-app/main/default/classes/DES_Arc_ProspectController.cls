/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 05-06-2021
 * @last modified by  : David Rodríguez
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   28-04-2021   Global Desktop   Initial Version
**/
@SuppressWarnings('sf:AvoidUsingTestIsRunningTest')
public with sharing class DES_Arc_ProspectController {
  /**
  * @description
  * @author Global Desktop | 29-04-2021
  * @param ;
  **/
  private static final list<Integer> RESPONSE_OK_LIST = new list<Integer>{200,201};

  /**
  * @description
  * @author Global Desktop | 29-04-2021
  * @param ;
  **/
  private static final String MENSAJEVAR = ' --- Mensaje Completo: ';

  /**
  * @description
  * @author Global Desktop | 29-04-2021
  * @param ;
  **/
  private DES_Arc_ProspectController() {}

  /**
  * @description
  * @author Global Desktop | 29-04-2021
  * @param prospect
  * @return Boolean
  **/
  public static Boolean callCreateProspect(Account prospect, Boolean toUpdate) {
    Boolean callOk = true;
    try {
      final String reqString = getRequestBody(prospect.Name, prospect.DES_ID_Fiscal__c, null);
      final Map<String,String> jsonInputMap = new Map<String,String>();
      jsonInputMap.put('wholeRequest',reqString);
      jsonInputMap.put('prospectId',prospect.gf_customer_prospect_id__c);
      final HttpResponse mockTest = new HttpResponse();
      mockTest.setStatus('OK');
      mockTest.setStatusCode(201);
      final HttpResponse response = ( Test.isRunningTest() ? mockTest : iaso.GBL_Integration_GenericService.invoke('createProspect',jsonInputMap) );
      System.debug('>>>>>>>>>>>> El WS codeResponse: ' + response.getStatusCode() + MENSAJEVAR + response.toString());
      if (RESPONSE_OK_LIST.contains(response.getStatusCode()) && toUpdate) {
        prospect.DES_Prospect_status__c = Label.Prospect_created;
        update prospect;
      } else {
        throw new CalloutException('ERROR createProspect' + ' ' + response.getStatus() +  '\n' + response.getBody());
      }
      system.debug(callOk);
    } catch (Exception e) {
      callOk = false;
    }

    return callOk;
  }

  /**
  * @description
  * @author Global Desktop | 29-04-2021
  * @param prospect
  * @return Boolean
  **/
  public static Boolean callConvertProspect(String namepros, String fiscalIdpros, String prosId, String bussinessId) {
    Boolean callOk = true;
    try {
      final String reqString = getRequestBody(namepros, fiscalIdpros, bussinessId);
      final Map<String,String> jsonInputMap = new Map<String,String>();
      jsonInputMap.put('wholeRequest',reqString);
      jsonInputMap.put('prospectId',prosId);
      final HttpResponse mockTest = new HttpResponse();
      mockTest.setStatus('OK');
      mockTest.setStatusCode(201);
      mockTest.setBody('{ "data":{ "id":"00Q4H00000gpVwAUAQ", "origin":"ALPHA", "legalName":"Nacex Telecom", "businessId":"ES0182000013105", "businessDocuments":[ { "number":"50900356R", "numberType":{ "id":"CIF" } } ] } }');
      final HttpResponse response = ( Test.isRunningTest() ? mockTest : iaso.GBL_Integration_GenericService.invoke('editProspect',jsonInputMap) );
      System.debug('>>>>>>>>>>>> El WS codeResponse: ' + response.getStatusCode() + MENSAJEVAR + response.toString());
      if (RESPONSE_OK_LIST.contains(response.getStatusCode())) {
        final DES_Arc_ProspectResponse propResponse = (DES_Arc_ProspectResponse) Json.deserialize(response.getBody(), DES_Arc_ProspectResponse.class);
        System.debug('>>>>>>>>>>>> PropResponse: ' + Json.serialize(propResponse));
      } else {
        throw new CalloutException('ERROR createProspect' + ' ' + response.getStatus() +  '\n' + response.getBody());
      }
      system.debug(callOk);
    } catch (Exception e) {
      callOk = false;
    }
    return callOk;
  }

  /**
  * @description
  * @author Global Desktop | 29-04-2021
  * @param prospect
  * @return String
  **/
  private static String getRequestBody (String namepros, String fiscalIdpros, String businessId) {
    final DES_Arc_Prospect prosp = new DES_Arc_Prospect();
    prosp.businessId = businessId;
    prosp.legalName = namepros;
    if(fiscalIdpros != null && fiscalIdpros != '') {
      final List<DES_Arc_Prospect.businessDocuments> listBussDoc = new  List<DES_Arc_Prospect.businessDocuments>();
      listBussDoc.add(new DES_Arc_Prospect.businessDocuments(fiscalIdpros));
      prosp.businessDocuments = listBussDoc;
    }
    return getJSONProspect (prosp);
  }

  /**
  * @description
  * @author Global Desktop | 29-04-2021
  * @param request
  * @return String
  **/
  private static String getJSONProspect (DES_Arc_Prospect request) {
    return JSON.serialize(request,true).replaceAll('number_y','number');
  }

  /**
  * @description
  * @author Global Desktop | 29-04-2021
  * @param prospectJson
  * @return Boolean
  **/
  @Future(callout=true)
  public static void futureCreateProspect (String prospectJson) {
    final DES_Arc_ProspectController.WrapperService wrap = (DES_Arc_ProspectController.WrapperService) JSON.deserialize(prospectJson, DES_Arc_ProspectController.WrapperService.class);
    if(!callCreateProspect(wrap.pros, wrap.toUpdate)) {
      //ha fallado tenemos que ver que hacer
    }
  }

  /*
  * Wrapper to call service
  */
  public class WrapperService {
    /*
    * Account prospect
    */
    public Account pros { get; set; } //NOSONAR

    /*
    * String alphacode
    */
    public String alphacode{  get; set; } //NOSONAR

    /*
    * Boolean toUpdate
    */
    public Boolean toUpdate { get; set; } //NOSONAR

    public WrapperService(Account pros, String alphacode, Boolean toUpdate) {
      this.pros = pros;
      this.alphacode = alphacode;
      this.toUpdate = toUpdate;
    }
  }
}