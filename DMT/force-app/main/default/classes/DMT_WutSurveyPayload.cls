/**
 * @description Async payload carrying the parameters for a WUT survey Platform Event publish,
 *              dispatched via DMT_AsyncOrchestrator/DMT_AsyncDispatcher like other async work in this
 *              trigger, so it shares the same "one Queueable per transaction" budget instead of
 *              competing with it.
 */
public class DMT_WutSurveyPayload implements DMT_AsyncPayload {
    public String survey;
    public String moduleName;
    public String userIds;

    public DMT_WutSurveyPayload(String survey, String moduleName, String userIds) {
        this.survey = survey;
        this.moduleName = moduleName;
        this.userIds = userIds;
    }
}