/*------------------------------------------------------------------------------
        Author:        Raúl Agüera
        Company:       Accenture
        Description:   Controller VF SER_PrePhoneCase

        History:
        <Date>          <Author>                <Description>
        21/02/2017      Raúl Agüera             Initial Version
---------------------------------------------------------------------------------*/
public with sharing class SER_PrePhoneCase {

  /*Declaracion de una lista para guardar los nombres de los perfiles*/
  private final list<String> LSTPROF_REDIRECT = getProfilesName();
  /*Constante para definir el tipo de codificación */
  private final static string ENCODING = 'UTF-8';

  /*Get y set del objeto Caso*/
  public Case myCase {get; set;}
  /*Get y set del string URL*/
  public String sUrl {get; set;}
  /*Get y set del string ID del contacto*/
  public String sContactId {get; set;}
  /*Get y set del string ID del cliente*/
  public String sAccountId {get; set;}
  /*Get y set del string Mailing group*/
  public String stMailgroup {get; set;}
  /*Get y set del string Outbound Milbox*/
  public String stOutboundMailbox {get; set;}

  /*Standard Controller*/
  ApexPages.StandardController stdController;

  /*----------------------------------------------------------------------
      Author:        Raúl Agüera
      Company:       Accenture
      Description:   SER_PrePhoneCase

      IN:            -
      OUT:           List<String>

      History:
      <Date>                  <Author>                <Change Description>
      28/03/2017              Raúl Agüera             Initial Version
  ------------------------------------------------------------------------*/

  public SER_PrePhoneCase(ApexPages.StandardController controller) {

    stdController = controller;
    //Recoge params Contact y Account por si la página es llamada des de estos objetos
    sContactId = System.currentPageReference().getParameters().get('def_contact_id');
    sContactId = String.isBlank(sContactId) ? '' : sContactId;
    sAccountId = System.currentPageReference().getParameters().get('def_account_id');
    sAccountId = String.isBlank(sAccountId) ? '' : sAccountId;
    system.debug('## sContactId: ' + sContactId);

  }
  /*----------------------------------------------------------------------
      Author:        Raúl Agüera
      Company:       Accenture
      Description:   Get Profiles have to be redirected.
                      (Create Custom Setting with values?)

      IN:            -
      OUT:           List<String>

      History:
      <Date>                  <Author>                <Change Description>
      28/03/2017              Raúl Agüera             Initial Version
  ------------------------------------------------------------------------*/
  private List<String> getProfilesName() {
    return new List<String> {
              'SERVICE SYSTEM ADMINISTRATOR',
              'TEST SERVICE SYSTEM ADMINISTRATOR',
              'System Administrator'
    };
  }

  /*---------------------------------------------------------------------
      Author:        Raúl Agüera
      Company:       Accenture
      Description:   Check User Profile fro redirect to Visualforce.

      IN:            -
      OUT:           PageReference

      History:
      <Date>                  <Author>                <Change Description>
      21/03/2017              Raúl Agüera             Initial Version
  -----------------------------------------------------------------------*/
  public PageReference actionRedirect() {


    boolean bRedirect = false;
    bRedirect = isUserToRedirect();

  /*        sUrl = bRedirect ?
                '/apex/SER_PhoneCase' //Redireccion para seleccionar antes Transaccional
                :
                '/500/e'; //Redirección nueva ventana nuevo Caso en modo edición
  */
    if(!Test.isRunningTest()) {
      this.presetMailingGroup();
    }
    if (bRedirect) {
      sUrl = '/apex/SER_PhoneCase';         //Redireccion para seleccionar antes Transaccional
    } else {

      System.debug('JLB - bRedirect FALSE... GM');
      System.debug('JLB - sContactId: ' + sContactId);
      System.debug('JLB - sAccountId: ' + sAccountId);

      insertCase();

    }

    //Se envian tb valores de posibles parametros recibidos por URL
    sUrl += '?nooverride=1&def_contact_id=' + sContactId + '&def_account_id=' + sAccountId;
    //if(!Test.isRunningTest())this.presetMailingGroup();
    sUrl += String.isNotBlank(this.stMailGroup) ? '&'+Label.SER_MailingGroupFieldID+'='+this.stMailGroup : '';
    sUrl += String.isNotBlank(this.stOutboundMailbox) ? '&'+Label.SER_OutboundMailboxFieldID+'='+this.stOutboundMailbox : '';

    return null;
  }

  private void insertCase () {
    // Para usuarios GM, al dar al boton NEW CASE
    // primero se crea el caso y se redirecciona.
    Case casoGM;
    casoGM = new Case();
    if (String.isNotBlank(this.stMailGroup)) {
      System.debug('JLB - MailGroup: ' + EncodingUtil.urlDecode(this.stMailGroup, ENCODING));
      casoGM.SER_MailingGroup__c = EncodingUtil.urlDecode(this.stMailGroup, ENCODING);
    }
    if (String.isNotBlank(this.stOutboundMailbox)) {
      System.debug('JLB - OutboundMailbox: ' + EncodingUtil.urlDecode(this.stOutboundMailbox, ENCODING));
      casoGM.SER_Outbound_Mailbox__c = EncodingUtil.urlDecode(this.stOutboundMailbox, ENCODING);
    }
    insert casoGM;
    //sUrl = '/'+ casoGM.Id + '/e'; //Redirección nueva ventana nuevo Caso en modo edición
    sUrl = '/'+ casoGM.Id;     //Redirección nueva ventana nuevo Caso en modo consulta

  }

  private boolean isUserToRedirect () {
    final Id ProfileId = userinfo.getProfileId();
    boolean bRedirect = false;
    for(Profile inProf : [SELECT Id, Name FROM Profile WHERE Id = :ProfileId]) {
      for (string inProfRedirect : LSTPROF_REDIRECT) {
        //Si es usuario con determinado profile se redirije para seleccionar Producto
        if (inProfRedirect.equalsIgnoreCase(inProf.Name)) {
          bRedirect = true;
        }
      }
    }
    return bRedirect;
  }
  /*----------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Preload SER_MailingGroup__c field value.

      IN:            None
      OUT:           String

      History:
      <Date>                  <Author>                <Change Description>
      13/06/2017              Juan Carlos Terrón      Initial Version.
  ------------------------------------------------------------------------*/
  public void presetMailingGroup() {
    String stUserId = '';
    stUserId = UserInfo.getUserId();

    List<SER_MailingGroup__c> listMailingGroups = new List<SER_MailingGroup__c>();
    listMailingGroups = [select Id, SER_User__c, SER_MailingGroup__c, SER_DefaultMailbox__c from SER_MailingGroup__c where SER_User__c = :stUserId];
    System.debug('JCT - LISTA DE MG : '+listMailingGroups);
    System.debug('JCT - LISTA DE MG SIZE: '+listMailingGroups.size());

    if( !listMailingGroups.isEmpty()
        && listMailingGroups.size() == 1) {
      this.stMailGroup =  String.isNotBlank(listMailingGroups[0].SER_MailingGroup__c) ? EncodingUtil.urlEncode(listMailingGroups[0].SER_MailingGroup__c, ENCODING) : '';
      this.stOutboundMailbox = String.isNotBlank(this.stMailGroup) && String.isNotBlank(listMailingGroups[0].SER_DefaultMailbox__c) ? EncodingUtil.urlEncode(listMailingGroups[0].SER_DefaultMailbox__c, ENCODING) : '';
    }
  }
}