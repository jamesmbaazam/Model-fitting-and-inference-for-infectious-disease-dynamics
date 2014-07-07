# @knitr generate_samples
trace <- my_mcmcMH(target = my_logPosterior_epi1, # target distribution
                   init.theta = c(R0 = 1, D.inf = 2), # intial parameter guess
                   proposal.sd = c(0.1, 0), # standard deviation of
                       # Gaussian proposals: 0.1 for the first
                       # parameter of init.theta (R0), 0 for the
                       # second (D.inf,  which we keep fixed)
                   n.iterations = 1000) # number of iterations