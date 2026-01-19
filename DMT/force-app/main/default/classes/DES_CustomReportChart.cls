/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class DES_CustomReportChart {
    global DES_CustomReportChart() {

    }
    
    @AuraEnabled
    public static String getreport(String clientId){/*
        //Using report id for example purpose
						// '00O6E000000K3BX' -> ID del report "RAR de clientes"
						// '00O6E000000KCyx' -> ID del report "RAR de Cliente filtro por IdCliente"
        Report reportRec = [SELECT Id FROM Report WHERE Name = 'RAR de Cliente']; 


        
        // Get the report metadata
		Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportRec.Id);
		Reports.ReportMetadata reportMd = describe.getReportMetadata();
		
        // Override filter and run report
        Reports.ReportFilter filter = reportMd.getReportFilters()[0];
		filter.setValue(clientId);    
        Reports.ReportResults reportResult = Reports.ReportManager.runReport(reportRec.Id,reportMd, true);
        
        system.debug(' ------------> reportResult: ' + reportResult);    
        return JSON.serialize(reportResult);*/
        return null;
    }
}