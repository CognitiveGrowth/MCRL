// Generated by CoffeeScript 1.12.3

/*
experiment.coffee
Fred Callaway

Demonstrates the jsych-mdp plugin
 */
var BLOCKS, DEBUG, DEMO, N_TRIALS, PARAMS, TRIALS, condition, counterbalance, createStartButton, delay, initializeExperiment, psiturk,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

DEBUG = false;

if (DEBUG) {
  console.log("X X X X X X X X X X X X X X X X X\n X X X X X DEBUG  MODE X X X X X\nX X X X X X X X X X X X X X X X X");
  condition = 0;
} else {
  console.log("# =============================== #\n# ========= NORMAL MODE ========= #\n# =============================== #");
}

if (mode === "{{ mode }}") {
  DEMO = true;
  condition = 0;
  counterbalance = 0;
}

psiturk = new PsiTurk(uniqueId, adServerLoc, mode);

BLOCKS = void 0;

PARAMS = void 0;

TRIALS = void 0;

N_TRIALS = void 0;

delay = function(time, func) {
  return setTimeout(func, time);
};

$(window).on('load', function() {
  var loadTimeout, slowLoad;
  slowLoad = function() {
    return document.getElementById("failLoad").style.display = "block";
  };
  loadTimeout = delay(12000, slowLoad);
  psiturk.preloadImages(['static/images/example1.png', 'static/images/example2.png', 'static/images/example3.png', 'static/images/money.png', 'static/images/plane.png', 'static/images/spider.png']);
  return delay(300, function() {
    var ERROR, expData;
    console.log('Loading data');
    expData = loadJson("static/json/condition_0_0.json");
    console.log('expData', expData);
    PARAMS = expData.conditions[condition % 3];
    PARAMS.start_time = Date(Date.now());
    BLOCKS = expData.blocks;
    TRIALS = BLOCKS.standard;
    psiturk.recordUnstructuredData('params', PARAMS);
    if (DEBUG || DEMO) {
      createStartButton();
      return PARAMS.message = true;
    } else {
      console.log('Testing saveData');
      ERROR = null;
      return psiturk.saveData({
        error: function() {
          console.log('ERROR saving data.');
          return ERROR = true;
        },
        success: function() {
          console.log('Data saved to psiturk server.');
          clearTimeout(loadTimeout);
          return delay(500, createStartButton);
        }
      });
    }
  });
});

createStartButton = function() {
  if (DEBUG) {
    initializeExperiment();
    return;
  }
  document.getElementById("loader").style.display = "none";
  document.getElementById("successLoad").style.display = "block";
  document.getElementById("failLoad").style.display = "none";
  return $('#load-btn').click(initializeExperiment);
};

initializeExperiment = function() {
  var BONUS, Block, MDPBlock, QuizLoop, TextBlock, calculateBonus, debug_slide, experiment_timeline, finish, instruct_loop, instructions, main, prompt_resubmit, quiz, reprompt, save_data, text;
  console.log('INITIALIZE EXPERIMENT');
  N_TRIALS = BLOCKS.standard.length;
  text = {
    debug: function() {
      if (DEBUG) {
        return "`DEBUG`";
      } else {
        return '';
      }
    },
    feedback: function() {
      if (PARAMS.PR_type) {
        return [markdown("# Instructions\n\n<b>You will receive feedback about your planning. This feedback will\nhelp you learn how to make better decisions.</b> After each flight, if\nyou did not plan optimally, a feedback message will apear. This message\nwill tell you two things:\n\n1. Whether you observed too few relevant values or if you observed\n   irrelevant values (values of locations that you cant fly to).\n2. Whether you flew along the best route given your current location and\n   the information you had about the values of other locations.\n\nIn the example below, not enough relevant values were observed, and\nas a result there is a 41 second timeout penalty. <b>The duration of\nthe timeout penalty is proportional to how poorly you planned your\nroute:</b> the more money you could have earned from observing more\nvalues and/or choosing a better route, the longer the delay. <b>If\nyou perform optimally, no feedback will be shown and you can proceed\nimmediately.</b>")];
      } else {
        return [];
      }
    },
    constantDelay: function() {
      if (PARAMS.PR_type) {
        return "";
      } else {
        return "Note: there will be short delays after taking some flights.";
      }
    }
  };
  Block = (function() {
    function Block(config) {
      _.extend(this, config);
      this._block = this;
      if (this._init != null) {
        this._init();
      }
    }

    return Block;

  })();
  TextBlock = (function(superClass) {
    extend(TextBlock, superClass);

    function TextBlock() {
      return TextBlock.__super__.constructor.apply(this, arguments);
    }

    TextBlock.prototype.type = 'text';

    TextBlock.prototype.cont_key = ['space'];

    return TextBlock;

  })(Block);
  QuizLoop = (function(superClass) {
    extend(QuizLoop, superClass);

    function QuizLoop() {
      return QuizLoop.__super__.constructor.apply(this, arguments);
    }

    QuizLoop.prototype.loop_function = function(data) {
      var c, i, len, ref;
      console.log('data', data);
      ref = data[data.length].correct;
      for (i = 0, len = ref.length; i < len; i++) {
        c = ref[i];
        if (!c) {
          return true;
        }
      }
      return false;
    };

    return QuizLoop;

  })(Block);
  MDPBlock = (function(superClass) {
    extend(MDPBlock, superClass);

    function MDPBlock() {
      return MDPBlock.__super__.constructor.apply(this, arguments);
    }

    MDPBlock.prototype.type = 'mouselab-mdp';

    MDPBlock.prototype._init = function() {
      return this.trialCount = 0;
    };

    return MDPBlock;

  })(Block);
  debug_slide = new Block({
    type: 'html',
    url: 'test.html'
  });
  instructions = new Block({
    type: "instructions",
    pages: [markdown("# Instructions " + (text.debug()) + "\n\nIn this game, you are in charge of flying an aircraft. As shown below,\nyou will begin in the central location. The arrows show which actions\nare available in each location. Note that once you have made a move you\ncannot go back; you can only move forward along the arrows. There are\neight possible final destinations labelled 1-8 in the image below. On\nyour way there, you will visit two intermediate locations. <b>Every\nlocation you visit will add or subtract money to your account</b>, and\nyour task is to earn as much money as possible. <b>To find out how much\nmoney you earn or lose in a location, you have to click on it.</b> You\ncan uncover the value of as many or as few locations as you wish.\n\n\n" + (img('Slide1.png')) + "\n\nTo navigate the airplane, use the arrows (the example above is non-interactive).\nYou can uncover the value of a location at any time. Click \"Next\" to proceed."), markdown("# Instructions\n\nYou will play the game for " + N_TRIALS + " rounds. The value of every location will\nchange from each round to the next. At the begining of each round, the\nvalue of every location will be hidden, and you will only discover the\nvalue of the locations you click on. The example below shows the value\nof every location, just to give you an example of values you could see\nif you clicked on every location. <b>Every time you click a circle to\nobserve its value, you pay a fee of " + (fmtMoney(PARAMS.info_cost)) + ".</b>\nEach time you move to a\nlocation, your profit will be adjusted. If you move to a location with\na hidden value, your profit will still be adjusted according to the\nvalue of that location. " + (text.constantDelay()))].concat((text.feedback()).concat([markdown("# Instructions\n\nThere are two more important things to understand:\n1. You must spend at least 45 seconds on each round. A countdown timer\n   will show you how much more time you must spend on the round. You\n   won’t be able to proceed to the next round before the countdown has\n   finished, but you can take as much time as you like afterwards.\n2. </b>You will earn <u>real money</u> for your flights.</b> Specifically,\n   one of the " + N_TRIALS + " rounds will be chosen at random and you will receive 5%\n   of your earnings in that round as a bonus payment.\n\n You may proceed to take an entry quiz, or go back to review the instructions.")])),
    show_clickable_nav: true
  });
  quiz = new Block({
    preamble: function() {
      return markdown("# Quiz");
    },
    type: 'survey-multi-choice',
    questions: ["True or false: The hidden values will change each time I start a new round.", "How much does it cost to observe each hidden value?", "How many hidden values am I allowed to observe in each round?", "How is your bonus determined?"].concat((PARAMS.PR_type ? ["What does the feedback teach you?"] : [])),
    options: [['True', 'False'], ['$0.01', '$0.05', '$1.60', '$2.80'], ['At most 1', 'At most 5', 'At most 10', 'At most 15', 'As many or as few as I wish'], ['10% of my best score on any round', '10% of my total score on all rounds', '5% of my best score on any round', '5% of my score on a random round'], ['Whether I observed the rewards of relevant locations.', 'Whether I chose the move that was best according to the information I had.', 'The length of the delay is based on how much more money I could have earned by planning and deciding better.', 'All of the above.']],
    required: [true, true, true, true, true],
    correct: ['True', fmtMoney(PARAMS.info_cost), 'As many or as few as I wish', '5% of my score on a random round', 'All of the above.'],
    on_mistake: function(data) {
      return alert("You got at least one question wrong. We'll send you back to the\ninstructions and then you can try again.");
    }
  });
  instruct_loop = new Block({
    timeline: [instructions, quiz],
    loop_function: function(data) {
      var c, i, len, ref;
      ref = data[1].correct;
      for (i = 0, len = ref.length; i < len; i++) {
        c = ref[i];
        if (!c) {
          return true;
        }
      }
      psiturk.finishInstructions();
      psiturk.saveData();
      return false;
    }
  });
  main = new MDPBlock({
    timeline: _.shuffle(TRIALS)
  });
  finish = new Block({
    type: 'button-response',
    stimulus: function() {
      return markdown("# You've completed the HIT\n\nThanks again for participating. We hope you had fun!\n\nBased on your performance, you will be\nawarded a bonus of **$" + (calculateBonus().toFixed(2)) + "**.");
    },
    is_html: true,
    choices: ['Submit hit'],
    button_html: '<button class="btn btn-primary btn-lg">%choice%</button>'
  });
  if (DEBUG) {
    experiment_timeline = [main, finish];
  } else {
    experiment_timeline = [instruct_loop, main, finish];
  }
  BONUS = void 0;
  calculateBonus = function() {
    var data;
    if (DEBUG) {
      return 0;
    }
    if (BONUS != null) {
      return BONUS;
    }
    data = jsPsych.data.getTrialsOfType('graph');
    BONUS = 0.05 * Math.max(0, (_.sample(data)).score);
    psiturk.recordUnstructuredData('final_bonus', BONUS);
    return BONUS;
  };
  reprompt = null;
  save_data = function() {
    return psiturk.saveData({
      success: function() {
        console.log('Data saved to psiturk server.');
        if (reprompt != null) {
          window.clearInterval(reprompt);
        }
        return psiturk.computeBonus('compute_bonus', psiturk.completeHIT);
      },
      error: function() {
        return prompt_resubmit;
      }
    });
  };
  prompt_resubmit = function() {
    $('#jspsych-target').html("<h1>Oops!</h1>\n<p>\nSomething went wrong submitting your HIT.\nThis might happen if you lose your internet connection.\nPress the button to resubmit.\n</p>\n<button id=\"resubmit\">Resubmit</button>");
    return $('#resubmit').click(function() {
      $('#jspsych-target').html('Trying to resubmit...');
      reprompt = window.setTimeout(prompt_resubmit, 10000);
      return save_data();
    });
  };
  return jsPsych.init({
    display_element: $('#jspsych-target'),
    timeline: experiment_timeline,
    on_finish: function() {
      if (DEBUG) {
        return jsPsych.data.displayData();
      } else {
        psiturk.recordUnstructuredData('final_bonus', calculateBonus());
        return save_data();
      }
    },
    on_data_update: function(data) {
      console.log('data', data);
      return psiturk.recordTrialData(data);
    }
  });
};
