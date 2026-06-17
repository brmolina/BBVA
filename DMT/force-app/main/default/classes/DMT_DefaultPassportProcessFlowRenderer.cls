public with sharing class DMT_DefaultPassportProcessFlowRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.allsteps?.isEmpty()) {
            return '<div>Validation process not provided</div>';
        }
        try {
            List<DMT_Case_Steps_Controller.WRAPPER_Step> approvalFeatures = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
            List<DMT_Case_Steps_Controller.WRAPPER_Step> otherFeatures = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
            String table = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Validation Process</h2>';
            for (DMT_Case_Steps_Controller.WRAPPER_Step feature : data.allsteps) {
                String name = DMT_FormattingUtils.checkNull(feature?.featureName);
                if (feature?.featureType == 'passport' || feature?.featureType == null ) {
                    if (feature?.featureName != null ) {
                        approvalFeatures.add(feature);
                    } else {
                        approvalFeatures.add(feature.subitems[0]);
                    }
                }

            }
            String tableFeature = '';
            if (!approvalFeatures.isEmpty()) {
                
                for (DMT_Case_Steps_Controller.WRAPPER_Step feature : approvalFeatures) {
                    if( feature.featureType == 'passport') {
                        tableFeature = '<div>'
                    
                        + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                        + '<tr>'
                        + '<td colspan="8" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' +feature?.featureName+ '</strong></td>'
                        + '</tr>'
                        + '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Approver</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Task</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Status</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>User</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Start Date</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>End Date</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Result</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Comments</strong></td>'

                        + '</tr>';
                        if(feature.subitems.isEmpty()) {
                            tableFeature += '<tr>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.approver) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.step?.urlLabel) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.status) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.user) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.startDate) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.endDate) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.result) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.description) + '</td>'
                                + '</tr>';
                    
                            tableFeature += '</table></div></br></br>';
                        } else {
                                tableFeature += '<tr>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.approver) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.step?.urlLabel) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.status) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.user) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.startDate) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.endDate) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.result) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(feature?.description) + '</td>'
                                +    '</tr>';
                                for (DMT_Case_Steps_Controller.WRAPPER_Step task : feature.subitems) {
                                    tableFeature += '<tr>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(task?.approver) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(task?.step?.urlLabel) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(task?.status) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(task?.user) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(task?.startDate) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(task?.endDate) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(task?.result) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(task?.description) + '</td>'
                                    +    '</tr>';
                    }
                    tableFeature += '</table></div></br></br>';
                    }

                    table += tableFeature;
                    table += '</div>';
                    }

                }
            } else {
                table += '<div>There is no information about the validation process.</div>';
            }

            return table;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultPassportProcessFlowRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {

        if (data == null || data.participantList.isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            List<Object> contentListApprovalProcess= new List<Object>();
            Map<String, Object> componentApprovalProcess = new Map<String, Object>();
            
            // Add a page break before
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 35
            };
            
            contentListApprovalProcess.add(DMT_Create_Pdf_Controller.createTitle('Validation Process'));
            List<String> listHeaders = new List<String>{'Approver', 'Task', 'Status', 'User', 'Start Date', 'End Date', 'Result','Comments'};
            List<DMT_Case_Steps_Controller.WRAPPER_Step> approvalFeatures = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
            for (DMT_Case_Steps_Controller.WRAPPER_Step feature : data.allsteps) {
                String name = DMT_FormattingUtils.checkNull(feature?.featureName);
                if (feature?.featureType == 'passport' || feature?.featureType == null ) {
                    if (feature?.featureName != null ) {
                        approvalFeatures.add(feature);
                    } else {
                        approvalFeatures.add(feature.subitems[0]);
                    }
                }
            }
            for (DMT_Case_Steps_Controller.WRAPPER_Step feature : approvalFeatures) {
                Map<String, Object> tableApprovalProcessComponent = new Map<String, Object>();
                List<List<String>> body = new List<List<String>>();
                List<List<String>> headers = new List<List<String>>();
                if( feature.featureType == 'passport' ) {

                    if( feature.subitems.isEmpty()){

                        List<String> row = new List<String>();
                        row.add(DMT_FormattingUtils.checkNull(feature.approver));
                        row.add(DMT_FormattingUtils.checkNull(feature.step?.urlLabel));
                        row.add(DMT_FormattingUtils.checkNull(feature.status));
                        row.add(DMT_FormattingUtils.checkNull(feature.user));
                        row.add(DMT_FormattingUtils.checkNull(feature.startDate));
                        row.add(DMT_FormattingUtils.checkNull(feature.endDate));
                        row.add(DMT_FormattingUtils.checkNull(feature.result));
                        row.add(DMT_FormattingUtils.checkNull(feature.description));
                        body.add(row);

                        contentListApprovalProcess.add(pageBreak);
                        List<Object> titleSection = new List<Object>();
                        titleSection = DMT_Create_Pdf_Controller.createTitleSection(feature?.featureName);
                        headers.add(listHeaders);
                        Map<String, Object> stylesTable = new Map<String, Object>();
                        stylesTable.put('fontSize', 8);
                        Map<String, Object> lineWidthItem = new Map<String, Object>();
                        lineWidthItem.put('bottom',0.1);
                        stylesTable.put('lineWidth',lineWidthItem);
                        Map<String, Object> headStyles= new Map<String, Object>();
                        headStyles.put('fontSize', 8);
                        tableApprovalProcessComponent.put('headStyles', headStyles);
                        tableApprovalProcessComponent.put('style', stylesTable);
                        tableApprovalProcessComponent.put('body', body);
                        tableApprovalProcessComponent.put('head', headers);
                        tableApprovalProcessComponent.put('type', 'table');
            
                        contentListApprovalProcess.add(titleSection[0]);
                        contentListApprovalProcess.add(titleSection[1]);
                        contentListApprovalProcess.add(tableApprovalProcessComponent);
                        
                    }
                    else{
                        
                        List<String> row = new List<String>();
                        row.add(DMT_FormattingUtils.checkNull(feature.approver));
                        row.add(DMT_FormattingUtils.checkNull(feature.step?.urlLabel));
                        row.add(DMT_FormattingUtils.checkNull(feature.status));
                        row.add(DMT_FormattingUtils.checkNull(feature.user));
                        row.add(DMT_FormattingUtils.checkNull(feature.startDate));
                        row.add(DMT_FormattingUtils.checkNull(feature.endDate));
                        row.add(DMT_FormattingUtils.checkNull(feature.result));
                        row.add(DMT_FormattingUtils.checkNull(feature.description));
                        body.add(row);
                        
                        for (DMT_Case_Steps_Controller.WRAPPER_Step task : feature.subitems) {
                            List<String> rowTask = new List<String>();
                            
                            rowTask.add(DMT_FormattingUtils.checkNull(task.approver));
                            rowTask.add(DMT_FormattingUtils.checkNull(task.step?.urlLabel));
                            rowTask.add(DMT_FormattingUtils.checkNull(task.status));
                            rowTask.add(DMT_FormattingUtils.checkNull(task.user));
                            rowTask.add(DMT_FormattingUtils.checkNull(task.startDate));
                            rowTask.add(DMT_FormattingUtils.checkNull(task.endDate));
                            rowTask.add(DMT_FormattingUtils.checkNull(task.result));
                            rowTask.add(DMT_FormattingUtils.checkNull(task.description));
                            body.add(rowTask);

                        }
                        contentListApprovalProcess.add(pageBreak);
                        List<Object> titleSection = new List<Object>();
                        titleSection = DMT_Create_Pdf_Controller.createTitleSection(feature?.featureName);
                        headers.add(listHeaders);
                        Map<String, Object> stylesTable = new Map<String, Object>();
                        stylesTable.put('fontSize', 8);
                        Map<String, Object> lineWidthItem = new Map<String, Object>();
                        lineWidthItem.put('bottom',0.1);
                        stylesTable.put('lineWidth',lineWidthItem);
                        Map<String, Object> headStyles= new Map<String, Object>();
                        headStyles.put('fontSize', 8);
                        tableApprovalProcessComponent.put('headStyles', headStyles);
                        tableApprovalProcessComponent.put('style', stylesTable);
                        tableApprovalProcessComponent.put('body', body);
                        tableApprovalProcessComponent.put('head', headers);
                        tableApprovalProcessComponent.put('type', 'table');
                        //CREATE TITLE SECTION
                        contentListApprovalProcess.add(titleSection[0]);
                        contentListApprovalProcess.add(titleSection[1]);
                        contentListApprovalProcess.add(tableApprovalProcessComponent);
                    }
                }
            }
            componentApprovalProcess.put('content', contentListApprovalProcess);
            componentApprovalProcess.put('name', 'Validation Process FLOW');
    
            return componentApprovalProcess;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultPassportProcessFlowRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_DefaultPassportProcessFlowRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}