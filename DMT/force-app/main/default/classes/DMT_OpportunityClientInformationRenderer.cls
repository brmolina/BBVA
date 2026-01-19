public with sharing class DMT_OpportunityClientInformationRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Opportunity data not provided</div>';
        }
        try {
            String html = '<div>'
            + '<h3 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">CLIENT INFORMATION</h3>'
            + '<div style="font-size: 16px; color: #004481; margin-bottom: 10px;"> 1. GEOGRAPHICAL FOOTPRINT </div>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">'
                            + '<div style="font-size:8px; color:#666; font-style:italic;">Banker\'s insight on client\'s presence and our geographical matching. Description of our capabilities in the countries where we are present and weight of the countries where we lack of presence in client\'s revenues/sales/EBITDA.</div>'
                            + '<div>'+DMT_FormattingUtils.checkNull(data.oppClient.Geographical_Footprint_desc__c)+'</div>'
                        + '</td>'
                    + '</tr>'
                + '</table><br/>'
            + '<div style="font-size: 16px; color: #004481; margin-bottom: 10px;"> 2. RELATIONSHIP STATUS </div>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">'
                            + '<div style="font-size:8px; color:#666; font-style:italic;">Banker\'s feedback on the status of our relationship: evolution since onboarding, strengths, weakness, opportunities in the short term.</div>'
                            + '<div>'+DMT_FormattingUtils.checkNull(data.oppClient.Relationship_Status_desc__c)+'</div>'
                        + '</td>'
                    + '</tr>'
                + '</table><br/>'
            + '<div style="font-size: 16px; color: #004481; margin-bottom: 10px;"> 3. INDUSTRY OVERVIEW </div>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">'
                            + '<div style="font-size:8px; color:#666; font-style:italic;">Industry Head/Banker brief opinion on key drivers of client\'s sector: Opportunies & Threats, acquisition movements, strategic actions (sale/ buy of business division) impact of market risks and BBVA position in this sector.</div>'
                            + '<div>'+DMT_FormattingUtils.checkNull(data.oppClient.Industry_Overview_desc__c)+'</div>'
                        + '</td>'
                    + '</tr>'
                + '</table><br/>'
            + '</div>';
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OpportunityClientInformationRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            // initial page break threshold
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 60
            };
            contentList.add(pageBreak);

            // Main Title
            contentList.add(DMT_Create_Pdf_Controller.createTitle('CLIENT INFORMATION'));

            // 1. GEOGRAPHICAL FOOTPRINT subtitle
            Map<String, Object> subtitle = DMT_Create_Pdf_Controller.createTitle('1. GEOGRAPHICAL FOOTPRINT');
                subtitle.put('type', 'text');
                Map<String, Object> style = (Map<String, Object>) subtitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(subtitle);

            // GEOGRAPHICAL FOOTPRINT information
            // Table Head
            List<List<Object>> tableHead = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{'content'=>'Banker\'s insight on client\'s presence and our geographical matching. Description of our capabilities in the countries where we are present and weight of the countries where we lack of presence in client\'s revenues/sales/EBITDA.',
                        'styles'=>new Map<String,Object>{
                            'fontSize'=>8,
                            'textColor'=>'#666666',
                            'fontStyle'=>'italic',
                            'fillColor' => new List<Integer>{255,255,255}  // WHITE background
                        }
                    }
                }
            };
            // Table Body
            List<List<Object>> tableBody = new List<List<Object>>{
                new List<Object>{
                    DMT_FormattingUtils.checkNull(data.oppClient.Geographical_Footprint_desc__c)
                }
            };
            Map<String, Object> table = DMT_Create_Pdf_Controller.createTableObj(tableHead, tableBody);
            contentList.add(table);

            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 30 };
            contentList.add(pageBreak);

            // 2. RELATIONSHIP STATUS subtitle
            subtitle = DMT_Create_Pdf_Controller.createTitle('2. RELATIONSHIP STATUS');
                subtitle.put('type', 'text');
                style = (Map<String, Object>) subtitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(subtitle);

            // RELATIONSHIP STATUS information
            // Table Head
            tableHead = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{'content'=>'Banker\'s feedback on the status of our relationship: evolution since onboarding, strengths, weakness, opportunities in the short term.',
                        'styles'=>new Map<String,Object>{
                            'fontSize'=>8,
                            'textColor'=>'#666666',
                            'fontStyle'=>'italic',
                            'fillColor' => new List<Integer>{255,255,255}  // WHITE background
                        }
                    }
                }
            };
            // Table Body
            tableBody = new List<List<Object>>{
                new List<Object>{
                    DMT_FormattingUtils.checkNull(data.oppClient.Relationship_Status_desc__c)
                }
            };
            table = DMT_Create_Pdf_Controller.createTableObj(tableHead, tableBody);
            contentList.add(table);

            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 30 };
            contentList.add(pageBreak);

            // 3. INDUSTRY OVERVIEW subtitle
            subtitle = DMT_Create_Pdf_Controller.createTitle('3. INDUSTRY OVERVIEW');
                subtitle.put('type', 'text');
                style = (Map<String, Object>) subtitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(subtitle);

            // INDUSTRY OVERVIEW information
            // Table head
            tableHead = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{'content'=>'Industry Head/Banker brief opinion on key drivers of client\'s sector: Opportunies & Threats, acquisition movements, strategic actions (sale/ buy of business division) impact of market risks and BBVA position in this sector.',
                        'styles'=>new Map<String,Object>{
                            'fontSize'=>8,
                            'textColor'=>'#666666',
                            'fontStyle'=>'italic',
                            'fillColor' => new List<Integer>{255,255,255}  // WHITE background
                        }
                    }
                }
            };
            // Table Body
            tableBody = new List<List<Object>>{
                new List<Object>{
                    DMT_FormattingUtils.checkNull(data.oppClient.Industry_Overview_desc__c)
                }
            };
            table = DMT_Create_Pdf_Controller.createTableObj(tableHead, tableBody);
            contentList.add(table);

            component.put('content', contentList);
            component.put('name', 'CLIENT INFORMATION');
            return component;
        } catch (Exception e) {
            System.debug('Error in DMT_OpportunityClientInformationRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OpportunityClientInformationRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}