trigger OpportunityTriggerV1 on Opportunity (before insert, before update, after update) {

    switch on Trigger.operationType {
        when BEFORE_INSERT{
            OpportunityTriggerHandler.checkAccountForOpenOpps(Trigger.new);
          }
        when BEFORE_UPDATE {
        OpportunityTriggerHandler.errorHandler(Trigger.new);
      }

      when AFTER_UPDATE {
        OpportunityTriggerHandler.renewalOppty(Trigger.new, Trigger.newMap, Trigger.oldMap);
      }

      

    }
}