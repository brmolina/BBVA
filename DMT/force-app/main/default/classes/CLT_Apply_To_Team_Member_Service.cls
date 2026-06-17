/**
 * --------------------------------------------------------------------------------------
 * @Name              : CLT_Apply_To_Team_Member_Service.cls
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
public with sharing class CLT_Apply_To_Team_Member_Service {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros de la respuesta del servicio 
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public class ServiceResult{
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
    * @param    input Tiene el mapa con la información para generar el payload
    * @example  CLT_Apply_To_Team_Member_Service.submitApply(input)
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public static ServiceResult submitApply(Map<String,Object> input){
        String serviceName;
        String requestBody;
        String requestType = (String) input.get('mode');
        if(requestType == 'UNASSIGNED'){
            serviceName = 'IXMAS_Apply_Request_PROD';
            requestBody = buildRequest(input);
        } else {
            serviceName = 'IXMAS_Cancel_Request_PROD';
            requestBody = buildRequest(input);
        } 
        ServiceResult service = new ServiceResult();
        final HttpResponse sResponse = bbvacon.GBL_Integration_GenericService.invoke(serviceName,requestBody);
        Map<String, Object> jsonResServ = new Map<String, Object>();
        switch on sResponse.getStatusCode() {
            WHEN 200 {   
                jsonResServ.put('Message', String.valueOf(sResponse.getStatus()));
                jsonResServ.put('CodeResponse', String.valueOf(sResponse.getStatusCode()));
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
        service.statusMessage = String.valueOf(jsonResServ.get('Message'));
        service.statusCode = Integer.valueOf(jsonResServ.get('CodeResponse'));
        return service;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method para construir el JSON de petición
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * @param    flowPayload Contiene la información para generar el payload para la petición
    * @return   String Contiene el Json para realizar la petición
    * @example  CLT_Get_Context_Role_Service.buildRequest(flowPayload)
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    private static String buildRequest(Map<String,Object> flowPayload){
        Map<String,Object> apipayload = new Map<String,Object>{
            'idUser' => (String) flowPayload.get('idUser'),
            'idRequestedBy' => (String) flowPayload.get('idRequestedBy'),
            'idCompany' => (String) flowPayload.get('idCompany'),
            'comment' => (String) flowPayload.get('comment'),
            'idRole' => (String) flowPayload.get('idRole')
        };
        apipayload.put('idSubsidiary', '[]');
        String role = (String) flowPayload.get('idRole');
        if(role == 'RTB')
        {
            String singleDual = (String) flowPayload.get('singleDual');
            String idOffice = (String) flowPayload.get('idOffice');
            String mode = (String) flowPayload.get('mode');
            if(idOffice == 'null') idOffice = '';
            if(mode == 'UNASSIGNED'){
                if(!String.isBlank(singleDual)) apipayload.put('singleDual', singleDual);
            } 
            apipayload.put('idOffice', idOffice);
        }
        if(role == 'RRB')
        {
            String idMacroregion = (String) flowPayload.get('idMacroregion');
            if(!String.isBlank(idMacroregion)) apipayload.put('idMacroRegion', idMacroregion);
        }
        if(role == 'RLB'){
            String subsidiary = (String) flowPayload.get('idSubsidiary');
            List<String> listSubsidiary = new List<String>();
            if(!String.isBlank(subsidiary)){
                for(String sub : subsidiary.split(',')){
                    if(!String.isBlank(sub)){
                        listSubsidiary.add(sub.trim());
                    }
                }
            }
            String subsidiaryFinal = JSON.serialize(listSubsidiary);
            apipayload.put('idSubsidiary', subsidiaryFinal);
        }
        return JSON.serialize(apipayload);
    }
}