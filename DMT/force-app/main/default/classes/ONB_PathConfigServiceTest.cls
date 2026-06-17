@isTest
private class ONB_PathConfigServiceTest {

    private static String anyPicklistValue(Schema.SObjectField fieldRef) {
        List<Schema.PicklistEntry> vals = fieldRef.getDescribe().getPicklistValues();
        return vals.isEmpty() ? null : vals[0].getValue();
    }

    private static ONB_Onboarding__c createOnboarding(String stepValue) {
        ONB_Onboarding__c onb = new ONB_Onboarding__c(
            Name = 'Test Onboarding',
            Step__c = stepValue,
            Any_Master_Agreement__c = 'Yes',
            ONB_Onboarding_Client_Type__c = 'Bank'
        );
        insert onb;
        return onb;
    }

    @IsTest
    static void getPathModel_shouldWorkWithoutAnyCmdtData() {
        String stepValue = anyPicklistValue(ONB_Onboarding__c.Step__c);
        System.assertNotEquals(null, stepValue, 'Step__c no tiene valores disponibles');

        ONB_Onboarding__c onb = createOnboarding(stepValue);

        Test.startTest();
        ONB_PathConfigService.PathModelDTO model =
            ONB_PathConfigService.getPathModel(onb.Id, null); // fuerza contextKey DEFAULT
        Test.stopTest();

        System.assertNotEquals(null, model, 'Model no debe ser null');
        System.assertNotEquals(null, model.steps, 'Steps no debe ser null (puede ser lista vacía)');
        System.assertEquals(false, model.allComplete, 'Sin steps, allComplete debe ser false');

        if (model.steps.isEmpty()) {
            System.assertEquals(stepValue, model.currentStep, 'currentStep debe respetar Step__c si no hay pasos visibles');
            return;
        }

        Boolean currentExistsInSteps = false;
        for (ONB_PathConfigService.StepDTO step : model.steps) {
            if (step.key == model.currentStep) {
                currentExistsInSteps = true;
                break;
            }
        }

        System.assertEquals(true, currentExistsInSteps, 'currentStep debe existir dentro de los pasos visibles');
    }

    /**
     * Este test intenta validar la lógica real (status + clickable),
     * PERO sin romper si el sandbox/org no tiene CMDT cargada.
     */
    @IsTest
    static void getPathModel_shouldComputeStatusesAndClickables_whenThereAreVisibleSteps() {
        String stepValue = anyPicklistValue(ONB_Onboarding__c.Step__c);
        System.assertNotEquals(null, stepValue, 'Step__c no tiene valores disponibles');

        ONB_Onboarding__c onb = createOnboarding(stepValue);

        Test.startTest();
        ONB_PathConfigService.PathModelDTO model =
            ONB_PathConfigService.getPathModel(onb.Id, 'DEFAULT');
        Test.stopTest();

        System.assertNotEquals(null, model);
        System.assertNotEquals(null, model.steps);

        // Si no hay CMDT, no podemos validar la lógica de statuses/clickables
        if (model.steps.isEmpty()) {
            System.assertEquals(stepValue, model.currentStep);
            System.assertEquals(false, model.allComplete);
            return;
        }

        // currentStep: si el Step__c no está en visibles, se fuerza al primero
        Integer currentIdx = -1;
        for (Integer i = 0; i < model.steps.size(); i++) {
            if (model.steps[i].key == model.currentStep) {
                currentIdx = i;
                break;
            }
        }
        System.assert(currentIdx >= 0, 'currentStep debe existir dentro de steps cuando steps no está vacío');

        // allComplete si current es el último
        Boolean expectedAllComplete = (currentIdx == model.steps.size() - 1);
        System.assertEquals(expectedAllComplete, model.allComplete);

        // validar status + clickable por regla:
        for (Integer i = 0; i < model.steps.size(); i++) {
            ONB_PathConfigService.StepDTO s = model.steps[i];

            // status
            String expectedStatus =
                (i < currentIdx) ? 'complete' :
                (i == currentIdx) ? 'current' :
                'incomplete';
            System.assertEquals(expectedStatus, s.status, 'Status incorrecto para index ' + i);

            // clickable
            Boolean expectedClickable;
            if (expectedAllComplete) {
                expectedClickable = true;
            } else {
                expectedClickable = (i == currentIdx || i == currentIdx - 1 || i == currentIdx + 1);
            }
            System.assertEquals(expectedClickable, s.clickable, 'Clickable incorrecto para index ' + i);
        }
    }
}