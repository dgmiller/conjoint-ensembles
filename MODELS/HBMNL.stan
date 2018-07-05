# HBMNL for discrete choice experiments

data {
  int<lower=2> C; // number of alternatives (choices) per question
  int<lower=1> K; // number of feature variables
  int<lower=1> J; // number of respondents
  int<lower=1> S; // number of questions (unique inquiries)
  int<lower=1> G; // number of respondent covariates (demographics, etc)
  int<lower=1,upper=C> Y[J, S]; // observed responses
  matrix[C, K] X[J, S]; // matrix of attributes for each obs
  matrix[G, J] Z; // vector of covariates for each respondent
}

transformed data {
  int<lower=1> N = J*S; // total number of inquiries
  int<lower=1> id[N]; // inquiry n belonging to individual with id
  matrix[C, K] Xx[N];
  int<lower=1, upper=C> Yy[N];

  for (j in 1:J) {
    for (s in 1:S) {
      id[S*(j-1) + s] = j;
      Xx[S*(j-1) + s] = X[j, s];
      Yy[S*(j-1) + s] = Y[j, s];
    }
  }
}

parameters {
  matrix[K, C] alpha;
  cholesky_factor_corr[K] L_Omega;
  vector<lower=0,upper=pi()/2>[K] tau_unif;
  matrix[J, K] mu;
  real<lower=0> sigma;
}

transformed parameters {
  matrix[C, K] B; // matrix of beta coefficients
  vector<lower=0>[K] tau; // prior scale
  for (k in 1:K) tau[k] = 2.5 * tan(tau_unif[k]);
  L = diag_pre_multiply(tau, L_Omega);
  B = Z * mu + (L * alpha)';
}

model {
  //priors
  to_vector(alpha) ~ normal(0, 1);
  L_Omega ~ lkj_corr_cholesky(2);
  to_vector(mu) ~ normal(0, 5);

  // model fitting
  for (n in 1:N) {
    Yy[n] ~ categorical_logit(Xx[n]*B[id[n]]);
  }
}
