from collections import namedtuple, defaultdict, deque, Counter
import numpy as np
import gym
from gym import spaces
import itertools as it
from distributions import cmax, smax, expectation, Normal, PointMass
from toolz import memoize, get
import random
from contracts import contract


NO_CACHE = False
if NO_CACHE:
    lru_cache = lambda _: (lambda f: f)
else:
    from functools import lru_cache

CACHE_SIZE = int(2**16)
SMALL_CACHE_SIZE = int(2**14)
ZERO = PointMass(0)

class MetaTreeEnv(gym.Env):
    """MetaMDP for a tree with a discrete unobserved reward function."""
    metadata = {'render.modes': ['human', 'array']}
    term_state = '__term_state__'
    def __init__(self, init, cost=0, sample_term_reward=False,
                 ground_truth=None):

        self.init = init
        self.cost = - abs(cost)
        self.sample_term_reward = sample_term_reward
        self.ground_truth = np.array(ground_truth) if ground_truth is not None else None
        self.term_action = len(self.init)
        

        self.action_space = spaces.Discrete(len(self.init) + 1)
        self.observation_space = spaces.Box(-np.inf, np.inf, shape=len(self.init))

        # self.subtree = self._get_subtree()
        # self.subtree_slices = self._get_subtree_slices()
        self.tree = init.structure

        self.reset()

    def _reset(self):
        self._state = self.init
        return self._state

    def _step(self, action):
        if self._state is self.term_state:
            assert 0, 'state is terminal'

        if action == self.term_action:
            self._state = self.term_state
            reward = self._true_term_reward()
            done = True

        elif not hasattr(self._state[action], 'sample'):  # already observed
            assert 0, f'{action} has already been observed'
            reward = 0
            done = False

        else:  # observe a new node
            self._state = self._state.update(action, self._observe(action))
            reward = self.cost
            done = False

        return self._state, reward, done, {}

    def _true_term_reward(self):
        if self.ground_truth is not None:
            # paths = list(self.optimal_paths())
            assert 0

        if self.sample_term_reward:
            return self.term_reward.sample()
        else:
            return self.term_reward.expectation()
        
        
        # state = self._state
        # if self.sample_term_reward:
        #     if self.ground_truth is not None:
        #         reward = self.ground_truth[list(path)].sum()
        #     else:
        #         reward = self.term_reward().sample()
        # else:
        #     if self.ground_truth is not None:
        #         reward =  np.mean([self.ground_truth[list(path)].sum()
        #                            for path in self.optimal_paths()])

    def _observe(self, action):
        if self.ground_truth is None:
            return self._state[action].sample()
        else:
            return self.ground_truth[action]

    def actions(self, state):
        """Yields actions that can be taken in the given state.

        Actions include observing the value of each unobserved node and terminating.
        """
        if state is self.term_state:
            return
        for i, v in enumerate(state):
            if hasattr(v, 'sample'):
                yield i
        yield self.term_action

    def term_reward(self, state):
        """A distribution over the return gained by acting given a belief state."""
        return self.node_value(0, state)
    
    def optimal_paths(self, state, tolerance=0.01):
        def rec(path):
            children = self.tree[path[-1]]
            if not children:
                yield path
                return
            quals = [self.node_quality(n1, state).expectation()
                     for n1 in children]
            best_q = max(quals)
            for n1, q in zip(children, quals):
                if np.abs(q - best_q) < tolerance:
                    yield from rec(path + (n1,))

        yield from rec((0,))

    @lru_cache(CACHE_SIZE)
    def expected_term_reward(self, state):
        return self.term_reward(state).expectation()

    def node_value(self, node, state=None):
        """A distribution over total rewards after the given node."""
        state = state if state is not None else self._state
        return max((self.node_value(n1, state) + state[n1]
                    for n1 in self.tree[node]), 
                   default=ZERO, key=expectation)
    
    def node_value_to(self, node, state=None):
        """A distribution over rewards up to and including the given node."""
        state = state if state is not None else self._state
        start_value = ZERO
        return sum((state[n] for n in self.path_to(node)), start_value)

    def node_quality(self, node, state=None):
        """A distribution of total expected rewards if this node is visited."""
        state = state if state is not None else self._state
        return self.node_value_to(node, state) + self.node_value(node, state)

    # @lru_cache(CACHE_SIZE)
    @contract
    def myopic_voc(self, action, state) -> 'float, >= -0.001':
        return (self.node_value_after_observe((action,), 0, state).expectation()
                - self.expected_term_reward(state)
                )

    # @lru_cache(CACHE_SIZE)
    @contract
    def vpi_branch(self, action, state) -> 'float, >= -0.001':
        obs = self._relevant_subtree(action)
        return (self.node_value_after_observe(obs, 0, state).expectation()
                - self.expected_term_reward(state)
                )
    
    @contract
    def vpi_action(self, action, state) -> 'float, >= -0.001':
        obs = (*self.subtree[action][1:], *self.path_to(action)[1:])
        return (self.node_value_after_observe(obs, 0, state).expectation()
                - self.expected_term_reward(state)
                )

    @lru_cache(CACHE_SIZE)
    @contract
    def vpi(self, state) -> 'float, >= -0.001':
        obs = self.subtree[0]
        return (self.node_value_after_observe(obs, 0, state).expectation()
                - self.expected_term_reward(state)
                )

    def unclicked(self, state):
        return sum(1 for x in state if hasattr(x, 'sample'))

    def true_Q(self, node):
        """The object-level Q function."""
        r = self.ground_truth[node]
        return r + max((self.true_Q(n1) for n1 in self.tree[node]),
                    default=0)
    
    def worst_Q(self, node):
        """The object-level Q function."""
        r = self.ground_truth[node]
        return r + min((self.worst_Q(n1) for n1 in self.tree[node]),
                    default=0)
    
    def rand_Q(self, node):
        """The object-level Q function."""
        r = self.ground_truth[node]
        lst = [self.rand_Q(n1) for n1 in self.tree[node]]
        if lst:
            return r+random.choice(lst)
        return r 
    
    def mean_Q(self,node):
        r = self.ground_truth[node]
        lst = [self.mean_Q(n1) for n1 in self.tree[node]]
        if lst:
            return r+np.mean(lst)
        return r 
    
    @lru_cache(None) 
    def _relevant_subtree(self, node):
        trees = [self.subtree[n1] for n1 in self.tree[0]]
        for t in trees:
            if node in t:
                return tuple(t)
        assert False

    @lru_cache(None) 
    def leaves(self, node):
        trees = [self.subtree[n1] for n1 in self.tree[0]]
        for t in trees:
            if node in t:
                return tuple(t)
        assert False

    def node_value_after_observe(self, obs, node, state):
        """A distribution over the expected value of node, after making an observation.
        
        obs can be a single node, a list of nodes, or 'all'
        """
        if self._binary:
            obs_flat = self.to_obs_flat(state, node, obs)
            if self.exact:
                return exact_flat_node_value_after_observe(obs_flat)
            else:
                return flat_node_value_after_observe(obs_flat)
        else:
            obs_tree = self.to_obs_tree(state, node, obs)
            if self.exact:
                return exact_node_value_after_observe(obs_tree)
            else:
                return node_value_after_observe(obs_tree)

    @memoize
    def path_to(self, node, start=0):
        path = [start]
        if node == start:
            return path
        for _ in range(self.height + 1):
            children = self.tree[path[-1]]
            for i, child in enumerate(children):
                if child == node:
                    path.append(node)
                    return path
                if child > node:
                    path.append(children[i-1])
                    break
            else:
                path.append(child)
        assert False

    def all_paths(self, start=0):
        def rec(path):
            children = self.tree[path[-1]]
            if children:
                for child in children:
                    yield from rec(path + [child])
            else:
                yield path

        return rec([start])

    def _get_subtree_slices(self):
        slices = [0] * len(self.tree)
        def get_end(n):
            end = max((get_end(n1) for n1 in self.tree[n]), default=n+1)
            slices[n] = slice(n, end)
            return end
        get_end(0)
        return slices

    def _get_subtree(self):
        def gen(n):
            yield n
            for n1 in self.tree[n]:
                yield from gen(n1)
        return [tuple(gen(n)) for n in range(len(self.tree))]


    def _render(self, mode='notebook', close=False):
        if close:
            return
        from graphviz import Digraph
        from IPython.display import display
        import matplotlib as mpl
        from matplotlib.colors import rgb2hex
        
        vmin = -2
        vmax = 2
        norm = mpl.colors.Normalize(vmin=vmin, vmax=vmax)
        cmap = mpl.cm.get_cmap('RdYlGn')
        colormap = mpl.cm.ScalarMappable(norm=norm, cmap=cmap)
        colormap.set_array(np.array([vmin, vmax]))

        def color(val):
            if val > 0:
                return '#8EBF87'
            else:
                return '#F7BDC4'
        
        dot = Digraph()
        for x, ys in enumerate(self.tree):
            r = self._state[x]
            observed = not hasattr(self._state[x], 'sample')
            c = color(r) if observed else 'grey'
            l = str(round(r, 2)) if observed else str(x)
            dot.node(str(x), label=l, style='filled', color=c)
            for y in ys:
                dot.edge(str(x), str(y))
        display(dot)

    def to_obs_tree(self, state, node, obs=(), sort=True):
        maybe_sort = sorted if sort else lambda x: x
        def rec(n):
            subjective_reward = state[n] if n in obs else expectation(state[n])
            children = tuple(maybe_sort(rec(c) for c in self.tree[n]))
            return (subjective_reward, children)
        # return obs_rec(self.tree, state, obs, node)
        return rec(node)


class Tree(object):
    def __init__(self, val, children):
        self.val = val
        self.children = children

    @memoize
    def __len__(self):
        return 1 + sum(len(c) for c in self.children)

    def __hash__(self):
        return id(self)
        # return hash(self.vals) + hash(self.structure)
    
    @memoize
    def update(self, address, val):
        if address:
            children = list(self.children)
            first, rest = address[0], address[1:]
            children[first] = children[first].update(rest, val)
            return Tree(self.val, children)
        else:
            return Tree(val, self.children)
    
    def leaves(self):
        pass

    def paths(self):
        pass

    def value(self):
        return max((child.value() + child.val for child in self.children),
                    default=ZERO, key=expectation)

    def obs_value(self):
        return cmax((child.value() + child[0] for child in self.children),
                    default=ZERO)

    @classmethod
    def build(cls, branching, value):
        if not callable(value):
            val = value
            value = lambda depth: val

        def rec(d):
            v = value(d)
            if d == len(branching):
                children = []
            else:
                children = [rec(d+1) for _ in range(branching[d])]
            return Tree(v, children)

        return rec(0)

    def __repr__(self):
        return 'Tree'

    def __str__(self):
        children = tuple(str(c) for c in self.children)
        return f'({self.val}, {children})'

    def as_tuple(self):
        return (self.vals[0],
                tuple(child.as_tuple() for child in self.children))

    def draw(self):
        from graphviz import Digraph
        from IPython.display import display
        
        def color(val):
            if val > 0:
                return '#8EBF87'
            else:
                return '#F7BDC4'
        
        dot = Digraph()
        def rec(tree):
            dot.node(str(id(tree)), label=repr(tree.val))
            for child in tree.children:
                dot.edge(str(id(tree)), str(id(child)))
                rec(child)

        rec(self)
        display(dot)
        







def tree_value(tree):
    return 


# @lru_cache(SMALL_CACHE_SIZE)
def obs_tree_value(tree):
    """A distribution over the expected value of node, after making an observation.
    
    """
    children = tuple(obs_tree_value(c) + c[0] for c in tree)
    return cmax(children, default=ZERO)



