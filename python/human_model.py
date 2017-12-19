from skopt import gp_minimize
import numpy as np

from evaluation import get_util
from policies import Policy
from contexttimer import Timer
from joblib import Parallel, delayed
from toolz import curry

import warnings
warnings.filterwarnings("ignore",
    message="The objective has been evaluated at this point before.")

from pymc3.distributions.continuous import Continuous
import theano.tensor as tt

def softmax(x, temp=1):
    ex = np.exp((x - x.max()) / temp)
    return ex / ex.sum()

def zero_pad(size, x):
    return np.r_[x, np.zeros(size - len(x))]

@curry
def path_features(env, state, path):
    val = env.node_value_to(path[-1], state=state)
    # m = val.mean / (max(env.reward.vals) * len(path))
    # s = val.std / env.node_value_to(path[-1], state=env.init).std
    m = val.mean / env.reward.std
    s = val.std
    return [m, s, m * s]

@curry
def action_features(env, state, action, max_paths=2):
    term = (action == env.term_action)
    if not (term or hasattr(state[action], 'sample')):
        # Clicking an already revealed node, an invalid action
        return np.zeros(2 + max_paths * 3)

    node_features = ([] if term else 
                     np.concatenate(sorted(map(path_features(env, state), 
                                               env.all_paths(start=action)))))
                             
    return np.array([
        env.expected_term_reward(state) if term else 0,
        int(not term), 
        *zero_pad(max_paths * 3, node_features)
     ])


class HumanModel(Continuous):
    """docstring for HumanModel"""
    def __init__(self, policy):
        super().__init__()
        self.policy = policy

    def logp(self, value):
        state, action = value
        return tt.log(self.policy.act(state)[action])

    def random(self, point=None, size=None, repeat=None):
        pass
      

class HumanPolicy(Policy):
    def __init__(self, theta, temp=0):
        super().__init__()
        self.theta = np.array(theta)
        self.temp = temp

    def attach(self, agent):
        super().attach(agent)
        self.max_paths = len(list(self.env.all_paths(start=1)))
        
    def act(self, state):
        if self.temp == 0:
            return max(self.env.actions(state), key=self.Q(state))
        else:
            assert 0

    def action_distribution(self, state):
        q = np.zeros(self.n_action)
        for a in self.env.actions(state):
            q[a] = self.Q(state, a)
        # return q
        return softmax(q, self.temp)
    
    @curry
    def Q(self, state, action):
        phi = action_features(self.env, state, action, self.max_paths)
        return np.dot(self.theta, phi)

    def phi(self, state, action):
        return action_features(self.env, state, action, self.max_paths)


    @classmethod
    def optimize(cls, envs, n_jobs=None, verbose=False, **kwargs):
        if n_jobs is not None:
            parallel = Parallel(n_jobs=n_jobs)
        else:
            parallel = None

        def objective(x):
            theta = np.r_[1, x]  # term_reward weight fixed to 1
            with Timer() as t:
                util = get_util(cls(theta), envs, parallel)
            if verbose:
                print(np.array(theta).round(3), '->', round(util, 3),
                      'in', round(t.elapsed), 'sec')
            return - util

        max_paths = len(list(envs[0].all_paths(start=1)))

        bounds = [
            (-5., 5.),                      # is click
            *([(-1., 1.)] * max_paths * 3)  # node_features
        ]
        with Timer() as t:
            result = gp_minimize(objective, bounds, **kwargs)
        theta = np.r_[1, result.x]
        util = -result.fun

        print('BO:', theta.round(3), '->', round(util, 3),
              'in', round(t.elapsed), 'sec')
        return cls(theta)
