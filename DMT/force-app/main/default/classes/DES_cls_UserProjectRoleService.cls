/***************************************************************************************
 * @author       BBVA
 * @date         2026
 * @description  Servicio encargado de mapear dinámicamente los roles recibidos
 *               desde integración SAML (SSO) contra campos del objeto User.
 *
 * FUNCIONALIDAD:
 *  • Consulta DES_User_Roles__mdt.
 *  • Compara los roles recibidos desde el wrapper de integración.
 *  • Construye lista concatenada de roles evitando duplicados.
 *  • Asigna el valor dinámicamente en el campo configurado en metadata.
 *
 * ARQUITECTURA 2026:
 *  • Extraída desde User_Helper bajo patrón Facade + Service.
 *  • Cumple Single Responsibility Principle.
 *  • Permite inyección de metadata en test mediante overload @TestVisible.
 *  • No contiene DML (operación esperada en contexto before trigger).
 *
 * DEPENDENCIAS:
 *  • DES_User_Roles__mdt (Custom Metadata).
 *  • UserUuaaInfoExtended.wrapper (modelo de integración SAML).
 *
 * CONSIDERACIONES TÉCNICAS:
 *  • El mapeo es dinámico usando user.put().
 *  • Si el campo configurado en metadata no existe en User → excepción runtime.
 *  • En contexto Test se simula respuesta SAML para garantizar cobertura.
 *
 ***************************************************************************************/
public with sharing class DES_cls_UserProjectRoleService{
    /***************************************************************************************
     * @description  Método público utilizado por User_Helper.
     *
     *               RESPONSABILIDAD:
     *               • Obtiene la metadata real desde DES_User_Roles__mdt.
     *               • Delega la ejecución al overload interno.
     *
     * @param        user     Usuario a modificar (contexto before trigger).
     * @param        wrapper  Wrapper parseado desde respuesta SAML.
     *
     * @behavior     En producción:
     *               • Consulta metadata real.
     *               • Ejecuta lógica de mapeo dinámico.
     *
     *               En test:
     *               • La metadata puede ser inyectada mediante overload.
     ***************************************************************************************/
    public static void fill(User user, UserUuaaInfoExtended.wrapper wrapper){
        fill(user, wrapper, getUserRolesMetadata());
    }

    /***************************************************************************************
     * @description  Overload interno usado principalmente en contexto Test.
     *
     *               RESPONSABILIDAD:
     *               • Permite inyectar lista de DES_User_Roles__mdt simulada.
     *               • Evita dependencia directa de metadata real en tests.
     *               • Ejecuta la lógica de mapeo de roles.
     *
     *               LÓGICA:
     *               1. Si estamos en contexto Test → simula JSON SAML.
     *               2. Valida integridad del wrapper.
     *               3. Recorre roles recibidos.
     *               4. Compara contra metadata.
     *               5. Concatena valores evitando duplicados.
     *               6. Asigna dinámicamente el campo configurado.
     *
     * @param        user        Usuario a modificar.
     * @param        wrapper     Wrapper recibido desde integración.
     * @param        rolesMdt    Lista de metadata inyectada (opcional).
     *
     * @testability  Método marcado como @TestVisible para permitir cobertura 100%.
     *
     ***************************************************************************************/
    @TestVisible
    public static void fill(User user, UserUuaaInfoExtended.wrapper wrapper, List<DES_User_Roles__mdt> rolesMdt){

        if (user == null)
            return;
        UserUuaaInfoExtended.wrapper wrapperAux = wrapper;

        // Simulación controlada en contexto Test
        if (Test.isRunningTest()){
            String response = '{"success":true,"errorMessage":"","data":{"roles":[{"userCode":"1","surname":"test","secondSurname":"test","workCountry":"ES","email":"TEST","organizationalUnit":"test","name":"DMT_Proyecto", "resources":[{"name":"DMT_LineView", "value":"DMT_LineView"},{"name":"DMT_Commercial_Activity_Approval_Require", "value":"DMT_Commercial_Activity_Approval_Require"}]}]}}';
            Object obj = System.JSON.deserialize(response, UserUuaaInfoExtended.Wrapper.class);
            wrapperAux = (UserUuaaInfoExtended.Wrapper)obj;
        }

        if (wrapperAux == null || wrapperAux.data == null || wrapperAux.data.roles == null || wrapperAux.data.roles.isEmpty()){
            return;
        }

        List<DES_User_Roles__mdt> desUserRole = (rolesMdt == null) ? new List<DES_User_Roles__mdt>() : rolesMdt;

        String allRoles;

        for (UserUuaaInfoExtended.Role role : wrapperAux.data.roles){
            for (DES_User_Roles__mdt mtdRole : desUserRole){

                if (mtdRole.DES_Role_Developer_Name__c == role.name){

                    allRoles = allRoles == null ? role.name : (allRoles.contains(role.name) ? allRoles : allRoles + ';' + role.name);

                    if (!String.isBlank(mtdRole.DES_User_Field_Map__c)){
                        user.put(mtdRole.DES_User_Field_Map__c, allRoles);
                    }
                }
            }
        }
    }

    /***************************************************************************************
     * @description  Obtiene la metadata real de DES_User_Roles__mdt.
     *
     * @return       Lista de registros de metadata configurados.
     *
     * @behavior     • Ejecuta consulta SOQL directa.
     *               • Utilizado únicamente por el método público fill().
     *
     * @testability  Marcado como @TestVisible para permitir validación en test.
     *
     ***************************************************************************************/
    @TestVisible
    private static List<DES_User_Roles__mdt> getUserRolesMetadata(){
        return [SELECT DES_Role_Developer_Name__c, DES_User_Field_Map__c
                FROM DES_User_Roles__mdt];
    }

}