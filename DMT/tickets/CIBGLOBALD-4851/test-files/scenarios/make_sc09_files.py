"""CIBGLOBALD-4851 - scenario 9 files (Line (Other Products)): the old Other Products Lines and Products files for a new
line <prefix>OL01, and a products-only load (old Products format) for the Ready to close line <prefix>OL02.
Terms in days (the picklists DMT_Init_Term__c / DMT_End_Term__c). Run: python -I make_sc09_files.py <prefix> <out dir>"""
import csv
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.dirname(HERE)
prefix, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
low = prefix.lower()
# a Customer client (Other Products lines need Customer, Custom or Golden: flow DMT_OTHER_Line_Validations)
CLIENT = 'ES0182011178580'
INIT, END, AMOUNT = 'DMT_Risk_Line_Term__c DMT_Init_Term__c', 'DMT_Risk_Line_Term__c DMT_End_Term__c', 'DMT_Risk_Line_Term__c DMT_Amount__c'


def old_rows(name, line_id, terms):
    """The rows of an old file with the line id of the prefix; terms = (term id suffix, amount, init, end) per row."""
    rows = list(csv.DictReader(open(os.path.join(SOURCE, name), encoding='utf-8-sig')))
    result = []
    for (suffix, amount, init, end), row in zip(terms, rows * len(terms)):
        row = dict(row, Line_Id__c=line_id, Client_Code__c=CLIENT, Name=f'{prefix} Other Products line', DMT_Comments__c=f'{prefix} old file')
        row.update({INIT: init, END: end, AMOUNT: amount, 'DMT_RiskLineTermId__c': f'{line_id}-{suffix}'})
        result.append(row)
    return result


def write(name, rows, header):
    with open(os.path.join(out, name), 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=header, lineterminator='\r\n')
        writer.writeheader()
        writer.writerows(rows)


def header(name):
    return next(csv.reader(open(os.path.join(SOURCE, name), encoding='utf-8-sig')))


for line in ('OL01', 'OL02'):
    line_id = prefix + line
    tag = '' if line == 'OL01' else '_setup'
    write(f'{low}_ol_lines{tag}.csv', old_rows('ol_lines.csv', line_id, [('01', '1000000', '0', '365')]), header('ol_lines.csv'))
    products = [('01', '600000', '0', '365'), ('02', '400000', '365', '1095')] if line == 'OL01' else [('01', '1000000', '0', '365')]
    write(f'{low}_ol_products{tag}.csv', old_rows('ol_products.csv', line_id, products), header('ol_products.csv'))

# Ready to close line, products only: a Lines file with the line id alone and one term that replaces the current one
write(f'{low}_rtc_lines.csv', [{'Line_Id__c': prefix + 'OL02'}], ['Line_Id__c'])
write(f'{low}_rtc_products.csv',
      [{'Line_Id__c': prefix + 'OL02', 'DMT_RiskLineTermId__c': prefix + 'OL02-02', AMOUNT: '1000000', INIT: '0', END: '1095'}],
      ['Line_Id__c', 'DMT_RiskLineTermId__c', AMOUNT, INIT, END])
print('built', sorted(os.listdir(out)))
