#'Plot one or more model trajectories
#'
#'This function use faceting to plot all state.variables trajectories. Convenient to see results of several simulations.
#' @param fitmodel a \code{\link{fitmodel}} object.
#' @param traj data.frame, output of \code{fitmodel$simulate.model} or \code{simulateModelReplicates}.
#' @param state.variables subset of state.variables to plot. If \code{NULL} (default) all state variables are plotted.
#' @param alpha transparency of the trajectories (between 0 and 1).
#' @param plot if \code{TRUE} the plot is displayed, and returned otherwise.
#' @export
#' @import reshape2 ggplot2
#' @seealso simulateModelReplicates
plotModelTraj <- function(fitmodel,traj,state.variables=NULL,alpha=1, plot=TRUE) {

    if(is.null(state.variables)){
        state.variables <- fitmodel$state.variables
    }

    if(!"replicate"%in%names(traj) && !any(duplicated(traj$time))){
        traj$replicate <- 1
    }

    df <- melt(traj,measure.vars=state.variables)

    p <- ggplot(df,aes(x=time,y=value,group=replicate))+facet_wrap(~variable)
    p <- p + geom_line(alpha=alpha)
    p <- p + theme_bw()

    if(plot){
        print(p)
    }else{
        return(p)
    }

}



#'Plot fit of model to data
#'
#'Simulate the model under \code{theta}, generate observation and plot against data. Since simulation and observation processes can be stochastic, \code{n.replicates} can be plotted.
#' @param n.replicates numeric, number of replicated simulations.
#' @inheritParams marginalLogLikelihoodDeterministic
#' @inheritParams plotModelTraj
#' @export
#' @import plyr ggplot2 
#' @return if \code{plot==FALSE}, a list of 2 elements is returned:
#' \itemize{
#'     \item \code{simulations} \code{data.frame} of \code{n.replicates} simulated observations.
#'     \item \code{plot} the plot of the fit.
#' }
plotThetaFit <- function(theta,fitmodel,n.replicates=1, alpha=min(1,10/n.replicates), plot=TRUE) {

    if(is.null(fitmodel$data)){
        stop(sQuote("fitmodel")," argument must have a ",sQuote("data"),call.=FALSE)
    }

    replicates <- 1:n.replicates
    names(replicates) <- replicates

    times <- c(0, fitmodel$data$time)

    cat("Simulate ",n.replicates," replicate(s)\n")
    fit <- ldply(replicates,function(i) {

        # simulate model at successive observation times of data
        traj <- fitmodel$simulate.model(theta,fitmodel$initialise.state(theta),times)

        # generate observation
        traj.obs <- fitmodel$generate.observation(traj,theta)

        return(traj.obs)        

    },.progress="text",.id="index")

    p <- ggplot()
    p <- p + geom_line(data=fit,aes(x=time,y=observation,group=index),alpha=alpha)
    p <- p + geom_point(data=fitmodel$data,aes(x=time,y=Inc),colour="red")
    p <- p + theme_bw()

    if(plot){
        print(p)        
    } else {
        return(list(simulations=fit,plot=p))        
    }

}


#'Plot result of SMC
#'
#'Plot the observation generated by the filtered trajectories together with the data.
#' @param smc output of \code{\link{bootstrapParticleFilter}}
#' @inheritParams plotModelTraj
#' @export
#' @import ggplot2 plyr
#' @seealso bootstrapParticleFilter
plotSMC <- function(smc,fitmodel,alpha=1,plot=TRUE) {

    traj <- smc$traj
    names(traj) <- 1:length(traj)

    traj <- ldply(traj,function(df) {
        return(fitmodel$generate.observation(df,fitmodel$theta))
    },.id="particle")

    p <- ggplot()
    p <- p + geom_line(data=traj,aes(x=time,y=observation,group=particle),alpha=alpha)
    p <- p + geom_point(data=fitmodel$data,aes(x=time,y=Inc),colour="red")
    p <- p + theme_bw()

    if(plot){
        print(p)
    }else{
        return(p)
    }

}


#'Plot MCMC trace
#'
#'Plot the traces of all estimated variables.
#' @param trace a \code{data.frame} with one column per estimated parameter, as returned by \code{\link{burnAndThin}}
#' @param estimated.only logical, if \code{TRUE} only estimated parameters are displayed.
#' @export
#' @import ggplot2 reshape2
#' @seealso burnAndThin
plotTrace <- function(trace, estimated.only = FALSE){

    if(estimated.only){
        is.fixed <- apply(trace,2,function(x) {length(unique(x))==1})
        trace <- trace[,-which(is.fixed)]
    }

    df <- melt(trace,id.vars="iteration")

    # density
    p <- ggplot(df,aes(x=iteration,y=value))+facet_wrap(~variable,scales="free")
    p <- p+geom_line(alpha=0.75)
    print(p)

}

#'Plot MCMC posterior densities
#'
#'Plot the posterior density of all estimated variables.
#' @inheritParams plotTrace
#' @export
#' @import ggplot2 reshape2
#' @seealso burnAndThin
plotPosteriorDistribution <- function(trace, estimated.only = FALSE){

    if(estimated.only){
        is.fixed <- apply(trace,2,function(x) {length(unique(x))==1})
        trace <- trace[,-which(is.fixed)]
    }


    df <- melt(trace,id.vars="iteration")

    # density
    p <- ggplot(df,aes(x=value))+facet_wrap(~variable,scales="free")
    p <- p+geom_histogram(aes(y=..density..),alpha=0.75)
    p <- p+geom_density()
    print(p)

}


#'Plot MCMC posterior fit
#'
#'Plot posterior distribution of observation generated under model's posterior parameter distribution.
#' @param posterior.median logical, if \code{TRUE} use the median of the posterior distribution.
#' @param summary logical, if \code{TRUE} trajectories are summarised by their mean, median, 50\% and 95\% quantile distributions. Otheriwse, the trajectories are ploted.
#' @param sample.size number of replicated simulations (if \code{posterior.median=TRUE}) or number of theta sampled from posterior distribution (if \code{posterior.median=TRUE}).
#' @inheritParams plotTrace
#' @inheritParams plotModelTraj
#' @export
#' @import ggplot2 plyr
#' @return If \code{plot==FALSE}, a list of 2 elements is returned:
#'\itemize{
#'    \item \code{posterior.traj} a \code{data.frame} with the trajectories (and observations) sampled from the posterior distribution.
#'    \item \code{plot} the plot of the fit displayed.
#'}
plotPosteriorFit <- function(trace, fitmodel, posterior.median=FALSE, summary=FALSE, sample.size = 100, alpha=min(1,10/sample.size), plot=TRUE) {

    sample.size <- min(c(sample.size,nrow(trace)))

    index <- sample(1:nrow(trace),sample.size)
    names(index) <- index

    # names of estimated theta
    names.theta <- names(fitmodel$theta)

    # time sequence (must include initial time)
    times <- c(0,fitmodel$data$time)

    message("Compute posterior fit")

    if(posterior.median){

        # theta.median <- apply(trace[names.theta],2,median)
        # ind <- which.max(trace$log.posterior)
        # theta.median <- trace[ind,names.theta]
        theta <- c(R0=6.44,LP=1.36,IP=0.98,TIP=12,alpha=0.49,rho=0.65,pI0=4e-2,pL0=0.15,N=284)
        fit <- simulateModelReplicates(fitmodel=fitmodel,theta=theta.median,times=times,n=sample.size,observation=TRUE)
        fit <- rename(fit,c("replicate"="index"))

    } else {

        fit <- ldply(index,function(ind) {

            # extract posterior parameter set
            theta <- trace[ind,names.theta]

            # simulate model at successive observation times of data
            traj <- fitmodel$simulate.model(theta,fitmodel$initialise.state(theta),times)

            # generate observation
            traj <- fitmodel$generate.observation(traj,theta)

            return(traj)
        },.progress="text",.id="index")
    }

    if(summary){
        message("Compute confidence intervals")

        fit.CI <- ddply(fit,"time",function(df) {

            tmp <- as.data.frame(t(quantile(df$observation,prob=c(0.025,0.25,0.5,0.75,0.975))))
            names(tmp) <- c("low_95","low_50","median","up_50","up_95")
            tmp$mean <- mean(df$observation)
            return(tmp)

        },.progress="text")

        fit.CI.line <- melt(fit.CI[c("time","mean","median")],id.vars="time")
        fit.CI.area <- melt(fit.CI[c("time","low_95","low_50","up_50","up_95")],id.vars="time")
        fit.CI.area$type <- sapply(fit.CI.area$variable,function(x) {str_split(x,"_")[[1]][1]})
        fit.CI.area$CI <- sapply(fit.CI.area$variable,function(x) {str_split(x,"_")[[1]][2]})
        fit.CI.area$variable <- NULL
        fit.CI.area <- dcast(fit.CI.area,"time+CI~type")

        p <- ggplot()
        p <- p + geom_ribbon(data=fit.CI.area,aes(x=time,ymin=low,ymax=up,alpha=CI),fill="red")
        p <- p + geom_line(data=fit.CI.line,aes(x=time,y=value,linetype=variable),colour="red")
        p <- p + geom_point(data=fitmodel$data,aes(x=time,y=Inc),colour="black")
        p <- p + scale_alpha_manual("Confidence\ninterval",values=c("95"=0.25,"50"=0.45))
        p <- p + scale_y_continuous("observation")    
        p <- p + theme_bw()

    } else {

        p <- ggplot()
        p <- p + geom_line(data=fit,aes(x=time,y=observation,group=index),alpha=alpha,colour="red")
        p <- p + geom_point(data=fitmodel$data,aes(x=time,y=Inc),colour="black")
        p <- p + theme_bw()

    }   

    if(plot){
        print(p)        
    } else {
        return(list(posterior.traj=fit,plot=p))        
    }


}







