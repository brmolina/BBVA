@isTest
global class PRFL_RoleUsersMockResponseGenerator implements HttpCalloutMock{

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            // Respuesta del mock
            res.setBody('{'+
            '"data": {'+
                '"uuaa": "ESCD",'+
                '"name": "Salesforce_basico",'+
                '"users": ['+
                    '{'+
                        '"userCode": "T013977",'+
                        '"name": "LEYDI MARCELA",'+
                        '"ou": "00023196",'+
                        '"surname1": "LAVERDE",'+
                        '"surname2": "CARRILLO"'+
                    '},'+
                    '{'+
                        '"userCode": "T007848",'+
                        '"name": "LEYDI MARIA",'+
                        '"ou": "00023196",'+
                        '"surname1": "DIAZ",'+
                        '"surname2": "ORTIZ"'+
                    '},'+
                    '{'+
                        '"userCode": "XP71098",'+
                        '"name": "LEYDI NICOL",'+
                        '"ou": "00024599",'+
                        '"surname1": "VILLON",'+
                        '"surname2": "MENDOZA"'+
                    '},'+
                    '{'+
                        '"userCode": "XE62644",'+
                        '"name": "LEYDIS",'+
                        '"ou": "00080463",'+
                        '"surname1": "QUINTERO",'+
                        '"surname2": "REGA"'+
                    '},'+
                    '{'+
                        '"userCode": "CE58446",'+
                        '"name": "LEYDY",'+
                        '"ou": "00023196",'+
                        '"surname1": "GOMEZ",'+
                        '"surname2": "GUERRERO"'+
                    '}'+
                ']'+
            '}'+
        '}');
            res.setStatusCode(200);
        return res;

    }
}