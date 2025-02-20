process BINARIZE_METH {
    label 'process_medium'
    tag "$meta.sample"
    container "ghcr.io/dhslab/docker-methfast:241008"

    input:
    tuple val(meta), path(meth)

    output:
    tuple val(meta.sample), path("methbin"), emit: meth

    script:
    """
    # Create output directory
    mkdir -p methbin

    # Run methfast and generate the initial BED file
    methfast $meth /storage2/fs1/dspencer/Active/spencerlab/dnidhi/projects/chromhmm/all_samples/binarize/wgbs/regions_200.bed.final > ${meta.sample}-CD34-wgbs.methfast.bed

    # Loop through chromosomes 1-22
    for chr in {1..22}; do
        chr_file="methbin/${meta.sample}_chr\${chr}_binary.txt"
        
        # Extract lines for the current chromosome, add header, binarize, and remove last line
        {
            echo "${meta.sample}\tchr\${chr}"
            echo "methylation"
            awk -v chr="chr\${chr}" '(\$1 == chr) {
                if (\$4 == 0) print 2;
                else if (\$4 > 0 && \$5 < 0.5) print 0;
                else print 1;
            }' ${meta.sample}-CD34-wgbs.methfast.bed | head -n -1
        } > \$chr_file
    done
    """
}
