/** ********************************************************************************
* @author       JSS
* @date         12/05/2020
* @description  Controlador del componente lighning PRC_PriceAmortizationCSVCreator
* @Revision
********************************************************************************* */
@SuppressWarnings('sf:CommentedOutCode')
public with sharing class PRC_PriceAmortizationCSVCreator {
    private final static String HEADER_DATE_FIELD = 'Fecha';
    private final static String HEADER_NOMINAL_ONB_FIELD = 'NominalDB';
    private final static String HEADER_NOMINAL_OFFB_FIELD = 'NominalFB';
    private final static String HEADER_SPREAD_ONB_FIELD = 'SpreadDB';
    private final static String HEADER_SPREAD_OFFB_FIELD = 'SpreadFB';
    private final static String HEADER_NONACCRUAL_FIELD = 'Comision';
    /*private final static String HEADER_QUALIFICATION_FIELD = 'Qualification';
    private final static String HEADER_RATING_FIELD = 'Rating';
    private final static String HEADER_LGD_FIELD = 'LGD';*/


    /**
    * @author       JSS
    * @description  Método que guarda la información de Amortizacion en el objeto de Salesforce
    */
    @AuraEnabled
    public static List<PRC_Price_Amortization_Data__c> savePriceAmortizationDataFromCSV(String csv_str, String oppId) {
        List<String> lines_raw = csv_str.split('\n');
        List<String> headers_raw = separateCommas(lines_raw[0]);
    System.debug('>>>>>> savePriceAmortizationDataFromCSV. headers_raw: ' + headers_raw);

        List<PRC_Price_Amortization_Data__c> padList = new List<PRC_Price_Amortization_Data__c>();
        lines_raw.remove(0);//  fuera el header
		//Handling fields with commas
        for(String line : lines_raw) {
            List<String> line_fields = separateCommas(line);
        	PRC_Price_Amortization_Data__c pad = setPriceAmortizationData(headers_raw, line_fields);
            pad.PRC_Opportunity__c = oppId;
            padList.add(pad);
        }

        if(!padList.isEmpty()) {
            // check eliminar amortizaciones previas que ya existan
            list<PRC_Price_Amortization_Data__c> previousPadList = getPriceAmortizationData(oppId);
            if (!previousPadList.isEmpty()) {
               delete previousPadList;
            }
            // Insertamos Amortizaciones nuevas
            insert padList;
        }

        return padList;
    }

    /**
    * @author       JSS
    * @description  Método que actualiza en el PricingDetails la información de Amortizacion calculada para el campo nonAccrualFees
    */
    @AuraEnabled
    public static void updatePricingDetails(Decimal nonAccrualFees, String oppId, String amortization) {
        System.debug('>>>>>> updatePricingDetails. nonAccrualFees: ' + nonAccrualFees);

        PRC_Pricing_Detail__c pricingDetail = [Select Id, gf_non_accrual_comission_per__c,amortization_desc__c From PRC_Pricing_Detail__c where PRC_Opportunity__c = :oppId LIMIT 1].get(0);
        pricingDetail.gf_non_accrual_comission_per__c = nonAccrualFees;
        pricingDetail.amortization_desc__c = amortization;
        update pricingDetail;
    }

    /**
    * @author       JSS
    * @description  Método que devuelve la información de Amortizacion de una Oportunidad
    */
    @AuraEnabled
    public static List<PRC_Price_Amortization_Data__c> getPriceAmortizationData(String oppId) {
        return [SELECT Id, PRC_Opportunity__c, cutoff_date__c, gf_on_bal_mrgn_gen_amount__c, gf_off_bal_mrgn_gen_amount__c, gf_ope_on_balance_margin_per__c, gf_ope_off_balance_margin_per__c, gf_non_accrual_comission_per__c,gf_financing_type_name__c,gf_amort_proc_oper_rating_type__c,gf_amort_proc_expct_lss_amount__c, PRC_Pricing_Detail__c, PRC_Pricing_Detail__r.gf_financing_type_name__c FROM PRC_Price_Amortization_Data__c Where PRC_Opportunity__c = :oppId order by cutoff_date__c ASC];
    }

    /**
    * @author       JSS
    * @description  Método que elimina la información de Amortizacion en el objeto de Salesforce
    */
    @AuraEnabled
    public static void deletePriceAmortizationData(String oppId) {
        List<PRC_Price_Amortization_Data__c> amortList = getPriceAmortizationData(oppId);
            if (!amortList.isEmpty()) {
                delete amortList;
            }
        }


    /**
    * @description
    * @author Global Desktop | 03-08-2021
    * @param input
    * @return List<String>
    **/
    private static List<String> separateCommas(String input){
        List<String> results = input.split(';');
        for(String result : results) {
            result = result.trim();
         System.debug('>>>>>> separateCommas. result: ' + result);

        }
        return results;
    }



    /**
    * @description
    * @author Global Desktop | 03-08-2021
    * @param headers_raw
    * @param fields
    * @return PRC_Price_Amortization_Data__c
    **/
    private static PRC_Price_Amortization_Data__c setPriceAmortizationData(List<String> headers_raw, List<String> fields) {
        map<String,Integer> headerFieldMap = new map<String,Integer>();
        Integer pos = 0;
        for (String headerField : headers_raw) {
            headerFieldMap.put(headerField.trim(),pos);//Aunque ya se hizo trim() de cada campo no sé por qué pero en el último campo lo trimea mal y hay que volver a hacer el trim() por seguridad
            pos++;
        }
        System.debug('>>>>>> setPriceAmortizationData. headerFieldMap: ' + headerFieldMap);
        PRC_Price_Amortization_Data__c pad = new PRC_Price_Amortization_Data__c();
        pad.cutoff_date__c = Date.newinstance(Integer.valueOf(fields.get(headerFieldMap.get(HEADER_DATE_FIELD)).split('/')[2]), Integer.valueOf(fields.get(headerFieldMap.get(HEADER_DATE_FIELD)).split('/')[0]), Integer.valueOf(fields.get(headerFieldMap.get(HEADER_DATE_FIELD)).split('/')[1]));
        pad.gf_ope_off_balance_margin_per__c = Decimal.valueOf(fields.get(headerFieldMap.get(HEADER_SPREAD_OFFB_FIELD)));
        pad.gf_ope_on_balance_margin_per__c = Decimal.valueOf(fields.get(headerFieldMap.get(HEADER_SPREAD_ONB_FIELD)));
        pad.gf_off_bal_mrgn_gen_amount__c = Decimal.valueOf(fields.get(headerFieldMap.get(HEADER_NOMINAL_OFFB_FIELD)));
        pad.gf_on_bal_mrgn_gen_amount__c = Decimal.valueOf(fields.get(headerFieldMap.get(HEADER_NOMINAL_ONB_FIELD)));
        pad.gf_non_accrual_comission_per__c = Decimal.valueOf(fields.get(headerFieldMap.get(HEADER_NONACCRUAL_FIELD)).trim()); //Aunque ya se hizo trim() de cada campo no sé por qué pero en el último campo lo hace mal y hay que volver a hacer el trim() por seguridad
        /*
        pad.gf_financing_type_name__c = String.valueOf(fields.get(headerFieldMap.get(HEADER_QUALIFICATION_FIELD)));
        pad.gf_amort_proc_oper_rating_type__c = String.valueOf(fields.get(headerFieldMap.get(HEADER_RATING_FIELD)));
        pad.gf_amort_proc_expct_lss_amount__c = Decimal.valueOf(fields.get(headerFieldMap.get(HEADER_LGD_FIELD)));*/
        return pad;
    }

}