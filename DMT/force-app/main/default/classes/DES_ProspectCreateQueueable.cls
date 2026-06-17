/**
 * @description Queueable job that calls the remote prospect-creation service for a
 *              single prospect Account per execution, chaining itself for any remaining
 *              records.
 *
 *              WHY ONE RECORD PER JOB:
 *              iaso.GBL_Integration_GenericService.invoke enqueues an internal @Future
 *              (audit logging) immediately after completing each HTTP callout. Salesforce
 *              treats a pending @Future as uncommitted work, causing any subsequent callout
 *              in the same transaction to fail with:
 *                  "You have uncommitted work pending. Please commit or rollback
 *                   before calling out."
 *              This makes it impossible to process more than one record per transaction.
 *
 *              WHY NOT DELEGATE TO @Future:
 *              The natural workaround — delegating each callout to a separate @Future via
 *              DES_Arc_ProspectController.futureCreateProspect — is also blocked: iaso
 *              calls @Future internally, and Salesforce prohibits calling @Future from
 *              within a @Future context (AsyncException: Future method cannot be called
 *              from a future or batch method).
 *
 *              RESULTING ARCHITECTURE:
 *              Each Queueable execution processes exactly one record in a fresh transaction,
 *              then chains to a new Queueable for the remaining records. This guarantees:
 *              - One callout per transaction → no "uncommitted work" error.
 *              - iaso's internal @Future runs cleanly (allowed from Queueable context).
 *              - Each record fails or succeeds independently without affecting others.
 *              At any point only one job is in Holding in the Flex Queue, so the
 *              org-wide 100-job Holding limit is never at risk from this chain.
 *
 * @author      Borja Lorenzo Adajas
 * @date        2026-05-19
 */
public with sharing class DES_ProspectCreateQueueable implements Queueable, Database.AllowsCallouts {

    // ──────────────────────────────────────────────────────────────────────────
    // Constants
    // ──────────────────────────────────────────────────────────────────────────

    // 1 record per execution: iaso.invoke enqueues an internal @Future after each callout,
    // blocking any subsequent callout in the same transaction. One callout per Queueable
    // transaction is the only architecture that avoids this constraint.
    @TestVisible
    private static final Integer BATCH_SIZE = 1;

    // ──────────────────────────────────────────────────────────────────────────
    // State
    // ──────────────────────────────────────────────────────────────────────────

    private final List<DES_Arc_ProspectController.WrapperService> wraps;

    // ──────────────────────────────────────────────────────────────────────────
    // Constructor
    // ──────────────────────────────────────────────────────────────────────────

    public DES_ProspectCreateQueueable(List<DES_Arc_ProspectController.WrapperService> wraps) {
        this.wraps = wraps;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Execute
    // ──────────────────────────────────────────────────────────────────────────

    public void execute(QueueableContext context) {
        if (wraps.isEmpty()) {
            return;
        }

        // One callout per transaction: iaso.invoke enqueues an internal @Future after
        // each callout, which blocks any subsequent callout in the same transaction.
        final DES_Arc_ProspectController.WrapperService wrap = wraps.get(0);
        
        if(wrap.pros.DES_Prospect_status__c != Label.Prospect_created) {
            DES_Arc_ProspectController.callCreateProspect(wrap.pros, wrap.toUpdate);
        }

        // Chain to next job if there are remaining records.
        if (wraps.size() > 1) {
            final List<DES_Arc_ProspectController.WrapperService> remaining =
                new List<DES_Arc_ProspectController.WrapperService>();
            for (Integer i = 1; i < wraps.size(); i++) {
                remaining.add(wraps.get(i));
            }
            // Guard against test context: chaining from within a synchronously-executed
            // Queueable causes AsyncException: Maximum stack depth has been reached.
            if (!Test.isRunningTest()) {
                try {
                    System.enqueueJob(new DES_ProspectCreateQueueable(remaining));
                } catch (Exception e) {
                    // The Flex Queue is full (100-job Holding limit). Log and surface so
                    // the remaining records can be reprocessed manually or via monitoring.
                    System.debug(LoggingLevel.ERROR,
                        '[DES_ProspectCreateQueueable] Failed to enqueue chained job.'
                        + ' remaining=' + remaining.size()
                        + ' | error=' + e.getMessage()
                    );
                }
            }
        }
    }
}