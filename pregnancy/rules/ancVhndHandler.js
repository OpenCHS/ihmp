import lib from "../../lib";

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

const WithStatusBuilder = StatusBuilderAnnotationFactory('programEncounter', 'formElement');

const ANCVHNDViewFilter = RuleFactory("e2cf41de-d962-4110-9d66-70877e2eb59d", "ViewFilter");
@ANCVHNDViewFilter("18ae0315-e6c7-4d8c-89fa-527e2f8712ca", "IHMP ANC VHND View Filter", 100.0, {})
class PregnancyANCVHNDViewFilterHandlerIHMP {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new PregnancyANCVHNDViewFilterHandlerIHMP(), programEncounter, formElementGroup, today);
    }

    @WithStatusBuilder
    tt1Date([], statusBuilder) {
        statusBuilder.show().when.latestValueInPreviousEncounters("TT1 Date").is.notDefined;
    }
    
    @WithStatusBuilder
    tt2Date([], statusBuilder) {
        statusBuilder.show().when.latestValueInPreviousEncounters("TT2 Date").is.notDefined;
    }
    
    @WithStatusBuilder
    ttBoosterDate([], statusBuilder) {
        statusBuilder.show().when.latestValueInPreviousEncounters("TT Booster Date").is.notDefined;
    }

}

const ANCASHAFollowupViewFilter = RuleFactory('5edbca3a-04bf-4e16-b624-57331a71da39', "ViewFilter");
@ANCASHAFollowupViewFilter("243be415-dc0a-429e-afff-938c493d2de5", "IHMP ANC VHND Followup View Filter", 100.0, {})
class PregnancyANCVHNDFollowupViewFilterHandlerIHMP {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new PregnancyANCVHNDFollowupViewFilterHandlerIHMP(), programEncounter, formElementGroup, today);
    }

    @WithStatusBuilder
    pregnancyComplications([programEncounter, fe, today], statusBuilder) {
        const currentTrimester = lib.calculations.currentTrimester(programEncounter.programEnrolment, today);
        if (currentTrimester !== 3) {
            statusBuilder.skipAnswers('Reduced fetal movement', 'Watery discharge before onset of labour');
        }
    }

    @WithStatusBuilder
    placeOfAncVhndReferralUtilized([], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether ANC VHND referral utilized").is.yes;
    }
}

module.exports = {PregnancyANCVHNDViewFilterHandlerIHMP,PregnancyANCVHNDFollowupViewFilterHandlerIHMP};