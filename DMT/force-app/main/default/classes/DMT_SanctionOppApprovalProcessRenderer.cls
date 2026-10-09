public without sharing class DMT_SanctionOppApprovalProcessRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.sanctionOppAllsteps?.isEmpty()) {
            return '<div>Approval process not provided</div>';
        }
        try {
            List<DMT_Case_Steps_Controller.WRAPPER_Step> approvalFeatures = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
            String table = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Approval Process</h2>';
            for (DMT_Case_Steps_Controller.WRAPPER_Step feature : data.sanctionOppAllsteps) {
                String name = DMT_FormattingUtils.checkNull(feature?.featureName);
                if (feature?.featureType == 'approval'  || feature?.featureType == null ) {
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
                    if( feature.featureType == 'approval') {
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
                table += '<div>There is no information about the approval process.</div>';
            }

            return table;
        } catch (Exception e){
            System.debug('Error in DMT_SanctionOppApprovalProcessRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}