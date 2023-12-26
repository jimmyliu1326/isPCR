#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// define global var
pipeline_name = workflow.manifest.name

WorkflowMain.initialise(workflow, params, log)

// import workflows
include { preprocessing } from './workflow/preprocessing.nf'
include { ispcr } from './workflow/ispcr.nf'
include { postprocessing } from './workflow/postprocessing.nf'

// define main workflow
workflow {

    // read data
    samples_file = channel
        .fromPath(params.input, checkIfExists: true)
    data = samples_file
        .splitCsv(header: false)
        .map { tuple(it[0], file(it[1])) }
    primers = channel
        .fromPath(params.primer, checkIfExists: true)

    // preprocess input data
    preprocessing(data)
    // run in silico PCR
    ispcr(preprocessing.out, primers)
    // postprocess blast outputs
    postprocessing(ispcr.out.output, primers, samples_file)
}