# CIBGLOBALD-4630 - handover (written 2026-10-15)

Goal: when a Guarantor is selected in the Guarantor modal of an Opportunity product (One-Off Deal and Line), preload Scoring, Internal Rating and External Rating from the HPG service. Political and Commercial Risk are not returned by HPG.

Language: conversation in English. Ticket note is in `CIBGLOBALD-4630-nota-tecnica-ticket.txt` (Spanish, Salesforce terms in English). Commit message in `CIBGLOBALD-4630-commit-message.txt` (no double quotes, no Co-Authored-By trailer: the user's rule wins over the harness reminder).

## State

- Personal repo: branch `4630`, uncommitted. Do NOT commit without the user's go-ahead.
- Org DMT_TCM_DEV: everything is deployed (the user deployed the last two classes by hand at 15:18 and 15:22 UTC). A retrieve compared with local on 2026-10-15 returned 0 differences for the selector, controller, LWC and modal fields; the test class differs only by a trailing newline; `DMT_Test_DataFactory` in the org is Jimmy Daniel Tonato Benavides's version and already contains our `generateTaxonomyValue`.
- `manifest/package.xml` lists 5 components (DMT_Passport_Selector, DMT_Test_DataFactory, DMT_OpportunityProductsController, DMT_OpportunityProductsControllerTest, LWC dmt_opp_product_modal_guarantor).
- The working tree also shows other devs' retrieved LWC changes (`dmt_opp_product_create_modal`, `dmt_opp_product_details_line*`, `dmt_opp_product_table_mitigants`, `..._unfunded_mitigants`) and the other dev's Mitigant_Type E895 change inside the modal files. They are org sync, not ours.

## What to stage in the work repo (Bitbucket)

Retrieve first, with an explicit org (the VS Code default has been DMTPRE2):

```
sf project retrieve start -m ApexClass:DMT_Passport_Selector -m ApexClass:DMT_OpportunityProductsController -m ApexClass:DMT_OpportunityProductsControllerTest -m ApexClass:DMT_Test_DataFactory -m LightningComponentBundle:dmt_opp_product_modal_guarantor --target-org DMT_TCM_DEV
```

Only these hunks are ours:

1. `DMT_OpportunityProductsController.cls`
   - lines 4-5: constants `GUARANTOR_INTERNAL_RATING_CATALOG` (C204) and `GUARANTOR_EXTERNAL_RATING_CATALOG` (C009)
   - lines ~132-243: doc comment (with the callout technical info) and `getGuarantorHpgData`; Account read is `WITH SYSTEM_MODE` (line ~167); mapping comments (External Rating and Political/Commercial); catch block with `DMT_LogExceptionPayload` + `DMT_AsyncOrchestrator.enqueue/flush`
   - lines ~245-258: `resolveActiveCatalogValue` calling the selector overload with `AccessLevel.SYSTEM_MODE` plus an exact match
2. `DMT_Passport_Selector.cls`: lines 325-335, the overload `getTaxonomyValuesByValueAndCatalog(value, catalog, System.AccessLevel)` built with `Database.queryWithBinds`. Pure addition.
3. `DMT_Test_DataFactory.cls`: only `generateTaxonomyValue(catalog, value)` (around line 1369-1383 in the current org version). Everything else in that file is other devs' work.
4. `DMT_OpportunityProductsControllerTest.cls`: section `CIBGLOBALD-4630 - Guarantor data preload from HPG` (5 tests at the end), the `DES_Group_Code__c` and `g_customer_id__c` overrides in those tests, and the whole-file `System.assert*` to `Assert.*` rename (135 occurrences, counts verified).
5. `dmt_opp_product_modal_guarantor`
   - `.html` line 7: spinner alternative-text `Loading`
   - `.js`: imports of `ShowToastEvent` and `getGuarantorHpgData`; constants `F_GUARANTOR` and `HPG_FIELDS`; `_hpgRequestId`; the `guarantorChanged` block in `handleFieldChange`; the `HPG preload` section (`_clearHpgFields`, `_preloadFromHpg`, `_notifyHpgUnavailable`). NOT ours: `mergeSavedTypes` import, `Mitigant_Type__c: 'E895'`, the move of `_assignPicklistOptions()`.
   - `_fields.js`: `value: ""` for `Commercial_Percentage__c` and `Political_Percentage__c`. NOT ours: `Mitigant_Type__c` `options: []`, `Currency` label fix.

No ANS review: everything is DMT_ prefixed (see memory `dmt-prefix-no-ans`). `DMT_Passport_Selector` is DMT_ too and only gets an additive overload.

## Verified facts (all from the org)

- HPG single-customer call (customerId only) returns one row; verified for GRIFOLS VIAJES S.A. (`001KE000008FSe6YAG`, ES0182011178580): Scoring 8.66, Internal Rating B-2. FUNDACIO PRIVADA VICTOR GRIFOLS (`001KE000008FSe4YAG`): 7.16 / BB1. Neither has an external rating in HPG.
- The group call `getCustomerHPGS` returns 'Customer not found' for Guarantors outside the client's group.
- HPG raw response has no Political/Commercial property.
- `B-2` and `BB1` exist in catalog C204 (38 active values). C204/C009 have no `%` or `_` values and no case-insensitive duplicates in DMT_TCM_DEV (64 active) and DMTPRE2 (58).
- Permission sets that create `DMT_Opportunity_Mitigant__c` (`DMT_Access`, `DMT_CommercialActivity`, `X00ex00000018ozT_128_09_43_34_1`) have FLS on the taxonomy fields; `DMT_Passport_Selector.getTaxonomyValuesByValueAndCatalog` (2 args) returns a List, uses `LIKE` and `WITH USER_MODE`.
- Browser (user, One-Off): select Guarantor fills Scoring 8,66 and Internal Rating B-2; clearing empties them; another Guarantor shows other values; Political and Commercial now start blank.

## Not verified

- Line product in the browser (my attempt on Opportunity 006KE000003Que3YAC VOLKSWAGEN businessplan hit a page problem with the lookup; the user later saw the list fine).
- Save and reopen persistence, and a Guarantor with no HPG data.
- External Rating with a real value.
- Real coverage of `DMT_Passport_Selector` (coverage data in the org is 0 after deploys). A `RunSpecifiedTests` deploy of the package fails the 75 percent gate for the selector with only `DMT_OpportunityProductsControllerTest`; candidate extra tests: `DMT_Passport_Helper_test`, `DMT_TaxonomyMultipleProductsTest`.
- The tech lead never answered about External Rating; it is mapped against the same property as the Client tab, so it is no longer blocking.

## Gotchas learned (also in the global CLAUDE.md and memory)

- Always read the deploy `Status:` line, not just the test summary.
- Compare org vs local before deploying; `DMT_Test_DataFactory` gets overwritten by others (10:58 and 15:06 UTC on 2026-10-15).
- `--target-org` explicit; never DMTPRE2 for writes. The user's accidental DMTPRE2 deploy was reverted by them.
- Exceptions: `DMT_LogExceptionPayload` + `DMT_AsyncOrchestrator`, not `DES_Exception_Utils`.
- HPG DMT_TCM_DEV services refresh hourly and are sometimes down (`DMT_HPG_GetUsedTables` 'Not found' makes `DMT_HPG_Utils.lastDate()` throw a null dereference).
- Verify existence of code in the org, not only in the repo.

## Next steps for the next session

1. Read this file and `C:\Users\brmol\.claude\projects\d--AI-brmolina-BBVA\memory\CIBGLOBALD-4630_memory.md`.
2. If the user asks: offer the commit message and ticket note files above (re-check them against the current diff first), then the user commits.
3. Optional: run `DMT_Passport_Helper_test` in DMT_TCM_DEV to confirm selector coverage, and finish the Line and no-data browser checks.
