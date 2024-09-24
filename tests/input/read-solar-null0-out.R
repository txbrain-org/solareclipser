library(tidyverse)
library(stringr)

# Read the file into R
con <- file("tests/output/solar/CC/null0.out", "r")
file_content <- readLines(con)
close(con)

# Function to extract specific lines based on regex
extract_section <- function(content, start_pattern, end_pattern = NULL) {
  start_idx <- which(str_detect(content, start_pattern))
  end_idx <- if (!is.null(end_pattern)) which(str_detect(content, end_pattern)) else length(content)
  return(content[start_idx:end_idx])
}

# Extract the "Model Parameter Optimizations" section
param_opt_section <- extract_section(file_content, "^\\s*Model Parameter Optimizations", "^\\s*Loglikelihood")

# Extract individual data lines from the parameter section
param_opt_data <- param_opt_section[str_detect(param_opt_section, "^\\s+(mean|sd|e2|h2r)")]

# Parse the parameter lines and load them into a dataframe
param_df <- param_opt_data %>%
  str_squish() %>%
  str_split_fixed("\\s+", 4) %>%
  as.data.frame(stringsAsFactors = FALSE)

# Rename the columns
colnames(param_df) <- c("Parameter", "Final_Val", "Std_Err", "Other")

# Convert the values to numeric
param_df <- param_df %>%
  mutate(across(c(Final_Val, Std_Err), as.numeric))

# View the dataframe
print(param_df)


# Extract the "Iteration History" section
iter_history_section <- extract_section(file_content, "^\\s*Iteration History", "^\\s*Asymptotic Standard Errors")

# Extract iteration data
iter_data <- iter_history_section[str_detect(iter_history_section, "^\\s*\\d+")]

# Parse iteration data and load it into a dataframe
iter_df <- iter_data %>%
  str_squish() %>%
  str_split_fixed("\\s+", 7) %>%
  as.data.frame(stringsAsFactors = FALSE)

# Rename the columns
colnames(iter_df) <- c("Iter", "Step", "Loglikelihood", "mean", "sd", "e2", "h2r")

# Convert values to numeric
iter_df <- iter_df %>%
  mutate(across(everything(), as.numeric))

# View the iteration dataframe
print(iter_df)


# Extract the "Pedigrees Excluded" section
pedigrees_excluded_section <- extract_section(file_content, "^\\s*Pedigrees Excluded", "^\\s*Pedigrees Included")

# Extract pedigree counts
pedigree_excluded_data <- pedigrees_excluded_section[str_detect(pedigrees_excluded_section, "^\\s*\\d")]

# Parse pedigree data into a dataframe
pedigree_excluded_df <- pedigree_excluded_data %>%
  str_squish() %>%
  str_split_fixed("\\s+", 6) %>%
  as.data.frame(stringsAsFactors = FALSE)

# Rename the columns
colnames(pedigree_excluded_df) <- c("Pedigrees", "People", "Females", "Males", "MZTwins", "Probands")

# Convert values to numeric
pedigree_excluded_df <- pedigree_excluded_df %>%
  mutate(across(everything(), as.numeric))

# View the pedigree dataframe
print(pedigree_excluded_df)
