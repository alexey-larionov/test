#!/bin/bash

# s02_filter_prune_pca.sh

# Filter by MAF (default 0.01)
# Prune by LD (--indep-pairphase 50000 50 0.5)
# Calculate eigenvectors

# Started: Alexey Larionov, 24Sep2018
# Last updated: Alexey Larionov, 19Jan2019

# Use:
# s02_filter_prune_pca.sh > s02_filter_prune_pca.log

# Stop at errors
set -e

# --- Start section --- #

# Progress report
echo "s02_filter_prune_pca.sh"
echo "Started: $(date +%d%b%Y_%H:%M:%S)"
echo ""
plink19="/Users/alexey/Documents/tools/plink_19/plink"
"${plink19}" --version
echo ""

base_folder="/Users/alexey/Documents/wecare/ampliseq/analysis3/s12_eigenvectors_and_outliers"
cd "${base_folder}"

#----------------------#
#     Filter by AF     #
#----------------------#

# --- Reference --- #

# https://www.cog-genomics.org/plink/1.9/filter#maf

# --- Used flags --- #

# --maf filters out all variants with minor allele frequency 
# below the provided threshold (default 0.01)

# --recode creates a new text fileset, after applying sample/variant 
# filters and other operations. By default, the fileset includes a .ped 
# and a .map file, readable with --file

# --- Unused flags --- #

# --filter-founders excludes all samples with at least one known parental ID 
# from the current analysis..., while --filter-nonfounders does the reverse. 
# By default, nonfounders are not counted by --freq{x} or --maf/--max-maf/--hwe. 
# Use the --nonfounders flag to include them.  
# In our data noone has parental IDs, so everyone is considered founder. 
# Thus, there is no need in the --nonfounders flag.

# --allow-no-sex unless the input is loaded with --no-sex, samples with 
# ambiguous sex have their phenotypes set to missing when analysis commands 
# are run. Use --allow-no-sex to prevent this. 
# In our datset all participants are femele and it is stated in the data. 
# Thus, there is no need in the --allow-no-sex flag.

echo ""
echo "--- Filter out rare variants ---"
echo ""

source="${base_folder}/ampliseq"
maf="${base_folder}/ampliseq_maf"

"${plink19}" \
  --file "${source}" \
  --maf 0.01 \
  --recode \
  --out "${maf}"

#------------------------------------#
#     Remove SNPs in pairwise LD     #
#------------------------------------#

# Settings: 
# a window size in variant count or kilobase (if the 'kb' modifier is present) units, 
# a variant count to shift the window at the end of each step
# r2 values are based on maximum likelihood phasing

# plink help ("${plink19}"  --indep-pairphase --help) gives the following example:
# --indep-pairwise 500kb 5 0.5

# Considering the small number of variants we may take a 5k-variants window that would include all of them at once ?

echo ""
echo "--- Detect SNPs in pairwise LD ---"
echo ""

pairwise_ld="${base_folder}/pairwise_ld"

"${plink19}" \
  --file "${maf}" \
  --indep-pairphase 500kb 1 0.5 \
  --out "${pairwise_ld}"

echo ""
echo "--- Exclude SNPs in paiwise LD ---"
echo ""

vars_to_exclude_by_ld="${pairwise_ld}.prune.out"
pruned="${base_folder}/common_pruned"

"${plink19}" \
  --file "${maf}" \
  --exclude "${vars_to_exclude_by_ld}" \
  --recode \
  --out "${pruned}"
  
echo ""

#-----------------------#
#     Calculate PCA     #
#-----------------------#

# --- Reference --- #

# https://www.cog-genomics.org/plink/1.9/strat#pca

# --- Notes --- #

# By default, --pca extracts the top 20 principal components of the 
# variance-standardized relationship matrix... 
# Eigenvectors are written to plink.eigenvec, and top eigenvalues are 
# written to plink.eigenval. The 'header' modifier adds a header line 
# and the 'tabs' modifier makes the .eigenvec file(s) tab- delimited

# Top principal components are generally used as covariates in 
# association analysis regressions to help correct for population 
# stratification

echo ""
echo "--- Calculate eigenvectors ---"
echo ""

ampliseq="${base_folder}/ampliseq"

"${plink19}" \
  --file "${pruned}" \
  --pca header tabs \
  --out "${ampliseq}"

# Completion message
echo ""
echo "Completed: $(date +%d%b%Y_%H:%M:%S)"
echo ""
