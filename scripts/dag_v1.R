remotes::install_github('jtextor/dagitty/r')
library( dagitty )


myDAG <- dagitty(" dag {
  m 
  i [unobserved] 
  i-j [unobserved]
  y [outcome]
  y_t-1 
  y_z [unobserved]
  d [exposure]
  j [unobserved]
  m -> y
  j -> m
  i -> i-j
  i -> y
  i-j -> m
  i-j -> y
  y -> y
  y_t-1 -> y
  d -> m
  d -> y
  j -> m
  j -> i-j
  j -> y
  j -> d
}", layout = T
)

plot( myDAG )


install.packages( "lavaan" )
libary(lavaan)