public class DMT_Passport_CalloutQueueable implements Queueable, Database.AllowsCallouts {
    private Id recordId;
    private Id clientId;
    
    public DMT_Passport_CalloutQueueable(Id recordId, Id clientId) {
        this.recordId = recordId;
        this.clientId = clientId;
    }
    
    public void execute(QueueableContext context) {
        // Paso 1: Hacer el callout
        String result = makeCallout();
        
        // Paso 2: Procesar el resultado (sin más async calls)
        processResult(result);
        
        // Paso 3: Si necesitas más procesamiento, debe ser síncrono
        //updateRecord();
    }
    
    private String makeCallout() {
        // Tu lógica de callout aquí
        String lastDate = DMT_HPG_Utils.lastDate();
        List<String> countries = new List<String> {'All'};
        DMT_HPG_GlobalPosition.Wrapper wrapper = new DMT_HPG_GlobalPosition.Wrapper();
        if(!Test.isRunningTest()) {
            Object res = DMT_HPG_MainTableCustomController.fetchData('passport', this.clientId, countries, lastDate,'Y/N', '1', '5000', String.valueOf(this.clientId));
            wrapper = (DMT_HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), DMT_HPG_GlobalPosition.Wrapper.class);
        } 
        return JSON.serialize(wrapper.data);
    }
    
    private void processResult(String jsonResult) {
        // Procesamiento síncrono del resultado
        DMT_Passport_Handler.buttonCallPassport(this.recordId, jsonResult);
    }

}