/**
 * CIBGLOBALD-4117: Implement this on a renderer whose displayed fields should be watched by the
 * approval-restart mechanism: when a watched field changes and a Line/Opportunity is resubmitted,
 * its open approval tasks are cancelled and recreated so the approver reviews the new value.
 *
 * Return the field API names exactly as they'd be read off the record being watched - a
 * relationship path like 'Client__r.Name' is fine. Derive the list from the same method that
 * builds the renderer's displayed fields, never a hand-typed duplicate, so the two cannot drift
 * apart.
 *
 * If the renderer reads anything beyond the record's own fields - any child object at all -
 * implement DMT_MultiObjectFieldTrackableRenderer instead of this interface. That one also
 * requires declaring a ChildSection per child object; skipping it is a silent no-op, not an error -
 * the field can be listed as tracked and still never actually get compared.
 *
 * Once a component's renderer implements this, DMT_RendererFactory.getTrackedComponentNames()
 * picks it up automatically - nothing else to register. See DMT_InfoRenderer/DMT_ClientRenderer for
 * the maintenance rules each component family follows.
 */
public interface DMT_FieldTrackableRenderer {
    List<String> getTrackedFields(SObject record);
}