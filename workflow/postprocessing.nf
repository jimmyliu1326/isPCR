// import modules
include { blast2fa; blast2bed; blast_summary; combine_summary } from '../modules/local/tntblast_parse.nf'
include { fa2tab } from '../modules/local/seqkit.nf'

workflow postprocessing {

    take: 
        blast_out
        primers
        samples

    main:
        blast_out
            | transpose 
            | blast2fa

        blast_out
            | transpose 
            | blast2bed

        blast2fa.out
            | fa2tab

        fa2tab.out
            | combine(primers)
            | blast_summary
        
        summary = blast_summary.out
            | map { it[1] }
            | collect

        combine_summary(summary,
                        primers,
                        samples)

    emit:
        fasta = blast2fa.out
        bed = blast2bed.out
        summary = blast_summary.out
        combined_res = combine_summary.out
}