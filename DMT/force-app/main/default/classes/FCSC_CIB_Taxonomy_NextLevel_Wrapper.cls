/**
 * --------------------------------------------------------------------------------------
 * @Name              : FCSC_CIB_Taxonomy_NextLevel_Wrapper.cls
 * @Author            : José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
 * @Date              : 2026-02-22
 * @Group             : CIB Global Desktop
 * @Description       : Wrapper DTO para exponer al LWC los valores del siguiente nivel de la taxonomy CIB.
 *                      Se utiliza como salida de métodos @AuraEnabled cacheables.
 * --------------------------------------------------------------------------------------
**/
public with sharing class FCSC_CIB_Taxonomy_NextLevel_Wrapper {

    /**
     * @Description Constructor vacío requerido para serialización/deserialización en Aura/LWC.
     */
    public FCSC_CIB_Taxonomy_NextLevel_Wrapper() {}

    /**
     * --------------------------------------------------------------------------------------
     * @Description       Constructor principal del wrapper.
     * @param label       Texto a mostrar (display label).
     * @param value       Valor/código asociado.
     * @param recordId    Id del registro de CIB_Taxonomy_Values__c (se serializa como String).
     * @param nextCatalog Id/clave del catálogo del siguiente nivel.
     * --------------------------------------------------------------------------------------
     */
    public FCSC_CIB_Taxonomy_NextLevel_Wrapper(String label, String value, Id recordId, String nextCatalog) {
        this.label = label;
        this.value = value;
        this.recordId = (recordId == null) ? null : String.valueOf(recordId);
        this.nextCatalog = nextCatalog;
    }

    /** @Description Etiqueta a mostrar en la UI. */
    @AuraEnabled public String label { get; set; }

    /** @Description Valor/código seleccionado y enviado al siguiente nivel. */
    @AuraEnabled public String value { get; set; }

    /** @Description Id del registro de valor de taxonomy, serializado como String para LWC. */
    @AuraEnabled public String recordId { get; set; }

    /** @Description Catálogo del siguiente nivel que se debe consultar con el valor seleccionado. */
    @AuraEnabled public String nextCatalog { get; set; }

}