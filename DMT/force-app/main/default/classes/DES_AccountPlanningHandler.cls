/**
* @author       Global Desktop
* @date         05/07/2019
* @description  Handler del trigger de Account Planning con los mét0d0s que aplican sólo a funcionalidad dentro de Global Desktop
* @Revision
* Version   Date            Author          Summary of changes
* ----------------------------------------------------------------------------------
* 0.1        2019/11/08      JSS            Modificada query método copyAPTeamFromGroup para recuperar solo los 'Global Banker'
*                                           Añadido método checkAPperiod
*                                           Añadido método setFieldsBeforeInsert
*                                           Añadidos mét0d0s para que después de insertar un AP se cree la estructura del Business Plan
*                                           (BP, Version, Items...) relacionado con dicho AP.
* 0.2       2021/02/25      ICG             [Irene y Víctor] Cambios relacionados con la incidencia del chatter. Al usar la clase local de 
*                                           blockUnblockAP hay que modificar para adaptarlo al paquete 3.4 de AP
* 0.2       2021/02/25      GDT             [Ander] Revertir los cambios en el método blockUnblockAPaux para que no se tengan en cuenta los 
*                                           en las notificaciones enviadas.
*                                            
*/
public without sharing class DES_AccountPlanningHandler {

    /*instance*/
    public static DES_AccountPlanningHandler instance;


    /*
    * @author       Global Desktop
    * @Description  Constructor
    */
    private DES_AccountPlanningHandler() {
        System.debug('CONSTRUCTOR');
    }

    /*
    * @author       Global Desktop
    * @Description  getInstance
    */
    public static DES_AccountPlanningHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new DES_AccountPlanningHandler();
        }
        return instance;
    }

    /*
    * @author       Global Desktop
    * @Description  Inserts the global banker in the AP team
    */
    public void copyAPTeamFromGroup(List<acpl__Account_Planning__c> triggernew) {
        final Set<Id> accountSet = new Set<Id>();
        final Map<Id, acpl__Account_Planning__c> accountAPMap = new Map<Id, acpl__Account_Planning__c>();
        for(acpl__Account_Planning__c apAux : triggernew) {
            accountSet.add(apAux.acpl__participant_id__c);
            accountAPMap.put(apAux.acpl__participant_id__c, apAux);
        }
        final List<DES_BBVA_Management_team__c> bbvaTeamList = [SELECT Id, DES_User__c, DES_Member_Role__c, DES_Client__c, DES_Local_Banker_Country__c, DES_PS_Product_Family__c FROM DES_BBVA_Management_team__c WHERE DES_Client__c IN :accountSet AND DES_Member_Role__c = :Label.DES_ROLE_GLOBAL_BANKER];
        List<bupl__AP_Team__c> apTeamList;
        apTeamList = new List<bupl__AP_Team__c>();

        for(DES_BBVA_Management_team__c bbvaMAux : bbvaTeamList) {
            bupl__AP_Team__c apTeamAux;
            apTeamAux = new bupl__AP_Team__c();
            apTeamAux.acpl__gf_account_planning_id__c = accountAPMap.get(bbvaMAux.DES_Client__c).Id;
            apTeamAux.bupl__gf_ap_team_user_id__c = bbvaMAux.DES_User__c;
            apTeamAux.bupl__gf_ap_team_role_user_name__c = bbvaMAux.DES_Member_Role__c;
            apTeamAux.bupl__country_id__c = bbvaMAux.DES_Local_Banker_Country__c;
            apTeamAux.bupl__solution_category_type__c = bbvaMAux.DES_PS_Product_Family__c;
            apTeamAux.bupl__gf_ap_team_new_member_date__c = Date.TODAY();
            apTeamList.add(apTeamAux);
        }
        insert apTeamList;

        /*final Set<Id> apSet = new Set<Id>();
        for(Account_Planning__c apAux : triggernew) {
            apSet.add(apAux.Id);
        }
        Map<Id, Account_Planning__c> apMap = new Map<Id, Account_Planning__c>([SELECT Id, participant_id__r.DES_Global_banker__c FROM Account_Planning__c where Id IN : apSet]);
        List<AP_Team__c> apTeam = new List<AP_Team__c>();
        for(Account_Planning__c apAux : apMap.values()) {
            if(apAux.participant_id__r.DES_Global_banker__c != null) {
                AP_Team__c apTeamAux = new AP_Team__c();
                apTeamAux.gf_account_planning_id__c = apAux.Id;
                apTeamAux.gf_ap_team_user_id__c = apAux.participant_id__r.DES_Global_banker__c;
                apTeam.add(apTeamAux);
                apAux.AA_Global_banker_id__c = apAux.participant_id__r.DES_Global_banker__c;
            }
        }
        System.debug('apTeam: ' + apTeam);
        if(!apTeam.isEmpty()) {
            update apMap.values();
            insert apTeam;
        }*/

    } //FIN de insertGBinTeam


    /*
    * @author       Global Desktop
    * @Description  Si el perfil del usuario es distinto de los permitidos, se llama al met0d0 que chequea si se puede editar el Account Plannings
    */
    public void checkAPperiod(List<acpl__Account_Planning__c> triggerNew, Map<Id, acpl__Account_Planning__c> triggerOldMap) {
        final String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].get(0).Name;
        final List<PermissionSetAssignment> permissionSetList = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name = :Label.AP_Admin_Permission_Set];
        System.debug('>>>>>> Dentro método DES_AccountPlanningHandler.checkAPperiod -> perfil usuario: ' + profileName);
        if (profileName != LABEL.DES_ADMIN_PROFILE && profileName != Label.DES_INTEGRATION_PROFILE && profileName != Label.DES_AP_ADMIN_PROFILE && permissionSetList.isEmpty()) {
            final acpl.AccountPlanningHandler apHandler = acpl.AccountPlanningHandler.getInstance();
            apHandler.checkAPperiod(triggerNew, triggerOldMap);
        }
    } //FIN de checkAPperiod

    /*
    * @author       Global Desktop
    * @Description  Si el perfil del usuario es AP Admin, se llama al met0d0 que envía notificación si se (des)bloquea un AP
    */
    public void blockUnblockAP(List <acpl__Account_Planning__c> triggerNew, Map<Id, acpl__Account_Planning__c> triggerOldMap) {
        final String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].get(0).Name;
        final List<PermissionSetAssignment> permissionSetList = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name = :Label.AP_Admin_Permission_Set];
        System.debug('>>>>>> Dentro método DES_AccountPlanningHandler.blockUnblockAP -> perfil usuario: ' + profileName);
        if (profileName == LABEL.DES_AP_ADMIN_PROFILE || !permissionSetList.isEmpty()) {
            //final acpl.AccountPlanningHandler apHandler = acpl.AccountPlanningHandler.getInstance();
            blockUnblockAPaux(triggerNew, triggerOldMap);
        }
    } //FIN de blockUnblockAP

    /*
    * @author       Global Desktop
    * @Description  Enables or disables the edition of the account plannings individually
    */
    public void blockUnblockAPaux(List<acpl__Account_Planning__c> triggernew, Map<Id, acpl__Account_Planning__c> triggerOldMap) {
        System.debug('dentro de blockUnblockAPaux');
        Set<Id> apSet;
        apSet = new Set<Id>();
        for(acpl__Account_Planning__c apAux : triggernew) {
            //si se ha actualizado el check de bloqueo/desbloqueo, me guardo los AP para buscar su equipo
            if(apAux.acpl__gf_ap_indvi_lock_edit_ind_type__c != triggerOldMap.get(apAux.Id).acpl__gf_ap_indvi_lock_edit_ind_type__c) {
                apSet.add(apAux.Id);
            }
        }
        if(!apSet.isEmpty()) {
            final Map<Id, bupl__AP_Team__c> apTeamMap = getTeamMap(apSet);
            if(!apTeamMap.isEmpty()) {
                final Set<Id> userIdSet_blockUnblock = new Set<Id>();
                String clientName = '';
                boolean unlock = false;

                for(bupl__AP_Team__c apTeamAux : apTeamMap.values()) {
                    if(!userIdSet_blockUnblock.contains(apTeamAux.bupl__gf_ap_team_user_id__c)) {
                        userIdSet_blockUnblock.add(apTeamAux.bupl__gf_ap_team_user_id__c);
                        unlock = apTeamAux.acpl__gf_account_planning_id__r.acpl__gf_ap_indvi_lock_edit_ind_type__c;
                        clientName = apTeamAux.acpl__gf_account_planning_id__r.acpl__participant_id__r.Name;
                    }
                }
                System.debug('userIdSet_blockUnblock: ' + userIdSet_blockUnblock);

                if(triggernew.size() == 1) {
                    individualBlockUnblock(userIdSet_blockUnblock, unlock, clientName);
                } else {
                    final List<Batches_Process_Parameters__mdt> batchParams = new List<Batches_Process_Parameters__mdt>([SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = 'MassiveBlockUnblockAPBatch' LIMIT 1]);
                    final MassiveBlockUnblockAPBatch massiveAPBatch = new MassiveBlockUnblockAPBatch();
                    massiveAPBatch.BatchParameters(userIdSet_blockUnblock,unlock);
                    database.executebatch(massiveAPBatch,(Integer)batchParams[0].Batch_Size__c );

                    //massiveBlockUnblock(userIdSet_blockUnblock, unlock);
                }
            }
        }
    } //FIN de blockUnblockAPaux


        /*
    * @author       Global Desktop
    * @Description  Sends chatter notifications to ONE ap team
    */
    public void individualBlockUnblock(Set<Id> userIdSet_blockUnblock, boolean unlock, String clientName) {
        System.debug('bloqueo individual ');
        for(ID apTeamIdAux : userIdSet_blockUnblock) {
            if(unlock) {
                System.debug('bloqueo individual - unlock');
                Desktop_Utils_aux.generarPostChatter(apTeamIdAux, clientName + ' ' + Label.acpl.Unlock_Account_Plan);
            } else {
                System.debug('bloqueo individual - lock');
                Desktop_Utils_aux.generarPostChatter(apTeamIdAux, clientName + ' ' + Label.acpl.Lock_Account_Plan);
            }
        }
    }

    /*
    * @author       Global Desktop
    * @Description  Sends chatter notifications to ap team
    */
    public void massiveBlockUnblock(Set<Id> userIdSet_blockUnblock, boolean unlock) {
        System.debug('bloqueo masivo ');
        // recojo el registro de configuración y envío notificaciones con el mensaje definido
        final List<AP_notif__c> apPeriod = [SELECT Id, gf_admin_notif_lock_mgr_desc__c, gf_admin_notif_unlock_mgr_desc__c FROM AP_notif__c LIMIT 1];
        for(ID apTeamIdAux : userIdSet_blockUnblock) {
            if(unlock) {
                System.debug('bloqueo masivo - unlock');
                Desktop_Utils_aux.generarPostChatter(apTeamIdAux, apPeriod.get(0).gf_admin_notif_unlock_mgr_desc__c);
            } else {
                System.debug('bloqueo masivo - lock');
                Desktop_Utils_aux.generarPostChatter(apTeamIdAux, apPeriod.get(0).gf_admin_notif_lock_mgr_desc__c);
            }
        }
    }
    /*
    * @author       Service banker tools 
    * @Description  Clase que recoge los usuarios para ser notificados, in incluir los que tienen el chatter desactivado.
    *               Revisión para paquete 3.4 problema del chatter
    */
    public Map<Id, bupl__AP_Team__c> getTeamMap(Set<Id> apSet) {
        final Map<Id, bupl__AP_Team__c> apTeamMap = new Map<Id, bupl__AP_Team__c>([SELECT Id, bupl__gf_ap_team_user_id__c, acpl__gf_account_planning_id__c, acpl__gf_account_planning_id__r.acpl__gf_ap_indvi_lock_edit_ind_type__c, acpl__gf_account_planning_id__r.acpl__participant_id__r.Name
                                                                                    FROM bupl__AP_Team__c WHERE acpl__gf_account_planning_id__c IN :apSet
                                                                                    AND bupl__gf_ap_team_user_id__r.DES_Disable_Chatter__c = false
                                                                                    AND bupl__gf_ap_team_user_id__r.IsActive = true]);
        return apTeamMap;
    }


    /*
    * @author       Global Desktop
    * @Description  Fill needed fields data from Group before insert
    */
    public void setFieldsBeforeInsert(List<acpl__Account_Planning__c> triggernew) {
        Set<Id> listAccountid = new Set<Id>();
        for (acpl__Account_Planning__c ap : triggernew) {
            listAccountid.add(ap.acpl__participant_id__c);
        }

        Map<Id,Account> mapGroups = new Map<Id, Account>([Select Id, DES_Country_of_Management__c, DES_Segment__c, DES_Subsegment__c, DES_Tier__c From Account Where id IN :listAccountid]);
        for (acpl__Account_Planning__c ap : triggernew) {
           ap.gf_ap_mgmt_country_type_name__c = (mapGroups.containsKey(ap.acpl__participant_id__c)? mapGroups.get(ap.acpl__participant_id__c).DES_Country_of_Management__c : '');
           ap.industry_type__c = (mapGroups.containsKey(ap.acpl__participant_id__c)? mapGroups.get(ap.acpl__participant_id__c).DES_Subsegment__c : '');
           ap.tier_desc__c = (mapGroups.containsKey(ap.acpl__participant_id__c)? Util_Picklist.getLabelFromAPI('Account','DES_Tier__c').get(mapGroups.get(ap.acpl__participant_id__c).DES_Tier__c) : '');
        }

    }

    /*
    * @author       Global Desktop
    * @Description  Create the structure of the BP (BP, BP version, VP item...) related to the Account Planning
    */
    public void initRelatedBP(List<acpl__Account_Planning__c> triggerNew) {
        final List<bupl__BusinessPlan__c> listBP = new List<bupl__BusinessPlan__c>();
        for (acpl__Account_Planning__c ap : triggerNew) {
            final bupl__BusinessPlan__c newBP = new bupl__BusinessPlan__c(
                Name = ap.Name,
                acpl__gf_account_planning_id__c = ap.Id,
                bupl__participant_id__c = ap.acpl__participant_id__c,
                bupl__gf_ap_public_ind_type__c = true,
                //status_type__c = ap.gf_ap_status_type_name__c,
                CurrencyIsoCode = ap.CurrencyIsoCode
            );
            listBP.add(newBP);

        }

        if (!listBP.isEmpty()) {
            insert listBP;
        }
    }

    /*
    * @author       Global Desktop
    * @Description  Updates the account planning evend date
    */
    public void updateEventDate(List<acpl__Account_Planning__c> triggernew, Map<Id, acpl__AP_PeriodConfiguration__c> triggerOldMap) {
        //final List<AP_PeriodConfiguration__c> apConfigList = [SELECT Id, gf_ap_edit_days_left_number__c FROM AP_PeriodConfiguration__c LIMIT 1];
        final Set<Id> accountSet = new Set<Id>();
        for(acpl__Account_Planning__c apAux : triggernew) {
            accountSet.add(apAux.acpl__participant_id__c);
         /*   if(apConfigList.get(0).AA_Event__c == '' || apConfigList.get(0).AA_Event__c == null) {
                apAux.gf_event_date__c = null;
            }else if(apConfigList.get(0).AA_Event__c == 'PF renewal date') {
                accountSet.add(apAux.participant_id__c);
            }*/
        }
        System.debug('accountSet: ' + accountSet);
        if(!accountSet.isEmpty()) {
            final Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, DES_PF_RENEWAL_DATE__c FROM Account WHERE Id IN : accountSet]);

            for(acpl__Account_Planning__c apAux : triggernew) {
                if(accountMap.get(apAux.acpl__participant_id__c) != null) {
                    apAux.acpl__gf_event_date__c = accountMap.get(apAux.acpl__participant_id__c).DES_PF_RENEWAL_DATE__c;
                }
            }
        }
        if(triggerOldMap != null) {
            update triggernew;
        }

    } //FIN de updateEventDate

    /*
    * @author       Global Desktop
    * @Description
    */
    public void createShareValidator(Map<Id, acpl__Account_Planning__c> triggerNewMap, Map<Id, acpl__Account_Planning__c> triggerOldMap) {

        //GENERO UN MAPA QUE TIENE COMO KEY EL ID DEL ACCOUNT PLAN Y COMO VALUE EL ID DEL BUSINESS PLAN
        final Map<Id, Id> mapAccPlanBP = gtmapAccPlanBP(triggerNewMap);
        //GENERO UN MAPA QUE TIENE COMO KEY EL VALOR DEL AP Y COMO VALUE UN SET CON LOS ID'S DE LOS USUARIOS QUE FORMAN PARTE DEL EQUIPO DE AP
        final Set<String> setAPlanAPTUser = gtSetAPlanAPTUser(triggerNewMap.keySet());

        final Map<Id, Id> mapAccPlanUserId = new Map<Id, Id>();

        final List<acpl__Account_Planning__Share> listAPShareValidator = new List<acpl__Account_Planning__Share>();
        final List<bupl__BusinessPlan__Share> listBPShareValidtor = new List<bupl__BusinessPlan__Share>();

        final List<acpl__Account_Planning__Share> listAPShareDelete = new List<acpl__Account_Planning__Share>();
        final List<bupl__BusinessPlan__Share> listBPShareDelete = new List<bupl__BusinessPlan__Share>();


        for(acpl__Account_Planning__c accPlan : triggerNewMap.values()) {
            //Si es modificación y se ha cambiado el validador, compruebo si tengo que borrar los permisos del antiguo validador

            //SI ES INSERT
            if(triggerOldMap == null //SI ES INSERT
                && accPlan.acpl__gf_ap_validator_user_id__c != null) { //Y EL VALIDADOR NO ES NULL
                //Doy permisos
                if(Desktop_Utils_aux.newManualSharingAccountPlanning(accPlan.Id, accPlan.acpl__gf_ap_validator_user_id__c, 'Edit') != null) {
                    listAPShareValidator.add(Desktop_Utils_aux.newManualSharingAccountPlanning(accPlan.Id, accPlan.acpl__gf_ap_validator_user_id__c, 'Edit'));
                }
                system.debug('::::: listAPShareValidator AA : ' + listAPShareValidator);
                if(mapAccPlanBP.get(accPlan.Id) != null
                    && Desktop_Utils_aux.newManualSharingBusinessPlan(mapAccPlanBP.get(accPlan.Id), accPlan.acpl__gf_ap_validator_user_id__c, 'Edit') != null) {
                    listBPShareValidtor.add(Desktop_Utils_aux.newManualSharingBusinessPlan(mapAccPlanBP.get(accPlan.Id), accPlan.acpl__gf_ap_validator_user_id__c, 'Edit'));
                }
            }//fin si es insert

            //SI ES UPDATE
            if((triggerOldMap != null  // SI ES ACTUALIZACION
                && accPlan.acpl__gf_ap_validator_user_id__c != triggerOldMap.get(accPlan.Id).acpl__gf_ap_validator_user_id__c )) {//Y EL VALIDADOR HA CAMBIADO
                //Si el validador antiguo no está como miembro en el equipo de AP borro la share del usuario
                if(triggerOldMap.get(accPlan.Id).acpl__gf_ap_validator_user_id__c != null
                    && !setAPlanAPTUser.contains(accPlan.Id + '_' + triggerOldMap.get(accPlan.Id).acpl__gf_ap_validator_user_id__c)) {
                    mapAccPlanUserId.put(accPlan.Id, triggerOldMap.get(accPlan.Id).acpl__gf_ap_validator_user_id__c);
                }
                if(accPlan.acpl__gf_ap_validator_user_id__c != null) {
                    //Doy permisos
                    if(Desktop_Utils_aux.newManualSharingAccountPlanning(accPlan.Id, accPlan.acpl__gf_ap_validator_user_id__c, 'Edit') != null) {
                        listAPShareValidator.add(Desktop_Utils_aux.newManualSharingAccountPlanning(accPlan.Id, accPlan.acpl__gf_ap_validator_user_id__c, 'Edit'));
                    }
                    system.debug('::::: listAPShareValidator AA : ' + listAPShareValidator);
                    if(mapAccPlanBP.get(accPlan.Id) != null
                        && Desktop_Utils_aux.newManualSharingBusinessPlan(mapAccPlanBP.get(accPlan.Id), accPlan.acpl__gf_ap_validator_user_id__c, 'Edit') != null) {
                        listBPShareValidtor.add(Desktop_Utils_aux.newManualSharingBusinessPlan(mapAccPlanBP.get(accPlan.Id), accPlan.acpl__gf_ap_validator_user_id__c, 'Edit'));
                    }
                }

            }//fin si es update

        }//FIN FOR

        for(acpl__Account_Planning__Share accPlanShare : [SELECT Id, UserOrGroupId, ParentId
                                                            FROM acpl__Account_Planning__Share
                                                            WHERE UserOrGroupId IN :mapAccPlanUserId.values() AND ParentId IN :mapAccPlanUserId.keySet() AND RowCause = :Schema.acpl__Account_Planning__Share.RowCause.Manual]) {
            if(mapAccPlanUserId.get(accPlanShare.ParentId) == accPlanShare.UserOrGroupId) {
                listAPShareDelete.add(accPlanShare);
            }
        }
        system.debug('::::: listAPShareDelete : ' + listAPShareDelete);
        for(bupl__BusinessPlan__Share busPlanShare : [SELECT Id, UserOrGroupId, ParentId, Parent.acpl__gf_account_planning_id__c
                                                            FROM bupl__BusinessPlan__Share
                                                            WHERE UserOrGroupId IN :mapAccPlanUserId.values() AND Parent.acpl__gf_account_planning_id__c IN :mapAccPlanUserId.keySet() AND RowCause = :Schema.bupl__BusinessPlan__Share.RowCause.Manual]) {
            if(mapAccPlanUserId.get(busPlanShare.Parent.acpl__gf_account_planning_id__c) == busPlanShare.UserOrGroupId) {
                listBPShareDelete.add(busPlanShare);
            }
        }
        insrtAndDelete(listAPShareValidator, listBPShareValidtor, listAPShareDelete, listBPShareDelete);

    } //FIN de updateEventDate

    /*
    * @author       Global Desktop
    * @Description  Funcion que se encarga de insertar y borrar los shares correspondiens
    */
    public void insrtAndDelete(List<acpl__Account_Planning__Share> listAPShareValidator, List<bupl__BusinessPlan__Share> listBPShareValidtor,
                                List<acpl__Account_Planning__Share> listAPShareDelete, List<bupl__BusinessPlan__Share> listBPShareDelete) {
        system.debug('::::: listBPShareDelete : ' + listBPShareDelete);
        if(!listAPShareDelete.isEmpty()) {
            system.debug('::::: listAPShareDelete : ' + listAPShareDelete);
            delete listAPShareDelete;
        }
        if(!listBPShareDelete.isEmpty()) {
            system.debug('::::: listBPShareDelete : ' + listBPShareDelete);
            delete listBPShareDelete;
        }
        if(!listAPShareValidator.isEmpty()) {
            system.debug('::::: listAPShareValidator : ' + listAPShareValidator);
            insert listAPShareValidator;
        }
        if(!listBPShareValidtor.isEmpty()) {
            system.debug('::::: listBPShareValidtor : ' + listBPShareValidtor);
            insert listBPShareValidtor;
        }
    }



    /*
    * @author       Global Desktop
    * @Description  Funcion que devuelve el mapa con clave el id del accPlan y Key el id del BP relacionado
    */
    public Map<Id, Id> gtmapAccPlanBP(Map<Id, acpl__Account_Planning__c> triggerNewMap) {

        //GENERO UN MAPA QUE TIENE COMO KEY EL ID DEL ACCOUNT PLAN Y COMO VALUE EL ID DEL BUSINESS PLAN
        final Map<Id, Id> mapAccPlanBP = new Map<Id,Id>();
        for(bupl__BusinessPlan__c busPlan :[SELECT Id, acpl__gf_account_planning_id__c FROM bupl__BusinessPlan__c WHERE acpl__gf_account_planning_id__c IN :triggerNewMap.keySet()]) {
            mapAccPlanBP.put(busPlan.acpl__gf_account_planning_id__c, busPlan.Id);
        }
        system.debug('::::: mapAccPlanBP: ' + mapAccPlanBP);
        return mapAccPlanBP;
    } //FIN funcion


    /*
    * @author       Global Desktop
    * @Description  Funcion que devuelve un mapa con clave el Id del AP y como value un Set con el Id de los Usuarios que forman parte del equipo
    */
    public Set<String> gtSetAPlanAPTUser(Set<Id> setAccPlanIds) {
        final Set<String> setAPlanAPTUser = new Set<String>();
        for(bupl__AP_Team__c apTeamMember : [SELECT Id, acpl__gf_account_planning_id__c, bupl__gf_business_plan_id__c, bupl__gf_ap_team_user_id__c
                                            FROM bupl__AP_Team__c
                                            WHERE acpl__gf_account_planning_id__c IN :setAccPlanIds]) {
            setAPlanAPTUser.add(apTeamMember.acpl__gf_account_planning_id__c + '_' + apTeamMember.bupl__gf_ap_team_user_id__c);

        }

        system.debug('::::: setAPlanAPTUser: ' + setAPlanAPTUser);
        return setAPlanAPTUser;
    } //FIN funcion

    /*
    * @author       Global Desktop
    * @Description  Fill due date on Account Planning.
    */
    public void fillDueDate(List<acpl__Account_Planning__c> triggerNew, Map<Id, acpl__Account_Planning__c> triggerOldMap) {
        System.debug('dentro de fillDueDate');
        
        final List<acpl__AP_PeriodConfiguration__c> listAPPerConf = new List<acpl__AP_PeriodConfiguration__c>([SELECT Id, acpl__gf_ap_edit_prms_type_name__c, acpl__gf_ap_edit_days_left_number__c FROM acpl__AP_PeriodConfiguration__c LIMIT 1]);
        acpl__AP_PeriodConfiguration__c config;
        config = listAPPerConf.get(0);
        List<acpl__AP_Period__c> periodList = [SELECT Id, acpl__gf_ap_priority_edit_type__c, acpl__gf_ap_edit_end_date__c  FROM acpl__AP_Period__c];
        List<acpl__Account_Planning__c> apList;
        apList = new List<acpl__Account_Planning__c>();
        for(acpl__Account_Planning__c apQuery : triggerNew) {
            if(apQuery.acpl__gf_ap_substatus_type_name__c != Label.AP_Timed_Out) {
                apList.add(apQuery);
            }
        }
        
        if(config.acpl__gf_ap_edit_prms_type_name__c == 'General') {
            for(acpl__Account_Planning__c apAux : apList) {
                if(triggerOldMap == null) {
                    generalConfig(apAux, periodList, config);
                } else if(apAux.acpl__gf_ap_launch_name__c != triggerOldMap.get(apAux.Id).acpl__gf_ap_launch_name__c || apAux.acpl__gf_event_date__c != triggerOldMap.get(apAux.Id).acpl__gf_event_date__c) {
                    generalConfig(apAux, periodList, config);
                }
            } 
        } else if(config.acpl__gf_ap_edit_prms_type_name__c == 'Wave') {
            Map<String, Date> priorityDateMap;
            priorityDateMap = new Map<String, Date>();
            for(acpl__AP_Period__c periodAux : periodList) {
                priorityDateMap.put(periodAux.acpl__gf_ap_priority_edit_type__c, periodAux.acpl__gf_ap_edit_end_date__c);
            }
            for(acpl__Account_Planning__c apAux : apList) {
                if(triggerOldMap == null) {
                    periodConfig(apAux, priorityDateMap, config);
                } else if(apAux.acpl__gf_ap_launch_name__c != triggerOldMap.get(apAux.Id).acpl__gf_ap_launch_name__c || apAux.acpl__gf_event_date__c != triggerOldMap.get(apAux.Id).acpl__gf_event_date__c) {
                    periodConfig(apAux, priorityDateMap, config);
                }
            }
        } else {
            for(acpl__Account_Planning__c apAux : apList) {
                if(apAux.acpl__gf_ap_launch_name__c == 'Event driven') {
                    Date eventDrivenDate = calculateDate(apAux, config);
                	apAux.acpl__gf_ap_limit_date__c = eventDrivenDate;
                }
            }
        }
        
    }
    
    /*
    * @author       Global Desktop
    * @Description  Fill due date on Account Planning - general period
    */
    public void generalConfig(acpl__Account_Planning__c apAux, List<acpl__AP_Period__c> periodList, acpl__AP_PeriodConfiguration__c config){
        Date eventDrivenDate = calculateDate(apAux, config);
        
        if(apAux.acpl__gf_ap_launch_name__c == 'General period' && !periodList.isEmpty()) {
            apAux.acpl__gf_ap_limit_date__c = periodList.get(0).acpl__gf_ap_edit_end_date__c;
        } else if(apAux.acpl__gf_ap_launch_name__c == 'Event driven'  && !periodList.isEmpty()) {
            if(apAux.acpl__gf_event_date__c != null && periodList.get(0).acpl__gf_ap_edit_end_date__c < eventDrivenDate) { //si tiene fecha de evento y la configurada es menor que evento+dias
                apAux.acpl__gf_ap_limit_date__c = eventDrivenDate; //due date = evento+dias
            } else {
                apAux.acpl__gf_ap_limit_date__c = periodList.get(0).acpl__gf_ap_edit_end_date__c; //due date = la configurada
            }
        } else { //por prioridad -> due date = vacia
            apAux.acpl__gf_ap_limit_date__c = null; 
        }
    }
    
    /*
    * @author       Global Desktop
    * @Description  Fill due date on Account Planning - wave period
    */
    public void periodConfig(acpl__Account_Planning__c apAux, Map<String, Date> priorityDateMap, acpl__AP_PeriodConfiguration__c config) {
        System.debug('dentro de periodConfig');
        System.debug('apAux: ' + apAux);
        System.debug('priorityDateMap: ' + priorityDateMap);

        Date eventDrivenDate = calculateDate(apAux, config);
        
        if(apAux.acpl__gf_ap_launch_name__c == 'Period by wave' && !priorityDateMap.isEmpty() //PRIORITY
           && apAux.acpl__gf_ap_priority_type_name__c != '' //el AP tiene la prioridad rellena
           && priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c) != null) { //prioridad del AP configurada
               apAux.acpl__gf_ap_limit_date__c = priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c); //due date = la configurada
               
           } else if(apAux.acpl__gf_ap_launch_name__c == 'Event driven') {
               System.debug('Es event driven con configuración de prioridad');
               if(apAux.acpl__gf_ap_priority_type_name__c != '' && apAux.acpl__gf_ap_priority_type_name__c != null) { //EVENT DRIVEN y el AP tiene la prioridad rellena
                   System.debug('EVENT DRIVEN y el AP tiene la prioridad rellena');
                   if(priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c) != null) { //si prioridad configurada
                       System.debug('prioridad configurada');
                       if(apAux.acpl__gf_event_date__c != null && priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c) < eventDrivenDate) { //si tiene fecha de evento y la configurada es menor que evento+dias 
                           apAux.acpl__gf_ap_limit_date__c = eventDrivenDate; //due date = evento+dias
                       } else {
                           apAux.acpl__gf_ap_limit_date__c = priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c); //due date = la configurada
                       }
                   } if(apAux.acpl__gf_event_date__c != null) { //si tiene prioridad pero no está configurada y tiene evento
                       apAux.acpl__gf_ap_limit_date__c = eventDrivenDate;
                   }
               } else if(apAux.acpl__gf_event_date__c == null) { //si tiene la prioridad vacía y no tiene fecha de evento
                   apAux.acpl__gf_ap_limit_date__c = null;
               } else { //si tiene la prioridad vacía y tiene fecha de evento
                   System.debug('tiene la prioridad vacía y tiene fecha de evento');
                   apAux.acpl__gf_ap_limit_date__c = eventDrivenDate; 
               }
           } else { //por general o prioridad sin valores -> due date = vacia
               apAux.acpl__gf_ap_limit_date__c = null;
           }
    }
    
    /*
    * @author       Global Desktop
    * @Description  Calculates the evend driven date end
    */
    public Date calculateDate(acpl__Account_Planning__c apAux, acpl__AP_PeriodConfiguration__c config) {
        Integer numOfDays = 0;
        Date returnDate = null;
        if(config.acpl__gf_ap_edit_days_left_number__c != null) {
            numOfDays = (Integer)config.acpl__gf_ap_edit_days_left_number__c;
        }
        if(apAux.acpl__gf_event_date__c != null && apAux.acpl__gf_event_date__c < apAux.acpl__gf_event_date__c.addDays(numOfDays)) {
            returnDate = apAux.acpl__gf_event_date__c.addDays(numOfDays);
        } else if(apAux.acpl__gf_event_date__c != null && apAux.acpl__gf_event_date__c >= apAux.acpl__gf_event_date__c.addDays(numOfDays)) {
            returnDate = apAux.acpl__gf_event_date__c;
        }
        return returnDate;
    }
    
    /*
    * @author       Global Desktop
    * @Description  creates a group analysis if an AP has been validated
    */
    public void createGroupAnalysis(List<acpl__Account_Planning__c> triggerNew/*, Map<Id, acpl__Account_Planning__c> triggerOldMap*/) {
        List<DES_Group_Analysis__c> groupAnalysisList;
        groupAnalysisList = new List<DES_Group_Analysis__c>();
        for(acpl__Account_Planning__c apAux : triggerNew) {
            //if(apAux.acpl__gf_ap_status_type_name__c == Label.AP_Validated && triggerOldMap.get(apAux.Id).acpl__gf_ap_status_type_name__c != Label.AP_Validated) { 
			DES_Group_Analysis__c groupAnalysisAux;
			groupAnalysisAux = new DES_Group_Analysis__c();
			groupAnalysisAux.Name = apAux.Name;
			groupAnalysisAux.gf_account_planning_id__c = apAux.Id;
			groupAnalysisAux.participant_id__c = apAux.acpl__participant_id__c;
			groupAnalysisList.add(groupAnalysisAux);
            //}
        }
		if(!Test.isRunningTest()){
			insert groupAnalysisList;
		}
    }
    
    /*
    * @author       Global Desktop
    * @Description  updates last BP version validated to true
    */
    public void updateLastBPversion(List<acpl__Account_Planning__c> triggerNew, Map<Id, acpl__Account_Planning__c> triggerOldMap) {
        Set<Id> apSet;
        apSet = new Set<Id>();

        for(acpl__Account_Planning__c apAux : triggerNew) {
            System.debug('apAux.acpl__gf_ap_status_type_name__c: ' + apAux.acpl__gf_ap_status_type_name__c);
            System.debug('triggerOldMap.get(apAux.Id).acpl__gf_ap_status_type_name__c: ' + triggerOldMap.get(apAux.Id).acpl__gf_ap_status_type_name__c);
            if(apAux.acpl__gf_ap_substatus_type_name__c == Label.DES_AP_In_place && triggerOldMap.get(apAux.Id).acpl__gf_ap_substatus_type_name__c != Label.DES_AP_In_place) { 
                apSet.add(apAux.Id);
            }
        }
        System.debug('apSet: ' + apSet);
        if(!apSet.isEmpty()) {
            final List<bupl__BusinessPlan_Version__c> bpVersionList = [SELECT Id, Name, bupl__gf_bus_pl_lst_vldt_vr_ind_type__c, bupl__gf_business_plan_act_ind_type__c FROM bupl__BusinessPlan_Version__c
                                                                 WHERE bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c IN :apSet
                                                                 AND (bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true OR bupl__gf_business_plan_act_ind_type__c = 'Yes')];
            
            System.debug('bpVersionList query: ' + bpVersionList);
            //cambio la última versión validada por la nueva
            for(bupl__BusinessPlan_Version__c bpVersionAux : bpVersionList) {
                if(bpVersionAux.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c) {
                    bpVersionAux.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = false;
                } else if(bpVersionAux.bupl__gf_business_plan_act_ind_type__c == LABEL.acpl.YES) {
                    bpVersionAux.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true;
                    final String bpVersionName = bpVersionAux.Name.substringBefore('_');
                    bpVersionAux.Name = bpVersionName + '_Version_' + date.today().format();
                }
            }
            System.debug('bpVersionList to update: ' + bpVersionList);
            update bpVersionList;
        }
    }
    
    /*
    * @author       Global Desktop
    * @Description  Creates audit records
    */
    public void insertAudit(List<acpl__Account_Planning__c> triggerNew, Map<Id, acpl__Account_Planning__c> triggerOldMap) {
        final List<acpl__Account_Planning__c> apList = getAPauditList(triggerNew, triggerOldMap);
        if(!apList.isEmpty()) {
            final List<dwp_cvad__Action_Audit__c> actAudToInsert = new List<dwp_cvad__Action_Audit__c>();
            for (acpl__Account_Planning__c apAux : apList) {
                //final String audName = 'Account Planning approved by';
                final Id audUserId = apAux.LastModifiedById;
                //final String audStyle =  'approve';
                final dwp_cvad__Action_Audit__c newActAud = createActionAudit(apAux.Id, 'Account Planning approved by', audUserId, 'approve');
                actAudToInsert.add(newActAud);
            }
            if (!actAudToInsert.isEmpty()) {
        		final List<dwp_cvad__Action_Audit_Detail__c> actAudDetToInsert = new List<dwp_cvad__Action_Audit_Detail__c>();
                insert actAudToInsert;            
                for (dwp_cvad__Action_Audit__c aa : actAudToInsert) {
                    String detailContent = string.valueOf(date.today());
                    detailContent = 'Validation date: <b>' + detailContent + '</b>';
                    final dwp_cvad__Action_Audit_Detail__c newActAudDet = createActionAuditDetail(aa.Id, detailContent);
                    actAudDetToInsert.add(newActAudDet);
                }
                insert actAudDetToInsert;
            }
        }
    }
    
    /*
    * @author       Global Desktop
    * @Description  Get APs to insert audit
    */
    public static List<acpl__Account_Planning__c> getAPauditList(List<acpl__Account_Planning__c> triggerNew, Map<Id, acpl__Account_Planning__c> triggerOldMap) {
        List<acpl__Account_Planning__c> apList;
        apList = new List<acpl__Account_Planning__c>();
        for(acpl__Account_Planning__c apAux : triggerNew) {
            if(apAux.acpl__gf_ap_status_type_name__c == Label.AP_Validated && triggerOldMap.get(apAux.Id).acpl__gf_ap_status_type_name__c == Label.AP_Validated
               && apAux.acpl__gf_ap_substatus_type_name__c == Label.DES_AP_In_place && triggerOldMap.get(apAux.Id).acpl__gf_ap_substatus_type_name__c != Label.DES_AP_In_place
               && !apList.contains(apAux)) {
                apList.add(apAux);
            }
        }
        return apList;
    }

    /*
    * @author       Global Desktop
    * @Description  Create a record on Action Audit object.
    */
    public static dwp_cvad__Action_Audit__c createActionAudit(Id accountPlanningId, String auditName, Id auditUserId, String auditStyle) {
        return new dwp_cvad__Action_Audit__c(
            dwp_cvad__action_audit_date__c = Datetime.now(),
            dwp_cvad__action_audit_object_api_name__c = 'acpl__Account_Planning__c',
            dwp_cvad__action_audit_record_id__c = accountPlanningId,
            dwp_cvad__action_audit_style__c = auditStyle,
            dwp_cvad__action_audit_type__c = 'AccountPlanning',
            dwp_cvad__action_audit_name__c = auditName,
            dwp_cvad__action_audit_user_id__c = auditUserId
        	);
    }
    
    /*
    * @author       Global Desktop
    * @Description  Create a record on Auction Audit Details object.
    */
    public static dwp_cvad__Action_Audit_Detail__c createActionAuditDetail(Id actionAuditId, String detailContent) {
		return new dwp_cvad__Action_Audit_Detail__c(
            dwp_cvad__action_audit_detail_content_format__c = 'HTML',
            dwp_cvad__action_audit_detail_display_order__c = 1,
            dwp_cvad__action_audit_detail_display_type__c = 'Embedded',
            dwp_cvad__action_audit_detail_content__c = detailContent,
            dwp_cvad__action_audit_id__c = actionAuditId
        	);
    }
}