# First, install a compiler or "tool chain" (i.e., the latest version of Xcode).

# Second, make sure the Makevars directory and file exist. If not, create them.
dotR <- file.path(Sys.getenv("HOME"), ".R")
if (!file.exists(dotR)) dir.create(dotR)
M <- file.path(dotR, "Makevars")
if (!file.exists(M)) file.create(M)

# Third, configure Makevars compiler flags to work with rstan (appended manually since locked out of file).
# cat("\nCXXFLAGS=-O3 -mtune=native -march=native -Wno-unused-variable -Wno-unused-function  -Wno-macro-redefined",
#     file = M, sep = "\n", append = TRUE)
cat("\nCXXFLAGS=-O3 -mtune=native -march=native -Wno-unused-variable -Wno-unused-function  -Wno-macro-redefined",
    sep = "\n", append = TRUE)

# Fourth, configure clang++ in Makevars to work with rstan (appended manually since locked out of file).
# cat("\nCC=clang",
#     "CXX=clang++ -arch x86_64 -ftemplate-depth-256", 
#     file = M, sep = "\n", append = TRUE)
cat("\nCC=clang",
    "CXX=clang++ -arch x86_64 -ftemplate-depth-256", 
    sep = "\n", append = TRUE)

# Check you work.
cat(readLines(M), sep = "\n")

# Install rstan.
install.packages("rstan", dependencies = TRUE)

# Restart R and run the following to check install.
fx <- inline::cxxfunction( signature(x = "integer", y = "numeric" ) , '
	return ScalarReal( INTEGER(x)[0] * REAL(y)[0] ) ;
                           ' )
fx( 2L, 5 ) # should be 10
