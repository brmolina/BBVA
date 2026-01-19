/**
* @author
* Project:           BBVA Service
* Description:       Class Controller SER_ReclamacionesPDFGenerator_CTRL
*
*            No.     Date            Author                  Description
*            -----   ----------      --------------------    ---------------
* @version   1.0     2017-07-08      Accenture Admin6       Class Controller SER_ReclamacionesPDFGenerator_CTRL
* @version   1.1     2018-12-03      Victor Velandia (VV)   Modification Class for Sonar
**************************************************************************************************************************************/
public with sharing class SER_ReclamacionesPDFGeneratorController {
  /**
  * description: caso
  * @author Victor Velandia
  */
  public Case caso {get; set;}
  /**
  * description: dtCreatedDateDateOnly
  * @author Victor Velandia
  */
  public String dtCreDatDateOnly {get; set;}
  /**
  * description: tmCreatedDateTimeOnly
  * @author Victor Velandia
  */
  public String tmCreDateTimOnly {get; set;}
  /**
  * description: dtAccountingDateDateOnly
  * @author Victor Velandia
  */
  public String dtAccDatDateOnly {get; set;}
  /**
  * description: stAmmounFinallyAssumed
  * @author Victor Velandia
  */
  public String stAmmouFinalAssm {get; set;}
  /**
  * description: stAmmounFinallyAssumedEUR
  * @author Victor Velandia
  */
  public String stAmmouFnlAssEUR {get; set;}
  /**
  * description: stAFACurrency
  * @author Victor Velandia
  */
  public String stAFACurrency {get; set;}
  /**
  * description: stOperationalRisk
  * @author Victor Velandia
  */
  public String stOperationalRisk {get; set;}
  /**
  * description: stOperationalRiskEUR
  * @author Victor Velandia
  */
  public String stOpertionRiskEUR {get; set;}
  /**
  * description: stOPRCurrency
  * @author Victor Velandia
  */
  public String stOPRCurrency {get; set;}
  /**
  * description: stClaimRecovered
  * @author Victor Velandia
  */
  public String stClaimRecovered {get; set;}
  /**
  * description: stAmountRecoveredEUR
  * @author Victor Velandia
  */
  public String stAmouRecoverEUR {get; set;}
  /**
  * description: stCARCurrency
  * @author Victor Velandia
  */
  public String stCARCurrency {get; set;}
  /**
  * description: SER_ReclamacionesPDFGenerator_Controller
  * @author Victor Velandia
  */
  public SER_ReclamacionesPDFGeneratorController(ApexPages.StandardController stdController) {

    this.caso                   = (Case) stdController.getRecord();

    Case caso;
    caso = new Case();
    caso = [ SELECT Id,CaseNumber,Status,AccountId,Account.Name,CreatedDate,CreatedById,LastModifiedDate,LastModifiedById,SER_Responsible__r.Name,SER_Currency__c,SER_Accounting_date__c,SER_Transactional_Reference__c,SER_Transactional_Reference__r.Name,SER_Amount_finally_assumed__c,SER_Amount_finally_assumed_EUR__c,SER_Operational_risk__c,SER_Operational_risk_EUR__c,SER_Amount_recovered_EUR__c,SER_Claim_partially_recovered__c FROM Case WHERE Id = :this.caso.Id ];
    this.caso = caso;

    this.dtCreDatDateOnly       = String.valueOf(this.caso.CreatedDate.date());
    this.tmCreDateTimOnly       = String.valueOf(this.caso.CreatedDate.time());

    this.stAmmouFinalAssm       = formato(caso.SER_Amount_finally_assumed__c);
    this.stAmmouFnlAssEUR       = formato(caso.SER_Amount_finally_assumed_EUR__c);
    if ( caso.SER_Amount_finally_assumed__c != null ) {
      this.stAFACurrency      = caso.SER_Currency__c;
    }

    this.stOperationalRisk      = formato(caso.SER_Operational_risk__c);
    this.stOpertionRiskEUR      = formato(caso.SER_Operational_risk_EUR__c);
    if ( caso.SER_Operational_risk__c != null ) {
      this.stOPRCurrency      = caso.SER_Currency__c;
    }
    this.stClaimRecovered       = formato(caso.SER_Claim_partially_recovered__c);
    this.stAmouRecoverEUR       = formato(caso.SER_Amount_recovered_EUR__c);
    if ( caso.SER_Claim_partially_recovered__c != null ) {
      this.stCARCurrency      = caso.SER_Currency__c;
    }

    this.dtAccDatDateOnly       = formato(caso.SER_Accounting_date__c);
  }
  /**
  * description: formato
  * @author Victor Velandia
  */
  public static String formato(Decimal num) {

    string result;
    if ( num == null ) {
      result = '';
    } else {
      result = String.valueOf(num).substring(0,String.valueOf(num).lastIndexOf('.')+3);
    }

    return result;
  }
  /**
  * description: formato
  * @author Victor Velandia
  */
  public static String formato(Date fecha) {

    string result;
    if ( fecha == null ) {
      result = '';
    } else {
      result = String.valueOf(fecha);
    }

    return result;
  }
}