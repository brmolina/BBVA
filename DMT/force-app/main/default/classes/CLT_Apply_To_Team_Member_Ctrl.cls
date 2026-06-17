/**
 * --------------------------------------------------------------------------------------
 * @Name              : CLT_Apply_To_Team_Member_Ctrl.cls
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
public with sharing class CLT_Apply_To_Team_Member_Ctrl {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros que vienen desde el flow 
    *              para llamar al servicio y realizar la petición.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public class FlowInput{
        @InvocableVariable (required=true) public String idUser;
        @InvocableVariable (required=true) public String idRequestedBy;
        @InvocableVariable (required=true) public String idCompany;
        @InvocableVariable (required=true) public String comment;
        @InvocableVariable (required=true) public String idRole;
        @InvocableVariable (required=true) public String singleDual;
        @InvocableVariable (required=true) public String idOffice;
        @InvocableVariable (required=true) public String idMacroregion;
        @InvocableVariable (required=true) public String idSubsidiary;
        @InvocableVariable (required=true) public String mode;
    }
    
    /**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros que van hacia el flow para que 
    *              el usuario pueda ver si la petición se realizó de manera correcta.
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
    public class FlowOutput{
        @InvocableVariable public Integer statusCode;
        @InvocableVariable public String statusMessage;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method para consultar las peticiones en el servicio submitApplyCtrl
    * --------------------------------------------------------------------------------------
    * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-02-22
    * @param  inputs Datos obtenidos desde el flow Apply to join Coverage Team
    * @return List<FlowOutput> Lista de objetos con el estatus y el codigo de respuesta del servicio
    * @example  CLT_Apply_To_Team_Member_Service.submitApply(payload)
    * --------------------------------------------------------------------------------------
    **/
    @InvocableMethod(label='Apply to BBVA Coverage Team' description='Applies the current user to the specified records as a team member.')
    public static List<FlowOutput> submitApplyCtrl(List<FlowInput> inputs) {
        FlowInput input  = inputs[0];
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(input));
        CLT_Apply_To_Team_Member_Service.ServiceResult servResult = CLT_Apply_To_Team_Member_Service.submitApply(payload);
        FlowOutput output = new FlowOutput();
        output.statusCode = servResult != null ? servResult.statusCode : 500;
        output.statusMessage = servResult != null ? servResult.statusMessage : 'An unhandled fault has occurred while processing the flow. Please contact your system administrator for more information.';
        return new List<FlowOutput>{output};
    }
}