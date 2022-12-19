// basic processes for Nanopore workflows
process combine_fq {
    tag "Combining Fastq files for ${sample_id}"
    label "process_low"

    input:
        tuple val(sample_id), path(reads)
    output:
        tuple val(sample_id), file("${sample_id}.{fastq,fastq.gz}")
    shell:
        """
        sample=\$(find -L ${reads} -type f -name '*.fastq*' | head -n 1)
        if [[ \${sample##*.} == "gz" ]]; then
            cat ${reads}/*.fastq.gz > ${sample_id}.fastq.gz
        else
            cat ${reads}/*.fastq > ${sample_id}.fastq
        fi
        """
}

process combine_fa {
    tag "Combining Fasta files for ${sample_id}"
    label "process_low"

    input:
        tuple val(sample_id), path(data_dir)
    output:
        tuple val(sample_id), file("${sample_id}.{fasta,fasta.gz}")
    shell:
        """
        sample=\$(find -L  ${data_dir} -type f -name '*.fa*' -or -name '*.fasta*' | head -n 1)
        if [[ \${sample##*.} == "gz" ]]; then
            cat \$(find -L ${data_dir} -type f -name '*.fa.gz' -or -name '*.fasta.gz') > ${sample_id}.fasta.gz
        else
            cat \$(find -L ${data_dir} -type f -name '*.fa' -or -name '*.fasta') > ${sample_id}.fasta
        fi
        """
}

process porechop {
    tag "Adaptor trimming on ${reads.simpleName}"
    label "process_high"

    input:
        tuple val(sample_id), path(reads)
    output:
        tuple val(sample_id), file("${reads.simpleName}_trimmed.fastq")
    shell:
        """
        porechop -t ${task.cpus} -i ${reads} -o ${reads.simpleName}_trimmed.fastq
        """
}

process nanoq {
    tag "Read filtering on ${reads.simpleName}"
    label "process_low"
    cache true

    input:
        tuple val(sample_id), path(reads)
    output:
        tuple val(sample_id), file("${reads.simpleName}.filt.fastq.gz")
    shell:
        """
        nanoq -i ${reads} -l 200 -q 7 -O g > ${reads.simpleName}.filt.fastq.gz
        """
}

process nanocomp {
    tag "Generating raw read QC with NanoPlot"
    label "process_low"
    publishDir "$params.outdir"+"/reports/", mode: "copy"

    input:
        path(reads)
    output:
        file("NanoComp-report.html")
    shell:
        """
        NanoComp -t ${task.cpus} --fastq *.fastq* --names \$(ls | sed 's/.fastq*//g') -o .
        """
}