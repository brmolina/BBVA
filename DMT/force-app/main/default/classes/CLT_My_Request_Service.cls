/**
 * --------------------------------------------------------------------------------------
 * @Name              : CLT_My_Request_Service.cls
 * @Author            : Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
 * @Date              : 2026-02-22
 * @Group             : CIB Global Desktop
 * @Description  Clase service para componente de My Request CLT_My_Request
 * --------------------------------------------------------------------------------------
 * @Changes
 * 2026-02-22   carlosalberto.maqueda.maldona.contractor@bbva.com
 *              Versión inicial
 * 
 * --------------------------------------------------------------------------------------
**/
public with sharing class CLT_My_Request_Service {
    /**
    * @Author: Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Description: Valor de numero de meses que se va a consultar las peticiones
    */
    final public Static Integer month = 24;
    /**
    * --------------------------------------------------------------------------------------
    * @Description Constructor privado de la Clase
    * --------------------------------------------------------------------------------------
    * @Author 	Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * @param    None
    * @return   void
    * @example  CLT_My_Request_Service constructor = new CLT_My_Request_Service()
    * --------------------------------------------------------------------------------------
    **/
    @testVisible private CLT_My_Request_Service() {}
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method para consultar el servicio ASO 
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * @param    numUser Es el Id de Salesforce del usuario el cual esta solicitando la petición.
    * @param    page Es la página actual que se esta consultando para la petición.
    * @param    pageSize Es la cantidad de registros que se estan consultando en cada página.
    * @return   MyRequestResponse Contiene el Json resultante de la petición
    * @example  CLT_My_Request_Service.getMyRequest(numUser,page,pageSize)
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public static MyRequestResponse getMyRequest(Id numUser, Integer page, Integer pageSize){
        final String requestJson = buildRequest(numUser,page,pageSize);
        final String serviceName = 'IXMAS_Status_Request_PROD';
        final HttpResponse sResponse = bbvacon.GBL_Integration_GenericService.invoke(serviceName, requestJson);
        MyRequestResponse result = new MyRequestResponse();
        result.myRequestList = new List<MyRequestRow>();
        result.pagination = new Pagination();
        ExternalResponse external;
        switch on sResponse.getStatusCode() {
            WHEN 200 {   
                external = (ExternalResponse) JSON.deserialize(sResponse.getBody(), ExternalResponse.class);
                result.statusMessage = String.valueOf(sResponse.getStatus());
                result.statusCode = sResponse.getStatusCode();
            } WHEN ELSE {
                result.statusCode = sResponse.getStatusCode();
                try{
                    ExternalErrorWrapper err = (ExternalErrorWrapper) JSON.deserialize(sResponse.getBody(), ExternalErrorWrapper.class);
                    result.statusMessage = err.error.message;
                } catch(Exception e){
                    result.statusMessage = String.valueOf(sResponse.getStatus());
                }
                result.pagination.page = page;
                result.pagination.pageSize = pageSize;
                result.pagination.totalCount = 0;
                result.pagination.totalPages = 1;
                return result;
            }
        }
        List<ExternalStatusItem> items = external.statusList;
        Map<String, String> roleCodeToLabel = buildRoleMap();
        for(ExternalStatusItem item : items){
           if(item.subsidiaries !=null && !item.subsidiaries.isEmpty()){
               result.myRequestList.addAll(buildRLBRow(item,roleCodeToLabel));
               continue;
           }
            MyRequestRow row = new MyRequestRow();
            row.idCompany = item.idCompany;
            row.nameCompany = item.nameCompany;
            row.idRole = item.idRole;
            row.nameRole = roleCodeToLabel.containsKey(item.idRole) ? roleCodeToLabel.get(item.idRole) : item.idRole;
            row.status = mapStatus(item.status);
            row.comment = item.comment;
            row.requestType = mapRequestAction(item.requestType);
            row.rowKey = item.idCompany + item.idRole + item.lastUpdated;
            row.lastUpdate = Datetime.newInstance(Long.valueOf(item.lastUpdated));
            result.myRequestList.add(row);
        }
        if(external.pagination != null){
            result.pagination.page = external.pagination.page;
            result.pagination.pageSize = external.pagination.pageSize;
            result.pagination.totalCount = external.pagination.totalCount;
            result.pagination.totalPages = external.pagination.totalPages;
        } else {
            result.pagination.page = page;
            result.pagination.pageSize = pageSize;
            result.pagination.totalCount = result.myRequestList.size();
            result.pagination.totalPages = 1;
        }
        return result;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method para construir el JSON de petición
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * @param    numUser Es el Id de Salesforce del usuario el cual esta solicitando la petición.
    * @param    page Es la página actual que se esta consultando para la petición.
    * @param    pageSize Es la cantidad de registros que se estan consultando en cada página.
    * @return   String Contiene el Json resultante para la solicitud de la petición
    * @example  CLT_My_Request_Service.buildRequest(numUser, page, pageSize)
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private static String buildRequest(Id numUser, Integer page, Integer pageSize){
        User u = [
            SELECT ID_User__c 
            FROM User 
            WHERE ID = :numUser
            LIMIT 1
        ];
        String numUserId  = u.ID_User__c;
        Map <String, Object> body = new Map <String, Object>();
        body.put('idUser',numUserId);
        body.put('idRequestedBy',numUserId);
        body.put('X-Page',page);
        body.put('X-Page-Size',pageSize);
        body.put('X-Last-Updated-Months',month);
        String json = JSON.serialize(body);
        return json;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method para concatenar Subsidiarias para rol RLB y RRA
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * @param    parent Información del grupo padre.
    * @param    roleCodeToLabel Contiene el diccionario de código con su rol
    * @return   List<MyRequestRow> Regresa la inofrmación agrupada de cada subsidiaria.
    * @example  CLT_My_Request_Service.buildRLBRow(parent, roleCodeToLabel)
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private static List<MyRequestRow> buildRLBRow(ExternalStatusItem parent, Map<String, String> roleCodeToLabel){
        List<MyRequestRow> result = new List<MyRequestRow>();
        Map<String, List<ExternalStatusItem>> subsidiariesByRole = new Map<String, List<ExternalStatusItem>>();
        for(ExternalStatusItem sitem : parent.subsidiaries){
            String role = sitem.idRole.trim().toUpperCase();
            if(!subsidiariesByRole.containsKey(role)) subsidiariesByRole.put(role, new List<ExternalStatusItem>());
            subsidiariesByRole.get(role).add(sitem);
        }
        for(String role : subsidiariesByRole.keySet()){
            List<ExternalStatusItem> groupGlobal = subsidiariesByRole.get(role);
            ExternalStatusItem first = groupGlobal[0];
            Boolean anyAccepted = false;
            Boolean anyPending = false;
            Long max = 0;
            for(ExternalStatusItem gitem : groupGlobal){
                if(gitem == null) continue;

                String st = gitem.status.trim().toUpperCase();
                if(st == 'ACCEPTED') anyAccepted = true;
                else if(st == 'PENDING_APPROVAL') anyPending = true;
                try{
                    Long ms = Long.valueOf(gitem.lastUpdated);
                    if(ms > max) max = ms;
                } catch (Exception e) {}
            }
            String globalStatus;
            if(anyAccepted) globalStatus = 'ACCEPTED';
            else if (anyPending) globalStatus = 'PENDING_APPROVAL';
            else globalStatus = 'CANCELLED';
            MyRequestRow globalRow = new MyRequestRow();
            globalRow.idCompany = parent.idCompany;
            globalRow.nameCompany = parent.nameCompany;
            globalRow.idRole = role;
            globalRow.nameRole = roleCodeToLabel.containsKey(role) ? roleCodeToLabel.get(role) : role;
            globalRow.requestType = mapRequestAction(first.requestType);
            globalRow.status = mapStatus(globalStatus);
            globalRow.comment = first.comment;
            globalRow.rowKey = parent.idCompany + role + max;
            globalRow.lastUpdate = Datetime.newInstance(max);
            result.add(globalRow);
        }
        return result;
    }  

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method para contruir un diccionario de roles con su respectivo codigo
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * @param    None
    * @return   Map<String, String> Contiene el diccionario (Rol. Label)
    * @example  CLT_My_Request_Service.buildRLBRow(parent, roleCodeToLabel)
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private static Map<String, String> buildRoleMap(){
        Map<String, String> codeToLabel = new Map<String, String>();
        for(CLT_Role_Mapping__mdt role : [
            SELECT CLT_Role_Code__c,Label 
            FROM CLT_Role_Mapping__mdt
        ]){
            codeToLabel.put(role.CLT_Role_Code__c, role.Label);
        }
        return codeToLabel;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method para mapear el tipo de request.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * @param    requestType Contien el tipo de request para mapearlo.
    * @return   String Contiene el tipo de request mapeado.
    * @example  CLT_My_Request_Service.mapRequestAction(requestType)
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private static String mapRequestAction(String requestType){
       if(String.isBlank(requestType)) return requestType;
       String rt = requestType.trim().toUpperCase();
       if(rt == 'ADD') return 'Apply to Team';
       if(rt == 'CANCEL') return 'Leave Team';
       return requestType;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method para mapear el status.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * @param    status Contien el status del servicio para mapearlo.
    * @return   String Contiene el estatus de la petición mapeado.
    * @example  CLT_My_Request_Service.mapStatus(status)
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private static String mapStatus(String status){
        if(String.isBlank(status)) return status;
        String st = status.trim().toUpperCase();
        if(st == 'ACCEPTED') return 'Approved';
        if(st == 'CANCELLED') return 'Declined';
        if(st == 'PENDING_APPROVAL') return 'Pending';
        return status;
    }
    
    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros de la respuesta del servicio externo
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public class MyRequestResponse{
        @AuraEnabled public List<MyRequestRow> myRequestList;
        @AuraEnabled public Pagination pagination;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String statusMessage;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros que contiene el body del JSON 
    *              del servicio que contiene los request del usuario.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public class MyRequestRow{
        @AuraEnabled public String rowKey;
        @AuraEnabled public Datetime lastUpdate;
        @AuraEnabled public String idCompany;
        @AuraEnabled public String nameCompany;
        @AuraEnabled public String idRole;
        @AuraEnabled public String nameRole;
        @AuraEnabled public String requestType;
        @AuraEnabled public String status;
        @AuraEnabled public String comment;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase publica que representa los parámetros de paginación enviados del servicio externo.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public class Pagination{
        @AuraEnabled public Integer page;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Integer totalPages;
    }
    
    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros de la respuesta enviados del servicio externo.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private class ExternalResponse{
        public List<ExternalStatusItem> statusList;
        public ExternalPagination pagination;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros de error enviados del servicio externo.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private class ExternalErrorWrapper{
        public ExternalError error;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros que contiene el JSON de error del servicio externo.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private class ExternalError{
        public String code;
        public String message;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros del body de la respuesta enviados del servicio externo.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private class ExternalStatusItem{
        public String lastUpdated;
        public String idCompany;
        public String idRole;
        public String status;
        public String comment;
        public String requestType;
        public String nameCompany;
        public List<ExternalStatusItem> subsidiaries;
        public String idParent;
        public String nameCompanyChild;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros de paginación enviados del servicio externo.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private class ExternalPagination{
        public Integer page;
        public Integer pageSize;
        public Integer totalCount;
        public Integer totalPages;
    }
}