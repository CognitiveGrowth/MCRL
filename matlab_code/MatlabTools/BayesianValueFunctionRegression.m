function [glm_Q,MSE,R_total]=BayesianValueFunctionRegression(mdp,feature_extractor,nr_episodes,glm_policy,training_data)
%Bayesian regression is used to estimate the value function of the policy
%defined by Thompson sampling with the supplied GLM.
%inputs:
%  1. mdp: object of whose class implements the interface MDP
%  2. feature_extractor: a function that returns the state x features matrix
%  of state features when given a vector of states as its input
%  3. nr_episodes: number of training episodes
%  4. epsilon: probability that the epsilon-greedy policy will choose an
%  action at random

%outputs:
%  1. glm: GLM with posterior distribution on the feature weights
%  2. avg_MSE: average mean-squared error in the prediction of the state
%  value by training episode.

mdp.object_level_MDP=mdp.object_level_MDPs(1);
[s0,mdp0]=mdp.newEpisode();
actions=mdp0.actions;

mu=zeros(size(feature_extractor(s0,actions(1),mdp)));
nr_features=length(mu);
glm_Q=BayesianGLM(nr_features,0.1);

w_old(:,1)=mu;

avg_MSE=zeros(nr_episodes,1);

R_total=zeros(nr_episodes,1);


nr_observations=0;

nr_training_examples=length(training_data.state_actions);
training_data_order=shuffle(1:nr_training_examples);

for i=1:nr_episodes
    rewards=zeros(0,1);
    F=zeros(0,nr_features);
    
   %[s,mdp]=mdp.randomStart();
   %Get the state in which the i-th action was taken
   [s,mdp]=mdp.getStateFromActionSequence(training_data,training_data_order(i)-1);
   
   if s.step>s.nr_steps
       continue;
   end
   
    t=0; %time step within episode

    while not(mdp.isTerminalState(s))
        t=t+1;
                
        %1. Choose first action according to what the participant did and
        %choose subsequent actions according to the policy to be evaluated        
        if t==1
            action_id=training_data.state_actions(training_data_order(i));
            
            is_click=action_id<100;
            
            if is_click
                %participant chose a click
                action = struct('is_decision_mechanism',false,...
                'is_computation',true,'planning_horizon',0,'decision',0,...
                'from_state',s.s,'move',0,'state',action_id);
            else
                %participant chose a move
                c_move=find(mdp.object_level_MDP.T(s.s,action_id-100,:));
                action = struct('is_decision_mechanism',true,...
                'is_computation',false,'planning_horizon',0,'decision',c_move,...
                'from_state',s.s,'move',c_move,'state',action_id-100);                
            end
            
        else
            action=contextualThompsonSampling(s,mdp,glm_policy);
        end
        
        features=feature_extractor(s,action,mdp)';
        F=[F;features];
        
        %2. Observe outcome
        [r,s,PR]=mdp.simulateTransition(s,action);
        rewards=[rewards;r];
        
        R_total(i)=R_total(i)+r;
        nr_observations=nr_observations+1;
                
        %value_estimate=dotglm_Q.mu_n*features
        %PE=value_estimate-dot(glm_Q.mu_n,features);
        
        %avg_MSE(i)=((t-1)*avg_MSE(i)+PE^2)/t;
        
        if any(or(isnan(glm_Q.mu_n),isinf(glm_Q.mu_n)))
            throw(MException('MException:isNaN','MSE is NaN'))
        end
    end
    
    nr_actions_in_episode=size(rewards,1);
    returns=zeros(nr_actions_in_episode,1);
    for a=1:nr_actions_in_episode
        returns(a,1)=sum(rewards(a:end));
    end
    predicted_returns=F*glm_Q.mu_n;
    MSE(i)=norm(predicted_returns-returns)^2/nr_actions_in_episode;
    
    glm_Q=glm_Q.update(F(1,:),returns(1));
    
    if mod(i,250)==0
        disp(['Completed episode ',int2str(i),', dw=',num2str(norm(glm_Q.mu_n(:)-w_old(:))),', w_old: ',mat2str(roundsd(w_old(:),4)),'',...
            ', w_new=',mat2str(roundsd(glm_Q.mu_n(:),4))])
        w_old=glm_Q.mu_n(:);
    end
    %disp(['MSE=',num2str(avg_MSE(i)),', |mu_n|=',num2str(norm(glm.mu_n)),', return: ',num2str(R_total(i))])
end

end