public with sharing class DMT_DefaultParticipantRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.participantList.isEmpty()) {
            return '<div>Participants data not provided</div>';
        }
        try {
            String table = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">PARTICIPANTS</h2>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                + '<td colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>PARTICIPANT SELECTION</strong></td>'
                + '</tr>'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>PARTICIPANT</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>ACCESS LEVEL</strong></td>'
                + '</tr>';
            for (DMT_TeamMember__c participant : data.participantList) {
                table += '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(participant?.Full_Name_User__c) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(participant?.AccessLevel__c) + '</td>'
                    + '</tr>';
            }
            table += '</table></div></br></br>';
            return table;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultParticipantRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {

        if (data == null || data.participantList.isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            List<Object> contentListParticipants= new List<Object>();
            Map<String, Object> componentParticipants = new Map<String, Object>();
            //TITLE PARTICIPANTS DARA
            // Add a page break before
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 35
            };
            
            contentListParticipants.add(pageBreak);
            contentListParticipants.add(DMT_Create_Pdf_Controller.createTitle('PARTICIPANTS'));
            List<List<String>> headers = new List<List<String>>();
            List<String> listHeaders = new List<String>{'PARTICIPANT', 'ACCESS LEVEL'};
            headers.add(listHeaders);
            Map<String, Object> tableParticipantsComponent = new Map<String, Object>();
            List<List<String>> body = new List<List<String>>();
            for (DMT_TeamMember__c participant : data.participantList) {
                List<String> row = new List<String>();
                row.add(DMT_FormattingUtils.checkNull(participant.Full_Name_User__c));
                row.add(DMT_FormattingUtils.checkNull(participant.AccessLevel__c));
                body.add(row);
            }
            Map<String, Object> stylesTable = new Map<String, Object>();
                stylesTable.put('fontSize', 8);
            Map<String, Object> lineWidthItem = new Map<String, Object>();
                lineWidthItem.put('bottom',0.1);
                stylesTable.put('lineWidth',lineWidthItem);
            Map<String, Object> headStyles= new Map<String, Object>();
                headStyles.put('fontSize', 8);
                tableParticipantsComponent.put('headStyles', headStyles);
                tableParticipantsComponent.put('style', stylesTable);
                tableParticipantsComponent.put('body', body);
                tableParticipantsComponent.put('head', headers);
                tableParticipantsComponent.put('type', 'table');
    
            //CREATE TITLE SECTION
            List<Object> titleSection = new List<Object>();
            titleSection = DMT_Create_Pdf_Controller.createTitleSection('PARTICIPANT SELECTION');
            contentListParticipants.add(titleSection[0]);
            contentListParticipants.add(titleSection[1]);
            contentListParticipants.add(tableParticipantsComponent);
            componentParticipants.put('content', contentListParticipants);
            componentParticipants.put('name', 'PARTICIPANTS');
    
            return componentParticipants;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultParticipantRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_DefaultParticipantRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}