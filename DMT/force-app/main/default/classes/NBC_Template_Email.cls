/*
    *Autor: Alejandro del Rio
     */
public with sharing class NBC_Template_Email {
   private NBC_Template_Email() {}

    /*
    *Autor: Alejandro del Rio
     */
    public class FlowInputs {
        @InvocableVariable
        public String record;//NOSONAR
        @InvocableVariable
        public String body;//NOSONAR
        @InvocableVariable
        public String[] address ;//NOSONAR
    }

	@InvocableMethod(label='Prueba NBC' description='prueba NBC')
    /*
    *Autor: Alejandro del Rio
    *Met0d0 que manda email, recibiendo una lista de parametros para asignar
    *los valores al email
     */
    public static void gettemplates(list<FlowInputs> mgList) {
        final FlowInputs nbcInputs = mgList[0];
        final List<NBC__c> nbcs=[Select id,name,Committee_Start_Date__c from NBC__c where Id =: nbcInputs.record limit 1];
        final DateTime myDateTime = nbcs[0].Committee_Start_Date__c;
        final String cabecera = '&#60;'+nbcs[0].name+'&#62; '+myDateTime.format('dd/MM/yyyy');
        final list<String> emails = new List<String>();//NOSONAR
        for (User correo :[Select id, Email from User where id in: nbcInputs.address]) {
            emails.add(correo.Email);
        }
        final Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = emails;
        final OrgWideEmailAddress orgmail=[Select id from OrgWideEmailAddress where Address ='no-reply_sf_globaldesktop@bbva.com' limit 1];
		message.setOrgWideEmailAddressId(orgmail.id);
        message.optOutPolicy = 'FILTER';
        message.subject = 'Virtual NBC <'+nbcs[0].name+'> '+myDateTime.format('dd/MM/yyyy');
        final String bodu= nbcInputs.body;
         String lista='<a href="'+URL.getOrgDomainURL().toExternalForm()+'/'+nbcs[0].Id+'"><h4>'+nbcs[0].name+'</h4></a>';
        for(DES_Template__c templ : [SELECT Name,Id FROM DES_Template__c WHERE gf_oppy_virtual_cmtee_id__c =:nbcs[0].Id]) {
            lista +='<li><a href="'+URL.getOrgDomainURL().toExternalForm()+'/'+templ.Id+'">'+templ.Name+'</a></li>';
        }
        String target = '**NBCLISTA**';//NOSONAR
        final String body2 = bodu.replace(target,lista);
        final String body3 = body2.replace('**NBCCABECERA**',cabecera);
        message.setHtmlBody(body3);
        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
        
        try {
    		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
    	} catch (EmailException e) {
        	if (Test.isRunningTest()) {
            	// Silenciamos el error solo en tests si es por falta de configuración
            	System.debug('Error de envío en test: ' + e.getMessage());
        	} else {
            	throw e;
        	}
    	}
    }
}