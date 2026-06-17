/**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros de la respuesta del servicio
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
public class CLT_Apply_To_Team_Member_RoleWrapper {
    @auraEnabled public String id;
    @auraEnabled public String label;
    @auraEnabled public String firstApproveName;
    @auraEnabled public List<CLT_Apply_To_Team_Member_LocWrapper> locations;
    @auraEnabled public List<CLT_Apply_To_Team_Member_SubWrapper> subsidiaries;
}