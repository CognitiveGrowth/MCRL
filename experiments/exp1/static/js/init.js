// Generated by CoffeeScript 1.12.3
var COST_LEVEL, DEBUG, DEMO, IVs, PARAMS, PRType, condition, conditions, counterbalance, experiment_nr, frequency, i, infoCost, j, k, l, len, len1, len2, len3, message, messageTypes, nrConditions, nrDelays, nrInfoCosts, nrMessages, ref, ref1, ref2;

DEBUG = true;

if (DEBUG) {
  console.log("X X X X X X X X X X X X X X X X X\n X X X X X DEBUG  MODE X X X X X\nX X X X X X X X X X X X X X X X X");
  condition = 1;
} else {
  console.log("# =============================== #\n# ========= NORMAL MODE ========= #\n# =============================== #");
}

if (mode === "{{ mode }}") {
  DEMO = true;
  condition = 1;
  counterbalance = 0;
}

experiment_nr = 0.6;

switch (experiment_nr) {
  case 0:
    IVs = {
      frequencyOfFB: ['after_each_move'],
      PRTypes: ['none', 'featureBased', 'fullObservation'],
      messageTypes: ['full', 'none'],
      infoCosts: [0.01, 2.80]
    };
    break;
  case 0.6:
    IVs = {
      frequencyOfFB: ['after_each_move'],
      PRTypes: ['featureBased'],
      messageTypes: ['full'],
      infoCosts: [0.01, 1.00, 2.50]
    };
    break;
  case 1:
    IVs = {
      frequencyOfFB: ['after_each_move'],
      PRTypes: ['none', 'featureBased', 'fullObservation'],
      messageTypes: ['full', 'none'],
      infoCosts: [0.01, 1.00, 2.50]
    };
    break;
  case 2:
    IVs = {
      frequencyOfFB: ['after_each_move'],
      PRTypes: ['featureBased', 'objectLevel'],
      messageTypes: ['full'],
      infoCosts: [0.01, 1.60, 2.80]
    };
    break;
  case 3:
    IVs = {
      frequencyOfFB: ['after_each_move'],
      PRTypes: ['none', 'featureBased'],
      messageTypes: ['full', 'simple'],
      infoCosts: [1.60]
    };
    break;
  case 4:
    IVs = {
      frequencyOfFB: ['after_each_move', 'after_each_click'],
      PRTypes: ['featureBased'],
      messageTypes: ['none'],
      infoCosts: [1.60]
    };
    break;
  default:
    console.log("Invalid experiment_nr!");
}

nrDelays = IVs.PRTypes.length;

nrMessages = IVs.messageTypes.length;

nrInfoCosts = IVs.infoCosts.length;

nrConditions = (function() {
  switch (experiment_nr) {
    case 0:
      return 6;
    case 0.6:
      return 3;
    case 1:
      return 3 * 3;
    default:
      return nrDelays * nrMessages * nrInfoCosts;
  }
})();

conditions = {
  'PRType': [],
  'messageType': [],
  'infoCost': [],
  'frequencyOfFB': []
};

ref = IVs.PRTypes;
for (i = 0, len = ref.length; i < len; i++) {
  PRType = ref[i];
  if (experiment_nr <= 1) {
    if (PRType === 'none') {
      messageTypes = ['none'];
    } else {
      messageTypes = ['full'];
    }
  } else {
    messageTypes = IVs.messageTypes;
  }
  for (j = 0, len1 = messageTypes.length; j < len1; j++) {
    message = messageTypes[j];
    ref1 = IVs.infoCosts;
    for (k = 0, len2 = ref1.length; k < len2; k++) {
      infoCost = ref1[k];
      ref2 = IVs.frequencyOfFB;
      for (l = 0, len3 = ref2.length; l < len3; l++) {
        frequency = ref2[l];
        conditions.PRType.push(PRType);
        conditions.messageType.push(message);
        conditions.infoCost.push(infoCost);
        conditions.frequencyOfFB.push(frequency);
      }
    }
  }
}

PARAMS = {
  PR_type: conditions.PRType[condition],
  feedback: conditions.PRType[condition] !== "none",
  info_cost: conditions.infoCost[condition],
  message: conditions.messageType[condition],
  frequencyOfFB: conditions.frequencyOfFB[condition],
  condition: condition
};

console.log('PARAMS', PARAMS);

COST_LEVEL = (function() {
  switch (PARAMS.info_cost) {
    case 0.01:
      return 'low';
    case 1.00:
      return 'med';
    case 2.50:
      return 'high';
    default:
      throw new Error('bad info_cost');
  }
})();