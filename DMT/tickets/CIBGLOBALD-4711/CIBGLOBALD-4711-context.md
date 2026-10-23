# CIBGLOBALD-4711 - context (written 2026-10-22, end of CIBGLOBALD-4713 session)

Branch name (work repo): feature/CIBGLOBALD-4711-dmt-nuevo-boton-para-descargar-detalle-de-profitability-en-csv-desde-epsilon
Personal repo branch: 4711 (created from main, which already contains 4713).

## Original ticket description (verbatim, pasted by the user 2026-10-22)

```
feature/CIBGLOBALD-4711-dmt-nuevo-boton-para-descargar-detalle-de-profitability-en-csv-desde-epsilon

depends on

feature/CIBGLOBALD-4713-dmt-anadir-boton-para-descargar-el-modal-de-profitability-en-pdf

📋 Descripción

Se solicita incorporar un nuevo botón en el modal de Profitability (Passport) de Opportunity, que permita descargar en formato CSV el detalle de rentabilidad proporcionado por Epsilon.

Para ello, se deberá integrar el nuevo servicio de descarga de detalle de Profitability.

Referencia del servicio:
profitability_download_detail – Catálogo de Servicios BBVA - https://console.platform.bbva.com/app/P6ES/3297737/GLO/3297739/ns/central/p6es.gl.dsg/apx.du_online/profitability_download_detail

Contacto funcional/técnico: Fátima Paterna.

🔘 1. Nuevo botón de descarga

Añadir un botón en el modal de Profitability con una label similar a:

Profitability Detail

Al pulsarlo, se deberá:

Invocar el servicio profitability_download_detail de Epsilon.
Enviar los parámetros necesarios para identificar el cálculo de rentabilidad correspondiente.
Recuperar la información estructurada devuelta por el servicio.
Generar y descargar automáticamente un archivo .csv con dicha información.

📌 El botón deberá utilizar el contexto del cálculo de Profitability de la Opportunity que el usuario está consultando.

🔄 2. Integración y generación del CSV

Revisar el contrato del servicio para determinar:

Parámetros de entrada necesarios.
Estructura de la respuesta.
Si el servicio devuelve directamente el CSV o información estructurada que debe transformarse.
Columnas, cabeceras y formato definitivo del fichero.

Si el servicio devuelve datos estructurados, DMT deberá transformarlos a CSV, respetando la información y el orden definido por Epsilon.

La descarga no deberá modificar ni recalcular los resultados de Profitability almacenados.

⚠️ 3. Gestión de errores

Contemplar los casos en los que:

No exista un cálculo de Profitability disponible.
El servicio no devuelva información.
La llamada falle o devuelva un error.

En estos escenarios, mostrar un mensaje adecuado al usuario y evitar descargar archivos vacíos o incorrectos.

🧪 Validación QA
Abrir el modal de Profitability de una Opportunity con cálculo disponible.
Pulsar Profitability Detail y comprobar que se invoca correctamente el servicio de Epsilon.
Verificar que se descarga un fichero CSV válido.
Comprobar que las columnas y los valores coinciden con la respuesta del servicio.
Validar caracteres especiales, separadores y formatos numéricos.
Probar escenarios sin información y con errores de servicio.
Confirmar que la descarga no altera los resultados de Profitability.
```

## Platform console findings (screenshot, 2026-10-22)
- Resource profitability_download_detail: type apx.du_online (APX online transaction, backend), UA P6ES0000, application GLO (P6ES0000) Calculadora de Rentabilidad Ex-Ante (RORC y ROREC) IB&F y GTB. Description: Service that allows you to download the file with the details of the monthly amortization table. Created 16/01/2026 by Antonio Jesús Gil Reyes (T014446), updated 19/01/2026. Metadata {runtimes: {GLO: online}}.
- Same application, Banking runtimes (ASO.LINK = ASO REST APIs): DmtAssumptionV0, DmtDownloadDetailsV0, DmtProfitabilityV0, DmtProfitabilitycatalogsV0, etc. DmtDownloadDetailsV0 is the likely ASO API exposing this APX transaction.
- Org check (DMT_TCM_DEV): Salesforce already calls this application's ASO APIs. iaso record DMT_ProfitabilityMatrix = POST, custom setting DMT_ProfitabilityEndPoint_INT (iaso__GBL_Rest_Services_Url__c = https://aso-int-global.work-01.platform.bbva.com/dmt/v0/), path assumption (= DmtAssumptionV0), auth DMT_GrantingTicket, input #payload#. The new service most likely follows the same pattern (same custom setting + auth, path of DmtDownloadDetailsV0), to be confirmed from the ASO API spec.

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
Retrieve fresh before editing; callout doc comments name service, iaso record, call path and LWC; exception logging via DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(...)) + flush; tests with DMT_Test_DataFactory (generatePassport exists since 4713) and Assert class; per-ticket manifest DMT/tickets/CIBGLOBALD-4711/CIBGLOBALD-4711-package.xml; technical note rules (no pending section, exact conditions and queries, org-agnostic QA steps).

## Draft questions for Fátima Paterna (Epsilon, profitability_download_detail)
Send only what DMT cannot answer from the org (re-verify in a fresh session before sending). Spanish, no closing pleasantries.

1. Endpoint y entornos: URL o servicio del catálogo para cada entorno (desarrollo, pre, producción), método HTTP y si ya está publicado para el entorno de desarrollo de DMT. Quién da de alta la configuración iaso (iaso__GBL_integration_service__mdt) y con qué autenticación.
2. Parámetros de entrada: qué identifica el cálculo de rentabilidad. En Salesforce solo guardamos del último cálculo el opportunityId de Epsilon (el mismo que enviamos al motor, DMT_Opp_Id__c, p. ej. ESCD26OPP00004148ES), el engineVersion y los productId de cada resultado; no tenemos un id de cálculo o de ejecución. ¿Basta con el opportunityId (devuelve siempre el último cálculo) o hace falta otro id, fecha o versión? ¿Se envía también el usuario (enviamos userId con el federation identifier en todas las llamadas iaso)?
3. Respuesta: ¿devuelve el fichero CSV ya generado (texto o base64) o datos estructurados (JSON)? Ejemplo real de respuesta, incluidos los casos sin datos y de error (códigos HTTP y cuerpo).
4. Formato del CSV: columnas y orden definitivos, cabeceras, separador (punto y coma o coma), separador decimal y de miles, formato de fechas, codificación (UTF-8 con o sin BOM) y nombre de fichero esperado.
5. Volumen y tiempos: tamaño máximo esperado de la respuesta y tiempo de respuesta (límites de Salesforce: 12 MB de heap síncrono, 120 s de timeout por callout).
6. Comportamiento sin cálculo: qué responde el servicio si la Opportunity no tiene cálculo o si el cálculo es antiguo respecto a lo que muestra el Passport.

## ASO contract found in the console (2026-10-22)
- ASO resource DmtDownloadDetailsV0 (ASO.LINK), API DmtAPIDownloadDetailsV0 (Finances - DMT), SMC SMGG20260167, logical id dmtListDownloadDetailsV0, method version 0.145.0 (API global 0.151.0). Release 1.1.0 ACTIVE in DEV, INT and GRE.
- Operation: GET /dmt/v0/download-details (DmtGETDownloadDetailsDownloadDetailsV0). Description: Service that allows you to download the CSV file with the details of the monthly amortization table.
- Query parameters: opportunityId (mandatory, string, Id de oportunidad), opportunityVersion (optional, string, Version de oportunidad).
- Response 200 application/json: data (root node, OBJECT [] in the console) with file (mandatory, string, Archivo en base64) and opportunityVersion (mandatory, string). Documented codes: 200, 204, 400, 401, 403, 404, 500. One example in the spec.
- So: Epsilon builds the CSV, DMT only decodes base64 and downloads. Same host/custom setting as DMT_ProfitabilityMatrix (DMT_ProfitabilityEndPoint_INT .../dmt/v0/), path download-details?opportunityId=...
- Spec example (pasted by the user): {data: [{file: <base64>, opportunityVersion: 7}]}. data is a LIST with one element. The example base64 decodes to Lorem ipsum placeholder text, not a CSV: the spec does not confirm the CSV layout (separator, header, encoding). A real sample must come from Epsilon.
- Naming: profitability_download_detail is the backend APX transaction (apx.du_online); download-details is the ASO REST resource that Salesforce calls (same pattern as assumption). Both carry the same description (monthly amortization table); link between them still to be confirmed (Implementation History tab or Fatima).

## Deployed to DMT_TCM_DEV (2026-10-22, NoTestRun by user decision)
Manifest DMT/tickets/CIBGLOBALD-4711/CIBGLOBALD-4711-package.xml: CustomMetadata iaso__GBL_integration_service.DMT_ProfitabilityDownloadDetail; ApexClass DMT_Profitability_utils, DMT_Profitability_utilsTest, DMT_Test_DataFactory (org version + generatePassport of 4713, dropped again by another deploy); LWC dmt_profitability_view, dmt_passport_modal. Status Succeeded 6/6, org retrieve = local.
Then DMT_Profitability_utilsTest setup changed to generateGroupAccount + generateOpportunityForAccount (generateAccount sets Account.Past2_FY_Corp_Synd_Lending_amount__c, not createable for our user) and redeployed with RunSpecifiedTests: Succeeded, 23/23, DMT_Profitability_utils coverage 91% (23 of 265 uncovered).

## Deployment steps per org
Pre-deployment (before the metadata deploy; the custom setting record is data, it is not deployed, and the iaso record only references it by name, so it can exist first):
1. Create the iaso__GBL_Rest_Services_Url__c record for the service with that environment's ASO /dmt/v0/ URL, named DMT_ProfitabilityDownloadDetail_<ENV> after the environment it points to (_INT, _AUS, _PRO), like DMTO_Endpoint_AUS, DMT_HPGR_Endpoint_AUS and DMTO_Endpoint_PRO. Delivery files per target org (plain .txt, step by step, for the delivery manager): CIBGLOBALD-4711-<ORG>-pre-deployment.txt (custom setting record via Execute Anonymous) and CIBGLOBALD-4711-<ORG>-post-deployment.txt (Setup edit of the iaso record) for DMTPRE2, PREPRO, PRO. Steps 2 and 3 below are our own prerequisites before the release, not delivery manager steps.
2. Check in the BBVA console (GLO P6ES0000, resource DmtDownloadDetailsV0, tab Deployments) that the ASO API is deployed in the environment the org calls.
3. Check that Epsilon granted the APX transaction profitability_download_detail to the technical user of that org's granting ticket; otherwise the service answers HTTP 500 technicalError 01211008#EL USUARIO NO TIENE PERMISOS PARA EJECUTAR LA TRANSACCION (visible in iaso__GBL_Application_Log__c, Name DMT_ProfitabilityDownloadDetail, when iaso__Enable_Log__c is on).

Post-deployment (the iaso record is deployed with the DMT_TCM_DEV values):
4. In the iaso record DMT_ProfitabilityDownloadDetail (iaso__GBL_integration_service__mdt) set iaso__Custom_Setting__c to the record created in step 1 and iaso__Authentication_Service__c to the same value DMT_ProfitabilityMatrix uses in that org.

### DMT_TCM_DEV (development sandbox: configured during development, no pre- or post-deployment steps)
- Custom setting: DMT_ProfitabilityDownloadDetail_INT, iaso__Url__c https://aso-int-global.work-01.platform.bbva.com/dmt/v0/, iaso__Enable_Log__c true (created 2026-10-22).
- iaso record: iaso__Custom_Setting__c DMT_ProfitabilityDownloadDetail_INT, iaso__Authentication_Service__c DMT_GrantingTicket (as deployed).
- ASO: DmtDownloadDetailsV0 1.1.0 ACTIVE in INT.
- Epsilon permission: NOT granted yet for USLHPG01 (consumerID 30000026). Raised through Diego.

### DMTPRE2
- Custom setting: create DMT_ProfitabilityDownloadDetail_AUS, iaso__Url__c https://aso-aus-global.work-01.platform.bbva.com/dmt/v0/, iaso__Enable_Log__c true (DMT_ProfitabilityEndPoint, used by DMT_ProfitabilityMatrix there, has the same URL with log on).
- Checked 2026-10-22: DMTPRE2 holds endpoint records for INT, AUS, PRO (aso-backend-global.live-01) and a dev host, but 20 of its 21 DMT iaso records point to AUS records (exception DMT_GetLeveragedLending -> DMT_HPGR_Endpoint, INT URL); authentication DMT_GrantingTicketAUS (DMT_OpportunityCodes_Bulk: HPG_GrantingTicketAUS). DMTPRE2 = AUS.
- iaso record: iaso__Custom_Setting__c DMT_ProfitabilityDownloadDetail_AUS, iaso__Authentication_Service__c DMT_GrantingTicketAUS (value of DMT_ProfitabilityMatrix in DMTPRE2 on 2026-10-22).
- ASO: check DmtDownloadDetailsV0 in AUS (not seen in the console on 2026-10-22: ACTIVE only in DEV, INT, GRE).
- Epsilon permission: check for the technical user of DMT_GrantingTicketAUS.

### PREPRO
- Checked 2026-10-22 (queries run by the user): every DMT iaso record points to an AUS endpoint (DMT_HPGR_Endpoint_AUS, DMTO_Endpoint_AUS, DMTO_Endpoint_RISKPOSITION_AUS, DMTO_Endpoint_RISKREASSIGN_AUS, or DMT_ProfitabilityEndPoint / DMTO_GetSnapshotEvaluationVersions / DMTO_PostSnapshotVersions, which hold AUS URLs). DMT_ProfitabilityMatrix -> DMT_ProfitabilityEndPoint (https://aso-aus-global.work-01.platform.bbva.com/dmt/v0/, log on), auth DMT_GrantingTicketAUS. PREPRO = AUS, same as DMTPRE2.
- Custom setting: create DMT_ProfitabilityDownloadDetail_AUS, iaso__Url__c https://aso-aus-global.work-01.platform.bbva.com/dmt/v0/, iaso__Enable_Log__c true.
- iaso record: iaso__Custom_Setting__c DMT_ProfitabilityDownloadDetail_AUS, iaso__Authentication_Service__c DMT_GrantingTicketAUS (custom setting DMT_GrantingTicket_AUS, technical user USLHPG01).
- ASO: same as DMTPRE2, check DmtDownloadDetailsV0 in AUS.
- Epsilon permission: technical user USLHPG01 (same as INT).

### PRO (values decided 2026-10-23 from the PREPRO/DMTPRE2 records; user: if they fail, delivery will see it)
- Custom setting: DMT_ProfitabilityDownloadDetail_PRO, iaso__Url__c https://aso-backend-global.live-01.platform.bbva.com/dmt/v0/ (host copied from DMTO_Endpoint_PRO = https://aso-backend-global.live-01.platform.bbva.com/dmto/v0/; DMTO_Endpoint_RISKPOSITION / RISKREASSIGN use the same host), iaso__Enable_Log__c true.
- iaso record: iaso__Custom_Setting__c DMT_ProfitabilityDownloadDetail_PRO, iaso__Authentication_Service__c DMT_GrantingTicketPRO (exists in PREPRO: custom setting GrantingTicketsGlobal, technical user USLHPG02).
- ASO: DmtDownloadDetailsV0 must be deployed in PRO; Epsilon permission for USLHPG02.

### Not part of 4711
- DMT_Test_DataFactory: generatePassport comes from CIBGLOBALD-4713 (redeployed to DMT_TCM_DEV on 2026-10-22 only because a factory refactor dropped it).
