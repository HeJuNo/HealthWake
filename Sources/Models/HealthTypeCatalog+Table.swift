// ERZEUGT von scripts/generate-catalog.swift aus den Kopfdateien des iOS-SDK,
// danach von Hand kuratiert. Wer neue Typen aufnimmt, laesst das Skript neu
// laufen und uebernimmt die Kuratierung.

import Foundation

extension HealthTypeCatalog {
    static let table: [HealthTypeDescriptor] = [
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierAbdominalCramps",
        kind: .category,
        displayName: "Abdominal Cramps",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierAcne",
        kind: .category,
        displayName: "Acne",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierAppetiteChanges",
        kind: .category,
        displayName: "Appetite Changes",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "No Change", 2: "Decreased", 3: "Increased"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierAppleStandHour",
        kind: .category,
        displayName: "Stand Hour",
        group: .activity,
        defaultUnitString: nil,
        categoryLabels: [0: "Stood", 1: "Idle"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierAppleWalkingSteadinessEvent",
        kind: .category,
        displayName: "Walking Steadiness Event",
        group: .mobility,
        defaultUnitString: nil,
        categoryLabels: [1: "First Low Reading", 2: "First Very Low Reading", 3: "Repeat Low Reading", 4: "Repeat Very Low Reading"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierBladderIncontinence",
        kind: .category,
        displayName: "Bladder Incontinence",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierBleedingAfterPregnancy",
        kind: .category,
        displayName: "Bleeding After Pregnancy",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [1: "Unspecified", 2: "Light", 3: "Medium", 4: "Heavy", 5: "None"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierBleedingDuringPregnancy",
        kind: .category,
        displayName: "Bleeding During Pregnancy",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [1: "Unspecified", 2: "Light", 3: "Medium", 4: "Heavy", 5: "None"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierBloating",
        kind: .category,
        displayName: "Bloating",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierBreastPain",
        kind: .category,
        displayName: "Breast Pain",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierCervicalMucusQuality",
        kind: .category,
        displayName: "Cervical Mucus Quality",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [1: "Dry", 2: "Sticky", 3: "Creamy", 4: "Watery", 5: "Egg White"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierChestTightnessOrPain",
        kind: .category,
        displayName: "Chest Tightness or Pain",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierChills",
        kind: .category,
        displayName: "Chills",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierConstipation",
        kind: .category,
        displayName: "Constipation",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierContraceptive",
        kind: .category,
        displayName: "Contraceptive",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [1: "Unspecified", 2: "Implant", 3: "Injection", 4: "Intrauterine Device", 5: "Intravaginal Ring", 6: "Oral", 7: "Patch"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierCoughing",
        kind: .category,
        displayName: "Coughing",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierDiarrhea",
        kind: .category,
        displayName: "Diarrhea",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierDizziness",
        kind: .category,
        displayName: "Dizziness",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierDrySkin",
        kind: .category,
        displayName: "Dry Skin",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierEnvironmentalAudioExposureEvent",
        kind: .category,
        displayName: "Environmental Audio Exposure Event",
        group: .hearing,
        defaultUnitString: nil,
        categoryLabels: [1: "Momentary Limit"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierFainting",
        kind: .category,
        displayName: "Fainting",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierFatigue",
        kind: .category,
        displayName: "Fatigue",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierFever",
        kind: .category,
        displayName: "Fever",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierGeneralizedBodyAche",
        kind: .category,
        displayName: "Generalized Body Ache",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierHairLoss",
        kind: .category,
        displayName: "Hair Loss",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierHandwashingEvent",
        kind: .category,
        displayName: "Handwashing Event",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierHeadache",
        kind: .category,
        displayName: "Headache",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierHeadphoneAudioExposureEvent",
        kind: .category,
        displayName: "Headphone Audio Exposure Event",
        group: .hearing,
        defaultUnitString: nil,
        categoryLabels: [1: "Seven Day Limit"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierHeartburn",
        kind: .category,
        displayName: "Heartburn",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierHighHeartRateEvent",
        kind: .category,
        displayName: "High Heart Rate Event",
        group: .vitals,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierHotFlashes",
        kind: .category,
        displayName: "Hot Flashes",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierInfrequentMenstrualCycles",
        kind: .category,
        displayName: "Infrequent Menstrual Cycles",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierIntermenstrualBleeding",
        kind: .category,
        displayName: "Intermenstrual Bleeding",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierIrregularHeartRhythmEvent",
        kind: .category,
        displayName: "Irregular Heart Rhythm Event",
        group: .vitals,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierIrregularMenstrualCycles",
        kind: .category,
        displayName: "Irregular Menstrual Cycles",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierLactation",
        kind: .category,
        displayName: "Lactation",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierLossOfSmell",
        kind: .category,
        displayName: "Loss of Smell",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierLossOfTaste",
        kind: .category,
        displayName: "Loss of Taste",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierLowCardioFitnessEvent",
        kind: .category,
        displayName: "Low Cardio Fitness Event",
        group: .vitals,
        defaultUnitString: nil,
        categoryLabels: [1: "Low Fitness"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierLowHeartRateEvent",
        kind: .category,
        displayName: "Low Heart Rate Event",
        group: .vitals,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierLowerBackPain",
        kind: .category,
        displayName: "Lower Back Pain",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierMemoryLapse",
        kind: .category,
        displayName: "Memory Lapse",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierMenstrualFlow",
        kind: .category,
        displayName: "Menstrual Flow",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [1: "Unspecified", 2: "Light", 3: "Medium", 4: "Heavy"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierMindfulSession",
        kind: .category,
        displayName: "Mindful Minutes",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierMoodChanges",
        kind: .category,
        displayName: "Mood Changes",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierNausea",
        kind: .category,
        displayName: "Nausea",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierNightSweats",
        kind: .category,
        displayName: "Night Sweats",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierOvulationTestResult",
        kind: .category,
        displayName: "Ovulation Test Result",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [1: "Negative", 2: "LH Surge", 3: "Indeterminate", 4: "Estrogen Surge"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierPelvicPain",
        kind: .category,
        displayName: "Pelvic Pain",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierPersistentIntermenstrualBleeding",
        kind: .category,
        displayName: "Persistent Intermenstrual Bleeding",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierPregnancy",
        kind: .category,
        displayName: "Pregnancy",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierPregnancyTestResult",
        kind: .category,
        displayName: "Pregnancy Test Result",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [1: "Negative", 2: "Positive", 3: "Indeterminate"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierProgesteroneTestResult",
        kind: .category,
        displayName: "Progesterone Test Result",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [1: "Negative", 2: "Positive", 3: "Indeterminate"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierProlongedMenstrualPeriods",
        kind: .category,
        displayName: "Prolonged Menstrual Periods",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierRapidPoundingOrFlutteringHeartbeat",
        kind: .category,
        displayName: "Rapid Pounding or Fluttering Heartbeat",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierRunnyNose",
        kind: .category,
        displayName: "Runny Nose",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierSexualActivity",
        kind: .category,
        displayName: "Sexual Activity",
        group: .reproductive,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierShortnessOfBreath",
        kind: .category,
        displayName: "Shortness of Breath",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierSinusCongestion",
        kind: .category,
        displayName: "Sinus Congestion",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierSkippedHeartbeat",
        kind: .category,
        displayName: "Skipped Heartbeat",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        kind: .category,
        displayName: "Sleep",
        group: .sleep,
        defaultUnitString: nil,
        categoryLabels: [0: "In Bed", 1: "Asleep", 2: "Awake", 3: "Core Sleep", 4: "Deep Sleep", 5: "REM Sleep"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierSleepApneaEvent",
        kind: .category,
        displayName: "Sleep Apnea Event",
        group: .sleep,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierSleepChanges",
        kind: .category,
        displayName: "Sleep Changes",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierSoreThroat",
        kind: .category,
        displayName: "Sore Throat",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierToothbrushingEvent",
        kind: .category,
        displayName: "Toothbrushing Event",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Recorded"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierVaginalDryness",
        kind: .category,
        displayName: "Vaginal Dryness",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierVomiting",
        kind: .category,
        displayName: "Vomiting",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKCategoryTypeIdentifierWheezing",
        kind: .category,
        displayName: "Wheezing",
        group: .other,
        defaultUnitString: nil,
        categoryLabels: [0: "Unspecified", 1: "Not Present", 2: "Mild", 3: "Moderate", 4: "Severe"]
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierActiveEnergyBurned",
        kind: .quantity,
        displayName: "Active Energy",
        group: .activity,
        defaultUnitString: "kcal",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierAppleExerciseTime",
        kind: .quantity,
        displayName: "Exercise Time",
        group: .activity,
        defaultUnitString: "min",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierAppleMoveTime",
        kind: .quantity,
        displayName: "Move Time",
        group: .activity,
        defaultUnitString: "min",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierAppleSleepingBreathingDisturbances",
        kind: .quantity,
        displayName: "Sleeping Breathing Disturbances",
        group: .sleep,
        defaultUnitString: "count",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierAppleSleepingWristTemperature",
        kind: .quantity,
        displayName: "Sleeping Wrist Temperature",
        group: .sleep,
        defaultUnitString: "degC",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierAppleStandTime",
        kind: .quantity,
        displayName: "Stand Time",
        group: .activity,
        defaultUnitString: "min",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierAppleWalkingSteadiness",
        kind: .quantity,
        displayName: "Walking Steadiness",
        group: .mobility,
        defaultUnitString: "%",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierAtrialFibrillationBurden",
        kind: .quantity,
        displayName: "Atrial Fibrillation Burden",
        group: .vitals,
        defaultUnitString: "%",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierBasalBodyTemperature",
        kind: .quantity,
        displayName: "Basal Body Temperature",
        group: .reproductive,
        defaultUnitString: "degC",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierBasalEnergyBurned",
        kind: .quantity,
        displayName: "Resting Energy",
        group: .activity,
        defaultUnitString: "kcal",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierBloodAlcoholContent",
        kind: .quantity,
        displayName: "Blood Alcohol Content",
        group: .other,
        defaultUnitString: "%",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierBloodGlucose",
        kind: .quantity,
        displayName: "Blood Glucose",
        group: .vitals,
        defaultUnitString: "mg/dL",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierBloodPressureDiastolic",
        kind: .quantity,
        displayName: "Blood Pressure Diastolic",
        group: .vitals,
        defaultUnitString: "mmHg",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierBloodPressureSystolic",
        kind: .quantity,
        displayName: "Blood Pressure Systolic",
        group: .vitals,
        defaultUnitString: "mmHg",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierBodyFatPercentage",
        kind: .quantity,
        displayName: "Body Fat Percentage",
        group: .body,
        defaultUnitString: "%",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierBodyMass",
        kind: .quantity,
        displayName: "Weight",
        group: .body,
        defaultUnitString: "kg",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierBodyMassIndex",
        kind: .quantity,
        displayName: "Body Mass Index",
        group: .body,
        defaultUnitString: "count",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierBodyTemperature",
        kind: .quantity,
        displayName: "Body Temperature",
        group: .vitals,
        defaultUnitString: "degC",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierCrossCountrySkiingSpeed",
        kind: .quantity,
        displayName: "Cross Country Skiing Speed",
        group: .activity,
        defaultUnitString: "m/s",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierCyclingCadence",
        kind: .quantity,
        displayName: "Cycling Cadence",
        group: .activity,
        defaultUnitString: "count/min",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierCyclingFunctionalThresholdPower",
        kind: .quantity,
        displayName: "Cycling Functional Threshold Power",
        group: .activity,
        defaultUnitString: "W",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierCyclingPower",
        kind: .quantity,
        displayName: "Cycling Power",
        group: .activity,
        defaultUnitString: "W",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierCyclingSpeed",
        kind: .quantity,
        displayName: "Cycling Speed",
        group: .activity,
        defaultUnitString: "m/s",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryBiotin",
        kind: .quantity,
        displayName: "Dietary Biotin",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryCaffeine",
        kind: .quantity,
        displayName: "Dietary Caffeine",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryCalcium",
        kind: .quantity,
        displayName: "Dietary Calcium",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryCarbohydrates",
        kind: .quantity,
        displayName: "Dietary Carbohydrates",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryChloride",
        kind: .quantity,
        displayName: "Dietary Chloride",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryCholesterol",
        kind: .quantity,
        displayName: "Dietary Cholesterol",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryChromium",
        kind: .quantity,
        displayName: "Dietary Chromium",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryCopper",
        kind: .quantity,
        displayName: "Dietary Copper",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryEnergyConsumed",
        kind: .quantity,
        displayName: "Dietary Energy",
        group: .nutrition,
        defaultUnitString: "kcal",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryFatMonounsaturated",
        kind: .quantity,
        displayName: "Dietary Fat Monounsaturated",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryFatPolyunsaturated",
        kind: .quantity,
        displayName: "Dietary Fat Polyunsaturated",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryFatSaturated",
        kind: .quantity,
        displayName: "Dietary Fat Saturated",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryFatTotal",
        kind: .quantity,
        displayName: "Dietary Fat Total",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryFiber",
        kind: .quantity,
        displayName: "Dietary Fiber",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryFolate",
        kind: .quantity,
        displayName: "Dietary Folate",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryIodine",
        kind: .quantity,
        displayName: "Dietary Iodine",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryIron",
        kind: .quantity,
        displayName: "Dietary Iron",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryMagnesium",
        kind: .quantity,
        displayName: "Dietary Magnesium",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryManganese",
        kind: .quantity,
        displayName: "Dietary Manganese",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryMolybdenum",
        kind: .quantity,
        displayName: "Dietary Molybdenum",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryNiacin",
        kind: .quantity,
        displayName: "Dietary Niacin",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryPantothenicAcid",
        kind: .quantity,
        displayName: "Dietary Pantothenic Acid",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryPhosphorus",
        kind: .quantity,
        displayName: "Dietary Phosphorus",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryPotassium",
        kind: .quantity,
        displayName: "Dietary Potassium",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryProtein",
        kind: .quantity,
        displayName: "Dietary Protein",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryRiboflavin",
        kind: .quantity,
        displayName: "Dietary Riboflavin",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietarySelenium",
        kind: .quantity,
        displayName: "Dietary Selenium",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietarySodium",
        kind: .quantity,
        displayName: "Dietary Sodium",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietarySugar",
        kind: .quantity,
        displayName: "Dietary Sugar",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryThiamin",
        kind: .quantity,
        displayName: "Dietary Thiamin",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryVitaminA",
        kind: .quantity,
        displayName: "Dietary Vitamin A",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryVitaminB12",
        kind: .quantity,
        displayName: "Dietary Vitamin B12",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryVitaminB6",
        kind: .quantity,
        displayName: "Dietary Vitamin B6",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryVitaminC",
        kind: .quantity,
        displayName: "Dietary Vitamin C",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryVitaminD",
        kind: .quantity,
        displayName: "Dietary Vitamin D",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryVitaminE",
        kind: .quantity,
        displayName: "Dietary Vitamin E",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryVitaminK",
        kind: .quantity,
        displayName: "Dietary Vitamin K",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryWater",
        kind: .quantity,
        displayName: "Water",
        group: .nutrition,
        defaultUnitString: "mL",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDietaryZinc",
        kind: .quantity,
        displayName: "Dietary Zinc",
        group: .nutrition,
        defaultUnitString: "g",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDistanceCrossCountrySkiing",
        kind: .quantity,
        displayName: "Distance Cross Country Skiing",
        group: .activity,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDistanceCycling",
        kind: .quantity,
        displayName: "Distance Cycling",
        group: .activity,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDistanceDownhillSnowSports",
        kind: .quantity,
        displayName: "Distance Downhill Snow Sports",
        group: .activity,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDistancePaddleSports",
        kind: .quantity,
        displayName: "Distance Paddle Sports",
        group: .activity,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDistanceRowing",
        kind: .quantity,
        displayName: "Distance Rowing",
        group: .activity,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDistanceSkatingSports",
        kind: .quantity,
        displayName: "Distance Skating Sports",
        group: .activity,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDistanceSwimming",
        kind: .quantity,
        displayName: "Distance Swimming",
        group: .activity,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDistanceWalkingRunning",
        kind: .quantity,
        displayName: "Walking + Running Distance",
        group: .activity,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierDistanceWheelchair",
        kind: .quantity,
        displayName: "Distance Wheelchair",
        group: .activity,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierElectrodermalActivity",
        kind: .quantity,
        displayName: "Electrodermal Activity",
        group: .other,
        defaultUnitString: "S",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierEnvironmentalAudioExposure",
        kind: .quantity,
        displayName: "Environmental Audio Exposure",
        group: .hearing,
        defaultUnitString: "dBASPL",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierEnvironmentalSoundReduction",
        kind: .quantity,
        displayName: "Environmental Sound Reduction",
        group: .hearing,
        defaultUnitString: "dBASPL",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierEstimatedWorkoutEffortScore",
        kind: .quantity,
        displayName: "Estimated Workout Effort Score",
        group: .activity,
        defaultUnitString: "appleEffortScore",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierFlightsClimbed",
        kind: .quantity,
        displayName: "Flights Climbed",
        group: .activity,
        defaultUnitString: "count",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierForcedExpiratoryVolume1",
        kind: .quantity,
        displayName: "Forced Expiratory Volume (FEV1)",
        group: .respiratory,
        defaultUnitString: "L",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierForcedVitalCapacity",
        kind: .quantity,
        displayName: "Forced Vital Capacity",
        group: .respiratory,
        defaultUnitString: "L",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierHeadphoneAudioExposure",
        kind: .quantity,
        displayName: "Headphone Audio Exposure",
        group: .hearing,
        defaultUnitString: "dBASPL",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierHeartRate",
        kind: .quantity,
        displayName: "Heart Rate",
        group: .vitals,
        defaultUnitString: "count/min",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierHeartRateRecoveryOneMinute",
        kind: .quantity,
        displayName: "Heart Rate Recovery One Minute",
        group: .vitals,
        defaultUnitString: "count/min",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierHeartRateVariabilitySDNN",
        kind: .quantity,
        displayName: "Heart Rate Variability",
        group: .vitals,
        defaultUnitString: "ms",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierHeight",
        kind: .quantity,
        displayName: "Height",
        group: .body,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierInhalerUsage",
        kind: .quantity,
        displayName: "Inhaler Usage",
        group: .respiratory,
        defaultUnitString: "count",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierInsulinDelivery",
        kind: .quantity,
        displayName: "Insulin Delivery",
        group: .other,
        defaultUnitString: "IU",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierLeanBodyMass",
        kind: .quantity,
        displayName: "Lean Body Mass",
        group: .body,
        defaultUnitString: "kg",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierNikeFuel",
        kind: .quantity,
        displayName: "NikeFuel",
        group: .activity,
        defaultUnitString: "count",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierNumberOfAlcoholicBeverages",
        kind: .quantity,
        displayName: "Number of Alcoholic Beverages",
        group: .other,
        defaultUnitString: "count",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierNumberOfTimesFallen",
        kind: .quantity,
        displayName: "Number of Times Fallen",
        group: .other,
        defaultUnitString: "count",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierOxygenSaturation",
        kind: .quantity,
        displayName: "Blood Oxygen",
        group: .respiratory,
        defaultUnitString: "%",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierPaddleSportsSpeed",
        kind: .quantity,
        displayName: "Paddle Sports Speed",
        group: .activity,
        defaultUnitString: "m/s",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierPeakExpiratoryFlowRate",
        kind: .quantity,
        displayName: "Peak Expiratory Flow Rate",
        group: .respiratory,
        defaultUnitString: "L/min",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierPeripheralPerfusionIndex",
        kind: .quantity,
        displayName: "Peripheral Perfusion Index",
        group: .vitals,
        defaultUnitString: "%",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierPhysicalEffort",
        kind: .quantity,
        displayName: "Physical Effort",
        group: .activity,
        defaultUnitString: "kcal/(kg*hr)",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierPushCount",
        kind: .quantity,
        displayName: "Push Count",
        group: .activity,
        defaultUnitString: "count",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierRespiratoryRate",
        kind: .quantity,
        displayName: "Respiratory Rate",
        group: .respiratory,
        defaultUnitString: "count/min",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierRestingHeartRate",
        kind: .quantity,
        displayName: "Resting Heart Rate",
        group: .vitals,
        defaultUnitString: "count/min",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierRowingSpeed",
        kind: .quantity,
        displayName: "Rowing Speed",
        group: .activity,
        defaultUnitString: "m/s",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierRunningGroundContactTime",
        kind: .quantity,
        displayName: "Running Ground Contact Time",
        group: .mobility,
        defaultUnitString: "ms",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierRunningPower",
        kind: .quantity,
        displayName: "Running Power",
        group: .activity,
        defaultUnitString: "W",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierRunningSpeed",
        kind: .quantity,
        displayName: "Running Speed",
        group: .activity,
        defaultUnitString: "m/s",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierRunningStrideLength",
        kind: .quantity,
        displayName: "Running Stride Length",
        group: .mobility,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierRunningVerticalOscillation",
        kind: .quantity,
        displayName: "Running Vertical Oscillation",
        group: .mobility,
        defaultUnitString: "cm",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierSixMinuteWalkTestDistance",
        kind: .quantity,
        displayName: "Six-Minute Walk Distance",
        group: .mobility,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierStairAscentSpeed",
        kind: .quantity,
        displayName: "Stair Ascent Speed",
        group: .mobility,
        defaultUnitString: "m/s",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierStairDescentSpeed",
        kind: .quantity,
        displayName: "Stair Descent Speed",
        group: .mobility,
        defaultUnitString: "m/s",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierStepCount",
        kind: .quantity,
        displayName: "Step Count",
        group: .activity,
        defaultUnitString: "count",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierSwimmingStrokeCount",
        kind: .quantity,
        displayName: "Swimming Stroke Count",
        group: .activity,
        defaultUnitString: "count",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierTimeInDaylight",
        kind: .quantity,
        displayName: "Time in Daylight",
        group: .other,
        defaultUnitString: "min",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierUVExposure",
        kind: .quantity,
        displayName: "UV Index",
        group: .other,
        defaultUnitString: "count",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierUnderwaterDepth",
        kind: .quantity,
        displayName: "Underwater Depth",
        group: .activity,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierVO2Max",
        kind: .quantity,
        displayName: "VO2 Max",
        group: .vitals,
        defaultUnitString: "ml/(kg*min)",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierWaistCircumference",
        kind: .quantity,
        displayName: "Waist Circumference",
        group: .body,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierWalkingAsymmetryPercentage",
        kind: .quantity,
        displayName: "Walking Asymmetry Percentage",
        group: .mobility,
        defaultUnitString: "%",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierWalkingDoubleSupportPercentage",
        kind: .quantity,
        displayName: "Walking Double Support Percentage",
        group: .mobility,
        defaultUnitString: "%",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierWalkingHeartRateAverage",
        kind: .quantity,
        displayName: "Walking Heart Rate Average",
        group: .vitals,
        defaultUnitString: "count/min",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierWalkingSpeed",
        kind: .quantity,
        displayName: "Walking Speed",
        group: .mobility,
        defaultUnitString: "m/s",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierWalkingStepLength",
        kind: .quantity,
        displayName: "Walking Step Length",
        group: .mobility,
        defaultUnitString: "m",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierWaterTemperature",
        kind: .quantity,
        displayName: "Water Temperature",
        group: .other,
        defaultUnitString: "degC",
        categoryLabels: nil
    ),
    HealthTypeDescriptor(
        identifier: "HKQuantityTypeIdentifierWorkoutEffortScore",
        kind: .quantity,
        displayName: "Workout Effort Score",
        group: .activity,
        defaultUnitString: "appleEffortScore",
        categoryLabels: nil
    ),
    ]
}
