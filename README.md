# isPCR: *in silico* PCR

## Description
The core component of the isPCR pipeline is [thermonucleotideBLAST](https://github.com/jgans/thermonucleotideBLAST) developed by *Gans et al.* *In silico* PCR involves oligonucleotides as queries to search for gap alignments that are bounded by foward and reverse primers. qPCR Taqman probe sequences can be provided as an additional factor to parameterize the search. Sequence matches are defined by thermodynamic properties such as hybridization melting temperature (Tm), and Gibb's Free Energy (deltaG). More information on the implementation of the algorithm can be found [here](https://pubmed.ncbi.nlm.nih.gov/18515842/).

The isPCR pipeline wraps thermonucleotideBLAST in Nextflow framework to allow *in silico* PCR to be scalable, flexible, and parsable. Sequence search against FASTA and FASTQ formats is supported. thermonucleotideBLAST outputs are further processed to report alignment results in standardized formats (BED/FASTA/TSV).

## Installation

```bash
# Install pre-requisites
 - Nextflow >= 21.0
 - Docker or Singularity
 - Git

# Pull the latest pipeline code from GitHub
nextflow pull jimmyliu1326/isPCR
```

## Getting Started

### Preparing samples.csv

Paths to database sequences must be supplied in the form of a **headerless** `samples.csv` with two columns that encode database IDs and paths to **DIRECTORIES** containing .FASTA or .FASTQ files (gzipped files are supported). Each database can be a set of genome assemblies, genes or raw reads.

Example `samples.csv`

```
Sample_1,/path/to/data/Sample_1/
Sample_2,/path/to/data/Sample_2/
Sample_3,/path/to/data/Sample_3/
```

Given the `samples.csv` above, your data directory should be set up like the following:

```
/path/to/data/
├── Sample_1
│   └── Sample_1.fastq.gz
├── Sample_2
│   └── Sample_2.fastq.gz
└── Sample_3
    ├── Sample_3a.fastq
    └── Sample_3b.fastq
```

*Note:*
* The sequencing data for each database must be placed within a unique subdirectory
* The names of the database subdirectories do not have to match the IDs in the `samples.csv`
* You can have multiple .FASTQ or .FASTA files associated with a single database. The pipeline will aggregate all .FASTQ/.FASTA files within the same directory before proceeding.

### Preparing primers.txt
Primer sequences have to be formatted in a **headerless** space delimited file containing 3 columns and an optional 4th column.

* Column 1: Primer ID (do not include blank spaces!)
* Column 2: Forward primer sequence
* Column 3: Reverse primer sequence
* Column 4 (optional): Probe sequence

Example `primers.txt`

```
TetH CAGTGAAAATTCACTGGCAAC ATCCAAAGTGTGGTTGAGAAT
TetR GATATAAAAAAACATTCTTA ATTGATCCTAAAACTGGACT
```

## Pipeline Usage

The pipeline executes process in Docker containers by default. Singularity containers and management of pipeline processes by Slurm are also supported. See below for simple use cases demonstrating pipeline execution using different preconfigured profiles.

**Docker (Default)**

```bash
nextflow run jimmyliu1326/isPCR -latest \
    --input samples.csv \
    --primer primers.txt \
    --input_format fasta
```

**Singularity**

```bash
nextflow run jimmyliu1326/isPCR -latest \
    --input samples.csv \
    --primer primers.txt \
    --input_format fasta \
    -profile singularity
```

**Singularity + Slurm**

```bash
nextflow run jimmyliu1326/isPCR -latest \
    --input samples.csv \
    --primer primers.txt \
    --input_format fasta \
    -profile singularity,slurm
```