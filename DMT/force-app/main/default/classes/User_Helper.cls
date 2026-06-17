/***************************************************************************************
 * @author       BBVA
 * @date         2026
 * @description  Clase fachada (Facade) del dominio User.
 *               Orquesta la ejecución de los distintos servicios especializados
 *               relacionados con la gestión de usuarios:
 *
 *               • Gestión de Ambits y permisos funcionales.
 *               • Gestión del Public Group de México.
 *               • Asignación automática de DMT Approver Members por UOS.
 *               • Eliminación de Approver Members cuando cambia el UOS.
 *               • Mapeo dinámico de roles desde integración SAML.
 *
 * ARQUITECTURA 2026:
 *  • Refactorizada bajo patrón Facade + Services.
 *  • Separación de responsabilidades (SRP).
 *  • Eliminada lógica monolítica anterior.
 *  • Mantiene compatibilidad hacia atrás con métodos legacy.
 *
 * DEPENDENCIAS:
 *  • DES_cls_UserAmbitProvider
 *  • DES_cls_UserAmbitService
 *  • DES_cls_UserMexicoGroupService
 *  • DES_cls_UserUosApproverService
 *  • DES_cls_UserProjectRoleService
 *
 ***************************************************************************************/
public with sharing class User_Helper{
  /*
   * Singleton instance
   */
  private static User_Helper instance;

  /***************************************************************************************
   * @description  Devuelve la instancia única del helper (Singleton Pattern).
   * @return       User_Helper
   ***************************************************************************************/
  public static User_Helper gtInstance(){
    if (instance == null){
      instance = new User_Helper();
    }
    return instance;
  }

  /*
   * Mapa estático de Ambits cargado desde Custom Metadata.
   * Se mantiene público por compatibilidad con Arc_Gen_TabSet_service.
   */
  public final static Map<String, Arce_ambit_hierarchy__mdt> MAPAMBIT = DES_cls_UserAmbitProvider.getMap();
  /***************************************************************************************
   * @description  Aplica la lógica de permisos funcionales en base al Ambit del usuario.
   *               Establece los flags:
   *                 - DES_ARCE_Can_Propose__c
   *                 - DES_ARCE_Can_Validate__c
   *                 - DES_ARCE_Can_Edit__c
   *
   * @param        newList  Lista de usuarios (before insert / before update).
   ***************************************************************************************/
  public void completeLogicValidate(List<User> newList){
    DES_cls_UserAmbitService.apply(newList);
  }

  /***************************************************************************************
   * @description  Método asíncrono que añade o elimina usuarios del Public Group
   *               que permite visualizar clientes de México.
   *
   * @param        usersIds         Conjunto de Ids de usuario.
   * @param        toCreateMember   TRUE → Insertar en grupo.
   *                                 FALSE → Eliminar del grupo.
   ***************************************************************************************/
  @future
  public static void validateMexUserFuture(Set<Id> usersIds, Boolean toCreateMember){
    validateMexUser(usersIds, toCreateMember);
  }

  /***************************************************************************************
   * @description  Gestiona la pertenencia de usuarios al Public Group de México.
   *               Delegado a DES_cls_UserMexicoGroupService.
   *
   * @param        usersIds         Conjunto de Ids de usuario.
   * @param        toCreateMember   TRUE → Insertar en grupo.
   *                                 FALSE → Eliminar del grupo.
   ***************************************************************************************/
  public static void validateMexUser(Set<Id> usersIds, Boolean toCreateMember){
    DES_cls_UserMexicoGroupService.manage(usersIds, toCreateMember);
  }

  /***************************************************************************************
   * @description  Asigna automáticamente DMT Approver Members y Group Members
   *               en función del UOS del usuario.
   *
   *               • Detecta cambios de UOS en update.
   *               • Crea nuevos registros DMT_Approver_Member__c.
   *               • Inserta usuarios en colas/grupos asociados.
   *               • Elimina membresías anteriores cuando corresponde.
   *               • Ejecuta operaciones vía Queueable.
   *
   * @param        oldUserMap   Mapa de usuarios antes de la actualización.
   * @param        newUsersMap  Mapa de usuarios nuevos.
   ***************************************************************************************/
  public void assignUserUosToDmtApprover(Map<Id, User> oldUserMap, Map<Id, User> newUsersMap){
    DES_cls_UserUosApproverService.process(oldUserMap, newUsersMap);
  }

  /***************************************************************************************
   * @description  Método mantenido por compatibilidad hacia atrás.
   *               Elimina DMT Approver Members y devuelve los GroupMembers
   *               que deben eliminarse cuando cambia el UOS.
   *
   * @param        oldUserMap   Mapa de usuarios antes del update.
   * @param        mapUosUser   Mapa UserId → UOS.
   *
   * @return       Lista de GroupMember a eliminar.
   ***************************************************************************************/
  public static List<GroupMember> uosDeleteApproveMember(Map<Id, User> oldUserMap, Map<Id, String> mapUosUser){
    return DES_cls_UserUosApproverService.deleteOldApproverMembersAndReturnGroupMembers(oldUserMap, mapUosUser);
  }

  /***************************************************************************************
   * @description  Rellena dinámicamente los campos de rol del usuario
   *               en base a la información recibida desde SAML (SSO).
   *
   *               • Consulta DES_User_Roles__mdt.
   *               • Mapea roles recibidos contra campos del User.
   *               • Soporta ejecución en contexto Test.
   *
   * @param        user     Usuario a modificar.
   * @param        wrapper  Respuesta parseada de integración SAML.
   ***************************************************************************************/
  public static void fillUserRoleByProject(User user, UserUuaaInfoExtended.wrapper wrapper){
    if (Test.isRunningTest()){
      DES_User_Roles__mdt fake = new DES_User_Roles__mdt();
      fake.DES_Role_Developer_Name__c = 'DMT_Proyecto';
      fake.DES_User_Field_Map__c = 'DMT_User_Role__c';
      
      DES_cls_UserProjectRoleService.fill(user, wrapper, new List<DES_User_Roles__mdt>{ fake });
      return;
    }
    DES_cls_UserProjectRoleService.fill(user, wrapper);
  }

}