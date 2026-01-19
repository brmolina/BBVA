/**********************************************************************************
* @author       Global Desktop
* @date         31/05/2019
* @description  Clase controladora de apoyo para trigger producto en procesos configuración de productos, en comprobaciones Multitranche ON/OFF
* @Revision
                31/05/2019 Añadidos methods y lógica relativa para activar/desactivar feature multitranche(tramos) en productos
**********************************************************************************/
public without sharing class DES_handleMultitrancheToogling {

    /*
    *   Constructor de instancia sin argumentos
    *
    **/
    private DES_handleMultitrancheToogling() {
        System.debug('DES_handleMultitrancheToogling');
    }

    /*
     *  Funcion que comprueba si se ha cambiado de producto sin tramos, a uno con tramos o viceversa, realizando los cambios necesarios
     *
     * @input   Map<Id,OpportunityLineItem> mapOppliNew       -   mapa ollis por su ID a checkear, con valores nuevos (Opportuniy Product)
     * @input   Map<Id,OpportunityLineItem> mapOppliOld       -   mapa ollis por su ID a checkear, con valores antiguos (Opportuniy Product)
     *
    **/
    public static void checkMultitranche(Map<Id,OpportunityLineItem> mapOppliNew, Map<Id,OpportunityLineItem> mapOppliOld) {
        Set<Id> changedMultiIds;
        changedMultiIds = new Set<Id>();

        for (OpportunityLineItem oppli : mapOppliNew.values()) {
            checkMultitrancheON(oppli,mapOppliOld.get(oppli.Id));
            checkMultitrancheOFF(oppli,mapOppliOld.get(oppli.Id));
            if(oppli.multi_tranche_type__c == Label.DES_No && mapOppliOld.get(oppli.Id).multi_tranche_type__c == Label.DES_YES) {
                changedMultiIds.add(oppli.Id);
            }
        }

        final List<fprd__GBL_Complex_product_section__c> tranchesDelete = [SELECT Id,fprd__GBL_Opportunity_Product__c FROM fprd__GBL_Complex_product_section__c WHERE fprd__GBL_Opportunity_Product__c IN :changedMultiIds];
        DES_relatedTranchesTriggerHandler.noLoopUpdates = true;
        delete tranchesDelete;
        DES_relatedTranchesTriggerHandler.noLoopUpdates = false;
    }

    /*
     *  Funcion que tras desactivar tramos en productos GF resetea los campos de producto o guarda los introducidos en el cambio
     *
     * @input   OpportunityLineItem olliNew     -   olli que cambia de estado (Opportuniy Product)
     * @input   OpportunityLineItem olliOld     -   olli con estado antiguo (Opportuniy Product)
     * @return   OpportunityLineItem olli    -   olli con valores reseteados (Opportuniy Product)
     *
    **/
    private static OpportunityLineItem checkMultitrancheON(OpportunityLineItem olliNew, OpportunityLineItem olliOld) {
        OpportunityLineItem newValuesOlli = olliNew;
        if(newValuesOlli.multi_tranche_type__c == Label.DES_YES && olliOld.multi_tranche_type__c == Label.DES_No) {
            if(newValuesOlli.solution_classification_desc__c == Label.DES_Corporate_Loans || newValuesOlli.solution_classification_desc__c == LABEL.DES_Leverage_Buyout_LBOs || newValuesOlli.solution_classification_desc__c == Label.DES_Project_Finance_Lending) {
                newValuesOlli = multitrancheONInGF(newValuesOlli,false);
            } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Debt_Capital_Markets) {
                newValuesOlli.opportunity_tenor_years_number__c= null; //NOSONAR
                newValuesOlli.loan_tenor_month_desc__c = null; //NOSONAR
                newValuesOlli.fee_next_12m_amount__c = resetIfZeroValue(newValuesOlli,newValuesOlli.fee_next_12m_amount__c);
                newValuesOlli.pre_oppy_revenue_next_12m_amount__c = 0;
            }
        }

        return newValuesOlli;
    }

    /*
     *  Funcion que tras desactivar tramos en productos GF resetea los campos de producto o guarda los introducidos en el cambio
     *
     * @input   OpportunityLineItem olliNew     -   olli que cambia de estado (Opportuniy Product)
     * @input   OpportunityLineItem olliOld     -   olli con estado antiguo (Opportuniy Product)
     * @return   OpportunityLineItem olli    -   olli con valores reseteados (Opportuniy Product)
     *
    **/
    private static OpportunityLineItem checkMultitrancheOFF(OpportunityLineItem olliNew, OpportunityLineItem olliOld) {
        OpportunityLineItem newValuesOlli = olliNew;
        if(newValuesOlli.multi_tranche_type__c == Label.DES_No && olliOld.multi_tranche_type__c == Label.DES_YES) {
            if(newValuesOlli.solution_classification_desc__c == Label.DES_Corporate_Loans || newValuesOlli.solution_classification_desc__c == LABEL.DES_Leverage_Buyout_LBOs || newValuesOlli.solution_classification_desc__c == Label.DES_Project_Finance_Lending) {
                newValuesOlli = multitrancheOFFInGF(newValuesOlli,olliOld);
            } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Debt_Capital_Markets) {
                newValuesOlli.fee_next_12m_amount__c = resetIfZeroValue(newValuesOlli,newValuesOlli.fee_next_12m_amount__c);
                newValuesOlli.pre_oppy_revenue_next_12m_amount__c = 0;
            }
        }

        return newValuesOlli;
    }

    /*
     *  Funcion que tras desactivar tramos en productos GF resetea los campos de producto o guarda los introducidos en el cambio
     *
     * @input   OpportunityLineItem olliNew     -   olli que cambia de estado (Opportuniy Product)
     * @input   OpportunityLineItem olliOld     -   olli con estado antiguo (Opportuniy Product)
     * @return   OpportunityLineItem olli       -   olli con valores reseteados (Opportuniy Product)
     *
    **/
    private static OpportunityLineItem multitrancheOFFInGF(OpportunityLineItem olliNew, OpportunityLineItem olliOld) {
        OpportunityLineItem newValuesOlli = olliNew;
        newValuesOlli.deal_total_amount__c = resetIfZeroValue(newValuesOlli,newValuesOlli.deal_total_amount__c);
        newValuesOlli.bbva_prtcp_tranche_amount__c = resetIfZeroValue(newValuesOlli,newValuesOlli.bbva_prtcp_tranche_amount__c);
        newValuesOlli.syndicated_loan_drawn_amount__c = resetIfZeroValue(newValuesOlli,newValuesOlli.syndicated_loan_drawn_amount__c);
        newValuesOlli.undrawn_fee_next_12m_per__c = resetIfZeroValue(newValuesOlli,newValuesOlli.undrawn_fee_next_12m_per__c);
        newValuesOlli.deferred_fee_per__c = resetIfZeroValue(newValuesOlli,newValuesOlli.deferred_fee_per__c);
        newValuesOlli.opening_fee_per__c = resetIfZeroValue(newValuesOlli,newValuesOlli.opening_fee_per__c);
        newValuesOlli.periodic_fee_amount__c = resetIfZeroValue(newValuesOlli,newValuesOlli.periodic_fee_amount__c);
        newValuesOlli.pre_gross_margin_next_12m_per__c = resetIfZeroValue(newValuesOlli,newValuesOlli.pre_gross_margin_next_12m_per__c);
        newValuesOlli.funding_cost_per__c = resetIfZeroValue(newValuesOlli,newValuesOlli.funding_cost_per__c);

        if(newValuesOlli.underwriting_amount__c == olliOld.underwriting_amount__c) {
            newValuesOlli.underwriting_amount__c = null; //NOSONAR
        } else {
            newValuesOlli.underwriting_amount__c = resetIfZeroValue(newValuesOlli,newValuesOlli.underwriting_amount__c);
        }
        if(newValuesOlli.operation_underwriting_per__c == olliOld.operation_underwriting_per__c) {
            newValuesOlli.operation_underwriting_per__c = null; //NOSONAR
        } else {
            newValuesOlli.operation_underwriting_per__c = resetIfZeroValue(newValuesOlli,newValuesOlli.operation_underwriting_per__c);
        }
        if(newValuesOlli.underwriting_amount__c == null && newValuesOlli.operation_underwriting_per__c == null) {
            newValuesOlli.underwriting_agreement_type__c = Label.DES_No;
        } else {
            newValuesOlli.underwriting_agreement_type__c = Label.DES_YES;
        }
        newValuesOlli = multitrancheONInGF(newValuesOlli,true);

        return newValuesOlli;
    }

    /*
     *  Funcion que tras activar tramos en productos GF resetea los campos de producto
     *
     * @input   OpportunityLineItem olli    -   olli que cambia de estado (Opportuniy Product)
     * @input   Boolean secondCall          -   Determina si se llama desde funcion multitrancheOFFInGF(true)
                                                o es llamada directa al desactivar multitranche(false)
     * @return   OpportunityLineItem olli   -   olli con valores reseteados (Opportuniy Product)
     *
    **/
    private static OpportunityLineItem multitrancheONInGF(OpportunityLineItem olli,Boolean secondCall) {
        if(!secondCall) {
            olli.deal_total_amount__c = null; //NOSONAR
            olli.bbva_prtcp_tranche_amount__c = null; //NOSONAR
            olli.syndicated_loan_drawn_amount__c = null; //NOSONAR
            olli.undrawn_fee_next_12m_per__c = null; //NOSONAR
            olli.deferred_fee_per__c = null; //NOSONAR
            olli.opening_fee_per__c = null; //NOSONAR
            olli.periodic_fee_amount__c = null; //NOSONAR
            olli.pre_gross_margin_next_12m_per__c = null; //NOSONAR
            olli.funding_cost_per__c = null; //NOSONAR
            olli.underwriting_amount__c = null; //NOSONAR
            olli.operation_underwriting_per__c = null; //NOSONAR
            olli.underwriting_agreement_type__c = Label.DES_No;
            olli.opportunity_tenor_years_number__c= null; //NOSONAR
            olli.loan_tenor_month_desc__c = null; //NOSONAR
        }
        olli.pre_oppy_revenue_next_12m_amount__c = 0;
        olli.fee_next_12m_amount__c = 0;
        olli.pre_net_margin_next_12m_amount__c = 0;
        olli.undrawn_fee_next_12m_amount__c = 0;
        olli.deferred_fee_amount__c = 0;
        olli.no_deferred_fee_amount__c = 0;
        olli.opening_fee_amount__c = 0;
        olli.underwriting_fee_amount__c = 0;

        return olli;
    }

    /*
     *  Funcion que tras cambiar multitranche, determina si los campos a insertar por el usuario se conservan o se ponen a null
     *
     * @input   OpportunityLineItem olli -   olli que contiene el valor a checkear (Opportuniy Product)
     * @input   Decimal valueSaved       -   valor a checkear (Amount)
     *
    **/
    private static Decimal resetIfZeroValue(OpportunityLineItem olli, Decimal valueSaved) {
        Decimal returnValue;
        if(olli.multi_tranche_type__c == Label.DES_No && valueSaved != 0) {
            returnValue = valueSaved;
        }
        return returnValue;
    }
}