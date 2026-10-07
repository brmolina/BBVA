// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
public without sharing class DMT_DefaultApprovalModificationsRenderer implements DMT_ViewRenderer {

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.closedWonVersions?.isEmpty()) {
            return '<div>There are no versions with post-approval modifications.</div>'; 
        }
        try {
            String table = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Post-Approval Management</h2>'
                + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr data-dmt-table-title="true">'
                + '<td colspan="8" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong> Change Audit Trail </strong></td>'
                + '</tr>'
                + '<tr data-dmt-table-header="true">'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Version</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Description</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>User</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Created Date</strong></td>'
                + '</tr>';

            for (Map<String, Object> version : data.closedWonVersions) {
                table += '<tr data-dmt-table-row="true">'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(version.get('id')) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(version.get('description')) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(version.get('user')) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(version.get('eventDate')) + '</td>'
                    + '</tr>';
            }

            table += '</table></div></br></br>';
            return table;

        } catch (Exception e) {
            System.debug('Error in DMT_DefaultApprovalModificationsRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }
}