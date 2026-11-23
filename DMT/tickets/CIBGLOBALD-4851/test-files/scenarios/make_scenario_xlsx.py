"""CIBGLOBALD-4851 - builds one XLSX per test scenario, one tab per table (Lines, Risk Line Terms, Line Product Items),
every cell as text so Google Sheets shows exactly the file value (no date or number reformatting). Drive converts the
XLSX to a Google Sheet and keeps the tabs. Run: python -I make_scenario_xlsx.py"""
import os
import zipfile
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))

SCENARIOS = {
    # Scenario 10 - standard user (BBVA Standard User + DMT_Line_God): from Draft only Proposal (validation rule
    # Go_through_each_step); the other codes stay in Draft
    'sc10': {
        'Lines': [
            ['Line_Id__c', 'Name', 'Booking_Geography__c', 'CurrencyIsoCode', 'Start_Date__c', 'End_Date__c', 'Client_Code__c', 'g_line_status_type__c'],
            ['SC10LIN00000001ES', 'SC10 line 1 to Proposal', 'ES', 'EUR', '2026-12-01', '2027-11-30', 'ES0182011178580', 'PR'],
            ['SC10LIN00000002ES', 'SC10 line 2 to Approval', 'ES', 'EUR', '2026-12-01', '2027-11-30', 'ES0182011178580', 'AP'],
            ['SC10LIN00000003ES', 'SC10 line 3 to Closed Won', 'ES', 'EUR', '2026-12-01', '2027-11-30', 'ES0182011178580', 'CW'],
            ['SC10LIN00000004ES', 'SC10 line 4 Draft', 'ES', 'EUR', '2026-12-01', '2027-11-30', 'ES0182011178580', 'DR'],
        ],
        'Risk Line Terms': [
            ['DMT_Line__r.Line_Id__c', 'DMT_Risk_Type__c', 'DMT_Amount__c', 'DMT_Init_Term__c', 'DMT_End_Term__c'],
        ] + [[f'SC10LIN0000000{n}ES', 'Derivatives', '100000', '0', '365'] for n in range(1, 5)],
        'Line Product Items': [
            ['Line__r.Line_Id__c', 'Product_Code_Value__c', 'DMT_DerivativeRestriction__c', 'DMT_FDRestriction__c', 'DMT_DVPRestriction__c', 'Max_Tenor_WC__c'],
        ] + [[f'SC10LIN0000000{n}ES', 'DEPO', 'FALSE', 'TRUE', 'FALSE', ''] for n in range(1, 5)],
    },
    # Scenario 7 - one Treasury load, one rule per line (Proposal rename + blank break clause, Closed without code, comment in
    # Approval, lower case code with a gap, Prospect closed Won, term in the wrong format)
    'sc07': {
        'Lines': [
            ['Line_Id__c', 'Name', 'Booking_Geography__c', 'CurrencyIsoCode', 'Client_Code__c', 'First_Breakclause__c', 'Breakclause_Frequency__c', 'DMT_Comments__c', 'g_line_status_type__c'],
            ['SC07LIN00000001ES', 'SC07 line 1 renamed in Proposal', 'ES', 'EUR', 'ES0182011178580', '', '', '', 'PR'],
            ['SC07LIN00000002ES', 'SC07 line 2 renamed while Closed', 'ES', 'EUR', 'ES0182011178580', '', '', '', ''],
            ['SC07LIN00000003ES', 'SC07 line 3', 'ES', 'EUR', 'ES0182011178580', '', '', 'Comment changed in Approval', 'AP'],
            ['SC07LIN00000004ES', 'SC07 line 4 lower case code with gap', 'ES', 'EUR', 'ES0182011178580', '', '', '', 'pr'],
            ['SC07LIN00000005ES', 'SC07 line 5 Prospect closed Won', 'ES', 'EUR', 'P00000000000078', '', '', '', 'CW'],
            ['SC07LIN00000006ES', 'SC07 line 6 term in wrong format', 'ES', 'EUR', 'ES0182011178580', '', '', '', 'PR'],
        ],
        'Risk Line Terms': [
            ['DMT_Line__r.Line_Id__c', 'DMT_Risk_Type__c', 'DMT_Amount__c', 'DMT_Init_Term__c', 'DMT_End_Term__c'],
            ['SC07LIN00000001ES', 'Derivatives', '100000', '0', '365'],
            ['SC07LIN00000002ES', 'Derivatives', '100000', '0', '365'],
            ['SC07LIN00000003ES', 'Derivatives', '100000', '0', '365'],
            ['SC07LIN00000005ES', 'Derivatives', '100000', '0', '365'],
            ['SC07LIN00000004ES', 'Derivatives', '100000', '0', '30'],
            ['SC07LIN00000004ES', 'Derivatives', '100000', '90', '365'],
            ['SC07LIN00000006ES', 'Derivatives', '100000', '2026-01-01', '365'],
        ],
        'Line Product Items': [
            ['Line__r.Line_Id__c', 'Product_Code_Value__c', 'DMT_DerivativeRestriction__c', 'DMT_FDRestriction__c', 'DMT_DVPRestriction__c', 'Max_Tenor_WC__c'],
            ['SC07LIN00000001ES', 'DEPO', 'FALSE', 'TRUE', 'FALSE', ''],
            ['SC07LIN00000002ES', 'DEPO', 'FALSE', 'TRUE', 'FALSE', ''],
            ['SC07LIN00000003ES', 'DEPO', 'FALSE', 'TRUE', 'FALSE', ''],
            ['SC07LIN00000004ES', 'DEPO', 'FALSE', 'TRUE', 'FALSE', ''],
            ['SC07LIN00000005ES', 'DEPO', 'FALSE', 'TRUE', 'FALSE', ''],
            ['SC07LIN00000006ES', 'DEPO', 'FALSE', 'TRUE', 'FALSE', ''],
        ],
    },
    # Scenario 6 - the SC05 lines that stayed in Draft get valid Line Product Items; Update Line Status moves them; Add OU
    'sc06': {
        'Lines': [
            ['Line_Id__c'],
            ['SC05LIN00000001ES'],
            ['SC05LIN00000002ES'],
            ['SC05LIN00000003ES'],
        ],
        'Line Product Items': [
            ['Line__r.Line_Id__c', 'Product_Code_Value__c', 'DMT_DerivativeRestriction__c', 'DMT_FDRestriction__c', 'DMT_DVPRestriction__c', 'Max_Tenor_WC__c'],
            ['SC05LIN00000001ES', 'DEPO', 'FALSE', 'TRUE', 'FALSE', ''],
            ['SC05LIN00000002ES', 'DEPO', 'FALSE', 'FALSE', 'TRUE', ''],
            ['SC05LIN00000003ES', 'DERI', 'TRUE', 'FALSE', 'FALSE', '3Y'],
        ],
    },
    # Scenario 5 (Diego) - Treasury lines and Line Product Items: the flow DMT_TRSR_Line_Validations applied to everyone
    'sc05': {
        'Lines': [
            ['Line_Id__c', 'Name', 'DMT_ID_User__c', 'Booking_Geography__c', 'CurrencyIsoCode', 'Start_Date__c', 'End_Date__c',
             'Client_Code__c', 'g_line_status_type__c'],
            ['SC05LIN00000001ES', 'SC05 No product item', 'O009201', 'ES', 'EUR', '2026-11-01', '2027-11-30', 'ES0182011178580', 'PR'],
            ['SC05LIN00000002ES', 'SC05 Item without restriction', 'O009201', 'ES', 'EUR', '2026-11-01', '2027-11-30', 'ES0182011178580', 'PR'],
            ['SC05LIN00000003ES', 'SC05 Derivatives item without term', 'O009201', 'ES', 'EUR', '2026-11-01', '2027-11-30', 'ES0182011178580', 'PR'],
            ['SC05LIN00000004ES', 'SC05 Correct', 'O009201', 'ES', 'EUR', '2026-11-01', '2027-11-30', 'ES0182011178580', 'PR'],
        ],
        'Risk Line Terms': [
            ['DMT_Line__r.Line_Id__c', 'DMT_Risk_Type__c', 'DMT_Amount__c', 'DMT_Init_Term__c', 'DMT_End_Term__c'],
            ['SC05LIN00000001ES', 'Derivatives', '100000.00', '0', '365'],
            ['SC05LIN00000002ES', 'Derivatives', '100000.00', '0', '365'],
            ['SC05LIN00000003ES', 'Derivatives', '100000.00', '0', '365'],
            ['SC05LIN00000004ES', 'Derivatives', '100000.00', '0', '365'],
        ],
        'Line Product Items': [
            ['Line__r.Line_Id__c', 'Product_Code_Value__c', 'DMT_DerivativeRestriction__c', 'DMT_FDRestriction__c', 'DMT_DVPRestriction__c', 'Max_Tenor_WC__c'],
            ['SC05LIN00000002ES', 'DEPO', 'FALSE', 'FALSE', 'FALSE', ''],
            ['SC05LIN00000003ES', 'DERI', 'TRUE', 'FALSE', 'FALSE', ''],
            ['SC05LIN00000004ES', 'DERI', 'TRUE', 'FALSE', 'FALSE', '5Y'],
        ],
    },
    # Scenario 4 - new lines with status codes: automatic move after the load, one stays in Draft (gap in its terms)
    'sc04': {
        'Lines': [
            ['Line_Id__c', 'Name', 'DMT_ID_User__c', 'Booking_Geography__c', 'CurrencyIsoCode', 'Start_Date__c', 'End_Date__c',
             'Client_Code__c', 'g_line_status_type__c'],
            ['SC04LIN00000001ES', 'SC04 Moves to Proposal', 'O009201', 'ES', 'EUR', '2026-11-01', '2027-11-30', 'ES0182011178580', 'PR'],
            ['SC04LIN00000002ES', 'SC04 Moves to Approval', 'O009201', 'ES', 'EUR', '2026-11-01', '2027-11-30', 'ES0182011178580', 'AP'],
            ['SC04LIN00000003ES', 'SC04 Gap in terms', 'O009201', 'ES', 'EUR', '2026-11-01', '2027-11-30', 'ES0182011178580', 'PR'],
            ['SC04LIN00000004ES', 'SC04 Draft code', 'O009201', 'ES', 'EUR', '2026-11-01', '2027-11-30', 'ES0182011178580', 'DR'],
        ],
        'Risk Line Terms': [
            ['DMT_Line__r.Line_Id__c', 'DMT_Risk_Type__c', 'DMT_Amount__c', 'DMT_Init_Term__c', 'DMT_End_Term__c'],
            ['SC04LIN00000001ES', 'Derivatives', '100000.00', '0', '365'],
            ['SC04LIN00000002ES', 'Derivatives', '100000.00', '0', '365'],
            ['SC04LIN00000003ES', 'Derivatives', '100000.00', '0', '30'],
            ['SC04LIN00000003ES', 'Derivatives', '100000.00', '90', '365'],
            ['SC04LIN00000004ES', 'Derivatives', '100000.00', '0', '365'],
        ],
    },
    # Scenario 3 - only the Lines table: the products in Salesforce show Kept; single records removed / restored
    'sc03': {
        'Lines': [
            ['Line_Id__c'],
            ['SC01LIN00000001ES'],
            ['SC01LIN00000002ES'],
        ],
    },
    # Scenario 2 - products replaced on existing lines: line 1 gets new terms, line 2 new items; the other table of each
    # line is kept
    'sc02': {
        'Lines': [
            ['Line_Id__c', 'DMT_Comments__c'],
            ['SC01LIN00000001ES', 'Scenario 2 - terms replaced'],
            ['SC01LIN00000002ES', 'Prueba línea 2'],
        ],
        'Risk Line Terms': [
            ['DMT_Line__r.Line_Id__c', 'DMT_Risk_Type__c', 'DMT_Amount__c', 'DMT_Init_Term__c', 'DMT_End_Term__c'],
            ['SC01LIN00000001ES', 'Derivatives', '120000.00', '0', '30'],
            ['SC01LIN00000001ES', 'Derivatives', '220000.00', '30', '365'],
        ],
        'Line Product Items': [
            ['Line__r.Line_Id__c', 'Product_Code_Value__c', 'DMT_DerivativeRestriction__c', 'DMT_FDRestriction__c', 'DMT_DVPRestriction__c'],
            ['SC01LIN00000002ES', 'DERI', 'TRUE', 'FALSE', 'FALSE'],
            ['SC01LIN00000002ES', 'FOEX', 'FALSE', 'FALSE', 'FALSE'],
        ],
    },
}


def col(i):
    name = ''
    i += 1
    while i:
        i, r = divmod(i - 1, 26)
        name = chr(65 + r) + name
    return name


def sheet_xml(rows):
    out = []
    for r, row in enumerate(rows, start=1):
        cells = ''.join(f'<c r="{col(c)}{r}" t="inlineStr"><is><t xml:space="preserve">{escape(v)}</t></is></c>'
                        for c, v in enumerate(row))
        out.append(f'<row r="{r}">{cells}</row>')
    return ('<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            f'<sheetData>{"".join(out)}</sheetData></worksheet>')


def build(name, tabs):
    names = list(tabs)
    files = {
        '[Content_Types].xml': '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            '<Default Extension="xml" ContentType="application/xml"/>'
            '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
            + ''.join(f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
                      for i in range(1, len(names) + 1)) + '</Types>',
        '_rels/.rels': '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
        'xl/workbook.xml': '<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
            + ''.join(f'<sheet name="{escape(n)}" sheetId="{i}" r:id="rId{i}"/>' for i, n in enumerate(names, start=1))
            + '</sheets></workbook>',
        'xl/_rels/workbook.xml.rels': '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            + ''.join(f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>'
                      for i in range(1, len(names) + 1)) + '</Relationships>',
    }
    for i, n in enumerate(names, start=1):
        files[f'xl/worksheets/sheet{i}.xml'] = sheet_xml(tabs[n])
    path = os.path.join(HERE, f'{name}.xlsx')
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        for fname, content in files.items():
            z.writestr(fname, content)
    print('built', path)


for scenario, tabs in SCENARIOS.items():
    build(scenario, tabs)
