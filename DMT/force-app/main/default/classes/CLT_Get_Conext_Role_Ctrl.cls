/**
 * --------------------------------------------------------------------------------------
 * @Name              : CLT_Get_Conext_Role_Ctrl.cls
 * @Author            : Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
 * @Date              : 2026-02-22
 * @Group             : CIB Global Desktop
 * @Description  Clase controller para componente el flow de Apply to join Coverage Team
 * --------------------------------------------------------------------------------------
 * @Changes
 * 2026-02-22   carlosalberto.maqueda.maldona.contractor@bbva.com
 *              Versión inicial
 * 
 * --------------------------------------------------------------------------------------
**/
public with sharing class CLT_Get_Conext_Role_Ctrl {

    /**
    * --------------------------------------------------------------------------------------
    * @Description Constructor privado de la Clase
    * --------------------------------------------------------------------------------------
    * @Author Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date 2026-02-22
    * @param None
    * @return void
    * @example CLT_Get_Conext_Role_Ctrl constructor = new CLT_Get_Conext_Role_Ctrl()
    * --------------------------------------------------------------------------------------
    **/
    public CLT_Get_Conext_Role_Ctrl() {}

    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros que vienen desde el flow 
    *              para llamar al servicio y obtener que rol puede realizar la petición.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public class FlowInput{
        @InvocableVariable (required=true) public String numClient;
        @InvocableVariable (required=true) public String numUser;
        @InvocableVariable (required=true) public String mode;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros que van hacia el flow para que 
    *              el usuario pueda indicar que rol desea realizar la petición
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public class FlowOutput{
        @InvocableVariable public List<CLT_Apply_To_Team_Member_RoleWrapper> roles;
        @InvocableVariable public Integer StatusCode;
        @InvocableVariable public String statusMessage;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method para consultar las peticiones en el servicio getRolesMembers
    * --------------------------------------------------------------------------------------
    * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-02-22
    * @param  inputs Datos obtenidos desde el flow Apply to join Coverage Team
    * @return List<FlowOutput> Lista de objetos con los roles que el usuario puede dar de alta/baja
    * @example  CLT_Get_Context_Role_Service.getRoles(numClient, numUser, mode)
    * --------------------------------------------------------------------------------------
    **/
    @InvocableMethod(label='Join context roles member' description='Get the current user role information.')
    public static List<FlowOutput> getRolesMembers(List<FlowInput> inputs) {
        FlowInput input  = inputs[0];
        CLT_Get_Context_Role_Service.ServiceResult servResult = CLT_Get_Context_Role_Service.getRoles(input.numClient, input.numUser, input.mode);
        FlowOutput output = new FlowOutput();
        output.roles = (servResult != null) ? servResult.roles : new List<CLT_Apply_To_Team_Member_RoleWrapper>();
        output.StatusCode = servResult.statusCode;
        output.statusMessage = servResult.statusMessage;
        return new List<FlowOutput>{output};
    }
}