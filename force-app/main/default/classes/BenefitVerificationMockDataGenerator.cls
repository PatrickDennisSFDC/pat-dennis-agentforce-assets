/**
 * @description       : BV Mock Data Generator class that is used to provide the mock implementation
 * @author            : wjeyaraj@salesforce.com
 * @group             : 
 * @last modified on  : 08-09-2021
 * @last modified by  : wjeyaraj@salesforce.com
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   07-17-2021   wjeyaraj@salesforce.com               1.0
**/

public class BenefitVerificationMockDataGenerator {  
	private static final String SEPARATOR = '~';

    public String getBenefitsItemKey(String memberNumber, String groupNumber) {
        return memberNumber;
    }
    
    public String getBenefitsItemLimitKey(String memberNumber, String groupNumber, String benefitsItemId) {
        return memberNumber + SEPARATOR + benefitsItemId;
    }
    
    public String getBenefitsItemLimitKey(String benefitsItemKey, String benefitsItemId) {
        return benefitsItemKey + SEPARATOR + benefitsItemId;
    }
    
    public String getHappyPathKey() {
        return '1234';
    }

    public String getErrorKey() {
        return '12345';
    }

    
    public Map<String, healthcloudext.BenefitsVerificationResponse> generateBVResponseMap() {
        System.debug('Inside generateBVResponseMap');
        List<String[]> benefitsResponseList = 
        	new List<String[]> {
                							// memberNumber, groupNumber, benefitsRequestId, isCoverageActive, BenefitPeriodStartDate, BenefitPeriodEndDate, errorResponse, jsonResponse
            					new String[] {'1234', 'crm123', '00005343', 'true', '2001/01/01', '2022/01/01', '', ''},
                				new String[] {'12345', 'crm123', '00005343', 'false', '', '', 'Invalid Member Number', ''},
                                new String[] {'234451', '{randomNumber(10000, 99999)}', '{randomNumber(10000, 99999)}', '{randomList(true, true, true, true, false)}', '{randomList(2020/01/01, 2020/04/01, 2020/08/01, 2020/12/01)}', '{randomList(2021/12/31, 2021/06/31, 2022/12/31, 2022/06/31)}', '', ''},
                                new String[] {'234452', '{randomNumber(10000, 99999)}', '{randomNumber(10000, 99999)}', '{randomList(true, true, true, true, false)}', '{randomList(2020/01/01, 2020/04/01, 2020/08/01, 2020/12/01)}', '{randomList(2021/12/31, 2021/06/31, 2022/12/31, 2022/06/31)}', '', ''},
                                new String[] {'234453', '{randomNumber(10000, 99999)}', '{randomNumber(10000, 99999)}', '{randomList(true, true, true, true, false)}', '{randomList(2020/01/01, 2020/04/01, 2020/08/01, 2020/12/01)}', '{randomList(2021/12/31, 2021/06/31, 2022/12/31, 2022/06/31)}', '', ''},
                                new String[] {'234454', '{randomNumber(10000, 99999)}', '{randomNumber(10000, 99999)}', '{randomList(true, true, true, true, false)}', '{randomList(2020/01/01, 2020/04/01, 2020/08/01, 2020/12/01)}', '{randomList(2021/12/31, 2021/06/31, 2022/12/31, 2022/06/31)}', '', ''},
                                new String[] {'234455', '{randomNumber(10000, 99999)}', '{randomNumber(10000, 99999)}', '{randomList(true, true, true, true, false)}', '{randomList(2020/01/01, 2020/04/01, 2020/08/01, 2020/12/01)}', '{randomList(2021/12/31, 2021/06/31, 2022/12/31, 2022/06/31)}', '', ''},
                                new String[] {'75656981', '{randomNumber(10000, 99999)}', '{randomNumber(10000, 99999)}', '{randomList(true, true, true, true, false)}', '{randomList(2020/01/01, 2020/04/01, 2020/08/01, 2020/12/01)}', '{randomList(2021/12/31, 2021/06/31, 2022/12/31, 2022/06/31)}', '', ''},
                                new String[] {'75656982', '{randomNumber(10000, 99999)}', '{randomNumber(10000, 99999)}', '{randomList(true, true, true, true, false)}', '{randomList(2020/01/01, 2020/04/01, 2020/08/01, 2020/12/01)}', '{randomList(2021/12/31, 2021/06/31, 2022/12/31, 2022/06/31)}', '', ''},
                                new String[] {'75656983', '{randomNumber(10000, 99999)}', '{randomNumber(10000, 99999)}', '{randomList(true, true, true, true, false)}', '{randomList(2020/01/01, 2020/04/01, 2020/08/01, 2020/12/01)}', '{randomList(2021/12/31, 2021/06/31, 2022/12/31, 2022/06/31)}', '', ''},
                                new String[] {'9765667', '{randomNumber(10000, 99999)}', '{randomNumber(10000, 99999)}', '{randomList(true, true, true, true, false)}', '{randomList(2020/01/01, 2020/04/01, 2020/08/01, 2020/12/01)}', '{randomList(2021/12/31, 2021/06/31, 2022/12/31, 2022/06/31)}', '', ''},
                                new String[] {'874565756', '{randomNumber(10000, 99999)}', '{randomNumber(10000, 99999)}', '{randomList(true, true, true, true, false)}', '{randomList(2020/01/01, 2020/04/01, 2020/08/01, 2020/12/01)}', '{randomList(2021/12/31, 2021/06/31, 2022/12/31, 2022/06/31)}', '', ''},
                                new String[] {'5689970', '{randomNumber(10000, 99999)}', '{randomNumber(10000, 99999)}', '{randomList(true, true, true, true, false)}', '{randomList(2020/01/01, 2020/04/01, 2020/08/01, 2020/12/01)}', '{randomList(2021/12/31, 2021/06/31, 2022/12/31, 2022/06/31)}', '', ''}
        					};
    	Map<String, List<List<String>>> benefitsItemMap = 
        	new Map<String, List<List<String>>> {
                '1234' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'additionnal info', 'true'},
                    new String[]{'2', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Out of Network additionnal info', 'false'},
                    new String[]{'3', 'Immunizations', '80', 'Immunizations', 'Flu Vaccine by Primary Care Physician', 'true'},
                    new String[]{'4', 'Urgent Care', 'UC', 'Urgent Care', 'Medical services and supplies provided by physicians or other healthcare providers for the treatment of an urgent medical condition or injury which requires medical attention.', 'true'},
                    new String[]{'5', 'Urgent Care', 'UC', 'Urgent Care', 'Out of Network - Medical services and supplies provided by physicians or other healthcare providers for the treatment of an urgent medical condition or injury which requires medical attention.', 'false'},
                    new String[]{'6', 'Emergency Services', '86', 'Emergency Services', 'Services provided by healthcare providers for the treatment of a sudden and unexpected medical condition or injury which requires immediate medical attention', 'false'}
        		},
                '234451' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', '{randomString(10, 100)}', '{randomList(true, true, true, true, false)}'}                    
        		},
                '234452' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', '{randomString(10, 100)}', '{randomList(true, true, true, true, false)}'}                    
        		},
                '234453' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', '{randomString(10, 100)}', '{randomList(true, true, true, true, false)}'}                    
        		},
                '234454' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', '{randomString(10, 100)}', '{randomList(true, true, true, true, false)}'}                    
        		},
                '234455' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', '{randomString(10, 100)}', '{randomList(true, true, true, true, false)}'}                    
        		},
                '75656981' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', '{randomString(10, 100)}', '{randomList(true, true, true, true, false)}'}                    
        		},
                '75656982' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', '{randomString(10, 100)}', '{randomList(true, true, true, true, false)}'}                    
        		},
                '75656983' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', '{randomString(10, 100)}', '{randomList(true, true, true, true, false)}'}                    
        		},
                '9765667' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', '{randomString(10, 100)}', '{randomList(true, true, true, true, false)}'}                    
        		},
                '874565756' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', '{randomString(10, 100)}', '{randomList(true, true, true, true, false)}'}                    
        		},
                '5689970' => new List<List<String>> {
                    			// benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
            		new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', '{randomString(10, 100)}', '{randomList(true, true, true, true, false)}'}                    
        		}
                
            };
    	
        Map<String, List<List<String>>> benefitsItemLimitMap = 
        	new Map<String, List<List<String>>> {
                '1234~1' => new List<List<String>> {
                    			// benefitCode, benefitValue, benefitMetricType, coverageLevel, limitNotes, termType, networkType, Count
        			new String[]{'C', '2800', 'Money', 'Family', 'Information About Limit', 'Calendar Year', 'IN', '1'},
                    new String[]{'C', '1300', 'Money', 'Family', 'Information About Limit', 'Remaining', 'IN', '1'},
                    new String[]{'C', '1200', 'Money', 'Individual', 'Information About Limit', 'Calendar Year', 'IN', '1'},
                    new String[]{'C', '1050', 'Money', 'Individual', 'Information About Limit', 'Remaining', 'IN', '1'},
                    new String[]{'C', '5400', 'Money', 'Family', 'Information About Limit', 'Calendar Year', 'OUT', '1'},
                    new String[]{'C', '1140', 'Money', 'Family', 'Information About Limit', 'Remaining', 'OUT', '1'},
                    new String[]{'C', '1800', 'Money', 'Individual', 'Information About Limit', 'Calendar Year', 'OUT', '1'},
                    new String[]{'C', '1300', 'Money', 'Individual', 'Information About Limit', 'Remaining', 'OUT', '1'},
                    new String[]{'C', '1300', 'Money', 'Individual', 'Information About Limit', 'Remaining', 'OUT', '1'},
                    new String[]{'B', '25', 'Money', 'Individual', 'Co-Payment', 'Day', 'IN', '1'},
                    new String[]{'B', '25', 'Money', 'Family', 'Co-Payment', 'Day', 'IN', '1'},
                    new String[]{'B', '50', 'Money', 'Individual', 'Co-Payment', 'Day', 'OUT', '1'},
                    new String[]{'B', '50', 'Money', 'Family', 'Co-Payment', 'Day', 'OUT', '1'},
                    // out of pocket
                    new String[]{'G', '3000', 'Money', 'Family', 'All Other In-Network Providers', 'Calendar Year', 'IN', '1'},
                    new String[]{'G', '1200', 'Money', 'Family', 'All Other In-Network Providers', 'Remaining', 'IN', '1'},
                    new String[]{'G', '8000', 'Money', 'Family', 'All Other In-Network Providers', 'Calendar Year', 'OUT', '1'},
                    new String[]{'G', '3500', 'Money', 'Family', 'All Other In-Network Providers', 'Remaining', 'OUT', '1'},
                    new String[]{'G', '300', 'Money', 'Individual', 'All Other In-Network Providers', 'Calendar Year', 'IN', '1'},
                    new String[]{'G', '120', 'Money', 'Individual', 'All Other In-Network Providers', 'Remaining', 'IN', '1'},
                    new String[]{'G', '800', 'Money', 'Individual', 'All Other In-Network Providers', 'Calendar Year', 'OUT', '1'},
                    new String[]{'G', '350', 'Money', 'Individual', 'All Other In-Network Providers', 'Remaining', 'OUT', '1'},
                    new String[]{'A', '20', 'Percentage', 'Family', 'Flu Vaccine in Office', 'Calendar Year', 'IN', '1'},
                    new String[]{'A', '35', 'Percentage', 'Family', 'Flu Vaccine in Office', 'Remaining', 'OUT', '1'}
                },
                '1234~2' => new List<List<String>> {
                    new String[]{'C', '2400', 'Money', 'Family', 'Information About Limit', 'Calendar Year', 'OUT', '1'}
        		},
                '1234~3' => new List<List<String>> {
                    new String[]{'B', '0', 'Money', 'Individual', 'Flu Vaccine by Primary Care Physician', 'Day', 'IN', '1'}
        		},
                '1234~4' => new List<List<String>> {
                    new String[]{'B', '25', 'Money', 'Individual', 'Urgent Care - In Network', 'Day', 'IN', '1'}
        		},
                '1234~5' => new List<List<String>> {
                    new String[]{'B', '100', 'Money', 'Individual', 'Urgent Care - Out Network', 'Day', 'OUT', '1'}
        		},
                '1234~6' => new List<List<String>> {
                    new String[]{'B', '500', 'Money', 'Individual', 'Emergency Care', 'Day', 'OUT', '1'}
        		},
                '234451~1' => new List<List<String>> {
                    new String[]{'{randomList(C, G, A)}', '{randomNumber(0, 999, 4, 0, false)}', 'Money', '{randomList(Family, Individual)}', '{randomString(10, 100)}', '{randomList(Calendar Year, Year to Date, Day, Month)}', '{randomList(IN, IN, IN, OUT)}', '{randomNumber(50, 100)}'}
        		},
                '234452~1' => new List<List<String>> {
                    new String[]{'{randomList(C, G, A)}', '{randomNumber(0, 999, 4, 0, false)}', 'Money', '{randomList(Family, Individual)}', '{randomString(10, 100)}', '{randomList(Calendar Year, Year to Date, Day, Month)}', '{randomList(IN, IN, IN, OUT)}', '{randomNumber(1, 10)}'}
        		},
                '234453~1' => new List<List<String>> {
                    new String[]{'{randomList(C, G, A)}', '{randomNumber(0, 999, 4, 0, false)}', 'Money', '{randomList(Family, Individual)}', '{randomString(10, 100)}', '{randomList(Calendar Year, Year to Date, Day, Month)}', '{randomList(IN, IN, IN, OUT)}', '{randomNumber(1, 10)}'}
        		},
                '234454~1' => new List<List<String>> {
                    new String[]{'{randomList(C, G, A)}', '{randomNumber(0, 999, 4, 0, false)}', 'Money', '{randomList(Family, Individual)}', '{randomString(10, 100)}', '{randomList(Calendar Year, Year to Date, Day, Month)}', '{randomList(IN, IN, IN, OUT)}', '{randomNumber(1, 10)}'}
        		},
                '234455~1' => new List<List<String>> {
                    new String[]{'{randomList(C, G, A)}', '{randomNumber(0, 999, 4, 0, false)}', 'Money', '{randomList(Family, Individual)}', '{randomString(10, 100)}', '{randomList(Calendar Year, Year to Date, Day, Month)}', '{randomList(IN, IN, IN, OUT)}', '{randomNumber(1, 10)}'}
        		},
                '75656981~1' => new List<List<String>> {
                    new String[]{'{randomList(C, G, A)}', '{randomNumber(0, 999, 4, 0, false)}', 'Money', '{randomList(Family, Individual)}', '{randomString(10, 100)}', '{randomList(Calendar Year, Year to Date, Day, Month)}', '{randomList(IN, IN, IN, OUT)}', '{randomNumber(1, 10)}'}
        		},
                '75656982~1' => new List<List<String>> {
                    new String[]{'{randomList(C, G, A)}', '{randomNumber(0, 999, 4, 0, false)}', 'Money', '{randomList(Family, Individual)}', '{randomString(10, 100)}', '{randomList(Calendar Year, Year to Date, Day, Month)}', '{randomList(IN, IN, IN, OUT)}', '{randomNumber(1, 10)}'}
        		},
                '75656983~1' => new List<List<String>> {
                    new String[]{'{randomList(C, G, A)}', '{randomNumber(0, 999, 4, 0, false)}', 'Money', '{randomList(Family, Individual)}', '{randomString(10, 100)}', '{randomList(Calendar Year, Year to Date, Day, Month)}', '{randomList(IN, IN, IN, OUT)}', '{randomNumber(1, 10)}'}
        		},
                '9765667~1' => new List<List<String>> {
                    new String[]{'{randomList(C, G, A)}', '{randomNumber(0, 999, 4, 0, false)}', 'Money', '{randomList(Family, Individual)}', '{randomString(10, 100)}', '{randomList(Calendar Year, Year to Date, Day, Month)}', '{randomList(IN, IN, IN, OUT)}', '{randomNumber(1, 10)}'}
        		},
                '874565756~1' => new List<List<String>> {
                    new String[]{'{randomList(C, G, A)}', '{randomNumber(0, 999, 4, 0, false)}', 'Money', '{randomList(Family, Individual)}', '{randomString(10, 100)}', '{randomList(Calendar Year, Year to Date, Day, Month)}', '{randomList(IN, IN, IN, OUT)}', '{randomNumber(1, 10)}'}
        		},
                '5689970~1' => new List<List<String>> {
                    new String[]{'{randomList(C, G, A)}', '{randomNumber(0, 999, 4, 0, false)}', 'Money', '{randomList(Family, Individual)}', '{randomString(10, 100)}', '{randomList(Calendar Year, Year to Date, Day, Month)}', '{randomList(IN, IN, IN, OUT)}', '{randomNumber(1, 10)}'}
        		}
            }; 
        
        Map<String, healthcloudext.BenefitsVerificationResponse> benefitsVerificationResponseMap = new Map<String, healthcloudext.BenefitsVerificationResponse>();
        
        for (String[] values : benefitsResponseList) {
            String key = getBenefitsItemKey(values[0], values[1]);
                        
            List<List<String>> bis = benefitsItemMap.get(key);
            
            List<healthcloudext.BenefitsItem> biList = new List<healthcloudext.BenefitsItem>();
            
            if (bis != null) {
                
                for (String[] biArray : bis) {
                    String biKey = getBenefitsItemLimitKey(key, biArray[0]);                    
                
                    List<healthcloudext.BenefitsItemLimit> bilList = new List<healthcloudext.BenefitsItemLimit>();
                
                    List<List<String>> bils = benefitsItemLimitMap.get(biKey);
                	
                    if (bils != null) {
                        for (String[] bilArray : bils) {
                            Integer cnt = Integer.valueOf(processString(bilArray[7]));
                            for (Integer i = 0; i < cnt; i++) {
                                bilList.add(getBenefitsItemLimit(bilArray[0], bilArray[1], bilArray[2], bilArray[3], bilArray[4], bilArray[5], bilArray[6], i+1));
                            }
                        }
                    }
                
                    healthcloudext.BenefitsItem bi = getBenefitsItem(biArray[1], biArray[2], biArray[3], biArray[4], biArray[5], bilList);
                
                    biList.add(bi);
                }
            }
            
            healthcloudext.BenefitsVerificationResponse bvr = getBenefitsVerificationResponse(values[0], values[1], values[2], values[3], values[4], values[5], biList, values[6], values[7]);    

            benefitsVerificationResponseMap.put(key, bvr);
        }
        
        return benefitsVerificationResponseMap;
    }
    
    public void debugBenefitsVerificationResponse(healthcloudext.BenefitsVerificationResponse response) {
        System.debug('BenefitsVerificationResponse{memberNumber=' + response.memberNumber + ';groupNumber=' + response.groupNumber + ';benefitsRequestId=' + response.benefitsRequestId +
                    									';isCoverageActive=' + response.isCoverageActive + ';benefitPeriodStartDate=' + response.benefitPeriodStartDate +
                    									';benefitPeriodEndDate=' + response.benefitPeriodEndDate + ';errorResponse=' + response.errorResponse + 
                     									';jsonResponse' + response.jsonResponse);
        
        if (response.benefitsItem != null) {
            for (healthcloudext.BenefitsItem bi : response.benefitsItem) {
                debugBenefitsItem(bi);
            }
        }
    }
    
    public void debugBenefitsItem(healthcloudext.BenefitsItem bi) {
        System.debug('=>BenefitsItem{serviceType=' + bi.serviceType + ';serviceTypeCode=' + bi.serviceTypeCode + 
                     				';benefitsCategory=' + bi.benefitsCategory + ';notes=' + bi.notes + 
                     				';inPlanNetworkIndicator=' + bi.inPlanNetworkIndicator);
        if (bi.benefitsItemLimit != null) {
        	for (healthcloudext.BenefitsItemLimit bil : bi.benefitsItemLimit) {
        		debugBenefitsItemLimit(bil);
        	}
        }
    }
    
    public void debugBenefitsItemLimit(healthcloudext.BenefitsItemLimit bil) {
        System.debug('==>BenefitsItemLimit{benefitCode=' + bil.benefitCode + ';benefitValue=' + bil.benefitValue + ';benefitMetricType=' + bil.benefitMetricType + 
                     					';coverageLevel=' + bil.coverageLevel + ';limitNotes=' + bil.limitNotes + ';termType=' + bil.termType + 
                     					';networkType=' + bil.networkType);
    }
    
    private healthcloudext.BenefitsVerificationResponse getBenefitsVerificationResponse(
        									String memberNumber, String groupNumber, String benefitsRequestId, 
                                            String isCoverageActive, String benefitPeriodStartDate, 
                                            String benefitPeriodEndDate, List<healthcloudext.BenefitsItem> benefitsItem,
        									String errorResponse, String jsonResponse) {
        System.debug('Inside getBenefitsVerificationResponse');
        healthcloudext.BenefitsVerificationResponse bvr = new healthcloudext.BenefitsVerificationResponse();
        
        bvr.memberNumber = processString(memberNumber);
        bvr.groupNumber = processString(groupNumber);
        bvr.benefitsRequestId = processString(benefitsRequestId);
        bvr.isCoverageActive = Boolean.valueOf(processString(isCoverageActive));
        bvr.benefitPeriodStartDate = processString(benefitPeriodStartDate);
        bvr.benefitPeriodEndDate = processString(benefitPeriodEndDate);
        bvr.benefitsItem = benefitsItem;
        bvr.errorResponse = processString(errorResponse);
        bvr.jsonResponse = processString(jsonResponse);
        
        return bvr;
    }
    
    private healthcloudext.BenefitsItem getBenefitsItem(String serviceType, String serviceTypeCode, String benefitsCategory, 
                                                        String notes, String inPlanNetworkIndicator,
                                                       List<healthcloudext.BenefitsItemLimit> benefitsItemLimit) {
        System.debug('Inside getBenefitsItem');
        healthcloudext.BenefitsItem bi = new healthcloudext.BenefitsItem();
            
        bi.serviceType = processString(serviceType);
        bi.serviceTypeCode = processString(serviceTypeCode);
        bi.benefitsCategory = processString(benefitsCategory);
        bi.notes = processString(notes);
        bi.inPlanNetworkIndicator = Boolean.valueOf(processString(inPlanNetworkIndicator));
		bi.benefitsItemLimit = benefitsItemLimit;
                                                           
        return bi;
    }
    
    private healthcloudext.BenefitsItemLimit getBenefitsItemLimit(
        									String benefitCode, String benefitValue, String benefitMetricType, 
                                            String coverageLevel, String limitNotes, String termType, 
                                            String networkType, Integer index) {
        System.debug('Inside getBenefitsItemLimit');
        healthcloudext.BenefitsItemLimit bil = new healthcloudext.BenefitsItemLimit();
            
        bil.benefitCode = processString(benefitCode, index);
        bil.benefitValue = processString(benefitValue, index);
        bil.benefitMetricType = processString(benefitMetricType, index);
        bil.coverageLevel = processString(coverageLevel, index);
        bil.limitNotes = processString(limitNotes, index);
        bil.termType = processString(termType, index);
        bil.networkType = processString(networkType, index);
        
        return bil;
    }

    private String processString(String str, Integer index) {
        String newStr = processMacros(str, index);
        return processString(newStr);
    }

    private String processMacros(String str, Integer index) {
        return str.replaceAll('#index#', String.valueOf(index));
    }

    private String processString(String str) {
        if (str.startsWith('{randomNumber(')) {
            List<String> params = str.substringBetween('(', ')').split(',');
            if (params.size() == 2) {
                return randomNumber(Integer.valueOf(params[0].trim()), Integer.valueOf(params[1].trim()));
            } else if (params.size() == 5) {
                return randomNumber(Integer.valueOf(params[0].trim()), Integer.valueOf(params[1].trim()), Integer.valueOf(params[2].trim()), params[3].trim(), Boolean.valueOf(params[4].trim()));
            }
        } else if (str.startsWith('{randomList(')) {
            return randomList(str.substringBetween('(', ')'));
        } else if (str.startsWith('{randomString(')) {
            List<String> params = str.substringBetween('(', ')').split(',');
            return randomString(Integer.valueOf(params[0].trim()), Integer.valueOf(params[1].trim()));
        }
        return str;
    }

    private String randomNumber(Integer startNo, Integer endNo) {
        return String.valueOf(randomBetween(startNo, endNo));
    }

    private String randomNumber(Integer startNo, Integer endNo, Integer length, String padStr, Boolean padLeft) {
        return (padLeft ? randomNumber(startNo, endNo).leftPad(length, padStr) : randomNumber(startNo, endNo).rightPad(length, padStr));        
    }

    private String randomList(String values) {
        List<String> valueList = values.split(',');
        Integer index = Integer.valueOf(Math.Floor(Math.Random() * valueList.size()));
        return valueList[index].trim();
    }

    private String randomString(Integer minLen, Integer maxLen) {
        String str = 'The meaning of health has evolved over time. In keeping with the biomedical perspective, early definitions of health focused on the theme of the body\'s ability to function; health was seen as a state of normal function that could be disrupted from time to time by disease. An example of such a definition of health is: "a state characterized by anatomic, physiologic, and psychological integrity; ability to perform personally valued family, work, and community roles; ability to deal with physical, biological, psychological, and social stress".[2] Then in 1948, in a radical departure from previous definitions, the World Health Organization (WHO) proposed a definition that aimed higher: linking health to well-being, in terms of "physical, mental, and social well-being, and not merely the absence of disease and infirmity".[3] Although this definition was welcomed by some as being innovative, it was also criticized as being vague, excessively broad and was not construed as measurable. For a long time, it was set aside as an impractical ideal and most discussions of health returned to the practicality of the biomedical model. Just as there was a shift from viewing disease as a state to thinking of it as a process, the same shift happened in definitions of health. Again, the WHO played a leading role when it fostered the development of the health promotion movement in the 1980s. This brought in a new conception of health, not as a state, but in dynamic terms of resiliency, in other words, as "a resource for living". In 1984 WHO revised the definition of health defined it as "the extent to which an individual or group is able to realize aspirations and satisfy needs and to change or cope with the environment. Health is a resource for everyday life, not the objective of living; it is a positive concept, emphasizing social and personal resources, as well as physical capacities".[5] Thus, health referred to the ability to maintain homeostasis and recover from insults. Mental, intellectual, emotional and social health referred to a person\'s ability to handle stress, to acquire skills, to maintain relationships, all of which form resources for resiliency and independent living.[4] This opens up many possibilities for health to be taught, strengthened and learned.  Since the late 1970s, the federal Healthy People Program has been a visible component of the United States’ approach to improving population health.[6][7] In each decade, a new version of Healthy People is issued,[8] featuring updated goals and identifying topic areas and quantifiable objectives for health improvement during the succeeding ten years, with assessment at that point of progress or lack thereof. Progress has been limited to many objectives, leading to concerns about the effectiveness of Healthy People in shaping outcomes in the context of a decentralized and uncoordinated US health system. Healthy People 2020 gives more prominence to health promotion and preventive approaches and adds a substantive focus on the importance of addressing social determinants of health. A new expanded digital interface facilitates use and dissemination rather than bulky printed books as produced in the past. The impact of these changes to Healthy People will be determined in the coming years. Systematic activities to prevent or cure health problems and promote good health in humans are undertaken by health care providers. Applications with regard to animal health are covered by the veterinary sciences. The term "healthy" is also widely used in the context of many types of non-living organizations and their impacts for the benefit of humans, such as in the sense of healthy communities, healthy cities or healthy environments. In addition to health care interventions and a person\'s surroundings, a number of other factors are known to influence the health status of individuals, including their background, lifestyle, and economic, social conditions and spirituality; these are referred to as "determinants of health." Studies have shown that high levels of stress can affect human health.  In the first decade of the 21st century, the conceptualization of health as an ability opened the door for self-assessments to become the main indicators to judge the performance of efforts aimed at improving human health.[11] It also created the opportunity for every person to feel healthy, even in the presence of multiple chronic diseases, or a terminal condition, and for the re-examination of determinants of health, away from the traditional approach that focuses on the reduction of the prevalence of diseases.';
        Integer maxStrSize = str.length();
        Integer strSize = (minLen == maxLen ? minLen : randomBetween(minLen, maxLen));
        if (strSize >= maxStrSize) {
            return str;
        } else {
            Integer startIndex = randomBetween(1, maxStrSize - strSize);
            Integer endIndex = startIndex + strSize;
            return str.substring(startIndex, endIndex);
        }
    }

    private Integer randomBetween(Integer startNo, Integer endNo) {
        return Math.Round(Math.Random() * (endNo - startNo) + startNo);
    }
}