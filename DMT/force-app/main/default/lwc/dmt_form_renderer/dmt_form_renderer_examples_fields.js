/* =============================================================================
 * EJEMPLOS COMPLETOS - dmt_form_renderer
 * =============================================================================
 *
 * Este archivo contiene ejemplos de TODOS los tipos de campos soportados
 * por el componente y TODAS las casuísticas posibles (required, readonly,
 * hidden, highlighted, overridable, blanks, distintos sizes, sin valor, etc.).
 *
 * Tipos soportados:
 *   - text
 *   - textarea
 *   - number
 *   - currency
 *   - numberWithCurrency
 *   - date
 *   - datetime
 *   - email
 *   - phone
 *   - url
 *   - checkbox
 *   - picklist
 *   - blank (espacio en blanco para layouts)
 *
 * Atributos transversales (aplicables a cualquier tipo):
 *   - id            (string, requerido y único)
 *   - label         (string)
 *   - apiName       (string, opcional)
 *   - value         (cualquier tipo según el campo)
 *   - size          ('1-of-1' | '1-of-2' | '1-of-3' | '1-of-4' | ...)
 *   - type          (uno de los tipos de arriba)
 *   - isReadOnly    (boolean)
 *   - isHidden      (boolean) -> oculta totalmente el campo
 *   - isRequired    (boolean)
 *   - isHighlighted (boolean) -> marca visualmente el campo como editado
 *   - helpText      (string) -> tooltip "?" al lado de la label
 *   - placeholder   (string)
 *   - maxLength     (number, sólo text/textarea)
 *   - step, min, max (number, sólo number/currency/numberWithCurrency)
 *   - currencyCode  (string, sólo currency/numberWithCurrency)
 *   - options       (array, sólo picklist)
 *   - overridable   (boolean) -> activa la capacidad de "valor original"
 *   - originalValue (cualquier tipo) -> valor original para comparar
 *
 * Notas sobre `overridable`:
 *   - Funciona en CUALQUIER tipo de campo.
 *   - Si `value !== originalValue` -> aparece icono warning + botón revert.
 *   - El tooltip muestra `originalValue` tal cual lo envíes (sin formatear).
 *   - El comparador es String(value) !== String(originalValue).
 * ============================================================================= */


// =============================================================================
// EJEMPLO 1: Formulario básico con todos los tipos (caso "happy path")
// =============================================================================
const exampleAllTypes = [

    // ===== TEXT =====
    {
        id: 'Name',
        label: 'Name',
        apiName: 'Name',
        value: 'Opportunity ABC-123',
        size: '1-of-2',
        type: 'text',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        maxLength: 80,
        helpText: 'Nombre único de la oportunidad.',
        placeholder: 'Ingrese el nombre',
        isHighlighted: false
    },

    // ===== TEXTAREA =====
    {
        id: 'Comments__c',
        label: 'Comments',
        apiName: 'Comments__c',
        value: 'Cliente solicita revisión adicional antes del cierre. Texto largo para probar el truncado con "View More" en modo lectura.',
        size: '1-of-1',
        type: 'textarea',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        maxLength: 1000,
        helpText: 'Comentarios adicionales. Máximo 1000 caracteres.',
        placeholder: 'Escribe tus comentarios...',
        isHighlighted: false
    },

    // ===== NUMBER =====
    {
        id: 'Number_of_Units__c',
        label: 'Number of Units',
        apiName: 'Number_of_Units__c',
        value: 50,
        size: '1-of-2',
        type: 'number',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        helpText: 'Cantidad de unidades del producto.',
        step: 1,
        min: 0,
        max: 9999,
        isHighlighted: false
    },

    // ===== CURRENCY =====
    {
        id: 'Line_Opportunity__c',
        label: 'Line / Opportunity',
        apiName: 'Line_Opportunity__c',
        value: 1500000,
        size: '1-of-2',
        type: 'currency',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        helpText: 'Monto total en USD.',
        currencyCode: 'USD',
        step: 0.01,
        isHighlighted: false
    },

    // ===== NUMBER WITH CURRENCY =====
    {
        id: 'Commission_Amount_EUR__c',
        label: 'Commission Amount (EUR)',
        apiName: 'Commission_Amount_EUR__c',
        value: 2500.50,
        size: '1-of-2',
        type: 'numberWithCurrency',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        helpText: 'Comisión en euros.',
        currencyCode: 'EUR',
        step: 0.01,
        min: 0,
        isHighlighted: false
    },

    // ===== DATE =====
    {
        id: 'Product_Start_Date__c',
        label: 'Product Start Date',
        apiName: 'Product_Start_Date__c',
        value: '2025-01-15',
        size: '1-of-2',
        type: 'date',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        helpText: 'Fecha de inicio de vigencia.',
        isHighlighted: false
    },

    // ===== DATETIME =====
    {
        id: 'LastModifiedDate',
        label: 'Last Modified',
        apiName: 'LastModifiedDate',
        value: '2025-04-29T14:30:00.000Z',
        size: '1-of-2',
        type: 'datetime',
        isReadOnly: true,
        isHidden: false,
        isRequired: false,
        helpText: 'Última modificación del registro.',
        isHighlighted: false
    },

    // ===== EMAIL =====
    {
        id: 'Contact_Email__c',
        label: 'Contact Email',
        apiName: 'Contact_Email__c',
        value: 'cliente@empresa.com',
        size: '1-of-2',
        type: 'email',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        helpText: 'Correo principal de contacto.',
        placeholder: 'nombre@dominio.com',
        isHighlighted: false
    },

    // ===== PHONE =====
    {
        id: 'Contact_Phone__c',
        label: 'Contact Phone',
        apiName: 'Contact_Phone__c',
        value: '+57 300 123 4567',
        size: '1-of-2',
        type: 'phone',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        helpText: 'Teléfono con código de país.',
        placeholder: '+57 300 000 0000',
        isHighlighted: false
    },

    // ===== URL =====
    {
        id: 'Company_Website__c',
        label: 'Company Website',
        apiName: 'Company_Website__c',
        value: 'https://www.empresa.com',
        size: '1-of-2',
        type: 'url',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        helpText: 'Sitio web oficial.',
        placeholder: 'https://...',
        isHighlighted: false
    },

    // ===== CHECKBOX =====
    {
        id: 'Active__c',
        label: 'Active',
        apiName: 'Active__c',
        value: true,
        size: '1-of-2',
        type: 'checkbox',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        helpText: 'Indica si el registro está activo.',
        isHighlighted: false
    },

    // ===== PICKLIST =====
    {
        id: 'Risk_Type__c',
        label: 'Risk Type',
        apiName: 'Risk_Type__c',
        value: 'Medium',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        helpText: 'Clasificación del riesgo.',
        placeholder: 'Seleccione un riesgo',
        options: [
            { label: '-- Ninguno --', value: '' },
            { label: 'Low', value: 'Low' },
            { label: 'Medium', value: 'Medium' },
            { label: 'High', value: 'High' },
            { label: 'Critical', value: 'Critical' }
        ],
        isHighlighted: false
    }
];


// =============================================================================
// EJEMPLO 2: Casuísticas especiales - SIN VALOR (vacíos / null)
// =============================================================================
const exampleEmptyValues = [

    // Text sin valor
    {
        id: 'EmptyText',
        label: 'Empty Text',
        value: '',
        size: '1-of-2',
        type: 'text',
        isRequired: false,
        helpText: 'Campo de texto vacío para probar el placeholder en read.',
        placeholder: 'Sin datos aún'
    },

    // Number sin valor (null)
    {
        id: 'EmptyNumber',
        label: 'Empty Number',
        value: null,
        size: '1-of-2',
        type: 'number',
        isRequired: false,
        step: 1
    },

    // Date sin valor
    {
        id: 'EmptyDate',
        label: 'Empty Date',
        value: '',
        size: '1-of-2',
        type: 'date',
        isRequired: false
    },

    // Picklist sin valor
    {
        id: 'EmptyPicklist',
        label: 'Empty Picklist',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isRequired: false,
        placeholder: 'Seleccione una opción',
        options: [
            { label: 'Opción A', value: 'A' },
            { label: 'Opción B', value: 'B' }
        ]
    },

    // Checkbox false
    {
        id: 'UncheckedBox',
        label: 'Unchecked',
        value: false,
        size: '1-of-2',
        type: 'checkbox',
        isRequired: false
    }
];


// =============================================================================
// EJEMPLO 3: Casuísticas READ-ONLY (no editables)
// =============================================================================
const exampleReadOnlyFields = [

    {
        id: 'RecordId',
        label: 'Record ID',
        value: 'a0X5g000001ABCDEF',
        size: '1-of-2',
        type: 'text',
        isReadOnly: true,
        helpText: 'ID del registro en Salesforce (no editable).'
    },

    {
        id: 'CreatedDate',
        label: 'Created Date',
        value: '2024-12-01T09:15:00.000Z',
        size: '1-of-2',
        type: 'datetime',
        isReadOnly: true
    },

    {
        id: 'CalculatedAmount',
        label: 'Calculated Amount',
        value: 87500.25,
        size: '1-of-2',
        type: 'currency',
        currencyCode: 'USD',
        isReadOnly: true,
        helpText: 'Monto calculado automáticamente por el sistema.'
    }
];


// =============================================================================
// EJEMPLO 4: Casuísticas HIDDEN (campos ocultos)
// =============================================================================
const exampleHiddenFields = [

    {
        id: 'VisibleField',
        label: 'Visible Field',
        value: 'Este sí se ve',
        size: '1-of-2',
        type: 'text'
    },

    {
        id: 'HiddenField',
        label: 'Hidden Field',
        value: 'Este NO se ve',
        size: '1-of-2',
        type: 'text',
        isHidden: true   // <-- desaparece completamente del DOM
    },

    {
        id: 'AnotherVisible',
        label: 'Another Visible',
        value: 'Visible de nuevo',
        size: '1-of-2',
        type: 'text'
    }
];


// =============================================================================
// EJEMPLO 5: Casuísticas HIGHLIGHTED (campos marcados como editados)
// =============================================================================
const exampleHighlightedFields = [

    {
        id: 'EditedDate',
        label: 'Edited Date',
        value: '2025-06-30',
        size: '1-of-2',
        type: 'date',
        isHighlighted: true,   // <-- borde/fondo destacado
        helpText: 'Este campo fue modificado recientemente.'
    },

    {
        id: 'EditedPicklist',
        label: 'Edited Picklist',
        value: 'High',
        size: '1-of-2',
        type: 'picklist',
        isHighlighted: true,
        options: [
            { label: 'Low', value: 'Low' },
            { label: 'Medium', value: 'Medium' },
            { label: 'High', value: 'High' }
        ]
    }
];


// =============================================================================
// EJEMPLO 6: OVERRIDABLE - atributo transversal en cualquier tipo
// =============================================================================
// Cuando overridable=true Y value !== originalValue, aparece:
//   - Icono warning ⚠️ al lado de la label con tooltip "Original value: X"
//   - Botón revert ↶ al lado del input (o al lado del lápiz en modo read)
// =============================================================================
const exampleOverridableFields = [

    // TEXT overridable - YA OVERRIDDEN (warning + revert visibles)
    {
        id: 'OverriddenText',
        label: 'Negotiated Term',
        value: '36 meses',
        originalValue: '24 meses',
        size: '1-of-2',
        type: 'text',
        overridable: true,
        helpText: 'Plazo negociado con el cliente.'
    },

    // TEXT overridable - NO OVERRIDDEN (mismo valor que original, no se ve nada)
    {
        id: 'NotOverriddenText',
        label: 'Standard Term',
        value: '12 meses',
        originalValue: '12 meses',
        size: '1-of-2',
        type: 'text',
        overridable: true
    },

    // NUMBER overridable
    {
        id: 'OverriddenNumber',
        label: 'Approved Rate (%)',
        value: 6.25,
        originalValue: 5.00,
        size: '1-of-2',
        type: 'number',
        overridable: true,
        step: 0.01,
        min: 0,
        max: 100,
        helpText: 'Tasa aprobada.'
    },

    // CURRENCY overridable
    {
        id: 'OverriddenCurrency',
        label: 'Final Amount',
        value: 1200000,
        originalValue: 1500000,
        size: '1-of-2',
        type: 'currency',
        currencyCode: 'USD',
        overridable: true,
        helpText: 'Monto final negociado.'
    },

    // DATE overridable
    {
        id: 'OverriddenDate',
        label: 'Disbursement Date',
        value: '2025-08-15',
        originalValue: '2025-07-01',
        size: '1-of-2',
        type: 'date',
        overridable: true
    },

    // PICKLIST overridable — originalValue como valor plano (API value)
    // El tooltip mostrará el API value directamente: "Original value: Medium"
    {
        id: 'OverriddenPicklist',
        label: 'Risk Level',
        value: 'High',
        originalValue: 'Medium',
        size: '1-of-2',
        type: 'picklist',
        overridable: true,
        options: [
            { label: 'Low', value: 'Low' },
            { label: 'Medium', value: 'Medium' },
            { label: 'High', value: 'High' }
        ]
    },

    // PICKLIST overridable — originalValue como objeto { label, value }
    // Útil cuando el API value no es legible (código interno, ID, etc.).
    // - El tooltip mostrará el label:  "Original value: Aprobado"
    // - El revert restaurará el value: 'APPROVED'
    // - La comparación se hace contra value, no contra label
    {
        id: 'OverriddenPicklistStructured',
        label: 'Approval Status',
        value: 'REJECTED',
        originalValue: { label: 'Aprobado', value: 'APPROVED' },
        size: '1-of-2',
        type: 'picklist',
        overridable: true,
        options: [
            { label: 'Pendiente', value: 'PENDING' },
            { label: 'Aprobado',  value: 'APPROVED' },
            { label: 'Rechazado', value: 'REJECTED' }
        ],
        helpText: 'Ejemplo con originalValue estructurado { label, value }.'
    },

    // CHECKBOX overridable (true vs false)
    {
        id: 'OverriddenCheckbox',
        label: 'Approved by Committee',
        value: true,
        originalValue: false,
        size: '1-of-2',
        type: 'checkbox',
        overridable: true,
        helpText: 'Marcar si fue aprobado por comité.'
    },

    // EMAIL overridable
    {
        id: 'OverriddenEmail',
        label: 'Billing Email',
        value: 'nuevo@empresa.com',
        originalValue: 'viejo@empresa.com',
        size: '1-of-2',
        type: 'email',
        overridable: true
    }
];


// =============================================================================
// EJEMPLO 7: SIZES - diferentes anchos para probar el layout
// =============================================================================
const exampleSizes = [

    // 1-of-1 (ancho completo)
    {
        id: 'FullWidth',
        label: 'Full Width Field',
        value: 'Ocupa toda la fila',
        size: '1-of-1',
        type: 'text'
    },

    // 1-of-2 (dos columnas)
    {
        id: 'Half1',
        label: 'Half 1',
        value: 'Primera mitad',
        size: '1-of-2',
        type: 'text'
    },
    {
        id: 'Half2',
        label: 'Half 2',
        value: 'Segunda mitad',
        size: '1-of-2',
        type: 'text'
    },

    // 1-of-3 (tres columnas)
    {
        id: 'Third1',
        label: 'Third 1',
        value: 'Tercio 1',
        size: '1-of-3',
        type: 'text'
    },
    {
        id: 'Third2',
        label: 'Third 2',
        value: 'Tercio 2',
        size: '1-of-3',
        type: 'text'
    },
    {
        id: 'Third3',
        label: 'Third 3',
        value: 'Tercio 3',
        size: '1-of-3',
        type: 'text'
    },

    // 1-of-4 (cuatro columnas)
    {
        id: 'Quarter1',
        label: 'Q1',
        value: 100,
        size: '1-of-4',
        type: 'number'
    },
    {
        id: 'Quarter2',
        label: 'Q2',
        value: 200,
        size: '1-of-4',
        type: 'number'
    },
    {
        id: 'Quarter3',
        label: 'Q3',
        value: 300,
        size: '1-of-4',
        type: 'number'
    },
    {
        id: 'Quarter4',
        label: 'Q4',
        value: 400,
        size: '1-of-4',
        type: 'number'
    }
];


// =============================================================================
// EJEMPLO 8: BLANKS - espacios en blanco para layouts asimétricos
// =============================================================================
// Los blanks NO se envían en getChanges() y no disparan eventos.
// Sirven solo para "saltarse" una celda y mantener el alineamiento del grid.
// =============================================================================
const exampleBlankLayout = [

    // Fila 1: campo + blank (ocupa media fila visualmente)
    {
        id: 'FieldA',
        label: 'Field A',
        value: 'Solo a la izquierda',
        size: '1-of-2',
        type: 'text'
    },
    {
        id: 'blank1',
        type: 'blank',
        size: '1-of-2'
    },

    // Fila 2: tres en tercios, último blank
    {
        id: 'FieldB',
        label: 'Field B',
        value: 'Tercio 1',
        size: '1-of-3',
        type: 'text'
    },
    {
        id: 'FieldC',
        label: 'Field C',
        value: 'Tercio 2',
        size: '1-of-3',
        type: 'text'
    },
    {
        id: 'blank2',
        type: 'blank',
        size: '1-of-3'
    },

    // Fila 3: blank al inicio + campo a la derecha
    {
        id: 'blank3',
        type: 'blank',
        size: '1-of-2'
    },
    {
        id: 'FieldD',
        label: 'Field D (alineado a la derecha)',
        value: 'Solo a la derecha',
        size: '1-of-2',
        type: 'text'
    }
];


// =============================================================================
// EJEMPLO 9: COMBO COMPLETO - todos los atributos mezclados
// =============================================================================
// Caso realista de un formulario de oportunidad con readonly, hidden,
// highlighted, overridable, required, blanks y diferentes sizes.
// =============================================================================
const exampleFullForm = [

    // Header readonly
    {
        id: 'Name',
        label: 'Opportunity Name',
        value: 'Crédito Empresa XYZ',
        size: '1-of-2',
        type: 'text',
        isReadOnly: true,
        isRequired: true
    },
    {
        id: 'Stage',
        label: 'Stage',
        value: 'In Progress',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: true,
        options: [
            { label: 'Draft', value: 'Draft' },
            { label: 'In Progress', value: 'In Progress' },
            { label: 'Approved', value: 'Approved' }
        ]
    },

    // Datos editables con highlight
    {
        id: 'StartDate',
        label: 'Start Date',
        value: '2025-06-01',
        size: '1-of-2',
        type: 'date',
        isRequired: true,
        isHighlighted: true,
        helpText: 'Fecha de inicio de la operación.'
    },
    {
        id: 'EndDate',
        label: 'End Date',
        value: '2026-06-01',
        size: '1-of-2',
        type: 'date',
        isRequired: false
    },

    // Currency con overridable activo
    {
        id: 'Amount',
        label: 'Approved Amount',
        value: 850000,
        originalValue: 1000000,
        size: '1-of-2',
        type: 'currency',
        currencyCode: 'USD',
        overridable: true,
        isRequired: true,
        helpText: 'Monto aprobado por comité.'
    },

    // Number con overridable sin override (mismo valor)
    {
        id: 'Rate',
        label: 'Interest Rate (%)',
        value: 5.5,
        originalValue: 5.5,
        size: '1-of-2',
        type: 'number',
        overridable: true,
        step: 0.01,
        min: 0,
        max: 100
    },

    // Email + Phone
    {
        id: 'Email',
        label: 'Contact Email',
        value: 'contacto@xyz.com',
        size: '1-of-2',
        type: 'email',
        isRequired: true
    },
    {
        id: 'Phone',
        label: 'Contact Phone',
        value: '+34 600 123 456',
        size: '1-of-2',
        type: 'phone'
    },

    // Checkbox overridable
    {
        id: 'NeedsReview',
        label: 'Needs Review',
        value: true,
        originalValue: false,
        size: '1-of-2',
        type: 'checkbox',
        overridable: true,
        helpText: 'Requiere revisión adicional.'
    },

    // Hidden (no se renderiza)
    {
        id: 'InternalFlag',
        label: 'Internal Flag',
        value: 'oculto-del-DOM',
        size: '1-of-2',
        type: 'text',
        isHidden: true
    },

    // Textarea full width
    {
        id: 'Notes',
        label: 'Notes',
        value: 'Cliente con buen historial. Solicita revisión de tasas.',
        size: '1-of-1',
        type: 'textarea',
        maxLength: 500,
        helpText: 'Notas internas del analista.'
    }
];


// =============================================================================
// EJEMPLO 10: TEXTAREA - casos de truncado y "View More"
// =============================================================================
const exampleTextareas = [

    // Textarea corta (no se trunca)
    {
        id: 'ShortText',
        label: 'Short Note',
        value: 'Texto corto.',
        size: '1-of-1',
        type: 'textarea'
    },

    // Textarea larga en 1-of-1 (puede truncar según ancho)
    {
        id: 'LongText',
        label: 'Long Note',
        value: 'Este es un texto muy largo que probablemente se truncará en modo lectura mostrando un botón "View More" para expandir el contenido completo. El truncado se basa en el ancho del contenedor, no en el número de caracteres.',
        size: '1-of-1',
        type: 'textarea',
        maxLength: 1000
    },

    // Textarea en 1-of-2 (más probable que trunque)
    {
        id: 'HalfText',
        label: 'Half Width Note',
        value: 'Texto a media columna que casi seguro se truncará en el modo lectura porque el contenedor es estrecho.',
        size: '1-of-2',
        type: 'textarea'
    }
];
// =============================================================================
// EJEMPLO 12: CUSTOM LOOKUP — casos de uso completos
// =============================================================================
//
// Tipo: 'customLookup'
//
// ATRIBUTOS:
//   objectApiName   (string)     → objeto Salesforce a consultar
//   searchFields    (string[])   → campos OR cuando el usuario escribe
//   returnFields    (string[])   → campos extra a traer (además de primaryField)
//   primaryField    (string)     → campo principal: pill, modo read, ORDER BY
//   secondaryFields (string[])   → segunda línea en opciones, unidos por " - "
//   filters         (array|obj)  → condiciones fijas siempre activas (ver formatos)
//   iconName        (string)     → icono SLDS. Default: 'standard:record'
//   recordLimit     (number)     → máximo resultados. Default y tope: 20
//
// VALUE:
//   Siempre un Id string o null.
//   { value: 'a1eKG0000000fL1YAI' } → el componente llama Apex para resolver el label
//   { value: null }                 → sin selección
//
// EVENTO fieldchange emite:
//   { fieldId, apiName, type: 'customLookup', value: 'a1eKG...' | null }
//
// =============================================================================
// FORMATOS DE FILTERS
// =============================================================================
//
// Sin filtros:
//   filters: null
//
// Array plano — todos AND, LIKE por defecto si no hay operator:
//   filters: [
//     { field: 'Alpha_code__c', value: '%ES%' }
//     → Alpha_code__c LIKE '%ES%'  (wildcards son del caller)
//   ]
//
// Array con operadores explícitos:
//   filters: [
//     { field: 'Alpha_code__c', operator: 'LIKE', value: 'ES'   },
//     { field: 'IsActive__c',   operator: '=',    value: 'true' },
//     { field: 'Amount__c',     operator: '>=',   value: '1000' },
//     { field: 'Stage__c',      operator: '!=',   value: 'Lost' },
//     { field: 'Type__c',       operator: 'IN',   value: ['Customer', 'Partner'] },
//   ]
//
// Árbol anidado AND/OR:
//   filters: {
//     AND: [
//       { field: 'IsActive__c', operator: '=', value: 'true' },
//       { OR: [
//           { field: 'Type__c', operator: '=', value: 'Customer' },
//           { field: 'Type__c', operator: '=', value: 'Partner'  },
//       ]},
//     ]
//   }
//
// Operadores soportados: LIKE (default), =, !=, <, <=, >, >=, IN
// LIKE pasa el valor tal cual — los wildcards % los pones tú en el value.
//
// DIFERENCIA CLAVE:
//   searchFields → OR mientras el usuario escribe, solo si hay texto
//   filters      → siempre activos, independientes del texto escrito
//
// WHERE generado:
//   (Name LIKE '%abc%' OR Alpha_code__c LIKE '%abc%')  ← searchFields
//   AND Alpha_code__c = 'ES'                           ← filters
//   AND (Type__c = 'Customer' OR Type__c = 'Partner')  ← filters anidados
// =============================================================================

export const exampleCustomLookups = [

    // -------------------------------------------------------------------------
    // Caso 1: Sin filtros — muestra todos los registros al hacer foco
    // El usuario puede buscar por Name, Alpha_code o NIF fiscal
    // -------------------------------------------------------------------------
    {
        id: 'Local_Client__c',
        label: 'Local Client',
        apiName: 'Local_Client__c',
        value: null,
        size: '1-of-2',
        type: 'customLookup',
        isRequired: true,
        helpText: 'Busca por nombre, código alpha o NIF fiscal.',
        placeholder: 'Search local client...',
        iconName: 'standard:account',
        objectApiName: 'Local_Client__c',
        primaryField: 'Name',
        secondaryFields: ['Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        searchFields: ['Name', 'Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        returnFields: ['Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        filters: null,
    },

    // -------------------------------------------------------------------------
    // Caso 2: Con valor preseleccionado (Id string)
    // El componente llama Apex automáticamente para resolver el label (Name)
    // -------------------------------------------------------------------------
    {
        id: 'Local_Client_Pre__c',
        label: 'Local Client (pre-selected)',
        apiName: 'Local_Client__c',
        value: 'a1eKG0000000fL1YAI',
        size: '1-of-2',
        type: 'customLookup',
        isRequired: true,
        placeholder: 'Search local client...',
        iconName: 'standard:account',
        objectApiName: 'Local_Client__c',
        primaryField: 'Name',
        secondaryFields: ['Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        searchFields: ['Name', 'Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        returnFields: ['Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        filters: null,
    },

    // -------------------------------------------------------------------------
    // Caso 3: Filtro LIKE — solo clientes de España
    // Sin operator → LIKE por defecto. El valor '%ES%' incluye wildcards explícitos.
    // -------------------------------------------------------------------------
    {
        id: 'Local_Client_ES__c',
        label: 'Local Client (Spain)',
        apiName: 'Local_Client__c',
        value: null,
        size: '1-of-2',
        type: 'customLookup',
        isRequired: true,
        helpText: 'Solo clientes con código alpha ES.',
        placeholder: 'Search Spanish client...',
        iconName: 'standard:account',
        objectApiName: 'Local_Client__c',
        primaryField: 'Name',
        secondaryFields: ['Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        searchFields: ['Name', 'Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        returnFields: ['Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        filters: [
            { field: 'Alpha_code__c',operator: 'LIKE', value: '%ES%' },
        ],
    },

    // -------------------------------------------------------------------------
    // Caso 4: Filtro igualdad exacta + IN
    // Solo clientes activos de tipo Customer o Partner
    // -------------------------------------------------------------------------
    {
        id: 'Active_Client__c',
        label: 'Active Client',
        apiName: 'Local_Client__c',
        value: null,
        size: '1-of-2',
        type: 'customLookup',
        isRequired: false,
        helpText: 'Solo clientes activos de tipo Customer o Partner.',
        placeholder: 'Search active client...',
        iconName: 'standard:account',
        objectApiName: 'Local_Client__c',
        primaryField: 'Name',
        secondaryFields: ['Alpha_code__c', 'Type__c'],
        searchFields: ['Name', 'Alpha_code__c'],
        returnFields: ['Alpha_code__c', 'Type__c'],
        filters: [
            { field: 'IsActive__c', operator: '=',  value: 'true' },
            { field: 'Type__c',     operator: 'IN', value: ['Customer', 'Partner'] },
        ],
    },

    // -------------------------------------------------------------------------
    // Caso 5: Filtro con comparación numérica
    // Oportunidades abiertas con importe >= 100.000
    // -------------------------------------------------------------------------
    {
        id: 'Big_Opportunity__c',
        label: 'Large Opportunity',
        apiName: 'OpportunityId__c',
        value: null,
        size: '1-of-2',
        type: 'customLookup',
        isRequired: false,
        helpText: 'Oportunidades abiertas con importe ≥ 100.000.',
        placeholder: 'Search opportunity...',
        iconName: 'standard:opportunity',
        objectApiName: 'Opportunity',
        primaryField: 'Name',
        secondaryFields: ['StageName', 'Amount'],
        searchFields: ['Name'],
        returnFields: ['StageName', 'Amount'],
        filters: [
            { field: 'Amount',    operator: '>=', value: '100000'     },
            { field: 'StageName', operator: '!=', value: 'Closed Lost' },
            { field: 'StageName', operator: '!=', value: 'Closed Won'  },
        ],
    },

    // -------------------------------------------------------------------------
    // Caso 6: Árbol AND/OR — clientes activos de España o Portugal
    // WHERE IsActive__c = true AND (Alpha_code__c = 'ES' OR Alpha_code__c = 'PT')
    // -------------------------------------------------------------------------
    {
        id: 'Iberian_Client__c',
        label: 'Iberian Client',
        apiName: 'Local_Client__c',
        value: null,
        size: '1-of-2',
        type: 'customLookup',
        isRequired: true,
        helpText: 'Clientes activos de España o Portugal.',
        placeholder: 'Search Iberian client...',
        iconName: 'standard:account',
        objectApiName: 'Local_Client__c',
        primaryField: 'Name',
        secondaryFields: ['Alpha_code__c'],
        searchFields: ['Name', 'Alpha_code__c'],
        returnFields: ['Alpha_code__c'],
        filters: {
            AND: [
                { field: 'IsActive__c', operator: '=', value: 'true' },
                {
                    OR: [
                        { field: 'Alpha_code__c', operator: '=', value: 'ES' },
                        { field: 'Alpha_code__c', operator: '=', value: 'PT' },
                    ]
                },
            ]
        },
    },

    // -------------------------------------------------------------------------
    // Caso 7: Árbol complejo — múltiples niveles anidados
    // WHERE Alpha_code__c = 'ES'
    //   AND IsActive__c = true
    //   AND Status__c != 'Draft'
    //   AND (Type__c = 'Customer' OR Type__c = 'Partner')
    // -------------------------------------------------------------------------
    {
        id: 'Qualified_Client__c',
        label: 'Qualified Client',
        apiName: 'Local_Client__c',
        value: null,
        size: '1-of-2',
        type: 'customLookup',
        isRequired: true,
        helpText: 'Clientes cualificados: ES, activos, Customer/Partner, no Draft.',
        placeholder: 'Search qualified client...',
        iconName: 'standard:account',
        objectApiName: 'Local_Client__c',
        primaryField: 'Name',
        secondaryFields: ['Alpha_code__c', 'Type__c'],
        searchFields: ['Name', 'Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        returnFields: ['Alpha_code__c', 'Type__c'],
        filters: {
            AND: [
                { field: 'Alpha_code__c', operator: '=',  value: 'ES'    },
                { field: 'IsActive__c',   operator: '=',  value: 'true'  },
                { field: 'Status__c',     operator: '!=', value: 'Draft'  },
                {
                    OR: [
                        { field: 'Type__c', operator: '=', value: 'Customer' },
                        { field: 'Type__c', operator: '=', value: 'Partner'  },
                    ]
                },
            ]
        },
    },

    // -------------------------------------------------------------------------
    // Caso 8: Campo cross-object en secondaryFields
    // Muestra el NIF fiscal del cliente relacionado (relación padre)
    // -------------------------------------------------------------------------
    {
        id: 'Local_Client_CIB__c',
        label: 'Local Client (with fiscal ID)',
        apiName: 'Local_Client__c',
        value: null,
        size: '1-of-2',
        type: 'customLookup',
        isRequired: true,
        placeholder: 'Search client...',
        iconName: 'standard:account',
        objectApiName: 'Local_Client__c',
        primaryField: 'Name',
        secondaryFields: ['Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        searchFields: ['Name', 'Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        returnFields: ['Alpha_code__c', 'Cib_Client__r.DES_ID_Fiscal__c'],
        filters: null,
        // Opción del dropdown:
        //   Acme Corporation
        //   ES · B12345678
    },

    // -------------------------------------------------------------------------
    // Caso 9: readOnly — solo modo read, muestra el label del Id
    // -------------------------------------------------------------------------
    {
        id: 'ReadOnly_Client__c',
        label: 'Assigned Client',
        apiName: 'Local_Client__c',
        value: 'a1eKG0000000fL1YAI',
        size: '1-of-2',
        type: 'customLookup',
        isReadOnly: true,
        helpText: 'Campo de solo lectura.',
        iconName: 'standard:account',
        objectApiName: 'Local_Client__c',
        primaryField: 'Name',
        secondaryFields: ['Alpha_code__c'],
        searchFields: ['Name', 'Alpha_code__c'],
        returnFields: ['Alpha_code__c'],
        filters: null,
    },

    // -------------------------------------------------------------------------
    // Caso 10: overridable — warning ⚠️ + botón revert ↶
    // Los ids son distintos → isOverridden = true
    // -------------------------------------------------------------------------
    {
        id: 'Overridden_Client__c',
        label: 'Overridden Client',
        apiName: 'Local_Client__c',
        value: 'a1eKG0000000fB4YAI',
        originalValue: 'a1eKG0000000fB3YAI',
        overridable: true,
        size: '1-of-2',
        type: 'customLookup',
        isRequired: true,
        helpText: 'Cliente modificado respecto al original.',
        iconName: 'standard:account',
        objectApiName: 'Local_Client__c',
        primaryField: 'Name',
        secondaryFields: ['Alpha_code__c'],
        searchFields: ['Name', 'Alpha_code__c'],
        returnFields: ['Alpha_code__c'],
        filters: [
            { field: 'Alpha_code__c', value: '%ES%' },
        ],
    },

    // -------------------------------------------------------------------------
    // Caso 11: highlighted — campo marcado como editado visualmente
    // -------------------------------------------------------------------------
    {
        id: 'Highlighted_Client__c',
        label: 'Highlighted Client',
        apiName: 'Local_Client__c',
        value: 'a1eKG0000000fB6YAI',
        size: '1-of-2',
        type: 'customLookup',
        isHighlighted: true,
        iconName: 'standard:account',
        objectApiName: 'Local_Client__c',
        primaryField: 'Name',
        secondaryFields: ['Alpha_code__c'],
        searchFields: ['Name', 'Alpha_code__c'],
        returnFields: ['Alpha_code__c'],
        filters: null,
    },

    // -------------------------------------------------------------------------
    // Caso 12: recordLimit personalizado — máximo 5 resultados
    // -------------------------------------------------------------------------
    {
        id: 'Limited_Client__c',
        label: 'Local Client (max 5)',
        apiName: 'Local_Client__c',
        value: null,
        size: '1-of-2',
        type: 'customLookup',
        placeholder: 'Search (max 5)...',
        iconName: 'standard:account',
        objectApiName: 'Local_Client__c',
        primaryField: 'Name',
        secondaryFields: ['Alpha_code__c'],
        searchFields: ['Name', 'Alpha_code__c'],
        returnFields: ['Alpha_code__c'],
        filters: null,
        recordLimit: 5,
    },

];




// =============================================================================
// CÓMO USAR ESTOS EJEMPLOS
// =============================================================================
// En tu componente padre:
//
// import { LightningElement, track } from 'lwc';
//
// export default class MyParent extends LightningElement {
//     @track fields = exampleFullForm;        // o cualquier otro ejemplo
//     @track isEditMode = false;
//
//     handleEditModeChange(event) {
//         this.isEditMode = event.detail.isEditMode;
//     }
//
//     handleFieldChange(event) {
//         console.log('Field changed:', event.detail);
//     }
//
//     handleSave() {
//         const child = this.template.querySelector('c-dmt_form_renderer');
//         const changes = child.getChanges();
//         console.log('All field values:', changes);
//     }
// }
//
// Y en el HTML del padre:
//
// <c-dmt_form_renderer
//     fields={fields}
//     is-edit-mode={isEditMode}
//     oneditmodechange={handleEditModeChange}
//     onfieldchange={handleFieldChange}>
// </c-dmt_form_renderer>
// =============================================================================


// Exporta los ejemplos por si los importas como módulo
export {
    exampleAllTypes,
    exampleEmptyValues,
    exampleReadOnlyFields,
    exampleHiddenFields,
    exampleHighlightedFields,
    exampleOverridableFields,
    exampleSizes,
    exampleBlankLayout,
    exampleFullForm,
    exampleTextareas
};