/**
 * CIBGLOBALD-4117 - implement this on a renderer whose displayed data is sourced from a live
 * external service callout rather than a persisted Salesforce field, so it can still be watched by
 * the approval-restart mechanism.
 *
 * Callouts are illegal from trigger context, so this is never invoked from the synchronous watch
 * gate directly - DMT_ApprovalChangeStep_Helper only enqueues the check (DMT_AsyncOrchestrator /
 * DMT_AsyncBatchJob, which allows callouts) once the cheap, synchronous SObject-field comparison
 * (DMT_FieldTrackableRenderer / DMT_MultiObjectFieldTrackableRenderer) already ran and found no
 * change - local-first, callout as fallback.
 *
 * The record passed to both methods is only guaranteed to carry its Id - it may come from either
 * an in-memory trigger record or a freshly-constructed shell in an async job with nothing else
 * loaded. Fetch anything else you need with your own Id-based query.
 */
public interface DMT_CalloutTrackableRenderer {
    // Cache key for de-duplicating the underlying call across renderers/components that hit the
    // same external service for the same scope (e.g. the callout's own customerId) - not the
    // renderer's own name, so two renderers sharing one call collide on purpose.
    String getCalloutCacheKey(SObject record);

    // Performs the live fetch. Returns values keyed exactly like the frozen snapshot's
    // calloutTrackedValues section, so comparison is a generic map-diff with no per-renderer
    // special-casing.
    Map<String, Object> fetchLiveTrackedValues(SObject record);
}