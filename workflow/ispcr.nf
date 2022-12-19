// import modules
include { tntblast } from '../modules/local/tntblast.nf'

workflow ispcr {

    take: 
        combined_seq
        primers

    main:
        // determine multiplex mode
        if (params.multiplex) {
            multiplex_args = '--plex -n F'
        } else {
            multiplex_args = '-n T'
        }
        
        // run tntblast
        tntblast(
            combined_seq,
            primers,
            params.primer_min_tm,
            params.probe_min_tm,
            params.max_length,
            multiplex_args
        )

    emit:
        output = tntblast.out.output

}