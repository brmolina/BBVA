"""CIBGLOBALD-4851 - builds ex_b_lines.xlsx without openpyxl: minimal workbook, dates as serial numbers with a date
format (as Excel saves them). Run: python -I make_ex_xlsx.py"""
import os
import zipfile
import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
rows = [
    ['Line_Id__c', 'Name', 'Client_Code__c', 'Booking_Geography__c', 'CurrencyIsoCode', 'Start_Date__c', 'End_Date__c'],
    ['EXX001', 'EX Xlsx Line', 'ES0182000125513', 'ES', 'EUR', datetime.date(2026, 3, 15), datetime.date(2027, 3, 15)],
]


def serial(d):
    return (d - datetime.date(1899, 12, 30)).days


def col(i):
    return chr(ord('A') + i)


cells = []
for r, row in enumerate(rows, start=1):
    out = []
    for c, v in enumerate(row):
        ref = f'{col(c)}{r}'
        if isinstance(v, datetime.date):
            out.append(f'<c r="{ref}" s="1"><v>{serial(v)}</v></c>')
        else:
            out.append(f'<c r="{ref}" t="inlineStr"><is><t>{v}</t></is></c>')
    cells.append(f'<row r="{r}">{"".join(out)}</row>')

files = {
    '[Content_Types].xml': '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>',
    '_rels/.rels': '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    'xl/workbook.xml': '<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Lines" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels': '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>',
    'xl/styles.xml': '<?xml version="1.0" encoding="UTF-8"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<fonts count="1"><font/></fonts><fills count="1"><fill/></fills><borders count="1"><border/></borders>'
        '<cellStyleXfs count="1"><xf/></cellStyleXfs><cellXfs count="2"><xf/><xf numFmtId="14" applyNumberFormat="1"/></cellXfs></styleSheet>',
    'xl/worksheets/sheet1.xml': '<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        f'<sheetData>{"".join(cells)}</sheetData></worksheet>',
}
with zipfile.ZipFile(os.path.join(HERE, 'ex_b_lines.xlsx'), 'w', zipfile.ZIP_DEFLATED) as z:
    for name, content in files.items():
        z.writestr(name, content)
print('ex_b_lines.xlsx built')
