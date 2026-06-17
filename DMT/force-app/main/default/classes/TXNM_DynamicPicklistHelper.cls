public with sharing class TXNM_DynamicPicklistHelper {
    public class MetadataApiException extends Exception {}

    // DTOs
    public class StandardValueSetInfo {
        public List<Pick> values = new List<Pick>();
    }
    public class GlobalValueSetInfo {
        public String masterLabel;
        public Boolean sorted = false;
        public List<Pick> values = new List<Pick>();
    }
    public class CustomFieldInfo {
        public String fieldType;           // Picklist / MultiselectPicklist / etc.
        public String fieldLabel;
        public String globalValueSetName;  // if using a GVS
        public List<Pick> values = new List<Pick>(); // inline values
    }
    public class Pick {
        public String apiName, label;
        public Boolean isDefault;
        public Pick(String apiName, String label, Boolean isDefault) {
            this.apiName = apiName; this.label = label; this.isDefault = (isDefault == true);
        }
    }

    // ===== PUBLIC READS =====

    public static StandardValueSetInfo readStandardValueSet(String nc, String apiVer, String svsName) {
        HttpRequest req = baseReq(nc, apiVer, 'readMetadata');
        req.setBody(envelope(
            '<met:readMetadata>' +
            '  <met:type>StandardValueSet</met:type>' +
            '  <met:fullNames>' + x(svsName) + '</met:fullNames>' +
            '</met:readMetadata>'
        ));
        HttpResponse res = send(req, 'readMetadata(SVS)', nc);
        Dom.Document doc = load(res);
        Dom.XmlNode root = doc.getRootElement();

        // If not found, return null
        if (!res.getBody().contains('<records')) return null;

        StandardValueSetInfo info = new StandardValueSetInfo();
        for (Dom.XmlNode n : findNodesByLocalName(root, 'standardValue')) {
            String fullName = childText(n, 'fullName');
            String label    = childText(n, 'label');
            Boolean deflt   = (childText(n, 'default') == 'true');
            if (!String.isBlank(fullName)) info.values.add(new Pick(fullName, label, deflt));
        }
        return info;
    }

    public static GlobalValueSetInfo readGlobalValueSet(String nc, String apiVer, String gvsName) {
        HttpRequest req = baseReq(nc, apiVer, 'readMetadata');
        req.setBody(envelope(
            '<met:readMetadata>' +
            '  <met:type>GlobalValueSet</met:type>' +
            '  <met:fullNames>' + x(gvsName) + '</met:fullNames>' +
            '</met:readMetadata>'
        ));
        HttpResponse res = send(req, 'readMetadata(GVS)', nc);
        Dom.Document doc = load(res);
        Dom.XmlNode root = doc.getRootElement();

        if (!res.getBody().contains('<records')) return null;

        Dom.XmlNode rec = findFirstByXsiType(root, 'GlobalValueSet');
        GlobalValueSetInfo info = new GlobalValueSetInfo();
        info.masterLabel = childText(rec, 'masterLabel');
        info.sorted = (childText(rec, 'sorted') == 'true');

        for (Dom.XmlNode n : findNodesByLocalName(rec, 'customValue')) {
            String fullName = childText(n, 'fullName');
            String label    = childText(n, 'label');
            Boolean deflt   = (childText(n, 'default') == 'true');
            if (!String.isBlank(fullName)) info.values.add(new Pick(fullName, label, deflt));
        }
        return info;
    }


    public static CustomFieldInfo readCustomField(String nc, String apiVer, String fullName) {
        HttpRequest req = baseReq(nc, apiVer, 'readMetadata');
        req.setBody(envelope(
            '<met:readMetadata>' +
            '  <met:type>CustomField</met:type>' +
            '  <met:fullNames>' + x(fullName) + '</met:fullNames>' +
            '</met:readMetadata>'
        ));
        HttpResponse res = send(req, 'readMetadata(CustomField)', nc);
        if (!res.getBody().contains('<records')) {
            return null; // not found
        }

        Dom.Document doc = load(res);
        Dom.XmlNode root = doc.getRootElement();
        Dom.XmlNode cfNode = findFirstByXsiType(root, 'CustomField');
        if (cfNode == null) cfNode = findFirstByLocalName(root, 'CustomField');
        if (cfNode == null) return null;

        CustomFieldInfo out = new CustomFieldInfo();
        out.fieldType  = childText(cfNode, 'type');
        out.fieldLabel = childText(cfNode, 'label');

        // ---- FIX HERE: detect global value set reference ----
        String gvsName = childText(cfNode, 'valueSetName');
        if (String.isBlank(gvsName)) {
            // Sometimes returned as <valueSet><valueSetName>MySet</valueSetName></valueSet>
            Dom.XmlNode vsNode = findFirstByLocalName(cfNode, 'valueSet');
            if (vsNode != null) {
                gvsName = childText(vsNode, 'valueSetName');
            }
        }

        // Normalize: ensure "__gvs" suffix
        if (!String.isBlank(gvsName) && !gvsName.endsWith('__gvs')) {
            gvsName += '__gvs';
        }
        out.globalValueSetName = gvsName;

        if (String.isBlank(out.globalValueSetName)) {
            // Inline picklist values
            for (Dom.XmlNode n : findNodesByLocalName(cfNode, 'value')) {
                String full = childText(n, 'fullName');
                String lab  = childText(n, 'label');
                Boolean def = (childText(n, 'default') == 'true');
                if (!String.isBlank(full)) out.values.add(new Pick(full, lab, def));
            }
        }

        return out;
    }



    // ===== PUBLIC UPDATES (replace entire list) =====

    public static void updateStandardValueSet(String nc, String apiVer, String svsName, List<TXNM_DynamicPicklistHandler.PickValue> values) {
        String valsXml = '';
        for (TXNM_DynamicPicklistHandler.PickValue v : values) {
            valsXml +=
            '  <met:standardValue>' +
            '    <met:fullName>' + x(v.apiName) + '</met:fullName>' +
            '    <met:label>'    + x(v.label)   + '</met:label>' +
            '    <met:default>'  + String.valueOf(v.isDefault) + '</met:default>' +
            '  </met:standardValue>';
        }
        HttpRequest req = baseReq(nc, apiVer, 'updateMetadata');
        req.setBody(envelope(
            '<met:updateMetadata>' +
            '  <met:metadata xsi:type="met:StandardValueSet">' +
            '    <met:fullName>' + x(svsName) + '</met:fullName>' +
                 valsXml +
            '  </met:metadata>' +
            '</met:updateMetadata>'
        ));
        HttpResponse res = send(req, 'updateMetadata(SVS)', nc);
        assertSuccess(res);
    }

    public static void updateGlobalValueSet(String nc, String apiVer, String gvsName, String masterLabel, Boolean sorted, List<TXNM_DynamicPicklistHandler.PickValue> values) {
        String valsXml = '';
        for (TXNM_DynamicPicklistHandler.PickValue v : values) {
            valsXml +=
            '  <met:customValue>' +
            '    <met:fullName>' + x(v.apiName) + '</met:fullName>' +
            '    <met:label>'    + x(v.label)   + '</met:label>' +
            '    <met:default>'  + String.valueOf(v.isDefault) + '</met:default>' +
            '    <met:isActive>true</met:isActive>' +   // present values are active
            '  </met:customValue>';
        }
        HttpRequest req = baseReq(nc, apiVer, 'updateMetadata');
        req.setBody(envelope(
            '<met:updateMetadata>' +
            '  <met:metadata xsi:type="met:GlobalValueSet">' +
            '    <met:fullName>'   + x(gvsName)     + '</met:fullName>' +
            (String.isBlank(masterLabel) ? '' : ('    <met:masterLabel>' + x(masterLabel) + '</met:masterLabel>')) +
            '    <met:sorted>'     + String.valueOf(sorted == true) + '</met:sorted>' +
                 valsXml +
            '  </met:metadata>' +
            '</met:updateMetadata>'
        ));
        HttpResponse res = send(req, 'updateMetadata(GVS)', nc);
        assertSuccess(res);
    }

    public static void updateCustomFieldValueSet(String nc, String apiVer, String fullName /* Object.Field */, String fieldLabel, String fieldType, List<TXNM_DynamicPicklistHandler.PickValue> values) {
        String valsXml = '';
        for (TXNM_DynamicPicklistHandler.PickValue v : values) {
            valsXml +=
            '  <met:value>' +
            '    <met:fullName>' + x(v.apiName) + '</met:fullName>' +
            '    <met:default>'  + String.valueOf(v.isDefault) + '</met:default>' +
            '    <met:label>'    + x(v.label)   + '</met:label>' +
            '  </met:value>';
        }
        HttpRequest req = baseReq(nc, apiVer, 'updateMetadata');
        req.setBody(envelope(
            '<met:updateMetadata>' +
            '  <met:metadata xsi:type="met:CustomField">' +
            '    <met:fullName>' + x(fullName)   + '</met:fullName>' +
            '    <met:label>'    + x(fieldLabel) + '</met:label>' +  // REQUIRED
            '    <met:type>'     + x(fieldType)  + '</met:type>'  +  // REQUIRED
            '    <met:valueSet>' +
            '      <met:valueSetDefinition>' +
                   valsXml +
            '        <met:sorted>false</met:sorted>' +
            '      </met:valueSetDefinition>' +
            '    </met:valueSet>' +
            '  </met:metadata>' +
            '</met:updateMetadata>'
        ));
        HttpResponse res = send(req, 'updateMetadata(CustomField)', nc);
        assertSuccess(res);
    }

    // ===== SOAP/HTTP helpers =====

    private static HttpRequest baseReq(String nc, String apiVer, String soapAction) {
        HttpRequest r = new HttpRequest();
        r.setTimeout(120000);
        r.setEndpoint('callout:' + nc + '/services/Soap/m/' + apiVer);
        r.setMethod('POST');
        r.setHeader('Content-Type', 'text/xml; charset=UTF-8');
        r.setHeader('SOAPAction', '"' + soapAction + '"');
        return r;
    }

    private static String envelope(String bodyInnerXml) {
        return
'<?xml version="1.0" encoding="UTF-8"?>' +
'<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" ' +
'              xmlns:met="http://soap.sforce.com/2006/04/metadata" ' +
'              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
'  <env:Header>' +
'    <met:SessionHeader><met:sessionId>{!$Credential.OAuthToken}</met:sessionId></met:SessionHeader>' +
'  </env:Header>' +
'  <env:Body>' +
       bodyInnerXml +
'  </env:Body>' +
'</env:Envelope>';
    }

    private static HttpResponse send(HttpRequest req, String tag, String nc) {
        Http h = new Http();
        HttpResponse res = h.send(req);

        // Metadata SOAP returns a SOAP Fault with INVALID_SESSION_ID (often HTTP 500).
        if (res.getBody() != null && res.getBody().contains('INVALID_SESSION_ID')) {
            // Prime the same Named Credential to trigger token refresh
            HttpRequest prime = new HttpRequest();
            prime.setEndpoint('callout:' + nc + '/services/data/v61.0/limits');
            prime.setMethod('GET');
            try {
                res = h.send(prime);
            } catch (Exception e) { /* ignore */ }

            // Retry SOAP once
            res = h.send(req);
        }

        if (res.getStatusCode() != 200 && res.getStatusCode() != 500) {
            throw new MetadataApiException(tag + ' failed: ' + res.getStatus() + ' ' + res.getBody());
        }
        return res;
    }

    private static Boolean assertSuccess(HttpResponse res) {
        // Success is indicated by <success>true</success> somewhere in the result.
        if (!res.getBody().contains('<success>true</success>')) {
            throw new MetadataApiException('Metadata operation did not succeed: ' + res.getBody());
        } else {
            return true;
        }
    }

    private static Dom.Document load(HttpResponse res) {
        Dom.Document d = new Dom.Document(); d.load(res.getBody()); return d;
    }

    // ===== XML helpers =====
    private static String x(String s) {
        if (s == null) return '';
        return s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
                .replace('"','&quot;').replace('\'','&apos;');
    }

    private static Dom.XmlNode findFirstByXsiType(Dom.XmlNode node, String desiredLocalType) {
        String t = node.getAttributeValue('type', 'http://www.w3.org/2001/XMLSchema-instance');
        if (t != null) {
            Integer i = t.lastIndexOf(':');
            String local = (i == -1) ? t : t.substring(i + 1);
            if (local == desiredLocalType) return node;
        }
        for (Dom.XmlNode c : node.getChildElements()) {
            Dom.XmlNode found = findFirstByXsiType(c, desiredLocalType);
            if (found != null) return found;
        }
        return null;
    }

    private static List<Dom.XmlNode> findNodesByLocalName(Dom.XmlNode node, String local) {
        List<Dom.XmlNode> found = new List<Dom.XmlNode>();
        if (endsWithLocal(node.getName(), local)) found.add(node);
        for (Dom.XmlNode c : node.getChildElements()) found.addAll(findNodesByLocalName(c, local));
        return found;
    }

    private static String childText(Dom.XmlNode n, String local) {
        if (n == null) return null;
        for (Dom.XmlNode c : n.getChildElements()) {
            if (endsWithLocal(c.getName(), local)) return c.getText();
        }
        return null;
    }


    // Utility: find the first child element with a given local name
    private static Dom.XmlNode findFirstByLocalName(Dom.XmlNode node, String local) {
        if (node == null) return null;
        for (Dom.XmlNode c : node.getChildElements()) {
            if (endsWithLocal(c.getName(), local)) {
                return c;
            }
        }
        return null;
    }

    // Utility: test if {prefix:localName} ends with the local part
    private static Boolean endsWithLocal(String qName, String local) {
        if (qName == null) return false;
        Integer idx = qName.lastIndexOf(':');
        return (idx == -1 ? qName : qName.substring(idx+1)) == local;
    }

    // Helper: very small XML extractor for a single tag
    public static String getCompactLayout(String rtMetadataXml) {
        if (String.isBlank(rtMetadataXml)) return null;
        String openTag = '<compactLayoutAssignment>';
        String closeTag = '</compactLayoutAssignment>';

        Integer start = rtMetadataXml.indexOf(openTag);
        if (start < 0) return null;
        start += openTag.length();

        Integer ending = rtMetadataXml.indexOf(closeTag, start);
        if (ending < 0 || ending <= start) return null;

        return rtMetadataXml.substring(start, ending).trim();
    }

    public static HttpResponse updateRecordTypePicklistValues(
        String nc,
        String apiVer,
        String objectApiName,
        String recordTypeDeveloperName,
        String picklistFieldApiName,
        List<TXNM_DynamicPicklistHandler.PickValue> values,
        String recordTypeLabel,
        String description
    ){
        String fullName = objectApiName + '.' + recordTypeDeveloperName;

        // --- Build values XML
        String valsXml = '';
        for (TXNM_DynamicPicklistHandler.PickValue v : values) {
            valsXml +=
            '    <met:values>' +
            '      <met:fullName>' + x(v.apiName) + '</met:fullName>' +
            '      <met:default>'  + String.valueOf(v.isDefault) + '</met:default>' +
            '    </met:values>';
        }

        // --- Read existing RecordType (so we can preserve the current compact layout, etc.)
        HttpRequest req1 = baseReq(nc, apiVer, 'readMetadata');
        req1.setBody(envelope(
            '<met:readMetadata>' +
            '  <met:type>RecordType</met:type>' +
            '  <met:fullNames>' + x(fullName) + '</met:fullNames>' +
            '</met:readMetadata>'
        ));
        HttpResponse res1 = send(req1, 'readMetadata(RecordType)', nc);

        // Try to extract <compactLayout>Current_Name</compactLayout> from the RecordType XML (if present)
        // We search with and without the "met:" prefix to be tolerant of namespace prefixes.
        String body = res1.getBody();
        String compactLayoutName = getCompactLayout(body);

        // --- Build metadata payload for update, reusing existing compact layout if we found one
        String metadataXml =
            '<met:metadata xsi:type="met:RecordType">' +
            '  <met:fullName>' + x(fullName) + '</met:fullName>' +
            '  <met:active>true</met:active>' +
            '  <met:label>' + x(recordTypeLabel) + '</met:label>' +
            '  <met:description>' + x(description) + '</met:description>';

        if (compactLayoutName != null) {
            metadataXml += '  <met:compactLayoutAssignment>' + x(compactLayoutName) + '</met:compactLayoutAssignment>';
        }

        metadataXml +=
            '  <met:picklistValues>' +
            '    <met:picklist>' + x(picklistFieldApiName) + '</met:picklist>' +
                valsXml +
            '  </met:picklistValues>' +
            '</met:metadata>';
        HttpRequest req = baseReq(nc, apiVer, 'updateMetadata');
        req.setBody(envelope('<met:updateMetadata>' + metadataXml + '</met:updateMetadata>'));
        HttpResponse res = send(req, 'updateMetadata(RecordType)', nc);
        assertSuccess(res);
        return res;
    }

    // Update ONE record type’s allowed values for ONE picklist field
}