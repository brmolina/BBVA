/*-----------------------------------------------------------------
Author:    Juan Carlos Terrón
Company:     Accenture
Description:   This class contains helper and auxiliar methods
              to not overload the main casemethods class of logic parent.

History:
<Date>      <Author>        <Description>
04/07/2017    Juan Carlos Terrón    Initial Version.
-------------------------------------------------------------------*/
public without sharing class SER_CaseMethods_HELPER_ParentCp {

  private SER_CaseMethods_HELPER_ParentCp() {
  }

  /*------------------------------------------------------------------------------------------------
      Author:    Juan Carlos Terrón
      Company:     Accenture
      Description:   Copy Fields from a Parent Case to its children.

      IN:
      OUT:       Void

      History:
      <Date>          <Author>        <Change Description>
      26/09/2017        Juan Carlos Terrón    Initial Version
      12/11/2018        Jose Luis Aranda      Add GNC
      ---------------------------------------------------------------------------------------------------*/
  public static void copyParentFieldsUPDATE(Case caso, Case casoPadre, Map<String,String> mapPicklistValues) {
    System.debug('JCT - ENTRO en la asignación : '+caso.Id);

    Boolean case2;
    case2 = caso.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GM && caso.SER_Close__c != true;
    Boolean case3;
    case3 = caso.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GNC && caso.SER_Close__c != true;

    if(case2) {
      //GM Bussines Logic
      System.debug('JCT - CAMBIO LOS CAMPOS de  : '+caso.Id);
      asignarAssetPtoC (caso, casoPadre);
      /**
        * Description: Add if for clientName casopadre in empty
        * @autor: Victor Velandia (VV)
        */
      if(caso.AccountId != casoPadre.AccountId && caso.AccountId == null) {
        caso.AccountId                = casoPadre.AccountId;
      }
      caso.SER_Type_GM__c             = casoPadre.SER_Type_GM__c; //Typologia
      caso.SER_Subtype_GM__c          = casoPadre.SER_Subtype_GM__c; // Reason
      caso.SER_Classification__c      = casoPadre.SER_Classification__c; //Classification
      caso.SER_MailingGroup__c        = casoPadre.SER_MailingGroup__c; //Mailing Group
      caso.SER_Outbound_Mailbox__c    = casoPadre.SER_Outbound_Mailbox__c; //Email outbox
      caso.SER_Pre_liquidacion__c     = casoPadre.SER_Pre_liquidacion__c; //Pre-liquidation
      caso.SER_Post_liquidation__c    = casoPadre.SER_Post_liquidation__c; //Post-liquidation
      copyStatusClose (caso, casoPadre);
      // Victor: se agrego condicion caso.SER_Close__c != true para que no actualizara los hijos que estan cerrados cuando el padre se modifica
    } else if(case3) {//GNC Bussines Logic
      /**
        * Description: Add AccountID and Subject
        * @autor: Victor Velandia (VV)
        */
      herenciaCamposGNC(caso,casoPadre);
      copyStatusClose (caso, casoPadre);
    }
  }
  private static void copyStatusClose (Case caso, Case casoPadre) {
    if(casoPadre.SER_Close__c && !caso.SER_Close__c) {
      if(casoPadre.AccountId != null
          && (caso.AccountId == null || caso.AccountId == Label.SER_InternalContactAccountID)
          && caso.AccountId != casoPadre.AccountId) {
        caso.AccountId    =     casoPadre.AccountId;
      }
      caso.SER_Close__c = true;
      system.debug('--->>> VV true');
    }
  }
  /*---------------------------------------------------------------------
      Author:    Juan Carlos Terrón
      Company:     Accenture
      Description:   Copy Fields from a Parent Case to its children.

      IN:
      OUT:       Void

      History:
      <Date>          <Author>        <Change Description>
      26/09/2017        Juan Carlos Terrón    Initial Version
      12/11/2018        Jose Luis Aranda      Add GNC
      ------------------------------------------------------------------------*/
  public static void copyParentFieldsINSERT(Case caso, Case casoPadre, Map<String,String> mapPicklistValues) {
    Boolean case2;
    case2 = caso.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GM && caso.SER_Close__c != true;
    Boolean case3;
    case3 = caso.SER_Business_Case_Type__c == SER_Constant.BUSINESS_GNC && caso.SER_Close__c != true;

    if(case2) {//GM Bussines Logic
      asignarAssetPtoC (caso, casoPadre);
      asignarSernovaClientPtoC (caso, casoPadre);    
      caso.SER_Type_GM__c           = casoPadre.SER_Type_GM__c;
      caso.SER_Subtype_GM__c        = casoPadre.SER_Subtype_GM__c;
      caso.SER_Classification__c    = casoPadre.SER_Classification__c;
      caso.SER_MailingGroup__c      = casoPadre.SER_MailingGroup__c;
      caso.SER_Outbound_Mailbox__c  = casoPadre.SER_Outbound_Mailbox__c;
      caso.SER_Pre_liquidacion__c   = casoPadre.SER_Pre_liquidacion__c;
      caso.SER_Post_liquidation__c  = casoPadre.SER_Post_liquidation__c;
      asignarAccountPtoC(caso, casoPadre);
      //Victor: se agrego condicion caso.SER_Close__c != true para que no actualizara los hijos que estan cerrados cuando el padre se modifica
    } else if(case3) {//GNC Bussines Logic
      /**
        * Description: AddClient Name and Subject
        * @autor: Victor Velandia (VV)
        */
      herenciaCamposGNC(caso,casoPadre);
    }
  }
  private static void asignarAccountPtoC (Case caso, Case casoPadre) {
    if(casoPadre.AccountId != null && (caso.AccountId == null || caso.AccountId == Label.SER_InternalContactAccountID) && caso.AccountId != casoPadre.AccountId && caso.SER_IsSernova__c == false) {
      caso.AccountId = casoPadre.AccountId;
    }
  }
  private static void herenciaCamposGNC (Case caso, Case casoPadre) {
    caso.SER_Classification__c    = casoPadre.SER_Classification__c;
    caso.SER_Country__c           = casoPadre.SER_Country__c;
    caso.SER_Type_GNC__c          = casoPadre.SER_Type_GNC__c;
    caso.SER_Subtype_GNC__c       = casoPadre.SER_Subtype_GNC__c;
    caso.Subject                  = casoPadre.Subject; //VV
    caso.Description              = casoPadre.Description;
    caso.SER_Solution__c          = casoPadre.SER_Solution__c;
  }
  /**
  * Description: Add if for clientName casopadre
  * @autor: Victor Velandia (VV)
  */
  private static void asignarsernovaClientPtoC (Case caso, Case casoPadre) {
    final boolean sameAccount = caso.AccountId != casoPadre.AccountId && caso.AccountId == null;   
    if(sameAccount) {
      Id sernovaSupId;
      sernovaSupId = [select Id,Name from Account where Client_STAR_ID__C = :Label.SER_SernovaAccountNAME and SER_CClient__c = :Label.SER_SernovaAccountNAME limit 1].Id;
      Boolean sernovaSupplier;
      sernovaSupplier = caso.SER_IsSernova__c == true && sernovaSupId != null;
      if(sernovaSupplier) {
        caso.AccountId = sernovaSupId;
      } else {
        caso.AccountId = casoPadre.AccountId;
      }
    }
  }
  private static void asignarAssetPtoC (Case caso, Case casoPadre) {
    if(casoPadre.SER_Asset__c != null && caso.SER_Asset__c != casoPadre.SER_Asset__c) {
      caso.SER_Asset__c         = casoPadre.SER_Asset__c;
    }
  }
}