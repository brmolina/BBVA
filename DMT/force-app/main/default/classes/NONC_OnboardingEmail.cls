/*
* Class to send the email to notify the onboarding of a prospect
*/
public class NONC_OnboardingEmail {
  /*
  * Invocable variables from flow
  */
  public class FlowInputs {
    @InvocableVariable
    public String record; //NOSONAR
    @InvocableVariable
    public String templateId; //NOSONAR
    @InvocableVariable
    public String addresses; //NOSONAR
    @InvocableVariable
    public String orgAddressDefault; //NOSONAR
  }

  /*
  * Method that sends the email
  */
  @InvocableMethod(label='Send Onboarding Mail' description='Send Onboarding Mail')
  public static void sendEmail(List<FlowInputs> inputs) {
    FlowInputs input = inputs.get(0);
    List <String> addresses = input.addresses.split(';');
    system.debug('addresses ' + addresses);
    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    message.toAddresses = addresses;
    message.optOutPolicy = 'FILTER';
    message.setSaveAsActivity(false);
    message.setTargetObjectId(UserInfo.getUserId());
    message.setWhatId(input.record);
    message.setTemplateId(input.templateId);
    if(input.orgAddressDefault != null) {
      message.setOrgWideEmailAddressId(input.orgAddressDefault);
    }
    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        
   	if (!Test.isRunningTest()) {
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        }
    } else {
        System.debug('Test context: email not sent.');
    }

  }
}