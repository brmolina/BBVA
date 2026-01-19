/**********************************************************************************
* @author       Accenture
* @date			30/05/2016
* @description  Manejador del trigger para el objeto User. No implementar logica aquí, para ello utilizar ActivitiesUtils
* @Revision
                2018/10/04 Añadida funcionalidad para gestionar los usuarios que se asignan/eliminan en el permissionSet que da acceso a los usuarios a Chatter.
**********************************************************************************/
@SuppressWarnings('sf:TooManyMethods, sf:MethodCouldBeStatic, sf:CyclomaticComplexity,sf:NPathComplexity,sf:AvoidGetSetMethods,sf:NcssMethodCount')
public with sharing class UserTriggerHandler {
	//LOGIC
	//private final UserLogic logic;
    private Integer timesExecuted = 0;
	/**
	* Variable eSales
	*/
	static final String SOPORTEROL = 'GLOBAL MARKETS E-COMMERCE';

	/*
	* HELPER USER
	*/
	public final static User_Helper USERHELPER = User_Helper.gtInstance();

    //CONSTRUCTOR
    private UserTriggerHandler() {
    }

    //SINGLETON PATTERN
    private static UserTriggerHandler instance;
    public static UserTriggerHandler getInstance() {
        if (instance == null) instance = new UserTriggerHandler();
        return instance;
    }

	/*
	* Variable Mexico
	*/
	static final String ISMEXICO = 'MEX';

    //EVENT HANDLER
	/**
	*
	* @author Global Desktop
	*
	*/
    public void onBeforeInsert(final List<User> newList) {
		system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger User (Before Insert)');
    	UserLogic.setUserProfileID_UserRoleID(newList);
		stUserCurrencyISOCode(newList);
		USERHELPER.completeLogicValidate(newList);
        timesExecuted ++;
        //actualiza el campo country standar
        updateUserCountry(newList);
    }

    public void onBeforeUpdate(final List<User> newList) {
		system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger User (Before Update)');
    	UserLogic.setUserProfileID_UserRoleID(newList);
		USERHELPER.completeLogicValidate(newList);
        timesExecuted ++;
        //actualiza el campo country standar
        updateUserCountry(newList);
    }

	public void onBeforeUpdateAmbit(final List<User> newList) {
		system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger User (Before Update Ambit)');
		USERHELPER.completeLogicValidate(newList);
    }

	/**
	*
	* @author Global Desktop
	*
	*/
    public void onAfterInsert(List<User> newList,Map<Id,User> newMap) {
	  //User_Helper helper = User_Helper.gtInstance();
	  //USERHELPER.ambitPermissionCall(newList,null, true); //(DEPRECATED)
      //USERHELPER.pricewisePermissionCall(newList, null, true);//(DEPRECATED)
      USERHELPER.assignUserUosToDmtApprover(null, newMap);
	  Set<Id> usersIdsFromMex = new Set<Id>();
	  for (User user : newList) {
		if(user.Country == ISMEXICO){
			usersIdsFromMex.add(user.Id);
		}
	  }
	  if(!usersIdsFromMex.isEmpty()){
		User_Helper.validateMexUserFuture(usersIdsFromMex, true);
	  }
	}

	/**
	*
	* @author Global Desktop
	*
	*/
    public void onAfterUpdate(List<User> newList, Map<Id,User> mapOld,Map<Id,User> mapNew) {
	  	  
	  USERHELPER.assignUserUosToDmtApprover(mapOld, mapNew);
	  	//User_Helper helper = User_Helper.gtInstance();
	  	Set<Id> inactiveUsersFromMex = new Set<Id>();
	  	Set<Id> usersIdsFromMex = new Set<Id>();
	  for (User user : newList) {
		System.debug(user.id_user__c+'--'+ user.isActive);
		if(user.isActive==true){
			//USERHELPER.ambitPermissionCall(newList,mapOld, false);//(DEPRECATED)
			//USERHELPER.pricewisePermissionCall(newList, mapOld, false);//(DEPRECATED)
			User oldUser = mapOld.get(user.Id);
			if(user.Country == ISMEXICO && user.Country != oldUser.Country ){
				usersIdsFromMex.add(user.Id);
			}
			if(oldUser.Country == ISMEXICO && user.Country != oldUser.Country ){
				inactiveUsersFromMex.add(user.Id);
			}
		}
		else{
			if(user.Country == ISMEXICO){
				inactiveUsersFromMex.add(user.Id);
			}
		}
	  }
	  if(!usersIdsFromMex.isEmpty()){
		User_Helper.validateMexUserFuture(usersIdsFromMex, true);
	  }
	  if(!inactiveUsersFromMex.isEmpty()){
		User_Helper.validateMexUserFuture(inactiveUsersFromMex, false);
	  }
	}

	/*
    * Copia el valor del departamento del usuario en el campo department del kit de visitas.
    */
    public void updateUserDepartment(final List<User> newList) {
    	for(User iUser : newList) {
    			iUser.dwp_kitv__EMPLOYEE_DEPARTMENT_DESC__c = iUser.EMPLOYEE_DEPARTMENT_DESC__c;
    	}
    }

    /*
    * Copia el valor del campo custom country del usuario en el campo country standar
    */
    public void updateUserCountry(final List<User> newList) {
    	for(User iUser : newList) {
    			iUser.Country = iUser.DES_Country__c;
    	}
    }
	/**
	*
	* @author Global Desktop  - DSL
	*
	*/
	private void stUserCurrencyISOCode(List<User> triggerNew) {
		final Map<String, String> mapCountryCurrency = gtMapCountryCurrency();
		Set<Id> setUsersId = new Set<Id>();
		system.debug('>>>>> triggerNew.get(0).DefaultCurrencyIsoCode: ' + triggerNew.get(0).DefaultCurrencyIsoCode);
		for(User usr : triggerNew) {
			system.debug('>>>>> ANTES: usr.DefaultCurrencyIsoCode: ' + usr.DefaultCurrencyIsoCode);
			system.debug('>>>>> ANTES: usr.DES_Country__c: ' + usr.DES_Country__c);
			system.debug('>>>>> mapCountryCurrency.get(usr.DES_Country__c) : ' + mapCountryCurrency.get(usr.DES_Country__c));
			usr.DefaultCurrencyIsoCode = mapCountryCurrency.get(usr.DES_Country__c);
			system.debug('>>>>> usr.DefaultCurrencyIsoCode: ' + usr.DefaultCurrencyIsoCode);
			system.debug('>>>>> usr.DES_Country__c: ' + usr.DES_Country__c);
			system.debug('>>>>> cambiado: usr.DefaultCurrencyIsoCode: ' + usr.DefaultCurrencyIsoCode);
		}

	}

	/*
	 *	@author Global Desktop - VASS
	 *	@Descripcion	-	Se encarga de gestionar de forma a automatica los usuarios con los perfiles SP.
	 *										- Si es un usuario nuevo SP o que antes tenia otro perfil distinto a SP  - se mete automaticamente a los usuarios en el grupo
	 *										- Si es un usuario que antes era SP y ahora no - se borra al usuario del grupo SP
	 *
	**
	public void gestionUsuariosSP(Map<Id, User> triggerNewMap, Map<Id, User> triggerOldMap) {
		final Set<Id> setNewSPUsers = new Set<Id>();
		final Set<Id> setOldSPUsers = new Set<Id>();
		final Id profileIdSP = [SELECT Id FROM Profile WHERE Name LIKE '%Desktop SP%' LIMIT 1].Id;
		for(User usr : triggerNewMap.values()) {
			if ((usr.ProfileId == profileIdSP && triggerOldMap == null) //SI ES UN USUARIO CON PERFIL SP NUEVO
			|| (usr.ProfileId == profileIdSP && triggerOldMap != null && triggerOldMap.get(usr.Id).ProfileId != profileIdSP)) { //O SI ES UN USUARIO QUE AHORA ES SP
				setNewSPUsers.add(usr.Id);
			} else if (usr.ProfileId != profileIdSP && triggerOldMap != null && triggerOldMap.get(usr.Id).ProfileId == profileIdSP) {
				setOldSPUsers.add(usr.Id);
			}
		}

		final Id spGroupId = gtSPGroupId();
		system.debug('::::: spGroupId : ' + spGroupId);
		groupSPMembersCreateLogic(setNewSPUsers, spGroupId);
		groupSPMembersDeleteLogic(setOldSPUsers, spGroupId);


	}*/

	public void processReactivatedUsers(Set<Id> userIds) {
        // Llamar al método @future
        handleReactivatedUsers(userIds);
	}

	/*
	 *	@author	Global Desktop	- VASS
	 *
	 *
	**
	private void groupSPMembersCreateLogic(Set<Id> setNewSPUsers, Id spGroupId) {
		if(!setNewSPUsers.isEmpty()) {
			createGroupSPMembers(setNewSPUsers, spGroupId);
		}
	}

	/*
	 *	@author	Global Desktop	- VASS
	 *
	**
	private void groupSPMembersDeleteLogic(Set<Id> setOldSPUsers, Id spGroupId) {
		if(!setOldSPUsers.isEmpty()) {
			deleteGroupSPMembers(setOldSPUsers, spGroupId);
		}
	}


	/*
	 *	@author Global Desktop - VASS
	 *	@Description	-	Devuelve el ID del grupo del equipo de SP
	 *
	**
	private Id gtSPGroupId() { //NOSONAR
		return [SELECT Id FROM Group WHERE DeveloperName = :Label.SP_Users_Group_DevName LIMIT 1].Id;
	}

	/*
	p *	@author Global Desktop - VASS
	 *	@Description	-	Crea los miembros del grupo SP y los inserta
	 *
	**
	private void createGroupSPMembers(Set<Id> setUserIds, Id spGroupId) {//NOSONAR
		final List<GroupMember> listGMtoInsert = new List<GroupMember>();
		for(Id idUser : setUserIds) {
			GroupMember gMember;
			gMember = new GroupMember();
			gMember.GroupId = spGroupId;
			gMember.UserOrGroupId = idUser;
			listGMtoInsert.add(gMember);
		}

		system.debug('::::: listGMtoInsert : ' + listGMtoInsert);
		if(!listGMtoInsert.isEmpty()) {
			insert listGMtoInsert;
		}
	}

	/*
	 *	@author Global Desktop - VASS
	 *	@Description	-	Borra los miembros del grupo SP
	 *
	**
	private void deleteGroupSPMembers(Set<Id> setUserIds, Id spGroupId) { //NOSONAR
		final List<GroupMember> listGroupMember = new List<GroupMember>([SELECT Id FROM GroupMember WHERE UserOrGroupId IN :setUserIds AND GroupId = :spGroupId]);
		delete listGroupMember;
	}*/

	/**
	*
	* @author Global Desktop  - DSL
	*
	*/
	private Map<String, String> gtMapCountryCurrency() {
		Map<String, String> mapCountryCurrency;
		mapCountryCurrency = new Map<String, String>();
		for(Opp_Countries__mdt mtd : [SELECT Country_User__c, Currency_ISO3__c FROM Opp_Countries__mdt]) {
			mapCountryCurrency.put(mtd.Country_User__c, mtd.Currency_ISO3__c);
		}
		system.debug('>>>>> mapCountryCurrency: ' + mapCountryCurrency);
		return mapCountryCurrency;
	}

	/**
	*
	* @author Global Desktop
	*
	*/
    public void checkAssignChatterPermissionSet(final List<User> newList) {
        system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger User (checkAssignChatterPermissionSet)');

        List<PermissionSet> psChatter = [SELECT Id FROM PermissionSet WHERE Name = :Label.DES_Name_PermissionSet_Chatter LIMIT 1];
        if(psChatter.size() == 1) {
//system.debug(Logginglevel.INFO,'>>>>>>> Assign - permissionSet de Chatter encontrado: ' + psChatter.get(0).Id);
            Set<Id> usersToBeAssigned = new Set<Id>();
            for (User newUser : newList) {
                if (newUser.isActive && newUser.UserType == 'Standard' && !newUser.DES_Disable_Chatter__c) { //NOSONAR
                    usersToBeAssigned.add(newUser.Id);
//system.debug(Logginglevel.INFO,'>>>>>>> Assign - usuario añadido: ' + newUser.Username + ' -- ' + newUser.isActive+ ' -- ' + newUser.UserType+ ' -- ' + newUser.DES_Disable_Chatter__c);
                }
            }

            if (!usersToBeAssigned.isEmpty()) {
               UserLogic.assignPermissionSet(psChatter.get(0).Id,usersToBeAssigned);
//system.debug(Logginglevel.INFO,'>>>>>>> Assign - Lista usuarios assignados: ' + usersToBeAssigned);
            }

        } else {
            System.debug(Logginglevel.INFO,'>>>>>>> No se encontra el PermissionSet con Name: ' + Label.DES_Name_PermissionSet_Chatter);
        }
        timesExecuted ++;
    }


    public void checkUpdateChatterPermissionSet(final List<User> newList,final Map<Id,User> oldLMap) {
        system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger User (checkUpdateChatterPermissionSet)');

        List<PermissionSet> psChatter = [SELECT Id FROM PermissionSet WHERE Name = :Label.DES_Name_PermissionSet_Chatter LIMIT 1];
        if(psChatter.size() == 1) {
//system.debug(Logginglevel.INFO,'>>>>>>> Update - permissionSet de Chatter encontrado: ' + psChatter.get(0).Id);
            Set<Id> usersToBeAssigned = new Set<Id>(); //usersToBeAssigned
            Set<Id> usersToBeRemoved = new Set<Id>(); //usersToBeRemoved
			String stand;
			stand = 'Standard';

            for (User newUser : newList) {
                //usersToBeAssigned
                if ( (newUser.UserType == stand && newUser.isActive && !oldLMap.get(newUser.id).isActive && !newUser.DES_Disable_Chatter__c) || (newUser.UserType == stand && newUser.isActive && !newUser.DES_Disable_Chatter__c && oldLMap.get(newUser.id).DES_Disable_Chatter__c) ) {
                    usersToBeAssigned.add(newUser.Id);
//system.debug(Logginglevel.INFO,'>>>>>>> Update -usuario añadido: ' + newUser.Username + ' -- ' + newUser.isActive+ ' -- ' + newUser.UserType+ ' -- ' + newUser.DES_Disable_Chatter__c);
                }

                //usersToBeRemoved
                if ( (!newUser.isActive && oldLMap.get(newUser.id).isActive) || (newUser.isActive && newUser.DES_Disable_Chatter__c && !oldLMap.get(newUser.id).DES_Disable_Chatter__c) ) {
                    usersToBeRemoved.add(newUser.Id);
//system.debug(Logginglevel.INFO,'>>>>>>> Update -usuario removido: ' + newUser.Username + ' -- ' + newUser.isActive+ ' -- ' + newUser.UserType+ ' -- ' + newUser.DES_Disable_Chatter__c);
                }


            }
            //usersToBeAssigned
            if (!usersToBeAssigned.isEmpty()) {
                UserLogic.assignPermissionSet(psChatter.get(0).Id,usersToBeAssigned); //usersToBeAssigned
//system.debug(Logginglevel.INFO,'>>>>>>> Update - Lista usuarios assignados: ' + usersToBeAssigned);
            }

            //usersToBeRemoved
            if (!usersToBeRemoved.isEmpty()) {
                UserLogic.removePermissionSet(psChatter.get(0).Id,usersToBeRemoved);  //usersToBeRemoved
//system.debug(Logginglevel.INFO,'>>>>>>> Update - Lista usuarios removidos: ' + usersToBeRemoved);
            }


        } else {
            System.debug(Logginglevel.INFO,'>>>>>>> No se encuentra el PermissionSet con Name: ' + Label.DES_Name_PermissionSet_Chatter);
        }
        timesExecuted ++;
    }



	/**
	*
	* @author Global Desktop
	*
	*/
    public void checkAssignECommercePermissionSet(final List<User> newList) {
        system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger User (checkAssignECommercePermissionSet)');
		String standardS = '';
		standardS = 'Standard';//NOSONAR
		System.debug(standardS);
        final List<PermissionSet> psECommerce = [SELECT Id, Name FROM PermissionSet WHERE Name = :Label.Manage_E_commerce_Configurations OR Name = :Label.Manage_E_commerce_Groups OR Name = :Label.Manage_E_commerce_Margins LIMIT 3];
		String psECommMargin;
		String psECommConfig;
		String psECommGroups;
		for(PermissionSet perm: psECommerce) {
			if(perm.Name == Label.Manage_E_commerce_Configurations) {
				psECommConfig = perm.id;
			} else if (perm.Name == Label.Manage_E_commerce_Margins) {
				psECommMargin = perm.id;
			} else {
				psECommGroups = perm.id;
			}
		}
		System.debug(psECommConfig+psECommMargin+psECommGroups);
		final Integer three = 3; //NOSONAR
        if(psECommerce.size() == three) {
            final Set<Id> usersToMargin = new Set<Id>();
            final Set<Id> usersToPlatform = new Set<Id>();
            final Set<Id> usersToGroup = new Set<Id>();
            for (User newUser : newList) {
                if (newUser.isActive && newUser.UserType == standardS && newUser.Disable_ECommerce_Margin__c) {
                    usersToMargin.add(newUser.Id);
				}
                if (newUser.isActive && newUser.UserType == standardS && newUser.Disable_ECommerce_Configuration__c) {
                    usersToPlatform.add(newUser.Id);
				}
                if (newUser.isActive && newUser.UserType == standardS && newUser.Disable_ECommerce_Group__c) {
                    usersToGroup.add(newUser.Id);
				}
            }

            if (!usersToMargin.isEmpty() && psECommMargin!=null) {
               UserLogic.assignPermissionSet(psECommMargin,usersToMargin);
            }
            if (!usersToPlatform.isEmpty() && psECommConfig!=null) {
               UserLogic.assignPermissionSet(psECommConfig,usersToPlatform);
            }
            if (!usersToGroup.isEmpty() && psECommGroups!=null) {
               UserLogic.assignPermissionSet(psECommGroups,usersToGroup);
            }

        } else {
            System.debug(Logginglevel.INFO,'>>>>>>> No se encontra el PermissionSet con Name: ' + Label.DES_Name_PermissionSet_Chatter);
        }
        timesExecuted ++;
    }


	/**
	*
	* @author Global Desktop
	*
	*/
    public void checkUpdateECommercePermissionSet(final List<User> newList,final Map<Id,User> oldLMap) {
        system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger User (checkUpdateChatterPermissionSet)');
		String standardS = '';
		standardS = 'Standard';//NOSONAR

        final List<PermissionSet> psECommerce = [SELECT Id, Name FROM PermissionSet WHERE Name = :Label.Manage_E_commerce_Configurations OR Name = :Label.Manage_E_commerce_Groups OR Name = :Label.Manage_E_commerce_Margins LIMIT 3];
		String psECommMargin;
		String psECommConfig;
		String psECommGroups;
		for(PermissionSet perm: psECommerce) {
			if(perm.Name == Label.Manage_E_commerce_Configurations) {
				psECommConfig = perm.id;
			} else if (perm.Name == Label.Manage_E_commerce_Margins) {
				psECommMargin = perm.id;
			} else {
				psECommGroups = perm.id;
			}
		}

        if(psECommerce.size() == 3) { //NOSONAR

            final Set<Id> usersAddMargin = new Set<Id>();
            final Set<Id> usersDelMargin = new Set<Id>();

            final Set<Id> usersAddPlatform = new Set<Id>();
            final Set<Id> usersDelPlatform = new Set<Id>();

            final Set<Id> usersAddGroup = new Set<Id>();
            final Set<Id> usersDelGroup = new Set<Id>();


            for (User newUser : newList) {
                //usersToBeAssigned
                if ( (newUser.UserType == standardS && newUser.isActive && !oldLMap.get(newUser.id).isActive && newUser.Disable_ECommerce_Margin__c) || (newUser.UserType == standardS && newUser.isActive && newUser.Disable_ECommerce_Margin__c && !oldLMap.get(newUser.id).Disable_ECommerce_Margin__c) ) {
                    usersAddMargin.add(newUser.Id);
                }

                //usersToBeRemoved
                if ( (!newUser.isActive && oldLMap.get(newUser.id).isActive) || (newUser.isActive && !newUser.Disable_ECommerce_Margin__c && oldLMap.get(newUser.id).Disable_ECommerce_Margin__c) ) {
                    usersDelMargin.add(newUser.Id);
                }

                //usersToBeAssigned
                if ( (newUser.UserType == standardS && newUser.isActive && !oldLMap.get(newUser.id).isActive && newUser.Disable_ECommerce_Configuration__c) || (newUser.UserType == standardS && newUser.isActive && newUser.Disable_ECommerce_Configuration__c && !oldLMap.get(newUser.id).Disable_ECommerce_Configuration__c) ) {
                    usersAddPlatform.add(newUser.Id);
                }

                //usersToBeRemoved
                if ( (!newUser.isActive && oldLMap.get(newUser.id).isActive) || (newUser.isActive && !newUser.Disable_ECommerce_Configuration__c && oldLMap.get(newUser.id).Disable_ECommerce_Configuration__c) ) {
                    usersDelPlatform.add(newUser.Id);
                }

                //usersToBeAssigned
                if ( (newUser.UserType == standardS && newUser.isActive && !oldLMap.get(newUser.id).isActive && newUser.Disable_ECommerce_Group__c) || (newUser.UserType == standardS && newUser.isActive && newUser.Disable_ECommerce_Group__c && !oldLMap.get(newUser.id).Disable_ECommerce_Group__c) ) {
                    usersAddGroup.add(newUser.Id);
                }

                //usersToBeRemoved
                if ( (!newUser.isActive && oldLMap.get(newUser.id).isActive) || (newUser.isActive && !newUser.Disable_ECommerce_Group__c && oldLMap.get(newUser.id).Disable_ECommerce_Group__c) ) {
                    usersDelGroup.add(newUser.Id);
                }

            }
            //usersToBeAssigned
            if (!usersAddMargin.isEmpty() && psECommMargin!=null) {
                UserLogic.assignPermissionSet(psECommMargin,usersAddMargin); //usersToBeAssigned
            }

            //usersToBeRemoved
            if (!usersDelMargin.isEmpty() && psECommMargin!=null) {
                UserLogic.removePermissionSet(psECommMargin,usersDelMargin);  //usersToBeRemoved
            }

            //usersToBeAssigned
            if (!usersAddPlatform.isEmpty() && psECommConfig!=null) {
                UserLogic.assignPermissionSet(psECommConfig,usersAddPlatform); //usersToBeAssigned
            }

            //usersToBeRemoved
            if (!usersDelPlatform.isEmpty() && psECommConfig!=null) {
                UserLogic.removePermissionSet(psECommConfig,usersDelPlatform);  //usersToBeRemoved
            }

            //usersToBeAssigned
            if (!usersAddGroup.isEmpty() && psECommGroups!=null) {
                UserLogic.assignPermissionSet(psECommGroups,usersAddGroup); //usersToBeAssigned
            }

            //usersToBeRemoved
            if (!usersDelGroup.isEmpty() && psECommGroups!=null) {
                UserLogic.removePermissionSet(psECommGroups,usersDelGroup);  //usersToBeRemoved
            }


        } else {
            System.debug(Logginglevel.INFO,'>>>>>>> No se encuentra el PermissionSet con Name: ' + Label.DES_Name_PermissionSet_Chatter);
        }
        timesExecuted ++;
    }

	/**
	*
	* @author Global Desktop
	*
	*/
    public void checkAssignECommercePermissionSetByRole(final List<User> newList) {
		system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger User (checkAssignECommercePermissionSetByRole)');
		List<String> roles;
		roles = getRoles();
        checkEsales(newList, roles);
        timesExecuted ++;
	}

	/**
	*
	* @author Global Desktop
	*
	*/
    public void checkUpdateECommercePermissionSetByRole(final List<User> newList,final Map<Id,User> oldLMap) {
        system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger User (checkUpdateECommercePermissionSetByRole)');
		List<String> roles;
		roles = getRoles();
		system.debug('roles'+roles);
		for(User oldUser : oldLMap.values()) {
			for(User newUser : newList) {
				if(oldUser.Id == newUser.Id && oldUser.UserRoleId != newUser.UserRoleId) {
					checkRole(newUser, oldUser, roles);
				}
			}
	   }
        timesExecuted ++;
    }

	private void checkEsales(List<User> newList, List<String> roles) {
		String standardS = '';
		standardS = 'Standard';//NOSONAR
		System.debug(standardS);
        for(User newUser : newList) {
			if (newUser.isActive && (newUser.UserType == standardS || Test.isRunningTest())&& newUser.UserRoleID == roles[0]) { //NOSONAR
				newUser.Disable_ECommerce_Margin__c = true;
			} else if (newUser.isActive && (newUser.UserType == standardS  || Test.isRunningTest()) && roles.contains(newUser.UserRoleID)) { //NOSONAR
				newUser.Disable_ECommerce_Margin__c = true;
				newUser.Disable_ECommerce_Configuration__c = true;
				newUser.Disable_ECommerce_Group__c = true;
			}
       }
	}

	private List<String> getRoles() {
		final List<UserRole> userRoleList = [SELECT Id, Name FROM UserRole WHERE Name =: SOPORTEROL OR Name = 'GLOBAL MARKETS ECOMMERCE SALES' LIMIT 2];
		Set<Id> roles;
		roles = new Set<Id>();
		List<String> rolesDevolver;
		rolesDevolver = new List<String>();
		String eSales = '';
		String soporte = '';
		Set<Id> roleSales;
		roleSales = new Set<Id>();
		for(UserRole rol : userRoleList) {
			if(rol.Name == SOPORTEROL) {
				soporte = rol.Id;
			} else {
				eSales = rol.Id;
				roleSales.add(rol.Id);
			}
		}
		final Set<Id> roleSalesHijos = getAllSubRoleIds(roleSales);
		roles.add(soporte);
		roles.add(eSales);
		roles.addAll(roleSalesHijos);
        for(Id rol : roles) {
        	rolesDevolver.add(rol);//NOSONAR
        }
		return rolesDevolver;
	}

    private static Set<Id> getAllSubRoleIds(Set<ID> roleIds) {
        Set<Id> currentRoleIds;
        currentRoleIds = new Set<Id>();
        for(UserRole userRole : [SELECT Id FROM UserRole WHERE ParentRoleId IN :roleIds AND ParentRoleID != null]) {   //NOSONAR
            currentRoleIds.add(userRole.Id);
        }
        if(!currentRoleIds.isEmpty()) {
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }
            return currentRoleIds;
    }

	private void checkRole(User newUser, User oldUser, List<String> roles) {
		System.debug('Entro al check rol---------->');
		System.debug('oldUser---------->'+oldUser.UserRoleId);
		System.debug('newUser---------->'+newUser.UserRoleId);
		if(roles.contains(oldUser.UserRoleId) && !roles.contains(newUser.UserRoleId)) {
			newUser.Disable_ECommerce_Margin__c = false;
			newUser.Disable_ECommerce_Configuration__c = false;
			newUser.Disable_ECommerce_Group__c = false;
		} else if(oldUser.UserRoleId == roles[0] && roles.contains(newUser.UserRoleId)) {
			newUser.Disable_ECommerce_Configuration__c = true;
			newUser.Disable_ECommerce_Group__c = true;
		} else if(roles.contains(oldUser.UserRoleId) && newUser.UserRoleId == roles[0]) {
			newUser.Disable_ECommerce_Configuration__c = false;
			newUser.Disable_ECommerce_Group__c = false;
		} else if(!roles.contains(oldUser.UserRoleId) && newUser.UserRoleId == roles[0]) {
			newUser.Disable_ECommerce_Configuration__c = false;
			newUser.Disable_ECommerce_Group__c = false;
			newUser.Disable_ECommerce_Margin__c = true;
		} else if(!roles.contains(oldUser.UserRoleId) && roles.contains(newUser.UserRoleId) && newUser.UserRoleId != roles[0]) {
			newUser.Disable_ECommerce_Margin__c = true;
			newUser.Disable_ECommerce_Configuration__c = true;
			newUser.Disable_ECommerce_Group__c = true;
		}
	}

    public void borrarGruposUsuario(Map<Id, User> triggerNewMap) {
    	Map<Id, Group> mapGroups = new Map<Id, Group>([
    					SELECT Id
    					FROM Group
    					WHERE DeveloperName LIKE '%Legal%'
    	]);

    	List<GroupMember> listaGM = new List<GroupMember>([
    					SELECT Id
    					FROM GroupMember
    					WHERE UserOrGroupId IN :triggerNewMap.keySet() AND GroupId IN :mapGroups.keySet()
    	]);

    	system.debug('>>>>> listaGM : ' + listaGM);

    	delete listaGM;
    }


  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   manage the mailing group association for EGS users

    IN:        Map<Id, User> triggerNewMap, Map<Id, User> triggerOldMap
    OUT:       Void

    History:
    <Date>            <Author>            <Change Description>
    11/06/2020      Cintia Carmona         Initial Version
  ---------------------------------------------------------------------------------------*/
	public void gestionUsuariosEGS(Map<Id, User> triggerNewMap, Map<Id, User> triggerOldMap) {
		final Set<Id> setNewEGSUsers = new Set<Id>();
		final Set<Id> setUpdateEGSUsers = new Set<Id>();
		final Id profileIdStandar = [SELECT Id FROM Profile WHERE Name = 'Service Standard User EGS' LIMIT 1].Id;
		final Id profileIdManager = [SELECT Id FROM Profile WHERE Name = 'Service Client Service Manager EGS' LIMIT 1].Id;
		final Id profileIdTech = [SELECT Id FROM Profile WHERE Name = 'Service Technical User EGS' LIMIT 1].Id;

		for(User usr : triggerNewMap.values()) {
			final boolean userNewEGS = (usr.ProfileId == profileIdManager || usr.ProfileId == profileIdStandar || usr.ProfileId == profileIdTech) // ES UN USUARIO CON PEFIL EGS
							&& triggerOldMap == null; //Y ES UN USUARIO NUEVO CON PERFIL EGS
			final boolean userUpdateEGS = (usr.ProfileId == profileIdManager || usr.ProfileId == profileIdStandar || usr.ProfileId == profileIdTech) // ES UN USUARIO CON PEFIL EGS
								  && triggerOldMap != null   //Y ES UN USUARIO QUE AHORA ES EGS
								  && triggerOldMap.get(usr.Id).ProfileId != profileIdStandar
							 	  && triggerOldMap.get(usr.Id).ProfileId != profileIdManager
								  && triggerOldMap.get(usr.Id).ProfileId != profileIdTech;

			if (userNewEGS) {
				setNewEGSUsers.add(usr.Id);
			} else if(userUpdateEGS) {
				setUpdateEGSUsers.add(usr.Id);
			}
		}

		if(!setNewEGSUsers.isEmpty()) {
			insertMailingGroup(setNewEGSUsers);
		}

		if(!setUpdateEGSUsers.isEmpty()) {
			updateMailingGroup(setUpdateEGSUsers);
		}
}

  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   insert the associated mailing group for a new EGS user

    IN:        Map<Id, User> triggerNewMap, Map<Id, User> triggerOldMap
    OUT:       Void

    History:
    <Date>            <Author>            <Change Description>
    11/06/2020      Cintia Carmona         Initial Version
  ---------------------------------------------------------------------------------------*/
	@future
    private static void insertMailingGroup(Set<Id> setNewEGSUsers) {

		final List<SER_MailingGroup__c> listMGtoInsert = new List<SER_MailingGroup__c>();

		for(Id idUser : setNewEGSUsers) {
			SER_MailingGroup__c mailingGroup;
			mailingGroup = new SER_MailingGroup__c();
			mailingGroup.SER_User__c = idUser;
			mailingGroup.SER_MailingGroup__c = 'EGS';
			mailingGroup.SER_DefaultMailbox__c = 'Global Client Service GCS';
			mailingGroup.SER_AvailableMailboxes__c = 'Global Client Service GCS;Global Client Service GNC';
			listMGtoInsert.add(mailingGroup);
		}

		system.debug('::::: listMGtoInsert : ' + listMGtoInsert);
		if(!listMGtoInsert.isEmpty()) {
			insert listMGtoInsert;
		}
	}

  /*---------------------------------------------------------------------------------------
    Company:       BBVA.
    Description:   update the associated mailing group for a EGS user

    IN:        Map<Id, User> triggerNewMap, Map<Id, User> triggerOldMap
    OUT:       Void

    History:
    <Date>            <Author>            <Change Description>
    11/06/2020      Cintia Carmona         Initial Version
  ---------------------------------------------------------------------------------------*/
	@future
    private static void updateMailingGroup(Set<Id> usersEGS) {

		final Map<Id,SER_MailingGroup__c> mapaMG = new Map<Id,SER_MailingGroup__c>();

		final List<SER_MailingGroup__c> listMGtoUpdate = [SELECT Id, SER_User__c, SER_MailingGroup__c, SER_DefaultMailbox__c
						  									FROM SER_MailingGroup__c WHERE SER_User__c IN :usersEGS];

    	if(!listMGtoUpdate.isEmpty()) {
	    	for(SER_MailingGroup__c mg:listMGtoUpdate) {
        		mapaMG.put(mg.SER_User__c, mg);
      		}
      	}

      	final List<SER_MailingGroup__c> listMGEGS = new List<SER_MailingGroup__c>();

		for(Id idUser : usersEGS) {
      		final SER_MailingGroup__c mgAct = mapaMG.get(idUser);
      		final boolean existeMG = mgAct != null;
      		if(existeMG) {
				mgAct.SER_MailingGroup__c = 'EGS';
				mgAct.SER_DefaultMailbox__c = 'Email EGS';
				listMGEGS.add(mgAct);
			}
		}

		system.debug('::::: listMGEGS : ' + listMGEGS);
		if(!listMGEGS.isEmpty()) {
			update listMGEGS;
		}
	}


    public void setUserGroup(List<User> triggerNew) {
    	List<GroupMember> listGroupMembers = new List<GroupMember>();
    	//Mapa que contiene como key el nombre api de la picklist Legal Entity de user y como value el grupo correspondiente
    	Map<String, Group> mapGroups = new Map<String, Group>();
    	for(Group g : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName LIKE '%Legal%']) {
			mapGroups.put(g.DeveloperName, g);
    	}

    	system.debug('>>>>> mapGroups : ' + mapGroups);
    	for(User us : triggerNew) {
    		system.debug('>>>>> us.Entity_name__c : ' + us.Entity_name__c);
    		if(us.Entity_name__c != null) {
    			if(us.Entity_name__c.contains(';')) {
    				for(String lglEntity : us.Entity_name__c.split(';')) {
	    				system.debug('>>>>> lglEntity : ' + lglEntity);
	    				system.debug('>>>>> mapGroups : ' + mapGroups);
	    				system.debug('>>>>> mapGroups.get(lglEntity) : ' + mapGroups.get(Util_PickList.getLabelFromAPI('User', 'Entity_name__c').get(lglEntity)));
	    				if(mapGroups.get(lglEntity) != null
	    				|| mapGroups.get(Util_PickList.getLabelFromAPI('User', 'Entity_name__c').get(lglEntity)) != null) {
	    					GroupMember gm = new GroupMember();
				    		gm.UserOrGroupId = us.Id;
				    		if(mapGroups.get(lglEntity) != null) {
				    			gm.GroupId = mapGroups.get(lglEntity).Id;
				    		} else if(mapGroups.get(Util_PickList.getLabelFromAPI('User', 'Entity_name__c').get(lglEntity)) != null) {
				    			gm.GroupId = mapGroups.get(Util_PickList.getLabelFromAPI('User', 'Entity_name__c').get(lglEntity)).Id;
				    		}

				    		system.debug('>>>>> gm.GroupId : ' + gm.GroupId);
				    		listGroupMembers.add(gm);
	    				} else {
	    					us.addError('No existe el grupo ' + lglEntity + ' correspondiente al usuario ' + us.Name);
	    				}
	    			}
    			} else {
    				GroupMember gm = new GroupMember();
		    		gm.UserOrGroupId = us.Id;
					system.debug('>>>>> mapGroups : ' + mapGroups);
		    		system.debug('>>>>> mapGroups.get(us.Entity_name__c) : ' + mapGroups.get(Util_PickList.getLabelFromAPI('User', 'Entity_name__c').get(us.Entity_name__c)));
		    		if(mapGroups.get(us.Entity_name__c) != null
		    		|| mapGroups.get(Util_PickList.getLabelFromAPI('User', 'Entity_name__c').get(us.Entity_name__c)) != null) {
		    			if(mapGroups.get(us.Entity_name__c) != null) {
			    			gm.GroupId = mapGroups.get(us.Entity_name__c).Id;
			    		} else if(mapGroups.get(Util_PickList.getLabelFromAPI('User', 'Entity_name__c').get(us.Entity_name__c)) != null) {
			    			gm.GroupId = mapGroups.get(Util_PickList.getLabelFromAPI('User', 'Entity_name__c').get(us.Entity_name__c)).Id;
			    		}

			    		system.debug('>>>>> gm.GroupId : ' + gm.GroupId);
			    		listGroupMembers.add(gm);
		    		} else {
    					us.addError('No existe el grupo ' + us.Entity_name__c + ' correspondiente al usuario ' + us.Name);
    				}

    			}

    		}
    	}

    	try {
    		insert listGroupMembers;
    	} catch(Exception e) {
    		system.debug('>>>>> EXCEPTION : ' + e);
    	}
    }//FIN setUserGroup


		/*
		 *	Global Desktop
		 *	Función que gestiona los usuarios de Sindicación
		 *
		**/
		/* public void manageSindicationUsers(List<User> triggerNew, Map<Id, User> triggerOldMap) {
			final List<PermissionSetAssignment> listPermSetToAdd = new List<PermissionSetAssignment>();
			final List<PermissionSetAssignment> listPermSetToDlt = new List<PermissionSetAssignment>();
			final Id permSetManageSoldOrder = [SELECT Id FROM PermissionSet WHERE Name = :Label.PERMISSION_SET_MANAGE_SOLD_ORDER LIMIT 1].Id;
			final Map<String, Id> mapPermAssignId = new Map<String, Id>();
			if(triggerOldMap != null) {//Si es update recojo en un mapa la asignacion de permissions sets
				for(PermissionSetAssignment permSetAss : [SELECT Id, PermissionSet.Name, AssigneeId
																								FROM PermissionSetAssignment
																								WHERE AssigneeId IN :triggerOldMap.keySet() AND PermissionSetId = :permSetManageSoldOrder]) {
					mapPermAssignId.put(permSetAss.AssigneeId + '_' + permSetAss.PermissionSetId, permSetAss.Id);
				}
			}


			if(permSetManageSoldOrder != null) {
				for(User usr : triggerNew) {
					//Si el usuario tiene marcado el check de Sindication User y es inserción o antes no lo tenia marcado
					if(usr.gf_user_syndicated_ind_type__c && (triggerOldMap == null || !triggerOldMap.get(usr.Id).gf_user_syndicated_ind_type__c)) {
						listPermSetToAdd.add(assignPermissionSet(usr, permSetManageSoldOrder));//le asigno el permission set de Manage Sold orders
					} else if(!usr.gf_user_syndicated_ind_type__c && triggerOldMap != null && triggerOldMap.get(usr.Id).gf_user_syndicated_ind_type__c) { //Si es modificación y deja de tener el check
						listPermSetToDlt.add(deletePermissionSet(usr, mapPermAssignId.get(usr.Id + '_' + permSetManageSoldOrder)));
					}
				}
			}


			system.debug('::::: listPermSetToAdd: ' + listPermSetToAdd);
			if(!listPermSetToAdd.isEmpty()) {
				insert listPermSetToAdd;
			}
			system.debug('::::: listPermSetToDlt: ' + listPermSetToDlt);
			if(!listPermSetToDlt.isEmpty()) {
				delete listPermSetToDlt;
			}

		} */
	//FIN manageSindicationUsers


		/*
		 *	Global Desktop
		 *	Función que gestiona los usuarios de Sindicación
		 *
		**/
		public PermissionSetAssignment assignPermissionSet(User usr, Id permissionSetId) {
			// final List<PermissionSetAssignment> listPermSet = new List<PermissionSetAssignment>();
			final PermissionSetAssignment permSetAssign = new PermissionSetAssignment (PermissionSetId = permissionSetId, AssigneeId = usr.Id);
			system.debug('::::: permSetAssign: ' + permSetAssign);
			return permSetAssign;
		}

		/*
		 *	Global Desktop
		 *	Función que gestiona los usuarios de Sindicación
		 *
		**/
		public PermissionSetAssignment deletePermissionSet(User usr, Id permSetAssToDlt) {
			// final List<PermissionSetAssignment> listPermSet = new List<PermissionSetAssignment>();
			final PermissionSetAssignment permSetAssign = new PermissionSetAssignment (Id = permSetAssToDlt);
			system.debug('::::: permSetAssign: ' + permSetAssign);
			return permSetAssign;
		}

		/*
		 *	CuCo CIB
		 *	Función para incluir/excluir a usuarios del grupo público y Permission Set de CuCo
		 *  según el Campo en User gf_manage_cuco__c, provisto por CES
		 *
		**/
		/* public void cucoManagementPG (List<User> triggerNew, Map<Id, User> triggerOldMap) {
			final Set<Id> userId = new Set<Id>();
			final List<PermissionSetAssignment> lstPSToAdd = new List<PermissionSetAssignment>();
			final List<PermissionSetAssignment> lstPSToDelete = new List<PermissionSetAssignment>();
			final Map<String, Id> mapPermAssignId = new Map<String, Id>();
			final Set<ID> setUserOrGroupId = new Set<Id>();
			final Set<ID> setUsers = new Set<Id>();
			final Group cucoGroup = [SELECT Id FROM Group WHERE DeveloperName =: System.Label.CucoNIFClient LIMIT 1];
			final List<GroupMember> gmlist = [SELECT Id, UserOrGroupId FROM GroupMember WHERE GroupId =: cucoGroup.Id];
			final Id psManageCuCo = [SELECT Id FROM PermissionSet WHERE Name =: System.Label.Manage_CuCo LIMIT 1].Id;

			if(triggerOldMap != NULL) {
				for(PermissionSetAssignment permSetAss : [SELECT Id, PermissionSet.Name, AssigneeId FROM PermissionSetAssignment
														WHERE AssigneeId IN :triggerOldMap.keySet() AND PermissionSetId = :psManageCuCo]) {
															mapPermAssignId.put(permSetAss.AssigneeId + '_' + permSetAss.PermissionSetId, permSetAss.Id);
														}
			}
			for(GroupMember member : gmlist) {
				userId.add(member.UserOrGroupId);
			}

			for(User usr : triggerNew) {
				switch on getCucoInfo(usr,userId) {
					when '10' {
						setUsers.add(usr.id);
						if(psManageCuCo != NULL && !mapPermAssignId.containsKey(usr.Id + '_' + psManageCuCo)) {
							lstPSToAdd.add(assignPermissionSet(usr, psManageCuCo));
						}
					} when '11' {
						if(psManageCuCo != NULL && !mapPermAssignId.containsKey(usr.Id + '_' + psManageCuCo)) {
							lstPSToAdd.add(assignPermissionSet(usr, psManageCuCo));
						}
					} when '01' {
						setUserOrGroupId.add(usr.id);
						if (psManageCuCo != NULL && mapPermAssignId.containsKey(usr.Id + '_' + psManageCuCo)) {
							lstPSToDelete.add(deletePermissionSet(usr, mapPermAssignId.get(usr.Id + '_' + psManageCuCo)));
						}
					} when '00' {
						if (psManageCuCo != NULL && mapPermAssignId.containsKey(usr.Id + '_' + psManageCuCo)) {
							lstPSToDelete.add(deletePermissionSet(usr, mapPermAssignId.get(usr.Id + '_' + psManageCuCo)));
						}
					}
				}
			}

			if(!setUsers.isEmpty()) {
				putGroupMember(setUsers,cucoGroup.Id);
			}
			if(!lstPSToAdd.isEmpty()) {
				insert lstPSToAdd;
			}
			if(!setUserOrGroupId.isEmpty()) {
				deleteGroupMember(setUserOrGroupId,cucoGroup.Id);
			}
			if(!lstPSToDelete.isEmpty()) {
				delete lstPSToDelete;
			}
		} */

		/*
		 *	CuCo CIB
		 *	Función para incluir/excluir a usuarios del grupo público y Permission Set de CuCo
		 *  según el Campo en User gf_manage_cuco__c, provisto por CES
		 *
		**/
		/* public String getCucoInfo(User usr, Set<Id> userId) {
			String info; // gf_manage_cuco__c = true (1), gf_manage_cuco__c = false (0), userId.contains = true (1), userId.contains= false (0)
			if(usr.isActive && usr.gf_manage_cuco__c && !userId.contains(usr.Id)) {
				info = '10';
			} else if(usr.isActive && !usr.gf_manage_cuco__c && userId.contains(usr.Id)) {
				info = '01';
			} else if(usr.isActive && usr.gf_manage_cuco__c && userId.contains(usr.Id)) {
				info = '11';
			} else if(usr.isActive && !usr.gf_manage_cuco__c && !userId.contains(usr.Id)) {
				info = '00';
			}
			return info;
		}
 */
		/*
		 *	CuCo CIB
		 *	Función para incluir a usuarios en el grupo público
		 *  según el Campo en User gf_manage_cuco__c, provisto por CES
		 *
		**/
		/* public static void putGroupMember(Set<ID> setUsers, Id groupId) {
			List<GroupMember> listGroupMember = new List<GroupMember>();
			for (Id usr : setUsers) {
				GroupMember groupM = new GroupMember();
				groupM.GroupId = groupId;
				groupM.UserOrGroupId = usr;
				listGroupMember.add(groupM);
			}
			Database.SaveResult[] srList = Database.insert(listGroupMember, false);
			// Iterate through each returned result
			for (Database.SaveResult sr : srList) {
				if (!sr.isSuccess()) {
					// Operation failed. Get all errors
					for(Database.Error err : sr.getErrors()) {
						System.debug(err.getStatusCode() + err.getMessage());
					}
				}
			}
		} */

		/*
		 *	CuCo CIB
		 *	Función para excluir a usuarios del grupo público
		 *  según el Campo en User gf_manage_cuco__c, provisto por CES
		 *
		**/
		/* public static void deleteGroupMember(Set<ID> setUserOrGroupId, Id groupId) {
			List<GroupMember> listGroupMember = new List<GroupMember>();
			listGroupMember = [SELECT Id FROM GroupMember WHERE UserOrGroupID in :setUserOrGroupId and GroupId =: groupId];
			if(!listGroupMember.isEmpty()) {
				delete listGroupMember;
			}
		} */

		/*
		 *	Función para eliminar Opp. Team members y volver a crearlos al resactivar usuarios
		 *  Esto evita incidencias de permisos al desactivar y reactivar usuarios
		 *
		**/
		@future
		public static void handleReactivatedUsers(Set<Id> userIds) {
			// Obtener Opp. Team Members
			List<DES_Opportunity_Management_member__c> existingTeamMembers = [
				SELECT Id, DES_Opportunity__c, DES_User__c, DES_BBVA_Opportunity_Role__c, DES_Opportunity_member_role__c, DES_Scope__c, DES_PS_Product_Family__c,
				DES_PS_Product__c, DES_Owner__c, Name, DES_Tipo_de_cobertura__c
				FROM DES_Opportunity_Management_member__c
				WHERE DES_User__c IN :userIds and DES_Opportunity__r.IsClosed = false
			];

			// Se eliminan los Opportunity Team Members existentes
			if (!existingTeamMembers.isEmpty()) {
				delete existingTeamMembers;
			}

			// Volver a crear los Opp. Team Members
			List<DES_Opportunity_Management_member__c> newTeamMembers = new List<DES_Opportunity_Management_member__c>();
			for (DES_Opportunity_Management_member__c otm : existingTeamMembers) {
				DES_Opportunity_Management_member__c newOtm = new DES_Opportunity_Management_member__c(
					DES_Opportunity__c = otm.DES_Opportunity__c,
					DES_User__c = otm.DES_User__c,
					DES_Scope__c = otm.DES_Scope__c,
					DES_PS_Product_Family__c = otm.DES_PS_Product_Family__c,
					DES_PS_Product__c = otm.DES_PS_Product__c,
					DES_Owner__c = otm.DES_Owner__c,
					Name = otm.Name,
					DES_Opportunity_member_role__c = otm.DES_Opportunity_member_role__c,
					DES_Tipo_de_cobertura__c = otm.DES_Tipo_de_cobertura__c
				);
				newTeamMembers.add(newOtm);
			}

			if (!newTeamMembers.isEmpty()) {
				insert newTeamMembers;
			}
		}

 }