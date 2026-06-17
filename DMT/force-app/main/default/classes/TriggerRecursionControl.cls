/**
 * @description Clase centralizada para controlar la recursión de TODOS los triggers
 *              en una transacción. Reemplaza a ControlTriggerTemplate y añade control
 *              para Opportunity y OpportunityLineItem.
 * @author Optimización de triggers - BBVA
 * @date 2024
 */
public class TriggerRecursionControl {
    
    // ============================================================================
    // CONTROL DE TEMPLATE TRIGGER
    // ============================================================================
    private static Boolean templateAfterUpdateExecuted = false;
    private static Boolean templateBeforeUpdateExecuted = false;
    
    public static void setTemplateAfterUpdateExecuted() {
        templateAfterUpdateExecuted = true;
    }
    
    public static Boolean hasTemplateAfterUpdateExecuted() {
        return templateAfterUpdateExecuted;
    }
    
    public static void setTemplateBeforeUpdateExecuted() {
        templateBeforeUpdateExecuted = true;
    }
    
    public static Boolean hasTemplateBeforeUpdateExecuted() {
        return templateBeforeUpdateExecuted;
    }
    
    // ============================================================================
    // CONTROL DE OPPORTUNITY TRIGGER
    // ============================================================================
    private static Boolean opportunityAfterUpdateExecuted = false;
    private static Boolean opportunityBeforeUpdateExecuted = false;
    private static Boolean opportunityReopenUpdateExecuted = false;
    
    public static void setOpportunityAfterUpdateExecuted() {
        opportunityAfterUpdateExecuted = true;
    }
    
    public static Boolean hasOpportunityAfterUpdateExecuted() {
        return opportunityAfterUpdateExecuted;
    }
    
    public static void setOpportunityBeforeUpdateExecuted() {
        opportunityBeforeUpdateExecuted = true;
    }
    
    public static Boolean hasOpportunityBeforeUpdateExecuted() {
        return opportunityBeforeUpdateExecuted;
    }
    
    public static void setOpportunityReopenUpdateExecuted() {
        opportunityReopenUpdateExecuted = true;
    }
    
    public static Boolean hasOpportunityReopenUpdateExecuted() {
        return opportunityReopenUpdateExecuted;
    }
    
    // ============================================================================
    // CONTROL DE OPPORTUNITYLINEITEM TRIGGER
    // ============================================================================
    private static Boolean oliAfterUpdateExecuted = false;
    private static Boolean oliBeforeUpdateExecuted = false;
    
    public static void setOLIAfterUpdateExecuted() {
        oliAfterUpdateExecuted = true;
    }
    
    public static Boolean hasOLIAfterUpdateExecuted() {
        return oliAfterUpdateExecuted;
    }
    
    public static void setOLIBeforeUpdateExecuted() {
        oliBeforeUpdateExecuted = true;
    }
    
    public static Boolean hasOLIBeforeUpdateExecuted() {
        return oliBeforeUpdateExecuted;
    }
    
    // ============================================================================
    // RESET PARA TESTS
    // ============================================================================
    @TestVisible
    private static void resetAllFlags() {
        templateAfterUpdateExecuted = false;
        templateBeforeUpdateExecuted = false;
        opportunityAfterUpdateExecuted = false;
        opportunityBeforeUpdateExecuted = false;
        opportunityReopenUpdateExecuted = false;
        oliAfterUpdateExecuted = false;
        oliBeforeUpdateExecuted = false;
    }
}