library(tidyverse); library(rstan)


# Make some fake data/parameters

# We'll do 10 tasks per individual for 100 individuals comparing 5 choices
I <- 100 ## number of individuals
T <- I*10 # Number of task observations
K <- 5 # Number of choices
P <- 2 # We'll vary two product attributes for each choice at each task
P2 <- 4 # number of individual attributes
N <- T*K # Number of observations

X <- matrix(rnorm(N*P), N, P) # Some random attributes (marketers will usually use binary variables but that doesn't matter)
# Need to make sure that every Kth row is zero (the outside option has no attributes)
X[1:nrow(X)%%K==0,] <- 0
X2 <- matrix(rnorm(I*P2), I, P2)

# The hypermeans of the part-worths
beta <- rnorm(P)

# The covariance matrix of the part-worths across individuals
Sigma <- diag(c(1, 2)) %*% matrix(c(1, .5, .5, 1), 2, 2) %*% diag(c(1, 2)) 

gamma <- matrix(rnorm(P2*P, 0, .2), P, P2)

# Individual-level part-worths
# The model is 
# beta_individual = beta + X2 * Gamma' + epsilon with epsilon ~ multi normal(0, Sigma)
# first do the mean + random bit
beta_individual <- MASS::mvrnorm(I, beta, Sigma)

# Then add the effects from individual-level covariates
beta_individual <- beta_individual + X2 %*% t(gamma)


# now make some indexes that tell us which parameters to use for each task, 
# and the beginning and end rows for each task
indexes <- data_frame(individual = rep(1:I, each = K*10),
                      task = rep(1:T, each = K),
                      row = 1:(T*K)) %>%
  group_by(task) %>% 
  summarise(task_individual = first(individual),
            start = first(row),
            end = last(row)) 
  
# I don't know why this isn't built into base R...
softmax <- function(x) exp(x)/sum(exp(x))

# Initialize choices
choice <- rep(0, N)

# Generate fixed components of utilities, and choices
for(t in 1:T) {
  # Add product attribute utility
  utility <- X[indexes$start[t]:indexes$end[t],] %*% beta_individual[indexes$task_individual[t],]
  choice[indexes$start[t]:indexes$end[t]] <- as.numeric(rmultinom(1, 1, softmax(as.numeric(utility))))
}



# Fit the model in Stan ---------------------------------------------------

# So you'll want to have data that look like so: 

# choice level data

bind_cols(choice = choice, as_data_frame(X)) %>% 
  head(20)

# task-level data

bind_cols(indexes) %>% 
  head(20)

# The start and end refer to the rows in the choice-level data that correspond to the choice task

# Individual-level data

bind_cols(individual = 1:I, as_data_frame(X2)) %>% head(20)

compiled_model <- stan_model("mixed_logit_with_demographics.stan")

data_list <- list(N = N, 
                  I = I, 
                  P = P, 
                  P2 = P2, 
                  K = K, 
                  T = T, 
                  X = X, 
                  X2 = X2, 
                  choice = choice, 
                  start = indexes$start,
                  end = indexes$end, 
                  task_individual = indexes$task_individual,
                  task = indexes$task)


model_fit <- sampling(compiled_model, data = data_list, cores = 4, iter = 1000)

# Check model fit
print(model_fit, pars = "beta")
print(model_fit, pars = "Gamma")

# Looks pretty good!

# Let's check that our estimates line up with the "known unknowns" 

gamma_means <- get_posterior_mean(model_fit, pars = "Gamma")[,5]
gamma_means <- matrix(gamma_means, P, P2, byrow = T)
plot(gamma_means, gamma)
abline(0, 1)

beta_individual_means <- get_posterior_mean(model_fit, pars = "beta_individual")[,5]
beta_individual_means <- matrix(beta_individual_means, I, P, byrow = T)

plot(beta_individual, beta_individual_means)
abline(0, 1)

# So it looks as though the model fit very well!

