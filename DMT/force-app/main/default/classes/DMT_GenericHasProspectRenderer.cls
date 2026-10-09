public without sharing class DMT_GenericHasProspectRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        String objectType = data.objectApiName == 'Opportunity' ? 'Opportunity' : 'Line';

        if(data.hasProspect) {
            return '<div>This ' + objectType + ' is associated to a PROSPECT</div><br>';
        } else {
            return '<div></div>';
        }
    }
}