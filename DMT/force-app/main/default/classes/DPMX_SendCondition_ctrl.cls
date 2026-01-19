/**
* ____________________________________________________________________________
* Controller class for DPMX_SendCondition.cmp aura Component
* ____________________________________________________________________________
* @author      David Otero
* @modifiedBy
* @version     1.0
* @created     2022-02-09
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class DPMX_SendCondition_ctrl {
    
    /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_SendCondition_ctrl() {

    }
    /**
    * @description 
    * @param sendConditionLst : 
    */
    @AuraEnabled
    public static void getInformationEmail(list<Object> recordTaxLst) {
        System.debug('Ejemplo primero');
        System.debug(recordTaxLst);
    }
    
    /*public sendEmail() {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { 'abc2@gmail.com', 'abc2@gmail.com' };
        message.optOutPolicy = 'FILTER';
        message.subject = 'Subject Test Message';
        message.plainTextBody = 'This is the message body.';
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        }
    }*/
}