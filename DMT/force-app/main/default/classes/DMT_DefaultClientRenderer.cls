// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
public without sharing class DMT_DefaultClientRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_CalloutTrackableRenderer {

    // CIBGLOBALD-4117: ADD OR REMOVE A SELECTED CLIENT COLUMN HERE. This one list drives both the rendered table
    // columns and the fields the approval-restart mechanism watches - see DMT_ClientRenderer.
    // In display order, after CLIENT NAME and MAIN HOLDER, which are handled separately (MAIN
    // HOLDER is a computed Yes/No, not a queryable field).
    private static final List<String> CLIENT_TABLE_COLUMN_FIELDS = new List<String>{
        'DMT_ClientStarCode__c', 'Alpha_Code_Client__c', 'DMT_Amount__c', 'DMT_Term__c',
        'DMT_FDAmount__c', 'DMT_DVPAmount__c', 'DMT_ClientContracts__c', 'DMT_ClientRating__c'
    };

    // Header fields. Feeds both renderHtml() and getTrackedFields(), so pass the field API name as
    // the third DisplayField argument or the field will render without being watched.
    // getTrackedFields() calls this with an empty wrapper for the field names alone, so Client__r
    // is null then - hence the safe navigation.
    private List<DMT_FormattingUtils.DisplayField> buildLineFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Client:', DMT_FormattingUtils.checkNull(data.line.Client__r?.Name), new List<String>{'Client__r.Name'}),
            new DMT_FormattingUtils.DisplayField('Client Type:', DMT_FormattingUtils.checkNull(data.line.Client_Type__c), new List<String>{'Client_Type__c'})
        };
    }

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        Set<String> fields = new Set<String>();
        for (DMT_FormattingUtils.DisplayField df : buildLineFields(new DMT_ViewController.LineDataWrapper())) {
            if (df.fieldApiNames != null) {
                fields.addAll(df.fieldApiNames);
            }
        }
        // CIBGLOBALD-4117 - not displayed directly, but each decides which CLIENT layout branch
        // renders or which computed value appears (see DMT_ViewController's population of
        // isSubsidiary/ratingMonoHolder/mainHolderCustomerId) - same treatment as
        // Booking_Geography__c in DMT_TreasuryProductsRenderer.
        fields.add('Custom_Association__c');
        fields.add('Custom_Association__r.g_customer_id__c');
        fields.add('Client__r.g_customer_id__c');
        return new List<String>(fields);
    }

    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        Set<String> customAssociationClientFields = new Set<String>{ 'Name' };
        customAssociationClientFields.addAll(CLIENT_TABLE_COLUMN_FIELDS);
        return new Map<String, List<String>>{
            'DMT_Line__c' => getTrackedFields(record),
            'Custom_Association_Client__c' => new List<String>(customAssociationClientFields)
        };
    }

    // The SELECTED CLIENT rows hang off DMT_Line__c.Custom_Association__c, not off the Line
    // itself - hence parentValueField is that lookup rather than 'Id'.
    // CIBGLOBALD-4117 - ChildSection(componentName, snapshotSectionKey, childObjectApiName,
    // childLookupField, parentValueField[, orderBy]):
    //   componentName       - this component's display name, matching its DMT_Items__c row;
    //                         shows up in logs/labels, not used for lookups.
    //   snapshotSectionKey  - the key this section's rows are stored under in the frozen JSON
    //                         snapshot. Shared across every component that reads the same child
    //                         object under the same key - fields from all of them get queried and
    //                         compared together, so add/remove fields on the OBJECT's
    //                         getTrackedFieldsByObject() map, never invent a new key for one field.
    //   childObjectApiName  - the SObject to query for this section's rows. Must match a key in
    //                         this renderer's own getTrackedFieldsByObject() map, or nothing gets
    //                         queried/compared for it.
    //   childLookupField    - the field ON childObjectApiName that points back to the parent record.
    //   parentValueField    - the field ON THE PARENT (Opportunity/Line) whose value is matched
    //                         against childLookupField - almost always 'Id'; a different value here
    //                         means an extra hop (see Custom_Association_Client__c's hand-written
    //                         special case in DMT_ApprovalChangeStep_Handler for why that one isn't
    //                         generic).
    //   orderBy (optional)  - ORDER BY clause for the child query, when row order matters for the
    //                         comparison.
    public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>{
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Client', 'customAssociationClientList', 'Custom_Association_Client__c',
                'Custom_Association__c', 'Custom_Association__c'
            )
        };
    }

    // CIBGLOBALD-4117 - ratingMonoHolder (HPG MonoHolder service) is never written to any Salesforce
    // field. record is only guaranteed to carry its Id here (async context) - re-query everything needed.
    public String getCalloutCacheKey(SObject record) {
        DMT_Line__c line = [SELECT Id, Client__r.g_customer_id__c FROM DMT_Line__c WHERE Id = :record.Id];
        return line.Client__r?.g_customer_id__c;
    }

    public Map<String, Object> fetchLiveTrackedValues(SObject record) {
        Map<String, Object> values = new Map<String, Object>();
        DMT_Line__c line = [SELECT Id, Client__c, Client__r.g_customer_id__c FROM DMT_Line__c WHERE Id = :record.Id];
        if (line.Client__c == null || line.Client__r?.g_customer_id__c == null) {
            return values;
        }
        DMT_ViewController.MonoHolderDataWrapper monoHolderData =
            DMT_ViewController.getMonoHolderDataFromService(line.Client__c, line.Client__r.g_customer_id__c);
        values.put('ratingMonoHolder', monoHolderData.ratingMonoHolder);
        return values;
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if(data.line.getPopulatedFieldsAsMap().isEmpty() || data.line.Client__c == null){
            return '<div>Client data not provided</div>';
        }
        try {
            List<DMT_FormattingUtils.DisplayField> lineFields = buildLineFields(data);
            String clientName = lineFields[0].value;
            String clientType = lineFields[1].value;

            String table;
            if(!data.isSubsidiary){
                table = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">CLIENT</h2>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr data-dmt-row="field">'
                + '<td data-dmt-pair="1" data-dmt-label="Client:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Client:</strong></td>'
                + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + clientName + '</td>'
                + '<td data-dmt-pair="2" data-dmt-label="Client Type:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Client Type:</strong></td>'
                + '<td data-dmt-pair="2" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + clientType + '</td>'
                + '</tr>'
                + '</table>'
                + '</div>'
                + '&nbsp;</br>';
            }else{
                String initialRating = '';
                for (Custom_Association_Client__c client : data.customAssociationClientList) {
                    initialRating = (String)client.DMT_ClientRating__c;
                }
                table = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">CLIENT</h2>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr data-dmt-row="field">'
                + '<td data-dmt-pair="1" data-dmt-label="Client:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Client:</strong></td>'
                + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + clientName + '</td>'
                + '<td data-dmt-pair="2" data-dmt-label="Client Type:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Client Type:</strong></td>'
                + '<td data-dmt-pair="2" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + clientType + '</td>'
                + '<td data-dmt-pair="3" data-dmt-label="INTERNAL RATING (SHORT):" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>INTERNAL RATING (SHORT):</strong></td>'
                + '<td data-dmt-pair="3" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.ratingMonoHolder) + '</td>'
                + '</tr>'
                + '</table>'
                + '</div>'
                + '&nbsp;</br>';
            }

            String table2 = '';
            if (!data.customAssociationClientList.isEmpty()) {
                table2 = '<div>'
                    + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr data-dmt-table-title="true">'
                    + '<td colspan="10" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>SELECTED CLIENT</strong></td>'
                    + '</tr>'
                    + '<tr data-dmt-table-header="true">'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>CLIENT NAME</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>MAIN HOLDER</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>STAR CODE</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>CUSTOMER ID</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DERIVATIVES AMOUNT</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>TERM</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FD AMOUNT</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DVP AMOUNT</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>CLIENT CONTRACTS</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>INTERNAL RATING (SHORT)</strong></td>'
                    + '</tr>';
                for (Custom_Association_Client__c client : data.customAssociationClientList) {
                    String isMainHolder = (client.Alpha_Code_Client__c == data.mainHolderCustomerId) ? 'Yes' : 'No';
                    table2 += '<tr data-dmt-table-row="true">'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.Name) + '</td>'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + isMainHolder + '</td>';
                    for (String fieldName : CLIENT_TABLE_COLUMN_FIELDS) {
                        table2 += '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.get(fieldName)) + '</td>';
                    }
                    table2 += '</tr>';
                }
                table2 += '</table></div>&nbsp;</br>';
            }
            return table + table2;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultClientRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}