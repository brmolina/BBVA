/**************************************************************************************************************
Name:            DES_OppManagementMemberTriggerHandler
Description:     Handler Class to manage the trigger on object DES_Opportunity_Management_member__c
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            01/04/2018      DSL          Creación de la clase
0.2            13/07/2018      JSS          Update -> Creación mehod setCountry_GB_IH para actualizar el country a 'Global'
                                            cuando se trata de los 'Industry Head' y 'Global Banker'
0.3            26/07/2018      JSS          Update -> En el borrado se hace la comprobación de no eliminar
                                            un BBVAMember en el objeto opportunityTeam estandar cuando en el objeto custom respectivo
                                            existe añadido varias veces el mismo miembro pero con diferentes roles
**************************************************************************************************************/
public class DES_OppManagementMemberTriggerHandler { //NOSONAR
    /*
    *   Lista de duplicados encontrados
    *
    **/
    public List <DES_Opportunity_Management_member__c> listDuplicates; //NOSONAR

    //private CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();

    /*
    *   Variable instancia del controlador
    *
    **/
    private static DES_OppManagementMemberTriggerHandler instance;

    public static DES_OppManagementMemberTriggerHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new DES_OppManagementMemberTriggerHandler();
        }
        return instance;
    }

    /*
    *   Method que comprueba si existen duplicados
    *
    **/
    public void checkDuplicates(List<DES_Opportunity_Management_member__c> triggerNew) {
            // meto en una lista las oportunidades de los BBVA management team que lanzan el trigger
        listDuplicates = new List <DES_Opportunity_Management_member__c>();
        Set<Id> listOpps;
        listOpps = new Set<Id>();
        //if (userSettings.CIB_Is_Desktop__c) {
        for(DES_Opportunity_Management_member__c aux : triggerNew) {
            listOpps.add(aux.DES_Opportunity__c);
        }
        system.debug('>>>>> listOpps: ' + listOpps);
        // recojo all los BBVA management team cuya oportunidad esté en el set inicial
        final List<DES_Opportunity_Management_member__c> listaBBVAOT = new List<DES_Opportunity_Management_member__c>([
                    SELECT  Id,
                            DES_User__c,
                            DES_Opportunity__c,
                            DES_Opportunity_member_role__c,
                            DES_Scope__c,
                            DES_PS_Product__c
                    FROM DES_Opportunity_Management_member__c
                    WHERE DES_Opportunity__c IN :listOpps
        ]);
        system.debug('>>>>> listaBBVAOT: ' + listaBBVAOT);
        // recorro la lista incial (triggerNew) y la comparo con la lista recogida (listaBBVAOT). Si hay alguna pareja repetida se muestra mensaje de error
        //Set<Id> setCuentasError = new Set<Id>();
        final Integer triggerNewSize = triggerNew.size();
        Boolean hayDuplicado = false;
        Map<DES_Opportunity_Management_member__c,DES_Opportunity_Management_member__c> checkElements = new Map<DES_Opportunity_Management_member__c,DES_Opportunity_Management_member__c>();
        for(DES_Opportunity_Management_member__c memTrig : triggerNew) {
            for(DES_Opportunity_Management_member__c memBBVA : listaBBVAOT) {
                    if(memTrig.DES_Opportunity__c == memBBVA.DES_Opportunity__c && memTrig.DES_User__c == memBBVA.DES_User__c && memTrig.DES_Opportunity_member_role__c == memBBVA.DES_Opportunity_member_role__c) {
                        checkElements.put(memTrig,memBBVA);
                    }
                }
        }
        for(DES_Opportunity_Management_member__c mem : checkElements.keySet()) {
            checkDuplicate(mem,checkElements.get(mem));
        }
        if(!listDuplicates.isEmpty()) {
            hayDuplicado = true;
        }
        // Si la inserción es manual salta el mensaje. Si la inserción es masiva sólo salta si se inserta 1 registro
        if(triggerNewSize == 1 && hayDuplicado == true) {
            triggerNew.get(0).addError(label.DES_Duplicate_BBVA_Team_Member);
        }
     // } // FIN SI ES USUARIO DESKTOP
        system.debug('>>>>>listDuplicates: ' + listDuplicates);
    } // FIN checkDuplicates()

    /*
    *   Method que comprueba si existen duplicados
    *
    **/
    private void checkDuplicate(DES_Opportunity_Management_member__c memTrig, DES_Opportunity_Management_member__c memBBVA/*, Boolean hayDuplicado*/) {
        system.debug('>>>>> listaBBVAOT: ' + memBBVA);
        system.debug('>>>>> triggerNew: ' + memTrig);
            // Global Banker, Industry Head y Risk Analyst
            if (memTrig.DES_Opportunity_member_role__c == Label.DES_ROLE_SECONDARY_GB || memTrig.DES_Opportunity_member_role__c == Label.DES_ROLE_GLOBAL_BANKER || memTrig.DES_Opportunity_member_role__c == Label.DES_ROLE_INDUSTRY_HEAD || memTrig.DES_Opportunity_member_role__c==Label.DES_Role_Risk_Analyst) {
                listDuplicates.add(memBBVA);

            // Local Banker, Transactional Banker y Regional Banker
            } else if (memTrig.DES_Scope__c == memBBVA.DES_Scope__c
            && (memTrig.DES_Opportunity_member_role__c == Label.DES_ROLE_LOCAL_BANKER || memTrig.DES_Opportunity_member_role__c==Label.DES_Role_Transactional_Banker || memTrig.DES_Opportunity_member_role__c==Label.DES_Role_Regional_Banker)) {
                listDuplicates.add(memBBVA);

            // Product Specialist
            } else {
                checkDuplicatePS(memTrig,memBBVA);
            }
    }

    /*
    *   Method que comprueba si existen Product Specialists duplicados
    *
    **/
    private void checkDuplicatePS(DES_Opportunity_Management_member__c memTrig, DES_Opportunity_Management_member__c memBBVA/*, Boolean hayDuplicado*/) {
        if ( memTrig.DES_Scope__c == memBBVA.DES_Scope__c && memTrig.DES_PS_Product__c == memBBVA.DES_PS_Product__c
        && memTrig.DES_Opportunity_member_role__c == Label.DES_Role_Product_Specialist) {
            listDuplicates.add(memBBVA);
        }
    }

	/**
    * Method que comprueba en eliminaciones manuales de un miembro de oportunidad si es el owner, impidiendo eliminarlo entonces
    *
    * @param triggerNew
    */
    public static void checkIsOwnerDelete(List<DES_Opportunity_Management_member__c> triggerOld) {
        if(triggerOld.size()==1 && triggerOld.get(0).DES_Owner__c==true) {
            triggerOld.get(0).addError(Label.Error_Delete_Owner_Opp_Team);
        }
    }


    /*
    *   Method que elimina una lista de miembros de oportunidad
    *
    **/
    public static void deleteOpportunityTeamMember(List<DES_Opportunity_Management_member__c> inputList) {
            set<Id> opportunityIds;
            opportunityIds = new set<Id>();
            set<Id> userIds;
            userIds = new set<Id>();

            for (DES_Opportunity_Management_member__c i : inputList) {
                if(!opportunityIds.contains(i.DES_Opportunity__c)) {
                   opportunityIds.add(i.DES_Opportunity__c);
                }
                if(!userIds.contains(i.DES_User__c)) {
                   userIds.add(i.DES_User__c);
                }
            }


            // recuperamos el numero de veces que aparece un usuario como miembro en cada cliente, y lo metemos en un mapa
            final AggregateResult[] grpdMemLst = [SELECT DES_Opportunity__c,DES_User__c, Count(Id)Member_count
                                                        FROM DES_Opportunity_Management_member__c
                                                        Where DES_Opportunity__c in :opportunityIds Group by DES_Opportunity__c,DES_User__c];
            map<String,Integer> mapCountMC;
            mapCountMC = new map<String,Integer>();
            for (AggregateResult memberCount : grpdMemLst) {
                mapCountMC.put((String) memberCount.get('DES_Opportunity__c') + '_' + memberCount.get('DES_User__c'),(Integer) memberCount.get('Member_count'));
            }

            //recuperamos los usuarios que están como miembros del objeto estandar OpportunityTeamMember
            //(si no habido error deberían ser los mismos que los del objeto custom), y lo metemos en un mapa
            final list<OpportunityTeamMember> oppTeamMemberList = [SELECT id, OpportunityId, UserId
                                                            FROM OpportunityTeamMember
                                                            WHERE OpportunityId IN:opportunityIds AND UserId IN:userIds];
            system.debug('Valor de oppTeamMemberList: ' +oppTeamMemberList);
            Map<String,OpportunityTeamMember> otmMap;
            otmMap = new Map<String, OpportunityTeamMember>();
            for (OpportunityTeamMember otm : oppTeamMemberList) {
                otmMap.put(otm.OpportunityId + '_' + otm.UserId, otm);
            }

            // creacion de la lista con los id's de los miembros del objeto estandar que habrá que eliminar a posteriori
            final List<OpportunityTeamMember> membersToDelete = checkDeleteMember(inputList,mapCountMC,otmMap);

            if (!membersToDelete.isEmpty()) {
                delete membersToDelete;
            }
        //}//FIN SI NO ES USUARIO DESKTOP
    }//fin deleteOpportunityTeamMember

    /*
    *   Method que elimina una lista de miembros de oportunidad
    *
    **/
    public static List<OpportunityTeamMember> checkDeleteMember(List<DES_Opportunity_Management_member__c> inputList, Map<String,Integer> mapCountMC, Map<String,OpportunityTeamMember> otmMap) {
        List<OpportunityTeamMember> membersToDelete;
        membersToDelete = new List<OpportunityTeamMember>();
        //Recorremos la lista que viene del trigger de miembros del objeto custom, y se rellena la lista de id's membersToDelete del objeto estandar
        for(DES_Opportunity_Management_member__c bbvaMember : inputList) {
            // si un usuario NO sigue apareciendo en el mapa (si sigue apareciendo es que estaba  más de 1 vez como miembro de una Oportunidad)
            //y si ese miembro está tambien en el objeto estandar, se añade en la lista para eliminar en el objeto estandar
            if (!mapCountMC.containsKey(bbvaMember.DES_Opportunity__c + '_' + bbvaMember.DES_User__c)
            && otmMap.containsKey(bbvaMember.DES_Opportunity__c + '_' + bbvaMember.DES_User__c)
            && !membersToDelete.contains(otmMap.get(bbvaMember.DES_Opportunity__c + '_' + bbvaMember.DES_User__c)) ) {
                membersToDelete.add(otmMap.get(bbvaMember.DES_Opportunity__c + '_' + bbvaMember.DES_User__c));
            }
        }

        return membersToDelete;
    }


    /*
    * La razón de por qué se hace este method en lugar de traer estos valores via campo fórmula,
    * es porque se quería que el campo fuera editable. Pero realmente no tiene sentido estar relacionado con un user y luego cambiarle el nombre.
    */
    public static void fillOppManagMemberName(List<DES_Opportunity_Management_member__c> triggerNew) {
        //Guardo los Id's de los usuarios
        Set<Id> userIds;
        userIds = new Set<Id>();
        for(DES_Opportunity_Management_member__c oppmm : triggerNew) {
            if(!userIds.contains(oppmm.DES_User__c)) {
                userIds.add(oppmm.DES_User__c);
            }
        }

        //Hago una query para recuperar el firstname y el lastname de los usuarios
        final Map<Id, User> mapUsers = new Map<Id, User>([
                    SELECT  Id,
                            FirstName,
                            LastName
                    FROM User
                    WHERE Id IN :userIds
        ]);

        //Mediante un for recorro los elementos del trigger new y le asigno el Name a partir del mapa de la query de Users
        for(DES_Opportunity_Management_member__c oppmm : triggerNew) {
            oppmm.Name = mapUsers.get(oppmm.DES_User__c).LastName;
            if ( !String.isBlank(mapUsers.get(oppmm.DES_User__c).FirstName) ) {
                oppmm.Name = mapUsers.get(oppmm.DES_User__c).FirstName + ' ' + oppmm.Name;
            }
        }

    }//FIN fillOppManagMemberName

    /*
    *   @AUTHOR Global Desktop
    *
    *   @DESCRIPTION    Method que controla que no existan registros duplicados de product specialist
    *                   dentro de trigger new (esta situación se da al tener una oportunidad con 1 producto clonado varias veces)
    **/
    public static void avoidPSDuplicatedTriggerNew(List<DES_Opportunity_Management_member__c> triggerNew) {
        Map<String, DES_Opportunity_Management_member__c> mapDuplicates;
        mapDuplicates = new Map<String, DES_Opportunity_Management_member__c>();
        for(DES_Opportunity_Management_member__c aux : triggerNew) {
            if(aux.DES_Opportunity_member_role__c == Label.DES_Role_Product_Specialist
            && mapDuplicates.get(aux.DES_Opportunity__c + '_' + aux.DES_User__c + '_' + aux.DES_Scope__c + '_' + aux.DES_Opportunity_member_role__c + '_' + aux.DES_PS_Product__c) == null) {
                mapDuplicates.put(aux.DES_Opportunity__c + '_' + aux.DES_User__c + '_' + aux.DES_Scope__c + '_' + aux.DES_Opportunity_member_role__c + '_' + aux.DES_PS_Product__c, aux);
            } else if (aux.DES_Opportunity_member_role__c == Label.DES_Role_Product_Specialist) {
                DES_Opportunity_Management_member__c memberCloned;
                memberCloned = aux.clone(true, false);
                Desktop_Utils.listMiembrosDuplicados.add(memberCloned);
            }
        }
        system.debug('>>>>> Desktop_Utils.listMiembrosDuplicados: ' + Desktop_Utils.listMiembrosDuplicados);
    }

    /* mehod que actualiza el country a 'Global' cuando se trata de los 'Industry Head' y 'Global Banker' */
    public static void fillCountryGBIH(List<DES_Opportunity_Management_member__c> triggerNew) {
        for(DES_Opportunity_Management_member__c oppmm : triggerNew) {
            if (oppmm.DES_Opportunity_member_role__c == Label.DES_ROLE_GLOBAL_BANKER
            || oppmm.DES_Opportunity_member_role__c == Label.DES_ROLE_INDUSTRY_HEAD) {
                oppmm.DES_Scope__c = 'Global';
            }
        }
    }//FIN fillCountryGBIH


    /*
    *   Method que setea el global banker
    *
    **/
    public static void fillGlobalBanker(Map<Id, DES_Opportunity_Management_member__c> triggerNewMap) {
        //Mapa que contiene el Id de la oportunidad como clave y el Id del usuario que es Global Banker como Value
        //Map<Id, Id> mapOppUserBG = new Map<Id, Id>();
        Map<Id, Opportunity> mapOppsUpd;
        mapOppsUpd = new Map<Id, Opportunity>();
        //Guardo los Id's de las Opps relacionadas SOLO de los miembros que son Global Banker
        for(DES_Opportunity_Management_member__c opmm : triggerNewMap.values()) {
            if(opmm.DES_Opportunity_member_role__c == Label.DES_ROLE_GLOBAL_BANKER) {
                mapOppsUpd.put(opmm.DES_Opportunity__c, new Opportunity(Id=opmm.DES_Opportunity__c, DES_Global_Banker__c=opmm.DES_User__c));
            }
        }

        system.debug('>>>>> mapOppsUpd : ' + mapOppsUpd);
        if(!mapOppsUpd.values().isEmpty()) {
            update mapOppsUpd.values();
        }
    }//FIN fillGlobalBanker

    /*
     *  @author Global Desktop - VASS
     *  @Description Method que se encarga de comprobar si hay algun NBC Chatter asociado y en caso de existir da permisos al usuario
     *
    **/
    public static void shareChatterNBCVirtual(Map<Id, DES_Opportunity_Management_member__c> triggerNewMap) {
        final Map<Id, Id> mapOppIdUserId = new Map<Id, Id>();
        final List<Chatter_NBC_Virtual__Share> listNBCVInsert = new List<Chatter_NBC_Virtual__Share>();
        for(DES_Opportunity_Management_member__c oppMM : triggerNewMap.values()) {
            mapOppIdUserId.put(oppMM.DES_Opportunity__c, oppMM.DES_User__c);
        }

        //lanzo una query al objeto Chatter_NBC_Virtual__c
        for(Chatter_NBC_Virtual__c chatterNBCV : [SELECT Id, id_objeto__c, tipo_objeto__c FROM Chatter_NBC_Virtual__c WHERE id_objeto__c IN :mapOppIdUserId.keySet()]) {
            listNBCVInsert.add(Chatter_NBC_Virtual_TriggerHelper.createChatterNBCVirtualShare(chatterNBCV.Id, mapOppIdUserId.get(chatterNBCV.id_objeto__c), 'Edit', Label.APEX_SHARING_REASON_CHATTER_NBC_VIRTUAL_OPP_TEAM_MEMBER));
        }

        system.debug( '::::: listNBCVInsert : ' + listNBCVInsert);
        if (!listNBCVInsert.isEmpty()) {
            insert listNBCVInsert;
        }
    }

    /*
     *  @author Global Desktop - VASS
     *  @Description Borra los permisos para el Chatter NBC Virtual
     *
    **/
    public static void deleteChatterNBCVirtualShare(List<DES_Opportunity_Management_member__c> triggerOld) {
        //Set que tiene concatenado el ID de la oportunidad + '_' + ID del usuario
        final Set<String> setOppStrUserStr = new Set<String>();
        final Set<Id> setUserIds = new Set<Id>();
        final Set<Id> setOppsIds = new Set<Id>();
        final List<Chatter_NBC_Virtual__Share> listNBCVDelete = new List<Chatter_NBC_Virtual__Share>();
        //Mapa que tiene como key la concatenacion de el id de la opp y el id del usuario y como value el numero de veces que aparece
        final Set<String> setOppUserReps = new Set<String>();
        for(DES_Opportunity_Management_member__c oppMM : triggerOld) {
            setOppStrUserStr.add(oppMM.DES_Opportunity__c + '_' + oppMM.DES_User__c);
            setUserIds.add(oppMM.DES_User__c);
            setOppsIds.add(oppMM.DES_Opportunity__c);
        }

        system.debug('::::: setUserIds : ' + setUserIds);
        system.debug('::::: setOppsIds : ' + setOppsIds);
        for(DES_Opportunity_Management_member__c oppMMBBDD : [SELECT DES_User__c, DES_Opportunity__c FROM DES_Opportunity_Management_member__c WHERE DES_User__c IN :setUserIds AND DES_Opportunity__c IN :setOppsIds]) {
            system.debug('::::: CONCAT FOR : ' + oppMMBBDD.DES_Opportunity__c + '_' + oppMMBBDD.DES_User__c);
            setOppUserReps.add(oppMMBBDD.DES_Opportunity__c + '_' + oppMMBBDD.DES_User__c);

        }
        system.debug('::::: setOppStrUserStr : ' + setOppStrUserStr);
        // system.debug('::::: mapOppUserReps : ' + mapOppUserReps);
        system.debug('::::: setOppUserReps : ' + setOppUserReps);
        //lanzo una query al objeto Chatter_NBC_Virtual__c
        final String sharReason = Label.APEX_SHARING_REASON_CHATTER_NBC_VIRTUAL_OPP_TEAM_MEMBER + '__c';
        for(Chatter_NBC_Virtual__Share chtrNBCVShare : [SELECT Id, ParentId, Parent.id_objeto__c, UserOrGroupId FROM Chatter_NBC_Virtual__Share WHERE Parent.id_objeto__c IN :setOppsIds AND UserOrGroupId IN :setUserIds AND RowCause = :sharReason]) {
            system.debug('::::: CONDICION SET setOppStrUserStr: ' + setOppStrUserStr.contains(chtrNBCVShare.Parent.id_objeto__c + '_' + chtrNBCVShare.UserOrGroupId));
            system.debug('::::: CONDICION SET !setOppUserReps : ' + !setOppUserReps.contains(chtrNBCVShare.Parent.id_objeto__c + '_' + chtrNBCVShare.UserOrGroupId));
            if(setOppStrUserStr.contains(chtrNBCVShare.Parent.id_objeto__c + '_' + chtrNBCVShare.UserOrGroupId) && !setOppUserReps.contains(chtrNBCVShare.Parent.id_objeto__c + '_' + chtrNBCVShare.UserOrGroupId)) {
                listNBCVDelete.add(chtrNBCVShare);
            }
        }

        system.debug( '::::: listNBCVDelete : ' + listNBCVDelete);
        if (!listNBCVDelete.isEmpty()) {
            delete listNBCVDelete;
        }
    }

    /*
	* @author Global Desktop
	* @Description Actualiza los paises de los miembros de oportunidad en la oportunidad
	*/
    /*public void updateIPOpportunityCountry(List <DES_Opportunity_Management_member__c> triggerNew) {
        // FILTRAR POR RECORD TYPE ?
        Set<Id> setUsersId = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        Map<Id, String> oppCountriesMap = new Map<Id, String>();

        //Cojo los ids de los usuarios de los miembros de la oportunidad y las oportunidades
        for(DES_Opportunity_Management_member__c opMember : triggerNew) {
            if(opMember.DES_User__c != null && !setUsersId.contains(opMember.DES_User__c)) {
                setUsersId.add(opMember.DES_User__c);
            }
            if(!oppIdSet.contains(opMember.DES_Opportunity__c)) {
                oppIdSet.add(opMember.DES_Opportunity__c);
            }
        }
        //Recojo los usuarios de Salesforce para coger su país
        Map<Id, User>mapUsers = new Map<Id, User>([SELECT Id, DES_Country__c FROM User WHERE Id IN :setUsersId]);

        System.debug('getOppCountriesMap: ' + triggerNew);
        oppCountriesMap = getOppCountriesMap(triggerNew, mapUsers);

        //Recojo las oportunidades para ponerles el país
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, oppy_participate_country_desc__c FROM Opportunity WHERE Id IN :oppIdSet]);

        //Pongo el país en las oportunidades
        for(Opportunity opp : oppList) {
            opp.oppy_participate_country_desc__c += oppCountriesMap.get(opp.Id);
            system.debug('oppCountriesMap.get(opp.Id): ' +oppCountriesMap.get(opp.Id));
            System.debug('opp.oppy_participate_country_desc__c: ' + opp.oppy_participate_country_desc__c);
        }
        System.debug('oppList: ' + oppList);

        updateOppList(JSON.serialize(oppList));
        //update oppList;
    }//FIN updateIPOpportunityCountry*/

    /*
	* @author Global Desktop
	* @Description Actualiza la concatenación de los países en las oportunidades
	*/
    @future
    public static void updateOppList (String oppListJSON) {
        final List<Opportunity> oppList = (List<Opportunity>)JSON.deserialize(oppListJSON, List<Opportunity>.class);
        if(!oppList.isEmpty()) {
        	system.debug('>>>>> oppList : ' + oppList);
            update oppList;
        }
    }

    /*
	* @author Global Desktop
	* @Description Funcion que tiene la logica a realizar cuando se ejecute el Before Delete
	*/
    /*public void logicBeforeDelete(Map<Id, DES_Opportunity_Management_member__c> triggerOldMap) {
        checkDeleteIPOppMember(triggerOldMap);
    }*/

    /*
    *   @author Global Desktop
    *   @Description Funcion que, si la oportunidad es IP, no deja borrar a los miembros de la oportunidad si ya ha iniciado sesión en algun momento
    *
    */
    /*private void checkDeleteIPOppMember(Map<Id, DES_Opportunity_Management_member__c> triggerOldMap) {
        system.debug('>>>>> triggerOldMap: ' + triggerOldMap);
        Global_Desktop_Settings__c gdSettings = Global_Desktop_Settings__c.getInstance();
        if(gdSettings.URL_Lightning__c != null && gdSettings.URL_Lightning__c != '') {
            final Set<String> setOppsId = new Set<String>();
            final Set<String> setOppsURL = new Set<String>();
            final Set<Id> setUserId = new Set<Id>();
            //Mapa que tiene como key 'IDUSUARIO_IDOPORTUNIDAD' y como value un true si ha visitado la oportunidad y no tiene que permitir borrar al opp team member
            final Set<String> setUserOppEvent = new Set<String>();
            //Recorro el triggerNew para recuperar todos los Ids de las opps y los usuarios relacionados
            for(DES_Opportunity_Management_member__c oppManag : triggerOldMap.values()) {
                if(!setOppsId.contains(oppManag.DES_Opportunity__c)) {
                    setOppsId.add(oppManag.DES_Opportunity__c);
                }
                if(!setUserId.contains(oppManag.DES_User__c)) {
                    setUserId.add(oppManag.DES_User__c);
                }
            }

            //Construyo las URLS de las Opps relacionadas que sean inside information
            for(Opportunity opp : [SELECT Id, disclosure_info_type__c FROM Opportunity WHERE disclosure_info_type__c = :Label.DES_OP_Inside AND Id IN :setOppsId]) {
                if(!setOppsURL.contains(gdSettings.URL_Lightning__c + 'lightning/r/Opportunity/' + opp.Id + '/view')) {
                    setOppsURL.add(gdSettings.URL_Lightning__c + 'lightning/r/Opportunity/' + opp.Id + '/view');
                }
            }
            system.debug('>>>>> setUserId: ' + setUserId);
            system.debug('>>>>> setOppsURL: ' + setOppsURL);
            system.debug('>>>>> query: ' + [SELECT Name, etrk__Account_Name__c, etrk__Body__c, etrk__CreationDate__c, etrk__Event_Name__c, etrk__Event_Text__c,
                                                                        etrk__Location__c, etrk__Raw_Location__c, etrk__Section__c, etrk__SessionId__c, etrk__Type__c, etrk__User__c
                                                                FROM etrk__EventTracker_Event__c
                                                                WHERE etrk__User__c IN :setUserId AND etrk__Location__c IN :setOppsURL]);
            if(!setOppsURL.isEmpty()) {
                //Recorro los eventtracker para ver si el usuario ha visitado la oportunidad que quiere comprobar
                for(etrk__EventTracker_Event__c eventTracker : [SELECT Name, etrk__Account_Name__c, etrk__Body__c, etrk__CreationDate__c, etrk__Event_Name__c, etrk__Event_Text__c,
                                                                        etrk__Location__c, etrk__Raw_Location__c, etrk__Section__c, etrk__SessionId__c, etrk__Type__c, etrk__User__c
                                                                FROM etrk__EventTracker_Event__c
                                                                WHERE etrk__User__c IN :setUserId AND etrk__Location__c IN :setOppsURL]) {
                    system.debug('>>>>> eventTracker: ' + eventTracker);
                    String oppId = eventTracker.etrk__Location__c.substringBeforeLast('/'); //NOSONAR
                    oppId = oppId.substringAfterLast('/');
                    if(!setUserOppEvent.contains(eventTracker.etrk__User__c + '_' + oppId)) {
                        setUserOppEvent.add(eventTracker.etrk__User__c + '_' + oppId);
                    }
                }
                for(DES_Opportunity_Management_member__c oppManag : triggerOldMap.values()) {
                    if(setUserOppEvent.contains(oppManag.DES_User__c + '_' + oppManag.DES_Opportunity__c)) {
                        oppManag.addError(Label.ERROR_IP_CANNOT_DELETE_OPP_MEMBER);
                    }
                }
            }

        }

        //etrk__EventTracker_Event__c
    }*/

    /*
	* @author Global Desktop
	* @Description Borra los paises de los miembros de oportunidad en la oportunidad
	*/
    /*public void deleteIPOpportunityCountry(List <DES_Opportunity_Management_member__c> triggerOld) {
        // FILTRAR POR RECORD TYPE ?
        Set<Id> setUsersId = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        Map<Id, String> oppCountriesMap = new Map<Id, String>();

        //Cojo los ids de los usuarios de los miembros de la oportunidad y las oportunidades
        for(DES_Opportunity_Management_member__c opMember : triggerOld) {
            if(!oppIdSet.contains(opMember.DES_Opportunity__c)) {
                oppIdSet.add(opMember.DES_Opportunity__c);
            }
        }

        //Recojo las oportunidades para ponerles el país
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, oppy_participate_country_desc__c, OwnerId FROM Opportunity WHERE Id IN :oppIdSet]);

        //Recojo los miembros de oportunidad de las oportunidades
        List<DES_Opportunity_Management_member__c> oppTMList = new List<DES_Opportunity_Management_member__c>([
            SELECT Id, DES_User__c, DES_Opportunity__c from DES_Opportunity_Management_member__c WHERE DES_Opportunity__c IN :oppIdSet]);

        //Construyo un set de ids de usuarios - miembros de oportunidad
        for(DES_Opportunity_Management_member__c oppTMAux : oppTMList) {
            if(!setUsersId.contains(oppTMAux.DES_User__c)) {
                setUsersId.add(oppTMAux.DES_User__c);
            }
        }
        //Meto también los owners
        for(Opportunity oppAux : oppList) {
            if(!setUsersId.contains(oppAux.OwnerId)) {
                setUsersId.add(oppAux.OwnerId);
            }
        }

        //Recojo los usuarios de Salesforce para coger su país
        Map<Id, User>mapUsers = new Map<Id, User>([SELECT Id, DES_Country__c FROM User WHERE Id IN :setUsersId]);

        oppCountriesMap = getOppCountriesMap(oppTMList, mapUsers);

        //Añado al mapa los ids de las oportunidades y sus países - owners
        for(Opportunity oppAux : oppList) {
            //Si ya tengo la oportunidad, meto el país del miembro de la op
            if(oppCountriesMap.get(oppAux.Id) != null) {
                String concat = oppCountriesMap.get(oppAux.Id);
                concat +=  mapUsers.get(oppAux.OwnerId).DES_Country__c + ';' ;
                oppCountriesMap.put(oppAux.Id, concat);
            } else {
                //Meto nueva oportunidad
                oppCountriesMap.put(oppAux.Id, mapUsers.get(oppAux.OwnerId).DES_Country__c + ';');
            }
        }

        //Pongo el país en las oportunidades
        for(Opportunity opp : oppList) {
            opp.oppy_participate_country_desc__c = oppCountriesMap.get(opp.Id);
            System.debug('opp.oppy_participate_country_desc__c: ' + opp.oppy_participate_country_desc__c);
        }
        System.debug('oppList: ' + oppList);
        updateOppList(JSON.serialize(oppList));
        //update oppList;
    }*/

    /*
    * @author Global Desktop
    * @Description Construyo un mapa con los ids de las oportunidades y sus países - miembros de oportunidad
    */
    /*public Map<Id, String> getOppCountriesMap(List<DES_Opportunity_Management_member__c> oppMTList, Map<Id, User> mapUsers) {
        System.debug('dentro de getOppCountriesMap');
        Map<Id, String> oppCountriesMap = new Map<Id, String>();
        for(DES_Opportunity_Management_member__c opMember : oppMTList) {
            //Si ya tengo la oportunidad, meto el país del miembro de la op
            if(oppCountriesMap.get(opMember.DES_Opportunity__c) != null) {
                System.debug('dentro del if');
                String concat = oppCountriesMap.get(opMember.DES_Opportunity__c);
                concat +=  mapUsers.get(opMember.DES_User__c).DES_Country__c + ';' ;
                oppCountriesMap.put(opMember.DES_Opportunity__c, concat);
            } else {
                System.debug('dentro del else');
                //Meto nueva oportunidad
                oppCountriesMap.put(opMember.DES_Opportunity__c, mapUsers.get(opMember.DES_User__c).DES_Country__c + ';');
            }
            System.debug('oppCountriesMap: ' + oppCountriesMap);
        }
        return oppCountriesMap;
    }*/

}//FIN CLASS