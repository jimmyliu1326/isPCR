process tntblast {
    tag "tntBlast search on ${fasta.simpleName}"
    label "process_medium"
    // publishDir "$params.outdir"+"/results/"+"$sample_id", mode: "copy"

    input:
        tuple val(sample_id), path(fasta)
        path(primer)
        val(min_primer_tm)
        val(min_probe_tm)
        val(max_length)
        val(multiplex)
    output:
        tuple val(sample_id), file("*.out*"), emit: output, optional: true
        tuple val(sample_id), file("*.txt"), emit: log
    shell:
        """
        OMP_NUM_THREADS=${task.cpus}
        tntblast \
            -i ${primer} \
            -o ${sample_id}.out \
            -d ${fasta} \
            -e ${min_primer_tm} \
            -E ${min_probe_tm} \
            -X 9999 \
            -m 0 \
            -a F \
            -S T \
            --best-match \
            -l ${max_length} \
            ${multiplex} | tee ${sample_id}.summary.txt
        """
}