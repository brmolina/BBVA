/**
 * --------------------------------------------------------------------------------------
 * @Name              : FCSC_Request_CIB_ProductFamily_Service.cls
 * @Author            : José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
 * @Date              : 2026-02-22
 * @Group             : CIB Global Desktop
 * @Description       : Capa de servicio para el controller FCSC_Request_CIB_ProductFamily_Ctrl.
 *                      Centraliza la obtención de valores/relaciones de taxonomía CIB y la persistencia
 *                      de la selección en FCSC_Commitment__c.
**/
public with sharing class FCSC_Request_CIB_ProductFamily_Service {


/** --------------------------------------------------------------------------------------
 * @Author            : José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
 * @Description Constante inmutable (lista vacía) de wrappers para respuestas a LWC.
 *              Se usa para retornar consistentemente una lista vacía en escenarios de:
 *              - Guard clauses (parámetros en blanco).
 *              - Sin relaciones encontradas.
 *              - Excepciones controladas en la obtención de taxonomía/relaciones.
 *
 *              Beneficios:
 *              - Reduce creación de objetos en múltiples retornos.
 *              - Simplifica lectura del código (return EMPTY_WRAPPERS).
 *
 * --------------------------------------------------------------------------------------
 */
    private static final List<DMT_Taxonomy_Values__c> EMPTY_VALUES = new List<DMT_Taxonomy_Values__c>();
    private static final List<FCSC_CIB_Taxonomy_NextLevel_Wrapper> EMPTY_WRAPPERS =
        new List<FCSC_CIB_Taxonomy_NextLevel_Wrapper>();


    /**
     * --------------------------------------------------------------------------------------
     * @Author            : José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Description Se usa para construir el primer nivel (familia) en el LWC.
     *              En caso de excepción, retorna lista vacía para no romper la UI.
     * --------------------------------------------------------------------------------------
     * @return  List<DMT_Taxonomy_Values__c>
     * @example List<DMT_Taxonomy_Values__c> values = FCSC_Request_CIB_ProductFamily_Service.getCIBTaxonomyValues();
     * --------------------------------------------------------------------------------------
     */
    public static List<DMT_Taxonomy_Values__c> getCIBTaxonomyValues() {
        try {
            return [
                SELECT Id, DMT_Catalog__c, DMT_Value__c, DMT_Name__c
                FROM DMT_Taxonomy_Values__c
                ORDER BY DMT_Catalog__c, DMT_Name__c
            ];
        } catch (Exception e) {
            return EMPTY_VALUES;
        }
    }

    /**
     * --------------------------------------------------------------------------------------
     * @Description Resuelve el siguiente nivel a partir de:
     *              - relationshipId: tipo de relación (p.ej. H744/H926/H927)
     *              - currentCatalog: catálogo origen
     *              - currentValue: código/valor seleccionado
     *
     *              Devuelve wrappers {label,value,recordId,nextCatalog}.
     *              nextCatalog corresponde al DMT_Id_Catalog_Final__c del registro de relación.
     *
     *              Nota: Se aplica deduplicación para protección ante datos duplicados en
     *              DMT_Taxonomy_Relationship__c).
     * --------------------------------------------------------------------------------------
     */
    public static List<FCSC_CIB_Taxonomy_NextLevel_Wrapper> getNextLevelValues(
        String relationshipId,
        String currentCatalog,
        String currentValue ) {
        if (!hasNextLevelParams(relationshipId, currentCatalog, currentValue)) {
            return EMPTY_WRAPPERS;
        }

        try {
            List<DMT_Taxonomy_Relationship__c> relations = queryNextLevelRelations(
                relationshipId,
                currentCatalog,
                currentValue
            );
            if (relations.isEmpty()) return EMPTY_WRAPPERS;

            Set<String> finalValues = collectFinalValues(relations);
            if (finalValues.isEmpty()) return EMPTY_WRAPPERS;

            Map<String, DMT_Taxonomy_Values__c> valueByCode = queryValuesByCode(finalValues);
            if (valueByCode.isEmpty()) return EMPTY_WRAPPERS;

            return buildNextLevelWrappers(relations, valueByCode);

        } catch (Exception e) {
            return EMPTY_WRAPPERS;
        }
    }

    /**
     * --------------------------------------------------------------------------------------
     * @Description Persiste la selección del usuario en FCSC_Commitment__c.
     *              En este org solo existen campos "label" (no *_Value__c), por lo que se
     *              actualizan únicamente:
     *              - FCSC_CIB_Products_Family__c
     *              - FCSC_CIB_Products__c
     *              - FCSC_CIB_SubProducts_N1__c
     *              - FCSC_CIB_SubProducts_N2__c
     * --------------------------------------------------------------------------------------
     */
    public static void saveProductValues(
        Id recordId,
        String family,
        String product,
        String subProductN1,
        String subProductN2,
        String familyValue,
        String productValue,
        String subProductN1Value,
        String subProductN2Value
    ) {


        if (recordId == null) return;

            Id productId = resolveProductIdByName(product);
    
            try {
                update new FCSC_Commitment__c(
                    Id = recordId,
                    // Persist lookup to Product when resolvable
                    FCSC_Product__c = productId,
                    // Persist CIB labels
                    FCSC_CIB_Products__c = product,
                    FCSC_CIB_Products_Family__c = family,
                    FCSC_CIB_SubProducts_N1__c = subProductN1,
                    FCSC_CIB_SubProducts_N2__c = subProductN2
                );
            } catch (Exception de) {

            }            
    }

    /** --------------------------------------------------------------------------------------
     * @Description Valida parámetros mínimos requeridos para resolver el siguiente nivel de taxonomía.
     *              Retorna TRUE únicamente si:
     *              - relationshipId no es null/empty
     *              - currentCatalog no es null/empty
     *              - currentValue no es null/empty
     *
     *              Se usa como “guard clause” para evitar ejecutar SOQL innecesario y prevenir
     *              estados inconsistentes en la navegación jerárquica (LWC).
     * --------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-08
     * @param       relationshipId  Id/clave del tipo de relación (ej. H744/H926/H927).
     * @param       currentCatalog  Id/clave del catálogo actual (origen).
     * @param       currentValue    Valor/código seleccionado dentro del catálogo origen.
     * @return      Boolean         TRUE si todos los parámetros son válidos; FALSE si falta alguno.
     * @example     if(!hasNextLevelParams(relId, catalog, value)) { return EMPTY_WRAPPERS; }
     * --------------------------------------------------------------------------------------
     */
    private static Boolean hasNextLevelParams(String relationshipId, String currentCatalog, String currentValue) {
        return !(String.isBlank(relationshipId) || String.isBlank(currentCatalog) || String.isBlank(currentValue));
    }

    /** --------------------------------------------------------------------------------------
     * @Description Esta consulta es la base de la navegación jerárquica del LWC:
     *              - relationshipId determina el tipo de relación (ej. H744/H926/H927).
     *              - currentCatalog y currentValue representan la selección actual del usuario.
     *
     *              Retorna una lista ordenada por el valor final para mantener estabilidad en la UI
     *              (si el LWC no reordena, la lista ya viene ordenada).
     *
     *              Nota: Si se invoca con parámetros blancos, el SOQL retornará
     *              vacío.
     * --------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-08
     * @param       relationshipId  Id/clave del tipo de relación (ej. H744/H926/H927).
     * @param       currentCatalog  Id/clave del catálogo inicial (origen).
     * @param       currentValue    Valor/código seleccionado en el catálogo origen.
     * @return      List<DMT_Taxonomy_Relationship__c> Lista de relaciones que conectan al siguiente catálogo/valor.
     * @example     List<DMT_Taxonomy_Relationship__c> rels =
     *              queryNextLevelRelations('H744', 'H780', 'codeWC');
     * --------------------------------------------------------------------------------------
     */
    private static List<DMT_Taxonomy_Relationship__c> queryNextLevelRelations(
        String relationshipId,
        String currentCatalog,
        String currentValue) {
        return [
            SELECT Id, DMT_Id_Catalog__c, DMT_Id_Catalog_Initial__c, DMT_Id_Catalog_Final__c,
                DMT_Value_Catalog_Initial__c, DMT_Value_Catalog_Final__c
            FROM DMT_Taxonomy_Relationship__c
            WHERE DMT_Id_Catalog__c = :relationshipId
              AND DMT_Id_Catalog_Initial__c = :currentCatalog
              AND DMT_Value_Catalog_Initial__c = :currentValue
            ORDER BY DMT_Value_Catalog_Final__c
        ];
    }

    /** --------------------------------------------------------------------------------------
     * @Description Recolecta los valores finales desde una lista derelaciones de taxonomía. 
     *              Estos valores representan los códigos/identificadores
     *              “destino” que posteriormente se consultarán en DMT_Taxonomy_Values__c para
     *              construir las opciones del siguiente nivel (label/value).
     *
     *              Se omiten valores en blanco para evitar:
     *              - llaves inválidas en el Set
     *              - consultas SOQL innecesarias (IN con valores vacíos)
     * --------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-08
     * @param       relations  Lista de relaciones (DMT_Taxonomy_Relationship__c) del salto actual.
     * @return      Set<String> Conjunto de valores finales únicos (DMT_Value_Catalog_Final__c).
     * @example     Set<String> finalValues = collectFinalValues(relations);
     * --------------------------------------------------------------------------------------
     */
    private static Set<String> collectFinalValues(List<DMT_Taxonomy_Relationship__c> relations) {
        Set<String> values = new Set<String>();
        for (DMT_Taxonomy_Relationship__c r : relations) {
            if (!String.isBlank(r.DMT_Value_Catalog_Final__c)) values.add(r.DMT_Value_Catalog_Final__c);
        }
        return values;
    }

    /** --------------------------------------------------------------------------------------
     * @Description Consulta los registros de DMT_Taxonomy_Values__c para un conjunto de códigos (DMT_Value__c)
     *              y construye un Map para resolver rápidamente:
     *              DMT_Value__c (code)  ->  DMT_Taxonomy_Values__c (registro completo)
     *
     *              Se utiliza para transformar los valores finales obtenidos desde las relaciones
     *              (DMT_Value_Catalog_Final__c) en opciones de UI (label/value) sin ejecutar consultas
     *              repetidas por cada relación.
     *
     *              Si el Set viene null o vacío, retorna un Map vacío y evita ejecutar SOQL.
     * --------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-08
     * @param       valueIds  Set<String> con los códigos a consultar (corresponde a DMT_Value__c).
     * @return      Map<String, DMT_Taxonomy_Values__c> Mapa indexado por DMT_Value__c.
     * @example     Map<String, DMT_Taxonomy_Values__c> byCode = queryValuesByCode(finalValues);
     * --------------------------------------------------------------------------------------
     */
    private static Map<String, DMT_Taxonomy_Values__c> queryValuesByCode(Set<String> valueIds) {
        Map<String, DMT_Taxonomy_Values__c> byCode = new Map<String, DMT_Taxonomy_Values__c>();
        if (valueIds == null || valueIds.isEmpty()) return byCode;

        for (DMT_Taxonomy_Values__c v : [
            SELECT Id, DMT_Catalog__c, DMT_Value__c, DMT_Name__c
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Value__c IN :valueIds
        ]) {
            byCode.put(v.DMT_Value__c, v);
        }
        return byCode;
    }

    /** --------------------------------------------------------------------------------------
     * @Description Construye la lista de wrappers (DTO) que consume el LWC a partir de:
     *              - Relaciones del siguiente nivel (DMT_Taxonomy_Relationship__c)
     *              - Mapa de valores por código (DMT_Value__c -> DMT_Taxonomy_Values__c)
     *
     *              Responsabilidades:
     *              1) Validar que cada relación tenga catálogo final y valor final.
     *              2) Resolver el registro de valor (label/value) desde valueByCode.
     *              3) Deduplicar resultados por combinación:
     *                   (DMT_Id_Catalog_Final__c + '|' + DMT_Value_Catalog_Final__c)
     *                 para protegerse de datos duplicados en DMT_Taxonomy_Relationship__c.
     *              4) Construir y retornar wrappers con:
     *                 - label      = DMT_Name__c
     *                 - value      = DMT_Value__c
     *                 - recordId   = Id del DMT_Taxonomy_Values__c
     *                 - nextCatalog= DMT_Id_Catalog_Final__c
     * --------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-08
     * @param       relations    Lista de relaciones resultantes del query para el salto actual.
     * @param       valueByCode  Mapa indexado por DMT_Value__c para resolver display/metadata.
     * @return      List<FCSC_CIB_Taxonomy_NextLevel_Wrapper> Lista deduplicada de wrappers para UI.
     * @example     List<FCSC_CIB_Taxonomy_NextLevel_Wrapper> wrappers =
     *              buildNextLevelWrappers(relations, valueByCode);
     * --------------------------------------------------------------------------------------
     */
    private static List<FCSC_CIB_Taxonomy_NextLevel_Wrapper> buildNextLevelWrappers(
        List<DMT_Taxonomy_Relationship__c> relations,
        Map<String, DMT_Taxonomy_Values__c> valueByCode) {
        List<FCSC_CIB_Taxonomy_NextLevel_Wrapper> result = new List<FCSC_CIB_Taxonomy_NextLevel_Wrapper>();
        Set<String> seenKeys = new Set<String>();

        for (DMT_Taxonomy_Relationship__c r : relations) {
            if (String.isBlank(r.DMT_Id_Catalog_Final__c) || String.isBlank(r.DMT_Value_Catalog_Final__c)) {
                continue;
            }

            String dedupeKey = r.DMT_Id_Catalog_Final__c + '|' + r.DMT_Value_Catalog_Final__c;
            if (seenKeys.contains(dedupeKey)) continue;
            seenKeys.add(dedupeKey);

            DMT_Taxonomy_Values__c v = valueByCode.get(r.DMT_Value_Catalog_Final__c);
            if (v == null) continue;

            result.add(new FCSC_CIB_Taxonomy_NextLevel_Wrapper(
                v.DMT_Name__c,
                v.DMT_Value__c,
                v.Id,
                r.DMT_Id_Catalog_Final__c
            ));
        }
        return result;
    }

    private static Id resolveProductIdByName(String productName) {
        if (String.isBlank(productName)) return null;

        // Using a list query to avoid QueryException when no rows are found.
        List<Product2> products = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = :productName
            LIMIT 1
        ];

        return products.isEmpty() ? null : products[0].Id;
    }
}