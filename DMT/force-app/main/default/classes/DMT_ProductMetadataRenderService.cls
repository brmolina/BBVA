public with sharing class DMT_ProductMetadataRenderService {
    private static final String WARRANTY_FIELD_KEY = 'DMT_Warranty__c.g_limits_grid_guarantee_type__c';
    private static final String CURRENCY_PROVISION_FIELD_KEY = 'DMT_Currency_Provision__c.g_currency_id__c';
    private static Map<String, Map<String, String>> taxonomyLabelsByCatalog = new Map<String, Map<String, String>>();

    public class RenderSection {
        public String title;
        public Decimal order;
        public List<DMT_FormattingUtils.DisplayField> fields = new List<DMT_FormattingUtils.DisplayField>();
    }

    private class RenderConfig implements Comparable {
        DMT_LineOtherTemplateConfig__mdt metadata;
        String fieldKey;
        String fieldApi;
        String sourceObject;
        Integer score;

        public Integer compareTo(Object other) {
            RenderConfig that = (RenderConfig) other;
            Integer thisSectionOrder = this.metadata.SectionOrder__c == null ? 9999 : Integer.valueOf(this.metadata.SectionOrder__c);
            Integer thatSectionOrder = that.metadata.SectionOrder__c == null ? 9999 : Integer.valueOf(that.metadata.SectionOrder__c);
            if (thisSectionOrder != thatSectionOrder) {
                return thisSectionOrder < thatSectionOrder ? -1 : 1;
            }

            Integer thisFieldOrder = this.metadata.FieldOrder__c == null ? 9999 : Integer.valueOf(this.metadata.FieldOrder__c);
            Integer thatFieldOrder = that.metadata.FieldOrder__c == null ? 9999 : Integer.valueOf(that.metadata.FieldOrder__c);
            if (thisFieldOrder != thatFieldOrder) {
                return thisFieldOrder < thatFieldOrder ? -1 : 1;
            }

            String thisLabel = String.valueOf(this.metadata.DisplayLabel__c);
            String thatLabel = String.valueOf(that.metadata.DisplayLabel__c);
            thisLabel = thisLabel.toLowerCase();
            thatLabel = thatLabel.toLowerCase();
            return thisLabel.compareTo(thatLabel);
        }
    }

    public static List<RenderSection> buildSections(
        DMT_ViewController.LineDataWrapper data,
        DMT_Risk_Line_Term__c baseRiskLine,
        String lineTypeCode,
        String defaultSubtype
    ) {
        Map<Id, List<RenderSection>> sectionsByRiskId = buildSectionsForRisks(
            data,
            baseRiskLine == null ? new List<DMT_Risk_Line_Term__c>() : new List<DMT_Risk_Line_Term__c>{ baseRiskLine },
            lineTypeCode,
            defaultSubtype
        );
        return baseRiskLine != null && sectionsByRiskId.containsKey(baseRiskLine.Id)
            ? sectionsByRiskId.get(baseRiskLine.Id)
            : new List<RenderSection>();
    }

    public static Map<Id, List<RenderSection>> buildSectionsForRisks(
        DMT_ViewController.LineDataWrapper data,
        List<DMT_Risk_Line_Term__c> baseRiskLines,
        String lineTypeCode,
        String defaultSubtype
    ) {
        Map<Id, List<RenderSection>> result = new Map<Id, List<RenderSection>>();
        if (data == null || baseRiskLines == null || baseRiskLines.isEmpty() || String.isBlank(lineTypeCode)) {
            return result;
        }

        String entific = data.line == null ? null : data.line.DMT_Client_Entific__c;
        List<DMT_LineOtherTemplateConfig__mdt> metadataRows = fetchMetadata(entific, lineTypeCode);
        if (metadataRows.isEmpty()) {
            return result;
        }

        Map<Id, DMT_Risk_Line_Term__c> enrichedRiskLines = enrichRiskLines(baseRiskLines, metadataRows);
        for (DMT_Risk_Line_Term__c baseRiskLine : baseRiskLines) {
            DMT_Risk_Line_Term__c riskLine = enrichedRiskLines.containsKey(baseRiskLine.Id)
                ? enrichedRiskLines.get(baseRiskLine.Id)
                : baseRiskLine;
            List<RenderSection> sections = buildSectionsForRisk(data, riskLine, metadataRows, defaultSubtype);
            if (!sections.isEmpty()) {
                result.put(baseRiskLine.Id, sections);
            }
        }
        return result;
    }

    public static void enrichLineOnWrapper(DMT_ViewController.LineDataWrapper data, String lineTypeCode) {
        if (data == null || data.line == null || data.line.Id == null) {
            return;
        }
        String entific = data.line.DMT_Client_Entific__c;
        List<DMT_LineOtherTemplateConfig__mdt> metadataRows = fetchMetadata(entific, lineTypeCode);
        if (!metadataRows.isEmpty()) {
            data.line = enrichLine(data.line, metadataRows);
            System.Formula.recalculateFormulas(new List<SObject>{ data.line });
        }
    }

    private static List<RenderSection> buildSectionsForRisk(
        DMT_ViewController.LineDataWrapper data,
        DMT_Risk_Line_Term__c riskLine,
        List<DMT_LineOtherTemplateConfig__mdt> metadataRows,
        String defaultSubtype
    ) {
        String riskSubtype = resolveRiskSubtype(riskLine, defaultSubtype);
        List<RenderConfig> configs = resolveConfigs(metadataRows, riskSubtype);
        if (configs.isEmpty()) {
            return new List<RenderSection>();
        }

        List<RenderSection> sections = new List<RenderSection>();
        Map<String, RenderSection> sectionByKey = new Map<String, RenderSection>();
        for (RenderConfig config : configs) {
            if (isHiddenByVisibilityRule(data, riskLine, config.metadata.VisibilityRule__c)) {
                continue;
            }

            DMT_FormattingUtils.DisplayField field = buildDisplayField(data, riskLine, config);
            if (field == null) {
                continue;
            }

            String sectionTitle = String.isBlank(config.metadata.Section__c) ? '' : config.metadata.Section__c.trim();
            String sectionKey = String.isBlank(sectionTitle)
                ? String.valueOf(config.metadata.SectionOrder__c)
                : sectionTitle.toLowerCase().replaceAll('\\s+', ' ');
            if (!sectionByKey.containsKey(sectionKey)) {
                RenderSection section = new RenderSection();
                section.title = sectionTitle;
                section.order = config.metadata.SectionOrder__c;
                sectionByKey.put(sectionKey, section);
                sections.add(section);
            }
            sectionByKey.get(sectionKey).fields.add(field);
        }
        return sections;
    }

    public static String renderSectionsHtml(List<RenderSection> sections) {
        String html = '';
        for (RenderSection section : sections) {
            if (!String.isBlank(section.title)) {
                html += '<h4 style="font-size: 14px; color: #004481; margin: 10px 0 6px; font-weight: bold">'
                    + DMT_FormattingUtils.checkNull(section.title)
                    + '</h4>';
            }
            html += DMT_FormattingUtils.generateHtmlTable(section.fields);
        }
        return html;
    }

    // CIBGLOBALD-4117: lets a test substitute a fixed, in-memory list of config rows instead of the
    // org's live DMT_LineOtherTemplateConfig__mdt data, for deterministic coverage of branches a
    // test can't otherwise reach or rely on (a specific Entific__c/TemplateSubtype__c combination, a
    // catch-all-free scenario, a 'related'/'special' FilterText__c alias the org's current rows
    // don't happen to use). Custom Metadata records cannot be inserted via DML even in test context
    // - this in-memory override is the standard workaround, same convention as
    // DMT_AsyncDispatcher.forceStatusCodeForTest for other otherwise-live state this class can't
    // control from a test. Set it directly from an @IsTest method (e.g.
    // DMT_ProductMetadataRenderService.testMetadataOverride = new List<DMT_LineOtherTemplateConfig__mdt>{...};)
    // - a fresh transaction per test method means no manual reset is needed between tests.
    @TestVisible
    private static List<DMT_LineOtherTemplateConfig__mdt> testMetadataOverride = null;

    private static Boolean passesBaseMetadataFilter(DMT_LineOtherTemplateConfig__mdt m) {
        return m.isActive__c == true
            && (m.Field_View_Is_Disabled__c == false || m.Field_View_Is_Disabled__c == null);
    }

    private static List<DMT_LineOtherTemplateConfig__mdt> fetchMetadata(String entific, String lineTypeCode) {
        if (testMetadataOverride != null) {
            List<DMT_LineOtherTemplateConfig__mdt> filtered = new List<DMT_LineOtherTemplateConfig__mdt>();
            for (DMT_LineOtherTemplateConfig__mdt m : testMetadataOverride) {
                if (passesBaseMetadataFilter(m)
                        && (m.Entific__c == entific || String.isBlank(m.Entific__c))
                        && (m.LineType__c == lineTypeCode || String.isBlank(m.LineType__c))) {
                    filtered.add(m);
                }
            }
            return filtered;
        }
        return [
            SELECT DeveloperName, MasterLabel, FilterText__c, Field_View_Is_Disabled__c,
                   LineType__c, TemplateSubtype__c, Entific__c, isActive__c,
                   Section__c, SectionOrder__c, FieldOrder__c,
                 DisplayLabel__c, DataType__c, VisibilityRule__c,
                 OptionsJson__c, TaxonomyCatalog__c, TaxonomyFilterRule__c
            FROM DMT_LineOtherTemplateConfig__mdt
            WHERE isActive__c = true
              AND (Field_View_Is_Disabled__c = false OR Field_View_Is_Disabled__c = null)
              AND (Entific__c = :entific OR Entific__c = null OR Entific__c = '')
              AND (LineType__c = :lineTypeCode OR LineType__c = null OR LineType__c = '')
        ];
    }

    // CIBGLOBALD-4117: several config rows resolve at render time to a computed display value
    // (resolveValue() below) rather than a literal SObject field - a translated taxonomy label, a
    // joined product-hierarchy name, a concatenated Id. Traced by hand against resolveValue() and
    // DMT_ViewController's population of the same maps (productLevelsByRiskLine,
    // riskLineToTaxonomy*Map) back to the real stored field each one derives from, so field-change
    // tracking watches the actual field a user edits rather than its rendered label.
    private static final Map<String, String> SPECIAL_KEY_TO_RISK_FIELD = new Map<String, String>{
        'familyProduct' => 'g_global_product_family_Id__c',
        'subfamilyProduct' => 'g_global_product_subfamily_Id__c',
        'categoryProduct' => 'g_global_product_category_Id__c',
        'subcategoryProduct' => 'g_gbl_product_subcategory_Id__c',
        'taxonomyC162' => 'g_limit_sinds_ast_sctr_id__c',
        'taxonomyC164' => 'g_limit_sinds_ast_subsec_id__c',
        'taxonomyH007' => 'g_branch_id__c',
        'taxonomyALAT' => 'g_amortization_type__c'
    };

    // CIBGLOBALD-4117: every field a component watches for one line type, resolved from every
    // currently active DMT_LineOtherTemplateConfig__mdt row for that line type (union across every
    // Entific__c/TemplateSubtype__c variant, not just the one a given record currently matches - the
    // same "report the wider set, never risk missing one" trade DMT_TreasuryProductsRenderer already
    // makes across its CO/PE/default geography variants). Reuses this class's own field-resolution
    // (resolveRelatedKey/resolveSpecialKey/resolveFieldApiName) so the tracked-field list can never
    // silently drift from what the renderer itself actually displays.
    public static Map<String, List<String>> getConfiguredFieldsByObject(String lineTypeCode) {
        Map<String, List<String>> fieldsByObject = new Map<String, List<String>>();
        if (String.isBlank(lineTypeCode)) {
            return fieldsByObject;
        }

        Map<String, Schema.SObjectField> riskFields = DMT_Risk_Line_Term__c.SObjectType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> lineFields = DMT_Line__c.SObjectType.getDescribe().fields.getMap();
        Map<String, String> riskLookup = buildFieldLookup(riskFields);
        Map<String, String> lineLookup = buildFieldLookup(lineFields);

        for (DMT_LineOtherTemplateConfig__mdt metadata : fetchMetadataForLineType(lineTypeCode)) {
            String rawField = metadata.FilterText__c;
            if (String.isBlank(rawField)) {
                continue;
            }

            String relatedKey = resolveRelatedKey(rawField);
            if (relatedKey == WARRANTY_FIELD_KEY) {
                addTrackedField(fieldsByObject, 'DMT_Warranty__c', 'Name');
                continue;
            }
            if (relatedKey == CURRENCY_PROVISION_FIELD_KEY) {
                addTrackedField(fieldsByObject, 'DMT_Currency_Provision__c', 'g_currency_id__c');
                continue;
            }

            String specialKey = resolveSpecialKey(rawField);
            if (specialKey == 'productName') {
                addTrackedField(fieldsByObject, 'DMT_Risk_Line_Term__c', 'DMT_Product__r.Name');
                continue;
            }
            if (specialKey == 'parentProductId') {
                addTrackedField(fieldsByObject, 'DMT_Line__c', 'Line_Id__c');
                addTrackedField(fieldsByObject, 'DMT_Risk_Line_Term__c', 'gf_group_priority_line_id__c');
                continue;
            }
            if (specialKey != null && SPECIAL_KEY_TO_RISK_FIELD.containsKey(specialKey)) {
                addTrackedField(fieldsByObject, 'DMT_Risk_Line_Term__c', SPECIAL_KEY_TO_RISK_FIELD.get(specialKey));
                continue;
            }

            String riskField = resolveFieldApiName(rawField, riskFields, riskLookup);
            if (riskField != null) {
                addTrackedField(fieldsByObject, 'DMT_Risk_Line_Term__c', riskField);
                continue;
            }
            String lineField = resolveFieldApiName(rawField, lineFields, lineLookup);
            if (lineField != null) {
                addTrackedField(fieldsByObject, 'DMT_Line__c', lineField);
            }
        }
        return fieldsByObject;
    }

    private static void addTrackedField(Map<String, List<String>> fieldsByObject, String objectName, String fieldName) {
        if (!fieldsByObject.containsKey(objectName)) {
            fieldsByObject.put(objectName, new List<String>());
        }
        if (!fieldsByObject.get(objectName).contains(fieldName)) {
            fieldsByObject.get(objectName).add(fieldName);
        }
    }

    private static List<DMT_LineOtherTemplateConfig__mdt> fetchMetadataForLineType(String lineTypeCode) {
        if (testMetadataOverride != null) {
            List<DMT_LineOtherTemplateConfig__mdt> filtered = new List<DMT_LineOtherTemplateConfig__mdt>();
            for (DMT_LineOtherTemplateConfig__mdt m : testMetadataOverride) {
                if (passesBaseMetadataFilter(m) && (m.LineType__c == lineTypeCode || String.isBlank(m.LineType__c))) {
                    filtered.add(m);
                }
            }
            return filtered;
        }
        return [
            SELECT FilterText__c
            FROM DMT_LineOtherTemplateConfig__mdt
            WHERE isActive__c = true
              AND (Field_View_Is_Disabled__c = false OR Field_View_Is_Disabled__c = null)
              AND (LineType__c = :lineTypeCode OR LineType__c = null OR LineType__c = '')
        ];
    }

    private static List<RenderConfig> resolveConfigs(List<DMT_LineOtherTemplateConfig__mdt> metadataRows, String riskSubtype) {
        Map<String, Schema.SObjectField> riskFields = DMT_Risk_Line_Term__c.SObjectType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> lineFields = DMT_Line__c.SObjectType.getDescribe().fields.getMap();
        Map<String, String> riskLookup = buildFieldLookup(riskFields);
        Map<String, String> lineLookup = buildFieldLookup(lineFields);
        Map<String, RenderConfig> bestConfigByField = new Map<String, RenderConfig>();

        for (DMT_LineOtherTemplateConfig__mdt metadata : metadataRows) {
            if (!subtypeMatches(metadata.TemplateSubtype__c, riskSubtype)) {
                continue;
            }

            RenderConfig config = resolveConfig(metadata, riskFields, lineFields, riskLookup, lineLookup);
            if (config == null) {
                continue;
            }

            config.score = 0;
            if (!String.isBlank(metadata.Entific__c)) {
                config.score += 4;
            }
            if (!String.isBlank(metadata.LineType__c)) {
                config.score += 2;
            }
            if (!String.isBlank(metadata.TemplateSubtype__c)) {
                config.score += 1;
            }

            String key = config.fieldKey;
            if (!bestConfigByField.containsKey(key) || bestConfigByField.get(key).score <= config.score) {
                bestConfigByField.put(key, config);
            }
        }

        List<RenderConfig> configs = bestConfigByField.values();
        configs.sort();
        return configs;
    }

    private static RenderConfig resolveConfig(
        DMT_LineOtherTemplateConfig__mdt metadata,
        Map<String, Schema.SObjectField> riskFields,
        Map<String, Schema.SObjectField> lineFields,
        Map<String, String> riskLookup,
        Map<String, String> lineLookup
    ) {
        String rawField = metadata.FilterText__c;
        if (String.isBlank(rawField)) {
            return null;
        }

        RenderConfig config = new RenderConfig();
        config.metadata = metadata;
        String relatedKey = resolveRelatedKey(rawField);
        if (relatedKey != null) {
            config.fieldKey = relatedKey;
            config.sourceObject = 'related';
            return config;
        }

        String specialKey = resolveSpecialKey(rawField);
        if (specialKey != null) {
            config.fieldKey = specialKey;
            config.sourceObject = 'special';
            return config;
        }

        String riskField = resolveFieldApiName(rawField, riskFields, riskLookup);
        if (riskField != null) {
            config.fieldApi = riskField;
            config.fieldKey = 'risk.' + riskField;
            config.sourceObject = 'risk';
            return config;
        }

        String lineField = resolveFieldApiName(rawField, lineFields, lineLookup);
        if (lineField != null) {
            config.fieldApi = lineField;
            config.fieldKey = 'line.' + lineField;
            config.sourceObject = 'line';
            return config;
        }

        return null;
    }

    private static DMT_FormattingUtils.DisplayField buildDisplayField(
        DMT_ViewController.LineDataWrapper data,
        DMT_Risk_Line_Term__c riskLine,
        RenderConfig config
    ) {
        Object rawValue = resolveValue(data, riskLine, config);
        String label = resolveLabel(config);
        String size = resolveSize(config.metadata);

        if (rawValue instanceof Boolean) {
            return new DMT_FormattingUtils.DisplayField(label, (Boolean) rawValue, size);
        }

        String value = formatValue(data, riskLine, config, rawValue);
        return new DMT_FormattingUtils.DisplayField(label, value, size);
    }

    private static Object resolveValue(DMT_ViewController.LineDataWrapper data, DMT_Risk_Line_Term__c riskLine, RenderConfig config) {
        if (config.sourceObject == 'risk') {
            return getSObjectValue(riskLine, config.fieldApi);
        }
        if (config.sourceObject == 'line') {
            return getSObjectValue(data.line, config.fieldApi);
        }
        if (config.fieldKey == CURRENCY_PROVISION_FIELD_KEY) {
            DMT_Currency_Provision__c provision = data.riskLineToCurrencyProvisionMap.get(riskLine.Id);
            return provision == null || String.isBlank(provision.g_currency_id__c) ? 'All Currencies' : provision.g_currency_id__c;
        }
        if (config.fieldKey == WARRANTY_FIELD_KEY) {
            return DMT_FormattingUtils.getWarrantyNamesAsString(data.riskLineToWarrantyListMap.get(riskLine.Id));
        }
        if (config.fieldKey == 'productName') {
            return riskLine.DMT_Product__r == null ? null : riskLine.DMT_Product__r.Name;
        }
        if (config.fieldKey == 'parentProductId') {
            return DMT_FormattingUtils.checkNull(data.line.Line_Id__c) + '_' + DMT_FormattingUtils.checkNull(riskLine.gf_group_priority_line_id__c);
        }
        if (config.fieldKey == 'familyProduct' || config.fieldKey == 'subfamilyProduct'
            || config.fieldKey == 'categoryProduct' || config.fieldKey == 'subcategoryProduct') {
            Map<String, String> levels = data.productLevelsByRiskLine.get(riskLine.Id);
            return levels == null ? null : levels.get(config.fieldKey);
        }
        if (config.fieldKey == 'taxonomyC162') {
            return data.riskLineToTaxonomyC162Map.get(riskLine.Id);
        }
        if (config.fieldKey == 'taxonomyC164') {
            return data.riskLineToTaxonomyC164Map.get(riskLine.Id);
        }
        if (config.fieldKey == 'taxonomyH007') {
            return data.riskLineToTaxonomyH007Map.get(riskLine.Id);
        }
        if (config.fieldKey == 'taxonomyALAT') {
            return data.riskLineToTaxonomyALATMap.get(riskLine.Id);
        }
        return null;
    }

    private static String formatValue(
        DMT_ViewController.LineDataWrapper data,
        DMT_Risk_Line_Term__c riskLine,
        RenderConfig config,
        Object rawValue
    ) {
        if (config.fieldKey == 'risk.DMT_Amount__c' || config.fieldKey == 'line.Amount__c' || normalizeKey(config.metadata.FilterText__c) == 'amount') {
            String currencyIsoCode = riskLine.CurrencyIsoCode == null ? data.currencyIsoCode : riskLine.CurrencyIsoCode;
            return DMT_FormattingUtils.formatCurrencyAmount(rawValue, currencyIsoCode);
        }
        return DMT_FormattingUtils.checkNull(resolveConfiguredLabel(config.metadata, rawValue));
    }

    private static String resolveLabel(RenderConfig config) {
        if (!String.isBlank(config.metadata.DisplayLabel__c)) {
            return config.metadata.DisplayLabel__c;
        }

        Map<String, String> labelsBySpecialKey = new Map<String, String>{
            WARRANTY_FIELD_KEY => 'Required mitigants',
            CURRENCY_PROVISION_FIELD_KEY => 'Available Currencies',
            'productName' => 'Global Product',
            'parentProductId' => 'Parent Product Id',
            'familyProduct' => 'Global Product Family',
            'subfamilyProduct' => 'Global Product Subfamily',
            'categoryProduct' => 'Global Product Category',
            'subcategoryProduct' => 'Global Product Subcategory',
            'taxonomyC162' => 'Asset Allocation Sector Limitation',
            'taxonomyC164' => 'Asset Allocation Subsector Limitation',
            'taxonomyH007' => 'Booking Geography',
            'taxonomyALAT' => 'Amortization Type'
        };
        if (labelsBySpecialKey.containsKey(config.fieldKey)) {
            return labelsBySpecialKey.get(config.fieldKey);
        }

        if (config.sourceObject == 'risk' && !String.isBlank(config.fieldApi)) {
            return DMT_Risk_Line_Term__c.SObjectType.getDescribe().fields.getMap().get(config.fieldApi).getDescribe().getLabel();
        }
        if (config.sourceObject == 'line' && !String.isBlank(config.fieldApi)) {
            return DMT_Line__c.SObjectType.getDescribe().fields.getMap().get(config.fieldApi).getDescribe().getLabel();
        }
        return String.isBlank(config.metadata.MasterLabel) ? config.metadata.DeveloperName : config.metadata.MasterLabel;
    }

    private static String resolveSize(DMT_LineOtherTemplateConfig__mdt metadata) {
        // String.valueOf(null) returns null (not the string 'null') in Apex - guard each field
        // before lower-casing, since a config row can legitimately leave DataType__c/DisplayLabel__c
        // blank (resolveLabel/formatValue already fall back to other sources for the label itself).
        String dataType = metadata.DataType__c == null ? '' : String.valueOf(metadata.DataType__c).toLowerCase();
        String label = metadata.DisplayLabel__c == null ? '' : String.valueOf(metadata.DisplayLabel__c).toLowerCase();
        String filterText = metadata.FilterText__c == null ? '' : String.valueOf(metadata.FilterText__c).toLowerCase();
        if (dataType.contains('textarea') || dataType.contains('long') || dataType.contains('rich')
            || label.contains('comment') || filterText.contains('comment') || filterText.contains('additional_information')) {
            return 'FULL';
        }
        return 'HALF';
    }

    private static DMT_Risk_Line_Term__c enrichRiskLine(DMT_Risk_Line_Term__c baseRiskLine, List<DMT_LineOtherTemplateConfig__mdt> metadataRows) {
        Map<Id, DMT_Risk_Line_Term__c> enrichedRiskLines = enrichRiskLines(
            baseRiskLine == null ? new List<DMT_Risk_Line_Term__c>() : new List<DMT_Risk_Line_Term__c>{ baseRiskLine },
            metadataRows
        );
        return baseRiskLine != null && enrichedRiskLines.containsKey(baseRiskLine.Id) ? enrichedRiskLines.get(baseRiskLine.Id) : baseRiskLine;
    }

    private static Map<Id, DMT_Risk_Line_Term__c> enrichRiskLines(List<DMT_Risk_Line_Term__c> baseRiskLines, List<DMT_LineOtherTemplateConfig__mdt> metadataRows) {
        Map<Id, DMT_Risk_Line_Term__c> result = new Map<Id, DMT_Risk_Line_Term__c>();
        if (baseRiskLines == null || baseRiskLines.isEmpty()) {
            return result;
        }

        Set<String> fields = new Set<String>{
            'Id', 'Name', 'CurrencyIsoCode', 'gf_group_priority_line_id__c', 'DMT_Operation_Type__c',
            'DMT_Product__c', 'DMT_Product__r.Name'
        };
        Map<String, Schema.SObjectField> riskFields = DMT_Risk_Line_Term__c.SObjectType.getDescribe().fields.getMap();
        Map<String, String> riskLookup = buildFieldLookup(riskFields);
        for (DMT_LineOtherTemplateConfig__mdt metadata : metadataRows) {
            String rawField = metadata.FilterText__c;
            if (String.isBlank(rawField) || resolveRelatedKey(rawField) != null || resolveSpecialKey(rawField) != null) {
                continue;
            }
            String riskField = resolveFieldApiName(rawField, riskFields, riskLookup);
            if (riskField != null) {
                fields.add(riskField);
            }

            for (String visibilityField : extractRuleFieldNames(metadata.VisibilityRule__c)) {
                riskField = resolveFieldApiName(visibilityField, riskFields, riskLookup);
                if (riskField != null) {
                    fields.add(riskField);
                }
            }
        }

        Set<Id> riskIds = new Set<Id>();
        for (DMT_Risk_Line_Term__c baseRiskLine : baseRiskLines) {
            if (baseRiskLine.Id != null) {
                riskIds.add(baseRiskLine.Id);
            }
        }
        if (riskIds.isEmpty()) {
            return result;
        }

        String queryText = 'SELECT ' + String.join(new List<String>(fields), ',')
            + ' FROM DMT_Risk_Line_Term__c WHERE Id IN :riskIds';
        for (DMT_Risk_Line_Term__c riskLine : (List<DMT_Risk_Line_Term__c>) Database.query(queryText)) {
            result.put(riskLine.Id, riskLine);
        }
        return result;
    }

    private static DMT_Line__c enrichLine(DMT_Line__c baseLine, List<DMT_LineOtherTemplateConfig__mdt> metadataRows) {
        if (baseLine == null || baseLine.Id == null) {
            return baseLine;
        }

        Set<String> fields = new Set<String>{
            'Id', 'Line_Id__c', 'CurrencyIsoCode', 'DMT_Client_Entific__c', 'g_limit_last_level_type__c'
        };
        Map<String, Schema.SObjectField> riskFields = DMT_Risk_Line_Term__c.SObjectType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> lineFields = DMT_Line__c.SObjectType.getDescribe().fields.getMap();
        Map<String, String> riskLookup = buildFieldLookup(riskFields);
        Map<String, String> lineLookup = buildFieldLookup(lineFields);
        for (DMT_LineOtherTemplateConfig__mdt metadata : metadataRows) {
            String rawField = metadata.FilterText__c;
            if (String.isBlank(rawField) || resolveRelatedKey(rawField) != null || resolveSpecialKey(rawField) != null) {
                rawField = null;
            }
            if (rawField != null && resolveFieldApiName(rawField, riskFields, riskLookup) == null) {
                String lineField = resolveFieldApiName(rawField, lineFields, lineLookup);
                if (lineField != null) {
                    fields.add(lineField);
                }
            }

            for (String visibilityField : extractRuleFieldNames(metadata.VisibilityRule__c)) {
                if (resolveFieldApiName(visibilityField, riskFields, riskLookup) != null) {
                    continue;
                }
                String lineField = resolveFieldApiName(visibilityField, lineFields, lineLookup);
                if (lineField != null) {
                    fields.add(lineField);
                }
            }
        }

        Id lineId = baseLine.Id;
        String queryText = 'SELECT ' + String.join(new List<String>(fields), ',')
            + ' FROM DMT_Line__c WHERE Id = :lineId LIMIT 1';
        DMT_Line__c freshFields = (DMT_Line__c) Database.query(queryText);

        DMT_Line__c merged = baseLine.clone(true, false, false, false);
        for (String fieldName : fields) {
            if (fieldName == 'Id') {
                continue;
            }
            try {
                merged.put(fieldName, freshFields.get(fieldName));
            } catch (Exception ignored) {
                // Formula/non-writable fields cannot be set via put(); their values
                // are carried over from baseLine via clone and refreshed below.
            }
        }
        System.Formula.recalculateFormulas(new List<SObject>{ merged });
        return merged;
    }

    private static String resolveRiskSubtype(DMT_Risk_Line_Term__c riskLine, String defaultSubtype) {
        Object rawSubtype = getSObjectValue(riskLine, 'DMT_Operation_Type__c');
        String subtype = rawSubtype == null ? defaultSubtype : String.valueOf(rawSubtype);
        if (subtype == 'OPP') {
            return 'OPP';
        }
        if (subtype == 'TO' || subtype == 'LIN' || subtype == 'LINE') {
            return 'LIN';
        }
        return String.isBlank(subtype) ? null : subtype.trim();
    }

    private static Boolean subtypeMatches(String configSubtype, String riskSubtype) {
        if (String.isBlank(configSubtype)) {
            return true;
        }
        if (String.isBlank(riskSubtype)) {
            return false;
        }
        return configSubtype.trim().equalsIgnoreCase(riskSubtype.trim());
    }

    private static String resolveRelatedKey(String rawField) {
        String key = normalizeKey(rawField);
        if (key == 'dmt_warranty.g_limits_grid_guarantee_type' || key == 'g_limits_grid_guarantee_type') {
            return WARRANTY_FIELD_KEY;
        }
        if (key == 'dmt_currency_provision.g_currency_id' || key == 'g_currency_id') {
            return CURRENCY_PROVISION_FIELD_KEY;
        }
        return null;
    }

    private static String resolveSpecialKey(String rawField) {
        Map<String, String> aliases = new Map<String, String>{
            'dmt_product' => 'productName',
            'global_product' => 'productName',
            'productname' => 'productName',
            'parent_product_id' => 'parentProductId',
            'familyproduct' => 'familyProduct',
            'global_product_family' => 'familyProduct',
            'subfamilyproduct' => 'subfamilyProduct',
            'global_product_subfamily' => 'subfamilyProduct',
            'categoryproduct' => 'categoryProduct',
            'global_product_category' => 'categoryProduct',
            'subcategoryproduct' => 'subcategoryProduct',
            'global_product_subcategory' => 'subcategoryProduct',
            'g_limit_sinds_ast_sctr_id' => 'taxonomyC162',
            'assetallocationsector' => 'taxonomyC162',
            'g_limit_sinds_ast_subsec_id' => 'taxonomyC164',
            'assetallocationsubsector' => 'taxonomyC164',
            'g_branch_id' => 'taxonomyH007',
            'bookinggeo' => 'taxonomyH007',
            'bookinggeography' => 'taxonomyH007',
            'g_amortization_type' => 'taxonomyALAT',
            'g_amortization_type_c' => 'taxonomyALAT',
            'dmt_amortization_type' => 'taxonomyALAT',
            'amortizationtype' => 'taxonomyALAT'
        };
        String key = normalizeKey(rawField);
        return aliases.containsKey(key) ? aliases.get(key) : null;
    }

    private static Map<String, String> buildFieldLookup(Map<String, Schema.SObjectField> fieldMap) {
        Map<String, String> lookup = new Map<String, String>();
        for (String fieldApi : fieldMap.keySet()) {
            lookup.put(fieldApi.toLowerCase(), fieldApi);
            lookup.put(normalizeKey(fieldApi), fieldApi);
            if (fieldApi.endsWith('__c')) {
                lookup.put(normalizeKey(fieldApi.substring(0, fieldApi.length() - 3)), fieldApi);
            }
        }
        return lookup;
    }

    private static String resolveFieldApiName(String rawField, Map<String, Schema.SObjectField> fieldMap, Map<String, String> lookup) {
        if (String.isBlank(rawField)) {
            return null;
        }

        String candidate = rawField.trim();
        if (candidate.contains('.')) {
            List<String> parts = candidate.split('\\.');
            candidate = parts[parts.size() - 1];
        }

        Map<String, String> knownFieldKeyAliases = new Map<String, String>{
            'amount' => 'DMT_Amount__c',
            'currency' => 'CurrencyIsoCode',
            'currencyisocode' => 'CurrencyIsoCode',
            'initterm' => 'DMT_Init_Term__c',
            'inittermlabel' => 'DMT_Init_Term__c',
            'initialterm' => 'DMT_Init_Term__c',
            'endterm' => 'DMT_End_Term__c',
            'endtermlabel' => 'DMT_End_Term__c',
            'maximumterm' => 'DMT_End_Term__c',
            'comments' => 'DMT_Comments__c'
        };
        String normalized = normalizeKey(candidate);
        if (knownFieldKeyAliases.containsKey(normalized) && fieldMap.containsKey(knownFieldKeyAliases.get(normalized))) {
            return knownFieldKeyAliases.get(normalized);
        }

        if (fieldMap.containsKey(candidate)) {
            return candidate;
        }
        if (lookup.containsKey(candidate.toLowerCase())) {
            return lookup.get(candidate.toLowerCase());
        }
        if (lookup.containsKey(normalized)) {
            return lookup.get(normalized);
        }
        if (normalized.endsWith('_c') && lookup.containsKey(normalized.substring(0, normalized.length() - 2))) {
            return lookup.get(normalized.substring(0, normalized.length() - 2));
        }
        return null;
    }

    private static Boolean isHiddenByVisibilityRule(DMT_ViewController.LineDataWrapper data, DMT_Risk_Line_Term__c riskLine, String rule) {
        if (String.isBlank(rule)) {
            return false;
        }

        for (String orGroup : rule.trim().split('\\s*\\|\\|\\s*')) {
            Boolean groupMatches = true;
            for (String condition : orGroup.split('\\s*&&\\s*')) {
                if (!evaluateVisibilityCondition(data, riskLine, condition)) {
                    groupMatches = false;
                    break;
                }
            }
            if (groupMatches) {
                return true;
            }
        }
        return false;
    }

    private static Boolean evaluateVisibilityCondition(DMT_ViewController.LineDataWrapper data, DMT_Risk_Line_Term__c riskLine, String conditionRaw) {
        String condition = String.isBlank(conditionRaw) ? '' : conditionRaw.trim();
        if (String.isBlank(condition)) {
            return false;
        }

        String lowerCondition = condition.toLowerCase();
        Integer notInIndex = lowerCondition.indexOf(' not in ');
        Integer inIndex = lowerCondition.indexOf(' in ');
        if (notInIndex > 0 || inIndex > 0) {
            Boolean isNotIn = notInIndex > 0;
            Integer operatorIndex = isNotIn ? notInIndex : inIndex;
            String leftField = condition.substring(0, operatorIndex).trim();
            String rightRaw = condition.substring(operatorIndex + (isNotIn ? 8 : 4)).trim();
            String leftValue = normalizeLiteral(resolveConditionValue(data, riskLine, leftField));
            Set<String> values = parseListLiteral(rightRaw);
            Boolean containsValue = values.contains(leftValue);
            return isNotIn ? !containsValue : containsValue;
        }

        List<String> operators = new List<String>{'>=', '<=', '==', '!=', '>', '<'};
        for (String operator : operators) {
            Integer operatorIndex = condition.indexOf(operator);
            if (operatorIndex <= 0) {
                continue;
            }

            String leftField = condition.substring(0, operatorIndex).trim();
            String rightRaw = condition.substring(operatorIndex + operator.length()).trim();
            Object leftRawValue = resolveConditionValue(data, riskLine, leftField);
            Object rightRawValue = parseLiteral(rightRaw);

            if (operator == '>' || operator == '>=' || operator == '<' || operator == '<=') {
                Decimal leftNumber = toDecimal(leftRawValue);
                Decimal rightNumber = toDecimal(rightRawValue);
                if (leftNumber == null || rightNumber == null) {
                    return false;
                }
                if (operator == '>') {
                    return leftNumber > rightNumber;
                }
                if (operator == '>=') {
                    return leftNumber >= rightNumber;
                }
                if (operator == '<') {
                    return leftNumber < rightNumber;
                }
                return leftNumber <= rightNumber;
            }

            String leftValue = normalizeLiteral(leftRawValue);
            String rightValue = normalizeLiteral(rightRawValue);
            return operator == '==' ? leftValue == rightValue : leftValue != rightValue;
        }

        return false;
    }

    private static Object resolveConditionValue(DMT_ViewController.LineDataWrapper data, DMT_Risk_Line_Term__c riskLine, String fieldName) {
        if (String.isBlank(fieldName)) {
            return null;
        }

        String normalized = fieldName.trim();
        if (normalized.contains('.')) {
            List<String> parts = normalized.split('\\.');
            normalized = parts[parts.size() - 1];
        }

        Map<String, Schema.SObjectField> riskFields = DMT_Risk_Line_Term__c.SObjectType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> lineFields = DMT_Line__c.SObjectType.getDescribe().fields.getMap();
        String riskField = resolveFieldApiName(normalized, riskFields, buildFieldLookup(riskFields));
        if (riskField != null) {
            return getSObjectValue(riskLine, riskField);
        }

        String lineField = resolveFieldApiName(normalized, lineFields, buildFieldLookup(lineFields));
        if (lineField != null) {
            return getSObjectValue(data == null ? null : data.line, lineField);
        }

        RenderConfig specialConfig = new RenderConfig();
        specialConfig.fieldKey = resolveSpecialKey(normalized);
        specialConfig.sourceObject = 'special';
        return specialConfig.fieldKey == null ? null : resolveValue(data, riskLine, specialConfig);
    }

    private static Set<String> parseListLiteral(String rawValue) {
        Set<String> values = new Set<String>();
        String normalized = String.isBlank(rawValue) ? '' : rawValue.trim();
        if (normalized.startsWith('[') && normalized.endsWith(']')) {
            normalized = normalized.substring(1, normalized.length() - 1);
        }
        for (String item : normalized.split(',')) {
            values.add(normalizeLiteral(parseLiteral(item)));
        }
        return values;
    }

    private static Object parseLiteral(String rawValue) {
        if (rawValue == null) {
            return null;
        }
        String value = rawValue.trim();
        if ((value.startsWith('\'') && value.endsWith('\'')) || (value.startsWith('"') && value.endsWith('"'))) {
            return value.substring(1, value.length() - 1);
        }
        if (value == '$Vlocity.NULL' || value == '{emptyString}' || value == 'emptyString') {
            return '';
        }
        if (value.equalsIgnoreCase('null')) {
            return null;
        }
        if (value.equalsIgnoreCase('true')) {
            return true;
        }
        if (value.equalsIgnoreCase('false')) {
            return false;
        }
        return value;
    }

    private static String normalizeLiteral(Object value) {
        if (value == null) {
            return '';
        }
        String normalized = String.valueOf(value).trim();
        if (normalized == '$Vlocity.NULL' || normalized == '{emptyString}' || normalized == 'emptyString') {
            return '';
        }
        return normalized;
    }

    private static Decimal toDecimal(Object value) {
        if (value == null || String.isBlank(String.valueOf(value))) {
            return null;
        }
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception ignored) {
            return null;
        }
    }

    private static Set<String> extractRuleFieldNames(String rule) {
        Set<String> fieldNames = new Set<String>();
        if (String.isBlank(rule)) {
            return fieldNames;
        }

        for (String orGroup : rule.split('\\s*\\|\\|\\s*')) {
            for (String condition : orGroup.split('\\s*&&\\s*')) {
                String trimmed = String.isBlank(condition) ? '' : condition.trim();
                if (String.isBlank(trimmed)) {
                    continue;
                }
                String lower = trimmed.toLowerCase();
                Integer endIndex = lower.indexOf(' not in ');
                if (endIndex < 0) {
                    endIndex = lower.indexOf(' in ');
                }
                if (endIndex < 0) {
                    for (String operator : new List<String>{'>=', '<=', '==', '!=', '>', '<'}) {
                        Integer operatorIndex = trimmed.indexOf(operator);
                        if (operatorIndex > 0) {
                            endIndex = operatorIndex;
                            break;
                        }
                    }
                }
                if (endIndex > 0) {
                    fieldNames.add(trimmed.substring(0, endIndex).trim());
                }
            }
        }
        return fieldNames;
    }

    private static Object resolveConfiguredLabel(DMT_LineOtherTemplateConfig__mdt metadata, Object rawValue) {
        if (rawValue == null || String.isBlank(String.valueOf(rawValue))) {
            return rawValue;
        }

        String rawString = String.valueOf(rawValue);
        String label = resolveLabelFromOptionsJson(metadata.OptionsJson__c, rawString);
        if (!String.isBlank(label)) {
            return label;
        }

        label = resolveLabelFromTaxonomy(metadata.TaxonomyCatalog__c, rawString);
        return String.isBlank(label) ? rawValue : label;
    }

    private static String resolveLabelFromOptionsJson(String optionsJson, String rawValue) {
        if (String.isBlank(optionsJson) || String.isBlank(rawValue)) {
            return null;
        }
        try {
            Object parsed = JSON.deserializeUntyped(optionsJson);
            Map<String, String> labelsByValue = new Map<String, String>();
            collectOptionLabels(parsed, labelsByValue);
            return labelsByValue.get(rawValue);
        } catch (Exception ignored) {
            return null;
        }
    }

    private static void collectOptionLabels(Object node, Map<String, String> labelsByValue) {
        if (node instanceof List<Object>) {
            for (Object item : (List<Object>) node) {
                collectOptionLabels(item, labelsByValue);
            }
            return;
        }

        if (node instanceof Map<String, Object>) {
            Map<String, Object> nodeMap = (Map<String, Object>) node;
            if (nodeMap.containsKey('value') || nodeMap.containsKey('label')) {
                String value = nodeMap.containsKey('value') && nodeMap.get('value') != null
                    ? String.valueOf(nodeMap.get('value'))
                    : String.valueOf(nodeMap.get('label'));
                String label = nodeMap.containsKey('label') && nodeMap.get('label') != null
                    ? String.valueOf(nodeMap.get('label'))
                    : value;
                labelsByValue.put(value, label);
            }

            for (String key : nodeMap.keySet()) {
                Object value = nodeMap.get(key);
                if (value instanceof String || value instanceof Boolean || value instanceof Decimal || value instanceof Integer) {
                    labelsByValue.put(key, String.valueOf(value));
                } else {
                    collectOptionLabels(value, labelsByValue);
                }
            }
        }
    }

    private static String resolveLabelFromTaxonomy(String catalogId, String rawValue) {
        if (String.isBlank(catalogId) || String.isBlank(rawValue)) {
            return null;
        }
        if (!taxonomyLabelsByCatalog.containsKey(catalogId)) {
            taxonomyLabelsByCatalog.put(catalogId, buildTaxonomyLabelMap(catalogId));
        }
        return taxonomyLabelsByCatalog.get(catalogId).get(rawValue);
    }

    private static Map<String, String> buildTaxonomyLabelMap(String catalogId) {
        Map<String, String> labelsByValue = new Map<String, String>();
        Date todayDate = Date.today();
        Map<String, Integer> distanceByValue = new Map<String, Integer>();

        for (DMT_Taxonomy_Values__c taxonomyValue : [
            SELECT DMT_Name__c, DMT_Name_EN__c, DMT_Value__c, DMT_Cutoff_Date__c, CreatedDate,
                   gf_catalog_atrb_val1_name_c__c, gf_catalog_atrb_val4_name__c
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c = :catalogId
        ]) {
            String value = resolveTaxonomyOptionValue(taxonomyValue);
            if (String.isBlank(value)) {
                continue;
            }
            String label = String.isNotBlank(taxonomyValue.DMT_Name_EN__c) ? taxonomyValue.DMT_Name_EN__c : taxonomyValue.DMT_Name__c;
            Integer distance = distanceToToday(taxonomyValue.DMT_Cutoff_Date__c, todayDate);
            if (!labelsByValue.containsKey(value) || distance < distanceByValue.get(value)) {
                labelsByValue.put(value, label);
                distanceByValue.put(value, distance);
            }
            if (!String.isBlank(taxonomyValue.DMT_Value__c) && !labelsByValue.containsKey(taxonomyValue.DMT_Value__c)) {
                labelsByValue.put(taxonomyValue.DMT_Value__c, label);
            }
        }
        return labelsByValue;
    }

    private static String resolveTaxonomyOptionValue(DMT_Taxonomy_Values__c record) {
        String typeValue = record == null ? null : record.gf_catalog_atrb_val4_name__c;
        String categoryCode = record == null ? null : record.gf_catalog_atrb_val1_name_c__c;
        if (typeValue == 'Category' && String.isNotBlank(categoryCode)) {
            return categoryCode;
        }
        return record == null ? null : record.DMT_Value__c;
    }

    private static Integer distanceToToday(Date targetDate, Date todayDate) {
        if (targetDate == null) {
            return 2147483647;
        }
        return Math.abs(todayDate.daysBetween(targetDate));
    }

    private static Object getSObjectValue(SObject record, String fieldApi) {
        if (record == null || String.isBlank(fieldApi)) {
            return null;
        }
        try {
            return record.get(fieldApi);
        } catch (Exception ignored) {
            return null;
        }
    }

    private static String normalizeKey(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        String result = value.trim().toLowerCase();
        if (result.contains('.')) {
            List<String> parts = result.split('\\.');
            result = parts[parts.size() - 1];
        }
        result = result.replace('__c', '');
        result = result.replaceAll('[^a-z0-9_]', '');
        return result;
    }
}