"""CIBGLOBALD-4851 - builds the exhaustive-test input files (ex_*) in this folder. Run: python -I make_ex_files.py"""
import os
import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
CUSTOMER = 'ES0182000125513'   # EUROMASTER (customer code; its DES_Client_Type__c is empty, so its lines are Group)
SUBSIDIARY = 'ES0182011178580' # GRIFOLS VIAJES (customer code, DES_Client_Type__c Subsidiary: lines are Customer)
GROUP    = 'G00000000000200'   # IBERDROLA (group code)


def write(name, text, bom=False):
    with open(os.path.join(HERE, name), 'w', encoding='utf-8-sig' if bom else 'utf-8', newline='') as f:
        f.write(text)


# A - Lines: semicolon delimiter, BOM, quoted value with a line break and doubled quotes, blank row,
#     group code, unknown client, new line without client, invalid date, decimal comma + dd/mm/yyyy, duplicate id
write('ex_a_lines_semicolon.csv', '\r\n'.join([
    'Line_Id__c;Name;Client_Code__c;Booking_Geography__c;CurrencyIsoCode;Start_Date__c;End_Date__c;FD_Amount__c;DMT_Comments__c',
    f'EXL001;EX Customer Code;{CUSTOMER};ES;EUR;2026-01-01;2027-01-01;1000;"Line one, with comma"',
    f'EXL002;EX Group Code;{GROUP.lower()};ES;EUR;2026-01-01;2027-01-01;1000;"Two\r\nlines and ""quotes"""',
    'EXL003;EX Unknown Client;XXNOPE999;ES;EUR;2026-01-01;2027-01-01;1000;rejected',
    'EXL004;EX No Client;;ES;EUR;2026-01-01;2027-01-01;1000;rejected',
    f'EXL005;EX Bad Date;{CUSTOMER};ES;EUR;next year;2027-01-01;1000;rejected',
    '',
    f'EXL006;EX Comma Decimal;{CUSTOMER};ES;EUR;01/11/2026;01/11/2027;1500,50;dd/mm/yyyy',
    f'EXL007;EX Duplicate;{CUSTOMER};ES;EUR;2026-01-01;2027-01-01;1000;dup',
    f'EXL007;EX Duplicate;{CUSTOMER};ES;EUR;2026-01-01;2027-01-01;1000;dup',
]) + '\r\n', bom=True)

# B - XLSX Lines file with real date cells
try:
    from openpyxl import Workbook
    wb = Workbook(); ws = wb.active
    ws.append(['Line_Id__c', 'Name', 'Client_Code__c', 'Booking_Geography__c', 'CurrencyIsoCode', 'Start_Date__c', 'End_Date__c'])
    ws.append(['EXX001', 'EX Xlsx Line', CUSTOMER, 'ES', 'EUR', datetime.date(2026, 3, 15), datetime.date(2027, 3, 15)])
    wb.save(os.path.join(HERE, 'ex_b_lines.xlsx'))
except ImportError:
    print('openpyxl missing: ex_b_lines.xlsx not built')

# D - products on existing lines (PW01 replaced, PW03 kept), first and second RLT file, LPI file for the wrong zone
write('ex_d_lines.csv', 'Line_Id__c\nTEST4851PW01\nTEST4851PW03\n')
write('ex_d_rlt_first.csv', 'DMT_Line__r.Line_Id__c,DMT_Risk_Type__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c\n'
      'TEST4851PW01,Derivatives,111111,0,30\nTEST4851PW01,Depos,222222,30,365\nTEST4851PW01,Repos,333333,0,90\n')
write('ex_d_rlt_second.csv', 'DMT_Line__r.Line_Id__c,DMT_Risk_Type__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c\n'
      'TEST4851PW01,Derivatives,444444,0,365\nTEST4851PW01,Depos,555555,365,730\n')
write('ex_d_lpi.csv', 'Line__r.Line_Id__c,Product_Code_Value__c,DMT_DerivativeRestriction__c\nTEST4851PW01,DERI,FALSE\n')

# E - volume: 30 new lines (2 chunks of the Add OU batch, 3 chunks of Process), one with an invalid risk type
lines = ['Line_Id__c,Name,Client_Code__c,Booking_Geography__c,CurrencyIsoCode']
terms = ['DMT_Line__r.Line_Id__c,DMT_Risk_Type__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c']
for i in range(1, 31):
    lid = f'EXV{i:03d}'
    lines.append(f'{lid},EX Volume {i},{CUSTOMER},ES,EUR')
    terms.append(f'{lid},{"BadType" if i == 15 else "Derivatives"},100000,0,365')
write('ex_e_lines.csv', '\n'.join(lines) + '\n')
write('ex_e_rlt.csv', '\n'.join(terms) + '\n')

# F - status rules
write('ex_f_lines.csv', '\n'.join([
    'Line_Id__c,Name,Client_Code__c,Booking_Geography__c,CurrencyIsoCode,g_line_status_type__c',
    f'EXS001,EX Status DR,{CUSTOMER},ES,EUR,DR',
    f'EXS002,EX Status AP,{CUSTOMER},ES,EUR,AP',
    f'EXS003,EX Status PR No Product,{CUSTOMER},ES,EUR,PR',
    f'TEST4851PW03,PW New Line Three,{CUSTOMER},ES,EUR,AP',
    f'TEST4851PW02,PW Closed Renamed,{CUSTOMER},ES,EUR,',
]) + '\n')
write('ex_f_rlt.csv', 'DMT_Line__r.Line_Id__c,DMT_Risk_Type__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c\n'
      'EXS001,Derivatives,100000,0,365\nEXS002,Derivatives,100000,0,365\n')
write('ex_f_retry_lines.csv', 'Line_Id__c\nEXS003\n')
write('ex_f_retry_rlt.csv', 'DMT_Line__r.Line_Id__c,DMT_Risk_Type__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c\n'
      'EXS003,Derivatives,100000,0,365\n')
# F - Ready to close, products only (Other Products line)
write('ex_f_rtc_lines.csv', 'Line_Id__c\nTEST4851OL01\n')
write('ex_f_rtc_products.csv', 'Line_Id__c,DMT_RiskLineTermId__c,DMT_Risk_Line_Term__c DMT_Amount__c,DMT_Risk_Line_Term__c DMT_Init_Term__c,DMT_Risk_Line_Term__c DMT_End_Term__c\n'
      'TEST4851OL01,TEST4851OL01-03,1000000,2026-01-01,2027-01-01\n')

# G - reopen toast: a Proposal line with finished passport features, renamed, no code column
write('ex_g_lines.csv', 'Line_Id__c,Name\nESCD26LIN00002786ES,Line IBERDROLA 2026 espana renamed\n')

# H - Other Products lines the org rules would not let leave Draft (flagged 'Draft (not ...)', not moved) + controls
write('ex_h_lines.csv', '\n'.join([
    'Line_Id__c,Name,Client_Code__c,Booking_Geography__c,CurrencyIsoCode,DMT_LastLevelId__c,DMT_Risk_Line_Term__c DMT_Amount__c,g_line_status_type__c',
    f'EXH001,EX Stay Group Client,{GROUP},ES,EUR,20200,100000,PR',
    f'EXH002,EX Stay No Amount,{CUSTOMER},ES,EUR,20200,,PR',
    f'EXH003,EX Stay No Risk Type,{CUSTOMER},ES,EUR,,100000,PR',
    f'EXH004,EX Moves Proposal,{CUSTOMER},ES,EUR,20200,100000,PR',
    f'EXH005,EX Moves Approval,{CUSTOMER},ES,EUR,20200,100000,AP',
]) + '\n')
write('ex_h_rlt.csv', 'DMT_Line__r.Line_Id__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c\n'
      + ''.join(f'EXH00{i},100000,2026-01-01,2027-01-01\n' for i in range(1, 6)))
# H2 - same with a real customer (Subsidiary): one reason only, the save rule on the type of risk, and the moves
write('ex_h2_lines.csv', '\n'.join([
    'Line_Id__c,Name,Client_Code__c,Booking_Geography__c,CurrencyIsoCode,DMT_LastLevelId__c,DMT_Risk_Line_Term__c DMT_Amount__c,g_line_status_type__c',
    f'EXH012,EX Stay No Amount,{SUBSIDIARY},ES,EUR,20200,,PR',
    f'EXH013,EX Fails No Risk Type,{SUBSIDIARY},ES,EUR,,100000,PR',
    f'EXH014,EX Moves Proposal,{SUBSIDIARY},ES,EUR,20200,100000,PR',
    f'EXH015,EX Moves Approval,{SUBSIDIARY},ES,EUR,20200,100000,AP',
]) + '\n')
write('ex_h2_rlt.csv', 'DMT_Line__r.Line_Id__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c\n'
      + ''.join(f'EXH01{i},100000,0,365\n' for i in range(2, 6)))  # terms in days (DMT_Line_Helper.createConsolidatedLine)
# H4 - EXH015 (Draft, code AP) gets terms in days, then Update Line Status moves it to Approval
write('ex_h4_lines.csv', 'Line_Id__c\nEXH015\n')
write('ex_h4_rlt.csv', 'DMT_Line__r.Line_Id__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c\nEXH015,100000,0,365\n')
# H3 - Update Line Status on the Draft lines of H: EXH002 gets a customer and an amount (sent), EXH001 still Group (not sent)
write('ex_h3_lines.csv', 'Line_Id__c,Client_Code__c,DMT_Risk_Line_Term__c DMT_Amount__c\n'
      f'EXH001,{GROUP},100000\nEXH002,{SUBSIDIARY},100000\n')

# I - results on screen: moved, stays in Draft, Approval, products below the line amount (fails in the background),
#     a date as term (rejected on save); I2 fixes EXI002 for the Update Line Status button
write('ex_i_lines.csv', '\n'.join([
    'Line_Id__c,Name,Client_Code__c,Booking_Geography__c,CurrencyIsoCode,DMT_LastLevelId__c,DMT_Risk_Line_Term__c DMT_Amount__c,g_line_status_type__c',
    f'EXI001,EX Result Moves,{SUBSIDIARY},ES,EUR,20200,100000,PR',
    f'EXI002,EX Result Stays No Amount,{SUBSIDIARY},ES,EUR,20200,,PR',
    f'EXI003,EX Result Approval,{SUBSIDIARY},ES,EUR,20200,100000,AP',
    f'EXI004,EX Result Products Below Amount,{SUBSIDIARY},ES,EUR,20200,900000,PR',
    f'EXI005,EX Result Term As Date,{SUBSIDIARY},ES,EUR,20200,100000,PR',
]) + '\n')
write('ex_i_rlt.csv', 'DMT_Line__r.Line_Id__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c\n'
      'EXI001,100000,0,365\nEXI002,100000,0,365\nEXI003,100000,0,365\nEXI004,100000,0,365\nEXI005,100000,2026-01-01,365\n')
write('ex_i2_lines.csv', 'Line_Id__c,DMT_Risk_Line_Term__c DMT_Amount__c\nEXI002,100000\n')
# J - same as I with new lines (EXJ004 now flagged: products below the line amount); J2 = button without code column
with open(os.path.join(HERE, 'ex_i_lines.csv'), encoding='utf-8') as f:
    write('ex_j_lines.csv', f.read().replace('EXI', 'EXJ'))
with open(os.path.join(HERE, 'ex_i_rlt.csv'), encoding='utf-8') as f:
    write('ex_j_rlt.csv', f.read().replace('EXI', 'EXJ'))
write('ex_j2_lines.csv', 'Line_Id__c,DMT_Risk_Line_Term__c DMT_Amount__c\nEXJ002,100000\n')

# M - Treasury: comment change in Approval (not saved, ApprovalProcessDataEdit) vs allowed edit, Prospect client closed Won,
#     lower case code with a gap in the terms (stays in Draft)
PROSPECT = 'P00000000000078'   # Prospect Subsidiary Prospect Group test3 (record type Prospect_Subsidiary)
write('ex_m_lines.csv', 'Line_Id__c,DMT_Comments__c\nEXS002,Comment change in Approval\nTEST4851PW03,Comment with approval edit allowed\n')
write('ex_m2_lines.csv', '\n'.join([
    'Line_Id__c,Name,Client_Code__c,Booking_Geography__c,CurrencyIsoCode,g_line_status_type__c',
    f'EXM010,EX Prospect Closed Won,{PROSPECT},ES,EUR,CW',
    f'EXM011,EX Lower Case Code With Gap,{SUBSIDIARY},ES,EUR,pr',
]) + '\n')
write('ex_m2_rlt.csv', 'DMT_Line__r.Line_Id__c,DMT_Risk_Type__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c\n'
      'EXM010,Derivatives,100000,0,365\nEXM011,Derivatives,100000,0,30\nEXM011,Derivatives,100000,90,365\n')
# N - Other Products: Proposal line renamed with terms that have a gap (not saved), new line with overlapping terms (stays)
write('ex_n_lines.csv', 'Line_Id__c,Name\nEXJ001,EX Result Moves Renamed\n')
write('ex_n_rlt.csv', 'DMT_Line__r.Line_Id__c,DMT_Risk_Type__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c\n'
      'EXJ001,Derivatives,100000,0,30\nEXJ001,Derivatives,100000,90,365\n')
write('ex_n2_lines.csv', 'Line_Id__c,Name,Client_Code__c,Booking_Geography__c,CurrencyIsoCode,DMT_LastLevelId__c,DMT_Risk_Line_Term__c DMT_Amount__c,g_line_status_type__c\n'
      f'EXN020,EX Overlapping Terms,{SUBSIDIARY},ES,EUR,20200,200000,PR\n')
write('ex_n2_rlt.csv', 'DMT_Line__r.Line_Id__c,DMT_Risk_Type__c,DMT_Amount__c,DMT_Init_Term__c,DMT_End_Term__c\n'
      'EXN020,Derivatives,100000,0,365\nEXN020,Derivatives,100000,30,90\n')

# C - pasted table (tab separated)
write('ex_c_paste.tsv', f'Line_Id__c\tName\tClient_Code__c\nEXP001\tEX Pasted\t{CUSTOMER}\n')
print('files built in', HERE)
