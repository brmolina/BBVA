/**********************************************************************************
* @author       Global Desktop
* @date         07/05/2019
* @description  Clase de apoyo para los flows
* @Revision
**********************************************************************************/
public without sharing class DES_IP_flow_queries { //NOSONAR
    /*
    * Entrada del mét0d0 invocable UserPublicGroups
    */
    public class UserPublicGroups { //NOSONAR
        /**
         * boolean para guardar si el usuario es jefe ip o no
         */
        @InvocableVariable(label='isInIPGroup' required=false)
        public Boolean isInIPGroup; //NOSONAR
        /**
         * Id del usuario
         */
        @InvocableVariable(label='idUser' required=false)
        public String idUser; //NOSONAR
        /**
         * Nombre del grupo/queue por el que filtrar en la query
         */
        @InvocableVariable(label='groupName' required=false)
        public String groupName; //NOSONAR
         /**
         * Nombre del grupo/queue por el que filtrar en la query
         */
        @InvocableVariable(label='queueId' required=false)
        public Id queueId; //NOSONAR
        /**
         * Lista de miembros de una oportunidad
         */
        @InvocableVariable(label='oppUsersList' required=false)
        public List<User> oppUsersList; //NOSONAR
        /**
         * Lista de miembros de una oportunidad
         */
        @InvocableVariable(label='userCountryList' required=false)
        public List<String> userCountryList; //NOSONAR
        /**
         * Lista de usuarios: owner + miembros de la oportunidad
         */
        @InvocableVariable(label='oppTMList' required=false)
        public List<DES_Opportunity_Management_member__c> oppTMList; //NOSONAR
        /**
         * Lista de Compliance_Team__mdt
         */
        @InvocableVariable(label='caseQueuesList' required=false)
        public List<String> caseQueuesList; //NOSONAR
        /**
         * Nombre de la función a invocar
         */
        @InvocableVariable(label='method' required=false)
        public String method; //NOSONAR
        /**
         * Lista de group members
         */
        @InvocableVariable(label='groupMemberList' required=false)
        public List<GroupMember> groupMemberList; //NOSONAR
        /**
         * Registro de caso
         */
        @InvocableVariable(label='caseRecord' required=false)
        public Case caseRecord; //NOSONAR
        /**
         * Estado
         */
        @InvocableVariable(label='status' required=false)
        public String status; //NOSONAR
        /**
         * Case team member list
         */
        @InvocableVariable(label='caseTeamMemberList' required=false)
        public List <CaseTeamMember> caseTeamMemberList; //NOSONAR
        /**
         * Registro de opportunity
         */
        @InvocableVariable(label='opportunityRecord' required=false)
        public Opportunity opportunityRecord; //NOSONAR
        /**
         * Email al que notificar
         */
        @InvocableVariable(label='emailList' required=false)
        public List<String> emailList; //NOSONAR
        /**
         * Email template
         */
        @InvocableVariable(label='emailTemplate' required=false)
        public String emailTemplate; //NOSONAR
        /**
         * Id de la oportunidad
         */
        @InvocableVariable(label='opportunityId' required=false)
        public Id opportunityId; //NOSONAR
        /**
         * Id de la visita
         */
        @InvocableVariable(label='visitId' required=false)
        public Id visitId; //NOSONAR
        /**
         * API Name del objeto
         */
        @InvocableVariable(label='objectAPIName' required=false)
        public String objectAPIName; //NOSONAR
        /**
         * Boolean con la respuesta true/false de si el usuario tiene permiso de creación sobre el objeto
         */
        @InvocableVariable(label='objectIsCreateable' required=false)
        public Boolean objectIsCreateable; //NOSONAR

    }

	/*
	* @author Global Desktop
	* @Description Funcion que comprueba si el usuario está en el public group enviado (else)
	*/
    @InvocableMethod(label='UserPublicGroups' description='User Public Groups')
    public static List<UserPublicGroups> currentUserIsInGroup(List<UserPublicGroups> uPublGroupList) { //NOSONAR
        System.debug('>>>>>>>>>>> uPublGroupList.size(): ' + uPublGroupList.size() + '\r\n' +
                    '>>>>>>>>>>> uPublGroupList: ' + uPublGroupList + '\r\n' +
                    '>>>>>>>>>>> uPublGroupList[0]: ' + uPublGroupList[0]);

        String USERS_OPP_MEMB = 'getUsersOfOppMemb';
        String COMPLNC_TEAM_COUNTRY = 'getComplianceTeamsByCountry';
        String UPSERT_CASE = 'insertUpdateCase';
        String CASE_TEAM_MEMBERS = 'insertCaseTeamMembers';
        String GROUP_MEMBERS = 'insertGroupMembers';
        String UPDATE_OPP = 'updateOpportunity';
        String SEND_EMAIL = 'sendEmail';
        String DELETE_OPP = 'deleteOpportunity';
        String DELETE_VISIT = 'deleteVisit';
        String CHECK_OBJECT_CREATE_PERMISSION = 'checkObjectCreatePermission';

        List<UserPublicGroups> uPublGroupListAux = uPublGroupList;

        if(uPublGroupList[0].method == DELETE_OPP) {
            uPublGroupListAux = deleteOpportunity(uPublGroupListAux);
        }
        if(uPublGroupList[0].method == DELETE_VISIT) {
            uPublGroupListAux = deleteVisit(uPublGroupListAux);
        }
        if(uPublGroupList[0].method == USERS_OPP_MEMB) {
            uPublGroupListAux = getUsersOfOppMemb(uPublGroupListAux);
        }
        if(uPublGroupList[0].method == COMPLNC_TEAM_COUNTRY) {
            uPublGroupListAux = getComplianceTeamsByCountry(uPublGroupListAux);
        }
        if(uPublGroupList[0].groupName != null) {

            final UserPublicGroups userPublicGroups = new userPublicGroups();
            userPublicGroups.isInIPGroup = false;
            final String filtro = '%' + uPublGroupList[0].groupName + '%';
            final List<GroupMember> groupMemberList =  [SELECT group.name, group.DeveloperName, GroupId
                                                      FROM GroupMember
                                                      WHERE UserOrGroupId = :uPublGroupList[0].idUser AND group.DeveloperName LIKE :filtro]; //NOSONAR
            if(!groupMemberList.isEmpty()) {
                userPublicGroups.isInIPGroup = true;
                userPublicGroups.queueId = groupMemberList[0].GroupId;
            }
            uPublGroupListAux.clear();
            uPublGroupListAux.add(userPublicGroups);
        }
        if(uPublGroupList[0].method == UPSERT_CASE) {
            uPublGroupListAux = insertUpdateCase(uPublGroupListAux);
        }
        if(uPublGroupList[0].method == UPSERT_CASE) {
            uPublGroupListAux = deleteOpportunity(uPublGroupListAux);
        }
        if(uPublGroupList[0].method == CASE_TEAM_MEMBERS) {
            insertCaseTeamMembers(uPublGroupListAux);
        }
        if(uPublGroupList[0].method == GROUP_MEMBERS) {
            //insertGroupMembers(userPublicGroupsListAux);
            insertGroupMembers(JSON.serialize(uPublGroupListAux));
        }
        if(uPublGroupList[0].method == UPDATE_OPP) {
            updateOpportunity(uPublGroupListAux);
        }
        if(uPublGroupList[0].method == CHECK_OBJECT_CREATE_PERMISSION) {
            checkObjectCreatePermission(uPublGroupListAux);
        }
        //if(uPublGroupList[0].method == SEND_EMAIL) {
            //sendEmail(userPublicGroupsListAux);
        //}

        return uPublGroupListAux;

    }

    /*
	* @author Global Desktop
	* @Description Funcion que devuelve si el usuario tiene permisos de creacción en el objeto que se pasa por parámetro
	*/
    public static List<UserPublicGroups> checkObjectCreatePermission(List<UserPublicGroups> uPublGroupListAux) {
      final String objectAPI = uPublGroupListAux.get(0).objectAPIName;
      switch on objectAPI {
          when 'Opportunity' {
        	uPublGroupListAux.get(0).objectIsCreateable = Opportunity.sObjectType.getDescribe().isCreateable();
          }
          when 'dwp_kitv__Visit__c' {
            uPublGroupListAux.get(0).objectIsCreateable = dwp_kitv__Visit__c.sObjectType.getDescribe().isCreateable();
          }
          when else {
            System.debug('>>>>>>>>>>>>>> objectAPI ' +objectAPI);
            System.debug('>>>>>>>>>>>>>> objectAPI isAccessible ' + Schema.getGlobalDescribe().get(objectAPI).getDescribe().isAccessible());
            uPublGroupListAux.get(0).objectIsCreateable = Schema.getGlobalDescribe().get(objectAPI).getDescribe().isCreateable();
          }
          //when else {		  // default block
              // code block 4
          //}
      }
      return uPublGroupListAux;
	}

    /*
	* @author Global Desktop
	* @Description Funcion que devuelve los usuarios de los participantes de una oportunidad
	*/
    public static List<UserPublicGroups> getUsersOfOppMemb(List<UserPublicGroups> uPublGroupListAux) {
        System.debug('Dentro de getUsersOfOppMemb');
        final UserPublicGroups userPublicGroups = new userPublicGroups();
        final Set<Id> userOppTMidSet = new Set<Id>();
        //usuarios miembros de la oportunidad
        final List<User> usersInOppTM = new List<User>();

        System.debug('uPublGroupListAux[0].oppTMList: ' + uPublGroupListAux[0].oppTMList);
        //recorro la lista de miembros de opp para coger su usuario
        for(DES_Opportunity_Management_member__c oppMembAux : uPublGroupListAux[0].oppTMList) {
            //guardo los usuarios
            if(!userOppTMidSet.contains(oppMembAux.DES_User__c)) {
                userOppTMidSet.add(oppMembAux.DES_User__c);
            }
        }
        System.debug('userOppTMidSet: ' + userOppTMidSet);

        //cojo los usuarios de los participantes
        final List<User> usersQueryList = [SELECT Id, Name, DES_Country__c FROM User WHERE Id IN :userOppTMidSet];
        //recorro los resultados para no guardar repetidos
        for(User userAux : usersQueryList) {
            if(!usersInOppTM.contains(userAux)) {
                usersInOppTM.add(userAux);
            }
        }
        System.debug('usersInOppTM: ' + usersInOppTM);

        userPublicGroups.oppUsersList = usersInOppTM;
        uPublGroupListAux.clear();
        uPublGroupListAux.add(userPublicGroups);
        return uPublGroupListAux;
    }

    /*
	* @author Global Desktop
	* @Description Funcion que devuelve los equipos de compliance a los que enviar el caso para cerrar la oportunidad
	*/
    public static List<UserPublicGroups> getComplianceTeamsByCountry(List<UserPublicGroups> uPublGroupListAux) {
        System.debug('>>>>>> Dentro de getComplianceTeamsByCountry: ' + uPublGroupListAux);

        final UserPublicGroups userPublicGroups = new userPublicGroups();

        final Set<String> complCountry = new Set<String>();
        //recorro la lista de usuarios para coger su país
        for(User userOppAux : uPublGroupListAux[0].oppUsersList) {
            //guardo los roles
            if(!complCountry.contains(userOppAux.DES_Country__c)) {
                complCountry.add(userOppAux.DES_Country__c);
            }

        }
        System.debug('complCountry: ' + complCountry);

        //obtengo los metadata que corresponden a los países
        final List<Compliance_Team__mdt> complTeamList = [SELECT Compliance_Team__c FROM Compliance_Team__mdt WHERE DeveloperName IN :complCountry];

        //recorro los resultados para no guardar repetidos y me quedo con Compliance_Team__c
        final Set<String> complianceTeamSet = new Set<String>();
        for(Compliance_Team__mdt complianceTeamAux : complTeamList) {
            if(!complianceTeamSet.contains(complianceTeamAux.Compliance_Team__c)) {
                complianceTeamSet.add(complianceTeamAux.Compliance_Team__c);
            }
        }

        //guardo las queues de los compliance team obtenidos
        final List<String> queuesIdList = new List<String>();
        final List<Group> queuesList = [SELECT id, Email from Group where Name IN :complianceTeamSet];
        for(Group queueAux : queuesList) {
            if(!queuesIdList.contains(queueAux.Id)) {
                queuesIdList.add(queueAux.Id);
            }
        }

        System.debug('queuesIdList: ' + queuesIdList);


        userPublicGroups.caseQueuesList = queuesIdList;
        uPublGroupListAux.clear();
        uPublGroupListAux.add(userPublicGroups);
        System.debug('getUsersAndRoles - userPublicGroups' + userPublicGroups);
        System.debug('getUsersAndRoles - uPublGroupListAux' + uPublGroupListAux);
        return uPublGroupListAux;
    }

    /*
	* @author Global Desktop
	* @Description Funcion que devuelve los equipos de compliance a los que enviar el caso para cerrar la oportunidad
	*/
    public static List<UserPublicGroups> insertUpdateCase(List<UserPublicGroups> uPublGroupListAux) {
        System.debug('>>>>>> Dentro de insertUpdateCase: ' + uPublGroupListAux);
        final UserPublicGroups userPublicGroups = new userPublicGroups();

        //recorro la lista de usuarios para coger su país
        final Case caso = uPublGroupListAux[0].caseRecord;

        String SENT_TO_IP_MNGR = 'Sent to IP manager';
        String SENT_TO_COMPLNC = 'Sent to compliance';

        if(uPublGroupListAux[0].status == SENT_TO_IP_MNGR) {
            caso.Status = SENT_TO_IP_MNGR;
        } else if(uPublGroupListAux[0].status == SENT_TO_COMPLNC) {
            caso.Status = SENT_TO_COMPLNC;
        }
        System.debug('>>>>>> caso: ' + caso);
        upsert caso;

        userPublicGroups.caseRecord = caso;
        uPublGroupListAux.clear();
        uPublGroupListAux.add(userPublicGroups);
        System.debug('getUsersAndRoles - userPublicGroups' + userPublicGroups);
        System.debug('getUsersAndRoles - uPublGroupListAux' + uPublGroupListAux);
        return uPublGroupListAux;
    }

    /*
	* @author Global Desktop
	* @Description Funcion que devuelve los equipos de compliance a los que enviar el caso para cerrar la oportunidad
	*/
    public static void insertCaseTeamMembers(List<UserPublicGroups> uPublGroupListAux) {
        System.debug('Dentro de insertCaseTeamMembers');

        final List<CaseTeamMember> caseTmMmbrLst = uPublGroupListAux[0].caseTeamMemberList;

        System.debug('caseTeamMemberList: ' + caseTmMmbrLst);
        if (caseTmMmbrLst != null && !caseTmMmbrLst.isEmpty()) {
            insert caseTmMmbrLst;
        }
    }

    /*
	* @author Global Desktop
	* @Description Funcion que devuelve los equipos de compliance a los que enviar el caso para cerrar la oportunidad
	*/
    @future
    public static void insertGroupMembers(String userPblcGrpStrngAux) { //NOSONAR
        System.debug('Dentro de insertGroupMembers');
        final List<UserPublicGroups> uPublGroupListAux = (List<UserPublicGroups>)JSON.deserialize(userPblcGrpStrngAux, List<UserPublicGroups>.class);
        final List<GroupMember> groupMemberList = uPublGroupListAux[0].groupMemberList;

        System.debug('groupMemberList: ' + groupMemberList);
        if (groupMemberList != null && !groupMemberList.isEmpty()) {insert groupMemberList;}

    }

    /*
	* @author Global Desktop
	* @Description Funcion que actualiza la oportunidad
	*/
    public static void updateOpportunity(List<UserPublicGroups> uPublGroupListAux) {
        System.debug('Dentro de updateOpportunity');
        final Opportunity opportunityRecord = uPublGroupListAux[0].opportunityRecord;
        System.debug('opportunityRecord: ' + opportunityRecord);
        if (opportunityRecord != null) {update opportunityRecord;}
    }

    /*
	* @author Global Desktop
	* @Description Funcion que elimina la oportunidad
	*/
    public static List<UserPublicGroups> deleteOpportunity(List<UserPublicGroups> uPublGroupListAux) {
        System.debug('>>>>>> Dentro de deleteOpportunity: ' + uPublGroupListAux);
        final UserPublicGroups userPublicGroups = new userPublicGroups();

        //recorro la lista de usuarios para coger su país
        final Id idOpp = uPublGroupListAux[0].opportunityId;


        System.debug('>>>>>> idOpp: ' + idOpp);
        delete new Opportunity(Id = idOpp);

        userPublicGroups.caseRecord = null; //NOSONAR
        uPublGroupListAux.clear();
        uPublGroupListAux.add(userPublicGroups);
        System.debug('getUsersAndRoles - userPublicGroups' + userPublicGroups);
        System.debug('getUsersAndRoles - uPublGroupListAux' + uPublGroupListAux);
        return uPublGroupListAux;
    }


    /*
	* @author Global Desktop
	* @Description Funcion que elimina la visita
	*/
    public static List<UserPublicGroups> deleteVisit(List<UserPublicGroups> uPublGroupListAux) {
        System.debug('>>>>>> Dentro de deleteVisit: ' + uPublGroupListAux);
        final UserPublicGroups userPublicGroups = new userPublicGroups();

        //recorro la lista de usuarios para coger su país
        final Id idVisit = uPublGroupListAux[0].visitId;


        System.debug('>>>>>> idVisit: ' + idVisit);
        delete new dwp_kitv__Visit__c(Id = idVisit);

        userPublicGroups.caseRecord = null; //NOSONAR
        uPublGroupListAux.clear();
        uPublGroupListAux.add(userPublicGroups);
        System.debug('getUsersAndRoles - userPublicGroups' + userPublicGroups);
        System.debug('getUsersAndRoles - uPublGroupListAux' + uPublGroupListAux);
        return uPublGroupListAux;
    }

}