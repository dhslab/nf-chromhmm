process BINARIZE_METH {
    label 'process_medium'
    tag "$meta.sample"
    container "ghcr.io/dhslab/docker-methfast:250531"

    input:
    tuple val(meta), path(meth)
    path(regions_200_bp)

    output:
    tuple val(meta.sample), path("methbin"), emit: meth

    // get param min meth count
    def min_meth_coverage = params.min_meth_coverage ? "${params.min_meth_coverage}"    : "1"
    
    script:
    """
    # Create output directory
    mkdir -p methbin

    # Run methfast and generate the initial BED file
    methfast $meth $regions_200_bp > ${meta.sample}.methfast.bed

    # Loop through chromosomes 1-22
    for chr in {1..22}; do
        chr_file="methbin/${meta.sample}_chr\${chr}_binary.txt"
        
        # Extract lines for the current chromosome, add header, binarize, and remove last line
        {
            echo "${meta.sample}\tchr\${chr}"
            echo "methylation"
            awk -v chr="chr\${chr}" '(\$1 == chr) {
                if (\$5 < ${min_meth_coverage}) print 2;
                else if (\$4 > 0 && \$6 <= 0.5) print 0;
                else print 1;
            }' ${meta.sample}.methfast.bed | head -n -1
        } > \$chr_file
    done
    """
}
