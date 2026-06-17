/**
 * --------------------------------------------------------------------------------------
 * @Name              : CLT_Get_Context_Role_Service.cls
 * @Author            : Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
 * @Date              : 2026-02-22
 * @Group             : CIB Global Desktop
 * @Description  Clase service para componente el flow de Apply to join Coverage Team
 * --------------------------------------------------------------------------------------
 * @Changes
 * 2026-02-22   carlosalberto.maqueda.maldona.contractor@bbva.com
 *              Versión inicial
 * 
 * --------------------------------------------------------------------------------------
**/
public with sharing class CLT_Get_Context_Role_Service {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Constructor privado de la Clase
    * --------------------------------------------------------------------------------------
    * @Author Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date 2026-02-22
    * @param None
    * @return void
    * @example CLT_Get_Context_Role_Service constructor = new CLT_Get_Context_Role_Service()
    * --------------------------------------------------------------------------------------
    **/
    @testVisible public CLT_Get_Context_Role_Service() {}

    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros de la respuesta del servicio ixmas_test
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public class ServiceResult{
        public List<CLT_Apply_To_Team_Member_RoleWrapper> roles;
        public Integer statusCode;
        public String statusMessage;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa el objeto de error de la respuesta del servicio ixmas_test
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
    * @Description Clase interna que representa los parámetros que contiene el objeto error de la respuesta del servicio ixmas_test
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
    * @Description Method para consultar el servicio ASO 
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * @param    numClient Es el codigo del grupo al cual se solicita la petición
    * @param    numUser Es el Id del usuario que va a realizar la petición
    * @param    mode Indica que tipo de datos nos va a traer si para asignarse o desasignarse
    * @return   ServiceResult Contiene el Json resultante de la petición
    * @example  CLT_Get_Context_Role_Service.getRoles(numClient,numUser,mode)
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public static ServiceResult getRoles(String numClient, String numUser,String mode){
        String serviceName = 'IXMAS_Context_Request_PROD';
        ServiceResult result = new ServiceResult();
        result.roles = new List<CLT_Apply_To_Team_Member_RoleWrapper>();
        String requestBody = buildRequest(numClient, numUser,mode);
        final HttpResponse sResponse = bbvacon.GBL_Integration_GenericService.invoke(serviceName,requestBody);
        Map<String, Object> jsonResServ = new Map<String, Object>();
        switch on sResponse.getStatusCode() {
            WHEN 200 {   
                jsonResServ.put('Message', String.valueOf(sResponse.getStatus()));
                jsonResServ.put('CodeResponse', String.valueOf(sResponse.getStatusCode()));
                result.roles = parseResponse(sResponse.getBody());
            }
            WHEN ELSE {
                jsonResServ.put('CodeResponse', String.valueOf(sResponse.getStatusCode()));
                try{
                    ExternalErrorWrapper err = (ExternalErrorWrapper) JSON.deserialize(sResponse.getBody(), ExternalErrorWrapper.class);
                    jsonResServ.put('Message', err.error.message);
                }catch(Exception e){
                    jsonResServ.put('Message', String.valueOf(sResponse.getStatus()));
                }
            }
        }
        result.statusMessage = String.valueOf(jsonResServ.get('Message'));
        result.statusCode = Integer.valueOf(jsonResServ.get('CodeResponse'));
        return result;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method para construir el JSON de petición
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * @param    numClient Es el codigo del grupo al cual se solicita la petición
    * @param    numUser Es el Id del usuario que va a realizar la petición
    * @param    mode Indica que tipo de datos nos va a traer si para asignarse o desasignarse
    * @return   String Contiene el Json para realizar la petición
    * @example  CLT_Get_Context_Role_Service.buildRequest(numClient, numUser, mode)
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private static String buildRequest(String numClient, String numUser, String mode){
        Map<String,Object> payload = new Map<String,Object>{
            'idUser' => numUser,
            'idRequestedBy' => numUser,
            'idCompany' => numClient,
            'mode' => mode,
            'includeApprovers' => 'true'
        };
        return JSON.serialize(payload);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method para construir el JSON con los datos del servicio para mostrarlos en el flow
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * @param    jsonBody Es el json de respuesta del servicio externo.
    * @return   List<CLT_Apply_To_Team_Member_RoleWrapper> Contiene una lista de los roles en que se puede asignar el usuario
    * @example  CLT_Get_Context_Role_Service.parseResponse(jsonBody)
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private static List<CLT_Apply_To_Team_Member_RoleWrapper> parseResponse (String jsonBody){
        Map<String, Object> jsonResServ = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
        List<CLT_Apply_To_Team_Member_RoleWrapper> outRoles = new List<CLT_Apply_To_Team_Member_RoleWrapper>();
        if(jsonResServ == null || !jsonResServ.containsKey('roles') || jsonResServ.get('roles') == null){
            return outRoles;
        }
        List<Object> rolesList = (List<Object>) jsonResServ.get('roles');
        for(Object roleObj : rolesList){
            Map<String, Object> roleMap = (Map<String, Object>) roleObj;
            if((String) roleMap.get('id') == 'RRA') continue;
            CLT_Apply_To_Team_Member_RoleWrapper role = new CLT_Apply_To_Team_Member_RoleWrapper();
            role.id = (String) roleMap.get('id');
            role.label = (String) roleMap.get('label');
            if(roleMap.containsKey('approversChain') && roleMap.get('approversChain') != null){
                List<Object> approvers = (List<Object>) roleMap.get('approversChain');
                if(approvers != null && !approvers.isEmpty()){
                    Map<String, Object> firstApprover = null;
                    for(Object approverObj : approvers){
                        Map<String,Object> approverMap = (Map<String, Object>) approverObj;
                        Object ord = approverMap.get('order');
                        if(ord != null && Integer.valueOf(ord) == approvers.size()){
                            firstApprover = approverMap;
                            break;
                        }
                    }
                    if (firstApprover == null) firstApprover = (Map<String, Object>)approvers[0];
                    role.firstApproveName = (String) firstApprover.get('name');
                }
            }
            if(roleMap.containsKey('locations')&& roleMap.get('locations') != null){
                List<Object> locs = (List<Object>) roleMap.get('locations');
                role.locations = new List<CLT_Apply_To_Team_Member_LocWrapper>();
                for(Object locationObj : locs){
                    Map<String, Object> locationMap = (Map<String, Object>) locationObj;
                    CLT_Apply_To_Team_Member_LocWrapper locationWrapp = new CLT_Apply_To_Team_Member_LocWrapper();
                    locationWrapp.id = (String) locationMap.get('id');
                    locationWrapp.name = (String) locationMap.get('name');
                    role.locations.add(locationWrapp);
                }
            }
            if(role.id =='RLB' && roleMap.containsKey('subsidiaries') && roleMap.get('subsidiaries') != null){
                List<Object> subs = (List<Object>) roleMap.get('subsidiaries');
                Map<String,List<String>> byCountry = new Map<String,List<String>>();
                for(Object subObj : subs){
                    Map<String, Object> subMap = (Map<String, Object>) subObj;
                    String country = (String) subMap.get('nameCountry');
                    String idSub = (String) subMap.get('idSubsidiary');
                    if(String.isBlank(country)||String.isBlank(idSub)) continue;
                    if(!byCountry.containsKey(country)){
                        byCountry.put(country,new List<String>());
                    }
                    byCountry.get(country).add(idSub);
                }
                role.subsidiaries = new List<CLT_Apply_To_Team_Member_SubWrapper>();
                for(String country : byCountry.keySet()){
                    CLT_Apply_To_Team_Member_SubWrapper subWrapp = new CLT_Apply_To_Team_Member_SubWrapper();
                    subWrapp.nameCountry = country;
                    subWrapp.idSubsidiary = byCountry.get(country);
                    subWrapp.idSubsidiaries = String.join(byCountry.get(country), ',');
                    role.subsidiaries.add(subWrapp);
                }
            }
            if(role.locations == null) role.locations = new List<CLT_Apply_To_Team_Member_LocWrapper>();
            if(role.subsidiaries == null) role.subsidiaries = new List<CLT_Apply_To_Team_Member_SubWrapper>();
            outRoles.add(role);
        }
        return outRoles;
    }
}