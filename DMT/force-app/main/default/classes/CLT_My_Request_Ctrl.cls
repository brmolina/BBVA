/**
 * --------------------------------------------------------------------------------------
 * @Name              : CLT_My_Request_Ctrl.cls
 * @Author            : Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
 * @Date              : 2026-02-22
 * @Group             : CIB Global Desktop
 * @Description  Clase controller para componente de My Request CLT_My_Request
 * --------------------------------------------------------------------------------------
 * @Changes
 * 2026-02-22   carlosalberto.maqueda.maldona.contractor@bbva.com
 *              Versión inicial
 * 
 * --------------------------------------------------------------------------------------
**/
public with sharing class CLT_My_Request_Ctrl {
   /**
    * --------------------------------------------------------------------------------------
    * @Description Constructor privado de la Clase
    * --------------------------------------------------------------------------------------
    * @Author Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date 2026-02-22
    * @param None
    * @return void
    * @example CLT_My_Request_Ctrl constructor = new CLT_My_Request_Ctrl()
    * --------------------------------------------------------------------------------------
    **/
   @testVisible public CLT_My_Request_Ctrl() {}

   /**
    * --------------------------------------------------------------------------------------
    * @Description Method para consultar las peticiones en el servicio getMyRequests
    * --------------------------------------------------------------------------------------
    * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-02-22
    * @param  page Numeró actual de la pagina que se esta consultando
    * @param  pageSize Numero de registros que se debe de observar en la págima
    * @return MyRequestResponse Objeto que se envia al cliente con la información del servicio
    * @example  CLT_My_Request_Service.MyRequestResponse.getMyRequests(page,pageSize)
    * --------------------------------------------------------------------------------------
    **/
   @AuraEnabled(cacheable=false)
   public static CLT_My_Request_Service.MyRequestResponse getMyRequests(Integer page, Integer pageSize){
    return CLT_My_Request_Service.getMyRequest(UserInfo.getUserId(), page, pageSize);
   }
}