public class TXNM_DynamicPicklistMock implements HttpCalloutMock {
    public static HTTPResponse lastResponse;
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);

        String body = req.getBody();
        XmlHelper responseHelper = new XmlHelper();

        // --- 1. Mock CustomField with inline picklist
        if (body.contains('<met:type>CustomField</met:type>') && body.contains('Account.CustomInline__c')) {
            res.setBody(responseHelper.customFieldInline());
        }
        // --- 2. Mock CustomField with GlobalValueSet reference
        else if (body.contains('<met:type>CustomField</met:type>') && body.contains('Account.Key_global_value__c')) {
            res.setBody(responseHelper.customFieldWithGVS());
        }
        // --- 3. Mock GlobalValueSet
        else if (body.contains('<met:type>GlobalValueSet</met:type>')) {
            res.setBody(responseHelper.globalValueSet());
        }
        // --- 4. Mock StandardValueSet (Industry, LeadSource, etc.)
        else if (body.contains('<met:type>StandardValueSet</met:type>')) {
            res.setBody(responseHelper.standardValueSet());
        }
        // --- 5. Mock updateMetadata response (always succeed)
        else if (body.contains('<met:updateMetadata>')) {
            res.setBody(responseHelper.successResponse());
        }
        else if (body.contains('INVALID_SESSION_ID')) {
            res.setBody(responseHelper.invalidSession());
        }
        else {
            res.setBody(responseHelper.emptyResponse());
        }

        lastResponse = res;
        return res;
    }

    // --- XML snippets (kept static for readability) ---
    public class XmlHelper {
        public String successResponse() {
            return '<?xml version="1.0" encoding="UTF-8"?>' +
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<soapenv:Body><updateMetadataResponse><result><success>true</success></result></updateMetadataResponse></soapenv:Body></soapenv:Envelope>';
        }
        public String emptyResponse() {
            return '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope><soapenv:Body/></soapenv:Envelope>';
        }
        public String customFieldInline() {
            return '<?xml version="1.0" encoding="UTF-8"?>' +
            '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<env:Body>' +
            '<readMetadataResponse xmlns="http://soap.sforce.com/2006/04/metadata">' +
            '<result><records xsi:type="CustomField" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '<type>Picklist</type><label>Custom Inline</label>' +
            '<valueSet><valueSetDefinition>' +
            '<value><fullName>A</fullName><label>A</label><default>true</default></value>' +
            '<value><fullName>B</fullName><label>B</label><default>false</default></value>' +
            '</valueSetDefinition></valueSet>' +
            '</records><size>1</size></result>' +
            '</readMetadataResponse></env:Body></env:Envelope>';
        }
        public String customFieldWithGVS() {
            return '<?xml version="1.0" encoding="UTF-8"?>' +
            '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<env:Body>' +
            '<readMetadataResponse xmlns="http://soap.sforce.com/2006/04/metadata">' +
            '<result><records xsi:type="CustomField" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '<type>Picklist</type><label>GlobalField</label>' +
            '<valueSet><valueSetName>My_Global_Set</valueSetName></valueSet>' +
            '</records><size>1</size></result>' +
            '</readMetadataResponse></env:Body></env:Envelope>';
        }
        public String globalValueSet() {
            return '<?xml version="1.0" encoding="UTF-8"?>' +
            '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<env:Body>' +
            '<readMetadataResponse xmlns="http://soap.sforce.com/2006/04/metadata">' +
            '<result><records xsi:type="GlobalValueSet" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '<masterLabel>My GVS</masterLabel><sorted>false</sorted>' +
            '<customValue><fullName>A</fullName><label>A</label><default>true</default></customValue>' +
            '<customValue><fullName>B</fullName><label>B</label><default>false</default></customValue>' +
            '</records><size>1</size></result>' +
            '</readMetadataResponse></env:Body></env:Envelope>';
        }
        public String standardValueSet() {
            return '<?xml version="1.0" encoding="UTF-8"?>' +
            '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<env:Body>' +
            '<readMetadataResponse xmlns="http://soap.sforce.com/2006/04/metadata">' +
            '<result><records xsi:type="StandardValueSet" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '<standardValue><fullName>Banking</fullName><label>Banking</label><default>true</default></standardValue>' +
            '<standardValue><fullName>Tech</fullName><label>Tech</label><default>false</default></standardValue>' +
            '</records><size>1</size></result>' +
            '</readMetadataResponse></env:Body></env:Envelope>';
        }
        public String invalidSession() {
            return 'INVALID_SESSION_ID';
        }
    }
}