process blast2fa {
    tag "Converting Blast output to fasta for ${sample_id}"
    label "process_low"
    publishDir "$params.outdir"+"/results/"+"$sample_id", mode: "copy"

    input:
        tuple val(sample_id), path(blast_out)
    output:
        tuple val(sample_id), file("*.fa*")
    shell:
        """
        # check if blast output file carries primer names
        if [[ \$(echo ${blast_out} | grep ".fa\$") ]]; then
            out_fa=${sample_id}.fa
        else
            primer=\$(echo ${blast_out} | rev | cut -f1 -d'.' | rev)
            out_fa=${sample_id}.fa.\$primer
        fi

        # append alignment coordinates to fasta header
        cat ${blast_out} | \
        egrep "is contained in|amplicon range|>" | \
        sed 's/amplicon range = / /g' | \
        sed 's/.*strand (/(/g' | \
        sed 's/ \\.\\. /../g' | \
        xargs -n3 -d'\n' | \
        sed -E "s#(^.*>)(.*)#\\2\\1#" | \
        sed -E "s#(.* )(.*)#\\2\\1#" | \
        sed 's/ \$//g' > headers.txt

        # remove irrelevant lines and 
        # replace original fasta headers with coordinate appended headers
        cat ${blast_out} | \
        grep -v " = " | \
        tr -d '#' | \
        grep -v 'primer' | \
        grep -v 'probe' | \
        awk 'NF' | \
        sed -e '1~2{R headers.txt' -e 'd;}' > \$out_fa
        """
}

process blast2bed {
    tag "Converting Blast output to bed for ${sample_id}"
    label "process_low"
    publishDir "$params.outdir"+"/results/"+"$sample_id", mode: "copy"

    input:
        tuple val(sample_id), path(blast_out)
    output:
        tuple val(sample_id), file("*.bed*")
    shell:
        """
        # check if blast output file carries primer names
        if [[ \$(echo ${blast_out} | grep ".fa\$") ]]; then
            out_bed=${sample_id}.bed
        else
            primer=\$(echo ${blast_out} | rev | cut -f1 -d'.' | rev)
            out_bed=${sample_id}.bed.\$primer
        fi

        # append alignment coordinates to fasta header
        cat ${blast_out} | \
        egrep "is contained in|amplicon range|>" | \
        sed 's/amplicon range = / /g' | \
        sed 's/.*strand (/(/g' | \
        sed 's/ \\.\\. /../g' | \
        xargs -n3 -d'\n' | \
        sed -E "s#(^.*>)(.*)#\\2\\1#" | \
        sed -E "s#(.* )(.*)#\\2\\1#" | \
        sed 's/ \$//g' > headers.txt

        # write isPCR hits in bed format
        paste <(cat headers.txt | cut -f1 -d' ') \
        <(cat headers.txt | rev | cut -f2 -d' ' | rev) \
        <(cat headers.txt | rev | cut -f1 -d' ' | rev) | \
        sed "s/\\.\\./\t/g" | \
        sed 's/>//g' | \
        sed 's/(/.\t/g' | \
        sed 's/)//g' > \$out_bed
        """
}

process blast_summary {
    tag "Generating Blast summary for ${sample_id}"
    label "process_low"
    publishDir "$params.outdir"+"/results/"+"$sample_id", mode: "copy"

    input:
        tuple val(sample_id), path(length), path(primers)
    output:
        tuple val(sample_id), file("*.tsv*")
    shell:
        """
        # check if input file carries primer names
        if [[ \$(echo ${length} | grep ".tsv\$") ]]; then
            out_tsv=${sample_id}.summary.tsv
        else
            primer=\$(echo ${length} | rev | cut -f1 -d'.' | rev)
            out_tsv=${sample_id}.summary.tsv.\$primer
        fi

        Rscript /R/tntBlast_summary.R \
            --primer ${primers} \
            --length ${length} \
            --output \$out_tsv \
            --sample ${sample_id}
        """
}

process combine_summary {
    tag "Aggregating Blast summary"
    label "process_low"
    publishDir "$params.outdir", mode: "copy"

    input:
        path(summary)
        path(primers)
        path(samples)
    output:
        path('analysis_results.tsv')
    shell:
        """
        Rscript /R/tntBlast_summary_combine.R \
            --primer ${primers} \
            --sample ${samples} \
            *.tsv*
        """
}