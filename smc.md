# Particle filter

## Coding the particle filter

Copy and past the skeleton of the particle filter algorithm on your R script file.


```r
# The particle filter returns an estimate of the marginal log-likelihood.
# It takes two arguments as inputs
# fitmodel: your fitmodel object
# n.particles: number of particles

my_particleFilter <- function(fitmodel, n.particles)
{

    ############################################################################################
    ## This function compute the marginal log.likelihood of the data (fitmodel$data) 
    ## given the parameters (fitmodel$theta) using a particle filter
    ############################################################################################

    ############################################################################################
    ## Initialisation of the algorithm
    ############################################################################################

    ## Initialise the state and the weight of your particles

    ############################################################################################
    # Start for() loop over observation time
    ############################################################################################

        ## Resample particles according to their weight
        ## you can use the `sample() function of R

        ########################################################################################
        # Start for() loop over particles
        ########################################################################################

            ## Propagate particles from current observation time to the next one
            ## using the function `fitmodel$simulation.model`

            ## Weight particles according to the likelihood of the data
            ## using the function `fitmodel$log.likelihood`

        ########################################################################################
        # End for() loop over particles
        ########################################################################################

        ## Update the estimate of the marginal log-likelihood
        ## by adding the log of the mean of the particles weights

    ############################################################################################
    # End for() loop over observation time
    ############################################################################################

    ## Compute and return the marginal log-likelihood (sum(log(mean(particle weight at time i))))

}
```

If you have trouble in writing the algorithm from scratch, you can use our more guided [example](smc_example.md).

## Using the particle filter


```r
my_seitlSto <- createSEITL(deterministic=FALSE)
log.like <- my_particleFilter(fitmodel=my_seitlSto, n.particles=10)
```

The particle filter returns a Monte-Carlo estimates of the log-likelihood and the precision of this estimate is proportional to the number of particles.

If you have too few particles then you will have a highly variable estimate of the log-likelihood and this will make the exploration of the likelihood surface quite unprecise. In addition, you might experience particle depletion (if you don't know what that means just try to run it with a single particle).

If you have too many particles, then you will have a very good estimate of your log-likelihood but it will be very time consuming so inefficient in practice.

So ideally you want just enough particles to have a fairly stable estimates of your log-likelihood. Can you think on an idea how to calibrate the number of particles?


## Plug the particle filter into your MCMC.

You can now write a new posterior function that will make use of `my_particleFilter`. Then you'll be able to use your `mcmc` to sample from this posterior and fit your SEITL stochastic model to the Tristan da Cunha outbreak.

## Going further

* Actually, in addition to the log-likelihood, a particle filter can also return the filtered trajectories (i.e. all the trajectories that "survived" until the last observation time). You can update your filter so it keeps track and returns these filtered trajectories. Alternatively, there is a function in the package that will do it for you (see `?bootstrapParticleFilter`).
* You might have noted that the `for()` loop over particles could be parallelized, as particles can be propagated independently. You could take advantage of this to code a parallel loop and make your algorithm even faster. If you have never coded a parallel program in R you can also have a look at the code of `bootstrapParticleFilter`.

Previous: [Tristan da Cunha outbreak](play_with_seitl.md)
