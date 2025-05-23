## Spatial Autoregressive (SAR) Model (with sectoral spillovers) ##

# step 1. Construct the Spillover Matrix (W): 
# Define a matrix that captures the spatial (sectoral) dependence. This matrix represents the relationships between sectors in the same country. If sector m influences sector n, W[m, n] would be non-zero.

library(spdep)
# Create a spatial weights matrix (W) based on sectoral dependencies within countries
W <- spdep::mat2listw(your_spillover_matrix)

# Create the Spatial Lag Variable: Manually construct the spatially lagged outcome variable by multiplying the spatial weights matrix by the outcome variable

library(spdep)
W <- mat2listw(your_spillover_matrix)
your_data$lagged_outcome <- lag.listw(W, your_data$outcome)

# Fit the Model
# step 2. Regression Specification: In a SAR model, you would include a spatially lagged dependent variable to account for spillovers.
# Y_{it} = ρ.W.Y_{it} + β.X_{it} + ϵ_{it}
# 
# Note: does not automatically account for all of the assumptions inherent in the SAR model (such as autocorrelation in the residuals).
# the assumptions inherent in the SAR model (such as autocorrelation in the residuals).



## Manual Construction

# Create a country-sector identifier
your_data <- your_data %>%
  mutate(country_sector = paste(country, sector, sep = "_"))

# Get the number of rows (sectors)
n <- nrow(your_data)

# Initialize the weights matrix
W <- matrix(0, n, n)

# Loop through each pair of sectors
for (i in 1:n) {
  for (j in 1:n) {
    if (your_data$country[i] == your_data$country[j]) {
      # Assign equal weight for sectors within the same country
      W[i, j] <- 1
    }
  }
}

# Convert the matrix to a spatial weights list (suitable for spatial models in spdep)
W_listw <- mat2listw(W)

## list approach

# Create a list of neighbors (sectors within the same country)
neighbors <- list()

for (country_id in unique(your_data$country)) {
  sectors_in_country <- which(your_data$country == country_id)
  neighbors[[as.character(country_id)]] <- sectors_in_country
}

# Convert to spatial weights list
W_listw <- nb2listw(neighbors, style = "W", zero.policy = TRUE)


## Matrix-Based Approach
library(Matrix)

# Generate country-sector dummy variables
your_data <- your_data %>%
  mutate(country_sector = as.factor(paste(country, sector, sep = "_")))

# Create a sparse matrix for the weights
W_sparse <- sparseMatrix(i = rep(1:nrow(your_data), each = nrow(your_data)), 
                         j = rep(1:nrow(your_data), times = nrow(your_data)),
                         x = ifelse(outer(your_data$country, your_data$country, "=="), 1, 0))

# Convert the sparse matrix to listw (spdep format)
W_listw <- mat2listw(W_sparse)
