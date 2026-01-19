/*-------------------------------------------------------------------------------
Author:        Juan Carlos Terrón
Company:       Accenture
Description:   Class EmailService_LogAnalizer_JOB

History:
<Author>                  <Date>                <Change Description>
Juan Carlos Terrón                              Initial version.
---------------------------------------------------------------------------------*/
global without sharing class EmailService_LogAnalizer_JOB implements Schedulable {
  /* Constant integer 12*/
  public static final integer DOCE = 12;
  /*-------------------------------------------------------------------------------
  Author:        Juan Carlos Terrón
  Company:       Accenture
  Description:   Method execute shedulablecontext
    IN: Schedula
  ---------------------------------------------------------------------------------*/
  global void execute(SchedulableContext scctx) {
    final Datetime fecha = Datetime.now();
    Datetime fechaformateada;
    final Map<String,Integer> counts = new Map<String,Integer>();
    List<AggregateResult>  results;
    if(fecha.hour() < DOCE) {
      results = [select count(id) number, cib_subject__c subject from cib_log__c where createddate = yesterday and cib_subject__c like 'Email Service Error%' group by cib_subject__c having count(Id) > 0 order by cib_subject__c asc];
      fechaformateada = fecha.adddays(-1);
    } else {
      results = [select count(id) number, cib_subject__c subject from cib_log__c where createddate = today and cib_subject__c like 'Email Service Error%' group by cib_subject__c having count(Id) > 0 order by cib_subject__c asc];
      fechaformateada = fecha;
    }
    Integer total;
    total = 0;
    for(AggregateResult result : results) {
      counts.put((String) result.get('subject'),(Integer) result.get('number'));
      total += (Integer) result.get('number');
    }
    String emailbody;
    if(fecha == fechaformateada) {
      emailbody = 'Informe de errores Email Service del día : '+fechaformateada.format('dd-MM-YYYY','GMT+0200')+' hasta el momento.\n\n\n';
    } else {
      emailbody = 'Informe de errores Email Service del día : '+fechaformateada.format('dd-MM-YYYY','GMT+0200')+'\n\n\n';
    }
    emailbody += 'TOTAL : ' + total+'\n\n\n';
    for(String casuistry : counts.keyset()) {
      emailbody += casuistry + ' : ' + counts.get(casuistry)+'\n';
    }
    final Boolean otherslogs = counts.containsKey('Email Service Error - Others') && counts.get('Email Service Error - Others') > 0;
    if(otherslogs) {
      List<CIB_Log__c> logs;
      emailbody += '\n\n\n--------------------------------------------------------\n\n\n';
      if(fecha.hour() < DOCE) {
        logs = [select id, createddate,cib_subject__c,cib_errormessage__c from cib_log__c where createddate = yesterday and cib_subject__c like 'Email Service Error%Others' order by createddate desc ];
      } else {
        logs = [select id, createddate,cib_subject__c,cib_errormessage__c from cib_log__c where createddate = today and cib_subject__c like 'Email Service Error%Others' order by createddate desc ];
      }
      for(CIB_Log__c log : logs) {
        emailbody += 'LOG ID : '+log.id+'\n';
        emailbody += 'LOG CREATED DATE : '+log.createddate+'\n';
        emailbody += 'LOG MESSAGE : '+log.cib_errormessage__c+'\n\n\n';
      }
      emailbody += '--------------------------------------------------------\n\n\n';
    }
    emailbody += 'Un saludo.\nFdo:El bot de correos.';

    //Email
    final Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setToAddresses(Label.EmailService_LogAnalizer_ToAddress.split(';'));
    email.setOrgWideEmailAddressId(Label.EmailService_LogAnalizer_FromAddress);
    email.setPlainTextBody(emailbody);
    email.setSubject(Label.EmailService_LogAnalizer_Subject.replace('fecha',fechaformateada.format('dd-MM-YYYY','GMT+0200')));
    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email},false);
  }
}