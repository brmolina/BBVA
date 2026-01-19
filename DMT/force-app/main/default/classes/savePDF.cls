/**
 *
 *
 *
 *
 */
public with sharing class savePDF {

  Private DES_Template__c templ;
  /**
   * Boolean para inicializar
   */
  public Boolean initialised {get; set;}
  /**
   * Lista de versiones
   */
  private List<ContentVersion> listContVersion;
  /**
   * Lista de versiones de documentos
   */
  private List<ContentDocument> listContDocument = new List<ContentDocument>();
  /**
   * Comprueba que exista un pdf anterior
   */
  public Boolean existTemplatePDF {get; set;}
  /**
   * Comprueba que no exista un pdf anterior con el check nbc
   */
  public Boolean existFinalPDF {get; set;}
  /**
   * Texto sobreescribir
   */
  public String pressOverwrite {get; set;}
  /**
   * Comprueba que no exista un pdf anterior
   */
  public Boolean newPDFExported {get; set;}
  /*
  * Script var para ejecutar código javascript desde el controlador
  *
  */
  public string scriptvar { get; set; }
  /*
  * Boolean si el usuario tiene el chatter desactivado
  *
  */
  public Boolean chatterDisabled { get; set; }

  //Constructor
  /**
   *  @author David Sanchez
   *
   *
   */
  public savePDF(ApexPages.StandardController stdController) {
    scriptvar = '';
    List<ContentVersion> listAllContVer;
    this.templ = (DES_Template__c)stdController.getRecord();
    Id templId = ApexPages.currentPage().getParameters().get('Id');
    system.debug('>>>>> templId : ' + templId);
    initialised=false;
    pressOverwrite = 'false';
    existTemplatePDF = false;
    existFinalPDF = false;
    newPDFExported = false;
    system.debug('id = ' + templ.id + '     id2' + templId);
    this.templ = [SELECT Id, Name, opportunity_id__c, opportunity_id__r.Name, opportunity_id__r.DES_Booking_Geography__c, RecordTypeId FROM DES_Template__c WHERE Id = :templId LIMIT 1];

    final User currentUser = [SELECT id, DES_Disable_Chatter__c FROM User WHERE id = :UserInfo.getUserId() LIMIT 1];
    chatterDisabled = currentUser.DES_Disable_Chatter__c;
    //Genero el nombre que tendrá el archivo pdf
    String nombrePDF = templ.opportunity_id__r.Name + ' - ' + templ.Name;

    //guardo en un set de id's los content documents que estan relacionados al template
    Set<Id> setIdsContDocs = new Set<Id>();
    for(ContentDocumentLink cdl : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :templ.Id]) {
      if(!setIdsContDocs.contains(cdl.ContentDocumentId)) {
        setIdsContDocs.add(cdl.ContentDocumentId);
      }
    }

    System.debug('nombrePDF ' + nombrePDF);
    System.debug('setIdsContDocs ' + setIdsContDocs);
    //me guardo los ContentVersion que estan vinculados al template y que tienen el nombre del template que se va a generar
    listContVersion = new List<ContentVersion>([
              SELECT Id,
                  ContentDocumentId
              FROM ContentVersion
              WHERE Title = : nombrePDF
                AND ContentDocumentId IN: setIdsContDocs
    ]);
    listAllContVer = new List<ContentVersion>([
              SELECT Id,
                  ContentDocumentId,
                  Copy_to_NBC__c
              FROM ContentVersion
              WHERE ContentDocumentId IN: setIdsContDocs
    ]);
    system.debug('>>>>> listContVersion : ' + listContVersion);
    if(listContVersion != null && !listContVersion.isEmpty()) {
      existTemplatePDF = true;
      for(ContentVersion cv : listContVersion) {
        listContDocument.add(new ContentDocument(Id=cv.ContentDocumentId));
      }
    }
    if(listAllContVer != null && !listAllContVer.isEmpty()) {
      for(ContentVersion cv : listAllContVer) {
        if(cv.Copy_to_NBC__c) {
          existFinalPDF = true;
        }
      }
    }

    System.debug('PRUEBAS:   ' + existFinalPDF);
  }

  /**
   *
   * Update template
   *
   */
  public void updateTemplate() {
    system.debug('ENTRA updateTemplate : ' + templ.Id);
    TemplateTableHandler.updateTemplate(templ.Id, true);
  }
  /**
   *
   * method to insert attachement call it on page on click of button
   *
   */
  public void saveAttachement() {


    system.debug('>>>>> existTemplatePDF : ' + existTemplatePDF);
    system.debug('>>>>> pressOverwrite : ' + pressOverwrite);
    system.debug('>>>>> listContDocument : ' + listContDocument);
    if(existTemplatePDF && !listContDocument.isEmpty()) {
      delete listContDocument;
      pressOverwrite = 'true';
      listContDocument.clear();
    }
    system.debug('>>>>> pressOverwrite : ' + pressOverwrite);
    if (!initialised && templ.Id != null) {
            final String recordTypeName = Schema.SObjectType.DES_Template__c.getRecordTypeInfosById().get(templ.recordTypeId).getDeveloperName();
      PageReference pdf;
            if(recordTypeName == Label.DES_Template_CSL || recordTypeName == Label.DES_Template_CSL_Compass) {
                pdf = Page.Template_CSL_toPDF;
            } else if(recordTypeName == Label.DES_Template_PF) {
                pdf = Page.Template_PF_toPDF;
            } else if(recordTypeName == Label.DES_Template_GTB) {
                pdf = Page.Template_GTB_toPDF;
            } else if(recordTypeName == Label.DES_Template_ECA) {
                pdf = Page.Template_ECA_toPDF;
            }
      pdf.getParameters().put('Id', templ.id);
      ContentVersion contVersion = new ContentVersion();
      Blob body;

      try {
        body = pdf.getContentAsPDF();
        system.debug('>>>>> EL BODY DEBERÍA SER EL PDF DE LA VISUALFORCE');
      } catch (VisualforceException e) {
        system.debug('>>>>> EXCEPTION : ' + e);
         body = Blob.valueOf('Something gone wrong.');
      }

      //NBC EMEA/USA/LATAM + nombre del cliente
      contVersion.Title = templ.opportunity_id__r.Name + ' - ' + templ.Name;
      contVersion.PathOnClient = templ.opportunity_id__r.Name + ' - ' + templ.Name + '.pdf';
      contVersion.VersionData = body;
      contVersion.Is_Template_PDF__c = true;
      insert contVersion;

      contVersion = [SELECT Id, ContentDocumentId, RecordTypeId, IsLatest, ContentUrl, ContentBodyId, VersionNumber, Title, Description, ReasonForChange, SharingOption, SharingPrivacy, PathOnClient, RatingCount, IsDeleted, ContentModifiedDate, ContentModifiedById, PositiveRatingCount, NegativeRatingCount, FeaturedContentBoost, FeaturedContentDate, CurrencyIsoCode, OwnerId, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate, SystemModstamp, TagCsv, FileType, PublishStatus, VersionData, ContentSize, FileExtension, FirstPublishLocationId, Origin, ContentLocation, TextPreview, ExternalDocumentInfo1, ExternalDocumentInfo2, ExternalDataSourceId, Checksum, IsMajorVersion, IsEncrypted, IsAssetEnabled, Category_Type__c FROM ContentVersion WHERE Id = :contVersion.Id];

            ContentWorkspace cw = new ContentWorkspace();
            cw = !Test.isRunningTest() ?[select Id, Name FROM ContentWorkspace WHERE Name = 'NBC Files' LIMIT 1] : null;
            system.debug('>>>>> cw : ' + cw);



      system.debug('>>>>> contVersion : ' + contVersion);
      ContentDocumentLink contDocLink = createContDocLink(templ, contVersion);
      insert contDocLink;


      newPDFExported = true;
      initialised=true;
    }

  } //FIN savePDF

  /**
   *
   *  @author VASS
   *
   *
   */
  private ContentDocumentLink createContDocLink(DES_Template__c templ, ContentVersion contVersion) {
    ContentDocumentLink contDocLink = new ContentDocumentLink();
    contDocLink.LinkedEntityId = templ.Id;
    contDocLink.ContentDocumentId = contVersion.ContentDocumentId;
    contDocLink.ShareType = 'I';
    return contDocLink;
  }

}