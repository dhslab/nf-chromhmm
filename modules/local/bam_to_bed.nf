process BAM_TO_BED {
    label 'process_medium'
    container "nidhidav/nf-chromhmm:v1"
    tag "$id"
    publishDir "${params.outdir}/bam_to_bed", mode: 'copy'

    input:
    tuple val(id), path(bam), path(cellmarkfile)
    path(regions)

    output:
    path("outbin/merged/*.bed"), emit: bed

    script:
    def args = task.ext.args ?: ''
    chr = params.XY ? "{1..22} X Y" : "{1..22}"
    """
    # Create directories for outputs
    mkdir -p outbin
    mkdir -p bams

    # Extract prefix from the BAM file name
    prefix=\$(basename $bam .bam)

    # Process the BAM file
    mv $bam bams/
    java -mx80000M -jar ${params.chromhmm} BinarizeBam \
        ${params.regions} bams/ $cellmarkfile outbin/ &&
    
    # Combine the binary output
    mkdir -p outbin/merged &&
    combined_file=outbin/merged/combined.txt &&
    > \$combined_file &&

    for i in $chr; do
        sed -i '1,2d' outbin/*chr\${i}_*binary* &&
        paste $regions/chr\${i}.regions.bed outbin/*chr\${i}_*binary* > outbin/merged/chr\${i}.merged.txt &&
        cat outbin/merged/chr\${i}.merged.txt >> \$combined_file
    done

    # Create the final merged BED file
    merged_file=outbin/merged/\$prefix.bed
    awk '\$4 > 0' \$combined_file | bedtools merge -i - > \$merged_file
    """
}
