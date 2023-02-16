trigger OpportunityTriggerV1 on Opportunity (before update) {
    OpportunityTriggerHandler.errorHandler(Trigger.new);
}