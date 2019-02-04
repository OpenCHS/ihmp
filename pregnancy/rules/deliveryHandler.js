const moment = require("moment");
const _ = require("lodash");
import {
    RuleFactory,
    FormElementsStatusHelper,
    FormElementStatusBuilder,
    StatusBuilderAnnotationFactory,
    FormElementStatus,
    VisitScheduleBuilder,
    RuleCondition
} from 'rules-config/rules';

const DeliveryFilter = RuleFactory("cc6a3c6a-c3cc-488d-a46c-d9d538fcc9c2", 'ViewFilter');
const WithStatusBuilder = StatusBuilderAnnotationFactory('programEncounter', 'formElement');

@DeliveryFilter('84ea002e-32a2-448c-b540-18bd277ef656', 'IHMP Skip logic for delivery form', 100.0)
class DeliveryFilterHandler {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new DeliveryFilterHandler(), programEncounter, formElementGroup, today);
    }

    @WithStatusBuilder
    deliveredBy([], statusBuilder) {
        statusBuilder.skipAnswers("Relative", "TBA (Trained Birth Attendant)", "Non-Skilled Birth Attendant (NSBA)").when.valueInEncounter("Place of delivery")
            .containsAnyAnswerConceptName("Private hospital", 'Government Hospital', 'Primary Health Center', 'Regional Hospital');
        statusBuilder.show().whenItem(true).is.truthy;
    }


    @WithStatusBuilder
    whetherRecievedBenefitOfJsy([], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether eligible for JSY").is.yes;
    }
    
    @WithStatusBuilder
    detailsOfJsyBenefitChequeNumberAndAmount([], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether recieved benefit of JSY").is.yes;
    }
    
    @WithStatusBuilder
    benefitsRecievedUnderPmvyInRupees([], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether received benefits of PMVY").is.yes;
    }

}

module.exports = {DeliveryFilterHandler};