/**
 * CIBGLOBALD-4117: Implement this on a renderer whose displayed fields span more than one SObject - for example
 * Client, which shows fields from DMT_Line__c and from its Custom_Association_Client__c rows.
 * For a single-object renderer, implement DMT_FieldTrackableRenderer instead.
 *
 * A renderer declares both halves of its own contract, and BOTH are required for a child object's
 * fields to actually be watched:
 *   getTrackedFieldsByObject() - WHICH fields, grouped by SObject
 *   getChildSections()         - WHERE the child rows live and how to reach them
 *
 * Listing a child object's fields in getTrackedFieldsByObject() without also declaring a matching
 * ChildSection for it in getChildSections() is a silent no-op: the field compiles, looks tracked,
 * and passes a unit test that only checks these two methods' return values, but the watch gate
 * (DMT_SnapshotChildComparator) has no section to compare that object's rows under, so the field is
 * never actually frozen or checked at restart time. When adding a child object's fields, always add
 * or reuse its ChildSection in the same change.
 *
 * Both live on the renderer rather than in any central registry, so a dev adding a displayed field
 * edits one file. See DMT_ClientRenderer for the maintenance rules.
 *
 * Fields are grouped by object rather than returned as one qualified list because a dot is
 * ambiguous: 'Client__r.Name' is a relationship traversal, 'Custom_Association_Client__c.Name' is
 * an object qualifier, and they cannot be told apart by parsing.
 */
public interface DMT_MultiObjectFieldTrackableRenderer {
    Map<String, List<String>> getTrackedFieldsByObject(SObject record);

    // Return an empty list when the renderer reads no child records.
    List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record);
}