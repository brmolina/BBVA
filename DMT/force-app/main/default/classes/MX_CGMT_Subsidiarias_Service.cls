/**
* ------------------------------------------------------------------------------------------------
* @Name     MX_CGMT_Subsidiarias_Service
* @Author   Luis González luisalberto.gonzalez.rojas@bbva.com
* @Date     2025-04-21
* @Group    Client & Group Mgm Tool
* -----------------------------------------------------------------------------------------------
* @Description Clase service para la clase MX_CGMT_Subsidiarias_Controller
* -----------------------------------------------------------------------------------------------
* @Changes
* 2025-02-13   luisalberto.gonzalez.rojas@bbva.com
*              Creación de clase.
* -----------------------------------------------------------------------------------------------
*/
public with sharing class MX_CGMT_Subsidiarias_Service {
    /**
    @Description Constante para definir el nombre del Integration Service
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String SERVICE_SI = 'CGMT_getServiceSubsidiariesInfo';
    /**
    @Description Constante para definir el nombre la columna Id
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String C_ID = 'Id';
    /**
    @Description Constante para definir el nombre la columna industryName
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String IND_NAME = 'industryName';
    /**
    @Description Constante para definir el nombre la columna Subsidiary Name
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String SUB_NAME = 'Subsidiary Name';
    /**
    @Description Constante para definir el nombre la columna Subsidiary Id
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String SUB_ID = 'Subsidiary Id';
    /**
    @Description Constante para definir el nombre la columna Internal Rating
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String INT_RATING = 'Internal Rating';
    /**
    @Description Constante para definir el nombre la columna Role Desc
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String ROL_DESC = 'Role Desc';
    /**
    @Description Constante para definir el nombre la columna Holding Sector Desc
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String HOLD_SECT = 'Holding Sector Desc';
    /**
    @Description Constante para definir el nombre la columna Portfolio
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String PORTFOLIO = 'Portfolio';
    /**
    @Description Constante para definir el nombre la columna coverage
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String COVERAGE = 'coverage';
    /**
    @Description Constante para definir el nombre la columna Global Transaction Banking
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String GTB = 'Global Transaction Banking';
    /**
    @Description Constante para definir el nombre la columna sameMonthLastYear
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String M_LASTYEAR = 'sameMonthLastYear';
    /**
    @Description Constante para definir el nombre la columna currentMonth
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String C_MONTH = 'currentMonth';
    /**
    @Description Constante para definir el nombre la columna ytdLastYear
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String L_YEAR = 'ytdLastYear';
    /**
    @Description Constante para definir el nombre la columna ytd
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String YTD = 'ytd';
    /**
    @Description Constante para definir el nombre la columna tam
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String TAM = 'tam';
    /**
    @Description Cadena con el nombre del mapa a retornar en el method invokeMethod dedicado a grupos
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String T_GROUP = 'returnGetDataGCS';
    /**
    @Description Cadena con el nombre del mapa a retornar en el method invokeMethod dedicado a subsidiarias
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String T_SUBS = 'getTableSubsidiary';
    /**
    @Description Cadena con el nombre del mapa a retornar en el method invokeMethod dedicado a la paginación
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String T_PAGES_SUB = 'returnGetDataPagesSub';
    /**
    @Description Cadena con la palabra Error usada en las validaciones
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String ERROR = 'Error';
    /**
    @Description Cadena con la palabra Error usada en las validaciones de errores desconocidas
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String ERRORDESC = 'Error desconocido';
    /**
    @Description Constante para definir el nombre la columna mainParent
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String MAINPARENT = 'Main Parent';
    /**
    @Description Constante para definir el nombre la columna localGroupName
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String L_GROUP_NAME = 'localGroupName';
    /**
    @Description Constante para definir el nombre la columna localGroupId
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String L_GROUP_ID = 'localGroupId';
    /**
    @Description Constante para definir el nombre la columna Links
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String LINKS = 'Links';
    /**
    @Description Constante para definir el nombre la columna Page
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String PAGE = 'Page';
    /**
    @Description Constante para definir el nombre la columna Total Pages
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String TOTAL_PAGES = 'Total Pages';
    /**
    @Description Constante para definir el nombre la columna Total Elements
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String T_ELEMENTS = 'TotalElements';
    /**
    @Description Constante para definir el nombre la columna Page Size
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String P_SIZE = 'pageSize';
    /**
    @Description Constante para definir el nombre del parámetro holding-group-id
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String HOLDING = 'holdingGroupId';
    /**
    @Description Constante para definir el nombre del parámetro subsidiaryId
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String SUBID = 'subsidiaryId';
    /**
    @Description Constante para definir el nombre del parámetro paginationKey
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String P_KEY = 'paginationKey';
    /**
    @Description Constante para definir el nombre la columna first
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String FIRST = 'first';
    /**
    @Description Constante para definir el nombre la columna last
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String LAST = 'last';
    /**
    @Description Constante para definir el nombre la columna previous
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String PREVIOUS = 'previous';
    /**
    @Description Constante para definir el nombre la columna next
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String NEXT = 'next';
    /**
    @Description Constante para definir el nombre de respuesta de excepción de error
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String MESSAGES = 'messages';
    /**
    @Description Constante para definir el nombre de respuesta de mensaje de error controlado
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String MESSAGE = 'message';
    /**
    @Description Constante para definir el nombre de respuesta de codigo de error controlado
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String CODE = 'code';
    /**
    @Description Constante para definir el nombre para los grupos y subsidiarias de tipo Dual
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String DUAL = 'Dual';
    /**
    @Description Constante para definir el nombre para identidficar los Transaction Banker
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String TRANSACBANK = 'Transaction Banker';
    /**
    @Description Constante para definir el nombre para campo de ccsbanker
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String CCSBAN = 'CCSBanker';
    /**
    @Description Constante para definir el nombre para campo de ccsporfolio
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String CCSPORTF = 'CCSPortfolio';
    /**
    @Description Constante para definir el nombre para campo de codigo de error
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String ERRORCOD = 'errorCode';
    /**
    @Description Constante para definir el nombre para campo de mensaje de error
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String ERRORMESS = 'errorMessage';
 
    /**
    @Description Constante para Mapa estático para guardar el catálogo y no consultarlo cada vez
    @Author      Alejandro Hernandez Ochoa - alejandro.hernandez.ochoa@bbva.com
    **/
    private static Set<String> gtbPortfolios;

    /**
    @Description Constante para definir el inicio de una consulta SQL
    @Author      Alejandro Hernandez Ochoa - alejandro.hernandez.ochoa@bbva.com
    **/
    final private static String SLT = 'SELECT';

    /**
    @Description Constante para definir los campos de la consulta SQL
    @Author      Alejandro Hernandez Ochoa - alejandro.hernandez.ochoa@bbva.com
    **/
    final private static String FEDSQRY = 'Portfolio_Name__c';

    /**
    @Description Constante para definir el FROM de una consulta SQL
    @Author      Alejandro Hernandez Ochoa - alejandro.hernandez.ochoa@bbva.com
    **/
    final private static String FRM = 'FROM';

    /**
    @Description Constante para definir el nombre del Custom Metadata Type que contiene los portafolios de GTB
    @Author      Alejandro Hernandez Ochoa - alejandro.hernandez.ochoa@bbva.com
    **/
    final private static String FRMQRY = 'GTB_Portfolio__mdt';

    /**
    @Description Constante para definir espacio entre palabras en una consulta SQL
    @Author      Alejandro Hernandez Ochoa - alejandro.hernandez.ochoa@bbva.com
    **/
    final private static String SPC = ' ';

    /**
    @Description Constante para definir la consulta SQL completa para obtener los portafolios de GTB
    @Author      Alejandro Hernandez Ochoa - alejandro.hernandez.ochoa@bbva.com
    **/
    final private static string QRYPORTAFOLIOS = SLT + SPC + FEDSQRY + SPC + FRM + SPC + FRMQRY;

 
   /**
   *-------------------------------------------------------------------------------------------------------
   * @Description Method que consume el servicio que trae la información de las subsidiarias
   *-------------------------------------------------------------------------------------------------------
   * @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
   * @Date        2025-04-21
   * @param       String request - Cadena con el Id del grupo
   * @return      ResponseWrapper - Mapa que contiene la información de los registros de las subsidiarias
   * @example     MX_CGMT_Subsidiarias_Service.getSubsidiariesInfo(groupCode)
   **/

    public static ResponseWrapper getSubsidiariesInfo(Map<String, Object> inputMap) {
       
        ResponseWrapper respWrapper = new ResponseWrapper();
        try{
            final String holdId = (String)inputMap.get(HOLDING);
            final String subsidiaryId = (String)inputMap.get(SUBID);
            final String pageSize = (String)inputMap.get(P_SIZE);
            final String paginationKey = (String)inputMap.get(P_KEY);
            final Map<String, Object> mapRequest = new Map<String, Object> {HOLDING => holdId, SUBID => subsidiaryId, P_SIZE => pageSize, P_KEY => paginationKey};
            HttpResponse response = arce.Arc_Gen_getIASOResponse.getServiceResponse(SERVICE_SI, JSON.serialize(mapRequest));
            switch on response.getStatusCode() {
                when 200 {
                    respWrapper = (ResponseWrapper)JSON.deserialize(response.getBody(), ResponseWrapper.class);
                    respWrapper.success = true;
                }
                when 400, 500 { 
                    Map<String, Object> errorBody = (Map<String, Object>) JSON.deserializeUntyped(response.getbody());
                    List<Object> messages = (List<Object>) errorBody.get(MESSAGES);
                    if (messages != null && !messages.isEmpty()) {
                        String messageStr = String.valueOf(messages[0]).replace('{', '').replace('}', '');
                        List<String> pairs = messageStr.split(',');
                        Map<String, String> messageMap = new Map<String, String>();
                        for (String pair : pairs) {
                            List<String> keyValue = pair.split('=');
                            if (keyValue.size() == 2) {
                                messageMap.put(keyValue[0].trim(), keyValue[1].trim());
                            }
                        }
                        respWrapper.code = messageMap.get(CODE);
                        respWrapper.errorMessage = messageMap.get(MESSAGE);
                    }
                    respWrapper.success = false;
                    respWrapper.errorCode = response.getStatusCode();
                }
                when else {
                    respWrapper.success = false;
                    respWrapper.errorMessage = ERRORDESC + ': ' + response.getStatusCode() + ' ' +  response.getBody();
                }
            }
        } catch (Exception e) {
            respWrapper.success = false;
            respWrapper.errorMessage = ERROR + ': ' + e.getMessage() + ' en línea ' + e.getLineNumber();
        }
        return respWrapper;
    }

    /**
   *-------------------------------------------------------------------------------------------------------
   * @Description Method dedicado a estructurar la información de subsidiarias en un mapa
   *-------------------------------------------------------------------------------------------------------
   * @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
   * @Date        2025-04-21
   * @param       String groupCode - Cadena que almacena el código del grupo
   * @return      Map<String, Object> - Mapa que contiene la información de los registros de las subsidiarias
   * @example     MX_CGMT_Subsidiarias_Service.getDataTableSubsidiaries(groupCode)
   **/

    public static Map<String, Object> getDataTableSubsidiaries(Map<String, Object> inputMap) {
        Map<String, Object> responseMap = new Map<String, Object>();
        List<Map<String, String>> dataGroupList = new List<Map<String, String>>();
        
        Map<String, Map<String, String>> consolidatedSubs = new Map<String, Map<String, String>>();

        try {
            Set<String> gtbPortfolioSet = getGtbPortfolioSet();

            ResponseWrapper response = getSubsidiariesInfo(inputMap);
            if (response.success && response.data != null && !response.data.isEmpty()) {
                for (Data dataWrapper : response.data) {
                    Groups grupoWrapper = dataWrapper.groupGl;
                    
                    for (DataDos dataWrapperDos : dataWrapper.data) {
                        if (dataWrapperDos.subsidiaryName != null && dataWrapperDos.subsidiaryName.trim() == dataWrapperDos.subsidiaryId) {
                            continue;
                        }
                        String currentId = dataWrapperDos.subsidiaryId;
                        Map<String, String> subsidiaryRecord;
                        if (consolidatedSubs.containsKey(currentId)) {
                            subsidiaryRecord = consolidatedSubs.get(currentId);
                        } else {
                            subsidiaryRecord = new Map<String, String>();
                            subsidiaryRecord.put(SUB_NAME, dataWrapperDos.subsidiaryName);
                            subsidiaryRecord.put(SUB_ID, dataWrapperDos.subsidiaryId);
                            subsidiaryRecord.put(INT_RATING, dataWrapperDos.internalRating);
                            subsidiaryRecord.put(IND_NAME, dataWrapperDos.industryName);
                            subsidiaryRecord.put(HOLD_SECT, dataWrapperDos.holdingSectorDesc);
                            subsidiaryRecord.put(COVERAGE, dataWrapperDos.coverage);
                            subsidiaryRecord.put(L_GROUP_NAME, grupoWrapper.localGroupName);
                            // Inicializar todos los campos para una estructura consistente
                            subsidiaryRecord.put(PORTFOLIO, '');
                            subsidiaryRecord.put(GTB, '');
                            subsidiaryRecord.put(CCSPORTF, '');
                            subsidiaryRecord.put(CCSBAN, '');
                            subsidiaryRecord.put(M_LASTYEAR, '');
                            subsidiaryRecord.put(C_MONTH, '');
                            subsidiaryRecord.put(L_YEAR, '');
                            subsidiaryRecord.put(YTD, '');
                            subsidiaryRecord.put(TAM, '');
                        }
                        String portfolioValue = dataWrapperDos.portfolio;
                        String gtbValue = dataWrapperDos.globalTransactionBanking;              
                        if (dataWrapperDos.roleDesc == TRANSACBANK) {
                            subsidiaryRecord.put(ROL_DESC, TRANSACBANK);
                        } else if (String.isBlank(subsidiaryRecord.get(ROL_DESC))) {
                            subsidiaryRecord.put(ROL_DESC, dataWrapperDos.roleDesc);
                        }
                        if (gtbPortfolioSet.contains(portfolioValue)) {
                            if(String.isNotBlank(portfolioValue)) subsidiaryRecord.put(PORTFOLIO, portfolioValue);
                            if(String.isNotBlank(gtbValue)) subsidiaryRecord.put(GTB, gtbValue);
                        } else {
                            if(String.isNotBlank(portfolioValue)) subsidiaryRecord.put(CCSPORTF, portfolioValue);
                            if(String.isNotBlank(gtbValue)) subsidiaryRecord.put(CCSBAN, gtbValue);
                        }
                        consolidatedSubs.put(currentId, subsidiaryRecord);
                    }

                    Map<String, String> groupInfo = new Map<String, String>();
                    groupInfo.put(C_ID, grupoWrapper.id);
                    groupInfo.put(MAINPARENT, grupoWrapper.mainParent);
                    groupInfo.put(L_GROUP_NAME, grupoWrapper.localGroupName);
                    groupInfo.put(L_GROUP_ID, grupoWrapper.localGroupId);
                    groupInfo.put(ROL_DESC, grupoWrapper.roleDesc);
                    groupInfo.put(IND_NAME, grupoWrapper.industryName);
                    groupInfo.put(HOLD_SECT, grupoWrapper.holdingSectorDesc);
                    groupInfo.put(INT_RATING, grupoWrapper.internalRating);
                    groupInfo.put(COVERAGE, grupoWrapper.coverage);
                    groupInfo.put(GTB, grupoWrapper.globalTransactionBanking);
                    groupInfo.put(PORTFOLIO, grupoWrapper.portfolio);
                    if (grupoWrapper.coverage == DUAL) {
                        String firstCcsBanker = '';
                        String firstCcsPortfolio = '';

                        for (Map<String, String> subRecord : consolidatedSubs.values()) {
                            if (String.isNotBlank(subRecord.get(CCSBAN)) && String.isNotBlank(subRecord.get(CCSPORTF))) {
                                firstCcsBanker = subRecord.get(CCSBAN);
                                firstCcsPortfolio = subRecord.get(CCSPORTF);
                                break;
                            }
                        }
                        groupInfo.put(CCSBAN, firstCcsBanker);
                        groupInfo.put(CCSPORTF, firstCcsPortfolio);
                    } else {
                        groupInfo.put(CCSBAN, '');
                        groupInfo.put(CCSPORTF, '');
                    }
                    dataGroupList.add(groupInfo);
                }
                
                responseMap.put(T_GROUP, dataGroupList);
                responseMap.put(T_SUBS, consolidatedSubs.values());
            }
        } catch (Exception e) {
            responseMap.put(ERROR, e.getMessage() + ' en línea ' + e.getLineNumber());
        }
        return responseMap;
    }

    public static Map<String, Object> getDataTablePagination(Map<String, Object> inputMap) {
        List<Map<String, String>> pageDetailsList = new List<Map<String, String>>();
        List<Map<String, String>> dataLinks = new List<Map<String, String>>();
        Map<String, Object> responseMap = new Map<String, Object>();
        ResponseWrapper response = new ResponseWrapper();
        try {
            response = getSubsidiariesInfo(inputMap);
            if (response.success && response.pagination != null && !response.data.isEmpty()) {
                Pagination pageWrapper = response.pagination;
                Map<String, String> pageInfo = new Map<String, String>();
                Links linkWrapper = response.pagination.links;
                Map<String, String> linkMap = new Map<String, String>();
                linkMap.put(FIRST, linkWrapper.first);
                linkMap.put(LAST, linkWrapper.last);
                linkMap.put(PREVIOUS, linkWrapper.previous);
                linkMap.put(NEXT, linkWrapper.next);
                dataLinks.add(linkMap);
                pageInfo.put(LINKS, String.valueOf(dataLinks));
                pageInfo.put(PAGE, String.valueOf(pageWrapper.page));
                pageInfo.put(TOTAL_PAGES, String.valueOf(pageWrapper.totalPages));
                pageInfo.put(T_ELEMENTS, String.valueOf(pageWrapper.totalElements));
                pageInfo.put(P_SIZE,String.valueOf(pageWrapper.pageSize));
                pageDetailsList.add(pageInfo);
                responseMap.put(T_PAGES_SUB, pageDetailsList);
            }
            if (response.errorCode == 400) {
                Map<String, String> errorInfo = new Map<String, String>();
                errorInfo.put(CODE, response.code);
                errorInfo.put(ERRORCOD, String.valueOf(response.errorCode));
                errorInfo.put(ERRORMESS, response.errorMessage);
                responseMap.put(T_PAGES_SUB, new List<Map<String, String>>{ errorInfo });
            }
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = ERROR + e.getMessage();
            responseMap.put(ERROR, response.errorMessage);
        }
 
 
        return responseMap;
    }
 

    private static Set<String> getGtbPortfolioSet() {
        if (gtbPortfolios == null) {
            gtbPortfolios = new Set<String>();
            for (GTB_Portfolio__mdt record : Database.query(QRYPORTAFOLIOS)) {
                gtbPortfolios.add(record.Portfolio_Name__c);
            }
        }
        return gtbPortfolios;
    }

      /**
   *-------------------------------------------------------------------------------------------------------
   * @Description Clase que guarda la información del response derivado del consumo del servicio CGMT_getServiceSubsidiariesInfo
   *-------------------------------------------------------------------------------------------------------
   * @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
   * @Date        2025-04-21
   **/
   public class ResponseWrapper {
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String errorMessage { get; set; }
    @AuraEnabled public List<Data> data { get; set; }
    @AuraEnabled public Pagination pagination { get; set; }
    @AuraEnabled public String code { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public Integer errorCode { get; set; }
}
/**
*-------------------------------------------------------------------------------------------------------
* @Description Clase que guarda los registros de las subsidiarias
*-------------------------------------------------------------------------------------------------------
* @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
* @Date        2025-04-21
**/
public class Data {
    @AuraEnabled public List<DataDos> data { get; set; }
    @AuraEnabled public Groups groupGl { get; set; }
    @AuraEnabled public WrapperError errorDetails { get; set; }
}
/**
*-------------------------------------------------------------------------------------------------------
* @Description Clase que guarda los registros de las subsidiarias
*-------------------------------------------------------------------------------------------------------
* @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
* @Date        2025-04-21
**/
public class DataDos {
    @AuraEnabled public String subsidiaryName { get; set; }
    @AuraEnabled public String subsidiaryId { get; set; }
    @AuraEnabled public String internalRating { get; set; }
    @AuraEnabled public String roleDesc { get; set; }
    @AuraEnabled public String industryName { get; set; }
    @AuraEnabled public String holdingSectorDesc { get; set; }
    @AuraEnabled public String portfolio { get; set; }
    @AuraEnabled public String coverage { get; set; }
    @AuraEnabled public String globalTransactionBanking { get; set; }
}
/**
*-------------------------------------------------------------------------------------------------------
* @Description Clase que guarda los grupos de las subsidiarias
*-------------------------------------------------------------------------------------------------------
* @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
* @Date        2025-04-21
**/
public class Groups {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String mainParent { get; set; }
    @AuraEnabled public String localGroupName { get; set; }
    @AuraEnabled public String localGroupId { get; set; }
    @AuraEnabled public String roleDesc { get; set; }
    @AuraEnabled public String industryName { get; set; }
    @AuraEnabled public String holdingSectorDesc { get; set; }
    @AuraEnabled public String internalRating { get; set; }
    @AuraEnabled public String portfolio { get; set; }
    @AuraEnabled public String coverage { get; set; }
    @AuraEnabled public String globalTransactionBanking { get; set; }
}
/**
*-------------------------------------------------------------------------------------------------------
* @Description Clase que guarda las paginaciones de las subsidiarias
*-------------------------------------------------------------------------------------------------------
* @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
* @Date        2025-04-21
**/
public class Pagination {
    @AuraEnabled public Links links { get; set; }
    @AuraEnabled public Integer page { get; set; }
    @AuraEnabled public Integer totalPages { get; set; }
    @AuraEnabled public Integer totalElements { get; set; }
    @AuraEnabled public Integer pageSize { get; set; }
}
/**
*-------------------------------------------------------------------------------------------------------
* @Description Clase que guarda las links de las subsidiarias
*-------------------------------------------------------------------------------------------------------
* @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
* @Date        2025-04-21
**/
public class Links {
    @AuraEnabled public String first { get; set; }
    @AuraEnabled public String last { get; set; }
    @AuraEnabled public String previous { get; set; }
    @AuraEnabled public String next { get; set; }
}


/**
*-------------------------------------------------------------------------------------------------------
* @Description Clase que guarda respuestas de error en los servicios
*-------------------------------------------------------------------------------------------------------
* @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
* @Date        2025-04-21
**/
public class WrapperError {
    @AuraEnabled public String code { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public Integer errorCode { get; set; }
    @AuraEnabled public String errorMessage { get; set; }

}
}