addpath('../MatlabTools/')
addpath('/Users/Falk/Dropbox/PhD/Metacognitive RL/MCRL/matlab_code/Mouselab/')
load low_cost_condition
load medium_cost_condition
load high_cost_condition

low_costs=[0.01]; %[0.01,2.80]
medium_costs=[0.25,0.50,0.75,1];
high_costs=[1.50,2,2.50,3];

parfor c=1:numel(low_costs)
    policySearchMouselabMDP(low_costs(c),low_cost_condition,'low_cost')
end

parfor c=1:numel(medium_costs)
    policySearchMouselabMDP(medium_costs(c),medium_cost_condition,'medium_cost')
end

parfor c=1:numel(high_costs)
    policySearchMouselabMDP(high_costs(c),high_cost_condition,'high_cost')
end

%%
clear

%condition='lowCost';

addpath([pwd,'/MatlabTools/'])
%create meta-level MDP

add_pseudorewards=false;
pseudoreward_type='none';

mean_payoff=4.5;
std_payoff=10.6;

conditions={'mediumCost','highCost','lowCost'};

for c=1:numel(conditions)
    
    condition=conditions{c};
    
    if strcmp(condition,'highCost')
        %load high_cost_condition
        %experiment = high_cost_condition;
        cost = 2.50;
        
        temp=load(['../../results/BO/BO_c250n50high_cost.mat']);
        w_policy=temp.BO.w_hat;
        
    end
    
    if strcmp(condition,'mediumCost')
        %load medium_cost_condition
        %experiment = medium_cost_condition;
        cost = 1.00;
        
        temp=load(['../../results/BO/BO_c100n100medium_cost.mat']);
        w_policy=temp.BO.w_hat;
    end
    
    if strcmp(condition,'lowCost')
        %load low_cost_condition
        %experiment = low_cost_condition;
        cost=0.01;
        
        temp=load(['../../results/BO/BO_c1n100low_cost.mat']);
        w_policy=temp.BO.w_hat;
    end
    
    load ControlExperiment
    experiment = control_experiment;
    actions_by_state{1}=[];
    actions_by_state{2}=[1];
    actions_by_state{3}=[2];
    actions_by_state{4}=[3];
    actions_by_state{5}=[4];
    actions_by_state{6}=[1,1];
    actions_by_state{7}=[2,2];
    actions_by_state{8}=[3,3];
    actions_by_state{9}=[4,4];
    actions_by_state{10}=[1,1,2];
    actions_by_state{11}=[1,1,4];
    actions_by_state{12}=[2,2,3];
    actions_by_state{13}=[2,2,4];
    actions_by_state{14}=[3,3,2];
    actions_by_state{15}=[3,3,4];
    actions_by_state{16}=[4,4,3];
    actions_by_state{17}=[4,4,1];
    for e=1:numel(experiment)
        experiment(e).actions_by_state=actions_by_state;
        experiment(e).hallway_states=2:9;
        experiment(e).leafs=10:17;
        experiment(e).parent_by_state={1,1,1,1,1,2,3,4,5,6,6,7,7,8,8,9,9};
    end
    
    training_data1=load('~/Dropbox/PhD/Metacognitive RL/mcrl-experiment/1E_state-action_pairs/stateActions_0.mat');
    training_data2=load('~/Dropbox/PhD/Metacognitive RL/mcrl-experiment/1E_state-action_pairs/stateActions_2.mat');
    
    training_data.trialID=[training_data1.trialID,training_data2.trialID];
    training_data.trialNr=[training_data1.trialNr,training_data2.trialNr];
    training_data.state_actions=[training_data1.state_actions,training_data2.state_actions];
    training_data.rewardSeen=[training_data1.rewardSeen,training_data2.rewardSeen];
    training_data.trials=experiment;    
    
    %costs=[0.01,1.60,2.80];
    %w_observe_everything=[1;1;1];
    %w_observe_nothing=[-1.3;0.4;0.3];
    
    %[ER_hat_everything,result_everything]=evaluatePolicy(w_observe_everything,0.01,1000)
    %[ER_hat_nothing,result_nothing]=evaluatePolicy(w_observe_nothing,2.80,1000)
    
    nr_episodes=numel(training_data.trialNr);
    %parfor c=1:numel(costs)
    
    glm_policy=BayesianGLM(4,1e-6);
    glm_policy.mu_n=w_policy;
    glm_policy.mu_0=w_policy;
    
    meta_MDP=MouselabMDPMetaMDPNIPS(add_pseudorewards,pseudoreward_type,mean_payoff,std_payoff,experiment);
    meta_MDP.cost_per_click=cost;
    
    feature_extractor=@(s,c,meta_MDP) meta_MDP.extractStateActionFeatures(s,c);
    
    [glm_Q(c),MSE(:,c),R_total(:,c)]=BayesianValueFunctionRegression(meta_MDP,feature_extractor,nr_episodes,glm_policy,training_data)
end
%end
fit.glm=glm_Q; fit.MSE=MSE; fit.R_total=R_total;
save ../../results/BO/valueFunctionFitConditionSpecific.mat fit