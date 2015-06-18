#'Bootstrap Particle Filter for fitmodel object
#'
#'The bootstrap particle filter returns an estimate of the marginal log-likelihood \eqn{L = p(y(t_{1:T})|\theta)}
#'as well as the set of filtered trajectories and their respective weights at the last observation time \eqn{\omega(t_T)=p(y(t_T)|\theta)}.
#' @param n.particles number of particles
#' @param progress if \code{TRUE} progression of the filter is displayed in the console.
#' @param n.cores number of cores on which propogation of the particles is parallelised. By default no parallelisation (\code{n.cores=1}). If \code{NULL}, set to the value returned by \code{\link[parallel]{detectCores}}.
#' @inheritParams marginalLogLikelihoodDeterministic
#' @note An unbiased state sample \eqn{x(t_{0:T}) ~ p(X(t_{0:T})|\theta,y(t_{0:T}))} can be obtained by sampling the set of trajectories \code{traj} with probability \code{traj.weight}.
#' @export
#' @seealso plotSMC
#' @import parallel doParallel
#' @return A list of 3 elements:
#' \itemize{
#' \item \code{log.likelihood} the marginal log-likelihood of the theta.
#' \item \code{traj} a list of size \code{n.particles} with all filtered trajectories.
#' \item \code{traj.weight} a vector of size \code{n.particles} with the normalised weight of the filtered trajectories.
#' }
bootstrapParticleFilter <- function(fitmodel, n.particles, progress = FALSE, n.cores = 1)
{

    if(is.null(n.cores)){
        n.cores <- detectCores()
        # cat("SMC runs on ",n.cores," cores\n")
    }

    if(n.cores > 1){
        registerDoParallel(cores=n.cores)
    }

    ## compute the log.likelihood using a particle filter

    # useful variable (avoid repetition of long names)
    data <- fitmodel$data
    theta <- fitmodel$theta

    # initialisation

    # marginal log-likelihood of the theta
    log.likelihood <- 0

    # initial state of particles
    initialise.particle  <- fitmodel$initialise.state(theta)
    current.state.particles <- rep(list(initialise.particle),n.particles)

    # filtered trajectories (just add time variable to initial state)
    traj.particles <- rep(list(data.frame(t(c(time=0,initialise.particle)))),n.particles)

    # weight of particles
    weight.particles <- rep(1/n.particles,length=n.particles)

    if(progress){
        # help to visualise progression of the filter
        progress.bar <- txtProgressBar(min=1, max= nrow(data))
    }

    # particle filter
    for(i in seq_len(nrow(data))){

        # initial + observation times
        times <- c(ifelse(i==1,0,data$time[i-1]),data$time[i])

        if(!all(weight.particles==0)){
            # resample particles according to their weight (normalization is done in the function sample())
            index.resampled <- sample(x=n.particles,size=n.particles,replace=T,prob=weight.particles)
        }else{
            warning("All particles depleted at step ",i," of SMC. Return log.likelihood = -Inf for theta set: ",paste(getParameterValues(theta),collapse=", "))
            return(list(log.likelihood=-Inf,traj=NA,traj.weight=NA))
        }

        # update traj and current state after resampling
        traj.particles <- traj.particles[index.resampled]
        current.state.particles <- current.state.particles[index.resampled]

        # propagate particles (this for loop could be parallelized)
        propagate <- llply(current.state.particles,function(current.state) {

            # simulate from previous observation to current observation time
            traj <- fitmodel$simulate.model(theta=theta,state.init=unlist(current.state),times=times)

            # compute particle weight
            weight <- exp(fitmodel$log.likelihood( data=data, model.traj=traj, theta= theta))

            return(list(traj=traj[-1,],weight=weight))

        },.parallel=(n.cores > 1))

        # collect parallel jobs
        current.state.particles <- llply(propagate,function(x) {x$traj[fitmodel$state.variables]})
        weight.particles <- unlist(llply(propagate,function(x) {x$weight}))
        traj.particles <- llply(seq_along(propagate),function(j) {rbind(traj.particles[[j]],propagate[[j]]$traj)})

        # update marginal log-likelihood
        log.likelihood <- log.likelihood + log(mean(weight.particles))

        if(progress){
            # advance progress bar
            setTxtProgressBar(progress.bar, i)
        }
    }

    if(progress){
        close(progress.bar)
    }

    # return marginal log-likelihood, filtered trajectories, normalised weight of each trajectory
    ans <- list(log.likelihood=log.likelihood,traj=traj.particles,traj.weight=weight.particles/sum(weight.particles))

    return(ans)

}