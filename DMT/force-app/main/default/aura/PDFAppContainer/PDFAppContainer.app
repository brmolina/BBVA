<aura:application description="AppContainer que lanza el Component PDF correspondiente en funcion del recordId recibido" 
                  implements="force:hasRecordId,force:hasSObjectName"> <!-- extends="force:slds" -->   
    
    <aura:if isTrue="{!v.sObjectName == 'Inside_information_form__c'}">
        <c:PDFOpportunityIP recordId="{!v.recordId}"/>
    <aura:set attribute="else">
        <!-- añadir if-else cada vez que se quiera lanzar un nuevo componente de otro sObjectName -->    
        <div class="uiOutputText">Error while generating PDF, please try again.<br/></div>
    </aura:set>
    </aura:if> 
    
</aura:application>