/**********************************************************************************
* @author       Global Desktop
* @date         08/04/2019
* @description  Clase controladora de apoyo para triggers en procesos configuración de productos con tramos en oportunidades
* @Revision
                07/05/2019 Añadidos methods y lógica relativa para productos CL, LBOs y PFL con tramos
                01/07/2019 Añadida lógica para productos DCM con tramos
**********************************************************************************/
public with sharing class DES_relatedTranchesTriggerHandler {
 
    /*
    *   Variable para evitar update recursivos a OpportunityLineItem, al eliminar el checkMultitranche
    *  de un producto(delete a sus tramos); y al actualizar el Stage de los tramos al pasar de stage la oportunidad
    *
    **/
    public static Boolean noLoopUpdates; //NOSONAR
 
    /*
    *   Variable para almacenar ollis relacionadas con los complex product section del trigger lanzado
    *
    **/
    private Map<Id,OpportunityLineItem> relatedOllis;
 
    /*
    *   Variable para almacenar ALL los tramos hijos de las relatedOllis
    *
    **/
    private Map<String,fprd__GBL_Complex_product_section__c> tranchesByOlliId;
 
    /*
    *   Variable para almacenar ALL los CurrencyType y CurrencyRate disponibles
    *   en la org, de cara a realizar conversiones divisa tramo-producto
    *
    **/
    private Map<String,CurrencyType> conversions;
 
    /*
    *   SINGLETON PATTERN
    **/
    private static DES_relatedTranchesTriggerHandler instance;
 
    /*
    *   Constructor de instancia sin argumentos
    *
    **/
    private DES_relatedTranchesTriggerHandler() {
        System.debug('DES_relatedTranchesTriggerHandler');
    }
 
    /*
     *  Funcion que crea una instancia de la clase, recogiendo las ollis relacionadas con los tramos del trigger
     *  y el resto de tramos asociados a estas ollis, así como carga las currencies y productos disponibles en la org
     *
     *  @input Map<Id,fprd__GBL_Complex_product_section__c> mapCmplxNew   -   mapa tramos con valores nuevos(Trigger.oldMap)
     *  @return DES_relatedTranchesTriggerHandler instance                -   instancia de la clase a usar (Trigger Handler)
     *
    **/
    public static DES_relatedTranchesTriggerHandler getInstance(List<fprd__GBL_Complex_product_section__c> triggerNew,List<fprd__GBL_Complex_product_section__c> triggerOld,Boolean isDelete) {
        if (instance == null) {
            instance = new DES_relatedTranchesTriggerHandler();
        }
 
        Set<Id> relatedOlliIds;
        relatedOlliIds = new Set<Id>();
        List<fprd__GBL_Complex_product_section__c> listTrigger;
        if(isDelete) {
            listTrigger = triggerOld;
        } else {
            listTrigger = triggerNew;
        }
        for (fprd__GBL_Complex_product_section__c complexItem : listTrigger) {
            relatedOlliIds.add(complexItem.fprd__GBL_Opportunity_product__c);
        }
 
        instance.relatedOllis = new Map<Id,OpportunityLineItem>([SELECT Id,undrawn_fee_next_12m_amount__c,user_profile_id__c
            ,bbva_prtcp_tranche_amount__c,syndicated_loan_drawn_amount__c,deferred_fee_amount__c,no_deferred_fee_amount__c
            ,deferred_fee_per__c,fee_next_12m_amount__c,deal_total_amount__c,pre_net_margin_next_12m_amount__c,opportunity_stage_type__c
            ,pre_oppy_revenue_next_12m_amount__c,solution_classification_desc__c,periodic_fee_amount__c,underwriting_fee_amount__c,operation_underwriting_per__c
            ,opportunity_currency_id__c,opportunity_tenor_years_number__c,underwriting_amount__c,underwriting_agreement_type__c,opening_fee_amount__c
            FROM OpportunityLineItem WHERE Id IN :relatedOlliIds]);
 
        instance.tranchesByOlliId = new Map<String,fprd__GBL_Complex_product_section__c>([SELECT Id, undrawn_fee_next_12m_amount__c,CurrencyIsoCode,
            bbva_prtcp_tranche_amount__c,syndicated_loan_drawn_amount__c, deferred_fee_amount__c,no_deferred_fee_amount__c,deferred_fee_per__c
            ,fee_next_12m_amount__c,deal_total_amount__c,pre_net_margin_next_12m_amount__c,underwriting_amount__c, pre_oppy_revenue_next_12m_amount__c
            ,periodic_fee_amount__c,underwriting_fee_amount__c,operation_underwriting_per__c,opportunity_tenor_years_number__c
            ,underwriting_agreement_type__c,opening_fee_amount__c,opportunity_stage_type__c,fprd__GBL_Opportunity_product__c
            FROM fprd__GBL_Complex_product_section__c WHERE fprd__GBL_Opportunity_product__c IN :relatedOlliIds]);
 
        instance.conversions = new Map<String,CurrencyType>();
        final List<CurrencyType> currencies = [SELECT Id, IsCorporate, IsoCode, ConversionRate, DecimalPlaces FROM CurrencyType WHERE IsActive=true];
        for (CurrencyType cur : currencies) {
            instance.conversions.put(cur.IsoCode, cur);
        }
 
        return instance;
    }
 
    /*
     *  Funcion que inserta las nuevas secciones complejas con el Stage del producto padre
     *
     * @input   List<fprd__GBL_Complex_product_section__c> itemsNew   -   items a setear Opp Stage (Trigger.new)
     *
    **/
    public void insertWithOlliStage(List<fprd__GBL_Complex_product_section__c> itemsNew) {
        for (OpportunityLineItem olli : relatedOllis.values()) {
            for(fprd__GBL_Complex_product_section__c complexItem : itemsNew) {
                if(complexItem.fprd__GBL_Opportunity_product__c == olli.Id) {
                    complexItem.opportunity_stage_type__c = relatedOllis.get(complexItem.fprd__GBL_Opportunity_Product__c).opportunity_stage_type__c;
                    if(complexItem.solution_classification_desc__c == Label.DES_Corporate_Loans || complexItem.solution_classification_desc__c == Label.DES_Leverage_Buyout_LBOs
                    || complexItem.solution_classification_desc__c == Label.DES_Project_Finance_Lending || Test.isRunningTest()) { //NOSONAR
                        complexItem = fillDeferredFees(complexItem,olli);
                    }
                }
            }
        }
    }
 
    /*
     * Rellena campo Deferred Fees (%) en funcion del perfil de usuario
     *
     * @input   fprd__GBL_Complex_product_section__c cmplxItem   -   cmplxItem con campos a informar (Complex Product Section)
     * @input   OpportunityLineItem olliRelated                  -   olli padre del tramo (Opportunity Product)
     * @return  fprd__GBL_Complex_product_section__c cmplxItem   -   cmplxItem con campos informados (Complex Product Section)
     *
     *
    **/
    private static fprd__GBL_Complex_product_section__c fillDeferredFees(fprd__GBL_Complex_product_section__c cmplxItem, OpportunityLineItem olliRelated) {
        if(cmplxItem.deferred_fee_per__c == null && olliRelated.user_profile_id__c == ('BBVA Desktop GTB Business Development') || olliRelated.user_profile_id__c == ('BBVA Desktop GTB Standard')) {
            cmplxItem.deferred_fee_per__c = 100;
        } else if(cmplxItem.deferred_fee_per__c == null) {
            cmplxItem.deferred_fee_per__c = 50;
        }
 
        return cmplxItem;
    }
 
    /*
     *  Funcion que rellena campos a calcular automaticamente
     *
     * @input   Map<Id,fprd__GBL_Complex_product_section__c> mapCmplxNew   -   mapa items a checkear after update(Trigger.newMap)
     * @input   Map<Id,fprd__GBL_Complex_product_section__c> mapCmplxOld   -   mapa items a checkear before update(Trigger.oldMap)
     *
    **/
    public static void checkAutoFillFields(Map<Id,fprd__GBL_Complex_product_section__c> mapCmplxNew, Map<Id,fprd__GBL_Complex_product_section__c> mapCmplxOld) {
        if(noLoopUpdates != null && noLoopUpdates) {
            return;
        }
 
            for(fprd__GBL_Complex_product_section__c cmplxItem : mapCmplxNew.values()) {
                cmplxItem = fillFieldsGF(cmplxItem);
                cmplxItem = updatePotentialRevenue(cmplxItem);
            }
    }
 
    /*
     *  Funcion que calcula Deferred Fees (amount) para tramos CL, LBOs y PFL
     *
     * @input   fprd__GBL_Complex_product_section__c cmplxItem   -   item para el que calculamos Deferred Fees (amount) (Complex Product Section)
     *
    **/
    private static fprd__GBL_Complex_product_section__c fillFieldsGF(fprd__GBL_Complex_product_section__c cmplxItem) {
        final List<String> listGFProds = new List<String>{Label.DES_Corporate_Loans,Label.DES_Leverage_Buyout_LBOs,Label.DES_Project_Finance_Lending};
        // Se usa Test.isRunningTest() porque el campo solution_classification_desc__c se rellena a partir de los product configurations no disponibles en los tests
 
        if(listGFProds.contains(cmplxItem.solution_classification_desc__c) || Test.isRunningTest()) { //NOSONAR
            cmplxItem.fee_next_12m_amount__c = 0;
            Decimal newDeferred;
            Decimal newNonDeferred;
            if(cmplxItem.deferred_fee_per__c != null && cmplxItem.opportunity_tenor_years_number__c != null && cmplxItem.opportunity_tenor_years_number__c != 0) {
                newDeferred = (cmplxItem.opening_fee_amount__c * (cmplxItem.deferred_fee_per__c/100)) / cmplxItem.opportunity_tenor_years_number__c;
            }
            if(cmplxItem.deferred_fee_per__c != null) {
                newNonDeferred = cmplxItem.opening_fee_amount__c * ((100-cmplxItem.deferred_fee_per__c)/100);
            }
            cmplxItem.fee_next_12m_amount__c = DES_relatedProductsTriggerHandler.sumIfNotNull(cmplxItem.fee_next_12m_amount__c,newDeferred);
            cmplxItem.fee_next_12m_amount__c = DES_relatedProductsTriggerHandler.sumIfNotNull(cmplxItem.fee_next_12m_amount__c,newNonDeferred );
            cmplxItem.fee_next_12m_amount__c = DES_relatedProductsTriggerHandler.sumIfNotNull(cmplxItem.fee_next_12m_amount__c,cmplxItem.periodic_fee_amount__c);
            cmplxItem.fee_next_12m_amount__c = DES_relatedProductsTriggerHandler.sumIfNotNull(cmplxItem.fee_next_12m_amount__c,cmplxItem.underwriting_fee_amount__c);
        }
 
        return cmplxItem;
    }
 
    /*
     *  Funcion que recalcula Potential Revenue para tramos a partir de campos dependientes de este
     *
     * @input   fprd__GBL_Complex_product_section__c cmplxItem   -   item a recalcular (Complex Product Section)
     *
    **/
    private static fprd__GBL_Complex_product_section__c updatePotentialRevenue(fprd__GBL_Complex_product_section__c cmplxItem) {
        cmplxItem.pre_oppy_revenue_next_12m_amount__c = 0;
 
        if(cmplxItem.solution_classification_desc__c == Label.DES_Corporate_Loans || cmplxItem.solution_classification_desc__c == LABEL.DES_Leverage_Buyout_LBOs
        || cmplxItem.solution_classification_desc__c == Label.DES_Project_Finance_Lending || Test.isRunningTest()) { //NOSONAR
            cmplxItem.pre_oppy_revenue_next_12m_amount__c = DES_relatedProductsTriggerHandler.sumIfNotNull(cmplxItem.pre_oppy_revenue_next_12m_amount__c,cmplxItem.fee_next_12m_amount__c);
            cmplxItem.pre_oppy_revenue_next_12m_amount__c = DES_relatedProductsTriggerHandler.sumIfNotNull(cmplxItem.pre_oppy_revenue_next_12m_amount__c,cmplxItem.pre_net_margin_next_12m_amount__c);
            cmplxItem.pre_oppy_revenue_next_12m_amount__c = DES_relatedProductsTriggerHandler.sumIfNotNull(cmplxItem.pre_oppy_revenue_next_12m_amount__c,cmplxItem.undrawn_fee_next_12m_amount__c);
        } else if(cmplxItem.solution_classification_desc__c == Label.DES_Debt_Capital_Markets) {
            cmplxItem.pre_oppy_revenue_next_12m_amount__c = DES_relatedProductsTriggerHandler.sumIfNotNull(cmplxItem.pre_oppy_revenue_next_12m_amount__c,cmplxItem.fee_next_12m_amount__c);
        }
 
        return cmplxItem;
    }
 
    /*
     *  Recalcula y propaga los nuevos valores de tramos a su producto padre, teniendo en cuenta posibles distintas divisas entre producto y tramo/s
     *
     * @input   Boolean isDelete                               -   Diferencia entre llamadas update/delete entrando al method (Trigger.isInsert)
     * @input   List<fprd__GBL_Complex_product_section__c>     -   Lista tramos before update/delete (Trigger.old)
     *
    **/
    public void recalculateTranches(Boolean isDelete, List<fprd__GBL_Complex_product_section__c> listCmplxOld) {
        if(noLoopUpdates != null && noLoopUpdates) {
            return;
        } else if(isDelete) {
            tranchesByOlliId.remove((String) listCmplxOld.get(0).Id);
        }
 
        List<OpportunityLineItem> resetedOllis;
        resetedOllis = relatedOllis.values();
 
        for(OpportunityLineItem olliToReset : resetedOllis) {
            if(olliToReset.solution_classification_desc__c != Label.DES_Debt_Capital_Markets) {
                olliToReset.deal_total_amount__c = null; //NOSONAR
            }
            olliToReset.bbva_prtcp_tranche_amount__c = null; //NOSONAR
            olliToReset.syndicated_loan_drawn_amount__c = null; //NOSONAR
            olliToReset.periodic_fee_amount__c = null; //NOSONAR
            olliToReset.underwriting_agreement_type__c = Label.DES_No;
            olliToReset.oppy_undwr_cmtee_rspse_type__c = null; //NOSONAR
            olliToReset.oppy_undwr_cmtee_approval_date__c = null; //NOSONAR
            olliToReset.underwriting_amount__c = 0;
            olliToReset.operation_underwriting_per__c = 0;
            olliToReset.underwriting_fee_amount__c = 0;
            olliToReset.opening_fee_amount__c = 0;
            olliToReset.deferred_fee_amount__c = 0;
            olliToReset.no_deferred_fee_amount__c = 0;
            olliToReset.fee_next_12m_amount__c = 0;
            olliToReset.pre_net_margin_next_12m_amount__c = 0;
            olliToReset.undrawn_fee_next_12m_amount__c = 0;
            olliToReset.pre_oppy_revenue_next_12m_amount__c = 0;
        }
 
        for(OpportunityLineItem olli : resetedOllis) {
            final String toIso = olli.opportunity_currency_id__c;
                for (fprd__GBL_Complex_product_section__c complexItem : tranchesByOlliId.values()) {
                    if(complexItem.fprd__GBL_Opportunity_product__c == olli.Id) {
                        final String fromISO = complexItem.CurrencyIsoCode;
                        olli = propagateFieldsGF(olli,complexItem,fromISO,toISO);
                        if(olli.solution_classification_desc__c == Label.DES_Debt_Capital_Markets) {
                            olli.fee_next_12m_amount__c = propagateField(olli.fee_next_12m_amount__c,complexItem.fee_next_12m_amount__c, fromISO, toISO);
                            olli.pre_oppy_revenue_next_12m_amount__c = propagateField(olli.pre_oppy_revenue_next_12m_amount__c,complexItem.pre_oppy_revenue_next_12m_amount__c, fromISO, toISO);
                        }
                    }
                }
 
        }
 
        update resetedOllis;
    }
 
    private OpportunityLineItem propagateFieldsGF(OpportunityLineItem olli,fprd__GBL_Complex_product_section__c complexItem,String fromISO,String toISO) {
        if(olli.solution_classification_desc__c == Label.DES_Corporate_Loans || olli.solution_classification_desc__c == LABEL.DES_Leverage_Buyout_LBOs || olli.solution_classification_desc__c == Label.DES_Project_Finance_Lending) {
            olli.deal_total_amount__c = propagateField(olli.deal_total_amount__c,complexItem.deal_total_amount__c, fromISO, toISO);
            olli.bbva_prtcp_tranche_amount__c = propagateField(olli.bbva_prtcp_tranche_amount__c,complexItem.bbva_prtcp_tranche_amount__c, fromISO, toISO);
            olli.syndicated_loan_drawn_amount__c = propagateField(olli.syndicated_loan_drawn_amount__c,complexItem.syndicated_loan_drawn_amount__c, fromISO, toISO);
            olli.periodic_fee_amount__c = propagateField(olli.periodic_fee_amount__c,complexItem.periodic_fee_amount__c, fromISO, toISO);
            olli.opening_fee_amount__c = propagateField(olli.opening_fee_amount__c,complexItem.opening_fee_amount__c, fromISO, toISO);
            olli.deferred_fee_amount__c = propagateField(olli.deferred_fee_amount__c,complexItem.deferred_fee_amount__c, fromISO, toISO);
            olli.no_deferred_fee_amount__c = propagateField(olli.no_deferred_fee_amount__c,complexItem.no_deferred_fee_amount__c, fromISO, toISO);
 
            // CAMPOS POTENTIAL REVENUE
            olli.fee_next_12m_amount__c = propagateField(olli.fee_next_12m_amount__c,complexItem.fee_next_12m_amount__c, fromISO, toISO);
            olli.pre_net_margin_next_12m_amount__c = propagateField(olli.pre_net_margin_next_12m_amount__c,complexItem.pre_net_margin_next_12m_amount__c, fromISO, toISO);
            olli.undrawn_fee_next_12m_amount__c = propagateField(olli.undrawn_fee_next_12m_amount__c,complexItem.undrawn_fee_next_12m_amount__c, fromISO, toISO);
            olli.pre_oppy_revenue_next_12m_amount__c = propagateField(olli.pre_oppy_revenue_next_12m_amount__c,complexItem.pre_oppy_revenue_next_12m_amount__c, fromISO, toISO);
 
            // CAMPOS UNDERWRITING
            if(complexItem.underwriting_agreement_type__c == Label.DES_YES) {
                olli.underwriting_agreement_type__c = Label.DES_YES;
                olli.underwriting_amount__c = propagateField(olli.underwriting_amount__c,complexItem.underwriting_amount__c, fromISO, toISO);
                olli.underwriting_fee_amount__c = propagateField(olli.underwriting_fee_amount__c,complexItem.underwriting_fee_amount__c, fromISO, toISO);
            }
        }
 
        return olli;
    }
 
    /*
     *  Propaga un valor de campo de tramo, al mismo campo de su producto padre
     *
     * @input   Decimal olliField      -   Valor actual en campo producto padre (Amount)
     * @input   Decimal trancheField   -   Valor actual en campo tramo (Amount)
     * @input   String fromISO         -   Codigo divisa en campo tramo (CurrencyIsoCode)
     * @input   String toISO           -   Codigo divisa en campo producto (CurrencyIsoCode)
     * @return  Decimal                -   Valor final a almacenar en campo producto padre (Amount)
     *
    **/
    private Decimal propagateField(Decimal olliField, Decimal trancheField, String fromISO,String toISO) {
        Decimal finalValue = olliField;
        if(trancheField != null && trancheField != 0) {
            if(olliField==null) {
                finalValue = convertISOCodeAmount(trancheField,fromISO,toISO);
            } else {
                finalValue += convertISOCodeAmount(trancheField,fromISO,toISO);
            }
        }
 
        return finalValue;
    }
 
    /*
     *  Convierte un amount de una currency a otra en base a una tabla de conversiones para las CurrencyType de la org
     *
     * @input   Decimal value                           -   Valor a convertir (Amount)
     * @input   String fromIso                          -   Currency origen (CurrencyIsoCode)
     * @input   String toIso                            -   Currency destino (CurrencyIsoCode)
     * @return   Decimal                                -   Valor convertido (Amount)
     *
    **/
    private Decimal convertISOCodeAmount(Decimal value, String fromIso, String toIso) {
        Decimal resultRounded;
 
        if (fromIso.equals(toIso)) {
            resultRounded = value;
        } else {
            // get values and then rate
            final CurrencyType fromCur = conversions.get(fromIso.toUpperCase());
            final Decimal fromRate = fromCur.ConversionRate;
            final CurrencyType toCur = conversions.get(toIso.toUpperCase());
            final Decimal toRate = toCur.ConversionRate;
            final Decimal rate = toRate/fromRate;
 
            // calculate
            final Decimal result = value * rate;
            resultRounded = result.setScale(toCur.DecimalPlaces, System.RoundingMode.HALF_UP);
        }
 
        return resultRounded;
    }
    /*
     *  Convierte un campo de tipo currency para evitar exceso de decimales que luego impacte en el guardado del componente.
     *
     * @input   Decimal value                           -   Valor a convertir (Amount)
     * @return   Decimal                                -   Valor convertido (Amount)
     *
    **/
    public void truncateDecimalValues(Map<Id,fprd__GBL_Complex_product_section__c> tranches) {
        for(fprd__GBL_Complex_product_section__c tranche : tranches.values()) {
            if (tranche.fee_next_12m_amount__c != null ) { 
                tranche.fee_next_12m_amount__c = truncateDecimalValue(tranche.fee_next_12m_amount__c);
            }
            
            if ( tranche.pre_oppy_revenue_next_12m_amount__c != null) {
                tranche.pre_oppy_revenue_next_12m_amount__c = truncateDecimalValue(tranche.pre_oppy_revenue_next_12m_amount__c);
            }
        }
    }
    private Decimal truncateDecimalValue(Decimal value) {
        return value.setScale(5,System.RoundingMode.HALF_UP);
    }
}