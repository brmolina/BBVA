/**
    * --------------------------------------------------------------------------------------
    * @Description Clase interna que representa los parámetros del Rol de Local Banker
    *              para poder guardar las subsidirias en el flow
    * --------------------------------------------------------------------------------------
    * @Author   Carlos Maqueda    carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date     2026-02-22
    * ---------------------------------------------------------------------------------------------------------------------------------------------
    **/
public class CLT_Apply_To_Team_Member_SubWrapper {
    @auraEnabled public String nameCountry;
    @auraEnabled public List<String> idSubsidiary;
    @auraEnabled public String idSubsidiaries;
}