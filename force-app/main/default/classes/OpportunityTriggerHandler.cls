public with sharing class OpportunityTriggerHandler {
        public static void errorHandler(List<Oppportunity> oppList){
            for(Opportunity opp : oppList){
            if(account.NumberOfEmployees <= 0 || account.NumberOfEmployees == Null){
                            opp.NumberOfEmployees.addError('Please enter atleast one employee');
                        }
                    }
                }
    }
