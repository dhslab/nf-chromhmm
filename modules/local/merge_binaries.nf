process MERGE_BINARIES {
label 'process_medium'
tag "$sample"
container "nidhidav/nf-chromhmm:v1"

input:
tuple val(sample), path(bam_bin), path(bed_bin), path(meth_bin)

output:
tuple val(sample), path("merged_binary_reordered"), emit: merged_binary

script:
"""
mkdir binary &&
mkdir merged_binary_reordered && 
cp -r \$(readlink -f methbin/) \$(readlink -f bambin/) \$(readlink -f bedbin/) binary/
java -jar ${params.chromhmm} MergeBinary binary/ merged_binary &&
for i in \$(ls merged_binary); do python3 ${projectDir}/bin/reorder_columns.py merged_binary/\$i merged_binary_reordered/\$i ${params.mark_order.join(',')}; done
"""
}