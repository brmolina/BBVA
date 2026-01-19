/**********************************************************************************
* @author       Global Desktop
* @date         29/01/2021
* @description  Clase de apoyo para los flows
* @Revision
**********************************************************************************/
public without sharing class WrongDataFlow {
    /**
    * Private constructor
    **/
    private WrongDataFlow() {
    }
    /*
    * Entrada del mét0d0 invocable UserPublicGroups
    */
    public class RegistriesForms { //NOSONAR
        /**
         * Asset template
         */
        @InvocableVariable(label='recordId' required=true)
        public String form; //NOSONAR
        /**
         * Mensaje
         */
        @InvocableVariable(label='text' required=true)
        public String text; //NOSONAR
    }

    /*
	* @author Global Desktop
	* @Description Funcion que comprueba si el usuario está en el public group enviado (else)
	*/
    @InvocableMethod(label='RolesEsales' description='Roles Esales')
    public static void notifyFlow(List<RegistriesForms> registries) {
        System.debug('Formulario----------->'+registries[0].form);
        System.debug('Formulario----------->'+registries[0].text);
        String mensaje;
        mensaje = registries[0].text.replace('***',  URL.getOrgDomainURL().toExternalForm() + '/' + registries[0].form);
        generarNotificaciones(registries[0].form, mensaje);
    }

    /**
     * @author Global Desktop
    * @Description Funcion que genera notificaciones por carga en función de prioridad y/o tipo de notificacion que elige el usuario
    */
    public static void generarNotificaciones(String temp, String texto) {
        Set<Id> roles;
        roles = rolESales();
        final List<User> users = new List<User>([
        SELECT Id FROM User WHERE UserRoleId IN :roles AND DES_Disable_Chatter__c = false AND isActive = true
        ]);
        for(User user : users) {
            generarPostChatter(user.Id, texto);
        }

        System.debug('Desktop_Utils.batchFeedItemInputs.size(): ' + Desktop_Utils.batchFeedItemInputs.size());
        for(ConnectApi.BatchInput batch : Desktop_Utils.batchFeedItemInputs) {
          System.debug('batch: ' + batch);
        }

        if(!Desktop_Utils.batchFeedItemInputs.isEmpty() && !test.isRunningTest()) {             //NOSONAR
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
        }
    }  //FIN generarNotificaciones

    /**
     * @author Global Desktop
    * @Description Funcion que genera el post de chatter para las notificaciones de soporte
    */
    public static void generarPostChatter(Id idUser, String texto) {
        System.debug('idUser: ' + idUser);

        final ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        final ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = texto;
        messageInput.messageSegments.add(textSegment);
        final ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;

        if(idUser != null) {
            input.subjectId = idUser;
        }

        final ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
        Desktop_Utils.batchFeedItemInputs.add(batchInput);
        System.debug('Desktop_Utils.batchFeedItemInputs.size(): ' + Desktop_Utils.batchFeedItemInputs.size());

        if(Desktop_Utils.batchFeedItemInputs.size() == 500 && !test.isRunningTest()) {     //NOSONAR
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
            Desktop_Utils.batchFeedItemInputs = new List<ConnectApi.BatchInput>();
            System.debug('>>>>> Desktop_Utils.batchFeedItemInputs FORMATEADO : ' + Desktop_Utils.batchFeedItemInputs);
        }
    }

    /**
     * @author Global Desktop
    * @Description Funcion que devuelve un set de ids con los usuarios de eSales
    */
    public static Set<Id> rolESales() {
        Set<Id> roleIds;
        roleIds = new Set<Id>();
        Set<Id> rolsCompare;
        rolsCompare = new Set<Id>();
        final userRole rol = [SELECT Id, Name FROM UserRole WHERE Name = 'GLOBAL MARKETS ECOMMERCE SALES' LIMIT 1];
        System.debug('rol----------->'+rol);
        roleIds.add(rol.Id);
        rolsCompare = getAllSubRoleIds(roleIds);
        rolsCompare.add(rol.Id);
        System.debug('rolsCompare ----------->'+rolsCompare);
        return rolsCompare;
    }

    private static Set<Id> getAllSubRoleIds(Set<ID> roleIds) {
        System.debug('roleIds------------------> '+roleIds);
        Set<Id> currentRoleIds;
        currentRoleIds = new Set<Id>();
        for(UserRole userRole : [SELECT Id FROM UserRole WHERE ParentRoleId IN :roleIds AND ParentRoleID != null]) {   //NOSONAR
            System.debug('userRole------------------> '+userRole);
            currentRoleIds.add(userRole.Id);
        }
        if(!currentRoleIds.isEmpty()) {
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }
            return currentRoleIds;
    }

}