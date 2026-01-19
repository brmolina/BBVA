/**
 * @description       :
 * Ver   Date         Author
 * 1.0   08-02-2023   david.otero.carcia.contractor@bbva.com
**/
public class DPMX_Authorization_ctrl {

	/**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_Authorization_ctrl() {

    }

    @AuraEnabled
    public static Map<String, Object> getInitialData(){
        Map<String, Object> retMap = new Map<String, Object>();
        List<PermissionSetAssignment> usersToAuthLst = DPMX_Utils.userSelectorPermisionSet('DPMX_DynamicPrincingAuthorize');
        List<String> usersToAuthNamesLst = new List<String>();
        //Asignar usuarios para la Auth
        for(PermissionSetAssignment usersToAuth : usersToAuthLst){
            usersToAuthNamesLst.add(usersToAuth.Assignee.Name);
        }
        retMap.put('usersToAuthLst',usersToAuthLst);
        retMap.put('usersToAuthNamesLst',usersToAuthNamesLst);

        return retMap;

    }

    @AuraEnabled
    public static Map<Boolean, String> createAuthorization(String commentarioTxt, DPMX_Dynamic_Pricing__c DPAut, String debit, String credit, String international, String profability, String bai, string isGs, String debitBase, String creditBase, String internationalBase, String rentaBase, String baiBase, String family, String userId, string resultRates) {
            Map<Boolean, String> msgToast = new Map<Boolean, String>();
            Boolean authExist = false;
            Boolean authUserFind = true;

                authExist = DPMX_Utils.returnAuthIsCreated(DPAut.Id, debit, credit, international);            
                if(!authExist){
                DPMX_Dynamic_Pricing__c dynamicPricing = DPMX_Utils.dynamicPricingSelector(DPAut.Id);
                DPMX_authorization__c newAuth = new DPMX_authorization__c();

                user usOwner = DPMX_Utils.userSelector(dynamicPricing.OwnerId);
                user usAuth = new user();
               
                    newAuth.LKP_Dynamic_Pricing__c = DPAut.Id;
                    if(resultRates == 'BREAK_EVEN'){
                        newAuth.STR_AuthResult__c =  'Break even';
                    }else{
                        newAuth.STR_AuthResult__c =  resultRates;
                    }
                    newAuth.lkp_AssignedTo__c = userId;
                    newAuth.Comentario__c = commentarioTxt;
                    newAuth.STR_AuthCredit__c = credit;
                    newAuth.STR_AuthDebit__c = debit;
                    newAuth.STR_AuthInternational__c = international;
                    newAuth.STR_AuthProfitability__c = profability;
                    newAuth.STR_AuthBai__c = bai;
                    newAuth.STR_BaseDebit__c = debitBase;
                    newAuth.STR_BaseCredit__c = creditBase;
                    newAuth.STR_BaseInter__c = internationalBase;
                    newAuth.STR_BaseRenta__c = rentaBase;
                    newAuth.STR_BaseBai__c = baiBase;
                    newAuth.STR_AuthFamily__c = family;
                    newAuth.clientName__c = DPAut.Client__r.Name;
                    
                    if( isGs == 'false'){
                        newAuth.isGs__c = false;
                    }else {
                        newAuth.isGs__c = true;
                    }
                    insert newAuth;

                    if(!Test.isRunningTest()){
                        sendReport(commentarioTxt, DPAut, newAuth.Id);
                    }

                if(authUserFind){
                    msgToast.put(authExist, 'La autorización se ha creado.');
                }
            } else {
                msgToast.put(authExist, 'La autorización con estos valores ya existe.');
            }
            
            return msgToast;
    }

        /**
        * @description retrieve Profitability Sheets related to the participant
        * @param recordId : Client Id
        * @return retMap status update 
        */
        @AuraEnabled
        public static Map<String,Object> sendReport (String commentarioTxt, DPMX_Dynamic_Pricing__c DPAut, string authId) {
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            EmailTemplate emailTemp = DPMX_Utils.returnEmailTemp('DPMX_AuthorizeCreated');
            DPMX_authorization__c auth = DPMX_Utils.AuthSelector(authId);
            DateTime today = DateTime.now();
            String consultDate = today.format('yyyy-MM-dd');
            Map<String, Object> retMap = new Map<String, Object>();
            String htmlBody = emailTemp.HtmlValue;
            string status = 'sendReport';
            Boolean sendReport = true;
                
            htmlBody = htmlBody.replace('{!DPMX.fecha}',consultDate);
            htmlBody = htmlBody.replace('{!DPMX.razónSocial}',DPAut.Company_Name__r.Name);
            htmlBody = htmlBody.replace('{!DPMX.Link}', Label.DPMX_Link);
            htmlBody = htmlBody.replace('{!DPMX.autId}',authId);


            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(emailTemp.Id);
            mail.setTargetObjectId(auth.lkp_AssignedTo__c);
            mail.setHtmlBody(htmlBody);
            mail.setSaveAsActivity(false);
            mail.setSubject('Solicitud de autorización de tasa de adquirente / de descuento Break Even');
            emailList.add(mail);
            
            if(!emailList.isEmpty()){
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