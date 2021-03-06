import sys
import numpy as np
import scipy.misc
import scipy.io
import matplotlib.pyplot as plt

def n_bib(balls,bins):
    return scipy.misc.comb(balls+bins-1,balls)

def n_st(n_balls,n_arms): #excluding terminal state
    return int(np.sum([n_bib(i,n_arms*2) for i in range(n_balls+1)]))

def check(T,b):
    a = np.where(np.all(T==b,axis=1))
    if len(a[0]) > 0:
        return a[0][0]
    else:
        return -1

def states(n_balls,n_arms):

    S = np.ones((1,n_arms*2),dtype=np.int) # Matrix of all possible states

    n_states = n_st(n_balls,n_arms) # Number of all possible states

    balls = 0 # Counter for which observation is happening
    ipb = 0 # Index of previous basis
    count_added = 0 # Number of states added with the current number of balls
    state_count = 0

    while balls < n_balls:
        for j in range(count_added+1): # Use each of the states added with balls-1 observations as bases
            for i in range(n_arms*2): # Distribute the ball to each bin
                new = S[ipb].copy() # Copy the previous basis

                # Prepare and add the new state generated by the observation
                new[i] += 1
                k = check(S,new)

                if k == -1: #If it isn't already added
                    S = np.vstack((S,new))
                    count_added += 1
                    state_count += 1
            count_added -= 1 # Remove the added one to balance after the initial case
            ipb += 1 # Move down the previously added states at observation balls-1
        balls += 1

    S = np.vstack((S,-np.ones((1,n_arms*2)))) #Add the terminal state
    print('done!')
    return S

if __name__ == '__main__':
    n_balls=int(sys.argv[1])
    n_arms=int(sys.argv[2])
    print(n_balls,n_arms)
    print(n_st(n_balls,n_arms))
    s = states(n_balls,n_arms)
    np.savetxt("states"+str(n_arms)+str(n_balls)+".csv", s ,delimiter=',', fmt='%i')
