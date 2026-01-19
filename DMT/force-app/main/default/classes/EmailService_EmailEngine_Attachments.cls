/*-------------------------------------------------------------------------------
Author:        Juan Carlos Terrón
Company:       Accenture
Description:   Method that insert Attachments Email for Email Service

History:
<Author>                  <Date>                <Change Description>
Juan Carlos Terrón                              Initial version.
---------------------------------------------------------------------------------*/
public with sharing class EmailService_EmailEngine_Attachments {
  /* Methods Get/Set Inbound Email */
  public Messaging.InboundEmail inbound {get;set;}
  /* Methods Get/Set Attachments */
  public List<Attachment> attachments {get;set;}
  /* Methods Get/Set emailattachments */
  public List<Attachment> emailattachments {get;set;}
  /* Methods Get/Set cidAttachments */
  public Map<String,Attachment> cidAttachments {get;set;}
  /* Methods Get/Set contentversions */
  public List<ContentVersion> contentversions {get;set;}
  /* Methods Get/Set cidcontversions */
  public Map<String,ContentVersion> cidcontversions {get;set;}
  /* Methods Get/Set fullcontversions */
  public Map<Id,ContentVersion> fullcontversions {get;set;}
  /* Methods Get/Set fullcontversions */
  public String businessType {get;set;}
  /* Constant 'Content-type'*/
  public static final String CNT_TYP= 'Content-type';
  /* Constant 'Content-ID'*/
  public static final String CNT_ID= 'Content-ID';
  /* Constant Max length email*/
  public static final integer MAXLENGTH= 130000;
  /* Constant Min size Attachment*/
  public static final integer MINSIZE = 4000;
/*-------------------------------------------------------------------------------
Author:        Juan Carlos Terrón
Company:       Accenture
Description:   Method Create EmailEngine Attachments
    IN: Email Wrapper
---------------------------------------------------------------------------------*/
  public EmailService_EmailEngine_Attachments (InboundEmailWrapper wrapper) {
    System.debug('EmailService_EmailEngine_Attachments - Constructor');//NOSONAR
    this.inbound = wrapper.email;
    this.attachments = new List<Attachment>();
    this.emailattachments = new List<Attachment>();
    this.contentversions = new List<ContentVersion>();
    this.cidAttachments = new Map<String,Attachment>();
    this.cidcontversions = new Map<String,ContentVersion>();
    this.fullcontversions = new Map<Id,ContentVersion>();
    this.businessType = wrapper.businessType;
    this.setTextAttachments();
    this.setBinaryAttachments();
  }
  private void setTextAttachments() { //NOSONAR
    System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments');//NOSONAR
    final Boolean hasTextAttach = (this.inbound.textAttachments == null) == false;
    System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments - hasTextAttach : '+hasTextAttach);//NOSONAR
    if(hasTextAttach) {
      for(Messaging.InboundEmail.TextAttachment att : this.inbound.textAttachments) {
        System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments - length: '+att.body.length());//NOSONAR
        final Attachment newAttachment = new Attachment();
        final Attachment newEmailAttach = new Attachment();
        newAttachment.Name = att.fileName;
        newEmailAttach.Name = att.fileName;
        System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments - Name : '+newAttachment.Name);//NOSONAR
        newAttachment.Body = Blob.valueOf(att.Body);
        newEmailAttach.Body = Blob.valueOf(att.Body);
        System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments - Body : '+newAttachment.Body);//NOSONAR
        final Boolean hasHeaders = (att.headers == null) == false;
        System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments - hasHeaders : '+hasHeaders);//NOSONAR
        if(hasHeaders) {
          final Map<String,String> headers = this.getAttachmentHeaders(att.headers);
          final Boolean hasContentType = headers.containsKey(CNT_TYP) && headers.get(CNT_TYP) != null;
          System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments - hasContentType : '+hasContentType);//NOSONAR
          if(hasContentType) {
            newAttachment.ContentType = headers.get(CNT_TYP);
            newEmailAttach.ContentType = headers.get(CNT_TYP);
            System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments - ContentType : '+newAttachment.ContentType);//NOSONAR
          }
          final Boolean hasContentId = headers.containsKey(CNT_ID) && headers.get(CNT_ID) != null;
          System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments - hasContentId : '+hasContentId);//NOSONAR
          if(hasContentId) {
            final String contentid = headers.get(CNT_ID);
            this.cidAttachments.put(contentid,newAttachment);
            this.emailattachments.add(newEmailAttach);
            this.createFile(newAttachment,contentid);
            System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments - contentid : '+contentid);//NOSONAR
          } else {
            this.attachments.add(newAttachment);
            this.emailattachments.add(newEmailAttach);
            this.createFile(newAttachment,'');
          }
        } else {
          System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments - No Headers');//NOSONAR
          this.attachments.add(newAttachment);
          this.emailattachments.add(newEmailAttach);
          this.createFile(newAttachment,'');
        }
      }
    }
  }
  private void setBinaryAttachments() { //NOSONAR
      System.debug('EmailService_EmailEngine_Attachments - Set Binary Attachments');//NOSONAR
      final Boolean hasBinaryAttach = (this.inbound.binaryAttachments == null) == false;
      if(hasBinaryAttach) {
          for(Messaging.InboundEmail.BinaryAttachment att : this.inbound.binaryAttachments) {
              System.debug('EmailService_EmailEngine_Attachments - Set Binary Attachments - size :'+att.body.size());//NOSONAR
              //System.debug('EmailService_EmailEngine_Attachments - Set Text Attachments - emailSize: '+emailSize);//NOSONAR*/
              final Attachment newAttachment = new Attachment();
              final Attachment newEmailAttach = new Attachment();
              newAttachment.Name = att.fileName;
              newEmailAttach.Name = att.fileName;
              System.debug('EmailService_EmailEngine_Attachments - Set Binary Attachments - Name :'+newAttachment.Name);//NOSONAR 
              newAttachment.Body = att.Body;
              newEmailAttach.Body = att.Body;
              System.debug('EmailService_EmailEngine_Attachments - Set Binary Attachments - Body :'+newAttachment.Body);//NOSONAR 
              final Boolean hasHeaders = (att.headers == null) == false;
              System.debug('EmailService_EmailEngine_Attachments - Set Binary Attachments - hasHeaders :'+hasHeaders);//NOSONAR 
              System.debug('EmailService_EmailEngine_Attachments - Set Binary Attachments - businessType :'+businessType);//NOSONAR 
              if(businessType == null && att.body.size() > MINSIZE) {
                  if(hasHeaders) {
                      final Map<String,String> headers = this.getAttachmentHeaders(att.headers);
                      final Boolean hasContentType = headers.containsKey(CNT_TYP) && headers.get(CNT_TYP) != null;
                      System.debug('EmailService_EmailEngine_Attachments - Set Binary Attachments - hasContentType :'+hasContentType);//NOSONAR
                      if(hasContentType) {
                          newAttachment.ContentType = headers.get(CNT_TYP);
                          newEmailAttach.ContentType = headers.get(CNT_TYP);
                          System.debug('EmailService_EmailEngine_Attachments - Set Binary Attachments - ContentType :'+newAttachment.ContentType);//NOSONAR
                      }
                      final Boolean hasContentId = headers.containsKey(CNT_ID) && headers.get(CNT_ID) != null;
                      if(hasContentId) {
                          final String contentid = headers.get(CNT_ID);
                          this.cidAttachments.put(contentid,newAttachment);
                          this.emailattachments.add(newEmailAttach);
                          this.createFile(newAttachment,contentid);
                          System.debug('EmailService_EmailEngine_Attachments - Set Binary Attachments - contentid :'+contentid);//NOSONAR
                      } else {
                          this.attachments.add(newAttachment);
                          this.emailattachments.add(newEmailAttach);
                          this.createFile(newAttachment,'');
                      }
                  } else {
                      this.attachments.add(newAttachment);
                      this.emailattachments.add(newEmailAttach);
                      this.createFile(newAttachment,'');
                  }
              } System.debug('EmailService_EmailEngine_Attachments - Set Binary Attachments - less than MINSIZE');//NOSONAR
          }
      }
  }
  private void createFile(Attachment att, String cid) {
    final ContentVersion cvs = new ContentVersion();
    cvs.ContentLocation = 'S'; 
    cvs.Title = att.Name;
    cvs.pathonclient = att.Name;
    cvs.versiondata = EncodingUtil.base64Decode(Encodingutil.base64Encode(att.body));
    if(cvs.versiondata != null && cvs.versiondata.size() > 0) {
      if(String.isnotblank(cid)) {
        System.debug('EmailService_EmailEngine_Attachments - createFile - CID is not blank : '+cid);//NOSONAR  
        this.cidcontversions.put(cid,cvs);
      } else {
        System.debug('EmailService_EmailEngine_Attachments - createFile - CID is blank : '+cid);//NOSONAR
        this.contentversions.add(cvs);
      }
    }
  }
  private Map<String,String> getAttachmentHeaders(List<Messaging.InboundEmail.Header> headers) {
    System.debug('EmailService_EmailEngine_Attachments - Get Attachment Headers - start');//NOSONAR
    final Map<String,String> result = new Map<String,String>();
    if((headers == null) == false) {
      for(Messaging.InboundEmail.Header header : headers) {
        System.debug('EmailService_EmailEngine_Attachments - Get Attachment Headers - Name : '+header.name);//NOSONAR
        System.debug('EmailService_EmailEngine_Attachments - Get Attachment Headers - Value : '+header.value);//NOSONAR
        result.put(header.name,header.value);
      }
    }
    return result;
  }
/*-------------------------------------------------------------------------------
  Author:        Juan Carlos Terrón
  Company:       Accenture
  Description:   Method Load Attachments
      IN: Id: Case Id, String: Email body
      OUT: String 
---------------------------------------------------------------------------------*/
  public String loadAttachments(Id caseId, String htmlbody) {
    System.debug('EmailService_EmailEngine_Attachments - Load Attachments - caseId : '+caseId);//NOSONAR
    System.debug('EmailService_EmailEngine_Attachments - Load Attachments - htmlbody : '+htmlbody);//NOSONAR
    String parsedHtmlBody;
    parsedHtmlBody = '';
    parsedHtmlBody = htmlbody;
    for(Attachment att : this.attachments) {
      att.ParentId = caseId;
    }
    for(Attachment att : this.cidAttachments.values()) {
      att.ParentId = caseId;
    }
    if(this.contentversions.isempty() == false) {
      System.debug('EmailService_EmailEngine_Attachments - Load Attachments - CONTENT CONTEVERSIONS SIZE : '+this.contentversions.size());//NOSONAR
      insert this.contentversions; //Insertamos FILES

      final Set<Id> contentversionids = new Set<Id>(); //IDS de lso contentversions
      insert contentVersion(contentversionids, caseId);
    }
    if(this.cidcontversions.isempty() == false) {

      System.debug('EmailService_EmailEngine_Attachments - Load Attachments - CID CONTENT CONTEVERSIONS SIZE : '+this.cidcontversions.size());//NOSONAR
      insert this.cidcontversions.values();//Insertamos los content versions

      final Map<String,ContentDistribution> ciddistributions = new Map<String,ContentDistribution>();//Mapa de CID-ContentDistribution vacio apra rellenar
      //final List<ContentDistribution> distributions = new List<ContentDistribution>();//Lista de ContentDistribution a rellenar
      final List<ContentDocumentLink> links = new List<ContentDocumentLink>();//Lista de Links a rellenar

      final Set<String> versionids = new Set<String>();//Set de Id de Contentversion para filtrar la query sobre la que iterar
      final Map<String,String> cidversionids = new Map<String,String>();//Mapa de CID-Id de Content version para mapear lo demás

      for(String versioncid : this.cidcontversions.keyset()) {//Iteramos sobre el keyset mapa CID-ContentVersion 
        final String versionid = String.valueof(this.cidcontversions.get(versioncid).id);
        versionids.add(versionid);//Guardamos el id en el set
        cidversionids.put(versioncid,versionid);//Guardamos el par CID-Version ID
        cidversionids.put(versionid,versioncid);//Guardamos el par Version ID-CID
      }//Cierre de bucle
      for(ContentVersion version : [select id, contentdocumentid from ContentVersion where id in :versionids]) {//Iteramos sobre la query filtrada por el set de ids
        links.add(this.createContentDocumentLink(version.contentdocumentid,caseId));//creo y añado el link a su lista
        ciddistributions.put(cidversionids.get(version.id),this.createContentDistribution(version.id));//creo y añado el content distribution a su mapa
        this.fullcontversions.put(version.id,version);
      }//cierre de bucle

      insert links;//inserto los links
      parsedHtmlBody = createParsedHtmlBody(ciddistributions, parsedHtmlBody);
    }
    if(parsedHtmlBody.length() > MAXLENGTH) {
      System.debug('EmailService_EmailEngine_Attachments - Load Attachments - Max Char Size Exceeded');//NOSONAR
      parsedHtmlBody = parsedHtmlBody.left(MAXLENGTH)+'Este mensaje ha sido recortado pore exceder el tamaño máximo de caracteres.'; //Cortamos el body
    }
    return parsedHtmlBody;
  }
  private ContentDocumentLink createContentDocumentLink(Id contentDocumentId, Id caseid) {
    final ContentDocumentLink link = new ContentDocumentLink();
    link.ContentDocumentId = contentDocumentId;
    link.LinkedEntityId = caseid;
    link.ShareType = 'I';
    return link;
  }
  private ContentDistribution createContentDistribution(Id contentVersionId) {
    final ContentDistribution cdist = new ContentDistribution();
    cdist.Name = 'Content Distribution';
    cdist.ContentVersionId = contentVersionId;
    cdist.PreferencesAllowViewInBrowser= true;
    cdist.PreferencesLinkLatestVersion=true;
    cdist.PreferencesNotifyOnVisit=false;
    cdist.PreferencesPasswordRequired=false;
    cdist.PreferencesAllowOriginalDownload= true;
    return cdist;
  }
  private String createParsedHtmlBody (Map<String,ContentDistribution> ciddistributions,String parsedHtml) {
    String parsedHtmlBody = parsedHtml;
    if(ciddistributions.isempty() == false) {
      for(String rawcid : ciddistributions.keyset()) {
        final String cid = 'cid:'+rawcid.replace( '<', '' ).replace( '>', '' ); //Genero el CID limpio sin el formato de la cabecera
        if(parsedhtmlbody.contains(cid) == false) {
          ciddistributions.remove(rawcid);
        }
      }
      if(ciddistributions.isempty() == false) {
        insert ciddistributions.values();//inserto los contentdistribution desde su mapa
        final Map<String,String> distributidcids = new Map<String,String>();
        for(String cid : ciddistributions.keyset()) {
          final ContentDistribution distribution = ciddistributions.get(cid);
          distributidcids.put(distribution.id,cid);
        }
        //---PARSEAR EL BODY---
        for(ContentDistribution distribution : [select id,ContentDownloadUrl from ContentDistribution where id in :distributidcids.keyset()]) {
          final String cid = distributidcids.get(distribution.id).replace( '<', '' ).replace( '>', '' ); //Genero el CID limpio sin el formato de la cabecera
          final String url = distribution.ContentDownloadUrl; //Recupero la URL del objeto distribución
          System.debug('EmailService_EmailEngine_Attachments - Load Attachments - Size del body antes de convertirlo : '+parsedHtmlBody.length());//NOSONAR
          parsedHtmlBody = parsedHtmlBody.replaceAll( 'cid:' + cid, url ); //Parseamos el body
          System.debug('EmailService_EmailEngine_Attachments - Load Attachments - Size del body después de convertirlo : '+parsedHtmlBody.length());//NOSONAR
        }
      }
    }
    return parsedHtmlBody;
  }
  /*
    Methods link files to email
  */
  public void linkFilesToEmail(Id emailId) {
    for(attachment att : this.emailattachments) {
      att.ParentId = emailId;
    }
    if(this.emailattachments.isempty() == false) {
      insert this.emailattachments;
    }
  }
  /*
    Methods contentVersion
  */
  public List<ContentDocumentLink> contentVersion (Set<Id> contentversionids,Id caseId) {
    final List<ContentDocumentLink> cdistls = new List<ContentDocumentLink>(); //Lista de links para insertar
    for(ContentVersion cvs : this.contentversions) {
          contentversionids.add(cvs.Id);
    }
    for(ContentVersion cvs : [select Id, contentdocumentid from ContentVersion where id in :contentversionids]) {
      final ContentDocumentLink cdistl = new ContentDocumentLink();
      System.debug(cvs.ContentDocumentId);
      System.debug('CVID : '+cvs.Id);
      cdistl.ContentDocumentId = cvs.ContentDocumentId;
      cdistl.LinkedEntityId = caseId;
      cdistl.ShareType = 'I';
      cdistls.add(cdistl);
      this.fullcontversions.put(cvs.id,cvs);
    }
    return cdistls; 
  }
}