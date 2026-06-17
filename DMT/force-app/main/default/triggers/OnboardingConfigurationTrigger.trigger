trigger OnboardingConfigurationTrigger on Onboarding_Configuration__c (before insert, after update, after insert) {

  final OnboardingConfigurationTriggerHandler handler = OnboardingConfigurationTriggerHandler.getInstance();

  if (Trigger.isAfter) {
    if (Trigger.isInsert) {
      handler.newListGroupName(Trigger.new);
    }
    if (Trigger.isUpdate) {
      handler.updateListGroupName(Trigger.new, Trigger.oldMap);
    }
  }
}