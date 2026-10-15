// CIBGLOBALD-4374 - Marker for async payloads whose dispatch can make an HTTP callout.
//
// A managed package's post-callout DML (for example the IASO application log) makes a second
// callout in the same transaction throw 'You have uncommitted work pending'. DMT_AsyncQueueJob and
// DMT_AsyncBatchJob dispatch at most ONE DMT_CalloutPayload per transaction and hand the others back
// to DMT_AsyncOrchestrator, so each one gets its own transaction. The marker goes on the (small)
// payload class, never on the large service classes that happen to contain a callout.
public interface DMT_CalloutPayload extends DMT_AsyncPayload {
}
