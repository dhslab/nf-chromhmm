process BINARIZE_BED {
label 'process_medium'
tag "$sample"
container "nidhidav/nf-chromhmm:v1"

input:
tuple val(sample), path(cellmarkfile), path(bams)

output:
tuple val(sample), path("bedbin"), emit: bed

script:
"""
mkdir beds
mv *Peak beds/ 
java -mx80000M -jar ${params.chromhmm} BinarizeBed -peaks \
${params.regions} beds/ $cellmarkfile bedbin/
"""
}