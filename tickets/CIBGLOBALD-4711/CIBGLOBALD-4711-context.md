# CIBGLOBALD-4711 - context (written 2026-10-22, end of CIBGLOBALD-4713 session)

Branch name (work repo): feature/CIBGLOBALD-4711-dmt-nuevo-boton-para-descargar-detalle-de-profitability-en-csv-desde-epsilon
Personal repo branch: 4711 (created from main, which already contains 4713).

## Requirement (summary of the ticket)
New button in the Opportunity Passport Profitability modal, label similar to Profitability Detail. On click: call the Epsilon service profitability_download_detail (BBVA service catalogue; functional/technical contact: Fátima Paterna) with the parameters that identify the profitability calculation of the Opportunity being viewed, get the structured response and download a .csv automatically (transform to CSV if the service returns structured data, keeping Epsilon's information and column order). No recalculation, nothing stored. Errors: no calculation available, empty response, failed call -> clear message, never an empty/wrong file. QA: CSV valid, columns/values equal the response, special characters, separators, number formats.

## Dependency on CIBGLOBALD-4713: YES
4713 (deployed to DMT_TCM_DEV, 3 commits in the work repo) rebuilt exactly the components this ticket touches. Developing 4711 on a base without 4713 means conflicts in the same files:
- LWC dmt_passport_modal: in Profitability mode the footer is built from a list of actions (getter footerActions: name, label, iconName, variant, disabled; handler handleFooterAction) precisely so new buttons are one more entry. Today: Close (neutral) + Download PDF (brand, utility:download). The Profitability Detail button goes there (next to Download PDF) unless the user decides otherwise.
- LWC dmt_profitability_view (new in 4713): body of the modal. Emits statuschange {isLoading, canDownload}; has hasResults (profitability.results not empty) for the no-calculation case; errorMessage banner at the top of the modal; downloadPdf() already contains the browser download pattern (Blob + temporary anchor + revokeObjectURL; mobile via NavigationMixin). Reuse the same pattern for text/csv.
- Apex DMT_Profitability_utils (the modal's controller, without sharing since 4713): already holds the other Profitability callout, callExternalOrchestrators (service DMTO_ExternalOrchestrators via DMT_Utils.callService -> DMT_HPG_Utils.callService -> iaso.GBL_Integration_GenericService.invoke). The new download callout belongs next to it.
Work repo: create the 4711 branch from the 4713 branch (git pull origin 4713), and mark 4711 depends on 4713 in Jira.

## What is known in the org (DMT_TCM_DEV, 2026-10-22)
- No iaso__GBL_integration_service__mdt record for profitability_download_detail / Epsilon exists yet. Existing related ones: DMTO_EvaluationOpportunity (Passport evaluation, returns the features incl. Profitability Engine), DMTO_ExternalOrchestrators (External RWA), DMT_ProfitabilityMatrix.
- Callout helper: DMT_HPG_Utils.callService(serviceName, Map request) adds userId (federation identifier), serializes JSON, calls iaso.GBL_Integration_GenericService.invoke; in tests returns the mock from the service record (iaso__Mock_LTA__c, iaso__Http_Method__c), so the new service record needs a mock body for unit tests.
- Profitability data of the modal = saved Passport JSON (Passport__c.DMT_Passport_Save__c), feature with name Profitability Engine (motorDesc). Feature keys: active, autoWorkflowRequest, id, indicatorId, motorDesc, name, orderNumber, passportSanction, profitability, profitabilityEngineApply, requiredColorCapability, requiredType, stateName. profitability.audit = rorcThreshold, raroecThreshold, opportunityId (= Opportunity.DMT_Opp_Id__c), isError, engineVersion. There is NO calculation/execution id in the saved JSON: the only identifiers available are the Opportunity external Id (DMT_Opp_Id__c / audit.opportunityId), engineVersion and the productIds in results. Whether that is enough for profitability_download_detail must come from the contract.
- Calculation eligibility already coded: DMT_PassportProfitabilityProcessor.evaluateProfitabilityFeature (state GREEN/YELLOW/RED and no validations).

## Open questions (need the contract / Fátima Paterna, or the user)
1. Contract of profitability_download_detail: HTTP method, URL/iaso configuration, input parameters (Opportunity Id only? engine version? product ids? user?), response format (CSV text vs JSON), columns, order, separators, decimal format, encoding.
2. Is the service reachable from DMT_TCM_DEV (and which environment), and who creates the iaso__GBL_integration_service__mdt record (+ mock)?
3. Button label and place (proposal: footer, next to Download PDF, via footerActions).
4. CSV details if DMT builds it: separator (; or ,), UTF-8 BOM for Excel, number format.

## Conventions to apply (from CLAUDE.md / memory)
Retrieve fresh before editing; callout doc comments name service, iaso record, call path and LWC; exception logging via DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(...)) + flush; tests with DMT_Test_DataFactory (generatePassport exists since 4713) and Assert class; per-ticket manifest DMT/manifest/CIBGLOBALD-4711-package.xml; technical note rules (no pending section, exact conditions and queries, org-agnostic QA steps).
