/**
 * --------------------------------------------------------------------------------------------------------------------------
 * @Name        FCSC_Request_CIB_ProductFamily_Test.cls
 * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
 * @Date        2026-03-06
 * @Group       CIB Global Desktop
 * @Description Pruebas unitarias para FCSC_Request_CIB_ProductFamily_Ctrl / FCSC_Request_CIB_ProductFamily_Service.
 *              Cobertura:
 *              - Lectura de catálogo (getCIBTaxonomyValues)
 *              - Navegación de siguiente nivel (getNextLevelValues) + deduplicación
 *              - Persistencia en Commitment (updateProductCommitment)
 * --------------------------------------------------------------------------------------------------------------------------
 **/
@IsTest
public with sharing class FCSC_Request_CIB_ProductFamily_Test {


/** @Description Test Account name used as Client reference (FCSC_Client__c -> Account). */
private static final String TEST_ACCOUNT_NAME = 'Test Client Account';

/** @Description Test Commitment name used to query the record created in @TestSetup. */
private static final String TEST_COMMITMENT_NAME = 'Test Commitment';

/** @Description Taxonomy catalog id for Level 1 (Family). */
private static final String CAT_FAMILY = 'H780';

/** @Description Taxonomy catalog id for next level (Product). */
private static final String CAT_PRODUCT = 'H812';

/** @Description Relationship type id used to relate Family (CAT_FAMILY) to Product (CAT_PRODUCT). */
private static final String REL_FAM_TO_PROD = 'H744';

/** @Description Value/code stored for the Family taxonomy entry (DMT_Value__c). */
private static final String CODE_FAMILY = 'codeWC';

/** @Description Display label stored for the Family taxonomy entry (DMT_Name__c). */
private static final String LABEL_FAMILY = 'Working Capital';

/** @Description Value/code stored for the Product taxonomy entry (DMT_Value__c). */
private static final String CODE_PRODUCT = 'codeCM';

/** @Description Display label stored for the Product taxonomy entry (DMT_Name__c). */
private static final String LABEL_PRODUCT = 'Cash Management';


    /**
     * ----------------------------------------------------------------------------------------------------------------------
     * @Description Método @TestSetup para generar los datos de prueba compartidos por todos los casos de esta clase.
     *              Crea:
     *              1) Account (cliente) requerido para poblar el lookup obligatorio FCSC_Client__c del Commitment.
     *              2) Commitment mínimo mediante buildCommitment(acc.Id) para validar persistencia.
     *              3) Valores mínimos de taxonomía (DMT_Taxonomy_Values__c) para validar obtención de catálogo.
     *              4) Relaciones duplicadas (DMT_Taxonomy_Relationship__c) para validar la deduplicación del servicio.
     *
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-06
     * @param       No aplica (método sin parámetros)
     * @return      void
     * @example     setupData()
     * ----------------------------------------------------------------------------------------------------------------------
     **/
        @TestSetup
        static void setupData() {
            Account acc = new Account(Name = TEST_ACCOUNT_NAME);
            insert acc;

            insert buildCommitment(acc.Id);

            insert new List<DMT_Taxonomy_Values__c>{
                buildTaxValue(CAT_FAMILY, CODE_FAMILY, LABEL_FAMILY),
                buildTaxValue(CAT_PRODUCT, CODE_PRODUCT, LABEL_PRODUCT)
            };
            // Duplicate relationship to cover service dedup.
            insert new List<DMT_Taxonomy_Relationship__c>{
                buildRelationship(REL_FAM_TO_PROD, CAT_FAMILY, CODE_FAMILY, CAT_PRODUCT, CODE_PRODUCT),
                buildRelationship(REL_FAM_TO_PROD, CAT_FAMILY, CODE_FAMILY, CAT_PRODUCT, CODE_PRODUCT)
            };
        }

    /**
     * ----------------------------------------------------------------------------------------------------------------------
     * @Description Valida la obtención del catálogo de taxonomía mediante el Controller
     *              FCSC_Request_CIB_ProductFamily_Ctrl.getCIBTaxonomyValues().
     *              Verifica que:
     *              - La lista retornada no sea nula.
     *              - Los registros insertados en @TestSetup existan en la respuesta (indexados por DMT_Value__c).
     *              - Los registros devuelvan el catálogo (DMT_Catalog__c) y etiqueta (DMT_Name__c) esperados
     *                para familia y producto.
     * ----------------------------------------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-06
     * @param       No aplica (método sin parámetros)
     * @return      void
     * @example     test_getCIBTaxonomyValues_returnsExpectedRows()
     * ----------------------------------------------------------------------------------------------------------------------
     **/
    @IsTest
    static void test_getCIBTaxonomyValues_returnsExpectedRows() {
        Test.startTest();
        List<DMT_Taxonomy_Values__c> result = FCSC_Request_CIB_ProductFamily_Ctrl.getCIBTaxonomyValues();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected non-null taxonomy values list');

        Map<String, DMT_Taxonomy_Values__c> byCode = indexByCode(result);
        assertTaxValue(byCode, CODE_FAMILY, CAT_FAMILY, LABEL_FAMILY);
        assertTaxValue(byCode, CODE_PRODUCT, CAT_PRODUCT, LABEL_PRODUCT);
    }

    /**
     * ----------------------------------------------------------------------------------------------------------------------
     * @Description Valida las guard clauses del método getNextLevelValues ante parámetros inválidos.
     *              Se comprueba que para los siguientes escenarios el método NO lance excepción y retorne lista vacía:
     *              - Parámetros nulos (relationshipId / currentCatalog / currentValue)
     *              - Parámetros en blanco o con espacios (String.isBlank)
     *              - Combinación sin relaciones coincidentes (relations.isEmpty)
     *
     *              El test es data-driven mediante una lista de casos (NextLevelCase) para reducir duplicación y
     *              mejorar mantenibilidad.
     * ----------------------------------------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-06
     * @param       No aplica (método sin parámetros)
     * @return      void
     * @example     test_getNextLevelValues_invalidParams_returnsEmpty()
     * ----------------------------------------------------------------------------------------------------------------------
     **/
    @IsTest
    static void test_getNextLevelValues_invalidParams_returnsEmpty() {
        List<NextLevelCase> cases = new List<NextLevelCase>{
            // nulls
            new NextLevelCase(null, CAT_FAMILY, CODE_FAMILY, 'relationshipId is null'),
            new NextLevelCase(REL_FAM_TO_PROD, null, CODE_FAMILY, 'currentCatalog is null'),
            new NextLevelCase(REL_FAM_TO_PROD, CAT_FAMILY, null, 'currentValue is null'),

            // blank/whitespace
            new NextLevelCase('', CAT_FAMILY, CODE_FAMILY, 'relationshipId is blank'),
            new NextLevelCase('   ', CAT_FAMILY, CODE_FAMILY, 'relationshipId is whitespace'),
            new NextLevelCase(REL_FAM_TO_PROD, '', CODE_FAMILY, 'currentCatalog is blank'),
            new NextLevelCase(REL_FAM_TO_PROD, '   ', CODE_FAMILY, 'currentCatalog is whitespace'),
            new NextLevelCase(REL_FAM_TO_PROD, CAT_FAMILY, '', 'currentValue is blank'),
            new NextLevelCase(REL_FAM_TO_PROD, CAT_FAMILY, '   ', 'currentValue is whitespace'),

            // no matching relations -> relations.isEmpty()
            new NextLevelCase(REL_FAM_TO_PROD, CAT_FAMILY, 'doesNotExist', 'no matching relations')
        };

        Test.startTest();
        for (NextLevelCase c : cases) {
            List<FCSC_CIB_Taxonomy_NextLevel_Wrapper> res =
                FCSC_Request_CIB_ProductFamily_Ctrl.getNextLevelValues(c.relationshipId, c.currentCatalog, c.currentValue, 1);
            System.assertEquals(0, res.size(), 'Expected empty result when ' + c.reason);
        }
        Test.stopTest();
    }

    /**
     * ----------------------------------------------------------------------------------------------------------------------
     * @Description Valida la deduplicación en el método getNextLevelValues.
     *              Dado que en @TestSetup se insertan relaciones duplicadas (mismo catálogo final y mismo valor final),
     *              se espera que el servicio/controller devuelva un único wrapper (sin duplicados).
     *
     *              Además, valida que el wrapper retornado contenga:
     *              - label esperado (LABEL_PRODUCT)
     *              - value/código esperado (CODE_PRODUCT)
     *              - nextCatalog esperado (CAT_PRODUCT)
     *              - recordId informado (no nulo)
     * ----------------------------------------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-06
     * @param       No aplica (método sin parámetros)
     * @return      void
     * @example     test_getNextLevelValues_dedupesDuplicates()
     * ----------------------------------------------------------------------------------------------------------------------
     **/
    @IsTest
    static void test_getNextLevelValues_dedupesDuplicates() {
        Test.startTest();
        List<FCSC_CIB_Taxonomy_NextLevel_Wrapper> result =
            FCSC_Request_CIB_ProductFamily_Ctrl.getNextLevelValues(REL_FAM_TO_PROD, CAT_FAMILY, CODE_FAMILY, 1);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Expected deduped next level values');
        System.assertEquals(LABEL_PRODUCT, result[0].label);
        System.assertEquals(CODE_PRODUCT, result[0].value);
        System.assertEquals(CAT_PRODUCT, result[0].nextCatalog);
        System.assertNotEquals(null, result[0].recordId);
    }

    /**
     * ----------------------------------------------------------------------------------------------------------------------
     * @Description Valida la persistencia de datos en Commitment mediante el método
     *              FCSC_Request_CIB_ProductFamily_Ctrl.updateProductCommitment().
     *              Cubre el caso de uso principal del componente LWC: guardar la selección de
     *              Familia / Producto / SubProducto N1 / SubProducto N2 en el registro FCSC_Commitment__c.
     *
     *              Flujo:
     *              1) Recupera el Commitment de prueba creado en @TestSetup.
     *              2) Ejecuta updateProductCommitment con valores de prueba (labels).
     *              3) Consulta nuevamente el Commitment y valida que los 4 campos CIB fueron actualizados.
     * ----------------------------------------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-06
     * @param       No aplica (método sin parámetros)
     * @return      void
     * @example     test_updateProductCommitment_updatesCommitmentFields()
     * ----------------------------------------------------------------------------------------------------------------------
     **/
    @IsTest
    static void test_updateProductCommitment_updatesCommitmentFields() {
        FCSC_Commitment__c c = [
            SELECT Id
            FROM FCSC_Commitment__c
            WHERE Name = :TEST_COMMITMENT_NAME
            LIMIT 1
        ];

        Test.startTest();
        FCSC_Request_CIB_ProductFamily_Ctrl.updateProductCommitment(c.Id,LABEL_FAMILY,LABEL_PRODUCT,'Payments','Cash Back (ATM)',null,null,null,null);

        Test.stopTest();

        FCSC_Commitment__c updated = [
            SELECT FCSC_CIB_Products_Family__c, FCSC_CIB_Products__c,
                   FCSC_CIB_SubProducts_N1__c, FCSC_CIB_SubProducts_N2__c
            FROM FCSC_Commitment__c
            WHERE Id = :c.Id
        ];

        System.assertEquals(LABEL_FAMILY, updated.FCSC_CIB_Products_Family__c);
        System.assertEquals(LABEL_PRODUCT, updated.FCSC_CIB_Products__c);
        System.assertEquals('Payments', updated.FCSC_CIB_SubProducts_N1__c);
        System.assertEquals('Cash Back (ATM)', updated.FCSC_CIB_SubProducts_N2__c);
    }

    /**
     * ----------------------------------------------------------------------------------------------------------------------
     * @Description Clase auxiliar (wrapper) para ejecutar pruebas data-driven sobre getNextLevelValues.
     *              Permite definir, por cada escenario de prueba:
     *              - relationshipId    Tipo de relación (catálogo de relación)
     *              - currentCatalog    Catálogo origen
     *              - currentValue      Valor/código origen
     *              - reason            Descripción del caso (usada en mensajes de assert)
     *
     *              Se utiliza para reducir duplicación y complejidad ciclomática en los tests (buenas prácticas / Sonar).
     * ----------------------------------------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-06
     * ----------------------------------------------------------------------------------------------------------------------
     **/
    private class NextLevelCase {
    /** @Description Id/clave del tipo de relación que se envía a getNextLevelValues. */
    String relationshipId;

    /** @Description Id/clave del catálogo origen (catálogo actual). */
    String currentCatalog;

    /** @Description Valor/código seleccionado en el catálogo origen. */
    String currentValue;

    /** @Description Texto descriptivo del escenario, usado para mensajes de aserción. */
    String reason;

        NextLevelCase(String relationshipId, String currentCatalog, String currentValue, String reason) {
            this.relationshipId = relationshipId;
            this.currentCatalog = currentCatalog;
            this.currentValue = currentValue;
            this.reason = reason;
        }
    }

    /**
     * ----------------------------------------------------------------------------------------------------------------------
     * @Description Método auxiliar (factory) para construir un registro de FCSC_Commitment__c con los campos mínimos
     *              requeridos para las pruebas.
     *              Se utiliza en @TestSetup para:
     *              - Evitar duplicación de código en la creación del Commitment.
     *              - Garantizar consistencia en los datos de prueba (campos obligatorios).
     *
     *              Campos poblados:
     *              - Name: TEST_COMMITMENT_NAME
     *              - FCSC_Client__c: lookup al Account recibido (cliente)
     *              - FCSC_Fecha_Vencimiento__c: fecha futura para cumplir la validación de “Estimated closing date”.
     * ----------------------------------------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-06
     * @param       accountId  Id del Account que actúa como cliente para el lookup FCSC_Client__c.
     * @return      FCSC_Commitment__c Registro de Commitment listo para insertarse.
     * @example     FCSC_Commitment__c c = buildCommitment(acc.Id);
     * ----------------------------------------------------------------------------------------------------------------------
     **/
    private static FCSC_Commitment__c buildCommitment(Id accountId) {
        return new FCSC_Commitment__c(
            Name = TEST_COMMITMENT_NAME,
            FCSC_Client__c = accountId,
            FCSC_Fecha_Vencimiento__c = Date.today().addDays(30)
        );
    }

    /**
     * ----------------------------------------------------------------------------------------------------------------------
     * @Description Método auxiliar (factory) para construir un registro de DMT_Taxonomy_Values__c usado en pruebas.
     *              Centraliza la creación de valores de taxonomía para:
     *              - Reducir duplicación en @TestSetup y en los tests.
     *              - Mantener consistencia en los datos de prueba (catálogo, código y etiqueta).
     *
     *              Campos poblados:
     *              - DMT_Catalog__c : Identificador del catálogo (p.ej. H780 / H812)
     *              - DMT_Value__c   : Código/valor de negocio (p.ej. codeWC / codeCM)
     *              - DMT_Name__c    : Etiqueta visible (p.ej. Working Capital / Cash Management)
     * ----------------------------------------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-06
     * @param       catalog  Id/clave del catálogo al que pertenece el valor.
     * @param       code     Código/valor que representa el registro dentro del catálogo.
     * @param       name     Etiqueta (label) a mostrar para el valor del catálogo.
     * @return      DMT_Taxonomy_Values__c Registro de taxonomía listo para insertarse.
     * @example     DMT_Taxonomy_Values__c v = buildTaxValue('H780','codeWC','Working Capital');
     * ----------------------------------------------------------------------------------------------------------------------
     **/
    private static DMT_Taxonomy_Values__c buildTaxValue(String catalog, String code, String name) {
        return new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = catalog,
            DMT_Value__c = code,
            DMT_Name__c = name
        );
    }

    /**
     * ----------------------------------------------------------------------------------------------------------------------
     * @Description Método auxiliar (factory) para construir un registro de DMT_Taxonomy_Relationship__c usado en pruebas.
     *              Centraliza la creación de relaciones de taxonomía para:
     *              - Reducir duplicación de código en @TestSetup y en los tests.
     *              - Mantener consistencia en los datos de prueba entre catálogos origen y destino.
     *
     *              Campos poblados:
     *              - DMT_Id_Catalog__c              : Id/clave del tipo de relación (por ejemplo H744)
     *              - DMT_Id_Catalog_Initial__c      : Catálogo origen
     *              - DMT_Value_Catalog_Initial__c   : Valor/código origen seleccionado
     *              - DMT_Id_Catalog_Final__c        : Catálogo destino (siguiente nivel)
     *              - DMT_Value_Catalog_Final__c     : Valor/código destino
     * ----------------------------------------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-06
     * @param       relationId       Id/clave del tipo de relación.
     * @param       initialCatalog   Id/clave del catálogo origen.
     * @param       initialValue     Valor/código del catálogo origen.
     * @param       finalCatalog     Id/clave del catálogo destino (siguiente nivel).
     * @param       finalValue       Valor/código del catálogo destino.
     * @return      DMT_Taxonomy_Relationship__c Registro de relación listo para insertarse.
     * @example     DMT_Taxonomy_Relationship__c rel = buildRelationship('H744','H780','codeWC','H812','codeCM');
     * ----------------------------------------------------------------------------------------------------------------------
     **/
    private static DMT_Taxonomy_Relationship__c buildRelationship(String relationId,String initialCatalog,String initialValue,
        String finalCatalog,String finalValue) {
        return new DMT_Taxonomy_Relationship__c(
            DMT_Id_Catalog__c = relationId,
            DMT_Id_Catalog_Initial__c = initialCatalog,
            DMT_Value_Catalog_Initial__c = initialValue,
            DMT_Id_Catalog_Final__c = finalCatalog,
            DMT_Value_Catalog_Final__c = finalValue
        );
    }

    /**
     * ----------------------------------------------------------------------------------------------------------------------
     * @Description Método auxiliar para indexar una lista de registros DMT_Taxonomy_Values__c por su código/valor
     *              (campo DMT_Value__c).
     *              Se utiliza en los tests para:
     *              - Evitar búsquedas repetidas en listas.
     *              - Simplificar aserciones al validar valores esperados del catálogo.
     *
     *              Nota: Se omiten registros cuyo DMT_Value__c sea nulo, vacío o espacios (String.isBlank).
     * ----------------------------------------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-06
     * @param       values  Lista de DMT_Taxonomy_Values__c a indexar.
     * @return      Map<String, DMT_Taxonomy_Values__c> Mapa con clave = DMT_Value__c y valor = registro correspondiente.
     * @example     Map<String, DMT_Taxonomy_Values__c> byCode = indexByCode(result);
     * ----------------------------------------------------------------------------------------------------------------------
     **/
    private static Map<String, DMT_Taxonomy_Values__c> indexByCode(List<DMT_Taxonomy_Values__c> values) {
        Map<String, DMT_Taxonomy_Values__c> byCode = new Map<String, DMT_Taxonomy_Values__c>();
        for (DMT_Taxonomy_Values__c v : values) {
            if (String.isBlank(v.DMT_Value__c)) continue;
            byCode.put(v.DMT_Value__c, v);
        }
        return byCode;
    }

    /**
     * ----------------------------------------------------------------------------------------------------------------------
     * @Description Método auxiliar de aserción para validar un registro de taxonomía indexado por código (DMT_Value__c).
     *              Verifica que:
     *              - El mapa contenga la clave `code`.
     *              - El catálogo (DMT_Catalog__c) coincida con `expectedCatalog`.
     *              - El nombre/etiqueta (DMT_Name__c) coincida con `expectedName`.
     *
     *              Se utiliza para reducir duplicación en los tests y mejorar mantenibilidad (buenas prácticas / Sonar).
     * ----------------------------------------------------------------------------------------------------------------------
     * @Author      José Alejandro Osorio    josealejandro.fernandez.contractor@bbva.com
     * @Date        2026-03-06
     * @param       byCode           Mapa indexado por DMT_Value__c con los registros retornados por el servicio.
     * @param       code             Código/valor esperado (clave del mapa).
     * @param       expectedCatalog  Catálogo esperado asociado al código.
     * @param       expectedName     Etiqueta/nombre esperado asociado al código.
     * @return      void
     * @example     assertTaxValue(byCode, CODE_FAMILY, CAT_FAMILY, LABEL_FAMILY);
     * ----------------------------------------------------------------------------------------------------------------------
     **/
    private static void assertTaxValue(Map<String, DMT_Taxonomy_Values__c> byCode,String code,
        String expectedCatalog,String expectedName) {
        System.assert(byCode.containsKey(code), 'Expected ' + code + ' to exist in returned taxonomy values');
        System.assertEquals(expectedCatalog, byCode.get(code).DMT_Catalog__c);
        System.assertEquals(expectedName, byCode.get(code).DMT_Name__c);
    }
}