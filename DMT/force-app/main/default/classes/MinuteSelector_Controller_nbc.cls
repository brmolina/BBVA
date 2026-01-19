/*
*Author: Alejandro del Rio
*pagina que envía varias minutas por un determinado recordtype
*
*/
public with sharing class MinuteSelector_Controller_nbc {//NOSONAR
    /*
    *Author: Alejandro del Rio
    *numero maximo de emails en to
    *
    */
    static final Integer MAXEMAILS = Integer.valueOf(Label.NBC_minute_max_email);
    /*
    *Author: Alejandro del Rio
    *objeto NBC sobre el que crear el template
    *
    */
    public NBC__c nbcObj {get;set;}
    /*
    *Author: Alejandro del Rio
    *marca si el correo se envia para refrescar la pagina
    *
    */
    public boolean correoEnviado {get;set;}
    /*
    *Author: Alejandro del Rio
    *marca si está en proceso de envio
    *
    */
    public boolean sending {get;set;}
    /*
    *Author: Alejandro del Rio
    *marca si no contiene minuta
    *
    */
    public boolean minuteNotFound {get;set;}
    /*
    *Author: Alejandro del Rio
    *ID de la visita
    *
    */
    public Id idnbc {get;set;}

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
       CAMBIO Alejandro del Rio
     * ids oportunidades seleccionadas
     */
    public String opportunitysIDs {get;set;}
    /**
     * Observaciones del usuario que se incluyen en el email
     */
    public String observations {get; set;}

      /**
     * Alejandro del Rio: lista de oportundiades asociadas al comite 
     */
    public List<WVL_cls_wraperOpportunity> lstWprOpor {get; set;}//NOSONAR
    /**
     * Alejandro del Rio: muestra un mensaje de error en la pagina si no selecciona al menos una oportundiad
    */
    public Boolean selOpportunity {get;set;}
    /*
    *Author: Alejandro del Rio
    *Constructor del controller
    *
    */
    public MinuteSelector_Controller_nbc(ApexPages.StandardController stdController) {
        System.debug(stdController);
        observations = '';
        minuteNotFound = true;
        sending = false;
        idnbc = ApexPages.currentPage().getParameters().get('Id');
        //Alejandro del Rio
        lstWprOpor  =     new List<WVL_cls_wraperOpportunity>();
        Final List<Profile> lCurrentProfile = [SELECT id, name FROM Profile WHERE id = :UserInfo.getProfileId()];

        if(lCurrentProfile != null && !lCurrentProfile.isEmpty() && (lCurrentProfile.get(0).name.contains('BBVA Desktop') || lCurrentProfile.get(0).name.equals('System Administrator'))) {

            minuteNotFound = false;
            final List<NBC__c> lNBC = new List<NBC__c>([select id, Committee_End_Date__c, Name,
                                                                          Committee_Start_Date__c, NBC_Region_type__c
                                                                          from NBC__c where Id = :idnbc]);

            nbcObj = lNBC[0];

            if (nbcObj.Id == null) {
                minuteNotFound = true;
            } else {
                fileName = 'Minute-' + nbcObj.Name + '.pdf';
                urlMinute = '/apex/NBC_Minute_NBC?id=' + idnbc + '&action=download&fileName=' + fileName;
               final LIst<Opportunity>        lstOportunity          =  [ SELECT id,name
                                                                     FROM Opportunity
                                                                     WHERE Committee_id__c=:nbcObj.Id];
                //carga el wraper con las oportundiades
                for(Opportunity  itemOportunidad: lstOportunity) {
                    final WVL_cls_wraperOpportunity objOportunidad     =  new WVL_cls_wraperOpportunity();
                    objOportunidad.bolSelected                   =  true;
                    objOportunidad.strId                         =  itemOportunidad.id;
                    objOportunidad.strNombre                     =  itemOportunidad.Name;
                    lstWprOpor.add(objOportunidad);

                }
            }
        }

    }

   /***********************************************************************
    *@Author:      Alejandro del Rio- Alejandro del Rio
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
    *Author: Alejandro del Rio
    *envia email
    *
    */
    public void sendMail() {


        loadIdOpportunitys();
        //si debe mostrar un mensaje de error se sale de la logica
        if(selOpportunity) {
            return;
        }

        if (!minuteNotFound) {
            List<String> lEmailsTo;
            lEmailsTo = new List<String>();
            sending = true;
            Final List<String> groupList= new List<String>();
            groupList.add(String.valueOf(Label.SP_Users_Group_DevName));
            groupList.add(String.valueOf(Label.GroupNBCVirtualDevName));
            Final List<GroupMember> members=new List<GroupMember>([SELECT id, Group.Name, UserOrGroupId  FROM GroupMember where Group.DeveloperName  =:groupList])  ;
            Final List<String> usersId= new List<String>();
            Final List<OpportunityTeamMember> opp=new List<OpportunityTeamMember>([SELECT id, UserId FROM OpportunityTeamMember WHERE OpportunityId =: opportunitysIDs]) ;
            for(GroupMember member : members) {
                usersId.add(member.UserOrGroupId);
            }
            for(OpportunityTeamMember member2 : opp) {
                usersId.add(member2.UserId);
            }
            Final List<user> usermails=new List<user>([SELECT id,Email  FROM user WHERE id =: usersId]);
            for(user usermail : usermails) {
                lEmailsTo.add(usermail.Email);
            }
            correoEnviado = sendTemplateEmail(nbcObj, lEmailsTo, observations,opportunitysIDs);
        }
    }

    private static boolean sendTemplateEmail(NBC__c nbcObj, List<String> lEmailsTo, String observations,String opportunitysIDs) {

      boolean enviado;
      enviado = false;

        try {
            Messaging.SingleEmailMessage email;
            email   = generateEmail (nbcObj, observations,opportunitysIDs);
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

    private static Messaging.SingleEmailMessage generateEmail (NBC__c nbcObj, String observations,String opportunitysIDs) {

      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      try {

          email = completeEmail (email, nbcObj, observations);
          email.setSaveAsActivity(false);
          Messaging.EmailFileAttachment pdfAttach;
          pdfAttach = generatePDFAttach (nbcObj,opportunitysIDs);

          if(pdfAttach != null) {
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { pdfAttach });
          }


      } catch(Exception ex) {
          System.debug('ERROR: ' + ex.getMessage());
      }

      return email;
    }

    private static String stringGetBody (NBC__c nbcObj, String observations) {

      String htmlBodyFinal;
      htmlBodyFinal = '';
      final String htmlObservations = observations == '' ? '' : '<br>Observations: <br>' + observations + '<br>'; //NOSONAR

      if(nbcObj.Id != null) {
          htmlBodyFinal = '<div class="content" style="color: rgb(102,102,102); font-size: 17px;  font-family: \'Arial\'; padding:10px; width:80%;"> <div class="textHeader" style="padding:10px;"> <img src="https://bbvacibsales--c.eu6.content.force.com/servlet/servlet.ImageServer?id=01558000002FsnT&oid=00D570000003yeK" alt="BBVA">  <h2> '+nbcObj.Name+' </h2> </div> <div class="textBody" style="padding:20px 30px; border: 1px solid #00529B; border-radius:5px; width:60%; margin:5% 0 0 18%;"> <article> Dear all,<br><br> Please, find attached NBC Minutes.<br>' + htmlObservations + '<br> Best regards.<br><br></article> </div> </div>';
      }

      String htmlBody;
      htmlBody = '<![CDATA[ <html lang="es">'+
              '<meta content="text/html; charset=UTF-8" http-equiv="Content-Type" />'+
              htmlBodyFinal +
              '</html>';
      return htmlBody;
    }

    private static Messaging.EmailFileAttachment generatePDFAttach (NBC__c nbcObj,String opportunitysIDs) {
        PageReference pdf;
        Messaging.EmailFileAttachment attach;

        if(nbcObj.Id != null) {
            pdf = Page.NBC_Minute_NBC;
            pdf.getParameters().put('id',nbcObj.ID);
            pdf.getParameters().put('Opps',opportunitysIDs);

        }

        if (pdf != null) {
            Blob body;
            try {
                body = pdf.getContentAsPDF();
            } catch (VisualforceException e) {
                body = Blob.valueOf('Please contact your administrator.');
            }


            attach = new Messaging.EmailFileAttachment();
            if(nbcObj.Id != null) {
                attach.setFileName('Minute-' + nbcObj.Name + '.pdf');
            }
            attach.setBody(body);
        }

        return attach;
    }

    private static Messaging.SingleEmailMessage completeEmail (Messaging.SingleEmailMessage emailRecive, NBC__c nbcObj, String observations) {
        Messaging.SingleEmailMessage email;
        email = emailRecive;
        email.setHtmlBody(stringGetBody(nbcObj, observations));

        if(nbcObj.Id != null) {
            email.setSubject(nbcObj.Name + ' Minutes');
            email.setSenderDisplayName('NBC ' + nbcObj.NBC_Region_type__c);
            email.setReplyTo('nbc.' + nbcObj.NBC_Region_type__c + '@bbva.com');
        }
        return email;
    }

    /***************************************************************************
    * @name: WVL_cls_wraperOpportunity
    * @version: v1.0
    * @creation date: 15/03/2019
    * @author: Alejandro del Rio
    * @description:se creo un graper para mostrar las oportunides en la pagina VF
    *****************************************************************************/

   public class WVL_cls_wraperOpportunity {
       /*
        *Author: Alejandro del Rio
        *check seleccion del registro
        *
        */
       public Boolean bolSelected {get;set;}
              /*
        *Author: Alejandro del Rio
        *identificador de la oportunidad
        *
        */
       public String  strId {get;set;}
              /*
        *Author: Alejandro del Rio
        *nombre de la oportunidad
        *
        */
       public String  strNombre {get;set;}
   }
}