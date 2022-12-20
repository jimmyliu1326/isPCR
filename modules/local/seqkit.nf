process fa2tab {
    tag "Calculating tntBlast hit lengths for ${sample_id}"
    label "process_low"
    publishDir "$params.outdir"+"/results/"+"$sample_id", mode: "copy"

    input:
        tuple val(sample_id), path(fasta)
    output:
        tuple val(sample_id), file("*.tsv*"), emit: stats
    shell:
        """
        # check if fasta file carries primer names
        if [[ \$(echo ${fasta} | grep ".fa\$") ]]; then
            out_file=${sample_id}.stats.tsv
        else
            primer=\$(echo ${fasta} | rev | cut -f1 -d'.' | rev)
            out_file=${sample_id}.stats.tsv.\$primer
        fi

        seqkit fx2tab -l -n -g ${fasta} | sed '1iid\tlength\tpercent_gc' > \$out_file
        """
}

process fq2fa {
    tag "Converting FASTQ to FASTA for ${sample_id}"
    label "process_low"

    input:
        tuple val(sample_id), path(fastq)
    output:
        tuple val(sample_id), file("*.fasta")
    shell:
        """
        seqkit fq2fa -j ${task.cpus} ${fastq} -o ${sample_id}.fasta
        """
}