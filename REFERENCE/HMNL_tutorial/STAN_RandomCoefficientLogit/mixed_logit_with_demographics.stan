data {
  int N; // number of rows
  int T; // number of inidvidual-choice sets/task combinations
  int I; // number of Individuals
  int P; // number of covariates that vary by choice
  int P2; // number of covariates that vary by individual
  int K; // number of choices
  
  vector<lower = 0, upper = 1>[N] choice; // binary indicator for choice
  matrix[N, P] X; // choice attributes
  matrix[I, P2] X2; // individual attributes
  
  int task[T]; // index for tasks
  int task_individual[T]; // index for individual
  int start[T]; // the starting observation for each task
  int end[T]; // the ending observation for each task
}
parameters {
  vector[P] beta; // hypermeans of the part-worths
  matrix[P, P2] Gamma; // coefficient matrix on individual attributes
  vector<lower = 0>[P] tau; // diagonal of the part-worth covariance matrix
  matrix[I, P] z; // individual random effects (unscaled)
  cholesky_factor_corr[P] L_Omega; // the cholesky factor of the correlation matrix of tastes/part-worths
}
transformed parameters {
  // here we use the reparameterization discussed on slide 30
  matrix[I, P] beta_individual = rep_matrix(beta', I) + X2 * Gamma' + z*diag_pre_multiply(tau, L_Omega);
}
model {
  // create a temporary holding vector
  vector[N] log_prob;
  
  // priors on the parameters
  tau ~ cauchy(0, .5);
  beta ~ normal(0, 1);
  to_vector(z) ~ normal(0, 1);
  L_Omega ~ lkj_corr_cholesky(10);
  to_vector(Gamma) ~ cauchy(0, .1);
  
  // log probabilities of each choice in the dataset
  for(t in 1:T) {
    vector[K] utilities; // tmp vector holding the utilities for the task/individual combination
    // add utility from product attributes with individual part-worths/marginal utilities
    utilities = X[start[t]:end[t]]*beta_individual[task_individual[t]]';
    
    log_prob[start[t]:end[t]] = log(softmax(utilities));
  }
  
  // use the likelihood derivation on slide 29
  target += log_prob' * choice;
}
