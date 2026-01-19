/**
* ____________________________________________________________________________
* Controller class for DPMX_AuthorizationDetails.cmp aura Component
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-05-04
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/

public class DPMX_AuthorizationReassign_ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_AuthorizationReassign_ctrl() {
		Map<String, Object> retMap = new Map<String, Object>();
    }
    /**
    * @description Get data from services
    * @param recordId : 
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData (String recordId) {
        Map<String, Object> retMap = new Map<String, Object>();
        List<PermissionSetAssignment> userLst = [SELECT AssigneeId, Assignee.Name 
        FROM PermissionSetAssignment
        WHERE PermissionSet.Name = 'DPMX_DynamicPrincingAuthorize'];
        retMap.put('userLst', userLst);
        retMap.put('success', true);
        return retMap;
    }

    /**
    * @description retrieve Profitability Sheets related to the participant
    * @param recordId : Client Id
    * @return retMap status update 
    */
    @AuraEnabled
    public static Map<String,Object> updateAuth (String recordId, string userId) {
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_authorization__c auth = [SELECT lkp_AssignedTo__c
        FROM DPMX_authorization__c
        WHERE Id =:recordId];

        auth.lkp_AssignedTo__c = userId;
        update auth;
        
        retMap = sendReport(recordId);
        retMap.put('success', true);
        return retMap;
    }

    @AuraEnabled
        public static Map<String,Object> sendReport (string authId) {
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            EmailTemplate emailTemp = DPMX_Utils.returnEmailTemp('DPMX_AuthorizeCreated');
            DPMX_authorization__c auth = DPMX_Utils.AuthSelector(authId);
            DPMX_Dynamic_Pricing__c DPAut = DPMX_Utils.dynamicPricingSelector(auth.LKP_Dynamic_Pricing__c);
            Map<String, Object> retMap = new Map<String, Object>();
            String htmlBody = emailTemp.HtmlValue;
            string status = 'sendReport';
            Boolean sendReport = true;
            DateTime today = DateTime.now();
            String consultDate = today.format('yyyy-MM-dd');
                
            htmlBody = htmlBody.replace('{!DPMX.Name}',auth.name);
            htmlBody = htmlBody.replace('{!DPMX.Dynamic_Pricing__r.Name}',DPAut.Name);
            htmlBody = htmlBody.replace('{!DPMX.Comment}','Autorización reasignada');
            htmlBody = htmlBody.replace('{!DPMX.Link}', Label.DPMX_Link);
            htmlBody = htmlBody.replace('{!DPMX.autId}',authId);
            htmlBody = htmlBody.replace('{!DPMX.fecha}',consultDate);
            htmlBody = htmlBody.replace('{!DPMX.razónSocial}',DPAut.Company_Name__r.Name);


            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(emailTemp.Id);
            mail.setTargetObjectId(auth.lkp_AssignedTo__c);
            mail.setHtmlBody(htmlBody);
            mail.setSaveAsActivity(false);
            mail.setSubject('Autorización reasignada');
            emailList.add(mail);
            
            if(Test.isRunningTest()){
              status = 'Verificacion de envio de email para classes test.';
              sendReport = true;  
            }else  if(!emailList.isEmpty()){
                Messaging.sendEmail(emailList);
            }else {
                status = 'fail send report';
                sendReport = false;
            }

            retMap.put('sendReport', sendReport);
            retMap.put('status', status);
            return retMap;
        }
}