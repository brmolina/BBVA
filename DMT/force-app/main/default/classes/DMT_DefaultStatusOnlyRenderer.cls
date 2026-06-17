public with sharing class DMT_DefaultStatusOnlyRenderer implements DMT_ViewRenderer {

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            return '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">STATUS</h2>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Status:</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.statusLineOrOpp) + '</td>'
                + '</tr>'
                + '</table>'
                + '</div>'
                + '&nbsp;</br>';
        } catch (Exception e) {
            System.debug('Error in DMT_DefaultStatusOnlyRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            List<Object> contentList = new List<Object>();
            contentList.add(DMT_Create_Pdf_Controller.createTitle('STATUS'));

            List<String> names = new List<String>{ 'Status:' };
            List<String> values = new List<String>{ DMT_FormattingUtils.checkNull(data.statusLineOrOpp) };
            contentList.add(DMT_Create_Pdf_Controller.createListText(names, values, ''));

            Map<String, Object> component = new Map<String, Object>();
            component.put('content', contentList);
            component.put('name', 'STATUS');
            return component;
        } catch (Exception e) {
            System.debug('Error in DMT_DefaultStatusOnlyRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_DefaultStatusOnlyRenderer', 'renderPdfJson', 'DMT', ''));
            return new Map<String, Object>();
        }
    }
}