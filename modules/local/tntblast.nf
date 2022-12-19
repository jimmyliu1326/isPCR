process tntblast {
    tag "tntBlast search on ${sample_id}"
    label "process_medium"
    publishDir "$params.outdir"+"/results/"+"$sample_id", mode: "copy", pattern: '*.log'

    input:
        tuple val(sample_id), path(fasta), path(primer), val(args)
        
    output:
        tuple val(sample_id), file("*.out*"), emit: output, optional: true
        tuple val(sample_id), file("*.log"), emit: log
    shell:
        """
        OMP_NUM_THREADS=${task.cpus}
        tntblast \
            -i ${primer} \
            -o ${sample_id}.out \
            -d ${fasta} \
            -X 9999 \
            -m 0 \
            -a F \
            -S T \
            --best-match \
            ${args} | tee ${sample_id}.log
        """
}