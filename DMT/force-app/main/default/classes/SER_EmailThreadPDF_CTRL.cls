/*--------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Controller for the emailthreadpdf page to manage the records displayed.

    History:
    <Date>          <Author>                <Description>
----------------------------------*/
public with sharing class SER_EmailThreadPDF_CTRL {
  /* Case accessor */
  public Case cASO {get; set;}
  /* EmailMessage accessor */
  public EmailMessage firstemail {get; set;}
  /* String accessor */
  public String stBody {get; set;}
  /* List String accessor */
  transient public List<String> emailMesgBody {get; set;}
  /* List EmailMessage accessor */
  transient public List<EmailMessage> emailMesg {get; set;}

  /* SER_EmailThreadPDF_CTRL method no input*/
  public SER_EmailThreadPDF_CTRL() {
  }

  /* SER_EmailThreadPDF_CTRL method with input*/
  public SER_EmailThreadPDF_CTRL(ApexPages.StandardController stdController) {
    this.cASO = new Case();
    this.cASO =
    [
      select Id,Subject,
      (
        select Id,Subject,CreatedDate,
        HtmlBody,TextBody,ThreadIdentifier,
        FromAddress,ToAddress,CCAddress,BCCAddress
        from EmailMessages
        order by CreatedDate desc
      )

      from Case
      where Id = :stdController.getId()
                  limit   1
    ][0];

    System.debug('JCT - CASO : '+this.cASO);

    this.emailMesgBody = new List<String>();

    if(cASO.EmailMessages.isempty()) {
      this.emailMesg = new List<EmailMessage>();
    } else {
      this.emailMesg = new List<EmailMessage>(cASO.EmailMessages);
    }
    System.debug('JCT - LISTA de EM : '+emailMesg);

    this.stBody = '';
    if(this.emailMesg!= null && !this.emailMesg.isempty()) {
      this.firstemail = this.emailMesg[0];
      if(String.isNotBlank(this.emailMesg[0].HtmlBody)) {
        this.emailMesgBody.add(this.emailMesg[0].HtmlBody);
      } else if(String.isNotBlank(this.emailMesg[0].TextBody)) {
        this.emailMesgBody.add(this.emailMesg[0].TextBody);
      }
    }
  }

  /*-------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method that transforms Current PAge content into PDF attachment.

      IN:            none
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      05/07/2017				Juan Carlos Terrón		Initial version
  -----------------*/
  public void loadPDF() {
    Blob blobPageContent;
    blobPageContent = ApexPages.currentPage().getContent();
    final Attachment newATT = new Attachment();
    newATT.Name = this.cASO.Subject + Datetime.now();
    newATT.Body = blobPageContent;
    //newATT.ContentType = 'application/pdf';
    newATT.ParentId = this.cASO.Id;

    insert newATT;
  }
}