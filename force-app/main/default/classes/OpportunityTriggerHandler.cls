public with sharing class OpportunityTriggerHandler {
        public static void errorHandler(List<Opportunity> oppList){
            List<OpportunityLineItem> productList = [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId IN :oppList];
            Map<Id,SObject> productMap = new Map<Id,SObject>();
            for(OpportunityLineItem oppProduct: productList){
                productMap.put(oppProduct.OpportunityId , oppProduct);
            }
            for(Opportunity opp : oppList){
                if(opp.Probability > 10 && !productMap.containsKey(opp.Id)){
                            opp.addError('Please enter at least one product for this opportunity');
                        }
                    }
                }

        public static void renewalOppty(List<Opportunity> newOpptyList,Map<Id,Opportunity> newOpptyMap, Map<Id,Opportunity> oldOpptyMap) {
            List<OpportunityLineItem> productList = [SELECT Id, TotalPrice, OpportunityId, Product2Id,PricebookEntryId,Quantity FROM OpportunityLineItem WHERE OpportunityId IN :newOpptyList];
            
            List<Opportunity> renewalOppList = new List<Opportunity>();
            for (Id oppId : newOpptyMap.keySet()) {
                Opportunity newOpp = newOpptyMap.get(oppId);
                Opportunity oldOpp = oldOpptyMap.get(oppId);
                if (newOpp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                    Opportunity renewalOppty = new Opportunity();
                    renewalOppty.Name = 'Renewal: ' + newOpp.Name;
                    renewalOppty.StageName = 'Value Proposition';
                    renewalOppty.ParentOpportunity__c = newOpp.Id;
                    renewalOppty.AccountId = newOpp.AccountId;
                    renewalOppty.Amount = newOpp.Amount;
                    renewalOppty.CloseDate = newOpp.CloseDate.addYears(1);
                    renewalOppty.Type = newOpp.Type;
                    renewalOppty.LeadSource = newOpp.LeadSource;
                    renewalOppty.Description = newOpp.Description;
                    
                    renewalOppList.add(renewalOppty);
                    System.debug(renewalOppty);
                }
            }
            if (renewalOppList.size() > 0) {
                insert renewalOppList;
            }
            List<Opportunity> insertedOpptys = [SELECT Id, ParentOpportunity__c FROM Opportunity WHERE Id IN :renewalOppList];
            System.debug(insertedOpptys);

            List<OpportunityLineItem> renewalProducts = new List<OpportunityLineItem>();
            if(insertedOpptys.size() > 0){
                for(Opportunity insertedOpp: insertedOpptys){
                        for(OpportunityLineItem product: productList){
                            if(insertedOpp.ParentOpportunity__c == product.OpportunityId){
                            OpportunityLineItem renewalProduct = new OpportunityLineItem();
                            renewalProduct.OpportunityId = insertedOpp.Id;
                            renewalProduct.Product2Id = product.Product2Id;
                            renewalProduct.PricebookEntryId = product.PricebookEntryId;
                            renewalProduct.Quantity = product.Quantity;
                            renewalProduct.TotalPrice = product.TotalPrice;
                            System.debug(renewalProduct);
                            renewalProducts.add(renewalProduct);
                            }
                            
                        }
                    }
                }
            
            if(renewalProducts.size()>0){
                insert renewalProducts;
            }
        }
        }
                
    
