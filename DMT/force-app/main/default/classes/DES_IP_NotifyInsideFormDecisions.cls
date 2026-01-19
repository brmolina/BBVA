public without sharing class DES_IP_NotifyInsideFormDecisions {

    /**
	   * Notifica a los miembros del equipo de la oportunidad de que la revisión del formulario ha sido aprobada o rechazada
	   *
	   * @param List<GroupMember> targets
	   * @param String decision
	   */
	  @AuraEnabled
	  public static void NotifyOppTeamFormDecision ( List<GroupMember> targets, String decision, Inside_information_form__c form, Case relatedCase) {

	    try {
            EmailTemplate et;
            Boolean isOpp = relatedCase.opportunity_id__c != null;
            if(decision.equalsIgnoreCase('Approved')) {
                if(isOpp) {
                    et=[Select Id,Body,HtmlValue,Subject from EmailTemplate where name=:'DES IP Approve Opp Form'];
                } else {
                    et=[Select Id,Body,HtmlValue,Subject from EmailTemplate where name=:'DES IP Approve Visit Form'];
                }
            } else if(decision.equalsIgnoreCase('Rejected')) {
                if(isOpp) {
                    et=[Select Id,Body,HtmlValue,Subject from EmailTemplate where name=:'DES IP Reject Opp Form'];
                } else {
                    et=[Select Id,Body,HtmlValue,Subject from EmailTemplate where name=:'DES IP Reject Visit Form'];
                }
            }

            String mergedBody;
            if(!Test.isRunningTest()) {
                mergedBody = et.HtmlValue.replace('{!Case.domain_desc__c}',relatedCase.domain_desc__c);
            } else {
                mergedBody = et.HtmlValue;
            }
            if(isOpp && !Test.isRunningTest()) {
                mergedBody = mergedBody.replace('{!Case.Opportunity_Name__c}',relatedCase.Opportunity_Name__c);
                mergedBody = mergedBody.replace('{!Case.opportunity_idId__c}',relatedCase.opportunity_id__c);
            } else if(isOpp) {
                mergedBody = mergedBody.replace('{!Case.opportunity_idId__c}',relatedCase.opportunity_id__c);
            } else if(!Test.isRunningTest()){
                mergedBody = mergedBody.replace('{!Case.visit_name__c}',relatedCase.visit_name__c);
                mergedBody = mergedBody.replace('{!Case.visit_idId__c}',relatedCase.visit_id__c);
            } else {
                mergedBody = mergedBody.replace('{!Case.visit_idId__c}',relatedCase.visit_id__c);
            }

            final OrgWideEmailAddress fromAddress = [select Id from OrgWideEmailAddress where Address = 'no-reply_sf_globaldesktop@bbva.com'];

            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for(GroupMember gm : targets){
                Messaging.SingleEmailMessage singleMail = new Messaging.SingleEmailMessage();
                singleMail.setTargetObjectId(gm.UserOrGroupId);
                singleMail.setTreatTargetObjectAsRecipient(true);
                singleMail.setSaveAsActivity(false);

                singleMail.setSubject(et.Subject);
                singleMail.setOrgWideEmailAddressId(fromAddress.Id);

                singleMail.setHtmlBody(mergedBody);
                singleMail.setPlainTextBody(et.Body.replace('{!Inside_information_form__c.Name}',form.Name));

                emails.add(singleMail);

            }

            Messaging.sendEmail(emails);

	    } catch (Exception e) {

	      throw new AuraHandledException(e.getMessage()); //NOSONAR

	    }


	  }
}