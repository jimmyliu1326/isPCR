#!/usr/bin/env Rscript

# load pkgs
suppressPackageStartupMessages(library(argparse))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))

# create arg parser
parser <- ArgumentParser()
parser$add_argument("--primer", default=NULL, type='character',
										help='Path to primer sequences [default \"%(default)s\"]',
										required = T)
parser$add_argument("--samples", default=NULL, type='character',
										help='Path to headerless isPCR samples.csv [default \"%(default)s\"]',
										required = T)
parser$add_argument("--output", default='analysis_results.tsv', type='character',
										help='Path to output tsv file  [default \"%(default)s\"]')
parser$add_argument("file", default=NULL, type='character',
										help='Path to summary outputs from tntBlast_summary.R',
										nargs = "+")

# parse command line args
args <- parser$parse_args()

# determine if input is from multiplexed PCR
primer_ext <- last(unlist(str_split(args$file[1], "\\.")))
if ( primer_ext == "tsv" ) {
	multiplex <- T
	message("Did not detect any primer extensions, treating input as multiplex PCR results")
} else {
	multiplex <- F
	message(paste0("Detected primer extension: ", primer_ext))
}

# load input summary files (from a vector)
load_summary <- function(file_paths) {
	map_dfr(file_paths, ~fread(., header = T, fill = T,
														 colClasses = list(character = 1:5)))
}

# load primer sequence file
load_primers <- function(file_path) {
	# read file
	df <- fread(file_path,
							fill = T,
							header = F,
							sep = " ",
							colClasses = list(character = 1))
	# rename first 3 columns
	colnames(df)[1:3] <- c("primer_id",
												 "fwd_seq",
												 "rev_seq")
	
	# add probe seq column if absent
	if (ncol(df) == 3) {
		df %>% 
			cbind("probe_seq" = "NULL")
	} else {
		# set empty probe seq values to NA
		colnames(df)[4] <- "probe_seq"
		df %>% 
			mutate(probe_seq = if_else(nchar(probe_seq) == 0, "NULL", probe_seq))
	}
}

# complete summary files by adding zero hit primers and samples
complete_summary <- function(summary, primer_ids, sample_ids) {
	# sample_ids = vector of sample ids
	# summary = data frame of combined tntblast summary outputs
	# primers = vector of primer ids
	
	if (multiplex == F) {
			
		# construct all combinations of sample id and primers
			expand.grid(sample_ids,
								primer_ids) %>% 
			left_join(primers,
								by = c("Var2" = "primer_id")) %>% 
			rename("sample_id" = "Var1",
						 "primer_id" = "Var2") %>%
			left_join(summary) %>% 
			mutate(amplicons = if_else(is.na(amplicons), 0, as.double(amplicons)))
		
	} else {
		
			data.frame(sample_id = sample_ids) %>% 
			left_join(summary) %>% 
			mutate(amplicons = if_else(is.na(amplicons), 0, as.double(amplicons)))
			
	}
}

# main
samples <- fread(args$samples, header = F, col.names = c("sample_id", "path"))
summary_res <- load_summary(args$file)
primers <- load_primers(args$primer)
summary_res_out <- complete_summary(summary_res, primers$primer_id, samples$sample_id)
write.table(summary_res_out, file = args$output, row.names = F, quote = F, sep = "\t")
