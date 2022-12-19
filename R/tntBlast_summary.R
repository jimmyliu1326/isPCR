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
parser$add_argument("--length", default=NULL, type='character',
										help='Path to amplicon lengths of thermonucleotideBLAST hits  [default \"%(default)s\"]',
										required = T)
parser$add_argument("--sample", default=NULL, type='character',
										help='Sample ID  [default \"%(default)s\"]',
										required = T)
parser$add_argument("--output", default=NULL, type='character',
										help='Path to output tsv file  [default \"%(default)s\"]',
										required = T)

# parse command line args
args <- parser$parse_args()

# determine if input is from multiplexed PCR
primer_ext <- last(unlist(str_split(args$length, "\\.")))
if ( primer_ext == "tsv" ) {
	multiplex <- T
	message("Did not detect any primer extensions, treating input as multiplex PCR results")
} else {
	multiplex <- F
	message(paste0("Detected primer extension: ", primer_ext))
}

# calculate length and hit count summary
length_summary <- function(file_path) {
	# read file
	df <- fread(file_path)
	# number of hits
	n <- nrow(df)
	# 5 point summary
	summary <- df$length %>% 
		summary() %>% 
		as.matrix() %>% 
		as.data.frame() %>% 
		rename(val = V1) %>% 
		rownames_to_column("stat") %>% 
		mutate(stat = str_replace_all(stat, "\\.", ""),
					 stat = paste0(stat, '.Length'))
	
	# combine hits count with 5 point sum
	summary %>% 
		rbind(c("amplicons", n)) %>% 
	# pivot to wide format
		pivot_wider(names_from = "stat",
								values_from = "val") %>% 
		select(amplicons, everything()) %>% 
		return()
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

# join primers information with search summary results
combine_data <- function(primer_key, primers_df, search_res) {
	# append primer id to search res to join data frames
	search_res %>% 
		mutate(primer_id = primer_key) %>% 
		left_join(primers_df,
							by = "primer_id") %>% 
		select(primer_id,
					 fwd_seq,
					 rev_seq,
					 probe_seq,
					 everything())
}

# main
length_summary <- length_summary(args$length)

if (multiplex == F) {
	primers <- load_primers(args$primer)
	combined <- combine_data(primer_ext,
													 primers,
													 length_summary) %>% 
		mutate(sample_id = args$sample) %>% 
		select(sample_id, everything())
} else {
	combined <- data.frame(sample_id = args$sample,
					 primer_id = 'multiplex',
					 fwd_seq = 'multiplex',
					 rev_seq = 'multiplex',
					 probe_seq = 'multiplex') %>% 
		cbind(length_summary)
}

write.table(combined, 
						file = args$output,
						sep = "\t",
						quote = F, 
						row.names = F)
