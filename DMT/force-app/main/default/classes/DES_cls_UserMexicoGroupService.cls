/***************************************************************************************
 * @author       BBVA
 * @date         2026
 * @description  Servicio especializado encargado de gestionar la pertenencia
 *               de usuarios al Public Group de México (cTMMexico).
 *
 *               RESPONSABILIDAD:
 *               • Añadir usuarios al grupo cuando corresponda.
 *               • Eliminar usuarios del grupo cuando deje de aplicar.
 *               • Centralizar la lógica de acceso a clientes de México.
 *
 * ARQUITECTURA 2026:
 *  • Extraída desde User_Helper como parte del refactor a patrón Facade + Services.
 *  • Implementa cache estática del Group para evitar queries repetidas.
 *  • Bulk-safe (opera sobre Set<Id>).
 *
 * CONSIDERACIONES:
 *  • El Group debe existir en el org con:
 *        - Type = 'Regular'
 *        - DeveloperName = 'cTMMexico'
 *  • Las operaciones se ejecutan en contexto síncrono.
 *
 ***************************************************************************************/
public with sharing class DES_cls_UserMexicoGroupService{
    /*
     * Cache estática del Public Group de México.
     * Evita ejecutar múltiples queries en la misma transacción.
     */
    private static Group mexicoGroup;

    /***************************************************************************************
     * @description  Devuelve el Public Group de México.
     *               Si no está cacheado, lo consulta y lo almacena.
     *
     * @return       Group (cTMMexico)
     ***************************************************************************************/
    private static Group getGroup(){
        if (mexicoGroup == null){
            mexicoGroup = [SELECT Id
                           FROM Group
                           WHERE Type = 'Regular' AND DeveloperName = 'cTMMexico'
                           LIMIT 1];
        }
        return mexicoGroup;
    }

    /***************************************************************************************
     * @description  Gestiona la pertenencia de usuarios al Public Group de México.
     *
     *               • Si add = TRUE  → Inserta nuevos GroupMember.
     *               • Si add = FALSE → Elimina los GroupMember existentes.
     *
     *               Método bulk-safe.
     *
     * @param        usersIds   Conjunto de Ids de usuario.
     * @param        add        TRUE  → Añadir usuarios al grupo.
     *                          FALSE → Eliminar usuarios del grupo.
     ***************************************************************************************/
    public static void manage(Set<Id> usersIds, Boolean add){

        if (usersIds == null || usersIds.isEmpty())
            return;
        Group grp = getGroup();

        if (add){

            List<GroupMember> members = new List<GroupMember>();

            for (Id uid : usersIds){
                members.add(new GroupMember(
                    GroupId = grp.Id, 
                    UserOrGroupId = uid
                ));
            }

            if (!members.isEmpty()){
                insert members;
            }

        } else{

            delete [SELECT Id
                    FROM GroupMember
                    WHERE GroupId = :grp.Id AND UserOrGroupId IN:usersIds];
        }
    }

}