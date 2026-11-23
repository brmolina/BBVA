"""CIBGLOBALD-4851 - builds CIBGLOBALD-4851-test-scenarios.csv (the user's manual test plan, uploaded to Drive as a Google
Sheet). Run: python -I make_scenarios.py"""
import csv
import os

HERE = os.path.dirname(os.path.abspath(__file__))
HEADER = ['#', 'Area', 'Scenario', 'Line Type', 'Files (load in this order)', 'Steps', 'Expected result',
          'Data prep (ask Claude before)', 'Your result', 'Notes']
TL = 'Treasury Line'
OL = 'Line (Other Products)'
S = [
    # Files and parsing
    ('Files', 'TL Lines file: new and existing lines', TL, 'tl_lines.csv',
     'Drop the file in Lines. Check the preview. Process.',
     'Preview: New / Will Update badges, Status Change column. After Process: rows Created / Updated, new line in Draft.',
     'Delete TEST4851PW01 so it is New again'),
    ('Files', 'CSV with semicolons, BOM, quoted line break and doubled quotes, blank row', TL, 'ex_a_lines_semicolon.csv',
     'Drop the file. Read the toasts and the preview. Process.',
     'All columns read. Toast: duplicate EXL007 removed (rows 9, 10). After Process: EXL003 unknown client, EXL004 client required, EXL005 invalid date (row 6) in the error table; row numbers match Excel.',
     'Delete EXL001 to EXL007'),
    ('Files', 'XLSX with date cells', TL, 'ex_b_lines.xlsx',
     'Drop the XLSX. Process. Open the line.',
     'Start Date 15/03/2026 and End Date 15/03/2027 (not one day earlier).', 'Delete EXX001'),
    ('Files', 'Paste a table (Ctrl+V) and Start Over', TL, 'ex_c_paste.tsv (open it, copy all, paste on the page)',
     'Paste outside any input. Then click Start Over.',
     'Lines table shows EXP001. Start Over clears everything.', ''),
    ('Files', 'Old Other Products files still work', OL, 'ol_lines.csv, then ol_products.csv',
     'Drop the Lines file, then the Products file in Risk Line Terms. Process.',
     'No wrong-zone dialog. Terms of the Lines file shown as Risk Line Terms. Line saved with its terms.',
     'Delete TEST4851OL01 if you want it New'),
    # Products
    ('Products', 'Replace the products of an existing line', TL, 'tl_lines.csv, tl_rlt.csv, tl_lpi.csv',
     'Drop the 3 files. Check the child tables. Process.',
     'Old records Will Be Deleted, file rows New, other lines Kept. After Process the line has exactly the file products.', ''),
    ('Products', 'Wrong drop zone', TL, 'ex_d_lines.csv, then ex_d_lpi.csv dropped in Risk Line Terms',
     'Drop the LPI file in the Risk Line Terms zone. Click Cancel. Repeat and click OK.',
     'Dialog Wrong drop zone. Cancel: nothing changes. OK: the rows go to Line Product Items.', ''),
    ('Products', 'Second file replaces the first in a zone, remove a row', TL,
     'ex_d_lines.csv, ex_d_rlt_first.csv, then ex_d_rlt_second.csv',
     'Drop the first terms file, remove one row (row menu), drop the second file. Process.',
     'Removed row disappears. The second file replaces the first. After Process the line has the 2 rows of the second file.', ''),
    ('Products', 'Ready to close line, products only', OL, 'ex_f_rtc_lines.csv, ex_f_rtc_products.csv',
     'Drop both. Check Status Change. Process.',
     'Status kept (Ready to close). Terms replaced. A Ready to close recheck runs (features may reopen).',
     'Put TEST4851OL01 in Ready to close'),
    ('Products', 'Term in the wrong format', OL, 'ex_i_lines.csv, ex_i_rlt.csv (line EXI005)',
     'Drop both. Process.',
     'EXI005 fails: DMT_Init_Term__c invalid value 2026-01-01 (expected a number of days). 365.0 is accepted as 365.',
     'Delete EXI001 to EXI005'),
    # Status rules
    ('Status', 'New lines with codes DR, AP, PR', TL, 'ex_f_lines.csv, ex_f_rlt.csv',
     'Drop both. Check Status Change. Process. Wait for the final toast.',
     'DR: no change. AP: Draft to Approval (only System Administrator / Desktop Integration). Cells go Moving, then Moved; final green toast.',
     'Delete EXS001 to EXS003'),
    ('Status', 'Existing line outside Draft, blocked field changed', TL, 'ex_g_lines.csv (rename)',
     'Drop. Check Status Change and the toasts. Process.',
     'Proposal to Draft to Proposal. Toast Features that will reopen (if any). Line ends in Proposal with the new name.',
     'Line ESCD26LIN00002786ES in Proposal'),
    ('Status', 'Closed line without code', TL, 'ex_f_lines.csv (TEST4851PW02 row)',
     'Process.', 'Closed to Draft, stays in Draft.', 'Put TEST4851PW02 in Closed'),
    ('Status', 'Stays in Draft: no amount, products below the amount, group client', OL, 'ex_j_lines.csv, ex_j_rlt.csv',
     'Drop both. Check Status Change. Process.',
     'Red warning cells: no line amount / products total below the line amount. Toast N lines will stay in Draft. Those lines are saved in Draft, no error email.',
     'Delete EXJ001 to EXJ005'),
    ('Status', 'Stays in Draft: terms with a gap or overlap', OL, 'ex_n2_lines.csv, ex_n2_rlt.csv',
     'Drop both. Process.', 'EXN020: Stays in Draft, Derivatives terms 0-365 overlaps 30-90.', 'Delete EXN020'),
    ('Status', 'Stays in Draft: Prospect client closed Won; lower case code with a gap', TL, 'ex_m2_lines.csv, ex_m2_rlt.csv',
     'Drop both. Process.',
     'EXM010: a Prospect client cannot be closed Won. EXM011: gap between 0-30 and 90-365; code saved as PR.',
     'Delete EXM010, EXM011'),
    ('Status', 'Will not be saved: comment changed on a Treasury line in Approval', TL, 'ex_m_lines.csv',
     'Drop. Check Status Change. Process.',
     'EXS002: Will not be saved (rule ApprovalProcessDataEdit), then Failed with the rule message. TEST4851PW03 (Approval Edit allowed) is saved.',
     'EXS002 and TEST4851PW03 in Approval'),
    ('Status', 'Standard user cannot jump past Proposal', TL, 'ex_f_lines.csv (AP row)',
     'Log in as a BBVA Standard User with DMT_Line_God. Drop and check Status Change.',
     'AP lines: Stays in Draft, profile BBVA Standard User cannot jump from Draft.', 'Delete EXS002; a standard user login'),
    ('Status', 'Update Line Status button after fixing the data', OL, 'ex_j2_lines.csv (after ex_j)',
     'Process the fix file. Click Update Line Status.',
     'Button enabled. EXJ002 Moving, then Moved to Proposal; final green toast. Lines still blocked are not sent (warning icon next to the button lists them).',
     'EXJ002 in Draft with code PR and no amount'),
    ('Status', 'Background failure is shown on screen', OL, 'Any load where a move fails in the background',
     'Process and wait.',
     'Cell red Not moved to X: <org message>; final red toast listing the lines. If no answer in 5 minutes: warning toast, cells read from Salesforce.',
     'Claude can prepare a line that fails'),
    # Add OU
    ('Add OU', 'OU code validation', TL, 'any processed load',
     'After Process: leave OU blank, then type ZZZ99999, then 00011769.',
     'Blank: button disabled. ZZZ99999: no users error. 00011769: no Read/Write users error. Nothing is saved.', ''),
    ('Add OU', 'Valid OU on the lines of the load', TL, 'ex_e_lines.csv, ex_e_rlt.csv (30 lines)',
     'Process, then OU 00025828, Add OU.',
     'Toast Add OU running, then Add OU finished: 12 users added to all the lines of the load. Button locked. 29 lines saved, EXV015 failed (bad risk type).',
     'Delete EXV001 to EXV030'),
    # Other
    ('Other', 'Break clause columns blank keep the value', TL, 'tl_lines.csv (TEST26LIN00008860ES row has them blank)',
     'Process.', 'First_Breakclause__c and Breakclause_Frequency__c keep their Salesforce values.', ''),
    ('Other', 'Emails', TL, 'any load with a status move',
     'Check your inbox.', 'Sender Global Desktop Notification; body lists the lines moved or failed.', ''),
]


def main():
    path = os.path.join(HERE, 'CIBGLOBALD-4851-test-scenarios.csv')
    with open(path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(HEADER)
        for i, (area, scenario, line_type, files, steps, expected, prep) in enumerate(S, start=1):
            writer.writerow([i, area, scenario, line_type, files, steps, expected, prep, '', ''])
    text = open(path, encoding='utf-8').read()
    assert '"' not in ''.join(c for row in S for c in row), 'no double quotes inside cells'
    print(path, len(S), 'scenarios')


main()
