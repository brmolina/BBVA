/**********************************************************************************
 * @author       Accenture
 * @date            30/05/2016
 * @description  Manejador del trigger para el objeto User. No implementar logica aquí, para ello utilizar ActivitiesUtils
 * @Revision
 * 2018/10/04 Añadida funcionalidad para gestionar los usuarios que se asignan/eliminan en el permissionSet que da acceso a los usuarios a Chatter.
 *
 * REFACTOR 2026:
 *  • Eliminada funcionalidad legacy E-Commerce en desuso.
 *  • Introducidos métodos orquestadores:
 *        - handleBeforeInsert
 *        - handleBeforeUpdate
 *        - handleAfterInsert
 *        - handleAfterUpdate
 *  • Centralizada la lógica de:
 *        - Skip por cambio de ámbito (shouldSkipAmbitUpdate)
 *        - Filtrado de usuarios activos (getActiveUsers)
 *        - Gestión de reactivaciones
 *  • Reducida complejidad ciclomática y acoplamiento al modelo de Roles.
 *
 * Diseño actual:
 *  Trigger → Dispatcher
 *  Handler → Orquestador + Reglas de negocio
 *
 * Objetivo: mayor mantenibilidad, escalabilidad y claridad arquitectónica.
 **********************************************************************************/
@SuppressWarnings('sf:TooManyMethods, sf:MethodCouldBeStatic, sf:CyclomaticComplexity, sf:NPathComplexity, sf:AvoidGetSetMethods, sf:NcssMethodCount')
public with sharing class UserTriggerHandler{
	private static UserTriggerHandler instance;

	public static UserTriggerHandler getInstance(){
		if (instance == null){
			instance = new UserTriggerHandler();
		}
		return instance;
	}

	private UserTriggerHandler(){
	}

	private static final String IS_MEXICO = 'MEX';
	public final static User_Helper USERHELPER = User_Helper.gtInstance();
	/**********************************************************************************************************
	 * @name            handleBeforeInsert
	 * @author          David Díaz
	 * @created         2026
	 * @description     Orquestador del evento BEFORE INSERT del objeto User.
	 *                  Ejecuta la lógica principal previa a la inserción:
	 *                  - Inicialización de ProfileId y RoleId
	 *                  - Asignación de moneda por país
	 *                  - Validaciones generales
	 *                  - Sincronización de departamento
	 * @param           List<User> newList - Lista de usuarios en contexto Trigger.new.
	 * @return          void
	 **********************************************************************************************************/
	public void handleBeforeInsert(List<User> newList){
		onBeforeInsert(newList);
		updateUserDepartment(newList);
	}

	/**********************************************************************************************************
	 * @name            handleBeforeUpdate
	 * @author          David Díaz
	 * @created         2026
	 * @description     Orquestador del evento BEFORE UPDATE del objeto User.
	 *                  Gestiona la lógica previa a la actualización incluyendo:
	 *                  - Validación de cambio exclusivo de ámbito
	 *                  - Actualización de datos derivados
	 *                  - Limpieza de grupos si aplica bypass
	 * @param           List<User> newList - Lista de usuarios actualizados.
	 * @param           Map<Id, User> oldMap - Estado anterior de los usuarios.
	 * @param           Boolean skipDenorm - Flag de configuración para bypass de lógica de grupos.
	 * @return          void
	 **********************************************************************************************************/
	public void handleBeforeUpdate(List<User> newList, Map<Id, User> oldMap, Boolean skipDenorm){
		if (shouldSkipAmbitUpdate(newList, oldMap)){
			onBeforeUpdateAmbit(newList);
			return;
		}

		onBeforeUpdate(newList);
		updateUserDepartment(newList);

		if (skipDenorm){
			borrarGruposUsuario(new Map<Id, User>(newList));
		}
	}

	/**********************************************************************************************************
	 * @name            handleAfterInsert
	 * @author          David Díaz
	 * @created         2026
	 * @description     Orquestador del evento AFTER INSERT del objeto User.
	 *                  Ejecuta lógica posterior a la inserción:
	 *                  - Gestión de grupos legales
	 *                  - Asignación automática de Permission Set de Chatter
	 *                  - Validaciones específicas por país (México)
	 * @param           List<User> newList - Usuarios insertados.
	 * @param           Map<Id, User> newMap - Mapa de usuarios insertados.
	 * @param           Boolean skipDenorm - Flag de configuración para bypass de lógica de grupos.
	 * @return          void
	 **********************************************************************************************************/
	public void handleAfterInsert(List<User> newList, Map<Id, User> newMap, Boolean skipDenorm){
		List<User> activeUsers = getActiveUsers(newList);
		if (activeUsers.isEmpty())
			return;
		if (skipDenorm){
			setUserGroup(activeUsers);
		}

		checkAssignChatterPermissionSet(activeUsers);
		onAfterInsert(activeUsers, newMap);
	}

	/**********************************************************************************************************
	 * @name            handleAfterUpdate
	 * @author          David Díaz
	 * @created         2026
	 * @description     Orquestador del evento AFTER UPDATE del objeto User.
	 *                  Ejecuta lógica posterior a la actualización:
	 *                  - Gestión de grupos legales
	 *                  - Actualización de Permission Set de Chatter
	 *                  - Validaciones por país
	 *                  - Gestión de reactivaciones de usuario
	 * @param           List<User> newList - Usuarios actualizados.
	 * @param           Map<Id, User> oldMap - Estado previo.
	 * @param           Map<Id, User> newMap - Estado actual.
	 * @param           Boolean skipDenorm - Flag de configuración para bypass.
	 * @return          void
	 **********************************************************************************************************/
	public void handleAfterUpdate(List<User> newList, Map<Id, User> oldMap, Map<Id, User> newMap, Boolean skipDenorm){
		if (shouldSkipAmbitUpdate(newList, oldMap))
			return;
		List<User> activeUsers = getActiveUsers(newList);
		if (activeUsers.isEmpty())
			return;
		if (skipDenorm){
			setUserGroup(activeUsers);
		}

		checkUpdateChatterPermissionSet(activeUsers, oldMap);
		onAfterUpdate(activeUsers, oldMap, newMap);
		handleReactivations(newList, oldMap);
	}

	/**********************************************************************************************************
	 * @name            onBeforeInsert
	 * @author          Accenture
	 * @created         30/05/2016
	 * @description     Lógica principal ejecutada en el evento BEFORE INSERT del objeto User.
	 *                  Inicializa Profile/Role, asigna moneda por país, ejecuta validaciones
	 *                  generales y sincroniza el campo Country.
	 * @param           List<User> newList - Usuarios en contexto de inserción.
	 * @return          void
	 **********************************************************************************************************/
	private void onBeforeInsert(List<User> newList){
		UserLogic.setUserProfileID_UserRoleID(newList);
		stUserCurrencyISOCode(newList);
		USERHELPER.completeLogicValidate(newList);
		updateUserCountry(newList);
	}

	/**********************************************************************************************************
	 * @name            onBeforeUpdate
	 * @author          Accenture
	 * @created         30/05/2016
	 * @description     Lógica principal ejecutada en el evento BEFORE UPDATE del objeto User.
	 *                  Revalida perfil/rol, aplica validaciones generales y sincroniza Country.
	 * @param           List<User> newList - Usuarios en contexto de actualización.
	 * @return          void
	 **********************************************************************************************************/
	private void onBeforeUpdate(List<User> newList){
		UserLogic.setUserProfileID_UserRoleID(newList);
		USERHELPER.completeLogicValidate(newList);
		updateUserCountry(newList);
	}

	/**********************************************************************************************************
	 * @name            onBeforeUpdateAmbit
	 * @author          Accenture
	 * @created         30/05/2016
	 * @description     Ejecuta únicamente validaciones cuando la actualización corresponde
	 *                  exclusivamente a un cambio de ámbito operativo.
	 * @param           List<User> newList - Usuarios actualizados.
	 * @return          void
	 **********************************************************************************************************/
	public void onBeforeUpdateAmbit(List<User> newList){
		USERHELPER.completeLogicValidate(newList);
	}

	/**********************************************************************************************************
	 * @name            onAfterInsert
	 * @author          Accenture
	 * @created         30/05/2016
	 * @description     Lógica posterior a la inserción del usuario.
	 *                  Gestiona asignaciones de aprobadores DMT y validaciones específicas
	 *                  para usuarios con país México.
	 * @param           List<User> newList - Usuarios insertados.
	 * @param           Map<Id, User> newMap - Mapa de usuarios insertados.
	 * @return          void
	 **********************************************************************************************************/
	private void onAfterInsert(List<User> newList, Map<Id, User> newMap){

		USERHELPER.assignUserUosToDmtApprover(null, newMap);

		Set<Id> mexicoUsers = new Set<Id>();
		for (User u : newList){
			if (u.Country == IS_MEXICO){
				mexicoUsers.add(u.Id);
			}
		}

		if (!mexicoUsers.isEmpty()){
			User_Helper.validateMexUserFuture(mexicoUsers, true);
		}
	}

	/**********************************************************************************************************
	 * @name            onAfterUpdate
	 * @author          Accenture
	 * @created         30/05/2016
	 * @description     Lógica posterior a la actualización del usuario.
	 *                  Gestiona asignaciones DMT y validaciones para usuarios con país México
	 *                  ante cambios de estado o país.
	 * @param           List<User> newList - Usuarios actualizados.
	 * @param           Map<Id, User> oldMap - Estado previo de los usuarios.
	 * @param           Map<Id, User> newMap - Estado actual de los usuarios.
	 * @return          void
	 **********************************************************************************************************/
	private void onAfterUpdate(List<User> newList, Map<Id, User> oldMap, Map<Id, User> newMap){
		USERHELPER.assignUserUosToDmtApprover(oldMap, newMap);

		Set<Id> mexicoActivate = new Set<Id>();
		Set<Id> mexicoDeactivate = new Set<Id>();

		for (User u : newList){

			User oldUser = oldMap.get(u.Id);

			if (u.IsActive){
				if (u.Country == IS_MEXICO && u.Country != oldUser.Country){
					mexicoActivate.add(u.Id);
				}
				if (oldUser.Country == IS_MEXICO && u.Country != oldUser.Country){
					mexicoDeactivate.add(u.Id);
				}
			} else if (u.Country == IS_MEXICO){
				mexicoDeactivate.add(u.Id);
			}
		}

		if (!mexicoActivate.isEmpty()){
			User_Helper.validateMexUserFuture(mexicoActivate, true);
		}

		if (!mexicoDeactivate.isEmpty()){
			User_Helper.validateMexUserFuture(mexicoDeactivate, false);
		}
	}

	/**********************************************************************************************************
	 * @name            checkAssignChatterPermissionSet
	 * @author          David Díaz
	 * @created         2026
	 * @description     Asigna automáticamente el Permission Set de Chatter a usuarios
	 *                  activos de tipo Standard que no tengan deshabilitado el acceso.
	 * @param           List<User> users - Usuarios a evaluar.
	 * @return          void
	 **********************************************************************************************************/
	public void checkAssignChatterPermissionSet(List<User> users){

		PermissionSet ps = [SELECT Id
		                    FROM PermissionSet
		                    WHERE Name = :Label.DES_Name_PermissionSet_Chatter
		                    LIMIT 1];

		Set<Id> assignIds = new Set<Id>();

		for (User u : users){
			if (u.IsActive && u.UserType == 'Standard' && !u.DES_Disable_Chatter__c){
				assignIds.add(u.Id);
			}
		}

		if (!assignIds.isEmpty()){
			UserLogic.assignPermissionSet(ps.Id, assignIds);
		}
	}

	/**********************************************************************************************************
	 * @name            checkUpdateChatterPermissionSet
	 * @author          David Díaz
	 * @created         2026
	 * @description     Gestiona la asignación o eliminación del Permission Set de Chatter
	 *                  en función de cambios en estado activo o flag DES_Disable_Chatter__c.
	 * @param           List<User> users - Usuarios actualizados.
	 * @param           Map<Id, User> oldMap - Estado previo.
	 * @return          void
	 **********************************************************************************************************/
	public void checkUpdateChatterPermissionSet(List<User> users, Map<Id, User> oldMap){

		PermissionSet ps = [SELECT Id
		                    FROM PermissionSet
		                    WHERE Name = :Label.DES_Name_PermissionSet_Chatter
		                    LIMIT 1];

		Set<Id> assignIds = new Set<Id>();
		Set<Id> removeIds = new Set<Id>();

		for (User u : users){

			User oldUser = oldMap.get(u.Id);

			Boolean shouldAssign = u.UserType == 'Standard' && u.IsActive && !u.DES_Disable_Chatter__c && (!oldUser.IsActive || oldUser.DES_Disable_Chatter__c);

			Boolean shouldRemove = (!u.IsActive && oldUser.IsActive) || (u.IsActive && u.DES_Disable_Chatter__c && !oldUser.DES_Disable_Chatter__c);

			if (shouldAssign)
				assignIds.add(u.Id);
			if (shouldRemove)
				removeIds.add(u.Id);
		}

		if (!assignIds.isEmpty()){
			UserLogic.assignPermissionSet(ps.Id, assignIds);
		}

		if (!removeIds.isEmpty()){
			UserLogic.removePermissionSet(ps.Id, removeIds);
		}
	}

	/**********************************************************************************************************
	 * @name            shouldSkipAmbitUpdate
	 * @author          David Díaz
	 * @created         2026
	 * @description     Determina si la actualización del usuario corresponde exclusivamente
	 *                  a un cambio de ámbito operativo, permitiendo omitir lógica adicional.
	 * @param           List<User> newList - Usuarios actualizados.
	 * @param           Map<Id, User> oldMap - Estado previo de los usuarios.
	 * @return          Boolean - true si debe omitirse lógica adicional, false en caso contrario.
	 **********************************************************************************************************/
	public Boolean shouldSkipAmbitUpdate(List<User> newList, Map<Id, User> oldMap){
		for (User u : newList){
			User oldU = oldMap.get(u.Id);
			if (!(u.gf_user_operation_ambit_name__c != null && u.gf_user_operation_ambit_name__c != oldU.gf_user_operation_ambit_name__c)){
				return false;
			}
		}
		return true;
	}

	/**********************************************************************************************************
	 * @name            getActiveUsers
	 * @author          David Díaz
	 * @created         2026
	 * @description     Filtra y devuelve únicamente los usuarios activos de una lista.
	 * @param           List<User> users - Lista de usuarios a evaluar.
	 * @return          List<User> - Lista filtrada con usuarios activos.
	 **********************************************************************************************************/
	private List<User> getActiveUsers(List<User> users){
		List<User> activeUsers = new List<User>();
		for (User u : users){
			if (u.IsActive){
				activeUsers.add(u);
			}
		}
		return activeUsers;
	}

	/**********************************************************************************************************
	 * @name            handleReactivations
	 * @author          David Díaz
	 * @created         2026
	 * @description     Detecta usuarios reactivados (IsActive de false a true)
	 *                  y dispara la lógica correspondiente para reconstrucción
	 *                  de miembros de equipo en oportunidades abiertas.
	 * @param           List<User> newList - Usuarios actualizados.
	 * @param           Map<Id, User> oldMap - Estado previo.
	 * @return          void
	 **********************************************************************************************************/
	private void handleReactivations(List<User> newList, Map<Id, User> oldMap){
		Set<Id> reactivated = new Set<Id>();

		for (User u : newList){
			if (u.IsActive && !oldMap.get(u.Id).IsActive){
				reactivated.add(u.Id);
			}
		}

		if (!reactivated.isEmpty()){
			processReactivatedUsers(reactivated);
		}
	}

	/**********************************************************************************************************
	 * @name            processReactivatedUsers
	 * @author          David Díaz
	 * @created         2026
	 * @description     Invoca de forma asíncrona la lógica de reconstrucción
	 *                  de miembros de oportunidad tras reactivación de usuarios.
	 * @param           Set<Id> userIds - Identificadores de usuarios reactivados.
	 * @return          void
	 **********************************************************************************************************/
	public void processReactivatedUsers(Set<Id> userIds){
		handleReactivatedUsers(userIds);
	}

	/**********************************************************************************************************
	 * @name            handleReactivatedUsers
	 * @author          David Díaz
	 * @created         2026
	 * @description     Método asíncrono que elimina y recrea los miembros de equipo
	 *                  de oportunidades abiertas asociados a usuarios reactivados,
	 *                  evitando inconsistencias de permisos.
	 * @param           Set<Id> userIds - Identificadores de usuarios reactivados.
	 * @return          void
	 **********************************************************************************************************/
	@future
	public static void handleReactivatedUsers(Set<Id> userIds){

		List<DES_Opportunity_Management_member__c> existing = [SELECT Id, DES_Opportunity__c, DES_User__c, DES_Scope__c, DES_PS_Product_Family__c, DES_PS_Product__c, DES_Owner__c, Name, DES_Opportunity_member_role__c, DES_Tipo_de_cobertura__c
		                                                       FROM DES_Opportunity_Management_member__c
		                                                       WHERE DES_User__c IN:userIds AND DES_Opportunity__r.IsClosed = false];

		if (!existing.isEmpty()){
			delete existing;
		}

		List<DES_Opportunity_Management_member__c> recreated = new List<DES_Opportunity_Management_member__c>();

		for (DES_Opportunity_Management_member__c otm : existing){
			recreated.add(new DES_Opportunity_Management_member__c(
				DES_Opportunity__c = otm.DES_Opportunity__c, 
				DES_User__c = otm.DES_User__c, 
				DES_Scope__c = otm.DES_Scope__c, 
				DES_PS_Product_Family__c = otm.DES_PS_Product_Family__c, 
				DES_PS_Product__c = otm.DES_PS_Product__c, 
				DES_Owner__c = otm.DES_Owner__c, 
				Name = otm.Name, 
				DES_Opportunity_member_role__c = otm.DES_Opportunity_member_role__c, 
				DES_Tipo_de_cobertura__c = otm.DES_Tipo_de_cobertura__c
			));
		}

		if (!recreated.isEmpty()){
			insert recreated;
		}
	}

	/**********************************************************************************************************
	 * @name            updateUserCountry
	 * @author          Accenture
	 * @created         30/05/2016
	 * @description     Sincroniza el campo estándar Country del usuario con el valor
	 *                  del campo personalizado DES_Country__c.
	 * @param           List<User> users - Usuarios a actualizar.
	 * @return          void
	 **********************************************************************************************************/
	private void updateUserCountry(List<User> users){
		for (User u : users){
			u.Country = u.DES_Country__c;
		}
	}

	/**********************************************************************************************************
	 * @name            updateUserDepartment
	 * @author          Accenture
	 * @created         30/05/2016
	 * @description     Copia el valor del departamento del usuario al campo
	 *                  dwp_kitv__EMPLOYEE_DEPARTMENT_DESC__c.
	 * @param           List<User> users - Usuarios a actualizar.
	 * @return          void
	 **********************************************************************************************************/
	public void updateUserDepartment(List<User> users){
		for (User u : users){
			u.dwp_kitv__EMPLOYEE_DEPARTMENT_DESC__c = u.EMPLOYEE_DEPARTMENT_DESC__c;
		}
	}

	/**********************************************************************************************************
	 * @name            stUserCurrencyISOCode
	 * @author          Accenture
	 * @created         30/05/2016
	 * @description     Asigna el DefaultCurrencyIsoCode del usuario en función
	 *                  del país definido en DES_Country__c utilizando Custom Metadata.
	 * @param           List<User> users - Usuarios a procesar.
	 * @return          void
	 **********************************************************************************************************/
	private void stUserCurrencyISOCode(List<User> users){

		Map<String, String> countryCurrency = new Map<String, String>();

		for (Opp_Countries__mdt mtd : [SELECT Country_User__c, Currency_ISO3__c
		                               FROM Opp_Countries__mdt]){

			countryCurrency.put(mtd.Country_User__c, mtd.Currency_ISO3__c);
		}

		for (User u : users){
			u.DefaultCurrencyIsoCode = countryCurrency.get(u.DES_Country__c);
		}
	}

	/**********************************************************************************************************
	 * @name            borrarGruposUsuario
	 * @author          Accenture
	 * @created         30/05/2016
	 * @description     Elimina la pertenencia del usuario a grupos públicos
	 *                  cuyo DeveloperName contiene 'Legal', en caso de bypass activo.
	 * @param           Map<Id, User> users - Usuarios afectados.
	 * @return          void
	 **********************************************************************************************************/
	public void borrarGruposUsuario(Map<Id, User> users){

		Map<Id, Group> groups = new Map<Id, Group>([SELECT Id
		                                            FROM Group
		                                            WHERE DeveloperName LIKE '%Legal%']);

		List<GroupMember> members = [SELECT Id
		                             FROM GroupMember
		                             WHERE UserOrGroupId IN:users.keySet() AND GroupId IN:groups.keySet()];

		if (!members.isEmpty()){
			delete members;
		}
	}

	/**********************************************************************************************************
	 * @name            setUserGroup
	 * @author          Accenture
	 * @created         30/05/2016
	 * @description     Asigna automáticamente al usuario los grupos públicos
	 *                  correspondientes según el valor del campo Entity_name__c.
	 * @param           List<User> users - Usuarios a procesar.
	 * @return          void
	 **********************************************************************************************************/
	public void setUserGroup(List<User> users){

		List<GroupMember> listGroupMembers = new List<GroupMember>();
		Map<String, Group> mapGroups = new Map<String, Group>();

		for (Group g : [SELECT Id, DeveloperName
		                FROM Group
		                WHERE DeveloperName LIKE '%Legal%']){
			mapGroups.put(g.DeveloperName, g);
		}

		for (User us : users){

			if (us.Entity_name__c == null)
				continue;
			List<String> entities = us.Entity_name__c.contains(';') ? us.Entity_name__c.split(';') : new List<String>{ us.Entity_name__c };

			for (String entity : entities){

				Group targetGroup = mapGroups.get(entity);

				if (targetGroup == null){
					Map<String, String> labelMap = Util_PickList.getLabelFromAPI('User', 'Entity_name__c');
					targetGroup = mapGroups.get(labelMap.get(entity));
				}

				if (targetGroup == null){
					us.addError('No existe el grupo ' + entity + 
							' correspondiente al usuario ' + us.Name);
					continue;
				}

				listGroupMembers.add(new GroupMember(
					GroupId = targetGroup.Id, 
					UserOrGroupId = us.Id
				));
			}
		}

		if (!listGroupMembers.isEmpty()){
			insert listGroupMembers;
		}
	}

}