/**
* ____________________________________________________________________________
* Controller class for DPMX_FormalizeDeny.cmp aura Component
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-05-16
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class DPMX_FormalizeDeny_ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_FormalizeDeny_ctrl() {

    }

    /**
    * @description retrieve Profitability Sheets related to the participant
    * @param recordId : Client Id
    * @return retMap status update 
    */
    @AuraEnabled
    public static Map<String,Object> deniedFormalize (String recordId, String commentarioTxt) {
        Map<String, Object> retMap = new Map<String, Object>();
        boolean toastStatus = false;
        DPMX_Formalize__c formalize = DPMX_Utils.formalizeSelector(recordId);
        DPMX_Dynamic_Pricing__c dynamicPricing =DPMX_Utils.dynamicPricingSelector(formalize.Dynamic_Pricing__c);
        
        if(formalize.deniedCheck__c == false){
            sendReport(formalize, commentarioTxt);
            formalize.deniedDate__c = Date.today()+'';
            formalize.deniedCheck__c = true;
            formalize.denyComments__c = commentarioTxt;
            toastStatus = true;
            formalize.FirmODTUser__c = false;
            formalize.FirmOdtClient__c = false;
            formalize.NewODT__c = false;
            formalize.ScanODT__c = false;
            update formalize;
            dynamicPricing.Stage__c = 'Negotiation';
            update dynamicPricing;
        }
 
        return retMap;
    }

    /**
        * @description retrieve Profitability Sheets related to the participant
        * @param recordId : Client Id
        * @return retMap status update 
        */
        @AuraEnabled
        public static Map<String,Object> sendReport (DPMX_Formalize__c formalize, string commentarioTxt) {
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            Map<String, Object> retMapUpdateRates = new Map<String, Object>();
            EmailTemplate emailTemp = DPMX_Utils.returnEmailTemp('dpmx_deniedFormalize');
            Map<String, Object> retMap = new Map<String, Object>();
            DPMX_Dynamic_Pricing__c dynamicPricing = DPMX_Utils.dynamicPricingSelector(formalize.Dynamic_Pricing__c);
            string status = 'sendReport';
            Boolean sendReport = true;
            String htmlBody = emailTemp.HtmlValue;
            String customerId = '';
            String contentText = '';
            String asunto = '';
            if(!formalize.NewODT__c){
                asunto = 'Solicitud de verificación de tasa rechazada';
                contentText = 'Te informamos que la solicitud de la tasa de descuento fue <Strong>rechazada</Strong>. Para realizar una nueva propuesta de la tasa de descuento debe editar la información y enviar otra propuesta a formalizar.';
            }else {
                asunto = 'Solicitud de creación y resguardo de ODT rechazada';
                contentText = 'La solicitud de la tasa de descuento fue rechazada por el equipo de TAM. Para realizar una nueva propuesta de la tasa de descuento debe editar la información y enviar otra propuesta a formalizar.';
            }
    
            if(sendReport){
                htmlBody = htmlBody.replace('{!DPMX.ContentText}', contentText);
                htmlBody = htmlBody.replace('{!DPMX.Link}', Label.DPMX_Link);
                htmlBody = htmlBody.replace('{!DPMX.IdFormalize}', dynamicPricing.Id);
                htmlBody = htmlBody.replace('{!DPMX.client}', dynamicPricing.Company_Name__r.Name);
                htmlBody = htmlBody.replace('{!DPMX.Comments}', commentarioTxt);
                htmlBody = htmlBody.replace('{!DPMX.Comment}', commentarioTxt);
                htmlBody = htmlBody.replace('{!DPMX.Name}', formalize.Name);
    
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(emailTemp.Id);
                mail.setTargetObjectId(dynamicPricing.OwnerId);
                //mail.setCcAddresses(sendCC);
                mail.setHtmlBody(htmlBody);
                mail.setSaveAsActivity(false);
                mail.setSubject(asunto);
                emailList.add(mail);
                
                if(!emailList.isEmpty()){
                    Messaging.sendEmail(emailList);
                }else {
                    status = 'fail send report';
                }
            }
            retMap.put('sendReport', sendReport);
            retMap.put('status', status);
            return retMap;
        }
}