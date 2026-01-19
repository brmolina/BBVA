/*
* @author Global Desktop
* @Description: batch que lanza las notificaciones de las alertas insertadas/modificadas con la configuración del usuario
*/
public without sharing class DES_Batch_Commercial_Alert_Notify implements Database.Batchable<Sobject>, Database.Stateful{
	private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
	public static Map<Id, User> mapUsers = new Map<Id, User>();
	private static Map<Id, Account> mapAccounts = new Map<Id, Account>();
	private static Map<String, Boolean> mapUserPriority = new Map<String, Boolean>();
    private static Map<Id,Map<Id,Integer>> mapUserAgrupado = new Map<Id,Map<Id,Integer>>();
    private static List<ConnectApi.BatchInput> batchFeedItemInputs = new List<ConnectApi.BatchInput>();
    private static Map<Id, String> mapClientMembers = new Map<Id, String>();
    private static Map<Id, Id> mapGroupSubsidiary = new Map<Id, Id>();
    private static Set<Id> setIdsUsersNotifGeneral = new Set<Id>(); //Set de ID's de los usuarios que tendrán 1 ÚNICA notificacion general.

	/*
    private attributes
    */
	private Integer recordsProcessed = 0;
	/*
    private attributes
    */
	private String query = ''; //NOSONAR

	/*
	* @author Global Desktop
	* @Description: constructor
	*/
	public DES_Batch_Commercial_Alert_Notify(String type) {
        this.query = 'SELECT Id, Name, almd__User_id__c, almd__participant_id__c, OwnerId, almd__priority_alert_type__c,RecordTypeId,almd__commercial_alert_task_type__c  FROM almd__Commercial_Alert__c where CreatedDate = TODAY AND almd__commercial_alert_record_type__c = \'' + type + '\' AND (LastModifiedBy.Profile.Name =\'' + Label.DES_ADMIN_PROFILE + '\' OR LastModifiedBy.Profile.Name =\'' + Label.DES_INTEGRATION_PROFILE +'\')' + (Test.isRunningTest() ? ' LIMIT 1000' : '');
		System.debug('>>>>> Query: ' + query);
	}

		/*
	* @author Global Desktop
	* @Description: batchable method
	*/
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

	/*
	* @author Global Desktop
	* @Description: batch que lanza las notificaciones de las alertas insertadas/modificadas con la configuración del usuario
	*/
	public void execute(Database.BatchableContext bc, List<almd__Commercial_Alert__c> listCommAlert) {
		System.debug('>>>>> BATCH listCommAlert: ' + listCommAlert);
		generarNotificaciones(listCommAlert);
		System.debug('>>>>> batchFeedItemInputs.size() : ' + batchFeedItemInputs.size());
		if(batchFeedItemInputs.size() > 0 && !Test.isRunningTest()) {
			ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchFeedItemInputs);
		}
	}

	/*
	* @author Global Desktop
	* @Description: finish batch method
	*/
	public void finish(Database.BatchableContext bc) {
		AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

		System.debug('>>>>> SUMMARY: ');
		System.debug('>>>>>   Records Processed: ' + recordsProcessed);
		System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
		System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
		System.debug('>>>>>   Status: ' + job.Status);
	}

	/*
	* @author Global Desktop
	* @Description Funcion que guarda en un mapa los usuarios con sus campos necesarios
	y que devuelve un mapa el usuario con su nivel de prioridad marcada en check
	*/
    public static Map<String, Boolean> userPriorityInfo(List<almd__Commercial_Alert__c> triggerNew) {
        Set<Id> setIdsUsers = new Set<Id>();
        for(almd__Commercial_Alert__c commAlert : triggerNew) {
            //SI NO VIENE EL GESTOR, QUE SE VAYA AL CLIENTE Y NOTIFIQUE A LOS MIEMBROS DE LA CUENTA DE ESE CLIENTE RELACIONADO
            if(commAlert.almd__User_id__c == null) {
                setIdsUsers = givenUserNull(commAlert, setIdsUsers);
            }

			//User_id__c
            if(!setIdsUsers.contains(commAlert.almd__User_id__c)) {
                setIdsUsers.add(commAlert.almd__User_id__c);
            }

            //OwnerId
            if(!setIdsUsers.contains(commAlert.OwnerId)) {
                setIdsUsers.add(commAlert.OwnerId);
            }
        }

        //current user lo guardo siempre
        if(!setIdsUsers.contains(UserInfo.getUserId())) {
        	setIdsUsers.add(UserInfo.getUserId());
        }

        //Map<String, Boolean> mapUserPriority = new Map<String, Boolean>();
        mapUsers = new Map<Id, User>([SELECT Id, Name, DES_Disable_Chatter__c, almd__alert_notification_type__c, almd__notification_priority_high_type__c,
                                      almd__notification_priority_med_type__c, almd__notification_priority_low_type__c FROM User WHERE Id IN :setIdsUsers
                                      AND DES_Disable_Chatter__c = false AND isActive = true]);
        System.debug('>>>>> mapUsers : ' + mapUsers);
        for(User us : mapUsers.values()) {
            mapUserPriority.put(us.Id + Label.almd.Priority_High, us.almd__notification_priority_high_type__c);
            mapUserPriority.put(us.Id + Label.almd.Priority_Medium, us.almd__notification_priority_med_type__c);
            mapUserPriority.put(us.Id + Label.almd.Priority_Low, us.almd__notification_priority_low_type__c);
        }
        return mapUserPriority;
    }
	/*
	* @author Global Desktop
	* @Description Funcion que devuelve un set con los ids del cliente directo de la alerta y su padre principal
	*/
    public static Set<Id> getSetIdCuentas(List<almd__Commercial_Alert__c> triggerNew) {
        Set<Id> setIdsCuentas = new Set<Id>();
        for(almd__Commercial_Alert__c cAlert : triggerNew) {
            if(!setIdsCuentas.contains(cAlert.almd__participant_id__c)) {
                setIdsCuentas.add(cAlert.almd__participant_id__c);
            }
        }
        System.debug('@@setIdsCuentas' + setIdsCuentas);
        // recojo las matrix en las que las alertas son hijos
        List<DES_Subsidiary_Group_Relation__c> matrixAccountsList = new List<DES_Subsidiary_Group_Relation__c> ([
            SELECT Id, participant_parent_id__c, participant_child_id__c FROM DES_Subsidiary_Group_Relation__c WHERE participant_child_id__c IN :setIdsCuentas AND main_subsidiary_ind_type__c = true
        ]);
        // guardo los padres en el set que ya tengo
        for (DES_Subsidiary_Group_Relation__c idAux : matrixAccountsList) {
            setIdsCuentas.add(idAux.participant_parent_id__c);
            mapGroupSubsidiary.put(idAux.participant_child_id__c, idAux.participant_parent_id__c);
            System.debug('mapGroupSubsidiary ' + mapGroupSubsidiary);
        }
        System.debug('>>>>> setIdsCuentas : ' + setIdsCuentas);
        return setIdsCuentas;
    }

	/*
	* @author Global Desktop
	* @Description Funcion que obtiene los miembros de cuenta de un set de cuentas
	*/
    public static Map<Id, AccountTeamMember> getMapAccountMembers(Set<Id> setIdsCuentas) {
        return new Map<Id, AccountTeamMember>([
                    SELECT  Id,
                            UserId,
                            AccountId
                    FROM    AccountTeamMember
                    WHERE   AccountId IN :setIdsCuentas AND User.DES_Disable_Chatter__c = false]);
    }

    /*
	* @author Global Desktop
	* @Description Genero el mapa con los clientes y sus miembros de cuentas concatenados en el value
	*/
    public static void setMapClientMembers(Map<Id, AccountTeamMember> mapEquiposCuenta) {
        for(AccountTeamMember bbvaMT : mapEquiposCuenta.values()) {
            if(mapClientMembers.get(bbvaMT.AccountId) != null) {//Si el mapa contiene el cliente

                //Concateno en un string los id's de los usuarios que son miembros de las cuentas
                System.debug('>>>>> mapClientMembers.get(bbvaMT.AccountId): ' + mapClientMembers.get(bbvaMT.AccountId));
                String concat = mapClientMembers.get(bbvaMT.AccountId);
                if(!concat.contains(bbvaMT.UserId)) {
                    concat += ';' + bbvaMT.UserId;
                }
                mapClientMembers.put(bbvaMT.AccountId, concat);
            } else {
                mapClientMembers.put(bbvaMT.AccountId, (String)bbvaMT.UserId);
            }
            System.debug('>>>>> mapClientMembers.get(bbvaMT.AccountId): ' + mapClientMembers.get(bbvaMT.AccountId));
        }
    }

	/*
	* @author Global Desktop
	* @Description Envío de notificaciones al banker (si la alerta tiene banker),
	al equipo de cliente directo y grupo principal (si la alerta no tiene banker)
	y al owner
	*/
    public static void chooseNotify(almd__Commercial_Alert__c comAlert) {
        Set<String> idsUsers = new Set<String>();

        //si no viene banquero informado y es inserción, notifico al equipo de cuenta
        if(comAlert.almd__User_id__c == null) {
            manageStep0Notifications(comAlert, idsUsers);
        //si viene banquero informado, no es notificado por el equipo de cuenta y tiene chatter
        } else if(!idsUsers.contains(comAlert.almd__User_id__c) && mapUsers.get(comAlert.almd__User_id__c) != null) {
            manageStep2Notifications(comAlert);
        }

        // si el owner es distinto que el banquero, no es notificado por el equipo de cuenta y tiene chatter
        System.debug('si es inserción o el owner ha cambiado');
        if(comAlert.OwnerId != comAlert.almd__User_id__c && !idsUsers.contains(comAlert.OwnerId) && mapUsers.get(comAlert.OwnerId) != null) {
            manageStep3Notifications(comAlert);
        }

    }// FIN chooseNotify

    /*
	* @author Global Desktop
	* @Description Funcion que genera notificaciones por carga en función de prioridad y/o tipo de notificacion que elige el usuario
	*/
    public static void generarNotificaciones(List<almd__Commercial_Alert__c> triggerNew) {
	        //Set que tiene los id's de las cuentas de las alertas comerciales
	        Set<Id> setIdsCuentas = getSetIdCuentas(triggerNew);
	        System.debug('>>>>> setIdsCuentas : ' + setIdsCuentas);
	        //Guardo en el mapa las cuentas que tienen vinculadas alertas comerciales con los campos necesarios
	        getMapaAccounts(setIdsCuentas);
	        //Guardo los equipo se las cuentas relacionadas a las alertas comerciales
	        System.debug('>>>>> mapAccounts : ' + mapAccounts);
	        Map<Id, AccountTeamMember> mapEquiposCuenta = getMapAccountMembers(setIdsCuentas);
	        System.debug('>>>>> mapEquiposCuenta: ' + mapEquiposCuenta);
	        //Mapa que contiene el Id de la cuenta y un string que concatena los Id's de los usuarios que son miembros de las cuentas
	        setMapClientMembers(mapEquiposCuenta);

	        //Mapa con key 'idUsuario' + 'Prioridad' y con valor truo o false
	        Map<String, Boolean> mapUserPriority = new Map<String, Boolean>();
	        //Busco los campos del usuario necesarios para las validaciones
	        mapUserPriority = userPriorityInfo(triggerNew);
	        System.debug('>>>>> mapUserPriority :  ' + mapUserPriority);
	        //RECORRO EL TRIGGER NEW Y LLAMO A LAS FUNCIONES PARA DECIDIR DE QUE FORMA SE LE VA A NOTIFICAR A CADA UNO
	        for(almd__Commercial_Alert__c comAlert : triggerNew) {
	        	chooseNotify(comAlert);
	        }//FIN FOR TRIGGER NEW
	        //Si llego a este punto es que se ha terminado de recorrer el triggerNew,
	        //por lo que ya tengo los mapas preparados para el envío de notificación
	        System.debug('>>>>> mapUserAgrupado : ' + mapUserAgrupado);
	        System.debug('>>>>> setIdsUsersNotifGeneral : ' + setIdsUsersNotifGeneral);

	        //NOTIFICACION AGRUPADA
	        launchGroupedByClientNotification();

	        //NOTIFICACION GENERAL
	        launchOneGeneralNotification();

	        for(ConnectApi.BatchInput batch : Desktop_Utils.batchFeedItemInputs) {
	        	System.debug('batch: ' + batch);
	        }
	        if(!Desktop_Utils.batchFeedItemInputs.isEmpty() || !test.isRunningTest()) { //NOSONAR
	            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
	        }
    }//FIN generarNotificaciones

	/*
	* @author Global Desktop
	* @Description Funcion que genera el mensaje de notificaciones agrupadas por cliente
	*/
    public static void launchGroupedByClientNotification() {
        for(Id userId : mapUserAgrupado.keySet()) {
            String message = Label.almd.COMM_ALERT_NOTIF_AGRUPADA_1;
            Map<Id, Integer> clientNotif = mapUserAgrupado.get(userId);
            System.debug('>>>>> NA - userId : ' + userId);
            System.debug('>>>>> NA - clientNotif: ' + clientNotif);
            if(clientNotif != null) {
                for(Id clientId : clientNotif.keySet()) {
                    if(mapAccounts != null && mapAccounts.get(clientId) != null) {
                        System.debug('>>>>> NA - mapAccounts : ' + mapAccounts);
                        System.debug('>>>>> NA - clientNotif : ' + clientNotif);
                        System.debug('>>>>> NA - message : ' + message);
                        System.debug('>>>>> NA - clientId : ' + clientId);
                        message += '\n\t - ' + mapAccounts.get(clientId).Name + ': ' + clientNotif.get(clientId);
                    }
                }
                message += '\n' + Label.almd.COMM_ALERT_NOTIF_AGRUPADA_2;
                System.debug('>>>>> NA - message : ' + message);
                generarPostChatter(null, userId, message); //DEFINIR MENSAJE
            }
        }
    }//FIN launchGroupedByClientNotification

	/*
	* @author Global Desktop
	* @Description Funcion que genera el mensaje de 1 notificacion agrupada
	*/
    public static void launchOneGeneralNotification() {
        for(Id userId : setIdsUsersNotifGeneral) {
            if(mapUsers != null && mapUsers.get(userId) != null && mapUsers.get(userId).almd__alert_notification_type__c == Label.almd.COMM_ALERT_NOTIF_TYPE_ONE_GENERAL) {
                generarPostChatter(null, userId, Label.almd.COMM_ALERT_NOTIF_GENERAL); //DEFINIR MENSAJE
            }
        }
    }//FIN launchOneGeneralNotification

	/*
	* @author Global Desktop
	* @Description Funcion que genera el mensaje de notificaciones individuales
	*/
    public static String getIndividualMessage(String text, almd__Commercial_Alert__c comAlert) {
        String formMessage = text;
        if(formMessage.contains('%alertType%') && comAlert != null) {
            formMessage = formMessage.replaceAll('%alertType%', comAlert.almd__commercial_alert_task_type__c);
        }

        if(formMessage.contains('%clientName%') && comAlert != null && mapAccounts.get(comAlert.almd__participant_id__c) != null) {
            formMessage = formMessage.replaceAll('%clientName%', mapAccounts.get(comAlert.almd__participant_id__c).Name);
        }

        if(formMessage.contains('%notiName%') && comAlert != null) {
            formMessage = formMessage.replaceAll('%notiName%', comAlert.Name);
        }

        System.debug('>>>>> formMessage : ' + formMessage);
        return formMessage;
    }

	/*
	* @author Global Desktop
	* @Description Funcion que genera notificaciones individuales
	*/
    public static void notificacionIndividual(almd__Commercial_Alert__c comAlert, Id userId) {
        System.debug('>>>>> comAlert.Priority_Alert_Type__c : ' + comAlert.almd__Priority_Alert_Type__c);
        System.debug('>>>>> mapUserPriority.get(userId + comAlert.Priority_Alert_Type__c) : ' + mapUserPriority.get(userId + comAlert.almd__Priority_Alert_Type__c));
        //Notifico al usuario que va por el parametro userId
        if(comAlert.almd__Priority_Alert_Type__c != null
                && mapUserPriority.get(userId + comAlert.almd__Priority_Alert_Type__c)
                && comAlert.RecordTypeId != Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.almd.RT_COMM_ALERT_NOTIFICATION).getRecordTypeId()) {
            generarPostChatter(comAlert, userId, getIndividualMessage(Label.DES_MESSAGE_COMM_ALERT_NOTIF, comAlert)); //DEFINIR MENSAJE
        } else if(comAlert.almd__Priority_Alert_Type__c != null
                && mapUserPriority.get(userId + comAlert.almd__Priority_Alert_Type__c)
                && comAlert.RecordTypeId == Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.almd.RT_COMM_ALERT_NOTIFICATION).getRecordTypeId()) {
            generarPostChatter(comAlert, userId, getIndividualMessage(Label.almd.MESSAGE_NOTIFICATION, comAlert)); //DEFINIR MENSAJE
        }
    }//FIN notificacionIndividual

	/*
	* @author Global Desktop
	* @Description Funcion que genera notificaciones agrupadas por cliente
	*/
    public static void notificacionAgrupada(almd__Commercial_Alert__c comAlert, Id comAlUserId) {
        System.debug('>>>>> comAlert : ' + comAlert);
        if(mapUserAgrupado.get(comAlUserId) != null
        && mapUserPriority.get(comAlUserId + comAlert.almd__Priority_Alert_Type__c)) {//Si ya hay algun dato del usuario en el mapa
            System.debug('>>>>> User_id__c - mapUserAgrupado.get(comAlUserId)  : ' + mapUserAgrupado.get(comAlUserId) );
            if(mapUserAgrupado.get(comAlUserId).get(comAlert.almd__participant_id__c) != null) { //Si ese usuario ya tiene algun registro de ese cliente
                System.debug('>>>>> User_id__c -mapUserAgrupado.get(comAlUserId).get(comAlert.participant_id__c) : ' + mapUserAgrupado.get(comAlUserId).get(comAlert.almd__participant_id__c));
                //Sumo 1 a la notificacion de ese cliente
                Map<Id, Integer> mapaCliente = mapUserAgrupado.get(comAlUserId);
                Integer num = mapUserAgrupado.get(comAlUserId).get(comAlert.almd__participant_id__c);
                System.debug('>>>>> User_id__c -num : ' + num);
                num++;
                mapaCliente.put(comAlert.almd__participant_id__c, num);
                System.debug('>>>>> User_id__c -mapaCliente : ' + mapaCliente);
                mapUserAgrupado.put(comAlUserId, mapaCliente);
                System.debug('>>>>> User_id__c -mapUserAgrupado : ' + mapUserAgrupado);
            } else {
                System.debug('>>>>> NUEVO CLIENTE : ' + comAlert.almd__participant_id__c);
                //Si ese usuario aun no tiene datos de ese cliente
                Map<Id, Integer> mapaCliente = mapUserAgrupado.get(comAlUserId);
                mapaCliente.put(comAlert.almd__participant_id__c, 1);
                mapUserAgrupado.put(comAlUserId, mapaCliente);
            }
        } else if(mapUsers.get(comAlUserId).almd__alert_notification_type__c == Label.almd.COMM_ALERT_NOTIF_TYPE_GROUPED_BY_CLIENT
        && mapUserPriority.get(comAlUserId + comAlert.almd__Priority_Alert_Type__c)) {//Si el usuario aun no tiene datos con ningún cliente
            System.debug('>>>>> User_id__c -PRIMERA VEZ  ');
            Map<Id, Integer> mapaCliente = new Map<Id, Integer>();
            mapaCliente.put(comAlert.almd__participant_id__c, 1);
            mapUserAgrupado.put(comAlUserId, mapaCliente);
        }
        System.debug('>>>>> FIN AGRUPADO mapUserAgrupado : ' + mapUserAgrupado);

    }//FIN notificacionAgrupada

	/*
	* @author Global Desktop
	* @Description Funcion que genera 1 notificacion agrupada
	*/
    public static void notificacionGeneral(almd__Commercial_Alert__c comAlert, Id userId) {
        //Para el Gestor
        if(!setIdsUsersNotifGeneral.contains(userId)) {
            setIdsUsersNotifGeneral.add(userId);
        }

    }//FIN notificacionGeneral

	/*
	* @author Global Desktop
	* @Description Funcion que genera el post de chatter para las notificaciones de alertas
	*/
    public static void generarPostChatter(almd__Commercial_Alert__c commAlert, Id idUser, String textNotification) {
        System.debug('commAler: ' + commAlert);
         System.debug('idUser: ' + idUser);
         System.debug('textNotification: ' + textNotification);
         if(!Test.isRunningTest()){//NOSONAR
            ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
            messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
            mentionSegment.id = idUser; // The ID of the user to mention.
            messageInput.messageSegments.add(mentionSegment);
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = ' ' + textNotification;
            messageInput.messageSegments.add(textSegment);
            textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = '.';
            messageInput.messageSegments.add(textSegment);
            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.body = messageInput;
            if(commAlert == null) {
                input.subjectId = idUser;
            } else {
                input.subjectId = commAlert.id;
            }
            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
            Desktop_Utils.batchFeedItemInputs.add(batchInput);
            System.debug('Desktop_Utils.batchFeedItemInputs.size(): ' + Desktop_Utils.batchFeedItemInputs.size());
            if(Desktop_Utils.batchFeedItemInputs.size() == 500 || !Test.isRunningTest()) { //NOSONAR
                ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
                Desktop_Utils.batchFeedItemInputs = new List<ConnectApi.BatchInput>();
                System.debug('>>>>> Desktop_Utils.batchFeedItemInputs FORMATEADO : ' + Desktop_Utils.batchFeedItemInputs);
            }
        }
    }

	/*
	* @author Global Desktop
	* @Description Obtiene las cuentas de un set de ids de cuentas
	*/
	public static void getMapaAccounts(Set<Id> setIdsCuentas) {
	    if(mapAccounts.isEmpty()) {
	        mapAccounts = new Map<Id, Account>([
	                    SELECT  Id,
	                            Name
	                    FROM Account
	                    WHERE Id IN :setIdsCuentas
	        ]);
	    }
  	}

    /*
	* @author Global Desktop
	* @Description helper method
	*/
    private static Set<Id> givenUserNull(almd__Commercial_Alert__c commAlert, Set<Id> setIdUsers) {
        final Set<Id> setIdsUsers = setIdUsers;
        //Si no tiene product specialist, hay que notificar al equipo de cuenta
        if(mapClientMembers.get(commAlert.almd__participant_id__c) != null) {
            List<String> idsUsers = mapClientMembers.get(commAlert.almd__participant_id__c).split(';');
            setIdsUsers.add(UserInfo.getUserId());
            for(String user : idsUsers) {
                if(!setIdsUsers.contains((Id)user)) {
                    setIdsUsers.add((Id)user);//LO AGREGO PARA LAS PRIORIDADES
                }
            }
        }
        for(Id idGrupo : mapGroupSubsidiary.values()) {
            if(mapClientMembers.get(idGrupo) != null) {
                List<String> idsUsers = mapClientMembers.get(idGrupo).split(';');
                System.debug('idsUsers: ' +idsUsers);
                for(String user : idsUsers) {
                    if(!setIdsUsers.contains((Id)user)) {
                        setIdsUsers.add((Id)user);//LO AGREGO PARA LAS PRIORIDADES
                    }
                }
            }
        }
        return setIdsUsers;
    }
    /*
	* @author Global Desktop
	* @Description helper method
	*/
    private static void manageStep0Notifications(almd__Commercial_Alert__c comAlert, Set<String> idsUsers) {
        System.debug('>>>>> NO TIENE BANKER');
        if(mapClientMembers.get(comAlert.almd__participant_id__c) != null ) {

            //Guardo el equipo de la cuenta directa
            idsUsers.addAll(mapClientMembers.get(comAlert.almd__participant_id__c).split(';'));
            System.debug('>>>>> NOTIF idsUsers : ' + idsUsers);
            System.debug('>>>>> NOTIF mapUserPriority : ' + mapUserPriority);
        }

        //Guardo el equipo del grupo principal
        if(mapClientMembers.get(mapGroupSubsidiary.get(comAlert.almd__participant_id__c)) != null) {
            idsUsers.addAll(mapClientMembers.get(mapGroupSubsidiary.get(comAlert.almd__participant_id__c)).split(';'));
            System.debug('idsUsers del grupo principal: ' + idsUsers);
        }
        System.debug('idsUsers total: ' + idsUsers);
        if(idsUsers != null) {
            manageStep1Notifications(comAlert, idsUsers);
        }
    }
     /*
	* @author Global Desktop
	* @Description helper method
	*/
    private static void manageStep1Notifications(almd__Commercial_Alert__c comAlert, Set<String> idsUsers) {
        for(String us : idsUsers) {
            if(us != null && mapUserPriority != null && mapUsers != null && comAlert.almd__Priority_Alert_Type__c != null
               && mapUserPriority.get(us + comAlert.almd__Priority_Alert_Type__c) != null && mapUserPriority.get(us + comAlert.almd__Priority_Alert_Type__c) && mapUsers.get(us) != null) {
                if(mapUsers.get(us).almd__alert_notification_type__c == Label.almd.COMM_ALERT_NOTIF_TYPE_INDIVIDUAL
                || comAlert.RecordTypeId ==  Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.almd.RT_COMM_ALERT_NOTIFICATION).getRecordTypeId()) {
                    System.debug('>>>>> NOTIFICACION INDIVIDUAL AL USER ID : ' + mapUsers.get(us).Name);
                    notificacionIndividual(comAlert, us);
                } else if(mapUsers.get(us).almd__alert_notification_type__c == Label.almd.COMM_ALERT_NOTIF_TYPE_GROUPED_BY_CLIENT) {
                    System.debug('>>>>> NOTIFICACION AGRUPADA AL USER ID : ' + mapUsers.get(us).Name);
                    notificacionAgrupada(comAlert, us);
                } else if(mapUsers.get(us).almd__alert_notification_type__c == Label.almd.COMM_ALERT_NOTIF_TYPE_ONE_GENERAL) {
                    System.debug('>>>>> NOTIFICACION GENERAL AL USER ID : ' + mapUsers.get(us).Name);
                    notificacionGeneral(comAlert, us);
                }
            }
	    }
    }
     /*
	* @author Global Desktop
	* @Description helper method
	*/
    private static void manageStep2Notifications(almd__Commercial_Alert__c comAlert) {
        System.debug('>>>>> TIENE BANKER');
        if(mapUsers.get(comAlert.almd__User_id__c).almd__alert_notification_type__c == Label.almd.COMM_ALERT_NOTIF_TYPE_INDIVIDUAL
        || comAlert.RecordTypeId ==  Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.almd.RT_COMM_ALERT_NOTIFICATION).getRecordTypeId()) {
            System.debug('>>>>> NOTIFICACION INDIVIDUAL AL USER ID : ' + mapUsers.get(comAlert.almd__User_id__c).Name);
            notificacionIndividual(comAlert, comAlert.almd__User_id__c);
        } else if(mapUsers.get(comAlert.almd__User_id__c).almd__alert_notification_type__c == Label.almd.COMM_ALERT_NOTIF_TYPE_GROUPED_BY_CLIENT) {
            System.debug('>>>>> NOTIFICACION AGRUPADA AL USER ID : ' + mapUsers.get(comAlert.almd__User_id__c).Name);
            notificacionAgrupada(comAlert, comAlert.almd__User_id__c);
        } else if(mapUsers.get(comAlert.almd__User_id__c).almd__alert_notification_type__c == Label.almd.COMM_ALERT_NOTIF_TYPE_ONE_GENERAL) {
            System.debug('>>>>> NOTIFICACION GENERAL AL USER ID : ' + mapUsers.get(comAlert.almd__User_id__c).Name);
            notificacionGeneral(comAlert, comAlert.almd__User_id__c);
        }
    }
     /*
	* @author Global Desktop
	* @Description helper method
	*/
    private static void manageStep3Notifications(almd__Commercial_Alert__c comAlert) {
        System.debug('el owner es distinto que el banker y tiene chatter');
        if(mapUsers.get(comAlert.OwnerId).almd__alert_notification_type__c == Label.almd.COMM_ALERT_NOTIF_TYPE_INDIVIDUAL
        || comAlert.RecordTypeId == Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.almd.RT_COMM_ALERT_NOTIFICATION).getRecordTypeId()) {
            System.debug('>>>>> NOTIFICACION INDIVIDUAL AL OWNERID : ' + mapUsers.get(comAlert.OwnerId).Name);
            notificacionIndividual(comAlert, comAlert.OwnerId);
        } else if(mapUsers.get(comAlert.OwnerId).almd__alert_notification_type__c == Label.almd.COMM_ALERT_NOTIF_TYPE_GROUPED_BY_CLIENT) {
            System.debug('>>>>> NOTIFICACION AGRUPADA AL OWNERID : ' + mapUsers.get(comAlert.OwnerId).Name);
            notificacionAgrupada(comAlert, comAlert.OwnerId);
        } else if(mapUsers.get(comAlert.OwnerId).almd__alert_notification_type__c == Label.almd.COMM_ALERT_NOTIF_TYPE_ONE_GENERAL) {
            System.debug('>>>>> NOTIFICACION GENERAL AL OWNERID : ' + mapUsers.get(comAlert.OwnerId).Name);
            notificacionGeneral(comAlert, comAlert.OwnerId);
        }
    }
}