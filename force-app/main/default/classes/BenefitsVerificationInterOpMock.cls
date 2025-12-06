/**
 * @description       : Mock implementation for IBenefitsVerificationInterOp
 * @author            : wjeyaraj@salesforce.com
 * @group             : 
 * @last modified on  : 07-27-2021
 * @last modified by  : wjeyaraj@salesforce.com
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   07-17-2021   wjeyaraj@salesforce.com              1.0
**/
global class BenefitsVerificationInterOpMock implements healthcloudext.IBenefitsVerificationInterOp {
    private Map<String, healthcloudext.BenefitsVerificationResponse> benefitsVerificationResponseMap = new Map<String, healthcloudext.BenefitsVerificationResponse>();
    
    private BenefitVerificationMockDataGenerator mockDataGenerator = new BenefitVerificationMockDataGenerator();
    
    public BenefitsVerificationInterOpMock() {
        benefitsVerificationResponseMap = mockDataGenerator.generateBVResponseMap();
    }
    
    private healthcloudext.BenefitsVerificationResponse getDefaultResponse(String memberNumber, String groupNumber) {
        Boolean happyKey = true;
        if (memberNumber.startsWith('1')) {
            happyKey = false;
        }
        healthcloudext.BenefitsVerificationResponse response = benefitsVerificationResponseMap.get((happyKey ? mockDataGenerator.getHappyPathKey() : mockDataGenerator.getErrorKey()));
        
        return response;
    }
    
    public List<healthcloudext.BenefitsVerificationResponse> verifyBenefits(List<healthcloudext.BenefitsVerificationRequest> request) {
		List<healthcloudext.BenefitsVerificationResponse> responses = new List<healthcloudext.BenefitsVerificationResponse>();

        for (healthcloudext.BenefitsVerificationRequest r : request) {
            if (r != null) {
                healthcloudext.BenefitsVerificationResponse response = benefitsVerificationResponseMap.get(mockDataGenerator.getBenefitsItemKey(r.memberNumber, r.groupNumber));
                if (response == null) {
                    response = getDefaultResponse(r.memberNumber, r.groupNumber);
                }
                response.memberNumber = r.memberNumber;
                response.groupNumber = r.groupNumber;
                response.benefitsRequestId = r.benefitsRequestId;
                
                responses.add(response);
            }            
        }
        
        return responses;
    }
}