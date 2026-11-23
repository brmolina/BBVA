"""CIBGLOBALD-4851 - scenario 8 files (file formats): copies of ex_a_lines_semicolon.csv and ex_b_lines.xlsx with the Line
IDs of the given prefix (bytes otherwise unchanged: BOM, semicolons, CRLF, quoted line break, doubled quotes, blank row),
plus a Line Product Items file for line 1 to drop in the wrong zone. Run: python -I make_sc08_files.py <prefix> <out dir>"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.dirname(HERE)
prefix, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
low = prefix.lower()


def line_id(n):
    return f'{prefix}LIN0000000{n}ES'


# Semicolon CSV: EXL00n -> <prefix>LIN0000000nES
data = open(os.path.join(SOURCE, 'ex_a_lines_semicolon.csv'), 'rb').read()
for n in range(1, 8):
    data = data.replace(f'EXL00{n};'.encode(), f'{line_id(n)};'.encode())
data = data.replace(b'EX ', f'{prefix} '.encode())
open(os.path.join(out, f'{low}_lines_semicolon.csv'), 'wb').write(data)

# XLSX with date cells: EXX001 -> <prefix>LIN00000008ES
src = zipfile.ZipFile(os.path.join(SOURCE, 'ex_b_lines.xlsx'))
with zipfile.ZipFile(os.path.join(out, f'{low}_lines_dates.xlsx'), 'w', zipfile.ZIP_DEFLATED) as dst:
    for item in src.infolist():
        content = src.read(item.filename)
        if item.filename == 'xl/worksheets/sheet1.xml':
            content = content.replace(b'EXX001', line_id(8).encode()).replace(b'EX Xlsx Line', f'{prefix} Xlsx Line'.encode())
        dst.writestr(item, content)

# Line Product Items of line 1, to drop in the Risk Line Terms zone
with open(os.path.join(out, f'{low}_line_product_items.csv'), 'w', encoding='utf-8', newline='') as f:
    f.write('Line__r.Line_Id__c,Product_Code_Value__c,DMT_DerivativeRestriction__c,DMT_FDRestriction__c,DMT_DVPRestriction__c,Max_Tenor_WC__c\r\n')
    f.write(f'{line_id(1)},DEPO,FALSE,TRUE,FALSE,\r\n')
print('built', sorted(os.listdir(out)))
