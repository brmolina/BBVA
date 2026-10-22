---
name: CIBGLOBALD-4711
description: "Profitability Detail button in the Profitability modal downloading a CSV from Epsilon service profitability_download_detail; depends on CIBGLOBALD-4713; analysis only, contract pending"
metadata:
  type: project
---

**Ticket (2026-10-22):** feature/CIBGLOBALD-4711-dmt-nuevo-boton-para-descargar-detalle-de-profitability-en-csv-desde-epsilon. New button (label like Profitability Detail) in the Opportunity Passport Profitability modal; calls Epsilon service profitability_download_detail (contact Fátima Paterna) and downloads a CSV; no recalculation; clear errors, no empty files.

**Depends on [[CIBGLOBALD-4713]]:** same components (dmt_passport_modal footerActions list, dmt_profitability_view download/error/status pattern, DMT_Profitability_utils callouts). Work repo: 4711 branch from 4713, Jira 'depends on 4713'. Personal repo: branch 4711 from main.

**Full context:** tickets/CIBGLOBALD-4711/CIBGLOBALD-4711-context.md (org findings: no iaso record for the service yet; saved JSON has no calculation id, only audit.opportunityId = DMT_Opp_Id__c and engineVersion; DMT_HPG_Utils.callService mock via iaso__Mock_LTA__c).

**Status:** analysis only. Nothing retrieved/edited/deployed. Blocked on the service contract (params, response format, columns, iaso config).
