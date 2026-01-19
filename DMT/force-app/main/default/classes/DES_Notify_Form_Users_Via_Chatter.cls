/**********************************************************************************
* @author      	Global Desktop 
* @date         26/04/2019
* @description  Clase without sharing de notificación a usuarios al recibir un formulario
* @Revision     
**********************************************************************************/
public without sharing class DES_Notify_Form_Users_Via_Chatter {
    
    /*
	* Entrada del mét0d0 invocable CloseOpportunities
	*/
  	public class ChatterCompliance {
        /**
         * Id del formulario asociado al chatter
         */
        @InvocableVariable(label='Form' required=true)
        public Inside_information_form__c form; //NOSONAR
        
        /**
         * Lista de usuarios a notificar
         */
        @InvocableVariable(label='Users list' required=true)
        public List<User> userList; //NOSONAR
  	}
    
	/*
	* @author Global Desktop
	* @Description Notificación via chatter
	*/
    @InvocableMethod(label='ChatterCompliance' description='Notify compliance users ')
	public static void notificacionIndividual (List<ChatterCompliance> lstChttrCmplnc) {
        final List<ConnectApi.BatchInput> batchInputList = new List<ConnectApi.BatchInput>();
        for(ChatterCompliance chttrCmplncAux : lstChttrCmplnc) {
            for(User user : chttrCmplncAux.userList) {
                System.debug('user :' + user);
                System.debug('user.DES_Disable_Chatter__c :' + user.DES_Disable_Chatter__c);
                System.debug('!user.DES_Disable_Chatter__c :' + !user.DES_Disable_Chatter__c);
                System.debug('user.IsActive :' + user.IsActive);
                
                if(!user.DES_Disable_Chatter__c && user.IsActive) {
                    System.debug('chatterComplianceAux.form: ' + chttrCmplncAux.form);
                    System.debug('user.Id: ' + user.Id);
                    System.debug('Label.Share_IP_form_with_compliance_team: ' + Label.Share_IP_form_with_compliance_team);
                    
                	batchInputList.add(generarPostChatter(chttrCmplncAux.form, user.Id, Label.Share_IP_form_with_compliance_team));
                }
        	}
        }
        
        ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputList);
        System.debug('Notificacion: ' + batchInputList);
    }//FIN notificacionIndividual
    
    /*
	* @author Global Desktop
	* @Description Funcion que genera el post de chatter para las notificaciones de alertas
	*/
    public static ConnectApi.BatchInput generarPostChatter(Inside_information_form__c form, Id idUser, String textNotification) {
        final ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        final ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = idUser; // The ID of the user to mention.
        messageInput.messageSegments.add(mentionSegment);
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = ' ' + textNotification;
        messageInput.messageSegments.add(textSegment);
        textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = '.';
        messageInput.messageSegments.add(textSegment);
        final ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        input.subjectId = form.Id;
        return new ConnectApi.BatchInput(input);
    }

}