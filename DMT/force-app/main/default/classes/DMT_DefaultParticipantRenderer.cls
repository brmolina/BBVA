// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
//
// CIBGLOBALD-4117: shared between two record types (Sanction Lines and DMT_Opportunity) with two
// different lookup fields back to the parent (DMT_TeamMember__c.Line__c vs .Opportunity__c) - the
// only place in this renderer that needs to know which one it's rendering for.
public without sharing class DMT_DefaultParticipantRenderer implements DMT_ViewRenderer, DMT_MultiObjectFieldTrackableRenderer {
    private static final Set<String> TEAM_MEMBER_FIELDS = new Set<String>{ 'Full_Name_User__c', 'AccessLevel__c' };

    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'DMT_TeamMember__c' => new List<String>(TEAM_MEMBER_FIELDS)
        };
    }

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
        String lookupField = record.getSObjectType() == Opportunity.SObjectType ? 'Opportunity__c' : 'Line__c';
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>{
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Participants', 'participantList', 'DMT_TeamMember__c', lookupField, 'Id', 'Full_Name_User__c ASC'
            )
        };
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.participantList.isEmpty()) {
            return '<div>Participants data not provided</div>';
        }
        try {
            String table = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Participants</h2>'
                + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr data-dmt-table-title="true">'
                + '<td colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Participant Selection</strong></td>'
                + '</tr>'
                + '<tr data-dmt-table-header="true">'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Participant</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Access Level</strong></td>'
                + '</tr>';
            for (DMT_TeamMember__c participant : data.participantList) {
                table += '<tr data-dmt-table-row="true">'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(participant?.Full_Name_User__c) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(participant?.AccessLevel__c) + '</td>'
                    + '</tr>';
            }
            table += '</table></div></br></br>';
            return table;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultParticipantRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}