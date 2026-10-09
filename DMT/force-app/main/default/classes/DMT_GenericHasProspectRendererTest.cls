@isTest(seeAllData=false)
public class DMT_GenericHasProspectRendererTest {
    
    @isTest
    static void testRenderHtml_Opportunity_WithProspect() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.objectApiName = 'Opportunity';
        data.hasProspect = true;
        
        Test.startTest();
        DMT_GenericHasProspectRenderer renderer = new DMT_GenericHasProspectRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Opportunity'), 'Should mention Opportunity');
        System.assert(result.contains('PROSPECT'), 'Should contain PROSPECT message');
    }
    
    @isTest
    static void testRenderHtml_Line_WithoutProspect() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.objectApiName = 'DMT_Line__c';
        data.hasProspect = false;
        
        Test.startTest();
        DMT_GenericHasProspectRenderer renderer = new DMT_GenericHasProspectRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('<div></div>', result, 'Should return empty div');
    }
}