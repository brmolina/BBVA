/**
 *
 * Alejandro del Rio
 */
public with sharing class CurrentUserInfoCtrl {
    /**
     *
     * Alejandro del Rio
     */
     private CurrentUserInfoCtrl() {}
    /**
     *
     * Alejandro del Rio
     */
   @AuraEnabled
    public static user fetchUser() {
        try {
            return [select Id, Profile.Name FROM User Where id =: userInfo.getUserId()];
        } catch(Exception e) {
			throw new AuraHandledException(Label.DES_Error + e);
		}
    }
    /**
     * Met0d0 que devuelve un boolean dependiendo si el usuario cumple alguno de los requisitos para ver la tab de BBVA Business
     */
    @AuraEnabled
    public static Boolean legalLogicUser(String profile,string recordId) {
        boolean validation= false;
        final Map<String, String> maptype = getcountry();//NOSONAR
        final Map<String, String> maptypeAcc = getcountryAcc();//NOSONAR
        final Set<Id> setIdChildRoles = new Set<Id>();//NOSONAR
        final Set<Id> setIdChilds = new Set<Id>();
        Map<Id, User> mapUsersChildRole = new Map<Id, User>();
        Final list<String> accountsIDs= new list<string>();
        accountsIDs.add(recordId);
        boolean hiecValidation=false;
        final List<BBVA_business_validations__mdt> batchParams =new List<BBVA_business_validations__mdt>([SELECT DeveloperName, MasterLabel from BBVA_business_validations__mdt  WHERE DeveloperName =:profile LIMIT 1]);
        if(!batchParams.isEmpty() && batchParams !=null) {
            Final User userInfo=[Select Id,Profile.Name,DES_Country__c,UserRoleId from User Where id =:userinfo.getUserId() limit 1];
            accountsIDs.addAll(getgroup(accountsIDs));
            Final Account AccountInfo=[select id,DES_Country__c, DES_Country_Client__c from Account Where id in:accountsIDs limit 1];
            setIdChilds.add((Id)userInfo.UserRoleId);
            setIdChildRoles.addAll(getroles(setIdChilds));
            mapUsersChildRole = DES_RoleUtils.getAllUserWithRoles(setIdChildRoles);
            Final List<Id> memberMap=getBBVAMember(accountsIDs);
            Final Set <Id> memberset = new Set<Id>();
            memberset.addAll(memberMap);
            Final boolean boosProfiles = getProfile(mapUsersChildRole.values(),profile,maptypeAcc.get(AccountInfo.DES_Country_Client__c));
          	hiecValidation=hiecvali(mapUsersChildRole,memberset);
            if((userInfo.Profile.name.contains(profile) && maptypeAcc.get(AccountInfo.DES_Country_Client__c)==maptype.get(userInfo.DES_Country__c) ) || memberMap.contains(userInfo.Id) || hiecValidation==true || boosProfiles==true) {
                validation=true;
            }
        } else {
            validation=true;
        }
        return validation;
    }
    /**
     * Met0d0 que devuelve el valor de la picklist DES_Country_Client__c de Account
     */
    public static Map<String, String> getcountryAcc() {
		final Map<String, String> mapPicklist = new Map<String, String>();
		final Schema.DescribeFieldResult fieldResult = Account.DES_Country_Client__c.getDescribe();
		final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple) {
			mapPicklist.put(pickListVal.getValue(), pickListVal.getLabel());
		}
		return mapPicklist;
	}
    /**
     * Met0d0 que devuelve el valor de la picklist DES_Country__c de User
     */
    public static Map<String, String> getcountry() {
		final Map<String, String> mapPicklist = new Map<String, String>();
		final Schema.DescribeFieldResult fieldResult = User.DES_Country__c.getDescribe();
		final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple) {
			mapPicklist.put(pickListVal.getValue(), pickListVal.getLabel());
		}
		return mapPicklist;
	}
    /**
     * Met0d0 que devuelve los BBVA members del grupo
     */
    public static List<Id> getBBVAMember(list<id> recordId) {
  		Final List<Id> memberMap = new List<Id>();
		Final List<DES_BBVA_Management_team__c> membersBBVA=new List<DES_BBVA_Management_team__c>([SELECT id, Name, CreatedBy.Profile.Name, DES_Client__c, DES_User__c from DES_BBVA_Management_team__c where DES_Client__c =:recordId]);
        system.debug('membersBBVA :' +membersBBVA);
        for(DES_BBVA_Management_team__c member : membersBBVA) {
            system.debug('test memberMap :' +memberMap);
            system.debug('test member :' +member);
            if(!memberMap.isEmpty() || !memberMap.contains(member.DES_User__c) ) {
                memberMap.add(member.DES_User__c);
            }
        }
        return memberMap;
    }
    /**
     * Met0d0 que valida si el perfil del usuario es del tipo de producto seleccionado
     */
    public static boolean getProfile(list<User> profilss,string perfile, String country) {
        boolean validation= false;
        final Map<String, String> maptype = getcountry();//NOSONAR
        for(User lol:[Select Id,name,profile.name,DES_Country__c from User where id in:profilss]) {
            if(lol.profile.name.contains(perfile) && country==maptype.get(lol.DES_Country__c) ) {
              validation=true;
            }
        }
		return validation;
	}
    /**
     * Met0d0 que valida si el usuario es tiene algun usuario por debajo en roles que lo pueda ver
     */
    public static boolean hiecvali(Map<Id, User>  mapUsersChildRole,Set <Id> memberset) {
        boolean validation= false;
        for(User idsss :mapUsersChildRole.values()) {
        	if(memberset.contains(idsss.id)) {
            	validation= true;
            }
        }
        return validation;
	}
    /**
     * Met0d0 que devuelve el grupo asociado, si tiene
     */
    public static List<Id> getgroup(list<id> accountsIDs) {
        Final list<String> accounts= new list<string>();
        for(DES_Subsidiary_Group_Relation__c gsm : [SELECT participant_child_id__c, participant_parent_id__c FROM DES_Subsidiary_Group_Relation__c WHERE participant_child_id__c in :accountsIDs AND main_subsidiary_ind_type__c = true]) {
        	accounts.add(gsm.participant_parent_id__c);
    	}
        return accounts;
    }
    /**
     * Met0d0 que devuelve los roles que tienen por debajo
     */
    public static Set<Id> getroles(Set<Id> setIdChilds) {
        Set<Id> setIdChildRoles = new Set<Id>();//NOSONAR
        Set<Id> setIdsRoles = new Set<Id>();//NOSONAR
        Integer cont=0;//NOSONAR
        do {
                        //Set<Id> setIdsRoles = new Set<Id>();
                    //	system.debug('>>>>> cont : ' + cont);
                        if(cont >= 10) {
                            break;
                            }
                        //system.debug('>>>>> setIdChilds : ' + setIdChilds);
                        //system.debug('>>>>> setIdChildRoles : ' + setIdChildRoles);

                        if(setIdsRoles.isEmpty()) {
                            setIdsRoles = DES_RoleUtils.getAllSubRoleIds(setIdChilds);

                        } else {
                            setIdsRoles = DES_RoleUtils.getAllSubRoleIds(setIdsRoles);
                        }
                        setIdChildRoles.addAll(setIdsRoles);
                        cont++;
                    } while(!setIdsRoles.isEmpty());
        return setIdChildRoles;
    }
}