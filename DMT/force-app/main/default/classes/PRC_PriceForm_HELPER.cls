/** ********************************************************************************
* @author       JSS
* @date         02/06/2020
* @description  Helper del Controlador del componente lighning PRC_PriceForm
* @Revision
********************************************************************************* */
public with sharing class PRC_PriceForm_HELPER {

  public static void setFees(PRC_PFS_Request request, PRC_Pricing_Detail__c pricingDetails) {
    /* //Obsoleto en V3.0
	if(pricingDetails.gf_non_accrual_comission_per__c != null) {
      PRC_PFS_Operation.operationfee nonaccrualfee = new PRC_PFS_Operation.operationfee('NON_ACCRUAL',pricingDetails.gf_non_accrual_comission_per__c);
      request.engineWorksWith.operations[0].fees.add(nonaccrualfee);
    }
    if(pricingDetails.gf_accrual_per__c != null) {
      PRC_PFS_Operation.operationfee accrualfee = new PRC_PFS_Operation.operationfee('ACCRUAL',pricingDetails.gf_accrual_per__c);
      request.engineWorksWith.operations[0].fees.add(accrualfee);
    }
	*/
  }

  public static void setMatrix(PRC_PFS_Request request) {
    // de momento solo hay 2 casos: o metemos 1 matriz 1x1, o metemos 2 de 5x5
    if (request.engineWorksWith.operations[0].amortization.amortizationType == 'USER_DEFINED') {
      final PRC_PFS_Matrix matrix1 = new PRC_PFS_Matrix();matrix1.id='1';
      matrix1.axis = new List<PRC_PFS_Matrix.axis>{new PRC_PFS_Matrix.axis('MARGIN',1),new PRC_PFS_Matrix.axis('TERM',1)};
      request.engineWorksWith.matrices= new List<PRC_PFS_Matrix>{matrix1};
    } else {
      PRC_PFS_Matrix matrix1 = new PRC_PFS_Matrix();matrix1.id='1';
      matrix1.axis = new List<PRC_PFS_Matrix.axis>{new PRC_PFS_Matrix.axis('MARGIN',5),new PRC_PFS_Matrix.axis('TERM',5)};
      PRC_PFS_Matrix matrix2 = new PRC_PFS_Matrix();matrix2.id='2';
      matrix2.axis = new List<PRC_PFS_Matrix.axis>{new PRC_PFS_Matrix.axis('FEES',5),new PRC_PFS_Matrix.axis('TERM',5)};
      request.engineWorksWith.matrices= new List<PRC_PFS_Matrix>{matrix1,matrix2};
    }
  }
  public static void setUserDefinedAmortization(PRC_PFS_Request request, String oppid) {
    final List<PRC_PFS_Operation_Amortization.installment> installments = new List<PRC_PFS_Operation_Amortization.installment>();
    final List<PRC_Price_Amortization_Data__c> amortizations = new List<PRC_Price_Amortization_Data__c>();
    amortizations.addAll([select Id,PRC_Opportunity__c,gf_amort_proc_oper_rating_type__c,gf_amort_proc_expct_lss_amount__c,gf_financing_type_name__c, cutoff_date__c, gf_on_bal_mrgn_gen_amount__c, gf_off_bal_mrgn_gen_amount__c, gf_ope_on_balance_margin_per__c, gf_ope_off_balance_margin_per__c, gf_non_accrual_comission_per__c, PRC_Pricing_Detail__c from PRC_Price_Amortization_Data__c where PRC_Opportunity__c = :oppid order by cutoff_date__c asc] );

    for(PRC_Price_Amortization_Data__c data : amortizations){
      final PRC_PFS_Operation_Amortization.installment installment = new PRC_PFS_Operation_Amortization.installment();
      installment.paymentDate = data.cutoff_date__c ;
      installment.margin = new PRC_PFS_Operation_Amortization.margin(data.gf_ope_on_balance_margin_per__c,data.gf_ope_off_balance_margin_per__c);
      installment.notional = new PRC_PFS_Operation_Amortization.notional(data.gf_on_bal_mrgn_gen_amount__c,data.gf_off_bal_mrgn_gen_amount__c);
      installment.fee = new PRC_PFS_Operation_Amortization.fee(0,data.gf_non_accrual_comission_per__c);

      installments.add(installment);
    }
    request.engineWorksWith.operations[0].amortization.installments =installments;
  }
}