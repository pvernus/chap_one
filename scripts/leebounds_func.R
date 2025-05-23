### Estimate bounds for the intensive margin effect
### Source: Huber (2023), p.300

## Note: 
# strata: The variable name indicating strata. If this is specified, the quantities of interest will be first calculated within each strata and then aggregated. The default is NULL.
# ratio : A𝐽×𝑀 matrix of probabilities where 𝐽is the number of strata and 𝑀 is the number of treatment and control groups. Each element of the matrix specifies the probability of a unit falling into that category. The default is NULL in which case the sample estimates of these probabilities are used for computation.
# survey: The variable name for survey weights. The default is NULL.
 
# Question1: how to include covariates and FEs? 
# Question2: can i use weights from treatment model for the survey parameter?

library ( experiment ) # load experiment package  
library ( causalweight ) # load causalweight package

treat=data$large_dis_dummy # random treatment
outcome=data$commit # define outcome
selection=data$commit_dummy # sample selection

outcome[selection==NA]=NA # recode non-selected outcomes as NA
dat=data.frame(treat, selection, outcome) # generate data frame  
results=ATEbounds(outcome∼factor(treat), data=dat) # compute worst case bounds
results$bounds ; results$bonf.ci # bounds on ATE + confidence intervals

## In a next step, we aim at tightening the bounds by imposing monotonicity of selection O  in the treatment D

library (devtools) # load devtools package  
install_github("vsemenova/leebounds") # install leebounds package  
library (leebounds) # load leebounds package  

results=leebounds(dat) # bounds (monotonic selection in treat)  
results$lowerbound ; results$upperbound # bounds on ATE under monotonicity