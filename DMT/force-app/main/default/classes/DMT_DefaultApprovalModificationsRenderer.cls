public with sharing class DMT_DefaultApprovalModificationsRenderer implements DMT_ViewRenderer {

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.closedWonVersions?.isEmpty()) {
            return '<div>There are no versions with post-approval modifications.</div>'; 
        }
        try {
            String table = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Post-Approval Management</h2>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                + '<td colspan="8" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong> Change Audit Trail </strong></td>'
                + '</tr>'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Version</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Description</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>User</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Created Date</strong></td>'
                + '</tr>';

            for (Map<String, Object> version : data.closedWonVersions) {
                table += '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(version.get('id')) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(version.get('description')) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(version.get('user')) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(version.get('eventDate')) + '</td>'
                    + '</tr>';
            }

            table += '</table></div></br></br>';
            return table;

        } catch (Exception e) {
            System.debug('Error in DMT_DefaultApprovalModificationsRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.closedWonVersions?.isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 35
            };

            contentList.add(DMT_Create_Pdf_Controller.createTitle('Post-Approval Management'));

            List<Object> titleSection = DMT_Create_Pdf_Controller.createTitleSection('Change Audit Trail');

            // Columnas igual que el renderHtml
            List<String> listHeaders = new List<String>{'Version', 'Description', 'User', 'Created Date'};
            List<List<String>> headers = new List<List<String>>();
            headers.add(listHeaders);

            List<List<String>> body = new List<List<String>>();
            for (Map<String, Object> version : data.closedWonVersions) {
                List<String> row = new List<String>();
                row.add(DMT_FormattingUtils.checkNull(version.get('id')));
                row.add(DMT_FormattingUtils.checkNull(version.get('description')));
                row.add(DMT_FormattingUtils.checkNull(version.get('user')));
                row.add(DMT_FormattingUtils.checkNull(version.get('eventDate')));
                body.add(row);
            }

            Map<String, Object> stylesTable = new Map<String, Object>();
            stylesTable.put('fontSize', 8);
            Map<String, Object> lineWidthItem = new Map<String, Object>();
            lineWidthItem.put('bottom', 0.1);
            stylesTable.put('lineWidth', lineWidthItem);

            Map<String, Object> headStyles = new Map<String, Object>();
            headStyles.put('fontSize', 8);

            Map<String, Object> tableComponent = new Map<String, Object>();
            tableComponent.put('headStyles', headStyles);
            tableComponent.put('style', stylesTable);
            tableComponent.put('body', body);
            tableComponent.put('head', headers);
            tableComponent.put('type', 'table');

            contentList.add(pageBreak);
            contentList.add(titleSection[0]); // título sección línea 1
            contentList.add(titleSection[1]); // título sección línea 2
            contentList.add(tableComponent);

            component.put('content', contentList);
            component.put('name', 'Post-Approval Management');

            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_DefaultApprovalModificationsRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_DefaultApprovalModificationsRenderer', 'renderPdfJson', 'DMT', ''));
            return new Map<String, Object>();
        }
    }
}