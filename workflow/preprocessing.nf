// import modules
include { combine_fq; combine_fa } from '../modules/local/nanopore-base.nf'
include { fq2fa } from '../modules/local/seqkit.nf'

workflow preprocessing {

    take: data

    main:
        // combine input files
        if ( params.input_format == 'fasta' ) {

            combined_seq = combine_fa(data)

        } else {

            combined_fq = combine_fq(data)
            // convert fq to fa
            combined_seq = fq2fa(combined_fa)

        }

    emit: combined_seq

}