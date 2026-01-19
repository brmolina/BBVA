public with sharing class DMT_OpportunitySustainabilityRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Opportunity data not provided</div>';
        }
        try {
            String html = '<div>'
            + '<h3 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">SUSTAINABLE FINANCE</h3>'
            // Client Information section
            + '<div style="font-size: 16px; color: #004481; margin-bottom: 10px;"> 1. CLIENT INFORMATION </div>'
            + '<div style="font-size:8px; color:#666; font-style:italic;">Brief description of client\'s sustainability strategy (can include plans for a transition to a low carbon economy/meeting the Paris Agreement, international sustainability commitments, green investments or relevant divestments, etc.)</div>'
            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                + DMT_FormattingUtils.tableRow1column('ESG Score', DMT_FormattingUtils.checkNull(data.oppClient.gf_esg_score_close_ope_name__c))
                + DMT_FormattingUtils.tableRow1column('TCFD supporter', DMT_FormattingUtils.checkNull(data.oppClient.gf_co_list_tcfd_ind_type__c))
                + DMT_FormattingUtils.tableRow1column('Paris Aligned', DMT_FormattingUtils.checkNull(data.oppClient.gf_paris_agreement_ind_type__c))
                + DMT_FormattingUtils.tableRow1column('Other', DMT_FormattingUtils.checkNull(data.oppClient.gf_customer_sustnbl_strg_desc__c))
            + '</table></br>'
            + '<div style="font-size:8px; color:#666; font-style:italic;">Brief description of sustainable finance pitches to the client in the last 12 months and opportunities identified</div>'
            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                + DMT_FormattingUtils.tableRow1column('IB&F', DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_ibf_desc__c))
                + DMT_FormattingUtils.tableRow1column('GM', DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_gm_desc__c))
                + DMT_FormattingUtils.tableRow1column('GTB', DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_gtb_desc__c))
            + '</table></br>'
            // Sustainability Indicators section
            + '<div style="font-size: 16px; color: #004481; margin-bottom: 10px;"> 2. SUSTAINABILITY INDICATORS </div>'
            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                + DMT_FormattingUtils.tableRow2columns_New('TRI', 'TODO', 'Positioning', 'TODO')
                + DMT_FormattingUtils.tableRow2columns_New('CCA', 'TODO', 'CTA', 'TODO')
                + DMT_FormattingUtils.tableRow2columns_New('TRI Engagement Plan', 'TODO', 'Group Alignment degree', 'TODO')
                + DMT_FormattingUtils.tableRow2columns_New('Sector Alignment degree', 'TODO', 'Emissoins Intensity', 'TODO')
                + DMT_FormattingUtils.tableRow2columns_New('Scope', 'TODO', '', '')
            + '</table></br>'
            // Transaction section
            + '<div style="font-size: 16px; color: #004481; margin-bottom: 10px;"> 3. TRANSACTION </div>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                    + '<td colspan="2" style="width:50%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>Sustainable deal</strong></td>'
                + '</tr>'
                + '<tr>'
                    + '<td style="padding:8px; border-bottom:1px solid #ccc;">TODO</td>'
                    + '<td style="padding:8px; border-bottom:1px solid #ccc;">TODO</td>'
                + '</tr>'
            + '</table><br/>'
            // Assessment section
            + '<div style="font-size: 16px; color: #004481; margin-bottom: 10px;"> 4. ASSESSMENT </div>'
            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                + DMT_FormattingUtils.tableRow2columns_New('Reputational risk', 'TODO', 'Equator Principles', 'TODO')
                + DMT_FormattingUtils.tableRow2columns_New('CleanTech', 'TODO', 'Portfolio Alignment', 'TODO')
                + DMT_FormattingUtils.tableRow2columns_New('KPI-Link Margin Adjustment', 'TODO', 'Opinion provided by', 'TODO')
            + '</table></br>'
            // Environmental and Social Framework section
            + '<div style="font-size: 16px; color: #004481; margin-bottom: 10px;"> 5. Environmental and Social Framework </div>'
            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                + DMT_FormattingUtils.tableRow2columns_New('Sector affected', 'TODO', 'Transaction requirements', 'TODO')
            + '</table></br>'
            + '</div>';
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OpportunitySustainabilityRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
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
            contentList.add(DMT_Create_Pdf_Controller.createTitle('SUSTAINABLE FINANCE'));

            // 1. CLIENT INFORMATION subtitle
            Map<String, Object> subtitle = DMT_Create_Pdf_Controller.createTitle('1. CLIENT INFORMATION');
                subtitle.put('type', 'text');
                Map<String, Object> style = (Map<String, Object>) subtitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(subtitle);

            // CLIENT INFORMATION content
            List<List<Object>> tableHead = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>'Brief description of client\'s sustainability strategy (can include plans for a transition to a low carbon economy/meeting the Paris Agreement, international sustainability commitments, green investments or relevant divestments, etc.)',
                        'styles'=>new Map<String,Object>{'fontSize'=>8, 'textColor'=>new List<Integer>{102,102,102}, 'fontStyle'=>'italic', 'fillColor' => new List<Integer>{255,255,255}}
                    }
                }
            };
            List<List<Object>> tableBody = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>'ESG Score',
                        'styles'=>new Map<String,Object>{'fontSize'=>10, 'fontStyle'=>'bold', 'cellPadding' => new Map<String, Object>{'top' => 4, 'bottom' => 2, 'left' => 1, 'right' => 0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>DMT_FormattingUtils.checkNull(data.oppClient.gf_esg_score_close_ope_name__c),
                        'styles'=>new Map<String,Object>{'fontSize'=>10, 'lineWidth' => new Map<String,Object>{'top'=>0,'bottom'=>0.1,'left'=>0,'right'=>0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>'TCFD supporter',
                        'styles'=>new Map<String,Object>{'fontSize'=>10, 'fontStyle'=>'bold', 'cellPadding' => new Map<String, Object>{'top' => 4, 'bottom' => 2, 'left' => 1, 'right' => 0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>DMT_FormattingUtils.checkNull(data.oppClient.gf_co_list_tcfd_ind_type__c),
                        'styles'=>new Map<String,Object>{'fontSize'=>10, 'lineWidth' => new Map<String,Object>{'top'=>0,'bottom'=>0.1,'left'=>0,'right'=>0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>'Paris Aligned',
                        'styles'=>new Map<String,Object>{'fontSize'=>10, 'fontStyle'=>'bold', 'cellPadding' => new Map<String, Object>{'top' => 4, 'bottom' => 2, 'left' => 1, 'right' => 0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>DMT_FormattingUtils.checkNull(data.oppClient.gf_paris_agreement_ind_type__c),
                        'styles'=>new Map<String,Object>{'fontSize'=>10, 'lineWidth' => new Map<String,Object>{'top'=>0,'bottom'=>0.1,'left'=>0,'right'=>0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>'Other',
                        'styles'=>new Map<String,Object>{'fontSize'=>10, 'fontStyle'=>'bold', 'cellPadding' => new Map<String, Object>{'top' => 4, 'bottom' => 2, 'left' => 1, 'right' => 0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>DMT_FormattingUtils.checkNull(data.oppClient.gf_customer_sustnbl_strg_desc__c),
                        'styles'=>new Map<String,Object>{'fontSize'=>10, 'lineWidth' => new Map<String,Object>{'top'=>0,'bottom'=>0.1,'left'=>0,'right'=>0}}
                    }
                }
            };
            Map<String, Object> table = DMT_Create_Pdf_Controller.createTableObj(tableHead, tableBody);
            contentList.add(table);

            tableHead = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>'Brief description of sustainable finance pitches to the client in the last 12 months and opportunities identified',
                        'styles'=>new Map<String,Object>{'fontSize'=>8, 'textColor'=>new List<Integer>{102,102,102}, 'fontStyle'=>'italic', 'fillColor' => new List<Integer>{255,255,255}}
                    }
                }
            };
            tableBody = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>'IB&F',
                        'styles'=>new Map<String,Object>{'fontSize'=>10,'fontStyle'=>'bold', 'cellPadding' => new Map<String, Object>{'top' => 4, 'bottom' => 2, 'left' => 1, 'right' => 0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_ibf_desc__c),
                        'styles'=>new Map<String,Object>{ 'fontSize'=>10, 'lineWidth' => new Map<String,Object>{'top'=>0,'bottom'=>0.1,'left'=>0,'right'=>0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>'GM',
                        'styles'=>new Map<String,Object>{'fontSize'=>10,'fontStyle'=>'bold', 'cellPadding' => new Map<String, Object>{'top' => 4, 'bottom' => 2, 'left' => 1, 'right' => 0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_gm_desc__c),
                        'styles'=>new Map<String,Object>{'fontSize'=>10, 'lineWidth' => new Map<String,Object>{'top'=>0,'bottom'=>0.1,'left'=>0,'right'=>0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>'GTB',
                        'styles'=>new Map<String,Object>{'fontSize'=>10,'fontStyle'=>'bold', 'cellPadding' => new Map<String, Object>{'top' => 4, 'bottom' => 2, 'left' => 1, 'right' => 0}}
                    }
                },
                new List<Object>{
                    new Map<String,Object>{
                        'content'=>DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_gtb_desc__c),
                        'styles'=>new Map<String,Object>{'fontSize'=>10, 'lineWidth' => new Map<String,Object>{'top'=>0,'bottom'=>0.1,'left'=>0,'right'=>0}}
                    }
                }
            };
            table = DMT_Create_Pdf_Controller.createTableObj(tableHead, tableBody);
            contentList.add(table);

            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 30 };
            contentList.add(pageBreak);

            // 2. SUSTAINABILITY INDICATORS subtitle
            subtitle = DMT_Create_Pdf_Controller.createTitle('2. SUSTAINABILITY INDICATORS');
                subtitle.put('type', 'text');
                style = (Map<String, Object>) subtitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(subtitle);

            // SUSTAINABILITY INDICATORS content
            List<String> listTextLabels = new List<String>{
                'TRI',
                'CCA',
                'TRI Engagement Plan',
                'Sector Alignment degree',
                'Scope',
                'Positioning',
                'CTA',
                'Group Alignment degree',
                'Emissoins Intensity'
            };
            List<String> listTextValues = new List<String>{
                'TODO',
                'TODO',
                'TODO',
                'TODO',
                'TODO',
                'TODO',
                'TODO',
                'TODO',
                'TODO'
            };
            contentList.add(DMT_Create_Pdf_Controller.createListText(listTextLabels, listTextValues, ''));

            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 30 };
            contentList.add(pageBreak);

            // 3. TRANSACTION subtitle
            subtitle = DMT_Create_Pdf_Controller.createTitle('3. TRANSACTION');
                subtitle.put('type', 'text');
                style = (Map<String, Object>) subtitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(subtitle);

            // TRANSACTION content
            List<List<String>> tranTableHead = new List<List<String>>{
                new List<String>{'Sustainable Deal', ''}
            };
            List<List<String>> tranTableBody = new List<List<String>>{
                new List<String>{'TODO', 'TODO'}
            };
            contentList.add(DMT_Create_Pdf_Controller.createTable(tranTableHead, tranTableBody));

            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 30 };
            contentList.add(pageBreak);

            // 4. ASSESSMENT subtitle
            subtitle = DMT_Create_Pdf_Controller.createTitle('4. ASSESSMENT');
                subtitle.put('type', 'text');
                style = (Map<String, Object>) subtitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(subtitle);

            // ASSESSMENT content
            listTextLabels = new List<String>{
                'Reputational risk',
                'CleanTech',
                'KPI-Link Margin Adjustment',
                'Equator Principles',
                'Portfolio Alignment',
                'Opinion provided by'
            };
            listTextValues = new List<String>{
                'TODO',
                'TODO',
                'TODO',
                'TODO',
                'TODO',
                'TODO'
            };
            contentList.add(DMT_Create_Pdf_Controller.createListText(listTextLabels, listTextValues, ''));

            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 30 };
            contentList.add(pageBreak);

            // 5. Environmental and Social Framework subtitle
            subtitle = DMT_Create_Pdf_Controller.createTitle('5. Environmental and Social Framework');
                subtitle.put('type', 'text');
                style = (Map<String, Object>) subtitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(subtitle);

            // Environmental and Social Framework content
            listTextLabels = new List<String>{
                'Sector affected',
                'Transaction requirements'
            };
            listTextValues = new List<String>{
                'TODO',
                'TODO'
            };
            contentList.add(DMT_Create_Pdf_Controller.createListText(listTextLabels, listTextValues, ''));

            component.put('content', contentList);
            component.put('name', 'CLIENT INFORMATION');
            return component;
        } catch (Exception e) {
            System.debug('Error in DMT_OpportunitySustainabilityRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OpportunitySustainabilityRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}