/**********************************************************************************
* @author       Global Desktop
* @date         04/03/2020
* @description  Helper del handler de UtilInitiatives
**********************************************************************************/
public class UtilInitiatives {

  /**
   * SINGLETON PATTERN
   */
  private static UtilInitiatives instance;

  /**
   * getInstance
   */
  public static UtilInitiatives gtInstance() {
    if (instance == null) {
      instance = new UtilInitiatives();
    }
    return instance;
  }

  /*
   * Met0d0 para pasar sonar
   */
  private UtilInitiatives() {
  }

 
   /**
  * @author Global Desktop
  * @description sendMail
  */
  public static void sendMail(String subject, String body, List<intt__Team_initiative__c> lstTeam) {
      sendMailPaquete(subject,body,lstTeam,false);
  }
   /**
  * @author Global Desktop
  * @description sendMailPaquete
  */
  public static void sendMailPaquete(String subject, String body, List<intt__Team_initiative__c> lstTeam,Boolean futuro) {

    Map<String,String> mapUser;
    mapUser = new Map<String,String>();
    List<String> emails;
    emails = new List<String>();
    Integer contEmail=0;
    final Integer limitEmail=149;
    system.debug('llegaronUSUT====='+lstTeam.size());
    for(Integer i = 0; i < lstTeam.size()&&i<1500; i++) {
      if(!mapUser.containsKey(lstTeam[i].intt__manager_team_id__c)) {

        mapUser.put(lstTeam[i].intt__manager_team_id__c,lstTeam[i].intt__manager_team_id__c);
        emails.add(lstTeam[i].intt__manager_team_id__r.id);
        contEmail=contEmail+1;
        if(contEmail>limitEmail) {
            system.debug('paqueteemail====='+emails.size());
            if(futuro==true) {
               UtilInitiatives.enviarFuture(subject,body,emails);
            } else {
                UtilInitiatives.enviar(subject,body,emails);
            }
            emails = new List<String>();
            contEmail=0;
        }
      }
    }
    if(contEmail>0) {
        system.debug('paqueteemail2====='+emails.size());
        if(futuro==true) {
            UtilInitiatives.enviarFuture(subject,body,emails);
        } else {
            UtilInitiatives.enviar(subject,body,emails);
        }
    }

  }
  @future
  public static void enviarFuture(String subject, String body,List<String> emails) {
    system.debug('Se mandaron email====='+emails.size());
    //parte la cadena de correos en 2 en caso que existan muchos emails
    List<String> Addresses=new List<String>();
    List<String> bccAddresses=new List<String>();
    
    for(Integer i=0;i<emails.size();i++)  {
        if(i<100) {
            Addresses.add(emails[i]);
        }else {
            bccAddresses.add(emails[i]);
        }
        
    }
    
    //envia los correos
    Messaging.SingleEmailMessage message;
    message = new Messaging.SingleEmailMessage();
    message.toAddresses = Addresses;
    message.ccAddresses = bccAddresses;
    //message.optOutPolicy = 'FILTER';
    message.subject = subject;
    message.htmlbody = body;
    final Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
    System.debug(messages);

    if(!test.isrunningtest()) {
      final Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
      System.debug(results);
    }


  }

  public static void enviar(String subject, String body,List<String> emails) {
      system.debug('Se mandaron email====='+emails.size());
      //envia los correos
      Messaging.SingleEmailMessage message;
      message = new Messaging.SingleEmailMessage();
      message.toAddresses = emails;
      //message.optOutPolicy = 'FILTER';
      message.subject = subject;
      message.htmlbody = body;
      final Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
      System.debug(messages);

      if(!test.isrunningtest()) {
        final Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        System.debug(results);
      }

  }

}