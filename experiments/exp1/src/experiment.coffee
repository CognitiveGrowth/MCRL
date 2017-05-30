###
experiment.coffee
Fred Callaway

Demonstrates the jsych-mdp plugin

###
# coffeelint: disable=max_line_length, indentation
DEBUG = true

experiment_nr = 1

switch experiment_nr
    when 1 then IVs = {PRTypes: ['none','featureBased','fullObservation'], messageTypes: ['full','none'],infoCosts: [0.01,1.60,2.80]}
    when 2 then IVs = {PRTypes: ['featureBased','objectLevel'], messageTypes: ['full'],infoCosts: [0.01,1.60,2.80]}
    when 3 then   IVs = {PRTypes: ['none','featureBased'], messageTypes: ['full','simple'],infoCosts: [1.60]}
    else console.log "Invalid experiment_nr!" 

        
nrDelays = IVs.PRTypes.length    
nrMessages = IVs.messageTypes.length
nrInfoCosts = IVs.infoCosts.length

if experiment_nr is 1
    nrConditions = 3 * 3
else
    nrConditions = nrDelays * nrMessages * nrInfoCosts

conditions = {'PRType':[], 'messageType':[], 'infoCost': []}

for PRType in IVs.PRTypes
    if experiment_nr is 1
        if PRType is 'none'
            messageTypes = ['none']
        else
            messageTypes = ['full']
    else
        messageTypes = IVs.messageTypes
                
        for message in messageTypes            
            for infoCost in IVs.infoCosts                
                conditions.PRType.push(PRType)
                conditions.messageType.push(message)
                conditions.infoCost.push(infoCost)
        
if DEBUG
  console.log """
  X X X X X X X X X X X X X X X X X
   X X X X X DEBUG  MODE X X X X X
  X X X X X X X X X X X X X X X X X
  """
  condition = 0
else
  console.log """
  # =============================== #
  # ========= NORMAL MODE ========= #
  # =============================== #
  """    
    
if mode is "{{ mode }}"
  # Viewing experiment not through the PsiTurk server
  DEMO = true
  condition = 1
  counterbalance = 0


# Globals.
psiturk = new PsiTurk uniqueId, adServerLoc, mode

BLOCKS = undefined
PARAMS = undefined
TRIALS = undefined
N_TRIALS = undefined
# because the order of arguments of setTimeout is awful.
delay = (time, func) -> setTimeout func, time

# $(window).resize -> checkWindowSize 920, 720, $('#jspsych-target')
# $(window).resize()

# $(document).ready ->
$(window).on 'load', ->
  # Load data and test connection to server.
  slowLoad = -> document.getElementById("failLoad").style.display = "block"
  loadTimeout = delay 12000, slowLoad

  psiturk.preloadImages [
    'static/images/example1.png'
    'static/images/example2.png'
    'static/images/example3.png'
    'static/images/money.png'
    'static/images/plane.png'
    'static/images/spider.png'
  ]


  delay 300, ->
    console.log 'Loading data'
    expData = loadJson "static/json/condition_0_0.json"
    console.log 'expData', expData
    #PARAMS = expData.conditions[condition % 3]
    #PARAMS.start_time = Date(Date.now())
    #PARAMS.message = 'full'
    
    condition_nr = condition % nrConditions
    PARAMS={'PR_type': conditions.PRType[condition_nr], 'feedback': conditions.PRType[condition_nr] != "none", 'info_cost': conditions.infoCost[condition_nr], 'message':  conditions.messageType[condition_nr]}
        
    # PARAMS.bonus_rate = .1
    BLOCKS = expData.blocks
    TRIALS = BLOCKS.standard
    psiturk.recordUnstructuredData 'params', PARAMS
    psiturk.recordUnstructuredData 'experiment_nr', experiment_nr
    psiturk.recordUnstructuredData 'condition_nr', condition_nr

    if DEBUG or DEMO
      createStartButton()
    else
      console.log 'Testing saveData'
      ERROR = null
      psiturk.saveData
        error: ->
          console.log 'ERROR saving data.'
          ERROR = true
        success: ->
          console.log 'Data saved to psiturk server.'
          clearTimeout loadTimeout
          delay 500, createStartButton


createStartButton = ->
  if DEBUG
    initializeExperiment()
    return
  document.getElementById("loader").style.display = "none"
  document.getElementById("successLoad").style.display = "block"
  document.getElementById("failLoad").style.display = "none"
  $('#load-btn').click initializeExperiment


initializeExperiment = ->
  console.log 'INITIALIZE EXPERIMENT'

  N_TRIALS = BLOCKS.standard.length

  costLevel =
    switch PARAMS.info_cost
      when 0.01 then 'low'
      when 1.60 then 'med'
      when 2.80 then 'high'
      else throw new Error('bad info_cost')


  #  ======================== #
  #  ========= TEXT ========= #
  #  ======================== #

  # These functions will be executed by the jspsych plugin that
  # they are passed to. String interpolation will use the values
  # of global variables defined in this file at the time the function
  # is called.

  text =
    debug: -> if DEBUG then "`DEBUG`" else ''

    feedback: ->
      if PARAMS.PR_type != "none"
        [markdown """
          # Instructions

          <b>You will receive feedback about your planning. This feedback will
          help you learn how to make better decisions.</b> After each flight, if
          you did not plan optimally, a feedback message will apear. This message
          will tell you two things:

          1. Whether you observed too few relevant values or if you observed
             irrelevant values (values of locations that you cant fly to).
          2. Whether you flew along the best route given your current location and
             the information you had about the values of other locations.

          In the example below, not enough relevant values were observed, and
          as a result there is a 15 second timeout penalty. <b>The duration of
          the timeout penalty is proportional to how poorly you planned your
          route:</b> the more money you could have earned from observing more
          values and/or choosing a better route, the longer the delay. <b>If
          you perform optimally, no feedback will be shown and you can proceed
          immediately.</b> The example message here is not necessarily representative of the feedback you'll receive.

        #{img('task_images/Slide4.png')}

        """]
      else []

    constantDelay: ->
      if PARAMS.PR_type != "none"
        ""
      else
        "Note: there will be short delays after taking some flights."



  # ================================= #
  # ========= BLOCK CLASSES ========= #
  # ================================= #

  class Block
    constructor: (config) ->
      _.extend(this, config)
      @_block = this  # allows trial to access its containing block for tracking state
      if @_init?
        @_init()

  class TextBlock extends Block
    type: 'text'
    cont_key: ['space']

  class QuizLoop extends Block
    loop_function: (data) ->
      console.log 'data', data
      for c in data[data.length].correct
        if not c
          return true
      return false

  class MDPBlock extends Block
    type: 'mouselab-mdp'
    # playerImage: 'static/images/spider.png'
    _init: -> @trialCount = 0


  #  ============================== #
  #  ========= EXPERIMENT ========= #
  #  ============================== #

  debug_slide = new Block
    type: 'html'
    url: 'test.html'



  instructions = new Block
    type: "instructions"
    pages: [
      markdown """
        # Instructions #{text.debug()}

        In this game, you are in charge of flying an aircraft. As shown below,
        you will begin in the central location. The arrows show which actions
        are available in each location. Note that once you have made a move you
        cannot go back; you can only move forward along the arrows. There are
        eight possible final destinations labelled 1-8 in the image below. On
        your way there, you will visit two intermediate locations. <b>Every
        location you visit will add or subtract money to your account</b>, and
        your task is to earn as much money as possible. <b>To find out how much
        money you earn or lose in a location, you have to click on it.</b> You
        can uncover the value of as many or as few locations as you wish.

        #{img('task_images/Slide1.png')}

        To navigate the airplane, use the arrows (the example above is non-interactive).
        You can uncover the value of a location at any time. Click "Next" to proceed.
      """

      markdown """
        # Instructions

        You will play the game for #{N_TRIALS} rounds. The value of every location will
        change from each round to the next. At the begining of each round, the
        value of every location will be hidden, and you will only discover the
        value of the locations you click on. The example below shows the value
        of every location, just to give you an example of values you could see
        if you clicked on every location. <b>Every time you click a circle to
        observe its value, you pay a fee of #{fmtMoney PARAMS.info_cost}.</b>

        #{img('task_images/Slide2_' + costLevel + '.png')}

        Each time you move to a
        location, your profit will be adjusted. If you move to a location with
        a hidden value, your profit will still be adjusted according to the
        value of that location. #{do text.constantDelay}
      """

    ] . concat (do text.feedback) .concat [

      markdown """
        # Instructions

        There are two more important things to understand:
        1. You must spend at least 45 seconds on each round. A countdown timer
           will show you how much more time you must spend on the round. You
           won’t be able to proceed to the next round before the countdown has
           finished, but you can take as much time as you like afterwards.
        2. </b>You will earn <u>real money</u> for your flights.</b> Specifically,
           one of the #{N_TRIALS} rounds will be chosen at random and you will receive 5%
           of your earnings in that round as a bonus payment.

        #{img('task_images/Slide3.png')}

         You may proceed to take an entry quiz, or go back to review the instructions.
      """
    ]
    show_clickable_nav: true


  quiz = new Block
    preamble: -> markdown """
      # Quiz
    """
    type: 'survey-multi-choice'  # note: I've edited this jspysch file
    questions: [
      "True or false: The hidden values will change each time I start a new round."
      "How much does it cost to observe each hidden value?"
      "How many hidden values am I allowed to observe in each round?"
      "How is your bonus determined?"
      ] .concat (if PARAMS.PR_type != "none" then [
        "What does the feedback teach you?"
    ] else [])
    options: [
      ['True', 'False']
      ['$0.01', '$0.05', '$1.60', '$2.80']
      ['At most 1', 'At most 5', 'At most 10', 'At most 15', 'As many or as few as I wish']
      ['10% of my best score on any round'
       '10% of my total score on all rounds'
       '5% of my best score on any round'
       '5% of my score on a random round']
      ['Whether I observed the rewards of relevant locations.'
       'Whether I chose the move that was best according to the information I had.'
       'The length of the delay is based on how much more money I could have earned by planning and deciding better.'
       'All of the above.']
    ]
    required: [true, true, true, true, true]
    correct: [
      'True'
      fmtMoney PARAMS.info_cost
      'As many or as few as I wish'
      '5% of my score on a random round'
      'All of the above.'
    ]
    on_mistake: (data) ->
      alert """You got at least one question wrong. We'll send you back to the
               instructions and then you can try again."""


  instruct_loop = new Block
    timeline: [instructions, quiz]
    loop_function: (data) ->
      for c in data[1].correct
        if not c
          return true  # try again
      psiturk.finishInstructions()
      psiturk.saveData()
      return false


  # for t in BLOCKS.standard
  #   _.extend t, t.stim.env
  #   t.pseudo = t.stim.pseudo


  main = new MDPBlock
    timeline: _.shuffle TRIALS


  finish = new Block
    type: 'button-response'
    stimulus: -> markdown """
      # You've completed the HIT

      Thanks again for participating. We hope you had fun!

      Based on your performance, you will be
      awarded a bonus of **$#{calculateBonus().toFixed(2)}**.
      """
    is_html: true
    choices: ['Submit hit']
    button_html: '<button class="btn btn-primary btn-lg">%choice%</button>'


  if DEBUG
    experiment_timeline = [
      #instruct_loop
      main
      finish
    ]
  else
    experiment_timeline = [
      instruct_loop
      main
      finish
    ]


  # ================================================ #
  # ========= START AND END THE EXPERIMENT ========= #
  # ================================================ #

  # calculateBonus = ->
  #   if BONUS?
  #     return BONUS
  #   data = jsPsych.data.getTrialsOfType 'mouselab-mdp'
  #   bonus = mean (_.pluck data, 'score')
  #   bonus = (Math.round (bonus * 100)) / 100
  #   BONUS =  (Math.max 0, bonus) * PARAMS.bonus_rate
  #   psiturk.recordUnstructuredData 'final_bonus', BONUS
  #   return BONUS

  # bonus is the score on a random trial.
  BONUS = undefined
  calculateBonus = ->
    if DEBUG then return 0
    if BONUS?
      return BONUS
    data = jsPsych.data.getTrialsOfType 'graph'
    BONUS = 0.05 * Math.max 0, (_.sample data).score
    psiturk.recordUnstructuredData 'final_bonus', BONUS
    return BONUS
  

  reprompt = null
  save_data = ->
    psiturk.saveData
      success: ->
        console.log 'Data saved to psiturk server.'
        if reprompt?
          window.clearInterval reprompt
        psiturk.computeBonus('compute_bonus', psiturk.completeHIT)
      error: -> prompt_resubmit


  prompt_resubmit = ->
    $('#jspsych-target').html """
      <h1>Oops!</h1>
      <p>
      Something went wrong submitting your HIT.
      This might happen if you lose your internet connection.
      Press the button to resubmit.
      </p>
      <button id="resubmit">Resubmit</button>
    """
    $('#resubmit').click ->
      $('#jspsych-target').html 'Trying to resubmit...'
      reprompt = window.setTimeout(prompt_resubmit, 10000)
      save_data()

  jsPsych.init
    display_element: $('#jspsych-target')
    timeline: experiment_timeline
    # show_progress_bar: true

    on_finish: ->
      if DEBUG
        jsPsych.data.displayData()
      else
        psiturk.recordUnstructuredData 'final_bonus', calculateBonus()
        save_data()

    on_data_update: (data) ->
      console.log 'data', data
      psiturk.recordTrialData data
      