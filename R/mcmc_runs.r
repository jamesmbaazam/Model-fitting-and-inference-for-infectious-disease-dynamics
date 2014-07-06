my_logPosterior_epi1 <- function(theta) {

    return(my_logPosterior(fitmodel = SIR,
                        theta = theta,
                        init.state = c(S = 999, I = 1, R = 0),
                        data = epi1))

}

## mcmc.run.R0 <- mcmcMH(target = my_logPosterior_epi1, init.theta = c(R0 = 3, D.inf = 2), proposal.sd = c(0.05, 0), n.iterations = 10000)
mcmc.epi1 <- mcmcMH(target = my_logPosterior_epi1, init.theta = c(R0 = 3, D.inf = 2), proposal.sd = c(0.05, 0), n.iterations = 10000)

my_logPosterior_epi3 <- function(theta) {

    return(my_logPosterior(fitmodel = SIR,
                        theta = theta,
                        init.state = c(S = 999, I = 1, R = 0),
                        data = epi3))

}

## mcmc.run.R0.Dinf <- mcmcMH(target = my_logPosterior_epi3, init.theta = c(R0 = 1, D.inf = 2), proposal.sd = c(0.01, 0.1), n.iterations = 10000)
mcmc.epi3 <- mcmcMH(target = my_logPosterior_epi3, init.theta = c(R0 = 1, D.inf = 2), proposal.sd = c(0.01, 0.1), n.iterations = 1000)

my_logPosterior_epi4 <- function(theta) {

    return(my_logPosterior(fitmodel = SIR_reporting,
                        theta = theta,
                        init.state = c(S = 999, I = 1, R = 0),
                        data = epi4))

}

## mcmc.run.R0.Dinf.RR <- mcmcMH(target = my_logPosterior_epi4, init.theta = c(R0 = 1, D.inf = 2, RR = 1), proposal.sd = c(0.01, 0.1, 0.01), n.iterations = 10000)
mcmc.epi4 <- mcmcMH(target = my_logPosterior_epi4, init.theta = c(R0 = 1, D.inf = 2, RR = 1), proposal.sd = c(0.01, 0.1, 0.01), n.iterations = 10000)

save(mcmc.epi1, mcmc.epi3, mcmc.epi4, file = "mcmc.rdata")

SEIT2L_sto$logPrior <- function(theta) {

	log.prior.R0 <- dunif(theta[["R0"]], min = 1, max = 50, log = TRUE)
	log.prior.latent.period <- dnorm(theta[["D.lat"]], mean = 2, log = TRUE)
	log.prior.infectious.period <- dnorm(theta[["D.inf"]], mean = 2, log = TRUE)
	log.prior.temporary.immune.period <- dunif(theta[["D.imm"]], min = 0, max = 50, log = TRUE)
	log.prior.probability.long.term.immunity <- dunif(theta[["alpha"]], min = 0, max = 1, log = TRUE)
	log.prior.reporting.rate <- dunif(theta[["rho"]], min = 0, max = 1, log = TRUE)
	
	return(log.prior.R0 + log.prior.latent.period + log.prior.infectious.period + log.prior.temporary.immune.period + log.prior.probability.long.term.immunity + log.prior.reporting.rate)

}

mcmc.abc.trial <- mcmcMH(target = my_ABClogPosterior_try_tdc, init.theta = theta, n.iterations = 10000, limits = list(lower = c(R0 = 1, D.lat = 0, D.inf = 0, D.imm = 0, alpha = 0, rho = 0), upper = c(R0 = Inf, D.lat = Inf, D.inf = Inf, D.imm = Inf, alpha = 1, rho = 1)))

epsilon <- unname(quantile(mcmc.abc.trial$trace$distance, probs = 0.01))
init.theta.26 <- unlist(mcmc.abc.trial$trace[which.min(mcmc.abc.trial$trace$distance), 1:6])

time.mcmc.abc.26 <- system.time(mcmc.abc.26 <- mcmcMH(target = my_ABClogPosterior_try_tdc, init.theta = init.theta.26, proposal.sd = init.theta.26/100, n.iterations = 1000000, limits = list(lower = c(R0 = 1, D.lat = 0, D.inf = 0, D.imm = 0, alpha = 0, rho = 0), upper = c(R0 = Inf, D.lat = Inf, D.inf = Inf, D.imm = Inf, alpha = 1, rho = 1))))

epsilon.8 <- unname(quantile(mcmc.abc.26$trace$distance, probs = 0.01))
init.theta.8 <- unlist(mcmc.abc.26$trace[which.min(mcmc.abc.26$trace$distance), 1:6])

