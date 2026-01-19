/**
* ____________________________________________________________________________
* Mock class to be used in web service calls of the test classes
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-05-08
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('PMD.StdCyclomaticComplexity')
public with sharing class RPP_GSheets_Mock_Generator implements HttpCalloutMock {
    // Implement this interface method
    @SuppressWarnings('PMD.NcssMethodCount')
    public HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if (req.getEndpoint().equals('https://accounts.google.com/o/oauth2/token') && req.getMethod() == 'POST') {
            System.debug('RPP_GSheets_Mock_Generator - respond - req 1: ' + req);
            System.assertEquals('https://accounts.google.com/o/oauth2/token', req.getEndpoint());
            System.assertEquals('POST', req.getMethod());
            // fake session response
            res.setBody('{' +
                '"access_token": "ya29.Gn0eBCQBlfaT2smQCjuw2RoYndiOcyGy7he_-BWrHmqy4kNHSkc-mjaY_Y0mf_lvpsSM3QWBJk5WbdjAUifJNRRAMozPB0bH8hVvxw1X8wyJzg4REuVUfIanv-i1nIU5YjPAd57HDRHk6-Jzoi5dDW89esjGmlUv-8QMgJ8hTg",' +
                '"expires_in": 3600,' +
                '"token_type": "Bearer"' +
            '}');
            res.setStatusCode(200);
        } else if (req.getEndpoint().contains('gdrive/v3') && req.getMethod() == 'GET') {
            System.debug('RPP_GSheets_Mock_Generator - respond - req 2: ' + req);
            System.assert(req.getEndpoint().contains('gdrive/v3'));
            System.assertEquals('GET', req.getMethod());
            res.setStatusCode(200);
            res.setBody(
                '{"kind": "drive#fileList",'+
                '"incompleteSearch": false,'+
                '"files": ['+
                '{'+
                '"kind": "drive#file",'+
                '"id": "1djxT7xNjK4upqXaxw2s15hYUvQEUOwISODCa7RodzPw",'+
                '"name": "Calculadora RPP - OK 1",'+
                '"mimeType": "application/vnd.google-apps.spreadsheet",'+
                '"teamDriveId": "0AAw1d4hdTYIBUk9PVA",'+
                '"driveId": "0AL6XBCQvntEnUk9PVA"'+
                '}'+
                ']'+
                '}');
        } else if (req.getEndpoint().contains('gdrive/v3') && req.getMethod() == 'PATCH') {
            System.debug('RPP_GSheets_Mock_Generator - respond - req 3: ' + req);
            System.assert(req.getEndpoint().contains('gdrive/v3'));
            System.assertEquals('PATCH', req.getMethod());
            res.setStatusCode(200);
            res.setBody(
                '{"kind": "drive#fileList",'+
                '"incompleteSearch": false,'+
                '"files": ['+
                '{'+
                '"kind": "drive#file",'+
                '"id": "1djxT7xNjK4upqXaxw2s15hYUvQEUOwISODCa7RodzPw",'+
                '"name": "Calculadora RPP - OK 1",'+
                '"mimeType": "application/vnd.google-apps.spreadsheet",'+
                '"teamDriveId": "0AAw1d4hdTYIBUk9PVA",'+
                '"driveId": "0AL6XBCQvntEnUk9PVA"'+
                '}'+
                ']'+
                '}');
        } else if (req.getEndpoint().contains('gsheets/v4') && req.getEndpoint().contains('values:batchGet') && req.getMethod() == 'GET') {
            System.debug('RPP_GSheets_Mock_Generator - respond - req 4: ' + req);
            System.assert(req.getEndpoint().contains('gsheets/v4') );
            System.assertEquals('GET', req.getMethod());
            res.setStatusCode(200);
            res.setBody(
            '{"spreadsheetId":"1djxT7xNjK4upqXaxw2s15hYUvQEUOwISODCa7RodzPw","valueRanges":'+
                '[{"range":"SALESFORCE!A1:S1","majorDimension":"ROWS","values":[["TYPE","FIELD01","FIELD02","FIELD03","FIELD04","FIELD05","FIELD06","FIELD07","FIELD08","FIELD09","FIELD10","FIELD11","FIELD12","FIELD13","FIELD14","FIELD15","FIELD16","FIELD17","FIELD18"]]},'+
                 '{"range":"SALESFORCE!A2:Z300","majorDimension":"ROWS","values":[["CALCULATOR","RPP Calculator - Test 01 - OK","B12312323","Empresa cedente"],'+
                                                                                 '["CONFIG","A","A","70,00%","26","9%","100%","CC-","A+","9%","3%","Sí","95%","Aseguradora A","A","100.000","40%","1,00"],'+
                                                                                 '["DEBTOR","8","FR12345678","959800N60CEGKTATBG10","TECH DATA CORPORATION","EUR","516.726.895,67","516.726.895,67"],'+
                                                                                 '["DEBTOR","","","","Total"]'+
                ']}]}');
        } else if (req.getEndpoint().contains('gsheets/v4/spreadsheets') && !req.getEndpoint().contains('values:batchGet') && req.getMethod() == 'GET') {
            System.debug('RPP_GSheets_Mock_Generator - respond - req 5: ' + req);
            System.assert(req.getEndpoint().contains('gsheets/v4/spreadsheets') );
            System.assertEquals('GET', req.getMethod());
            res.setStatusCode(200);
            res.setBody(
            '{"spreadsheetId":"1djxT7xNjK4upqXaxw2s15hYUvQEUOwISODCa7RodzPw","properties":{"title":"Calculadora RPP - OK 1","locale":"es_ES","autoRecalc":"ON_CHANGE","timeZone":"Europe/Madrid","defaultFormat":{"backgroundColor":{"red":1,"green":1,"blue":1},"padding":{"top":2,"right":3,"bottom":2,"left":3},"verticalAlignment":"BOTTOM","wrapStrategy":"OVERFLOW_CELL","textFormat":{"foregroundColor":{},"fontFamily":"arial,sans,sans-serif","fontSize":10,"bold":false,"italic":false,"strikethrough":false,"underline":false,"foregroundColorStyle":{"rgbColor":{}}},"backgroundColorStyle":{"rgbColor":{"red":1,"green":1,"blue":1}}},"spreadsheetTheme":{"primaryFontFamily":"Arial","themeColors":[{"colorType":"ACCENT2","color":{"rgbColor":{"red":0.91764706,"green":0.2627451,"blue":0.20784314}}},{"colorType":"ACCENT1","color":{"rgbColor":{"red":0.25882354,"green":0.52156866,"blue":0.95686275}}},{"colorType":"ACCENT5","color":{"rgbColor":{"red":1,"green":0.42745098,"blue":0.003921569}}},{"colorType":"TEXT","color":{"rgbColor":{}}},{"colorType":"BACKGROUND","color":{"rgbColor":{"red":1,"green":1,"blue":1}}},{"colorType":"ACCENT4","color":{"rgbColor":{"red":0.20392157,"green":0.65882355,"blue":0.3254902}}},{"colorType":"ACCENT3","color":{"rgbColor":{"red":0.9843137,"green":0.7372549,"blue":0.015686275}}},{"colorType":"LINK","color":{"rgbColor":{"red":0.06666667,"green":0.33333334,"blue":0.8}}},{"colorType":"ACCENT6","color":{"rgbColor":{"red":0.27450982,"green":0.7411765,"blue":0.7764706}}}]}},"sheets":[{"properties":{"sheetId":0,"title":"SALESFORCE","index":0,"sheetType":"GRID","gridProperties":{"rowCount":5,"columnCount":19}}},{"properties":{"sheetId":1674473923,"title":"EA_Export_Dia","index":1,"sheetType":"GRID","gridProperties":{"rowCount":5,"columnCount":18}}}],"spreadsheetUrl":"https://docs.google.com/spreadsheets/d/1djxT7xNjK4upqXaxw2s15hYUvQEUOwISODCa7RodzPw/edit"}');
        } else {
            System.debug('RPP_GSheets_Mock_Generator - respond - req 6: ' + req);
            res.setBody('{}');
            res.setStatusCode(404);
        }
        return res;
    }
}