@isTest
public class DES_CoreDocumentsExpedientFolders_Test {

    @isTest
    static void testGetExpedientFolders_Success200() {
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.getConfig('DMT');
        String serviceName = cfg.expedientFoldersServiceName;

        //Consultamos el JSON que está guardado en el Custom Metadata
        iaso__GBL_integration_service__mdt serviceDetails = [SELECT iaso__Mock_LTA__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName = :serviceName WITH SYSTEM_MODE LIMIT 1];

        //Deserializamos ese JSON en nuestro Wrapper para saber qué valores exactos debemos esperar
        DES_CoreDocumentsExpedientFolders.Wrapper expectedData = (DES_CoreDocumentsExpedientFolders.Wrapper) JSON.deserialize(serviceDetails.iaso__Mock_LTA__c,  DES_CoreDocumentsExpedientFolders.Wrapper.class);
        
        Test.startTest();
            Map<String, Object> requestParams = new Map<String, Object>{'param1' => 'value1'};
            DES_CoreDocumentsExpedientFolders.Wrapper result = DES_CoreDocumentsExpedientFolders.getExpedientFolders(requestParams, 'DMT');
        Test.stopTest();

        System.assertEquals(true, result.success, 'Success should be true for a 200 response');
        System.assertNotEquals(null, result.data, 'Data should not be null');
        System.assertEquals(expectedData.data[0].id, result.data[0].id, 'Data ID should match the MDT value');

        if (expectedData.data[0].businessCode != null) {
            System.assertEquals(expectedData.data[0].businessCode.folderCode, result.data[0].businessCode.folderCode, 'Business code should match');
        }
    }

    @isTest
    static void testGetExpedientFolders_NoContent204() {
        DES_CoreDocumentsUtils.overrideMockStatusCode = 204;
        DES_CoreDocumentsUtils.overrideMockResponseBody = '';
        
        Test.startTest();
            DES_CoreDocumentsExpedientFolders.Wrapper result = DES_CoreDocumentsExpedientFolders.getExpedientFolders(new Map<String, Object>(), 'DMT');
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Success should be true for a 204 response');
        System.assertEquals(null, result.data, 'Data should be null when there is no content');
    }
    
    @isTest
    static void testGetExpedientFolders_ErrorElse() {
        DES_CoreDocumentsUtils.overrideMockStatusCode = 500;
        DES_CoreDocumentsUtils.overrideMockResponseBody = 'Error Interno Simulado';
        
        Test.startTest();
            DES_CoreDocumentsExpedientFolders.Wrapper result = DES_CoreDocumentsExpedientFolders.getExpedientFolders(new Map<String, Object>(), 'DMT');
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Success should be false for a 500 response');
        System.assertEquals('Error Interno Simulado', result.errorMessage, 'Error message should match the response body');
    }

    @isTest
    static void testInnerClassesInstantiation() {
        DES_CoreDocumentsExpedientFolders.ProcessType pt = new DES_CoreDocumentsExpedientFolders.ProcessType();
        pt.id = '123';
        System.assertEquals('123', pt.id, 'ProcessType ID should be correctly assigned');

        DES_CoreDocumentsExpedientFolders.Status st = new DES_CoreDocumentsExpedientFolders.Status();
        st.name = 'Test';
        st.statusDate = Date.today();
        System.assertEquals('Test', st.name, 'Status name should be correctly assigned');
    }

    @isTest
    static void testWrapperPropertiesCoverage() {
        DES_CoreDocumentsExpedientFolders.NodeType node = new DES_CoreDocumentsExpedientFolders.NodeType();
        node.id = 'nt1';
        node.description = 'Test Node';
        System.assertEquals('nt1', node.id, 'NodeType ID should match');
        
        DES_CoreDocumentsExpedientFolders.Child childObj = new DES_CoreDocumentsExpedientFolders.Child();
        childObj.id = 'c1';
        childObj.nodeType = node;
        childObj.objectCode = 'objCode';
        childObj.objectName = 'objName';
        childObj.documentType = 'docType';
        childObj.contentLocator = 'locator';
        childObj.securityLevelInfo = new DES_CoreDocumentsExpedientFolders.SecurityLevelInfo();
        System.assertEquals('c1', childObj.id, 'Child ID should match');

        DES_CoreDocumentsExpedientFolders.SecurityLevelInfo secInfo = new DES_CoreDocumentsExpedientFolders.SecurityLevelInfo();
        secInfo.classificationLevel = 1;
        secInfo.securityLevel = 2;

        DES_CoreDocumentsExpedientFolders.BusinessCode bc = new DES_CoreDocumentsExpedientFolders.BusinessCode();
        bc.folderCode = 'fc1';
        
        DES_CoreDocumentsExpedientFolders.FolderInfo fi = new DES_CoreDocumentsExpedientFolders.FolderInfo();
        fi.objectName = 'obj';
        fi.creationDate = '2023-01-01';
        fi.creationUser = 'user1';
        
        DES_CoreDocumentsExpedientFolders.ProcessType pt = new DES_CoreDocumentsExpedientFolders.ProcessType();
        pt.id = 'pt1';
        
        DES_CoreDocumentsExpedientFolders.ProcessInfo pi = new DES_CoreDocumentsExpedientFolders.ProcessInfo();
        pi.id = 'pi1';
        pi.code = 'code1';
        pi.name = 'name1';
        pi.processType = pt;
        
        DES_CoreDocumentsExpedientFolders.Status st = new DES_CoreDocumentsExpedientFolders.Status();
        st.statusDate = Date.today();
        st.name = 'status1';

        DES_CoreDocumentsExpedientFolders.Data dataObj = new DES_CoreDocumentsExpedientFolders.Data();
        dataObj.id = 'd1';
        dataObj.businessCode = bc;
        dataObj.folderInfo = fi;
        dataObj.origin = 'origin';
        dataObj.processInfo = pi;
        dataObj.securityLevelInfo = secInfo;
        dataObj.status = st;
        dataObj.children = new List<DES_CoreDocumentsExpedientFolders.Child>{ childObj };
        dataObj.jwt = 'jwt1';

        DES_CoreDocumentsExpedientFolders.Links linksObj = new DES_CoreDocumentsExpedientFolders.Links();
        linksObj.first = '1';
        linksObj.last = '2';
        linksObj.previous = '3';
        linksObj.next = '4';
        
        DES_CoreDocumentsExpedientFolders.Pagination pagObj = new DES_CoreDocumentsExpedientFolders.Pagination();
        pagObj.links = linksObj;
        pagObj.page = 1;
        pagObj.pageSize = 10;
        pagObj.totalElements = 100;
        pagObj.totalPages = 10;

        DES_CoreDocumentsExpedientFolders.Wrapper mainWrapper = new DES_CoreDocumentsExpedientFolders.Wrapper();
        mainWrapper.data = new List<DES_CoreDocumentsExpedientFolders.Data>{ dataObj };
        mainWrapper.pagination = pagObj;
        mainWrapper.success = true;
        mainWrapper.errorMessage = 'none';
        
        System.assertEquals(true, mainWrapper.success, 'Wrapper success status should be true');
        System.assertEquals('nt1', mainWrapper.data[0].children[0].nodeType.id, 'Nested NodeType ID should match the assigned value');
    }
}