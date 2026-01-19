@isTest
global class PRFL_MockResponseGenerator implements HttpCalloutMock{
    
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            // Respuesta del mock
            res.setBody('{'+
                '"data": {'+
                    '"userCode": "T033546",'+
                    '"name": "John",'+
                    '"surname": "Doe",'+
                    '"secondSurname": "Smith",'+
                    '"workCountry": "ESP",'+
                    '"email": "john.doe.testing1@example.com",'+
                    '"organizationalUnit": {'+
                        '"unitCode": "00080132",'+
                        '"unitName": "CIB SUSTAINABILITY & BUSINESS SOL",'+
                        '"parentCode1": "00003906",'+
                    '"parentCode2": "00003906",'+
                        '"parentCode3": "00025539"'+
                    '},'+
                    '"roles": ['+
                        '{'+
                            '"name": "Salesforce_basico",'+
                        '"uuaa": "ESCD",'+
                            '"resources": ['+
                                '{'+
                                    '"resourceCode": "208145",'+
                                    '"name": "GTB_Tier",'+
                                    '"resourceType": "Etiqueta",'+
                                    '"value": "GTB_Tier"'+
                                '}'+
                            ']'+
                        '},'+
                        '{'+
                            '"name": "sAdmin",'+
                            '"uuaa": "ESCD",'+
                            '"resources": []'+
                        '}'+
                    '],'+
                    '"attributeSet": ['+
                        '{'+
                            '"setCode": "6359",'+
                            '"attributes": ['+
                                '{'+
                                    '"attributeName": "PricingGTB",'+
                                    '"attributeValue": "TRUE"'+
                                '},'+
                                '{'+
                                    '"attributeName": "LicenciaSalesforce",'+
                                    '"attributeValue": "TRUE"'+
                                '}'+
                            ']'+
                        '}'+
                    ']'+
                '}'+
            '}');
            res.setStatusCode(200);
        return res;

    }
}