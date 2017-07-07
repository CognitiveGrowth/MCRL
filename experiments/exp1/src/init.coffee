DEBUG = true

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


experiment_nr = 2

switch experiment_nr
    when 0 then IVs = {frequencyOfFB : ['after_each_move'], PRTypes: ['none','featureBased','fullObservation'], messageTypes: ['full','none'],infoCosts: [0.01,2.80]}    
    when 0.6 then IVs = {frequencyOfFB : ['after_each_move'], PRTypes: ['featureBased','none'], messageTypes: ['full','none'],infoCosts: [0.01,1.00,2.50]}
    when 0.9 then IVs = {frequencyOfFB : ['after_each_move'], PRTypes: ['featureBased','none','object_level'], messageTypes: ['full'],infoCosts: [0.01,1.00,2.50]}    
    when 1 then IVs = {frequencyOfFB : ['after_each_move'], PRTypes: ['none','featureBased','objectLevel'], messageTypes: ['full','none'],infoCosts: [0.01,1.00,2.50]}
    when 2 then   IVs = {frequencyOfFB : ['after_each_move'], PRTypes: ['none','featureBased'], messageTypes: ['full','simple'],infoCosts: [1.00]}
    when 3 then IVs = {frequencyOfFB : ['after_each_move','after_each_click'], PRTypes: ['featureBased'], messageTypes: ['none'],infoCosts: [1.00]}      
    else console.log "Invalid experiment_nr!" 
        
nrDelays = IVs.PRTypes.length    
nrMessages = IVs.messageTypes.length
nrInfoCosts = IVs.infoCosts.length


nrConditions = switch experiment_nr
    when 0 then 6
    when 0.6 then 6
    when 0.9 then 6
    when 1 then 3 * 3
    else nrDelays * nrMessages * nrInfoCosts

conditions = {'PRType':[], 'messageType':[], 'infoCost': [], 'frequencyOfFB': []}

for PRType in IVs.PRTypes
    if experiment_nr <= 1
        if PRType is 'none'
            messageTypes = ['none']
        else
            messageTypes = ['full']
    else
        messageTypes = IVs.messageTypes
                
    for message in messageTypes            
        for infoCost in IVs.infoCosts      
            for frequency in IVs.frequencyOfFB
                conditions.PRType.push(PRType)
                conditions.messageType.push(message)
                conditions.infoCost.push(infoCost)
                conditions.frequencyOfFB.push(frequency)
        

PARAMS =
  PR_type: conditions.PRType[condition % nrConditions]
  feedback: conditions.PRType[condition % nrConditions] != "none"
  info_cost: conditions.infoCost[condition % nrConditions]
  message:  conditions.messageType[condition % nrConditions]
  frequencyOfFB: conditions.frequencyOfFB[condition% nrConditions]
  condition: condition

# if DEBUG
  # PARAMS.message = 'full'
  # PARAMS.info_cost = 2.50
  # PARAMS.PR_type = 'featureBased'

console.log 'PARAMS', PARAMS
COST_LEVEL =
  switch PARAMS.info_cost
    when 0.01 then 'low'
    when 1.00 then 'med'
    when 2.50 then 'high'
    else throw new Error('bad info_cost')