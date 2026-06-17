/**
 * --------------------------------------------------------------------------------------
 * @Name              : FCSC_Request_CIB_ProductFamily_Ctrl.cls
 * @Author            : José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
 * @Date              : 2026-02-22
 * @Group             : CIB Global Desktop
 * @Description       : Controller Apex para el componente LWC gdCIBProductFamilyForCommitments.
 *                      Expone métodos @AuraEnabled como fachada hacia FCSC_Request_CIB_ProductFamily_Service.
 * --------------------------------------------------------------------------------------
**/
public with sharing class FCSC_Request_CIB_ProductFamily_Ctrl {

    /**
     * --------------------------------------------------------------------------------------
     * @Author            : José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Description       Obtiene el catálogode la taxonomía CIB.
     *                    Método cacheable para consumo desde LWC.
     * @return            List<CIB_Taxonomy_Values__c>
     * @example           getCIBTaxonomyValues()
     * --------------------------------------------------------------------------------------
     */
    @AuraEnabled(cacheable=true)
    public static List<DMT_Taxonomy_Values__c> getCIBTaxonomyValues(){
        return FCSC_Request_CIB_ProductFamily_Service.getCIBTaxonomyValues();
    }

    /**
     * --------------------------------------------------------------------------------------
     * @Author            : José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Description       Devuelve los valores del siguiente nivel (wrapper) según relación y valor.
     *                    Incluye cacheBreaker para invalidar cache del wire (parámetro dummy).
     * @param relationshipId  Id/clave del tipo de relación.
     * @param currentCatalog  Id/clave del catálogo actual.
     * @param currentValue    Valor actual dentro del catálogo.
     * @param cacheBreaker    Parámetro dummy para evitar cache (no se usa en lógica de negocio).
     * @return                List<FCSC_CIB_Taxonomy_NextLevel_Wrapper>
     * @example               getNextLevelValues('H744','CAT','VAL', DateTime.now().getTime())
     * --------------------------------------------------------------------------------------
     */
    @AuraEnabled(cacheable=true)
    public static List<FCSC_CIB_Taxonomy_NextLevel_Wrapper> getNextLevelValues(
        String relationshipId,
        String currentCatalog,
        String currentValue,
        Long cacheBreaker
    ){
        return FCSC_Request_CIB_ProductFamily_Service.getNextLevelValues(relationshipId, currentCatalog, currentValue);
    }

    /**
     * --------------------------------------------------------------------------------------
     * @Description       Actualiza el Commitment con labels y values seleccionados en el LWC.
     *                    Mantiene compatibilidad con el front (labels + values).
     * @param recordId            Id del Commitment.
     * @param family              Label familia.
     * @param product             Label producto.
     * @param subProductN1         Label subproducto N1.
     * @param subProductN2         Label subproducto N2.
     * @param familyValue         Value/código familia.
     * @param productValue        Value/código producto.
     * @param subProductN1Value   Value/código subproducto N1.
     * @param subProductN2Value   Value/código subproducto N2.
     * @return                    void
     * --------------------------------------------------------------------------------------
     */
    @AuraEnabled
    public static void updateProductCommitment(Id recordId,String family,String product,String subProductN1,
        String subProductN2,String familyValue,String productValue,String subProductN1Value,String subProductN2Value){
        FCSC_Request_CIB_ProductFamily_Service.saveProductValues(
            recordId,
            family,
            product,
            subProductN1,
            subProductN2,
            familyValue,
            productValue,
            subProductN1Value,
            subProductN2Value
        );
    }
}