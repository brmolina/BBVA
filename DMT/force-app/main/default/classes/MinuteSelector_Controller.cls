/*
*Author: Vass
*pagina que envía varias minutas por un determinado recordtype
*
*/
public with sharing class MinuteSelector_Controller {
    /*
    *Author: Vass
    *numero maximo de emails en to
    *
    */
    static final Integer MAXEMAILS = Integer.valueOf(Label.NBC_minute_max_email);
    /*
    *Author: Vass
    *objeto visita sobre el que creqar el template
    *
    */
    public dwp_kitv__Visit__c visitObj {get;set;}
    /*
    *Author: Vass
    *marca si el correo se envia para refrescar la pagina
    *
    */
    public boolean correoEnviado {get;set;}
    /*
    *Author: Vass
    *marca si está en proceso de envio
    *
    */
    public boolean sending {get;set;}
    /*
    *Author: Vass
    *marca si no contiene minuta
    *
    */
    public boolean minuteNotFound {get;set;}
    /*
    *Author: Vass
    *ID de la visita
    *
    */
    public Id idVisit {get;set;}

    /**
     * Nombre del archivo pdf a descargar
     */
    public String fileName {get;set;}

    /**
     * url de la visualforce de la minuta
     */
    public String urlMinute {get;set;}
    /**
     * url del PDF
     */
    public String urlMinutePDF {get;set;}
    /**
       CAMBIO William Dorado
     * ids oportunidades seleccionadas
     */
    public String opportunitysIDs {get;set;}
    /**
     * Observaciones del usuario que se incluyen en el email
     */
    public String observations {get; set;}

      /**
     * William Dorado: lista de oportundiades asociadas al comite 
     */
    public List<WVL_cls_wraperOpportunity> lstWprOpor {get; set;}//NOSONAR
    /**
     * William Dorado: muestra un mensaje de error en la pagina si no selecciona al menos una oportundiad
    */
    public Boolean selOpportunity {get;set;}
    /*
    *Author: Vass
    *Constructor del controller
    *
    */
    public MinuteSelector_Controller(ApexPages.StandardController stdController) {
        System.debug(stdController);
        observations = '';
        minuteNotFound = true;
        sending = false;
        idVisit = ApexPages.currentPage().getParameters().get('Id');
        //william dorado
        lstWprOpor  =     new List<WVL_cls_wraperOpportunity>();
        
        List<Profile> lCurrentProfile = [SELECT id, name FROM Profile WHERE id = :UserInfo.getProfileId()];

        if(lCurrentProfile != null && !lCurrentProfile.isEmpty() && (lCurrentProfile.get(0).name.contains('BBVA Desktop') || lCurrentProfile.get(0).name.equals('System Administrator'))) {

            minuteNotFound = false;
            final List<dwp_kitv__Visit__c> lVisit = new List<dwp_kitv__Visit__c>([select id, Name, Committee_id__c, Committee_id__r.Committee_End_Date__c, Committee_id__r.Name,
                                                                          dwp_kitv__visit_status_type__c, RecordType.name, dwp_kitv__account_id__r.id,
                                                                          Committee_id__r.Committee_Start_Date__c, Committee_id__r.NBC_Region_type__c,
                                                                          (SELECT id, dwp_kitv__contact_email_desc__c FROM dwp_kitv__Visit_Management_Teams__r),
                                                                          (SELECT id, dwp_kitv__contact_email_desc__c FROM dwp_kitv__Visit_Contacts__r)
                                                                          from dwp_kitv__Visit__c where Id = :idVisit]);

            visitObj = lVisit[0];

            if (visitObj.Committee_id__c == null) {
                minuteNotFound = true;
            } else {
                fileName = 'Minute-' + visitObj.Committee_id__r.Name + '.pdf';
                urlMinute = '/apex/NBC_Minute?id=' + idVisit + '&action=download&fileName=' + fileName;
                
                
                //CAMBIO William Dorado CAMBIO:Se agrega una consulta a las oportundiades del comite y se crea un wraper para mostrar estos registros en la pagina
                final LIst<Opportunity>        lstOportunity          =  [ SELECT id,name
                                                                     FROM Opportunity 
                                                                     WHERE Committee_id__c=:visitObj.Committee_id__c];
                //carga el wraper con las oportundiades
                for(Opportunity  itemOportunidad: lstOportunity) {
                    final WVL_cls_wraperOpportunity objOportunidad     =  new WVL_cls_wraperOpportunity();
                    
                    objOportunidad.bolSelected                   =  true;
                    objOportunidad.strId                         =  itemOportunidad.id;
                    objOportunidad.strNombre                     =  itemOportunidad.Name;
                    
                    lstWprOpor.add(objOportunidad);      

                }
                

                //FIN CAMBIOS

                 
            }
        }

    }

   /***********************************************************************
    *@Author:      Henry William Dorado- Accenture
    * @Method:      loadIdOpportunitys
    * @Return:      Void
    * @Paramerers:  Void
    * @Description: Carga los ids de las oportundades seleccionadas en la variable opportunitysIDs, 
    * esta variable se envia a la VF NBC_Minuta para generar un PDF con la informacion de esas opportundiades
    * ,muestra un mensaje de error en caso de que el usuario no seleccione una opportunidad
    ************************************************************************/
    
    public void loadIdOpportunitys() {
        
        opportunitysIDs                        =    '';
        selOpportunity                         =    true;
   
        //valida que seleccione almenos una oportundiad 
        for(Integer i=0;i< lstWprOpor.size();i++) {  
               if(lstWprOpor[i].bolSelected==true) {
                    selOpportunity               =    false;
                   
                    //Carga los ids de las opportunidades como parametros en la VF
         
                    opportunitysIDs               =    opportunitysIDs+lstWprOpor[i].strId;
                    if(i<(lstWprOpor.size()-1)) {
                        opportunitysIDs            =    opportunitysIDs+':';
                    
                    }
              }  
        }
         
        //arma la url del pdf de la minuta
        final String baseUrl = System.URL.getOrgDomainURL().toExternalForm();
        system.debug(baseUrl);

        if(OpportunitysIDs != null && OpportunitysIDs.isWhitespace()==false) {
          urlMinutePDF=baseUrl+ urlMinute+'&Opps='+OpportunitysIDs;
        } else {
            urlMinutePDF=''; 
        }
        
  
    }
    /*
    *Author: Vass
    *envia email
    *
    */
    public void sendMail() {


        //CAMBIO William Dorado
        loadIdOpportunitys();
        
        //si debe mostrar un mensaje de error se sale de la logica
        if(selOpportunity) {
            return;
        }
        //FIN CAMBIO 

        List<String> lEmailsTo;
        lEmailsTo = new List<String>();
        sending = true;
        
        
        if (!minuteNotFound) {
            for(dwp_kitv__Visit_Management_Team__c visitTeam : visitObj.dwp_kitv__Visit_Management_Teams__r) {
                lEmailsTo.add(visitTeam.dwp_kitv__contact_email_desc__c);
            }
            for(dwp_kitv__Visit_Contact__c visitContact : visitObj.dwp_kitv__Visit_Contacts__r) {
                lEmailsTo.add(visitContact.dwp_kitv__contact_email_desc__c);
            }
            correoEnviado = sendTemplateEmail(visitObj, lEmailsTo, observations,opportunitysIDs);
        }
        System.debug(lEmailsTo);
    }

    private static boolean sendTemplateEmail(dwp_kitv__Visit__c visitObj, List<String> lEmailsTo, String observations,String opportunitysIDs) {

      boolean enviado;
      enviado = false;

        try {
            Messaging.SingleEmailMessage email;
            email   = generateEmail (visitObj, observations,opportunitysIDs);
            enviado = splitEmails (email, lEmailsTo);

        } catch(Exception ex) {
            enviado = false;
        }
        return enviado;
    }

    private static boolean splitEmails (Messaging.SingleEmailMessage email, List<String> lEmailsTo) {

        boolean correoEnviado1;
        correoEnviado1 = true;
        Integer count = 0;
        Messaging.SingleEmailMessage emailSplit;
        emailSplit = email;

        List<String> lEmailsToEmail;
        lEmailsToEmail = new List<String>();

        emailSplit.setCcAddresses(new List<String>());
        emailSplit.setBccAddresses(new List<String>());
        emailSplit.setToAddresses(new List<String>());
        Messaging.SingleEmailMessage[] messages;

        for(Integer i = 0; i < lEmailsTo.size(); i++) {
            if(count < MAXEMAILS) {
                count ++;
                lEmailsToEmail.add(lEmailsTo.get(i));
            } else {
                count = 0;
                lEmailsToEmail.add(lEmailsTo.get(i));
                emailSplit.setBccAddresses(lEmailsToEmail);
                messages = new List<Messaging.SingleEmailMessage> { emailSplit };
                lEmailsToEmail = new List<String>();

                Messaging.SendEmailResult[] results;
                results = Messaging.sendEmail(messages);

                if (!results[0].isSuccess() && lEmailsToEmail.isEmpty()) {
                  correoEnviado1 = false;
                }
            }
        }
        if(count != 0) {
            emailSplit.setBccAddresses(lEmailsToEmail);
            messages = new List<Messaging.SingleEmailMessage> { emailSplit };

            Messaging.SendEmailResult[] results;
            results = Messaging.sendEmail(messages);

            if (!results[0].isSuccess()) {
              correoEnviado1 = false;
            }
        }

        return correoEnviado1;
    }

    private static Messaging.SingleEmailMessage generateEmail (dwp_kitv__Visit__c visitObj, String observations,String opportunitysIDs) {

      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      try {

          email = completeEmail (email, visitObj, observations);
          email.setSaveAsActivity(false);
          Messaging.EmailFileAttachment pdfAttach;
          pdfAttach = generatePDFAttach (visitObj,opportunitysIDs);

          if(pdfAttach != null) {
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { pdfAttach });
          }


      } catch(Exception ex) {
          System.debug('ERROR: ' + ex.getMessage());
      }

      return email;
    }

    private static String stringGetBody (dwp_kitv__Visit__c visitObj, String observations) {

      String htmlBodyFinal;
      htmlBodyFinal = '';
      final String htmlObservations = observations == '' ? '' : '<br>Observations: <br>' + observations + '<br>'; //NOSONAR

      if(visitObj.Committee_id__c != null) {
          htmlBodyFinal = '<div class="content" style="color: rgb(102,102,102); font-size: 17px;  font-family: \'Arial\'; padding:10px; width:80%;"> <div class="textHeader" style="padding:10px;"> <img src="https://bbvacibsales--c.eu6.content.force.com/servlet/servlet.ImageServer?id=01558000002FsnT&oid=00D570000003yeK" alt="BBVA">  <h2> '+visitObj.Committee_id__r.Name+' </h2> </div> <div class="textBody" style="padding:20px 30px; border: 1px solid #00529B; border-radius:5px; width:60%; margin:5% 0 0 18%;"> <article> Dear all,<br><br> Please, find attached NBC Minutes.<br>' + htmlObservations + '<br> Best regards.<br><br></article> </div> </div>';
      }

      String htmlBody;
      htmlBody = '<![CDATA[ <html lang="es">'+
              '<meta content="text/html; charset=UTF-8" http-equiv="Content-Type" />'+
              htmlBodyFinal +
              '</html>';
      return htmlBody;
    }

    private static Messaging.EmailFileAttachment generatePDFAttach (dwp_kitv__Visit__c visitObj,String opportunitysIDs) {
        PageReference pdf;
        Messaging.EmailFileAttachment attach;

        if(visitObj.Committee_id__c != null) {
         
            pdf = Page.NBC_Minute;
            pdf.getParameters().put('id',visitObj.ID);
            //CAMBIO: William Dorado carga los ids de las opportunidades como parametros en la VF
            pdf.getParameters().put('Opps',opportunitysIDs);
            //FIN CAMBIOS

        }

        if (pdf != null) {
            Blob body;
            try {
                body = pdf.getContentAsPDF();
            } catch (VisualforceException e) {
                body = Blob.valueOf('Please contact your administrator.');
            }


            attach = new Messaging.EmailFileAttachment();
            if(visitObj.Committee_id__c != null) {
                attach.setFileName('Minute-' + visitObj.Committee_id__r.Name + '.pdf');
            }
            attach.setBody(body);
        }

        return attach;
    }

    private static Messaging.SingleEmailMessage completeEmail (Messaging.SingleEmailMessage emailRecive, dwp_kitv__Visit__c visitObj, String observations) {
        Messaging.SingleEmailMessage email;
        email = emailRecive;
        email.setHtmlBody(stringGetBody(visitObj, observations));

        if(visitObj.Committee_id__c != null) {
            email.setSubject(visitObj.Committee_id__r.Name + ' Minutes');
            email.setSenderDisplayName('NBC ' + visitObj.Committee_id__r.NBC_Region_type__c);
            email.setReplyTo('nbc.' + visitObj.Committee_id__r.NBC_Region_type__c + '@bbva.com');
        }
        return email;
    }

    /*************************************************************************** 
    * @name: WVL_cls_wraperOpportunity
    * @version: v1.0
    * @creation date: 15/03/2019
    * @author: Henry William Dorado, Accenture 
    * @description:se creo un graper para mostrar las oportunides en la pagina VF
    *****************************************************************************/

   public class WVL_cls_wraperOpportunity {
       /*
        *Author: Accenture
        *check seleccion del registro
        *
        */
       public Boolean bolSelected {get;set;}
              /*
        *Author: Accenture
        *identificador de la oportunidad
        *
        */
       public String  strId {get;set;}
              /*
        *Author: Accenture
        *nombre de la oportunidad
        *
        */
       public String  strNombre {get;set;} 
   }
}