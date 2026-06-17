/**
 * @description Payload para ejecutar de forma asíncrona el mapeo dinámico de campos
 * desde Custom Metadata y llamar a la integración correspondiente.
 * Se encola a través de DMT_AsyncOrchestrator cuando una Opportunity de tipo DMT_Opportunity
 * transiciona a un estado de cierre.
 */
public class DMT_DynamicMapperPayload implements DMT_AsyncPayload {

    public String opportunityId { get; set; }
    public String metadataName  { get; set; }
    public String stageName     { get; set; }

    public DMT_DynamicMapperPayload(String opportunityId, String metadataName, String stageName) {
        this.opportunityId = opportunityId;
        this.metadataName  = metadataName;
        this.stageName     = stageName;
    }
}