// import modules
include { tntblast } from '../modules/local/tntblast.nf'

workflow ispcr {

    take: 
        combined_seq
        primers

    main:
        // determine multiplex mode
        if (params.multiplex) {
            multiplex_args = '--plex T -n F'
        } else {
            multiplex_args = '-n T'
        }

        // tntblast args
        tntblast_args = multiplex_args
        tntblast_args = tntblast_args + ' -e ' + params.primer_min_tm
        tntblast_args = tntblast_args + ' -E ' + params.probe_min_tm
        tntblast_args = tntblast_args + ' -l '  + params.max_length
        tntblast_args_ch = Channel.from( tntblast_args )

        // print(tntblast_args)
        
        // run tntblast
        combined_seq
            | combine(primers)
            | combine(tntblast_args_ch)
            | tntblast

    emit:
        output = tntblast.out.output

}